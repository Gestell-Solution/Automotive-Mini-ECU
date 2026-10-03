# 🔧 HAL Layer — Detailed UML Diagrams

> **Module:** Hardware Abstraction Layer (HAL)  
> **Modules:** LCD 20×4 · Sensors · Actuators · Bluetooth (HC-05) · WiFi (ESP-01)  
> **Depends on:** MCAL Layer only  

---

## 1. HAL Module Class Diagram

```mermaid
classDiagram
    direction TB

    class LCD_HAL {
        <<module HAL>>
        -RS_PORT : PORT_C
        -RS_PIN : PC0
        -RW_PORT : PORT_C
        -RW_PIN : PC1 «tied LOW»
        -EN_PORT : PORT_C
        -EN_PIN : PC2
        -D4_PIN : PC4
        -D5_PIN : PC5
        -D6_PIN : PC6
        -D7_PIN : PC7
        -lineCache : char[4][21]
        -dirtyFlags : uint8_t «bit per line»
        +LCD_Init() void
        +LCD_Clear() void
        +LCD_Home() void
        +LCD_SetCursor(row, col) void
        +LCD_WriteChar(c) void
        +LCD_WriteString(str) void
        +LCD_WriteCommand(cmd) void
        +LCD_WriteData(data) void
        -LCD_WriteNibble(nibble) void
        -LCD_EnablePulse() void
        -LCD_WaitBusy() void
        +LCD_SetDirty(line) void
        +LCD_ClearDirty(line) void
        +LCD_IsDirty(line) bool
        +LCD_UpdateDirtyLines() void
        +LCD_CreateCustomChar(pos, bitmap) void
    }

    class LCD_Cmd_t {
        <<enumeration>>
        LCD_CMD_CLEAR = 0x01
        LCD_CMD_HOME = 0x02
        LCD_CMD_ENTRY = 0x06
        LCD_CMD_DISPLAY_ON = 0x0C
        LCD_CMD_4BIT_2LINE = 0x28
        LCD_CMD_SETCURSOR = 0x80
    }

    class Sensors_HAL {
        <<module HAL>>
        -ADC_CH_TEMP : uint8_t = 0
        -ADC_CH_BATT : uint8_t = 1
        -TEMP_SCALE : float «V_ref=5.0, 10mV/°C»
        -BATT_DIVIDER : float = 3.0 «×3 scale»
        -lastTempC : float
        -lastBattV : float
        -lastRawADC0 : uint16_t
        -lastRawADC1 : uint16_t
        -discCount0 : uint8_t «consecutive saturated»
        -discCount1 : uint8_t «consecutive saturated»
        +Sensor_Init() void
        +Sensor_ReadTemperature() float
        +Sensor_ReadBatteryVoltage() float
        +Sensor_GetLastTemp() float
        +Sensor_GetLastBatt() float
        +Sensor_ConvertTempADC(raw) float
        +Sensor_ConvertBattADC(raw) float
        +Sensor_IsDisconnected(ch) bool
        +Sensor_GetRawADC(ch) uint16_t
        +Sensor_IncrementDiscCount(ch) void
        +Sensor_ResetDiscCount(ch) void
        +Sensor_GetDiscCount(ch) uint8_t
    }

    class Actuators_HAL {
        <<module HAL>>
        -FAN_PORT : PORT_B
        -FAN_PIN : PB4
        -LED_PWR_PORT : PORT_D
        -LED_PWR_PIN : PD4 «Green Heartbeat»
        -LED_STS_PORT : PORT_D
        -LED_STS_PIN : PD5 «Blue RUN Active»
        -LED_WRN_PORT : PORT_D
        -LED_WRN_PIN : PD6 «Yellow Warning»
        -BUZZER_PORT : PORT_D
        -BUZZER_PIN : PD7
        -fanDutyPct : uint8_t
        -blinkState : uint8_t[3]
        -blinkCounter : uint16_t[3]
        -blinkPeriod_ms : uint16_t[3]
        +Actuators_Init() void
        +Fan_SetDuty(percent) void
        +Fan_Stop() void
        +Fan_GetDutyPct() uint8_t
        +LED_Set(id, state) void
        +LED_Blink(id, freq_hz) void
        +LED_StopBlink(id) void
        +LED_Toggle(id) void
        +Buzzer_On(freq_hz) void
        +Buzzer_Off() void
        +Buzzer_Toggle() void
        +Actuators_EmergencyCutoff() void
        +Actuators_Update_1ms() void «call from scheduler»
    }

    class BT_HAL {
        <<module HAL>>
        -frameBuffer : char[128]
        -frameIdx : uint8_t
        -rxState : BT_RxState_t
        -lastRxTime_ms : uint32_t
        -connected : bool
        -pendingCmd : BT_Command_t
        -cmdParam : char[32]
        +BT_Init() void
        +BT_SendByte(byte) void
        +BT_SendString(str) void
        +BT_SendTelemetryFrame(temp, batt, pwm, dtc) void
        +BT_SendDTCReport(dtcList, count) void
        +BT_SendDiagReport(report) void
        +BT_SendACK(cmd) void
        +BT_ParseIncomingByte(byte) bool
        +BT_GetParsedCommand() BT_Command_t
        +BT_GetCommandParam() char*
        +BT_ComputeXORChecksum(str) uint8_t
        +BT_ValidateChecksum(frame) bool
        +BT_IsConnected() bool
        +BT_CheckTimeout() bool
        +BT_UpdateRxTime() void
        +BT_ResetParser() void
    }

    class BT_RxState_t {
        <<enumeration>>
        BT_RX_IDLE = 0
        BT_RX_START = 1 «got $»
        BT_RX_BODY = 2
        BT_RX_CHECKSUM = 3
        BT_RX_COMPLETE = 4
        BT_RX_ERROR = 5
    }

    class WiFi_HAL {
        <<module HAL>>
        -AT_RESPONSE_TIMEOUT : uint16_t = 5000ms
        -atBuffer : char[256]
        -atIdx : uint16_t
        -jsonBuffer : char[512]
        -retryCount : uint8_t
        -connected : bool
        -tcpClientId : uint8_t = 0
        -wifiState : WiFi_State_t
        -lastRxTime_ms : uint32_t
        +WiFi_Init() void
        +WiFi_SendAT(cmd) void
        +WiFi_WaitResponse(expected, timeout) bool
        +WiFi_JoinNetwork(ssid, pass) bool
        +WiFi_GetIP() char*
        +WiFi_StartTCPServer(port) bool
        +WiFi_BuildJSONPayload(ecuData) void
        +WiFi_TransmitJSON() bool
        +WiFi_Reconnect() bool
        +WiFi_IsConnected() bool
        +WiFi_CheckTimeout() bool
        +WiFi_ParseATResponse(byte) void
        +WiFi_GetRetryCount() uint8_t
        +WiFi_ResetState() void
    }

    class WiFi_State_t {
        <<enumeration>>
        WIFI_IDLE = 0
        WIFI_AT_TEST = 1
        WIFI_RESET = 2
        WIFI_SET_MODE = 3
        WIFI_JOIN_AP = 4
        WIFI_GET_IP = 5
        WIFI_MULTI_CONN = 6
        WIFI_TCP_SERVER = 7
        WIFI_CONNECTED = 8
        WIFI_ERROR = 9
    }

    %% Relationships
    LCD_HAL --> LCD_Cmd_t
    Sensors_HAL --> ADC_Channel_t
    Actuators_HAL --> LED_ID_t
    BT_HAL --> BT_RxState_t
    BT_HAL --> BT_Command_t
    WiFi_HAL --> WiFi_State_t
```

---

## 2. LCD HAL — 4-bit HD44780 Initialization State Machine

```mermaid
stateDiagram-v2
    direction TB

    [*] --> POWER_ON_WAIT

    POWER_ON_WAIT : Wait 40ms after VCC stable\n(HD44780 power-up requirement)
    POWER_ON_WAIT --> RESET_1

    RESET_1 : Send 0x03 (8-bit Function Set)\nRS=0, D7-D4=0011\nWait 5ms
    RESET_1 --> RESET_2

    RESET_2 : Send 0x03 (8-bit Function Set)\nRS=0, D7-D4=0011\nWait 200µs
    RESET_2 --> RESET_3

    RESET_3 : Send 0x03 (8-bit Function Set)\nRS=0, D7-D4=0011\nWait 200µs
    RESET_3 --> SET_4BIT

    SET_4BIT : Send 0x02 (Switch to 4-bit mode)\nRS=0, D7-D4=0010\nWait 200µs
    SET_4BIT --> FUNC_SET

    FUNC_SET : Send 0x28 (4-bit, 2-line, 5×8 font)\nSend high nibble (0x02) then low nibble (0x08)\nWait 53µs
    FUNC_SET --> DISP_CTRL

    DISP_CTRL : Send 0x0C (Display ON, Cursor OFF, Blink OFF)\nWait 53µs
    DISP_CTRL --> CLR_DISP

    CLR_DISP : Send 0x01 (Clear Display)\nWait 2ms (slow command!)
    CLR_DISP --> ENTRY_MODE

    ENTRY_MODE : Send 0x06 (Increment cursor, No shift)\nWait 53µs
    ENTRY_MODE --> [*] : LCD Ready

    note right of FUNC_SET
        4-bit mode: each byte sent as 2 nibbles
        High nibble first (D7-D4)
        Then low nibble (D7-D4)
        EN pulse between each nibble
    end note
```

---

## 3. LCD HAL — Dirty-Flag Update Mechanism

```mermaid
flowchart TD
    subgraph LCD_RENDER["LCD_UpdateDirtyLines() — Every 200ms"]
        START(["Entry"]) --> CHECK_L1{Line 1\nDirty?}
        CHECK_L1 -- Yes --> WRITE_L1["LCD_SetCursor(0,0)\nLCD_WriteString(newLine1)\nClearDirty(0)"]
        CHECK_L1 -- No --> CHECK_L2
        WRITE_L1 --> CHECK_L2

        CHECK_L2{Line 2\nDirty?} -- Yes --> WRITE_L2["LCD_SetCursor(1,0)\nLCD_WriteString(newLine2)\nClearDirty(1)"]
        CHECK_L2 -- No --> CHECK_L3
        WRITE_L2 --> CHECK_L3

        CHECK_L3{Line 3\nDirty?} -- Yes --> WRITE_L3["LCD_SetCursor(2,0)\nLCD_WriteString(newLine3)\nClearDirty(2)"]
        CHECK_L3 -- No --> CHECK_L4
        WRITE_L3 --> CHECK_L4

        CHECK_L4{Line 4\nDirty?} -- Yes --> WRITE_L4["LCD_SetCursor(3,0)\nLCD_WriteString(newLine4)\nClearDirty(3)"]
        CHECK_L4 -- No --> DONE
        WRITE_L4 --> DONE(["Exit"])
    end

    subgraph DIRTY_SET["When Dirty Flag is Set"]
        COMPARE["Renderer compares new content\nwith lineCache[i]"]
        DIFFERENT{Content\nChanged?}
        SET_DIRTY["LCD_SetDirty(line)\ndirtyFlags |= (1 << line)\nUpdate lineCache"]
        COMPARE --> DIFFERENT
        DIFFERENT -- Yes --> SET_DIRTY
        DIFFERENT -- No --> SKIP["Skip — no LCD write"]
    end

    subgraph NIBBLE_WRITE["LCD_WriteChar(c) — 4-bit Write Sequence"]
        N1["Set RS = HIGH (data mode)"]
        N2["Write HIGH nibble (bits 7-4)\nSET/CLR PC4-PC7 based on bits"]
        N3["LCD_EnablePulse()\nEN=HIGH → wait 1µs → EN=LOW"]
        N4["Write LOW nibble (bits 3-0)\nSET/CLR PC4-PC7 based on bits"]
        N5["LCD_EnablePulse()\nEN=HIGH → wait 1µs → EN=LOW"]
        N6["Wait 53µs (char write settle time)"]
        N1 --> N2 --> N3 --> N4 --> N5 --> N6
    end
```

---

## 4. Sensors HAL — Data Conversion & Disconnect Detection

```mermaid
flowchart TD
    subgraph TEMP_READ["Sensor_ReadTemperature() — ADC Channel 0"]
        T_START(["Called every 100ms"]) --> T_ADC["ADC_ReadBlocking(ADC_CH0)\nReturns raw 10-bit value (0-1023)"]
        T_ADC --> T_SAT{raw == 0\nOR raw == 1023?}
        T_SAT -- Yes --> T_INC["discCount0++"]
        T_INC --> T_3{discCount0\n>= 3?}
        T_3 -- Yes --> T_F003["Return SENSOR_DISCONNECTED\n(triggers F003 in FaultManager)"]
        T_3 -- No --> T_LAST["Return lastTempC\n(use previous valid value)"]
        T_SAT -- No --> T_RESET["discCount0 = 0"]
        T_RESET --> T_CONV["temp_C = (raw × 5000.0) / (1023.0 × 10.0)\n→ LM35: 10mV/°C, AVCC=5V\n→ Resolution: 0.0488°C per LSB"]
        T_CONV --> T_STORE["lastTempC = temp_C\nlastRawADC0 = raw"]
        T_STORE --> T_RETURN["Return temp_C"]
    end

    subgraph BATT_READ["Sensor_ReadBatteryVoltage() — ADC Channel 1"]
        B_ADC["ADC_ReadBlocking(ADC_CH1)\nPotentiometer simulates 0-15V battery"]
        B_CONV["Step 1: v_adc = raw × (5.0 / 1023)\n→ ADC input voltage (0-5V)\nStep 2: v_batt = v_adc × 3.0\n→ ×3 for voltage divider (R1=10kΩ, R2=5kΩ)\n→ Battery range: 0-15V"]
        B_STORE["lastBattV = v_batt\nlastRawADC1 = raw"]
        B_ADC --> B_CONV --> B_STORE
    end

    subgraph FORMULA["Conversion Formulas"]
        F1["Temperature (LM35):\ntemp_C = ADC_raw × 5000\n         ─────────────────\n           1023 × 10\n\nUnit: °C, Range: 0-500°C ADC range"]
        F2["Battery Voltage (Pot + Divider):\nv_batt = ADC_raw × 5.0 × 3.0\n         ──────────────────────\n                1023\n\nUnit: V, Range: 0-15V actual"]
        F3["OCR0 (Fan PWM):\nOCR0 = (temp - 40) × 255\n       ──────────────────\n              50\nClamped: OCR0 ∈ [0, 255]"]
    end
```

---

## 5. Actuators HAL — LED Blink & Emergency Cutoff

```mermaid
stateDiagram-v2
    direction LR

    state LED_NORMAL {
        [*] --> LED_OFF_STATE
        LED_OFF_STATE : LED physically OFF\nDIO_WritePin(PORT_D, pin, LOW)
        LED_OFF_STATE --> LED_ON_STATE : LED_Set(id, ON)
        LED_ON_STATE : LED physically ON\nDIO_WritePin(PORT_D, pin, HIGH)
        LED_ON_STATE --> LED_OFF_STATE : LED_Set(id, OFF)
        LED_ON_STATE --> LED_BLINK_STATE : LED_Blink(id, freq)
    }

    state LED_BLINK_STATE {
        [*] --> BLINK_ON
        BLINK_ON : LED = HIGH\nCounter counts up
        BLINK_ON --> BLINK_OFF : period/2 elapsed
        BLINK_OFF : LED = LOW\nCounter counts up
        BLINK_OFF --> BLINK_ON : period/2 elapsed

        note right of BLINK_ON
            2Hz blink (Warning LED):
            period = 500ms
            ON for 250ms, OFF for 250ms
            Driven by Actuators_Update_1ms()
            called from 1ms scheduler hook
        end note
    }

    LED_BLINK_STATE --> LED_NORMAL : LED_StopBlink(id)

    state EMERGENCY_CUTOFF {
        [*] --> CUT_FAN
        CUT_FAN : Timer0_SetDutyCycle(0)\nOCR0 = 0 → Fan OFF
        CUT_FAN --> CUT_LEDS
        CUT_LEDS : LED_Set(LED_STATUS_BLUE, OFF)
        CUT_LEDS --> WARN_LED
        WARN_LED : LED_Blink(LED_WARNING_YELLOW, 2Hz)
        WARN_LED --> BUZZER_ON
        BUZZER_ON : Buzzer_On(2000)\n2kHz alarm active
    }
```

---

## 6. Bluetooth HAL — Frame Parser State Machine

```mermaid
stateDiagram-v2
    direction LR

    [*] --> IDLE

    IDLE : Waiting for '$' start byte\nframeIdx = 0
    IDLE --> START_FOUND : Received '$'

    START_FOUND : '$' detected\nframeBuffer[0] = '$'\nframeIdx = 1
    START_FOUND --> READING_BODY : Next byte

    READING_BODY : Accumulating frame bytes\nframeBuffer[frameIdx++] = byte
    READING_BODY --> READING_BODY : byte != '*' AND byte != '\r'
    READING_BODY --> CHECKSUM_READING : Received '*'
    READING_BODY --> ERROR : frameIdx >= 127 (overflow)

    CHECKSUM_READING : Reading 2-byte hex checksum\ncsBuffer[0] = hex digit 1
    CHECKSUM_READING --> CHECKSUM_COMPLETE : Received '\n'

    CHECKSUM_COMPLETE : Validate XOR checksum\ncomputed = XOR of all bytes between '$' and '*'\nparsed = strtol(csBuffer, 16)
    CHECKSUM_COMPLETE --> VALID_FRAME : computed == parsed
    CHECKSUM_COMPLETE --> ERROR : computed != parsed

    VALID_FRAME : Extract command token\nParse parameters\nSet pendingCmd\nSet frameReady = true
    VALID_FRAME --> [*] : Return to IDLE

    ERROR : Log parse error\nReset frameIdx = 0
    ERROR --> IDLE

    note right of VALID_FRAME
        Frame format:
        $IGN_START,1,0*3A\r\n
        $CLEAR_DTC,F001,0*2F\r\n
        $DIAG_REQ,0,0*1B\r\n
        $READ_DTC,0,0*5A\r\n
    end note
```

---

## 7. WiFi HAL — AT Command Engine State Machine

```mermaid
stateDiagram-v2
    direction TB

    [*] --> AT_TEST

    AT_TEST : Send "AT\r\n"\nWait "OK" (1s timeout, 3 retries)
    AT_TEST --> AT_RESET : OK received
    AT_TEST --> ERROR_STATE : Timeout / max retries

    AT_RESET : Send "AT+RST\r\n"\nWait "ready" (3s timeout)
    AT_RESET --> SET_STATION_MODE : ready received

    SET_STATION_MODE : Send "AT+CWMODE=1\r\n"\nWait "OK" (2s timeout)
    SET_STATION_MODE --> JOIN_AP : OK received

    JOIN_AP : Send "AT+CWJAP=\"SSID\",\"PASS\"\r\n"\nWait "WIFI GOT IP" (15s timeout)\nOn fail: retry up to 3 times
    JOIN_AP --> GET_IP : WIFI GOT IP received
    JOIN_AP --> ERROR_STATE : 3 retries failed → Log F004

    GET_IP : Send "AT+CIFSR\r\n"\nWait "+CIFSR:STAIP" response\nParse IP address string
    GET_IP --> SET_MULTI_CONN : IP received

    SET_MULTI_CONN : Send "AT+CIPMUX=1\r\n"\nWait "OK"
    SET_MULTI_CONN --> START_TCP_SERVER : OK received

    START_TCP_SERVER : Send "AT+CIPSERVER=1,80\r\n"\nWait "OK"
    START_TCP_SERVER --> CONNECTED_READY : OK received

    CONNECTED_READY : TCP Server active on port 80\nReady to receive clients and broadcast
    CONNECTED_READY --> TRANSMITTING : WiFi_TransmitJSON() called

    TRANSMITTING : AT+CIPSEND=0,<len>\r\n\nWait ">"\nSend JSON payload bytes\nWait "SEND OK"
    TRANSMITTING --> CONNECTED_READY : SEND OK
    TRANSMITTING --> RECONNECT : Timeout / error

    ERROR_STATE : Log F004 Comms Fault\nFall back to local-only mode\nLCD: "WiFi:LOST"
    ERROR_STATE --> AT_TEST : Auto-retry after 30s

    RECONNECT : Attempt reconnection\nBack to AT_RESET
    RECONNECT --> AT_RESET

    note right of CONNECTED_READY
        JSON Payload (every 500ms):
        {
          "ecu_id": "GESTELL_ECU_01",
          "mode": "RUN",
          "temp_c": 42.5,
          "battery_v": 12.4,
          "fan_pwm": 5,
          "fault": "NONE",
          "uptime_s": 1420
        }
    end note
```

---

## 8. HAL Layer — Sequence: Full Sensor-to-Actuator Control Loop

```mermaid
sequenceDiagram
    participant SCHED as Scheduler (100ms task)
    participant SENS as Sensors HAL
    participant ADC as ADC Driver (MCAL)
    participant ACT as Actuators HAL
    participant TMR as Timer0 Driver (MCAL)
    participant DIO as DIO Driver (MCAL)

    Note over SCHED,DIO: ADC Sampling + Fan Control — Every 100ms

    SCHED ->> SENS: Sensor_ReadTemperature()
    activate SENS
    SENS ->> ADC: ADC_SetChannel(ADC_CH0)
    ADC ->> ADC: ADMUX = (ADMUX & 0xE0) | 0x00
    SENS ->> ADC: ADC_StartConversion()
    ADC ->> ADC: ADCSRA |= (1 << ADSC)
    SENS ->> ADC: ADC_WaitReady()
    note over ADC: 104µs conversion time
    ADC -->> SENS: ADSC cleared
    SENS ->> ADC: ADC_GetResult()
    ADC -->> SENS: raw = 87 (for 42.6°C)
    SENS ->> SENS: temp = (87 × 5000.0) / (1023.0 × 10.0) = 42.52°C
    SENS -->> SCHED: 42.52°C
    deactivate SENS

    SCHED ->> SENS: Sensor_ReadBatteryVoltage()
    activate SENS
    SENS ->> ADC: ADC_ReadBlocking(ADC_CH1)
    ADC -->> SENS: raw = 843 (for 12.36V)
    SENS ->> SENS: v = (843 × 5.0 / 1023) × 3.0 = 12.36V
    SENS -->> SCHED: 12.36V
    deactivate SENS

    SCHED ->> SCHED: Compute OCR0 = floor((42.52 - 40) / 50 × 255) = 12

    SCHED ->> ACT: Fan_SetDuty(percent=5)
    activate ACT
    ACT ->> ACT: ocr = (5 × 255) / 100 = 12
    ACT ->> TMR: Timer0_SetDutyCycle(12)
    TMR ->> TMR: OCR0 = 12
    Note over TMR: Hardware PWM updated immediately\nNo ISR needed — hardware does it
    ACT -->> SCHED: Fan duty set to 5%
    deactivate ACT

    Note over SCHED,DIO: LED Heartbeat Update (1Hz in RUN mode)
    SCHED ->> ACT: LED_Toggle(LED_POWER_GREEN)
    ACT ->> DIO: DIO_TogglePin(PORT_D, PD4)
    DIO ->> DIO: PORTD ^= (1 << PD4)
```

---

*Module: HAL | Layer: 2 of 4 | Depends on: MCAL*
