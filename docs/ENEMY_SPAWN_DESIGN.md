# Enemy Spawn System Design

## Table of Contents
1. [Overview](#1-overview)
2. [Enemy Types & Behaviors](#2-enemy-types--behaviors)
3. [Enemy Digimon Roster](#3-enemy-digimon-roster)
4. [Wave Timing & Pacing](#4-wave-timing--pacing)
5. [Stat Scaling](#5-stat-scaling)
6. [Phase 1: Waves 1-20](#6-phase-1-waves-1-20)
7. [Phase 2: Waves 21-40](#7-phase-2-waves-21-40)
8. [Phase 3: Waves 41-60](#8-phase-3-waves-41-60)
9. [Phase 4: Waves 61-80](#9-phase-4-waves-61-80)
10. [Phase 5: Waves 81-100](#10-phase-5-waves-81-100)
11. [Endless Mode: Wave 101+](#11-endless-mode-wave-101)
12. [Boss Configurations](#12-boss-configurations)
13. [Spawn Formulas](#13-spawn-formulas)

---

## 1. Overview

### Design Goals
- **Early waves**: Teach mechanics, low pressure
- **Mid waves**: Challenge player's army composition
- **Late waves**: Require optimized builds and high DP Digimon
- **Variety**: Mix enemy types to prevent stale strategies
- **Pacing**: Give players time to manage towers between waves

### Wave Structure Summary
```
PHASE 1 (Waves 1-20):   In-Training + Rookie enemies
PHASE 2 (Waves 21-40):  Champion enemies
PHASE 3 (Waves 41-60):  Ultimate enemies
PHASE 4 (Waves 61-80):  Mega enemies
PHASE 5 (Waves 81-100): Mega + Ultra enemies
ENDLESS (Wave 101+):    Scaling mixed enemies
```

---

## 2. Enemy Types & Behaviors

### Type Definitions

| Type | Speed | HP | Armor | Behavior | Counter |
|------|-------|-----|-------|----------|---------|
| **Swarm** | 1.3x | 0.5x | 0% | Many weak units, tight groups | AoE attacks |
| **Standard** | 1.0x | 1.0x | 10% | Balanced, predictable | Any |
| **Tank** | 0.6x | 2.5x | 40% | Slow, absorbs damage | Armor Break, % damage |
| **Speedster** | 2.0x | 0.4x | 0% | Rushes through, hard to hit | Slow, Freeze, high DPS |
| **Flying** | 1.2x | 0.8x | 0% | Ignores ground hazards | Anti-air, ranged |
| **Regen** | 0.8x | 1.5x | 10% | Heals 2% HP/sec | Burst damage, Poison |
| **Shielded** | 0.9x | 1.0x | 60% | High armor, vulnerable to magic | Armor Break, % damage |
| **Splitter** | 1.0x | 0.8x | 0% | Splits into 2 smaller on death | Sustained DPS |

### Special Enemy Modifiers (Wave 50+)
| Modifier | Effect | Visual |
|----------|--------|--------|
| **Enraged** | +50% speed, +25% damage | Red glow |
| **Armored** | +30% armor | Metal sheen |
| **Hasty** | +100% speed, -30% HP | Blur trail |
| **Vampiric** | Heals 10% of damage dealt | Purple aura |
| **Giant** | +200% HP, +50% size, -20% speed | Larger sprite |

---

## 3. Enemy Digimon Roster

### In-Training Enemies (Waves 1-5 only)
| Digimon | Attribute | Type | Notes |
|---------|-----------|------|-------|
| Koromon | Vaccine | Swarm | Basic |
| Tsunomon | Data | Swarm | Basic |
| Tokomon | Vaccine | Swarm | Basic |
| Pagumon | Virus | Swarm | Slightly faster |
| Gigimon | Virus | Standard | Slightly tougher |

### Rookie Enemies (Waves 1-20)
| Digimon | Attribute | Type | Special |
|---------|-----------|------|---------|
| Agumon | Vaccine | Standard | None |
| Gabumon | Data | Standard | None |
| Patamon | Vaccine | Flying | Aerial |
| Guilmon | Virus | Tank | High HP |
| Impmon | Virus | Speedster | Fast |
| Goblimon | Virus | Standard | Common |
| Gazimon | Virus | Swarm | Groups |
| Elecmon | Data | Standard | None |
| Gotsumon | Data | Tank | Armored |
| Kunemon | Virus | Swarm | Poison tick |
| Biyomon | Data | Flying | Aerial |
| Tentomon | Data | Standard | None |
| Betamon | Virus | Standard | None |
| Floramon | Data | Regen | Heals |

### Champion Enemies (Waves 21-40)
| Digimon | Attribute | Type | Special |
|---------|-----------|------|---------|
| Greymon | Vaccine | Standard | Fire attack |
| Garurumon | Data | Standard | Ice slow |
| Devimon | Virus | Tank | Fear aura |
| Angemon | Vaccine | Flying | Holy |
| Ogremon | Virus | Tank | High damage |
| Tyrannomon | Data | Tank | Very tanky |
| Leomon | Vaccine | Standard | Balanced |
| Meramon | Data | Speedster | Burns nearby |
| Bakemon | Virus | Swarm | Ghost (ignores some) |
| Seadramon | Data | Standard | Slows on hit |
| Birdramon | Data | Flying | Fast flyer |
| Kuwagamon | Virus | Speedster | Armor pierce |
| Centarumon | Data | Shielded | High armor |
| Wizardmon | Data | Standard | Magic damage |
| Numemon | Virus | Swarm | Many weak |
| Monochromon | Data | Tank | Very armored |
| Airdramon | Virus | Flying | Fast |
| DarkTyrannomon | Virus | Tank | Dark aura |
| Kabuterimon | Data | Flying | Chain shock |
| Togemon | Data | Regen | Heals others |

### Ultimate Enemies (Waves 41-60)
| Digimon | Attribute | Type | Special |
|---------|-----------|------|---------|
| MetalGreymon | Vaccine | Tank | Missile AoE |
| WereGarurumon | Data | Speedster | Very fast |
| MagnaAngemon | Vaccine | Flying | Gate attack |
| Myotismon | Virus | Standard | Lifesteal |
| SkullGreymon | Virus | Tank | Berserk |
| Andromon | Vaccine | Shielded | Very armored |
| MegaKabuterimon | Data | Flying | Chain lightning |
| Garudamon | Data | Flying | Pierce attack |
| Zudomon | Vaccine | Tank | AoE stun |
| MegaSeadramon | Data | Standard | Ice attacks |
| Angewomon | Vaccine | Flying | Heals others |
| LadyDevimon | Virus | Speedster | Fear |
| Pumpkinmon | Data | Swarm | Groups |
| Mamemon | Data | Splitter | Splits into 2 |
| MetalMamemon | Data | Shielded | Armored splitter |
| BlueMeramon | Virus | Speedster | Burns |
| Megadramon | Virus | Flying | Bombing run |
| Gigadramon | Virus | Tank | Heavy bomber |
| WaruMonzaemon | Virus | Tank | Curses |
| SkullMeramon | Virus | Standard | Fire trail |

### Mega Enemies (Waves 61-80)
| Digimon | Attribute | Type | Special |
|---------|-----------|------|---------|
| WarGreymon | Vaccine | Tank | Terra Force |
| MetalGarurumon | Data | Speedster | Freeze breath |
| VenomMyotismon | Virus | Tank | Mass fear |
| Piedmon | Virus | Standard | Teleports |
| Puppetmon | Virus | Speedster | Erratic |
| MetalSeadramon | Data | Tank | Pierce |
| Machinedramon | Virus | Tank | Huge HP |
| Phoenixmon | Vaccine | Flying | Rebirth |
| HerculesKabuterimon | Vaccine | Flying | Chain 8 |
| SaberLeomon | Data | Speedster | Bleed |
| Boltmon | Data | Tank | Shock AoE |
| Diaboromon | Virus | Splitter | Splits into 4 |
| BlackWarGreymon | Virus | Tank | Dark Terra |
| GranKuwagamon | Virus | Speedster | Armor ignore |
| Daemon | Virus | Tank | Evil fire |
| Beelzemon | Virus | Speedster | Execute |
| Leviamon | Virus | Tank | Instakill chance |
| Cherubimon Evil | Virus | Tank | Mass shock |

### Ultra Enemies (Waves 81-100)
| Digimon | Attribute | Type | Special |
|---------|-----------|------|---------|
| Omegamon | Vaccine | Tank | All effects |
| Omegamon Zwart | Virus | Tank | Dark sword |
| Imperialdramon DM | Virus | Tank | Dragon form |
| Armageddemon | Virus | Tank | Massive HP |
| Millenniummon | Virus | Tank | Time stop |

---

## 4. Wave Timing & Pacing

### Between-Wave Timer
| Wave Range | Prep Time | Notes |
|------------|-----------|-------|
| 1-10 | 20 seconds | Learn mechanics |
| 11-20 | 18 seconds | Comfortable |
| 21-40 | 15 seconds | Standard |
| 41-60 | 12 seconds | Pressure |
| 61-80 | 10 seconds | High pressure |
| 81-100 | 8 seconds | Intense |
| 101+ | 6 seconds | Endurance |

### Spawn Interval (time between enemy spawns)
| Wave Range | Interval | Notes |
|------------|----------|-------|
| 1-10 | 2.0 seconds | Slow, countable |
| 11-20 | 1.8 seconds | Slightly faster |
| 21-40 | 1.5 seconds | Standard |
| 41-60 | 1.2 seconds | Quicker |
| 61-80 | 1.0 seconds | Fast |
| 81-100 | 0.8 seconds | Very fast |
| 101+ | 0.6 seconds | Overwhelming |

### Path Length
- Enemies take approximately **20-25 seconds** to walk the full path at 1.0x speed
- Speedsters (2.0x): ~10-12 seconds
- Tanks (0.6x): ~35-40 seconds

---

## 5. Stat Scaling

### Base Stats by Tier

| Tier | Base HP | Base Damage | Base Speed |
|------|---------|-------------|------------|
| In-Training | 15 | 2 | 1.0 |
| Rookie | 40 | 5 | 1.0 |
| Champion | 120 | 12 | 1.0 |
| Ultimate | 350 | 25 | 1.0 |
| Mega | 1000 | 50 | 1.0 |
| Ultra | 3000 | 100 | 1.0 |

### Within-Phase Scaling

Stats increase within each phase:

```
HP = Base HP × (1 + 0.08 × waves_into_phase)
Damage = Base Damage × (1 + 0.05 × waves_into_phase)

Example: Wave 15 (5 waves into Phase 1)
  Rookie HP = 40 × (1 + 0.08 × 5) = 40 × 1.4 = 56 HP
```

### Enemy Count Scaling

| Wave | Base Enemies | Swarm Bonus | Total (approx) |
|------|--------------|-------------|----------------|
| 1 | 6 | +0 | 6 |
| 5 | 8 | +4 | 12 |
| 10 | 10 | +6 | 16 (+ boss) |
| 20 | 14 | +8 | 22 (+ boss) |
| 30 | 16 | +10 | 26 (+ boss) |
| 50 | 20 | +15 | 35 (+ boss) |
| 70 | 24 | +18 | 42 (+ boss) |
| 100 | 30 | +25 | 55 (+ boss) |

---

## 6. Phase 1: Waves 1-20

### Wave Composition

#### Waves 1-5: Tutorial Waves
| Wave | Enemies | Composition | Featured Enemy |
|------|---------|-------------|----------------|
| 1 | 6 | 100% Swarm | Koromon ×6 |
| 2 | 7 | 100% Swarm | Tsunomon ×4, Tokomon ×3 |
| 3 | 8 | 80% Swarm, 20% Standard | Pagumon ×6, Agumon ×2 |
| 4 | 9 | 70% Swarm, 30% Standard | Gigimon ×6, Gabumon ×3 |
| 5 | 10 | 50% Swarm, 50% Standard | Mixed In-Training ×5, Rookie ×5 |

#### Waves 6-10: Rookie Introduction
| Wave | Enemies | Composition | Featured Enemy |
|------|---------|-------------|----------------|
| 6 | 10 | 100% Standard | Agumon ×4, Gabumon ×3, Goblimon ×3 |
| 7 | 11 | 80% Standard, 20% Speedster | Elecmon ×6, Impmon ×2, Gazimon ×3 |
| 8 | 12 | 70% Standard, 20% Flying, 10% Tank | Mixed ×8, Patamon ×2, Gotsumon ×2 |
| 9 | 14 | 60% Standard, 20% Swarm, 20% Mixed | Varied Rookies ×14 |
| **10** | 12 + Boss | Mixed | **Mini-Boss: Greymon** |

#### Waves 11-15: Difficulty Ramp
| Wave | Enemies | Composition | Special |
|------|---------|-------------|---------|
| 11 | 14 | 50% Standard, 30% Tank, 20% Swarm | Tanks introduced heavily |
| 12 | 15 | 40% Standard, 30% Speedster, 30% Swarm | Speed pressure |
| 13 | 16 | 50% Standard, 25% Flying, 25% Tank | Air units |
| 14 | 17 | 40% Standard, 20% each other | Mixed challenge |
| 15 | 18 | 30% Tank, 30% Speedster, 40% Standard | Pincer |

#### Waves 16-20: Phase 1 Finale
| Wave | Enemies | Composition | Special |
|------|---------|-------------|---------|
| 16 | 18 | Mixed Rookies + 2 Champions | Champion preview |
| 17 | 19 | Mixed + 3 Champions | More champions |
| 18 | 20 | 50% Rookie, 50% Champion | Half and half |
| 19 | 22 | 30% Rookie, 70% Champion | Champion heavy |
| **20** | 18 + Boss | Mixed Champions | **Phase Boss: Greymon** (Phase Boss version) |

### Phase 1 Enemy Pool
```
Primary: Agumon, Gabumon, Patamon, Goblimon, Gazimon
Tanks: Gotsumon, Guilmon
Speedsters: Impmon
Flying: Patamon, Biyomon
Swarm: Koromon, Tsunomon, Tokomon, Kunemon
```

---

## 7. Phase 2: Waves 21-40

### Wave Composition

#### Waves 21-25: Champion Introduction
| Wave | Enemies | Composition | Featured |
|------|---------|-------------|----------|
| 21 | 16 | 100% Standard Champions | Greymon ×4, Garurumon ×4, Leomon ×4, Seadramon ×4 |
| 22 | 17 | 80% Standard, 20% Tank | Add Tyrannomon ×3 |
| 23 | 18 | 70% Standard, 20% Flying, 10% Speedster | Add Birdramon ×3, Meramon ×2 |
| 24 | 19 | 60% Standard, 40% Mixed | Varied |
| 25 | 20 | 50% Standard, 30% Tank, 20% Speedster | Ogremon ×6, Kuwagamon ×4 |

#### Waves 26-30: Type Variety
| Wave | Enemies | Composition | Special |
|------|---------|-------------|---------|
| 26 | 20 | Heavy Swarm | Bakemon ×10, Numemon ×10 |
| 27 | 18 | Heavy Tank | Monochromon ×6, DarkTyrannomon ×6, Ogremon ×6 |
| 28 | 22 | Heavy Flying | Birdramon ×8, Airdramon ×8, Kabuterimon ×6 |
| 29 | 20 | Heavy Speedster | Meramon ×8, Kuwagamon ×8, Bakemon ×4 |
| **30** | 16 + Boss | Mixed | **Mini-Boss: Devimon** |

#### Waves 31-35: Mixed Pressure
| Wave | Enemies | Composition | Special |
|------|---------|-------------|---------|
| 31 | 22 | Champions + 2 Ultimate preview | WereGarurumon preview |
| 32 | 23 | Heavy Regen | Togemon ×8 + Standard ×15 |
| 33 | 24 | Heavy Shielded | Centarumon ×8, Monochromon ×8, Standard ×8 |
| 34 | 25 | Rush wave | 70% Speedster |
| 35 | 26 | Balanced hell | Equal all types |

#### Waves 36-40: Phase 2 Finale
| Wave | Enemies | Composition | Special |
|------|---------|-------------|---------|
| 36 | 24 | 50% Champion, 50% Ultimate | Ultimates arrive |
| 37 | 25 | 40% Champion, 60% Ultimate | More Ultimates |
| 38 | 26 | 30% Champion, 70% Ultimate | Ultimate heavy |
| 39 | 28 | 20% Champion, 80% Ultimate | Almost all Ultimate |
| **40** | 22 + Boss | Mixed Ultimates | **Phase Boss: Myotismon** |

### Phase 2 Enemy Pool
```
Standard: Greymon, Garurumon, Leomon, Seadramon, Wizardmon
Tanks: Tyrannomon, Ogremon, Monochromon, DarkTyrannomon, Devimon
Speedsters: Meramon, Kuwagamon
Flying: Angemon, Birdramon, Airdramon, Kabuterimon
Swarm: Bakemon, Numemon
Shielded: Centarumon
Regen: Togemon
```

---

## 8. Phase 3: Waves 41-60

### Wave Composition

#### Waves 41-45: Ultimate Introduction
| Wave | Enemies | Composition | Featured |
|------|---------|-------------|----------|
| 41 | 22 | 100% Standard | MetalGreymon ×5, Zudomon ×5, MegaSeadramon ×6, SkullMeramon ×6 |
| 42 | 23 | 80% Standard, 20% Tank | Add SkullGreymon ×4 |
| 43 | 24 | 70% Standard, 20% Flying, 10% Speedster | Add MegaKabuterimon, WereGarurumon |
| 44 | 25 | Mixed | Varied Ultimates |
| 45 | 26 | Tank heavy | Andromon ×8, SkullGreymon ×8, Mixed ×10 |

#### Waves 46-50: Special Types
| Wave | Enemies | Composition | Special |
|------|---------|-------------|---------|
| 46 | 26 | Splitter wave | Mamemon ×13 (becomes 26) |
| 47 | 24 | Flying swarm | Garudamon ×8, MegaKabuterimon ×8, Megadramon ×8 |
| 48 | 28 | Regen + Tank | Angewomon ×6 + Tanks ×22 |
| 49 | 30 | All speedsters | WereGarurumon ×10, BlueMeramon ×10, LadyDevimon ×10 |
| **50** | 25 + Boss | Mixed | **Mini-Boss: SkullGreymon** |

#### Waves 51-55: Modifiers Introduced
| Wave | Enemies | Composition | Modifier |
|------|---------|-------------|----------|
| 51 | 28 | Mixed | 20% Enraged |
| 52 | 29 | Heavy Tank | 30% Armored |
| 53 | 30 | Speedsters | 25% Hasty |
| 54 | 31 | Mixed | 20% Vampiric |
| 55 | 32 | Tanks | 15% Giant |

#### Waves 56-60: Phase 3 Finale
| Wave | Enemies | Composition | Special |
|------|---------|-------------|---------|
| 56 | 30 | 50% Ultimate, 50% Mega | Mega preview |
| 57 | 31 | 40% Ultimate, 60% Mega | More Mega |
| 58 | 32 | 30% Ultimate, 70% Mega | Mega heavy |
| 59 | 35 | Mixed with 30% modifiers | Chaos |
| **60** | 28 + Boss | Mixed Mega | **Phase Boss: VenomMyotismon** |

### Phase 3 Enemy Pool
```
Standard: MetalGreymon, MegaSeadramon, SkullMeramon, Myotismon
Tanks: SkullGreymon, Andromon, Zudomon, Gigadramon, WaruMonzaemon
Speedsters: WereGarurumon, BlueMeramon, LadyDevimon
Flying: MagnaAngemon, MegaKabuterimon, Garudamon, Megadramon
Swarm: Pumpkinmon
Splitter: Mamemon, MetalMamemon
Regen: Angewomon
```

---

## 9. Phase 4: Waves 61-80

### Wave Composition

#### Waves 61-65: Mega Introduction
| Wave | Enemies | Composition | Featured |
|------|---------|-------------|----------|
| 61 | 30 | Standard Mega | WarGreymon ×6, MetalGarurumon ×6, Mixed ×18 |
| 62 | 31 | Add Tanks | VenomMyotismon ×4, Machinedramon ×4 |
| 63 | 32 | Add Flying | Phoenixmon ×6, HerculesKabuterimon ×6 |
| 64 | 33 | Add Speedster | SaberLeomon ×6, Beelzemon ×6 |
| 65 | 35 | Balanced Mega | All types |

#### Waves 66-70: Intense Combat
| Wave | Enemies | Composition | Special |
|------|---------|-------------|---------|
| 66 | 35 | Splitter hell | Diaboromon ×9 (becomes 36) |
| 67 | 34 | All Tanks | Machinedramon ×10, Daemon ×10, Leviamon ×7, VenomMyotismon ×7 |
| 68 | 38 | Speed rush | All speedsters, 40% Hasty modifier |
| 69 | 40 | Mixed madness | Everything, 30% random modifiers |
| **70** | 35 + Boss | Mixed | **Mini-Boss: Machinedramon** |

#### Waves 71-75: Modifier Heavy
| Wave | Enemies | Composition | Modifier |
|------|---------|-------------|----------|
| 71 | 38 | Mixed | 40% Enraged |
| 72 | 39 | Tanks | 50% Armored |
| 73 | 40 | Mixed | 40% Vampiric |
| 74 | 42 | Mixed | 30% Giant |
| 75 | 44 | Mixed | 50% random modifier |

#### Waves 76-80: Phase 4 Finale
| Wave | Enemies | Composition | Special |
|------|---------|-------------|---------|
| 76 | 42 | Mega swarm | 80% Swarm type Mega |
| 77 | 44 | 70% Mega, 30% Ultra preview | Ultra arrives |
| 78 | 46 | 60% Mega, 40% Ultra | More Ultra |
| 79 | 50 | 50% Mega, 50% Ultra | Half and half |
| **80** | 40 + Boss | Mixed Ultra | **Phase Boss: Omegamon** |

### Phase 4 Enemy Pool
```
Standard: WarGreymon, MetalGarurumon, Piedmon
Tanks: VenomMyotismon, Machinedramon, Daemon, BlackWarGreymon, Leviamon, Boltmon, Cherubimon Evil
Speedsters: SaberLeomon, Beelzemon, GranKuwagamon, Puppetmon
Flying: Phoenixmon, HerculesKabuterimon
Splitter: Diaboromon (splits into 4)
```

---

## 10. Phase 5: Waves 81-100

### Wave Composition

#### Waves 81-85: Ultra Era
| Wave | Enemies | Composition | Featured |
|------|---------|-------------|----------|
| 81 | 42 | 60% Mega, 40% Ultra | Omegamon ×4, Mixed |
| 82 | 44 | 50% Mega, 50% Ultra | Omegamon Zwart ×4 |
| 83 | 46 | 40% Mega, 60% Ultra | Imperialdramon DM ×4 |
| 84 | 48 | 30% Mega, 70% Ultra | Mixed Ultra |
| 85 | 50 | 80% Ultra | Ultra dominated |

#### Waves 86-90: Peak Difficulty
| Wave | Enemies | Composition | Special |
|------|---------|-------------|---------|
| 86 | 48 | All Ultra | 100% Ultra tier |
| 87 | 50 | Ultra + 50% Enraged | Enraged Ultra |
| 88 | 52 | Ultra + 50% Armored | Armored Ultra |
| 89 | 55 | Ultra + Mixed mods | Chaos Ultra |
| **90** | 45 + Boss | Ultra | **Mini-Boss: Omegamon Zwart** |

#### Waves 91-95: Survival Mode
| Wave | Enemies | Composition | Special |
|------|---------|-------------|---------|
| 91 | 55 | Ultra swarm | Rapid spawn, lower HP each |
| 92 | 50 | Ultra Tanks | Machinedramon ×15, Armageddemon ×5, Ultra Tanks ×30 |
| 93 | 55 | Ultra Speedsters | Hasty modifier 60% |
| 94 | 60 | Mixed Ultra | 60% modifier chance |
| 95 | 65 | Everything | Complete chaos |

#### Waves 96-100: Final Stretch
| Wave | Enemies | Composition | Special |
|------|---------|-------------|---------|
| 96 | 55 | Mixed | 70% modifier |
| 97 | 58 | Mixed | 80% modifier |
| 98 | 60 | All Giant | Giant modifier on all |
| 99 | 65 | Everything | Pre-boss swarm |
| **100** | 50 + Boss | Elite | **Final Boss: Apocalymon** |

### Phase 5 Enemy Pool
```
Ultra: Omegamon, Omegamon Zwart, Imperialdramon DM, Armageddemon, Millenniummon
Mega (support): All Mega enemies with 50% stat boost
```

---

## 11. Endless Mode: Wave 101+

### Scaling Formula
```
Enemy HP = Base HP × (1.05 ^ (wave - 100))
Enemy Damage = Base Damage × (1.03 ^ (wave - 100))
Enemy Count = 50 + (wave - 100) × 2 (cap at 100)
Spawn Interval = max(0.3, 0.6 - (wave - 100) × 0.01)
```

### Composition
- Random mix of all enemy types
- 80% modifier chance
- Stacking modifiers possible (wave 150+)
- Boss every 10 waves (random Phase Boss)

### Example Waves
| Wave | Enemies | HP Multiplier | Modifiers |
|------|---------|---------------|-----------|
| 110 | 70 | 1.63x | 80% chance |
| 125 | 100 | 3.39x | 90% chance |
| 150 | 100 | 7.69x | 100% + stacking |
| 200 | 100 | 39.5x | Multi-stack |

---

## 12. Boss Configurations

### Mini-Bosses (Wave 10, 30, 50, 70, 90)

| Wave | Boss | HP | Abilities |
|------|------|-----|-----------|
| 10 | Greymon | 500 | Nova Blast (AoE) |
| 30 | Devimon | 2,000 | Death Claw (stun tower) |
| 50 | SkullGreymon | 8,000 | Ground Zero (massive AoE) |
| 70 | Machinedramon | 25,000 | Infinity Cannon (pierce) |
| 90 | Omegamon Zwart | 80,000 | Grey Sword (execute) |

### Phase Bosses (Wave 20, 40, 60, 80)

| Wave | Boss | HP | Abilities |
|------|------|-----|-----------|
| 20 | Greymon (Evolved) | 1,500 | Nova Blast, Roar (stun all 2s) |
| 40 | Myotismon | 6,000 | Crimson Lightning (lifesteal), Summon (3 Bakemon) |
| 60 | VenomMyotismon | 20,000 | Venom Infuse (poison all), Tyrant Savage (AoE), Regen |
| 80 | Omegamon | 60,000 | Transcendent Sword (execute), Grey Cannon (AoE), Shield |

### Final Boss: Apocalymon (Wave 100)

| Stat | Value |
|------|-------|
| HP | 200,000 |
| Armor | 30% |
| Speed | 0.5x |

**Abilities:**
1. **Darkness Zone** (20s CD): Disables 3 random towers for 5 seconds
2. **Gran Death Big Bang** (30s CD): Deals 50% current HP to all towers (survivable)
3. **Summon Dark Masters** (45s CD): Spawns Piedmon, Puppetmon, Machinedramon, MetalSeadramon (mini versions, 10% HP each)
4. **Total Annihilation** (90s CD / below 25% HP): Massive AoE, must kill fast or wipe

---

## 13. Spawn Formulas

### Enemy Count Formula
```gdscript
func get_enemy_count(wave: int) -> int:
    var base = 6 + (wave * 0.5)
    var swarm_bonus = 0
    if wave > 5:
        swarm_bonus = (wave - 5) * 0.3
    return int(min(base + swarm_bonus, 100))
```

### Spawn Interval Formula
```gdscript
func get_spawn_interval(wave: int) -> float:
    if wave <= 10:
        return 2.0
    elif wave <= 20:
        return 1.8
    elif wave <= 40:
        return 1.5
    elif wave <= 60:
        return 1.2
    elif wave <= 80:
        return 1.0
    elif wave <= 100:
        return 0.8
    else:
        return max(0.3, 0.6 - (wave - 100) * 0.01)
```

### Enemy Stats Formula
```gdscript
func get_enemy_stats(base_hp: int, base_dmg: int, wave: int, tier: int) -> Dictionary:
    var phase_start = [1, 21, 41, 61, 81][tier]
    var waves_into_phase = wave - phase_start

    var hp_mult = 1.0 + (0.08 * waves_into_phase)
    var dmg_mult = 1.0 + (0.05 * waves_into_phase)

    # Endless scaling
    if wave > 100:
        hp_mult *= pow(1.05, wave - 100)
        dmg_mult *= pow(1.03, wave - 100)

    return {
        "hp": int(base_hp * hp_mult),
        "damage": int(base_dmg * dmg_mult)
    }
```

### Modifier Chance Formula
```gdscript
func get_modifier_chance(wave: int) -> float:
    if wave < 50:
        return 0.0
    elif wave <= 60:
        return 0.2
    elif wave <= 80:
        return 0.4
    elif wave <= 100:
        return 0.6 + (wave - 80) * 0.02
    else:
        return min(1.0, 0.8 + (wave - 100) * 0.01)
```

---

*Document Version: 1.0*
*Last Updated: 2025-02-03*
