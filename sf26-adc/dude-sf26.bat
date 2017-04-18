PATH %PATH%;C:\Program Files\winavr\bin
avrdude -c usbtiny -p t2313 -U flash:w:sf26-adc.hex -U lfuse:w:0xed:m
@rem lfuse:w:0xed:m  - 4Mhz
@rem lfuse:w:0x64:m  - default 1Mhz internal
@rem lfuse:w:0xE4:m  - 8Mhz internal
