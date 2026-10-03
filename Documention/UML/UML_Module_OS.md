# ⚡ OS / Service Layer — Detailed UML Diagrams

> **Module:** OS / Service Layer  
> **Modules:** SysTick Cooperative Scheduler · Ring Buffer Manager · Event Flag Queue · Watchdog Handler  
> **Depends on:** HAL Layer (for Timer2)  

---

## 1. OS Module Class Diagram

```mermaid
classDiagram
    direction TB

    class SchedulerTask_t {
        <<struct>>
        +name : char[16]
        +taskFunc : void(*)(void)
        +periodMs : uint16_t
        +lastRunMs : uint32_t
        +enabled : bool
        +runCount : uint32_t
        +totalRunTime_us : uint32_t
    }

    class Scheduler {
        <<module OS>>
        -taskList : SchedulerTask_t[8]
        -taskCount : uint8_t = 0
        -maxTasks : uint8_t = 8
        -sysTick_ms : volatile uint32_t
        -uptimeSeconds : volatile uint32_t
        -taskOverrunFlag : bool
        +Scheduler_Init() void
        +Scheduler_AddTask(func, period_ms, name) bool
        +Scheduler_RemoveTask(name) bool
        +Scheduler_EnableTask(name) void
        +Scheduler_DisableTask(name) void
        +Scheduler_Run() void «called in main loop»
        +Scheduler_Tick_ISR() void «called from Timer2 ISR»
        +Scheduler_GetUptime_ms() uint32_t
        +Scheduler_GetUptime_s() uint32_t
        +Scheduler_GetTaskRunCount(name) uint32_t
        +Scheduler_IsTaskOverdue(name) bool
    }

    class TaskPeriods {
        <<constants>>
        TASK_CMD_PARSER = 10ms
        TASK_FAULT_MONITOR = 20ms
        TASK_ADC_SAMPLING = 100ms
        TASK_LCD_REFRESH = 200ms
        TASK_TELEMETRY = 500ms
        TASK_HEARTBEAT_LED = 1000ms
    }

    class RingBuffer_t {
        <<struct>>
        +buffer : uint8_t[64]
        +head : volatile uint8_t
        +tail : volatile uint8_t
        +count : volatile uint8_t
        +capacity : uint8_t
    }

    class RingBufferManager {
        <<module OS>>
        +RingBuf_Init(rb, buf, capacity) void
        +RingBuf_Push(rb, byte) bool
        +RingBuf_Pop(rb, out_byte) bool
        +RingBuf_Peek(rb, out_byte) bool
        +RingBuf_IsEmpty(rb) bool
        +RingBuf_IsFull(rb) bool
        +RingBuf_GetCount(rb) uint8_t
        +RingBuf_GetFreeSpace(rb) uint8_t
        +RingBuf_Flush(rb) void
    }

    class EventQueue {
        <<module OS>>
        -ignitionON_Flag : volatile bool
        -ignitionOFF_Flag : volatile bool
        -faultReset_Flag : volatile bool
        -diagReq_BT_Flag : volatile bool
        -diagReq_WiFi_Flag : volatile bool
        -btCmd_Flag : volatile bool
        -wifiCmd_Flag : volatile bool
        +Event_SetIgnitionON() void
        +Event_SetIgnitionOFF() void
        +Event_SetFaultReset() void
        +Event_SetDiagReq_BT() void
        +Event_SetDiagReq_WiFi() void
        +Event_GetIgnitionON() bool
        +Event_GetIgnitionOFF() bool
        +Event_GetFaultReset() bool
        +Event_GetDiagReq() bool
        +Event_ClearIgnition() void
        +Event_ClearFaultReset() void
        +Event_ClearDiagReq() void
        +Event_ClearAll() void
        +Event_AnyPending() bool
    }

    class WatchdogHandler {
        <<module OS>>
        -wdtTimeout_ms : uint16_t
        -wdtEnabled : bool
        +WDT_Enable(timeout_ms) void
        +WDT_Disable() void
        +WDT_Reset() void «call to pet watchdog»
        +WDT_ISR() void «ISR — triggered if not reset in time»
        +WDT_GetTimeout_ms() uint16_t
        +WDT_IsEnabled() bool
    }

    class WDT_Timeout_t {
        <<enumeration»
        WDT_16MS   = 0x00
        WDT_32MS   = 0x01
        WDT_65MS   = 0x02
        WDT_130MS  = 0x03
        WDT_260MS  = 0x04
        WDT_520MS  = 0x05
        WDT_1000MS = 0x06
        WDT_2000MS = 0x07 «used in ECU»
    }

    %% Relationships
    Scheduler "1" *-- "0..8" SchedulerTask_t
    Scheduler --> TaskPeriods
    RingBufferManager --> RingBuffer_t
    WatchdogHandler --> WDT_Timeout_t
```

---

## 2. Scheduler — Task Registration & Dispatch Activity Diagram

```mermaid
flowchart TD
    subgraph SCHEDULER_INIT["Scheduler_Init() — Called Once at Startup"]
        I1["taskCount = 0\nsysTick_ms = 0\nuptimeSeconds = 0"]
        I2["Scheduler_AddTask(CMD_Parser_Task, 10, 'CMD')"]
        I3["Scheduler_AddTask(Fault_Monitor_Task, 20, 'FAULT')"]
        I4["Scheduler_AddTask(ADC_Sampling_Task, 100, 'ADC')"]
        I5["Scheduler_AddTask(LCD_Refresh_Task, 200, 'LCD')"]
        I6["Scheduler_AddTask(Telemetry_Task, 500, 'TELE')"]
        I7["Scheduler_AddTask(Heartbeat_Task, 1000, 'HB')"]
        I8["Timer2_Init_CTC_10ms()\nEnable Timer2 Compare interrupt"]
        I1 --> I2 --> I3 --> I4 --> I5 --> I6 --> I7 --> I8
    end

    subgraph TICK_ISR["Timer2_ISR_COMP() — Every ~10ms (ISR context)"]
        T1["sysTick_ms += 10"]
        T2["if sysTick_ms % 1000 == 0:\n  uptimeSeconds++"]
        T3["WDT_Reset()\n(pet watchdog every tick)"]
        T4["ISR exits — returns to main loop"]
        T1 --> T2 --> T3 --> T4
    end

    subgraph SCHEDULER_RUN["Scheduler_Run() — Called in Main Loop (forever)"]
        R1["now = sysTick_ms"]
        R2["i = 0"]
        R3{i < taskCount?}
        R4["task = taskList[i]"]
        R5{task.enabled\nAND\n(now - task.lastRunMs)\n>= task.periodMs?}
        R6["task.taskFunc()\ntask.lastRunMs = now\ntask.runCount++"]
        R7["i++"]
        R8["Repeat forever"]

        R1 --> R2 --> R3
        R3 -- Yes --> R4 --> R5
        R5 -- Yes --> R6 --> R7 --> R3
        R5 -- No --> R7
        R3 -- No --> R8 --> R1
    end
```

---

## 3. Scheduler — Task Execution Timeline

```mermaid
sequenceDiagram
    participant TIMER2 as Timer2 ISR (10ms)
    participant MAIN as Main Loop
    participant CMD_T as CMD Parser (10ms)
    participant FAULT_T as Fault Monitor (20ms)
    participant ADC_T as ADC Task (100ms)
    participant LCD_T as LCD Task (200ms)
    participant TELE_T as Telemetry (500ms)
    participant HB_T as Heartbeat (1000ms)

    Note over TIMER2,HB_T: t=0ms — System Start

    TIMER2 ->> MAIN: tick=0, sysTick=10ms
    activate MAIN
    MAIN ->> CMD_T: Run (10-0=10 >= 10ms) ✅
    CMD_T -->> MAIN: done
    MAIN ->> FAULT_T: Run (10-0=10 < 20ms) ❌
    MAIN ->> ADC_T: Run (10-0=10 < 100ms) ❌
    deactivate MAIN

    TIMER2 ->> MAIN: tick=1, sysTick=20ms
    activate MAIN
    MAIN ->> CMD_T: Run (20-10=10 >= 10ms) ✅
    MAIN ->> FAULT_T: Run (20-0=20 >= 20ms) ✅
    FAULT_T -->> MAIN: done
    MAIN ->> ADC_T: Run (20-0=20 < 100ms) ❌
    deactivate MAIN

    Note over TIMER2,HB_T: ... (ticks 2-9 skipped for brevity)

    TIMER2 ->> MAIN: tick=9, sysTick=100ms
    activate MAIN
    MAIN ->> CMD_T: Run ✅
    MAIN ->> FAULT_T: Run ✅ (every 20ms)
    MAIN ->> ADC_T: Run (100-0=100 >= 100ms) ✅
    ADC_T -->> MAIN: done
    MAIN ->> LCD_T: Run (100-0=100 < 200ms) ❌
    deactivate MAIN

    TIMER2 ->> MAIN: tick=19, sysTick=200ms
    activate MAIN
    MAIN ->> CMD_T: Run ✅
    MAIN ->> ADC_T: Run ✅ (every 100ms)
    MAIN ->> LCD_T: Run (200-0=200 >= 200ms) ✅
    LCD_T -->> MAIN: done
    MAIN ->> TELE_T: Run (200-0=200 < 500ms) ❌
    deactivate MAIN

    TIMER2 ->> MAIN: tick=49, sysTick=500ms
    activate MAIN
    MAIN ->> CMD_T: Run ✅
    MAIN ->> FAULT_T: Run ✅
    MAIN ->> ADC_T: Run ✅
    MAIN ->> LCD_T: Run ✅
    MAIN ->> TELE_T: Run (500-0=500 >= 500ms) ✅ ← All tasks align!
    TELE_T -->> MAIN: done
    deactivate MAIN

    Note over TIMER2,HB_T: t=1000ms — All 6 tasks run (LCM of all periods)
    TIMER2 ->> MAIN: tick=99, sysTick=1000ms
    MAIN ->> HB_T: Run (1000-0=1000 >= 1000ms) ✅ ← LED heartbeat toggle
```

---

## 4. Ring Buffer Manager — Push/Pop Operations

```mermaid
flowchart LR
    subgraph RING_BUF_STRUCT["RingBuffer_t — 64-byte circular"]
        BUFFER["buffer[0..63]\n(uint8_t array)"]
        HEAD["head\n(write pointer)"]
        TAIL["tail\n(read pointer)"]
        COUNT["count\n(bytes available)"]
    end

    subgraph PUSH["RingBuf_Push(rb, byte) — Called from ISR"]
        P1{rb.count\n< rb.capacity?}
        P2["rb.buffer[rb.head] = byte\nrb.head = (rb.head + 1) % 64\nrb.count++\nreturn true"]
        P3["Buffer FULL!\nDrop byte\nreturn false\n(data loss warning)"]
        P1 -- Yes --> P2
        P1 -- No --> P3
    end

    subgraph POP["RingBuf_Pop(rb, &byte) — Called from task"]
        Q1{rb.count\n> 0?}
        Q2["*byte = rb.buffer[rb.tail]\nrb.tail = (rb.tail + 1) % 64\nrb.count--\nreturn true"]
        Q3["Buffer EMPTY\nreturn false"]
        Q1 -- Yes --> Q2
        Q1 -- No --> Q3
    end

    subgraph ATOMIC["Thread-Safety in AVR"]
        A1["ISR calls Push() — preemptive\nMain loop calls Pop() — cooperative\nAVR single-core: count is volatile\ncritical sections use cli/sei if needed"]
    end

    subgraph VISUALIZE["Buffer State Visualization (example: 5 bytes in 64-byte buffer)"]
        VIS["[B B B B B . . . . . . . . . . ...]
              ↑         ↑
             tail      head
             (read)   (write)
             count = 5"]
    end
```

---

## 5. Event Flag Queue — ISR to Task Communication

```mermaid
sequenceDiagram
    participant INT4 as INT4 ISR (PE4)
    participant INT5 as INT5 ISR (PE5)
    participant EVT as Event Flag Queue
    participant FSM as FSM Core (Task context)

    Note over INT4,FSM: Physical button press → event → FSM

    Note over INT4: User presses Ignition button (PE4 LOW edge)
    INT4 ->> INT4: ISR_INT4_Handler() fires (atomically)
    INT4 ->> EVT: Event_SetIgnitionON()
    Note right of EVT: ignitionON_Flag = true\n(volatile — atomic write on AVR 8-bit)
    INT4 ->> INT4: ISR returns (< 5 cycles)

    Note over FSM: Scheduler runs FSM on next tick (max 10ms later)
    FSM ->> EVT: Event_GetIgnitionON()
    EVT -->> FSM: true
    FSM ->> FSM: Process ignition event\nFSM_HandleIgnitionON()
    FSM ->> EVT: Event_ClearIgnition()
    Note right of EVT: ignitionON_Flag = false

    Note over INT5: User presses Reset button (PE5 LOW edge)
    INT5 ->> INT5: ISR_INT5_Handler() fires
    INT5 ->> EVT: Event_SetFaultReset()
    Note right of EVT: faultReset_Flag = true

    FSM ->> EVT: Event_GetFaultReset()
    EVT -->> FSM: true
    FSM ->> FSM: Check fault cleared condition\nIf OK: FSM_Transition(OFF)
    FSM ->> EVT: Event_ClearFaultReset()
```

---

## 6. Watchdog Handler — Operation & Trigger Sequence

```mermaid
flowchart TD
    subgraph WDT_NORMAL["Normal Operation — WDT Reset Every 10ms"]
        W1(["System Running"]) --> W2["Timer2 ISR fires every 10ms"]
        W2 --> W3["Scheduler_Tick_ISR() called"]
        W3 --> W4["WDT_Reset() — WDTCR |= (1<<WDCE) ... wdr instruction"]
        W4 --> W5["Watchdog counter restarted (2s window)"]
        W5 --> W2
    end

    subgraph WDT_TRIGGER["Watchdog Trigger — Scheduler Stuck (> 2s without reset)"]
        X1["Scheduler stuck / main loop blocked\nTimer2 ISR not executing"]
        X2["WDT counter counts to 2000ms timeout"]
        X3["WDT fires: MCUSR |= (1<<WDRF)\nSystem RESET"]
        X4["Power-on Reset sequence restarts\nAll drivers reinitialize"]
        X5["FSM starts at STATE_OFF\nDTC F005 logged if detected"]
        X1 --> X2 --> X3 --> X4 --> X5
    end

    subgraph WDT_CONFIG["WDT_Enable(2000ms)"]
        C1["Disable interrupts: cli()"]
        C2["Enable WDT change: WDTCR |= (1<<WDCE) | (1<<WDE)"]
        C3["Set timeout: WDTCR = (1<<WDE) | WDT_2000MS (0x07)"]
        C4["Enable interrupts: sei()"]
        C1 --> C2 --> C3 --> C4
    end
```

---

*Module: OS / Service Layer | Layer: 3 of 4 | Depends on: HAL (Timer2)*
