-- Required by patch 0001 (AutoDonationPoints).
-- Run against your LOGIN database (the one holding `account` and `shop_coins`,
-- e.g. turtle_logon), NOT the world or character database.
--
-- Stores how much online time each account has accumulated toward its next
-- donation point. Without this table the feature still runs, but progress
-- lives in memory only and resets to zero on every server restart.

CREATE TABLE IF NOT EXISTS `donation_point_progress` (
  `account_id`     INT UNSIGNED NOT NULL PRIMARY KEY,
  `accumulated_ms` INT UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
