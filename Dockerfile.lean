# Panda CI Docker Image (Lean Version for Matrix Testing)
# Provides minimal environment optimized for matrix testing with different Rails versions

ARG RUBY_VERSION=3.3

FROM ruby:${RUBY_VERSION}-slim

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone to UTC
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install only essential system dependencies
RUN apt-get update && apt-get install -y \
  # Build essentials
  build-essential \
  git \
  curl \
  wget \
  # PostgreSQL client (for pg gem)
  postgresql-client \
  libpq-dev \
  # SQLite (for sqlite3 gem)
  sqlite3 \
  libsqlite3-dev \
  # For Nokogiri (commonly required)
  libxml2-dev \
  libxslt1-dev \
  # For psych gem (YAML parsing)
  libyaml-dev \
  # For rbnacl gem (used by JWT/OAuth)
  libsodium-dev \
  # Utilities
  sudo \
  locales \
  # Clean up
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

# -----------------------------------------------------------
# Locale
# -----------------------------------------------------------
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# -----------------------------------------------------------
# Install Bundler (always latest)
# -----------------------------------------------------------
RUN gem update --system && gem install bundler

# Create a non-root user for running tests (optional but recommended)
RUN useradd -m -s /bin/bash panda && \
  echo 'panda ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Only install minimal gems that are always needed
# Don't pre-install Rails or test gems - let matrix testing handle versions
RUN gem install \
  rake \
  bundler-audit

# Pre-create common directories
RUN mkdir -p /app /tmp/cache

# Set working directory
WORKDIR /app

# Add a health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ruby -v || exit 1

# Labels for GitHub Container Registry
LABEL org.opencontainers.image.source="https://github.com/tastybamboo/panda-ci"
LABEL org.opencontainers.image.description="Lean CI environment for Panda matrix testing"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"
LABEL maintainer="Otaina Limited"

# Bundler layer cache support inside CI image
ENV BUNDLE_PATH=/usr/local/bundle
ENV BUNDLE_APP_CONFIG=/usr/local/bundle
RUN bundle config set --global path "/usr/local/bundle"

# Default command
CMD ["/bin/bash"]
