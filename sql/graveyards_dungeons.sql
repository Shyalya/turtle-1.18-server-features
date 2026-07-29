-- Graveyard assignments for dungeon zones that have none.
--
-- Apply to the WORLD database, then `reload game_graveyard_zone`.
-- The second half needs tools/add_worldsafelocs_dungeons.py and a restart.
--
-- Turtle splits several instances into multiple *zones* - Scarlet Monastery
-- Library and Graveyard, three Scholomance zones, five Dire Maul wings, three
-- Blackwing Lair zones, six Shadowfang Keep zones - and only the main zone got
-- a game_graveyard_zone row. GetZoneId() at the death position returns the
-- wing, GetClosestGraveYard finds nothing, and RepopAtGraveyard does not
-- teleport: the ghost appears at its own corpse. Real players get no corpse
-- run, and any "resurrect solo in a dungeon" feature silently does nothing.
--
-- Part one: let the wings inherit their main zone's graveyards.

INSERT IGNORE INTO `game_graveyard_zone` (`id`, `ghost_zone`, `faction`)
SELECT g.`id`, q.`target`, g.`faction`
FROM (
    SELECT  209 AS source, 5132 AS target UNION ALL SELECT  209, 5150
    UNION ALL SELECT  209, 5161 UNION ALL SELECT  209, 5169
    UNION ALL SELECT  209, 5173 UNION ALL SELECT  209, 5177   -- Shadowfang Keep
    UNION ALL SELECT  721, 5152 UNION ALL SELECT  721, 5162   -- Gnomeregan
    UNION ALL SELECT  796, 5135 UNION ALL SELECT  796, 5136   -- Scarlet Monastery
    UNION ALL SELECT 2057, 5142 UNION ALL SELECT 2057, 5156
    UNION ALL SELECT 2057, 5165                               -- Scholomance
    UNION ALL SELECT 2557, 5145 UNION ALL SELECT 2557, 5157
    UNION ALL SELECT 2557, 5166 UNION ALL SELECT 2557, 5171
    UNION ALL SELECT 2557, 5175                               -- Dire Maul
    UNION ALL SELECT 2677, 5146 UNION ALL SELECT 2677, 5158
    UNION ALL SELECT 2677, 5167                               -- Blackwing Lair
    UNION ALL SELECT 3428, 5147                               -- Ahn'Qiraj
    UNION ALL SELECT 3457, 5557                               -- Rock of Desolation
    UNION ALL SELECT 2366, 2367                               -- Old Hillsbrad
) q
JOIN `game_graveyard_zone` g ON g.`ghost_zone` = q.`source`;

-- Shadowfang Keep's graveyard was Horde only, so Alliance had none at all -
-- an oddity, every other instance graveyard here is shared. Both sides run it.
UPDATE `game_graveyard_zone` SET `faction` = 0 WHERE `id` = 32;

-- Part two: five Turtle-built dungeons have no graveyard anywhere on their map,
-- so nothing can be inherited. tools/add_worldsafelocs_dungeons.py creates ids
-- 960-964 at each instance entrance (taken from areatrigger_teleport). Run it
-- and restart before applying these rows, or they will be skipped on load.

REPLACE INTO `game_graveyard_zone` (`id`, `ghost_zone`, `faction`) VALUES
    (960, 5723, 0),   -- Lower Karazhan Halls
    (961, 5601, 0),   -- Dragonmaw Retreat
    (961, 5634, 0),   -- Zuluhed's Terrace   (same map)
    (961,  296, 0),   -- South Seas          (same map)
    (961, 4016, 0),   -- Kamio               (same map)
    (962, 5640, 0),   -- Timbermaw Hold
    (963, 5641, 0),   -- Windhorn Canyon
    (964, 5734, 0);   -- Frostmane Hollow

-- Verify: should list no dungeon zone except the three unused ones on map 36.
SELECT a.`entry`, a.`name`, a.`map_id`
FROM `area_template` a
JOIN `map_template` m ON m.`entry` = a.`map_id` AND m.`map_type` IN (1, 2)
LEFT JOIN `game_graveyard_zone` g ON g.`ghost_zone` = a.`entry`
WHERE a.`zone_id` = 0 AND g.`ghost_zone` IS NULL
ORDER BY a.`map_id`;
