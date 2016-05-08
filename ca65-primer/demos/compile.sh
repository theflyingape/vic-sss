#!/bin/sh
#
set -o xtrace
ca65 --cpu 6502 --listing --include-dir .. bigdudes.s
ld65 -C ../basic+8k.cfg -o bigdudes.prg ../basic.o bigdudes.o ../VIC-SSS-MMX.o
ca65 --cpu 6502 --listing --include-dir .. hello.s
ld65 -C ../basic+8k.cfg -o hello.prg ../basic.o hello.o ../VIC-SSS-MMX.o
set +o xtrace

echo -n "Press RETURN: " && read N

# UNCOMMENT YOUR CHOICE OF EMULATORS ...

#mess -debug vic20 -ramsize 16k -quik demo.prg
#xvic -memory 8k -autostart demo.prg

exit

