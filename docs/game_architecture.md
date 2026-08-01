# Grow Tower high-level structure

## Core idea
The game is a simple sequence-based tower builder. The player presses one of six buttons to add a block to the tower. Each block can react to the block that came before or after it, and the tower grows taller as the interactions resolve.

## Main scene
- Main scene: scenes/game.tscn
- Responsibilities:
  - host the UI buttons
  - hold the tower container
  - connect the game controller to the tower manager

## Script roles
- scripts/game_controller.gd
  - handles button input
  - spawns blocks in sequence
  - records the current order
- scripts/tower_manager.gd
  - stores the active blocks
  - tracks interactions between blocks
  - exposes tower state such as height
- scripts/block.gd
  - defines block behavior
  - stores block metadata such as name, color, and growth value
  - provides collision-driven interaction hooks for future animation work

## Scene pieces
- scenes/block.tscn
  - reusable block instance with a collision area, a visual shape, and a label
  - ready for animation work later

## Next implementation steps
1. Add richer block animations for growth and interaction states.
2. Replace the simple sequence trigger with rule-based combinations.
3. Add scoring or win conditions based on the maximum tower height.
