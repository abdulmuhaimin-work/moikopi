# Moikopi — Story Mode: Storyline & Design

A single storyline for Story Mode, with notes for character and environment redesign so art and levels stay consistent.

---

## Premise

**Moikopi** is a small amphibian—once a normal frog—who woke up at the bottom of **the Stack**: a vertical megastructure in a neon-soaked cyber world. The Stack is a relic of the old network, a tower of data and light that now flickers between reality and simulation. Something at the **apex** holds the key to who they were—or who they can become. To find out, Moikopi has to climb: jump by jump, platform by platform, from the dark underbelly to the peak.

**Endless mode** is the same world after the story: once you’ve reached the top, you keep climbing into the endless signal (optional headcanon: Moikopi keeps exploring the network).

---

## Story Beats (for levels and cutscenes)

Use these as a spine for level order and cutscene text. Each level can be one “chapter” or you can split chapters across several levels.

| Level(s) | Chapter       | Story beat | Tone |
|----------|----------------|------------|------|
| 1        | **Awakening**  | Moikopi wakes at the bottom of the Stack. First platforms, first goal: “Get higher. Find out why you’re here.” | Confused, determined |
| 2        | **Undercity**  | Climbing through the lowest tier—flickering grids, failing lights. A voice or log: “The Stack remembers. Keep going.” | Eerie, hopeful |
| 3        | **The middle** | Mid-tier: more stable neon, data streams (particles), first real view of how high the tower goes. “You’re not the first to climb. You can be the first to reach the top.” | Wonder, tension |
| 4        | **Close**      | Near the apex. Architecture changes—cleaner lines, stronger glow. “Almost there. The source is just above.” | Triumph, urgency |
| 5 (final)| **Apex**       | Reach the Goal at the peak. Revelation: e.g. “You are Moikopi. The Stack chose you. Now choose: stay and become part of it, or jump back down and live in the world below.” (Or a simpler ending: “You reached the peak. The signal is yours.”) | Resolution, choice or triumph |

Cutscene triggers in each level should deliver one short line or two that match the beat above (e.g. level 1: “Jump left and right to climb. Reach the GOAL!” is already a good tutorial line; you can add a second trigger with story text like “The Stack is waiting.”).

---

## Character redesign (Moikopi)

- **Concept**  
  A small, agile climber that fits a neon-cyber world: part creature, part signal. Not necessarily “realistic frog”—could be a data-frog, a glowing avatar, or a creature that emerged from the grid.

- **Visual direction**  
  - Silhouette: readable at small scale (big jump, small body).  
  - Accent colors: cyan/magenta to match the neon palette; possible glow or subtle scan-line on the sprite.  
  - Idle: subtle pulse or flicker.  
  - Jump/charge: build-up of light or “data” around the character before launch.

- **Lore**  
  Name “Moikopi” can be what they’re called by the system, or their own reclaimed name. No need to over-explain; keep it mysterious so Endless mode still fits.

- **Implementation**  
  - Replace or recolor the current frog sprite to match the above (new sprite sheet or shader tint + glow).  
  - Optional: second “story-only” player scene with a slightly different sprite (e.g. more glitchy or more “digital”) if you want Story vs Endless to feel different.

---

## Environment redesign

Keep the current **neon grid + dark gradient** as the base; treat it as “the Stack’s” look. Different levels can vary **palette and density** instead of changing the whole engine.

- **Level 1 – Awakening**  
  Dark purple/blue (as now). Grid subtle. Few platforms, clear “first steps” feel. Goal: “get out of the pit.”

- **Level 2 – Undercity**  
  Darker, more red/purple. Grid a bit more broken (e.g. fewer lines, or flicker in script). Platforms: rust-like or “corrupted” accent (dimmer cyan, more magenta). Optional: hazard color (e.g. red) for “don’t fall” zones.

- **Level 3 – Mid-tier**  
  Current neon look at full strength: cyan, magenta, clean grid. Platforms wider, more “data bridges.” Particles (digital rain / drift) a bit stronger. Feels like the “main” Stack.

- **Level 4 – Near apex**  
  Brighter, cleaner. More white/cyan, less magenta. Grid finer or softer. Platforms look more “solid” or “official”—gold or white accent for the final stretch.

- **Level 5 – Apex**  
  Bright, minimal. Goal platform or area clearly “the source”—e.g. white/cyan glow, or a simple terminal shape. One clear “you made it” platform.

**Technical**  
- You already have `platform_color` per platform; use it to match the table above.  
- Optional: per-level background script or shader params (e.g. gradient colors, grid opacity) so each level scene can override the default neon background.  
- Story-specific BGM or SFX per chapter can reinforce the tone (e.g. calmer at apex).

---

## Level design checklist (per level)

- [ ] **PlayerStart** on a safe platform; spawn height correct (feet on surface).  
- [ ] **Goal** placement matches the “peak” of that chapter (top of the level).  
- [ ] **CutsceneTrigger(s)** with 1–2 lines that match the story beat for that chapter.  
- [ ] **Platforms** use the chapter’s palette (undercity = darker, apex = brighter).  
- [ ] **Camera limits** and **death_y** so the level feels like one continuous climb.  
- [ ] **Next level path** set on the root (except the last level, which returns to menu).

---

## Example cutscene text (copy-paste or adapt)

- **Level 1**  
  - “Jump left and right to climb. Reach the GOAL!”  
  - “The Stack goes up. So do you.”  

- **Level 2**  
  - “The undercity never sleeps. Neither do you.”  
  - “Keep climbing. The signal is stronger above.”  

- **Level 3**  
  - “You’re halfway to the apex. The data streams remember every climber.”  
  - “Don’t look down.”  

- **Level 4**  
  - “The light at the top isn’t just glow. It’s the source.”  
  - “One more stretch.”  

- **Level 5 (final)**  
  - “You reached the peak. Moikopi—the Stack sees you.”  
  - (Optional second line:) “Stay, or jump. The choice is yours.”  

---

## Summary

- **Story**: Moikopi climbs the Stack from bottom to apex to find out why they’re there; the peak is the resolution.  
- **Character**: Redesign the frog as a neon, data-like climber (cyan/magenta, optional glow); keep the name Moikopi.  
- **Environment**: Same neon grid base; vary palette and platform style per chapter (dark undercity → bright apex).  
- **Levels**: Use the chapter table and cutscene examples above to build level_01 through level_05 (or more) and keep story and art aligned.

You can implement character and environment changes gradually: e.g. first update level_01 cutscenes and platform colors to this storyline, then add new levels and finally swap the character sprite when the new art is ready.
