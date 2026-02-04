# Digimon Stats Database

## Table of Contents
1. [Stat Overview](#1-stat-overview)
2. [Level Scaling](#2-level-scaling)
3. [In-Training Tier](#3-in-training-tier)
4. [Rookie Tier](#4-rookie-tier)
5. [Champion Tier](#5-champion-tier)
6. [Ultimate Tier](#6-ultimate-tier)
7. [Mega Tier](#7-mega-tier)
8. [Ultra Tier](#8-ultra-tier)
9. [Evolution Chains](#9-evolution-chains)
10. [Status Effect Reference](#10-status-effect-reference)

---

## 1. Stat Overview

### Stat Definitions

| Stat | Description | Range |
|------|-------------|-------|
| **DMG** | Base damage per attack | 2-150 |
| **SPD** | Attacks per second | 0.4-1.5 |
| **RNG** | Attack range in tiles | 1-6 |
| **Effect** | Status effect applied | See Section 10 |
| **Chance** | Probability of effect (%) | 0-100% |
| **Priority** | Default targeting priority | See below |

### Targeting Priority System

Each tower has a **default targeting priority** that players can override.

#### Available Priorities
| Priority | Description | Best For |
|----------|-------------|----------|
| **First** | Enemy closest to base (furthest along path) | General DPS, killing before escape |
| **Last** | Enemy furthest from base (just spawned) | Early damage, softening waves |
| **Strongest** | Highest current HP | Focus fire on tanks/bosses |
| **Weakest** | Lowest current HP | Securing kills, reducing numbers |
| **Fastest** | Highest move speed | Catching speedsters |
| **Flying** | Prioritize flying enemies | Anti-air specialists |
| **Closest** | Nearest to this tower | Maximizing uptime |

#### Default Priority by Role
| Tower Role | Default Priority | Reason |
|------------|------------------|--------|
| **DPS / Artillery** | First | Kill before enemies escape |
| **Anti-Air** | Flying | Specialized role |
| **Support / Healer** | N/A | Targets friendly towers |
| **AoE / Splash** | Strongest | Maximize splash value |
| **Debuffer** | First | Apply debuffs early |
| **Assassin / Execute** | Weakest | Secure kills on low HP |
| **Slow / Control** | Fastest | Catch speedsters |

#### Default Priority by Digimon

**Anti-Air (Flying Priority):**
Patamon, Biyomon, Hawkmon, Falcomon, Angemon, Aquilamon, Birdramon, Peckmon, Gargomon, Unimon, Kiwimon, MagnaAngemon, Garudamon, Rapidmon, Crowmon, Phoenixmon, HerculesKabuterimon, UlforceVeedramon, Valkyrimon

**Control (Fastest Priority):**
Gabumon, Lopmon, Palmon, Otamamon, Gotsumon, Hagurumon, Seadramon, Clockmon, Gekomon, Garurumon, Dolphmon, MegaSeadramon, Phantomon, MetalGarurumon, Vikemon, Plesiomon

**Execute (Weakest Priority):**
MagnaAngemon, Beelzemon, Leviamon, Gallantmon CM, Imperialdramon PM, Omegamon Zwart

**AoE (Strongest Priority):**
Greymon, GeoGreymon, Ikkakumon, Zudomon, Guardromon, MetalGreymon, SkullGreymon, Megadramon, Machinedramon, WarGreymon, MegaGargomon, Daemon

**Support (Targets Allies - No Enemy Priority):**
Sunflowmon, Angewomon, Magnadramon, Lotosmon, Sakuyamon, Kentaurosmon, Mastemon

**All Others: First Priority (Default)**

### Tier Stat Ranges

| Tier | DMG Range | SPD Range | RNG Range |
|------|-----------|-----------|-----------|
| In-Training | 2-5 | 0.5-0.8 | 1.0-1.5 |
| Rookie | 5-12 | 0.8-1.3 | 1.5-3.0 |
| Champion | 12-25 | 0.5-1.3 | 2.0-4.0 |
| Ultimate | 25-50 | 0.4-1.3 | 2.5-5.0 |
| Mega | 50-100 | 0.4-1.0 | 3.0-5.5 |
| Ultra | 80-150 | 0.4-0.7 | 4.0-6.0 |

### Attack Types

| Type | Description |
|------|-------------|
| **Single** | Hits one target |
| **Pierce** | Passes through enemies, hits multiple |
| **Chain** | Jumps to nearby enemies (X targets) |
| **AoE** | Area damage (XxX tiles) |
| **Multi-hit** | Multiple projectiles per attack |
| **Splash** | Reduced damage to nearby enemies |
| **Tracking** | Projectiles follow target |

---

## 2. Level Scaling

### Stat Growth Per Level

```
Damage at Level = Base Damage × (1 + Level × 0.02)
Attack Speed at Level = Base Speed × (1 + Level × 0.01)

Example: Greymon (Base 18 DMG, 0.8 SPD) at Level 30
  Damage = 18 × (1 + 30 × 0.02) = 18 × 1.6 = 28.8
  Speed = 0.8 × (1 + 30 × 0.01) = 0.8 × 1.3 = 1.04
```

### DPS Calculation

```
DPS = (Damage × Speed) × Level Multiplier

Example: Greymon Lv 30
  DPS = 28.8 × 1.04 = 29.95 damage/second (before effects)
```

---

## 3. In-Training Tier

*Starting stage. Weak attacks. Cannot merge. All default to First priority.*

### Vaccine Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Notes |
|---------|--------|-----|-----|-----|--------|--------|----------|-------|
| Koromon | Dragon's Roar | 3 | 0.6 | 1.0 | None | - | First | Basic |
| Tokomon | Virus Busters | 4 | 0.5 | 1.0 | None | - | First | Bite attack |
| Gummymon | Virus Busters | 3 | 0.7 | 1.2 | None | - | First | Slightly ranged |
| Nyaromon | Virus Busters | 3 | 0.6 | 1.0 | None | - | First | Basic |

### Data Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Notes |
|---------|--------|-----|-----|-----|--------|--------|----------|-------|
| Tsunomon | Nature Spirits | 3 | 0.6 | 1.0 | None | - | First | Basic |
| Tanemon | Jungle Troopers | 2 | 0.7 | 1.2 | None | - | First | Weak but fast |
| Bukamon | Deep Savers | 3 | 0.6 | 1.0 | None | - | First | Basic |
| Yokomon | Wind Guardians | 3 | 0.7 | 1.3 | None | - | First | Ranged |
| Motimon | Jungle Troopers | 3 | 0.6 | 1.0 | None | - | First | Basic |
| Viximon | Nature Spirits | 3 | 0.8 | 1.5 | None | - | First | Fast, ranged |
| Kokomon | Virus Busters | 4 | 0.5 | 1.0 | None | - | First | Strong bite |

### Virus Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Notes |
|---------|--------|-----|-----|-----|--------|--------|----------|-------|
| Pagumon | Nightmare Soldiers | 3 | 0.6 | 1.0 | Poison | 5% | First | Poison bubbles |
| Gigimon | Dragon's Roar | 4 | 0.6 | 1.0 | Burn | 5% | First | Hot bite |
| Minomon | Jungle Troopers | 2 | 0.8 | 1.2 | Slow | 10% | Fastest | Sticky, slows |

### Free Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Notes |
|---------|--------|-----|-----|-----|--------|--------|----------|-------|
| DemiVeemon | Dragon's Roar | 4 | 0.6 | 1.0 | None | - | First | Strong basic |

---

## 4. Rookie Tier

*First merge-capable stage. Can participate in combat effectively.*

### Vaccine Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | Evolves To |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|------------|
| Agumon | Dragon's Roar | 8 | 1.0 | 2.0 | Burn | 15% | First | 3s, 5 dmg/tick | Greymon, GeoGreymon, Tyrannomon |
| Patamon | Virus Busters | 5 | 1.2 | 3.0 | Knockback | 100% | Flying | 0.5 tiles | Angemon, Unimon, Pegasusmon |
| Salamon | Virus Busters | 6 | 1.1 | 2.5 | Confuse | 10% | First | 2s | Gatomon, D'Arcmon |
| Terriermon | Virus Busters | 6 | 1.1 | 2.0 | None | - | First | Basic | Gargomon |
| Elecmon | Nature Spirits | 7 | 1.0 | 2.0 | Chain (2) | 100% | Strongest | 50% chain dmg | Leomon, Centalmon |
| Gomamon | Deep Savers | 5 | 1.0 | 2.0 | Summon | 100% | First | 2 blockers, 10HP each | Ikkakumon |
| Penguinmon | Deep Savers | 6 | 0.9 | 2.0 | Slow | 20% | Fastest | 2s, 20% slow | Dolphmon, Rukamon |
| Hawkmon | Wind Guardians | 6 | 1.1 | 2.5 | Pierce | 100% | Flying | Hits 2 enemies | Aquilamon, Halsemon |
| Falcomon | Wind Guardians | 7 | 1.2 | 2.5 | None | - | Flying | Fast attack | Peckmon |
| Kudamon | Virus Busters | 6 | 1.0 | 2.5 | Holy | 15% | First | +50% vs Virus | Reppamon |

### Data Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | Evolves To |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|------------|
| Gabumon | Nature Spirits | 7 | 1.0 | 2.0 | Slow | 20% | Fastest | 2s, 30% slow | Garurumon, BlackGarurumon |
| Tentomon | Jungle Troopers | 7 | 0.9 | 2.0 | Chain (2) | 100% | Strongest | 60% chain dmg | Kabuterimon, Kuwagamon |
| Palmon | Jungle Troopers | 6 | 0.8 | 2.0 | Root | 25% | Fastest | 1s | Togemon, Woodmon |
| Biyomon | Wind Guardians | 6 | 1.1 | 3.0 | Tracking | 100% | Flying | Homing projectile | Birdramon, Saberdramon |
| Renamon | Nature Spirits | 7 | 1.2 | 2.5 | Multi-hit (3) | - | First | 3 projectiles | Kyubimon |
| Lopmon | Virus Busters | 6 | 1.1 | 2.0 | Freeze | 10% | Fastest | 1s stun | Antylamon, Wendigomon |
| Armadillomon | Nature Spirits | 5 | 0.8 | 1.5 | Block | 10% | First | Blocks attack | Ankylomon |
| Floramon | Jungle Troopers | 5 | 0.9 | 2.5 | Confuse | 15% | First | 2s | Kiwimon, Sunflowmon |
| Otamamon | Deep Savers | 5 | 1.0 | 2.0 | Slow | 15% | Fastest | 2s, 25% slow | Gekomon |
| Gotsumon | Nature Spirits | 6 | 0.8 | 1.5 | Armor Break | 15% | Strongest | 3s, -20% armor | Monochromon, Icemon |
| Candlemon | Nightmare Soldiers | 7 | 0.9 | 2.0 | Burn | 20% | First | 3s, 4 dmg/tick | Wizardmon, Meramon |
| ToyAgumon | Metal Empire | 6 | 1.0 | 2.0 | None | - | First | Basic | Tankmon, Guardromon |
| Hagurumon | Metal Empire | 7 | 0.8 | 2.0 | Slow | 20% | Fastest | 3s, 30% slow | Guardromon, Mekanorimon |
| Kotemon | Nature Spirits | 8 | 0.9 | 1.5 | None | - | First | Melee focused | Dinohyumon |
| Bearmon | Nature Spirits | 7 | 0.9 | 1.5 | Stun | 10% | First | 0.5s | Grizzlymon |

### Virus Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | Evolves To |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|------------|
| Guilmon | Dragon's Roar | 9 | 0.9 | 1.5 | Armor Break | 10% | Strongest | 3s, -15% armor | Growlmon |
| DemiDevimon | Nightmare Soldiers | 6 | 1.0 | 2.0 | Confuse | 15% | First | 2s | Devimon, IceDevimon |
| Impmon | Nightmare Soldiers | 7 | 1.0 | 2.0 | Burn | 10% | First | 2s, 4 dmg/tick | Wizardmon, Bakemon |
| Wormmon | Jungle Troopers | 5 | 0.9 | 2.0 | Slow | 30% | Fastest | 3s, 40% slow | Stingmon |
| Betamon | Deep Savers | 6 | 1.0 | 2.0 | Chain (2) | 100% | Strongest | 50% chain dmg | Seadramon |
| Gazimon | Nightmare Soldiers | 6 | 1.1 | 2.0 | None | - | First | Fast | Devidramon |
| Goblimon | Nightmare Soldiers | 7 | 0.9 | 1.5 | Armor Break | 10% | Strongest | 2s, -15% armor | Ogremon |
| Kunemon | Jungle Troopers | 5 | 1.0 | 2.0 | Poison | 20% | First | 3s, 3 dmg/tick | Flymon, Kuwagamon |
| Dorumon | Dragon's Roar | 8 | 1.0 | 2.0 | None | - | First | Balanced | Dorugamon |
| SnowAgumon | Nature Spirits | 7 | 1.0 | 2.0 | Freeze | 15% | Fastest | 1s stun | Frigimon |
| BlackAgumon | Dragon's Roar | 8 | 1.0 | 2.0 | Burn | 10% | First | 2s, 4 dmg/tick | DarkTyrannomon |
| Tsukaimon | Nightmare Soldiers | 5 | 1.1 | 2.5 | Fear | 10% | First | 2s | Bakemon |

### Free Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | Evolves To |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|------------|
| Veemon | Dragon's Roar | 8 | 1.0 | 1.5 | Stun | 10% | First | 0.5s | ExVeemon, Flamedramon |
| Lucemon | Virus Busters | 10 | 0.8 | 3.0 | Holy | 25% | First | +50% vs Virus | Lucemon FM |

---

## 5. Champion Tier

*Main combat stage. Varied abilities and roles.*

### Vaccine Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req | Evolves To |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|--------|------------|
| Greymon | Dragon's Roar | 18 | 0.8 | 3.0 | Burn, AoE | 25% | Strongest | 2x2 AoE, 3s burn | 0-2 | MetalGreymon, SkullGreymon |
| GeoGreymon | Dragon's Roar | 20 | 0.7 | 2.5 | Burn | 30% | First | 4s, 6 dmg/tick | 3-4 | RizeGreymon |
| Angemon | Virus Busters | 20 | 0.7 | 3.0 | Holy | 100% | Flying | +50% vs Virus | 0-2 | MagnaAngemon, Shakkoumon |
| Gatomon | Virus Busters | 16 | 1.3 | 1.5 | Crit | 25% | Weakest | 2x damage on crit | 0-2 | Angewomon, Silphymon |
| Unimon | Virus Busters | 14 | 1.0 | 3.5 | Anti-Air | 100% | Flying | +100% vs Flying | 3-4 | - |
| Leomon | Nature Spirits | 20 | 0.9 | 2.0 | Stun | 15% | First | 1s | 0-2 | GrapLeomon, SaberLeomon |
| Centalmon | Nature Spirits | 15 | 0.8 | 3.5 | Pierce | 100% | First | Hits 3 enemies | 3-4 | - |
| Ikkakumon | Deep Savers | 16 | 0.7 | 3.0 | Splash | 100% | Strongest | 2x2 splash, 50% dmg | 0-2 | Zudomon |
| Dolphmon | Deep Savers | 14 | 1.1 | 2.5 | Slow | 25% | Fastest | 3s, 30% slow | 3-4 | Whamon |
| Aquilamon | Wind Guardians | 16 | 1.0 | 3.5 | Pierce, Flying | 100% | Flying | Hits 2, aerial | 0-2 | Silphymon |
| Gargomon | Virus Busters | 14 | 1.2 | 3.0 | Multi-hit (6) | - | Flying | 6 bullets | 0-2 | Rapidmon |
| Peckmon | Wind Guardians | 15 | 1.1 | 3.0 | Tracking, Flying | 100% | Flying | Homing | 0-2 | Crowmon |
| Reppamon | Virus Busters | 17 | 1.0 | 2.0 | None | - | First | Balanced | 0-2 | Chirinmon |
| Starmon | Metal Empire | 15 | 0.9 | 3.0 | Stun | 20% | First | 1s | 0-2 | SuperStarmon |
| Ankylomon | Nature Spirits | 18 | 0.7 | 2.0 | Stun | 30% | Strongest | 1.5s | 0-2 | Shakkoumon |

### Data Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req | Evolves To |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|--------|------------|
| Garurumon | Nature Spirits | 16 | 1.0 | 3.0 | Slow, Pierce | 30% | Fastest | Pierce 2, 3s 30% slow | 0-2 | WereGarurumon |
| Kabuterimon | Jungle Troopers | 17 | 0.8 | 2.5 | Chain (3), Stun | 15% | Strongest | 60% chain, 1s stun | 0-2 | MegaKabuterimon |
| Togemon | Jungle Troopers | 12 | 1.2 | 2.5 | Multi-hit (5) | - | First | 5 needles | 0-2 | Lillymon |
| Birdramon | Wind Guardians | 15 | 1.0 | 3.0 | Burn, Flying | 20% | Flying | 2s burn, aerial | 0-2 | Garudamon |
| Kyubimon | Nature Spirits | 16 | 1.0 | 3.0 | Multi-hit (9), Burn | 10% | First | 9 flames each | 0-2 | Taomon |
| Seadramon | Deep Savers | 15 | 0.8 | 3.5 | Slow | 30% | Fastest | 3s, 40% slow | 0-2 | MegaSeadramon |
| Wizardmon | Nightmare Soldiers | 15 | 1.0 | 3.0 | Chain (3) | 100% | Strongest | 70% chain dmg | 0-2 | Mystimon |
| Sunflowmon | Jungle Troopers | 13 | 0.9 | 3.0 | Heal | 100% | Support | +0.05 lives/s | 5+ | Lillymon |
| Gekomon | Deep Savers | 14 | 0.9 | 2.5 | Confuse | 25% | First | 3s | 3-4 | ShogunGekomon |
| Woodmon | Jungle Troopers | 16 | 0.7 | 1.5 | Root | 30% | Fastest | 2s | 3-4 | Cherrymon |
| Monochromon | Nature Spirits | 14 | 0.6 | 2.0 | Armor Break | 20% | Strongest | 4s, -25% armor | 3-4 | Vermilimon |
| Clockmon | Metal Empire | 14 | 1.0 | 2.0 | Slow | 40% | Fastest | 4s, 50% slow | 3-4 | - |
| Icemon | Nature Spirits | 16 | 0.8 | 2.5 | Freeze | 20% | Fastest | 1.5s stun | 5+ | - |
| Shellmon | Deep Savers | 14 | 0.9 | 3.0 | Knockback | 100% | First | 1 tile | 3-4 | - |
| Kiwimon | Wind Guardians | 13 | 1.0 | 3.0 | Pierce, Flying | 100% | Flying | Hits 2 | 3-4 | - |
| Dinohyumon | Nature Spirits | 19 | 0.9 | 2.0 | None | - | First | High damage | 0-2 | - |
| Grizzlymon | Nature Spirits | 17 | 0.8 | 1.5 | Stun | 20% | First | 1s | 0-2 | GrappLeomon |
| Frigimon | Nature Spirits | 14 | 0.8 | 2.5 | Freeze | 25% | Fastest | 2s stun | 0-2 | - |
| Coelamon | Deep Savers | 15 | 0.9 | 2.5 | None | - | First | Balanced | 0-2 | - |
| Antylamon (Data) | Virus Busters | 18 | 0.9 | 2.5 | Stun | 25% | First | 1.5s | 0-3 | Cherubimon (Good) |

### Virus Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req | Evolves To |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|--------|------------|
| Growlmon | Dragon's Roar | 19 | 0.8 | 2.5 | Burn | 30% | First | 3s, 6 dmg/tick | 0-2 | WarGrowlmon |
| Tyrannomon | Nature Spirits | 15 | 0.9 | 2.0 | Armor Pierce | 100% | Strongest | Ignores 50% armor | 5-6 | MasterTyrannomon |
| DarkTyrannomon | Dragon's Roar | 17 | 0.8 | 2.5 | Armor Break | 20% | Strongest | 4s, -30% armor | 7+ | MetalTyrannomon |
| Devimon | Nightmare Soldiers | 19 | 0.8 | 2.0 | Armor Break | 25% | Strongest | 4s, -30% armor | 0-2 | Myotismon, NeoDevimon |
| IceDevimon | Nightmare Soldiers | 17 | 0.9 | 2.0 | Freeze | 25% | Fastest | 2s stun | 5+ | - |
| Bakemon | Nightmare Soldiers | 14 | 1.0 | 2.0 | Fear | 25% | First | 3s | 3-4 | Phantomon |
| Ogremon | Nightmare Soldiers | 18 | 0.9 | 1.5 | Stun | 20% | First | 1s | 0-2 | - |
| Kuwagamon | Jungle Troopers | 20 | 0.9 | 1.5 | Armor Pierce | 100% | Strongest | Ignores all armor | 3-4 | Okuwamon |
| Stingmon | Jungle Troopers | 18 | 1.1 | 2.0 | Crit | 25% | Weakest | 2x on crit | 0-2 | Paildramon (DNA) |
| Meramon | Nightmare Soldiers | 16 | 1.0 | 2.0 | Burn | 35% | First | 3s, 5 dmg/tick | 0-2 | SkullMeramon |
| Devidramon | Nightmare Soldiers | 17 | 0.9 | 2.0 | Fear | 20% | First | 2s | 0-2 | - |
| Snimon | Jungle Troopers | 18 | 1.0 | 2.5 | Bleed | 20% | Weakest | 4s, 3% HP/tick | 0-2 | - |
| Flymon | Jungle Troopers | 14 | 1.1 | 2.5 | Poison, Flying | 25% | Flying | 3s, 3 dmg/tick | 3-4 | - |
| Tuskmon | Nature Spirits | 17 | 0.7 | 1.5 | Armor Break | 30% | Strongest | 4s, -25% armor | 0-2 | - |
| Dokugumon | Jungle Troopers | 15 | 0.9 | 2.5 | Poison | 35% | First | 4s, 4 dmg/tick | 0-2 | Arukenimon |
| Saberdramon | Wind Guardians | 18 | 1.1 | 2.5 | Bleed, Flying | 20% | Flying | 3s, 2% HP/tick | 3-4 | - |
| BlackGarurumon | Nature Spirits | 18 | 0.9 | 2.5 | Fear | 15% | First | 3s | 5+ | ShadowWereGarurumon |
| NeoDevimon | Nightmare Soldiers | 20 | 0.8 | 2.5 | Armor Break | 30% | Strongest | 5s, -35% armor | 5+ | - |
| Tankmon | Metal Empire | 22 | 0.5 | 4.0 | None | - | First | Long range, slow | 5+ | - |
| Guardromon | Metal Empire | 16 | 0.6 | 3.0 | AoE | 100% | Strongest | 3x3 AoE | 0-2 | Andromon |
| Mekanorimon | Metal Empire | 15 | 0.7 | 3.0 | Slow | 30% | Fastest | 3s, 35% slow | 3-4 | - |
| Dorugamon | Dragon's Roar | 18 | 0.9 | 2.5 | None | - | First | Balanced | 0-2 | DoruGreymon |
| Wendigomon | Nightmare Soldiers | 19 | 0.8 | 2.0 | Fear | 20% | First | 3s | 5+ | Antylamon (Virus) |

### Free Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req | Evolves To |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|--------|------------|
| ExVeemon | Dragon's Roar | 18 | 0.9 | 3.0 | Pierce | 100% | First | Hits 2 enemies | 0-2 | Paildramon (DNA) |
| Flamedramon | Dragon's Roar | 17 | 1.0 | 2.5 | Burn | 25% | First | 3s, 5 dmg/tick | 0-2 | - |
| Raidramon | Dragon's Roar | 16 | 1.1 | 2.5 | Chain (2) | 100% | Strongest | 60% chain | 3-4 | - |
| Shurimon | Wind Guardians | 15 | 1.2 | 3.0 | Multi-hit (4) | - | Flying | 4 shuriken | 3-4 | - |
| Digmon | Jungle Troopers | 17 | 0.8 | 2.5 | Armor Pierce | 100% | Strongest | Ignores 50% armor | 3-4 | - |
| Submarimon | Deep Savers | 15 | 0.9 | 3.0 | Slow | 25% | Fastest | 3s, 30% slow | 3-4 | - |

---

## 6. Ultimate Tier

*Powerful evolved forms. Varied specialized abilities.*

### Vaccine Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req | Evolves To |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|--------|------------|
| MetalGreymon | Dragon's Roar | 35 | 0.6 | 4.0 | Burn, Multi-hit (3) | 40% | Strongest | 3 missiles, 3s burn | 0-3 | WarGreymon |
| RizeGreymon | Dragon's Roar | 38 | 0.5 | 4.0 | Burn, Pierce | 35% | First | Pierce 3, 4s burn | 4-6 | ShineGreymon |
| MagnaAngemon | Virus Busters | 30 | 0.7 | 3.0 | Execute | 8% | Weakest | Kills if <20% HP | 0-3 | Seraphimon |
| Angewomon | Virus Busters | 32 | 0.6 | 4.5 | Heal | 100% | Support | +0.1 lives/hit | 0-3 | Ophanimon |
| Shakkoumon | Virus Busters | 28 | 0.6 | 4.0 | Holy | 100% | First | +75% vs Virus | 4-6 | - |
| Silphymon | Virus Busters | 28 | 1.0 | 3.5 | Stun, AoE | 20% | Flying | 2x2 AoE, 1s stun | 0-3 | Valkyrimon |
| Zudomon | Deep Savers | 40 | 0.5 | 2.5 | Stun, AoE | 30% | Strongest | 3x3 AoE, 1.5s stun | 0-3 | Vikemon |
| GrapLeomon | Nature Spirits | 35 | 0.9 | 2.0 | Stun | 25% | First | 1.5s | 0-3 | SaberLeomon |
| Rapidmon | Virus Busters | 30 | 1.1 | 4.5 | Multi-hit (8), Tracking | - | Flying | 8 missiles, homing | 0-3 | MegaGargomon |
| Chirinmon | Virus Busters | 32 | 0.8 | 3.5 | Holy | 100% | First | +60% vs Virus | 0-3 | Kentaurosmon |
| Andromon | Metal Empire | 38 | 0.7 | 3.0 | Pierce, Slow | 30% | Fastest | Pierce all, 3s 40% slow | 0-3 | HiAndromon |
| SuperStarmon | Metal Empire | 35 | 0.7 | 3.5 | Stun | 30% | First | 2s | 0-3 | Justimon |
| AeroVeedramon | Dragon's Roar | 36 | 0.8 | 3.5 | Pierce, Flying | 100% | Flying | Pierce 3, aerial | 0-3 | UlforceVeedramon |
| WereGarurumon (Vaccine) | Nature Spirits | 32 | 1.2 | 2.0 | Crit | 35% | Weakest | 2x on crit | 4-6 | MetalGarurumon |
| DoruGreymon | Dragon's Roar | 38 | 0.7 | 3.0 | Armor Break | 25% | Strongest | 4s, -35% armor | 0-3 | Alphamon |

### Data Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req | Evolves To |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|--------|------------|
| WereGarurumon | Nature Spirits | 30 | 1.3 | 2.0 | Crit | 30% | Weakest | 2x on crit | 0-3 | MetalGarurumon |
| MegaKabuterimon | Jungle Troopers | 38 | 0.6 | 3.0 | Chain (5), Stun | 25% | Strongest | 70% chain, 1s stun | 0-3 | HerculesKabuterimon |
| Lillymon | Jungle Troopers | 28 | 0.9 | 4.0 | Multi-shot (3) | - | First | 3 projectiles | 0-3 | Rosemon |
| Garudamon | Wind Guardians | 35 | 0.8 | 4.0 | Pierce, Flying | 100% | Flying | Pierce all, aerial | 0-3 | Phoenixmon |
| Taomon | Nature Spirits | 32 | 0.8 | 4.0 | Holy, Reflect | 100% | First | +60% vs Virus, 10% reflect | 0-3 | Sakuyamon |
| MegaSeadramon | Deep Savers | 35 | 0.7 | 4.0 | Chain (3), Slow | 40% | Fastest | 60% chain, 4s slow | 4-6 | MetalSeadramon |
| Blossomon | Jungle Troopers | 25 | 1.0 | 3.5 | Root, AoE | 30% | Fastest | 3x3 AoE, 2s root | 4-6 | - |
| ShogunGekomon | Deep Savers | 30 | 0.7 | 3.0 | Confuse, AoE | 35% | Strongest | 3x3 AoE, 3s confuse | 0-3 | - |
| Whamon | Deep Savers | 35 | 0.5 | 3.5 | Splash | 100% | Strongest | 4x4 splash, 60% dmg | 0-3 | - |
| Antylamon (Data) | Virus Busters | 35 | 0.9 | 2.5 | Stun | 40% | First | 2s | 0-3 | Cherubimon (Good) |
| Vermilimon | Nature Spirits | 38 | 0.6 | 2.5 | Burn | 35% | First | 4s, 8 dmg/tick | 4-6 | - |
| HiAndromon | Metal Empire | 40 | 0.6 | 3.5 | Pierce, Slow | 35% | Fastest | Pierce all, 4s 45% slow | 4-6 | Craniamon |
| Crowmon | Wind Guardians | 40 | 0.9 | 3.0 | Bleed, Flying | 35% | Flying | 4s, 3% HP/tick | 4-6 | Ravemon |
| Mystimon | Nightmare Soldiers | 33 | 0.9 | 3.5 | Chain (4) | 100% | Strongest | 75% chain | 0-3 | Dynasmon |

### Virus Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req | Evolves To |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|--------|------------|
| SkullGreymon | Dragon's Roar | 50 | 0.4 | 3.0 | AoE | 100% | Strongest | 4x4 AoE, random target | 7-9 | BlackWarGreymon |
| WarGrowlmon | Dragon's Roar | 38 | 0.6 | 3.5 | Burn, AoE | 35% | Strongest | 3x3 AoE, 4s burn | 0-3 | Gallantmon |
| MasterTyrannomon | Nature Spirits | 45 | 0.5 | 3.0 | None | - | Strongest | Single target nuke | 10+ | - |
| Myotismon | Nightmare Soldiers | 35 | 0.8 | 3.0 | Lifesteal | 25% | Weakest | Heals 25% of damage | 0-3 | VenomMyotismon |
| LadyDevimon | Nightmare Soldiers | 30 | 0.9 | 3.5 | Fear | 35% | First | 4s | 4-6 | Lilithmon |
| SkullSatamon | Nightmare Soldiers | 45 | 0.9 | 2.5 | Berserk | 100% | First | +50% dmg, takes 5% self | 7+ | Beelzemon |
| Phantomon | Nightmare Soldiers | 25 | 0.8 | 3.0 | Slow | 50% | Fastest | 5s, 60% slow | 10+ | - |
| Okuwamon | Jungle Troopers | 42 | 0.8 | 2.0 | Armor Break | 50% | Strongest | 5s, -50% armor | 4-6 | GrandKuwagamon |
| MarineDevimon | Deep Savers | 32 | 0.8 | 3.0 | Poison | 40% | First | 5s, 5 dmg/tick | 7+ | Leviamon |
| SkullMeramon | Nightmare Soldiers | 38 | 0.8 | 2.5 | Burn | 45% | First | 4s, 7 dmg/tick | 0-3 | Boltmon |
| Megadramon | Metal Empire | 45 | 0.5 | 4.0 | AoE | 100% | Strongest | 4x4 AoE | 4-6 | Machinedramon |
| Datamon | Metal Empire | 25 | 1.1 | 3.0 | Armor Break | 50% | Strongest | 5s, -50% armor | 7+ | - |
| Cherrymon | Jungle Troopers | 22 | 0.7 | 3.0 | Confuse | 40% | First | 4s | 7+ | Puppetmon |
| ShadowWereGarurumon | Nature Spirits | 33 | 1.2 | 2.0 | Lifesteal | 25% | Weakest | Heals 20% of damage | 7+ | CresGarurumon |
| NeoDevimon (Ult) | Nightmare Soldiers | 36 | 0.8 | 3.0 | Armor Break, Fear | 30% | Strongest | 5s armor, 2s fear | 4-6 | Daemon |
| Arukenimon | Nightmare Soldiers | 30 | 0.9 | 3.0 | Poison, Slow | 35% | Fastest | 4s poison, 3s 30% slow | 0-3 | - |
| MetalTyrannomon | Dragon's Roar | 40 | 0.6 | 3.0 | Armor Break | 35% | Strongest | 5s, -40% armor | 7+ | - |
| Antylamon (Virus) | Nightmare Soldiers | 36 | 0.8 | 2.5 | Fear | 30% | First | 3s | 5+ | Cherubimon (Evil) |
| Gigadramon | Metal Empire | 42 | 0.5 | 4.0 | AoE | 100% | Strongest | 3x3 AoE | 4-6 | Machinedramon |

### Free Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req | Evolves To |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|--------|------------|
| Paildramon | Dragon's Roar | 36 | 0.8 | 4.0 | Multi-hit (6) | - | First | 6 projectiles | DNA | Imperialdramon FM |

---

## 7. Mega Tier

*Near-peak power. Devastating abilities and effects.*

### Vaccine Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|--------|
| WarGreymon | Dragon's Roar | 70 | 0.5 | 4.0 | Burn, AoE, KB | 60% | Strongest | 5x5 AoE, 4s burn, knockback | 0-5 |
| ShineGreymon | Dragon's Roar | 65 | 0.5 | 4.5 | Blind, AoE | 100% | Strongest | 4x4 AoE, 3s blind | 6-8 |
| VictoryGreymon | Dragon's Roar | 80 | 0.6 | 3.0 | Dragon Slayer | 100% | First | +100% vs Dragon family | 9-11 |
| BlackWarGreymon | Dragon's Roar | 75 | 0.5 | 4.0 | Armor Break, AoE | 40% | Strongest | 5x5 AoE, 5s -40% armor | 12+ |
| Seraphimon | Virus Busters | 55 | 0.6 | 5.0 | Aura (Damage) | 100% | Support | Team +30% damage | 0-5 |
| Ophanimon | Virus Busters | 50 | 0.7 | 5.0 | Aura (Speed) | 100% | Support | Team +25% attack speed | 6-8 |
| Goldramon | Virus Busters | 75 | 0.5 | 4.0 | Holy, Burn | 50% | First | +100% vs Virus, 5s burn | 9+ |
| Magnadramon | Virus Busters | 60 | 0.6 | 4.5 | Heal, AoE | 100% | Support | +0.1 lives/s, +0.5/kill | 6-8 |
| Phoenixmon | Wind Guardians | 60 | 0.6 | 4.5 | Rebirth, Burn | 50% | Flying | Revives at 50% HP once, 5s burn | 0-5 |
| HerculesKabuterimon | Jungle Troopers | 70 | 0.5 | 4.0 | Chain (8), Stun | 40% | Flying | 75% chain, 1.5s stun | 0-5 |
| MegaGargomon | Virus Busters | 55 | 0.7 | 5.0 | Multi-hit (12), AoE | - | Strongest | 6x6 AoE, 12 missiles | 0-5 |
| Cherubimon (Good) | Virus Busters | 65 | 0.6 | 5.0 | Chain (10), Stun | 30% | Strongest | 80% chain, 1.5s stun | 6-8 |
| UlforceVeedramon | Dragon's Roar | 68 | 0.8 | 4.0 | Pierce, Flying | 100% | Flying | Pierce all, aerial, fast | 0-5 |
| Kentaurosmon | Virus Busters | 62 | 0.7 | 4.5 | Shield | 100% | Support | Grants 20% block to adjacent | 0-5 |
| Vikemon | Deep Savers | 60 | 0.5 | 4.5 | Freeze, AoE | 60% | Strongest | 5x5 AoE, 3s freeze | 0-5 |
| Neptunemon | Deep Savers | 75 | 0.6 | 4.0 | Pierce, Slow | 50% | Fastest | Pierce all, 4s 50% slow | 6-8 |
| Craniamon | Metal Empire | 70 | 0.6 | 3.5 | Block, Reflect | 100% | First | 40% block, 20% reflect | 6-8 |
| Justimon | Metal Empire | 72 | 0.7 | 3.0 | Stun | 35% | First | 2s | 0-5 |
| Dynasmon | Virus Busters | 70 | 0.6 | 4.0 | Pierce | 100% | First | Pierce all, +30% vs Virus | 0-5 |
| Valkyrimon | Wind Guardians | 65 | 0.8 | 4.0 | Crit, Flying | 40% | Flying | 2.5x on crit, aerial | 6-8 |

### Data Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|--------|
| MetalGarurumon | Nature Spirits | 60 | 0.6 | 4.0 | Freeze, AoE | 50% | Fastest | 4x4 AoE, 2.5s freeze | 0-5 |
| CresGarurumon | Nature Spirits | 70 | 0.7 | 3.5 | Bleed | 40% | Weakest | Cross slash, 5s 4% HP/tick | 9+ |
| SaberLeomon | Nature Spirits | 72 | 0.8 | 3.0 | Bleed | 35% | Weakest | Double hit, 4s 3% HP/tick | 6-8 |
| Rosemon | Jungle Troopers | 50 | 0.8 | 4.0 | Root, Multi-shot (5) | 40% | Fastest | 5 projectiles, 3s root | 0-5 |
| Lotosmon | Jungle Troopers | 45 | 0.7 | 5.0 | Heal, Debuff | 30% | Support | +0.1 lives/s, 30% debuffs | 6-8 |
| Sakuyamon | Nature Spirits | 58 | 0.8 | 4.5 | Aura (All), Holy | 100% | Support | Team +20% all stats, +80% vs Dark | 0-5 |
| Ravemon | Wind Guardians | 70 | 0.9 | 3.5 | Pierce, Bleed, Flying | 35% | Flying | Pierce all, 4s 3% HP/tick, aerial | 9+ |
| MetalSeadramon | Deep Savers | 65 | 0.6 | 5.0 | Pierce | 100% | First | Pierce all enemies | 0-5 |
| Plesiomon | Deep Savers | 55 | 0.7 | 4.5 | Heal, Slow | 100% | Support | +0.05 lives/s, 40% slow | 6-8 |
| Boltmon | Metal Empire | 75 | 0.5 | 3.5 | Stun, AoE | 40% | Strongest | 4x4 AoE, 2s stun | 0-5 |
| Jesmon | Metal Empire | 65 | 0.9 | 3.0 | Multi-hit (6), Debuff | 25% | First | 6 hits, 25% all debuffs | 9+ |
| Alphamon | Virus Busters | 75 | 0.6 | 4.0 | Reset | 100% | Weakest | Resets own cooldowns on kill | 9+ |
| HiAndromon | Metal Empire | 68 | 0.6 | 4.0 | Pierce, Slow | 40% | Fastest | Pierce all, 5s 50% slow | 6-8 |
| Minervamon | Virus Busters | 70 | 0.9 | 3.0 | Crit | 45% | Weakest | 2.5x on crit | 6-8 |
| Ebemon | Metal Empire | 58 | 0.8 | 4.5 | Confuse, Chain (6) | 35% | Strongest | 80% chain, 3s confuse | 6-8 |

### Virus Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|--------|
| Gallantmon | Dragon's Roar | 68 | 0.6 | 3.5 | Pierce, Stun | 30% | First | Pierce all, 1.5s stun | 0-5 |
| VenomMyotismon | Nightmare Soldiers | 65 | 0.5 | 4.0 | Fear, Poison, AoE | 50% | Strongest | Mass fear 4s, 5s poison | 0-5 |
| Beelzemon | Nightmare Soldiers | 75 | 0.7 | 4.0 | Execute | 40% | Weakest | Kills if <30% HP | 6-8 |
| Daemon | Nightmare Soldiers | 80 | 0.5 | 4.0 | Burn, AoE | 60% | Strongest | 5x5 AoE, 5s burn | 9+ |
| Lilithmon | Nightmare Soldiers | 55 | 0.8 | 4.0 | Debuff | 50% | First | Applies all debuffs | 6-8 |
| Piedmon | Nightmare Soldiers | 62 | 0.9 | 4.0 | Multi-hit (4), Fear | 25% | First | 4 swords, 3s fear | 0-5 |
| GrandKuwagamon | Jungle Troopers | 85 | 0.6 | 3.0 | Armor Ignore | 100% | Strongest | Ignores all armor | 9+ |
| Leviamon | Deep Savers | 90 | 0.4 | 3.5 | Execute | 10%/25% | Weakest | 10% kill, 25% if <25% HP | 9+ |
| Machinedramon | Metal Empire | 90 | 0.4 | 5.0 | Pierce, AoE | 100% | Strongest | Pierce all, 5x5 AoE | 0-5 |
| Puppetmon | Nightmare Soldiers | 58 | 1.0 | 4.0 | Confuse | 50% | First | 4s, erratic targeting | 6-8 |
| Cherubimon (Evil) | Nightmare Soldiers | 75 | 0.6 | 4.0 | Multi-hit (10), Fear | 30% | Strongest | 10 spears, 3s fear | 9+ |
| BlackMetalGarurumon | Nature Spirits | 65 | 0.6 | 4.0 | Freeze, Fear | 45% | Fastest | 4x4 freeze, 3s fear | 9+ |
| Diaboromon | Nightmare Soldiers | 70 | 0.7 | 4.0 | Split | 100% | First | Creates copy at 50% HP on death | 6-8 |
| Darkdramon | Metal Empire | 78 | 0.6 | 4.0 | Pierce, Armor Break | 35% | Strongest | Pierce 5, 5s -45% armor | 6-8 |
| GranDracmon | Nightmare Soldiers | 72 | 0.6 | 4.5 | Lifesteal, Fear | 35% | Weakest | 30% lifesteal, 4s fear | 9+ |
| Megidramon | Dragon's Roar | 95 | 0.4 | 3.5 | Burn, Fear | 50% | Strongest | 5s burn, 4s fear, berserk | 12+ |
| ChaosGallantmon | Dragon's Roar | 72 | 0.6 | 3.5 | Pierce, Lifesteal | 25% | Weakest | Pierce all, 20% lifesteal | 9+ |

### Free Attribute

| Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req |
|---------|--------|-----|-----|-----|--------|--------|----------|---------|--------|
| Imperialdramon FM | Dragon's Roar | 80 | 0.5 | 5.0 | Pierce, AoE | 100% | Strongest | Pierce all, 4x4 AoE | DNA |
| Imperialdramon DM | Dragon's Roar | 90 | 0.4 | 4.5 | AoE, Armor Break | 100% | Strongest | 5x5 AoE, 5s -50% armor | Mega+ |
| Susanoomon | Virus Busters | 100 | 0.5 | 5.0 | Armor Ignore, AoE | 100% | Strongest | 7x7 AoE, ignores all armor | DNA |

---

## 8. Ultra Tier

*Pinnacle of power. DNA Digivolution required.*

| Digimon | Attribute | DMG | SPD | RNG | Effect | Chance | Priority | Details | DNA Components |
|---------|-----------|-----|-----|-----|--------|--------|----------|---------|----------------|
| Omegamon | Vaccine | 100 | 0.6 | 4.0 | All Effects | 30% | Strongest | All debuffs, +50% all stats | WarGreymon + MetalGarurumon |
| Omegamon Zwart | Virus | 110 | 0.5 | 4.0 | Execute, Burn, Armor Break | 50% | Weakest | Execute <35% HP, 5s burn, -50% armor | BlackWarGreymon + BlackMetalGarurumon |
| Imperialdramon PM | Vaccine | 100 | 0.5 | 5.0 | Execute, Pierce, AoE | 50% | Weakest | 6x6 AoE, execute <40% HP, pierce all | Imperialdramon FM + Omegamon |
| Mastemon | Vaccine | 80 | 0.6 | 5.0 | Holy, Fear, Heal | 100% | Support | +100% vs Dark, mass fear, +2 lives (60s) | Angewomon + LadyDevimon |
| Gallantmon CM | Virus | 95 | 0.5 | 5.0 | Purge, Execute, AoE | 30% | Weakest | 6x6 AoE, removes buffs, execute <25% HP | Gallantmon + Grani |
| Alphamon Ouryuken | Vaccine | 110 | 0.6 | 5.0 | Reset, Execute | 50% | Weakest | Resets all cooldowns, execute <30% HP | Alphamon + Ouryumon |
| Shoutmon X7 | Free | 120 | 0.5 | 5.5 | AoE, Multi-hit (7) | 100% | Strongest | 7x7 AoE, 7 hit combo | Special Fusion |

---

## 9. Evolution Chains

### Dragon's Roar Family

```
AGUMON LINE:
Koromon → Agumon → Greymon (DP 0-2) → MetalGreymon (DP 0-3) → WarGreymon (DP 0-5)
                 → GeoGreymon (DP 3-4) → RizeGreymon (DP 4-6) → ShineGreymon (DP 6-8)
                 → Tyrannomon (DP 5-6) → MasterTyrannomon (DP 10+)
                 → DarkTyrannomon (DP 7+) → MetalTyrannomon (DP 7+)
         → SkullGreymon (DP 7-9) → BlackWarGreymon (DP 12+)

GUILMON LINE:
Gigimon → Guilmon → Growlmon (DP 0-2) → WarGrowlmon (DP 0-3) → Gallantmon (DP 0-5)
                                                              → Megidramon (DP 12+)
                                                              → ChaosGallantmon (DP 9+)

VEEMON LINE:
DemiVeemon → Veemon → ExVeemon (DP 0-2) ──┐
                    → Flamedramon (DP 0-2) │ DNA: Paildramon → Imperialdramon FM → Imperialdramon PM
Minomon → Wormmon → Stingmon (DP 0-2) ────┘
```

### Nature Spirits Family

```
GABUMON LINE:
Tsunomon → Gabumon → Garurumon (DP 0-2) → WereGarurumon (DP 0-3) → MetalGarurumon (DP 0-5)
                   → BlackGarurumon (DP 5+) → ShadowWereGarurumon (DP 7+) → CresGarurumon (DP 9+)

RENAMON LINE:
Viximon → Renamon → Kyubimon (DP 0-2) → Taomon (DP 0-3) → Sakuyamon (DP 0-5)
```

### Virus Busters Family

```
PATAMON LINE:
Tokomon → Patamon → Angemon (DP 0-2) → MagnaAngemon (DP 0-3) → Seraphimon (DP 0-5)
                  → Unimon (DP 3-4)

SALAMON LINE:
Nyaromon → Salamon → Gatomon (DP 0-2) → Angewomon (DP 0-3) → Ophanimon (DP 0-5)
                                      → Silphymon (DP 0-3) → Valkyrimon (DP 6-8)

TERRIERMON LINE:
Gummymon → Terriermon → Gargomon (DP 0-2) → Rapidmon (DP 0-3) → MegaGargomon (DP 0-5)

LOPMON LINE:
Kokomon → Lopmon → Antylamon (Data) (DP 0-3) → Cherubimon (Good) (DP 6-8)
                 → Wendigomon (DP 5+) → Antylamon (Virus) (DP 5+) → Cherubimon (Evil) (DP 9+)
```

### Nightmare Soldiers Family

```
DEMIDEVIMON LINE:
Pagumon → DemiDevimon → Devimon (DP 0-2) → Myotismon (DP 0-3) → VenomMyotismon (DP 0-5)
                      → IceDevimon (DP 5+)                    → Beelzemon (DP 6-8)
                      → Bakemon (DP 3-4) → Phantomon (DP 10+) → Daemon (DP 9+)
                                                              → Lilithmon (DP 6-8)

IMPMON LINE:
Pagumon → Impmon → Wizardmon (DP 0-2) → Mystimon (DP 0-3) → Dynasmon (DP 0-5)
                 → Bakemon (DP 3-4)
                 → Meramon (DP 0-2) → SkullMeramon (DP 0-3) → Boltmon (DP 0-5)
```

### Jungle Troopers Family

```
TENTOMON LINE:
Motimon → Tentomon → Kabuterimon (DP 0-2) → MegaKabuterimon (DP 0-3) → HerculesKabuterimon (DP 0-5)
                   → Kuwagamon (DP 3-4) → Okuwamon (DP 4-6) → GrandKuwagamon (DP 9+)

PALMON LINE:
Tanemon → Palmon → Togemon (DP 0-2) → Lillymon (DP 0-3) → Rosemon (DP 0-5)
                 → Woodmon (DP 3-4) → Cherrymon (DP 7+) → Puppetmon (DP 6-8)
                 → Sunflowmon (DP 5+) → Lillymon → Lotosmon (DP 6-8)
```

### Deep Savers Family

```
GOMAMON LINE:
Bukamon → Gomamon → Ikkakumon (DP 0-2) → Zudomon (DP 0-3) → Vikemon (DP 0-5)
                                                          → Neptunemon (DP 6-8)

BETAMON LINE:
Bukamon → Betamon → Seadramon (DP 0-2) → MegaSeadramon (DP 4-6) → MetalSeadramon (DP 0-5)
                                       → MarineDevimon (DP 7+) → Leviamon (DP 9+)
```

### Wind Guardians Family

```
BIYOMON LINE:
Yokomon → Biyomon → Birdramon (DP 0-2) → Garudamon (DP 0-3) → Phoenixmon (DP 0-5)
                  → Saberdramon (DP 3-4)

HAWKMON LINE:
Poromon → Hawkmon → Aquilamon (DP 0-2) → Silphymon (DP 0-3) → Valkyrimon (DP 6-8)
                  → Peckmon (DP 0-2) → Crowmon (DP 4-6) → Ravemon (DP 9+)
```

### Metal Empire Family

```
HAGURUMON LINE:
Kapurimon → Hagurumon → Guardromon (DP 0-2) → Andromon (DP 0-3) → HiAndromon (DP 4-6)
                      → Mekanorimon (DP 3-4)                    → Craniamon (DP 6-8)
                                            → Megadramon (DP 4-6) → Machinedramon (DP 0-5)
                                            → Gigadramon (DP 4-6) → Machinedramon
```

---

## 10. Status Effect Reference

### Damage Over Time

| Effect | Damage | Duration | Stack |
|--------|--------|----------|-------|
| Burn | 3-8 dmg/tick | 2-5s | No |
| Poison | 3-5 dmg/tick | 3-5s | Yes (3x) |
| Bleed | 2-4% HP/tick | 3-5s | Yes (3x) |

### Crowd Control

| Effect | Behavior | Duration |
|--------|----------|----------|
| Stun | Cannot move or act | 0.5-2s |
| Freeze | Stun + slow after | 1-3s stun + 2-4s slow |
| Root | Cannot move, can act | 1-3s |
| Slow | Reduced move speed | 2-5s, 20-60% slow |
| Confuse | Random movement | 2-4s |
| Fear | Runs backward | 2-4s |
| Knockback | Pushed back | Instant, 0.5-1.5 tiles |

### Debuffs

| Effect | Reduction | Duration |
|--------|-----------|----------|
| Armor Break | -15% to -50% armor | 3-5s |
| Blind | Attacks miss | 2-3s |

### Special

| Effect | Behavior | Condition |
|--------|----------|-----------|
| Execute | Instant kill | Target below X% HP |
| Lifesteal | Heal on hit | % of damage dealt |
| Pierce | Hits multiple | Passes through enemies |
| Chain | Jumps to nearby | X targets, Y% damage |
| Holy | Bonus damage | +X% vs Virus |
| Rebirth | Revive once | At X% HP |
| Reflect | Return damage | X% of damage taken |
| Block | Negate attack | X% chance |

### Support Effects (Buff Allies & Recover Lives)

*Support Digimon buff other towers or recover lives for the player.*

| Effect | Behavior | Target | Notes |
|--------|----------|--------|-------|
| **Heal (Life Recovery)** | Restore player lives | Player | Slow accumulation, caps at 20 |
| **Damage Aura** | +X% damage buff | Adjacent towers | Stacks with other auras |
| **Speed Aura** | +X% attack speed buff | Adjacent towers | Stacks with other auras |
| **All Aura** | +X% to all stats | Adjacent towers | Most powerful support |

### Life Recovery System

*Support Digimon with "Heal" restore lives lost when enemies reach the base.*

| Heal Type | Trigger | Amount | Example |
|-----------|---------|--------|---------|
| **On Hit** | Each attack | +0.1 lives | Angewomon |
| **On Kill** | Participation in kill | +0.5 lives | Magnadramon |
| **Aura** | Passive per second | +0.05-0.1 lives/s | Lotosmon, Sunflowmon |
| **Mass Heal** | Active (cooldown) | +1-2 lives | Mastemon (60s CD) |

*Life recovery is intentionally slow. Max lives = 20 (cannot exceed).*

---

*Document Version: 2.0*
*Last Updated: 2025-02-04*
