# vic-sss
Commodore VIC20: Software Sprite Stack library using modern 6502 assembler

I have found that programming for an 8-bit computer is a very challenging, yet 
personally rewarding, experience:

VIC-SSS provides a programmer-friendly API to manage your game's playfield with 
software-rendered sprites and other animations for a flicker-free video 
experience. On-the-fly custom character manipulations with dual video buffers 
accomplish these goals, avoiding the alternative of dedicating all internal RAM 
for a smaller, but fully, bit-mapped screen. This API supports both NTSC and 
PAL VIC 20 computers, and allows for display modes that change VIC's 22x23 
screen layout.

The software sprite stack promotes a flicker-free video experience, with the 
option by the game programmer to govern frame buffer flips with screen raster 
timing. While the VIC 20 computer and its graphics are primitive to begin with, 
this API was created to strike a balance between machine and programmer 
friendliness – which is what the VIC is all about. The result of that 
friendliness makes the code size around 2 kilobytes and requires nearly all of 
the internal 4 kilobytes of RAM for graphics display and management. Thus, your 
game program will require some form of memory expansion – all examples provided 
will run on 8k expansion.

