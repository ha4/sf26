
.equ F_CPU		= 9830400				; speed 9.8304 MHz 
#define XTAL_CPU	 "9830400"				; for printing

.equ UART_MULT		= 16					; 16 or 8 (double speed)
.equ UART_BAUD		= 9600					; USART at 9600baud
.equ UBRR_VAL		= ((F_CPU+UART_BAUD*(UART_MULT/2))/(UART_BAUD*UART_MULT)-1); smart round

.equ NBUFin		= 16					; 16 bytes UART input
.equ NBUFout		= 16					; 16 bytes UART output

.org URXCaddr
		rjmp	ISR_RX

.org UDREaddr
		rjmp	ISR_TX


; ------------------------------------------------------------------------------------------------
; UART is ISR-driven
; -----------------------------

UARTISR_Init:
		ldi	YL, low(RX_buf)
		sts	RX_in, YL
		sts	RX_out, YL
		ldi	YL, low(TX_buf)
		sts	TX_in, YL
		sts	TX_out, YL

		ldi 	temp0,  low(UBRR_VAL)
		ldi 	temp1, high(UBRR_VAL)
		out	UBRRH, temp1
		out	UBRRL, temp0

		ldi	temp0, (0<<USBS)|(3<<UCSZ0)
		out	UCSRC, temp0

		ldi	temp0, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(1<<UDRIE)
		out	UCSRB, temp0

.if UART_MULT == 8
		sbi 	UCSRA, U2X					; Double speed
.endif	

		ret

ISR_RX:
		push	temp1
		in	temp1, SREG
		push	temp1
		push	YH
		push	YL

		in	temp1, UDR

		mov	YH, zero
		lds	YL, RX_in

		st	Y+, temp1
		cpi	YL, low(RX_bufend)
		brlo	no_rx_wrap
		ldi	YL, low(RX_buf)
no_rx_wrap:
		sts	RX_in, YH 
		

		pop	YL
		pop	YH
		pop	temp1
		out	SREG, temp1
		pop	temp1
		reti
ISR_TX:
		reti


.dseg

RX_buf:
	.byte NBUFin
RX_bufend:

TX_buf:
	.byte NBUFout
TX_bufend:

RX_in:
	.byte 1
RX_out:
	.byte 1

TX_in:
	.byte 1
TX_out:
	.byte 1
