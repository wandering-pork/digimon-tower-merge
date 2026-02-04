# Digimon Tower Merge

## Project Overview
A tower defense merge game where players spawn Digimon, level them up by paying,
merge same-attribute Digimon to gain DP (Digivolution Points), and digivolve at
max level. Higher DP unlocks rarer evolution paths. Origin stage determines how
far a Digimon can evolve. Defend against waves of enemy Digimon using strategic
tower placement and evolution choices.

## Tech Stack
- **Engine**: Godot 4.x
- **Language**: GDScript
- **Art Style**: Pixel Art 2D (16x16 or 32x32 base sprites)

### Godot Executable Path (Steam)
```
C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe
```
Use this path when running Godot from command line or configuring MCP tools.

## Project Structure
```
project/
├── scenes/           # Godot scene files (.tscn)
│   ├── main/        # Main menu, game over, etc.
│   ├── levels/      # Individual level scenes
│   ├── towers/      # Digimon tower scenes
│   ├── enemies/     # Enemy Digimon scenes
│   └── ui/          # UI components (evolution menu, DP display)
├── scripts/         # GDScript files (.gd)
│   ├── autoload/    # Singleton managers
│   ├── towers/      # Tower behavior scripts
│   ├── enemies/     # Enemy behavior scripts
│   ├── systems/     # Core game systems (merge, combat, waves)
│   └── data/        # Data classes and resources
├── assets/          # Game assets
│   ├── sprites/     # Pixel art sprites
│   ├── audio/       # Sound effects and music
│   ├── fonts/       # Custom fonts
│   └── ui/          # UI graphics
├── resources/       # Godot resources (.tres)
│   ├── digimon/     # Digimon data resources
│   │   ├── in_training/ # Baby II stage Digimon
│   │   ├── rookie/  # Child stage Digimon
│   │   ├── champion/ # Adult stage Digimon
│   │   ├── ultimate/ # Perfect stage Digimon
│   │   ├── mega/    # Ultimate stage Digimon
│   │   └── ultra/   # Super Ultimate stage Digimon
│   ├── effects/     # Status effect definitions (burn, freeze, etc.)
│   ├── abilities/   # Tower ability resources
│   └── levels/      # Level configuration
└── docs/            # Documentation
```

## Coding Conventions
- Use snake_case for variables and functions
- Use PascalCase for class names
- Prefix private variables with underscore (_variable)
- Keep scripts under 300 lines, split if larger
- Use signals for loose coupling between systems
- Comment complex logic, not obvious code

## Key Patterns
- Component-based design for towers/enemies
- Resource files for Digimon data (stats, evolution chains, DP requirements)
- Autoload singletons for game state, audio, events
- State machines for game flow and entity behavior

## Architecture (Refactored Feb 2026)

### Autoloads (load order matters)
1. **GameConfig** - Centralized game constants (economy, progression, combat, grid)
2. **GameManager** - Game state (currency, lives, wave number)
3. **EventBus** - Global signal bus for loose coupling
4. **AudioManager** - Sound management with pooling
5. **CombatSystem** - Combat coordination
6. **WaveManager** - Wave progression
7. **EconomySystem** - Transaction handling

### Tower Components (scripts/towers/)
- `digimon_tower.gd` - Core tower coordinator, component management
- `tower_combat_component.gd` - Targeting, attacking, damage dealing
- `tower_progression_component.gd` - Leveling, evolution, DP, origin tracking
- `tower_visual_component.gd` - Sprite management, animations, range indicators, flash effects
- `tower_ui_component.gd` - Label updates, DP indicator, stats display formatting

### Enemy Components (scripts/enemies/)
- `enemy_digimon.gd` - Core enemy, path movement
- `enemy_state_machine.gd` - States: IDLE, MOVING, STUNNED, SLOWED, FEARED, DYING, DEAD
- `enemy_effects_component.gd` - Status effects (burn, freeze, slow, poison, fear, etc.)
- `enemy_combat_component.gd` - Damage handling, HP, death

### Wave System (scripts/systems/)
- `wave_manager.gd` - State orchestration, wave flow, rewards, signal handling (~280 lines)
- `wave_spawner.gd` - Enemy instantiation, spawn timing, spawn queue management (~190 lines)
- `wave_state_machine.gd` - States: IDLE, COUNTDOWN, SPAWNING, IN_PROGRESS, INTERMISSION, BOSS_INCOMING, VICTORY, DEFEAT
- `wave_generator.gd` - Main wave generation interface
- `wave_config_database.gd` - Wave definitions and enemy pools
- `enemy_composition.gd` - Enemy group building logic
- `wave_modifier_system.gd` - Wave 50+ modifiers and endless scaling

### Combat System (scripts/combat/ & scripts/systems/)
- `combat_system.gd` - Main combat coordinator (facade pattern)
- `combat_projectile_factory.gd` - Projectile creation and configuration
- `combat_damage_processor.gd` - Damage calculations, AoE, chain lightning

### Projectile Components (scripts/combat/)
- `projectile.gd` - Base projectile class, movement, collision, component coordination
- `projectile_behaviors.gd` - Homing/tracking, piercing, chaining behaviors
- `projectile_effects.gd` - Damage application, AoE/splash effects, visual effects

### Status Effects System (scripts/combat/)
- `status_effects.gd` - Base interface, effect registry, common utilities
- `damage_effects.gd` - Burn, poison, bleed (DoT effects)
- `control_effects.gd` - Stun, slow, freeze, fear, root, knockback
- `debuff_effects.gd` - Armor shred, weakness, vulnerability, instakill

### Level System (scripts/levels/)
- `main_level.gd` - Core level orchestration, system initialization
- `level_ui_coordinator.gd` - UI panel management, menus
- `level_input_handler.gd` - Mouse/keyboard input processing

### Performance Optimizations
- Path progress calculations cached (O(1) instead of O(n))
- Distance checks use `distance_squared_to()` to avoid sqrt
- Memory leak fixes: proper signal disconnection in `_exit_tree()`

## Commands
- Run game: F5 in Godot editor
- Run current scene: F6
- Export: Project > Export

## Important Notes
- All Digimon data in resources/digimon/
- Evolution chains and DP requirements defined in DigimonData resources
- DP and Origin tracking handled in digimon_tower.gd
- Merge logic in merge_system.gd

---

## Game Mechanics Quick Reference

### Starting Conditions
```
┌─────────────────────────────────┐
│  DigiBytes: 200 DB              │
│  Lives: 20                      │
│  Towers: 1 free In-Training     │
│  Tower Slots: 87 placeable      │
└─────────────────────────────────┘
```

### Map Layout (Serpentine Path)
```
Grid: 8 columns × 18 rows | 15 direction changes | 57 path tiles

     Col: 1    2    3    4    5    6    7    8
        ┌────┬────┬────┬────┬────┬────┬────┬────┐
Row 1   │ T  │ T  │ T  │ T  │ T  │ T  │ T  │ T  │
Row 2   │ S→ │ →  │ ↓  │ T  │ T  │ T  │ T  │ T  │
Row 3   │ T  │ T  │ ↓  │ T  │ →  │ →  │ ↓  │ T  │
Row 4   │ T  │ T  │ ↓  │ T  │ ↑  │ T  │ ↓  │ T  │
Row 5   │ T  │ ↓  │ ←  │ T  │ ↑  │ T  │ ↓  │ T  │
Row 6   │ T  │ ↓  │ T  │ T  │ ↑  │ T  │ ↓  │ T  │
Row 7   │ T  │ →  │ →  │ →  │ ↑  │ T  │ ↓  │ T  │
Row 8   │ T  │ T  │ T  │ T  │ T  │ T  │ ↓  │ T  │
Row 9   │ ←  │ ←  │ ↑  │ T  │ T  │ T  │ ↓  │ T  │
Row 10  │ ↓  │ T  │ ↑  │ T  │ T  │ T  │ ↓  │ T  │
Row 11  │ ↓  │ T  │ ↑  │ T  │ T  │ T  │ ↓  │ T  │
Row 12  │ ↓  │ T  │ ↑  │ T  │ T  │ T  │ ↓  │ T  │
Row 13  │ ↓  │ T  │ ←  │ ←  │ ←  │ ←  │ ↓  │ T  │
Row 14  │ ↓  │ T  │ T  │ T  │ T  │ T  │ T  │ T  │
Row 15  │ ↓  │ T  │ T  │ →  │ →  │ →  │ →  │ E  │
Row 16  │ ↓  │ T  │ T  │ ↑  │ T  │ T  │ T  │ T  │
Row 17  │ ↓  │ T  │ T  │ ↑  │ T  │ T  │ T  │ T  │
Row 18  │ →  │ →  │ →  │ ↑  │ T  │ T  │ T  │ T  │
        └────┴────┴────┴────┴────┴────┴────┴────┘

S = Spawn | E = End/Base | T = Tower Slot | →↓←↑ = Path Direction
```

### Core Loop
```
SPAWN    → Pay DB for random/specific Digimon
LEVEL UP → Pay DB to increase level (5 DB × current level)
MERGE    → Sacrifice same-stage + same-attribute → +1 DP, better Origin
DIGIVOLVE→ At max level + pay fee → choose evolution based on DP
DEFEND   → Towers attack enemies, earn DB per wave
```

### Evolution Stages (6 Stages, No Fresh)
| Tier | Stage | Base Max Lv | Digivolve Cost | Can Merge? |
|------|-------|-------------|----------------|------------|
| 0 | In-Training | 10 | 100 DB | No |
| 1 | Rookie | 20 | 150 DB | Yes |
| 2 | Champion | 35 | 200 DB | Yes |
| 3 | Ultimate | 50 | 250 DB | Yes |
| 4 | Mega | 70 | - | Yes |
| 5 | Ultra | 100 | DNA only | DNA |

### DP (Digivolution Points) System
```
DP gained ONLY through merging (+1 per merge)
DP determines:
  1. Which evolution paths are available
  2. Level cap bonus (+X levels per DP based on stage)

Max Level = Base + (DP × Stage Bonus) + Origin Bonus
```

### Origin System
```
Origin = Stage at which Digimon was spawned

ORIGIN CAPS (how far you can evolve):
┌─────────────────────────────────────────┐
│ In-Training origin → Champion max       │
│ Rookie origin      → Ultimate max       │
│ Champion origin    → Mega max           │
└─────────────────────────────────────────┘

When merging: Survivor takes the BETTER Origin
```

### Origin Bonus
```
Origin Bonus = (Current Stage - Origin Stage) × 5 levels

Example:
- Raised from In-Training, now Champion: (2 - 0) × 5 = 10 bonus levels
- Spawned as Champion: (2 - 2) × 5 = 0 bonus levels
```

### Merge Rules
```
REQUIREMENTS:
- Rookie stage or higher (In-Training cannot merge)
- Same stage (Rookie + Rookie, Champion + Champion)
- Same attribute (Vaccine + Vaccine, Data + Data)
- Exception: FREE attribute can merge with ANY attribute

RESULT:
- One Digimon is sacrificed
- Survivor gains +1 DP
- Survivor takes the better Origin of the two
```

### Spawn Costs
| Stage | Random | Specific Attr | FREE Attr |
|-------|--------|---------------|-----------|
| In-Training | 100 DB | 150 DB | 200 DB |
| Rookie | 300 DB | 450 DB | 600 DB |
| Champion | 800 DB | 1200 DB | 1600 DB |

*FREE costs double because it can merge with any attribute (wild card)*

### Attribute Triangle
```
      VACCINE
        /\
       /  \
      / 1.5x\
     /   ↓   \
    /         \
 DATA ←─1.5x── VIRUS
       1.5x→

FREE = neutral (1.0x to all)
```

### Level Up Cost
```
Cost = 5 DB × current level

Lv 1→2:   5 DB
Lv 10→11: 50 DB
Lv 20→21: 100 DB
Lv 35→36: 175 DB
```

### Wave Economy
| Wave Range | Base Reward | Per Kill | Avg Total |
|------------|-------------|----------|-----------|
| 1-10 | 50 DB | 5 DB | ~100 DB |
| 11-20 | 75 DB | 8 DB | ~175 DB |
| 21-30 | 100 DB | 12 DB | ~280 DB |
| 31-40 | 150 DB | 18 DB | ~450 DB |
| 41-50 | 200 DB | 25 DB | ~700 DB |

### Lives System
```
Starting Lives: 20
Normal enemy passes: -1 life
Boss passes: -3 lives
Game Over: 0 lives
Bonus: +1 life every 10 waves (optional)
```

### Tower Categories by Family
- Dragon's Roar: Artillery (high damage, fire)
- Nature Spirits: Balanced (versatile)
- Virus Busters: Support/Magic (holy, buffs)
- Nightmare Soldiers: Debuff/Control (slows, weakens)
- Metal Empire: High-Tech (consistent damage)
- Deep Savers: Splash/AoE (water, crowd control)
- Wind Guardians: Anti-Air (fast, aerial specialists)
- Jungle Troopers: Barracks/Summon (traps, swarms)

---

## Example Playthrough

```
START: 200 DB, 1 free In-Training (A), 20 lives

BEFORE WAVE 1:
├── Spawn In-Training (B): -100 DB
├── Spawn In-Training (C): -100 DB
└── 0 DB, 3 towers

WAVE 1-5 (~500 DB earned):
├── Level A, B, C to Lv 10: ~150 DB each = 450 DB
├── Digivolve all to Rookie: 100 × 3 = 300 DB
└── 3 Rookies, deficit covered by wave 6-10

WAVE 6-10 (~500 DB earned):
├── Level Rookies toward Lv 20
├── Merge B → A (A gains DP 1, keeps In-Training origin)
├── Spawn Rookie (D) directly: -300 DB (Origin: Rookie!)
└── 2 Rookies (A, D) + spawning more

WAVE 11-20:
├── A reaches Champion (but stuck - In-Training origin)
├── D reaches Champion (can go to Ultimate - Rookie origin)
├── Merge A → D (D gains DP, keeps Rookie origin)
└── D is now main carry with good origin + DP

WAVE 21+:
├── Spawn Champion for Mega potential
├── Continue building army
└── Push toward Ultimate/Mega
```

---

## Documentation

For detailed design documents, see the `docs/` folder:

| Document | Description |
|----------|-------------|
| **GAME_DESIGN_DOCUMENT.md** | Full GDD with all mechanics, map design, data structures, and roadmap |
| **DIGIMON_STATS_DATABASE.md** | Complete ~150 Digimon roster with stats, effects, and evolution paths |
| **ENEMY_SPAWN_DESIGN.md** | Wave-by-wave enemy spawn design for 100 waves + endless mode |
| **IMPLEMENTATION_TODO.md** | Remaining refactoring work and architecture improvements |

### Map Design Reference
- **Path Type**: Complex serpentine (fixed waypoints)
- **Grid Size**: 8 columns × 18 rows
- **Path Length**: 57 tiles, 15 direction changes
- **Tower Slots**: 87 placement cells
- **Total Waypoints**: 57 points from Spawn to End
- **Kill Zones**: Multiple switchbacks allow multi-hit coverage
- **Path Time**: ~45-50 seconds at 1.0× speed

---

## Refactoring Status (Feb 2026)

### Completed Fixes - Session 1
| Issue | Status | Files Changed |
|-------|--------|---------------|
| GameConfig autoload | DONE | game_config.gd (new) |
| EnemyStateMachine | DONE | enemy_state_machine.gd (new) |
| WaveStateMachine | DONE | wave_state_machine.gd (new) |
| Memory leak fixes | DONE | digimon_tower.gd, wave_manager.gd, audio_manager.gd, merge_system.gd |
| Split digimon_tower.gd | DONE | tower_combat_component.gd, tower_progression_component.gd (new) |
| Split wave_generator.gd | DONE | wave_config_database.gd, enemy_composition.gd, wave_modifier_system.gd (new) |
| Split enemy_digimon.gd | DONE | enemy_effects_component.gd, enemy_combat_component.gd (new) |
| Cache path calculations | DONE | enemy_digimon.gd |
| Update project.godot | DONE | GameConfig autoload registered |

### Completed Fixes - Session 2
| Issue | Status | Files Changed |
|-------|--------|---------------|
| Integrate WaveStateMachine | DONE | wave_manager.gd now uses WaveStateMachine properly |
| Add _exit_tree() to components | DONE | tower_combat_component.gd, tower_progression_component.gd, enemy_effects_component.gd, enemy_combat_component.gd, enemy_state_machine.gd |
| Remove duplicate constants | DONE | wave_manager.gd now uses GameConfig (removed ~70 lines) |
| Split combat_system.gd | DONE | combat_projectile_factory.gd, combat_damage_processor.gd (new) |
| Split main_level.gd | DONE | level_ui_coordinator.gd, level_input_handler.gd (new) |

### Completed Fixes - Session 3
| Issue | Status | Files Changed |
|-------|--------|---------------|
| Split grid_manager.gd | DONE | grid_manager.gd (refactored), path_manager.gd (new) |
| Add ASCII documentation | DONE | path_manager.gd has full map diagram |
| Add _exit_tree() cleanup | DONE | grid_manager.gd, path_manager.gd |

### Completed Fixes - Session 4
| Issue | Status | Files Changed |
|-------|--------|---------------|
| Split projectile.gd | DONE | projectile.gd (281 lines), projectile_behaviors.gd (246 lines), projectile_effects.gd (212 lines) |

### Completed Fixes - Session 5
| Issue | Status | Files Changed |
|-------|--------|---------------|
| Split status_effects.gd | DONE | status_effects.gd (295 lines), damage_effects.gd (132 lines), control_effects.gd (190 lines), debuff_effects.gd (189 lines) |

### Completed Fixes - Session 6
| Issue | Status | Files Changed |
|-------|--------|---------------|
| Split wave_manager.gd | DONE | wave_manager.gd (~280 lines), wave_spawner.gd (~190 lines, new) |

### New Files Created (30 total)
```
scripts/autoload/game_config.gd              # Centralized constants
scripts/autoload/error_handler.gd            # Centralized error logging
scripts/interfaces/i_attacker.gd             # Interface for damage dealers
scripts/interfaces/i_damageable.gd           # Interface for damage receivers
scripts/interfaces/i_targetable.gd           # Interface for targetable entities
scripts/interfaces/i_effect_receiver.gd      # Interface for status effect receivers
scripts/enemies/enemy_state_machine.gd       # Enemy state machine
scripts/enemies/enemy_effects_component.gd   # Status effects
scripts/enemies/enemy_combat_component.gd    # Combat handling
scripts/systems/wave_state_machine.gd        # Wave flow states
scripts/systems/wave_spawner.gd              # Enemy instantiation and spawn timing
scripts/systems/wave_config_database.gd      # Wave definitions
scripts/systems/enemy_composition.gd         # Enemy group building
scripts/systems/wave_modifier_system.gd      # Late game modifiers
scripts/systems/path_manager.gd              # Path initialization, waypoints, navigation
scripts/towers/tower_combat_component.gd     # Tower combat
scripts/towers/tower_progression_component.gd # Tower progression
scripts/towers/tower_visual_component.gd     # Sprite, animations, range indicators, flash
scripts/towers/tower_ui_component.gd         # Labels, DP indicator, stats display
scripts/combat/combat_projectile_factory.gd  # Projectile creation
scripts/combat/combat_damage_processor.gd    # Damage calculations
scripts/combat/projectile_behaviors.gd       # Projectile movement behaviors
scripts/combat/projectile_effects.gd         # Projectile on-hit effects
scripts/combat/damage_effects.gd             # Burn, poison, bleed (DoT effects)
scripts/combat/control_effects.gd            # Stun, slow, freeze, fear, root, knockback
scripts/combat/debuff_effects.gd             # Armor shred, weakness, vulnerability, instakill
scripts/levels/level_ui_coordinator.gd       # UI panel management
scripts/levels/level_input_handler.gd        # Input processing
```

### Completed Fixes - Session 7
| Issue | Status | Files Changed |
|-------|--------|---------------|
| Create interface abstractions | DONE | i_attacker.gd, i_damageable.gd, i_targetable.gd, i_effect_receiver.gd (new) |
| Add ErrorHandler autoload | DONE | error_handler.gd (new), registered in project.godot |
| Integrate ErrorHandler | DONE | 22 files updated to use ErrorHandler |
| Cache enemy list | DONE | combat_system.gd (O(1) enemy lookup) |
| Fix constant duplication | DONE | game_manager.gd, economy_system.gd, spawn_system.gd now use GameConfig |
| Split digimon_tower.gd further | DONE | tower_visual_component.gd (161 lines), tower_ui_component.gd (78 lines) |

### Completed Fixes - Session 8 (Build Fixes)
| Issue | Status | Files Changed |
|-------|--------|---------------|
| Fix autoload class_name conflicts | DONE | Removed class_name from game_config.gd, combat_system.gd, economy_system.gd (autoloads register as globals) |
| Add preload constants | DONE | 25+ files updated with preload() for type resolution |
| Fix circular dependencies | DONE | Changed strict type hints to Node in tower components, grid_manager, etc. |
| Inline utility functions | DONE | damage_effects.gd now has inlined _apply_dot_damage and _flash_effect_color |
| Build verification | DONE | Project builds successfully with Godot 4.6 |

### GDScript Type Resolution Notes
When using typed references in GDScript with Godot 4.x:
- **Autoloads**: Remove `class_name` declarations - autoloads already register as globals
- **Cross-file types**: Use `const ClassName = preload("res://path/to/script.gd")` at top of file
- **Circular dependencies**: Change type hints to base types (`Node`, `Area2D`) to avoid cycles
- **Example pattern**:
  ```gdscript
  # At top of file
  const DigimonData = preload("res://scripts/data/digimon_data.gd")

  # For circular deps, use base type
  var tower: Node  # DigimonTower - avoid circular dependency
  ```

### Remaining Work (Future Sessions)
- [ ] Implement dependency injection pattern
- [ ] Add GUT testing framework
- [ ] Configure audio buses (Music, SFX) to fix AudioManager warnings
