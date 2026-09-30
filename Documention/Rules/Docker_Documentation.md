<div align="center">

![Gestell Company Logo][gestell-logo]

<br/><br/>

# 🐳 Docker Environment Documentation

**Unified Development Environment**

_Developed by Gestell Company - Professional Embedded Solutions_

<br/>

![Status](https://img.shields.io/badge/Status-Draft-red) ![Category](https://img.shields.io/badge/Category-DevOps-blue) ![Version](https://img.shields.io/badge/Version-0.1-lightgrey) ![License](https://img.shields.io/badge/License-Gestell-orange) ![Type](https://img.shields.io/badge/Type-Infrastructure-brightgreen)

</div>

---

<div align="center">

![Type](https://img.shields.io/badge/Type-Environment-blue)
![Status](https://img.shields.io/badge/Status-Standard-green)

**Containerized Toolchain for Embedded, Dashboard & Mobile Teams**

</div>

---

## 📋 Overview

This document provides a comprehensive guide to the Docker-based development environment for the **Automotive-Mini-ECU** project. The environment is **unified** — a single Docker image supports all three project teams, guaranteeing that every developer works with identical toolchains regardless of their host operating system.

| Team              | Technologies               |
| :---------------- | :------------------------- |
| **Embedded**      | C/AVR, Unity, MISRA, gcov  |
| **Dashboard**     | Node.js, npm               |
| **MobileApp**     | Flutter, Dart              |

---

## 🏗️ Architecture Overview

The Docker setup consists of three primary configuration files located in the root directory:

```mermaid
graph TD
    DF[Dockerfile] --> IMG[Unified Docker Image]
    IMG --> EMB[embedded service]
    IMG --> DASH[dashboard service]
    IMG --> MOB[mobile service]

    DC[docker-compose.yml] --> EMB
    DC --> DASH
    DC --> MOB

    ES[docker-entrypoint.sh] --> SEC{Token Check}
    SEC -->|GESTELL_CI=true| BYPASS[Skip - CI Mode]
    SEC -->|Token Match| GRANT[Access Granted]
    SEC -->|Token Mismatch| DENY[Access Denied]

    EMB --> WD1[/workspace/Embedded]
    DASH --> WD2[/workspace/Dashboard]
    MOB --> WD3[/workspace/MobileApp]
```

---

## 🔐 Security and Access Control

To ensure that only authorized team members can access the development environments, a **token-based security layer** is implemented at the Docker entrypoint.

### How It Works

When a container starts, `docker-entrypoint.sh` executes before any user commands (e.g., `/bin/bash`):

1. It reads the environment variable `$GESTELL_TOKEN` from your `.env` file.
2. It computes the **SHA256 hash** of the provided token.
3. It compares this hash against the `$GESTELL_TOKEN_HASH` baked into the image at build time.
4. ✅ If they match → access is granted.
5. ❌ If they don't match → the container exits immediately with an "Access Denied" error.

### CI/CD Bypass

When running inside GitHub Actions, the environment variable `GESTELL_CI=true` is set. The entrypoint detects this flag and **bypasses** the token check, allowing automated pipelines to execute build and test commands seamlessly without needing the raw token.

### Configuring Your Local Token

A `.env` file should be placed in the root of your project. This file is listed in `.gitignore` to prevent leaking secrets:

```env
GESTELL_TOKEN=GestellSecure2026
```

The `docker-compose.yml` automatically reads this `.env` file and passes `GESTELL_TOKEN` to all containers.

---

## 📦 The Dockerfile (Unified Toolchain)

The custom Docker image is based on a lightweight Ubuntu distribution and installs the following toolchains in a single build:

| Team                   | Installed Tools                             | Purpose                                                         |
| :--------------------- | :------------------------------------------ | :-------------------------------------------------------------- |
| **Embedded**           | `make`, `avr-libc`, `gcc-avr`, `avrdude`    | Cross-compiling firmware and flashing the ATmega128 MCU         |
| **Embedded (Testing)** | `gcc`, `g++`, `lcov`, `cppcheck`            | Building host-based Unit Tests, coverage reports, MISRA analysis|
| **Dashboard**          | `nodejs`, `npm`, `curl`                     | Running and building the web dashboard interface                |
| **MobileApp**          | `flutter`, `dart`, `git`, `unzip`           | Building and testing the mobile application                     |

> **Note:** The image is built **once**. All three teams share the same base image to guarantee consistency across the entire project.

---

## ⚙️ Docker Compose Setup

The `docker-compose.yml` file defines **three distinct services**, allowing each team to spin up an environment perfectly tailored to their context while sharing the same unified image.

### 1. The `embedded` Service

- **Working Directory:** `/workspace/Embedded`
- **Volume Map:** Mounts the root project folder to `/workspace`, so code edits on your host machine instantly reflect inside the container.
- **Usage:** Ideal for running `make build`, `make test`, or `make flash`.

### 2. The `dashboard` Service

- **Working Directory:** `/workspace/Dashboard`
- **Ports:** Exposes web ports (e.g., `3000:3000` or `8080:8080`) so you can preview the dashboard on your host browser via `localhost`.
- **Usage:** Ideal for running `npm install` and `npm start`.

### 3. The `mobile` Service

- **Working Directory:** `/workspace/MobileApp`
- **Usage:** Ideal for running `flutter pub get` and `flutter test`.

---

## 💡 Usage Commands

### Building the Image

Before starting, build the image. This step **bakes the secure SHA256 hash** of your secret token into the image at build time:

```bash
docker compose build --build-arg BUILD_TOKEN=GestellSecure2026
```

### Starting an Environment

To open an interactive terminal (`/bin/bash`) for a specific team, use `docker compose run`:

**For the Embedded Team:**
```bash
docker compose run --rm embedded
```
*(You will automatically start inside the `Embedded/` directory, ready to run `make all`)*

**For the Dashboard Team:**
```bash
docker compose run --rm --service-ports dashboard
```
*(The `--service-ports` flag enables port forwarding for browser preview)*

**For the Mobile Team:**
```bash
docker compose run --rm mobile
```

### Cleaning Up

To stop all background containers and remove the network:
```bash
docker compose down
```

---

## ✅ Best Practices

- **Do NOT commit the `.env` file.** It contains the raw `GESTELL_TOKEN` and must remain local to each developer's machine.
- **Do NOT manually install packages inside the container.** If a team needs a new tool (e.g., Python, CMake), add it to the `Dockerfile` and rebuild the image. Containers are ephemeral — manual changes are lost upon exit.
- **Use the CI/CD Pipelines.** The Docker environment perfectly matches the GitHub Actions runners. If it builds locally in the container, it will build in the cloud.

---

<div align="center">

**Built with ❤️ by Gestell Team**

_Empowering the next generation of embedded systems engineers_

**Copyright © 2026 Gestell Company - All Rights Reserved**

</div>

[gestell-logo]: data:image/png;base64,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件。
