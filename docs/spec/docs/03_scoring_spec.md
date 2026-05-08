# 03. Scoring Spec

## Core Scoring Formula

The MVP scoring formula is:

```text
score = sum(gem_value) * clear_count_multiplier * chain_multiplier
```

Do not include match shape in the base score for MVP.

## Why Not Shape-Based Base Score?

Shape-based scoring such as L-shape, T-shape, cross, or 5-in-a-row is harder to understand when cascades and simultaneous clears happen.

MVP scoring should be explainable as:

> High-value gems cleared in large groups during chains produce high score.

## Gem Value

Each gem instance has a value.

Default normal gem value:

```text
10
```

Gem upgrades can create values such as:

```text
15, 20, 35
```

Represent these as base value plus upgrades:

- normal: 10
- +5 gem: 15
- +10 gem: 20
- +25 gem: 35

Gem value is stored on the gem instance, not only on the board cell. If a +10 red gem is cleared and later returns from the deck, it remains +10.

## Clear Count Multiplier

The clear count multiplier depends on how many gems are cleared in one resolution step.

MVP default:

| Cleared Count | Multiplier |
|---:|---:|
| 3 | x1.00 |
| 4 | x1.10 |
| 5 | x1.25 |
| 6 | x1.45 |
| 7 | x1.70 |
| 8 | x2.00 |
| 9+ | x2.00 + 0.10 per gem above 8 |

Definition:

```text
clear_count = number of gems cleared in the same resolution step
```

If multiple independent groups are cleared at the same time, count the total number of gems cleared in that step.

## Chain Multiplier

The chain multiplier depends on cascade index.

The initial player-created clear is chain 1.

MVP default:

| Chain Index | Multiplier |
|---:|---:|
| 1 | x1.00 |
| 2 | x1.10 |
| 3 | x1.20 |
| 4 | x1.35 |
| 5 | x1.50 |
| 6+ | x1.50 + 0.15 per chain above 5 |

## Scoring Examples

### Basic 3 Clear

```text
values = [10, 10, 10]
sum = 30
clear_count_multiplier = x1.00
chain_multiplier = x1.00
score = 30
```

### 5 Clear

```text
values = [10, 10, 10, 10, 10]
sum = 50
clear_count_multiplier = x1.25
chain_multiplier = x1.00
score = 62.5 -> round to 63 or floor to 62
```

Use integer rounding consistently. MVP recommendation: floor final score.

### Chain 3 with 8 Gems Cleared

```text
sum = 120
clear_count_multiplier = x2.00
chain_multiplier = x1.20
score = 288
```

## Relic Interaction

Relics should mainly modify:

- clear_count_multiplier growth
- chain_multiplier growth
- gem_value upgrades

Examples:

```text
Large Excavation Emblem:
When clearing 6+ gems at once, clear_count_multiplier +0.30.

Chain Gear:
chain_multiplier growth +0.05 per chain.

Polishing Kit:
After clearing 8+ gems, upgrade one random normal gem by +5.
```

## UI Requirement

Show score breakdown after significant clears.

Example:

```text
Gem Value: 120
Clear Bonus: x1.70
Chain Bonus: x1.20
Total: 244
```

This is important because score explanation is part of the game feel.
