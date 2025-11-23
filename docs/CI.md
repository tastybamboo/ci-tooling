# CI/CD Documentation

## Overview

This repository has comprehensive CI/CD for validating changes and ensuring Docker images build correctly.

## GitHub Actions CI

### PR Validation Workflow

The `.github/workflows/pr-validation.yml` workflow runs on all pull requests and includes:

1. **YAML Validation**
   - Runs `yamllint` on all YAML files
   - Ensures consistent formatting and catches syntax errors

2. **Dockerfile Validation**
   - Uses Hadolint to check Dockerfiles for best practices
   - Validates syntax and security concerns

3. **Docker Image Build & Test**
   - Builds all three Docker images (main, rails, lean)
   - Tests Ruby and Bundler installations
   - Verifies Chrome/Chromium works (except in lean image)
   - Tests Bootsnap cache directory configuration
   - Runs functional tests with sample Gemfiles

4. **Image Size Checks**
   - Reports size of each image
   - Ensures lean image stays under 1GB
   - Compares sizes to ensure lean < main

## Local Development with Lefthook

### Installation

1. Install Lefthook:
   ```bash
   # Via Homebrew (macOS/Linux)
   brew install lefthook

   # Via Ruby gem
   gem install lefthook

   # Or use bundler
   bundle install
   ```

2. Install git hooks:
   ```bash
   lefthook install
   ```

### Pre-commit Hooks

- **yamllint**: Validates YAML files before commit
- **check-dockerfiles**: Basic Dockerfile validation
- **check-whitespace**: Prevents trailing whitespace

### Pre-push Hooks

- **validate-branch**: Prevents direct pushes to main
- **yamllint-all**: Full YAML validation
- **dockerfile-syntax**: Attempts to validate Dockerfile syntax

### Skipping Hooks

If you need to skip hooks temporarily:
```bash
# Skip all hooks for one commit
git commit --no-verify

# Skip all hooks for one push
git push --no-verify

# Or set environment variable
LEFTHOOK=0 git commit
```

## Running CI Locally

To test the CI workflow locally before pushing:

```bash
# Run yamllint
yamllint -c .yamllint .

# Build and test Docker images
docker build -f Dockerfile -t test:main .
docker build -f Dockerfile.rails -t test:rails --build-arg RAILS_VERSION=7.2.2 .
docker build -f Dockerfile.lean -t test:lean .

# Test the images
docker run --rm test:main ruby -v
docker run --rm test:main bundler -v
docker run --rm test:rails rails -v
```

## Troubleshooting

### YAML Lint Errors

If yamllint fails, fix the issues or update `.yamllint` configuration:
```bash
# Auto-fix some issues (use with caution)
yamllint --format auto -c .yamllint .
```

### Docker Build Failures

1. Check Docker daemon is running
2. Ensure you have enough disk space
3. Try clearing Docker cache: `docker system prune -a`

### Lefthook Not Running

1. Ensure hooks are installed: `lefthook install`
2. Check git hooks directory: `ls -la .git/hooks/`
3. Reinstall if needed: `lefthook uninstall && lefthook install`

## Best Practices

1. **Always create PRs** - Don't push directly to main
2. **Run yamllint** before committing workflow changes
3. **Test Docker builds locally** for significant Dockerfile changes
4. **Keep images lean** - Especially `Dockerfile.lean`
5. **Update this documentation** when adding new CI features