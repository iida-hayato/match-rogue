# 04. Upgrade Systems

## Overview

The MVP supports three upgrade layers:

1. Deck additions
2. Coats
3. Relics

These should be modeled separately.

## 1. Deck Additions

Deck additions are special gem instances added to the player's deck.

They have:

- color
- base value
- special effect
- optional coats

They are drawn onto the board like normal gems.

They match by color.

When included in a match and cleared, they trigger their special effect.

After clearing, they go to discard and later return through shuffle.

### MVP Deck Addition Examples

| ID | Name | Color | Effect |
|---|---|---|---|
| red_vertical_rocket | Red Vertical Rocket | Red | Clears its column |
| blue_horizontal_rocket | Blue Horizontal Rocket | Blue | Clears its row |
| yellow_bomb | Yellow Bomb | Yellow | Clears surrounding 8 cells |
| purple_diagonal_beam | Purple Diagonal Beam | Purple | Clears both diagonals through its cell |
| green_coin_gem | Green Coin Gem | Green | Gain +1 gold when cleared, stage cap applies |

## 2. Coats

A coat is an additional effect attached to a gem instance.

A coat has active/spent state.

### Coat Lifecycle

```text
Draw pile: active
  -> Board: active
  -> Trigger condition met
  -> Coat effect resolves
  -> Coat becomes spent
  -> Board/Discard: spent
  -> Shuffle discard into draw pile
  -> Coat restores to active
```

The key rule:

> Coats activate at most once per deck cycle.

### Restore Timing

Restore spent coats when a gem moves from discard pile back into draw pile during shuffle.

### MVP Coat Examples

| ID | Name | Effect |
|---|---|---|
| gold_coat | Gold Coat | When cleared while active, gain +1 gold. Then spend. |
| polish_coat | Polish Coat | When scored while active, this gem value counts +50%. Then spend. |
| protection_coat | Protection Coat | When cleared while active, prevent the gem from being removed once; leave it as normal/spent on board. Restore original full state on shuffle. |
| repeat_coat | Repeat Coat | When cleared while active, place this gem on top of draw pile instead of discard. Then spend or restore depending on balance. MVP: spend until next shuffle. |
| chain_coat | Chain Coat | If cleared during chain 2+, add +0.20 chain multiplier. Then spend. |

### Protection Coat Simplification

For MVP, if a protection coat prevents removal of a special gem, the gem should remain on board as a normal gem of the same color with spent coat visuals.

When it later returns to the deck and is shuffled back to draw, restore the original special gem identity and active coat.

This avoids repeated special effect abuse while preserving the fantasy of a protective coating.

## 3. Relics

Relics are run-wide passive effects.

They should not be gem instances.

They listen to events and modify scoring, rewards, shop, or board effects.

### MVP Relic Categories

#### Clear Count Relics

| Name | Effect |
|---|---|
| Large Excavation Emblem | When clearing 6+ gems at once, clear_count_multiplier +0.30 |
| Mass Harvest Gloves | Clearing 8+ gems gives +2 gold |
| Weight Gauge | clear_count_multiplier cap +0.50 |
| Batch Polisher | Clearing 5+ gems upgrades one random normal gem by +1 value |

#### Chain Relics

| Name | Effect |
|---|---|
| Chain Gear | chain multiplier growth +0.05 |
| Avalanche Bell | 3+ chain gives +3 gold |
| Echo Furnace | 4+ chain triggers one small explosion |
| Chain Polisher | During chains, one cleared normal gem gets +5 value |

#### Economy / Shop Relics

| Name | Effect |
|---|---|
| Membership Card | Shop prices -15% |
| Piggy Bank | Stage end: gain +1 gold per 10 held, max +5 |
| Coating Artisan | After buying a product, add a random coat to a random normal gem |
| Frugal Bag | If buying nothing in shop, remove one random normal gem |

#### Temporary Match-3 Effect Relics

These are optional after core MVP.

| Name | Trigger | Effect |
|---|---|---|
| Rocket Workshop | Clearing 4+ gems at once | Fire a temporary rocket |
| Bomb Workshop | Clearing 6+ gems at once | Fire a temporary bomb |
| Prism Secret | Clearing 8+ gems at once | Clear one color or convert gems |

Important: temporary effects from relics are not added to the deck.

## Upgrade Design Principle

Deck additions change what appears.

Coats change individual gem behavior.

Relics change the rules.
