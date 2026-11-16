-- TerritoryPvP
-- This client forbids add-ons from changing the PvP flag (C_PvP.SetPVP / TogglePVP are blocked).
-- The only legal route is a real click on a secure button running /pvp, so this add-on:
--   * shows your PvP state with a faction shield (gray = off, color = flagged),
--   * glows + prints a gold chat line when your territory calls for PvP and you are not flagged,
--   * plain click = turn PvP ON, Shift-click = turn PvP OFF (5 minute countdown).
-- It never calls a forbidden API.

local ADDON, ns = ...

local VERSION = "0.9.0-beta"   -- fallback only; the real value comes from the .toc
local TITLE = "Forever War Mode Lite"   -- display name; internal identifiers keep the TerritoryPvP name
do
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    if get then
        local ok, v = pcall(get, ADDON, "Version")
        if ok and v then VERSION = v end
    end
end

local GOLD = "|cffffd100"
local function say(msg) print(GOLD .. "[War Mode Lite]|r " .. GOLD .. msg .. "|r") end
-- GetRealZoneText() returns "" (not nil) while loading, so "or" alone is not enough
local function zoneName(fallback)
    local z = GetRealZoneText and GetRealZoneText()
    if z and z ~= "" then return z end
    return fallback
end
-- Raid-warning style banner in the middle of the screen. Falls back to the red-text error frame
-- if the raid notice frame is unavailable.
local function screen(msg)
    local ok = false
    if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo and ChatTypeInfo["RAID_WARNING"] then
        ok = pcall(RaidNotice_AddMessage, RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
    end
    if not ok and UIErrorsFrame then UIErrorsFrame:AddMessage(msg, 1, 0.82, 0) end
end
local db
local function dbg(msg) if db and db.debug then print("|cff888888[TerritoryPvP debug] " .. msg .. "|r") end end

local DEFAULTS = {
    mode = "auto",        -- "auto" | "pve"
    reminders = true,     -- Show PvP reminders (popup in contested territory while Manual PvE)
    chatAlerts = true,    -- gold chat line when a click is needed
    debug = false,
    iconTune = {},        -- [iconIdx] = { size=mult, glow=mult, x=px, y=px }, set with /tpvp size|glowsize|nudge
    screenAlert = false,  -- big raid-warning style text on screen when a click is needed
    iconIdx = 3,          -- honor currency icon is the default; /tpvp icons to change
    guard = true,         -- secure in-combat click guard; /tpvp guard off if it misbehaves
    zoneOverride = {},    -- [mapID] = class, set by /tpvp mark
}

local S = {            -- runtime state (not saved)
    cls = "unknown", src = "none", mapID = nil,
    flag = "off", need = false, hintOff = false,
    alertKey = nil, inContested = false, remPending = false,
}

local btn, mini, glowShape, shapeAnim, frameGlow, frameAnim, countText, icon, header
local secured = {}
local ticker

---------------------------------------------------------------- territory
local PRETTY = {
    contested = "Contested", own = "Friendly (your faction)", enemy = "Enemy-controlled",
    sanctuary = "Sanctuary", forced = "Forced PvP / instance", unknown = "Unknown",
}
-- Does this territory call for PvP on? true / false / nil (= no opinion, leave the flag alone)
local WANT = { contested = true, enemy = true, own = false }

local function relative(entry, faction)
    if entry == "contested" then return "contested" end
    if entry == "sanctuary" then return "sanctuary" end
    if entry == "alliance" or entry == "horde" then
        return (entry:lower() == faction:lower()) and "own" or "enemy"
    end
end

local function Classify()
    local faction = UnitFactionGroup("player")
    if faction ~= "Alliance" and faction ~= "Horde" then return "unknown", "no faction", nil end

    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")

    if IsInInstance() then return "forced", "instance", mapID end
    if UnitIsPVPFreeForAll and UnitIsPVPFreeForAll("player") then return "forced", "ffa", mapID end

    -- game's own label (only reliably filled in for some places, e.g. capitals)
    local okz, pvpType = pcall(function() return C_PvP.GetZonePVPInfo() end)
    if not okz then pvpType = nil end
    if pvpType == "sanctuary" then return "sanctuary", "api", mapID end
    if pvpType == "combat" or pvpType == "arena" then return "forced", "api", mapID end

    if mapID then
        local sub = GetSubZoneText()
        local entry = db.zoneOverride[mapID]
        local src = "override"
        if not entry then
            local subs = ns.SUBZONES[mapID]
            entry = subs and sub and subs[sub]
            src = "subzone table"
        end
        if not entry then entry = ns.ZONES[mapID]; src = "zone table" end
        if entry then
            local cls = relative(entry, faction)
            if cls then return cls, src, mapID end
        end
    end

    -- fallback to the API label when the table has no entry
    if pvpType == "friendly" then return "own", "api", mapID end
    if pvpType == "hostile" then return "enemy", "api", mapID end
    if pvpType == "contested" then return "contested", "api", mapID end
    return "unknown", "none", mapID
end

---------------------------------------------------------------- zone log (for /tpvp report)
-- Account-wide record of every map ID seen, so players can send back what their client reports.
-- Nothing leaves the game by itself: /tpvp report shows it as text to copy.
local function Record(mapID, newVisit)
    if not mapID or not TerritoryPvPDB then return end
    local zones = TerritoryPvPDB.zones
    local z = zones[mapID]
    if not z then z = { n = 0, api = {}, subs = {}, fac = {} }; zones[mapID] = z end
    z.name = zoneName(z.name)
    if newVisit then z.n = z.n + 1 end
    local okp, label = pcall(function() return C_PvP.GetZonePVPInfo() end)
    z.api[(okp and label) or "none"] = true
    local fac = UnitFactionGroup("player")
    if fac then z.fac[fac] = true end
    local sub = GetSubZoneText()
    if sub and sub ~= "" then
        local count = 0
        for _ in pairs(z.subs) do count = count + 1 end
        if count < 40 then z.subs[sub] = true end
    end
    z.table = ns.ZONES[mapID] or "unlisted"
    z.override = db and db.zoneOverride[mapID] or z.override   -- an override is a vote that the table is wrong
end

local function FlagState()
    local flagged = UnitIsPVP("player") and true or false
    local counting = (IsPVPTimerRunning and IsPVPTimerRunning()) and true or false
    if flagged and counting then return "counting" end
    if flagged then return "on" end
    return "off"
end

---------------------------------------------------------------- secure sync
local pendingSync = false
local function SyncSecure()
    if #secured == 0 then return end
    if InCombatLockdown() then pendingSync = true; return end
    local perm = (S.flag == "on")
    for _, fr in ipairs(secured) do
        fr:SetAttribute("tp_perm", perm and "1" or "0")
        -- plain click is only armed when it would turn PvP ON (or cancel a countdown)
        fr:SetAttribute("macrotext1", perm and "" or "/pvp")
        -- Shift-click is only armed when it would turn PvP OFF (permanently flagged). /pvp is a toggle,
        -- so an armed Shift-click while unflagged or counting down would turn PvP ON.
        fr:SetAttribute("shift-macrotext1", perm and "/pvp" or "")
        fr:SetAttribute("tp_pend", nil)   -- state was just re-read from the game
        fr:SetAttribute("tp_kd", GetCVar("ActionButtonUseKeyDown") == "1" and "1" or "0")
    end
    pendingSync = false
end

---------------------------------------------------------------- visuals
local function FormatTime(ms)
    local ok, s = pcall(function() return math.max(0, math.floor((ms or 0) / 1000)) end)
    if not ok then return "?" end
    return ("%d:%02d"):format(math.floor(s / 60), s % 60)
end

local function UpdateCountdown()
    if not countText then return end
    if S.flag == "counting" and GetPVPTimer then
        countText:SetText(FormatTime(GetPVPTimer()))
    else
        countText:SetText("")
    end
end

local function UpdateVisuals()
    if not (btn and icon and glowShape and shapeAnim and frameGlow and frameAnim) then return end
    local flagged = (S.flag ~= "off")
    if icon.SetDesaturated then icon:SetDesaturated(not flagged) end
    if flagged then icon:SetVertexColor(1, 1, 1) else icon:SetVertexColor(0.55, 0.55, 0.55) end
    btn:SetAlpha(db.mode == "pve" and 0.55 or 1)
    -- Glow: normally a pulsing gold copy of the icon's own shape. Icons marked glow="frame" (art
    -- that looks wrong when copied or tinted) get a pulsing gold outline around the square instead.
    local frameStyle = ns.ICONS[ns.PickIcon()].glow == "frame"
    if S.need and not frameStyle then
        glowShape:SetAlpha(1)
        if not shapeAnim:IsPlaying() then shapeAnim:Play() end
    else
        if shapeAnim:IsPlaying() then shapeAnim:Stop() end
        glowShape:SetAlpha(0)
    end
    if S.need and frameStyle then
        frameGlow:SetAlpha(1)
        if not frameAnim:IsPlaying() then frameAnim:Play() end
    else
        if frameAnim:IsPlaying() then frameAnim:Stop() end
        frameGlow:SetAlpha(0)
    end
    if S.flag == "counting" then
        if not ticker then ticker = C_Timer.NewTicker(1, UpdateCountdown) end
    elseif ticker then
        ticker:Cancel(); ticker = nil
    end
    UpdateCountdown()
    if mini then
        if mini.icon.SetDesaturated then mini.icon:SetDesaturated(not flagged) end
        mini.icon:SetAlpha(db.mode == "pve" and 0.6 or 1)
    end
end

---------------------------------------------------------------- reminder popup
local SetMode
StaticPopupDialogs["TERRITORYPVP_REMINDER"] = {
    text = GOLD .. "PvP automation is paused|r\n\nYou are currently using Manual PvE. Would you like to resume Automatic PvP?",
    button1 = "Resume Automatic PvP",
    button2 = "Keep Manual PvE",
    OnAccept = function() if SetMode then SetMode("auto") end end,
    timeout = 0, whileDead = false, hideOnEscape = true, preferredIndex = 3,
}

---------------------------------------------------------------- core refresh
local Refresh
Refresh = function(reason)
    if not db then return end
    local cls, src, mapID = Classify()
    S.cls, S.src, S.mapID = cls, src, mapID
    S.flag = FlagState()
    Record(mapID, mapID ~= S.logMap)
    S.logMap = mapID

    local want = WANT[cls]
    S.need = (db.mode == "auto") and want == true and S.flag ~= "on"
    S.hintOff = (want == false) and S.flag == "on"

    dbg(("refresh(%s) map=%s cls=%s via %s flag=%s need=%s"):format(
        tostring(reason), tostring(mapID), cls, src, S.flag, tostring(S.need)))

    -- chat alerts: only when the territory changes, not on every subzone or flag event
    local key = cls .. ":" .. tostring(mapID)
    if key ~= S.alertKey then
        S.alertKey = key
        if S.need and db.screenAlert then
            screen(("%s (%s): click the shield to turn PvP on"):format(zoneName("This area"), PRETTY[cls]))
        end
        if db.chatAlerts then
            local zone = zoneName("this area")
            if S.need then
                say(("%s (%s): click the shield to turn PvP on."):format(zone, PRETTY[cls]))
            elseif db.mode == "auto" and S.hintOff then
                say(("%s is friendly territory: Shift-click the shield to turn PvP off (5 minute countdown)."):format(zone))
            elseif db.mode == "pve" and S.flag == "on" and WANT[cls] ~= nil then
                say("Manual PvE is selected but you are PvP-flagged: Shift-click the shield to turn PvP off.")
            end
        end
    end

    -- contested-zone reminder (once per entry, never in combat, never changes mode by itself)
    if cls == "contested" then
        if not S.inContested then
            S.inContested = true
            if db.mode == "pve" then S.remPending = true end
        end
    else
        S.inContested = false
        S.remPending = false
    end
    if db.mode ~= "pve" then S.remPending = false end
    -- UnitAffectingCombat is checked too: right after a /reload InCombatLockdown() can read false
    if S.remPending and db.reminders and not InCombatLockdown() and not UnitAffectingCombat("player") then
        S.remPending = false
        StaticPopup_Show("TERRITORYPVP_REMINDER")
    end

    SyncSecure()
    UpdateVisuals()
end

SetMode = function(mode)
    db.mode = mode
    S.remPending = false
    say(mode == "auto" and "Automatic PvP: the shield will prompt you in contested and enemy territory."
        or "Manual PvE: no PvP prompts until you switch back to Automatic.")
    S.alertKey = nil
    Refresh("mode")
end

---------------------------------------------------------------- tooltip / status
local function StatusLines()
    local faction = UnitFactionGroup("player") or "?"
    local lines = {
        { "Faction", faction },
        { "Territory", PRETTY[S.cls] .. (S.src ~= "none" and (" (" .. S.src .. ")") or "") },
        { "Mode", db.mode == "auto" and "Automatic PvP" or "Manual PvE override" },
    }
    local st = S.flag
    local flagText = (st == "on") and "PvP flagged"
        or (st == "counting") and ("PvP flagged, deactivating in " .. FormatTime(GetPVPTimer and GetPVPTimer())) or "Not flagged"
    lines[#lines + 1] = { "PvP flag", flagText }
    return lines
end

local function ShowTooltip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:AddLine(TITLE .. " " .. VERSION, 1, 0.82, 0)
    for _, l in ipairs(StatusLines()) do GameTooltip:AddDoubleLine(l[1], l[2], 0.8, 0.8, 0.8, 1, 1, 1) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Click: turn PvP on", 0.6, 1, 0.6)
    GameTooltip:AddLine("Shift-click: turn PvP off", 1, 0.6, 0.6)
    GameTooltip:AddLine("Right-click: menu    Ctrl-drag: move", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

local function PrintStatus()
    for _, l in ipairs(StatusLines()) do say(l[1] .. ": " .. l[2]) end
end

---------------------------------------------------------------- menu
local function OpenMenu(owner)
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(owner, function(_, root)
            root:CreateTitle(TITLE .. " " .. VERSION)
            root:CreateRadio("Automatic PvP", function() return db.mode == "auto" end, function() SetMode("auto") end)
            root:CreateRadio("Manual PvE override", function() return db.mode == "pve" end, function() SetMode("pve") end)
            root:CreateDivider()
            root:CreateCheckbox("Show PvP reminders", function() return db.reminders end,
                function() db.reminders = not db.reminders end)
            root:CreateCheckbox("Chat alerts (gold)", function() return db.chatAlerts end,
                function() db.chatAlerts = not db.chatAlerts end)
            root:CreateCheckbox("Screen alert (raid warning text)", function() return db.screenAlert end,
                function() db.screenAlert = not db.screenAlert end)
        end)
    else
        say("Menu unavailable. Use /tpvp auto, /tpvp pve, /tpvp reminders, /tpvp alert.")
    end
end

---------------------------------------------------------------- icons
local ICONS = {
    { name = "HUD faction atlas", atlas = { Alliance = "UI-HUD-UnitFrame-Player-PVP-AllianceIcon", Horde = "UI-HUD-UnitFrame-Player-PVP-HordeIcon" } },
    { name = "Honor portrait atlas", atlas = { Alliance = "honorsystem-portrait-alliance", Horde = "honorsystem-portrait-horde" } },
    { name = "Honor currency icon", file = { Alliance = "Interface\\Icons\\PVPCurrency-Honor-Alliance", Horde = "Interface\\Icons\\PVPCurrency-Honor-Horde" }, glow = "frame" },
    { name = "PvP currency frame", file = { Alliance = "Interface\\PVPFrame\\PVP-Currency-Alliance", Horde = "Interface\\PVPFrame\\PVP-Currency-Horde" }, goff = { 0, -1.3 } },
    { name = "Old PvP badge", file = { Alliance = "Interface\\TargetingFrame\\UI-PVP-Alliance", Horde = "Interface\\TargetingFrame\\UI-PVP-Horde" }, coords = { 0, 0.609375, 0, 0.796875 }, aspect = 0.765, goff = { -0.6, -2.4 } },
}
local function atlasExists(n)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(n) ~= nil
end
local function myFaction()
    return (UnitFactionGroup("player") == "Horde") and "Horde" or "Alliance"
end
local function PickIcon()
    if db.iconIdx and ICONS[db.iconIdx] then return db.iconIdx end
    local fac = myFaction()
    for i, c in ipairs(ICONS) do
        if c.atlas and atlasExists(c.atlas[fac]) then return i end
    end
    return 3
end
local function ApplyIcon(tex)
    local c, fac = ICONS[PickIcon()], myFaction()
    if c.atlas then
        local ok = pcall(tex.SetAtlas, tex, c.atlas[fac], false)
        if ok then tex:SetTexCoord(0, 1, 0, 1) return end
        c = ICONS[3]
    end
    tex:SetTexture(c.file[fac])
    local t = c.coords or { 0, 1, 0, 1 }
    -- optional inward crop (fraction of each side) to trim stray edge/corner pixels in a texture
    local tune = db.iconTune and db.iconTune[PickIcon()]
    local k = (tune and tune.crop) or c.crop or 0
    local w, h = t[2] - t[1], t[4] - t[3]
    tex:SetTexCoord(t[1] + w * k, t[2] - w * k, t[3] + h * k, t[4] - h * k)
end
-- Size/position of an icon texture. `aspect` (width/height) stops cropped textures being stretched
-- square; per-icon tuning (size multiplier, glow multiplier, x/y nudge) is saved per character.
local GLOW_MUL = 1.3
local function Layout(tex, base, isGlow)
    local c = ICONS[PickIcon()]
    local t = (db.iconTune and db.iconTune[PickIcon()]) or {}
    local k = base * (t.size or 1) * (isGlow and (t.glow or c.gmul or GLOW_MUL) or 1)
    -- The glow is a scaled copy of the icon. If the artwork is not centred in its texture, scaling
    -- shifts it, so each icon can carry a glow offset (goff) that re-aligns the copy with the icon.
    local gx, gy = 0, 0
    if isGlow then
        local g = c.goff or { 0, 0 }
        gx, gy = (t.gx or g[1]), (t.gy or g[2])
    else
        -- icon-only offset (glow stays put): for artwork that is off-centre in its texture
        local o = c.ioff or { 0, 0 }
        gx, gy = (t.ix or o[1]), (t.iy or o[2])
    end
    tex:ClearAllPoints()
    tex:SetPoint("CENTER", tex:GetParent(), "CENTER", ((t.x or 0) + gx) * base / 40, ((t.y or 0) + gy) * base / 40)
    tex:SetSize(k * (c.aspect or 1), k)
end
ns.ApplyAllIcons = function()
    if icon then ApplyIcon(icon); Layout(icon, 40) end
    if glowShape then ApplyIcon(glowShape); Layout(glowShape, 40, true) end
    if mini then ApplyIcon(mini.icon); Layout(mini.icon, 20) end
    if UpdateVisuals then UpdateVisuals() end
end
ns.ICONS, ns.PickIcon, ns.atlasExists, ns.myFaction = ICONS, PickIcon, atlasExists, myFaction

---------------------------------------------------------------- secure click setup (shared)
-- /pvp is a toggle, so each click is armed only when its result is the one it promises:
--   plain click       runs /pvp only when you are NOT permanently flagged (turns PvP on / cancels a countdown)
--   Shift-click       runs /pvp only when you ARE permanently flagged (turns PvP off)
-- The other macro is blanked, so a stray click does nothing. Lua cannot change attributes in combat, so a
-- secure snippet keeps the two macros in step. Only the PRE snippet is used (the post snippet never ran on
-- this client, see the debug output). Each click predicts its result into tp_pend; the pending change is
-- applied at the start of the next click event, before the action of that event can run. Because the
-- secure button acts on key-down or key-up depending on ActionButtonUseKeyDown (tp_kd), the click that
-- acts never sees its own change. Ctrl/Alt do nothing (Ctrl is for dragging). Right click is our menu.
local PRE = [[
    self:SetAttribute("tp_dbg", (down and "D" or "U") .. "/" .. (button or "?"))
    if button ~= "LeftButton" then return end

    -- 1. apply the change predicted by the previous acting click
    local pend = self:GetAttribute("tp_pend")
    if pend then
        self:SetAttribute("tp_perm", pend)
        self:SetAttribute("macrotext1", pend == "1" and "" or "/pvp")
        self:SetAttribute("shift-macrotext1", pend == "1" and "/pvp" or "")
        self:SetAttribute("tp_pend", nil)
    end

    -- 2. only the event that actually runs the macro predicts the next state
    local kd = self:GetAttribute("tp_kd") == "1"
    local acting
    if down then acting = kd else acting = not kd end
    if not acting then return end
    local shift = IsShiftKeyDown()
    local perm = self:GetAttribute("tp_perm")
    if shift then
        if perm == "1" then self:SetAttribute("tp_pend", "0") end   -- Shift-click turns PvP off
    else
        if perm ~= "1" then self:SetAttribute("tp_pend", "1") end   -- plain click turns PvP on
    end
]]

local lastHint = 0
local function SetupSecure(frame, label)
    frame:RegisterForClicks("AnyUp", "AnyDown")   -- secure buttons act on key-down or key-up by CVar
    frame:SetAttribute("type1", "macro")
    frame:SetAttribute("macrotext1", "/pvp")
    frame:SetAttribute("shift-type1", "macro")
    frame:SetAttribute("shift-macrotext1", "")   -- armed by SyncSecure / the snippet only while permanently flagged
    for _, mod in ipairs({ "ctrl-", "alt-", "ctrl-shift-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }) do
        frame:SetAttribute(mod .. "type1", "macro")
        frame:SetAttribute(mod .. "macrotext1", "")
    end
    frame:SetAttribute("tp_perm", "0")
    frame:SetAttribute("tp_kd", GetCVar("ActionButtonUseKeyDown") == "1" and "1" or "0")

    if db.guard then
        header = header or CreateFrame("Frame", nil, UIParent, "SecureHandlerBaseTemplate")
        local ok, err = pcall(SecureHandlerWrapScript, frame, "OnClick", header, PRE)
        if not ok then
            say("Combat click guard could not be installed on " .. label .. ": " .. tostring(err))
            S.noGuard = true
        end
    else
        S.noGuard = true
    end

    frame:HookScript("PostClick", function(self, b, down)
        if db.debug then
            dbg(("%s click %s %s shift=%s combat=%s keydownCVar=%s | tp_kd=%s tp_perm=%s macro='%s' shiftmacro='%s' tp_pend=%s pre=%s | UnitIsPVP=%s state=%s")
                :format(label, tostring(b), down and "down" or "up", tostring(IsShiftKeyDown()),
                tostring(InCombatLockdown()), tostring(GetCVar("ActionButtonUseKeyDown")),
                tostring(self:GetAttribute("tp_kd")), tostring(self:GetAttribute("tp_perm")),
                tostring(self:GetAttribute("macrotext1")), tostring(self:GetAttribute("shift-macrotext1")),
                tostring(self:GetAttribute("tp_pend")), tostring(self:GetAttribute("tp_dbg")),
                tostring(UnitIsPVP("player")), tostring(S.flag)))
            if down then C_Timer.After(1.5, function()
                dbg(("  1.5s later: UnitIsPVP=%s timerRunning=%s"):format(
                    tostring(UnitIsPVP("player")), tostring(IsPVPTimerRunning())))
            end) end
        end
        if not down then return end
        if b == "RightButton" then OpenMenu(self); return end
        if b == "LeftButton" and not IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
            if S.flag == "on" and not S.noGuard and GetTime() - lastHint > 2 then
                lastHint = GetTime()
                say("PvP is on. Shift-click to turn it off.")
            end
        elseif b == "LeftButton" and IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
            -- Shift-click is deliberately inert unless you are permanently flagged; say why
            if S.flag ~= "on" and (not S.noGuard or not InCombatLockdown()) and GetTime() - lastHint > 2 then
                lastHint = GetTime()
                if S.flag == "counting" then
                    say("PvP is already deactivating. Click (without Shift) to cancel the countdown.")
                else
                    say("Shift-click only turns PvP off. Click (without Shift) to turn it on.")
                end
            end
        end
    end)
    secured[#secured + 1] = frame
end

---------------------------------------------------------------- frames
local function CreateMinimapButton()
    mini = CreateFrame("Button", "TerritoryPvPMinimapButton", Minimap, "SecureActionButtonTemplate")
    mini:SetSize(31, 31)
    mini:SetFrameStrata("MEDIUM"); mini:SetFrameLevel(8)
    mini:RegisterForDrag("LeftButton")
    local border = mini:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53); border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    local bg = mini:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20); bg:SetPoint("CENTER"); bg:SetColorTexture(0, 0, 0, 0.6)
    mini.icon = mini:CreateTexture(nil, "ARTWORK")
    mini.icon:SetSize(20, 20); mini.icon:SetPoint("CENTER")
    ApplyIcon(mini.icon); Layout(mini.icon, 20)

    local function place()
        if InCombatLockdown() then return end   -- protected frame: can't move in combat
        local a = math.rad(db.miniAngle or 215)
        mini:ClearAllPoints()
        mini:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(a), 80 * math.sin(a))
    end
    place()
    SetupSecure(mini, "minimap")
    mini:SetScript("OnDragStart", function(self)
        if InCombatLockdown() or not IsControlKeyDown() then return end
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            db.miniAngle = math.deg(math.atan2(py / scale - my, px / scale - mx))
            place()
        end)
    end)
    mini:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    mini:SetScript("OnEnter", function(self) ShowTooltip(self) end)
    mini:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function CreateActionButton()
    btn = CreateFrame("Button", "TerritoryPvPButton", UIParent, "SecureActionButtonTemplate")
    btn:SetSize(40, 40)
    btn:SetFrameStrata("MEDIUM")
    btn:SetMovable(true); btn:SetClampedToScreen(true)
    btn:RegisterForDrag("LeftButton")

    local p = db.pos
    if p then btn:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else btn:SetPoint("CENTER", UIParent, "CENTER", 0, -160) end

    icon = btn:CreateTexture(nil, "ARTWORK")
    ApplyIcon(icon); Layout(icon, 40)

    glowShape = btn:CreateTexture(nil, "OVERLAY")
    ApplyIcon(glowShape); Layout(glowShape, 40, true)
    glowShape:SetBlendMode("ADD")
    glowShape:SetVertexColor(1, 0.82, 0)
    glowShape:SetAlpha(0)
    shapeAnim = glowShape:CreateAnimationGroup()
    shapeAnim:SetLooping("BOUNCE")
    local b = shapeAnim:CreateAnimation("Alpha")
    b:SetFromAlpha(1); b:SetToAlpha(0.25); b:SetDuration(0.7)

    -- gold outline (two rings) around the button, for icons that use glow = "frame"
    frameGlow = CreateFrame("Frame", nil, btn)
    frameGlow:SetAllPoints(btn)
    frameGlow:SetFrameLevel(btn:GetFrameLevel() + 2)
    frameGlow:SetAlpha(0)
    for _, ring in ipairs({ { off = 1, th = 2, alpha = 1 }, { off = 3, th = 2, alpha = 0.4 } }) do
        local o, th, al = ring.off, ring.th, ring.alpha
        -- top, bottom, left, right bars of a square ring `o` px outside the button
        local t1 = frameGlow:CreateTexture(nil, "OVERLAY"); t1:SetColorTexture(1, 0.82, 0, al)
        t1:SetPoint("BOTTOMLEFT", btn, "TOPLEFT", -o - th, o); t1:SetPoint("BOTTOMRIGHT", btn, "TOPRIGHT", o + th, o); t1:SetHeight(th)
        local t2 = frameGlow:CreateTexture(nil, "OVERLAY"); t2:SetColorTexture(1, 0.82, 0, al)
        t2:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", -o - th, -o); t2:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", o + th, -o); t2:SetHeight(th)
        local t3 = frameGlow:CreateTexture(nil, "OVERLAY"); t3:SetColorTexture(1, 0.82, 0, al)
        t3:SetPoint("TOPRIGHT", btn, "TOPLEFT", -o, o); t3:SetPoint("BOTTOMRIGHT", btn, "BOTTOMLEFT", -o, -o); t3:SetWidth(th)
        local t4 = frameGlow:CreateTexture(nil, "OVERLAY"); t4:SetColorTexture(1, 0.82, 0, al)
        t4:SetPoint("TOPLEFT", btn, "TOPRIGHT", o, o); t4:SetPoint("BOTTOMLEFT", btn, "BOTTOMRIGHT", o, -o); t4:SetWidth(th)
    end
    frameAnim = frameGlow:CreateAnimationGroup()
    frameAnim:SetLooping("BOUNCE")
    local fa = frameAnim:CreateAnimation("Alpha")
    fa:SetFromAlpha(1); fa:SetToAlpha(0.25); fa:SetDuration(0.7)

    countText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countText:SetPoint("TOP", btn, "BOTTOM", 0, -1)

    SetupSecure(btn, "shield")

    btn:SetScript("OnDragStart", function(self)
        if InCombatLockdown() or not IsControlKeyDown() then return end
        self:StartMoving()
    end)
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        db.pos = { point, relPoint, x, y }
    end)
    btn:SetScript("OnEnter", function(self) ShowTooltip(self) end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

---------------------------------------------------------------- report window
local function keysOf(t)
    local k = {}
    for key in pairs(t) do k[#k + 1] = tostring(key) end
    table.sort(k)
    return k
end
local function joined(t)
    local k = keysOf(t)
    return #k > 0 and table.concat(k, ",") or "-"
end
-- what each game label should mean for the visiting faction
local EXPECT = { friendly = "own", hostile = "enemy", contested = "contested", sanctuary = "sanctuary" }

local function BuildReport()
    local v, b, _, toc = GetBuildInfo()
    local out = {
        ("%s zone report | addon %s | client %s build %s | interface %s | %s"):format(
            TITLE, VERSION, tostring(v), tostring(b), tostring(toc), date("%Y-%m-%d")),
        "Columns: mapID | zone | table class | game label(s) | factions seen | visits | flags | subzones",
    }
    local ids = {}
    for id in pairs(TerritoryPvPDB.zones) do ids[#ids + 1] = id end
    table.sort(ids)
    local attention, all = {}, {}
    for _, id in ipairs(ids) do
        local z = TerritoryPvPDB.zones[id]
        local flags = {}
        if z.table == "unlisted" then flags[#flags + 1] = "UNLISTED" end
        if z.override then flags[#flags + 1] = "OVERRIDE=" .. z.override end
        if z.table and z.table ~= "unlisted" then
            for label in pairs(z.api) do
                local want = EXPECT[label]
                if want then
                    for fac in pairs(z.fac) do
                        local got = relative(z.table, fac)
                        if got ~= want then
                            flags[#flags + 1] = ("API-DIFFERS(%s says %s, table gives %s for %s)"):format(
                                label, want, tostring(got), fac)
                        end
                    end
                end
            end
        end
        local line = ("%d | %s | %s | %s | %s | %d | %s | %s"):format(
            id, z.name or "?", z.table or "?", joined(z.api), joined(z.fac), z.n or 0,
            #flags > 0 and table.concat(flags, "; ") or "-", joined(z.subs))
        all[#all + 1] = line
        if #flags > 0 then attention[#attention + 1] = line end
    end
    out[#out + 1] = ""
    out[#out + 1] = ("== NEEDS ATTENTION (%d) =="):format(#attention)
    for _, l in ipairs(attention) do out[#out + 1] = l end
    out[#out + 1] = ""
    out[#out + 1] = ("== ALL ZONES SEEN (%d) =="):format(#all)
    for _, l in ipairs(all) do out[#out + 1] = l end
    return table.concat(out, "\n"), #all
end

local reportFrame
local function ShowReport()
    local text, count = BuildReport()
    if count == 0 then say("No zones recorded yet. Walk around a bit, then try again.") return end
    if not reportFrame then
        local fr
        local ok, made = pcall(CreateFrame, "Frame", "TerritoryPvPReportFrame", UIParent, "BasicFrameTemplateWithInset")
        if ok and made then
            fr = made
            if fr.TitleText then fr.TitleText:SetText(TITLE .. " zone report") end
        else
            fr = CreateFrame("Frame", "TerritoryPvPReportFrame", UIParent, "BackdropTemplate")
            fr:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 } })
            local title = fr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            title:SetPoint("TOP", 0, -10); title:SetText(TITLE .. " zone report")
            local x = CreateFrame("Button", nil, fr, "UIPanelCloseButton")
            x:SetPoint("TOPRIGHT", -2, -2)
        end
        fr:SetSize(640, 440)
        fr:SetPoint("CENTER")
        fr:SetFrameStrata("DIALOG")
        fr:SetMovable(true); fr:EnableMouse(true)
        fr:RegisterForDrag("LeftButton")
        fr:SetScript("OnDragStart", fr.StartMoving)
        fr:SetScript("OnDragStop", fr.StopMovingOrSizing)
        tinsert(UISpecialFrames, "TerritoryPvPReportFrame")

        local hint = fr:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("BOTTOMLEFT", 16, 14)
        hint:SetText("Press Ctrl+C to copy, then paste it into a message to the author.")

        local scroll = CreateFrame("ScrollFrame", "TerritoryPvPReportScroll", fr, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 14, -34)
        scroll:SetPoint("BOTTOMRIGHT", -34, 40)
        local eb = CreateFrame("EditBox", nil, scroll)
        eb:SetMultiLine(true)
        eb:SetFontObject(ChatFontNormal)
        eb:SetWidth(570)
        eb:SetAutoFocus(false)
        eb:SetScript("OnEscapePressed", function() fr:Hide() end)
        -- read-only: put the original text back if someone types in it
        eb:SetScript("OnTextChanged", function(self, user)
            if user and fr.text then self:SetText(fr.text); self:HighlightText() end
        end)
        scroll:SetScrollChild(eb)
        fr.eb = eb
        reportFrame = fr
    end
    reportFrame.text = text
    reportFrame.eb:SetText(text)
    reportFrame:Show()
    reportFrame.eb:SetFocus()
    reportFrame.eb:HighlightText()
    say(("Zone report ready (%d zones). Ctrl+C to copy."):format(count))
end

---------------------------------------------------------------- events
local initialized = false
local function Init()
    if initialized then return end
    if InCombatLockdown() then return end   -- secure setup must wait for out of combat
    initialized = true
    CreateActionButton()
    CreateMinimapButton()
    Refresh("init")
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("ZONE_CHANGED")
f:RegisterEvent("ZONE_CHANGED_INDOORS")
f:RegisterEvent("PLAYER_FLAGS_CHANGED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_DEAD")
f:RegisterEvent("PLAYER_ALIVE")
f:RegisterEvent("PLAYER_UNGHOST")
f:RegisterEvent("CVAR_UPDATE")   -- the key-down/key-up click mode is read by the secure snippet

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON then return end
        if type(TerritoryPvPDB) ~= "table" then TerritoryPvPDB = {} end
        if type(TerritoryPvPDB.zones) ~= "table" then TerritoryPvPDB.zones = {} end
        if type(TerritoryPvPCharDB) ~= "table" then TerritoryPvPCharDB = {} end
        db = TerritoryPvPCharDB
        -- fill missing fields; replace fields of the wrong type; never touch valid saved values
        for k, v in pairs(DEFAULTS) do
            if db[k] == nil or type(db[k]) ~= type(v) then
                if type(v) == "table" then db[k] = {} else db[k] = v end
            end
        end
        if db.mode ~= "auto" and db.mode ~= "pve" then db.mode = "auto" end
        if db.pos ~= nil and type(db.pos) ~= "table" then db.pos = nil end
        if db.miniAngle ~= nil and type(db.miniAngle) ~= "number" then db.miniAngle = nil end
        return
    end
    if not db then return end
    if event == "PLAYER_LOGIN" then
        Init()
        return
    end
    if not initialized then
        if event == "PLAYER_REGEN_ENABLED" then Init() end
        return
    end
    if event == "CVAR_UPDATE" then SyncSecure(); return end
    if event == "PLAYER_FLAGS_CHANGED" and arg1 ~= "player" then return end
    if event == "PLAYER_REGEN_ENABLED" then
        Refresh("regen")
        return
    end
    Refresh(event)
end)

---------------------------------------------------------------- slash commands
SLASH_TERRITORYPVP1 = "/tpvp"
SlashCmdList["TERRITORYPVP"] = function(msg)
    if not db then return end
    local cmd, arg = (msg or ""):match("^(%S*)%s*(.-)%s*$")
    cmd = cmd:lower(); arg = arg:lower()
    local function onoff(key, label)
        if arg == "on" then db[key] = true elseif arg == "off" then db[key] = false else db[key] = not db[key] end
        say(label .. ": " .. (db[key] and "on" or "off"))
    end
    if cmd == "" or cmd == "status" then
        PrintStatus()
    elseif cmd == "auto" then SetMode("auto")
    elseif cmd == "pve" then SetMode("pve")
    elseif cmd == "reminders" then onoff("reminders", "PvP reminders")
    elseif cmd == "alert" then onoff("chatAlerts", "Chat alerts")
    elseif cmd == "screen" then
        if arg == "test" then
            screen("Stranglethorn Vale (Contested): click the shield to turn PvP on")
        else
            onoff("screenAlert", "Screen alerts")
        end
    elseif cmd == "debug" then onoff("debug", "Debug")
    elseif cmd == "zone" then
        local cls, src, mapID = Classify()
        local pv = select(2, pcall(function() return C_PvP.GetZonePVPInfo() end))
        say(("%s / %s  mapID=%s  apiLabel=%s"):format(GetRealZoneText() or "?", GetSubZoneText() or "", tostring(mapID), tostring(pv)))
        say(("Class: %s via %s%s"):format(PRETTY[cls], src, db.zoneOverride[mapID or 0] and " (your override)" or ""))
    elseif cmd == "mark" then
        local mapID = C_Map.GetBestMapForUnit("player")
        if not mapID then say("No map ID here.") return end
        if arg == "clear" then db.zoneOverride[mapID] = nil; say("Override cleared for map " .. mapID)
        elseif arg == "alliance" or arg == "horde" or arg == "contested" or arg == "sanctuary" then
            db.zoneOverride[mapID] = arg; say(("Map %d marked %s for this character."):format(mapID, arg))
        else say("Usage: /tpvp mark alliance|horde|contested|sanctuary|clear") return end
        S.alertKey = nil; Refresh("mark")
    elseif cmd == "icons" then
        local fac = ns.myFaction()
        for i, c in ipairs(ns.ICONS) do
            local ex = c.atlas and (ns.atlasExists(c.atlas[fac]) and "atlas found" or "atlas MISSING") or "file (cannot check)"
            say(("%d: %s [%s]%s"):format(i, c.name, ex, (ns.PickIcon() == i) and "  <- in use" or ""))
        end
        say("Pick one with /tpvp icon <number>, or /tpvp icon auto")
    elseif cmd == "icon" then
        local n = tonumber(arg)
        if n and ns.ICONS[n] then db.iconIdx = n
        elseif arg == "auto" then db.iconIdx = 0   -- 0 = auto-pick (nil would be refilled with the default at next login)
        else say("Usage: /tpvp icon <1-" .. #ns.ICONS .. "|auto>   (see /tpvp icons)") return end
        ns.ApplyAllIcons()
    elseif cmd == "size" or cmd == "glowsize" or cmd == "nudge" or cmd == "glownudge" or cmd == "iconnudge" or cmd == "crop" or cmd == "tune" then
        local i = ns.PickIcon()
        db.iconTune = db.iconTune or {}
        local t = db.iconTune[i] or {}
        db.iconTune[i] = t
        local a, b = arg:match("^(%-?[%d%.]+)%s*(%-?[%d%.]*)")
        a, b = tonumber(a), tonumber(b)
        if cmd == "tune" and arg == "reset" then db.iconTune[i] = nil
        elseif cmd == "size" and a then t.size = math.max(0.3, math.min(3, a))
        elseif cmd == "glowsize" and a then t.glow = math.max(0.8, math.min(3, a))
        elseif cmd == "nudge" and a and b then t.x, t.y = a, b
        elseif cmd == "glownudge" and a and b then t.gx, t.gy = a, b
        elseif cmd == "iconnudge" and a and b then t.ix, t.iy = a, b
        elseif cmd == "crop" and a then t.crop = math.max(0, math.min(0.2, a))
        elseif cmd == "tune" then
            local g = ns.ICONS[i].goff or { 0, 0 }
            say(("Icon %d: size x%.2f, glow x%.2f, offset %.1f,%.1f, glow offset %.1f,%.1f"):format(
                i, t.size or 1, t.glow or ns.ICONS[i].gmul or 1.3, t.x or 0, t.y or 0, t.gx or g[1], t.gy or g[2]))
            local o = ns.ICONS[i].ioff or { 0, 0 }
            say(("icon-only offset %.1f,%.1f, crop %.2f"):format(t.ix or o[1], t.iy or o[2], t.crop or ns.ICONS[i].crop or 0))
            say("/tpvp size <mult> | glowsize <mult> | nudge <x> <y> | glownudge <x> <y> | iconnudge <x> <y> | crop <0-0.2> | tune reset")
            return
        else
            say("Usage: /tpvp size <mult> (1 = default) | glowsize <mult> (1.3 default) | nudge <x> <y> | glownudge <x> <y> | iconnudge <x> <y> (pixels, +x right, +y up) | crop <0-0.2> | tune reset")
            return
        end
        ns.ApplyAllIcons()
    elseif cmd == "report" then
        if arg == "clear" then
            wipe(TerritoryPvPDB.zones)
            say("Zone log cleared.")
        else
            ShowReport()
        end
    elseif cmd == "guard" then
        db.guard = (arg ~= "off")
        say("Combat click guard " .. (db.guard and "ON" or "OFF") .. ". /reload to apply.")
    elseif cmd == "reset" then
        db.pos = nil; db.miniAngle = nil
        say("Positions reset. /reload to apply.")
    else
        say("/tpvp [status] | auto | pve | reminders [on|off] | alert [on|off] | screen [on|off|test] | zone | report [clear] | mark <class|clear> | icons | icon <n> | size | glowsize | nudge | tune | guard on|off | debug | reset")
    end
end
