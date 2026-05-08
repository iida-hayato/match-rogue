# 06. Godot Implementation Spec

## Engine

Use Godot 4.x with GDScript.

Target MVP export:

- Web / HTML5 for itch.io first
- native Windows/Mac later

## Project Structure

```text
scenes/
  app/
    boot_scene.tscn
    main_scene.tscn
  screens/
    title_screen.tscn
    stage_intro_screen.tscn
    stage_play_screen.tscn
    stage_clear_screen.tscn
    reward_select_screen.tscn
    shop_screen.tscn
    game_over_screen.tscn
    result_screen.tscn
    options_screen.tscn
    pause_overlay.tscn
  components/
    board_view.tscn
    gem_view.tscn
    reward_card.tscn
    shop_item_card.tscn
    relic_icon.tscn
    tooltip.tscn
    modal_dialog.tscn

scripts/
  domain/
    run_state.gd
    stage_state.gd
    stage_plan.gd
    gem_definition.gd
    gem_instance.gd
    coat_definition.gd
    coat_state.gd
    relic_definition.gd
    deck_state.gd
    board_state.gd
    match_resolver.gd
    cascade_resolver.gd
    score_calculator.gd
    effect_resolver.gd
    reward_generator.gd
    shop_service.gd
  ui/
    stage_play_screen.gd
    shop_screen.gd
    reward_select_screen.gd
    result_screen.gd
  data/
    gem_master.gd
    coat_master.gd
    relic_master.gd
    stage_master.gd
```

## Domain Model

### RunState

```gdscript
class_name RunState

var stage_index: int
var max_stages: int
var deck: DeckState
var relic_ids: Array[String]
var consumables: Array[String]
var gold: int
var total_gold_earned: int
var run_seed: int
```

### StagePlan

```gdscript
class_name StagePlan

var stage_index: int
var max_stages: int
var target_score: int
var move_limit: int
var rule_ids: Array[String]
var reward_profile: String
var is_boss: bool
```

MVP generates only one next stage at a time.

Later expansion can generate multiple route candidates.

### StageState

```gdscript
class_name StageState

var plan: StagePlan
var score: int
var moves_remaining: int
var chain_index: int
var shuffle_count: int
var gold_earned_this_stage: int
var board: BoardState
```

### GemDefinition

```gdscript
class_name GemDefinition

var id: String
var color: String
var base_value: int
var special_effect_id: String # optional
var display_name: String
var tags: Array[String]
```

### GemInstance

```gdscript
class_name GemInstance

var instance_id: String
var definition_id: String
var value_bonus: int
var coat_states: Array[CoatState]
var runtime_flags: Dictionary

func total_value(definition: GemDefinition) -> int:
    return definition.base_value + value_bonus
```

### CoatDefinition

```gdscript
class_name CoatDefinition

var id: String
var display_name: String
var trigger_id: String
var effect_id: String
var applicable_tags: Array[String]
```

### CoatState

```gdscript
class_name CoatState

var coat_id: String
var is_active: bool = true
```

### RelicDefinition

```gdscript
class_name RelicDefinition

var id: String
var display_name: String
var trigger_id: String
var effect_id: String
var tags: Array[String]
```

### DeckState

```gdscript
class_name DeckState

var draw_pile: Array[GemInstance]
var discard_pile: Array[GemInstance]

func draw_one() -> GemInstance:
    # If draw pile empty, shuffle discard into draw and restore coats.
    pass

func restore_coats_on_shuffle() -> void:
    for gem in draw_pile:
        for coat in gem.coat_states:
            coat.is_active = true
```

## Board Resolution

### BoardState

Board should store gem instance references or IDs.

```gdscript
class_name BoardState

var width: int = 8
var height: int = 8
var cells: Array # 2D flattened array of GemInstance or null
```

### MatchResolver

Responsibilities:

- detect horizontal/vertical matches of 3+
- return match groups
- merge groups into one clear set for each resolution step

MVP does not need to score shape.

### CascadeResolver

Responsibilities:

- clear matched gems
- send cleared gems to discard unless overridden
- apply gravity
- refill from deck
- repeat until no matches
- increment chain index each resolution step

### ScoreCalculator

Input:

- cleared gems
- clear_count
- chain_index
- active relics
- active coats

Output:

- score_delta
- breakdown data

## Effect System

Use an event-based approach.

Important events:

- `OnGemCleared`
- `OnResolutionStepScored`
- `OnChainStarted`
- `OnStageCleared`
- `OnShopEntered`
- `OnProductBought`
- `OnDeckShuffled`

Relics and coats can subscribe conceptually through `EffectResolver`.

MVP can implement this with direct method calls rather than a full event bus, but keep the structure clear.

## UI Implementation Notes

Use Control and Container nodes for UI.

Avoid absolute positioning when possible.

Recommended root resolution:

```text
1280 x 720
```

Use a `MainScene` to manage screen transitions.

Do not place core game rules inside UI scripts.

UI should emit intents:

- buy_requested(product_id)
- reward_chosen(reward_id)
- start_next_stage_requested()
- swap_requested(from_cell, to_cell)

Domain services should validate and mutate state.
