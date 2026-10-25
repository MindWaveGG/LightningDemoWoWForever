# LightningDemo — Concepts

Procedural multi-termination lightning concept for WoW Forever.  
Demo runs on Classic Era (Interface 11509). Target implementation is WoW Forever (Interface 16001).

---

## Generation Overview

- Shared upper channel (cloud level).
- 5–12 distinct ground terminations (wider multi-point spread).
- Minimum simulated distance: 200 yards. Range: 200–2200 yards.
- Jagged descending paths with random horizontal offset.
- Sideways node spacing compresses with distance (`hSpacing` scales with size).
- Branch probability and length fall off with height.
- Fast bottom-to-top flash + optional flicker.
- White/blue core with yellow-ish outer glow.
- Node marker squares are disabled (debug only). Only bolt lines are drawn.

---

## 2D Demo Concepts vs 3D World-Space Translation

| Concept | 2D Demo (screen space) | 3D World (Forever) |
|---------|------------------------|--------------------|
| Distance | Random 200–2200 yards from player | Real horizontal distance from player to strike |
| Ground strikes | Random 5–12 points, spread wider on screen | Random 5–12 world positions on terrain, spread in X/Y |
| Upper channel | High screen Y, pinned near top | High world Z near cloud base |
| Descending paths | Jagged steps downward on screen | Jagged steps downward in world Z with X/Y offset |
| Node spacing | Horizontal steps shrink as distance grows | Same falloff in world units with distance |
| Branching | Probability and length fall off with screen height | Same falloff with world height |
| Perspective | Inverse-distance size; base approaches horizon | True camera projection |
| Thunder delay | Fake distance / 375 | Real horizontal distance / 375 |
| Sound | PlaySound on SFX | C_Sound.PlaySound on SFX/Ambience + volumeOverride |

---

## Perspective (2D)

- Size scale ≈ \(300 / distance\) (clamped about 0.28–1.4).
- Top of the bolt stays near the top of the screen.
- Base rises toward a horizon line as distance increases.
- Thickness scales with the same factor.
- Horizontal node spacing scales with size so far strikes look tighter.
- Earth curvature is negligible at normal game distances and is not applied.

---

## Sound

- Strike: sound kit 30 on the **SFX** channel.
- Lead-up: sound kit 31 on the **SFX** channel.
- Delay: yards / 375 (sound speed ≈ 375 yards/second).
- Volume scales down with distance (closer = louder).
- Forever can use `C_Sound.PlaySound(..., volumeOverride)` for true distance-based volume.

---

## Chat Channel

- Addon auto-joins a local channel named `LightningDemo`.
- Messages use `C_ChatInfo.SendChatMessage(text, "CHANNEL", nil, channelID)`.
- `SendAddonMessage` with `"CHANNEL"` is blocked on Classic (InvalidChatType).
- Enable the **LightningDemo** channel in a chat window to see status, strike, and config lines.
- Channel sends from timers work on this client; if a future client blocks them, only slash-triggered lines will appear.

---

## Classic Era vs WoW Forever

| | Classic Era (demo) | WoW Forever (target) |
|---|---|---|
| Interface | 11509 | 16001 |
| API | Older Classic | Modern Mainline / Midnight-style |
| PlaySound | `PlaySound(id, "SFX")` | Prefer `C_Sound.PlaySound` + volumeOverride |
| CreateLine | Unreliable | Available |
| Combat restrictions | Full | Modern restrictions (not relevant to this visual) |
