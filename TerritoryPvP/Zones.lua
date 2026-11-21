-- Territory table, keyed by uiMapID.
-- Values: "alliance" | "horde" | "contested" | "sanctuary"
-- Anything NOT listed is "unknown" and the add-on will never prompt you based on a guess.
--
-- Two separate questions are tracked for every zone:
--   * the map ID:   "id VERIFIED" = seen in game with /tpvp zone or diagnostic logs;
--                   "id unverified" = taken from the retail uiMapID scheme. Every ID checked so far
--                   matched that scheme, but an unverified one can still be wrong.
--   * the owner:    zone-level classes follow the Icy Veins WoW Forever zone list (exceptions noted below)
--                   (article of Nov 9th 2026). Capitals are not on that list; they are marked by the game's
--                   own "friendly" label in game, so they are listed from observation.
-- None of the ownership classes has been confirmed in game on a PvP realm: on a Normal realm the
-- game's own label is nil outside capitals. In capitals the label is "friendly" for the player's own
-- faction, which agrees with the table. Subzone exceptions match ENGLISH names only (not localized).
-- Note: the Icy Veins PvP overview says "any zone above level 15 is contested", but its zone list
-- tags Redridge, Duskwood, Wetlands (Alliance) and The Barrens (Horde) as owned. The zone list is used.
--
-- Check or correct a zone: stand in it and type /tpvp zone. For one character only:
--   /tpvp mark alliance|horde|contested|sanctuary|clear
-- Boats and open sea report the whole continent (1414 Kalimdor, 1415 Eastern Kingdoms), deliberately
-- not listed, so they read as unknown. Deeprun Tram reports no map ID (nil), also unknown.
-- Wetlands, Redridge and Duskwood follow Wowhead's WoW Forever map (Contested), not the Icy Veins list.
-- Mount Hyjal, Riverglades, Shen'dralas and Zephras Isle IDs come from Wowhead's map data.

local _, ns = ...

ns.ZONES = {
    -- ===== Alliance-controlled =====
    [1426] = "alliance", -- Dun Morogh (id VERIFIED)
    [1429] = "alliance", -- Elwynn Forest (id VERIFIED)
    [1432] = "alliance", -- Loch Modan (id VERIFIED)
    [1438] = "alliance", -- Teldrassil (id VERIFIED)
    [1453] = "alliance", -- Stormwind City (id VERIFIED; API also says "friendly")
    [1455] = "alliance", -- Ironforge (id VERIFIED; API also says "friendly")
    [1457] = "alliance", -- Darnassus (id VERIFIED; API also says "friendly")
    [1439] = "alliance", -- Darkshore (id VERIFIED)
    [1436] = "alliance", -- Westfall (id unverified)

    -- ===== Horde-controlled =====
    [1411] = "horde",    -- Durotar (id VERIFIED)
    [1412] = "horde",    -- Mulgore (id VERIFIED)
    [1413] = "horde",    -- The Barrens (id VERIFIED)
    [1420] = "horde",    -- Tirisfal Glades (id VERIFIED)
    [1454] = "horde",    -- Orgrimmar (id VERIFIED; API also says "friendly")
    [1456] = "horde",    -- Thunder Bluff (id VERIFIED; API also says "friendly")
    [1458] = "horde",    -- Undercity (id VERIFIED; API also says "friendly")
    [1421] = "horde",    -- Silverpine Forest (id unverified)

    -- ===== Contested =====
    [1434] = "contested", -- Stranglethorn Vale (id VERIFIED, incl. Booty Bay)
    [1445] = "contested", -- Dustwallow Marsh (id VERIFIED)
    -- Eastern Kingdoms
    [1424] = "contested", -- Hillsbrad Foothills (id unverified)
    [1417] = "contested", -- Arathi Highlands (id unverified)
    [1416] = "contested", -- Alterac Mountains (id unverified)
    [1418] = "contested", -- Badlands (id unverified)
    [1435] = "contested", -- Swamp of Sorrows (id unverified)
    [1425] = "contested", -- The Hinterlands (id unverified)
    [1427] = "contested", -- Searing Gorge (id unverified)
    [1419] = "contested", -- Blasted Lands (id unverified)
    [1428] = "contested", -- Burning Steppes (id unverified)
    [1430] = "contested", -- Deadwind Pass (id unverified)
    [1422] = "contested", -- Western Plaguelands (id unverified)
    [1423] = "contested", -- Eastern Plaguelands (id unverified)
    -- Kalimdor
    [1442] = "contested", -- Stonetalon Mountains (id unverified)
    [1440] = "contested", -- Ashenvale (id unverified)
    [1441] = "contested", -- Thousand Needles (id unverified)
    [1443] = "contested", -- Desolace (id unverified)
    [1444] = "contested", -- Feralas (id unverified)
    [1446] = "contested", -- Tanaris (id VERIFIED)
    [1447] = "contested", -- Azshara (id unverified)
    [1448] = "contested", -- Felwood (id unverified)
    [1449] = "contested", -- Un'Goro Crater (id unverified)
    [1451] = "contested", -- Silithus (id unverified)
    [1452] = "contested", -- Winterspring (id unverified)
    [1450] = "contested", -- Moonglade (id VERIFIED; game label nil; was mislabeled Mount Hyjal)
    -- Moved from Alliance (Icy Veins) to contested: Wowhead's WoW Forever map labels all three Contested
    [1437] = "contested", -- Wetlands (id VERIFIED)
    [1433] = "contested", -- Redridge Mountains (id VERIFIED)
    [1431] = "contested", -- Duskwood (id VERIFIED)
    -- Forever zones (IDs from Wowhead's WoW Forever world map data; not yet seen in game)
    [2482] = "contested", -- Mount Hyjal (id unverified; Wowhead tooltip: Contested)
    [2548] = "contested", -- Riverglades (id unverified; Wowhead tooltip: Contested)
    [2652] = "contested", -- Shen'dralas (id unverified; Wowhead tooltip: Contested)
    [2521] = "contested", -- Zephras Isle (id unverified; Wowhead tooltip: Contested)
}

-- Subzone exceptions: ns.SUBZONES[mapID][subzoneName] = class. Empty for now.
ns.SUBZONES = {
    -- [1434] = { ["Booty Bay"] = "sanctuary" },
}
