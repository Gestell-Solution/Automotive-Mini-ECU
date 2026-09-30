# ==============================================================================
# @file       Makefile
# @brief      Professional Build System for Gestell Automotive Mini-ECU
# @author     Eng. Hesham (Email: Hesham4Ahmed@gmail.com)
# @company    Gestell Company
# @copyright  Copyright (c) 2026, Gestell Company. All rights reserved.
#
# Target MCU : ATmega128 @ 16 MHz
# Firmware   : AUTOSAR-Inspired 4-Layer (MCAL -> HAL -> OS -> APP)
# Source Root: Firmware/Src
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Project Configuration
# ------------------------------------------------------------------------------
PROJECT     := Gestell_Automotive_Mini_ECU
MCU         := atmega128
F_CPU       := 16000000UL

# Source tree root — all .c files discovered automatically under this path
SRC_DIR     := Firmware/Src
BUILD_DIR   := $(SRC_DIR)/build
BIN_DIR     := $(BUILD_DIR)/bin
OBJ_DIR     := $(BUILD_DIR)/obj

# ------------------------------------------------------------------------------
# 2. Toolchain & Output Verbosity
# ------------------------------------------------------------------------------
CROSS_COMPILE ?= avr-
CC       := $(CROSS_COMPILE)gcc
OBJCOPY  := $(CROSS_COMPILE)objcopy
OBJDUMP  := $(CROSS_COMPILE)objdump
SIZE     := $(CROSS_COMPILE)size

# Verbose mode: make V=1 to show full commands (default: quiet)
ifeq ($(V),1)
  Q :=
else
  Q := @
endif

# ANSI Colors for pretty output
COLOR_RESET  = \033[0m
COLOR_GREEN  = \033[32;1m
COLOR_BLUE   = \033[34;1m
COLOR_CYAN   = \033[36;1m
COLOR_YELLOW = \033[33;1m
COLOR_RED    = \033[31;1m

# ------------------------------------------------------------------------------
# 3. Compiler & Linker Flags
# ------------------------------------------------------------------------------
CFLAGS := \
    -mmcu=$(MCU)        \
    -DF_CPU=$(F_CPU)    \
    -O2                 \
    -Wall               \
    -Wextra             \
    -std=gnu99          \
    -g2 -gdwarf-2       \
    -ffunction-sections \
    -fdata-sections     \
    -MMD -MP

LDFLAGS := \
    -mmcu=$(MCU)        \
    -Wl,--gc-sections

# ------------------------------------------------------------------------------
# 4. Source & Include Auto-Discovery
#    Recursively finds ALL .c files under Embedded/Firmware/Src (all layers:
#    MCAL, HAL, OS, App) including the root main.c — no manual listing needed.
# ------------------------------------------------------------------------------
SRCS      := $(shell find $(SRC_DIR) -name '*.c')
INC_DIRS  := $(shell find $(SRC_DIR) -type d)
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

# Map .c -> .o preserving relative path under OBJ_DIR
OBJS := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRCS))
DEPS := $(OBJS:.o=.d)

# Include generated dependency files (enables incremental builds)
-include $(DEPS)

# ------------------------------------------------------------------------------
# 5. Unit Test Configuration (host GCC + Unity framework)
# ------------------------------------------------------------------------------
TEST_DIR       := Firmware/Test
TEST_BUILD_DIR := $(TEST_DIR)/build
TEST_BIN_DIR   := $(TEST_BUILD_DIR)/test_bin
COV_DIR        := $(TEST_BUILD_DIR)/coverage
UNITY_SRC      := $(TEST_DIR)/vendor/Unity/src/unity.c
MOCK_DIR       := $(TEST_DIR)/MockingFiles
SUPPORT_DIR    := $(TEST_DIR)/support

# NOTE: HOST_CC and GCOV must be the same GCC version to avoid .gcda mismatch
HOST_CC     := gcc-13
GCOV        := gcov-13
LCOV        := lcov
GENHTML     := genhtml
HOST_CFLAGS := -O0 -g3 -Wall -Wextra -std=gnu99 -DTEST --coverage

TEST_SRCS  := $(shell find $(TEST_DIR)/TestFiles -name 'test_*.c' 2>/dev/null)
TEST_EXECS := $(patsubst $(TEST_DIR)/TestFiles/%.c,$(TEST_BIN_DIR)/%.elf,$(TEST_SRCS))

TEST_INC_FLAGS := \
    -I$(TEST_DIR)/vendor/Unity/src \
    $(addprefix -I,$(shell find $(TEST_DIR)/TestFiles -type d 2>/dev/null)) \
    $(addprefix -I,$(shell find $(MOCK_DIR)           -type d 2>/dev/null)) \
    $(addprefix -I,$(shell find $(SUPPORT_DIR)        -type d 2>/dev/null)) \
    $(INC_FLAGS)

# ------------------------------------------------------------------------------
# 6. Phony Declarations & Default Target
# ------------------------------------------------------------------------------
.PHONY: all build flash test coverage misra size clean clean-build clean-test help

all: build
	@echo "$(COLOR_GREEN)============================================================$(COLOR_RESET)"
	@echo "$(COLOR_GREEN)  $(PROJECT) - Build Complete!$(COLOR_RESET)"
	@echo "$(COLOR_GREEN)============================================================$(COLOR_RESET)"

# ------------------------------------------------------------------------------
# 7. Firmware Build Targets
# ------------------------------------------------------------------------------
build: $(BIN_DIR)/$(PROJECT).hex $(BIN_DIR)/$(PROJECT).lss
	@echo "$(COLOR_CYAN)[SIZE]$(COLOR_RESET)  $(BIN_DIR)/$(PROJECT).elf"
	$(Q)$(SIZE) $(BIN_DIR)/$(PROJECT).elf

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(dir $@)
	@echo "$(COLOR_BLUE)[CC]$(COLOR_RESET)    $<"
	$(Q)$(CC) $(CFLAGS) $(INC_FLAGS) -c $< -o $@

$(BIN_DIR)/$(PROJECT).elf: $(OBJS)
	@mkdir -p $(dir $@)
	@echo "$(COLOR_CYAN)[LD]$(COLOR_RESET)    $@"
	$(Q)$(CC) $(LDFLAGS) -Wl,-Map=$(BIN_DIR)/$(PROJECT).map $^ -o $@

$(BIN_DIR)/$(PROJECT).hex: $(BIN_DIR)/$(PROJECT).elf
	@echo "$(COLOR_CYAN)[HEX]$(COLOR_RESET)   $@"
	$(Q)$(OBJCOPY) -O ihex -R .eeprom $< $@

$(BIN_DIR)/$(PROJECT).lss: $(BIN_DIR)/$(PROJECT).elf
	@echo "$(COLOR_CYAN)[LSS]$(COLOR_RESET)   $@"
	$(Q)$(OBJDUMP) -h -S $< > $@

# ------------------------------------------------------------------------------
# 8. Flash Target (avrdude)
#    Usage: make flash PORT=/dev/ttyUSB0 PROGRAMMER=arduino
# ------------------------------------------------------------------------------
PORT       ?= /dev/ttyUSB0
PROGRAMMER ?= arduino

flash: $(BIN_DIR)/$(PROJECT).hex
	@echo "$(COLOR_GREEN)[FLASH]$(COLOR_RESET) Uploading to $(MCU) via $(PROGRAMMER) on $(PORT)..."
	$(Q)avrdude -p $(MCU) -c $(PROGRAMMER) -P $(PORT) -b 115200 \
	    -U flash:w:$(BIN_DIR)/$(PROJECT).hex:i
	@echo "$(COLOR_GREEN)[FLASH]$(COLOR_RESET) Done."

# ------------------------------------------------------------------------------
# 9. Unit Test Target
# ------------------------------------------------------------------------------
test: $(TEST_EXECS)
	@echo "$(COLOR_GREEN)--- Running All Unit Tests ---$(COLOR_RESET)"
	$(Q)for t in $^; do \
	    echo "$(COLOR_CYAN)[RUN]$(COLOR_RESET)   $$t"; \
	    (cd `dirname $$t` && ./`basename $$t`) || true; \
	done
	@echo "$(COLOR_GREEN)--- Testing Complete ---$(COLOR_RESET)"

# Dynamic test compilation with smart source resolution (same strategy as SAMCS)
$(TEST_BIN_DIR)/%.elf: $(TEST_DIR)/TestFiles/%.c
	@mkdir -p $(dir $@)
	@echo "$(COLOR_BLUE)[TEST CC]$(COLOR_RESET) $<"
	$(Q)MODULE_NAME=$(subst test_,,$(notdir $<)); \
	MODULE_SRC=`find $(SRC_DIR) -name "$$MODULE_NAME" 2>/dev/null | grep -v "/build/" | head -n 1`; \
	if [ -z "$$MODULE_SRC" ]; then \
	    STEM=`basename "$$MODULE_NAME" .c`; \
	    BASE=`echo "$$STEM" | sed -E 's/_(Driver|Program|Test|Config|Cfg|Interface)$$//'`; \
	    MODULE_SRC=`find $(SRC_DIR) -name "$${BASE}_Program.c" -o -name "$${BASE}.c" -o -name "$${BASE}_*.c" 2>/dev/null | grep -v "/build/" | head -n 1`; \
	fi; \
	if [ -z "$$MODULE_SRC" ]; then \
	    echo "$(COLOR_YELLOW)[WARN]$(COLOR_RESET)  No source found in $(SRC_DIR) for $<"; \
	fi; \
	SUPPORT_SRCS=`find $(SUPPORT_DIR) -name '*.c' 2>/dev/null | tr '\n' ' '`; \
	MOCK_SRCS=`find $(MOCK_DIR) -name '*.c' 2>/dev/null | tr '\n' ' '`; \
	$(HOST_CC) $(HOST_CFLAGS) $(TEST_INC_FLAGS) $< $$MODULE_SRC $$SUPPORT_SRCS $$MOCK_SRCS $(UNITY_SRC) -o $@

# ------------------------------------------------------------------------------
# 10. Coverage Report (lcov + genhtml)
# ------------------------------------------------------------------------------
coverage: test
	@echo "$(COLOR_CYAN)[COVERAGE]$(COLOR_RESET) Collecting coverage data..."
	$(Q)mkdir -p $(COV_DIR)
	$(Q)$(LCOV) --capture \
	    --directory $(TEST_BIN_DIR) \
	    --output-file $(COV_DIR)/coverage.info \
	    --gcov-tool $(GCOV) \
	    --ignore-errors gcov,source
	$(Q)$(LCOV) --remove $(COV_DIR)/coverage.info \
	    '*/vendor/*' '*/Tests/*' \
	    --output-file $(COV_DIR)/coverage_filtered.info \
	    --ignore-errors gcov,source
	$(Q)if [ -s $(COV_DIR)/coverage_filtered.info ]; then \
	    $(GENHTML) $(COV_DIR)/coverage_filtered.info \
	        --output-directory $(COV_DIR)/html \
	        --title "$(PROJECT) Code Coverage" \
	        --legend --show-details; \
	    echo "$(COLOR_GREEN)[COVERAGE]$(COLOR_RESET) HTML report: $(COV_DIR)/html/index.html"; \
	else \
	    echo "$(COLOR_YELLOW)[COVERAGE]$(COLOR_RESET) No coverage data - ensure tests compile and run."; \
	fi

# ------------------------------------------------------------------------------
# 11. MISRA-C Static Analysis (cppcheck)
# ------------------------------------------------------------------------------
misra:
	@echo "$(COLOR_CYAN)[MISRA-C]$(COLOR_RESET) Running static analysis with cppcheck..."
	$(Q)mkdir -p $(BUILD_DIR)
	$(Q)cppcheck \
	    --enable=all \
	    --addon=misra \
	    --std=c99 \
	    $(INC_FLAGS) \
	    $(SRCS) 2>&1 | tee $(BUILD_DIR)/misra_report.txt || true
	@echo "$(COLOR_GREEN)[MISRA-C]$(COLOR_RESET) Report saved to $(BUILD_DIR)/misra_report.txt"

# ------------------------------------------------------------------------------
# 12. Memory Size Report
# ------------------------------------------------------------------------------
size: $(BIN_DIR)/$(PROJECT).elf
	@echo "$(COLOR_CYAN)======== Memory Usage: $(PROJECT) ($(MCU)) ========$(COLOR_RESET)"
	$(Q)$(SIZE) --format=avr --mcu=$(MCU) $<

# ------------------------------------------------------------------------------
# 13. Clean Targets
# ------------------------------------------------------------------------------
clean:
	@echo "$(COLOR_RED)[CLEAN]$(COLOR_RESET)  Removing all build and test artifacts..."
	$(Q)rm -rf $(BUILD_DIR) $(TEST_BUILD_DIR)
	@echo "$(COLOR_GREEN)[CLEAN]$(COLOR_RESET)  Done."

clean-build:
	@echo "$(COLOR_RED)[CLEAN]$(COLOR_RESET)  Removing firmware build artifacts..."
	$(Q)rm -rf $(BUILD_DIR)

clean-test:
	@echo "$(COLOR_RED)[CLEAN]$(COLOR_RESET)  Removing test artifacts..."
	$(Q)rm -rf $(TEST_BUILD_DIR)

# ------------------------------------------------------------------------------
# 14. Help Target
# ------------------------------------------------------------------------------
help:
	@echo "$(COLOR_CYAN)======================================================$(COLOR_RESET)"
	@echo "$(COLOR_CYAN)  Gestell Automotive Mini-ECU - Build System          $(COLOR_RESET)"
	@echo "$(COLOR_CYAN)  Authorized by Eng. Hesham - Gestell Company 2026    $(COLOR_RESET)"
	@echo "$(COLOR_CYAN)======================================================$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_GREEN)Firmware Targets:$(COLOR_RESET)"
	@echo "  make all          - Build the complete firmware (default)"
	@echo "  make build        - Compile + link -> .elf, .hex, .lss"
	@echo "  make flash        - Flash .hex to MCU via avrdude"
	@echo "                      Options: PORT=/dev/ttyUSB0  PROGRAMMER=arduino"
	@echo ""
	@echo "$(COLOR_GREEN)Testing & Quality Targets:$(COLOR_RESET)"
	@echo "  make test         - Compile & run all Unity unit tests"
	@echo "  make coverage     - Run tests + generate HTML coverage report"
	@echo "  make misra        - Run MISRA-C static analysis (cppcheck)"
	@echo "  make size         - Print detailed AVR memory usage report"
	@echo ""
	@echo "$(COLOR_GREEN)Clean Targets:$(COLOR_RESET)"
	@echo "  make clean        - Remove ALL build & test artifacts"
	@echo "  make clean-build  - Remove firmware build artifacts only"
	@echo "  make clean-test   - Remove test artifacts only"
	@echo ""
	@echo "$(COLOR_GREEN)Options:$(COLOR_RESET)"
	@echo "  V=1               - Verbose: show full compiler commands"
	@echo "  PORT=<dev>        - Serial port for flash target"
	@echo "  PROGRAMMER=<prg>  - avrdude programmer type"
