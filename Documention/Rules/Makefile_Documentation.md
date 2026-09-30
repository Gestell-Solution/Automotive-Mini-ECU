<div align="center">

![Gestell Company Logo][gestell-logo]

<br/><br/>

# 🔨 Makefile Documentation

**Embedded Build System**

_Developed by Gestell Company - Professional Embedded Solutions_

<br/>

![Status](https://img.shields.io/badge/Status-Draft-red) ![Category](https://img.shields.io/badge/Category-Embedded-blue) ![Version](https://img.shields.io/badge/Version-0.1-lightgrey) ![License](https://img.shields.io/badge/License-Gestell-orange) ![Type](https://img.shields.io/badge/Type-Build%20System-brightgreen)

</div>

---

<div align="center">

![Type](https://img.shields.io/badge/Type-Automation-blue)
![Status](https://img.shields.io/badge/Status-Standard-green)

**AVR Firmware Build, Test, Coverage & Static Analysis**

</div>

---

## 📋 Overview

This document provides a comprehensive guide to the professional build system (`Makefile`) implemented for the **Embedded Team** of the Gestell Automotive Mini-ECU project.

The `Makefile` is located at `Embedded/Makefile` and automates the entire embedded development lifecycle — from compilation and flashing to unit testing, coverage reporting, and MISRA-C static analysis.

> **Key Feature:** You do **not** need to manually list source files. The Makefile dynamically discovers all `.c` files and header directories in the source tree, eliminating the need for manual updates when adding new modules.

---

## 🏗️ Build System Architecture

```mermaid
graph TD
    MK[Embedded/Makefile] --> BD[Firmware Build]
    MK --> TD[Unit Test Build]
    MK --> SA[Static Analysis]

    BD --> SRCS["shell find Firmware/Src -name '*.c'"]
    BD --> INCS["shell find Firmware/Src -type d"]
    SRCS --> AVRCC[avr-gcc Cross Compiler]
    INCS --> AVRCC
    AVRCC --> ELF[.elf Binary]
    ELF --> HEX[.hex Flash Image]
    ELF --> LSS[.lss Disassembly]

    TD --> TESTS["shell find Firmware/Test -name 'test_*.c'"]
    TESTS --> HOSTCC[Host gcc-13 Compiler]
    HOSTCC --> BIN[Test Binary]
    BIN --> RUN[Execute Tests]
    RUN --> GCOV[gcov Coverage Data]
    GCOV --> HTML[HTML Coverage Report]

    SA --> CPP[cppcheck + misra.json]
    CPP --> RPT[misra_report.txt]
```

---

## 📁 Directory Structure Context

The build system expects the following relative paths within the `Embedded/` directory:

| Path                         | Description                                                    |
| :--------------------------- | :------------------------------------------------------------- |
| `Firmware/Src/`              | Root of all production C code (MCAL, HAL, OS, App, main.c)    |
| `Firmware/Test/`             | Root of all unit tests (Unity framework, mocks, test cases)    |
| `Firmware/Tools&Scripts/`    | Auxiliary tools (e.g., `misra.json` for cppcheck rules)       |
| `Firmware/Src/build/`        | Generated firmware artifacts (`.elf`, `.hex`, `.map`, `.lss`) |
| `Firmware/Test/build/`       | Generated test binaries and HTML coverage reports              |

---

## 🔧 Toolchain Requirements

All tools listed below are **pre-installed** in the provided Docker container. If running locally, ensure the following are available on your system:

| Tool                        | Purpose                                                      |
| :-------------------------- | :----------------------------------------------------------- |
| `make`                      | Build automation orchestrator                                |
| `avr-gcc` / `avr-libc`      | Cross-compiling C code for the ATmega128 MCU                 |
| `avrdude`                   | Flashing the `.hex` file to the physical microcontroller     |
| `gcc-13`                    | Host compiler for building and running Unity Unit Tests      |
| `cppcheck`                  | MISRA-C static code analysis                                 |
| `gcov-13` / `lcov` / `genhtml` | Code coverage tracking and HTML report generation         |

---

## 🎯 Make Targets

Run all targets from inside the `Embedded/` directory using `make <target>`.

### 1. Firmware Build Targets

| Target       | Description                                                                                                          |
| :----------- | :------------------------------------------------------------------------------------------------------------------- |
| `make all`   | Default target. Alias for `make build`. Compiles the entire firmware.                                                |
| `make build` | Compiles all source files → links into `.elf` → generates `.hex` (flash image) and `.lss` (disassembly).            |
| `make flash` | Uploads the compiled `.hex` to the ATmega128 via `avrdude`. Override with `PORT` and `PROGRAMMER` as needed.        |
| `make size`  | Prints a detailed Flash / EEPROM / RAM memory usage report for the compiled firmware.                                |

---

### 2. Testing & Quality Targets

| Target          | Description                                                                                                                           |
| :-------------- | :------------------------------------------------------------------------------------------------------------------------------------ |
| `make test`     | Discovers all `test_*.c` files, resolves their production dependencies, compiles with Host GCC, and executes all tests.               |
| `make coverage` | Runs `make test`, collects `gcov` data, and generates a visual HTML report using `lcov` + `genhtml` at `Firmware/Test/build/coverage/html/index.html`. |
| `make misra`    | Runs MISRA-C static analysis on the production codebase using `cppcheck`. Saves the report to `Firmware/Src/build/misra_report.txt`.  |

---

### 3. Clean Targets

| Target             | Description                                                                      |
| :----------------- | :------------------------------------------------------------------------------- |
| `make clean`       | Deletes **all** generated build artifacts (both firmware and test builds).       |
| `make clean-build` | Deletes only the firmware build artifacts (`Firmware/Src/build/`).               |
| `make clean-test`  | Deletes only the test build artifacts and coverage reports (`Firmware/Test/build/`). |

---

### 4. Helper Targets

| Target       | Description                                                    |
| :----------- | :------------------------------------------------------------- |
| `make help`  | Prints an interactive cheat sheet of all available targets.   |

---

## ⚙️ Advanced Configuration

### 1. Auto-Discovery Mechanism

Instead of modifying the Makefile every time you add a new `.c` file or module folder, the Makefile uses shell commands to find them automatically:

```makefile
SRCS     := $(shell find $(SRC_DIR) -name '*.c')
INC_DIRS := $(shell find $(SRC_DIR) -type d)
```

Every directory under `Firmware/Src/` is automatically added as an include path (`-I`), so there is **no need to update header search paths manually**.

---

### 2. Unit Test Smart Resolution

When running `make test`, the Makefile parses each test file name (e.g., `test_Dio.c`), strips the `test_` prefix, and recursively searches `Firmware/Src/` to find the matching production file (`Dio.c` or `Dio_Program.c`). This ensures tests are always compiled against the correct source.

---

### 3. Incremental Builds

The Makefile automatically generates `.d` dependency files during compilation:

```makefile
-include $(DEPS)
```

This ensures that if you modify a `.h` header file, **only** the `.c` files that include it will be recompiled, saving significant build time during development.

---

### 4. Verbose Mode

By default, the Makefile suppresses long compiler commands and prints beautifully formatted, color-coded output (e.g., `[CC] main.c`). To see the exact GCC commands for debugging:

```bash
make build V=1
make test V=1
```

---

### 5. Flash Customization

The `flash` target defaults to Arduino as the programmer and `/dev/ttyUSB0` as the port. Override these inline:

```bash
make flash PORT=/dev/ttyUSB1 PROGRAMMER=usbasp
make flash PORT=COM3 PROGRAMMER=avrispmkII
```

---

## 📂 Output Artifacts Locations

After running the respective commands, find your generated files here:

| Artifact              | Path                                                        |
| :-------------------- | :---------------------------------------------------------- |
| **Flash Image**       | `Firmware/Src/build/bin/Gestell_Automotive_Mini_ECU.hex`   |
| **Disassembly**       | `Firmware/Src/build/bin/Gestell_Automotive_Mini_ECU.lss`   |
| **Coverage Report**   | `Firmware/Test/build/coverage/html/index.html`             |
| **MISRA Report**      | `Firmware/Src/build/misra_report.txt`                      |

---

<div align="center">

**Built with ❤️ by Gestell Team**

_Empowering the next generation of embedded systems engineers_

**Copyright © 2026 Gestell Company - All Rights Reserved**

</div>

[gestell-logo]: data:image/png;base64,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件。
