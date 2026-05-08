# 08. Open Questions and Tuning

## Open Questions

### Board Size

MVP default: 8x8.

Need testing:

- Is 8x8 readable on itch.io Web?
- Is 7x7 better for mobile-like browser windows?

### Stage Count

MVP default: 14 stages.

Need testing:

- Is 14 stages too long for a web demo?
- Should MVP demo end at 8 or 10 stages?

### Move Count

MVP provisional:

- early stages: 15 moves
- later stages: tune based on target score growth

Need testing:

- Are stages too easy if chains happen often?
- Are they too hard before upgrades appear?

### Target Score Curve

Need a score curve after the first playable prototype.

Initial placeholder:

```text
Stage 1: 500
Stage 2: 800
Stage 3: 1200
Stage 4: 1800
Stage 5: 2600
...
```

Do not lock this until scoring is tested.

### Rounding

MVP recommendation:

- floor final calculated score

Alternative:

- round to nearest integer

### Coats on Special Gems

Protection coat on special gems can be strong.

MVP simplification:

- If protection prevents a special gem from being removed, it becomes a normal spent gem on board.
- It restores its special identity when returning to draw pile through shuffle.

Need testing:

- Is this understandable?
- Should protection be normal-gem-only?

### Relic Shape Triggers

Current MVP avoids shape in base score.

Possible later relic triggers:

- clear 4+ gems at once -> temporary rocket
- clear 6+ gems at once -> temporary bomb
- clear 8+ gems at once -> temporary prism

Do not add too many before the base loop is proven.

## Tuning Principles

### Keep Default Chain Modest

Chains are partly random. Do not make default chain multiplier too dominant.

Let relics create chain builds.

### Keep Large Clears Understandable

Large clears should be visible and explained by score breakdown.

### Avoid Infinite Economy

Gold effects should have stage caps.

Examples:

- coin gem gold gain: max 10 per stage
- piggy bank interest: max 5 per stage
- cashback: max 10 per shop

### Separate Power Sources

Each upgrade layer should feel distinct:

- deck addition: changes what appears
- coat: changes an individual gem
- relic: changes rules

### MVP Success Criteria

The MVP is promising if players can describe their build as one of:

- I made high-value gems and tried to clear them together.
- I built around large clears.
- I built around chains.
- I built around gold/shop scaling.
- I built around coated/special gems.
