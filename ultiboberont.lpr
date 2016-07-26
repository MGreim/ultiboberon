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
  BCM2836,
  BCM2709,

  SysUtils,
           //  Keyboard, {Keyboard uses USB so that will be included automatically}
  DWCOTG,          {We need to include the USB host driver for the Raspberry Pi}

  risccore, riscglob;

const
BLACK = $657b83;
WHITE = $fdf6e3;


TYPE
cachety =  ARRAY[0..Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT DIV 32)] of uint32_t;
bufferty = ARRAY[0..Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT)] OF uint32_t;




{We'll need a few more variables for this example.}
var
 GraphicHandle1 :TWindowHandle;
 cache: cachety;
 buffer: bufferty;




PROCEDURE init_texture;
     VAR i : longint;

     BEGIN
    fillchar(cache,sizeof(cache), 0);

       FOR  i := 0 TO Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT) DO

           BEGIN
             buffer[i] := BLACK;
           END;
         GraphicsWindowDrawImage(GraphicHandle1, 1, 1, @buffer, RISC_SCREEN_WIDTH, RISC_SCREEN_HEIGHT,COLOR_FORMAT_UNKNOWN);
//       SDL_UpdateTexture(texture,NIL,@buffer,RISC_SCREEN_WIDTH*4);
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
        GraphicsWindowDrawText(GraphicHandle1, '/', 30, 30);

          dirty_y1 := RISC_SCREEN_HEIGHT;
          dirty_y2 := 0;
          dirty_x1 := RISC_SCREEN_WIDTH div 32;
          dirty_x2 := 0;

          idx := 0;
          FOR line := RISC_SCREEN_HEIGHT-1 DOWNTO 0 DO

             BEGIN
               FOR col := 0 TO pred(RISC_SCREEN_WIDTH DIV 32) DO
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

//          GraphicsWindowDrawImage(GraphicHandle1, 0, 0, @buffer, RISC_SCREEN_WIDTH, RISC_SCREEN_HEIGHT,COLOR_FORMAT_UNKNOWN);

          IF dirty_y1 <= dirty_y2 THEN

               BEGIN
                 rect.x :=  dirty_x1 * 32;
                 rect.y :=  dirty_y1;
                 rect.w := (dirty_x2 - dirty_x1 + 1) * 32;
                 rect.h := (dirty_y2 - dirty_y1 + 1);


                 ptr:= @buffer[dirty_y1 * RISC_SCREEN_WIDTH + dirty_x1 * 32];

                 GraphicsWindowDrawImage(GraphicHandle1, rect.x, rect.y, ptr, rect.w, rect.h,COLOR_FORMAT_UNKNOWN);
                 GraphicsWindowDrawText(GraphicHandle1, 'X', 30, 30);
                 {8 bits per pixel Red/Green/Blue (RGB332)}
{Draw an image on an existing console window}
{Handle: The handle of the window to draw on}
{X: The left starting point of the image (relative to current viewport)}
{Y: The top starting point of the image (relative to current viewport)}
{Image: Pointer to the image data in a contiguous block of pixel rows}
{Width: The width in pixels of a row in the image data}
{Height: The height in pixels of all rows in the image data}
{Format: The color format of the image data (eg COLOR_FORMAT_ARGB32) Pass COLOR_FORMAT_UNKNOWN to use the window format}
{Return: ERROR_SUCCESS if completed or another error code on failure}

{Note: For Graphics Console functions, Viewport is based on screen pixels not characters}


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

PROCEDURE main;

    var
       done: bool;
       frame_start: longword;
       frame_end, starttime: longword;

       mydelay: longint;



       BEGIN
       GraphicsWindowDrawText(GraphicHandle1, 'Now in main', 10,20);

         //IF paramcount <> 1 THEN
         //   BEGIN
         //     writeln('Argv : ', paramcount);
         //     writeln('Args : ', paramstr(0), ' ', paramstr(1),' ',paramstr(2),' ',paramstr(3));
         //     writeln('Usage: riscpas disk-file-name [coredumpfile_from_cycle coredumpfile_to_cycle]');
         //     writeln('Stop with Alt-F4');
         //     exitcode := 1;
         //     exit;
         //   END;


//         risc.init(paramstr(1), paramstr(2), paramstr(3));
//           write('jetzt risc.init');
           //REPEAT
           //UNTIL ConsoleKeyPressed;

           risc.init('oberon.dsk', '', '');
           GraphicsWindowDrawText(GraphicHandle1, ' oberon.dsk is loaded', 10, 30);

         done := False;

         ActivityLEDEnable;


         starttime := getTickCount64;
         WHILE NOT(done) DO

            BEGIN
              frame_start := getTickCount64 - starttime;
              risc.set_time(frame_start);
              ActivityLEDON;
              risc.run(CPU_HZ DIV FPS);
              ActivityLEDoff;
              update_texture(risc.get_framebuffer_ptr);
              frame_end := getTickCount64 - starttime;
              mydelay := frame_start + (1000 div FPS) - frame_end;

//              IF mydelay > 0 THEN sleep(mydelay);



              exitcode := 0;
           END; (* while not done *)
        risc.done;
        //shutting down video subsystem

      END; (* proc *)






begin

 // MouseInit;


//   GraphicsConsoleInit;
//   writeln('Framebuffer initialisiert');
   // GraphicsConsoleInit;
   GraphicHandle1 := GraphicsWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_FULLSCREEN);
//   write('weiter mit Taste');

   GraphicsWindowDrawText(GraphicHandle1,'Marke 1',20,20);
//   GraphicsWindowShow(GraphicHandle1);
IF GraphicsWindowSetViewPort(GraphicHandle1, 10, 10, RISC_SCREEN_WIDTH+10, RISC_SCREEN_HEIGHT+10) = ERROR_SUCCESS THEN  GraphicsWindowDrawLine(GraphicHandle1, 10, 10, 100, 10, COLOR_RED, 2);
{Set the rectangle X1,Y1,X2,Y2 of the window viewport for an existing console window}
{Handle: The handle of the window to set the rectangle for}
{Rect: The rectangle to set for the window viewport}
{Return: ERROR_SUCCESS if completed or another error code on failure}


   init_texture;
//   writeln('texture buffer filled');

//   writeln('Jetzt nach main... ?');

    main;




 // my end



 {We're not doing a loop this time so we better halt this thread before it exits}
 ThreadHalt(0);
end.

