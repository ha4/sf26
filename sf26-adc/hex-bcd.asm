*******************************************************************
* HEXADECIMAL to BCD CONVERSION                                   *
* Set one byte of HEXADECIMAL to be converted into Digit register *
* Result in Digit+1 register (Units & Tens),                      *
*        in Digit+2 register (Hundreds)                           *
*******************************************************************
.nolist
$include "fr908QT2.asm"; Frame file of uC 908QT
.list
********* VARIABLES   ***************************
          org   RAM
Digit     rmb  3  ;Digit  - HEX
                  ;Digit+1- BCD Units & Tens
                  ;Digit+2- BCD Hundreds & Thousands
N         rmb  1  ;shifts counter
********** INITIALIZATION    ***************************
          org   ROM
init      rsp                ;reset stack pointer to $ff
          mov   #$01,CONFIG1 ;COP disable
          clrA
          clrX
          clrH
********************************************************
; for testing set Hexadecimal number $FF to be converted
HEX       equ    $ff
********************************************************
Start     mov    #HEX,Digit
          clr    Digit+1
          clr    Digit+2
          clr    N
chkUNIT   lda    Digit+1
          and    #$0f      ;separate Units
          cmp    #$05
          blo    chkTEN    ;if Unit<5,go to chkTEN
          lda    Digit+1
          add    #$03
          sta    Digit+1
chkTEN    lda    Digit+1
          and    #$f0      ;separate Tens
          cmp    #$50
          blo    chkHUNDR  ;if Tens<5,go to chkHUNDR
          lda    Digit+1
          add    #$30
          sta    Digit+1
chkHUNDR  lda    Digit+2
          and    #$0f      ;separate Hundreds
          cmp    #$05
          blo    shift     ;if Hundreds<5,go to shift
          lda    Digit+2
          add    #$03
          sta    Digit+2
shift     lsl    Digit
          rol    Digit+1
          rol    Digit+2
          inc    N         ;is it the last shift?
          lda    N
          cmp    #8
          blo    chkUNIT
exit      rts
*********************************************************
        org   RESET
        fdb   init
.end
.nolist

