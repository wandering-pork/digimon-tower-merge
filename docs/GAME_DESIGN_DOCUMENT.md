# Digimon Tower Merge - Game Design Document

## Table of Contents
1. [Game Overview](#1-game-overview)
2. [Core Mechanics](#2-core-mechanics)
3. [DP System](#3-dp-digivolution-points-system)
4. [Origin System](#4-origin-system)
5. [Evolution System](#5-evolution-system)
6. [Wave System](#6-wave-system)
7. [Economy & Balance](#7-economy--balance)
8. [Combat System](#8-combat-system)
9. [Digimon Database](#9-digimon-database)
10. [Data Structures](#10-data-structures)
11. [Technical Specifications](#11-technical-specifications)
12. [Settings Menu](#12-settings-menu)
13. [UI/UX Design](#13-uiux-design)
14. [Tutorial System](#14-tutorial-system)
15. [Digivolution Encyclopedia](#15-digivolution-encyclopedia)
16. [Asset Pipeline & Sprites](#16-asset-pipeline--sprites)
17. [Development Roadmap](#17-development-roadmap)
18. [Resources & References](#18-resources--references)

---

## 1. Game Overview

### Concept
A tower defense merge game combining the Digimon franchise with strategic mechanics inspired by Digimon World 2. Players spawn Digimon, pay to level them up, merge same-attribute Digimon to gain DP (Digivolution Points), and digivolve at max level. The Origin system determines how far each Digimon can evolve, forcing strategic spawning and merging decisions.

### Core Pillars
1. **Strategic Depth**: Origin management, DP accumulation, and evolution paths reward planning
2. **Nostalgia**: Faithful representation of iconic Digimon with authentic evolution paths
3. **Player Agency**: Choose spawn types, evolution paths, and merge targets
4. **Accessibility**: Clear progression systems with meaningful choices

### Target Platform
PC (Windows/Linux/Mac) via Godot 4.x export

### Basic Loop
```
┌─────────────────────────────────────────────────────────────┐
│  1. SPAWN     → Pay DigiBytes for In-Training/Rookie/etc    │
│  2. LEVEL UP  → Pay to increase tower level                 │
│  3. MERGE     → Same stage + same attribute = +1 DP         │
│  4. DIGIVOLVE → At max level + pay fee = choose evolution   │
│  5. DEFEND    → Towers attack waves, earn DigiBytes         │
│  6. REPEAT    → Build army to reach Wave 100                │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Core Mechanics

### Starting Conditions
```
┌─────────────────────────────────┐
│  DigiBytes: 200 DB              │
│  Lives: 20                      │
│  Towers: 1 free In-Training     │
│  Tower Slots: 87 placeable      │
└─────────────────────────────────┘
```

### New Game - Starter Selection

At the start of a new game, the player chooses their first In-Training Digimon from a selection screen.

#### Starter Selection UI
```
┌───────────────────────────────────────────────────────────────────────────┐
│                      CHOOSE YOUR PARTNER                                  │
│                   ═══════════════════════════                             │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│   Select your starting In-Training Digimon. Each has unique evolution    │
│   paths and specialties!                                                  │
│                                                                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐         │
│  │  ┌───────┐  │ │  ┌───────┐  │ │  ┌───────┐  │ │  ┌───────┐  │         │
│  │  │       │  │ │  │       │  │ │  │       │  │ │  │       │  │         │
│  │  │Koromon│  │ │  │Tsunomon│ │ │  │Tokomon│  │ │  │Gigimon│  │         │
│  │  │       │  │ │  │       │  │ │  │       │  │ │  │       │  │         │
│  │  └───────┘  │ │  └───────┘  │ │  └───────┘  │ │  └───────┘  │         │
│  │             │ │             │ │             │ │             │         │
│  │  Vaccine    │ │    Data     │ │  Vaccine    │ │   Virus     │         │
│  │ Dragon's    │ │   Nature    │ │   Virus     │ │  Dragon's   │         │
│  │   Roar      │ │  Spirits    │ │  Busters    │ │    Roar     │         │
│  │             │ │             │ │             │ │             │         │
│  │  → Agumon   │ │  → Gabumon  │ │  → Patamon  │ │  → Guilmon  │         │
│  │  → Greymon  │ │  → Garurumon│ │  → Angemon  │ │  → Growlmon │         │
│  │             │ │             │ │             │ │             │         │
│  │  [SELECT]   │ │  [SELECT]   │ │  [SELECT]   │ │  [SELECT]   │         │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘         │
│                                                                           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐         │
│  │  ┌───────┐  │ │  ┌───────┐  │ │  ┌───────┐  │ │  ┌───────┐  │         │
│  │  │       │  │ │  │       │  │ │  │       │  │ │  │       │  │         │
│  │  │Tanemon│  │ │  │DemiVee-│ │ │  │Pagumon│  │ │  │Viximon │  │         │
│  │  │       │  │ │  │  mon  │  │ │  │       │  │ │  │       │  │         │
│  │  └───────┘  │ │  └───────┘  │ │  └───────┘  │ │  └───────┘  │         │
│  │             │ │             │ │             │ │             │         │
│  │    Data     │ │    FREE     │ │   Virus     │ │    Data     │         │
│  │   Jungle    │ │  Dragon's   │ │ Nightmare   │ │   Nature    │         │
│  │  Troopers   │ │    Roar     │ │  Soldiers   │ │  Spirits    │         │
│  │             │ │             │ │             │ │             │         │
│  │  → Palmon   │ │  → Veemon   │ │ → DemiDevi  │ │  → Renamon  │         │
│  │  → Togemon  │ │  → ExVeemon │ │ → Devimon   │ │  → Kyubimon │         │
│  │             │ │             │ │             │ │             │         │
│  │  [SELECT]   │ │  [SELECT]   │ │  [SELECT]   │ │  [SELECT]   │         │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘         │
│                                                                           │
├───────────────────────────────────────────────────────────────────────────┤
│  Tip: Your starter's Origin is In-Training, limiting it to Champion max. │
│       Spawn higher-tier Digimon later for Mega potential!                │
└───────────────────────────────────────────────────────────────────────────┘
```

#### Available Starters
| Starter | Attribute | Family | Evolves To | Specialty |
|---------|-----------|--------|------------|-----------|
| Koromon | Vaccine | Dragon's Roar | Agumon → Greymon | Fire DPS |
| Tsunomon | Data | Nature Spirits | Gabumon → Garurumon | Ice Control |
| Tokomon | Vaccine | Virus Busters | Patamon → Angemon | Holy Support |
| Gigimon | Virus | Dragon's Roar | Guilmon → Growlmon | Fire Tank |
| Tanemon | Data | Jungle Troopers | Palmon → Togemon | Poison/Nature |
| DemiVeemon | FREE | Dragon's Roar | Veemon → ExVeemon | Versatile |
| Pagumon | Virus | Nightmare Soldiers | DemiDevimon → Devimon | Dark Debuff |
| Viximon | Data | Nature Spirits | Renamon → Kyubimon | Magic Multi-hit |

### Sell System

Players can sell towers to recover DigiBytes. **Sell value = 50% of total investment.**

```
Sell Value = 50% × (Spawn Cost + Total Level Up Cost + Digivolve Costs)

Example:
  Greymon at Lv 25:
  - Spawned as In-Training (Random): 100 DB
  - Leveled to 10: ~275 DB
  - Digivolved to Rookie: 100 DB
  - Leveled to 20: ~775 DB (cumulative from 11-20)
  - Digivolved to Champion: 150 DB
  - Leveled to 25: ~550 DB (cumulative from 21-25)
  - Total invested: ~1,950 DB
  - Sell value: ~975 DB
```

#### Sell Confirmation
```
┌─────────────────────────────────────┐
│         SELL DIGIMON?              │
├─────────────────────────────────────┤
│                                     │
│   ┌───────┐                         │
│   │Greymon│  Lv 25                  │
│   └───────┘  DP: 3                  │
│                                     │
│   Sell Value: 975 DB                │
│                                     │
│   ⚠ This action cannot be undone!   │
│                                     │
│   [CONFIRM SELL]     [Cancel]       │
└─────────────────────────────────────┘
```

### Game Speed

Game speed affects **everything** - enemies, towers, cooldowns, projectiles.

| Speed | Multiplier | Use Case |
|-------|------------|----------|
| 1.0× | Normal | Learning, strategic planning |
| 1.5× | Fast | Experienced players |
| 2.0× | Very Fast | Grinding, replays |

```
Toggle: Click speed button or press [Space] to cycle
Display: Shows current speed in HUD (e.g., "▶ 1.5×")

Implementation:
  Engine.time_scale = selected_speed
```

### Targeting Priority

Each tower has a targeting priority that determines which enemy it attacks first. Players can **cycle** through options by clicking a button on the selected tower.

#### Targeting Cycle Button
```
┌─────────────────────────────────────┐
│  Target: [◄] FIRST [►]             │
│          ↻ Click to cycle           │
└─────────────────────────────────────┘

Cycle Order:
  FIRST → LAST → STRONGEST → WEAKEST → FASTEST → CLOSEST → (back to FIRST)
```

| Priority | Description | Best For |
|----------|-------------|----------|
| **First** | Closest to base | General use, cleanup |
| **Last** | Furthest from base | Softening incoming |
| **Strongest** | Highest current HP | Focus fire tanks/bosses |
| **Weakest** | Lowest current HP | Securing kills |
| **Fastest** | Highest move speed | Catching speedsters |
| **Closest** | Nearest to tower | Maximize uptime |

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **Space** | Toggle game speed (1× → 1.5× → 2× → 1×) |
| **Escape** | Pause / Close modal |
| **Delete** | Sell selected tower (with confirmation) |
| **1-6** | Quick select targeting (1=First, 2=Last, etc.) |
| **E** | Digivolve selected tower (if available) |
| **L** | Level up selected tower |
| **Tab** | Cycle through owned towers |
| **F** | Toggle fast-forward (hold for 2×) |

### Edge Cases

| Situation | Resolution |
|-----------|------------|
| **Grid full, can't spawn** | Player must sell or merge existing towers |
| **Can't afford anything** | Wait for wave rewards, sell towers if desperate |
| **All towers disabled by boss** | Temporary - wait for effect to end |
| **No valid merge targets** | Spawn more of same attribute, or use FREE |
| **Max level, can't digivolve (Origin cap)** | Merge with higher-origin Digimon |
| **0 lives** | Game Over screen |

### Map Layout

The map uses a **complex serpentine path design** where enemies wind through the battlefield with multiple switchbacks, maximizing travel time and creating numerous kill zones where towers can hit enemies multiple times.

```
LEGEND:
  S = SPAWN (enemy entry point)
  E = END/BASE (defend this!)
  P = Path tiles (enemies walk here)
  T = Tower placement slots

MAP GRID (8 columns × 18 rows):

     Col: 1    2    3    4    5    6    7    8
        ┌────┬────┬────┬────┬────┬────┬────┬────┐
Row 1   │ T  │ T  │ T  │ T  │ T  │ T  │ T  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 2   │ S  │ P  │ P  │ T  │ T  │ T  │ T  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 3   │ T  │ T  │ P  │ T  │ P  │ P  │ P  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 4   │ T  │ T  │ P  │ T  │ P  │ T  │ P  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 5   │ T  │ P  │ P  │ T  │ P  │ T  │ P  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 6   │ T  │ P  │ T  │ T  │ P  │ T  │ P  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 7   │ T  │ P  │ P  │ P  │ P  │ T  │ P  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 8   │ T  │ T  │ T  │ T  │ T  │ T  │ P  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 9   │ P  │ P  │ P  │ T  │ T  │ T  │ P  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 10  │ P  │ T  │ P  │ T  │ T  │ T  │ P  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 11  │ P  │ T  │ P  │ T  │ T  │ T  │ P  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 12  │ P  │ T  │ P  │ T  │ T  │ T  │ P  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 13  │ P  │ T  │ P  │ P  │ P  │ P  │ P  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 14  │ P  │ T  │ T  │ T  │ T  │ T  │ T  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 15  │ P  │ T  │ T  │ P  │ P  │ P  │ P  │ E  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 16  │ P  │ T  │ T  │ P  │ T  │ T  │ T  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 17  │ P  │ T  │ T  │ P  │ T  │ T  │ T  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 18  │ P  │ P  │ P  │ P  │ T  │ T  │ T  │ T  │
        └────┴────┴────┴────┴────┴────┴────┴────┘
```

### Path Visualization with Directions
```
DIRECTION KEY:
  → = Moving RIGHT    ← = Moving LEFT
  ↓ = Moving DOWN     ↑ = Moving UP
  ◉ = Turn point (direction change)

     Col: 1    2    3    4    5    6    7    8
        ┌────┬────┬────┬────┬────┬────┬────┬────┐
Row 1   │ T  │ T  │ T  │ T  │ T  │ T  │ T  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 2   │ S→ │ →  │ ◉↓ │ T  │ T  │ T  │ T  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 3   │ T  │ T  │ ↓  │ T  │ ◉→ │ →  │ ◉↓ │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 4   │ T  │ T  │ ↓  │ T  │ ↑  │ T  │ ↓  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 5   │ T  │ ◉↓ │ ◉← │ T  │ ↑  │ T  │ ↓  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 6   │ T  │ ↓  │ T  │ T  │ ↑  │ T  │ ↓  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 7   │ T  │ ◉→ │ →  │ →  │ ◉↑ │ T  │ ↓  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 8   │ T  │ T  │ T  │ T  │ T  │ T  │ ↓  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 9   │ ◉← │ ←  │ ◉↑ │ T  │ T  │ T  │ ↓  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 10  │ ↓  │ T  │ ↑  │ T  │ T  │ T  │ ↓  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 11  │ ↓  │ T  │ ↑  │ T  │ T  │ T  │ ↓  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 12  │ ↓  │ T  │ ↑  │ T  │ T  │ T  │ ↓  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 13  │ ↓  │ T  │ ◉← │ ←  │ ←  │ ←  │ ◉↓ │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 14  │ ↓  │ T  │ T  │ T  │ T  │ T  │ T  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 15  │ ↓  │ T  │ T  │ ◉→ │ →  │ →  │ →  │ E  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 16  │ ↓  │ T  │ T  │ ↑  │ T  │ T  │ T  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 17  │ ↓  │ T  │ T  │ ↑  │ T  │ T  │ T  │ T  │
        ├────┼────┼────┼────┼────┼────┼────┼────┤
Row 18  │ ◉→ │ →  │ →  │ ◉↑ │ T  │ T  │ T  │ T  │
        └────┴────┴────┴────┴────┴────┴────┴────┘

S = Spawn Point (enemies enter here)
E = End/Base (lives lost if enemies reach here)
T = Tower Placement Slot (87 total)
```

### Evolution Stages (6 Stages - No Fresh)
```
In-Training → Rookie → Champion → Ultimate → Mega → Ultra
  (Tier 0)    (Tier 1)  (Tier 2)   (Tier 3)  (Tier 4) (Tier 5)
   spawn      digivolve digivolve  digivolve digivolve  DNA
```

| Tier | Stage | Base Max Lv | Digivolve At | Digivolve Cost | Can Merge? |
|------|-------|-------------|--------------|----------------|------------|
| 0 | In-Training | 10 | Lv 10 | 100 DB | No |
| 1 | Rookie | 20 | Lv 20 | 150 DB | Yes |
| 2 | Champion | 35 | Lv 35 | 200 DB | Yes |
| 3 | Ultimate | 50 | Lv 50 | 250 DB | Yes |
| 4 | Mega | 70 | - | - | Yes |
| 5 | Ultra | 100 | - | DNA only | DNA |

### Spawn System

Players can spawn Digimon at different stages with different costs.

**Spawn Costs:**

| Stage | Random Attr | Specific Attr (+50%) | FREE Attr (+100%) |
|-------|-------------|----------------------|-------------------|
| In-Training | 100 DB | 150 DB | 200 DB |
| Rookie | 300 DB | 450 DB | 600 DB |
| Champion | 800 DB | 1200 DB | 1600 DB |

- **Random**: Get a random attribute (Vaccine/Data/Virus)
- **Specific**: Choose Vaccine, Data, or Virus
- **FREE**: Get FREE attribute (can merge with any attribute - wild card)

### Tower Placement Flow

Players have two methods to spawn and place towers:

#### Method 1: Click on Empty Cell
```
1. Player clicks on empty tower cell (T)
2. Spawn menu opens AT that cell location
3. Player selects Stage → Type → (Attribute if Specific)
4. Digimon spawns directly on clicked cell
5. DigiBytes deducted

┌─────────────────────────────────────┐
│      SPAWN DIGIMON HERE             │
├─────────────────────────────────────┤
│  SELECT STAGE:                      │
│  [In-Training 100DB] [Rookie 300DB] │
│                                     │
│  SELECT TYPE:                       │
│  [Random ×1.0] [Specific ×1.5]      │
│  [FREE ×2.0]                        │
│                                     │
│  (If Specific)                      │
│  [Vaccine] [Data] [Virus]           │
│                                     │
│  TOTAL: 150 DB    [SPAWN] [Cancel]  │
└─────────────────────────────────────┘
```

#### Method 2: Drag from Spawn Menu
```
1. Player opens bottom Spawn Menu panel
2. Player configures Stage + Type + Attribute
3. Player drags spawn icon onto valid cell
4. Valid cells highlight green, invalid cells red
5. Release on valid cell → Digimon spawns
6. DigiBytes deducted

DRAG FEEDBACK:
┌─────────────────────────────────────┐
│  While dragging:                    │
│  - Ghost sprite follows cursor      │
│  - Valid cells glow GREEN           │
│  - Occupied/Path cells glow RED     │
│  - Cost displayed near cursor       │
│                                     │
│  On drop:                           │
│  - Valid: Spawn with animation      │
│  - Invalid: Cancel with error sound │
└─────────────────────────────────────┘
```

#### Merge via Drag-and-Drop
```
1. Player drags owned tower onto another owned tower
2. System checks merge compatibility:
   - Same stage? ✓
   - Same attribute (or FREE involved)? ✓
   - Both Rookie or higher? ✓
3. If valid: Show merge confirmation modal
4. If invalid: Show error message, cancel drag

MERGE PREVIEW (while hovering):
┌─────────────────────────────────────┐
│  ✓ MERGE POSSIBLE                   │
│  Greymon (DP 2) + Greymon (DP 1)    │
│  = Greymon (DP 3)                   │
│  Origin: In-Training (best kept)    │
└─────────────────────────────────────┘

or

┌─────────────────────────────────────┐
│  ✗ CANNOT MERGE                     │
│  Reason: Different attributes       │
│  (Vaccine ≠ Data)                   │
└─────────────────────────────────────┘
```

#### Input States
| State | Left Click | Right Click | Drag |
|-------|------------|-------------|------|
| Empty cell | Open spawn menu | - | - |
| Owned tower | Select tower | Open context menu | Start drag (merge/move) |
| Path cell | - | - | - |
| During wave | Same as above | Same as above | Same as above |

#### Tower Context Menu (Right-Click)
```
┌─────────────────────┐
│ Greymon Lv 25       │
├─────────────────────┤
│ Level Up (125 DB)   │
│ Digivolve (150 DB)  │
│ Set Target Priority │
│ ─────────────────── │
│ Sell (50 DB)        │
└─────────────────────┘
```

### Level Up System

Towers level up by **paying DigiBytes**, not through combat.

```
Level Up Cost = 5 DB × Current Level

Examples:
  Lv 1 → 2:    5 DB
  Lv 5 → 6:   25 DB
  Lv 10 → 11: 50 DB
  Lv 20 → 21: 100 DB
  Lv 35 → 36: 175 DB

Total cost to reach Lv 20: ~1,000 DB
Total cost to reach Lv 35: ~3,000 DB
```

**Level Effects:**
- Each level = +2% base damage
- Each level = +1% attack speed

### Digivolve System

To digivolve:
1. Reach the **base max level** for current stage
2. Pay the **digivolve fee**
3. Choose evolution path based on current **DP**

```
Example:
  Agumon (Rookie, Lv 20, DP 3)
  → Pay 150 DB to digivolve
  → Choose from: Greymon (DP 0-2), GeoGreymon (DP 3-4) ✓
  → Becomes GeoGreymon (Champion, Lv 1, DP 3)
```

### Merge System

**Requirements:**
- Rookie stage or higher (In-Training cannot merge)
- Same stage (Rookie + Rookie, Champion + Champion, etc.)
- Same attribute (Vaccine + Vaccine, Data + Data, Virus + Virus)
- **Exception**: FREE attribute can merge with ANY attribute

**Result:**
- One Digimon is **sacrificed**
- Survivor gains **+1 DP**
- Survivor takes the **better Origin** of the two

```
Example:
  Your Greymon (DP 2, Origin: In-Training)
    +
  Their Greymon (DP 1, Origin: Rookie)
    =
  Your Greymon (DP 3, Origin: Rookie) ← takes better origin!
```

### Attribute System

**Merge Compatibility:**
```
Vaccine + Vaccine = ✓
Data + Data = ✓
Virus + Virus = ✓
FREE + Anything = ✓ (wild card)
Vaccine + Data = ✗
```

**Combat Triangle:**
```
        VACCINE
          /\
         /  \
        / 1.5x\
       /   ↓   \
      /         \
   DATA ←─1.5x── VIRUS
         1.5x→

FREE = 1.0x against all (neutral)
```

| Attacker | vs Vaccine | vs Data | vs Virus |
|----------|------------|---------|----------|
| Vaccine | 1.0x | 0.75x | **1.5x** |
| Data | **1.5x** | 1.0x | 0.75x |
| Virus | 0.75x | **1.5x** | 1.0x |
| Free | 1.0x | 1.0x | 1.0x |

---

## 3. DP (Digivolution Points) System

Based on Digimon World 2's mechanics.

### Core Concept
```
┌─────────────────────────────────────────────────────────────────┐
│  DP = Digivolution Points                                        │
│                                                                  │
│  - DP is gained ONLY through MERGING                             │
│  - Each merge grants +1 DP to the survivor                       │
│  - DP determines which evolution paths are available             │
│  - Higher DP = access to stronger/rarer evolutions               │
│  - DP also increases level cap (more potential)                  │
└─────────────────────────────────────────────────────────────────┘
```

### DP Gain on Merge
```
Survivor DP = MAX(Digimon A DP, Digimon B DP) + 1

Example:
  Greymon (DP 2) + Greymon (DP 4) = Greymon (DP 5)
```

### DP Bonus to Level Cap

Higher DP = higher level cap = stronger tower.

| Stage | Base Max Lv | DP Bonus | DP 0 Cap | DP 5 Cap | DP 10 Cap |
|-------|-------------|----------|----------|----------|-----------|
| In-Training | 10 | +1/DP | 10 | 15 | 20 |
| Rookie | 20 | +2/DP | 20 | 30 | 40 |
| Champion | 35 | +3/DP | 35 | 50 | 65 |
| Ultimate | 50 | +4/DP | 50 | 70 | 90 |
| Mega | 70 | +5/DP | 70 | 95 | 120 |
| Ultra | 100 | +5/DP | 100 | 125 | 150 |

### DP Thresholds for Evolution

Different evolutions unlock at different DP thresholds.

**Example: Agumon → Champion**

| DP Range | Evolution | Type |
|----------|-----------|------|
| 0-2 | Greymon | Default (Fire) |
| 3-4 | GeoGreymon | Alternate (Earth/Fire) |
| 5-6 | Tyrannomon | Tank path |
| 7+ | DarkTyrannomon | Dark path |

**Example: Greymon → Ultimate**

| DP Range | Evolution | Type |
|----------|-----------|------|
| 0-3 | MetalGreymon | Default (Missile) |
| 4-6 | RizeGreymon | Gunner |
| 7-9 | SkullGreymon | Berserk |
| 10+ | MasterTyrannomon | Tank Nuke |

---

## 4. Origin System

The **Origin** is the stage at which a Digimon was spawned. It determines the maximum stage that Digimon can reach.

### Origin Caps

```
┌─────────────────────────────────────────────────────────────────┐
│  ORIGIN DETERMINES MAX STAGE                                     │
│                                                                  │
│  Origin: In-Training  → Can reach: Champion (max)               │
│  Origin: Rookie       → Can reach: Ultimate (max)               │
│  Origin: Champion     → Can reach: Mega (max)                   │
└─────────────────────────────────────────────────────────────────┘
```

| Origin Stage | Can Reach | Cannot Reach |
|--------------|-----------|--------------|
| In-Training | Champion | Ultimate, Mega, Ultra |
| Rookie | Ultimate | Mega, Ultra |
| Champion | Mega | Ultra |

### Origin Bonus to Level Cap

Digimon that were raised from lower origins get bonus max levels.

```
Origin Bonus = (Current Stage - Origin Stage) × 5 levels
```

| Digimon | Origin | Current | Origin Bonus |
|---------|--------|---------|--------------|
| Greymon (raised) | In-Training (0) | Champion (2) | +10 levels |
| Greymon (spawned Rookie, evolved) | Rookie (1) | Champion (2) | +5 levels |
| Greymon (spawned Champion) | Champion (2) | Champion (2) | +0 levels |

### Full Max Level Formula

```
Max Level = Base[Stage] + (DP × Stage Bonus) + Origin Bonus

Example: Greymon with DP 3, raised from In-Training
  Base: 35 (Champion)
  DP Bonus: 3 × 3 = 9
  Origin Bonus: (2 - 0) × 5 = 10
  Max Level: 35 + 9 + 10 = 54
```

### Origin Upgrade via Merge

When merging, the survivor takes the **better (lower) Origin** of the two.

```
Your Champion (Origin: In-Training, stuck at Champion)
  +
Spawned Champion (Origin: Champion, can reach Mega)
  =
Your Champion (Origin: Champion, can now reach Mega!)
```

This forces players to:
1. Spawn higher-origin Digimon (costs more)
2. Raise them to the same stage as their main
3. Merge to upgrade Origin

### Progression Path Example

```
1. Start with free In-Training (Origin: In-Training)
   └── Max potential: Champion

2. Raise to Champion, hit the wall

3. Spawn Rookie (300 DB, Origin: Rookie)
   └── Raise to Champion
   └── Merge into your Champion
   └── Now Origin: Rookie, can reach Ultimate!

4. Raise to Ultimate, hit the wall

5. Spawn Champion (800 DB, Origin: Champion)
   └── Merge into your Ultimate
   └── Now Origin: Champion, can reach Mega!

6. Raise to Mega!
```

---

## 5. Evolution System

### Evolution Trees Overview

Each In-Training starter has multiple evolution paths branching based on DP.

#### Koromon Line (Dragon's Roar - Fire)
```
Koromon → Agumon
             │
   ┌─────────┼─────────┬─────────┐
   ↓         ↓         ↓         ↓
Greymon  GeoGreymon Tyrannomon DarkTyrannomon
(DP 0-2) (DP 3-4)   (DP 5-6)   (DP 7+)
   │         │         │         │
   ↓         ↓         ↓         ↓
MetalGrey RizeGrey  MasterTyran MetalTyran
(DP 0-3) (DP 4-6)   (DP 7+)    (DP 7+)
   │
   ↓
WarGreymon → ShineGreymon → VictoryGreymon → BlackWarGreymon
(DP 0-5)    (DP 6-8)       (DP 9-11)        (DP 12+)
```

#### Tsunomon Line (Nature Spirits - Ice)
```
Tsunomon → Gabumon
              │
    ┌─────────┼─────────┐
    ↓         ↓         ↓
 Garurumon Gururumon BlackGarurumon
 (DP 0-2)  (DP 3-4)  (DP 5+)
    │
    ↓
WereGarurumon → ShadowWereGarurumon
(DP 0-3)        (DP 7+)
    │
    ↓
MetalGarurumon → CresGarurumon
(DP 0-5)         (DP 9+)
```

#### Tokomon Line (Virus Busters - Holy)
```
Tokomon → Patamon
             │
   ┌─────────┼─────────┐
   ↓         ↓         ↓
Angemon   Unimon    Gatomon
(DP 0-2)  (DP 3-4)  (DP 5+)
   │                   │
   ↓                   ↓
MagnaAngemon       Angewomon
(DP 0-3)           (DP 0-3)
   │                   │
   ↓                   ↓
Seraphimon         Ophanimon
(DP 0-5)           (DP 0-5)
```

### DNA Digivolution (Ultra Tier)

Combine two **specific different Mega** Digimon to create Ultra tier.

| Digimon A | Digimon B | Result | Special |
|-----------|-----------|--------|---------|
| WarGreymon | MetalGarurumon | Omegamon | All effects 30% |
| BlackWarGreymon | BlackMetalGarurumon | Omegamon Zwart | 50% all debuffs |
| Angewomon | LadyDevimon | Mastemon | +100% vs Dark |
| Imperialdramon FM | Omegamon | Imperialdramon PM | 50% Execute |
| Gallantmon | Grani | Gallantmon CM | Purge all |

---

## 6. Wave System

### Wave Structure (100 Waves + Endless)

```
╔═══════════════════════════════════════════════════════════════════╗
║  PHASE 1: ROOKIE GAUNTLET (Waves 1-20)                            ║
╠═══════════════════════════════════════════════════════════════════╣
║  Waves 1-5:    Rookie enemies (weak)                              ║
║  Waves 6-10:   Rookie enemies (normal)                            ║
║    └── Wave 10: MINI-BOSS - Strong Rookie                         ║
║  Waves 11-15:  Rookie enemies (tough) + rare Champion             ║
║  Waves 16-19:  Mixed Rookie/Champion                              ║
║    └── Wave 20: PHASE BOSS - Greymon                              ║
╚═══════════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════════╗
║  PHASE 2: CHAMPION CHALLENGE (Waves 21-40)                        ║
╠═══════════════════════════════════════════════════════════════════╣
║  Waves 21-25:  Champion enemies (weak)                            ║
║  Waves 26-30:  Champion enemies (normal)                          ║
║    └── Wave 30: MINI-BOSS - Devimon                               ║
║  Waves 31-35:  Champion enemies (tough) + rare Ultimate           ║
║  Waves 36-39:  Mixed Champion/Ultimate                            ║
║    └── Wave 40: PHASE BOSS - Myotismon                            ║
╚═══════════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════════╗
║  PHASE 3: ULTIMATE ASSAULT (Waves 41-60)                          ║
╠═══════════════════════════════════════════════════════════════════╣
║  Waves 41-45:  Ultimate enemies (weak)                            ║
║  Waves 46-50:  Ultimate enemies (normal)                          ║
║    └── Wave 50: MINI-BOSS - SkullGreymon                          ║
║  Waves 51-55:  Ultimate enemies (tough) + rare Mega               ║
║  Waves 56-59:  Mixed Ultimate/Mega                                ║
║    └── Wave 60: PHASE BOSS - VenomMyotismon                       ║
╚═══════════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════════╗
║  PHASE 4: MEGA MAYHEM (Waves 61-80)                               ║
╠═══════════════════════════════════════════════════════════════════╣
║  Waves 61-65:  Mega enemies (weak)                                ║
║  Waves 66-70:  Mega enemies (normal)                              ║
║    └── Wave 70: MINI-BOSS - Machinedramon                         ║
║  Waves 71-75:  Mega enemies (tough)                               ║
║  Waves 76-79:  Mega swarm                                         ║
║    └── Wave 80: PHASE BOSS - Omegamon                             ║
╚═══════════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════════╗
║  PHASE 5: ULTRA APOCALYPSE (Waves 81-100)                         ║
╠═══════════════════════════════════════════════════════════════════╣
║  Waves 81-85:  Mixed Mega/Ultra                                   ║
║  Waves 86-90:  Ultra enemies                                      ║
║    └── Wave 90: MINI-BOSS - Omegamon Zwart                        ║
║  Waves 91-95:  Ultra swarm                                        ║
║  Waves 96-99:  Everything mixed                                   ║
║    └── Wave 100: FINAL BOSS - Apocalymon                          ║
╚═══════════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════════╗
║  ENDLESS MODE (Wave 101+)                                         ║
╠═══════════════════════════════════════════════════════════════════╣
║  - Unlocked after clearing Wave 100                               ║
║  - Continues indefinitely until all lives are lost                ║
║  - Enemy stats scale each wave (see below)                        ║
║  - Random enemy composition with all types possible               ║
║  - Mini-boss every 10 waves, Phase-boss every 20 waves            ║
╚═══════════════════════════════════════════════════════════════════╝
```

### Endless Mode Details

#### Scaling Formula
```
Wave 101+:
  Enemy HP   = Base HP × (1.0 + (wave - 100) × 0.05)
  Enemy Armor = Base Armor + (wave - 100) × 0.5%
  Enemy Speed = Base Speed × (1.0 + (wave - 100) × 0.01)  [caps at 1.5×]

Example Wave 150:
  HP: 250% of base
  Armor: +25% bonus
  Speed: 150% of base (capped)
```

#### Enemy Composition
- Waves 101-120: Mixed Mega + occasional Ultra
- Waves 121-150: Heavy Ultra, multiple modifiers
- Waves 151+: All Ultra with 2-3 modifiers each

#### Endless Mode Bosses
| Wave | Boss Type | Notes |
|------|-----------|-------|
| Every 10 | Mini-Boss | Random Mega with 1 ability |
| Every 20 | Phase-Boss | Random Ultra with 2 abilities |
| Every 50 | Mega-Boss | Apocalymon variant with 3 abilities |

#### Leaderboard System

The leaderboard tracks two metrics for competitive play:

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENDLESS MODE LEADERBOARD                     │
├─────────────────────────────────────────────────────────────────┤
│  RANK BY SURVIVAL TIME                                          │
│  ─────────────────────                                          │
│  #1  PlayerName    Wave 187    42:35:12                         │
│  #2  PlayerName    Wave 165    38:22:45                         │
│  #3  PlayerName    Wave 152    31:18:33                         │
│                                                                 │
│  RANK BY KILLS                                                  │
│  ─────────────────                                              │
│  #1  PlayerName    4,523 kills    Wave 187                      │
│  #2  PlayerName    3,891 kills    Wave 165                      │
│  #3  PlayerName    3,245 kills    Wave 152                      │
└─────────────────────────────────────────────────────────────────┘
```

| Metric | Description |
|--------|-------------|
| **Survival Time** | Total time from Wave 101 start until game over |
| **Total Kills** | Number of enemies defeated in Endless Mode |
| **Highest Wave** | Furthest wave reached before game over |

#### Endless Mode Rewards (Optional Future Feature)
- Cosmetic unlocks based on milestones
- Wave 125: Bronze badge
- Wave 150: Silver badge
- Wave 175: Gold badge
- Wave 200: Platinum badge

### Boss Mechanics

Bosses are tanky enemies with special abilities. They do NOT attack towers directly - they simply try to reach the base like normal enemies, but have powerful abilities that affect gameplay.

| Boss Type | HP Multiplier | Armor | Abilities | Appears |
|-----------|---------------|-------|-----------|---------|
| Mini-Boss | 5x normal | 20% | 1 ability | Wave 10, 30, 50, 70, 90 |
| Phase Boss | 15x normal | 35% | 2 abilities | Wave 20, 40, 60, 80 |
| Final Boss | 30x normal | 50% | 3 abilities | Wave 100 |

### Boss Abilities Pool

Abilities are divided into two categories: **Movement/Survival** (self-buffs) and **Tower Disruption** (environmental effects).

#### Movement/Survival Abilities
| Ability | Effect | Cooldown | Visual |
|---------|--------|----------|--------|
| **Charge** | +100% move speed for 3s | 12s | Speed lines, dust trail |
| **Shield** | Immune to damage for 3s | 18s | Blue barrier sphere |
| **Regenerate** | Heals 10% max HP over 3s | 25s | Green healing particles |
| **Burrow** | Untargetable for 2s, emerges ahead | 20s | Digs underground |
| **Aura of Haste** | Nearby enemies gain +30% speed | Passive | Glowing circle around boss |

#### Tower Disruption Abilities
| Ability | Effect | Cooldown | Visual |
|---------|--------|----------|--------|
| **Roar** | Stuns ALL towers for 2s | 15s | Shockwave, screen shake |
| **Corrupt** | Disables 1 random tower for 5s | 20s | Purple lightning to tower |
| **Summon** | Spawns 3-5 minions at boss location | 20s | Dark portal effect |
| **EMP Pulse** | Reduces all tower attack speed by 50% for 4s | 25s | Electric wave |
| **Fog of War** | Reduces all tower range by 30% for 5s | 30s | Dark mist spreads |

### Boss Ability Assignments

| Boss | Wave | Abilities |
|------|------|-----------|
| **Greymon** (Mini) | 10 | Charge |
| **Devimon** (Mini) | 30 | Corrupt |
| **SkullGreymon** (Mini) | 50 | Roar |
| **Machinedramon** (Mini) | 70 | EMP Pulse |
| **Omegamon Zwart** (Mini) | 90 | Shield, Summon |
| **Myotismon** (Phase) | 20 | Corrupt, Summon |
| **VenomMyotismon** (Phase) | 40 | Roar, Regenerate |
| **Piedmon** (Phase) | 60 | Fog of War, Corrupt |
| **Omegamon** (Phase) | 80 | Shield, Charge |
| **Apocalymon** (Final) | 100 | Roar, Summon, Regenerate |

---

## 7. Economy & Balance

### Starting Resources
- **DigiBytes**: 200 DB
- **Lives**: 20
- **Free Tower**: 1 In-Training

### Wave Rewards

| Wave Range | Base Reward | Per Kill | Avg Total |
|------------|-------------|----------|-----------|
| 1-10 | 50 DB | 5 DB | ~100 DB |
| 11-20 | 75 DB | 8 DB | ~175 DB |
| 21-30 | 100 DB | 12 DB | ~280 DB |
| 31-40 | 150 DB | 18 DB | ~450 DB |
| 41-50 | 200 DB | 25 DB | ~700 DB |
| 51+ | Scales +10%/wave | Scales | Varies |

### Spawn Costs

| Stage | Random | Specific (+50%) | FREE (+100%) |
|-------|--------|-----------------|--------------|
| In-Training | 100 DB | 150 DB | 200 DB |
| Rookie | 300 DB | 450 DB | 600 DB |
| Champion | 800 DB | 1200 DB | 1600 DB |

### Level Up Costs

```
Cost = 5 DB × Current Level

Cumulative to reach level:
  Lv 10:  ~275 DB
  Lv 20:  ~1,050 DB
  Lv 35:  ~3,150 DB
  Lv 50:  ~6,375 DB
  Lv 70:  ~12,425 DB
```

### Digivolve Costs

| From → To | Cost |
|-----------|------|
| In-Training → Rookie | 100 DB |
| Rookie → Champion | 150 DB |
| Champion → Ultimate | 200 DB |
| Ultimate → Mega | 250 DB |

### Lives System

| Event | Lives Change |
|-------|--------------|
| Start | 20 lives |
| Normal enemy reaches base | -1 life |
| Boss reaches base | -3 lives |
| Every 10 waves cleared | +1 life (optional) |
| Game Over | 0 lives |

---

## 8. Combat System

### Damage Calculation
```
final_damage = base_damage × level_bonus × attribute_multiplier
level_bonus = 1 + (level × 0.02)

Example:
  Greymon Lv 30, base 18 damage, vs Virus enemy
  = 18 × 1.6 × 1.5 = 43.2 damage
```

### Status Effects

| Effect | Duration | Behavior |
|--------|----------|----------|
| **Burn** | 3s | 5% max HP/tick |
| **Poison** | 5s | 3% max HP/tick, -50% healing |
| **Freeze** | 2s | Stun, then 50% slow 3s |
| **Slow** | 3s | -30% to -50% move speed |
| **Stun** | 1-2s | Cannot move or attack |
| **Armor Break** | 5s | -20% to -50% defense |
| **Fear** | 3s | Enemy runs backward |
| **Root** | 2s | Cannot move, can attack |

### Enemy Types

| Type | Speed | HP | Armor | Special |
|------|-------|-----|-------|---------|
| Swarm | Fast | Low | None | Many weak units |
| Standard | Medium | Medium | Low | Balanced |
| Tank | Slow | High | High | Hard to kill |
| Speedster | Very Fast | Low | None | Rushes through |
| Flying | Medium | Medium | Low | Ignores some towers |
| Boss | Slow | Very High | Medium | Has abilities |

### Tower Targeting Priority

Each tower has a **default targeting priority** based on its role. Players can change any tower's priority.

#### Available Priorities
| Priority | Targets | Use Case |
|----------|---------|----------|
| **First** | Enemy closest to base | Kill before escape (default for most) |
| **Last** | Enemy furthest from base | Soften incoming waves |
| **Strongest** | Highest current HP | Focus fire tanks/bosses |
| **Weakest** | Lowest current HP | Secure kills |
| **Fastest** | Highest move speed | Catch speedsters |
| **Flying** | Flying enemies first | Anti-air specialists |
| **Closest** | Nearest to tower | Maximize attack uptime |

#### Default Priority by Tower Type
| Tower Type | Default | Examples |
|------------|---------|----------|
| Standard DPS | First | Greymon, Garurumon |
| Anti-Air / Flying | Flying | Aquilamon, Birdramon, Angemon |
| AoE / Splash | Strongest | Zudomon, MetalGreymon |
| Slow / Control | Fastest | Gabumon, Seadramon |
| Execute / Assassin | Weakest | MagnaAngemon, Beelzemon |
| Support / Healer | N/A (targets allies) | Angewomon, Magnadramon |

### Enemy Pathfinding

Enemies follow a **fixed waypoint path** from spawn to base. The complex serpentine design creates multiple **kill zones** where towers can hit enemies on multiple passes.

#### Path Waypoints (Detailed)

The path follows a complex serpentine pattern with **15 direction changes**:

```
WAYPOINT SEQUENCE (Grid coordinates: Column, Row)

START: Spawn at (1, 2)

SEGMENT 1: Horizontal Right (→)
├── Waypoint 0:  (1, 2)  - SPAWN
├── Waypoint 1:  (2, 2)
└── Waypoint 2:  (3, 2)  - TURN 1 (turn down)

SEGMENT 2: Vertical Down (↓)
├── Waypoint 3:  (3, 3)
├── Waypoint 4:  (3, 4)
└── Waypoint 5:  (3, 5)  - TURN 2 (turn left)

SEGMENT 3: Horizontal Left (←)
└── Waypoint 6:  (2, 5)  - TURN 3 (turn down)

SEGMENT 4: Vertical Down (↓)
├── Waypoint 7:  (2, 6)
└── Waypoint 8:  (2, 7)  - TURN 4 (turn right)

SEGMENT 5: Horizontal Right (→)
├── Waypoint 9:  (3, 7)
├── Waypoint 10: (4, 7)
└── Waypoint 11: (5, 7)  - TURN 5 (turn up)

SEGMENT 6: Vertical Up (↑)
├── Waypoint 12: (5, 6)
├── Waypoint 13: (5, 5)
├── Waypoint 14: (5, 4)
└── Waypoint 15: (5, 3)  - TURN 6 (turn right)

SEGMENT 7: Horizontal Right (→)
├── Waypoint 16: (6, 3)
└── Waypoint 17: (7, 3)  - TURN 7 (turn down)

SEGMENT 8: Long Vertical Down (↓)
├── Waypoint 18: (7, 4)
├── Waypoint 19: (7, 5)
├── Waypoint 20: (7, 6)
├── Waypoint 21: (7, 7)
├── Waypoint 22: (7, 8)
├── Waypoint 23: (7, 9)
├── Waypoint 24: (7, 10)
├── Waypoint 25: (7, 11)
├── Waypoint 26: (7, 12)
└── Waypoint 27: (7, 13) - TURN 8 (turn left)

SEGMENT 9: Horizontal Left (←)
├── Waypoint 28: (6, 13)
├── Waypoint 29: (5, 13)
├── Waypoint 30: (4, 13)
└── Waypoint 31: (3, 13) - TURN 9 (turn up)

SEGMENT 10: Vertical Up (↑)
├── Waypoint 32: (3, 12)
├── Waypoint 33: (3, 11)
├── Waypoint 34: (3, 10)
└── Waypoint 35: (3, 9)  - TURN 10 (turn left)

SEGMENT 11: Horizontal Left (←)
├── Waypoint 36: (2, 9)
└── Waypoint 37: (1, 9)  - TURN 11 (turn down)

SEGMENT 12: Long Vertical Down (↓)
├── Waypoint 38: (1, 10)
├── Waypoint 39: (1, 11)
├── Waypoint 40: (1, 12)
├── Waypoint 41: (1, 13)
├── Waypoint 42: (1, 14)
├── Waypoint 43: (1, 15)
├── Waypoint 44: (1, 16)
├── Waypoint 45: (1, 17)
└── Waypoint 46: (1, 18) - TURN 12 (turn right)

SEGMENT 13: Horizontal Right (→)
├── Waypoint 47: (2, 18)
├── Waypoint 48: (3, 18)
└── Waypoint 49: (4, 18) - TURN 13 (turn up)

SEGMENT 14: Vertical Up (↑)
├── Waypoint 50: (4, 17)
├── Waypoint 51: (4, 16)
└── Waypoint 52: (4, 15) - TURN 14 (turn right)

SEGMENT 15: Final Approach Right (→)
├── Waypoint 53: (5, 15)
├── Waypoint 54: (6, 15)
├── Waypoint 55: (7, 15)
└── Waypoint 56: (8, 15) - END (enemies exit here)

END: Base at (8, 15) - Lives lost if enemy reaches here
```

#### Turn Points Summary
```
Turn #   Location   Direction Change
──────   ────────   ────────────────
  1      (3, 2)     Right → Down
  2      (3, 5)     Down → Left
  3      (2, 5)     Left → Down
  4      (2, 7)     Down → Right
  5      (5, 7)     Right → Up
  6      (5, 3)     Up → Right
  7      (7, 3)     Right → Down
  8      (7, 13)    Down → Left
  9      (3, 13)    Left → Up
  10     (3, 9)     Up → Left
  11     (1, 9)     Left → Down
  12     (1, 18)    Down → Right
  13     (4, 18)    Right → Up
  14     (4, 15)    Up → Right
  15     (8, 15)    → END
```

#### Strategic Tower Placement Zones

```
KILL ZONE ANALYSIS:

Zone A - "Upper Loop" (Row 2-7, Col 1-5)
┌─────────────────────────────────────┐
│ Dense switchback area:             │
│ - Path passes through 4 times      │
│ - Towers can hit multiple segments │
│ - Critical early-game zone         │
│ Best for: AoE, Multi-hit towers    │
└─────────────────────────────────────┘

Zone B - "Central Corridor" (Row 3-7, Col 6-8)
┌─────────────────────────────────────┐
│ Long vertical descent:             │
│ - Path goes down Col 7 for 10 rows │
│ - Extended damage window           │
│ - High-value sustained DPS spot    │
│ Best for: High DPS, DoT towers     │
└─────────────────────────────────────┘

Zone C - "Middle Crossroads" (Row 9-13, Col 2-6)
┌─────────────────────────────────────┐
│ Path crosses multiple times:       │
│ - Horizontal at Row 9 and Row 13   │
│ - Vertical at Col 3                │
│ Best for: Long-range, Splash       │
└─────────────────────────────────────┘

Zone D - "Lower Loop" (Row 14-18, Col 1-4)
┌─────────────────────────────────────┐
│ Final switchback section:          │
│ - Path goes down, right, up, right │
│ - Last chance for kills            │
│ Best for: Burst, Execute, Cleanup  │
└─────────────────────────────────────┘

Zone E - "Exit Corridor" (Row 15, Col 5-8)
┌─────────────────────────────────────┐
│ Final approach to base:            │
│ - Enemies making final dash        │
│ - Critical cleanup zone            │
│ Best for: High burst, Slow effects │
└─────────────────────────────────────┘
```

#### Tower Coverage by Position

| Zone | Grid Area | Path Segments Covered | Recommended Tower Types |
|------|-----------|----------------------|------------------------|
| **A** | Row 2-7, Col 1-5 | Upper switchbacks (4 passes) | AoE, Multi-hit |
| **B** | Row 3-13, Col 6-8 | Long vertical corridor | Sustained DPS, DoT |
| **C** | Row 9-13, Col 2-6 | Middle crossroads | Long-range, Splash |
| **D** | Row 14-18, Col 1-4 | Lower switchback | Burst, Execute |
| **E** | Row 15, Col 5-8 | Exit corridor | High burst, Slow |

#### Range and Multi-Hit Examples
```
EXAMPLE: Tower with Range 3.0 at position (4, 6) - Upper Loop

Coverage Radius (3 tiles in all directions):
    Col: 1   2   3   4   5   6   7   8
        ┌───┬───┬───┬───┬───┬───┬───┬───┐
Row 3   │   │   │ P │   │ P │ P │ P │   │  P = Path
        ├───┼───┼───┼───┼───┼───┼───┼───┤
Row 4   │   │   │ P*│ T │ P*│   │ P*│   │  T = Tower (4,6)
        ├───┼───┼───┼───┼───┼───┼───┼───┤  * = Within range
Row 5   │   │ P*│ P*│ T │ P*│   │ P*│   │
        ├───┼───┼───┼───┼───┼───┼───┼───┤
Row 6   │   │ P*│   │ T │ P*│   │ P*│   │
        ├───┼───┼───┼───┼───┼───┼───┼───┤
Row 7   │   │ P*│ P*│ P*│ P*│   │ P*│   │
        └───┴───┴───┴───┴───┴───┴───┴───┘

This tower can hit path at:
  - Col 2: Row 5, 6, 7 (3 tiles)
  - Col 3: Row 4, 5, 7 (3 tiles)
  - Col 5: Row 4, 5, 6, 7 (4 tiles)
  - Col 7: Row 4, 5, 6, 7 (4 tiles)
  = Enemies pass through range on MULTIPLE segments!
```

#### Coverage by Range
| Range | Avg Passes | Best Placement |
|-------|------------|----------------|
| 1.0-1.5 | 1-2× | Directly adjacent to path |
| 2.0-2.5 | 2-4× | Near turns/corners |
| 3.0-3.5 | 4-6× | Zone A or C (crossroads) |
| 4.0-5.0 | 6-10× | Can reach multiple segments |
| 5.5-6.0 | 10-15× | Central position, massive coverage |

#### Path Properties
| Property | Value |
|----------|-------|
| Grid size | 8 columns × 18 rows |
| Path type | Fixed waypoints (not dynamic A*) |
| Total waypoints | 57 points |
| Total path tiles | 57 tiles |
| Direction changes | 15 turns |
| Tower slots | 87 placement cells |
| Path length | ~45-50 seconds at 1.0× speed |
| Flying enemies | Follow same path (no shortcuts) |
| Speedsters (2.0×) | ~22-25 seconds to base |
| Tanks (0.6×) | ~75-83 seconds to base |

#### Why Fixed Waypoints (Not A*)
- **Predictable**: Players can plan tower placement strategically
- **Performant**: No runtime pathfinding calculations needed
- **Fair**: All enemies take the same route
- **Strategic**: Complex serpentine design rewards range and positioning
- **Multiple passes**: Enemies traverse near same areas multiple times

### Support Towers & Life Recovery

Support Digimon with "Heal" effects **restore lives** - helping protect the base.

#### Life Recovery Mechanics
| Effect | Trigger | Amount | Cooldown |
|--------|---------|--------|----------|
| **Heal (on hit)** | Each attack | +0.1 lives | None (slow accumulation) |
| **Heal (on kill)** | Kill participation | +0.5 lives | None |
| **Heal Aura** | Passive | +0.05 lives/sec | None |
| **Mass Heal** | Active ability | +1-2 lives | 30-60s |

*Life recovery is intentionally slow - support is valuable but not overpowered.*

#### Support Digimon Examples
| Digimon | Heal Type | Rate | Max Recovery/Wave |
|---------|-----------|------|-------------------|
| Sunflowmon | Aura | +0.05/s | ~1 life |
| Angewomon | On hit | +0.1/hit | ~2-3 lives |
| Magnadramon | Aura + On kill | +0.05/s, +0.5/kill | ~3-4 lives |
| Lotosmon | Aura | +0.1/s | ~2 lives |
| Mastemon | Mass Heal | +2 lives | 2 lives (60s CD) |

*Life recovery caps at starting lives (20). Cannot exceed maximum.*

---

## 9. Digimon Database

For complete Digimon stats, evolution paths, and detailed ability information, see:
**[DIGIMON_STATS_DATABASE.md](./DIGIMON_STATS_DATABASE.md)**

### Database Overview

The full database contains **~150 Digimon** across all 6 tiers:

| Tier | Stage | Count | Features |
|------|-------|-------|----------|
| 0 | In-Training | 14 | Starting stage, no combat |
| 1 | Rookie | 30+ | First combat tier, basic effects |
| 2 | Champion | 40+ | DP-gated evolutions, stronger effects |
| 3 | Ultimate | 35+ | Powerful abilities, special abilities unlock |
| 4 | Mega | 25+ | Peak power, DNA candidates |
| 5 | Ultra | 10+ | DNA fusion results only |

### Stat Categories

Each Digimon entry includes:
- **Base Damage (DMG)**: Raw damage per attack
- **Attack Speed (SPD)**: Attacks per second
- **Attack Range (RNG)**: Tile radius
- **Effect Type**: Status effect applied on hit
- **Effect Chance**: Probability of applying effect
- **Default Priority**: Tower's default targeting priority (player can override)
- **DP Requirements**: Min/Max DP to unlock evolution path
- **Evolution Paths**: All possible evolutions with DP thresholds
- **DP Requirements**: Min/Max DP to unlock evolution path
- **Evolution Paths**: All possible evolutions with DP thresholds

### Quick Reference - Evolution Trees

See the full database for complete trees. Key starter lines:

| In-Training | Rookie | Family | Theme |
|-------------|--------|--------|-------|
| Koromon | Agumon | Dragon's Roar | Fire DPS |
| Tsunomon | Gabumon | Nature Spirits | Ice Control |
| Tokomon | Patamon | Virus Busters | Holy Support |
| Pagumon | DemiDevimon | Nightmare Soldiers | Dark Debuff |
| Gigimon | Guilmon | Dragon's Roar | Fire Tank |
| Viximon | Renamon | Nature Spirits | Magic Multi-hit |
| DemiVeemon | Veemon | Dragon's Roar | Free/Versatile |

### DNA Digivolution Quick Reference

| Digimon A | Digimon B | Ultra Result |
|-----------|-----------|--------------|
| WarGreymon | MetalGarurumon | Omegamon |
| BlackWarGreymon | BlackMetalGarurumon | Omegamon Zwart |
| Angewomon | LadyDevimon | Mastemon |
| Imperialdramon FM | Omegamon | Imperialdramon PM |
| Gallantmon | Grani | Gallantmon CM |
| Seraphimon | Ophanimon | Susanoomon |

---

## 10. Data Structures

### DigimonData Resource
```gdscript
class_name DigimonData extends Resource

@export var digimon_name: String = ""
@export var stage: int = 0  # 0=In-Training, 1=Rookie, 2=Champion, etc.
@export var attribute: int = 0  # 0=Vaccine, 1=Data, 2=Virus, 3=Free
@export var family: int = 0

# Base stats
@export var base_damage: int = 0
@export var attack_speed: float = 1.0
@export var attack_range: float = 2.0

# Status effect
@export var effect_type: String = ""
@export var effect_chance: float = 0.0

# Evolution paths
@export var evolutions: Array[EvolutionPath] = []

# DNA Digivolution
@export var dna_partner: String = ""
@export var dna_result: String = ""
```

### EvolutionPath Resource
```gdscript
class_name EvolutionPath extends Resource

@export var result_digimon: String = ""
@export var min_dp: int = 0
@export var max_dp: int = 99
@export var is_default: bool = false
```

### DigimonTower Instance
```gdscript
class_name DigimonTower extends Node2D

var digimon_data: DigimonData
var current_dp: int = 0
var current_level: int = 1
var origin_stage: int = 0  # Stage when spawned

func get_max_level() -> int:
    var base = [10, 20, 35, 50, 70, 100][digimon_data.stage]
    var dp_bonus = [1, 2, 3, 4, 5, 5][digimon_data.stage]
    var origin_bonus = (digimon_data.stage - origin_stage) * 5
    return base + (current_dp * dp_bonus) + origin_bonus

func can_digivolve() -> bool:
    var base_max = [10, 20, 35, 50, 70, 100][digimon_data.stage]
    return current_level >= base_max

func get_max_reachable_stage() -> int:
    # Origin determines max stage
    match origin_stage:
        0: return 2  # In-Training origin → Champion max
        1: return 3  # Rookie origin → Ultimate max
        2: return 4  # Champion origin → Mega max
        _: return 5
```

### GameState Singleton
```gdscript
extends Node

var digibytes: int = 200
var lives: int = 20
var current_wave: int = 1
var active_digimon: Array[DigimonTower] = []

const SPAWN_COSTS = {
    "in_training": {"random": 100, "specific": 150, "free": 200},
    "rookie": {"random": 300, "specific": 450, "free": 600},
    "champion": {"random": 800, "specific": 1200, "free": 1600}
}

const DIGIVOLVE_COSTS = [100, 150, 200, 250]  # Per stage transition

func get_level_up_cost(current_level: int) -> int:
    return 5 * current_level
```

---

## 11. Technical Specifications

### Performance Targets
- 60 FPS stable gameplay
- Support 20 towers on grid
- Support 100+ enemies on screen
- Smooth drag-and-drop for merging

### Godot Scene Structure

```
Main (Node)
├── Autoloads (Singletons - set in Project Settings)
│   ├── GameManager         # Game state, lives, DB, wave, speed
│   ├── EventBus            # Global signals for loose coupling
│   ├── AudioManager        # SFX and music playback
│   ├── SaveManager         # Save/load functionality
│   └── DigimonDatabase     # Loads all DigimonData resources
│
├── Scenes/
│   ├── MainMenu (main_menu.tscn)
│   │   ├── Background
│   │   ├── Title
│   │   ├── MenuButtons (VBoxContainer)
│   │   │   ├── PlayButton
│   │   │   ├── EncyclopediaButton
│   │   │   ├── SettingsButton
│   │   │   └── QuitButton
│   │   └── StarterSelection (starter_selection.tscn) [popup]
│   │
│   ├── Game (game.tscn) - Main gameplay scene
│   │   ├── Map (Node2D)
│   │   │   ├── TileMap              # Visual grid (path + tower slots)
│   │   │   ├── Path2D               # Enemy path with waypoints
│   │   │   ├── TowerSlots (Node2D)  # Container for tower slot areas
│   │   │   │   └── TowerSlot (Area2D) [×87 instances]
│   │   │   ├── Towers (Node2D)      # Container for placed towers
│   │   │   │   └── DigimonTower (digimon_tower.tscn) [dynamic]
│   │   │   └── Enemies (Node2D)     # Container for enemies
│   │   │       └── Enemy (enemy.tscn) [dynamic]
│   │   │
│   │   ├── Projectiles (Node2D)     # Container for projectiles
│   │   │   └── Projectile (projectile.tscn) [dynamic]
│   │   │
│   │   ├── UI (CanvasLayer)
│   │   │   ├── HUD (hud.tscn)
│   │   │   │   ├── TopBar
│   │   │   │   │   ├── LivesDisplay
│   │   │   │   │   ├── DBDisplay
│   │   │   │   │   ├── WaveDisplay
│   │   │   │   │   ├── SpeedButton
│   │   │   │   │   ├── SettingsButton
│   │   │   │   │   └── PauseButton
│   │   │   │   ├── BossHealthBar [hidden until boss wave]
│   │   │   │   └── BottomPanel
│   │   │   │       ├── TowerInfoPanel (tower_info.tscn)
│   │   │   │       └── SpawnMenuPanel (spawn_menu.tscn)
│   │   │   │
│   │   │   ├── Modals (Control) [hidden by default]
│   │   │   │   ├── EvolutionModal (evolution_modal.tscn)
│   │   │   │   ├── MergeModal (merge_modal.tscn)
│   │   │   │   ├── SellModal (sell_modal.tscn)
│   │   │   │   ├── WaveCompleteModal (wave_complete.tscn)
│   │   │   │   └── GameOverModal (game_over.tscn)
│   │   │   │
│   │   │   ├── PauseMenu (pause_menu.tscn) [hidden]
│   │   │   │
│   │   │   └── DragPreview (Node2D)  # Ghost sprite while dragging
│   │   │
│   │   ├── WaveManager (Node)        # Spawns enemies per wave data
│   │   ├── CombatManager (Node)      # Handles damage, effects
│   │   └── TutorialManager (Node)    # Tutorial hints
│   │
│   ├── Encyclopedia (encyclopedia.tscn)
│   │   ├── Navigation
│   │   ├── DigimonList
│   │   ├── DigimonDetail
│   │   └── EvolutionTreeView
│   │
│   └── Settings (settings.tscn)
│       ├── AudioSettings
│       ├── DisplaySettings
│       ├── GameplaySettings
│       └── AccessibilitySettings
│
└── Resources/
    ├── digimon/ (DigimonData .tres files)
    ├── waves/ (WaveData .tres files)
    ├── effects/ (StatusEffect .tres files)
    └── abilities/ (BossAbility .tres files)
```

### Scene Descriptions

| Scene | Purpose |
|-------|---------|
| `main_menu.tscn` | Title screen, navigation |
| `starter_selection.tscn` | New game starter picker |
| `game.tscn` | Core gameplay, contains map and all game systems |
| `digimon_tower.tscn` | Individual tower instance (sprite, stats, targeting) |
| `enemy.tscn` | Individual enemy instance (sprite, HP, pathfinding) |
| `projectile.tscn` | Attack projectile (moves toward target, applies damage) |
| `hud.tscn` | Always-visible game UI |
| `tower_info.tscn` | Selected tower details panel |
| `spawn_menu.tscn` | Spawn configuration panel |
| `evolution_modal.tscn` | Evolution selection popup |
| `merge_modal.tscn` | Merge confirmation popup |
| `encyclopedia.tscn` | Digimon database browser |
| `settings.tscn` | Game settings |

### Autoload Singletons

```gdscript
# GameManager.gd - Central game state
extends Node

signal digibytes_changed(amount)
signal lives_changed(amount)
signal wave_changed(wave_number)
signal game_speed_changed(speed)
signal game_over

var digibytes: int = 200
var lives: int = 20
var current_wave: int = 0
var game_speed: float = 1.0
var is_paused: bool = false
var selected_tower: DigimonTower = null

# EventBus.gd - Decoupled communication
extends Node

signal tower_placed(tower, position)
signal tower_sold(tower)
signal tower_selected(tower)
signal tower_deselected
signal enemy_spawned(enemy)
signal enemy_died(enemy, killer)
signal enemy_reached_base(enemy)
signal wave_started(wave_number)
signal wave_completed(wave_number)
signal boss_spawned(boss)
signal boss_ability_used(boss, ability)
signal merge_requested(tower_a, tower_b)
signal evolution_requested(tower)
```

### Save System

The game uses a JSON-based save format that can be exported/imported as a file.

#### Save Triggers
- **Auto-save**: After each wave completion
- **Manual save**: From pause menu
- **Export**: Save to external file for backup/sharing

#### Save File Structure
```json
{
  "version": "1.0",
  "timestamp": "2025-02-04T10:30:00Z",
  "game_state": {
    "digibytes": 1250,
    "lives": 18,
    "current_wave": 25,
    "highest_wave": 25,
    "game_mode": "normal",
    "total_playtime_seconds": 3600
  },
  "towers": [
    {
      "id": "tower_001",
      "digimon_id": "greymon",
      "grid_position": {"col": 4, "row": 6},
      "level": 25,
      "dp": 3,
      "origin_stage": 0,
      "targeting_priority": "first"
    },
    {
      "id": "tower_002",
      "digimon_id": "garurumon",
      "grid_position": {"col": 2, "row": 8},
      "level": 20,
      "dp": 1,
      "origin_stage": 1,
      "targeting_priority": "strongest"
    }
  ],
  "statistics": {
    "total_enemies_killed": 423,
    "total_db_earned": 12500,
    "total_db_spent": 11250,
    "digimon_spawned": 15,
    "merges_performed": 8,
    "digivolutions_performed": 12
  },
  "endless_mode": {
    "unlocked": false,
    "best_wave": 0,
    "best_survival_time": 0,
    "best_kill_count": 0
  },
  "tutorial": {
    "completed": true,
    "hints_shown": ["wave1_controls", "wave2_currency", "wave3_attributes"]
  },
  "settings_snapshot": {
    "game_speed": 1.0,
    "auto_pause": true
  }
}
```

#### Save File Locations
| Platform | Location |
|----------|----------|
| Windows | `%APPDATA%/DigimonTowerMerge/saves/` |
| Linux | `~/.local/share/DigimonTowerMerge/saves/` |
| Mac | `~/Library/Application Support/DigimonTowerMerge/saves/` |

#### Export/Import Feature
```
┌─────────────────────────────────────────────────────────────────┐
│                    SAVE MANAGEMENT                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  SAVE SLOTS:                                                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Slot 1: Wave 25 | 1,250 DB | 18 Lives | 1h 00m           │   │
│  │         [Load] [Export] [Delete]                          │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Slot 2: Empty                                             │   │
│  │         [New Game]                                        │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Slot 3: Empty                                             │   │
│  │         [New Game]                                        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  [Import Save File]                                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Save Validation
- Version check on load (handle migration for older saves)
- Checksum to detect corrupted files
- Graceful error handling with backup restoration option

#### GDScript Save Manager
```gdscript
class_name SaveManager
extends Node

const SAVE_VERSION = "1.0"
const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".dtmsave"  # Digimon Tower Merge Save

func save_game(slot: int) -> bool:
    var save_data = {
        "version": SAVE_VERSION,
        "timestamp": Time.get_datetime_string_from_system(),
        "game_state": _get_game_state(),
        "towers": _get_tower_data(),
        "statistics": _get_statistics(),
        "endless_mode": _get_endless_data(),
        "tutorial": _get_tutorial_data(),
        "settings_snapshot": _get_settings_snapshot()
    }

    var file_path = SAVE_DIR + "slot_" + str(slot) + SAVE_EXTENSION
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(save_data, "\t"))
        file.close()
        return true
    return false

func load_game(slot: int) -> Dictionary:
    var file_path = SAVE_DIR + "slot_" + str(slot) + SAVE_EXTENSION
    if not FileAccess.file_exists(file_path):
        return {}

    var file = FileAccess.open(file_path, FileAccess.READ)
    var json = JSON.new()
    var parse_result = json.parse(file.get_as_text())
    file.close()

    if parse_result == OK:
        return json.get_data()
    return {}

func export_save(slot: int, export_path: String) -> bool:
    # Copy save file to user-specified location
    var source = SAVE_DIR + "slot_" + str(slot) + SAVE_EXTENSION
    return DirAccess.copy_absolute(source, export_path) == OK

func import_save(import_path: String, slot: int) -> bool:
    # Copy external file to save slot
    var dest = SAVE_DIR + "slot_" + str(slot) + SAVE_EXTENSION
    return DirAccess.copy_absolute(import_path, dest) == OK
```

### UI Requirements
- Tower info panel (stats, DP, Origin, level cap)
- Evolution choice modal with DP requirements
- Currency and lives display
- Wave counter and enemy preview
- Boss health bar
- Spawn menu with cost options

---

## 12. Settings Menu

### Menu Structure
```
MAIN MENU
├── Play
│   └── [Starts new game or continues]
├── Encyclopedia
│   └── [Opens Digivolution Encyclopedia]
├── Settings
│   └── [Opens Settings Menu]
└── Quit
    └── [Exit game]

PAUSE MENU (In-Game)
├── Resume
├── Settings
├── Restart Wave
│   └── [Restarts current wave, keeps towers]
├── Main Menu
│   └── [Confirmation prompt]
└── Quit
    └── [Confirmation prompt]
```

### Settings Categories

#### Audio Settings
| Setting | Type | Default | Range | Description |
|---------|------|---------|-------|-------------|
| Master Volume | Slider | 80% | 0-100% | Overall game volume |
| Music Volume | Slider | 70% | 0-100% | Background music |
| SFX Volume | Slider | 100% | 0-100% | Sound effects |
| UI Sounds | Toggle | ON | ON/OFF | Button clicks, notifications |

#### Display Settings
| Setting | Type | Default | Options | Description |
|---------|------|---------|---------|-------------|
| Fullscreen | Toggle | ON | ON/OFF | Fullscreen or windowed |
| Resolution | Dropdown | Native | 1280x720, 1920x1080, 2560x1440 | Screen resolution |
| VSync | Toggle | ON | ON/OFF | Vertical sync |
| Show FPS | Toggle | OFF | ON/OFF | Display FPS counter |
| Screen Shake | Toggle | ON | ON/OFF | Camera shake on impacts |

#### Gameplay Settings
| Setting | Type | Default | Options | Description |
|---------|------|---------|---------|-------------|
| Game Speed | Dropdown | 1x | 1x, 1.5x, 2x | Wave playback speed |
| Auto-Pause | Toggle | ON | ON/OFF | Pause between waves |
| Damage Numbers | Toggle | ON | ON/OFF | Show floating damage |
| Health Bars | Dropdown | All | All, Bosses Only, Off | Enemy health display |
| Range Indicators | Toggle | ON | ON/OFF | Show tower range on select |
| Tooltips | Toggle | ON | ON/OFF | Hover information |
| Confirm Merge | Toggle | ON | ON/OFF | Confirmation before merge |
| Confirm Digivolve | Toggle | ON | ON/OFF | Confirmation before digivolve |
| Show Tutorial | Toggle | ON | ON/OFF | Show tutorial hints (Waves 1-10) |

#### Accessibility Settings
| Setting | Type | Default | Options | Description |
|---------|------|---------|---------|-------------|
| Colorblind Mode | Dropdown | Off | Off, Protanopia, Deuteranopia, Tritanopia | Color adjustments |
| Text Size | Dropdown | Medium | Small, Medium, Large | UI text scaling |
| Reduced Motion | Toggle | OFF | ON/OFF | Minimize animations |

### Default Configuration File
```gdscript
# default_settings.gd
const DEFAULT_SETTINGS = {
    "audio": {
        "master_volume": 0.8,
        "music_volume": 0.7,
        "sfx_volume": 1.0,
        "ui_sounds": true
    },
    "display": {
        "fullscreen": true,
        "resolution": Vector2i(1920, 1080),
        "vsync": true,
        "show_fps": false,
        "screen_shake": true
    },
    "gameplay": {
        "game_speed": 1.0,
        "auto_pause": true,
        "damage_numbers": true,
        "health_bars": "all",  # "all", "bosses", "off"
        "range_indicators": true,
        "tooltips": true,
        "confirm_merge": true,
        "confirm_digivolve": true,
        "show_tutorial": true,
        "tutorial_prompt_answered": false  # True after player chooses at new game
    },
    "accessibility": {
        "colorblind_mode": "off",  # "off", "protanopia", "deuteranopia", "tritanopia"
        "text_size": "medium",  # "small", "medium", "large"
        "reduced_motion": false
    }
}
```

---

## 13. UI/UX Design

### Main HUD Layout
```
┌─────────────────────────────────────────────────────────────────────────┐
│ ┌──────────┐  ┌──────────┐  ┌──────────┐              ┌──────────────┐ │
│ │ ♥ 20     │  │ 💰 1,250 │  │ Wave 15  │              │ ⚙ Settings   │ │
│ │ Lives    │  │ DigiBytes│  │  /100    │              │ ⏸ Pause      │ │
│ └──────────┘  └──────────┘  └──────────┘              └──────────────┘ │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│                                                                         │
│                         [ GAME MAP AREA ]                               │
│                           8 × 18 Grid                                   │
│                                                                         │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────┐  ┌────────────────────────────────────┐ │
│ │ SELECTED TOWER INFO         │  │ SPAWN MENU                         │ │
│ │ ┌─────┐ Greymon  Lv 25/35   │  │ ┌────────┐ ┌────────┐ ┌────────┐  │ │
│ │ │sprite│ DP: 3  Origin: R   │  │ │In-Train│ │ Rookie │ │Champion│  │ │
│ │ └─────┘ ATK: 18  SPD: 0.8   │  │ │ 100 DB │ │ 300 DB │ │ 800 DB │  │ │
│ │ Vaccine | Dragon's Roar     │  │ └────────┘ └────────┘ └────────┘  │ │
│ │                             │  │                                    │ │
│ │ [Level Up: 125 DB] [Evolve] │  │ [Random] [Specific] [FREE]        │ │
│ │ [Merge] [Sell: 50 DB]       │  │                                    │ │
│ └─────────────────────────────┘  └────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

### HUD Elements Detail

#### Top Bar
| Element | Position | Content |
|---------|----------|---------|
| Lives | Top-left | Heart icon + current lives (e.g., "♥ 18") |
| DigiBytes | Top-left-center | Coin icon + current DB (e.g., "💰 1,250") |
| Wave Counter | Top-center | "Wave 15 / 100" or "Endless: Wave 127" |
| Settings | Top-right | Gear icon, opens settings |
| Pause | Top-right | Pause icon, pauses game |

#### Bottom Panel - Tower Info (Left)
Shows when a tower is selected:
```
┌─────────────────────────────────────┐
│ ┌───────┐  GREYMON                  │
│ │       │  ════════════════════     │
│ │ 64×64 │  Stage: Champion          │
│ │sprite │  Level: 25 / 35 (max)     │
│ │       │  DP: 3                    │
│ └───────┘  Origin: Rookie           │
│                                     │
│  ATK: 18 (+50%)   SPD: 0.8/s        │
│  RNG: 3.0 tiles   Effect: Burn 25%  │
│  Attribute: Vaccine                 │
│  Family: Dragon's Roar              │
│  Target: First                      │
│                                     │
│  ┌───────────┐ ┌───────────┐        │
│  │ Level Up  │ │ Digivolve │        │
│  │  125 DB   │ │  150 DB   │        │
│  └───────────┘ └───────────┘        │
│  ┌───────────┐ ┌───────────┐        │
│  │   Merge   │ │   Sell    │        │
│  │  (Drag)   │ │   50 DB   │        │
│  └───────────┘ └───────────┘        │
└─────────────────────────────────────┘
```

#### Bottom Panel - Spawn Menu (Right)
Always visible for quick access:
```
┌─────────────────────────────────────┐
│         SPAWN DIGIMON              │
├─────────────────────────────────────┤
│  STAGE:                             │
│  ┌──────────┐┌──────────┐┌────────┐ │
│  │In-Training││ Rookie  ││Champion│ │
│  │  100 DB  ││  300 DB ││ 800 DB │ │
│  │    ✓     ││         ││        │ │
│  └──────────┘└──────────┘└────────┘ │
│                                     │
│  TYPE:                              │
│  ┌──────────┐┌──────────┐┌────────┐ │
│  │  Random  ││ Specific ││  FREE  │ │
│  │   ×1.0   ││   ×1.5   ││  ×2.0  │ │
│  │    ✓     ││          ││        │ │
│  └──────────┘└──────────┘└────────┘ │
│                                     │
│  Total: 100 DB                      │
│  ─────────────────────              │
│  Drag to empty cell to spawn        │
│  or click empty cell directly       │
└─────────────────────────────────────┘
```

### Evolution Selection Modal
```
┌───────────────────────────────────────────────────────────────┐
│                       DIGIVOLUTION                            │
│                      Cost: 150 DB                             │
├───────────────────────────────────────────────────────────────┤
│  Agumon (DP: 3, Origin: Rookie) can evolve into:              │
│                                                               │
│  ┌─────────────────────┐  ┌─────────────────────┐             │
│  │ ┌───────┐           │  │ ┌───────┐           │             │
│  │ │       │  Greymon  │  │ │       │ GeoGreymon│             │
│  │ │ sprite│           │  │ │ sprite│           │             │
│  │ └───────┘           │  │ └───────┘           │             │
│  │ DMG: 18   SPD: 0.8  │  │ DMG: 22   SPD: 0.7  │             │
│  │ RNG: 3.0            │  │ RNG: 2.5            │             │
│  │ Effect: Burn 25%    │  │ Effect: Quake 30%   │             │
│  │ ─────────────────── │  │ ─────────────────── │             │
│  │ DP Required: 0-2    │  │ DP Required: 3-4    │             │
│  │ ░░░░░░░░░░░░░░░░░░ │  │ ████████████░░░░░░ │             │
│  │      LOCKED         │  │     AVAILABLE ✓     │             │
│  │                     │  │     [SELECT]        │             │
│  └─────────────────────┘  └─────────────────────┘             │
│                                                               │
│  Your DP: 3 | Can reach: Ultimate (Origin: Rookie)            │
│                                                               │
│                                            [Cancel]           │
└───────────────────────────────────────────────────────────────┘
```

### Merge Confirmation Modal
```
┌───────────────────────────────────────────────────────────────┐
│                         MERGE                                 │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│    ┌───────────┐              ┌───────────┐                   │
│    │           │              │           │                   │
│    │  Greymon  │      →       │  Greymon  │                   │
│    │           │    MERGE     │           │                   │
│    └───────────┘              └───────────┘                   │
│       DP: 2                      DP: 4                        │
│       Origin: Rookie             Origin: In-Training          │
│       SACRIFICE                  SURVIVOR                     │
│                                                               │
│    ═══════════════════════════════════════════                │
│                                                               │
│    RESULT:                                                    │
│    • Survivor DP: 4 → 5 (+1)                                  │
│    • Survivor Origin: In-Training (better, kept)              │
│    • Sacrifice is permanently lost                            │
│                                                               │
│    ┌─────────────────┐    ┌─────────────────┐                 │
│    │  CONFIRM MERGE  │    │     Cancel      │                 │
│    └─────────────────┘    └─────────────────┘                 │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### Wave Start / Complete Screens

#### Wave Start (Brief)
```
┌───────────────────────────────────────┐
│          ⚔ WAVE 16 ⚔                 │
│                                       │
│   Enemies: 12 Rookies, 4 Champions    │
│   Attributes: Mixed                   │
│                                       │
│        [Starting in 3...]             │
└───────────────────────────────────────┘
```

#### Wave Complete
```
┌───────────────────────────────────────────────────────────────┐
│                   ✓ WAVE 15 COMPLETE!                         │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│   Enemies Defeated: 18 / 18                                   │
│   DB Earned: +225 DB                                          │
│   Lives Remaining: 18 ♥                                       │
│                                                               │
│   ┌─────────────────────────────────────────────────────────┐ │
│   │ NEXT WAVE PREVIEW:                                      │ │
│   │ Wave 16: 12 Rookies, 4 Champions                        │ │
│   │ Attributes: Vaccine (40%), Data (35%), Virus (25%)      │ │
│   │ Special: None                                           │ │
│   └─────────────────────────────────────────────────────────┘ │
│                                                               │
│   ┌───────────────────┐    ┌───────────────────┐              │
│   │  START WAVE 16    │    │  Keep Building    │              │
│   └───────────────────┘    └───────────────────┘              │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### Boss Health Bar
```
During boss waves, a large health bar appears at top of screen:

┌─────────────────────────────────────────────────────────────────────────┐
│  👿 MYOTISMON - Phase Boss                                              │
│  ████████████████████████████████░░░░░░░░░░░░░░░░░░░░  65% HP          │
│  Abilities: [Corrupt ⏱12s] [Summon ⏱5s]                                 │
└─────────────────────────────────────────────────────────────────────────┘
```

### Game Over Screen
```
┌───────────────────────────────────────────────────────────────┐
│                      GAME OVER                                │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│                  You reached Wave 47                          │
│                                                               │
│   ┌─────────────────────────────────────────────────────────┐ │
│   │  STATISTICS                                             │ │
│   │  ─────────────────────────────────────                  │ │
│   │  Total Playtime: 1h 23m 45s                             │ │
│   │  Enemies Defeated: 842                                  │ │
│   │  DigiBytes Earned: 24,500 DB                            │ │
│   │  Digimon Spawned: 23                                    │ │
│   │  Merges Performed: 15                                   │ │
│   │  Digivolutions: 18                                      │ │
│   │  Highest Stage Reached: Mega                            │ │
│   └─────────────────────────────────────────────────────────┘ │
│                                                               │
│   ┌───────────────────┐    ┌───────────────────┐              │
│   │    Try Again      │    │    Main Menu      │              │
│   └───────────────────┘    └───────────────────┘              │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### Pause Menu
```
┌───────────────────────────────────────┐
│              ⏸ PAUSED                │
├───────────────────────────────────────┤
│                                       │
│         ┌─────────────────┐           │
│         │     Resume      │           │
│         └─────────────────┘           │
│         ┌─────────────────┐           │
│         │    Settings     │           │
│         └─────────────────┘           │
│         ┌─────────────────┐           │
│         │  Restart Wave   │           │
│         └─────────────────┘           │
│         ┌─────────────────┐           │
│         │    Save Game    │           │
│         └─────────────────┘           │
│         ┌─────────────────┐           │
│         │   Main Menu     │           │
│         └─────────────────┘           │
│         ┌─────────────────┐           │
│         │      Quit       │           │
│         └─────────────────┘           │
│                                       │
└───────────────────────────────────────┘
```

### Color Scheme & Visual Guidelines

#### Attribute Colors
| Attribute | Primary Color | Hex Code | Usage |
|-----------|---------------|----------|-------|
| Vaccine | Yellow/Gold | #FFD700 | Borders, highlights |
| Data | Blue | #4A90D9 | Borders, highlights |
| Virus | Purple | #9B59B6 | Borders, highlights |
| Free | White/Silver | #E0E0E0 | Borders, highlights |

#### UI Color Palette
| Element | Color | Hex Code |
|---------|-------|----------|
| Background (panels) | Dark blue-gray | #1A1A2E |
| Panel border | Light blue | #4A90D9 |
| Text (primary) | White | #FFFFFF |
| Text (secondary) | Light gray | #B0B0B0 |
| Button (normal) | Blue | #3498DB |
| Button (hover) | Light blue | #5DADE2 |
| Button (disabled) | Gray | #7F8C8D |
| Success/Confirm | Green | #27AE60 |
| Warning | Orange | #F39C12 |
| Error/Cancel | Red | #E74C3C |
| DB Currency | Gold | #F1C40F |
| Lives | Red | #E74C3C |

#### Font Recommendations
| Usage | Style | Size |
|-------|-------|------|
| Headers | Bold, pixel font | 24-32px |
| Body text | Regular, pixel font | 16-18px |
| Numbers/Stats | Monospace, pixel | 14-16px |
| Buttons | Bold, pixel font | 18-20px |

---

## 14. Tutorial System

### Tutorial Philosophy
- **Learn by playing**: No separate tutorial mode, integrated into Waves 1-10
- **Progressive disclosure**: Introduce one concept per wave, matched to economy
- **Non-intrusive**: Hints appear as dismissable popups, not forced stops
- **Skippable**: Returning players can disable tutorial entirely
- **Re-enableable**: Tutorial hints can be turned back on in Settings
- **Economy-aware**: Tutorials trigger when player can actually afford actions

### Skip Tutorial Option

#### First-Time Players
- Tutorial is ON by default
- No skip prompt shown on first launch

#### Returning Players (save data exists)
```
┌─────────────────────────────────────────────────────────┐
│                    NEW GAME                             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Welcome back, Tamer!                                   │
│                                                         │
│  Would you like to see tutorial hints?                  │
│                                                         │
│  ┌─────────────────────┐  ┌─────────────────────┐      │
│  │  Yes, show hints    │  │  No, skip tutorial  │      │
│  │  (Recommended for   │  │  (For experienced   │      │
│  │   new mechanics)    │  │   players)          │      │
│  └─────────────────────┘  └─────────────────────┘      │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  □ Remember my choice                           │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### Detection Logic
```gdscript
func should_show_tutorial_prompt() -> bool:
    # Show prompt if player has completed Wave 10+ before
    var save_data = SaveManager.load_progress()
    if save_data == null:
        return false  # First time player, tutorial ON by default
    return save_data.highest_wave_completed >= 10

func apply_tutorial_choice(show_tutorial: bool, remember: bool) -> void:
    Settings.set("gameplay/show_tutorial", show_tutorial)
    if remember:
        Settings.set("gameplay/tutorial_prompt_answered", true)
```

#### In-Game Toggle
Players can change this anytime via:
- **Settings → Gameplay → Show Tutorial**: ON/OFF
- Individual hints have "Don't show this again" checkbox
- "Reset Tutorial" button restores all hints

### Starting Conditions Reference
```
┌─────────────────────────────────────────┐
│  DigiBytes: 200 DB                      │
│  Lives: 20                              │
│  Towers: 1 free In-Training (random)    │
│  Grid Slots: 20 (5×4)                   │
└─────────────────────────────────────────┘
```

### Economy Milestones
```
Level In-Training to 10: 225 DB (5+10+15+20+25+30+35+40+45)
Digivolve In-Training → Rookie: 100 DB
Spawn new In-Training: 100 DB (random)

CUMULATIVE DB BY WAVE END (approx):
  Wave 1:  280 DB  ← Can spawn 1 more In-Training
  Wave 2:  365 DB  ← Can start leveling
  Wave 3:  455 DB  ← Can digivolve first tower
  Wave 4:  550 DB  ← Building second tower
  Wave 5:  650 DB  ← Leveling second tower
  Wave 6:  750 DB  ← Can have 2 Rookies
  Wave 7:  850 DB  ← Merging becomes possible
  Wave 8:  960 DB  ← Post-merge, building army
  Wave 9: 1070 DB  ← Preparing for boss
  Wave 10: 1190 DB ← Boss wave
```

### Wave-by-Wave Tutorial (Waves 1-10)

#### Wave 1: Basic Controls
```
ENEMIES: Koromon ×6 (Vaccine, Swarm)
ATTRIBUTES: All Vaccine

TRIGGER: Game start
HINT 1: "Welcome, Tamer! Click on your Digimon to see its stats."
        [Arrow pointing to starter tower]

TRIGGER: First tower selected
HINT 2: "This is your In-Training Digimon. It attacks enemies automatically."
        [Highlight stats panel: DMG, SPD, RNG]

TRIGGER: First enemy appears
HINT 3: "Enemies follow the path to your base. Don't let them through!"
        [Arrow pointing to path and lives counter showing 20]

CONCEPTS: Tower selection, stats panel, enemy path, lives system
```

#### Wave 2: Currency & Spawning
```
ENEMIES: Tsunomon ×4 (Data), Tokomon ×3 (Vaccine) - All Swarm
ATTRIBUTES: Mixed Data/Vaccine (no combat advantage yet)

TRIGGER: Wave 1 complete, DB counter updates
HINT 1: "You earned DigiBytes (DB)! Spend them to grow your army."
        [Highlight DB counter: ~280 DB]

TRIGGER: Player has 100+ DB
HINT 2: "Open the Spawn Menu to add more Digimon to your team."
        [Highlight spawn button]

TRIGGER: Spawn menu opened
HINT 3: "In-Training costs 100 DB. You can pick random or choose an attribute."
        [Show: Random 100 DB, Specific 150 DB, FREE 200 DB]

TRIGGER: Tower placed on grid
HINT 4: "Great! More towers = more firepower. Fill the grid strategically!"
        [Highlight empty grid slots]

CONCEPTS: Currency earned per wave, spawn menu, spawn costs, grid placement
EXPECTED ACTION: Player spawns 1-2 In-Training towers
```

#### Wave 3: Attributes & Leveling
```
ENEMIES: Pagumon ×6 (Virus, Swarm), Agumon ×2 (Vaccine, Standard)
ATTRIBUTES: First Virus enemies! Vaccine towers deal 1.5× to them.

TRIGGER: Wave 2 complete
HINT 1: "Notice the enemy attributes! Your Vaccine Digimon deal bonus damage to Virus."
        [Show attribute triangle: Vaccine → Virus → Data → Vaccine]

TRIGGER: Virus enemy (Pagumon) takes damage from Vaccine tower
HINT 2: "1.5× damage! Attributes give a big advantage in combat."
        [Floating "Super Effective!" indicator]

TRIGGER: Player has unleveled tower
HINT 3: "Level up your Digimon! Select a tower and click Level Up."
        [Highlight level up button]

TRIGGER: First level up
HINT 4: "Cost: 5 DB × current level. Each level adds +2% damage and +1% speed."
        [Show level cost: Lv1→2 = 5 DB, Lv5→6 = 25 DB]

CONCEPTS: Attribute triangle, damage multipliers, leveling system, level costs
EXPECTED ACTION: Player starts leveling their starter toward Lv 10
```

#### Wave 4: Progressing Toward Digivolution
```
ENEMIES: Gigimon ×6 (Virus, Standard), Gabumon ×3 (Data, Standard)
ATTRIBUTES: Virus and Data mix - encourages attribute variety

TRIGGER: Wave 3 complete
HINT 1: "Keep leveling! In-Training Digimon can digivolve at Level 10."
        [Show progress bar to Lv 10]

TRIGGER: Any tower reaches Lv 5+
HINT 2: "Halfway there! Digivolution transforms your Digimon into a stronger form."
        [Preview evolution: Koromon → Agumon silhouette]

TRIGGER: Player's DB drops below 50
HINT 3: "Running low on DB? Focus on leveling your best towers first."
        [Highlight highest level tower]

CONCEPTS: Digivolution goal (Lv 10), resource management
EXPECTED ACTION: Player continues leveling, possibly spawns another In-Training
```

#### Wave 5: First Digivolution
```
ENEMIES: Mixed In-Training ×5, Rookie ×5 (Agumon, Gabumon, Goblimon)
ATTRIBUTES: Mixed Vaccine/Data/Virus

TRIGGER: Any tower reaches Lv 10 (max for In-Training)
HINT 1: "MAX LEVEL! Your Digimon is ready to digivolve!"
        [Glowing effect on tower, Digivolve button highlighted]

TRIGGER: Digivolve button clicked
HINT 2: "Choose an evolution! Cost: 100 DB. Your Digimon will become a Rookie."
        [Show evolution options based on In-Training type]

TRIGGER: Digivolution complete
HINT 3: "Congratulations! Rookies are much stronger and can now MERGE with others."
        [Show new stats comparison: Before/After]

TRIGGER: Player hasn't digivolved by wave end
HINT 4: "Tip: Digivolve before enemies get stronger! Rookies handle Rookie enemies better."

CONCEPTS: Digivolution trigger (max level), evolution choices, Rookie stage
EXPECTED ACTION: Player digivolves their first In-Training into a Rookie
```

#### Wave 6: Building Your Army
```
ENEMIES: Agumon ×4 (Vaccine), Gabumon ×3 (Data), Goblimon ×3 (Virus) - All Standard
ATTRIBUTES: All three main attributes represented

TRIGGER: Wave 5 complete
HINT 1: "Full Rookie wave incoming! Your Rookie tower will shine here."
        [Highlight player's Rookie if they have one]

TRIGGER: Player has only 1 Rookie
HINT 2: "Spawn and raise more Digimon! You'll need multiple Rookies soon."
        [Highlight spawn button]

TRIGGER: Player has mix of In-Training and Rookie
HINT 3: "Balance your army: Level up In-Training, but keep your Rookie in a good position."

CONCEPTS: Army composition, positional strategy
EXPECTED ACTION: Player works toward having 2 Rookies (for upcoming merge tutorial)
```

#### Wave 7: Speedster Introduction
```
ENEMIES: Elecmon ×6 (Data, Standard), Impmon ×2 (Virus, Speedster), Gazimon ×3 (Virus, Swarm)
ATTRIBUTES: Mostly Virus - Data towers advantaged
NEW TYPE: Speedster (Impmon) - 2× speed, rushes through!

TRIGGER: First Speedster (Impmon) spawns
HINT 1: "SPEEDSTER incoming! These enemies move at double speed!"
        [Impmon highlighted with speed lines, "FAST" indicator]

TRIGGER: Speedster passes a tower quickly
HINT 2: "Slow and Freeze effects help catch Speedsters. Check tower abilities!"
        [Show which towers have Slow/Freeze in their effects]

TRIGGER: Speedster reaches base (if it happens)
HINT 3: "Speedsters can slip through! Position high-damage towers early in the path."

CONCEPTS: Speedster enemy type, counters (Slow, Freeze, positioning)
EXPECTED ACTION: Player learns to prioritize fast enemies
```

#### Wave 8: Flying & Tank Introduction
```
ENEMIES: Mixed ×8 (Standard), Patamon ×2 (Vaccine, Flying), Gotsumon ×2 (Data, Tank)
ATTRIBUTES: Mixed
NEW TYPES: Flying (Patamon) - aerial, Tank (Gotsumon) - high HP/armor

TRIGGER: First Flying enemy (Patamon) spawns
HINT 1: "FLYING enemy! Patamon ignores ground-based attacks."
        [Wing icon on Patamon, show which towers can hit air]

TRIGGER: First Tank enemy (Gotsumon) spawns
HINT 2: "TANK enemy! Gotsumon has high HP and 40% armor. Use Armor Break!"
        [Shield icon on Gotsumon, armor bar visible]

TRIGGER: Tower with Armor Break hits Gotsumon
HINT 3: "Armor Break reduces enemy defense. Great against Tanks!"
        [Show armor reduction effect]

CONCEPTS: Flying enemies (targeting), Tank enemies (armor), counter-strategies
EXPECTED ACTION: Player notes tower capabilities for future composition planning
```

#### Wave 9: Merge Preparation
```
ENEMIES: Varied Rookies ×14 (all types mixed)
ATTRIBUTES: Heavy mix - tests player's attribute coverage

TRIGGER: Wave 8 complete, player has 2+ Rookie Digimon
HINT 1: "You have multiple Rookies! Next wave has a BOSS. Time to learn about MERGING."
        [Highlight merge button or drag indicator]

TRIGGER: Player has 2 Rookies of same attribute
HINT 2: "MERGE: Drag one Rookie onto another of the SAME ATTRIBUTE to combine them!"
        [Show valid merge pairs glowing]

TRIGGER: Merge menu opened
HINT 3: "Merging sacrifices one Digimon. The survivor gains +1 DP (Digivolution Points)."
        [Explain DP: "DP unlocks better evolution paths!"]

TRIGGER: Player doesn't have matching attributes
HINT 4: "No matching attributes? Spawn with 'Specific Attribute' or use FREE attribute (merges with any)."

CONCEPTS: Merge requirements (same stage + same attribute), DP gained
EXPECTED ACTION: Player merges if possible, or understands for future
```

#### Wave 10: Mini-Boss & DP System
```
ENEMIES: 12 Mixed Rookies + MINI-BOSS: Greymon (Champion, 500 HP)
BOSS: Greymon - Nova Blast (AoE attack)

TRIGGER: Wave 9 complete
HINT 1: "BOSS WAVE! Greymon is a Champion-stage enemy with 500 HP and a special attack."
        [Boss health bar preview, ability icon]

TRIGGER: Boss spawns
HINT 2: "Focus fire on the boss! It deals AoE damage - spread your towers if needed."
        [Greymon highlighted, path shown]

TRIGGER: After merge (if done) or wave complete
HINT 3: "DP unlocks evolution paths! Higher DP = rarer evolutions. Check the Encyclopedia!"
        [Show Encyclopedia button, preview DP-gated evolutions]

TRIGGER: Wave 10 complete (first boss defeated)
HINT 4: "Great work! Remember: Your ORIGIN limits max evolution stage.
        In-Training origin → Champion max. Spawn Rookie/Champion origin to reach Mega!"
        [Brief Origin system explanation]

CONCEPTS: Boss mechanics, DP evolution paths, Origin system introduction
EXPECTED ACTION: Player defeats first boss, understands DP/Origin basics
```

### Post-Tutorial Enemy Type Hints (Wave 11+)

Additional hints trigger when new enemy types first appear:

| Wave | Enemy Type | First Appearance | Hint |
|------|------------|------------------|------|
| 11 | Tank (heavy) | Guilmon, Gotsumon ×4+ | "Heavy Tank wave! Stack Armor Break effects or use %-based damage." |
| 13 | Flying (swarm) | Patamon, Biyomon ×4+ | "Flying swarm! Make sure you have enough anti-air coverage." |
| 15 | Regen | Floramon | "Regenerating enemy! It heals 2% HP/sec. Burst it down or use Poison!" |
| 26 | Swarm (Champion) | Bakemon ×10 | "Massive swarm! AoE attacks like Greymon's fire breath are perfect here." |
| 33 | Shielded | Centarumon | "Shielded enemy! 60% armor - Armor Break is almost required." |
| 46 | Splitter | Mamemon | "Splitter enemy! Kills split into 2 smaller copies. Sustained DPS wins." |
| 51 | Modifier: Enraged | Red glow enemies | "Enraged modifier! +50% speed, +25% damage. Prioritize these threats!" |
| 52 | Modifier: Armored | Metal sheen enemies | "Armored modifier! +30% armor on top of base stats." |
| 53 | Modifier: Hasty | Blur trail enemies | "Hasty modifier! Double speed but less HP. Like super-Speedsters!" |
| 54 | Modifier: Vampiric | Purple aura enemies | "Vampiric modifier! Heals 10% of damage dealt. Kill fast!" |
| 55 | Modifier: Giant | Large sprite enemies | "Giant modifier! +200% HP, bigger target. Focus fire!" |

### Tutorial Summary Table

| Wave | Main Concepts | Enemy Types | Key Triggers |
|------|---------------|-------------|--------------|
| 1 | Controls, selection, path, lives | Swarm (Vaccine) | Game start, first select, first enemy |
| 2 | Currency, spawning, grid | Swarm (Data/Vaccine) | Wave complete, 100+ DB, spawn menu |
| 3 | Attributes, leveling | Swarm + Standard (Virus intro) | Virus enemy, first level up |
| 4 | Digivolution progress | Standard (Virus/Data) | Lv 5+, resource management |
| 5 | First digivolution | Mixed In-Training/Rookie | Lv 10 reached, digivolve complete |
| 6 | Army building | Full Rookie (all attributes) | Army composition |
| 7 | Speedster enemies | Standard + Speedster | First Impmon spawn |
| 8 | Flying + Tank enemies | Mixed + Flying + Tank | First Patamon, first Gotsumon |
| 9 | Merge preparation | Varied Rookies | 2+ Rookies, same attribute check |
| 10 | Boss + DP/Origin | Mixed + Mini-Boss | Boss spawn, DP explanation |

### Tutorial UI Components
```
┌─────────────────────────────────────────────────────────┐
│  [!] TUTORIAL - Wave 8                            [X]  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  FLYING ENEMY: Patamon                                 │
│  ══════════════════════                                │
│                                                         │
│  Flying enemies ignore ground-based attacks!           │
│                                                         │
│  [Image: Patamon with wing icon]                       │
│                                                         │
│  YOUR TOWERS THAT CAN HIT AIR:                         │
│  ┌────────┐ ┌────────┐                                │
│  │Patamon │ │Biyomon │  (shows player's air-capable)  │
│  └────────┘ └────────┘                                │
│                                                         │
│  ┌─────────────┐  ┌─────────────────────────────────┐  │
│  │  Got it!    │  │  □ Don't show hints for Wave 8  │  │
│  └─────────────┘  └─────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘

ENEMY TYPE INDICATORS (shown on enemy sprites):
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  [wing]  │  │ [shield] │  │ [speed]  │  │ [heart]  │
│  Flying  │  │   Tank   │  │ Speedster│  │   Regen  │
└──────────┘  └──────────┘  └──────────┘  └──────────┘

ATTRIBUTE INDICATORS (colored borders):
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  YELLOW  │  │   BLUE   │  │  PURPLE  │  │  WHITE   │
│ Vaccine  │  │   Data   │  │  Virus   │  │   Free   │
└──────────┘  └──────────┘  └──────────┘  └──────────┘
```

### Tutorial Data Structure
```gdscript
class_name TutorialHint extends Resource

@export var id: String = ""  # Unique ID like "wave3_attribute"
@export var wave: int = 0  # Which wave this hint belongs to (0 = any)
@export var trigger: String = ""  # Trigger type (see below)
@export var trigger_data: Dictionary = {}  # Additional conditions
@export var title: String = ""
@export var message: String = ""
@export var image: Texture2D = null
@export var highlight_target: String = ""  # UI element path to highlight
@export var arrow_direction: String = ""  # "up", "down", "left", "right", "none"
@export var show_once: bool = true  # Only show first time

# Trigger types:
# "wave_start" - When wave begins
# "wave_complete" - When wave ends
# "tower_selected" - When player clicks a tower
# "tower_level_up" - When any tower levels up
# "tower_max_level" - When tower hits stage max level
# "tower_digivolve" - When digivolution completes
# "enemy_spawn" - When specific enemy type spawns (use trigger_data.enemy_type)
# "enemy_damaged" - When enemy takes attribute-effective damage
# "currency_threshold" - When DB reaches amount (use trigger_data.amount)
# "tower_count" - When player has X towers (use trigger_data.count, trigger_data.stage)
# "merge_available" - When player has 2+ same-stage same-attribute
# "boss_spawn" - When boss enemy spawns

class_name TutorialManager extends Node

var shown_hints: Dictionary = {}  # id -> bool
var current_wave: int = 0

func is_tutorial_enabled() -> bool:
    return Settings.get("gameplay/show_tutorial", true)

func check_trigger(trigger: String, data: Dictionary = {}) -> void:
    if not is_tutorial_enabled():
        return  # Tutorial disabled, skip all hints

    var hints = get_hints_for_trigger(trigger, data)
    for hint in hints:
        if not shown_hints.get(hint.id, false) or not hint.show_once:
            show_hint(hint)
            if hint.show_once:
                shown_hints[hint.id] = true
                save_shown_hints()

func is_tutorial_complete() -> bool:
    return current_wave > 10 or not is_tutorial_enabled()

func reset_tutorial() -> void:
    # Called from Settings → "Reset Tutorial" button
    shown_hints.clear()
    save_shown_hints()
    Settings.set("gameplay/show_tutorial", true)

func disable_hint(hint_id: String) -> void:
    # Called when user checks "Don't show this again"
    shown_hints[hint_id] = true
    save_shown_hints()

func save_shown_hints() -> void:
    SaveManager.save_tutorial_progress(shown_hints)

func load_shown_hints() -> void:
    shown_hints = SaveManager.load_tutorial_progress()
```

---

## 15. Digivolution Encyclopedia

### Overview
The Encyclopedia is an in-game reference showing all Digimon, their stats, and evolution paths with DP requirements. Accessible from main menu and pause menu.

### Encyclopedia Structure
```
ENCYCLOPEDIA
├── Browse by Stage
│   ├── In-Training (14)
│   ├── Rookie (30+)
│   ├── Champion (40+)
│   ├── Ultimate (35+)
│   ├── Mega (25+)
│   └── Ultra (10+)
├── Browse by Family
│   ├── Dragon's Roar
│   ├── Nature Spirits
│   ├── Virus Busters
│   ├── Nightmare Soldiers
│   ├── Jungle Troopers
│   ├── Deep Savers
│   ├── Wind Guardians
│   └── Metal Empire
├── Browse by Attribute
│   ├── Vaccine
│   ├── Data
│   ├── Virus
│   └── Free
├── Evolution Trees
│   └── [Visual evolution charts]
└── Search
    └── [Search by name]
```

### Digimon Entry Layout
```
┌─────────────────────────────────────────────────────────────────────┐
│  ◄ Back                         ENCYCLOPEDIA                Search ▢ │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────┐   GREYMON                                             │
│  │          │   ═══════════════════════════════════                 │
│  │  [Sprite]│   Stage: Champion (Tier 2)                            │
│  │   64x64  │   Attribute: Vaccine                                  │
│  │          │   Family: Dragon's Roar                               │
│  └──────────┘                                                        │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  STATS                                                       │    │
│  ├─────────────────────────────────────────────────────────────┤    │
│  │  Base Damage: 18      Attack Speed: 0.8/s    Range: 3.0     │    │
│  │  Effect: Burn, AoE    Chance: 25%            2x2 AoE, 3s    │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  EVOLVES FROM                              DP REQUIRED       │    │
│  ├─────────────────────────────────────────────────────────────┤    │
│  │  [Agumon] Agumon ─────────────────────────── DP 0-2         │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  EVOLVES TO                                DP REQUIRED       │    │
│  ├─────────────────────────────────────────────────────────────┤    │
│  │  [MetalGreymon] MetalGreymon ─────────────── DP 0-3         │    │
│  │  [SkullGreymon] SkullGreymon ─────────────── DP 7-9         │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  FULL EVOLUTION TREE                         [View Tree →]   │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Evolution Tree View
```
┌─────────────────────────────────────────────────────────────────────┐
│  ◄ Back                    AGUMON EVOLUTION TREE                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  IN-TRAINING        ROOKIE         CHAMPION         ULTIMATE        │
│  ───────────        ──────         ────────         ────────        │
│                                                                      │
│  ┌────────┐       ┌────────┐     ┌────────────┐   ┌──────────────┐  │
│  │Koromon │──────►│ Agumon │────►│  Greymon   │──►│ MetalGreymon │  │
│  └────────┘       └────────┘     │  (DP 0-2)  │   │   (DP 0-3)   │  │
│                        │         └────────────┘   └──────────────┘  │
│                        │                │                 │         │
│                        │                │         ┌───────┴───────┐ │
│                        │                │         ▼               ▼ │
│                        │                │   ┌──────────┐   ┌──────┐│
│                        │                │   │WarGreymon│   │Skull-││
│                        │                │   │ (DP 0-5) │   │Greymon│
│                        │                │   └──────────┘   │(7-9) ││
│                        │                │         │        └──────┘│
│                        │         ┌──────┴─────┐   │                 │
│                        │         ▼            ▼   ▼                 │
│                        │   ┌──────────┐ ┌─────────────┐            │
│                        ├──►│GeoGreymon│ │  (more...)  │            │
│                        │   │ (DP 3-4) │ └─────────────┘            │
│                        │   └──────────┘                             │
│                        │         │                                  │
│                        │         ▼                                  │
│                        │   ┌──────────┐                             │
│                        │   │RizeGreymon                             │
│                        │   │ (DP 4-6) │                             │
│                        │   └──────────┘                             │
│                        │                                            │
│                        ├──►┌──────────┐                             │
│                        │   │Tyrannomon│                             │
│                        │   │ (DP 5-6) │                             │
│                        │   └──────────┘                             │
│                        │                                            │
│                        └──►┌────────────┐                           │
│                            │DarkTyrannon│                           │
│                            │  (DP 7+)   │                           │
│                            └────────────┘                           │
│                                                                      │
│  Legend: ──► Default path   ···► Alternate path                     │
│          [DP X-Y] = Required DP range for this evolution            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### DNA Digivolution Section
```
┌─────────────────────────────────────────────────────────────────────┐
│  ◄ Back                    DNA DIGIVOLUTIONS                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  DNA Digivolution combines two specific Mega Digimon into Ultra!    │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                                                              │    │
│  │  [WarGreymon]  +  [MetalGarurumon]  =  [Omegamon]           │    │
│  │     Mega            Mega                 Ultra               │    │
│  │                                                              │    │
│  │  Both Digimon are consumed. Omegamon inherits the higher    │    │
│  │  DP and better Origin from either parent.                   │    │
│  │                                                              │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ALL DNA COMBINATIONS:                                              │
│  ─────────────────────                                              │
│                                                                      │
│  WarGreymon + MetalGarurumon ──────────────► Omegamon               │
│  BlackWarGreymon + BlackMetalGarurumon ────► Omegamon Zwart         │
│  Angewomon + LadyDevimon ──────────────────► Mastemon               │
│  Imperialdramon FM + Omegamon ─────────────► Imperialdramon PM      │
│  Gallantmon + Grani ───────────────────────► Gallantmon CM          │
│  Seraphimon + Ophanimon ───────────────────► Susanoomon             │
│  Alphamon + Ouryumon ──────────────────────► Alphamon Ouryuken      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Encyclopedia Data Integration
```gdscript
# encyclopedia_manager.gd
extends Node

var all_digimon: Dictionary = {}  # id -> DigimonData
var evolution_trees: Dictionary = {}  # family -> tree structure

func get_evolutions_from(digimon_id: String) -> Array[Dictionary]:
    # Returns array of {digimon: DigimonData, min_dp: int, max_dp: int}
    var digimon = all_digimon[digimon_id]
    var results: Array[Dictionary] = []
    for evo in digimon.evolutions:
        results.append({
            "digimon": all_digimon[evo.result_digimon],
            "min_dp": evo.min_dp,
            "max_dp": evo.max_dp,
            "is_default": evo.is_default
        })
    return results

func get_evolves_into(digimon_id: String) -> Array[Dictionary]:
    # Reverse lookup - what Digimon can evolve INTO this one?
    var results: Array[Dictionary] = []
    for id in all_digimon:
        var digimon = all_digimon[id]
        for evo in digimon.evolutions:
            if evo.result_digimon == digimon_id:
                results.append({
                    "digimon": digimon,
                    "min_dp": evo.min_dp,
                    "max_dp": evo.max_dp
                })
    return results

func search_digimon(query: String) -> Array[DigimonData]:
    var results: Array[DigimonData] = []
    var query_lower = query.to_lower()
    for id in all_digimon:
        if all_digimon[id].digimon_name.to_lower().contains(query_lower):
            results.append(all_digimon[id])
    return results
```

### Unlock System (Optional Enhancement)
```
DISCOVERY MODE:
- Digimon entries start as "???" silhouettes
- Unlocked when:
  - You spawn/evolve that Digimon (fully revealed)
  - You encounter it as an enemy (partial reveal - sprite + name only)
- Evolution paths show "???" until both ends are discovered
- Adds collectible/discovery element to gameplay

Can be toggled: Settings → Gameplay → Encyclopedia Mode → [Full / Discovery]
```

---

## 16. Asset Pipeline & Sprites

### Sprite Specifications

| Property | Value |
|----------|-------|
| Base Size | 32x32 pixels (64x64 for larger) |
| Format | PNG with transparency |
| Style | Pixel art (DS-style preferred) |

### Folder Structure
```
assets/sprites/digimon/
├── in_training/
├── rookie/
├── champion/
├── ultimate/
├── mega/
├── ultra/
└── effects/
```

---

## 17. Development Roadmap

### MVP Goal: First Playable Version

The minimum playable version where all core loops work:
- Player can spawn, level, merge, and digivolve Digimon
- Enemies spawn and walk the path
- Towers attack enemies
- Waves progress until win/lose

---

### Sprint 1: Foundation (Get Something on Screen)
```
Priority: CRITICAL - Nothing else works without this
```
- [ ] Project setup (folder structure, autoloads)
- [ ] GameManager singleton (DB, lives, wave state)
- [ ] Main menu scene (Play button only)
- [ ] Game scene with placeholder grid
- [ ] TileMap with path and tower slot visuals
- [ ] Basic camera setup

**Milestone: Can launch game and see the map**

---

### Sprint 2: Towers (Core Tower System)
```
Priority: CRITICAL - Need towers before enemies
```
- [ ] DigimonData resource structure
- [ ] Create 3-4 test Digimon resources (1 per stage: In-Training, Rookie, Champion)
- [ ] DigimonTower scene (sprite, stats display)
- [ ] TowerSlot click detection
- [ ] Basic spawn system (click slot → spawn tower)
- [ ] Tower selection (click to select, show info)
- [ ] Basic HUD (DB display, tower info panel)

**Milestone: Can spawn and select towers on the map**

---

### Sprint 3: Enemies & Combat (Make It a Game)
```
Priority: CRITICAL - Core gameplay loop
```
- [ ] Enemy scene (sprite, HP, movement)
- [ ] Path2D setup with waypoints (57 points)
- [ ] PathFollow2D enemy movement
- [ ] WaveManager (spawn enemies from data)
- [ ] Create Wave 1-5 data (simple Rookie enemies)
- [ ] Tower targeting system (find enemy in range)
- [ ] Tower attack system (deal damage)
- [ ] Enemy death (remove, grant DB)
- [ ] Enemy reaches base (lose life)
- [ ] Wave complete detection
- [ ] Lives display in HUD
- [ ] Game Over condition

**Milestone: Can play through 5 waves, win or lose**

---

### Sprint 4: Progression Systems (RPG Elements)
```
Priority: HIGH - What makes it interesting
```
- [ ] Level up system (pay DB, increase level)
- [ ] Level up button in tower info panel
- [ ] Stats scale with level (+2% DMG, +1% SPD per level)
- [ ] Max level cap per stage
- [ ] Digivolve system (at max level + pay)
- [ ] Evolution selection modal
- [ ] DP system (track on tower)
- [ ] DP affects evolution options
- [ ] Origin system (track spawn stage)
- [ ] Origin caps max reachable stage

**Milestone: Full tower progression loop works**

---

### Sprint 5: Merge System
```
Priority: HIGH - Core strategic element
```
- [ ] Drag and drop tower movement
- [ ] Merge detection (same stage + same attr)
- [ ] Merge confirmation modal
- [ ] Merge execution (sacrifice one, boost survivor)
- [ ] DP gain on merge (+1)
- [ ] Origin inheritance (keep better)
- [ ] FREE attribute merge compatibility

**Milestone: Can merge towers to gain DP**

---

### Sprint 6: Spawn Menu & Economy
```
Priority: HIGH - Player agency
```
- [ ] Full spawn menu UI (stage, type, attribute)
- [ ] Random/Specific/FREE pricing
- [ ] Spawn cost calculation
- [ ] Drag-to-spawn from menu
- [ ] Sell system (50% refund)
- [ ] Sell confirmation modal
- [ ] Wave rewards (DB per kill, wave complete bonus)

**Milestone: Full economy loop works**

---

### Sprint 7: Combat Polish
```
Priority: MEDIUM - Makes combat feel good
```
- [ ] Attribute damage multipliers (triangle)
- [ ] Projectile system (visual attacks)
- [ ] Status effects (Burn, Freeze, Slow, etc.)
- [ ] Targeting priority system (First, Strongest, etc.)
- [ ] Targeting cycle button
- [ ] Enemy types (Swarm, Tank, Speedster, Flying)
- [ ] Enemy health bars
- [ ] Damage numbers (floating text)

**Milestone: Combat has depth and visual feedback**

---

### Sprint 8: Full Wave Content
```
Priority: MEDIUM - Content expansion
```
- [ ] Wave 1-100 data (from ENEMY_SPAWN_DESIGN.md)
- [ ] Boss enemies (Mini-boss, Phase-boss, Final)
- [ ] Boss health bar UI
- [ ] Boss abilities (Roar, Corrupt, Shield, etc.)
- [ ] Wave preview (next wave info)
- [ ] Wave start/complete modals

**Milestone: Can play all 100 waves**

---

### Sprint 9: Digimon Content
```
Priority: MEDIUM - Full roster
```
- [ ] Load all Digimon from DIGIMON_STATS_DATABASE.md
- [ ] All evolution paths
- [ ] All In-Training starters
- [ ] Starter selection screen
- [ ] DNA Digivolution system
- [ ] Ultra tier Digimon

**Milestone: All ~150 Digimon available**

---

### Sprint 10: Menus & Save System
```
Priority: MEDIUM - Quality of life
```
- [ ] Settings menu (audio, display, gameplay)
- [ ] Pause menu
- [ ] Save/Load system
- [ ] Save slots UI
- [ ] Export/Import saves
- [ ] Main menu polish

**Milestone: Full menu system and persistence**

---

### Sprint 11: Endless Mode & Leaderboard
```
Priority: LOW - Post-game content
```
- [ ] Endless mode unlock (after Wave 100)
- [ ] Endless scaling formula
- [ ] Endless boss schedule
- [ ] Leaderboard data tracking
- [ ] Leaderboard UI

**Milestone: Endless mode complete**

---

### Sprint 12: Tutorial & Encyclopedia
```
Priority: LOW - Onboarding
```
- [ ] Tutorial hint system
- [ ] Wave 1-10 tutorial triggers
- [ ] Encyclopedia browser
- [ ] Digimon detail view
- [ ] Evolution tree visualization

**Milestone: New players can learn the game**

---

### Sprint 13: Polish & Juice
```
Priority: LOW - Feel good
```
- [ ] Placeholder → real sprites
- [ ] Attack animations
- [ ] Digivolution animation
- [ ] Death effects
- [ ] UI animations
- [ ] Sound effects
- [ ] Music tracks
- [ ] Screen shake
- [ ] Particle effects

**Milestone: Game feels polished**

---

### Sprint 14: Balance & Testing
```
Priority: LOW - Final tuning
```
- [ ] Playtest waves 1-100
- [ ] Adjust Digimon stats
- [ ] Adjust wave difficulty
- [ ] Adjust economy
- [ ] Bug fixes
- [ ] Performance optimization

**Milestone: Game is balanced and stable**

---

### Definition of "Playable" (MVP Complete)
After **Sprint 6**, the game is playable:
- ✓ Spawn Digimon (with cost options)
- ✓ Level up Digimon
- ✓ Digivolve Digimon
- ✓ Merge Digimon
- ✓ Enemies walk path
- ✓ Towers attack enemies
- ✓ Earn/spend DigiBytes
- ✓ Win or lose condition

---

## 18. Resources & References

### Project Documentation
- **[DIGIMON_STATS_DATABASE.md](./DIGIMON_STATS_DATABASE.md)** - Complete roster of ~150 Digimon with stats, effects, and evolution paths
- **[ENEMY_SPAWN_DESIGN.md](./ENEMY_SPAWN_DESIGN.md)** - Detailed wave-by-wave enemy spawn design for 100 waves + endless mode

### Sprite Resources
- [The Spriters Resource](https://www.spriters-resource.com/ds_dsi/dgmnworldds/)
- [With the Will Forums](https://withthewill.net/threads/full-color-digimon-dot-sprites.25843/)

### Audio Resources (Free)
| Site | Type | License |
|------|------|---------|
| [OpenGameArt.org](https://opengameart.org) | SFX + Music | Various (CC0, CC-BY) |
| [Freesound.org](https://freesound.org) | SFX | CC licenses |
| [Kenney.nl](https://kenney.nl) | SFX packs | CC0 (Public Domain) |
| [ZapSplat](https://zapsplat.com) | SFX | Free with attribution |
| [Pixabay](https://pixabay.com/sound-effects/) | SFX + Music | Royalty-free |
| [Free Music Archive](https://freemusicarchive.org) | Music | Various CC |
| [Incompetech](https://incompetech.com) | Music (Kevin MacLeod) | CC-BY |

### Audio Resources (Paid/Premium)
| Site | Type | Notes |
|------|------|-------|
| [Epidemic Sound](https://epidemicsound.com) | Music + SFX | Subscription |
| [Artlist](https://artlist.io) | Music | Subscription |
| [Soundsnap](https://soundsnap.com) | SFX | Subscription |
| [itch.io](https://itch.io/game-assets/tag-sound-effects) | SFX packs | Various prices |

### Visual Effects Resources
| Site | Type | License |
|------|------|---------|
| [OpenGameArt.org](https://opengameart.org) | Sprites, VFX | Various CC |
| [itch.io/game-assets](https://itch.io/game-assets) | Sprites, VFX | Various (free & paid) |
| [Kenney.nl](https://kenney.nl) | Particle effects | CC0 |
| [GameDev Market](https://gamedevmarket.net) | VFX, sprites | Paid |

### Game Mechanics Reference
- [Digimon World 2 Digivolving Guide](https://strategywiki.org/wiki/Digimon_World_2/Digivolving)

---

*Document Version: 7.0*
*Last Updated: 2026-02-04*
