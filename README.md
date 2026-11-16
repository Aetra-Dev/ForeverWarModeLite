# Forever War Mode Lite 0.9.0-beta

**Forever War Mode Lite brings War Mode-inspired, territory-aware PvP controls to WoW Forever Normal (PvE) realms.**

By **Aetra**. MIT licensed. This is a **beta**, not a fully validated 1.0 release.

Source code, releases and bug reports: https://github.com/Aetra-Dev/ForeverWarModeLite

This add-on is not affiliated with, endorsed by, or supported by Blizzard Entertainment. World of Warcraft and related names are trademarks of Blizzard Entertainment.

## What it does, and what it does not
- **PvP activation and deactivation need your click.** The client does not let add-ons run protected PvP actions, so the add-on cannot flag you automatically when you change zones. It shows your PvP state and tells you when your territory calls for PvP.
- **Automatic mode** gives territory-aware visual reminders: a glow on the shield and a gold chat line when you are in contested or enemy territory and not flagged. An optional screen alert is available. The glow stays on while that is true, including while PvP is deactivating (a click would cancel the countdown).
- **Manual PvE override** suppresses the automatic-mode reminders and glow. In contested territory it offers a popup to resume Automatic mode, once per entry and never during combat.
- **Settings are saved separately for each character.**
- **PvP deactivation follows the game's normal rules:** after you turn PvP off there is the game's usual countdown (about five minutes), during which you are still flagged.
- It does **not** reproduce Retail War Mode's separate population layers, PvP talents or rewards.

## Controls
| Action | Result |
|---|---|
| Click | Turns PvP **on** when you are not permanently flagged. During a deactivation countdown it cancels the countdown and keeps you flagged. Does nothing while you are permanently flagged (it prints a hint). |
| Shift-click | Requests PvP **deactivation**, only while you are permanently flagged. While you are unflagged it does nothing and never activates PvP. During the countdown it does nothing and never reactivates PvP. Both cases print a hint. |
| Right-click | Settings menu: Automatic PvP / Manual PvE, reminders, chat alert, screen alert. |
| Ctrl-drag | Move the shield or the minimap icon. |

The game's `/pvp` command is a toggle, so the add-on arms only the click whose result matches what it promises and blanks the other. The shield and the minimap icon behave the same way, including in combat. The shield is gray when you are not flagged and colored when you are, with the Alliance or Horde emblem for your faction.

Tested in game: both the "cast on key down" and the key-up click setting, and both the shield and the minimap icon, in and out of combat.

## Install (first time)
1. Download `ForeverWarModeLite-0.9.0-beta.zip` and extract it. You get a folder named `TerritoryPvP`.
2. Copy that folder into your WoW Forever add-ons folder:
   `...\World of Warcraft\_forever_\Interface\AddOns\`
   The path must end `...\AddOns\TerritoryPvP\TerritoryPvP.toc`. If there is a second `TerritoryPvP` folder inside it, move the inner one up.
3. Close the game completely, start it again, and at the character-select screen click **AddOns**.
4. Tick **Forever War Mode Lite** (also tick "Load out of date AddOns" if the client has updated).
5. Log in. The shield appears near the middle of the screen; Ctrl-drag it where you want it.

The folder keeps the name `TerritoryPvP` on purpose, so saved settings carry over between versions.

## Commands (`/tpvp`)
| Command | What it does |
|---|---|
| *(none)* / `status` | mode, territory and flag |
| `auto`, `pve` | Automatic PvP / Manual PvE |
| `reminders`, `alert`, `screen` `[on\|off]` | reminder popup, gold chat line, screen alert (`screen test` shows a sample) |
| `zone` | map ID, zone name, the game's label and the class used |
| `mark alliance\|horde\|contested\|sanctuary\|clear` | fix the current zone for this character |
| `report [clear]` | window with every zone you have visited, ready to copy and send |
| `icons`, `icon <n\|auto>` | choose an icon (default 3) |
| `size`, `glowsize`, `nudge`, `glownudge`, `iconnudge`, `crop`, `tune [reset]` | per-icon appearance tuning |
| `guard on\|off` | secure in-combat click guard |
| `debug`, `reset` | diagnostics (debug is off by default); reset positions |

## The zone data
Zone ownership (Alliance, Horde, contested) comes from the **Icy Veins WoW Forever zone report** ("Not Sure Where to Level in WoW Forever? Here's Every Zone from 1 to 60", dated Nov 9, 2026). It is not historical Classic data. Capital cities are not on that report and are classed from the game's own "friendly" label.

The numeric map IDs are still being verified: **16 of 46** have been confirmed in the Forever client and **30** come from another client's ID scheme and may be wrong. Zones that are not listed, open sea, boats and Deeprun Tram count as unknown and never trigger a prompt. The full table with evidence is in `ZONE_VALIDATION.md` in the GitHub repository.

## Beta limitations
- Flagging always needs a click.
- Ownership is not confirmed in game: on Normal realms the client gives no territory label outside capitals.
- Not yet tested: entering enemy territory, most contested zones, non-English clients, the Hardcore, RP and PvP rulesets, and the `/tpvp report` window. It has only been tested on the Normal ruleset.
- In combat the add-on predicts the result of each click, so if a click does not register it can be out of step until combat ends.
- After a `/reload` in combat the shield appears only when combat ends.
- Open sea, boats and Deeprun Tram read as unknown. Subzone exceptions, if added later, match English names only.

## Reporting problems and wrong zones
Open an issue on the GitHub Issues page (https://github.com/Aetra-Dev/ForeverWarModeLite/issues), or comment on the add-on's CurseForge or WoWInterface page. For a zone problem, stand in the zone and run `/tpvp zone`, or run `/tpvp report`, press Ctrl+C and paste the text. Please include:

```text
Forever War Mode Lite - Zone Report

Add-on version:
Character faction:
Zone name:
Subzone name:
Reported map ID:
Expected territory classification:
Actual add-on classification:
Diagnostic output:
Additional notes:
```

No character name, account or realm is needed.

## License
MIT License, Copyright (c) 2026 Aetra. See the `LICENSE` file. The add-on contains no third-party code and does not include any game art: icons are loaded from the game's own files by path.
