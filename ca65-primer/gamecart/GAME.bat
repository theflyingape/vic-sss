@echo on
ca65.exe --cpu 6502 --listing --include-dir . GAME.sld65.exe -C GAME.cfg -m GAME.map -o GAME.a0 GAME.o VIC-SSS-MMX.o
pause
REM xvic -ntsc -sound -memory none -cartA GAME.a0
exit
