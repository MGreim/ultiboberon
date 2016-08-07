program ScreenOutputKeybvoardGraphic;

{$mode objfpc}{$H+}

//07.aug.2016 MG
//- There seems to be a problem with parallel using USB moude and
//keyboard. Each single function works fine, but not if they are in the same loop.


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
  keyboard,
           //  Keyboard, {Keyboard uses USB so that will be included automatically}
  DWCOTG,          {We need to include the USB host driver for the Raspberry Pi}
  linecircle;




{We'll need a few more variables for this example.}
var
 CurrentX :LongWord;
 CurrentY :LongWord;
 Handle1:TWindowHandle;
 altx, alty, neux, neuy : longint;
 Count:LongWord;
 MouseData:TMouseData;
 ScreenWidth, ScreenHeight : LongWord;
 maxheight, maxwidth : LongInt;



 FUNCTION mykeyboard : Boolean;


        VAR
        KeyBoardData : TKeyboardData;
        Count : longword;

          BEGIN

          IF (KeyboardRead(@KeyboardData,SizeOf(KeyboardData), Count) = ERROR_SUCCESS) THEN

                BEGIN

                  ConsoleWindowWriteLn(Handle1, 'KeyboardData.KeyCode   = ' + IntToHex(KeyboardData.KeyCode,4));
                  ConsoleWindowWriteLn(Handle1, 'KeyboardData.Modifiers = ' + IntToHex(KeyboardData.Modifiers,4));
                  ConsoleWindowWriteLn(Handle1, 'KeyboardData.ScanCode  = ' + IntToHex(KeyboardData.ScanCode,4));
                  ConsoleWindowWriteLn(Handle1,' ');

                end;



           mykeyboard := (keyboardData.KeyCode = 13);
          END;


FUNCTION mymouse : Boolean;

         BEGIN


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
                          line(altx, alty, neux, neuy, COLOR_RED);
                   END;
                 altx := altx + MouseData.Offsetx;
                 alty := alty + MouseData.OffsetY;
                 IF altx > maxWidth THEN altx := maxwidth;
                 IF alty > maxHeight THEN alty := maxHeight;
                 IF altx < 0 THEN altx := 0;
                 IF alty < 0 THEN alty := 0;

              end;

          mymouse := ((MouseData.Buttons AND MOUSE_RIGHT_BUTTON) <> 0);
         END;


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

 // Now try to load a new cursorshape from the disk, otherwise take the default mycursor
 CreateCursor;

 // writeln seems to work as well
 writeln('Press the left mouse button to draw a line, press the right mouse button to terminate the program');

//   We'll use a couple of variables to track the position in response to mouse messages}

  // My new things... and it works
  maxWidth := ScreenWidth;
  maxHeight := ScreenHeight;
  altx:=maxWidth div 2;
  alty:=maxHeight div 2;

  ConsoleWindowSetX(Handle1,altx);
  ConsoleWindowSetY(Handle1,alty);
  CursorSetState(True,altx, alty,False);

  Count := 0;
  sleep(1000);
  writeln('Now only kyboard input. Please finish keyboard input with Enter');
  REPEAT
  sleep(2);
  UNTIL mykeyboard;

  sleep(1000);
  writeln('Now only mouse input. Please the mouse function with the right mouse button');
  REPEAT
  sleep(2);
  UNTIL mymouse;



  writeln('Now mouse and keyboard.');
  writeln('You may see that the keyboard input is moving the mouse and keyboard input only works if the mouse is moved???');
  sleep(1000);
  REPEAT
  sleep(2);
  mymouse;
  sleep(2);
  mykeyboard;
  UNTIL False;


 // my end


 {Update our original console}
 ConsoleWindowWriteLn(Handle1,'Clearing the new console');


 {And say goodbye}
 ConsoleWindowWriteLn(Handle1,'All done, thanks for watching');

 {We're not doing a loop this time so we better halt this thread before it exits}
 ThreadHalt(0);
end.

