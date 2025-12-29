# Xenoflora Testing Guide

This directory contains unit tests for the Xenofloria game using the GdUnit4 testing framework.

## Setup

GdUnit4 has been installed in `addons/gdUnit4` and configured in `project.godot`.

### First Time Setup

1. Open the project in Godot Editor
2. Go to **Project → Project Settings → Plugins**
3. Enable the "gdUnit4" plugin
4. Restart Godot Editor when prompted

The GdUnit4 panel should now appear at the bottom of the editor.

## Running Tests

### Via Godot Editor (Recommended)

1. Open the project in Godot Editor
2. Click on the "GdUnit4" tab at the bottom panel
3. Click the "Run All" button to execute all tests
4. Individual test files can be run by right-clicking them in the FileSystem panel and selecting "Run GdUnit4 Tests"

### Via Command Line

```bash
# Run all tests
godot-4 --headless -s --path . addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/ --ignoreHeadlessMode --audio-driver Dummy

# Run specific test suite
godot-4 --headless -s --path . addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/test_asteroid_generator.gd --ignoreHeadlessMode --audio-driver Dummy
```

**Note:** The `--ignoreHeadlessMode` flag is required because our tests don't use UI interaction. Exit code 101 means "passed with warnings" (orphan node warnings are expected for these tests).

## Test Files

### test_asteroid_generator.gd
Tests the procedural asteroid generation system:
- Correct asteroid count generation
- No overlapping asteroids
- Asteroids within play area bounds
- Property ranges (energy, defense, speed)
- Starting position assignment
- Poisson disk sampling

### test_combat_system.gd
Tests the combat resolution mechanics:
- Successful captures with overwhelming force
- Failed captures (insufficient attackers)
- Defender attrition calculations
- Defense bonus multipliers
- Edge cases (empty asteroids, equal forces, overkill)
- Fractional damage rounding

## Writing New Tests

1. Create a new test file in `tests/` directory with naming pattern: `test_<feature_name>.gd`
2. Extend `GdUnitTestSuite`:
   ```gdscript
   extends GdUnitTestSuite
   ```
3. Write test functions prefixed with `test_`:
   ```gdscript
   func test_my_feature():
       var result = my_function()
       assert_int(result).is_equal(42)
   ```
4. Use `before_test()` for setup and `after_test()` for cleanup

### Common Assertions

```gdscript
# Integers
assert_int(value).is_equal(expected)
assert_int(value).is_greater(min)
assert_int(value).is_between(min, max)

# Floats
assert_float(value).is_equal(expected)
assert_float(value).is_greater_equal(min)
assert_float(value).is_between(min, max)

# Booleans
assert_bool(value).is_true()
assert_bool(value).is_false()

# Objects
assert_object(obj).is_not_null()
assert_object(obj).is_same(other)

# Arrays
assert_array(arr).has_size(count)
assert_array(arr).contains([items])
```

## Test Reports

Test reports are generated in `.gdunit4_reports/` (gitignored).

## Continuous Integration

For CI/CD pipelines, use the command-line interface:

```bash
# Example GitHub Actions workflow
godot-4 --headless -s --path . addons/gdUnit4/bin/GdUnitCmdTool.gd \
  --add tests/ \
  --ignoreHeadlessMode \
  --audio-driver Dummy \
  --quit-timeout 60
```

Exit codes: 0 or 101 indicate all tests passed (101 = passed with warnings).

## Troubleshooting

### Plugin Not Showing
- Ensure `addons/gdUnit4/plugin.cfg` exists
- Check Project Settings → Plugins shows gdUnit4
- Restart Godot Editor

### Tests Not Running
- Verify test files extend `GdUnitTestSuite`
- Check test function names start with `test_`
- Look for syntax errors in test files

### Import Errors
- Ensure scenes/scripts are properly preloaded
- Use `res://` paths for all resources
- Check that GameManager autoload is available

## Resources

- [GdUnit4 Documentation](https://github.com/MikeSchulze/gdUnit4)
- [GdUnit4 Assertions Reference](https://mikeschulze.github.io/gdUnit4/asserts/)
