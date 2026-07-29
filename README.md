# Turtle 1.18 Server Features

Custom server-side patches for the
[r-o-sh/tortoise-wow](https://github.com/r-o-sh/tortoise-wow) mangos core
(`playerbots-integration-gh` branch), built for a private Turtle WoW 1.12
server running against a 1.18 client.

Each patch is self-contained — pick the ones you want, in any combination.
There are no "fix the previous patch" follow-ups; every patch reflects its
final state.

**Base commit:** generated against
[`5e5e40c`](https://github.com/r-o-sh/tortoise-wow/commit/5e5e40c) on the
`playerbots-integration-gh` branch.

## Features

| Patch | What it does | Extra steps |
|---|---|---|
| [`0001`](patches/0001-Add-world-buffs-automatic-donation-points-and-fix-th.patch) **World buffs, donation points, shop fix** | Periodic world buffs, restricted by zone and faction: Spirit of Zandalar (Stranglethorn Vale), Warchief's Blessing (Horde, Crossroads/Orgrimmar), Rallying Cry of the Dragonslayer (Alliance in Stormwind, Horde in Orgrimmar). Each buff runs on its own timer so they don't all fire at once, with a shorter first interval after a restart. Plus `AutoDonationPoints`: real players (bots and the Discord bridge excluded) earn shop currency per hour online, persisted across restarts. Also fixes the Donation Rewards window showing only the "About" tab — the client expects a `parentId` field the server never sent, which threw a Lua error that aborted category parsing on the first entry. | config + SQL |
| [`0002`](patches/0002-Auto-join-new-low-level-players-into-the-configured-.patch) **Beginners guild** | Auto-joins new, guildless real players (level ≤ 5) into a configured welcome guild on first login. | config |
| [`0003`](patches/0003-Fix-playerbot-battlegrounds-queueing-combat-and-flag.patch) **Playerbot battlegrounds** | Fixes playerbots silently failing to queue for battlegrounds at all (their join packet was never processed); three separate reasons they never fought (attack trigger only wired into a combat engine idle bots never entered, target list only ever saw units already attacking them, flag-carrier attack check tested the wrong unit's aura); and flag carriers freezing forever mid-map. Bots no longer fetch the enemy flag on their own initiative — unless their own team has no real players, so solo-vs-bots matches aren't a walkover. Adds a 20-minute hard match cutoff. | – |
| [`0004`](patches/0004-Fix-WSG-and-AB-graveyard-resurrection-using-stale-va.patch) **BG graveyard resurrection** ⚠️ | Fixes "Release Spirit" leaving you stuck at your corpse in WSG/AB instead of teleporting to a graveyard. **Environment-specific — read below before applying.** | – |
| [`0005`](patches/0005-Keep-playerbots-out-of-enemy-faction-territory.patch) **Bots out of enemy territory** | Three separate routes into enemy settlements: taxi destinations drawn from *every* node when `AllFlightPaths = 1`; rpg triggers walking bots to enemy flight masters they can never use; and travel destinations only faction checked per NPC, never by location, so gather/skin/mine nodes inside enemy towns were fair game. | – |


### Graveyards (SQL + a DBC tool, no patch)

Two data defects that make characters - bots *and* real players - die in a loop.

[`sql/graveyards_barrens_arathi.sql`](sql/graveyards_barrens_arathi.sql) fixes
the mapping. **The Barrens had no graveyard entry at all**; when a zone has
none, `GetClosestGraveYard` returns nullptr and `RepopAtGraveyard` does not
teleport, so the ghost appears at its own corpse. Die among the guards in The
Crossroads and you release straight back into them - which is exactly what
produced the piles of bones there. Arathi Highlands had one graveyard shared by
both factions, 170 yards from the Alliance town Refuge Pointe.

[`tools/add_worldsafelocs.py`](tools/add_worldsafelocs.py) restores three
graveyards the world database references but no shipped DBC contains: 934, 937
and 950 for the Turtle high elf zones Quel'Thalas, Amani'Alor and Alah'Thalas.
Both the server's `WorldSafeLocs.dbc` and the client copy inside `patch-9.mpq`
stop at id 174, so those zones silently had no graveyard. The coordinates are
recovered from `game_tele` (`alahthalasgraveyard`, `amanialorgraveyard`).
Requires a server restart - DBCs are read at startup only.

To find the same class of bug on your own server, watch the startup log for
`has record for not existing graveyard`, and look for zones with no
`game_graveyard_zone` row at all.

### Playerbot travel nodes (SQL only, no patch)

[`sql/playerbot_bypass_crossroads.sql`](sql/playerbot_bypass_crossroads.sql)
adds a ground link that routes around The Crossroads instead of through it.

The bot travel graph has three nodes inside that Horde town, one of them
(`The Crossroads flightMaster`) sitting *on* the flight master, 21 yards from a
guard. Every ground route across the Barrens went through them. The new link
between `The Barrens` and `The Barrens spirithealer` keeps at least 84 yards
from every guard spawn and 90 from every patrol waypoint.

It wins on cost without any code change: the in-town links carry
`max_creature_2 = 55`, which the existing `factionAnnoyance` turns into roughly
a 7x penalty for a level 24 Alliance bot, while the bypass carries 0. Higher
level bots still take the shorter road through town, which is fine - they
survive the level 40 guards.

Optional, and specific to this node graph. Check your own node ids first.

### Guild bank trigger (SQL only, no patch)

[`sql/guildbank_trigger.sql`](sql/guildbank_trigger.sql) makes right-clicking
the guild vault keepers actually open the guild bank. No code change involved —
it is a pure data fix, independent of every patch above.

The bank UI ships client-side in `Turtle_GuildBankUI` (patch-8/9). It hooks
`GOSSIP_SHOW` and opens only when the NPC's **greeting text** is exactly
`GUILD_BANK_TRIGGER`. Older client builds matched the NPC *name* instead, via
`GUILD_BANK_NPC_TITLE` — that global no longer exists, so renaming the NPCs
does nothing. Server-side the vault keepers ship with `gossip_menu_id = 0` and
therefore only ever send the default greeting.

The string is never visible: the addon sets the gossip frame to alpha 0 in the
same handler.

Two things to know before blaming the trigger:

- The guild bank must be **unlocked** first — 2000 gold, guild master only,
  standing next to the NPC. Until then the UI opens with no tabs and throws
  `'for' limit must be a number`.
- Every guild bank action requires the player to be within
  `INTERACTION_DISTANCE` of entry 80917 (Alliance) or 80918 (Horde). Out of
  range, the server drops the request silently.

Per-tab access is set by **right-clicking a tab icon** as guild master. The
selected rank is the lowest one still allowed. Withdrawing *gold* is separate
and hardcoded to rank ≤ 1 (guild master and officer).

Requires a server restart: `broadcast_text` has no reload command.

### ⚠️ About patch 0004

Both battlegrounds hardcode the standard vanilla `WorldSafeLocs.dbc`
graveyard IDs. On this server's DBC (extracted from a Turtle WoW 1.18
client, 174 entries total) those IDs simply don't exist, so every lookup
returned NULL. The same graveyard locations *do* exist, just under
different IDs, and this patch swaps in the ones that matched.

**Those replacement IDs are only correct for a DBC missing the standard
entries in exactly this way.** If graveyard resurrection already works on
your server, do not apply this patch — it will send players to unrelated
locations. To check your own DBC:

```bash
python3 - <<'EOF'
import struct
with open('data/dbc/WorldSafeLocs.dbc','rb') as f:
    f.read(4)
    count, fields, size, _ = struct.unpack('<IIII', f.read(16))
    ids = {struct.unpack('<I', f.read(size)[:4])[0] for _ in range(count)}
print('total entries:', count)
print('has vanilla WSG ids (769-772):', {769,770,771,772} <= ids)
print('has vanilla AB ids (889,890,893-899):', {889,890,893,894,895,896,897,898,899} <= ids)
EOF
```

If both report `True`, skip this patch.

## Applying

Use `git am -3` rather than a plain `git am` — the `-3` does a real
three-way merge, which absorbs the line drift you get on a tree that has
moved on since the base commit. Plain `git am` rejects those outright.

```bash
cd /path/to/tortoise-playerbots
git am -3 /path/to/0001-Add-world-buffs-automatic-donation-points-and-fix-th.patch
# ... repeat for whichever others you want, in ascending order
```

Then, if you applied a patch that needs them:

1. **SQL** — apply [`sql/donation_point_progress.sql`](sql/donation_point_progress.sql)
   to your **login** database (patch 0001 only).
   [`sql/guildbank_trigger.sql`](sql/guildbank_trigger.sql) goes to the
   **world** database and belongs to no patch — see above.
2. **Config** — append the relevant blocks from
   [`conf/mangosd.conf.additions`](conf/mangosd.conf.additions) to your
   `mangosd.conf`. Note the `*.Enable` switches default to **off**.
3. **Rebuild and restart** — these are C++ source changes:
   ```bash
   cd build && make -j$(nproc) mangosd
   ```

If a patch still conflicts, resolve the markers by hand, then
`git add <files> && git am --continue`. To bail out entirely:
`git am --abort`.

## Do these apply to a newer tree?

Probed by applying the patches onto the fork's `main` branch, which has
genuinely diverged from the base commit (15 commits of its own, missing 85
of the playerbots branch):

| Patch | Result on a diverged tree |
|---|---|
| 0001 | `World.cpp`/`World.h` apply cleanly. `ChatHandler.cpp` conflicts — **because `main` already carries the same shop fix**, `"=0="` and all; only the comment differs. Take either side. |
| 0002 | applies cleanly |
| 0003 | not applicable there — `main` ships no PlayerBots module at all |
| 0004 | applies cleanly |

So the patches tolerate a fair amount of upstream movement. Two honest
caveats:

- **Applying cleanly is not the same as still working.** Patch 0003 in
  particular leans on playerbot internals (`AI_VALUE`, the strategy
  engines, the `"possible targets"` value). If those get refactored
  upstream, the patch may apply and then fail to compile — or compile and
  behave differently.
- **Patch 0004 is data-dependent, not code-dependent.** It stays wrong on
  any tree whose `WorldSafeLocs.dbc` has the standard IDs, no matter how
  cleanly it applies. Run the check above first.

Worth knowing: the shop-category fix in 0001 exists upstream on `main`
already — it simply never propagated to `playerbots-integration-gh`. If
your tree descends from a line that has it, that part of 0001 is redundant.

## License

Derived from the GPL-licensed tortoise-wow/mangos core — these patches are
provided under the same license (GPLv2 or later).
