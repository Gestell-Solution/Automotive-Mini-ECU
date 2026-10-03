# 🚗 Gestell Automotive Mini-ECU — Complete UML Diagrams (Embedded Part)

> **Project:** Gestell Automotive Mini-ECU  
> **MCU:** ATmega128 AVR @ 16 MHz  
> **Architecture:** AUTOSAR-Inspired 4-Layer (MCAL → HAL → OS → APP)  
> **Document:** Full System UML Reference  

---

## 📋 Table of Contents

1. [System Context Diagram](#1-system-context-diagram)
2. [Package / Component Diagram](#2-package--component-diagram)
3. [Class Diagram — Full System](#3-class-diagram--full-system)
4. [ECU Finite State Machine (State Diagram)](#4-ecu-finite-state-machine-state-diagram)
5. [Sequence Diagram — Boot & Self-Test](#5-sequence-diagram--boot--self-test)
6. [Sequence Diagram — RUN Mode Normal Operation](#6-sequence-diagram--run-mode-normal-operation)
7. [Sequence Diagram — Fault Detection & SAFE MODE](#7-sequence-diagram--fault-detection--safe-mode)
8. [Sequence Diagram — Bluetooth Command Processing](#8-sequence-diagram--bluetooth-command-processing)
9. [Sequence Diagram — WiFi Telemetry Broadcast](#9-sequence-diagram--wifi-telemetry-broadcast)
10. [Activity Diagram — Main Scheduler Loop](#10-activity-diagram--main-scheduler-loop)
11. [Activity Diagram — Fault Detection Pipeline](#11-activity-diagram--fault-detection-pipeline)
12. [Communication / Deployment Diagram](#12-communication--deployment-diagram)
13. [Data Flow Diagram (DFD)](#13-data-flow-diagram-dfd)
14. [Layer Dependency Diagram](#14-layer-dependency-diagram)
15. [Timing Diagram — Periodic Tasks](#15-timing-diagram--periodic-tasks)

---

## 1. System Context Diagram

> Shows the complete ECU system and all external actors/interfaces.

```mermaid
C4Context
    title Gestell Automotive Mini-ECU — System Context

    Person(driver, "🧑 Vehicle Driver", "Operates ignition button,\nmonitors LCD cockpit")
    Person(engineer, "👨‍💻 Service Engineer", "Uses Mobile App & Dashboard\nfor diagnostics & DTC management")

    System_Boundary(ecu_sys, "Gestell Automotive Mini-ECU System") {
        System(ecu, "ATmega128 ECU Firmware", "4-Layer AUTOSAR firmware:\nFSM, Fault Detection, Telemetry,\nScheduler, ADC, PWM, USART, EXTI")
    }

    System_Ext(mobile_app, "📱 Gestell Mobile App", "Bluetooth OBD-II Diagnostic\nScanner — 6 screens")
    System_Ext(web_dash, "🌐 Gestell Web Dashboard", "5-page TCP/JSON telemetry\nmonitoring & control centre")
    System_Ext(bt_module, "HC-05 Bluetooth Module", "USART0 SPP bridge\n9600 bps")
    System_Ext(wifi_module, "ESP-01 Wi-Fi Module", "USART1 TCP Server :80\n115200 bps")

    Rel(driver, ecu, "Ignition Button (INT4)\nFault Reset Button (INT5)")
    Rel(ecu, driver, "LCD 20x4 Cockpit Display\nLEDs + Buzzer feedback")
    Rel(engineer, mobile_app, "Uses")
    Rel(engineer, web_dash, "Uses (Browser)")
    Rel(ecu, bt_module, "USART0 TX/RX\n$TELE frames")
    Rel(bt_module, mobile_app, "Bluetooth SPP")
    Rel(ecu, wifi_module, "USART1 TX/RX\nAT Commands + JSON")
    Rel(wifi_module, web_dash, "TCP Port 80\nJSON Telemetry")
```

---

## 2. Package / Component Diagram

> Shows all firmware layers, modules, and their dependencies.

```mermaid
graph TB
    subgraph HW["⚙️ ATmega128 Hardware"]
        direction LR
        PORTF["PORTF\nADC0/ADC1"]
        PORTB["PORTB\nOC0/PB4"]
        PORTC["PORTC\nLCD Bus"]
        PORTD["PORTD\nUSART1 + LEDs"]
        PORTE["PORTE\nUSART0 + EXTIs"]
    end

    subgraph MCAL["🔌 MCAL Layer — Microcontroller Abstraction"]
        direction TB
        DIO["DIO Driver\n• GPIO_Init()\n• GPIO_Write()\n• GPIO_Read()\n• GPIO_Toggle()"]
        ADC_DRV["ADC Driver\n• ADC_Init()\n• ADC_StartConversion()\n• ADC_GetResult()\n• ADC_SetChannel()"]
        TIMER["Timer0/2 PWM Driver\n• Timer0_Init()\n• Timer0_SetDuty()\n• Timer2_Init()\n• Timer2_SetFreq()"]
        USART0["USART0 Driver\n• USART0_Init()\n• USART0_SendByte()\n• USART0_RxISR()\n• USART0_TxISR()"]
        USART1["USART1 Driver\n• USART1_Init()\n• USART1_SendByte()\n• USART1_RxISR()\n• USART1_TxISR()"]
        EXTI["EXTI Driver\n• EXTI_Init()\n• INT4_ISR()\n• INT5_ISR()"]
    end

    subgraph HAL["🔧 HAL Layer — Hardware Abstraction"]
        direction TB
        LCD_HAL["LCD 20x4 HAL\n• LCD_Init()\n• LCD_WriteString()\n• LCD_SetCursor()\n• LCD_Clear()\n• LCD_DirtyUpdate()"]
        SENSORS_HAL["Sensors HAL\n• Sensor_ReadTemp()\n• Sensor_ReadBattVolt()\n• Sensor_IsDisconnected()\n• Sensor_ConvertADC()"]
        ACT_HAL["Actuators HAL\n• Fan_SetDuty()\n• Fan_Stop()\n• LED_Set()\n• LED_Blink()\n• Buzzer_On()\n• Buzzer_Off()"]
        BT_HAL["Bluetooth HAL (HC-05)\n• BT_Init()\n• BT_SendFrame()\n• BT_ParseFrame()\n• BT_GetCommand()\n• BT_CheckTimeout()"]
        WIFI_HAL["WiFi HAL (ESP-01)\n• WiFi_Init()\n• WiFi_SendAT()\n• WiFi_JoinNetwork()\n• WiFi_BuildJSON()\n• WiFi_Transmit()\n• WiFi_Reconnect()"]
    end

    subgraph OS["⚡ OS / Service Layer"]
        direction TB
        SCHED["SysTick Scheduler\n• Scheduler_Init()\n• Scheduler_Run()\n• Scheduler_AddTask()\n• Scheduler_Tick()\n• Uptime_Get()"]
        RINGBUF["Ring Buffer Manager\n• RingBuf_Init()\n• RingBuf_Push()\n• RingBuf_Pop()\n• RingBuf_IsEmpty()\n• RingBuf_IsFull()"]
        EVTFLG["Event Flag Queue\n• Event_Set()\n• Event_Clear()\n• Event_IsPending()"]
        WDG["Watchdog Handler\n• WDT_Init()\n• WDT_Reset()\n• WDT_Trigger()"]
    end

    subgraph APP["🧠 APP Layer — ECU Core Logic"]
        direction TB
        FSM["ECU FSM Core\n• FSM_Init()\n• FSM_Run()\n• FSM_Transition()\n• FSM_GetState()\n• FSM_HandleIgnition()"]
        FAULT["Fault & DTC Manager\n• Fault_Monitor()\n• Fault_Detect()\n• DTC_Log()\n• DTC_Clear()\n• DTC_ReadAll()\n• EEPROM_Store()"]
        TELE["Telemetry Manager\n• Tele_BuildBTFrame()\n• Tele_BuildWiFiJSON()\n• Tele_Broadcast()\n• Tele_ParseCommand()"]
        LCD_APP["LCD Cockpit Renderer\n• LCD_RenderAll()\n• LCD_RenderLine1()\n• LCD_RenderLine2()\n• LCD_RenderLine3()\n• LCD_RenderLine4()\n• LCD_BootSequence()"]
    end

    subgraph COMMON["📦 Common / Shared"]
        direction LR
        CONFIG["Config.h\n• F_CPU\n• Thresholds\n• Baud Rates"]
        DEFS["Definition.h\n• uint8_t types\n• bool types\n• Enums"]
        MACROS["MacroFunction.h\n• SET_BIT()\n• CLR_BIT()\n• GET_BIT()"]
    end

    %% Layer dependencies (bottom-up)
    HW --> MCAL
    MCAL --> HAL
    HAL --> OS
    OS --> APP
    COMMON -.-> MCAL
    COMMON -.-> HAL
    COMMON -.-> OS
    COMMON -.-> APP

    %% Internal dependencies
    ADC_DRV --> SENSORS_HAL
    DIO --> LCD_HAL
    DIO --> ACT_HAL
    TIMER --> ACT_HAL
    USART0 --> BT_HAL
    USART1 --> WIFI_HAL
    EXTI --> FSM
    RINGBUF --> BT_HAL
    RINGBUF --> WIFI_HAL
    SCHED --> FSM
    SCHED --> FAULT
    SCHED --> TELE
    SCHED --> LCD_APP
    EVTFLG --> FSM
    FSM --> FAULT
    FSM --> TELE
    FSM --> LCD_APP
    FAULT --> TELE
    SENSORS_HAL --> FAULT
    ACT_HAL --> FAULT

    style MCAL fill:#1a1a2e,stroke:#e94560,color:#fff
    style HAL fill:#16213e,stroke:#0f3460,color:#fff
    style OS fill:#0f3460,stroke:#533483,color:#fff
    style APP fill:#533483,stroke:#e94560,color:#fff
    style COMMON fill:#2d3748,stroke:#718096,color:#fff
    style HW fill:#1a202c,stroke:#4a5568,color:#fff
```

---

## 3. Class Diagram — Full System

> Full system class diagram showing all modules, data structures, and relationships.

```mermaid
classDiagram
    direction TB

    %% ─── COMMON ────────────────────────────────────────────────
    class Config {
        <<header>>
        +F_CPU : uint32_t = 16000000
        +TEMP_MAX : uint8_t = 90
        +TEMP_MIN : uint8_t = 40
        +TEMP_HYSTERESIS : uint8_t = 75
        +BATT_MIN_V : float = 10.5
        +BATT_MAX_V : float = 16.0
        +BATT_NOM_LOW : float = 12.0
        +BATT_NOM_HIGH : float = 14.5
        +USART0_BAUD : uint32_t = 9600
        +USART1_BAUD : uint32_t = 115200
        +ADC_PRESCALER : uint8_t = 128
        +SCHEDULER_TICK_MS : uint8_t = 10
        +COMMS_TIMEOUT_S : uint8_t = 10
        +RING_BUF_SIZE : uint8_t = 64
        +DTC_MAX_STORED : uint8_t = 16
        +WIFI_RETRY_MAX : uint8_t = 3
    }

    class Definition {
        <<header>>
        <<typedef>> uint8_t
        <<typedef>> uint16_t
        <<typedef>> uint32_t
        <<typedef>> int8_t
        <<typedef>> bool
        <<enum>> ECU_State_t
        <<enum>> DTC_Code_t
        <<enum>> LED_ID_t
        <<enum>> BT_Command_t
        <<enum>> Sensor_ID_t
    }

    class ECU_State_t {
        <<enumeration>>
        STATE_OFF = 0
        STATE_START = 1
        STATE_RUN = 2
        STATE_DIAGNOSTIC = 3
        STATE_FAULT = 4
        STATE_SAFE_MODE = 5
    }

    class DTC_Code_t {
        <<enumeration>>
        DTC_NONE = 0x00
        DTC_F001_OVER_TEMP = 0x01
        DTC_F002_BATT_VOLT = 0x02
        DTC_F003_SENSOR_DISC = 0x03
        DTC_F004_COMMS_TIMEOUT = 0x04
        DTC_F005_PWM_FEEDBACK = 0x05
    }

    class LED_ID_t {
        <<enumeration>>
        LED_POWER_GREEN = 0
        LED_STATUS_BLUE = 1
        LED_WARNING_YELLOW = 2
    }

    class BT_Command_t {
        <<enumeration>>
        CMD_NONE = 0
        CMD_IGN_START = 1
        CMD_IGN_STOP = 2
        CMD_READ_DTC = 3
        CMD_CLEAR_DTC = 4
        CMD_DIAG_REQ = 5
    }

    %% ─── MCAL Layer ─────────────────────────────────────────────
    class DIO_Driver {
        <<module>>
        -DDRA : register
        -DDRB : register
        -DDRC : register
        -DDRD : register
        -DDRE : register
        -DDRF : register
        +DIO_Init(port, pin, direction) void
        +DIO_WritePin(port, pin, value) void
        +DIO_ReadPin(port, pin) uint8_t
        +DIO_TogglePin(port, pin) void
        +DIO_WritePort(port, value) void
        +DIO_ReadPort(port) uint8_t
    }

    class ADC_Driver {
        <<module>>
        -ADMUX : register
        -ADCSRA : register
        -ADCL : register
        -ADCH : register
        +ADC_Init() void
        +ADC_SetChannel(channel) void
        +ADC_StartConversion() void
        +ADC_GetResult() uint16_t
        +ADC_ReadBlocking(channel) uint16_t
    }

    class Timer0_Driver {
        <<module>>
        -TCCR0 : register
        -OCR0 : register
        -TCNT0 : register
        +Timer0_Init_FastPWM() void
        +Timer0_SetDutyCycle(ocr_value) void
        +Timer0_Stop() void
        +Timer0_GetDuty() uint8_t
    }

    class Timer2_Driver {
        <<module>>
        -TCCR2 : register
        -OCR2 : register
        +Timer2_Init_SysTick() void
        +Timer2_ISR() void
        +Timer2_GetTick() uint32_t
    }

    class USART0_Driver {
        <<module>>
        -UBRRH0 : register = 0x00
        -UBRRL0 : register = 0x67
        -UCSR0B : register = 0xD8
        -UCSR0C : register = 0x86
        -rxBuffer : RingBuffer_t
        -txBuffer : RingBuffer_t
        +USART0_Init() void
        +USART0_SendByte(data) void
        +USART0_SendString(str) void
        +USART0_ReceiveByte() uint8_t
        +USART0_DataAvailable() bool
        +ISR_USART0_RX() void
        +ISR_USART0_TX() void
    }

    class USART1_Driver {
        <<module>>
        -UBRRH1 : register = 0x00
        -UBRRL1 : register = 0x08
        -UCSR1B : register = 0xD8
        -rxBuffer : RingBuffer_t
        -txBuffer : RingBuffer_t
        +USART1_Init() void
        +USART1_SendByte(data) void
        +USART1_SendString(str) void
        +USART1_ReceiveByte() uint8_t
        +USART1_DataAvailable() bool
        +ISR_USART1_RX() void
        +ISR_USART1_TX() void
    }

    class EXTI_Driver {
        <<module>>
        -EICRB : register
        -EIMSK : register
        -ignitionFlag : volatile bool
        -resetFlag : volatile bool
        +EXTI_Init() void
        +EXTI_Enable(int_id) void
        +EXTI_Disable(int_id) void
        +ISR_INT4_Ignition() void
        +ISR_INT5_FaultReset() void
        +EXTI_GetIgnitionFlag() bool
        +EXTI_GetResetFlag() bool
        +EXTI_ClearFlags() void
    }

    %% ─── HAL Layer ─────────────────────────────────────────────
    class LCD_HAL {
        <<module>>
        -RS_PIN : PC0
        -EN_PIN : PC2
        -D4_PIN : PC4 .. PC7
        -dirtyFlags : uint8_t[4]
        -lineCache : char[4][21]
        +LCD_Init() void
        +LCD_Clear() void
        +LCD_SetCursor(row, col) void
        +LCD_WriteChar(c) void
        +LCD_WriteString(str) void
        +LCD_WriteCommand(cmd) void
        +LCD_WriteNibble(nibble) void
        +LCD_EnablePulse() void
        +LCD_UpdateDirtyLines() void
        +LCD_SetDirty(line) void
    }

    class Sensors_HAL {
        <<module>>
        -ADC_CH_TEMP : uint8_t = 0
        -ADC_CH_BATT : uint8_t = 1
        -lastTempRaw : uint16_t
        -lastBattRaw : uint16_t
        -discCount : uint8_t[2]
        +Sensor_Init() void
        +Sensor_ReadTemperature() float
        +Sensor_ReadBatteryVoltage() float
        +Sensor_ConvertTempADC(raw) float
        +Sensor_ConvertBattADC(raw) float
        +Sensor_IsDisconnected(ch) bool
        +Sensor_GetLastTemp() float
        +Sensor_GetLastBatt() float
    }

    class Actuators_HAL {
        <<module>>
        -FAN_PIN : PB4
        -LED_PWR : PD4
        -LED_STS : PD5
        -LED_WRN : PD6
        -BUZZER : PD7
        -fanDuty : uint8_t
        -buzzerActive : bool
        +Actuators_Init() void
        +Fan_SetDuty(percent) void
        +Fan_Stop() void
        +Fan_GetDuty() uint8_t
        +LED_Set(id, state) void
        +LED_Blink(id, freq_hz) void
        +LED_StopBlink(id) void
        +Buzzer_On(freq_hz) void
        +Buzzer_Off() void
        +Actuators_EmergencyCutoff() void
    }

    class BT_HAL {
        <<module>>
        -frameBuffer : char[128]
        -rxState : uint8_t
        -lastRxTime : uint32_t
        -connected : bool
        +BT_Init() void
        +BT_SendTelemetryFrame(temp, batt, pwm, dtc) void
        +BT_SendDTCReport(dtcList) void
        +BT_SendDiagReport(report) void
        +BT_ParseIncomingByte(byte) BT_Command_t
        +BT_GetParsedCommand() BT_Command_t
        +BT_GetCommandParam() char*
        +BT_ComputeXORChecksum(frame) uint8_t
        +BT_IsConnected() bool
        +BT_CheckTimeout() bool
    }

    class WiFi_HAL {
        <<module>>
        -atBuffer : char[256]
        -jsonBuffer : char[512]
        -retryCount : uint8_t
        -connected : bool
        -tcpClient : uint8_t
        +WiFi_Init() void
        +WiFi_SendAT(cmd) bool
        +WiFi_WaitResponse(expected, timeout_ms) bool
        +WiFi_JoinNetwork(ssid, pass) bool
        +WiFi_StartTCPServer(port) bool
        +WiFi_BuildJSONPayload(data) void
        +WiFi_TransmitJSON() void
        +WiFi_Reconnect() bool
        +WiFi_IsConnected() bool
        +WiFi_CheckTimeout() bool
        +WiFi_ParseIncomingAT() void
    }

    %% ─── OS Layer ───────────────────────────────────────────────
    class RingBuffer_t {
        <<struct>>
        +buffer : uint8_t[64]
        +head : uint8_t
        +tail : uint8_t
        +count : uint8_t
        +capacity : uint8_t
    }

    class SchedulerTask_t {
        <<struct>>
        +taskFunc : FuncPtr
        +periodMs : uint16_t
        +lastRunMs : uint32_t
        +enabled : bool
        +name : char[16]
    }

    class Scheduler {
        <<module>>
        -taskList : SchedulerTask_t[8]
        -taskCount : uint8_t
        -sysTick_ms : uint32_t
        -uptimeSeconds : uint32_t
        +Scheduler_Init() void
        +Scheduler_AddTask(func, period_ms, name) void
        +Scheduler_Run() void
        +Scheduler_Tick_ISR() void
        +Scheduler_GetUptime_ms() uint32_t
        +Scheduler_GetUptime_s() uint32_t
        +Scheduler_EnableTask(name) void
        +Scheduler_DisableTask(name) void
    }

    class EventQueue {
        <<module>>
        -ignitionEvent : volatile bool
        -resetEvent : volatile bool
        -diagReqEvent : volatile bool
        -btCmdEvent : volatile bool
        -wifiCmdEvent : volatile bool
        +Event_SetIgnition() void
        +Event_SetReset() void
        +Event_SetDiagReq() void
        +Event_GetIgnition() bool
        +Event_GetReset() bool
        +Event_GetDiagReq() bool
        +Event_ClearAll() void
    }

    class WatchdogHandler {
        <<module>>
        +WDT_Enable(timeout_ms) void
        +WDT_Reset() void
        +WDT_Disable() void
        +WDT_ISR() void
    }

    %% ─── APP Layer ──────────────────────────────────────────────
    class ECUData_t {
        <<struct>>
        +state : ECU_State_t
        +ignitionOn : bool
        +tempC : float
        +battV : float
        +fanPwmPct : uint8_t
        +activeDTC : DTC_Code_t
        +dtcList : DTC_Code_t[16]
        +dtcCount : uint8_t
        +btConnected : bool
        +wifiConnected : bool
        +uptimeSeconds : uint32_t
        +lastBtRxTime : uint32_t
        +lastWifiRxTime : uint32_t
    }

    class FSM_Core {
        <<module>>
        -ecuData : ECUData_t
        -currentState : ECU_State_t
        -prevState : ECU_State_t
        +FSM_Init() void
        +FSM_Run() void
        +FSM_Transition(newState) void
        +FSM_GetState() ECU_State_t
        +FSM_HandleIgnitionON() void
        +FSM_HandleIgnitionOFF() void
        +FSM_RunSelfTest() bool
        +FSM_EnterRUN() void
        +FSM_EnterFAULT() void
        +FSM_EnterSafeMode() void
        +FSM_EnterDiagnostic() void
        +FSM_HandleStateOFF() void
        +FSM_HandleStateSTART() void
        +FSM_HandleStateRUN() void
        +FSM_HandleStateDIAG() void
        +FSM_HandleStateFAULT() void
        +FSM_HandleStateSAFEMODE() void
    }

    class FaultManager {
        <<module>>
        -faultActive : bool
        -activeDTC : DTC_Code_t
        -sensorDiscCount : uint8_t[2]
        -btTimeoutCounter : uint16_t
        -wifiTimeoutCounter : uint16_t
        +Fault_Init() void
        +Fault_Monitor() void
        +Fault_CheckOverTemp(temp) bool
        +Fault_CheckBattVolt(volt) bool
        +Fault_CheckSensorDisc(ch) bool
        +Fault_CheckCommsTimeout() bool
        +Fault_TriggerFault(dtc) void
        +Fault_IsFaultActive() bool
        +Fault_GetActiveDTC() DTC_Code_t
        +Fault_ClearFault(dtc) bool
        +Fault_ExecuteFailSafe() void
    }

    class DTC_Manager {
        <<module>>
        -eepromDTCLog : DTC_Record_t[16]
        -dtcCount : uint8_t
        +DTC_Log(code, timestamp) void
        +DTC_Clear(code) bool
        +DTC_ClearAll() void
        +DTC_GetAll(outList) uint8_t
        +DTC_GetCount() uint8_t
        +DTC_IsStored(code) bool
        +DTC_LoadFromEEPROM() void
        +DTC_SaveToEEPROM() void
        +DTC_GetDescription(code) char*
    }

    class DTC_Record_t {
        <<struct>>
        +code : DTC_Code_t
        +timestamp_s : uint32_t
        +severity : uint8_t
        +cleared : bool
    }

    class TelemetryManager {
        <<module>>
        -btFrameBuffer : char[128]
        -jsonBuffer : char[512]
        -lastBroadcastTime : uint32_t
        +Tele_Init() void
        +Tele_Task_500ms() void
        +Tele_BuildBTFrame(data, outFrame) void
        +Tele_BuildWiFiJSON(data, outJSON) void
        +Tele_BroadcastBT(data) void
        +Tele_BroadcastWiFi(data) void
        +Tele_ParseBTCommand(frame) BT_Command_t
        +Tele_ParseWiFiCommand(frame) BT_Command_t
        +Tele_ExecuteCommand(cmd, param) void
    }

    class LCD_Renderer {
        <<module>>
        -line1 : char[21]
        -line2 : char[21]
        -line3 : char[21]
        -line4 : char[21]
        +LCD_RenderTask_200ms() void
        +LCD_RenderLine1_State(state, ignition) void
        +LCD_RenderLine2_Sensors(temp, batt) void
        +LCD_RenderLine3_Actuators(pwm, dtc) void
        +LCD_RenderLine4_Comms(btOk, wifiOk) void
        +LCD_BootSequence() void
        +LCD_ShowFaultScreen(dtc) void
    }

    %% ─── Relationships ──────────────────────────────────────────
    %% MCAL uses hardware
    DIO_Driver --> Definition
    ADC_Driver --> Definition
    Timer0_Driver --> Definition
    USART0_Driver --> RingBuffer_t
    USART1_Driver --> RingBuffer_t
    EXTI_Driver --> EventQueue

    %% HAL uses MCAL
    LCD_HAL --> DIO_Driver
    Sensors_HAL --> ADC_Driver
    Actuators_HAL --> DIO_Driver
    Actuators_HAL --> Timer0_Driver
    BT_HAL --> USART0_Driver
    WiFi_HAL --> USART1_Driver

    %% OS uses HAL
    Scheduler --> Timer2_Driver
    Scheduler "1" *-- "0..8" SchedulerTask_t

    %% APP uses OS + HAL
    FSM_Core --> Scheduler
    FSM_Core --> EventQueue
    FSM_Core --> Sensors_HAL
    FSM_Core --> Actuators_HAL
    FSM_Core --> FaultManager
    FSM_Core --> TelemetryManager
    FSM_Core --> LCD_Renderer
    FSM_Core "1" *-- "1" ECUData_t

    FaultManager --> Sensors_HAL
    FaultManager --> Actuators_HAL
    FaultManager --> DTC_Manager
    FaultManager --> ECUData_t

    DTC_Manager "1" *-- "0..16" DTC_Record_t

    TelemetryManager --> BT_HAL
    TelemetryManager --> WiFi_HAL
    TelemetryManager --> ECUData_t

    LCD_Renderer --> LCD_HAL
    LCD_Renderer --> ECUData_t

    ECU_State_t --> Definition
    DTC_Code_t --> Definition
    LED_ID_t --> Definition
    BT_Command_t --> Definition
```

---

## 4. ECU Finite State Machine (State Diagram)

> Formal UML State Machine with all states, transitions, guards, entry/exit actions.

```mermaid
stateDiagram-v2
    direction LR

    [*] --> OFF : Power ON

    state OFF {
        direction TB
        [*] --> WaitingIgnition
        WaitingIgnition : Waiting for Ignition Trigger
        note right of WaitingIgnition
            Entry: Disable all actuators
            Fan=OFF, LEDs=Heartbeat only
            Buzzer=OFF
            LCD: "MODE: OFF"
        end note
    }

    state START {
        direction TB
        [*] --> HardwareInit
        HardwareInit --> SelfTest : Init complete
        SelfTest --> SensorValidation : ADC/LCD/USART OK
        SensorValidation --> [*] : Validation result

        HardwareInit : Init GPIO, USART, ADC, Timer, EXTI
        SelfTest : Test ADC channels, LCD response,\nHC-05 AT ACK, ESP-01 AT response
        SensorValidation : Read ADC0 + ADC1,\nCheck within valid range
        note right of SelfTest
            Entry: Power LED heartbeat blink
            LCD: "MODE: START"
            Max boot time: 500ms
        end note
    }

    state RUN {
        direction TB
        [*] --> ADC_Sampling
        ADC_Sampling --> PWM_Control : Every 100ms
        PWM_Control --> LCD_Refresh : Every 200ms
        LCD_Refresh --> Telemetry : Every 500ms
        Telemetry --> CommandCheck : Every 10ms
        CommandCheck --> ADC_Sampling : No Command

        ADC_Sampling : Sample ADC0 (Temp) + ADC1 (Batt)\nEvery 100ms
        PWM_Control : Compute OCR0 = f(Temp)\nTimer0 Fast PWM 977Hz
        LCD_Refresh : Update 4-line cockpit display\nDirty-flag mechanism
        Telemetry : $TELE,BT frame @ 500ms\nJSON payload WiFi @ 500ms
        CommandCheck : Parse USART0/USART1 RX buffers\nEvery scheduler tick (10ms)
        note right of ADC_Sampling
            Entry: Enable ADC, PWM, LCD, Wireless
            Status LED = ON (blue)
            Heartbeat LED = 1Hz blink
            LCD: "MODE: RUN"
        end note
    }

    state DIAGNOSTIC {
        direction TB
        [*] --> BuildReport
        BuildReport --> Transmit
        Transmit --> [*] : Complete

        BuildReport : Collect last 5 readings, DTCs,\nuptime, actuator states
        Transmit : Send $DIAG report over\nUSART0 (BT) + USART1 (WiFi)
        note right of BuildReport
            Entry: Maintain current actuator states
            LCD: "MODE: DIAG"
        end note
    }

    state FAULT {
        direction TB
        [*] --> LogDTC
        LogDTC --> EmergencyCutoff
        EmergencyCutoff --> [*] : Auto-transition

        LogDTC : Write DTC code to EEPROM\nwith timestamp
        EmergencyCutoff : OCR0 = 0 (Fan OFF)\nWarning LED 2Hz blink\nBuzzer 2kHz ON
        note right of EmergencyCutoff
            Entry: Immediate actuator cutoff
            LCD: "MODE: FAULT"
            Auto-transition to SAFE_MODE
        end note
    }

    state SAFE_MODE {
        direction TB
        [*] --> Locked
        Locked : All actuators LOCKED (OFF)\nReject all ignition commands\nWarning LED steady ON\nBuzzer intermittent
        Locked --> WaitRecovery : Condition monitoring
        WaitRecovery : Monitor fault condition\nWait for physical clear + Reset

        note right of Locked
            Entry: Lock all outputs
            LCD: "MODE: SAFE"
            Reject IGN_START commands
        end note
    }

    OFF --> START : [Ignition ON]\n(Button INT4 / BT CMD / WiFi CMD)
    START --> RUN : [Self-Test PASS\n& Sensors Valid]
    START --> FAULT : [Self-Test FAIL\nor Sensor OOR]
    RUN --> FAULT : [Temp > 90°C\nOR Volt OOR\nOR ADC Saturated\nOR Sensor Disc.]
    RUN --> DIAGNOSTIC : [DIAG_REQ received\n(BT or WiFi)]
    RUN --> OFF : [Ignition OFF\n(Button / BT / WiFi)]
    DIAGNOSTIC --> RUN : [Report Transmitted]
    FAULT --> SAFE_MODE : [Auto-Transition\n(within 50ms)]
    SAFE_MODE --> OFF : [Fault Cleared (hysteresis)\n+ Reset Signal\n(Button INT5 / CLEAR_DTC)]
```

---

## 5. Sequence Diagram — Boot & Self-Test

> Detailed startup sequence from power-on to RUN state.

```mermaid
sequenceDiagram
    participant HW as ATmega128 Hardware
    participant MCAL as MCAL Layer
    participant HAL as HAL Layer
    participant OS as OS/Scheduler
    participant FSM as FSM Core (APP)
    participant LCD as LCD Cockpit
    participant BT as HC-05 (BT)
    participant WIFI as ESP-01 (WiFi)

    Note over HW,WIFI: 🔌 POWER ON — Hardware Reset

    HW ->> MCAL: Hardware Reset Vector
    activate MCAL
    MCAL ->> MCAL: DIO_Init() — Configure all GPIO directions
    MCAL ->> MCAL: ADC_Init() — ADMUX=0x40, ADCSRA=0x87, Prescaler÷128
    MCAL ->> MCAL: Timer0_Init_FastPWM() — TCCR0=0x6B, Prescaler÷64
    MCAL ->> MCAL: Timer2_Init_SysTick() — 10ms tick CTC mode
    MCAL ->> MCAL: USART0_Init() — 9600bps, 8N1, IRQ RX+TX enabled
    MCAL ->> MCAL: USART1_Init() — 115200bps, 8N1, IRQ RX+TX enabled
    MCAL ->> MCAL: EXTI_Init() — INT4 (PE4) falling edge, INT5 (PE5) falling edge
    deactivate MCAL

    MCAL ->> HAL: Drivers ready
    activate HAL
    HAL ->> HAL: LCD_Init() — HD44780 4-bit init sequence (40ms wait)
    HAL ->> HAL: Sensors_Init() — Configure ADC channels 0+1
    HAL ->> HAL: Actuators_Init() — All outputs LOW, Fan duty=0
    deactivate HAL

    HAL ->> OS: HAL ready
    activate OS
    OS ->> OS: Scheduler_Init() — Register all periodic tasks
    OS ->> OS: AddTask(ADC_Task, 100ms)
    OS ->> OS: AddTask(LCD_Task, 200ms)
    OS ->> OS: AddTask(Tele_Task, 500ms)
    OS ->> OS: AddTask(Fault_Task, 20ms)
    OS ->> OS: AddTask(Cmd_Task, 10ms)
    OS ->> OS: RingBuf_Init() — Init 4×64-byte ring buffers
    OS ->> OS: WDT_Enable(2000ms)
    deactivate OS

    OS ->> FSM: Scheduler running, start FSM
    activate FSM
    FSM ->> FSM: FSM_Init() → STATE = OFF

    Note over FSM,WIFI: 🚀 START State — Self-Test Sequence

    FSM ->> LCD: LCD_RenderLine1("MODE: START")
    LCD -->> FSM: Updated

    FSM ->> HAL: Sensor_ReadTemperature() — ADC channel 0
    HAL ->> MCAL: ADC_ReadBlocking(0)
    MCAL -->> HAL: raw_value
    HAL -->> FSM: temp = 32.1°C ✅

    FSM ->> HAL: Sensor_ReadBatteryVoltage() — ADC channel 1
    HAL ->> MCAL: ADC_ReadBlocking(1)
    MCAL -->> HAL: raw_value
    HAL -->> FSM: batt = 12.4V ✅

    FSM ->> WIFI: WiFi_Init() — AT command sequence
    activate WIFI
    WIFI ->> WIFI: Send AT → Wait "OK"
    WIFI ->> WIFI: Send AT+RST → Wait "ready"
    WIFI ->> WIFI: Send AT+CWMODE=1 → Wait "OK"
    WIFI ->> WIFI: Send AT+CWJAP → Wait "WIFI CONNECTED" (3 retry max)
    WIFI ->> WIFI: Send AT+CIPSERVER=1,80 → Wait "OK"
    WIFI -->> FSM: WiFi Connected ✅
    deactivate WIFI

    FSM ->> BT: BT_Init() — Send AT, verify HC-05 ACK
    activate BT
    BT ->> BT: USART0 send "AT\r\n"
    BT ->> BT: Wait for "OK" response
    BT -->> FSM: BT Module ACK ✅
    deactivate BT

    FSM ->> FSM: All tests PASSED → Transition to RUN
    FSM ->> LCD: LCD_RenderLine1("MODE: RUN")
    FSM ->> HAL: LED_Set(LED_STATUS_BLUE, ON)
    deactivate FSM

    Note over HW,WIFI: ✅ RUN State Active — Normal Operation Begins
```

---

## 6. Sequence Diagram — RUN Mode Normal Operation

> One complete scheduler cycle during normal RUN mode (every 500ms window).

```mermaid
sequenceDiagram
    participant SCHED as Scheduler (10ms tick)
    participant ADC_T as ADC Task (100ms)
    participant FAULT_T as Fault Task (20ms)
    participant LCD_T as LCD Task (200ms)
    participant TELE_T as Telemetry Task (500ms)
    participant SENSORS as Sensors HAL
    participant ACTUATORS as Actuators HAL
    participant FAULT_MGR as Fault Manager
    participant LCD_R as LCD Renderer
    participant BT as BT HAL
    participant WIFI as WiFi HAL

    loop Every 10ms Scheduler Tick
        SCHED ->> SCHED: Timer2 ISR → increment tick count
        SCHED ->> SCHED: WDT_Reset() — pet the watchdog

        alt tick % 2 == 0 (every 20ms)
            SCHED ->> FAULT_T: Run Fault Monitor Task
            activate FAULT_T
            FAULT_T ->> SENSORS: Sensor_GetLastTemp()
            SENSORS -->> FAULT_T: 42.5°C
            FAULT_T ->> FAULT_T: 42.5 < 90°C → OK ✅
            FAULT_T ->> SENSORS: Sensor_GetLastBatt()
            SENSORS -->> FAULT_T: 12.4V
            FAULT_T ->> FAULT_T: 10.5 < 12.4 < 16.0 → OK ✅
            FAULT_T ->> FAULT_T: Check Comms Timeout → within 10s ✅
            deactivate FAULT_T
        end

        alt tick % 10 == 0 (every 100ms)
            SCHED ->> ADC_T: Run ADC Sampling Task
            activate ADC_T
            ADC_T ->> SENSORS: Sensor_ReadTemperature()
            SENSORS ->> SENSORS: ADC_SetChannel(0), ADC_StartConversion()
            SENSORS ->> SENSORS: Wait 104µs, ADC_GetResult()
            SENSORS ->> SENSORS: temp = (raw × 5000) / (1024 × 10) = 42.5°C
            SENSORS -->> ADC_T: 42.5°C

            ADC_T ->> SENSORS: Sensor_ReadBatteryVoltage()
            SENSORS ->> SENSORS: ADC_SetChannel(1), ADC_StartConversion()
            SENSORS ->> SENSORS: batt = (raw × 5.0 / 1023) × 3.0 = 12.4V
            SENSORS -->> ADC_T: 12.4V

            ADC_T ->> ACTUATORS: Fan_SetDuty( OCR0 = floor((42.5-40)/(90-40) × 255) = 12 )
            ACTUATORS ->> ACTUATORS: Timer0_SetDutyCycle(12) → 5% duty
            ADC_T ->> ADC_T: Update ECUData: temp=42.5, batt=12.4, pwm=5%
            deactivate ADC_T
        end

        alt tick % 20 == 0 (every 200ms)
            SCHED ->> LCD_T: Run LCD Refresh Task
            activate LCD_T
            LCD_T ->> LCD_R: LCD_RenderTask_200ms()
            LCD_R ->> LCD_R: Build Line1: "MODE: RUN    IGN: ON "
            LCD_R ->> LCD_R: Build Line2: "TEMP:42.5C  BAT:12.4V"
            LCD_R ->> LCD_R: Build Line3: "FAN: 5%    FLT: NONE "
            LCD_R ->> LCD_R: Build Line4: "BT: OK   WiFi:ONLINE "
            LCD_R ->> LCD_R: Compare with cache → Line2 changed (dirty)
            LCD_R ->> LCD_R: LCD_SetCursor(1,0), LCD_WriteString(line2) only
            deactivate LCD_T
        end

        alt tick % 50 == 0 (every 500ms)
            SCHED ->> TELE_T: Run Telemetry Broadcast Task
            activate TELE_T
            TELE_T ->> BT: BT_SendTelemetryFrame(42.5, 12.4, 5, NONE)
            BT ->> BT: Build: "$TELE,42.5,12.4,5,NONE*5C\r\n"
            BT ->> BT: Compute XOR checksum = 0x5C
            BT ->> BT: USART0_SendString(frame) via ring buffer
            Note over BT: Frame transmitted to Mobile App

            TELE_T ->> WIFI: WiFi_BuildJSONPayload(ecuData)
            WIFI ->> WIFI: Build JSON: {"ecu_id":"GESTELL_ECU_01","mode":"RUN","temp_c":42.5,...}
            WIFI ->> WIFI: Send: AT+CIPSEND=0,<len>\r\n
            WIFI ->> WIFI: Send JSON payload via USART1
            Note over WIFI: JSON streamed to Web Dashboard
            deactivate TELE_T
        end
    end
```

---

## 7. Sequence Diagram — Fault Detection & SAFE MODE

> Complete fault detection, DTC logging, emergency cutoff, and recovery sequence.

```mermaid
sequenceDiagram
    participant SCHED as Scheduler
    participant FAULT_T as Fault Monitor Task (20ms)
    participant SENSORS as Sensors HAL
    participant FSM as FSM Core
    participant FAULT_MGR as Fault Manager
    participant DTC_MGR as DTC Manager
    participant ACTUATORS as Actuators HAL
    participant LCD as LCD Renderer
    participant BT as BT HAL
    participant WIFI as WiFi HAL

    Note over SCHED,WIFI: ⚠️ Over-Temperature Fault Scenario (F001)

    SCHED ->> FAULT_T: Run Fault Monitor (tick=t0)
    activate FAULT_T
    FAULT_T ->> SENSORS: Sensor_GetLastTemp()
    SENSORS -->> FAULT_T: 92.3°C (> 90°C threshold!)
    FAULT_T ->> FAULT_MGR: Fault_TriggerFault(DTC_F001_OVER_TEMP)
    activate FAULT_MGR

    FAULT_MGR ->> DTC_MGR: DTC_Log(F001, uptime=1420s)
    activate DTC_MGR
    DTC_MGR ->> DTC_MGR: Write DTC_Record to EEPROM
    DTC_MGR -->> FAULT_MGR: DTC logged ✅
    deactivate DTC_MGR

    FAULT_MGR ->> FSM: FSM_Transition(STATE_FAULT)
    activate FSM

    Note over FSM: FAULT State Entry Actions
    FSM ->> ACTUATORS: Actuators_EmergencyCutoff()
    activate ACTUATORS
    ACTUATORS ->> ACTUATORS: Timer0_SetDutyCycle(0) — Fan OFF
    ACTUATORS ->> ACTUATORS: DIO_WritePin(PD7, HIGH) — Buzzer 2kHz
    ACTUATORS -->> FSM: Cutoff done ✅
    deactivate ACTUATORS

    FSM ->> LCD: LCD_RenderLine1("MODE: FAULT ")
    FSM ->> LCD: LCD_RenderLine3("FAN: 0%   FLT: F001 ")
    FSM ->> BT: BT_SendTelemetryFrame(92.3, 12.4, 0, F001)
    BT ->> BT: "$TELE,92.3,12.4,0,F001*4A\r\n" → USART0

    WIFI ->> WIFI: Build JSON: {"mode":"FAULT","fault":"F001","fan_pwm":0}
    WIFI ->> WIFI: Transmit to Dashboard

    Note over FSM: Auto-Transition to SAFE_MODE (<50ms)
    FSM ->> FSM: FSM_Transition(STATE_SAFE_MODE)
    FSM ->> ACTUATORS: LED_Blink(LED_WARNING, 2Hz)
    FSM ->> LCD: LCD_RenderLine1("MODE: SAFE  ")
    FSM -->> FAULT_MGR: SAFE_MODE active
    deactivate FSM
    deactivate FAULT_MGR
    deactivate FAULT_T

    Note over SCHED,WIFI: 🔒 SAFE MODE — System Locked

    loop While in SAFE_MODE
        SCHED ->> FAULT_T: Fault Monitor running
        FAULT_T ->> SENSORS: Sensor_GetLastTemp()
        SENSORS -->> FAULT_T: 87.1°C (still > 75°C hysteresis)
        FAULT_T ->> FAULT_T: Fault not cleared — remain locked
    end

    Note over SCHED,WIFI: ✅ Recovery — Temperature drops below 75°C & Reset pressed

    SCHED ->> FAULT_T: Fault Monitor
    FAULT_T ->> SENSORS: Sensor_GetLastTemp()
    SENSORS -->> FAULT_T: 71.2°C (< 75°C hysteresis!) ✅
    FAULT_T ->> FAULT_T: F001 physical condition cleared

    Note over FSM: INT5 (PE5) pressed → Reset Signal
    FSM ->> DTC_MGR: DTC_Clear(F001)
    DTC_MGR ->> DTC_MGR: Update EEPROM record cleared=true
    DTC_MGR -->> FSM: Cleared ✅

    FSM ->> ACTUATORS: LED_StopBlink(LED_WARNING)
    FSM ->> ACTUATORS: LED_Set(LED_WARNING, OFF)
    FSM ->> ACTUATORS: Buzzer_Off()
    FSM ->> FSM: FSM_Transition(STATE_OFF)
    FSM ->> LCD: LCD_RenderLine1("MODE: OFF   ")
    Note over SCHED,WIFI: 🔄 System returned to OFF state — Ready for ignition
```

---

## 8. Sequence Diagram — Bluetooth Command Processing

> Full BT frame reception, parsing, and command execution flow.

```mermaid
sequenceDiagram
    participant MOBILE as 📱 Mobile App
    participant HC05 as HC-05 Module
    participant USART0 as USART0 Driver (IRQ)
    participant RINGBUF as RX Ring Buffer
    participant BT_HAL as BT HAL (Parser)
    participant TELE as Telemetry Manager
    participant FSM as FSM Core

    Note over MOBILE,FSM: 📥 Incoming BT Command: $IGN_START,1,0*3A\r\n

    MOBILE ->> HC05: Bluetooth SPP frame
    HC05 ->> USART0: Serial byte stream via PE0 (RXD0)

    loop For each received byte
        USART0 ->> USART0: ISR_USART0_RX() triggered
        USART0 ->> RINGBUF: RingBuf_Push(byte)
        Note right of RINGBUF: 64-byte circular buffer
    end

    Note over TELE,FSM: Every 10ms — Command Parser Task

    TELE ->> RINGBUF: RingBuf_Pop() loop until \r\n
    RINGBUF -->> TELE: "$IGN_START,1,0*3A\r\n"

    TELE ->> BT_HAL: BT_ParseIncomingByte(frame)
    BT_HAL ->> BT_HAL: Validate '$' start marker
    BT_HAL ->> BT_HAL: Extract command token: "IGN_START"
    BT_HAL ->> BT_HAL: Extract params: "1,0"
    BT_HAL ->> BT_HAL: Extract checksum: 0x3A
    BT_HAL ->> BT_HAL: Compute XOR of frame body
    BT_HAL ->> BT_HAL: Compare: computed == received? YES ✅
    BT_HAL -->> TELE: CMD_IGN_START (valid frame)

    TELE ->> FSM: FSM_HandleIgnitionON()
    FSM ->> FSM: Current state == OFF? YES
    FSM ->> FSM: FSM_Transition(STATE_START)
    Note over FSM: START state begins self-test...

    Note over MOBILE,FSM: 📤 Telemetry Response (500ms later)

    TELE ->> BT_HAL: BT_SendTelemetryFrame(42.5, 12.4, 5, NONE)
    BT_HAL ->> BT_HAL: Build: "$TELE,42.5,12.4,5,NONE"
    BT_HAL ->> BT_HAL: XOR checksum = 0x5C
    BT_HAL ->> BT_HAL: Append "*5C\r\n"
    BT_HAL ->> USART0: USART0_SendString("$TELE,42.5,12.4,5,NONE*5C\r\n")
    USART0 ->> USART0: Push to TX Ring Buffer
    USART0 ->> USART0: ISR_USART0_TX() empties buffer
    USART0 ->> HC05: Serial TX via PE1 (TXD0)
    HC05 ->> MOBILE: Bluetooth SPP → "$TELE,42.5,12.4,5,NONE*5C\r\n"
    MOBILE ->> MOBILE: Parse & display: Temp=42.5°C, Batt=12.4V, Fan=5%
```

---

## 9. Sequence Diagram — WiFi Telemetry Broadcast

> ESP-01 AT initialization and JSON telemetry broadcast to Web Dashboard.

```mermaid
sequenceDiagram
    participant FSM as FSM / Tele Manager
    participant WIFI_HAL as WiFi HAL
    participant USART1 as USART1 Driver (IRQ)
    participant ESP01 as ESP-01 Module
    participant ROUTER as WiFi Router
    participant DASH as 🌐 Web Dashboard

    Note over FSM,DASH: 🔧 WiFi AT Initialization (at START state)

    FSM ->> WIFI_HAL: WiFi_Init()
    activate WIFI_HAL

    WIFI_HAL ->> USART1: USART1_SendString("AT\r\n")
    USART1 ->> ESP01: Serial via PD3 (TXD1)
    ESP01 -->> USART1: "OK\r\n" via PD2 (RXD1)
    WIFI_HAL ->> WIFI_HAL: WaitResponse("OK", 1000ms) → ✅

    WIFI_HAL ->> USART1: "AT+RST\r\n"
    ESP01 -->> USART1: "ready\r\n"
    WIFI_HAL ->> WIFI_HAL: Wait 500ms for module stable

    WIFI_HAL ->> USART1: "AT+CWMODE=1\r\n"
    ESP01 -->> USART1: "OK\r\n" ✅

    WIFI_HAL ->> USART1: "AT+CWJAP=\"GESTELL_NET\",\"pass123\"\r\n"
    ESP01 ->> ROUTER: WiFi Association
    ROUTER -->> ESP01: IP Assigned
    ESP01 -->> USART1: "WIFI CONNECTED\r\nWIFI GOT IP\r\nOK\r\n" ✅

    WIFI_HAL ->> USART1: "AT+CIPMUX=1\r\n"
    ESP01 -->> USART1: "OK\r\n" ✅

    WIFI_HAL ->> USART1: "AT+CIPSERVER=1,80\r\n"
    ESP01 -->> USART1: "OK\r\n" ✅

    WIFI_HAL -->> FSM: WiFi ready, TCP Server active on :80
    deactivate WIFI_HAL

    Note over FSM,DASH: 📡 Telemetry Broadcast (every 500ms during RUN)

    DASH ->> ESP01: TCP Connect to 192.168.1.x:80
    ESP01 -->> USART1: "+IPD,0,..." (client connected, ID=0)

    loop Every 500ms
        FSM ->> WIFI_HAL: WiFi_BuildJSONPayload(ecuData)
        WIFI_HAL ->> WIFI_HAL: Build JSON string (max 512 bytes)
        Note right of WIFI_HAL: {"ecu_id":"GESTELL_ECU_01","mode":"RUN",\n"temp_c":42.5,"battery_v":12.4,\n"fan_pwm":5,"fault":"NONE",\n"uptime_s":1420,...}
        WIFI_HAL ->> USART1: "AT+CIPSEND=0,<len>\r\n"
        ESP01 -->> USART1: ">" (ready to receive)
        WIFI_HAL ->> USART1: USART1_SendString(jsonBuffer)
        USART1 ->> ESP01: JSON bytes via PD3
        ESP01 ->> DASH: TCP Port 80 → JSON payload
        DASH ->> DASH: Parse JSON, update charts
        ESP01 -->> USART1: "SEND OK\r\n"
    end
```

---

## 10. Activity Diagram — Main Scheduler Loop

> Complete activity flow of the cooperative scheduler main loop.

```mermaid
flowchart TD
    START(["🔌 Power ON"]) --> INIT["Initialize All Layers\nMCAL → HAL → OS → APP\nMax 500ms"]

    INIT --> FSM_INIT["FSM_Init()\nState = OFF"]

    FSM_INIT --> ENABLE_IRQ["Enable Global Interrupts\nsei()"]

    ENABLE_IRQ --> MAIN_LOOP(["🔄 Main Loop Entry"])

    MAIN_LOOP --> CHECK_TICK{Timer2 ISR\nFired? (10ms)}

    CHECK_TICK -- No --> WFI["Wait for Interrupt\nwfi / nop"]
    WFI --> CHECK_TICK

    CHECK_TICK -- Yes --> WDT_RESET["WDT_Reset()\nPet the watchdog"]

    WDT_RESET --> INC_TICK["tick_counter++\nuptime_ms += 10"]

    INC_TICK --> TASK_10MS["Run CMD Parser Task\n(Every 10ms)\nParse USART0+USART1 RX buffers"]

    TASK_10MS --> CHECK_20MS{tick % 2 == 0?\n(20ms)}
    CHECK_20MS -- No --> CHECK_100MS
    CHECK_20MS -- Yes --> FAULT_TASK["Run Fault Monitor Task\n(Every 20ms)\nCheck Temp, Batt, Sensor, Comms"]

    FAULT_TASK --> FAULT_DET{Fault\nDetected?}
    FAULT_DET -- Yes --> FAULT_TRIGGER["Fault_TriggerFault(dtc)\nLog DTC, Cut Actuators\nTransition FAULT→SAFE_MODE"]
    FAULT_DET -- No --> CHECK_100MS

    FAULT_TRIGGER --> CHECK_100MS

    CHECK_100MS{tick % 10 == 0?\n(100ms)} -- No --> CHECK_200MS
    CHECK_100MS -- Yes --> ADC_TASK["Run ADC Sampling Task\n(Every 100ms)\nRead Temp + Batt, Update ECUData\nCompute Fan PWM OCR0"]

    ADC_TASK --> CHECK_200MS{tick % 20 == 0?\n(200ms)}
    CHECK_200MS -- No --> CHECK_500MS
    CHECK_200MS -- Yes --> LCD_TASK["Run LCD Refresh Task\n(Every 200ms)\nBuild 4 lines, dirty-flag update"]

    LCD_TASK --> CHECK_500MS{tick % 50 == 0?\n(500ms)}
    CHECK_500MS -- No --> CHECK_EVENTS
    CHECK_500MS -- Yes --> TELE_TASK["Run Telemetry Task\n(Every 500ms)\nBuild + Send BT $TELE frame\nBuild + Send WiFi JSON payload"]

    TELE_TASK --> CHECK_EVENTS["Check Event Flags\n(from ISRs)"]

    CHECK_EVENTS --> IGN_EVT{Ignition\nEvent?}
    IGN_EVT -- Yes --> HANDLE_IGN["FSM_HandleIgnitionON/OFF()\nSet/Clear ignitionEvent flag"]
    IGN_EVT -- No --> RST_EVT

    HANDLE_IGN --> RST_EVT{Reset\nEvent?}
    RST_EVT -- Yes --> HANDLE_RST["FSM_HandleFaultReset()\nIf fault cleared → transition OFF"]
    RST_EVT -- No --> FSM_RUN

    HANDLE_RST --> FSM_RUN["FSM_Run()\nExecute current state handler"]

    FSM_RUN --> MAIN_LOOP

    style FAULT_TRIGGER fill:#e53e3e,color:#fff
    style FAULT_TASK fill:#dd6b20,color:#fff
    style ADC_TASK fill:#2d6a4f,color:#fff
    style LCD_TASK fill:#1a365d,color:#fff
    style TELE_TASK fill:#44337a,color:#fff
```

---

## 11. Activity Diagram — Fault Detection Pipeline

> Detailed fault detection decision logic evaluated every 20ms.

```mermaid
flowchart TD
    START(["⏱️ Fault Monitor Task — Every 20ms"]) --> GET_DATA["Read ECUData:\n• temp = Sensor_GetLastTemp()\n• batt = Sensor_GetLastBatt()\n• adcRaw0, adcRaw1"]

    GET_DATA --> CHECK_TEMP{temp > 90°C?}

    CHECK_TEMP -- Yes --> F001["🔴 TRIGGER F001\nEngine Over-Temperature\nThreshold: > 90°C"]
    CHECK_TEMP -- No --> CHECK_BATT

    CHECK_BATT{batt < 10.5V\nOR batt > 16.0V?} -- Yes --> F002["🔴 TRIGGER F002\nBattery Voltage Fault\nRange: 10.5V – 16.0V"]
    CHECK_BATT -- No --> CHECK_SENSOR

    CHECK_SENSOR{ADC = 0\nOR ADC = 1023?} -- Yes --> INC_DISC["discConnectCount[ch]++"]
    CHECK_SENSOR -- No --> RESET_DISC["discConnectCount[ch] = 0"]

    INC_DISC --> CHECK_3CONSEC{count >= 3\nconsecutive?}
    CHECK_3CONSEC -- Yes --> F003["🔴 TRIGGER F003\nSensor Disconnection\nADC saturated 3× in a row"]
    CHECK_3CONSEC -- No --> CHECK_COMMS

    RESET_DISC --> CHECK_COMMS

    CHECK_COMMS{lastRxTime_BT\n> 10 seconds?} -- Yes --> F004_BT["🟡 F004 BT Timeout\nLog warning, LCD:BT:ERR\nContinue local operation\n(No SAFE_MODE)"]
    CHECK_COMMS -- No --> CHECK_WIFI

    F004_BT --> CHECK_WIFI{lastRxTime_WiFi\n> 10 seconds?}
    CHECK_WIFI -- Yes --> F004_WIFI["🟡 F004 WiFi Timeout\nLog warning, LCD:WiFi:LOST\nContinue local operation"]
    CHECK_WIFI -- No --> NO_FAULT

    F004_WIFI --> NO_FAULT["✅ No Critical Fault\nAll checks passed"]

    F001 --> EXECUTE_FAILSAFE
    F002 --> EXECUTE_FAILSAFE
    F003 --> EXECUTE_FAILSAFE

    EXECUTE_FAILSAFE["⚡ Execute Fail-Safe Response\n1. DTC_Log(code, timestamp) → EEPROM\n2. Actuators_EmergencyCutoff()\n   • Fan PWM → 0% (OCR0=0)\n   • Warning LED → 2Hz blink\n   • Buzzer → 2kHz ON\n3. FSM_Transition(STATE_FAULT)\n4. Auto → FSM_Transition(STATE_SAFE_MODE)\nLatency requirement: ≤ 50ms"]

    EXECUTE_FAILSAFE --> END_FAULT(["🔒 SAFE_MODE Active"])
    NO_FAULT --> END_OK(["✅ Task Complete — Resume"])
    F004_BT --> END_OK
    F004_WIFI --> END_OK

    style F001 fill:#c53030,color:#fff
    style F002 fill:#c53030,color:#fff
    style F003 fill:#c53030,color:#fff
    style F004_BT fill:#d69e2e,color:#000
    style F004_WIFI fill:#d69e2e,color:#000
    style EXECUTE_FAILSAFE fill:#e53e3e,color:#fff
```

---

## 12. Communication / Deployment Diagram

> Physical deployment of all hardware nodes and their communication links.

```mermaid
graph LR
    subgraph ECU_BOARD["🖥️ ECU Development Board"]
        subgraph MEGA128["ATmega128 @ 16MHz"]
            subgraph PORTS["I/O Ports"]
                PF["PORTF\nPF0=ADC0 (LM35)\nPF1=ADC1 (Batt Pot)"]
                PB["PORTB\nPB4=OC0 (PWM Fan)"]
                PC["PORTC\nPC0=RS, PC2=EN\nPC4-7=D4-7 (LCD)"]
                PD["PORTD\nPD2=RXD1, PD3=TXD1\nPD4-7=LEDs+Buzzer"]
                PE["PORTE\nPE0=RXD0, PE1=TXD0\nPE4=INT4, PE5=INT5"]
            end
        end

        LM35["🌡️ LM35\nTemp Sensor\n10mV/°C"]
        POT["🔋 Potentiometer\nBattery Sim\n0-15V/0-5V"]
        LCD["📟 LCD 20×4\nHD44780\n4-bit mode"]
        FAN["🌀 PWM Fan\nDC Motor\n977Hz PWM"]
        LEDS["💡 LEDs ×3\nGreen/Blue/Yellow"]
        BUZZER["🔔 Buzzer\n2kHz alarm"]
        BTN_IGN["🔘 Ignition\nButton"]
        BTN_RST["🔘 Reset\nButton"]
        R_DIV["⚡ Voltage Divider\nR1=10kΩ, R2=5kΩ\n÷3 scale factor"]
    end

    subgraph BT_NODE["📶 Bluetooth Node"]
        HC05["HC-05 Module\nSPP Mode\n9600 bps\n3.3V logic"]
    end

    subgraph WIFI_NODE["🌐 WiFi Node"]
        ESP01["ESP-01 Module\nStation Mode\nTCP Server :80\n115200 bps\n3.3V logic"]
    end

    subgraph MOBILE_NODE["📱 Mobile Device"]
        MOBILE_APP["Gestell Mobile App\nBluetooth SPP\n6 Screens\nDTC Management"]
    end

    subgraph NETWORK["🏠 Local WiFi Network"]
        ROUTER["WiFi Router\n2.4GHz 802.11b/g/n"]
    end

    subgraph PC_NODE["💻 Engineering Workstation"]
        BROWSER["Web Browser\n(Chrome/Firefox)\nGestell Dashboard\n5 Pages"]
    end

    %% Physical connections
    LM35 -- "Analog 0-5V\nADC0 (PF0)" --> PF
    POT -- "Analog 0-5V\nADC1 (PF1)" --> R_DIV
    R_DIV -- "Scaled 0-5V" --> PF
    PB -- "PWM 977Hz\nOC0 (PB4)" --> FAN
    PC -- "4-bit parallel\n7 signals" --> LCD
    PD -- "GPIO Digital Out\nPD4-7" --> LEDS
    PD -- "GPIO Digital Out\nPD7" --> BUZZER
    PE -- "EXTI Falling Edge\nPE4=INT4" --> BTN_IGN
    PE -- "EXTI Falling Edge\nPE5=INT5" --> BTN_RST

    %% USART connections
    PE -- "USART0\n9600bps 8N1\nTX=PE1, RX=PE0" --> HC05
    PD -- "USART1\n115200bps 8N1\nTX=PD3, RX=PD2" --> ESP01

    %% Wireless connections
    HC05 -- "Bluetooth SPP\n2.4GHz\nSPP Profile" --> MOBILE_APP
    ESP01 -- "WiFi 802.11\n2.4GHz" --> ROUTER
    ROUTER -- "TCP Port 80\nJSON REST" --> BROWSER

    %% Logic level notes
    HC05 -. "3.3V ↔ 5V\nVoltage Divider\non HC-05 RX" .-> PE
    ESP01 -. "3.3V ↔ 5V\nVoltage Divider\non ESP01 RX" .-> PD

    style ECU_BOARD fill:#1a1a2e,stroke:#e94560,color:#fff
    style BT_NODE fill:#0f3460,stroke:#533483,color:#fff
    style WIFI_NODE fill:#16213e,stroke:#0f3460,color:#fff
    style MOBILE_NODE fill:#533483,stroke:#e94560,color:#fff
    style PC_NODE fill:#2d3748,stroke:#718096,color:#fff
    style NETWORK fill:#1a365d,stroke:#2b6cb0,color:#fff
```

---

## 13. Data Flow Diagram (DFD)

> Shows data flow between all system components — sensors to user interfaces.

```mermaid
flowchart LR
    subgraph SENSORS_IN["🔌 Physical Inputs"]
        LM35_S["LM35 Sensor\n0.01V per °C\n0-5V output"]
        POT_S["Battery Potentiometer\n0-5V (= 0-15V scaled)"]
        BTN_S["Buttons\nDigital Edge Events"]
    end

    subgraph ADC_PROC["⚡ ADC Processing (MCAL)"]
        ADC_HW["10-bit ADC\n125kHz clock\nAVCC=5V ref"]
    end

    subgraph SENSOR_CONV["🔧 Sensor Conversion (HAL)"]
        TEMP_CONV["Temperature Conversion\ntemp = (raw×5000)/(1024×10)\nUnit: °C (float)"]
        BATT_CONV["Battery Conversion\nbatt = (raw×5.0/1023)×3.0\nUnit: V (float)"]
    end

    subgraph EXTI_PROC["⚡ Event Processing (MCAL)"]
        INT4["INT4 ISR\nSet ignitionFlag\n(volatile bool)"]
        INT5["INT5 ISR\nSet resetFlag\n(volatile bool)"]
    end

    subgraph APP_CORE["🧠 APP Layer Processing"]
        ECU_DATA["ECUData_t\n• state\n• tempC, battV\n• fanPwmPct\n• activeDTC\n• btConnected\n• uptimeSeconds"]
        FSM_PROC["FSM Core\n6-State Machine\nState transitions\n& action dispatch"]
        FAULT_PROC["Fault Manager\nThreshold comparison\nDTC generation\nFail-safe trigger"]
        PWM_CALC["Fan PWM Calculator\nOCR0 = floor((T-40)/(90-40)×255)\nClamped [0,255]"]
    end

    subgraph SCHED_PROC["⏱️ Scheduler (OS)"]
        TICK["10ms SysTick\nTask dispatcher\nUptime counter"]
    end

    subgraph OUTPUT_PHYS["⚡ Physical Outputs (MCAL/HAL)"]
        PWM_OUT["Timer0 OCR0\nFast PWM 977Hz\nOC0/PB4"]
        LED_OUT["GPIO PD4-PD6\nLED control\nHeartbeat/Status/Warning"]
        BUZ_OUT["GPIO PD7\nBuzzer PWM\n2kHz alarm"]
        LCD_OUT["LCD 20×4\nPC0-PC7\n4-bit parallel"]
    end

    subgraph BT_FLOW["🔵 Bluetooth Data (HAL+MCAL)"]
        BT_RX["USART0 RX ISR\nRing Buffer 64B\n9600bps"]
        BT_TX["USART0 TX ISR\nRing Buffer 64B\n'$TELE,...' frames"]
        BT_PARSE["Frame Parser\n$CMD,P1,P2*CS\r\nXOR checksum"]
        BT_BUILD["Frame Builder\n$TELE,T,B,P,F*CS\r\n"]
    end

    subgraph WIFI_FLOW["🌐 WiFi Data (HAL+MCAL)"]
        WIFI_RX["USART1 RX ISR\nRing Buffer 64B\n115200bps"]
        WIFI_TX["USART1 TX ISR\nRing Buffer 64B\nJSON payload"]
        AT_ENGINE["AT Command Engine\nState machine\nAT+CWJAP → AT+CIPSEND"]
        JSON_BUILD["JSON Builder\n512-byte buffer\nComplete telemetry object"]
    end

    subgraph UI_OUT["🖥️ User Interfaces"]
        MOBILE_UI["📱 Mobile App\nLive Cockpit\nDTC Manager"]
        WEB_UI["🌐 Web Dashboard\nTelemetry Charts\nRemote Control"]
        LCD_UI["📟 LCD 20×4\nLocal Cockpit\n4-line display"]
    end

    %% Data flows
    LM35_S --> ADC_HW
    POT_S --> ADC_HW
    ADC_HW -- "10-bit raw (0-1023)" --> TEMP_CONV
    ADC_HW -- "10-bit raw (0-1023)" --> BATT_CONV
    TEMP_CONV -- "float °C" --> ECU_DATA
    BATT_CONV -- "float V" --> ECU_DATA
    BTN_S --> INT4
    BTN_S --> INT5
    INT4 -- "ignitionFlag=true" --> FSM_PROC
    INT5 -- "resetFlag=true" --> FSM_PROC

    TICK -- "10ms dispatch" --> FSM_PROC
    TICK -- "Fault task (20ms)" --> FAULT_PROC
    TICK -- "ADC task (100ms)" --> TEMP_CONV
    TICK -- "LCD task (200ms)" --> LCD_OUT
    TICK -- "Tele task (500ms)" --> BT_BUILD

    ECU_DATA --> FSM_PROC
    ECU_DATA --> FAULT_PROC
    ECU_DATA --> PWM_CALC

    FSM_PROC -- "state updates" --> ECU_DATA
    FAULT_PROC -- "dtc, faultActive" --> ECU_DATA
    PWM_CALC -- "OCR0 value" --> PWM_OUT
    FSM_PROC -- "actuator commands" --> LED_OUT
    FSM_PROC -- "buzzer commands" --> BUZ_OUT
    ECU_DATA -- "4-line content" --> LCD_OUT

    ECU_DATA --> BT_BUILD
    BT_BUILD -- "$TELE frame" --> BT_TX
    BT_TX -- "USART0 TX" --> MOBILE_UI

    BT_RX -- "raw bytes" --> BT_PARSE
    BT_PARSE -- "BT_Command_t" --> FSM_PROC

    ECU_DATA --> JSON_BUILD
    JSON_BUILD -- "JSON payload" --> WIFI_TX
    WIFI_TX -- "USART1 TX\nAT+CIPSEND" --> WEB_UI
    WIFI_RX -- "AT responses" --> AT_ENGINE
    AT_ENGINE -- "commands" --> FSM_PROC

    PWM_OUT --> FAN_PHY["🌀 Cooling Fan"]
    LED_OUT --> LED_PHY["💡 LEDs"]
    BUZ_OUT --> BUZ_PHY["🔔 Buzzer"]
    LCD_OUT --> LCD_UI
```

---

## 14. Layer Dependency Diagram

> Strict AUTOSAR-inspired dependency rules — no upward or skip-layer dependencies.

```mermaid
graph TB
    subgraph RULE["📏 AUTOSAR Dependency Rules"]
        R1["✅ Each layer may ONLY call the layer directly below it"]
        R2["❌ APP layer CANNOT access hardware registers directly"]
        R3["❌ HAL layer CANNOT access APP layer data structures"]
        R4["❌ No layer may skip a layer (e.g., APP→MCAL forbidden)"]
        R5["✅ COMMON headers may be included by ANY layer"]
    end

    subgraph APP_L["APP Layer"]
        FSM_A["ECU FSM Core"]
        FAULT_A["Fault & DTC Manager"]
        TELE_A["Telemetry Manager"]
        LCD_A["LCD Cockpit Renderer"]
    end

    subgraph OS_L["OS / Service Layer"]
        SCHED_O["SysTick Scheduler"]
        RING_O["Ring Buffer Manager"]
        EVT_O["Event Flag Queue"]
        WDG_O["Watchdog Handler"]
    end

    subgraph HAL_L["HAL Layer"]
        LCD_H["LCD HAL"]
        SENS_H["Sensors HAL"]
        ACT_H["Actuators HAL"]
        BT_H["Bluetooth HAL"]
        WIFI_H["WiFi HAL"]
    end

    subgraph MCAL_L["MCAL Layer"]
        DIO_M["DIO Driver"]
        ADC_M["ADC Driver"]
        TMR_M["Timer0/2 Driver"]
        UA0_M["USART0 Driver"]
        UA1_M["USART1 Driver"]
        EXT_M["EXTI Driver"]
    end

    subgraph HW_L["Hardware (Registers)"]
        HW_REG["ATmega128 SFRs\n(PORTA, ADMUX, OCR0,\nUBRR0, TCCR0, EICRB...)"]
    end

    subgraph CMN["Common (All Layers)"]
        CFG["Config.h"]
        DEF["Definition.h"]
        MCR["MacroFunction.h"]
    end

    %% Allowed dependencies (downward only)
    FSM_A --> SCHED_O
    FSM_A --> EVT_O
    FSM_A --> SENS_H
    FSM_A --> ACT_H
    FAULT_A --> SENS_H
    FAULT_A --> ACT_H
    TELE_A --> BT_H
    TELE_A --> WIFI_H
    LCD_A --> LCD_H

    SCHED_O --> TMR_M
    RING_O --> UA0_M
    RING_O --> UA1_M
    EVT_O --> EXT_M
    WDG_O --> HW_REG

    LCD_H --> DIO_M
    SENS_H --> ADC_M
    ACT_H --> DIO_M
    ACT_H --> TMR_M
    BT_H --> UA0_M
    BT_H --> RING_O
    WIFI_H --> UA1_M
    WIFI_H --> RING_O

    DIO_M --> HW_REG
    ADC_M --> HW_REG
    TMR_M --> HW_REG
    UA0_M --> HW_REG
    UA1_M --> HW_REG
    EXT_M --> HW_REG

    CMN -.->|"#include allowed\nfrom any layer"| APP_L
    CMN -.-> OS_L
    CMN -.-> HAL_L
    CMN -.-> MCAL_L

    style APP_L fill:#533483,stroke:#e94560,color:#fff
    style OS_L fill:#0f3460,stroke:#533483,color:#fff
    style HAL_L fill:#16213e,stroke:#0f3460,color:#fff
    style MCAL_L fill:#1a1a2e,stroke:#e94560,color:#fff
    style HW_L fill:#1a202c,stroke:#4a5568,color:#fff
    style CMN fill:#2d3748,stroke:#718096,color:#fff
```

---

## 15. Timing Diagram — Periodic Tasks

> Shows timing relationships of all scheduler tasks and their overlap.

```mermaid
gantt
    title Gestell ECU Scheduler — Periodic Task Timing (one 500ms window)
    dateFormat x
    axisFormat %L ms

    section SysTick
    Timer2 ISR (10ms tick)   :milestone, t0, 0, 0ms
    Timer2 ISR               :milestone, t1, 10, 0ms
    Timer2 ISR               :milestone, t2, 20, 0ms
    Timer2 ISR               :milestone, t3, 30, 0ms
    Timer2 ISR               :milestone, t4, 40, 0ms
    Timer2 ISR               :milestone, t5, 50, 0ms
    Timer2 ISR               :milestone, t6, 100, 0ms
    Timer2 ISR               :milestone, t7, 200, 0ms
    Timer2 ISR               :milestone, t8, 500, 0ms

    section CMD Parser (10ms)
    Parse USART0+1 RX       : active, cmd0, 0, 10ms
    Parse USART0+1 RX       : active, cmd1, 10, 10ms
    Parse USART0+1 RX       : active, cmd2, 20, 10ms
    Parse USART0+1 RX       : active, cmd3, 100, 10ms
    Parse USART0+1 RX       : active, cmd4, 200, 10ms
    Parse USART0+1 RX       : active, cmd5, 490, 10ms

    section Fault Monitor (20ms)
    Check Temp+Batt+Sensor  : crit, f0, 0, 5ms
    Check Temp+Batt+Sensor  : crit, f1, 20, 5ms
    Check Temp+Batt+Sensor  : crit, f2, 40, 5ms
    Check Temp+Batt+Sensor  : crit, f3, 100, 5ms
    Check Temp+Batt+Sensor  : crit, f4, 200, 5ms
    Check Temp+Batt+Sensor  : crit, f5, 480, 5ms

    section ADC Sampling (100ms)
    Read Temp + Batt ADC    : done, adc0, 0, 15ms
    Compute Fan PWM         : done, adc1, 100, 15ms
    Compute Fan PWM         : done, adc2, 200, 15ms
    Compute Fan PWM         : done, adc3, 300, 15ms
    Compute Fan PWM         : done, adc4, 400, 15ms

    section LCD Refresh (200ms)
    Dirty-flag update 4-line : active, lcd0, 15, 8ms
    Dirty-flag update 4-line : active, lcd1, 200, 8ms
    Dirty-flag update 4-line : active, lcd2, 400, 8ms

    section Telemetry (500ms)
    Build BT frame + WiFi JSON + Transmit : active, tele0, 23, 20ms
    Build BT frame + WiFi JSON + Transmit : active, tele1, 500, 20ms
```

---

## 📊 UML Diagram Summary

| # | Diagram Type | Name | Key Information |
|:---:|:---:|:---|:---|
| 1 | Context | System Context | ECU ↔ Driver, Engineer, Mobile App, Web Dashboard |
| 2 | Component | Package/Component | All modules across 4 layers + dependencies |
| 3 | Class | Full System Class | All classes, structs, attributes, methods, relationships |
| 4 | State Machine | ECU FSM | 6 states with entry/exit actions, guards, transitions |
| 5 | Sequence | Boot & Self-Test | Power-on → MCAL init → HAL init → Scheduler → RUN |
| 6 | Sequence | RUN Normal Operation | 500ms scheduler window, all periodic tasks |
| 7 | Sequence | Fault → SAFE_MODE | F001 detection, DTC logging, cutoff, recovery |
| 8 | Sequence | BT Command Processing | Frame RX, XOR validation, command execution |
| 9 | Sequence | WiFi Telemetry | AT init sequence, JSON broadcast, TCP server |
| 10 | Activity | Scheduler Main Loop | Complete cooperative scheduler flow |
| 11 | Activity | Fault Detection Pipeline | F001–F005 detection decision tree |
| 12 | Deployment | Hardware Deployment | All physical nodes and communication links |
| 13 | DFD | Data Flow | Sensor data → ADC → FSM → Actuators → UI |
| 14 | Dependency | Layer Architecture | AUTOSAR strict layer rules enforcement |
| 15 | Timing | Scheduler Timing | Gantt chart of all periodic task timing |

---

*Generated for: Gestell Automotive Mini-ECU — Embedded Part*  
*MCU: ATmega128 AVR @ 16 MHz | Architecture: AUTOSAR 4-Layer | Version: V1/V2/V3*
