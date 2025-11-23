# Version Configuration

This document explains the `version-config.json` file which controls how the CI tooling automatically discovers, builds, and manages Ruby and Rails versions.

## Overview

The configuration file uses a **discovery-based approach** rather than hardcoding specific versions. The workflows automatically discover all available versions and apply rules from this config to determine:

- Which versions to build
- Which versions are experimental
- Which version combinations are incompatible

## Configuration Structure

### Ruby Configuration

```json
{
  "ruby": {
    "minimum_supported_version": "3.2.0",
    "current_stable_major_version": 3,
    "experimental_suffixes": ["preview", "rc", "alpha", "beta"]
  }
}
```

**Fields:**

- **`minimum_supported_version`**: Don't build any Ruby version older than this. Versions below this are ignored during discovery.
  - Example: `"3.2.0"` means we ignore Ruby 2.7, 3.0, 3.1

- **`current_stable_major_version`**: The current stable major version line.
  - Any major version above this is automatically marked as experimental
  - Example: `3` means Ruby 3.x is stable, Ruby 4.x is experimental
  - Update this when a new major version becomes the recommended stable release

- **`experimental_suffixes`**: Version suffixes that indicate experimental/pre-release versions.
  - Any version with these suffixes is marked as experimental
  - Matches: `3.5.0-preview1`, `4.0.0-rc1`, `3.4.0-alpha2`, etc.

### Rails Configuration

```json
{
  "rails": {
    "minimum_supported_version": "7.0.0",
    "current_stable_major_version": 8,
    "experimental_suffixes": ["preview", "rc", "alpha", "beta"]
  }
}
```

Same structure as Ruby configuration. Rails 8.x is currently stable, Rails 9.x would be experimental.

### Compatibility Rules

```json
{
  "compatibility": {
    "excluded_combinations": [
      {
        "ruby": ">=3.4",
        "rails": "7.0",
        "reason": "Rails 7.0 incompatible with Ruby 3.4+"
      }
    ]
  }
}
```

**Fields:**

- **`excluded_combinations`**: Array of incompatible Ruby/Rails version pairs
- **`ruby`**: Ruby version or version range (see operators below)
- **`rails`**: Rails version or version range (see operators below)
- **`reason`**: Human-readable explanation for the exclusion

## Version Comparison Operators

The `excluded_combinations` rules support comparison operators:

### Exact Minor Version Match

```json
{"ruby": "3.4", "rails": "7.0"}
```

Matches any patch version of Ruby 3.4 with any patch version of Rails 7.0:

- ✅ Ruby 3.4.0 + Rails 7.0.8
- ✅ Ruby 3.4.7 + Rails 7.0.0
- ✅ Ruby 3.4.1-preview1 + Rails 7.0.4
- ❌ Ruby 3.5.0 + Rails 7.0.0
- ❌ Ruby 3.4.0 + Rails 7.1.0

### Greater Than or Equal (>=)

```json
{"ruby": ">=3.4", "rails": "7.0"}
```

Matches Ruby 3.4 and any higher minor/major version with Rails 7.0:

- ✅ Ruby 3.4.0 + Rails 7.0.8
- ✅ Ruby 3.5.0 + Rails 7.0.0
- ✅ Ruby 3.5.0-preview1 + Rails 7.0.4
- ✅ Ruby 4.0.0 + Rails 7.0.0
- ❌ Ruby 3.3.10 + Rails 7.0.0
- ❌ Ruby 3.4.0 + Rails 7.1.0

### Less Than or Equal (<=)

```json
{"ruby": "<=3.3", "rails": "8.0"}
```

Matches Ruby 3.3 and any lower minor/major version with Rails 8.0:

- ✅ Ruby 3.2.9 + Rails 8.0.0
- ✅ Ruby 3.3.10 + Rails 8.0.1
- ❌ Ruby 3.4.0 + Rails 8.0.0
- ❌ Ruby 3.3.0 + Rails 8.1.0

### Combining Rules

Multiple exclusion rules can be defined:

```json
{
  "excluded_combinations": [
    {
      "ruby": ">=3.4",
      "rails": "7.0",
      "reason": "Rails 7.0 incompatible with Ruby 3.4+"
    },
    {
      "ruby": "3.2",
      "rails": ">=8.1",
      "reason": "Rails 8.1+ requires Ruby 3.3+"
    }
  ]
}
```

## How It Works

### Daily Update Check Workflow

The `check-updates.yml` workflow runs daily and:

1. **Discovers all available versions** by fetching from ruby-lang.org and rubygems.org
2. **Filters by minimum version** using `minimum_supported_version`
3. **Marks experimental versions** based on:
   - Suffix matching (`experimental_suffixes`)
   - Major version comparison (`current_stable_major_version`)
4. **Finds latest patch** for each discovered minor version
5. **Updates workflow files** if new versions are found
6. **Creates a PR** with the changes

### Build Workflow

The `build-and-publish.yml` and `build-rails-images.yml` workflows:

1. **Use the discovered versions** from the check workflow
2. **Apply compatibility rules** to exclude incompatible combinations
3. **Build Docker images** for all valid combinations
4. **Tag experimental images** appropriately

## Examples

### When Ruby 3.5.0-preview1 is Released

1. Workflow discovers `3.5.0-preview1`
2. Marked as experimental (matches "preview" suffix)
3. Added to build matrix
4. Incompatible combinations excluded (e.g., Ruby 3.5 + Rails 7.0 via `>=3.4` rule)
5. Docker image built and tagged with experimental marker

### When Ruby 4.0.0 is Released

1. Workflow discovers `4.0.0`
2. Marked as experimental (major version 4 > current stable 3)
3. Added to build matrix
4. All Ruby 4.x versions automatically experimental until config updated

### When We Drop Support for Ruby 3.2

Update `minimum_supported_version`:

```json
{
  "ruby": {
    "minimum_supported_version": "3.3.0"
  }
}
```

Ruby 3.2.x versions will no longer be discovered or built.

### When Ruby 4 Becomes Stable

Update `current_stable_major_version`:

```json
{
  "ruby": {
    "current_stable_major_version": 4
  }
}
```

All Ruby 4.x versions are now stable (unless they have experimental suffixes).

## Maintenance

### Adding a New Incompatibility

When you discover a new incompatible version combination:

1. Add it to `excluded_combinations`
2. Use the most general rule possible (prefer `>=` over listing each version)
3. Include a clear reason

### Updating Supported Versions

- **Dropping old versions**: Update `minimum_supported_version`
- **New major release becomes stable**: Update `current_stable_major_version`
- **New experimental suffix**: Add to `experimental_suffixes` (rare)

## Related Files

- `version-config.json` - The configuration file itself
- `.github/workflows/check-updates.yml` - Daily Ruby/Bundler version check
- `.github/workflows/check-rails-updates.yml` - Daily Rails version check
- `.github/workflows/build-and-publish.yml` - Build Ruby CI images
- `.github/workflows/build-rails-images.yml` - Build Ruby+Rails CI images
- `COMPATIBILITY.md` - Runtime compatibility documentation
