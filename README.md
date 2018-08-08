# Flexible EasyFlash Loader
EasyFlash loader with usage examples, demonstrating a rather useful scenario involving:
- IRQ-driven tune playback while loading, and 
- moving data under I/O while handling IRQ requests.

## Notes
- Assemble source files with [ACME cross-assembler](https://sourceforge.net/projects/acme-crossass/). Version 0.96.4 has been successfully tested.
- To use the provided `Makefile` you need GNU `make`.

## CRT image
To create the CRT image, the tool `bin2efcrt` is used. This is invoked with a relative path, `../tools`: simply build this tool first and then come back to this example.\
To test the cartridge in a *recent* version of [VICE Emulator](http://vice-emu.sourceforge.net), run `x64 -cartcrt loader.crt` or attach it using "File => Attach cartridge image... => CRT Image...". You can also write it to your EasyFlash.

## Loading under I/O directly
The "load_under_io" folder provides *replacement* files for loading directly under I/O, which is discouraged as it involves quite some overhead (to backup/restore $01 and the I flag).

## Productions that use this loader
This loader was used to put together my [EasyFlash version of Last Ninja 2](https://csdb.dk/release/?id=167043).

## Left as an exercise
- Refactor the project structure to make examples "pluggable" into the main loader.
- Make good use of empty areas within the first two memory banks.
- Add support for data crunchers. The drawback here is that decrunching increases loading times.