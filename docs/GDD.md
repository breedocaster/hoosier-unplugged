# Hoosier Unplugged: Game Design Doc

> Working title. Living document. Numbers are starting points to tune by feel.

## One-liner

A drop-in co-op belt-scroll brawler for phones and Steam. A crew of Hoosiers gets flung through Indiana history by a data-center megacorp's time machine and has to fight back through the eras, undoing environmental wrecks as they go.

## Pillars

1. **Anyone can jump in, any time.** Press START and you're in. Drop out and the run keeps going. Couch, online, or both at once.
2. **Classic brawler crunch.** Grabs, throws, juggles, breakable barrels hiding food, and specials that cost health but can be earned back.
3. **Every run is a little different.** Roguelite Eco-Boons stack into builds. A dedicated roguelite mode makes that the whole game.
4. **Indiana, loud and proud.** Real places, real history, real eco stories. Tenderloins as health pickups.
5. **Eco hero, not a lecture.** Saturday-morning Captain Planet energy: you save the day, then a short Eco Fact card says what really happened.

## Influences: what we take, what we don't copy

| Source | What we take | What we leave |
|---|---|---|
| **Streets of Rage 4** | Specials cost health, and you win it back by landing hits without getting hit ("green health"). Star moves from collectible pickups. Team combo counter that breaks when anyone gets hit. Assists on retry (extra lives/stars for a lower score). Story, Arcade, Boss Rush and Battle modes. Friendly fire as an option. | Characters, art, music, names |
| **Final Fight** | Walk-in grabs, knees, throws. Breakable objects that drop food. Specials that cost health as a last resort. Car-smash-style bonus rounds. | Characters, Metro City |
| **TMNT: Turtles in Time** | Time-travel stage structure: present day → scattered across eras → back for the finale. Throwing enemies into the screen. Vehicle/chase stages. | Turtles, Foot Clan, Shredder, Krang, etc. |
| **TMNT: Shredder's Revenge** | Drop-in online co-op, story-mode overworld map with side challenges, character leveling, team attacks, reviving downed teammates. | Same |
| **TMNT: Splintered Fate** (roguelite) | Run-based power-ups picked from themed sources, active tools per character, rerolls, sacrifice-for-power choices, run currency vs. permanent currency, co-op runs. | Same |
| **Captain Planet** | A team whose elemental powers combine into something bigger. An eco message delivered as an end-of-episode tip. | The rings, Planeteers, Captain Planet, Gaia |

**IP guardrails:** no character, name, logo, sprite, sound or music from any of the above goes in this repo. "Like X" is fine in design notes. Anything recognizable on screen is not. StratoStack, its staff, and every product name are invented. Run a trademark check on the final title and on StratoStack before release.

## Modes

| Mode | Who it's for | Rules |
|---|---|---|
| **Story: Chill** | Kids, casual co-op, "just hang out" | Infinite respawns, enemies hit softer, boons on, drop in/out any time, autosave after each stage. Default mode. |
| **Story: Normal / Hoosier Hard** | Regular players | Same flow with slower respawns and harder hits. Retry a stage with assists (extra lives/Sparks) for a lower rank. |
| **Arcade** | Score chasers | Lives + continues (pressing START to rejoin costs a continue and shows on the scoreboard). No boons. Fixed seed so leaderboards are fair. |
| **Rollback Run** (roguelite) | Replay value | See below. Unlocks after Stage 4. |
| **Boss Rush** | Post-game | All bosses back to back. |
| **Battle** | Couch chaos | PvP in small arenas. Low priority. |

Every mode supports drop-in/drop-out. See [MULTIPLAYER.md](MULTIPLAYER.md).

## Combat

### Inputs (four buttons + stick)

| Action | Pad (Xbox names) | Keyboard P1 | Touch |
|---|---|---|---|
| Attack | X | J | HIT |
| Jump | A | K | JUMP |
| Special | Y | L | SPEC |
| Star move | B / RB | I | STAR |
| Pause / join | Start | Enter / Esc | ‖ (or tap HIT to join) |
| Hold to drop out | Back / View | Tab | pause menu |

Grabs happen automatically when you walk into an enemy (Final Fight rule), so phones only need four buttons. Mobile also gets **Auto-combo** (hold HIT) and **Smart Special** (special aims at the densest crowd) as accessibility toggles.

### Core rules (prototype implements the ✅ ones)

- ✅ **Three-hit string.** The chain only advances if a hit connects; a whiff repeats the jab.
- ✅ **Jump kick** knocks enemies down.
- ✅ **Grab:** walk into a standing or stunned enemy. ATTACK = knee (3 max, then auto-throw); back + ATTACK = throw behind you.
- ✅ **Thrown enemies are weapons.** They knock down anyone they fly into.
- ✅ **Specials cost health that turns green.** Land hits without getting hit to win it back. Get hit and the green is gone. Specials are invincible while active.
- ✅ **Star moves** spend a Spark (start with 1, find more) for a screen-wide hit.
- ✅ **Crossroads Combo:** two or more players fire star moves within ~⅓ s of each other for a bonus team blast. The full game expands this into duo team-ups (e.g. Kurt + JuiceJam = *Rhythm Section*).
- ✅ **Shared combo counter.** Any teammate getting hit breaks it.
- ✅ **Attack tokens:** at most 2 enemies can be attacking a given hero at once. That keeps 4-player crowds from turning into stunlocks.
- ⬜ Dash (double-tap), back attack (Attack+Jump), wall bounces, OTG hits, air specials.
- ⬜ **Toss to the screen:** grab near the bottom of the belt and throw *toward the camera*. The enemy smacks into the glass. (Turtles in Time homage.)
- ⬜ Weapons: rebar, fire extinguisher (spray stun), ethernet cable (whip), folding chair, an ear of corn (throwable). Kurt can pick up any guitar for a bonus special.
- ⬜ Revive: hold ATTACK next to a downed teammate in Story mode to bring them back early.
- ⬜ Taunt: fills a little Spark meter, Shredder's Revenge style.

### Pickups

| Pickup | Effect |
|---|---|
| Sweet Corn | small heal |
| Pork Tenderloin | big heal |
| Sugar Cream Pie | full heal |
| Persimmon Pudding | heal + faster green-health recovery for 20 s |
| Spark | +1 star move |
| Watts | run currency (shops, Rollback Run) |

## Roguelite layer: Eco-Boons, Gizmos, Rollback Run

### Eco-Boons (in-run passives, prototype has 7)

Boons come from six **Hoosier Spirits**, one per element. Each hero belongs to one element, which ties back to the Captain Planet team idea.

| Element | Spirit | Flavor | Example boons |
|---|---|---|---|
| Current ⚡ | The Grid | chain lightning, stun | ✅ *Live Wire*: every 3rd combo hit arcs to another enemy |
| Juice 🎵 | The Groove | rhythm, special economy | ✅ *Bass Boost*: specials cost 40% less health |
| Stone 🪨 | Limestone | armor, knockdowns | ✅ *Bedrock*: take 20% less damage |
| Water 💧 | The Wabash | pull, slow, healing | ✅ *Rain Barrel*: food heals 50% more |
| Wind 🌬️ | Prairie Wind | speed, air juggles | ✅ *Tailwind*: +20% move speed |
| Grow 🌱 | Old Sycamore | regen, roots | ✅ *Second Growth*: green health returns 2× faster |
| Corp 💼 | StratoStack (cursed) | power with a catch | ✅ *Terms & Conditions*: +40% damage, but no green health ever |

- **Picks:** after certain fights, each player gets their own 3 cards and picks one. The game waits (10 s timer, auto-pick) so co-op stays fair.
- **Duo boons:** hold boons from two elements to unlock a combo, e.g. Current + Water = *Thunderstorm* (zaps leave electrified puddles), Stone + Wind = *Dust Devil*, Grow + Water = *Wetland* (healing zone).
- **Team boon:** if the team together holds all six elements, the Crossroads Combo summons the **Sycamore Sentinel** for a stage-clearing team ultimate.
- **Corporate Bargains:** occasional StratoStack kiosks offer a strong boon with a drawback, like Splintered Fate's sacrifice choices. Always optional.
- **Catch-up rule (built):** anyone dropping in mid-run instantly gets boons up to the count of the teammate who has the fewest, so arriving late never means arriving weak.

### Gizmos (one active item per player, on cooldown)

Zip-Tie Bola, Leaf Blower, Hornet Nest, Solar Panel Shield, Jumper Cables (revive a teammate or stun a Rackbot), Rain Barrel (heal zone), Drone Jammer.

### Rollback Run (roguelite mode)

- **Fiction:** Vail's Rollback Engine keeps restoring the timeline from backup. The crew remembers each attempt.
- **Structure:** a run is ~6 *restore points* pulled from every era, each 3–5 fights long, ending with a remixed boss. Between fights the team chooses a door: **Spirit** (boon), **Farm Stand** (shop for Watts), **Gauntlet** (hard fight, big reward), **Corporate Bargain**, or **Rest Stop** (heal).
- **Meta progression:** runs earn **Seeds**. Seeds plant the **Restoration Garden** in the hub (the Garage), which visibly regrows native prairie. Plants unlock permanent perks, new boons, Gizmos, and characters.
- **Co-op:** drop-in works mid-run (catch-up rule). Seeds go to everyone who finished a restore point.

## Progression (Story)

- Indiana overworld map (like Shredder's Revenge) with stages, side challenges ("free 5 cardinals", "unplug 3 cooling towers"), and collectibles (Eco Fact cards, vintage postcards).
- Per-character levels unlock more health, an extra starting Spark, and new moves. XP saves to each player's own profile, including guests who dropped in.
- Story progress belongs to the host's save. Guests keep their XP and unlocks.

## Difficulty and assists

Chill / Normal / Hoosier Hard / *Mania* (post-game). Enemy count and HP scale with active player count (built: +25% HP per extra player, +50% for bosses, and more grunts). On a failed stage you can retry with assists (extra lives or Sparks) for a lower rank, like Streets of Rage 4.

## Platforms and tech

- **Engine:** Godot 4.7.x stable (4.8 is in beta; upgrade once it ships stable). GDScript. GL Compatibility renderer for the widest phone support.
- **Resolution:** 640×360 base, integer-scaled. That's 2× for 720p and Steam Deck (with letterbox), 3× for 1080p, 6× for 4K.
- **Steam:** Windows + Linux + Steam Deck as targets, macOS optional. GodotSteam for achievements, lobbies and Remote Play Together.
- **Android:** Google Play, using the existing Play Console developer account.
- **iOS:** Godot iOS export needs a Mac with Xcode. Options: a used Mac mini, a cloud Mac, or GitHub Actions macOS runners for CI builds. Decide before committing to an iOS date.
- **Determinism:** all actors tick from the stage in a fixed order on a 60 Hz physics clock and read only `InputFrame`s. That keeps online play a transport problem, not a rewrite.

## Art and audio direction

- **Art:** chunky pixel art at 640×360 (closer to Shredder's Revenge than SoR4's hand-drawn HD, and far cheaper to animate). Saturated Midwestern palettes per era: sodium-orange night streets, glacier blues, gaslight amber, marsh greens, 2099 neon.
- **Audio:** blues-rock/Americana with a different twist per era: ragtime piano for 1888, marching-band brass for the Brick Oval, synthwave for 2099. Kurt (guitar) and JuiceJam (bass) can record stems; a loop-pedal arrangement suits Kurt's Loop Pedal star move.
- **Hit feel:** 2–4 frame hitstop, screen shake on launches, a big chunky font for combo counts.

## Open questions

1. Final title (and a trademark/Steam name check).
2. Mobile pricing: premium, or free-to-try with a one-time unlock? Ads don't fit a co-op brawler.
3. Online scope for v1: Steam-only online plus Remote Play Together, or cross-play phone↔PC from day one?
4. Max players: 4 (current plan, fits phones and the HUD) or 6 like some modern brawlers?
5. JuiceJam's look and moveset need his input. Same for Kurt's.
