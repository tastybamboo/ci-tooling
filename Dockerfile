# Panda CI Docker Image
# Provides a pre-configured environment for running Panda project CI/CD pipelines

ARG RUBY_VERSION=3.3

FROM ruby:${RUBY_VERSION}-slim

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone to UTC
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install system dependencies
RUN apt-get update && apt-get install -y \
  # Build essentials
  build-essential \
  git \
  curl \
  wget \
  # PostgreSQL client
  postgresql-client \
  # Image processing
  libvips42 \
  imagemagick \
  libmagickwand-dev \
  # For Nokogiri
  libxml2-dev \
  libxslt1-dev \
  # For pg gem
  libpq-dev \
  # For psych gem (YAML parsing)
  libyaml-dev \
  # For rbnacl gem (used by JWT/OAuth)
  libsodium-dev \
  # Browser testing dependencies
  chromium \
  chromium-driver \
  xvfb \
  # Additional utilities
  sudo \
  locales \
  # YAML linting
  yamllint \
  # Clean up
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

# Generate locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Configure Chromium for headless operation with optimized flags
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMIUM_FLAGS="--no-sandbox --headless --disable-gpu --disable-dev-shm-usage --disable-software-rasterizer --disable-extensions --disable-background-networking --metrics-recording-only --mute-audio"

# Pre-warm Chrome to speed up first test execution
RUN chromium --headless --no-sandbox --disable-gpu --print-to-pdf=/tmp/test.pdf about:blank && \
    rm /tmp/test.pdf

# Install specific bundler version that matches your Gemfile.lock
RUN gem install bundler:2.7.2

# Create a non-root user for running tests (optional but recommended)
RUN useradd -m -s /bin/bash panda && \
  echo 'panda ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set up common Ruby gems that are used across all projects
# This speeds up bundle install in CI

# Testing & CI tools
RUN gem install \
  rake \
  rspec \
  rspec-rails \
  parallel_tests

# Code quality & linting
RUN gem install \
  standard \
  rubocop \
  rubocop-rails \
  rubocop-rspec \
  erb_lint \
  brakeman \
  bundle-audit

# Commonly used application dependencies
RUN gem install \
  rails-controller-testing \
  capybara \
  cuprite \
  database_cleaner-active_record \
  shoulda-matchers \
  simplecov \
  simplecov-json \
  pg

# Pre-create common directories
RUN mkdir -p /app /tmp/cache

# Set working directory
WORKDIR /app

# Add a health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ruby -v || exit 1

# Labels for GitHub Container Registry
LABEL org.opencontainers.image.source="https://github.com/tastybamboo/panda-ci"
LABEL org.opencontainers.image.description="CI/CD environment for Panda projects"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"
LABEL maintainer="Otaina Limited"

# Default command
CMD ["/bin/bash"]
