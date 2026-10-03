#ifndef _EMBEDDED_FIRMWARE_SRC_COMMON_MACROFUNCTION_H
#define _EMBEDDED_FIRMWARE_SRC_COMMON_MACROFUNCTION_H

/**
 * @file    MacroFunction.h
 * @brief   Common bit manipulation macros and utility functions.
 * @version 1.0
 */

/**
 * @defgroup BitMath Bit Manipulation Macros
 * @brief Macros for performing bitwise operations on registers and variables.
 * @{
 */

/**
 * @brief Sets a specific bit in a given register/variable.
 * @param Reg The register or variable to modify.
 * @param BitNo The bit position to set (0-31).
 */
#define SetBit(Reg, BitNo)       ((Reg) |= (1UL << (BitNo)))

/**
 * @brief Clears a specific bit in a given register/variable.
 * @param Reg The register or variable to modify.
 * @param BitNo The bit position to clear (0-31).
 */
#define ClearBit(Reg, BitNo)     ((Reg) &= ~(1UL << (BitNo)))

/**
 * @brief Toggles a specific bit in a given register/variable.
 * @param Reg The register or variable to modify.
 * @param BitNo The bit position to toggle (0-31).
 */
#define ToggleBit(Reg, BitNo)    ((Reg) ^= (1UL << (BitNo)))

/**
 * @brief Reads the value of a specific bit in a given register/variable.
 * @param Reg The register or variable to read from.
 * @param BitNo The bit position to read (0-31).
 * @return 1 if the bit is set, 0 if the bit is cleared.
 */
#define GetBit(Reg, BitNo)       (((Reg) >> (BitNo)) & 1UL)

/**
 * @brief Sets a multi-bit value in a register.
 * @param Reg The register to modify.
 * @param Mask The mask covering the bits to be set.
 * @param Val The value to set (must be shifted to the correct position).
 */
#define WriteReg(Reg, Mask, Val)   ((Reg) = (((Reg) & ~(Mask)) | (Val)))

/** @} */

#endif// _EMBEDDED_FIRMWARE_SRC_COMMON_MACROFUNCTION_H
