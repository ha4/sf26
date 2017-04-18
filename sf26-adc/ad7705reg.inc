; ------------------------------------------------------------------------------------------------
; AD7705 registers and bits
;

.equ REG_COMM		= 0b00000000
.equ REG_SETUP		= 0b00010000
.equ REG_CLOCK		= 0b00100000
.equ REG_DATA16		= 0b00110000
.equ REG_TEST		= 0b01000000
.equ REG_OFFSET24	= 0b01100000
.equ REG_GAIN24		= 0b01110000

; communication register (COMM)
; RS: register select
; R_nW: 1-read,0-write
; STBY: 0-normal,1-power down
;           +      -     cal. register 
; CH:00   AIN1+  AIN1-     #0
;    01   AIN2+  AIN2-    #1
;    10   AIN1-  AIN1-     #0
;    11   AIN1-  AIN2-    #2
;
; (AIN1+) PIN#7
; (AIN1-) PIN#8
; (AIN2+) PIN#6
; (AIN2-) PIN#11

.equ nDRDY		= 7
.equ RS2		= 6
.equ RS1		= 5
.equ RS0		= 4
.equ R_nW		= 3
.equ STBY		= 2
.equ CH1		= 1
.equ CH0		= 0


; setup register (SETUP)
; MD1,0: 00-work
;        01-self calibration
;        10-zero system calibration
;        11-full scale system calibration
; G2-0: 000..111: gain 1, 2, 4, 8,  16, 32, 64, 128
; nB_U: 0-bipolar, 1-unipolar;
; BUF: 0-no input buffer, 1-on, higher source impedance
; FSYNC: 1-reset filters, 0-start working

.equ MD1		= 7
.equ MD0		= 6
.equ G2			= 5
.equ G1			= 4
.equ G0			= 3
.equ nB_U		= 2
.equ BUF		= 1
.equ FSYNC		= 0

; clock register (CLOCK): 0 0 0 DIS - DIV CLK FS1 FS0
; bits 7,6,5 should be 0 (ZERO)
;
; CLKDIS: 1-disable, 0-normal
; CLKDIV: 1-MCLK div by2, 0-no division
; CLK: 0 - 2.4576Mhz mode
;      1 - 1.0000Mhz mode
;
; sample rate @CLK=0      @CLK=1
; FS:00   20Hz          50Hz
;    01   25Hz          60Hz
;    10  100Hz         250Hz
;    11  200Hz         500Hz

.equ CLKDIS		= 4
.equ CLKDIV		= 3
.equ CLK		= 2
.equ FS1		= 1
.equ FS0		= 0


; ------------------------------------------------------------------------------------------------
; AD7705 END
;
