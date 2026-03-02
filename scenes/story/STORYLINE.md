# Moikopi — Compelling Storyline (Early-Stage Friendly)

A single, expandable story for Story Mode that fits the current game and leaves room for more levels, characters, and twists as you add content.

---

## Why this story works

- **One clear goal:** Reach the peak. Every level is “climb higher,” so gameplay and story stay aligned.
- **Mystery, not lore dump:** You don’t have to explain everything up front. Who is Moikopi? Why the Stack? Answer in later levels—or leave it ambiguous.
- **Scales with the game:** Start with 3–5 levels; add more chapters (new areas, flashbacks, other climbers) without changing the core premise.
- **Mood over plot:** Neon, solitude, determination. Feels cohesive even with minimal dialogue.

---

## The hook (one sentence)

**A small creature wakes at the bottom of a vertical world of light and data—with no memory, only the certainty that the answer is at the top.**

That’s enough to carry the player. “Reach the peak” is both the mechanical goal and the story goal.

---

## Core premise

- **Moikopi** — The player character. Name can be what the system calls them, or a name they find along the way. Stays vague so you can add backstory later (e.g. “you were once …” in a late level).
- **The Stack** — The world: a vertical megastructure of platforms, grids, and neon. Could be a tower, a simulation, a network, or a dream. You don’t have to decide yet; “climb the Stack” is enough.
- **The peak** — Whatever matters is up there: truth, freedom, a person, or simply “what’s next.” The final level’s Goal is the payoff.

**Endless mode** = after the story (or no story): same world, keep climbing. No need to justify it beyond “the climb continues.”

---

## Emotional throughline (for cutscenes and tone)

| Feeling        | When                         | How to get there                          |
|----------------|------------------------------|-------------------------------------------|
| **Disorientation** | Start of game / Level 1      | Short line: “You don’t remember. You only know: up.” |
| **Determination**   | Early levels                 | “The Stack goes up. So do you.”           |
| **Loneliness / awe**| Mid levels                   | Big vertical space, few words. “No one else made it this far.” |
| **Hope**           | Nearing the top              | Brighter visuals, one line: “Almost there.” |
| **Resolution**      | Reaching the Goal            | One clear beat: arrival, then a single line (see endings below). |

You can hit these with 1–2 cutscene lines per level and palette changes (dark → bright). No need for long text or cutscenes early on.

---

## Story beats (expandable)

Use these as a **minimum** story spine. Add levels between any two rows, or new “chapters,” without breaking the premise.

| Beat        | Level(s) | What happens                         | One example line                    |
|-------------|----------|--------------------------------------|-------------------------------------|
| **Awakening** | 1        | First climb. Learn to jump, reach first Goal. | “Jump left and right. Reach the GOAL.” |
| **Deeper**    | 2        | Go further into the Stack. Darker, stranger.  | “The undercity doesn’t ask why. It just is.” |
| **Mid**       | 3        | Middle of the tower. Scale sinks in.        | “You’re not the first to climb. Be the first to reach the top.” |
| **Near**       | 4        | Close to the apex. Light changes.           | “The light above isn’t just glow. It’s the source.” |
| **Peak**       | 5 (or last) | Reach the Goal. Story payoff.              | See “Endings” below.                |

Later you can insert: “The Fallen” (level where you find traces of others), “The Glitch” (weird geometry / one-off mechanic), “The Voice” (first time something speaks to Moikopi), etc.

---

## Endings (pick one or keep it open)

Keep the **first** ending simple for early stage. The rest are options when you add more content.

1. **Minimal (recommended for now)**  
   Reach the Goal → one line: **“You reached the peak. The Stack holds its breath.”**  
   Then menu or short loop. No choice, no twist—just arrival. You can add more later.

2. **Mystery**  
   **“You are Moikopi. The Stack chose you. What you do next is yours.”**  
   Implies meaning without explaining it. Good if you want sequel or DLC hooks.

3. **Choice**  
   **“Stay and become part of the signal—or jump back down and live.”**  
   Only add if you’re ready to implement two outcomes (e.g. different menu or “New Game+”).

4. **Escape**  
   **“The peak isn’t the end. It’s the way out.”**  
   Suggests the world below was a trap; fits if you later add “outside” visuals or story.

Start with (1); swap in another when the game grows.

---

## What to add later (without changing the premise)

- **More levels** — New “zones” (e.g. The Core, The Spire, The Static) that reuse the same climb + Goal structure.
- **Echoes / logs** — Text or voice lines that hint at who built the Stack or who climbed before. Optional.
- **Another character** — A second creature, or a voice, that appears in one level. Doesn’t need to be in level 1.
- **Twist** — e.g. “You’ve been here before” or “The peak is a new beginning.” Drop in when you add a new act.
- **Endless tie-in** — Optional line in Endless: “The climb never ends. Maybe that’s the point.” Keeps both modes in the same world.

---

## Example cutscene lines (copy-paste or tweak)

**Level 1**  
- “Jump left and right to climb. Reach the GOAL!”  
- “You don’t remember. You only know: up.”

**Level 2**  
- “The Stack goes up. So do you.”  
- “The undercity never sleeps. Neither do you.”

**Level 3**  
- “You’re halfway. The data streams remember every climber.”  
- “Don’t look down.”

**Level 4**  
- “The light at the top isn’t just glow. It’s the source.”  
- “One more stretch.”

**Level 5 (final)**  
- “You reached the peak. The Stack holds its breath.”  
- Or: “You are Moikopi. What you do next is yours.”

---

## Summary

- **Compelling hook:** Small creature, bottom of a vertical world, no memory—answer is at the top.
- **One throughline:** Disorientation → determination → loneliness/awe → hope → resolution.
- **Early-stage:** Use 3–5 levels and a minimal ending (“You reached the peak”); add levels and twists later.
- **Expandable:** New zones, echoes, another character, or a twist can slot in without rewriting the core.

You can implement story gradually: cutscene text and palette per level first, then extra levels and character/environment art when ready.

---

## How the story is integrated in the game

These are wired up so the storyline appears in play, not only in this doc.

| Where | What |
|-------|------|
| **Story intro** | When you press **Story** on the menu, the game loads `scenes/story/story_intro.tscn` first. It shows the hook (“You woke at the bottom of the Stack…”) and “Tap or press any key to begin.” On key/tap, it loads the first level. |
| **Chapter title** | Each story level root has exports: **Chapter Title**, **Chapter Subtitle**, **Goal Message**. If you set them in the inspector (or in the .tscn), the level shows the chapter at the top of the screen when it loads (fade in → hold → fade out). Example: “Awakening” + “You don’t remember. You only know: up.” |
| **Cutscenes** | Use **CutsceneTrigger** instances and set **Cutscene Text** (and **Display Duration**, **Mode**: Ambient or Cinematic) to the lines from the “Example cutscene lines” table. Level 1 already has intro + ambient lines; add more per level. |
| **Goal message** | When the player reaches the Goal, the UI toast shows **Goal Message** if set (e.g. “First goal. The Stack awaits.” or “You reached the peak. The Stack holds its breath.”). Set **Goal Message** on the level root. |
| **Fail (story mode)** | If the player falls in Story mode, the fail panel title is “Fell. The Stack doesn’t forgive.” instead of “FELL!” |

**Where to set story text**

- **Intro screen:** `scenes/story/story_intro.tscn` — edit the HookLabel and ContinueLabel text in the scene.
- **Per level:** Open the level scene (e.g. `level_01.tscn`), select the root node (Level01), and in the Inspector set **Chapter Title**, **Chapter Subtitle**, **Goal Message**. Add or edit **CutsceneTrigger** nodes for in-level lines.
