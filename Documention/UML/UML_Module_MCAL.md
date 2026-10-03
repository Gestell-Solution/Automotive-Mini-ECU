# 🔌 MCAL Layer — Detailed UML Diagrams

> **Module:** Microcontroller Abstraction Layer (MCAL)  
> **Target:** ATmega128 AVR @ 16 MHz  
> **Modules:** DIO · ADC · Timer0/2 (PWM + SysTick) · USART0 · USART1 · EXTI  

---

## 1. MCAL Module Class Diagram

```mermaid
classDiagram
    direction TB

    class DIO_Driver {
        <<module MCAL>>
        -DDRA : reg8 «Output Direction»
        -DDRB : reg8 «Output Direction»
        -DDRC : reg8 «Output Direction»
        -DDRD : reg8 «Output Direction»
        -DDRE : reg8 «Output Direction»
        -DDRF : reg8 «Output Direction»
        -PORTA : reg8 «Output Data»
        -PORTB : reg8 «Output Data»
        -PORTC : reg8 «Output Data»
        -PORTD : reg8 «Output Data»
        -PORTE : reg8 «Output Data»
        -PORTF : reg8 «Output Data»
        -PINA : reg8 «Input Read»
        -PINB : reg8 «Input Read»
        +DIO_Init(port, pin, dir) void
        +DIO_WritePin(port, pin, val) void
        +DIO_ReadPin(port, pin) uint8_t
        +DIO_TogglePin(port, pin) void
        +DIO_WritePort(port, val) void
        +DIO_ReadPort(port) uint8_t
        +DIO_SetPinHigh(port, pin) void
        +DIO_SetPinLow(port, pin) void
    }

    class DIO_Port_t {
        <<enumeration>>
        PORT_A = 0
        PORT_B = 1
        PORT_C = 2
        PORT_D = 3
        PORT_E = 4
        PORT_F = 5
        PORT_G = 6
    }

    class DIO_Dir_t {
        <<enumeration>>
        DIR_INPUT = 0
        DIR_OUTPUT = 1
    }

    class ADC_Driver {
        <<module MCAL>>
        -ADMUX : reg8 «0x40 = AVCC ref, ch0»
        -ADCSRA : reg8 «0x87 = enable+start+prescaler128»
        -ADCL : reg8 «low byte of result»
        -ADCH : reg8 «high byte of result»
        -conversionDone : volatile bool
        +ADC_Init() void
        +ADC_SetChannel(ch) void
        +ADC_StartConversion() void
        +ADC_WaitReady() void
        +ADC_GetResult() uint16_t
        +ADC_ReadBlocking(ch) uint16_t
        +ADC_SetReference(ref) void
        +ADC_Enable() void
        +ADC_Disable() void
    }

    class ADC_Channel_t {
        <<enumeration>>
        ADC_CH0 = 0 «LM35 Temp»
        ADC_CH1 = 1 «Battery Pot»
        ADC_CH2 = 2
        ADC_CH3 = 3
        ADC_CH4 = 4
        ADC_CH5 = 5
        ADC_CH6 = 6
        ADC_CH7 = 7
    }

    class ADC_Ref_t {
        <<enumeration>>
        ADC_REF_AREF = 0x00
        ADC_REF_AVCC = 0x40 «default»
        ADC_REF_INT = 0xC0
    }

    class Timer0_Driver {
        <<module MCAL — PWM>>
        -TCCR0 : reg8 «0x6B = FastPWM, OC0 non-inv, presc÷64»
        -OCR0  : reg8 «Compare Output register 0»
        -TCNT0 : reg8 «Timer Counter»
        -TIMSK : reg8 «Timer Interrupt Mask»
        +Timer0_Init_FastPWM() void
        +Timer0_SetDutyCycle(ocr) void
        +Timer0_Stop() void
        +Timer0_Enable_OVF_IRQ() void
        +Timer0_GetDuty() uint8_t
        +Timer0_GetFrequency_Hz() uint16_t
    }

    class Timer2_Driver {
        <<module MCAL — SysTick>>
        -TCCR2 : reg8 «CTC mode, prescaler»
        -OCR2  : reg8 «Compare value for 10ms»
        -TCNT2 : reg8 «Timer counter»
        -sysTick_ms : volatile uint32_t
        +Timer2_Init_CTC_10ms() void
        +Timer2_GetTick_ms() uint32_t
        +Timer2_ISR_COMP() void «ISR»
        +Timer2_DelayMs(ms) void
        +Timer2_ResetTick() void
    }

    class USART0_Driver {
        <<module MCAL — Bluetooth>>
        -UBRRH0 : reg8 «0x00»
        -UBRRL0 : reg8 «0x67 = UBRR=103 for 9600bps»
        -UCSR0A : reg8 «0x00 normal speed»
        -UCSR0B : reg8 «0xD8 = RX+TX IRQ, RXen, TXen»
        -UCSR0C : reg8 «0x86 = 8N1»
        -rxRingBuf : RingBuffer_t «64 bytes»
        -txRingBuf : RingBuffer_t «64 bytes»
        +USART0_Init() void
        +USART0_SendByte(byte) void
        +USART0_SendString(str) void
        +USART0_SendBuffer(buf, len) void
        +USART0_ReceiveByte() uint8_t
        +USART0_DataAvailable() bool
        +USART0_TxReady() bool
        +ISR_USART0_RXC() void «ISR»
        +ISR_USART0_TXC() void «ISR»
        +USART0_FlushRX() void
    }

    class USART1_Driver {
        <<module MCAL — WiFi>>
        -UBRRH1 : reg8 «0x00»
        -UBRRL1 : reg8 «0x08 = UBRR=8 for 115200bps»
        -UCSR1B : reg8 «0xD8 = RX+TX IRQ, RXen, TXen»
        -UCSR1C : reg8 «0x86 = 8N1»
        -rxRingBuf : RingBuffer_t «64 bytes»
        -txRingBuf : RingBuffer_t «64 bytes»
        +USART1_Init() void
        +USART1_SendByte(byte) void
        +USART1_SendString(str) void
        +USART1_SendBuffer(buf, len) void
        +USART1_ReceiveByte() uint8_t
        +USART1_DataAvailable() bool
        +ISR_USART1_RXC() void «ISR»
        +ISR_USART1_TXC() void «ISR»
        +USART1_FlushRX() void
    }

    class RingBuffer_t {
        <<struct — shared>>
        +buffer : uint8_t[64]
        +head : volatile uint8_t
        +tail : volatile uint8_t
        +count : volatile uint8_t
        +capacity : uint8_t = 64
    }

    class EXTI_Driver {
        <<module MCAL — Interrupts>>
        -EICRB : reg8 «INT4,INT5 config = falling edge»
        -EIMSK : reg8 «Enable INT4, INT5»
        -ignitionFlag : volatile bool
        -resetFlag : volatile bool
        -ignDebounce_ms : uint16_t = 20
        -rstDebounce_ms : uint16_t = 20
        +EXTI_Init() void
        +EXTI_EnableINT4() void
        +EXTI_EnableINT5() void
        +EXTI_DisableINT4() void
        +EXTI_DisableINT5() void
        +EXTI_GetIgnitionFlag() bool
        +EXTI_GetResetFlag() bool
        +EXTI_ClearIgnitionFlag() void
        +EXTI_ClearResetFlag() void
        +ISR_INT4_Handler() void «ISR»
        +ISR_INT5_Handler() void «ISR»
    }

    %% Relationships
    DIO_Driver --> DIO_Port_t
    DIO_Driver --> DIO_Dir_t
    ADC_Driver --> ADC_Channel_t
    ADC_Driver --> ADC_Ref_t
    USART0_Driver "1" *-- "2" RingBuffer_t
    USART1_Driver "1" *-- "2" RingBuffer_t
    Timer0_Driver ..> Timer2_Driver : «independent»
```

---

## 2. DIO Driver — State & Operation Diagram

```mermaid
flowchart LR
    subgraph DIO_OPS["DIO Driver Operations"]
        INIT["DIO_Init(port, pin, dir)\n• DDRx bit set for OUTPUT\n• DDRx bit clear for INPUT\n• Optional pull-up via PORTx"]

        WRITE["DIO_WritePin(port, pin, val)\n• val=1: SET_BIT(PORTx, pin)\n• val=0: CLR_BIT(PORTx, pin)"]

        READ["DIO_ReadPin(port, pin)\n• return GET_BIT(PINx, pin)"]

        TOGGLE["DIO_TogglePin(port, pin)\n• PORTx ^= (1 << pin)"]
    end

    subgraph PIN_MAP["ATmega128 Pin Assignments (ECU)"]
        PORTA_MAP["PORTA: (reserved)"]
        PORTB_MAP["PORTB:\nPB4=OC0 (Fan PWM OUT)"]
        PORTC_MAP["PORTC:\nPC0=LCD RS OUT\nPC1=LCD RW OUT\nPC2=LCD EN OUT\nPC4=LCD D4 OUT\nPC5=LCD D5 OUT\nPC6=LCD D6 OUT\nPC7=LCD D7 OUT"]
        PORTD_MAP["PORTD:\nPD2=USART1 RX IN\nPD3=USART1 TX OUT\nPD4=LED_PWR OUT\nPD5=LED_STS OUT\nPD6=LED_WRN OUT\nPD7=BUZZER OUT"]
        PORTE_MAP["PORTE:\nPE0=USART0 RX IN\nPE1=USART0 TX OUT\nPE4=INT4 IN (Ignition)\nPE5=INT5 IN (Reset)"]
        PORTF_MAP["PORTF:\nPF0=ADC0 IN (LM35)\nPF1=ADC1 IN (Batt)"]
    end
```

---

## 3. ADC Driver — Conversion Sequence

```mermaid
sequenceDiagram
    participant HAL as Sensors HAL
    participant ADC as ADC Driver
    participant HW as ATmega128 ADC HW

    Note over HAL,HW: ADC Single Conversion (Blocking)

    HAL ->> ADC: ADC_ReadBlocking(ADC_CH0)
    ADC ->> ADC: ADC_SetChannel(0)
    ADC ->> HW: ADMUX = (ADMUX & 0xE0) | 0x00
    Note right of HW: AVCC ref (0x40) + CH0 (0x00)

    ADC ->> ADC: ADC_StartConversion()
    ADC ->> HW: ADCSRA |= (1 << ADSC)
    Note right of HW: Set ADSC bit → conversion starts\nADC clock = 16MHz/128 = 125kHz\nConversion time = 13 cycles = 104μs

    ADC ->> ADC: ADC_WaitReady()
    loop While ADSC bit set
        ADC ->> HW: Read ADCSRA
        HW -->> ADC: ADSC = 1 (converting...)
    end
    HW -->> ADC: ADSC = 0 (done!)

    ADC ->> ADC: ADC_GetResult()
    ADC ->> HW: Read ADCL (low byte first!)
    HW -->> ADC: ADCL = 0x6A
    ADC ->> HW: Read ADCH (high byte)
    HW -->> ADC: ADCH = 0x01
    ADC ->> ADC: result = (ADCH << 8) | ADCL = 0x016A = 362

    ADC -->> HAL: raw = 362

    Note over HAL,HW: Sensor Conversion in HAL
    HAL ->> HAL: temp = (362 × 5000) / (1024 × 10) = 176.8°C?
    Note right of HAL: Result = 17.68°C\n(LM35: 10mV/°C, AVCC=5V ref)
    HAL ->> HAL: temp_C = (raw × 5000.0) / (1023.0 × 10.0)
```

---

## 4. Timer0 PWM Driver — Configuration & Operation

```mermaid
flowchart TD
    subgraph TIMER0_INIT["Timer0_Init_FastPWM()"]
        T0["TCCR0 Register Configuration\nbits: WGM01=1, WGM00=1 → Fast PWM mode\nbits: COM01=1, COM00=0 → Non-inverting OC0\nbits: CS02=0, CS01=1, CS00=1 → Prescaler ÷64\nFinal: TCCR0 = 0x6B"]
        T1["OC0 Pin Direction\nDIO_Init(PORT_B, 4, DIR_OUTPUT)\nPB4 = OC0 = PWM Fan output"]
        T2["PWM Frequency\nf_PWM = F_CPU / (N × 256)\n= 16,000,000 / (64 × 256)\n= 976.5625 Hz ≈ 977 Hz"]
        T0 --> T1 --> T2
    end

    subgraph DUTY_CALC["Fan_SetDuty(percent)"]
        D0["Input: temp_C (float)\nT_min = 40°C → 0% duty\nT_max = 90°C → 100% duty"]
        D1["OCR0 = floor((T - 40) / 50 × 255)\nclamped to [0, 255]"]
        D2["Example:\nT=42°C → OCR0=floor(2/50×255)=10 → 4%\nT=65°C → OCR0=floor(25/50×255)=127 → 50%\nT=90°C → OCR0=255 → 100%"]
        D3["Timer0_SetDutyCycle(ocr)\nOCR0 = ocr_value\n(register write, immediate effect)"]
        D0 --> D1 --> D2 --> D3
    end

    subgraph TIMER0_STATES["OCR0 Register States"]
        S0["OCR0 = 0 → Fan OFF\n(0% duty cycle)\nUsed in: FAULT, SAFE_MODE, OFF"]
        S127["OCR0 = 127 → Fan 50%\n(50% duty cycle)\nExample: T=65°C"]
        S255["OCR0 = 255 → Fan 100%\n(100% duty cycle)\nUsed when T ≥ 90°C (just before fault)"]
    end
```

---

## 5. Timer2 SysTick — Interrupt-Driven Scheduler Timer

```mermaid
sequenceDiagram
    participant HW as Timer2 HW
    participant ISR as Timer2_ISR_COMP
    participant TICK as sysTick_ms Counter
    participant SCHED as Scheduler

    Note over HW,SCHED: Timer2 CTC Mode — 10ms tick generation
    Note over HW: F_CPU=16MHz, prescaler=128\nOCR2 = (F_CPU / (prescaler × freq)) - 1\n= (16M / (128 × 100)) - 1 = 1249 - 1 = 1249\n→ But 8-bit OCR2 max=255 → use prescaler=1024\nOCR2 = (16M / (1024 × 100)) - 1 = 155.25 ≈ 155\nActual tick ≈ 9.93ms (acceptable for 10ms scheduler)

    loop Every ~10ms
        HW ->> ISR: Timer2 Compare Match Interrupt (TIMER2_COMP_vect)
        activate ISR
        ISR ->> TICK: sysTick_ms += 10
        ISR ->> TICK: if sysTick_ms % 1000 == 0: uptimeSeconds++
        ISR ->> SCHED: Scheduler_Tick_ISR()
        deactivate ISR
        SCHED ->> SCHED: Evaluate all task periods
        SCHED ->> SCHED: Dispatch ready tasks
    end
```

---

## 6. USART0 Driver — Interrupt-Driven Ring Buffer Architecture

```mermaid
flowchart TB
    subgraph TX_PATH["📤 TX Path (ATmega128 → HC-05)"]
        TX_APP["APP/HAL calls\nUSART0_SendString(str)"]
        TX_PUSH["Loop: RingBuf_Push(txBuf, byte)\nfor each char in string"]
        TX_KICK["Enable UDRIE0 interrupt\nUCSR0B |= (1 << UDRIE0)"]
        TX_ISR["ISR: USART0_UDRE_vect\n(Runs when TX register empty)"]
        TX_POP["RingBuf_Pop(txBuf, &byte)"]
        TX_REG["UDR0 = byte\n(load to TX shift register)"]
        TX_EMPTY{TX Buffer\nEmpty?}
        TX_DIS["Disable UDRIE0\nUCSR0B &= ~(1<<UDRIE0)"]
        TX_HW["HC-05 receives byte\nover PE1/TXD0"]

        TX_APP --> TX_PUSH --> TX_KICK
        TX_KICK --> TX_ISR --> TX_POP --> TX_REG --> TX_EMPTY
        TX_EMPTY -- No --> TX_ISR
        TX_EMPTY -- Yes --> TX_DIS
        TX_REG --> TX_HW
    end

    subgraph RX_PATH["📥 RX Path (HC-05 → ATmega128)"]
        RX_HW["HC-05 sends byte\nover PE0/RXD0"]
        RX_ISR["ISR: USART0_RXC_vect\n(Runs on every byte received)"]
        RX_READ["byte = UDR0\n(read clears interrupt)"]
        RX_PUSH["RingBuf_Push(rxBuf, byte)"]
        RX_NOTE["64-byte circular buffer\nNo data loss at 9600bps"]

        RX_HW --> RX_ISR --> RX_READ --> RX_PUSH --> RX_NOTE
    end

    subgraph CMD_PARSE["📋 Command Parser (10ms task)"]
        POLL["USART0_DataAvailable()?\nRingBuf_IsEmpty(rxBuf) == false"]
        DEQUEUE["USART0_ReceiveByte()\nRingBuf_Pop(rxBuf, &byte)"]
        BUILD["Assemble frame until \\r\\n\nframeBuffer[idx++] = byte"]
        COMPLETE{Frame\ncomplete?}
        PARSE["BT_ParseFrame(frameBuffer)\nExtract CMD + params + checksum"]

        POLL --> DEQUEUE --> BUILD --> COMPLETE
        COMPLETE -- No --> POLL
        COMPLETE -- Yes --> PARSE
    end
```

---

## 7. EXTI Driver — Interrupt & Debounce Logic

```mermaid
stateDiagram-v2
    direction LR

    [*] --> IDLE_IGN : EXTI_Init() complete\nINT4 enabled, falling edge

    state IDLE_IGN {
        [*] --> WaitPress
        WaitPress : PE4 HIGH (button not pressed)\nIgnitionFlag = false
    }

    IDLE_IGN --> BOUNCE_IGN : PE4 falling edge\n(ISR_INT4 fires)

    state BOUNCE_IGN {
        [*] --> WaitDebounce
        WaitDebounce : Wait 20ms debounce\nScheduler counts 2 ticks
    }

    BOUNCE_IGN --> TRIGGERED_IGN : 20ms elapsed\nPin still LOW?

    state TRIGGERED_IGN {
        [*] --> FlagSet
        FlagSet : ignitionFlag = true\n(volatile, atomic write)
    }

    TRIGGERED_IGN --> IDLE_IGN : FSM reads flag\nEXTI_ClearIgnitionFlag()

    note right of TRIGGERED_IGN
        ISR is minimal:
        • Sets volatile flag ONLY
        • No blocking code in ISR
        • Debounce done in scheduler
    end note
```

---

*Module: MCAL | Layer: 1 of 4 | Target: ATmega128 AVR*
