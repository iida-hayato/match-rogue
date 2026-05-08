# 01. Current Design Summary

## Game Concept

A match-3 roguelike deckbuilder.

The board is filled by drawing gems from the player's deck. Cleared gems go to the discard pile. When the draw pile is empty, the discard pile is shuffled back into the draw pile.

The player clears stages by exceeding a target score within a move limit. After each stage, the player receives gold, chooses rewards, visits a shop, and proceeds to the next stage.

## Core Differentiator

In normal match-3 games, falling pieces are random. In this game, falling pieces come from the player's deck.

This means deck construction directly changes the match-3 board.

## MVP Target

Implement a playable MVP in Godot 4.x for itch.io Web first.

Target platform order:

1. itch.io Web build
2. Windows build
3. macOS build

## Current Fixed Decisions

- No Run Setup screen for MVP.
- Initial deck: 50 gems, 5 colors x 10 each.
- Stage progress displayed as `Stage X / Y`, e.g. `Stage 10 / 14`.
- MVP can use 14 stages as a provisional run length.
- Player visits shop after every cleared stage.
- Shop also shows next stage information.
- Main score axis is not match shape. It is:
  - gem value
  - number of gems cleared at once
  - chain count
- Match shape is not part of base score in MVP.
- Shape-based effects may be introduced later through relics.

## Upgrade Layers

There are three major upgrade layers.

### 1. Deck Additions

Special gems added to the deck.

Examples:

- colored vertical rocket gem
- colored horizontal rocket gem
- colored bomb gem
- colored diagonal beam gem
- coin gem

These appear from the deck, can be matched by color, trigger when matched, and return through the discard/draw cycle.

### 2. Coats

A coat is an additional effect attached to an individual gem instance.

A coat activates at most once per deck cycle. After activation, it becomes spent while on the board and in discard. It restores when the gem returns to the draw pile during shuffle.

Examples:

- score coat
- gold coat
- protective coat
- repeat coat
- chain coat

### 3. Relics

Run-wide passive effects that change rules or scoring growth.

Examples:

- improve clear-count multiplier growth
- improve chain multiplier growth
- create temporary rockets when clearing many gems
- improve shop prices
- coat random gems after purchases

## Design Principle

The game should be understandable without special effects.

The basic loop should be:

> Build high-value gems, clear many at once, and multiply by chains.

Special gems, coats, and relics should amplify or redirect that core loop rather than replace it.
