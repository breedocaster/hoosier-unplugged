# Characters

Six starting heroes, each tied to one element (and one boon spirit, see [GDD.md](GDD.md)). Six or more unlockables join from the past. Max 4 on screen, and no duplicate picks while someone holds a character.

Stat key: **HP / Speed / Power / Reach**, relative, 1–5. In-engine numbers are in `game/core/roster.gd`.

## Starting crew

### KURT, "The Breaker" ⚡ Current
- **Who:** Power-grid engineer by day, blues-rock guitarist by night. Reads machine logs like tea leaves and always knows which breaker to pull. He's the one who figures out StratoStack is pulling power from the past.
- **Role:** All-rounder, the beginner-friendly default. **3 / 3 / 3 / 3**
- **Weapon:** Beat-up electric guitar. Wrench as a backup.
- **Specials:** *Power Chord* ✅ (radial amp shockwave that launches) · *Throttle Twist* (shoulder rush, motorcycle style) · *Kickstand Drop* (air special)
- **Star move:** *Loop Pedal*. Records your last 4 attacks, then a glowing amp-ghost replays them across the screen.
- **Passive:** *Log Search*. Enemies you've hit show their health bars.
- **Taunt:** tunes a string, frowns, tunes it back.
- **Look:** TBD. Kurt supplies reference.

### JUICEJAM, "Low End Theory" 🎵 Juice
- **Who:** Kurt's bassist and gaming buddy. The rhythm section and the team's heartbeat. Hits like a subwoofer.
- **Role:** Heavy hitter / crowd control with long reach. Slower walk, bigger swings. **4 / 2 / 4 / 4**
- **Weapon:** Bass guitar (4- or 5-string: his call).
- **Specials:** *Drop the Bass* ✅ (ground-pound shockwave that launches everything around him) · *Slap Line* (fast forward multi-hit) · *Walking Bassline* (advancing combo that carries enemies)
- **Signature mechanic: Groove.** Attacks timed to the stage music's beat deal bonus damage and fill green health faster. A visual pulse on the HUD helps non-musicians. Off-beat play still works fine.
- **Star move:** *Rhythm Section*. Solo, it's a screen-wide sub-bass drop. With Kurt on the team, it becomes a duo finisher: Kurt's Loop Pedal plus JuiceJam's drop.
- **Look / moves:** TBD. Get JuiceJam's input.

### LIMESTONE LOU, "Quarry Hand" 🪨 Stone
- **Who:** Bedford limestone quarry worker. Built like the stone he cuts. Talks slow, hits slower, hits *hard*.
- **Role:** Grappler / tank (the Haggar slot). **5 / 1 / 5 / 2**
- **Specials:** *Quarry Drop* ✅ (spinning slam) · *Block Party* (hurls a limestone block) · *Cornerstone Clinch* (command grab)
- **Star move:** *Cornerstone*. Stomps the ground and the whole screen quakes.

### WABASH WREN, "River Guide" 💧 Water
- **Who:** Fishing guide and canoe racer who knows every bend of the Wabash.
- **Role:** Reach / zoning with a canoe paddle. **3 / 3 / 2 / 5**
- **Specials:** *Paddle Sweep* ✅ (long low sweep) · *Undertow* (pulls a crowd in) · *Portage* (paddle vault)
- **Star move:** *Flash Flood*. A wave rolls across the screen.

### TURBINE TESS, "Wind Tech" 🌬️ Wind
- **Who:** Wind-farm technician who climbs turbine towers for fun.
- **Role:** Speed / aerial juggles. **2 / 5 / 2 / 3**
- **Specials:** *Updraft* ✅ (dashing rush that launches) · *Gust Dash* · *Blade Spin* (air special)
- **Star move:** *Derecho*. Wind wall sweeps the screen and juggles everything.

### PRAIRIE, "Restoration Crew" 🌱 Grow
- **Who:** Restoration ecologist who plants native prairie and runs controlled burns. Calm, a little scary.
- **Role:** Control / support. Roots, snares, team healing. **3 / 3 / 2 / 4**
- **Specials:** *Root Snare* ✅ (long-range root that pins enemies) · *Seed Bomb* (thrown, sprouts a healing patch) · *Burn & Bloom* (fire wall, then flowers that heal the team's green health)
- **Star move:** *Bloom*. The screen erupts in prairie: enemies tangled, teammates healed.

## Unlockables (met in the past, come home with you)

| Name | From | Role | Hook |
|---|---|---|---|
| **TUSK** | Stage 5, Ice Age | Bruiser | A mastodon calf in a homemade exosuit. Can't talk, extremely huggable, flattens Rackbots. |
| **Surveyor Sam** | Stage 6, 1816 | Ranged | Frontier land surveyor. Measuring chain as a whip, compass for reading enemy weak points. |
| **Flambeau Flo** | Stage 7, 1888 | Fire / zoning | Gas Belt glassblower. Blowpipe, molten-glass bubbles. |
| **Marsh Mae** | Stage 8, ~1910 | Trapper / control | Kankakee marsh guide in a punt boat, with duck calls that stun. |
| **Riding Mechanic Benny** | Stage 9, 1911 | Speed | Early race-car riding mechanic. Wrench combos, rides a tire like a unicycle. |
| **Dune** | Stage 10, 1960s | Defense | Volunteer from the fight to save the dunes. Protest sign as a weapon, sand-shield parry. |
| **Retro forms** | Post-game | All | 8-bit "demake" versions of the starting crew (like SoR4's retro characters). |

## Enemies

| Enemy | Behavior | Prototype |
|---|---|---|
| **Rackbot (blue LEDs)** | Basic grunt, slow wind-up punch | ✅ `rackbot` |
| **Rackbot-R (red LEDs)** | Faster, shorter wind-up | ✅ `rackbot_red` |
| **Rackbot-Y (yellow)** | Shock baton. Can't be grabbed while sparking. | ⬜ |
| **Rackbot-G (green)** | Throws hard drives from range | ⬜ |
| **Rackbot-K (black)** | Blocks. Must be grabbed or launched. | ⬜ |
| **Fanboy** | Hovering cooling-fan drone. Fast poke; later blows heroes back with gusts. | ✅ `fanboy` |
| **Cable Snake** | Pops out of floor grates and snags ankles | ⬜ |
| **Middle Manager** | Buffs nearby enemies with "Synergy" and throws NDAs that silence specials for 3 s | ⬜ |
| **Coolant Brute** | Heavy armor, leaves slippery coolant puddles | ⬜ |
| **Bit Miner** | Steals food pickups off the ground. Chase it down to get the food back. | ⬜ |
| **Server Brute** | Mid-boss/boss stand-in: super armor while attacking, radial slam | ✅ `server_brute` |

Every enemy gets era-specific costumes: parkas (Ice Age), frontier hats (1816), bowler hats and goggles (1888), waders (1910), racing helmets (1911), hard hats (1960s), neon (2099).

## Bosses

See the stage table in [STORY.md](STORY.md). Boss rules: telegraphed attacks, super armor only during specific moves, enrage at 30% HP, and HP scaling with player count (+50% per extra player in the prototype).
