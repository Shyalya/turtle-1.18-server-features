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
| [`0001-...world-buffs...`](patches/0001-Restrict-world-buffs-by-zone-and-add-automatic-donat.patch) | Restricts automatic world buffs by zone: Spirit of Zandalar only in Stranglethorn Vale, Warchief's Blessing only for Horde in Crossroads or Orgrimmar, Rallying Cry of the Dragonslayer only for Alliance in Stormwind City. Also adds an `AutoDonationPoints` system that credits real online players (bots excluded) donation points (`shop_coins`) for every full hour played. Timer behavior refined by patch 0010 below. |
| [`0002-...battleground-queueing...`](patches/0002-Fix-playerbot-battleground-queueing-and-add-a-hard-m.patch) | Fixes playerbots silently failing to actually queue for battlegrounds (bot sessions aren't registered in `sWorld.m_sessions`, so their queue packet never got processed). Bots also get `+pvp` on BG entry so they seek out enemies instead of only reacting when attacked, and WSG/AB matches get a 20-minute hard time limit so bot-heavy matches that never cap objectives don't run forever. |
| [`0003-...beginners-guild...`](patches/0003-Auto-join-new-low-level-players-into-the-configured-.patch) | Auto-joins new, guildless real players (level 5 or below) into a configured "beginners guild" on first login. |
| [`0004-...flag-carriers-freezing...`](patches/0004-Fix-WSG-flag-carriers-freezing-forever-when-both-fla.patch) | Fixes WSG flag-carrier bots freezing forever in the middle of the map when the enemy also holds our own flag - they now always head straight to base instead of a "hiding spot" that a separate safety guard then refused to ever leave. |
| [`0005-...proactively-fetching...`](patches/0005-Stop-WSG-bots-from-proactively-fetching-the-enemy-fl.patch) | Bots no longer walk to the enemy flag spawn on their own initiative to grab it (they patrol instead) - they still defend their own carrier and chase down whoever's holding our flag. Behavior change, not a bug fix. Refined by patch 0009 below. |
| [`0006-...never-fighting...`](patches/0006-Fix-bots-never-fighting-each-other-in-battlegrounds.patch) | Fixes bots never initiating combat against each other in battlegrounds - the "enemy player near" trigger was only wired into the combat engine, which an idle bot never entered on its own, so two idle enemy bots standing next to each other never fought until a human player attacked one first. |
| [`0007-...flag-carrier-they...`](patches/0007-Fix-bots-never-attacking-the-enemy-flag-carrier-they.patch) | Fixes bots chasing the enemy flag carrier forever without ever attacking - `AttackEnemyFlagCarrierAction::isUseful()` checked the wrong unit's aura (a copy-paste bug), requiring the *attacking* bot to already be a flag carrier itself instead of checking the *target*. |
| [`0008-...graveyard-resurrection...`](patches/0008-Fix-WSG-and-AB-graveyard-resurrection-using-stale-va.patch) | ⚠️ **Environment-specific, read before applying.** Fixes "Release Spirit" leaving you stuck at your corpse in WSG/AB instead of teleporting to a graveyard. Both battlegrounds hardcode the standard vanilla `WorldSafeLocs.dbc` graveyard IDs, but *this* server's DBC (extracted from the Turtle WoW 1.18 client, only 174 entries total) doesn't have them under those IDs - the same locations exist under different IDs on this specific DBC. **This patch's replacement IDs are only correct if your `WorldSafeLocs.dbc` is missing the same entries in the same way.** Check first: if `bg->GetClosestGraveYard()` already works for you, don't apply this - it will silently point at the wrong (or a valid but unrelated) location in your DBC. |
| [`0009-...their-own-tea...`](patches/0009-Let-bots-fetch-the-enemy-WSG-flag-when-their-own-tea.patch) | Refines patch 0005: an all-bot team now goes back to actively fetching the enemy flag, but *only* when their own team has zero real players - a solo human vs. an all-bot enemy team no longer wins by default just because the enemy never tries to cap. Matches with humans on both sides are unaffected. Apply together with 0005. |
| [`0010-...independent-per-buff-timers...`](patches/0010-Split-world-buffs-into-independent-per-buff-timers.patch) | Splits the single shared world-buff timer from patch 0001 into one independent timer per buff, so Zandalar/Warchief's Blessing/Dragonslayer no longer all become available at the exact same instant. Adds a short "first roll after (re)start" interval (default 10min-2h) separate from the normal ongoing interval (default changed from 2h-3h to 1h-3h), so a server that restarts often doesn't effectively delay the buffs by a full interval every time. Apply on top of 0001. |

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
