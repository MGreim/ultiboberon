PROGRAM ultiboberont;

{$mode objfpc}{$H+}

//06.jul.2016
//- is now also compiling on wine but yu have to adapt the paths
//to drive Z: in /home/markus/Ultibo/Core/fpc/3.1.1/bin/i386-win32/rpi2.cfg

// 03.jul.2016 MG
// Extended Example 3 incl. the latest mouse example
// No. 15-MouseCursor.
//  + Bresenham line drawing algorithm
//  + loading an individual 32x32 pixel mouse cursor from an ASCII pnm file.
// only tested on Raspi2 with a 1280 x 1024 screen
// The standard file assign / reset / readln seems to work but eof seems to crash


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
// Graphic
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
 ledon : Boolean;
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



PROCEDURE toggleLED;

          BEGIN
          ledon := NOT(ledon);
          IF ledon THEN ActivityLEDON ELSE ActivityLEDOff;
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
                  mykeyboard2 := KeyboardData.ScanCode;
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
              toggleLED;
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
    init_texture;
    riscmainloop;

 {We're not doing a loop this time so we better halt this thread before it exits}
 ThreadHalt(0);
END.

