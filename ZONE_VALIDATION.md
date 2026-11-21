# Forever War Mode Lite 0.9.1-beta: zone validation

This file is the maintenance record for `Zones.lua`. It keeps two questions apart:

- **Territory classification** (Alliance, Horde, contested): from the Icy Veins WoW Forever zone report, except Wetlands, Redridge Mountains and Duskwood, which follow Wowhead's WoW Forever map (Contested), and the zones that are not on the Icy Veins report (Moonglade, Mount Hyjal, Riverglades, Shen'dralas, Zephras Isle), which follow Wowhead's map. It is not re-derived from Classic or Retail.
- **Map ID** (`uiMapID`): whether the number really is that zone in the Forever client. A verified ID does not by itself prove ownership.

## Coverage summary (calculated from the current `Zones.lua`)

| Item | Value |
|---|---|
| Zones listed | **50** (9 Alliance, 8 Horde, 33 contested, 0 sanctuary) |
| Map IDs verified in Forever | **22** |
| Map IDs unverified | **28** |
| Known missing or unsupported zones | none known; other new Forever zones may exist that nobody has visited yet |
| Subzone exceptions | none (the table is empty on purpose); any later entries match English names only |

Cross-check of the IDs against online data (2026-11-20):

- Warcraft Wiki *UiMapID/Classic* and the data behind Wowhead's *WoW Forever world map* agree with every ID in the table by zone name. This confirms the numbers follow the standard scheme. It does not replace seeing the ID in the Forever client.
- Wowhead's Forever map gives a faction owner only to the starter zones. Its tooltips read Contested for Wetlands, Redridge Mountains, Duskwood, Hillsbrad Foothills, Ashenvale, Stonetalon Mountains, Riverglades, Mount Hyjal, Shen'dralas and Zephras Isle, and Horde for Silverpine Forest.

Map hierarchy concerns:

- At sea or on a boat the client reports the continent map (1414 Kalimdor, 1415 Eastern Kingdoms). These are deliberately not listed, so they read as unknown. `/tpvp report` notes them as continent maps instead of flagging them.
- Deeprun Tram reports no map ID (`nil`), which also reads as unknown.
- `C_Map.GetBestMapForUnit` returned the zone map for every zone and subzone tested. No child-map failure has been observed, so there is no parent-map handling.
- Instances and the game's own `sanctuary` or `combat` labels are checked before the table.

IDs that need in-game testing next: 1416, 1417, 1418, 1419, 1421, 1422, 1423, 1424, 1425, 1427, 1428, 1430, 1435, 1436, 1440, 1441, 1442, 1443, 1444, 1447, 1448, 1449, 1451, 1452, 2482, 2521, 2548, 2652.

## Sources of the territory classifications

- Icy Veins: *Not Sure Where to Level in WoW Forever? Here's Every Zone from 1 to 60*, https://www.icy-veins.com/wow-forever/news/not-sure-where-to-level-in-wow-forever-heres-every-zone-from-1-to-60/ (Nov 9th, 2026; read 2026-11-15). It lists zone ownership by level range, not capitals or map IDs.
- Wowhead: WoW Forever world map, https://www.wowhead.com/forever/world-map (tooltips and map data read 2026-11-20). Used for Wetlands, Redridge Mountains, Duskwood and the zones missing from the Icy Veins list.
- Context only: Icy Veins' *Everything You Need to Know About PvP in World of Warcraft: Forever*, https://www.icy-veins.com/wow-forever/pvp-overview (last updated Sep 19, 2026), says zones above level 15 are contested, which conflicts with the zone report for Redridge, Duskwood and Wetlands. Wowhead's map agrees with that statement for those three.
- The six capitals are classed from in-game observation: the client labels your own capital `friendly`.

## Validation table

| Zone name | Territory classification | Map ID | ID status | ID source | Verification evidence | Notes |
|---|---|---|---|---|---|---|
| Durotar | Horde | 1411 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Horde-character probe log: `zone='Durotar' ... map=1411`; Razor Hill, Valley of Trials, Echo Isles and Darkspear Strand subzones all stayed 1411. |  |
| Mulgore | Horde | 1412 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Tauren probe log: `zone='Mulgore' ... map=1412`; Camp Narache, Red Cloud Mesa, Stonebull Lake, Bloodhoof Village all 1412. |  |
| The Barrens | Horde | 1413 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Horde probe log: `zone='The Barrens' ... map=1413`; The Merchant Coast and Ratchet subzones both 1413. | Ratchet is a subzone with no exception, so it follows the Barrens (Horde). |
| Alterac Mountains | Contested | 1416 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Arathi Highlands | Contested | 1417 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Badlands | Contested | 1418 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Blasted Lands | Contested | 1419 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Tirisfal Glades | Horde | 1420 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Undead probe log: `zone='Tirisfal Glades' ... map=1420`; Deathknell, Brill, Cold Hearth Manor, Ruins of Lordaeron all 1420. |  |
| Silverpine Forest | Horde | 1421 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Western Plaguelands | Contested | 1422 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Eastern Plaguelands | Contested | 1423 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Hillsbrad Foothills | Contested | 1424 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| The Hinterlands | Contested | 1425 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Dun Morogh | Alliance | 1426 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Dwarf probe log: `zone='Dun Morogh' ... map=1426`; Coldridge Valley, Kharanos, North Gate Pass all 1426. |  |
| Searing Gorge | Contested | 1427 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Burning Steppes | Contested | 1428 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Elwynn Forest | Alliance | 1429 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Human probe log: `zone='Elwynn Forest' ... map=1429`. |  |
| Deadwind Pass | Contested | 1430 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Duskwood | Contested | 1431 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | 0.9.1-beta, Alliance, 2026-11-20: `map=1431 cls=contested via zone table`, subzone The Darkened Bank, game label none; the add-on prompted to click the shield. | Class from Wowhead's WoW Forever map (tooltip: Contested). Icy Veins' zone list said Alliance; the two sources disagree. |
| Loch Modan | Alliance | 1432 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Dwarf probe log: `zone='Loch Modan' ... map=1432`. |  |
| Redridge Mountains | Contested | 1433 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | 0.9.1-beta, Alliance, 2026-11-20: `map=1433 cls=contested via zone table`, subzone Three Corners, game label none; the add-on prompted to click the shield. | Class from Wowhead's WoW Forever map (tooltip: Contested). Icy Veins' zone list said Alliance; the two sources disagree. |
| Stranglethorn Vale | Contested | 1434 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Probe logs: `zone='Stranglethorn Vale' ... map=1434`, including Booty Bay, its tavern and the Old Port Authority. The tooltip also showed `Contested (zone table)` there. | Booty Bay (neutral town) has no exception and follows the zone. |
| Swamp of Sorrows | Contested | 1435 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Westfall | Alliance | 1436 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Wetlands | Contested | 1437 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Dwarf probe log: `zone='Wetlands' sub='Dun Algaz' ... map=1437`. Zone report of 2026-11-17: map 1437, Menethil Harbor and Baradin Bay, game label none. 0.9.1-beta, 2026-11-20: `map=1437 cls=contested via zone table` and the add-on prompted to click the shield. | Class from Wowhead's WoW Forever map (tooltip: Contested). Icy Veins' zone list said Alliance; the two sources disagree. The earlier boat-travel reading of 1415 was the Eastern Kingdoms continent map, not Wetlands. |
| Teldrassil | Alliance | 1438 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | First Alliance probe log: Teldrassil / Shadowglen, map 1438. | Verified from the first diagnostic log. |
| Darkshore | Alliance | 1439 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Zone report of 2026-11-17 (Alliance): map 1439, Auberdine, Mist's Edge, game label none. |  |
| Ashenvale | Contested | 1440 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Thousand Needles | Contested | 1441 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Stonetalon Mountains | Contested | 1442 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Desolace | Contested | 1443 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Feralas | Contested | 1444 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Dustwallow Marsh | Contested | 1445 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Combat-test probe log: Dustwallow Marsh, map 1445. Zone report of 2026-11-17: map 1445 (Theramore Isle). |  |
| Tanaris | Contested | 1446 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Zone report of 2026-11-17 (Alliance): map 1446, Gadgetzan, Steamwheedle Port, game label none. |  |
| Azshara | Contested | 1447 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Felwood | Contested | 1448 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Un'Goro Crater | Contested | 1449 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Moonglade | Contested | 1450 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | 0.9.1-beta, druid on a Roleplaying PvP realm, 2026-11-20: `Moonglade / Nighthaven mapID=1450 apiLabel=nil`, class contested via zone table (the character was already flagged). | Moonglade. Earlier versions labeled this ID Mount Hyjal by mistake. Neither Wowhead's map data nor the game's own label (nil, also on the RPPVP realm) gives an owner for Moonglade; contested is an assumption. |
| Silithus | Contested | 1451 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Winterspring | Contested | 1452 | Unverified | Warcraft Wiki UiMapID/Classic and Wowhead Forever map data agree; not yet seen in game | None yet | Test next. |
| Stormwind City | Alliance | 1453 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Human probe log: `zone='Stormwind City' ... pvpType=friendly map=1453`. | Capital. Not on the Icy Veins zone report; classified from the in-game `friendly` label for the player's own faction. |
| Orgrimmar | Horde | 1454 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Horde probe log: `zone='Orgrimmar' ... pvpType=friendly map=1454`. | Capital. Not on the Icy Veins zone report; classified from the in-game `friendly` label for the player's own faction. |
| Ironforge | Alliance | 1455 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Human probe log: `zone='Ironforge' ... pvpType=friendly map=1455`. | Capital. Not on the Icy Veins zone report; classified from the in-game `friendly` label for the player's own faction. |
| Thunder Bluff | Horde | 1456 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Tauren probe log: `zone='Thunder Bluff' ... pvpType=friendly map=1456`. | Capital. Not on the Icy Veins zone report; classified from the in-game `friendly` label for the player's own faction. |
| Darnassus | Alliance | 1457 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Zone report of 2026-11-17 (Alliance): map 1457, label `friendly`. | Capital. Not on the Icy Veins zone report; classified from the in-game `friendly` label for the player's own faction. |
| Undercity | Horde | 1458 | **Verified** | Observed in WoW Forever (diagnostic logs or zone report) | Undead probe log: `zone='Undercity' ... pvpType=friendly map=1458`. | Capital. Not on the Icy Veins zone report; classified from the in-game `friendly` label for the player's own faction. |
| Mount Hyjal | Contested | 2482 | Unverified | Wowhead WoW Forever map data only; not checked in game | None yet | Not in the Classic ID scheme. ID taken from Wowhead's WoW Forever map data; not yet seen in game. Wowhead tooltip: Contested. |
| Zephras Isle | Contested | 2521 | Unverified | Wowhead WoW Forever map data only; not checked in game | None yet | Not in the Classic ID scheme. ID taken from Wowhead's WoW Forever map data; not yet seen in game. Wowhead tooltip: Contested, level 3-12. |
| Riverglades | Contested | 2548 | Unverified | Wowhead WoW Forever map data only; not checked in game | None yet | Not in the Classic ID scheme. ID taken from Wowhead's WoW Forever map data; not yet seen in game. Wowhead tooltip: Contested, level 36-44. |
| Shen'dralas | Contested | 2652 | Unverified | Wowhead WoW Forever map data only; not checked in game | None yet | Not in the Classic ID scheme. ID taken from Wowhead's WoW Forever map data; not yet seen in game. Wowhead tooltip: Contested. |

## How to validate a zone ID

1. Enter the zone (a step just inside the border is enough).
2. Run `/tpvp zone`.
3. Note the zone name and the `mapID` it prints.
4. Compare it with the table above and with `Zones.lua`.
5. If it matches, the ID is correct for Forever. If not, the zone is wrong or missing.
6. Send the report below. `/tpvp report` produces the same data for every zone you have visited.

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

