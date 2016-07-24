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
  Framebuffer,
  BCM2836,
  BCM2709,
  SysUtils,
  Mouse,
           //  Keyboard, {Keyboard uses USB so that will be included automatically}
  DWCOTG,          {We need to include the USB host driver for the Raspberry Pi}
  linecircle,

  risccore, riscglob;

const
BLACK = $657b83;
WHITE = $fdf6e3;


TYPE
cachety =  ARRAY[0..Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT DIV 32)] of uint32_t;
bufferty = ARRAY[0..Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT)] OF uint32_t;




{We'll need a few more variables for this example.}
var
 RowCount:LongWord;
 ColumnCount:LongWord;
 CurrentX :LongWord;
 CurrentY :LongWord;
 Handle1:TWindowHandle;
 altx, alty, neux, neuy : longint;
 Count:LongWord;
 MouseData:TMouseData;
 ScreenWidth, ScreenHeight : LongWord;
 maxheight, maxwidth : LongInt;

 cache: cachety;
 buffer: bufferty;

 MyFramebuffer : PFramebufferDevice;
 MyProperties : PFramebufferProperties;



PROCEDURE init_texture;
     VAR i : longint;

     BEGIN
       fillchar(cache,sizeof(cache), 0);

       FOR  i := 0 TO Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT) DO

           BEGIN
             buffer[i] := BLACK;
           END;

//       SDL_UpdateTexture(texture,NIL,@buffer,RISC_SCREEN_WIDTH*4);
     END;

//In your case if you are creating an image in memory, which is similar to how
//many graphics libraries render in memory using their own canvas, then one option
//would be the use the framebuffer device API from the Framebuffer.pas unit which
//provides functions like FramebufferDevicePutRect to quickly and efficiently put
//an image from memory to the framebuffer device (normally using DMA).
//The format (bits per pixel, colors depth etc) of the image passed to the
//framebuffer functions is assumed to be the same format used by the framebuffer
//device (which may differ between devices) and no transformation is done at all.

// function FramebufferDevicePutRect(Framebuffer:PFramebufferDevice;X,Y:LongWord;Buffer:Pointer;Width,Height,Skip,Flags:LongWord):LongWord;
{Put a rectangular area of pixels from a supplied buffer to framebuffer memory}
{Framebuffer: The framebuffer device to put to}
{X: The starting column of the put}
{Y: The starting row of the put}
{Buffer: Pointer to a block of memory containing the pixels in a contiguous block of rows}
{Width: The number of columns to put}
{Height: The number of rows to put}
{Skip: The number of pixels to skip in the buffer after each row (Optional)}
{Flags: The flags for the transfer (eg FRAMEBUFFER_TRANSFER_DMA)}
{Return: ERROR_SUCCESS if completed or another error code on failure}

{Note: Caller must ensure pixel data is in the correct color format for the framebuffer}
{Note: The default method assumes that framebuffer memory is DMA coherent and does not require cache invalidation after a DMA write}





PROCEDURE update_texture(framebufferpointer : uint32_t);

     TYPE
     rectty = RECORD
                  x, y , h, w : integer;
            END;


     VAR
        rect : rectty;
        dirty_y1: integer;
        dirty_y2: integer;
        dirty_x1: integer;
        dirty_x2: integer;
        idx: integer;
        pixels: uint32_t;
        ptr: Pointer;

        line : 0..RISC_SCREEN_HEIGHT;
        col  : 0..RISC_SCREEN_WIDTH;
        bufferindex : 0..RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT;
        b : 0..pred(32);

        BEGIN (* TODO: move dirty rectangle tracking into emulator core?*)
   (*     writeln('upd texture'); *)
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
          IF dirty_y1 <= dirty_y2 THEN

               BEGIN
                 rect.x :=  dirty_x1 * 32;
                 rect.y :=  dirty_y1;
                 rect.w := (dirty_x2 - dirty_x1 + 1) * 32;
                 rect.h := (dirty_y2 - dirty_y1 + 1);

                 ptr:= @buffer[dirty_y1 * RISC_SCREEN_WIDTH + dirty_x1 * 32];
//                 SDL_UpdateTexture(texture, @rect, ptr, RISC_SCREEN_WIDTH * 4);
                 FramebufferDevicePutRect(MyFramebuffer, 0, 0, ptr, RISC_SCREEN_WIDTH,RISC_SCREEN_HEIGHT,0,FRAMEBUFFER_TRANSFER_DMA);

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
       frame_start: uint32_t;
       frame_end: uint32_t;

       delay: longint;



       BEGIN

         IF paramcount <> 1 THEN
            BEGIN
              writeln('Argv : ', paramcount);
              writeln('Args : ', paramstr(0), ' ', paramstr(1),' ',paramstr(2),' ',paramstr(3));
              writeln('Usage: riscpas disk-file-name [coredumpfile_from_cycle coredumpfile_to_cycle]');
              writeln('Stop with Alt-F4');
              exitcode := 1;
              exit;
            END;


//         risc.init(paramstr(1), paramstr(2), paramstr(3));
           risc.init('oberon.dsk', '', '');
           writeln( ' oberon.dsk is loaded');

         done := False;

         WHILE NOT(done) DO

            BEGIN

              risc.set_time(frame_start);

              risc.run(CPU_HZ DIV FPS);
              update_texture(risc.get_framebuffer_ptr);
              inc(frame_start);


              exitcode := 0;
        END; (* while not done *)
        risc.done;
        //shutting down video subsystem

      END; (* proc *)






begin

 // MouseInit;
 {Let's create a console window again but this time on the left side of the screen}
 Handle1:=ConsoleWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_FULL,True);

 {To prove that worked let's output some text on the console window}
 ConsoleWindowWriteLn(Handle1,'Welcome to MGs extended Mouse example');


 {Now let's get the current position of the console cursor into a couple of variables}
 ConsoleWindowGetXY(Handle1,CurrentX,CurrentY);

  if FramebufferGetPhysical(ScreenWidth,ScreenHeight) = ERROR_SUCCESS then
   begin
    {Print our screen dimensions on the console}
    ConsoleWindowWriteLn(Handle1,'Screen is ' + IntToStr(ScreenWidth) + ' pixels wide by ' + IntToStr(ScreenHeight) + ' pixels high');
   end;


   FramebufferInit;
   FramebufferDeviceAllocate(MyFramebuffer, MyProperties);
//   init_texture;
//   main;


  Count := 0;
  REPEAT
      if MouseRead(@MouseData,SizeOf(MouseData),Count) = ERROR_SUCCESS then
      begin
         neux := altx + MouseData.OffsetX;
         neuy := alty + MouseData.OffsetY;
         IF neux > maxwidth THEN neux := maxWidth;
         IF neuy > maxHeight THEN neuy := maxHeight;
         IF neux < 0 THEN neux := 0;
         IF neux < 0 THEN neuy := 0;
         CursorSetState(True,neuX,neuY,False);

        if (MouseData.Buttons and MOUSE_LEFT_BUTTON) <> 0 then
           begin
//                ConsoleWindowWriteLn(Handle1, 'Left Button pressed');

 //               FramebufferConsoleDrawLine(ConsoleDeviceGetDefault,altx,alty,neux,neuy,COLOR_RED,2);
                  line(altx, alty, neux, neuy, COLOR_RED);
           END;
         altx := altx + MouseData.Offsetx;
         alty := alty + MouseData.OffsetY;
         IF altx > maxWidth THEN altx := maxwidth;
         IF alty > maxHeight THEN alty := maxHeight;
         IF altx < 0 THEN altx := 0;
         IF alty < 0 THEN alty := 0;

      end;




  UNTIL ((MouseData.Buttons AND MOUSE_RIGHT_BUTTON) <> 0);


 // my end


 {Update our original console}
 ConsoleWindowWriteLn(Handle1,'Clearing the new console');


 {And say goodbye}
 ConsoleWindowWriteLn(Handle1,'All done, thanks for watching');

 {We're not doing a loop this time so we better halt this thread before it exits}
 ThreadHalt(0);
end.

