# Hoosier Unplugged *(working title)*

A drop-in co-op beat 'em up for **phones and Steam**. A crew of Hoosiers takes on **StratoStack**, a data-center megacorp that's quietly pumping Indiana's past dry to power its server farms. When the crew storms HQ, the CEO "restores them from backup" and scatters them across Indiana history. They fight back through the Ice Age, the 1888 gas boom, the Kankakee marsh and a neon 2099, undoing environmental wrecks as they go.

**Plays like:** Streets of Rage 4 crunch + Final Fight grabs + Turtles in Time structure + Shredder's Revenge drop-in co-op + Splintered Fate roguelite boons, with a Captain Planet eco message delivered Saturday-morning style.

> Status: **M0 prototype.** Graybox Stage 1 is playable with 1–4 players. Everything is placeholder shapes, which is on purpose.

## Run it

1. Install **Godot 4.7.x** (standard build, not .NET): <https://godotengine.org/download>
2. Open `game/project.godot` in the editor and press **F5**.
   Or from a shell: `godot --path game`

### Controls

| | P1 keyboard | P2 keyboard | Gamepad (Xbox names) | Phone |
|---|---|---|---|---|
| Move | WASD | Arrows | Left stick / D-pad | Left-half floating stick |
| Attack | J | `,` or Num1 | X | HIT |
| Jump | K | `.` or Num2 | A | JUMP |
| Special (costs green health) | L | `/` or Num3 | Y | SPEC |
| Star move | I | `;` or Num5 | B / RB | STAR |
| Join / pause | Enter / Esc | Backspace / NumEnter | Start | tap HIT to join, ‖ to pause |
| Hold to drop out | Tab | Del / Num0 | Back / View | (pause menu, later) |

**Drop in:** press START on any free device, pick a fighter with left/right, press ATTACK.
**Grab:** walk into an enemy. ATTACK to knee, back + ATTACK to throw.

## What's in the prototype

- 6 heroes, including **Kurt** (guitar, Power Chord) and **JuiceJam** (bass, Drop the Bass)
- Up to 4 seats with drop-in/drop-out from keyboard, gamepads and touch
- Green-health specials, star moves, a two-player "Crossroads Combo" team star
- Rackbots, Fanboys and a Server Brute boss, plus attack tokens so 4-player crowds stay fair
- Eco-Boon picks after fights (roguelite layer), with catch-up boons for late joiners
- Story (Chill / Normal) and Arcade (lives + continues) modes
- A stage-clear Eco Fact card (sourced)

## Docs

| Doc | What's in it |
|---|---|
| [docs/GDD.md](docs/GDD.md) | Pillars, influences and IP guardrails, modes, combat, roguelite layer, tech |
| [docs/STORY.md](docs/STORY.md) | Premise, villains, all 12 stages across 3 acts, Eco Fact sources |
| [docs/CHARACTERS.md](docs/CHARACTERS.md) | Heroes, unlockables, enemies, bosses |
| [docs/MULTIPLAYER.md](docs/MULTIPLAYER.md) | Drop-in/out rules, architecture, online plan |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Milestones and open decisions |

## Repo layout

```
game/                     Godot project (open game/project.godot)
  autoload/game.gd        Game: mode, difficulty, seeded RNG, team Watts
  autoload/players.gd     Players: device polling, seats, drop-in/out
  core/                   InputFrame, PlayerSlot, Fighter base, Roster (all tuning data)
  actors/                 PlayerFighter, EnemyFighter, Breakable, Pickup
  stage/                  BrawlStage (waves, camera, combat, boons) + graybox backdrop
  ui/                     Title, HUD, touch controls
  tests/                  Headless smoke test (2 bots, drop-out/rejoin, pause)
docs/                     Design docs
.github/workflows/ci.yml  gdparse + gdlint + Godot 4.7.2 headless smoke test
```

## CI

Every push runs:
1. `gdparse` + `gdlint` on all GDScript
2. Godot 4.7.2 headless import
3. `tests/smoke_test.tscn`: two scripted players drop in, brawl, pick boons, pause, and one drops out and rejoins. The job fails on any script error.

Run the smoke test locally:

```sh
godot --headless --path game --import
godot --headless --path game --fixed-fps 60 res://tests/smoke_test.tscn
```

- `--headless`: no window or GPU, for servers/CI
- `--path game`: run the project in `game/`
- `--import`: import assets and build the class cache, then quit
- `--fixed-fps 60`: simulate exactly 60 fps without waiting on the real clock, so the test runs as fast as the CPU allows

## House rules

- No keystores, store credentials, Steam app secrets or personal info in the repo (`.gitignore` covers the usual files).
- No characters, names, art or audio from the games and shows that inspired this. See the IP guardrails in the GDD.
- All tuning numbers live in `game/core/roster.gd` and the constants at the top of `stage/brawl_stage.gd`.

## License

Not chosen yet. All rights reserved until a license is added.
