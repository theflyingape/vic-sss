#!/bin/sh
#

TITLE=ca65-sprite

set -o xtrace
ca65 --cpu 6502 --listing --include-dir . basic.s
ca65 --cpu 6502 --listing --include-dir . $TITLE.s
ca65 --cpu 6502 --listing --include-dir . VIC-SSS-MMX.s
ld65 -C basic+8k.cfg -Ln $TITLE.sym -m $TITLE.map -o $TITLE.prg basic.o $TITLE.o VIC-SSS-MMX.o
set +o xtrace

echo -n "Press RETURN: " && read N

# UNCOMMENT YOUR CHOICE OF EMULATORS ...

#mess -debug vic20 -ramsize 16k -quik $TITLE.prg
#xvic -memory 8k -autostart $TITLE.prg

exit

