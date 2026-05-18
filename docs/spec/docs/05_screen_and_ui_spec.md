# 05. Screen and UI Spec

## MVP Screens

- Boot / Loading
- Title
- Stage Intro
- Stage Play
- Stage Clear
- Reward Select
- Shop
- Game Over
- Result
- Options
- Pause

No Run Setup screen for MVP.

## Stage Intro

Purpose: show the next stage clearly.

Display:

- Stage X / Y
- Target Score
- Moves
- Optional special rule
- Start button

Example:

```text
Stage 10 / 14
Target Score: 85,000
Moves: 15
[Start]
```

## Stage Play

Main game screen.

Recommended layout for 1280x720:

```text
+--------------------------------------------------------------+
| Stage 3/14  Score 4,250/8,000  Moves 9  Gold 18              |
|--------------------------------------------------------------|
|                                                              |
|  +---------------------------+   +------------------------+   |
|  |                           |   | Deck                   |   |
|  |        8 x 8 Board         |   | Draw: 23               |   |
|  |                           |   | Discard: 17            |   |
|  |                           |   | Shuffle: 1             |   |
|  |                           |   |                        |   |
|  |                           |   | Relics                 |   |
|  |                           |   | - Chain Gear           |   |
|  |                           |   | - Piggy Bank           |   |
|  +---------------------------+   |                        |   |
|                                  | Items                  |   |
|  Selected: Red Rocket            | [Hammer] [Shuffle]     |   |
|  Score Breakdown: ...            +------------------------+   |
+--------------------------------------------------------------+
```

Required HUD:

- Stage X / Y
- Score / Target Score
- Moves remaining
- Gold
- Draw pile count
- Discard pile count
- Shuffle count
- Relic list
- Consumable item slots

## Score Breakdown UI

After clears, show concise breakdown:

```text
Value 120 x Clear 1.70 x Chain 1.20 = 244
```

This is essential for player learning.

## Stage Clear

Display:

- Stage X / Y Clear
- Score / Target
- Moves Left
- Gold Earned
- Gold breakdown
- Continue

## Reward Select

MVP: 3 choices.

Possible reward types:

- add special gem
- add coat to gem
- gain relic
- upgrade gem values
- gain gold
- gain consumable item

Show cards with:

- name
- type
- tags
- effect summary
- choose button

## Shop

The shop appears after every cleared stage.

It also shows next stage information.

MVP shop layout:

```text
+----------------------------------------------------------------+
| Shop after Stage 10 / 14                   Gold: 31             |
|----------------------------------------------------------------|
| [Special Gem] [Special Gem] [Special Gem] [Relic]               |
|                                                                |
| Services                                                       |
| [Remove Gem: 8G] [Reroll: 3G]                                  |
|                                                                |
| Next: Stage 11 / 14                                            |
| Target Score: 110,000                                          |
| Moves: 15                                                      |
|                                                                |
| [Start Next Stage]                                             |
+----------------------------------------------------------------+
```

MVP shop slots:

- special gem x3
- relic x1
- consumable or coat service x1
- permanent remove gem service
- reroll service

Special gems should be sampled from the allowed effect/color combinations rather than being fixed to one color per effect.
If a special gem is a value bundle, show the value badge on the icon and keep the badge in the top-right corner.

## Game Over

Display:

- Game Over
- Reason: Out of moves
- Reached Stage X / Y
- Final Score / Target
- Main build summary
- Retry / Result / Title

## Result

Display:

- Reached Stage X / Y or Run Clear
- total gold earned
- max chain
- largest clear count
- final deck summary
- relics acquired
- retry / title

## Options

MVP options:

- master volume
- BGM volume
- SE volume
- animation speed
- screen shake on/off

## Visual Notes

Use shape as well as color to distinguish normal gem colors.

Suggested normal gem shapes:

- Red: circle
- Blue: diamond
- Green: hexagon
- Yellow: star
- Purple: triangle

Coats need active/spent visual states.

Active coat: glow/edge/overlay visible.

Spent coat: dimmed or cracked overlay.
