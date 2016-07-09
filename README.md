Port to Ultibo





Oberon RISC Emulator for Pascal
===============================

translation of the Oberon Risc Emulator from
Peter De Wachter to Freepascal.

I was using:  

SDL2 headers translation for Free Pascal
  https://bitbucket.org/p_daniel/sdl-2-for-free-pascal-compiler
  from P. Daniel

SDL 
  Simple DirectMedia Layer
  Copyright (C) 1997-2013 Sam Lantinga <slouken@libsdl.org>
  [SDL2](http://libsdl.org/).

The Oberon bootload code 
  risc_boot.inc
from Paul Reed at http://projectoberon.com/

Original Project Oberon
  design and source code copyright © 1991–2014 Niklaus Wirth (NW) and Jürg Gutknecht (JG)
at http://www.inf.ethz.ch/personal/wirth/ProjectOberon/
or http://projectoberon.com/

Requirements: the freepacal compiler see: 

[Freepascal](https://github.com/graemeg/freepascal)
or
http://www.freepascal.org/

09.jun.2016
- Added the latest dsk file from Peter de Wachter
- removed 2 calls in SDL2.pas because they are not compatible with libSDL2-2.0.0
- will now try to port this program to [Ultibo](http://www.ultibo.org) 


===============================================================================================

below the orignal README.md from Peter de Wachter

===============================================================================================





Oberon RISC Emulator
====================

This is an emulator for the Oberon RISC machine. For more information, see:
http://www.inf.ethz.ch/personal/wirth/ and http://projectoberon.com/.

Requirements: a C99 compiler (e.g. [GCC](http://gcc.gnu.org/),
[clang](http://clang.llvm.org/)) and [SDL2](http://libsdl.org/).

A suitable disk image can be downloaded from http://projectoberon.com/ (in
S3RISCinstall.zip). **Warning**: Images downloaded before 2014-03-29 have
broken floating point.

Current emulation status
------------------------

* CPU
  * No known bugs.

* Keyboard and mouse
  * OK. Note that Oberon assumes you have a US keyboard layout and
    a three button mouse.
  * The left alt key can now be used to emulate a middle click.

* Display
  * OK. You can adjust the colors by editing `sdl-main.c`.
  * Use F11 to toggle full screen display.

* SD-Card
  * Very inaccurate, but good enough for Oberon. If you're going to
    hack the SD card routines, you'll need to use real hardware.

* RS-232
  * Implements PCLink protocol to send/receive single files at a time
    e.g. to receive Test.Mod into Oberon, run PCLink1.Start,
    then in host risc current directory, `echo Test.Mod > PCLink.REC`
  * Thanks to Paul Reed

* Network
  * Not implemented.

* LEDs
  * Printed on stdout.

* Reset button
  * Press F12 to abort if you get stuck in an infinite loop.


Copyright
---------

Copyright © 2014 Peter De Wachter

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted, provided that the
above copyright notice and this permission notice appear in all
copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
