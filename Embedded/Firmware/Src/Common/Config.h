#ifndef _EMBEDDED_FIRMWARE_SRC_COMMON_CONFIG_H
#define _EMBEDDED_FIRMWARE_SRC_COMMON_CONFIG_H

/**
 * @file    Config.h
 * @brief   Configuration file based on Gestell Automotive Mini-ECU specifications.
 * @version 1.0
 */

/** @brief System Clock Frequency (16 MHz) for ATmega128 */
#ifndef FCpu
#define FCpu 16000000UL
#endif

/**
 * @defgroup McalConfig MCAL Layer Configurations
 * @{
 */
#define ModuleDioEnabled      1
#define ModuleAdcEnabled      1
#define ModuleTimer0Enabled   1
#define ModuleTimer2Enabled   1
#define ModuleUsart0Enabled   1
#define ModuleUsart1Enabled   1
#define ModuleExtiEnabled     1
/** @} */

/**
 * @defgroup HalConfig HAL Layer Configurations
 * @{
 */
#define ModuleLcdEnabled      1
#define ModuleLm35Enabled     1
#define ModuleFanEnabled      1
#define ModuleLedEnabled      1
#define ModuleBuzzerEnabled   1
#define ModuleHc05Enabled     1
#define ModuleEsp01Enabled    1
/** @} */

/**
 * @defgroup AppConfig OS & APP Layer Configurations
 * @{
 */
#define ModuleOsEnabled       1
#define ModuleFsmEnabled      1
#define ModuleFaultEnabled    1
#define ModuleDtcEnabled      1
/** @} */

/**
 * @defgroup Thresholds System Thresholds & Limits
 * @{
 */
#define EngineTempMax       90.0f   /**< Max Engine Temp for FAULT (C) */
#define EngineTempMin       40.0f   /**< Min Engine Temp for Fan (C) */
#define BatteryVoltageMax   16.0f   /**< Max Battery Voltage (V) */
#define BatteryVoltageMin   10.5f   /**< Min Battery Voltage (V) */
#define AdcMaxResolution    1024.0f /**< 10-bit ADC Resolution */
#define AdcReferenceVoltage 5.0f    /**< 5V AVCC Reference */
/** @} */

#endif// _EMBEDDED_FIRMWARE_SRC_COMMON_CONFIG_H
