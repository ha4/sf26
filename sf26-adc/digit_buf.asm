; ------------------------------------------------------------------------------------------------
; digit buffer fill
;

		push	temp0

		cpi	temp0, 10
		breq	digit_end
		cpi	temp0, 13
		breq	digit_end

		cpi	temp0, 'a'
		brlo	not_tolower
		andi	temp0, 0b11011111
not_tolower:
		; str2hex digit
		subi	temp0, '0'
		cpi	temp0, 10
		brlo	digit_ok
		subi	temp0, 7				; ' distance from 9
		cpi	temp0, 10
		brlo	digit_error
		cpi	temp0, 16
		brsh	digit_error
		; str2hex end
digit_ok:
		; buf * 16
;		ldi	temp1, 0x0F
;		and	buf2, temp1				; AB CD EF ->
;		swap	buf2					;          -> B0 CD EF
;		swap	buf1					; B0 CD EF -> B0 DC EF
;		mov	temp2, buf1				;             B0 DC EF
;		and	temp2, temp1				; temp2:         0C
;		eor	buf1, temp2				;             B0 D0 EF
;		or	buf2, temp2				;         ->  BC D0 EF
;		swap	buf0					; BC D0 EF -> BC D0 FE
;		mov	temp2, buf0				;             BC D0 FE
;		and	temp2, temp1				; temp2:            0E
;		eor	buf0, temp2				;             BC D0 F0
;		or	buf1, temp2				;         ->  BC DE F0

		lsl	buf0
		rol	buf1
		rol	buf2
		lsl	buf0
		rol	buf1
		rol	buf2
		lsl	buf0
		rol	buf1
		rol	buf2
		lsl	buf0
		rol	buf1
		rol	buf2

		add	buf0, temp0

		dec	bufn
		pop	temp0
		breq	digit_last
		rjmp	digit_put

digit_error:
		pop	temp0
		ldi	temp0,'?'
digit_end:	
		clr	bufn
		ldi	temp0, 10				; CR
digit_put:
		rcall	UARTsend
		rjmp	MainLoop
digit_last:
		rcall	UARTsend
		rcall	UARTcr
		rjmp	MainLoop

