# Changelog

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
