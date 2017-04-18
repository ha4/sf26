; *
; * 2-CHANNEL-AD7705-CONTROLLER
; *
; * for Tiny2313
; *

; protocol:
; CMD -> [ INFO -> ] STATUS -> [ INFO -> ] ...
;
; CMD is:
; <command> <SP> [<option>  ..] <CR>
;
; INFO or STATUS is:
; <s-code> <SP> <message> <CR>
;
; SUMMARY:
;
; command:                s-code:
; Z ADC SPI reset         1x: information, data
; I ADC init/calibrate    2x: ok
; B bits read (PINB)      4x: client error
; D data read             5x: service error
; R ADC ready
; C <0..3> channel
; G [01] go-stop 

.include "tn2313def.inc"

; ================================================================================================
; Register etc. definition
; ----------------------------------

.def htc_c		= R6		; 40bit hi-resolution timer
.def htc_sreg		= R7

.def bufn		= R8
.def buf0		= R9
.def buf1		= R10
.def buf2		= R11

.def temp2		= R16
.def temp3		= R17

.def htc_a		= R18		; 40bit hi-resolution timer
.def htc_b		= R19

.def zero		= R20
.def ardy		= R21
.def aen		= R22
.def achan		= R23

.def temp0 		= R24
.def temp1 		= R25

;.def XL		= R26
;.def XH		= R27
;.def YL		= R28
;.def YH		= R29
;.def ZL		= R30
;.def ZH		= R31

.macro ldiw
	ldi	@0H, high(@1)
	ldi	@0L,  low(@1)
.endmacro

; ------------------------------------------------------------------------------------------------

.equ F_CPU		= 9830400				; speed 9.8304 MHz 
#define XTAL_CPU	 "9830400"				; for printing

.equ UART_MULT		= 16					; 16 or 8 (double speed)
.equ UART_BAUD		= 9600					; USART at 9600baud
.equ UBRR_VAL		= ((F_CPU+UART_BAUD*(UART_MULT/2))/(UART_BAUD*UART_MULT)-1); smart round

.equ CR			= 0x0D

.equ BUFSZ		= 32

.include "ad7705reg.inc"

; ------------------------------------------------------------------------------------------------
; Interrupt-Vector-Table Tiny2313
; ------------------------------------------

.CSEG

.org 0x0000     ; Reset
		rjmp    Start

.org INT1addr
		ser	ardy
		reti

.org OVF1addr
;		rjmp	ISR_HIRES
;ISR_HIRES:
		in	htc_sreg, SREG
		subi	htc_a, -1
		adc	htc_b, zero
		adc	htc_c, zero
		out	SREG, htc_sreg
		reti

; ================================================================================================
; Ports set
; ----------------

Start:

		clr 	zero
		clr 	aen
		clr 	achan

		ldi 	temp0, (1<<PB7)|(1<<PB6)|(1<<PB4)
		out 	DDRB, temp0				; PB7,4-sck,sck' PB6-MOSI
		ldi 	temp0, (0<<PB7)|(1<<PB6)|(1<<PB5)|(1<<PB4)|(0b1111<<PB0)
		out 	PORTB, temp0				; sck=0. sck'=1, MISO pullup...
																; pb3-0 input

		ldi 	temp0, 0b00100000
		out 	DDRD, temp0				; PD5 for output CLK, COM0B


; ------------------------------------------------------------------------------------------------
; Stack pointer. Initalization
; ----------------------------------------

		ldi 	temp0, LOW(RAMEND)
		out 	SPL, temp0

		rcall	UART_Init
		rcall	ACLK_Init
		rcall	INT_Init
		rcall	SPI_Init
		rcall	HiRES_Init

		sei
;		ldiw	Z, imsg*2
;		rcall	UARTasciiz

		ldiw	Y, Buffer
		sts	Buffer_in, YL

		ldiw	Y, BufferTX
		sts	Buffer_out, YL

; ------------------------------------------------------------------------------------------------
; Application initalization
; ----------------------------------------

		rcall	cmd_Zeroing
		rcall	cmd_InitADC
		rcall	cmd_Go


; ================================================================================================
; Main Loop
; ------------------------------------------------------------------------------------------------

MainLoop:
		rcall	UARTpoll
		breq	loop1
		rcall	main_type
loop1:
		rcall	UARTtxpoll
		breq	loop2
		rcall	main_send
loop2:
		and	ardy, aen
		breq	loop3
		rcall	main_data
loop3:
		rjmp	MainLoop

; ------------------------------------------------------------------------------------------------
; ADC data handler
; data INFO:
; 10 X YYYY Z <CR>  XX - channel, YYYY - data, ZZ - PINB data
;
main_data:
		; prepare part
		clr 	ardy

		; get data
		ldi 	temp0, REG_DATA16|(1<<R_nW)
		or  	temp0, achan
		rcall	SPI_xfer

		ldi 	temp0, $FF
		rcall	SPI_xfer
		push	temp0

		ldi 	temp0, $FF
		rcall	SPI_xfer
		push	temp0

		in  	temp2, PINB

		; send info
		ldi 	temp0, $10				; 10 status code
		rcall	UARTbyte                                ; info
		rcall	UARTsp

		mov 	temp0, achan				; channel number
		rcall	UARThex
		rcall	UARTsp

		pop 	temp0					; data word
		pop 	temp1
		rcall	UARTword
		rcall	UARTsp

		mov 	temp0, temp2				; PIN-B byte
		rcall	UARThex

		rcall	UARTcr

		ret


; ------------------------------------------------------------------------------------------------
; RS232 handler
;
main_type:
		clr	YH
		lds  	YL, Buffer_in
		rcall	UARTdata

		cpi  	temp0, $08
		breq	type_del
		cpi  	temp0, $7F
		breq	type_del

; insert
		cpi  	YL, low(Buffer+BUFSZ)
		breq 	type_empty

		rcall	UARTsend				; echo
		st  	Y+, temp0
		sts 	Buffer_in, YL

		cpi 	temp0, CR				; CR
		brne	type_empty

		ldi  	YL, low(Buffer)
		sts  	Buffer_in, YL

		rjmp	msg_in

type_del:
		cpi  	YL, low(Buffer)
		breq	type_empty

		dec  	YL
		sts  	Buffer_in, YL

		rcall	UARTbk					; echo
		rcall	UARTsp
		rcall	UARTbk

type_empty:
		ret


; ------------------------------------------------------------------------------------------------
; RS232 handler
;
main_send:
		lds  	YL, Buffer_out
		ret


; ------------------------------------------------------------------------------------------------
; command handler
;

msg_in:
		lds	temp0, Buffer

		; toupper
		cpi 	temp0, 'a'
		brlo	not_toupper
		andi	temp0, 0b11011111
not_toupper:

		cpi 	temp0, 'R'				; ready check
		brne	rdy_next
		rcall	cmd_Ready
		rjmp	msg_resp
rdy_next:

		cpi 	temp0, 'D'				; data read
		brne	data_next
		rcall	cmd_Data
		rjmp	msg_resp
data_next:

		cpi 	temp0, 'B'				; port B read
		brne	port_next
		rcall	cmd_Bits
		rjmp	msg_resp
port_next:

		cpi 	temp0, 'Z'				; zero/initalize AD7705 SPI part
		brne	reset_next
		rcall	cmd_Zeroing
		rjmp	msg_resp
reset_next:

		cpi 	temp0, 'I'				; initialization of AD7705 -> clock, filter, calibration
		brne	init_next
		rcall	cmd_InitADC
		rjmp	msg_resp
init_next:

		cpi 	temp0, 'G'				; go to permanent data acqure from AD7705
		brne	go_next
		rcall	cmd_Go
		rjmp	msg_resp
go_next:

		cpi 	temp0, 'C'				; go to permanent data acqure from AD7705
		brne	chan_next
		rcall	cmd_Chan
		rjmp	msg_resp
chan_next:

		cpi 	temp0, 'H'				; help/Usage
		breq	usage_help
		cpi 	temp0, '?'
		brne	usage_next
usage_help:
		ldiw	Z, iusage*2
		rcall	UARTasciiz
		ret
usage_next:
		; error message
		ldi 	temp0, 0x40
		ldiw	Z, ierr*2
		
		; response check
msg_resp:
		cpi  	temp0, 0x20				; 0 = silent, 0..1F is not response codes
		brlo	resp_not

		push	temp0					; print status code
		rcall	UARTbyte
		rcall	UARTsp
		pop 	temp0

		cpi 	temp0, 0x20				; is it 0x20? -> OK
		brne	resp_msg1
		ldiw	Z, iok*2
		rjmp	resp_msg2

resp_msg1:
		cpi 	temp0, 0x28				; 0x21..0x27 -> Z = asciiz
		brlo	resp_msg2

		cpi 	temp0, 0x2C				; 0x28..0x2B -> 1 byte ZL
		brlo	resp_msg3
		cpi	temp0, 0x40
		brsh	resp_msg2

		mov 	temp0, ZH				; 0x2C..0x2F -> 2 byte ZH:ZL
		rcall	UARTbyte
resp_msg3:
		mov 	temp0, ZL
		rcall	UARTbyte
		rcall	UARTcr
		ret

resp_msg2:
		rcall	UARTasciiz
resp_not:
		ret		
; ------------------------------------------------------------------------------------------------
; commands:
; return: temp0 - result code:
; 00h - no response
; 10h - 
; 1Fh - help info
; 20h - ok 
; 21h - 27h: Z have message (asciiz)
; 28h - 2Bh: temp1 have message (hex)
; 2Ch - 2FH: Z have message (word)
; 40h - command error, Z have message
; 50h - internal error


cmd_Ready:
		ldi 	temp0, REG_COMM|(1<<R_nW)
		or  	temp0, achan
		rcall	SPI_xfer

		ldi 	temp0, $FF
		rcall	SPI_xfer

		mov 	ZL, temp0
		ldi 	temp0, 0x28

		ret

cmd_Data:
		ldi 	temp0, REG_DATA16|(1<<R_nW)
		or  	temp0, achan
		rcall	SPI_xfer

		ldi 	temp0, $FF
		rcall	SPI_xfer
		mov 	ZH, temp0

		ldi 	temp0, $FF
		rcall	SPI_xfer
		mov 	ZL, temp0

		ldi 	temp0, 0x2C
		ret

cmd_Bits:
		in  	ZL, PINB
		ldi 	temp0, 0x28
		ret

cmd_Zeroing:
		ldi 	temp0, $FF	; clean SPI interface
		rcall	SPI_xfer
		ldi 	temp0, $FF
		rcall	SPI_xfer
		ldi 	temp0, $FF
		rcall	SPI_xfer
		ldi 	temp0, $FF
		rcall	SPI_xfer

		ldi 	temp0, 0x20
		ret

cmd_InitADC:
		ldi 	temp0, REG_CLOCK|(0<<R_nW)
		or  	temp0, achan
		rcall	SPI_xfer
		ldi 	temp0, (0<<CLKDIS)|(0<<CLKDIV)|(0<<CLK)|(0b01<<FS0)
		rcall	SPI_xfer


		ldi 	temp0, REG_SETUP|(0<<R_nW)
		or  	temp0, achan
		rcall	SPI_xfer

		ldi 	temp0, (0b01<<MD0)|(0b000<<G0)|(0<<nB_U)|(1<<BUF)|(0<<FSYNC)
		rcall	SPI_xfer

		ldi 	temp0, 0x20
		ret

cmd_Chan:
		lds 	temp0, Buffer+1
		cpi 	temp0, '0'				; select AD7705 channel
		breq	chan_set
		cpi 	temp0, '1'
		breq	chan_set
		cpi 	temp0, '2'
		breq	chan_set
		cpi 	temp0, '3'
		brne	chan_inc
chan_set:
		subi	temp0, '0'+1				; char-'0' - 1, then +1
		mov 	achan, temp0
chan_inc:
		inc 	achan
		andi	achan, 3

		ldi 	temp0, 0x20
		ret

cmd_Go:
		lds 	temp0, Buffer+1
		cpi 	temp0, '0'				; serial measurement
		breq	Go_stop
		cpi 	temp0, '1'
		breq	Go_start

		tst 	aen
		breq	go_start
go_stop:
		clr 	aen
		ldiw	Z, istop*2
		ldi 	temp0, 0x21
		ret
go_start:
		ser 	aen
		ldiw	Z, istart*2
		ldi 	temp0, 0x21
		ret

; ================================================================================================
; Timer0 for ADC clocking
; -------------------------------------
; PD5(COM0B)-clock output

ACLK_Init:			; output=9.8304/4 = 2.4576Mhz, 
		sbi 	DDRD, 5					; PD5 output COM0B

		ldi 	temp0, (F_CPU/2457600)-1
		out 	OCR0A, temp0
		asr 	temp0
		out 	OCR0B, temp0				; middle match

		ldi 	temp0, (0b11<<COM0B0)|(0b11<<WGM00)
		out 	TCCR0A, temp0				; COM0B=11 (set on match, reset on TOP)
		ldi 	temp0, (0b1<<WGM02)|(0b001<<CS00)
		out 	TCCR0B, temp0				; WGM=111 (FASTPWM, TOP=OC0A) CS0=001

		ret

; ================================================================================================
; ADC  AD7705
; -------------------------------------
; PD3(INT1) #7 - ~drdy signal; PD2(INT0) #6

INT_Init:
		in  	temp0, MCUCR
		cbr 	temp0, (0b11<<ISC10)			; preserve bits
		sbr 	temp0, (0b10<<ISC10)			; ISC1=10, falling edge
		out 	MCUCR, temp0

		ldi 	temp0, 1<<INT1
		out 	GIMSK, temp0

		ret

; ================================================================================================
; HIGH RESOULUTION CLOCK
; -------------------------------------
; 40 bit (16@TCNT+24@register) at 9.8mhz overflow after 1.29 day

HiRES_Init:							; 29 cycles from call. next op alwas 29
		out 	TCCR1A, zero
		in  	temp0, TIMSK
		cbr 	temp0, (1<<OCIE1A)|(1<<OCIE1B)|(1<<ICIE1)
		sbr 	temp0, (1<<TOIE1)
		out 	TIMSK, temp0
HiRESreset:							; Zero at rcall enter (Virtual); at exit always: 21
								; routine length with call: 21
							;3 rcall
		in  	temp1, SREG
		cli
		out 	TCCR1B, zero				; stop timer

		ldi 	temp0, 1<<TOV1
		out 	TIFR, temp0				; reset if interrupt happens in the routine

		ldi 	temp0, 16				; time correction to virtual start
		out 	TCNT1L, temp0
		out 	TCNT1H, zero

		clr 	htc_a
		clr 	htc_b
		clr 	htc_c

		ldi 	temp0, 0b001<<CS10			; clock prescaler = 1
		out 	TCCR1B, temp0				; start timer1
								; 16 cycles from RCALL here
		out 	SREG, temp1
		ret						; 5 cycles after ret

HiRESget:							; get time at rcall enter ZL:YH:YL:XH:XL
								; the rowtine eat always 25 cycles
							;3 rcall
		cli					;1
		in  	XL, TCNT1L			;1
		in  	XH, TCNT1H			;1
		movw	YL, htc_a			;1	; **** here real point of catch
		mov 	ZL, htc_c			;1
		sei					;1

		adiw	XL, 2				;2	; time catch correction ( distance from IN TCNT1L and MOVW )
		brcs	hires_ovf			;1/2	; handle overflow internally
		nop					;1	; the routine cycles compensation
		nop					;1
		rjmp	hires_ok			;2
hires_ovf:						
		adiw	YL, 1				;2
		adc 	ZL, zero			;1
hires_ok:

		subi	XL, 6				;1	; backward distance for 'rcall'
		sbc 	XH, zero			;1
		sbc 	YL, zero			;1
		sbc 	YH, zero			;1
		sbc 	ZL, zero			;1
		ret					;4	; total: 25




; ================================================================================================
; SPI-Master for ADC 
; -------------------------------------
; PB7-sck, PB4-sck' PB6-MOSI, PB5-MISO, PB3-CS

SPI_init:	
		ldi 	r24, (0<<USISIE)|(0<<USIOIE)|(0b01<<USIWM0)|(0b10<<USICS0)|(0<<USICLK)|(0<<USITC)
		out 	USICR, r24				; USIWM=01 - three wire
		ret						; USICS=10,USICLK=0 - external clock, positive

; ------------------------------------------------------------------------------------------------
; SPI Byte Transfer
; ----------------------
; data in:  temp0
; data out: temp0
; modify temp1, temp0

SPI_xfer:	
		ldi 	temp1, (1<<PB7)|(1<<PB4)
		cbi 	PORTB, 7
		sbi 	PORTB, 4				; initial clk=0, clk'=1

		out 	USIDR, temp0				; load data
		ldi 	temp0, 1<<USIOIF
		out 	USISR, temp0				; clear counter

		in  	temp0, PORTB

		cbr 	temp0, 1<<PB4				; first bit begin clk=0, clk'=1
		out 	PORTB, temp0				; fall clk'

		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0
	
		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop
 
		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop

		eor 	temp0, temp1
		out 	PORTB, temp0

		nop
		nop

		cbr 	temp0, (1<<PB7)
		out 	PORTB, temp0

		in  	temp0, USIDR

		ret

; ================================================================================================
; UART Initalization
; -------------------------------------

UART_Init:
		ldi 	temp0,  low(UBRR_VAL)
		ldi 	temp1, high(UBRR_VAL)
		out 	UBRRH, temp1
		out 	UBRRL, temp0

		ldi 	temp0, (0 << USBS)|(3 << UCSZ0)
		out 	UCSRC, temp0

		ldi 	temp0, (1 << RXEN)|(1 << TXEN)
		out 	UCSRB, temp0

.if UART_MULT == 8
		sbi 	UCSRA, U2X					; Double speed
.endif	
		ret

; ------------------------------------------------------------------------------------------------
; UART interface
; -------------------------------------

UARTread:
		rcall	UARTpoll
		breq	UARTread	        ; ANDI result
UARTdata:
		in  	temp0, UDR       	; return received data
		ret

UARTpoll:
		in  	temp0, UCSRA
		andi	temp0, 1<<RXC		; wait for incoming data
		ret

UARTbk:
		ldi 	temp0, 8
		rjmp	UARTsend
UARTcomma:
		ldi 	temp0, ','
		rjmp	UARTsend
UARTsp:
		ldi 	temp0, 32
		rjmp	UARTsend

UARTcr:
		ldi 	temp0, 10

UARTsend:
		sbis	UCSRA, UDRE
		rjmp	UARTsend		; wait for empty transmit buffer

		out 	UDR, temp0		; fill UDR, start transmission
		ret

UARTtxpoll:
		in  	temp0, UCSRA
		andi	temp0, 1<<UDRE		; wait for data register empty
		ret

; ------------------------------------------------------------------------------------------------
; UART extension
; ---------------------------
UARThex:					; print hexdecimal digit temp0
		push	temp0
		andi	temp0, 15
		cpi 	temp0, 10
		brlo	uart_digit
		subi	temp0, -7
uart_digit:
		subi	temp0, -'0'
		rcall	UARTsend
		pop 	temp0
		ret

UARTword:
		push 	temp0
		mov 	temp0,temp1
		rcall	UARTbyte
		pop 	temp0

UARTbyte:
		swap	temp0
		rcall	UARThex
		swap	temp0
		rcall	UARThex
		ret

UARTasciiz:  
		lpm 	temp0, Z+
		tst 	temp0
		breq	uart_asciiz2
		rcall	uartSend
		rjmp	UARTasciiz
uart_asciiz2:
		ret


UARTascii:
		ld  	temp0, Z+
		tst 	temp0
		breq	uart_ascii2
		rcall	uartSend
		rjmp	UARTascii
uart_ascii2:
		ret

; ================================================================================================
; RAM data section
; ----------------------

.dseg

Buffer:
	.byte BUFSZ
buffer_in:
	.byte 2

BufferTX:
	.byte BUFSZ
buffer_out:
	.byte 2

.cseg

iusage:		.db	"1F info commands:",CR
		.db	"1F Z ADCSPI reset",CR
		.db	"1F I ADC init/calibrate",CR
		.db	"1F B bits read (PINB)",CR
		.db	"1F D data read ",CR
		.db	"1F R ADC ready ",CR
		.db	"1F C <0..3> channel",CR
		.db	"1F G [01] go/stop",CR,0,0

ierr:		.db	"Bad command", CR
iok:		.db	"OK", CR, 0
istart:		.db	"start", CR, 0, 0
istop:		.db	"stop", CR,0


; ================================================================================================
; The End
; ------------------------------------------------------------------------------------------------
