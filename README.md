# Turtle 1.18 Server Features

Custom server-side patches for the
[r-o-sh/tortoise-wow](https://github.com/r-o-sh/tortoise-wow) mangos core
(`playerbots-integration-gh` branch), built for a private Turtle WoW 1.12
server running against a 1.18 client.

Each patch is self-contained — pick the ones you want, in any combination.
There are no "fix the previous patch" follow-ups; every patch reflects its
final state.

**Base commit:** 0001-0008 were generated against
[`5e5e40c`](https://github.com/r-o-sh/tortoise-wow/commit/5e5e40c) on the
`playerbots-integration-gh` branch. 0009-0027 build on top of those, against
the tree with 0001-0008 already applied - apply them in ascending order.

## Features

| Patch | What it does | Extra steps |
|---|---|---|
| [`0001`](patches/0001-Add-world-buffs-automatic-donation-points-and-fix-th.patch) **World buffs, donation points, shop fix** | Periodic world buffs, restricted by zone and faction: Spirit of Zandalar (Stranglethorn Vale), Warchief's Blessing (Horde, Crossroads/Orgrimmar), Rallying Cry of the Dragonslayer (Alliance in Stormwind, Horde in Orgrimmar). Each buff runs on its own timer so they don't all fire at once, with a shorter first interval after a restart. Plus `AutoDonationPoints`: real players (bots and the Discord bridge excluded) earn shop currency per hour online, persisted across restarts. Also fixes the Donation Rewards window showing only the "About" tab — the client expects a `parentId` field the server never sent, which threw a Lua error that aborted category parsing on the first entry. | config + SQL |
| [`0002`](patches/0002-Auto-join-new-low-level-players-into-the-configured-.patch) **Beginners guild** | Auto-joins new, guildless real players (level ≤ 5) into a configured welcome guild on first login. | config |
| [`0003`](patches/0003-Fix-playerbot-battlegrounds-queueing-combat-and-flag.patch) **Playerbot battlegrounds** | Fixes playerbots silently failing to queue for battlegrounds at all (their join packet was never processed); three separate reasons they never fought (attack trigger only wired into a combat engine idle bots never entered, target list only ever saw units already attacking them, flag-carrier attack check tested the wrong unit's aura); and flag carriers freezing forever mid-map. Bots no longer fetch the enemy flag on their own initiative — unless their own team has no real players, so solo-vs-bots matches aren't a walkover. Adds a 20-minute hard match cutoff. | – |
| [`0004`](patches/0004-Fix-WSG-and-AB-graveyard-resurrection-using-stale-va.patch) **BG graveyard resurrection** ⚠️ | Fixes "Release Spirit" leaving you stuck at your corpse in WSG/AB instead of teleporting to a graveyard. **Environment-specific — read below before applying.** | – |
| [`0005`](patches/0005-Keep-playerbots-out-of-enemy-faction-territory.patch) **Bots out of enemy territory** | Three separate routes into enemy settlements: taxi destinations drawn from *every* node when `AllFlightPaths = 1`; rpg triggers walking bots to enemy flight masters they can never use; and travel destinations only faction checked per NPC, never by location, so gather/skin/mine nodes inside enemy towns were fair game. | – |
| [`0006`](patches/0006-Solo-dungeon-quality-of-life-leech-limits-and-resurre.patch) **Solo dungeon quality of life** | Narrows the existing Leech feature down with four independent switches (PvE only, real players only, solo only, dungeons only) so it stops healing 1000 random bots and skewing PvP. Adds `SoloDungeonRepopAlive`: dying alone in an instance brings you back alive just inside the entrance instead of a corpse run. Both default to off. | config |
| [`0007`](patches/0007-Clear-Focused-Assault-when-the-WSG-flag-is-captured.patch) **Focused Assault on capture** | The WSG flag aura reapplies Focused Assault every 60s; each stack is +10% damage taken, lasts ten minutes and only clears on a map change, so a carrier who scores keeps the whole penalty into the next round. Now cleared on capture - and only on capture, since clearing it on drop would let a carrier reset the stacks by dropping the flag and taking it back up. | – |
| [`0008`](patches/0008-Guild-bank-configurable-vault-keepers.patch) **Guild bank vault keepers** | The guild bank only accepted two hardcoded NPCs, so it worked in Stormwind and Orgrimmar and nowhere else - the decorative keepers Turtle placed in the other capitals were dead ends, and giving them a gossip menu alone would only open a window whose every action the server drops. Now a config list per faction. | config + SQL |
| [`0009`](patches/0009-Dungeon-finder-fill-waiting-groups-with-playerbots.patch) **Dungeon finder fills with bots** | A player who queues alone waits forever on an empty realm. Bots are inserted into the same queue real players sit in, as ordinary entries, so role assignment, faction and hardcore checks, group building and the offer all run through the existing matcher - no parallel mechanism to keep in sync. Real players keep priority: when one queues, every fill bot not already part of an offer is dropped again. Bots also honour the role they were given, which has to be applied at the end of `ResetStrategies` because `sPlayerbotDbStore.Load` runs in the middle and would overwrite it. | config |
| [`0010`](patches/0010-Resurrect-at-the-dungeon-entrance-when-only-bots-cou.patch) **Bot groups survive a wipe** | Extends patch 0006. A wiped bot group used to end the run: bots cannot walk back in through an instance portal on this core, so they stayed ghosts at the outdoor graveyard. They now repop alive at the entrance, and so does a player whose group holds nobody but bots - an all-bot party is no more help than an empty one. | – |
| [`0011`](patches/0011-Keep-playerbots-out-of-enemy-home-zones-when-picking.patch) **Bots out of enemy territory, part two** | Extends patch 0005 to travel destinations and random teleports. `WorldPosition::isEnemyHomeZoneFor` is the shared test; it deliberately avoids `GetArea()`, which passes an area *flag* to `AreaEntry::GetById()` where an area *id* is expected and reported Barrens positions as Silverpine Forest. The teleport filter only applies while at least a quarter of the destinations survive it, so a sparse list cannot strand bots. | – |
| [`0012`](patches/0012-Replace-the-premade-talent-specs-and-tie-them-to-the.patch) **Talent specs that actually load** | Turtle reworked every talent tree, so all 94 stock links are rejected at startup and bots run around with no talents whatsoever. Replaced with 22 hand-built level 60 specs, each with a levelling path every five levels - without those a level 20 bot is handed the level 60 link and spends its first points in the secondary tree. Talent choice now follows the role the dungeon finder assigned instead of picking at random, and druid feral counts as tank rather than dps. | config |
| [`0013`](patches/0013-Playerbots-actually-vote-on-group-loot-rolls.patch) **Bots vote on group loot** | The path was never finished: `RollOnItemInSlot` returned false unconditionally, and both the pending-roll list and its cleanup went through `Loot::GetRollForSlot`, a stub returning `nullptr` - so entries were erased the moment they were added. No bot ever voted and the countdown ran out on every single item. This core keeps rolls in `Group::RollId`, so votes now go through `Group::CountRollVote`, the same entry point the client uses. Bots wait while any real player still has the dialog open, never roll need against a player who asked for need, and vote anyway once half the countdown is gone so one absent player cannot make everyone sit out the timer. | – |
| [`0014`](patches/0014-Playerbots-do-not-equip-items-that-contribute-nothin.patch) **No more roses as headgear** | An item with no stats, no armour, no weapon damage and no spell fell through to `ITEM_USAGE_BAD_EQUIP`, which bots without a real player master put on regardless. On the realm this was written for, 74 bots were wearing a Forever-Lovely Rose on their head and another 34 a rabbit headband or a carnival mask. Shirt and tabard are cosmetic slots and stay exempt. | – |
| [`0015`](patches/0015-Stop-the-bot-logger-from-treating-finished-text-as-a.patch) **Bot logging no longer kills a Windows server** | `PlayerbotAIConfig::log` handed its argument to `vfprintf` as the format string, and 67 of its 68 callers pass a line they have already assembled. A percent sign anywhere in it - a bot name, a mob name, an item name - was read as a conversion specifier. glibc prints nonsense and carries on, so on Linux the only trace was garbled rows in `bot_events.csv`; the Microsoft runtime calls the invalid-parameter handler instead and the server died with `0xc0000420` and SIGABRT seconds after the first bots came up. The signature is now split: `log` writes verbatim, `logf` keeps the varargs form for the one caller that formats, and carries the format attribute on GCC and Clang so the next such mistake is a warning rather than a crash dump. | – |
| [`0016`](patches/0016-Ship-debug-symbols-with-Release-builds-on-MSVC.patch) **Readable crash dumps on Windows** | The server installs a crash handler that writes a minidump, but the Release configuration passed neither `/Zi` nor `/DEBUG`, so no `.pdb` existed and every frame in the dump was a bare address - the one file meant to explain a crash explained nothing. The install rule for the `.pdb` was also restricted to `CONFIGURATIONS Debug`, so even a RelWithDebInfo build left it behind in the build tree. `/OPT:REF` and `/OPT:ICF` accompany `/DEBUG`, which disables them by default, so the binary itself is unchanged. | – |
| [`0017`](patches/0017-A-seated-trainer-could-not-teach-anything.patch) **Seated trainers can teach** | The learning spell is cast by the trainer, not the player, and `CheckCast` rejects any caster that is not standing up. A trainer placed at a table - `creature_addon.stand_state = 1` - therefore refused every purchase with `SPELL_FAILED_NOT_STANDING`. Nothing was visible at either end: no money changed hands, and the `TRAIN_FAIL_UNAVAILABLE` the handler sends is not displayed by the client, so clicking Train simply did nothing. Seated trainers now cast it as triggered; standing ones are untouched. Everything the check would otherwise catch is verified earlier in the same handler - interaction, line of sight, list membership, learnability and money. | – |
| [`0018`](patches/0018-Embrace-of-the-Viper-the-five-and-six-piece-bonuses-.patch) **Embrace of the Viper, five and six pieces** | The five piece heal fired on every hit with no cooldown; the six piece bonus did nothing at all. Spell 44070 procs at 100% on any damage taken and had no `spell_proc_event` row, so the heal was unlimited - its description says *"when your health drops below 35% ... only once every 3 min"*, and neither half was implemented. The cooldown is a data row; the threshold is a script, and it must subtract the damage of the proccing hit, because procs run before damage lands (`Unit::AttackerStateUpdate` calls `ProcDamageAndSpell`, then `DealMeleeDamage`) - reading health as it stands refuses the one moment the bonus exists for. That rules out `OnCheckProc`, which is not given the damage; `OnProc` costs nothing, since the cooldown is tested before the cast and set after. Spell 44085, the six piece bonus, is a `SPELL_AURA_DUMMY` no handler reads - the glyph form table in `Player::GetShapeshiftDisplay` was simply missing its row. | SQL |
| [`0019`](patches/0019-Summoning-a-bot-say-what-happened-and-do-not-land-it.patch) **Summoning a bot reports, and lands it above ground** | The free branch - GM, or `AiPlayerbot.NonGmFreeSummon` - returned `Teleport()` straight back, so a summon that worked and one that never arrived looked identical; `Teleport()` in turn ignored what `TeleportTo` returned, though it refuses in combat, mid flight, or into a map closed to that player. Separately, the destination height came from `Map::GetHeight` under the offset spot, which in front of an instance portal or on a platform is the terrain far below - the bot arrived under the walkable surface, could path nowhere and stood still. The existing line-of-sight fallback now covers height too. | – |
| [`0020`](patches/0020-Guild-bank-money-unsigned-column-checked-parsing-ove.patch) **Guild bank money** | `GuildBank::b_money` is a `uint32`; its column was `int(11)`, signed. Anything above 214748 gold was stored negative and came back as nonsense, and the `%u` in the UPDATE hid it. Deposits parsed with `atoi` (returns `int`) and withdrawals with `atol` - two functions for one job, neither matching the destination type - and `b_money += money` had no overflow check, which does not cap the balance but wraps it to near zero after the depositor has paid. | SQL |
| [`0021`](patches/0021-Shield-Specialization-granted-one-rage-on-every-rank.patch) **Shield Specialization rage per rank** | All five ranks trigger the same spell 23602, which energizes a flat ten rage points - one rage - so the rank never mattered. The per-rank amount sits on the talent itself and was never passed on, since `HandleProcTriggerSpellAuraProc` casts the trigger without base points of its own. Note the talent has two effects and `OnProc` runs per effect index, so the aura type must be tested or the rage is granted twice. | SQL |
| [`0022`](patches/0022-Bots-follow-the-role-the-dungeon-finder-gave-them.patch) **Bots honour their assigned role** | A druid queued as tank never shifted to bear: bear or cat was chosen from the ranks of Primal Fury, a talent well down the feral tree, and the assigned role was not consulted at all. It now decides, with the spell test as fallback for unassigned bots. And where the tree cannot fill the role at all - a balance druid on the tank slot - the stored spec is dropped and chosen again with the role in hand, since `AutoSelectTalents` only consults roles when picking a spec for the first time. Random bots only, real contradictions only, level 10 and up. | – |
| [`0023`](patches/0023-Embrace-of-the-Viper-six-pieces-the-serpent-bites.patch) **Embrace of the Viper: the serpent bites** *(new content)* | Builds on `0018`. The six piece bonus turns cat form into Cobrahn's serpent and did nothing else; it now also applies a poison at ten per cent of a landed melee attack, in cat form only. The poison is 744, the one the Deviate Adders use in Wailing Caverns where the set drops. An existing spell rather than a new id on purpose - the client resolves name, icon and tooltip from its own `Spell.dbc` and shows nothing for an id it does not know. The set tooltip still says nothing about poison; that would need a client patch. | SQL |
| [`0024`](patches/0024-The-Syndicate-quartermaster-stocked-one-item-out-of-.patch) **Syndicate quartermaster stock** | Thirteen items are gated behind faction 70 with buy prices and ranks 4 to 7 - a designed ladder at item level 30, 40, 50 and 62-63. Anna Lacroix (80946) had one row in `npc_vendor`. The other twelve had no acquisition path at all: no quest reward, nothing in any loot table, no other vendor. No `condition_id` needed, since `BuyItemFromVendor` enforces the rank from the item itself. | SQL |
| [`0025`](patches/0025-Trainers-nobody-could-talk-to-Survival-s-missing-art.patch) **Unreachable trainers, Survival ranks, guard directions** | `trainer_type` 0 is `TRAINER_TYPE_CLASS`, and `IsTrainerOf` then compares the player class against `trainer_class`; where that is also 0 nothing matches and the window never opens. Eighteen trainers were like that, disproportionately the expert and artisan ranks, so whole professions dead-ended. Survival additionally could not pass 225 - spell 46057 was on no trainer at all, while nine items require more than that. Rufus Hardwick gets it. Hellador Swiftluck (62962), a complete template with no spawn and the Alah'Thalas faction, is placed there. His `equipment_id` also pointed at a `creature_equip_template` row that does not exist, which logged an error every startup once he was actually in the world. And Survival gains an entry in all thirteen guard profession menus, mapped by measuring each menu's point-of-interest centroid against every trainer position. | SQL |


### Graveyards (SQL + a DBC tool, no patch)

Two data defects that make characters - bots *and* real players - die in a loop.

[`sql/graveyards_barrens_arathi.sql`](sql/graveyards_barrens_arathi.sql) fixes
the mapping. **The Barrens had no graveyard entry at all**; when a zone has
none, `GetClosestGraveYard` returns nullptr and `RepopAtGraveyard` does not
teleport, so the ghost appears at its own corpse. Die among the guards in The
Crossroads and you release straight back into them - which is exactly what
produced the piles of bones there. Arathi Highlands had one graveyard shared by
both factions, 170 yards from the Alliance town Refuge Pointe.

[`sql/graveyards_dungeons.sql`](sql/graveyards_dungeons.sql) does the same for
instances. Turtle splits several dungeons into multiple *zones* - the Scarlet
Monastery wings, three Scholomance zones, five Dire Maul wings, Blackwing Lair,
six Shadowfang Keep zones - and only the main zone was mapped, so dying in a
wing left you at your corpse. The wings now inherit their main zone's
graveyards. It also opens Shadowfang Keep's graveyard to both factions; it was
Horde only, leaving Alliance with none at all.

[`tools/add_worldsafelocs.py`](tools/add_worldsafelocs.py) restores graveyards
the world database references, or needs, but no shipped DBC contains. Ids 934,
937 and 950 for the Turtle high elf zones Quel'Thalas, Amani'Alor and
Alah'Thalas; ids 960-964 at the entrances of five Turtle-built dungeons
(Lower Karazhan Halls, Dragonmaw Retreat, Timbermaw Hold, Windhorn Canyon,
Frostmane Hollow) which had no graveyard anywhere on their map.
Both the server's `WorldSafeLocs.dbc` and the client copy inside `patch-9.mpq`
stop at id 174, so those zones silently had no graveyard. Coordinates come from
`game_tele` for the high elf zones and from `areatrigger_teleport` for the
dungeons - the latter put you just inside the door.
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


### PvP trinket dropping the flag (SQL only, no patch)

[`sql/pvp_trinket_flag_drop.sql`](sql/pvp_trinket_flag_drop.sql) stops the class
PvP trinket from dropping the battleground flag.

All class versions cast spell 52317, which dispels crowd control the usual way:
apply an immunity for 1 ms with `SPELL_ATTR_EX_DISPEL_AURAS_ON_IMMUNITY`, so
applying it strips matching auras and expires immediately. Besides the mechanic
mask that covers the entire tooltip, it also applied *physical school* immunity
- and the flag aura has school 0, counts as negative because of its periodic
effect, and carries no `SPELL_ATTR_UNAFFECTED_BY_INVULNERABILITY`. So it was
stripped along with everything else, and removing it fires
`EventPlayerDroppedFlag`.

Dropping that one effect leaves crowd control removal untouched. Divine Shield
and Ice Block still drop the flag, as they should - they go through the
dedicated flag branch instead.

Requires a restart: `spell_template` has no reload command.

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

To use the bank outside Stormwind and Orgrimmar you also need patch `0008` and
its config keys - the SQL alone opens the window but the server still rejects
every action.

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

### Patches that expect an earlier one

Most patches here stand alone, but two do not, and it is quicker to say so
than to let you find out from a rejected hunk:

- **0008** edits configuration comments that **0006** adds. Applied on its own
  against an untouched tree it fails in `mangosd.conf.dist.in`.
- **0028** touches the config enum in `World.h` next to entries that earlier
  patches introduce, so a tree without them will need the hunk placed by hand.

### Patches 0028-0032: crashes that only a busy server finds

These four came out of one week in August 2026 on a realm running about a
thousand playerbots. They are worth calling out together because they share a
shape: code that is correct for a few dozen players, and wrong once enough
things happen at once.

| | |
|---|---|
| 0028 | Navmesh tiles removed while a pathfinding query walks them. `removeTile` zeroes `tile->polys` and Detour reads it unvalidated, so a surviving polyRef lands on `nullptr + index` |
| 0029 | Healing Touch dereferenced an aura that had expired mid-cast |
| 0030 | Bot target values cached a raw `Unit*` for up to a second and followed it after the creature died |
| 0031 | The battleground queue declares a mutex and never takes it — all five acquisitions were left commented out during the move off ACE |
| 0032 | A creature taking damage that carries no threat fell into the player-only half of `Unit::DealDamage` and was cast to `Player*` |

Only 0030 is playerbot specific. The others sit in the core and apply to any
mangos-family tree; bots are simply what made them surface daily instead of
yearly. 0032 in particular needs no bots at all — any damage source that
carries no threat will do.

Two of them, 0029 and 0030, are the same bug wearing different clothes: a raw
pointer kept across time. If you are hunting something similar, that is the
pattern to grep for.

Patch 0028 is also a small cautionary tale, written up in its own message: the
obvious fix — a read/write lock around the mesh — was tried, deployed, and
stalled the world thread within minutes. It is not in this repository. What is
here is the boring answer that cannot deadlock.

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
   Patch 0012 is the exception: its talent specs live in `aiplayerbot.conf`,
   not `mangosd.conf`. The patch rewrites `aiplayerbot.conf.dist.in`, so a
   freshly generated config picks them up — an existing one keeps the broken
   stock links until you copy
   [`conf/aiplayerbot.conf.premade-specs`](conf/aiplayerbot.conf.premade-specs)
   over its `AiPlayerbot.PremadeSpec*` block.
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
| 0008 | **superseded upstream.** `Penqle/main` now implements the guild bank itself: it checks the creature the player has selected against the seven vault keepers by entry, and accepts any creature whose gossip menu carries `GOSSIP_OPTION_GUILD_BANKER`. That second half is the better mechanism - a new keeper needs a database row, not a rebuild. Apply this patch on such a tree only if you also want the config list, and expect to merge `GuildBank.cpp` by hand. The SQL half uses ids that do not collide with upstream's. |
| 0005-0007, 0009-0032 | not probed |

So the patches tolerate a fair amount of upstream movement. Three honest
caveats:

- **Applying cleanly is not the same as still working.** Patch 0003 in
  particular leans on playerbot internals (`AI_VALUE`, the strategy
  engines, the `"possible targets"` value). If those get refactored
  upstream, the patch may apply and then fail to compile — or compile and
  behave differently.
- **Patch 0004 is data-dependent, not code-dependent.** It stays wrong on
  any tree whose `WorldSafeLocs.dbc` has the standard IDs, no matter how
  cleanly it applies. Run the check above first.
- **0005-0007 and 0009-0032 were never probed against a diverged tree.** They were written
  and tested on `playerbots-integration-gh` only. Most of them touch the
  PlayerBots module, so the same reservation as 0003 applies: a tree without
  that module cannot use them at all. 0009 additionally needs the
  `src/game/LFT` matchmaker, and 0013 needs a core that keeps loot rolls in
  `Group::RollId` rather than on the loot object.

Worth knowing: the shop-category fix in 0001 exists upstream on `main`
already — it simply never propagated to `playerbots-integration-gh`. If
your tree descends from a line that has it, that part of 0001 is redundant.

## License

Derived from the GPL-licensed tortoise-wow/mangos core — these patches are
provided under the same license (GPLv2 or later).
