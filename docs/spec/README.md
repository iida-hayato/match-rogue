# Gem Match Roguelike - Implementation Brief v2

This package is a Gemini-ready implementation brief for a Godot 4.x MVP of a match-3 roguelike deckbuilder.

The current design intentionally focuses on a small but extensible core:

- Match-3 board where falling gems are drawn from a deck.
- Stage progression with move limit and target score.
- Money and shop after each stage.
- Score axis based on gem value, number of gems cleared at once, and chain count.
- Three upgrade layers: deck additions, coats, and relics.
- MVP-first implementation, with later expansion toward richer special effects.

Recommended reading order for implementation agents:

1. `docs/01_current_design_summary.md`
2. `docs/02_core_loop_and_stage_flow.md`
3. `docs/03_scoring_spec.md`
4. `docs/04_upgrade_systems.md`
5. `docs/05_screen_and_ui_spec.md`
6. `docs/06_godot_implementation_spec.md`
7. `docs/07_mvp_task_breakdown.md`
8. `docs/08_open_questions_and_tuning.md`

This is not a final production design. Numbers are MVP tuning defaults and should be adjusted after playable testing.
