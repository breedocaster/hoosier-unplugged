# Roadmap

## M0: Prototype ✅ (this commit)
- Godot 4.7 project, 640×360 integer-scaled, GL Compatibility
- Belt-scroll movement, 3-hit chain, jump kick, grab/knee/throw, thrown-body collisions
- SoR4-style green-health specials, star moves, Crossroads team combo
- 6 heroes (stats + one special each), Rackbots ×2, Fanboy, Server Brute
- 4-seat drop-in/drop-out: keyboard ×2, gamepads, touch overlay, scripted devices
- Camera locks, waves, breakables, food/Spark/Watts pickups
- 7 Eco-Boons with per-player pick cards and the catch-up rule
- Story (Chill/Normal) + Arcade (lives/continues), pause, stage-clear Eco Fact card
- CI: gdparse + gdlint, plus a headless Godot smoke test where two bots play, drop out and rejoin

## M1: Feel
- Hitstop, screen shake, knockback curves, sound placeholders
- Dash, back attack, weapons, revive
- Real sprites for Kurt + JuiceJam + Rackbot (idle, walk, 3 hits, special, hurt, down)
- Stage 1 art pass + Bulldozer Bruno boss
- Android test build on a real phone (touch feel, 60 fps on a mid-range device)

## M2: Vertical slice (Stages 1–2, 4 players)
- All 6 heroes with full kits
- Uptime & Downtime boss, Middle Manager, Cable Snake, Rackbot-Y/G
- Overworld map v1, save/load, character XP
- Steam: GodotSteam integration, achievements, Steam Deck check, Remote Play Together test
- Playtest with the band

## M3: Online
- Host-authoritative netcode over SteamMultiplayerPeer + lobbies
- Decide the cross-play transport for phone↔PC
- Combo co-op (local + online on one host)

## M4: Content
- Stages 3–12, vehicle stages, all bosses, Eco Fact cards (sourced)
- Rollback Run roguelite mode + Restoration Garden meta
- Unlockable heroes, Boss Rush, Battle

## M5: Ship
- Steam page, trailer, demo for Steam Next Fest
- Play Store release; iOS if a Mac/CI path is sorted
- Localization pass, accessibility pass (remapping, colorblind palettes, Auto-combo)

## Decisions needed (from Kurt)
- [ ] Final title
- [ ] JuiceJam's look, bass style, and favorite moves (ask him)
- [ ] Kurt's look and guitar
- [ ] Mobile pricing model
- [ ] Cross-play in v1, or Steam-only online first
- [ ] Art: commission pixel art, or make it in-house?
