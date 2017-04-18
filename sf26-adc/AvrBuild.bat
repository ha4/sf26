@ECHO OFF
"C:\Program Files\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S labels.tmp -fI -W+ie -o sf26-adc.hex -d sf26-adc.obj -e sf26-adc.eep -m sf26-adc.map sf26-adc.asm
