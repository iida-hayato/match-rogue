# 07. MVP Task Breakdown

## Phase 1: Static Play Screen

Goal: display the main play screen without gameplay.

Tasks:

- Create Godot project.
- Create `StagePlayScreen` scene.
- Create 8x8 board view.
- Create 5 placeholder gem visuals.
- Create HUD with Stage X/Y, Score, Moves, Gold.
- Create right panel with Draw, Discard, Shuffle, Relics, Items.

Done when:

- A screenshot clearly shows the intended play layout.

## Phase 2: Core Board Mechanics

Goal: playable match-3 board.

Tasks:

- Implement `BoardState`.
- Implement gem swapping.
- Implement match detection for horizontal/vertical 3+.
- Invalid swaps revert.
- Valid swaps consume one move.
- Clear matched gems.
- Apply gravity.
- Refill from deck.
- Resolve cascades.

Done when:

- Player can make matches and cascades happen.

## Phase 3: Deck / Discard System

Goal: falling gems come from deck.

Tasks:

- Implement initial 50-gem deck: 5 colors x 10 each.
- Draw gems to refill board.
- Cleared gems go to discard.
- When draw pile is empty, shuffle discard into draw.
- Show draw/discard counts in UI.

Done when:

- Board refills from finite deck and cycles correctly.

## Phase 4: Scoring

Goal: implement MVP scoring.

Tasks:

- Implement gem value.
- Implement clear count multiplier.
- Implement chain multiplier.
- Implement score breakdown.
- Update score HUD.
- Detect stage clear.
- Detect game over by moves.

Done when:

- Score calculation can be explained by UI breakdown.

## Phase 5: Stage Flow

Goal: full stage loop.

Tasks:

- Implement Stage Intro.
- Implement Stage Clear.
- Implement Game Over.
- Implement Result.
- Implement Stage X/Y progression.
- Implement fixed 14-stage run.
- Generate target score and move count per stage.

Done when:

- Player can clear/fail stages and proceed through a run.

## Phase 6: Gold and Shop

Goal: add economy and post-stage shop.

Tasks:

- Implement gold reward formula.
- Implement shop screen.
- Show next stage info in shop.
- Add product cards.
- Add buy action.
- Add reroll service.
- Add remove normal gem service.

Done when:

- Player can earn gold, buy products, and start next stage.

## Phase 7: Rewards

Goal: add post-stage 3-choice rewards.

Tasks:

- Implement Reward Select screen.
- Add reward types:
  - gold
  - gem value upgrade
  - special gem addition
  - relic
  - coat
- Apply chosen reward to run state.

Done when:

- Player can shape deck/build after each stage.

## Phase 8: Upgrade Systems MVP

Goal: implement minimal deck additions, coats, and relics.

### Special Gems

Implement:

- red vertical rocket
- blue horizontal rocket
- yellow bomb
- purple diagonal beam
- green coin gem

### Coats

Implement:

- gold coat
- polish coat
- protection coat
- chain coat

### Relics

Implement:

- Large Excavation Emblem
- Chain Gear
- Piggy Bank
- Membership Card
- Coating Artisan

Done when:

- At least 3 distinct build directions are possible:
  - high gem value
  - large clears
  - chains/economy

## Phase 9: Polish for itch.io MVP

Tasks:

- Add title screen.
- Add options screen.
- Add pause overlay.
- Add simple SFX placeholders.
- Add basic animations for swap/clear/refill.
- Add HTML5 export preset.
- Build and test in browser.

Done when:

- Game is playable as an itch.io web prototype.
