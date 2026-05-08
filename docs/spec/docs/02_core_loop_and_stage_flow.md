# 02. Core Loop and Stage Flow

## Run Flow

```text
Boot
  -> Title
  -> Stage Intro: Stage 1 / 14
  -> Stage Play
  -> Stage Clear
  -> Reward Select
  -> Shop
  -> Stage Intro: Stage 2 / 14
  -> ...
  -> Stage 14 / 14
  -> Run Clear or Game Over
  -> Result
```

## Stage Clear Condition

A stage is cleared when current stage score reaches or exceeds the target score before moves run out.

## Game Over Condition

The main game over condition is:

```text
moves_remaining <= 0 AND stage_score < target_score
```

For MVP, do not add shuffle-count loss conditions.

## Stage Progress Display

Every run uses a fixed max stage count for MVP.

Example:

```text
Stage 10 / 14
```

Show this in:

- Stage Intro
- Stage Play HUD
- Stage Clear
- Shop
- Result

## Stage Play Loop

```text
Player swaps adjacent gems
  -> if swap creates a valid match, consume 1 move
  -> resolve matched gems
  -> score cleared gems
  -> trigger gem effects and coat effects
  -> apply gravity
  -> refill from draw pile
  -> if draw pile empty, shuffle discard into draw pile and restore coats
  -> detect cascades
  -> repeat cascade resolution until stable
  -> if no possible moves, auto-shuffle board
```

## Move Consumption Rule

Only valid swaps that create at least one match consume a move.

Invalid swaps should revert and consume no move.

## Deck Flow

```text
Draw pile -> Board -> Discard pile -> Shuffle -> Draw pile
```

When a gem leaves the board by being cleared, it goes to discard unless an effect says otherwise.

When the draw pile is empty and new gems must be drawn, shuffle the discard pile into the draw pile.

At this shuffle moment, restore all spent coats.

## Stage Clear Rewards

After clearing a stage:

1. Show Stage Clear screen.
2. Grant gold.
3. Show Reward Select screen.
4. Go to Shop.
5. Shop shows next stage info.
6. Player starts next stage.

## Gold Reward Formula - MVP Default

```text
stage_gold = clear_bonus + moves_left_bonus + over_score_bonus
```

Suggested defaults:

- clear_bonus: 8 gold
- moves_left_bonus: moves_left x 1 gold
- over_score_bonus: +1 gold per 1000 score over target, max +5

These are tuning values.
