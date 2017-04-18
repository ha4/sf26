; ================================================================================================
; HIGH RESOULUTION CLOCK
; -------------------------------------
; 40 bit (16@TCNT+24@register) at 9.8mhz overflow after 1.29 day
.org 0x05
		rjmp	ISR_HIRES				; Timer/Counter1 Overflow

HiRES_Init:							; 29 cycles from call. next op alwas 29
		out	TCCR1A, zero
		in	temp0, TIMSK
		cbr	temp0, (1<<OCIE1A)|(1<<OCIE1B)|(1<<ICIE1)
		sbr	temp0, (1<<TOIE1)
		out	TIMSK, temp0
HiRESreset:						;3 rcall; Zero at rcall enter (Virtual); at exit always: 21
							;	; routine length with call: 21
		in	temp1, SREG			;1
		cli					;1
		out	TCCR1B, zero			;1	; stop timer

		ldi	temp0, 1<<TOV1			;1
		out	TIFR, temp0			;1	; reset if interrupt happens in the routine

		ldi	temp0, 16			;1	; time correction to virtual start
		out	TCNT1L, temp0			;1
		out	TCNT1H, zero			;1

		clr	htc_a				;1
		clr	htc_b				;1
		clr	htc_c				;1

		ldi	temp0, 0b001<<CS10		;1	; clock prescaler = 1
		out	TCCR1B, temp0			;1	; start timer1
								; 16 cycles from RCALL here
		out	SREG, temp1			;1
		ret					;4	; 5 cycles after

HiRESget:							; get time at rcall enter ZL:YH:YL:XH:XL
								; the rowtine eat always 25 cycles
							;3 rcall
		cli					;1
		in	XL, TCNT1L			;1
		in	XH, TCNT1H			;1
		movw	YL, htc_a			;1	; **** here real point of catch
		mov	ZL, htc_c			;1
		sei					;1

		adiw	XL, 2				;2	; time catch correction ( distance from IN TCNT1L and MOVW )
		brcs	hires_ovf			;1/2	; handle overflow internally
		nop					;1	; the routine cycles compensation
		nop					;1
		rjmp	hires_ok			;2
hires_ovf:						
		adiw	YL, 1				;2
		adc	ZL, zero			;1
hires_ok:

		subi	XL, 6				;1	; backward distance for 'rcall'
		sbc	XH, zero			;1
		sbc	YL, zero			;1
		sbc	YH, zero			;1
		sbc	ZL, zero			;1

		ret					;4	;25 total


ISR_HIRES:                                              ;4+2rjmp
		in	htc_sreg, SREG			;1
		subi	htc_a, -1			;1
		adc	htc_b, zero                     ;1
		adc	htc_c, zero                     ;1
		out	SREG, htc_sreg			;1
		reti					;4	; 15 total
