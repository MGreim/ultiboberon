program ultiboberont;

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



{ Example 03 Screen Output                                                     }
{                                                                              }
{  This example builds on the previous ones by demonstrating some of the console}
{  functions available in Ultibo and how to use them to manipulate text on the }
{  screen.                                                                     }
{                                                                              }
{  To compile the example select Run, Compile (or Run, Build) from the menu.   }
{                                                                              }
{  Once compiled copy the kernel7.img file to an SD card along with the        }
{  firmware files and use it to boot your Raspberry Pi.                        }
{                                                                              }
{  Raspberry Pi 2B version                                                     }
{   What's the difference? See Project, Project Options, Config and Target.    }

{Declare some units used by this example.}
uses
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  Console,
  GraphicsConsole,
  Framebuffer,
  BCM2836,
  BCM2709,
  SysUtils,


  // With this following block of units we can update
  // the SD card via telnet. The remote computer is xx.29
  // the path is /var/www
  // unfortunately a sunbdirectory doesnt work with my apache2
//----------------------------------------------------------------------
 Shell,           {Add the Shell unit just for some fun}
 ShellFileSystem, {Plus the File system shell commands}
 ShellUpdate,     //<- Add this extra one to enable the update commands
 RemoteShell,     {And the RemoteShell unit so we can Telnet to our Pi}
 SMSC95XX,        {And the driver for the Raspberry Pi network adapter}
//--------------------------------------------------------------

  Mouse,
  Keyboard, {Keyboard uses USB so that will be included automatically}
  DWCOTG,          {We need to include the USB host driver for the Raspberry Pi}

  risccore, riscglob, riscps2;

const
BLACK = $657b83;
WHITE = $fdf6e3;


TYPE
cachety =  ARRAY[0..Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT)] of uint32_t;
bufferty = ARRAY[0..Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT)] OF uint32_t;




{We'll need a few more variables for this example.}
var
 GraphicHandle1 :TWindowHandle;
 cache: cachety;
 buffer: bufferty;
 ledon : Boolean;
 neux, neuy, altx , alty : longint;

 mybutton : integer;



PROCEDURE init_texture;
     VAR i : longint;

     BEGIN
    fillchar(cache,sizeof(cache), 0);

       FOR  i := 0 TO Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT) DO

           BEGIN
             buffer[i] := BLACK;
           END;
           GraphicsWindowDrawImage(GraphicHandle1, 1, 1, @buffer, RISC_SCREEN_WIDTH, RISC_SCREEN_HEIGHT,COLOR_FORMAT_UNKNOWN);
//         FrameBufferConsoleDrawImage(ConsoleDeviceGetDefault, 1, 1, @buffer, RISC_SCREEN_WIDTH, RISC_SCREEN_HEIGHT,COLOR_FORMAT_UNKNOWN, 0);


     END;






PROCEDURE update_texture(framebufferpointer : uint32_t);

     TYPE
     rectty = RECORD
                  x, y , h, w : integer;
            END;


     VAR

        dirty_y1: integer;
        dirty_y2: integer;
        dirty_x1: integer;
        dirty_x2: integer;
        idx: integer;
        pixels: uint32_t;
        ptr: Pointer;
        rect : rectty;

        line : 0..RISC_SCREEN_HEIGHT;
        col  : 0..RISC_SCREEN_WIDTH;
        bufferindex : 0..RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT;
        b : 0..pred(32);

        BEGIN (* TODO: move dirty rectangle tracking into emulator core?*)
   (*     writeln('upd texture'); *)
//        GraphicsWindowDrawText(GraphicHandle1, '/', 30, 30);

          dirty_y1 := RISC_SCREEN_HEIGHT;
          dirty_y2 := 0;
          dirty_x1 := RISC_SCREEN_WIDTH;
          dirty_x2 := 0;

          idx := 0;
          FOR line := RISC_SCREEN_HEIGHT-1 DOWNTO 0 DO

             BEGIN
               FOR col := 0 TO pred(RISC_SCREEN_WIDTH) DO
                   BEGIN
                     pixels := risc.RAM[idx+framebufferpointer];
                     IF pixels <> cache[idx] THEN
                         BEGIN
                           cache[idx] := pixels;
                           IF line < dirty_y1 THEN dirty_y1 := line;
                           IF line > dirty_y2 THEN dirty_y2 := line;
                           IF  col < dirty_x1 THEN dirty_x1 := col;
                           IF  col > dirty_x2 THEN dirty_x2 := col;

                           bufferindex := line*RISC_SCREEN_WIDTH + col * 32;

                           FOR b := 0 TO Pred(32) DO

                                   BEGIN
                                     IF (pixels AND 1) > 0 THEN buffer[bufferindex] := WHITE ELSE buffer[bufferindex] := BLACK;
                                     inc(bufferindex);
                                     pixels := pixels SHR 1;
                                   END;
                         END;(*IF*)
                     inc(idx);
                   END;(*for col *)
             END;(*for line *)

//         GraphicsWindowDrawImage(GraphicHandle1, 0, 0, @buffer, RISC_SCREEN_WIDTH, RISC_SCREEN_HEIGHT,COLOR_FORMAT_UNKNOWN);

          IF dirty_y1 <= dirty_y2 THEN

               BEGIN
                 rect.x :=  dirty_x1;
                 rect.y :=  dirty_y1;
                 rect.w := (dirty_x2 - dirty_x1 + 1);
                 rect.h := (dirty_y2 - dirty_y1 + 1);


                 ptr:= @buffer[(dirty_y1 * RISC_SCREEN_WIDTH + dirty_x1)];

//                 GraphicsWindowSetViewport(GraphicHandle1,dirty_x1, dirty_y1, dirty_x2, dirty_y2);
                 GraphicsWindowDrawImage(GraphicHandle1, dirty_x1, dirty_y1, ptr, rect.w, rect.h,COLOR_FORMAT_UNKNOWN);

//                 SDL_UpdateTexture(texture, @rect, ptr, RISC_SCREEN_WIDTH * 4);

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

FUNCTION ceil(x : double) : longint;

  BEGIN
    Ceil := Trunc(x);
    If Frac(x) > 0 THEN Ceil := Ceil+1;
  END;





  FUNCTION b2i(b : boolean) : integer;

        BEGIN
        IF b THEN b2i := 1 ELSE b2i := 0;
        END;

PROCEDURE toggleLED;

          BEGIN
          ledon := NOT(ledon);
          IF ledon THEN ActivityLEDON ELSE ActivityLEDOff;
          end;





PROCEDURE mymouse;
          VAR
                     MouseData:TMouseData;
                     mcount : longword;


        BEGIN
        IF MousePeek = ERROR_SUCCESS THEN
             BEGIN
             if MouseRead(@MouseData,SizeOf(MouseData),mCount) = ERROR_SUCCESS then
                    begin
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
                                                                     end;

                                                end
                                              ELSE
                                                BEGIN
                                                IF mybutton > 0 THEN
                                                            BEGIN
                                                            risc.mouse_button(mybutton, False);
                                                            mybutton := 0;
                                                            end;
                                                end;

                           MouseFlush;

                    end;

             end; (* end MousePeek *)



          end;

FUNCTION mykeyboard2 : longword;


          CONST
               abstand = 18;
               left = 50;

          VAR

        KeyBoardData : TKeyboardData;
        Count : longword;
        lauf : integer;
        mymode_ : word;
        mymake  : Boolean;

       scancode_s : string;
       len : 0..pred(maxkeybufsize);
       l   : 0..pred(maxkeybufsize);
       scancode: keybufty;



  // original Oberon Code for Control recognition
  // PROCEDURE Peek();
  //BEGIN
  //  IF SYSTEM.BIT(msAdr, 28) THEN
  //    SYSTEM.GET(kbdAdr, kbdCode);
  //    IF kbdCode = 0F0H THEN Up := TRUE
  //    ELSIF kbdCode = 0E0H THEN Ext := TRUE
  //    ELSE
  //      IF (kbdCode = 12H) OR (kbdCode = 59H) THEN (*shift*) Shift := ~Up
  //      ELSIF kbdCode = 14H THEN (*ctrl*) Ctrl := ~Up
  //      ELSIF ~Up THEN Recd := TRUE (*real key going down*)
  //      END ;
  //      Up := FALSE; Ext := FALSE
  //    END
  //  END;
  //END Peek;



          BEGIN
          IF keyboardPeek = ERROR_SUCCESS THEN
                      BEGIN

                      IF (KeyboardRead(@KeyboardData,SizeOf(KeyboardData), Count) = ERROR_SUCCESS) THEN

                                  BEGIN
//
//                                  lauf := 38;
//                                  GraphicsWindowDrawBlock(GraphicHandle1, 0, 100+lauf*abstand, 800, 100+(lauf+6)*abstand, COLOR_WHITE);
//
//
//                                  GraphicsWindowDrawText(GraphicHandle1, 'Char                  = ' + IntToHex(Count,4), left, 100 + lauf * abstand);
//                                  inc(lauf);
//
//                                  // KeyCode = Character übersetzt mit Keymap
//                                  GraphicsWindowDrawText(GraphicHandle1, 'KeyboardData.KeyCode   = ' + IntToHex(KeyboardData.KeyCode,4), left, 100 + lauf * abstand);
//                                  inc(lauf);
//                                  GraphicsWindowDrawText(GraphicHandle1,'KeyboardData.Modifiers = ' + IntToHex(KeyboardData.Modifiers,8) , left, 100 + lauf * abstand);
//                                  inc(lauf);
//                                  GraphicsWindowDrawText(GraphicHandle1,'KeyboardData.ScanCode  = ' + IntToHex(KeyboardData.ScanCode,4) , left, 100 + lauf * abstand);
//                                  inc(lauf);
//                                  GraphicsWindowDrawLine(GraphicHandle1, 0, 100+lauf*abstand, 800, 100+lauf*abstand, COLOR_RED, 2);
//                                  inc(lauf);
                                  mykeyboard2 := KeyboardData.ScanCode;

                                  IF lauf > 40 THEN lauf := 38;
                                  mymode_ := 0;
                                  mymake := False;
                                  IF (((KeyboardData.Modifiers AND $4000) > 0) OR ((KeyboardData.Modifiers AND $8000) > 0)) THEN mymake := true;
                                  IF ((KeyboardData.Modifiers AND $2000) > 0)  THEN mymake := False;
                                  // $4000 = keypressed $8000 = repeat
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


                                  end;

                      end;

          END;







PROCEDURE main;

    var
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
              mykeyboard2;
              sleep(1);
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






begin

    GraphicHandle1 := GraphicsWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_FULL);
    init_texture;

    main;


 {We're not doing a loop this time so we better halt this thread before it exits}
 ThreadHalt(0);
end.

