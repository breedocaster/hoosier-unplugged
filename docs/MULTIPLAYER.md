# Multiplayer: drop-in / drop-out

Goal: **1–4 players, joining and leaving at any moment, in every mode, locally, online, or both at once.**

## Player-facing rules

| Situation | What happens | Built in prototype |
|---|---|---|
| Free controller/keyboard presses START (phone: tap HIT) | Opens a seat in that player's HUD panel with character select (`< KURT >`) | ✅ |
| Left/right in the panel | Cycles characters, skipping ones already taken | ✅ |
| ATTACK | Drops in at the left edge of the screen with spawn invincibility | ✅ |
| Hold BACK ~0.75 s | Drops out. The character leaves and the run continues. | ✅ |
| Controller unplugged | 10 s grace period, then auto drop-out. Plugging it back in cancels. | ✅ |
| Join mid-run with boons on | Catch-up boons up to the team's lowest boon count | ✅ |
| Join during a boss | Allowed. Boss HP doesn't rescale mid-fight (prevents abuse), but new waves do. | ✅ (scales at spawn) |
| Arcade: a player runs out of lives | Seat frees up. START again = continue (counted on the scoreboard). | ✅ |
| Story: a player goes down | Respawns after a delay. Can't lose in Chill. | ✅ |
| Revive a downed teammate early | Hold ATTACK next to them | ⬜ |
| Online guest joins | Same seat flow; their device id is `net:<peer>:<n>` | ⬜ |

Scaling with active players (all tunable in `brawl_stage.gd`): grunt count ×(1 + 0.5 per extra player), grunt HP +25% per extra player, boss HP +50% per extra player. Streets of Rage 4 also adjusts its settings by active player count.

## Architecture (why online won't need a rewrite)

```
devices ──► Players autoload ──► InputFrame per seat per tick ──► BrawlStage.tick() ──► Fighters
  kb0/kb1        (polling, seats,       (move vector + button bits)      (fixed order,
  joyN           join/leave rules)                                        60 Hz, seeded RNG)
  touch
  script:*  ◄── tests today
  net:*     ◄── online tomorrow
```

- **Seats, not scenes, own players.** The stage *reconciles* every tick: a seat that's PLAYING but has no fighter gets one spawned; a fighter whose seat is gone gets despawned. Local joins, online joins, disconnects and test scripts all take the same path.
- **Gameplay only reads `InputFrame`s.** A network peer just needs to deliver frames.
- **Deterministic tick.** The stage ticks every actor in a fixed order on the physics clock, using `Game.rng` (seeded). The headless smoke test relies on this, and it leaves the door open for lockstep or rollback later.

## Online plan

### Phase 1 (free): Steam Remote Play Together
Valve's Remote Play Together streams a local-multiplayer game to friends over the internet. It works with up to four players, and only the host needs to own the game ([TechRadar](https://www.techradar.com/news/steam-will-soon-let-offline-multiplayer-games-be-played-with-friends-online), [Neowin](https://www.neowin.net/amp/steam-will-let-local-multiplayer-games-be-played-online-with-remote-play-together/), [KeenGamer](https://keengamer.com/articles/news/steam-remote-play-together-lets-you-play-local-co-op-online/)). Good local co-op means Steam online works from day one at zero code cost.

### Phase 2: real netcode (host-authoritative listen server)
- The host runs the simulation. Clients send their `InputFrame` every tick. The host broadcasts compact actor snapshots at 20–30 Hz, and clients interpolate.
- Clients predict only their own movement. Hits are confirmed by the host. Co-op brawlers tolerate ~100 ms fine. Full GGPO-style rollback is overkill for co-op PvE (revisit for Battle mode).
- Built on Godot's high-level multiplayer (`MultiplayerSpawner` / `MultiplayerSynchronizer` or hand-rolled RPC snapshots) so the transport can swap:

| Transport | Use | Notes |
|---|---|---|
| **GodotSteam `SteamMultiplayerPeer`** + Steam Lobbies | Steam online | The lobby owner hosts. Peers connect by Steam ID instead of IP. Steam handles relay and NAT ([GodotSteam tutorial](https://godotsteam.com/tutorials/multiplayer_peer/)). Community add-ons already do 6-character room codes over lobby metadata ([LinkUx](https://godotengine.org/asset-library/asset/5085)). |
| **ENet** | LAN / direct IP, dev testing | Built into Godot |
| **WebRTC or a relay service** | Cross-play phone↔PC | Needs a signaling/relay server: self-hosted, or a hosted backend. **Open decision.** |

- **Combo co-op:** a host can have 2 couch players + 2 online guests. Streets of Rage 4 doesn't support mixing local and online players ([Co-Optimus review](https://www.co-optimus.com/review/2385/streets-of-rage-4-co-op-review.html)), so this is a selling point.
- **Host leaves:** v1 ends the session for everyone; guests keep XP/unlocks. Host migration is a stretch goal.
- **Saves:** story progress lives on the host. Each player's profile (XP, unlocks, Seeds) lives on their own device or Steam Cloud.

### Phase 3: platform polish
Steam invites and "Join Game" from the friends list, Rich Presence ("Stage 7 – Gas Boom Blowout, 3/4 players"), Android/iOS invite links via room codes.

## Mobile specifics
- Phones: touch overlay for P1. Bluetooth/USB gamepads show up as normal joypads, so a tablet on a coffee table supports 4-player couch co-op with controllers.
- Default mobile mode: Story / Chill with Auto-combo available.
