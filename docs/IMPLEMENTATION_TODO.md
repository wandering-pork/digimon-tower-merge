# Implementation TODO

> Last Updated: Feb 2026

This document tracks remaining implementation work identified during code reviews.

---

## Completed Work Summary

All major refactoring tasks have been completed. The codebase now:
- Builds successfully with Godot 4.6
- Has proper component separation (30+ new files)
- Uses centralized error handling (ErrorHandler)
- Has O(1) enemy lookups (cached)
- Follows 300-line file convention (most files)
- Has proper memory leak prevention (_exit_tree)

**Architecture Score: 9.2/10** (up from 6.0/10 pre-refactor)

---

## Remaining Work (Low Priority)

### 1. Audio Bus Configuration
**Status:** DONE
**Location:** `default_bus_layout.tres`

Created Music and SFX audio buses. Added 17 retro sound effects in `assets/audio/sfx/`.

### 2. GUT Testing Framework
**Status:** DONE (structure ready, addon install pending)
**Location:** `tests/`, `.gutconfig.json`

Created test infrastructure:
- `.gutconfig.json` - GUT configuration
- `tests/unit/test_game_config.gd` - 45+ tests for GameConfig
- `tests/unit/test_economy_system.gd` - 30+ tests for EconomySystem
- `tests/README.md` - Installation and usage guide

**To complete:** Install GUT addon from AssetLib and enable plugin.

### 3. Dependency Injection Pattern
**Priority:** Low
**Effort:** Medium

Consider implementing DI for better testability:
- Pass dependencies through constructors/setup methods
- Reduces coupling to autoload singletons
- Enables mock injection for testing

### 4. Formula Documentation
**Status:** DONE
**Location:** `scripts/towers/tower_combat_component.gd`

Added comprehensive damage formula documentation:
- Complete formula explanation
- Scaling factors with reference tables
- Three worked example calculations

---

## Completed Work (Reference)

### Session 1 (Feb 2026)
- [x] GameConfig autoload - centralized constants
- [x] EnemyStateMachine - proper state pattern
- [x] WaveStateMachine - wave flow states
- [x] Memory leak fixes - _exit_tree() in major files
- [x] Split digimon_tower.gd - combat + progression components
- [x] Split wave_generator.gd - config, composition, modifiers
- [x] Split enemy_digimon.gd - effects + combat components
- [x] Cache path calculations - O(1) progress queries
- [x] Register GameConfig in project.godot

### Session 2 (Feb 2026)
- [x] Integrate WaveStateMachine into WaveManager
- [x] Add _exit_tree() to all component classes
- [x] Remove duplicate constants from wave_manager.gd
- [x] Split combat_system.gd - projectile factory + damage processor
- [x] Split main_level.gd - UI coordinator + input handler

### Session 3 (Feb 2026)
- [x] Split grid_manager.gd (433 lines) -> grid_manager + path_manager
- [x] Add ASCII path documentation to path_manager.gd

### Session 4 (Feb 2026)
- [x] Split projectile.gd (472 -> 281 + 246 + 212 lines)

### Session 5 (Feb 2026)
- [x] Split status_effects.gd (456 -> 295 + 132 + 190 + 189 lines)

### Session 6 (Feb 2026)
- [x] Split wave_manager.gd (519 -> 280 + 190 lines)

### Session 7 (Feb 2026)
- [x] Create interface abstractions (i_attacker, i_damageable, i_targetable, i_effect_receiver)
- [x] Add ErrorHandler autoload with severity levels
- [x] Integrate ErrorHandler across 22 files
- [x] Cache enemy list in combat_system (O(1) lookup)
- [x] Fix constant duplication (game_manager, economy_system, spawn_system use GameConfig)
- [x] Split digimon_tower.gd further (visual + ui components)

### Session 8 (Feb 2026) - Build Fixes
- [x] Fix autoload class_name conflicts (removed class_name from autoloads)
- [x] Add preload constants to 25+ files for type resolution
- [x] Fix circular dependencies (changed type hints to Node where needed)
- [x] Inline utility functions in damage_effects.gd (break circular dep)
- [x] Verify build passes with Godot 4.6

---

## Architecture Score Tracking

| Date | Score | Notes |
|------|-------|-------|
| Pre-refactor | ~6.0/10 | Monolithic files, no state machines |
| Session 1 | 7.5/10 | Components, state machines, GameConfig |
| Session 2 | 8.0/10 | All state machines integrated |
| Session 7 | 8.5/10 | ErrorHandler, interfaces, all splits done |
| Session 8 | 8.5/10 | Build verified, type resolution fixed |
| Session 9 | 9.0/10 | Audio, tests, documentation complete |
| Session 10 | 9.2/10 | Critical fixes, file splits, typed arrays |
| Target | 9.5/10 | Install GUT, add more tests |

---

## Files Created During Refactoring (33 total)

### Autoloads
- `scripts/autoload/game_config.gd` - Centralized game constants
- `scripts/autoload/error_handler.gd` - Centralized error logging

### Interfaces
- `scripts/interfaces/i_attacker.gd` - Damage dealer interface
- `scripts/interfaces/i_damageable.gd` - Damage receiver interface
- `scripts/interfaces/i_targetable.gd` - Targeting interface
- `scripts/interfaces/i_effect_receiver.gd` - Status effect interface

### Enemy Components
- `scripts/enemies/enemy_state_machine.gd` - Enemy state management
- `scripts/enemies/enemy_effects_component.gd` - Status effects handling
- `scripts/enemies/enemy_combat_component.gd` - Combat and HP
- `scripts/enemies/enemy_movement_component.gd` - Path following and knockback
- `scripts/enemies/enemy_splitter_component.gd` - Split enemy spawning

### Tower Components
- `scripts/towers/tower_combat_component.gd` - Targeting and attacking
- `scripts/towers/tower_progression_component.gd` - Leveling and evolution
- `scripts/towers/tower_visual_component.gd` - Sprites and animations
- `scripts/towers/tower_ui_component.gd` - Labels and indicators

### Wave System
- `scripts/systems/wave_state_machine.gd` - Wave flow states
- `scripts/systems/wave_spawner.gd` - Enemy instantiation
- `scripts/systems/wave_config_database.gd` - Wave definitions
- `scripts/systems/enemy_composition.gd` - Enemy group building
- `scripts/systems/wave_modifier_system.gd` - Late game modifiers
- `scripts/systems/wave_reward_calculator.gd` - Reward calculations
- `scripts/systems/path_manager.gd` - Path and waypoints

### Combat System
- `scripts/combat/combat_projectile_factory.gd` - Projectile creation
- `scripts/combat/combat_damage_processor.gd` - Damage calculations
- `scripts/combat/projectile_behaviors.gd` - Movement behaviors
- `scripts/combat/projectile_effects.gd` - On-hit effects
- `scripts/combat/damage_effects.gd` - DoT effects
- `scripts/combat/control_effects.gd` - CC effects
- `scripts/combat/debuff_effects.gd` - Debuff effects

### Level System
- `scripts/levels/level_ui_coordinator.gd` - UI panel management
- `scripts/levels/level_input_handler.gd` - Input processing

---

## GDScript Best Practices Learned

### Type Resolution in Godot 4.x
1. **Autoloads don't need class_name** - They register as globals automatically
2. **Use preload() for cross-file types** - Required for type hints to work
3. **Avoid circular dependencies** - Use base types (Node) when needed
4. **Pattern for preloads:**
   ```gdscript
   const DigimonData = preload("res://scripts/data/digimon_data.gd")
   ```

### Memory Leak Prevention
- Always implement `_exit_tree()` in components
- Disconnect signals before nulling references
- Clear arrays and dictionaries
- Check `is_connected()` before disconnecting

### Component Architecture
- Parent class coordinates components
- Components receive parent reference via `setup()`
- Use signals for component-to-parent communication
- Keep components focused (single responsibility)
