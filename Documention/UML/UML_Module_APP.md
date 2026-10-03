# 🧠 APP Layer — Detailed UML Diagrams

> **Module:** Application Layer (APP)  
> **Modules:** ECU FSM Core · Fault & DTC Manager · Telemetry Manager · LCD Cockpit Renderer  
> **Depends on:** OS + HAL layers  

---

## 1. APP Module Class Diagram

```mermaid
classDiagram
    direction TB

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

    class ECUData_t {
        <<struct — global shared state>>
        +state : ECU_State_t
        +prevState : ECU_State_t
        +ignitionOn : bool
        +tempC : float
        +battV : float
        +fanPwmPct : uint8_t
        +fanOCR0 : uint8_t
        +activeDTC : DTC_Code_t
        +dtcList : DTC_Code_t[16]
        +dtcCount : uint8_t
        +btConnected : bool
        +wifiConnected : bool
        +uptimeSeconds : uint32_t
        +lastBtRxTime_ms : uint32_t
        +lastWifiRxTime_ms : uint32_t
        +selfTestPassed : bool
        +stateEntryTime_ms : uint32_t
    }

    class DTC_Record_t {
        <<struct>>
        +code : DTC_Code_t
        +timestamp_s : uint32_t
        +severity : uint8_t
        +cleared : bool
        +occurrenceCount : uint8_t
    }

    class FSM_Core {
        <<module APP>>
        -ecuData : ECUData_t
        -currentState : ECU_State_t
        -prevState : ECU_State_t
        -stateHandlers : FuncPtr[6]
        +FSM_Init() void
        +FSM_Run() void «called every scheduler iteration»
        +FSM_Transition(newState) void
        +FSM_GetState() ECU_State_t
        +FSM_GetStateString() char*
        +FSM_HandleIgnitionON() void
        +FSM_HandleIgnitionOFF() void
        +FSM_RunSelfTest() bool
        -FSM_State_OFF() void
        -FSM_State_START() void
        -FSM_State_RUN() void
        -FSM_State_DIAGNOSTIC() void
        -FSM_State_FAULT() void
        -FSM_State_SAFE_MODE() void
        -FSM_OnEnterOFF() void
        -FSM_OnEnterSTART() void
        -FSM_OnEnterRUN() void
        -FSM_OnEnterFAULT() void
        -FSM_OnEnterSAFE_MODE() void
        -FSM_OnExitRUN() void
    }

    class FaultManager {
        <<module APP>>
        -faultActive : bool
        -activeDTC : DTC_Code_t
        -sensorDiscCount : uint8_t[2]
        -commsTimeout_BT_ms : uint32_t
        -commsTimeout_WiFi_ms : uint32_t
        -TEMP_MAX_C : float = 90.0
        -TEMP_HYSTERESIS_C : float = 75.0
        -BATT_MIN_V : float = 10.5
        -BATT_MAX_V : float = 16.0
        -BATT_NOM_LOW : float = 12.0
        -BATT_NOM_HIGH : float = 14.5
        -DISC_CONSEC_COUNT : uint8_t = 3
        -COMMS_TIMEOUT_MS : uint32_t = 10000
        +Fault_Init() void
        +Fault_Monitor_20ms() void «scheduler task»
        +Fault_CheckOverTemp(temp) bool
        +Fault_CheckBattVolt(volt) bool
        +Fault_CheckSensorDisc(ch, raw) bool
        +Fault_CheckBTTimeout(lastRx_ms) bool
        +Fault_CheckWiFiTimeout(lastRx_ms) bool
        +Fault_TriggerFault(dtc) void
        +Fault_IsFaultActive() bool
        +Fault_GetActiveDTC() DTC_Code_t
        +Fault_ClearFault(dtc) bool
        +Fault_IsRecoveryPossible() bool
        +Fault_ExecuteFailSafe() void
    }

    class DTC_Manager {
        <<module APP>>
        -eepromBaseAddr : uint16_t = 0x0000
        -dtcLog : DTC_Record_t[16]
        -dtcCount : uint8_t
        -EEPROM_MAGIC : uint8_t = 0xA5
        +DTC_Init() void
        +DTC_Log(code, timestamp_s) void
        +DTC_Clear(code) bool
        +DTC_ClearAll() void
        +DTC_GetAll(outList, outCount) void
        +DTC_GetCount() uint8_t
        +DTC_IsStored(code) bool
        +DTC_GetActiveCode() DTC_Code_t
        +DTC_GetDescription(code) char*
        +DTC_GetSeverity(code) uint8_t
        +DTC_LoadFromEEPROM() void
        +DTC_SaveToEEPROM() void
        +DTC_DumpAll() void «debug: send over USART»
    }

    class TelemetryManager {
        <<module APP>>
        -btFrameBuffer : char[128]
        -jsonBuffer : char[512]
        -diagBuffer : char[1024]
        -lastBcastTime_ms : uint32_t
        -TELE_PERIOD_MS : uint16_t = 500
        +Tele_Init() void
        +Tele_Task_500ms() void «scheduler task»
        +Tele_BuildBTFrame(data, outBuf) void
        +Tele_BuildWiFiJSON(data, outBuf) void
        +Tele_BuildDiagReport(data, outBuf) void
        +Tele_BroadcastBT() void
        +Tele_BroadcastWiFi() void
        +Tele_BroadcastBothChannels() void
        +Tele_ParseCommand(frame) BT_Command_t
        +Tele_ExecuteCommand(cmd, param) void
        +Tele_ComputeXOR(str) uint8_t
        +Tele_FormatFloat(val, decimals, outBuf) void
    }

    class LCD_Renderer {
        <<module APP>>
        -line1 : char[21]
        -line2 : char[21]
        -line3 : char[21]
        -line4 : char[21]
        -bootStep : uint8_t
        -DISPLAY_COLS : uint8_t = 20
        -DISPLAY_ROWS : uint8_t = 4
        +LCD_Renderer_Init() void
        +LCD_RenderTask_200ms() void «scheduler task»
        +LCD_RenderLine1_StateIgnition(state, ign) void
        +LCD_RenderLine2_Sensors(temp, batt) void
        +LCD_RenderLine3_Actuators(pwm, dtc) void
        +LCD_RenderLine4_Comms(bt_ok, wifi_ok) void
        +LCD_RenderAll() void
        +LCD_BootSequence() void «animated boot splash»
        +LCD_ShowFaultScreen(dtc) void
        +LCD_ShowSafeMode() void
        +LCD_ClearAll() void
        -LCD_PadString(str, width) void
        -LCD_FormatFloat(val, dec, outBuf) void
    }

    %% Relationships
    FSM_Core "1" *-- "1" ECUData_t
    FSM_Core --> ECU_State_t
    FSM_Core --> FaultManager
    FSM_Core --> DTC_Manager
    FSM_Core --> TelemetryManager
    FSM_Core --> LCD_Renderer

    FaultManager --> DTC_Code_t
    FaultManager --> DTC_Manager
    FaultManager --> ECUData_t

    DTC_Manager "1" *-- "0..16" DTC_Record_t
    DTC_Manager --> DTC_Code_t

    TelemetryManager --> ECUData_t
    TelemetryManager --> DTC_Code_t

    LCD_Renderer --> ECU_State_t
    LCD_Renderer --> DTC_Code_t
    LCD_Renderer --> ECUData_t
```

---

## 2. ECU FSM Core — Detailed State Machine with Actions

```mermaid
stateDiagram-v2
    direction LR

    [*] --> STATE_OFF : FSM_Init()

    state STATE_OFF {
        [*] --> s_off
        s_off : «Entry Actions»\n• Fan_Stop() — OCR0=0\n• LED_Set(LED_STATUS_BLUE, OFF)\n• LED_Set(LED_WARNING, OFF)\n• Buzzer_Off()\n• LCD: "MODE: OFF   IGN: OFF"
    }

    state STATE_START {
        direction TB
        [*] --> hw_init
        hw_init : Hardware Self-Test\n1. ADC channels read check (ADC0+ADC1 not saturated)\n2. LCD_Init() with response check\n3. BT_Init() — "AT" command → expect "OK"\n4. WiFi_Init() — AT command sequence (3 retries max)
        hw_init --> sensor_val : HW test passed
        sensor_val : Sensor Validation\nRead ADC0 3 times\nRead ADC1 3 times\nAll reads within valid range?
        sensor_val --> [*] : Pass/Fail result

        state choice_self_test <<choice>>
        hw_init --> choice_self_test : Any module failed?
        choice_self_test --> STATE_FAULT : YES (boot fails)
        choice_self_test --> STATE_RUN : NO (all pass)
    }

    state STATE_RUN {
        direction LR
        [*] --> run_active
        run_active : «Entry Actions»\n• Enable ADC_Task @ 100ms\n• Enable LCD_Task @ 200ms\n• Enable Tele_Task @ 500ms\n• LED_Set(LED_STATUS_BLUE, ON)\n• Heartbeat LED blink @ 1Hz\n• LCD: "MODE: RUN"
    }

    state STATE_DIAGNOSTIC {
        [*] --> diag_collect
        diag_collect : Collect Diagnostic Data\n• Last 5 temp readings\n• Last 5 batt readings\n• Active DTC list\n• Actuator states\n• FSM state history\n• Uptime, MCU clock state
        diag_collect --> diag_tx
        diag_tx : Transmit Extended Report\n• $DIAG frame via USART0 (BT)\n• JSON extended report via USART1 (WiFi)\n• LCD: "MODE: DIAG"
        diag_tx --> [*] : Transmission complete
    }

    state STATE_FAULT {
        [*] --> fault_log
        fault_log : Log DTC to EEPROM\nDTC_Log(activeDTC, timestamp)
        fault_log --> fault_cutoff
        fault_cutoff : Emergency Cutoff\n• Actuators_EmergencyCutoff()\n• OCR0 = 0 (Fan STOP)\n• LED_Blink(WARNING, 2Hz)\n• Buzzer_On(2000Hz)
        fault_cutoff --> [*] : Auto-transition to SAFE_MODE
    }

    state STATE_SAFE_MODE {
        [*] --> safe_lock
        safe_lock : Lock All Outputs\n• Fan stays OFF\n• All actuator changes REJECTED\n• Warning LED steady ON\n• Buzzer intermittent\n• LCD: "MODE: SAFE"
        safe_lock --> safe_monitor
        safe_monitor : Monitor Recovery Conditions\n• F001: temp < 75°C (hysteresis) ?\n• F002: batt 12.0-14.5V ?\n• F003: ADC no longer saturated ?\n• Check Reset signal (INT5 / CLEAR_DTC cmd)
    }

    STATE_OFF --> STATE_START : [Guard: ignitionFlag == true]\n«Trigger: Button INT4 / BT IGN_START / WiFi»\n«Action: FSM_OnEnterSTART()»

    STATE_START --> STATE_RUN : [Guard: selfTestPassed == true]\n«Action: FSM_OnEnterRUN()»

    STATE_START --> STATE_FAULT : [Guard: selfTestPassed == false]\n«Action: DTC_Log(bootFaultCode)»

    STATE_RUN --> STATE_FAULT : [Guard: Fault_IsFaultActive() == true]\n«Trigger: Fault_Monitor_20ms() detects threshold breach»\n«Action: FSM_OnEnterFAULT()»

    STATE_RUN --> STATE_DIAGNOSTIC : [Guard: diagReqEvent == true]\n«Trigger: BT DIAG_REQ / WiFi DIAG_REQ command»\n«Action: Maintain actuator states»

    STATE_RUN --> STATE_OFF : [Guard: ignitionOFF_Flag == true]\n«Trigger: Button / BT IGN_STOP / WiFi»\n«Action: FSM_OnExitRUN() — clean shutdown»

    STATE_DIAGNOSTIC --> STATE_RUN : [Guard: diagReportSent == true]\n«Action: Resume normal telemetry»

    STATE_FAULT --> STATE_SAFE_MODE : [Guard: Always (auto-transition)]\n«Timing: ≤ 50ms after fault detection»

    STATE_SAFE_MODE --> STATE_OFF : [Guard: Fault_IsRecoveryPossible() == true\nAND resetFlag == true]\n«Action: DTC_Clear(code), re-enable peripherals»
```

---

## 3. ECU FSM — State Transition Table (Complete Reference)

| Current State | Event / Guard | Next State | Entry Action |
|:---:|:---|:---:|:---|
| `OFF` | Ignition ON (Button INT4 / BT `IGN_START` / WiFi) | `START` | Begin self-test, LCD: "MODE: START" |
| `START` | Self-test PASS & Sensors Valid | `RUN` | Enable ADC+LCD+Tele tasks, Status LED ON |
| `START` | Self-test FAIL (any module) | `FAULT` | Log boot fault DTC, execute fail-safe |
| `RUN` | `temp > 90°C` | `FAULT` | Log F001, Actuators_EmergencyCutoff() |
| `RUN` | `batt < 10.5V OR batt > 16V` | `FAULT` | Log F002, Actuators_EmergencyCutoff() |
| `RUN` | ADC saturated 3× consecutive | `FAULT` | Log F003, Actuators_EmergencyCutoff() |
| `RUN` | `DIAG_REQ` received (BT or WiFi) | `DIAGNOSTIC` | Collect + transmit extended report |
| `RUN` | Ignition OFF (Button / BT / WiFi) | `OFF` | Disable tasks, clean shutdown |
| `DIAGNOSTIC` | Report transmission complete | `RUN` | Resume normal telemetry broadcast |
| `FAULT` | Automatic (no guard) | `SAFE_MODE` | Lock all actuators within 50ms |
| `SAFE_MODE` | Recovery condition met + Reset signal | `OFF` | Clear DTC, re-enable peripherals, reset counters |

---

## 4. Fault & DTC Manager — Activity Diagram

```mermaid
flowchart TD
    subgraph FAULT_INIT["Fault_Init()"]
        FI1["faultActive = false\nactiveDTC = DTC_NONE\nsensorDiscCount[0] = 0\nsensorDiscCount[1] = 0"]
        FI2["DTC_Init()\nDTC_LoadFromEEPROM()\n(restore DTC history)"]
        FI1 --> FI2
    end

    subgraph FAULT_MON["Fault_Monitor_20ms() — Scheduler Task"]
        FM_START(["Task Entry — every 20ms"]) --> CHECK_F001

        CHECK_F001["Check F001: Over-Temperature\ntemp = ecuData.tempC"]
        CHECK_F001 --> F001_COND{temp > 90°C?}
        F001_COND -- Yes --> TRIG_F001["Fault_TriggerFault(DTC_F001)\n→ Transition to FAULT state"]
        F001_COND -- No --> CHECK_F002

        CHECK_F002["Check F002: Battery Voltage\nbatt = ecuData.battV"]
        CHECK_F002 --> F002_COND{batt < 10.5V\nOR batt > 16V?}
        F002_COND -- Yes --> TRIG_F002["Fault_TriggerFault(DTC_F002)"]
        F002_COND -- No --> CHECK_F003

        CHECK_F003["Check F003: Sensor Disconnection\nraw0 = ADC0 raw, raw1 = ADC1 raw"]
        CHECK_F003 --> F003_COND{raw == 0\nOR raw == 1023?}
        F003_COND -- Yes --> INC_DISC["sensorDiscCount[ch]++"]
        INC_DISC --> DISC3{count >= 3?}
        DISC3 -- Yes --> TRIG_F003["Fault_TriggerFault(DTC_F003)"]
        DISC3 -- No --> CHECK_F004
        F003_COND -- No --> RESET_DISC["sensorDiscCount[ch] = 0"]
        RESET_DISC --> CHECK_F004

        CHECK_F004["Check F004: BT Comms Timeout\nnow - lastBtRxTime_ms"]
        CHECK_F004 --> F004_BT{> 10,000ms?}
        F004_BT -- Yes --> WARN_BT["LCD: 'BT:ERR'\nLog F004 (no SAFE_MODE for F004)\nContinue local operation"]
        F004_BT -- No --> CHECK_F004W

        WARN_BT --> CHECK_F004W
        CHECK_F004W["Check F004: WiFi Comms Timeout\nnow - lastWifiRxTime_ms"]
        CHECK_F004W --> F004_WF{> 10,000ms?}
        F004_WF -- Yes --> WARN_WF["LCD: 'WiFi:LOST'\nLog F004"]
        F004_WF -- No --> FM_DONE

        WARN_WF --> FM_DONE(["Task Complete"])
        TRIG_F001 --> FM_DONE
        TRIG_F002 --> FM_DONE
        TRIG_F003 --> FM_DONE
    end

    subgraph FAILSAFE["Fault_ExecuteFailSafe() — Called by Fault_TriggerFault()"]
        FS1["1. DTC_Log(code, Scheduler_GetUptime_s())"]
        FS2["2. ecuData.activeDTC = code\n   ecuData.faultActive = true"]
        FS3["3. Actuators_EmergencyCutoff()\n   → Timer0_SetDutyCycle(0) ← FAN OFF\n   → LED_Blink(LED_WARNING, 2Hz)\n   → Buzzer_On(2000)"]
        FS4["4. FSM_Transition(STATE_FAULT)\n   → immediately FSM_Transition(STATE_SAFE_MODE)\n   Total latency requirement: ≤ 50ms"]
        FS1 --> FS2 --> FS3 --> FS4
    end

    subgraph DTC_OPS["DTC Manager Operations"]
        D1["DTC_Log(code, ts)\n• Create DTC_Record_t\n• Add to dtcLog[]\n• DTC_SaveToEEPROM()"]
        D2["DTC_Clear(code)\n• Find record by code\n• Set cleared = true\n• DTC_SaveToEEPROM()"]
        D3["DTC_LoadFromEEPROM()\n• Check magic byte 0xA5\n• Read all records\n• Restore dtcCount"]
        D4["EEPROM Layout:\n[0x0000] Magic: 0xA5\n[0x0001] dtcCount\n[0x0002..] DTC_Record_t × 16\nTotal: ~128 bytes"]
    end
```

---

## 5. Telemetry Manager — Frame Building & Broadcast

```mermaid
sequenceDiagram
    participant SCHED as Scheduler (500ms task)
    participant TELE as Telemetry Manager
    participant BT as BT HAL
    participant WIFI as WiFi HAL
    participant APP_OUT as Mobile App / Dashboard

    Note over SCHED,APP_OUT: Tele_Task_500ms() — Normal RUN mode

    SCHED ->> TELE: Tele_Task_500ms()
    activate TELE

    TELE ->> TELE: Tele_BuildBTFrame(ecuData, btFrameBuffer)
    Note right of TELE: Format: $TELE,<TEMP>,<BATT>,<FAN>,<DTC>*<CS>\r\n
    TELE ->> TELE: sprintf: "$TELE,42.5,12.4,5,NONE"
    TELE ->> TELE: Compute XOR checksum of "TELE,42.5,12.4,5,NONE" = 0x5C
    TELE ->> TELE: Append "*5C\r\n" → "$TELE,42.5,12.4,5,NONE*5C\r\n"

    TELE ->> BT: BT_SendTelemetryFrame(frame)
    BT ->> BT: USART0_SendString(frame)
    Note right of BT: Bytes pushed to TX ring buffer\nUSART0 TX ISR empties buffer asynchronously

    TELE ->> TELE: Tele_BuildWiFiJSON(ecuData, jsonBuffer)
    Note right of TELE: Build JSON:\n{\n  "ecu_id": "GESTELL_ECU_01",\n  "mode": "RUN",\n  "ignition": true,\n  "temp_c": 42.5,\n  "battery_v": 12.4,\n  "fan_pwm": 5,\n  "fault": "NONE",\n  "dtc_list": [],\n  "bt_status": "CONNECTED",\n  "uptime_s": 1420\n}

    TELE ->> WIFI: WiFi_TransmitJSON()
    WIFI ->> WIFI: USART1_SendString("AT+CIPSEND=0,<len>\r\n")
    WIFI ->> WIFI: Wait ">" prompt
    WIFI ->> WIFI: USART1_SendString(jsonBuffer)
    WIFI ->> WIFI: Wait "SEND OK"

    deactivate TELE

    Note over SCHED,APP_OUT: Command Reception & Execution (CMD_Parser_Task — 10ms)

    SCHED ->> TELE: CMD_Parser_Task() — check USART RX buffers
    TELE ->> BT: BT_ParseIncomingByte() — dequeue from rxRingBuf
    BT -->> TELE: CMD_READ_DTC (complete frame received)

    TELE ->> TELE: Tele_ExecuteCommand(CMD_READ_DTC, "")
    TELE ->> TELE: DTC_GetAll(dtcList, &count)
    TELE ->> TELE: Build $DTC response frame
    TELE ->> BT: BT_SendDTCReport(dtcList, count)
    BT ->> APP_OUT: "$DTC,F001,F002*XX\r\n" via Bluetooth
```

---

## 6. LCD Cockpit Renderer — Display Layout & Update Flow

```mermaid
flowchart TD
    subgraph LCD_LAYOUT["LCD 20×4 Cockpit Display Layout"]
        ROW1["Line 1 (Row 0): Col 0-19\n'MODE: RUN    IGN: ON '\n Field1: ECU State (cols 0-9)\n Field2: Ignition status (cols 10-19)"]
        ROW2["Line 2 (Row 1): Col 0-19\n'TEMP:42.5C  BAT:12.4V'\n Field1: Engine Temp float 1dp (cols 0-9)\n Field2: Battery Voltage float 1dp (cols 10-19)"]
        ROW3["Line 3 (Row 2): Col 0-19\n'FAN: 5%   FLT: NONE '\n Field1: Fan PWM % integer (cols 0-9)\n Field2: Active DTC code (cols 10-19)"]
        ROW4["Line 4 (Row 3): Col 0-19\n'BT: OK   WiFi:ONLINE'\n Field1: BT link status (cols 0-9)\n Field2: WiFi link status (cols 10-19)"]
    end

    subgraph LCD_RENDER_FLOW["LCD_RenderTask_200ms() — Flow"]
        R1(["Task Entry"]) --> R2["LCD_RenderLine1_StateIgnition(state, ign)\nFormat: 'MODE: %-6s  IGN: %s'\nstate strings: OFF/START/RUN/DIAG/FAULT/SAFE"]
        R2 --> R3["LCD_RenderLine2_Sensors(temp, batt)\nFormat: 'TEMP:%.1fC  BAT:%.1fV'\nPad to 20 chars"]
        R3 --> R4["LCD_RenderLine3_Actuators(pwm, dtc)\nFormat: 'FAN:%-3d%%  FLT:%-4s'\ndtc string: NONE or F001..F005"]
        R4 --> R5["LCD_RenderLine4_Comms(btOk, wifiOk)\nFormat: 'BT:%-4s WiFi:%-6s'\nbt: OK/ERR, wifi: ONLINE/LOST"]
        R5 --> R6["LCD_UpdateDirtyLines()\nOnly write lines where content changed"]
        R6 --> R7(["Task Complete"])
    end

    subgraph BOOT_SEQ["LCD_BootSequence() — Animated Splash"]
        B1["Clear LCD"] --> B2["Line1: 'GESTELL AUTOMOTIVE'"]
        B2 --> B3["Line2: '  ECU v1.0.0      '"]
        B3 --> B4["Line3: '  ATmega128 16MHz '"]
        B4 --> B5["Line4: 'Initializing...   '"]
        B5 --> B6["Wait 500ms"]
        B6 --> B7["Line4: 'BT: Testing...    '"]
        B7 --> B8["Wait 300ms"]
        B8 --> B9["Line4: 'WiFi: Testing...  '"]
        B9 --> B10["Wait 300ms"]
        B10 --> B11["Line4: 'System Ready!     '"]
        B11 --> B12["Wait 500ms → Enter RUN display mode"]
    end

    subgraph FAULT_SCREEN["LCD_ShowFaultScreen(dtc)"]
        F1["Line1: '!!! FAULT DETECTED'"]
        F2["Line2: 'Code: F001        '"]
        F3["Line3: 'Over-Temperature  '"]
        F4["Line4: 'Reset to Continue '"]
    end

    subgraph STATE_STRINGS["LCD State Display Mapping"]
        SS["OFF     → 'OFF   '\nSTART   → 'START '\nRUN     → 'RUN   '\nDIAGNOSTIC → 'DIAG  '\nFAULT   → 'FAULT '\nSAFE_MODE  → 'SAFE  '"]
    end
```

---

## 7. APP Layer — Complete Data Flow

```mermaid
flowchart LR
    subgraph INPUTS["External Inputs"]
        EXT_BTN["INT4 / INT5\nButtons → EventQueue"]
        EXT_BT["BT Commands\n$IGN_START etc.\n→ USART0 RX Buf"]
        EXT_WIFI["WiFi Commands\nHTTP/TCP → USART1 RX Buf"]
    end

    subgraph FSM_CENTER["FSM Core — Central Orchestrator"]
        STATE["Current State\n(ECU_State_t)"]
        ECUTDATA["ECUData_t\nShared Data Store"]
    end

    subgraph PERIODIC["Periodic Tasks (via Scheduler)"]
        T10["CMD Parser\n(10ms)"]
        T20["Fault Monitor\n(20ms)"]
        T100["ADC Task\n(100ms)"]
        T200["LCD Task\n(200ms)"]
        T500["Telemetry\n(500ms)"]
    end

    subgraph OUTPUTS["Outputs"]
        OUT_FAN["Fan PWM\nOCR0 (0-255)"]
        OUT_LED["LEDs (3×)\nPD4-PD6"]
        OUT_BUZ["Buzzer\nPD7"]
        OUT_LCD["LCD 20×4\nPC0-PC7"]
        OUT_BT["BT Telemetry\n$TELE frame\nUSART0 TX"]
        OUT_WIFI["WiFi JSON\nTCP Port 80\nUSART1 TX"]
    end

    EXT_BTN --> T10
    EXT_BT --> T10
    EXT_WIFI --> T10
    T10 --> FSM_CENTER

    T20 --> FSM_CENTER
    T100 --> ECUTDATA
    T200 --> OUT_LCD

    FSM_CENTER --> STATE
    STATE --> T20
    STATE --> T200
    STATE --> T500
    ECUTDATA --> T200
    ECUTDATA --> T500

    FSM_CENTER --> OUT_FAN
    FSM_CENTER --> OUT_LED
    FSM_CENTER --> OUT_BUZ
    T500 --> OUT_BT
    T500 --> OUT_WIFI
```

---

*Module: APP Layer | Layer: 4 of 4 | Depends on: OS + HAL layers*
