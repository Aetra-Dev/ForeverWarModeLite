# Changelog

## 0.9.1-beta
Zone data update. No change to clicks, modes, icons or saved settings.

- Wetlands, Redridge Mountains and Duskwood are now **contested** (Alliance players now get the glow and reminders there). The previous Alliance class came from the Icy Veins zone list; Wowhead's WoW Forever map labels all three Contested.
- Added Mount Hyjal, Riverglades, Shen'dralas and Zephras Isle as contested. Their map IDs come from Wowhead's map data and are not yet confirmed in game.
- Fixed ID 1450: it is **Moonglade**, not Mount Hyjal. It stays contested.
- 22 of 50 map IDs are now verified in the Forever client (added Darkshore, Tanaris, Darnassus, Duskwood, Redridge Mountains and Moonglade from tester reports). Every ID also matches the Warcraft Wiki and Wowhead lists by name.
- `/tpvp report`: continent maps (1414, 1415, reported at sea or on boats) are noted as continent maps instead of flagged, and zone names now come from the map data, so a building such as "Lion's Pride Inn" no longer replaces the zone name.

## 0.9.0-beta (first public release)
Beta. Not a validated 1.0 release.

- Public name: Forever War Mode Lite, by Aetra, MIT licensed. The folder, saved-variable names and `/tpvp` keep the internal TerritoryPvP name, so settings carry over.
- Faction shield with glow, gold chat line and optional raid-warning style screen alert.
- Click = PvP on (or cancel a countdown). Shift-click = PvP deactivation, only while permanently flagged. Shift-click never activates PvP, and a plain click never starts deactivation. Right-click menu, Ctrl-drag.
- The click rules hold in combat for both the shield and the minimap icon, and with both the key-down and key-up click settings (tested in game).
- Automatic PvP and Manual PvE override, saved per character. The Manual PvE popup waits until combat ends.
- Zone table of 46 maps from the Icy Veins WoW Forever zone report. 16 map IDs are verified in the Forever client; 30 are not yet.
- `/tpvp zone`, `/tpvp mark`, and `/tpvp report` for checking and reporting zones.
- Five selectable icons with per-icon tuning commands.
- Saved variables are checked at load: wrong-type values are replaced, valid values are never touched.
