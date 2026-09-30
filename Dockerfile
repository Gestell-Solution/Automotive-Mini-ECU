# ==============================================================================
# @file       Dockerfile
# @brief      Multi-team development environment for Gestell Automotive Mini-ECU
# @author     Eng. Hesham (Hesham4Ahmed@gmail.com)
# @company    Gestell Company
# @copyright  Copyright (c) 2026, Gestell Company. All rights reserved.
#
# Supported Teams:
#   - Embedded  : AVR cross-compilation toolchain (avr-gcc, avrdude, lcov)
#   - Dashboard : Node.js / npm for web development
#   - Mobile    : Flutter SDK for mobile app development
#
# Security: Docker Secrets / ARG-based password enforcement.
#           The image requires BUILD_TOKEN to be passed at build time.
#           Runtime access requires GESTELL_TOKEN env variable.
# ============================================================================== 

FROM ubuntu:22.04

# Suppress interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# Build-time access control
# Pass with: docker build --build-arg BUILD_TOKEN=<secret> .
# ------------------------------------------------------------------------------
ARG BUILD_TOKEN
RUN if [ -z "$BUILD_TOKEN" ]; then \
      echo "ERROR: BUILD_TOKEN is required. Use --build-arg BUILD_TOKEN=<secret>" && exit 1; \
    fi

# ------------------------------------------------------------------------------
# System packages
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update && apt-get install -y \
    # --- Build Essentials ---
    make \
    build-essential \
    curl \
    wget \
    git \
    unzip \
    xz-utils \
    zip \
    # --- AVR Cross-Compilation Toolchain (Embedded Team) ---
    gcc-avr \
    avr-libc \
    avrdude \
    binutils-avr \
    # --- Host GCC Toolchain (Unit Tests, must match gcov version) ---
    gcc-13 \
    # --- Static Analysis ---
    cppcheck \
    # --- Code Coverage ---
    lcov \
    # --- Node.js prerequisites (Dashboard Team) ---
    ca-certificates \
    gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Node.js 20 LTS (Dashboard Team)
# ------------------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# Flutter SDK (Mobile Team)
# ------------------------------------------------------------------------------
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git $FLUTTER_HOME \
    && flutter config --no-analytics \
    && flutter precache --no-android --no-ios --no-web \
    && flutter doctor || true

# ------------------------------------------------------------------------------
# Runtime access control
# The entrypoint checks for GESTELL_TOKEN before allowing any shell access.
# Set the correct value with: docker run -e GESTELL_TOKEN=<secret> ...
# The hash below is SHA256 of the token — replace with your own:
#   echo -n "YourSecretToken" | sha256sum
# ------------------------------------------------------------------------------
ENV GESTELL_TOKEN_HASH="4975ff34559f922568ea9c966e100d8090c6fb9730722cebd0758f2a7ff53a59"

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]

# ==============================================================================
# Installed Tools:
#   make             4.3
#   avr-gcc          5.4.0    (embedded firmware compilation)
#   avrdude          6.3      (firmware flashing)
#   gcc-13 / gcov-13 13.x    (unit testing + coverage — must match)
#   cppcheck         2.x      (MISRA-C static analysis)
#   lcov + genhtml   1.14+    (HTML coverage reports)
#   node             20.x LTS (Dashboard team)
#   npm              10.x     (Dashboard team)
#   flutter          stable   (Mobile team)
# ==============================================================================
