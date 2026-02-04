#!/usr/bin/env python3
"""
Digimon Resource Generator
Parses DIGIMON_STATS_DATABASE.md and generates .tres resource files for Godot.
"""

import os
import re
from dataclasses import dataclass, field
from typing import Optional
from pathlib import Path

# Mapping constants
STAGE_MAP = {
    "In-Training": 0,
    "Rookie": 1,
    "Champion": 2,
    "Ultimate": 3,
    "Mega": 4,
    "Ultra": 5
}

ATTRIBUTE_MAP = {
    "Vaccine": 0,
    "Data": 1,
    "Virus": 2,
    "Free": 3
}

FAMILY_MAP = {
    "Dragon's Roar": 0,
    "Nature Spirits": 1,
    "Virus Busters": 2,
    "Nightmare Soldiers": 3,
    "Metal Empire": 4,
    "Deep Savers": 5,
    "Wind Guardians": 6,
    "Jungle Troopers": 7,
    "Unknown": 8
}

STAGE_FOLDER_MAP = {
    0: "in_training",
    1: "rookie",
    2: "champion",
    3: "ultimate",
    4: "mega",
    5: "ultra"
}

@dataclass
class DigimonStats:
    name: str
    stage: int
    attribute: int
    family: int
    base_damage: int
    attack_speed: float
    attack_range: float
    effect_type: str = ""
    effect_chance: float = 0.0
    effect_duration: float = 0.0
    special_ability_name: str = ""
    special_ability_description: str = ""
    special_cooldown: float = 0.0
    evolutions: list = field(default_factory=list)
    evolves_from: str = ""
    dna_partner: str = ""
    dna_result: str = ""


def parse_effect(effect_str: str, chance_str: str, details_str: str = "") -> tuple:
    """Parse effect type, chance, and duration from table data."""
    if not effect_str or effect_str.lower() in ["none", "-", ""]:
        return "", 0.0, 0.0

    # Parse effect type - handle multiple effects (take first one)
    effects = effect_str.replace(",", " ").split()
    primary_effect = ""
    for e in effects:
        e_clean = e.strip().lower()
        # Skip non-effect keywords
        if e_clean not in ["pierce", "aoe", "multi-hit", "chain", "tracking", "flying", "splash", "kb"]:
            if e_clean in ["burn", "freeze", "slow", "stun", "poison", "confuse", "fear", "root",
                          "bleed", "knockback", "holy", "crit", "lifesteal", "armor break",
                          "armor pierce", "execute", "heal", "debuff", "blind", "berserk",
                          "summon", "block", "anti-air", "aura", "rebirth", "reset", "reflect",
                          "dragon slayer", "armor ignore", "shield", "purge", "split"]:
                primary_effect = e.strip()
                break
            # Check compound effects
            if e_clean == "armor":
                idx = effects.index(e) if e in effects else -1
                if idx >= 0 and idx + 1 < len(effects):
                    if effects[idx + 1].strip().lower() in ["break", "pierce", "ignore"]:
                        primary_effect = "Armor Break"
                        break

    # If no recognized effect, check the full string
    if not primary_effect:
        effect_lower = effect_str.lower()
        if "burn" in effect_lower:
            primary_effect = "Burn"
        elif "freeze" in effect_lower:
            primary_effect = "Freeze"
        elif "slow" in effect_lower:
            primary_effect = "Slow"
        elif "stun" in effect_lower:
            primary_effect = "Stun"
        elif "poison" in effect_lower:
            primary_effect = "Poison"
        elif "confuse" in effect_lower:
            primary_effect = "Confuse"
        elif "fear" in effect_lower:
            primary_effect = "Fear"
        elif "root" in effect_lower:
            primary_effect = "Root"
        elif "bleed" in effect_lower:
            primary_effect = "Bleed"
        elif "knockback" in effect_lower:
            primary_effect = "Knockback"
        elif "holy" in effect_lower:
            primary_effect = "Holy"
        elif "crit" in effect_lower:
            primary_effect = "Crit"
        elif "lifesteal" in effect_lower:
            primary_effect = "Lifesteal"
        elif "armor break" in effect_lower:
            primary_effect = "Armor Break"
        elif "armor pierce" in effect_lower or "armor ignore" in effect_lower:
            primary_effect = "Armor Pierce"
        elif "execute" in effect_lower:
            primary_effect = "Execute"
        elif "heal" in effect_lower:
            primary_effect = "Heal"
        elif "debuff" in effect_lower:
            primary_effect = "Debuff"
        elif "blind" in effect_lower:
            primary_effect = "Blind"
        elif "berserk" in effect_lower:
            primary_effect = "Berserk"
        elif "aura" in effect_lower:
            primary_effect = "Aura"
        elif "rebirth" in effect_lower:
            primary_effect = "Rebirth"
        elif "reset" in effect_lower:
            primary_effect = "Reset"
        elif "reflect" in effect_lower:
            primary_effect = "Reflect"
        elif "shield" in effect_lower:
            primary_effect = "Shield"
        elif "dragon slayer" in effect_lower:
            primary_effect = "Dragon Slayer"

    # Parse chance
    chance = 0.0
    if chance_str and chance_str != "-":
        # Handle "100%", "25%", "10%/25%", etc.
        match = re.search(r'(\d+(?:\.\d+)?)\s*%', chance_str)
        if match:
            chance = float(match.group(1)) / 100.0

    # Parse duration from details string
    duration = 0.0
    if details_str:
        # Look for patterns like "3s", "2.5s", "4s burn", etc.
        dur_match = re.search(r'(\d+(?:\.\d+)?)\s*s\b', details_str)
        if dur_match:
            duration = float(dur_match.group(1))

    return primary_effect, chance, duration


def parse_evolutions(evolves_to_str: str) -> list:
    """Parse evolution targets from table data."""
    if not evolves_to_str or evolves_to_str == "-":
        return []

    # Split by comma and clean up
    evolutions = []
    parts = evolves_to_str.split(",")
    for part in parts:
        # Remove DP requirements in parentheses, but keep DNA notation
        clean = re.sub(r'\s*\(DP.*?\)', '', part)
        clean = clean.strip()
        if clean and clean != "-":
            evolutions.append(clean)
    return evolutions


def generate_tres_content(digimon: DigimonStats) -> str:
    """Generate .tres file content for a Digimon."""
    evolutions_str = "[]"
    if digimon.evolutions:
        # Format evolutions as empty array (will link to actual resources later)
        evolutions_str = "[]"

    content = f'''[gd_resource type="Resource" script_class="DigimonData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/digimon_data.gd" id="1"]

[resource]
script = ExtResource("1")
digimon_name = "{digimon.name}"
stage = {digimon.stage}
attribute = {digimon.attribute}
family = {digimon.family}
base_damage = {digimon.base_damage}
attack_speed = {digimon.attack_speed}
attack_range = {digimon.attack_range}
effect_type = "{digimon.effect_type}"
effect_chance = {digimon.effect_chance}
effect_duration = {digimon.effect_duration}
special_ability_name = "{digimon.special_ability_name}"
special_ability_description = "{digimon.special_ability_description}"
special_cooldown = {digimon.special_cooldown}
evolutions = {evolutions_str}
evolves_from = "{digimon.evolves_from}"
dna_partner = "{digimon.dna_partner}"
dna_result = "{digimon.dna_result}"
'''
    return content


def parse_in_training_table(lines: list, attribute: str, attribute_int: int) -> list:
    """Parse In-Training tier table."""
    digimon_list = []

    for line in lines:
        if not line.strip().startswith("|"):
            continue
        if "Digimon" in line or "---" in line:
            continue

        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 8:
            continue

        # | Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Notes |
        # Offset by 1 due to leading empty split
        try:
            name = parts[1].strip()
            family_str = parts[2].strip()
            dmg = int(parts[3].strip())
            spd = float(parts[4].strip())
            rng = float(parts[5].strip())
            effect = parts[6].strip()
            chance = parts[7].strip()
            notes = parts[9].strip() if len(parts) > 9 else ""

            if not name or name.lower() == "digimon":
                continue

            family_int = FAMILY_MAP.get(family_str, 8)
            effect_type, effect_chance, effect_duration = parse_effect(effect, chance, notes)

            digimon = DigimonStats(
                name=name,
                stage=0,  # In-Training
                attribute=attribute_int,
                family=family_int,
                base_damage=dmg,
                attack_speed=spd,
                attack_range=rng,
                effect_type=effect_type,
                effect_chance=effect_chance,
                effect_duration=effect_duration
            )
            digimon_list.append(digimon)
        except (ValueError, IndexError) as e:
            print(f"Error parsing line: {line} - {e}")
            continue

    return digimon_list


def parse_rookie_table(lines: list, attribute: str, attribute_int: int) -> list:
    """Parse Rookie tier table."""
    digimon_list = []

    for line in lines:
        if not line.strip().startswith("|"):
            continue
        if "Digimon" in line or "---" in line:
            continue

        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 10:
            continue

        # | Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | Evolves To |
        try:
            name = parts[1].strip()
            family_str = parts[2].strip()
            dmg = int(parts[3].strip())
            spd = float(parts[4].strip())
            rng = float(parts[5].strip())
            effect = parts[6].strip()
            chance = parts[7].strip()
            details = parts[9].strip() if len(parts) > 9 else ""
            evolves_to = parts[10].strip() if len(parts) > 10 else ""

            if not name or name.lower() == "digimon":
                continue

            family_int = FAMILY_MAP.get(family_str, 8)
            effect_type, effect_chance, effect_duration = parse_effect(effect, chance, details)
            evolutions = parse_evolutions(evolves_to)

            digimon = DigimonStats(
                name=name,
                stage=1,  # Rookie
                attribute=attribute_int,
                family=family_int,
                base_damage=dmg,
                attack_speed=spd,
                attack_range=rng,
                effect_type=effect_type,
                effect_chance=effect_chance,
                effect_duration=effect_duration,
                evolutions=evolutions
            )
            digimon_list.append(digimon)
        except (ValueError, IndexError) as e:
            print(f"Error parsing line: {line} - {e}")
            continue

    return digimon_list


def parse_champion_ultimate_table(lines: list, attribute: str, attribute_int: int, stage: int) -> list:
    """Parse Champion or Ultimate tier table."""
    digimon_list = []

    for line in lines:
        if not line.strip().startswith("|"):
            continue
        if "Digimon" in line or "---" in line:
            continue

        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 11:
            continue

        # | Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req | Evolves To |
        try:
            name = parts[1].strip()
            family_str = parts[2].strip()
            dmg = int(parts[3].strip())
            spd = float(parts[4].strip())
            rng = float(parts[5].strip())
            effect = parts[6].strip()
            chance = parts[7].strip()
            details = parts[9].strip() if len(parts) > 9 else ""
            evolves_to = parts[11].strip() if len(parts) > 11 else ""

            if not name or name.lower() == "digimon":
                continue

            family_int = FAMILY_MAP.get(family_str, 8)
            effect_type, effect_chance, effect_duration = parse_effect(effect, chance, details)
            evolutions = parse_evolutions(evolves_to)

            digimon = DigimonStats(
                name=name,
                stage=stage,
                attribute=attribute_int,
                family=family_int,
                base_damage=dmg,
                attack_speed=spd,
                attack_range=rng,
                effect_type=effect_type,
                effect_chance=effect_chance,
                effect_duration=effect_duration,
                evolutions=evolutions
            )
            digimon_list.append(digimon)
        except (ValueError, IndexError) as e:
            print(f"Error parsing line: {line} - {e}")
            continue

    return digimon_list


def parse_mega_table(lines: list, attribute: str, attribute_int: int) -> list:
    """Parse Mega tier table (no Evolves To column)."""
    digimon_list = []

    for line in lines:
        if not line.strip().startswith("|"):
            continue
        if "Digimon" in line or "---" in line:
            continue

        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 10:
            continue

        # | Digimon | Family | DMG | SPD | RNG | Effect | Chance | Priority | Details | DP Req |
        try:
            name = parts[1].strip()
            family_str = parts[2].strip()
            dmg = int(parts[3].strip())
            spd = float(parts[4].strip())
            rng = float(parts[5].strip())
            effect = parts[6].strip()
            chance = parts[7].strip()
            details = parts[9].strip() if len(parts) > 9 else ""

            if not name or name.lower() == "digimon":
                continue

            family_int = FAMILY_MAP.get(family_str, 8)
            effect_type, effect_chance, effect_duration = parse_effect(effect, chance, details)

            digimon = DigimonStats(
                name=name,
                stage=4,  # Mega
                attribute=attribute_int,
                family=family_int,
                base_damage=dmg,
                attack_speed=spd,
                attack_range=rng,
                effect_type=effect_type,
                effect_chance=effect_chance,
                effect_duration=effect_duration
            )
            digimon_list.append(digimon)
        except (ValueError, IndexError) as e:
            print(f"Error parsing line: {line} - {e}")
            continue

    return digimon_list


def parse_ultra_table(lines: list) -> list:
    """Parse Ultra tier table."""
    digimon_list = []

    for line in lines:
        if not line.strip().startswith("|"):
            continue
        if "Digimon" in line or "---" in line:
            continue

        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 10:
            continue

        # | Digimon | Attribute | DMG | SPD | RNG | Effect | Chance | Priority | Details | DNA Components |
        try:
            name = parts[1].strip()
            attr_str = parts[2].strip()
            dmg = int(parts[3].strip())
            spd = float(parts[4].strip())
            rng = float(parts[5].strip())
            effect = parts[6].strip()
            chance = parts[7].strip()
            details = parts[9].strip() if len(parts) > 9 else ""
            dna_components = parts[10].strip() if len(parts) > 10 else ""

            if not name or name.lower() == "digimon":
                continue

            attribute_int = ATTRIBUTE_MAP.get(attr_str, 3)
            effect_type, effect_chance, effect_duration = parse_effect(effect, chance, details)

            # Parse DNA components
            dna_partner = ""
            if dna_components and "+" in dna_components:
                dna_parts = dna_components.split("+")
                if len(dna_parts) >= 2:
                    dna_partner = dna_parts[1].strip()

            digimon = DigimonStats(
                name=name,
                stage=5,  # Ultra
                attribute=attribute_int,
                family=2,  # Most Ultra are Virus Busters, but varies
                base_damage=dmg,
                attack_speed=spd,
                attack_range=rng,
                effect_type=effect_type,
                effect_chance=effect_chance,
                effect_duration=effect_duration,
                dna_partner=dna_partner
            )
            digimon_list.append(digimon)
        except (ValueError, IndexError) as e:
            print(f"Error parsing line: {line} - {e}")
            continue

    return digimon_list


def parse_database(filepath: str) -> list:
    """Parse the entire database file and return list of DigimonStats."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    all_digimon = []
    lines = content.split('\n')

    # State tracking
    current_tier = None
    current_attribute = None
    table_lines = []
    in_table = False

    for i, line in enumerate(lines):
        # Detect tier sections
        if "## 3. In-Training Tier" in line:
            current_tier = "In-Training"
            continue
        elif "## 4. Rookie Tier" in line:
            current_tier = "Rookie"
            continue
        elif "## 5. Champion Tier" in line:
            current_tier = "Champion"
            continue
        elif "## 6. Ultimate Tier" in line:
            current_tier = "Ultimate"
            continue
        elif "## 7. Mega Tier" in line:
            current_tier = "Mega"
            continue
        elif "## 8. Ultra Tier" in line:
            current_tier = "Ultra"
            continue
        elif line.startswith("## 9.") or line.startswith("## 10."):
            current_tier = None
            continue

        # Detect attribute subsections
        if "### Vaccine Attribute" in line:
            # Process previous table if any
            if table_lines and current_tier and current_attribute:
                all_digimon.extend(process_table(table_lines, current_tier, current_attribute))
            current_attribute = "Vaccine"
            table_lines = []
            in_table = False
            continue
        elif "### Data Attribute" in line:
            if table_lines and current_tier and current_attribute:
                all_digimon.extend(process_table(table_lines, current_tier, current_attribute))
            current_attribute = "Data"
            table_lines = []
            in_table = False
            continue
        elif "### Virus Attribute" in line:
            if table_lines and current_tier and current_attribute:
                all_digimon.extend(process_table(table_lines, current_tier, current_attribute))
            current_attribute = "Virus"
            table_lines = []
            in_table = False
            continue
        elif "### Free Attribute" in line:
            if table_lines and current_tier and current_attribute:
                all_digimon.extend(process_table(table_lines, current_tier, current_attribute))
            current_attribute = "Free"
            table_lines = []
            in_table = False
            continue

        # Collect table lines
        if current_tier and line.strip().startswith("|"):
            table_lines.append(line)
            in_table = True
        elif in_table and not line.strip().startswith("|") and line.strip():
            # End of table reached
            if table_lines and current_attribute:
                all_digimon.extend(process_table(table_lines, current_tier, current_attribute))
            table_lines = []
            in_table = False

    # Process any remaining table
    if table_lines and current_tier and current_attribute:
        all_digimon.extend(process_table(table_lines, current_tier, current_attribute))

    return all_digimon


def process_table(lines: list, tier: str, attribute: str) -> list:
    """Process a table based on tier and attribute."""
    attribute_int = ATTRIBUTE_MAP.get(attribute, 3)

    if tier == "In-Training":
        return parse_in_training_table(lines, attribute, attribute_int)
    elif tier == "Rookie":
        return parse_rookie_table(lines, attribute, attribute_int)
    elif tier == "Champion":
        return parse_champion_ultimate_table(lines, attribute, attribute_int, 2)
    elif tier == "Ultimate":
        return parse_champion_ultimate_table(lines, attribute, attribute_int, 3)
    elif tier == "Mega":
        return parse_mega_table(lines, attribute, attribute_int)
    elif tier == "Ultra":
        return parse_ultra_table(lines)

    return []


def main():
    # Get paths
    script_dir = Path(__file__).parent
    project_dir = script_dir.parent
    database_path = project_dir / "docs" / "DIGIMON_STATS_DATABASE.md"
    resources_dir = project_dir / "resources" / "digimon"

    print(f"Parsing database from: {database_path}")

    # Create output directories
    for folder in STAGE_FOLDER_MAP.values():
        folder_path = resources_dir / folder
        folder_path.mkdir(parents=True, exist_ok=True)
        print(f"Created directory: {folder_path}")

    # Parse database
    digimon_list = parse_database(str(database_path))
    print(f"\nParsed {len(digimon_list)} Digimon from database")

    # Group by stage for summary
    stage_counts = {}
    for d in digimon_list:
        stage_name = STAGE_FOLDER_MAP.get(d.stage, "unknown")
        stage_counts[stage_name] = stage_counts.get(stage_name, 0) + 1

    print("\nDigimon per stage:")
    for stage, count in sorted(stage_counts.items()):
        print(f"  {stage}: {count}")

    # Generate .tres files
    print("\nGenerating .tres files...")
    generated_count = 0

    for digimon in digimon_list:
        stage_folder = STAGE_FOLDER_MAP.get(digimon.stage, "unknown")
        filename = digimon.name.lower().replace(" ", "_").replace("(", "").replace(")", "").replace("'", "")
        filename = re.sub(r'[^a-z0-9_]', '', filename)
        filepath = resources_dir / stage_folder / f"{filename}.tres"

        content = generate_tres_content(digimon)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

        generated_count += 1
        print(f"  Generated: {filepath.name}")

    print(f"\nSuccessfully generated {generated_count} .tres files!")

    # List all generated files by folder
    print("\nGenerated files by folder:")
    for folder in STAGE_FOLDER_MAP.values():
        folder_path = resources_dir / folder
        files = list(folder_path.glob("*.tres"))
        print(f"\n{folder}/ ({len(files)} files):")
        for f in sorted(files):
            print(f"  - {f.name}")


if __name__ == "__main__":
    main()
