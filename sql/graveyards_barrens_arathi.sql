-- Graveyard assignments for The Barrens and Arathi Highlands.
--
-- Apply to the WORLD database, then `reload game_graveyard_zone` (no restart
-- needed for this file - the DBC tool below does need one).
--
-- The Barrens (zone 17) had NO graveyard mapping at all. When a zone has no
-- entry, ObjectMgr::GetClosestGraveYard returns nullptr and RepopAtGraveyard
-- does not teleport, so the ghost appears at its own corpse. A character that
-- dies among the guards in The Crossroads therefore releases right back into
-- them and dies again - an endless loop that produced literal piles of bones
-- around the flight master. This hits real players too, not just bots.
--
-- Arathi Highlands (zone 45) had a single graveyard shared by both factions
-- (faction 0), sitting 170 yards from Refuge Pointe - so Horde players woke up
-- next to an Alliance town guarded by level 41-45 defenders.
--
-- Graveyard ids are this server's WorldSafeLocs.dbc (174 entries, ids 1-174).
-- Check yours before applying:
--   9   The Barrens, The Crossroads   (Horde town)
--   50  The Barrens, Camp Taurajo     (Horde town)
--   51  The Barrens, Ratchet          (neutral goblin town)
--   34  Arathi Highlands              (next to Refuge Pointe, Alliance)
--   115 Arathi Basin - Horde Exit     (Hammerfall outpost, 18 Horde guards)
--
-- faction: 0 = both, 67 = Horde, 469 = Alliance

-- The Barrens: Horde keeps its two town graveyards, everyone else gets Ratchet.
REPLACE INTO `game_graveyard_zone` (`id`, `ghost_zone`, `faction`) VALUES
    ( 9, 17,  67),
    (50, 17,  67),
    (51, 17,   0);

-- Arathi Highlands: split the shared graveyard by faction.
UPDATE `game_graveyard_zone` SET `faction` = 469 WHERE `ghost_zone` = 45 AND `id` = 34;
REPLACE INTO `game_graveyard_zone` (`id`, `ghost_zone`, `faction`) VALUES
    (115, 45, 67);

-- Verify
SELECT g.`ghost_zone`, a.`name`, g.`id` AS graveyard,
       CASE g.`faction` WHEN 0 THEN 'both' WHEN 67 THEN 'Horde' WHEN 469 THEN 'Alliance' END AS available_to
FROM `game_graveyard_zone` g
JOIN `area_template` a ON a.`entry` = g.`ghost_zone`
WHERE g.`ghost_zone` IN (17, 45)
ORDER BY g.`ghost_zone`, g.`id`;
