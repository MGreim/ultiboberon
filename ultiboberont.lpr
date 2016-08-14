PROGRAM ultiboberont;

{$mode objfpc}{$H+}


//# ULTIBOBERON / Port of Peter de Wachters OBERON RISC  Emulator to Ultibo

//14.08.2016
//To do:
//- serial GPIO etc.
//- test on RPI 0, 1, 3


//# Hints, Design, Problems, To do's etc.
// 13.08.2016
//1. The software is __pre-beta__!
//2. There is a bug in the USB interface in Ultibo. You __must__ use an USB hub to
// connect mouse and keyboard. At least one of both must be connected via the hub.
//There seems to be a DMA problem for slow HID devices. Its a known issue.
//3. Due to lack of time, I have the code only tested for the RPI2.
//4. I have realised the sw in one single thread follwing Wirths original design.
//5. The code is not optimized for performance at all.
//6. The RISC5 code and the FPU code is from 2014, the latest FPU improvements
//etc. are not coded yet.
//7. The OBERON file system is encapsulated in one single file oberon.dsk, it
//would be nice for sure, to mirror it in FAT or similar.
//8. The disk image is from Peter de Wachter at:
//https://github.com/pdewacht/oberon-risc-emu/blob/master/DiskImage/Oberon-2016-08-02.dsk
//9. Ultibo has no command line options, so everything is hard coded.
//10. the F4 and F12 keys are not working yet.
//11. For Non-Oberonians: Before you play with the software please read:
//https://www.inf.ethz.ch/personal/wirth/ProjectOberon/UsingOberon.pdf
//The using of the mouse and the windows (here called viewers) is different
//from the Windows or OsX world. Even if Allen, Wozniak, Gates and Jobs said that
//they have been at least "inspired" by the ALTO system they had seen at Xerox.
//12. You need a 3 button mouse.
//13. .. and many more..

//06.jul.2016
//- is now also compiling on wine but yu have to adapt the paths
//to drive Z: in /home/markus/Ultibo/Core/fpc/3.1.1/bin/i386-win32/rpi2.cfg

(******************************************************************************)
//
//# ULTIBOBERON / Port of Peter de Wachters OBERON RISC  Emulator to Ultibo
//============================================
//[Ultibo](http://www.ultibo.org)
//
//## For the Oberonians:
//--------------------
//
//### What is Ultibo ?
//
//citation from the Ultibo web-site:
//
//"Ultibo core is an embedded or bare metal development environment for Raspberry Pi.
//It is not an operating system but provides many of the same services as an OS,
//things like memory management, networking, filesystems and threading plus
//much more."
//
//What they write only in the footnote is:
//
//"Ultibo is written entirely in Free Pascal and is designed to act as a unikernel
//or a kernel in a run time library. That means when you compile your application
//the necessary parts of Ultibo are automatically included by the compiler so
//that your program runs without needing an operating system."
//
//For all, not yet knowing what the Raspberry Pi is:
//
//### What is the Raspberry Pi ?
//"The Raspberry Pi is a series of credit card-sized single-board computers
//developed in the United Kingdom by the Raspberry Pi Foundation to promote the
//teaching of basic computer science in schools and developing countries"
//https://en.wikipedia.org/wiki/Raspberry_Pi
//
//And the most important thing: The RPI is cheap:
//The smallest model costs here in Germany incl. tax 15 EUR, the biggest iron
//38 EUR. Here we have 4 ARM cores @ 1 GHz, HDMI, USB, Network interface, PIO, LED,audio, etc. etc. + 1 GByte + SD card etc.
//
//The RPI is mostly used with LINUX. That's nice but with LINUX you are far, far
//away from the hardware. And its quite crazy for my opinion, to use Gigabytes
//of code to blink a LED.
//
//###So what is Ultibo for me:
// The ideal tool! You have more or less infinite RAM and power,
//you can and MUST write all programs in PASCAL, and you have with Lazarus
//a real nice and fast development environment for Windows and Linux (with Wine)
//
//
//## For the Ultiboys and Ultigirls:
//
//### What is OBERON:
//1. OBERON is a programming language designed from 1988 by the Turing award winner
// Niklaus Wirth, the inventor of PASCAL and some other programming languages.
//OBERON is quite similar to PASCAL with object extension and units as known from
//Turbo Pascal 6.0+.
//2. OBERON is also, and that's sometimes confusing,  the name of a complete operating
// system, including graphical user interface with mouse control, an editor, compiler, libraries etc.
//Wirth was 1977/78 at the XEROX park labs in Palo Alto, where he worked with the
//ALTO workstation. This was the first computer with a mouse and a graphical user
//interface. In 1986 Wirth developed his own 32bit computer called CERES incl.
//his own operating system written in his own language called OBERON.
//From 2013 Wirth was developing a new workstation based on one single FPGA and called it
//__Project OBERON__. See http://www.projectoberon.com/ or
//http://www.xilinx.com/support/documentation/xcell_articles/91-5-oberon-system-implemented-on-a-low-cost-fpga-board.pdf
//or
//https://www.computer.org/csdl/mags/co/2012/07/mco2012070008.pdf
//
//The complete system including the kernel, the editor, the compiler and the GUI
//has about 10000 (ten thousand) lines of code. The Linux 4.x kernel has about 15 million lines of code.
//
//
//
//## For both:
//Project Oberon aka FPGA OBERON is a very interesting system, but fiddling around with FPGAs,
// especially with the development environments of Xilinx or Altera is, friendly spoken, demanding.
// Even producing a video signal for a modern interface like HDMI or display port with a FPGA
// is for example 10 times more complex then the whole so called RISC5 processor for the Project OBERON.
//
//In 2014 Peter de Wachter has written an emulator for Project OBERON on the PC.
//A nice project, but written in C, a non-Wirthian languge. So i made a port of his program to (Free)-Pascal. The emulator works fine, but making the graphic
//and the mouse interface with the SDL library was a typical example for the
//complexity of Linux and Windows.
//
//## My intension to bring OBERON to Ultibo on the RPI:
//
//0. Having a total type save Wirthian system!
//1. A proof of concept and test for Ultibo.
//2. Having an OBERON system for 15 EUR
//3. Having direct hardware access from OBERON. Up to now only the Blink.Run works, but integrate GPIO, the serial interface etc. may be done with only a few
//lines of code.
//4. Its quite easy to expand OBERON with some TCP/IP functionality, which is already part of the Ultibo libraries.
//5. Maybe in the future OBERON can be used as a kind of inelligent shell, including
//editor, compiler etc. for Ultibo.
//
//
//#Licenses
// Copyright: (c) Markus Greim, August 2016
//Permission to use, copy, modify, and/or distribute this software for
//any purpose with or without fee is hereby granted, provided that the
//below copyright notice and this permission notice appear in all
//copies.
//
//THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
//WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
//WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
//AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
//DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
//PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
//TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
//PERFORMANCE OF THIS SOFTWARE.

//
//##Ultibo
//core is licensed under the GNU Lesser General Public License v2.1 and is
//freely available to use, modify and distribute within the terms of the license.
//The license includes an exception statement to permit static linking with files
//that are licensed under different terms.
//
//##Free-Pascal
//http://www.freepascal.org/faq.var#general-license
//
//##Oberon
//Project Oberon, Revised Edition 2013
//
//Book copyright (C)2013 Niklaus Wirth and Juerg Gutknecht;
//software copyright (C)2013 Niklaus Wirth (NW), Juerg Gutknecht (JG), Paul
//Reed (PR/PDR).
//
//Permission to use, copy, modify, and/or distribute this software and its
//accompanying documentation (the "Software") for any purpose with or
//without fee is hereby granted, provided that the above copyright notice
//and this permission notice appear in all copies.
//
//THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHORS DISCLAIM ALL WARRANTIES
//WITH REGARD TO THE SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF
//MERCHANTABILITY, FITNESS AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
//AUTHORS BE LIABLE FOR ANY CLAIM, SPECIAL, DIRECT, INDIRECT, OR
//CONSEQUENTIAL DAMAGES OR ANY DAMAGES OR LIABILITY WHATSOEVER, WHETHER IN
//AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//CONNECTION WITH THE DEALINGS IN OR USE OR PERFORMANCE OF THE SOFTWARE.
//
//
//##All other copyright things below, I hope.
//
//Below the Radme file of the original port:
//
//Oberon RISC Emulator for Pascal
//===============================
//
//translation of the Oberon Risc Emulator from
//Peter De Wachter to Freepascal.
//
//I was using:
//
//SDL2 headers translation for Free Pascal
//  https://bitbucket.org/p_daniel/sdl-2-for-free-pascal-compiler
//  from P. Daniel
//
//SDL
//  Simple DirectMedia Layer
//  Copyright (C) 1997-2013 Sam Lantinga <slouken@libsdl.org>
//  [SDL2](http://libsdl.org/).
//
//The Oberon bootload code
//  risc_boot.inc
//from Paul Reed at http://projectoberon.com/
//
//Original Project Oberon
//  design and source code copyright © 1991–2014 Niklaus Wirth (NW) and Jürg Gutknecht (JG)
//at http://www.inf.ethz.ch/personal/wirth/ProjectOberon/
//or http://projectoberon.com/
//
//Requirements: the freepacal compiler see:
//
//[Freepascal](https://github.com/graemeg/freepascal)
//or
//http://www.freepascal.org/
//
//09.jun.2016
//- Added the latest dsk file from Peter de Wachter
//- removed 2 calls in SDL2.pas because they are not compatible with libSDL2-2.0.0
//
//you may find this code at:
//
//https://github.com/MGreim/riscpas_repo
//
//================================================================================
//
//below the orignal README.md from Peter de Wachter
//
//================================================================================
//
//
//
//
//
//Oberon RISC Emulator
//====================
//
//This is an emulator for the Oberon RISC machine. For more information, see:
//http://www.inf.ethz.ch/personal/wirth/ and http://projectoberon.com/.
//
//Requirements: a C99 compiler (e.g. [GCC](http://gcc.gnu.org/),
//[clang](http://clang.llvm.org/)) and [SDL2](http://libsdl.org/).
//
//A suitable disk image can be downloaded from http://projectoberon.com/ (in
//S3RISCinstall.zip). **Warning**: Images downloaded before 2014-03-29 have
//broken floating point.
//
//Current emulation status
//------------------------
//
//* CPU
//  * No known bugs.
//
//* Keyboard and mouse
//  * OK. Note that Oberon assumes you have a US keyboard layout and
//    a three button mouse.
//  * The left alt key can now be used to emulate a middle click.
//
//* Display
//  * OK. You can adjust the colors by editing `sdl-main.c`.
//  * Use F11 to toggle full screen display.
//
//* SD-Card
//  * Very inaccurate, but good enough for Oberon. If you're going to
//    hack the SD card routines, you'll need to use real hardware.
//
//* RS-232
//  * Implements PCLink protocol to send/receive single files at a time
//    e.g. to receive Test.Mod into Oberon, run PCLink1.Start,
//    then in host risc current directory, `echo Test.Mod > PCLink.REC`
//  * Thanks to Paul Reed
//
//* Network
//  * Not implemented.
//
//* LEDs
//  * Printed on stdout.
//
//* Reset button
//  * Press F12 to abort if you get stuck in an infinite loop.
//
//
//Copyright
//---------
//
//Copyright © 2014 Peter De Wachter
//
//Permission to use, copy, modify, and/or distribute this software for
//any purpose with or without fee is hereby granted, provided that the
//above copyright notice and this permission notice appear in all
//copies.
//
//THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
//WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
//WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
//AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
//DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
//PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
//TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
//PERFORMANCE OF THIS SOFTWARE.


(*****************************************************************************)



{Declare some units used by this program.}
USES
// Units to run Ultibo
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  BCM2836,
  BCM2709,
  SysUtils,
  Console,
  GraphicsConsole,


  // With this following block of units we can update
  // the SD card via telnet. The remote computer is xx.29
  // the path is /var/www
  // unfortunately a sunbdirectory doesnt work with my apache2
  // not required, only helpful for rapid developement
  // otherwise you have to fiddle around
  // with the SD card.
//----------------------------------------------------------------------
   Shell,           {Add the Shell unit just for some fun}
   ShellFileSystem, {Plus the File system shell commands}
   ShellUpdate,     //<- Add this extra one to enable the update commands
   RemoteShell,     {And the RemoteShell unit so we can Telnet to our Pi}
   SMSC95XX,        {And the driver for the Raspberry Pi network adapter}
//--------------------------------------------------------------
  // Mouse and Keyboard

  DWCOTG,          {We need to include the USB host driver for the Raspberry Pi}
  Mouse,
  Keyboard, {Keyboard uses USB so that will be included automatically}

// All the Oberon stuff
  risccore, riscglob, riscps2;

const
BLACK = $657b83;
WHITE = $fdf6e3;


TYPE
cachety =  ARRAY[0..Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT DIV 32)] of uint32_t;
bufferty = ARRAY[0..Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT)] OF uint32_t;
bufferxyty = ARRAY[0..pred(RISC_SCREEN_WIDTH), 0..pred(RISC_SCREEN_HEIGHT)] OF uint32;


VAR
 GraphicHandle1 :TWindowHandle;
 cache: cachety;
 buffer, bufferlin: bufferty;
 bufferxy : bufferxyty;
 neux, neuy, altx , alty : longint;

 mybutton : integer;


PROCEDURE init_texture;
     VAR i : longint;
         xi, yi : longint;

     BEGIN
     fillchar(cache,sizeof(cache), 0);

       FOR  i := 0 TO Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT) DO

           BEGIN
             buffer[i] := BLACK;
           END;

       FOR  xi := 0 TO Pred(RISC_SCREEN_WIDTH) DO

           BEGIN
           FOR  yi := 0 TO Pred(RISC_SCREEN_HEIGHT) DO
               BEGIN
                 bufferxy[xi, yi] := BLACK;
               END;

           END;

     GraphicsWindowDrawImage(GraphicHandle1, 1, 1, @buffer, RISC_SCREEN_WIDTH, RISC_SCREEN_HEIGHT,COLOR_FORMAT_UNKNOWN);
//         FrameBufferConsoleDrawImage(ConsoleDeviceGetDefault, 1, 1, @buffer, RISC_SCREEN_WIDTH, RISC_SCREEN_HEIGHT,COLOR_FORMAT_UNKNOWN, 0);

    END;






PROCEDURE update_texture(framebufferpointer : uint32_t);

      VAR


        idx: integer;
        pixels: uint32_t;
        ptr: Pointer;


        line, ymin, ymax, yi, laufy : 0..RISC_SCREEN_HEIGHT;
        col, xmin, xmax, xi, laufx  : 0..RISC_SCREEN_WIDTH;
        bufferindex, i : 0..RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT;
        b : 0..pred(32);

        BEGIN (* TODO: move dirty rectangle tracking into emulator core?*)
          ymin := RISC_SCREEN_HEIGHT;
          ymax := 0;
          xmin := RISC_SCREEN_WIDTH;
          xmax := 0;

          idx := 0;
          FOR line := RISC_SCREEN_HEIGHT-1 DOWNTO 0 DO

             BEGIN
               FOR col := 0 TO pred(RISC_SCREEN_WIDTH DIV 32) DO
                   BEGIN
                     pixels := risc.RAM[idx+framebufferpointer];
                     IF pixels <> cache[idx] THEN
                         BEGIN
                           cache[idx] := pixels;

                           bufferindex := line*RISC_SCREEN_WIDTH + col * 32;
                           yi := line;
                           IF yi < ymin THEN ymin := yi;
                           IF yi > ymax THEN ymax := yi;


                             FOR b := 0 TO Pred(32) DO

                                   BEGIN
                                     xi := col * 32 +b;

                                     IF (pixels AND 1) > 0 THEN buffer[bufferindex] := WHITE ELSE buffer[bufferindex] := BLACK;
                                     IF (pixels AND 1) > 0 THEN bufferxy[xi, yi] := WHITE ELSE bufferxy[xi, yi] := BLACK;
                                     IF xi < xmin THEN xmin := xi;
                                     IF xi > xmax THEN xmax := xi;
                                     inc(bufferindex);
                                     pixels := pixels SHR 1;
                                   END;
                         END;(*IF*)
                     inc(idx);
                   END;(*for col *)
             END;(*for line *)

//         GraphicsWindowDrawImage(GraphicHandle1, 0, 0, @buffer, RISC_SCREEN_WIDTH, RISC_SCREEN_HEIGHT,COLOR_FORMAT_UNKNOWN);

           i := 0;
          IF ymin <= ymax THEN

               BEGIN

                 FOR laufy := ymin TO ymax DO

                     BEGIN
                       FOR laufx := xmin TO xmax DO
                                 BEGIN
                                   bufferlin[i] := bufferxy[laufx, laufy];
                                   inc(i);
                                 END;
                     END;

                   ptr:= @bufferlin;
                   GraphicsWindowDrawImage(GraphicHandle1, xmin, ymin, ptr, (xmax - xmin +1), (ymax - ymin +1),COLOR_FORMAT_UNKNOWN);

               END;
        END;


FUNCTION clamp(x, min, max : integer) : integer;

        VAR z : integer;

        BEGIN
        z := round(x);
        clamp := z;
        IF z < min THEN clamp := min;
        IF z > max THEN clamp := max;
        END;



PROCEDURE mymouse;

        VAR
           MouseData:TMouseData;
           mcount : longword;


        BEGIN
        IF MousePeek = ERROR_SUCCESS THEN
             BEGIN
             if MouseRead(@MouseData,SizeOf(MouseData),mCount) = ERROR_SUCCESS then
                BEGIN
                   neux := altx + MouseData.OffsetX;
                   neuy := alty + MouseData.OffsetY;
                   neux := clamp(neux, 0, RISC_SCREEN_WIDTH);
                   neuy := clamp(neuy, 0, RISC_SCREEN_HEIGHT);
                   IF ((neux <> altx) OR (neuy <> alty)) THEN risc.mouse_moved(neux, RISC_SCREEN_HEIGHT-neuy -1);
                   altx := neux;
                   alty := neuy;
                   IF MouseData.Buttons <> 0 THEN

                        BEGIN
                        mybutton := 0;
                        IF (MouseData.Buttons and MOUSE_LEFT_BUTTON)   <> 0 THEN mybutton := 1;
                        IF (MouseData.Buttons and MOUSE_MIDDLE_BUTTON) <> 0 THEN mybutton := 2;
                        IF (MouseData.Buttons and MOUSE_RIGHT_BUTTON)  <> 0 THEN mybutton := 3;
                        IF mybutton > 0 THEN
                             BEGIN
                             risc.mouse_button(mybutton, True);
                             END;
                        END
                      ELSE
                        BEGIN
                        IF mybutton > 0 THEN
                            BEGIN
                            risc.mouse_button(mybutton, False);
                            mybutton := 0;
                            END;
                        END;

                   MouseFlush;

                END;

             END; (* END MousePeek *)
         END;

FUNCTION mykeyboard : longword;

        VAR

        KeyBoardData : TKeyboardData;
        Count : longword;
        mymode_ : word;
        mymake  : Boolean;

       scancode_s : string;
       len : 0..pred(maxkeybufsize);
       l   : 0..pred(maxkeybufsize);
       scancode: keybufty;


          BEGIN
          IF keyboardPeek = ERROR_SUCCESS THEN
              BEGIN

              IF (KeyboardRead(@KeyboardData,SizeOf(KeyboardData), Count) = ERROR_SUCCESS) THEN

                  BEGIN
                  mykeyboard := KeyboardData.ScanCode;
                  mymode_ := 0;
                  mymake := False;
                  IF (((KeyboardData.Modifiers AND $4000) > 0) OR ((KeyboardData.Modifiers AND $8000) > 0)) THEN mymake := True;
                  IF ((KeyboardData.Modifiers AND $2000) > 0)  THEN mymake := False;
                  mymode_ := KeyboardData.Modifiers AND $0FFF;
                  len := ps2_encode(KeyboardData.ScanCode,mymake, mymode_, scancode_s);
                            IF len > 0 THEN

                                BEGIN
                                FOR l := 0 TO pred(len) DO

                                        BEGIN
                                        scancode[l] := ord(scancode_s[succ(l)]);
                                        END;
                                 END;
                  risc.keyboard_input(scancode, len);
                  END;

              END;

          END;




PROCEDURE riscmainloop;

    VAR
       done: bool;
       frame_start: longword;
       frame_end, starttime: longword;

       mydelay, counter: longint;

    BEGIN

         risc.init('C:\oberon.dsk', '', '');
         done := False;

         starttime := getTickCount64;
         counter := 0;
         neux := 0;
         neuy := 0;
         altx := 0;
         alty := 0;
         WHILE NOT(done) DO

            BEGIN
              frame_start := getTickCount64 - starttime;
              risc.set_time(frame_start);
              mykeyboard;
//              sleep(1);
              mymouse;
//              toggleLED;
              risc.run(CPU_HZ DIV FPS);
              inc(counter);
              update_texture(risc.get_framebuffer_ptr);

              frame_end := getTickCount64 - starttime;
              mydelay := frame_start + (1000 div FPS) - frame_end;

              IF ((mydelay > 0) AND (mydelay < 20)) THEN sleep(mydelay);

              exitcode := 0;
           END; (* while not done *)
        risc.done;

    END; (* proc *)






BEGIN

    GraphicHandle1 := GraphicsWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_FULL);
    ActivityLEDEnable;
    init_texture;
    riscmainloop;

 {We're not doing a loop this time so we better halt this thread before it exits}
 ThreadHalt(0);
END.

