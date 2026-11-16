# Forever War Mode Lite 0.9.0-beta: zone validation

This file is the maintenance record for `Zones.lua`. It keeps two questions apart:

- **Territory classification** (Alliance, Horde, contested): chosen from the Icy Veins WoW Forever zone report. It is kept as is and is not re-derived from Classic, Retail or any other source.
- **Map ID** (`uiMapID`): whether the number really is that zone in the Forever client. This is what still needs testing. A verified ID does not by itself prove ownership.

## Coverage summary (calculated from the current `Zones.lua`)

| Item | Value |
|---|---|
| Zones listed | **46** (12 Alliance, 8 Horde, 26 contested, 0 sanctuary) |
| Map IDs verified in Forever | **16** |
| Map IDs unverified | **30** |
| Known missing or unsupported zones | Riverglades, Shen'dralas, Zephras Isle (on the Icy Veins report, map ID unknown, so they are not listed and read as unknown) |
| Subzone exceptions | none (the table is empty on purpose); any later entries match English names only |

Map hierarchy concerns:

- At sea or on a boat the client reports the continent map (1414 Kalimdor, 1415 Eastern Kingdoms). These are deliberately not listed, so they read as unknown.
- Deeprun Tram reports no map ID (`nil`), which also reads as unknown.
- `C_Map.GetBestMapForUnit` returned the zone map for every zone and subzone tested. No child-map failure has been observed, so there is no parent-map handling.
- Instances and the game's own `sanctuary` or `combat` labels are checked before the table.

IDs that need in-game testing next: 1416, 1417, 1418, 1419, 1421, 1422, 1423, 1424, 1425, 1427, 1428, 1430, 1431, 1433, 1435, 1436, 1439, 1440, 1441, 1442, 1443, 1444, 1446, 1447, 1448, 1449, 1450, 1451, 1452, 1457.

## Source of the territory classifications

- Report: *Not Sure Where to Level in WoW Forever? Here's Every Zone from 1 to 60* (Icy Veins), https://www.icy-veins.com/wow-forever/news/not-sure-where-to-level-in-wow-forever-heres-every-zone-from-1-to-60/
- Date shown on the page: Nov 9th, 2026 (author shown as Emma). Read on 2026-11-15.
- The report lists zone ownership by level range. It does not list capital cities or map IDs.
- Context only, not used for classes: Icy Veins' *Everything You Need to Know About PvP in World of Warcraft: Forever*, https://www.icy-veins.com/wow-forever/pvp-overview (last updated Sep 19, 2026). It says zones above level 15 are contested, which conflicts with the zone report for Redridge, Duskwood, Wetlands and The Barrens. The zone report is used.
- The six capitals are classed from in-game observation: the client labels your own capital `friendly`.

## Validation table

| Zone name | Territory classification | Map ID | ID status | ID source | Verification evidence | Notes |
|---|---|---|---|---|---|---|
| Durotar | Horde | 1411 | **Verified** | Observed in WoW Forever (diagnostic logs) | Horde-character diagnostic log: `ZONE_CHANGED_NEW_AREA zone='Durotar' ... map=1411`; Razor Hill, Valley of Trials, Echo Isles and Darkspear Strand subzones all stayed 1411. |  |
| Mulgore | Horde | 1412 | **Verified** | Observed in WoW Forever (diagnostic logs) | Tauren diagnostic log: `zone='Mulgore' ... map=1412`; Camp Narache, Red Cloud Mesa, Stonebull Lake, Bloodhoof Village all 1412. |  |
| The Barrens | Horde | 1413 | **Verified** | Observed in WoW Forever (diagnostic logs) | Horde diagnostic log: `zone='The Barrens' ... map=1413`; The Merchant Coast and Ratchet subzones both 1413. | Ratchet is a subzone with no exception, so it follows the Barrens (Horde). |
| Alterac Mountains | Contested | 1416 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Arathi Highlands | Contested | 1417 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Badlands | Contested | 1418 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Blasted Lands | Contested | 1419 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Tirisfal Glades | Horde | 1420 | **Verified** | Observed in WoW Forever (diagnostic logs) | Undead diagnostic log: `zone='Tirisfal Glades' ... map=1420`; Deathknell, Brill, Cold Hearth Manor, Ruins of Lordaeron all 1420. |  |
| Silverpine Forest | Horde | 1421 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Western Plaguelands | Contested | 1422 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Eastern Plaguelands | Contested | 1423 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Hillsbrad Foothills | Contested | 1424 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| The Hinterlands | Contested | 1425 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Dun Morogh | Alliance | 1426 | **Verified** | Observed in WoW Forever (diagnostic logs) | Dwarf diagnostic log: `zone='Dun Morogh' ... map=1426`; Coldridge Valley, Kharanos, North Gate Pass all 1426. |  |
| Searing Gorge | Contested | 1427 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Burning Steppes | Contested | 1428 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Elwynn Forest | Alliance | 1429 | **Verified** | Observed in WoW Forever (diagnostic logs) | Human diagnostic log: `zone='Elwynn Forest' ... map=1429`. |  |
| Deadwind Pass | Contested | 1430 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Duskwood | Alliance | 1431 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Loch Modan | Alliance | 1432 | **Verified** | Observed in WoW Forever (diagnostic logs) | Dwarf diagnostic log: `zone='Loch Modan' ... map=1432`. |  |
| Redridge Mountains | Alliance | 1433 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Stranglethorn Vale | Contested | 1434 | **Verified** | Observed in WoW Forever (diagnostic logs) | Diagnostic logs: `zone='Stranglethorn Vale' ... map=1434`, including Booty Bay, its tavern and the Old Port Authority. The tooltip also showed `Contested (zone table)` there. | Booty Bay (neutral town) has no exception and follows the zone. |
| Swamp of Sorrows | Contested | 1435 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Westfall | Alliance | 1436 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Wetlands | Alliance | 1437 | **Verified** | Observed in WoW Forever (diagnostic logs) | Dwarf diagnostic log: `zone='Wetlands' sub='Dun Algaz' ... map=1437`. | The earlier boat-travel reading of 1415 was the Eastern Kingdoms continent map, not Wetlands. |
| Teldrassil | Alliance | 1438 | **Verified** | Observed in WoW Forever (diagnostic logs) | First Alliance diagnostic log: Teldrassil / Shadowglen, map 1438. | Verified from the first diagnostic log. |
| Darkshore | Alliance | 1439 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Ashenvale | Contested | 1440 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Thousand Needles | Contested | 1441 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Stonetalon Mountains | Contested | 1442 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Desolace | Contested | 1443 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Feralas | Contested | 1444 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Dustwallow Marsh | Contested | 1445 | **Verified** | Observed in WoW Forever (diagnostic logs) | Combat-test diagnostic log: Dustwallow Marsh, map 1445. |  |
| Tanaris | Contested | 1446 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Azshara | Contested | 1447 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Felwood | Contested | 1448 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Un'Goro Crater | Contested | 1449 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Mount Hyjal | Contested | 1450 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Silithus | Contested | 1451 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Winterspring | Contested | 1452 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Test next. |
| Stormwind City | Alliance | 1453 | **Verified** | Observed in WoW Forever (diagnostic logs) | Human diagnostic log: `zone='Stormwind City' ... pvpType=friendly map=1453`. | Capital. Not on the Icy Veins zone report; classified from the in-game `friendly` label for the player's own faction. |
| Orgrimmar | Horde | 1454 | **Verified** | Observed in WoW Forever (diagnostic logs) | Horde diagnostic log: `zone='Orgrimmar' ... pvpType=friendly map=1454`. | Capital. Not on the Icy Veins zone report; classified from the in-game `friendly` label for the player's own faction. |
| Ironforge | Alliance | 1455 | **Verified** | Observed in WoW Forever (diagnostic logs) | Human diagnostic log: `zone='Ironforge' ... pvpType=friendly map=1455`. | Capital. Not on the Icy Veins zone report; classified from the in-game `friendly` label for the player's own faction. |
| Thunder Bluff | Horde | 1456 | **Verified** | Observed in WoW Forever (diagnostic logs) | Tauren diagnostic log: `zone='Thunder Bluff' ... pvpType=friendly map=1456`. | Capital. Not on the Icy Veins zone report; classified from the in-game `friendly` label for the player's own faction. |
| Darnassus | Alliance | 1457 | Unverified | Retail uiMapID scheme, recalled from memory; not checked against Forever | None yet | Capital. An earlier log labeled Darnassus `friendly`, but its map ID was not captured, so the ID is still unverified. Not on the Icy Veins zone report. |
| Undercity | Horde | 1458 | **Verified** | Observed in WoW Forever (diagnostic logs) | Undead diagnostic log: `zone='Undercity' ... pvpType=friendly map=1458`. | Capital. Not on the Icy Veins zone report; classified from the in-game `friendly` label for the player's own faction. |

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

