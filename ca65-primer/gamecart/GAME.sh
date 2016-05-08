#!/bin/sh
#

TITLE=demo

set -o xtrace
ca65 --cpu 6502 --listing --include-dir . -o VIC-SSS-MMX.o ../VIC-SSS-MMX.s
ca65 --cpu 6502 --listing --include-dir . $TITLE.s
ca65 --cpu 6502 --listing --include-dir . GAME.s
ld65 -C GAME.cfg -Ln $TITLE.sym -m $TITLE.map -o $TITLE.a0 GAME.o $TITLE.o VIC-SSS-MMX.o
ca65 --cpu 6502 --listing --include-dir . -o basic.o ../basic.s
ld65 -C ../basic+8k.cfg -o ../demos/$TITLE.prg basic.o $TITLE.o VIC-SSS-MMX.o
set +o xtrace

echo -n "Press RETURN: " && read N

# UNCOMMENT YOUR CHOICE OF EMULATORS ...

#mess -debug vic20 -cart $TITLE.a0
#xvic -cartA $TITLE.a0

exit

