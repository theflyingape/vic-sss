@echo on
ca65.exe --cpu 6502 -t vic20 --listing --include-dir . vic-sss4.s
ca65.exe --cpu 6502 -t vic20 --listing --include-dir . -o sample.o basic-8K.s
ld65.exe -C basic-8k.cfg -Ln sample.sym -m sample.map -o ..\ca65-sprite.prg sample.o vic-sss4.o
@echo off

choice /C DMV /D M /T 30 /M "[D]ebug, [M]ESS, or [V]ICE? " /N
set CHOICE=%ERRORLEVEL%
cd ..

if %CHOICE% EQU 1 mess -debug -window -natural -skip_gameinfo -skip_warnings vic20 -ramsize 16k -quik ca65-sprite.prg
if %CHOICE% EQU 2 mess -skip_gameinfo -skip_warnings -newui vic20 -ramsize 16k -quik ca65-sprite.prg
if %CHOICE% EQU 3 xvic -memory 8k -autostart ca65-sprite.prg

exit
