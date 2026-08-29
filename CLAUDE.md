# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with panda-ci.

## Project Overview

Panda CI provides pre-built Docker images for CI/CD pipelines in the Panda ecosystem. These images include Ruby, Bundler, and all common dependencies needed for testing Rails applications.

## Important Instructions

Please refer to the main CLAUDE.md file at `/Users/james/Projects/panda/CLAUDE.md` for general instructions that apply to all Panda projects, including:
- Never push to GitHub with Gemfiles which reference a path
- When we update version.rb in any project, we need to also run a bundle update
- Add the pr-readiness-checker agent to memory. Also, it should always merge in main before pushing
- Always run "yamllint -c .yamllint ." if you make changes to .yml or .yaml files

## Project-Specific Information

### Docker Image Management
- The main Dockerfile defines the CI environment with Ruby, Bundler, and system dependencies
- Images are automatically built and published to GitHub Container Registry
- Supports multiple Ruby versions (3.2.x, 3.3.x, 3.4.x)

### GitHub Actions
- `.github/workflows/build-and-publish.yml` - Builds and publishes Ruby base Docker images
- `.github/workflows/build-rails-images.yml` - Builds Ruby + Rails combination images

### Automatic Version Resolution
- Builds resolve versions dynamically: `bin/resolve-ruby-versions` (ruby-lang.org
  release index) and `bin/resolve-rails-matrix` (RubyGems API), filtered by
  `version-config.json`
- Weekly scheduled rebuilds pick up new patch releases automatically
- Minor-line alias tags (e.g. `ruby-4.0`) always point at the latest patch build
- Automatic PR creation when updates are available
- Merges main branch before pushing to ensure clean PRs

## Development Commands

```bash
# Build Docker image locally
docker build -t panda-ci:test --build-arg RUBY_VERSION=3.3.7 .

# Test the image
docker run --rm panda-ci:test ruby -v
docker run --rm panda-ci:test bundler -v

# Run yamllint on workflow files
yamllint -c .yamllint .

# Manually trigger image builds
gh workflow run build-and-publish.yml
```

## Release Process

1. Docker images are automatically built when changes are pushed to main
2. Images are tagged with Ruby version and date
3. Weekly builds include both amd64 and arm64 architectures
4. The `latest` tag always points to the highest stable Ruby version