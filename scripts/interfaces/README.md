# Interface Abstractions

> TODO: Implement these interfaces for better decoupling

This folder will contain GDScript interface classes for pluggable behaviors.

## Planned Interfaces

### i_attacker.gd
```gdscript
class_name IAttacker
extends RefCounted
## Interface for entities that can deal damage

func get_base_damage() -> int:
    assert(false, "Must override")
    return 0

func get_attack_level() -> int:
    assert(false, "Must override")
    return 0

func get_attack_dp() -> int:
    assert(false, "Must override")
    return 0

func get_attribute() -> int:
    assert(false, "Must override")
    return 0
```

### i_damageable.gd
```gdscript
class_name IDamageable
extends RefCounted
## Interface for entities that can take damage

func take_damage(amount: float, source: Node, damage_type: String) -> void:
    assert(false, "Must override")

func get_current_hp() -> float:
    assert(false, "Must override")
    return 0.0

func get_max_hp() -> float:
    assert(false, "Must override")
    return 0.0

func is_alive() -> bool:
    assert(false, "Must override")
    return false
```

### i_targetable.gd
```gdscript
class_name ITargetable
extends RefCounted
## Interface for entities that can be targeted

func get_target_position() -> Vector2:
    assert(false, "Must override")
    return Vector2.ZERO

func get_priority_value(priority_type: int) -> float:
    assert(false, "Must override")
    return 0.0

func is_valid_target() -> bool:
    assert(false, "Must override")
    return false
```

### i_effect_receiver.gd
```gdscript
class_name IEffectReceiver
extends RefCounted
## Interface for entities that can receive status effects

func apply_effect(effect: TraitEffect, source: Node) -> void:
    assert(false, "Must override")

func has_effect(effect_name: String) -> bool:
    assert(false, "Must override")
    return false

func remove_effect(effect_name: String) -> void:
    assert(false, "Must override")

func clear_all_effects() -> void:
    assert(false, "Must override")
```

## Benefits

1. **Decoupling** - damage_calculator.gd works with interfaces, not concrete types
2. **Testing** - Create mock objects implementing interfaces
3. **Flexibility** - New entity types just implement required interfaces
4. **Documentation** - Interfaces document expected behavior

## Implementation Notes

In GDScript, interfaces are implemented via duck typing. Classes don't need to
explicitly inherit from interface classes - they just need to implement the
required methods. The interface classes serve as documentation and can be used
for type checking in debug builds.

See: docs/IMPLEMENTATION_TODO.md
