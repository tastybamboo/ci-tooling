# Ruby on Rails Compatibility Matrix

## Supported Combinations

This document tracks which Ruby versions are compatible with which Rails versions
for our CI testing matrix.

### Official Rails Requirements

| Rails Version | Minimum Ruby | Maximum Ruby | Notes |
|--------------|--------------|--------------|-------|
| Rails 7.0    | Ruby 2.7     | Ruby 3.3     | ❌ Not compatible with Ruby 3.4 |
| Rails 7.1    | Ruby 3.0     | Ruby 3.4+    | ✅ Works with Ruby 3.4 |
| Rails 7.2    | Ruby 3.1     | Ruby 3.4+    | ✅ Works with Ruby 3.4 |
| Rails 8.0    | Ruby 3.2     | Ruby 3.4+    | ✅ Works with Ruby 3.4 |
| Rails 8.1    | Ruby 3.2     | Ruby 3.4+    | ✅ Works with Ruby 3.4 |

### Our Testing Matrix

We test with Ruby 3.2, 3.3, and 3.4. Here's what we build:

#### ✅ Valid Combinations (15 total)

**Ruby 3.2** (works with all Rails versions):
- `ruby-3.2-rails-7.0.10`
- `ruby-3.2-rails-7.1.6`
- `ruby-3.2-rails-7.2.3`
- `ruby-3.2-rails-8.0.4`
- `ruby-3.2-rails-8.1.2`

**Ruby 3.3** (works with all Rails versions):
- `ruby-3.3-rails-7.0.10`
- `ruby-3.3-rails-7.1.6`
- `ruby-3.3-rails-7.2.3`
- `ruby-3.3-rails-8.0.4`
- `ruby-3.3-rails-8.1.2`

**Ruby 3.4** (works with Rails 7.1+):
- `ruby-3.4-rails-7.1.6`
- `ruby-3.4-rails-7.2.3`
- `ruby-3.4-rails-8.0.4`
- `ruby-3.4-rails-8.1.2`

#### ❌ Invalid Combinations (excluded)

- `ruby-3.4-rails-7.0.10` - Rails 7.0 is not compatible with Ruby 3.4

### Why Rails 7.0 doesn't support Ruby 3.4?

Rails 7.0 has compatibility issues with Ruby 3.4 due to:
1. Keyword argument handling changes in Ruby 3.4
2. Deprecation removals that Rails 7.0 relied on
3. Method signature changes that break Rails 7.0 internals

### Updating This Matrix

When new versions are released:

1. Check the [Rails releases page](https://rubyonrails.org/category/releases)
2. Check the [Ruby compatibility table](https://www.fastruby.io/blog/ruby/rails/versions/compatibility-table.html)
3. Update the build matrix in `.github/workflows/build-rails-images.yml`
4. Update this documentation
5. Update `Dockerfile.rails` if gem version constraints need updating

### Testing Locally

To test a specific combination locally:

```bash
# Build a specific combination
docker build -t panda-test \
  --build-arg RUBY_VERSION=3.4 \
  --build-arg RAILS_VERSION=8.1.1 \
  -f Dockerfile.rails .

# Run tests
docker run --rm panda-test rails -v
docker run --rm panda-test ruby -v
```

### CI Performance Notes

Pre-building these images with gems installed saves approximately 2-3 minutes per CI run:
- Without pre-built images: ~3-4 minutes for bundle install
- With pre-built images: ~30 seconds for bundle install (only panda-* gems)

### Latest Tags

For convenience, we maintain "latest" tags for each Rails series:
- `rails-7.0-latest` → Ruby 3.2 + Rails 7.0.7.0.10
- `rails-7.1-latest` → Ruby 3.2 + Rails 7.1.7.1.6
- `rails-7.2-latest` → Ruby 3.2 + Rails 7.2.7.2.3
- `rails-8.0-latest` → Ruby 3.3 + Rails 8.0.8.0.4
- `rails-8.1-latest` → Ruby 3.3 + Rails 8.1.8.1.2
- `rails-latest` → Ruby 3.4 + Rails 8.1.8.1.2