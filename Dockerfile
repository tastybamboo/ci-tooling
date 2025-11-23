# syntax=docker/dockerfile:1.4
#
# Panda CI Docker Image
# Multi-arch (AMD64 + ARM64) compatible

ARG RUBY_VERSION=3.4
FROM ruby:${RUBY_VERSION}-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# -----------------------------------------------------------
# System packages (multi-arch friendly + Chromium compatible)
# -----------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  curl \
  wget \
  git \
  sudo \
  locales \
  tzdata \
  # PostgreSQL
  postgresql-client \
  libpq-dev \
  # Image processing
  libvips42 \
  imagemagick \
  libmagickwand-dev \
  # Nokogiri deps
  libxml2-dev \
  libxslt1-dev \
  # YAML / rbnacl
  libyaml-dev \
  libsodium-dev \
  # Browser testing + dependencies
  chromium \
  chromium-driver \
  xvfb \
  # Linters
  yamllint \
  && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------
# Locale
# -----------------------------------------------------------
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

# -----------------------------------------------------------
# Chromium environment
# -----------------------------------------------------------
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMIUM_FLAGS="--no-sandbox --headless --disable-gpu --disable-dev-shm-usage --disable-software-rasterizer --disable-extensions --disable-background-networking --metrics-recording-only --mute-audio"

# -----------------------------------------------------------
# Pre-warm Chromium (non-fatal)
# -----------------------------------------------------------
RUN chromium --headless --no-sandbox --disable-gpu \
  --print-to-pdf=/tmp/test.pdf about:blank && rm /tmp/test.pdf \
  || echo "Chromium warmup skipped"

# -----------------------------------------------------------
# Install Bundler (always latest)
# -----------------------------------------------------------
RUN gem update --system && gem install bundler

# -----------------------------------------------------------
# Create non-root user
# -----------------------------------------------------------
RUN useradd -m -s /bin/bash panda && \
  echo 'panda ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# -----------------------------------------------------------
# Pre-install common CI gems
# -----------------------------------------------------------
RUN gem install \
  rake \
  rspec \
  rspec-rails \
  parallel_tests \
  standard \
  rubocop \
  rubocop-rails \
  rubocop-rspec \
  erb_lint \
  brakeman \
  bundle-audit \
  rails-controller-testing \
  capybara \
  cuprite \
  database_cleaner-active_record \
  shoulda-matchers \
  simplecov \
  simplecov-json \
  pg

# -----------------------------------------------------------
# Pre-create directories and Bootsnap cache
# -----------------------------------------------------------
# Bootsnap speeds up Ruby boot time by caching expensive operations
# Setting a CI-specific directory prevents cache conflicts between builds
RUN mkdir -p /app /tmp/cache /app/tmp/bootsnap-ci
WORKDIR /app
ENV BOOTSNAP_CACHE_DIR=/app/tmp/bootsnap-ci

# -----------------------------------------------------------
# Health check
# -----------------------------------------------------------
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ruby -v || exit 1

# -----------------------------------------------------------
# Labels
# -----------------------------------------------------------
LABEL org.opencontainers.image.source="https://github.com/tastybamboo/panda-ci"
LABEL org.opencontainers.image.description="CI/CD environment for Panda projects"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"
LABEL maintainer="Otaina Limited"

# Bundler layer cache support inside CI image
ENV BUNDLE_PATH=/usr/local/bundle
ENV BUNDLE_APP_CONFIG=/usr/local/bundle
RUN bundle config set --global path "/usr/local/bundle"

CMD ["/bin/bash"]
