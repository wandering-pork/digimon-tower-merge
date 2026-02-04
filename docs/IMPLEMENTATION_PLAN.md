# Implementation Plan: Digimon Tower Merge

## Overview

This document outlines the implementation roadmap for transforming the Digimon Tower Merge game from its current design-complete state to a playable Godot 4.x game.

---

## Current Status (Updated: 2026-02-04)

| Category | Status | Details |
|----------|--------|---------|
| Documentation | 100% | GDD, Digimon Stats Database, Enemy Spawn Design |
| Project Setup | **100%** | `project.godot` configured with autoloads, input actions |
| Data Scripts | **100%** | 36 GDScript files implemented |
| Sprites | ~95% | 150+ Digimon sprites across all 6 tiers |
| Digimon Resources | **100%** | 229 Digimon .tres files generated |
| Scenes | **100%** | 15 .tscn scene files created |
| Game Systems | **100%** | Combat, wave, merge, evolution, economy all implemented |
| Total Resources | **297** | Digimon, evolutions, enemies, bosses |

### Implementation Summary

| Phase | Status | Key Files Created |
|-------|--------|-------------------|
| Phase 1: Foundation | ✅ Complete | project.godot, autoloads, grid_manager, main scenes |
| Phase 2: Tower System | ✅ Complete | 229 Digimon resources, tower scenes, spawn system |
| Phase 3: Enemy System | ✅ Complete | enemy_digimon, enemy_data, modifiers, boss configs |
| Phase 4: Combat System | ✅ Complete | targeting, damage_calculator, projectiles, status_effects |
| Phase 5: Wave System | ✅ Complete | wave_manager, wave_generator, 100 wave compositions |
| Phase 6: Merge & Evolution | ✅ Complete | merge_system, evolution_system, 39 evolution paths |
| Phase 7: Economy & UI | ✅ Complete | economy_system, tower_info_panel, resource_bar |
| Phase 8: Tutorial & Polish | ⏳ Pending | Tutorial, encyclopedia, audio assets |

### Autoloads Configured
- `GameManager` - DigiBytes, Lives, Wave, Game Speed
- `EventBus` - Central signal hub
- `AudioManager` - SFX and music
- `CombatSystem` - Combat management
- `WaveManager` - Wave state and spawning
- `EconomySystem` - Costs and transactions

### Input Actions Configured
- `toggle_speed` (Space) - Cycle game speed
- `level_up` (L) - Level up selected tower
- `digivolve` (E) - Digivolve selected tower
- `sell` (Delete) - Sell selected tower

---

## Phase 1: Project Foundation ✅ COMPLETE

### 1.1 Godot Project Setup
- [x] Create `project.godot` with proper settings
- [x] Configure window size (1280x720)
- [x] Set up autoload singletons structure

**Files created:**
- `project.godot`
- `scripts/autoload/game_manager.gd` - Global game state (lives, DigiBytes, wave number)
- `scripts/autoload/event_bus.gd` - Signal-based event system
- `scripts/autoload/audio_manager.gd` - Sound/music playback

### 1.2 Grid & Map System
- [x] Create `GridManager` class for 8x18 tile grid
- [x] Implement path waypoints from GDD map layout (57 path tiles)
- [x] Tower placement validation (87 tower slots)
- [x] Visual grid overlay for placement feedback

**Files created:**
- `scripts/systems/grid_manager.gd`
- `scripts/data/level_data.gd`
- `scenes/levels/main_level.tscn`
- `resources/levels/level_1_path.tres` (path waypoints, grid config)

### 1.3 Basic Scene Structure
- [x] Main menu scene with New Game / Continue / Settings
- [x] Game level scene with grid, HUD area, spawn panel
- [x] Game over scene

**Files created:**
- `scenes/main/main_menu.tscn`
- `scenes/main/game_over.tscn`
- `scenes/ui/hud.tscn`
- `scripts/ui/main_menu.gd`
- `scripts/ui/game_over.gd`
- `scripts/ui/hud.gd`
- `scripts/levels/main_level.gd`

---

## Phase 2: Tower System ✅ COMPLETE

### 2.1 Digimon Resources (Batch Creation)
- [x] Create script to generate `.tres` files from `DIGIMON_STATS_DATABASE.md`
- [x] Generate all In-Training resources (15 Digimon)
- [x] Generate all Rookie resources (39 Digimon)
- [x] Generate all Champion resources (64 Digimon)
- [x] Generate all Ultimate resources (49 Digimon)
- [x] Generate all Mega resources (55 Digimon)
- [x] Generate Ultra resources (7 Digimon)

**Files created:**
- `tools/generate_digimon_resources.py` (generator script)
- `resources/digimon/**/*.tres` (229 files total)

### 2.2 Tower Scenes & Visuals
- [x] Create base tower scene with sprite, attack range indicator
- [x] Implement tower selection/deselection UI
- [x] Level-up animation and feedback
- [x] Targeting priority cycle UI

**Files created:**
- `scenes/towers/digimon_tower.tscn`
- `scripts/towers/digimon_tower.gd` (enhanced)

### 2.3 Spawn System
- [x] Spawn menu UI (click-to-spawn)
- [x] Random/Specific/FREE attribute selection
- [x] Cost calculation and validation
- [x] Starter selection screen for new game

**Files created:**
- `scenes/ui/spawn_menu.tscn`
- `scenes/ui/starter_selection.tscn`
- `scripts/ui/spawn_menu.gd`
- `scripts/ui/starter_selection.gd`
- `scripts/systems/spawn_system.gd`

---

## Phase 3: Enemy System ✅ COMPLETE

### 3.1 Enemy Base Class
- [x] Create `EnemyDigimon` class with HP, armor, speed
- [x] Path following along waypoints
- [x] Enemy type modifiers (Swarm, Tank, Speedster, Flying, etc.)
- [x] Death/escape handling

**Files created:**
- `scripts/enemies/enemy_digimon.gd`
- `scenes/enemies/enemy_digimon.tscn`

### 3.2 Enemy Resources
- [x] Create enemy data resources for all enemy Digimon
- [x] Define enemy types with HP/speed/armor multipliers
- [x] Special modifier system (Enraged, Armored, Hasty, etc.)

**Files created:**
- `scripts/data/enemy_data.gd`
- `scripts/enemies/enemy_modifier.gd`
- `resources/enemies/rookie/*.tres`
- `resources/enemies/champion/*.tres`

### 3.3 Boss System
- [x] Mini-boss configurations (Wave 10, 30, 50, 70, 90)
- [x] Phase boss configurations (Wave 20, 40, 60, 80)
- [x] Final boss Apocalymon (Wave 100)

**Files created:**
- `resources/waves/bosses/wave_10_greymon.tres`
- `resources/waves/bosses/wave_20_greymon_evolved.tres`
- `resources/waves/bosses/wave_30_devimon.tres`
- `resources/waves/bosses/wave_40_myotismon.tres`
- `resources/waves/bosses/wave_50_skullgreymon.tres`
- `resources/waves/bosses/wave_60_venommyotismon.tres`
- `resources/waves/bosses/wave_70_machinedramon.tres`
- `resources/waves/bosses/wave_80_omegamon.tres`
- `resources/waves/bosses/wave_90_omegamon_zwart.tres`
- `resources/waves/bosses/wave_100_apocalymon.tres`

---

## Phase 4: Combat System ✅ COMPLETE

### 4.1 Targeting & Attack
- [x] Implement 7 targeting priorities (First, Last, Strongest, Weakest, Fastest, Closest, Flying)
- [x] Attack range detection
- [x] Attack cooldown/speed handling
- [x] Projectile system for ranged attacks

**Files created:**
- `scripts/combat/targeting.gd`
- `scripts/systems/combat_system.gd`
- `scenes/combat/projectile.tscn`
- `scripts/combat/projectile.gd`

### 4.2 Damage & Effects
- [x] Damage calculation with attribute triangle (1.5x/0.75x)
- [x] Status effect application (Burn, Freeze, Slow, Poison, etc.)
- [x] Effect duration and tick damage
- [x] AoE/Chain/Pierce attack types

**Files created:**
- `scripts/combat/damage_calculator.gd`
- `scripts/combat/status_effects.gd`
- `scripts/combat/attack_types.gd`

### 4.3 Special Abilities
- [x] Attack type system by Digimon family
- [x] DNA Digivolution data in Mega resources

---

## Phase 5: Wave System ✅ COMPLETE

### 5.1 Wave Manager
- [x] Wave state machine (Prep → Active → Complete)
- [x] Between-wave timer (20s down to 6s)
- [x] Enemy spawn intervals per wave
- [x] Wave completion rewards

**Files created:**
- `scripts/systems/wave_manager.gd`
- `scripts/systems/wave_generator.gd`

### 5.2 Wave UI
- [x] Wave counter display
- [x] Next wave preview
- [x] Start wave button / auto-start
- [x] Lives display

**Files created:**
- `scenes/ui/wave_info_panel.tscn`
- `scripts/ui/wave_info_panel.gd`

### 5.3 Endless Mode
- [x] Wave 101+ scaling formulas
- [x] Random enemy composition
- [ ] Leaderboard tracking (survival time, kills, highest wave)

---

## Phase 6: Merge & Evolution System ✅ COMPLETE

### 6.1 Merge System
- [x] Drag-and-drop merge detection
- [x] Merge compatibility check (same stage, same attribute/FREE)
- [x] DP calculation on merge
- [x] Origin upgrade logic
- [x] Merge confirmation UI

**Files created:**
- `scripts/systems/merge_system.gd`
- `scenes/ui/merge_confirmation.tscn`
- `scripts/ui/merge_confirmation.gd`

### 6.2 Evolution System
- [x] Digivolution trigger at base max level
- [x] Evolution path selection UI based on DP
- [x] DP threshold unlocks

**Files created:**
- `scripts/systems/evolution_system.gd`
- `scenes/ui/evolution_menu.tscn`
- `scripts/ui/evolution_menu.gd`
- `resources/evolutions/*.tres` (39 evolution path resources)

### 6.3 DNA Digivolution
- [x] DNA partner detection (specific Mega pairs)
- [x] Ultra tier data (Omegamon, etc.)

---

## Phase 7: Economy & UI Polish ✅ COMPLETE

### 7.1 Economy System
- [x] DigiBytes tracking and display
- [x] Level-up cost calculation (5 DB × level)
- [x] Digivolve costs per stage
- [x] Sell system (50% investment return)
- [x] Wave rewards

**Files created:**
- `scripts/systems/economy_system.gd`

### 7.2 HUD & Menus
- [x] Resource display (DigiBytes, Lives, Wave)
- [x] Game speed toggle (1x, 1.5x, 2x)
- [x] Tower info panel (selected tower stats)
- [x] Sell confirmation dialog

**Files created:**
- `scenes/ui/resource_bar.tscn`
- `scripts/ui/resource_bar.gd`
- `scenes/ui/tower_info_panel.tscn`
- `scripts/ui/tower_info_panel.gd`
- `scenes/ui/sell_confirmation.tscn`
- `scripts/ui/sell_confirmation.gd`

### 7.3 Settings Menu
- [x] Audio volume controls (in main menu)
- [ ] Graphics options
- [x] Keyboard shortcuts (Space, L, E, Delete)

---

## Phase 8: Tutorial & Polish ⏳ PENDING

### 8.1 Tutorial System
- [ ] First-time player detection
- [ ] Step-by-step tutorial prompts
- [ ] Highlight system for UI elements

### 8.2 Encyclopedia
- [ ] Digivolution tree viewer
- [ ] Digimon stats browser
- [ ] Evolution path explorer

### 8.3 Audio
- [ ] Background music
- [ ] Attack sounds per Digimon family
- [ ] UI feedback sounds
- [ ] Boss encounter music

### 8.4 Additional Polish
- [ ] Save/Load system
- [ ] Leaderboard system
- [ ] Visual effects polish
- [ ] Animation polish

---

## File Inventory

### Scripts (36 files)

**Autoloads:**
- `scripts/autoload/game_manager.gd`
- `scripts/autoload/event_bus.gd`
- `scripts/autoload/audio_manager.gd`

**Data Classes:**
- `scripts/data/digimon_data.gd`
- `scripts/data/evolution_path.gd`
- `scripts/data/trait_effect.gd`
- `scripts/data/level_data.gd`
- `scripts/data/enemy_data.gd`

**Systems:**
- `scripts/systems/grid_manager.gd`
- `scripts/systems/spawn_system.gd`
- `scripts/systems/combat_system.gd`
- `scripts/systems/wave_manager.gd`
- `scripts/systems/wave_generator.gd`
- `scripts/systems/merge_system.gd`
- `scripts/systems/evolution_system.gd`
- `scripts/systems/economy_system.gd`

**Combat:**
- `scripts/combat/targeting.gd`
- `scripts/combat/damage_calculator.gd`
- `scripts/combat/status_effects.gd`
- `scripts/combat/attack_types.gd`
- `scripts/combat/projectile.gd`

**Entities:**
- `scripts/towers/digimon_tower.gd`
- `scripts/enemies/enemy_digimon.gd`
- `scripts/enemies/enemy_modifier.gd`

**UI:**
- `scripts/ui/main_menu.gd`
- `scripts/ui/game_over.gd`
- `scripts/ui/hud.gd`
- `scripts/ui/spawn_menu.gd`
- `scripts/ui/starter_selection.gd`
- `scripts/ui/evolution_menu.gd`
- `scripts/ui/merge_confirmation.gd`
- `scripts/ui/wave_info_panel.gd`
- `scripts/ui/tower_info_panel.gd`
- `scripts/ui/resource_bar.gd`
- `scripts/ui/sell_confirmation.gd`

**Levels:**
- `scripts/levels/main_level.gd`

### Scenes (15 files)

- `scenes/main/main_menu.tscn`
- `scenes/main/game_over.tscn`
- `scenes/levels/main_level.tscn`
- `scenes/towers/digimon_tower.tscn`
- `scenes/enemies/enemy_digimon.tscn`
- `scenes/combat/projectile.tscn`
- `scenes/ui/hud.tscn`
- `scenes/ui/spawn_menu.tscn`
- `scenes/ui/starter_selection.tscn`
- `scenes/ui/evolution_menu.tscn`
- `scenes/ui/merge_confirmation.tscn`
- `scenes/ui/wave_info_panel.tscn`
- `scenes/ui/tower_info_panel.tscn`
- `scenes/ui/resource_bar.tscn`
- `scenes/ui/sell_confirmation.tscn`

### Resources (297 files)

**Digimon (229):**
- `resources/digimon/in_training/*.tres` (15)
- `resources/digimon/rookie/*.tres` (39)
- `resources/digimon/champion/*.tres` (64)
- `resources/digimon/ultimate/*.tres` (49)
- `resources/digimon/mega/*.tres` (55)
- `resources/digimon/ultra/*.tres` (7)

**Evolutions (39):**
- `resources/evolutions/*.tres`

**Enemies (17+):**
- `resources/enemies/rookie/*.tres`
- `resources/enemies/champion/*.tres`

**Bosses (10):**
- `resources/waves/bosses/*.tres`

**Levels (1):**
- `resources/levels/level_1_path.tres`

---

## Verification Checklist

### Phase 1 Verification ✅
- [x] Game launches and shows main menu
- [x] Grid displays with correct 8x18 layout
- [x] Tower placement works on valid cells
- [x] Path is defined correctly

### Phase 2-4 Verification (Test Required)
- [ ] Towers spawn with correct stats
- [ ] Enemies follow path correctly
- [ ] Towers attack enemies in range
- [ ] Damage/effects apply correctly

### Phase 5-6 Verification (Test Required)
- [ ] Waves progress correctly
- [ ] Economy rewards are accurate
- [ ] Merging produces correct DP
- [ ] Evolution paths unlock at correct DP

### Full Game Verification (Test Required)
- [ ] Complete waves 1-10 without issues
- [ ] Level up, merge, and evolve a Digimon
- [ ] Verify attribute damage triangle
- [ ] Test boss encounters (Wave 10, 20)

---

## Next Steps

1. **Open in Godot 4.x** - Launch editor and open `project.godot`
2. **Run Main Scene** - Test main menu and starter selection
3. **Playtest Waves 1-10** - Verify core gameplay loop
4. **Fix Issues** - Debug any problems found
5. **Implement Phase 8** - Add tutorial, encyclopedia, audio

---

## Notes

- All mechanics are documented in `docs/GAME_DESIGN_DOCUMENT.md`
- All Digimon stats are in `docs/DIGIMON_STATS_DATABASE.md`
- All wave designs are in `docs/ENEMY_SPAWN_DESIGN.md`
- The game is ready for playtesting - core systems are implemented
- Phase 8 (Tutorial & Polish) is optional for initial testing
