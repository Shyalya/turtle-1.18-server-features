# Turtle 1.18 Server Features

A small collection of custom server-side patches for the
[r-o-sh/tortoise-wow](https://github.com/r-o-sh/tortoise-wow) mangos core
(`playerbots-integration-gh` branch), built for a private Turtle WoW 1.12
server. Each feature is its own patch file so you can apply only the ones
you want.

**Base commit:** these patches were generated against
[`5e5e40c`](https://github.com/r-o-sh/tortoise-wow/commit/5e5e40c) on the
`playerbots-integration-gh` branch. If your checkout is far ahead of that
commit, `git am` may fail to apply cleanly - see "Updating" below.

## Features

| Patch | What it does |
|---|---|
| [`0001-...world-buffs...`](patches/0001-Restrict-world-buffs-by-zone-and-add-automatic-donat.patch) | Restricts automatic world buffs by zone: Spirit of Zandalar only in Stranglethorn Vale, Warchief's Blessing only for Horde in Crossroads or Orgrimmar, Rallying Cry of the Dragonslayer only for Alliance in Stormwind City. Also adds an `AutoDonationPoints` system that credits real online players (bots excluded) donation points (`shop_coins`) for every full hour played. |
| [`0002-...battleground-queueing...`](patches/0002-Fix-playerbot-battleground-queueing-and-add-a-hard-m.patch) | Fixes playerbots silently failing to actually queue for battlegrounds (bot sessions aren't registered in `sWorld.m_sessions`, so their queue packet never got processed). Bots also get `+pvp` on BG entry so they seek out enemies instead of only reacting when attacked, and WSG/AB matches get a 20-minute hard time limit so bot-heavy matches that never cap objectives don't run forever. |
| [`0003-...beginners-guild...`](patches/0003-Auto-join-new-low-level-players-into-the-configured-.patch) | Auto-joins new, guildless real players (level 5 or below) into a configured "beginners guild" on first login. |

## Requirements

- A checkout of `r-o-sh/tortoise-wow` on the `playerbots-integration-gh`
  branch (or close enough to the base commit above).
- Patches 1 and 3 add new `mangosd.conf` options - see each patch's config
  block for the exact keys/defaults (`AutoWorldBuff.*`,
  `AutoDonationPoints.*`, `BeginnersGuilds`/`BeginnersGuildHorde`/
  `BeginnersGuildAlliance`).

## Applying a patch

```bash
cd /path/to/tortoise-playerbots
git am /path/to/0001-Restrict-world-buffs-by-zone-and-add-automatic-donat.patch
```

Repeat for whichever other patches you want. Then rebuild `mangosd` and
add/adjust the relevant config keys in `mangosd.conf` before restarting.

If `git am` fails to apply cleanly (likely if your checkout has diverged
from the base commit above), try:

```bash
git apply --reject /path/to/the.patch   # applies what it can, leaves .rej files for the rest
```

and resolve the rejected hunks by hand.

## Updating

These patches will be regenerated and re-pushed here whenever the features
get revised. If you already applied an older version, `git log` on your
own checkout for the corresponding commit message and `git rebase` /
re-apply as needed.

## License

Derived from the GPL-licensed tortoise-wow/mangos core - these patches are
provided under the same license (GPLv2 or later).
