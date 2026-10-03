#ifndef _EMBEDDED_FIRMWARE_SRC_COMMON_DEFINITION_H
#define _EMBEDDED_FIRMWARE_SRC_COMMON_DEFINITION_H

/**
 * @file    Definition.h
 * @brief   Standard data types and common definitions for Gestell ECU.
 * @version 1.0
 */
#include <stdint.h>

typedef uint8_t Std_ReturnType;

#define EOk        ((Std_ReturnType)0x00U)
#define ENotOk     ((Std_ReturnType)0x01U)

#ifndef Null
#define Null        ((void *)0)
#endif

#define High        1
#define Low         0
#define True        1
#define False       0
#define Enable      1
#define Disable     0

/**
 * @brief ECU Finite State Machine (FSM) States
 */
typedef enum {
    StateOff = 0,
    StateStart,
    StateRun,
    StateDiagnostic,
    StateFault,
    StateSafeMode
} EcuState_t;

/**
 * @brief Diagnostic Trouble Codes (DTCs)
 */
typedef enum {
    DtcNone = 0,
    DtcF001OverTemp = 1,     /**< Engine Temp > 90 C */
    DtcF002BatteryFault = 2, /**< Voltage < 10.5 V or > 16 V */
    DtcF003SensorError = 3,  /**< ADC Saturated (0 or 1023) */
    DtcF004CommsTimeout = 4, /**< No BT/WiFi RX > 10 sec */
    DtcF005Watchdog = 5      /**< Watchdog Reset */
} DtcCode_t;

#endif// _EMBEDDED_FIRMWARE_SRC_COMMON_DEFINITION_H
