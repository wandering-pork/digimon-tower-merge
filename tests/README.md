# Digimon Tower Merge - Test Suite

This directory contains unit and integration tests for the Digimon Tower Merge game using the GUT (Godot Unit Testing) framework.

## Directory Structure

```
tests/
├── unit/              # Unit tests for individual components
│   ├── test_game_config.gd      # Tests for GameConfig calculations
│   └── test_economy_system.gd   # Tests for EconomySystem transactions
├── integration/       # Integration tests (coming soon)
└── README.md          # This file
```

## Installing GUT

1. Open the Godot Editor
2. Go to **AssetLib** tab (top center)
3. Search for "GUT" or "Godot Unit Test"
4. Download and install the addon by **bitwes**
5. Enable the addon: **Project > Project Settings > Plugins > GUT** (set to Enabled)

Alternatively, download from GitHub:
- https://github.com/bitwes/Gut

## Running Tests

### From the Godot Editor

1. After enabling the GUT plugin, you'll see a **GUT** panel at the bottom
2. Click the panel to open it
3. Click **Run All** to run all tests, or select specific test files

### From Command Line

```bash
# Windows (using Steam Godot path from CLAUDE.md)
"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

### Test Configuration

The `.gutconfig.json` file in the project root configures GUT:

- **dirs**: Test directories to scan
- **prefix**: Test file prefix (default: "test_")
- **suffix**: Test file suffix (default: ".gd")
- **include_subdirs**: Scan subdirectories for tests

## Writing Tests

### Test File Structure

```gdscript
extends GutTest

func before_all() -> void:
    # Runs once before all tests
    pass

func after_all() -> void:
    # Runs once after all tests
    pass

func before_each() -> void:
    # Runs before each test method
    pass

func after_each() -> void:
    # Runs after each test method
    pass

func test_something() -> void:
    # Test methods must start with "test_"
    assert_eq(1 + 1, 2, "Math should work")
```

### Common Assertions

```gdscript
assert_eq(actual, expected, message)      # Equal
assert_ne(actual, expected, message)      # Not equal
assert_true(value, message)               # Is true
assert_false(value, message)              # Is false
assert_null(value, message)               # Is null
assert_not_null(value, message)           # Not null
assert_gt(actual, expected, message)      # Greater than
assert_lt(actual, expected, message)      # Less than
assert_between(value, low, high, message) # In range
```

### Signal Testing

```gdscript
func test_signal_emission() -> void:
    watch_signals(some_object)
    some_object.do_something()
    assert_signal_emitted(some_object, "signal_name")
```

### Pending Tests

Use `pending()` for tests that need external resources:

```gdscript
func test_requires_game_running() -> void:
    var system = get_node_or_null("/root/SomeAutoload")
    if not system:
        pending("Test requires running game")
        return
    # ... actual test code
```

## Test Categories

### Unit Tests (`tests/unit/`)

Test individual components in isolation:
- GameConfig calculations
- EconomySystem cost lookups
- Pure functions with no dependencies

### Integration Tests (`tests/integration/`)

Test component interactions:
- Wave system flow
- Tower combat interactions
- Full game scenarios

## Current Test Coverage

| Component | Tests | Coverage |
|-----------|-------|----------|
| GameConfig | 45+ | Spawn costs, level costs, digivolve costs, max level calculations, grid conversions |
| EconomySystem | 30+ | Spawn costs, level costs, sell values, wave rewards, cost formatting |

## Adding New Tests

1. Create a new file in the appropriate directory (`unit/` or `integration/`)
2. Name it with the `test_` prefix (e.g., `test_merge_system.gd`)
3. Extend `GutTest`
4. Add test methods with `test_` prefix
5. Run tests to verify

## Troubleshooting

### "EconomySystem not available"

Some tests require autoloads to be running. These tests use `pending()` when autoloads aren't available. Run tests through the Godot editor to have autoloads active.

### GUT Plugin Not Showing

1. Make sure you've enabled the plugin in Project Settings
2. Restart the editor
3. Check that `addons/gut/` directory exists
