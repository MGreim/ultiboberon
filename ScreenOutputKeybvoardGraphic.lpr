program ScreenOutputKeybvoardGraphic;

{$mode objfpc}{$H+}

//09.aug.2016
//If the keyboard is on a hub and the mouse directly connected evrything works fine.
//- also keyboard reading by an own thread is now working
//- modifier is 4100 if button is pressed, 8100 if holded and 2100 if released
//- some strange effects when used class instead of object, maybe some missing units.
// - so in the mext step I would include mouse and keaboard in a single thread
//  and the include it into ultiboberon

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
  GlobalConfig,
  Platform,
  Threads,
  Console,
  Framebuffer,
  BCM2836,
  BCM2709,
// With this block ogf units we can update
  //the SD card via telnet. The remote computer is xx.29
  //the path is /var/www
  //unfortunately a sunbdirectory doesnt work with my apche2
//----------------------------------------------------------------------
 Shell,           {Add the Shell unit just for some fun}
 ShellFileSystem, {Plus the File system shell commands}
 ShellUpdate,     //<- Add this extra one to enable the update commands
 RemoteShell,     {And the RemoteShell unit so we can Telnet to our Pi}
 SMSC95XX,        {And the driver for the Raspberry Pi network adapter}
//--------------------------------------------------------------
  SysUtils,
  USB,
  Mouse,
  keyboard,
           //  Keyboard, {Keyboard uses USB so that will be included automatically}
  DWCOTG,          {We need to include the USB host driver for the Raspberry Pi}
  linecircle;



type
  {Matrix-Screen specific clases}
  TConIn = object
    public
         pKeyCode : Word;
     pModifier: LongWord;
     pScanCode : Word;
     wartaste : Boolean;
    {Public Properties}
     Thread1Handle : TThreadHandle;
     Lock : TMutexHandle;
     {Public Methods}
     constructor Create;
     function myReadKey : Boolean;
     destructor Destroy;
     private
     {Internal Variables}
     meinKeyCode : word;
     meinModifier : longWord;
     meinScanCode : Word;

   end;


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
 mytconin : TConIn;



 FUNCTION mykeyboard : Boolean;


        VAR
        KeyBoardData : TKeyboardData;
        Count : longword;

          BEGIN
          mykeyboard := False;
//          IF KeyboardPeek = ERROR_NO_MORE_ITEMS THEN exit;
          IF KeyboardPeek = ERROR_SUCCESS THEN
             BEGIN

              IF (KeyboardReadEx(@KeyboardData,SizeOf(KeyboardData), KEYBOARD_FLAG_NON_BLOCK, Count) = ERROR_SUCCESS) THEN

                    BEGIN
                      ConsoleWindowWriteLn(Handle1, 'KeyboardData.KeyCode   = ' + IntToHex(KeyboardData.KeyCode,4));
                      ConsoleWindowWriteLn(Handle1, 'KeyboardData.Modifiers = ' + IntToHex(KeyboardData.Modifiers,4));
                      ConsoleWindowWriteLn(Handle1, 'KeyboardData.ScanCode  = ' + IntToHex(KeyboardData.ScanCode,4));
                      ConsoleWindowWriteLn(Handle1,' ');

                    end;



               mykeyboard := (keyboardData.KeyCode = 13);

             end;
          END;

function Thread1Execute(Parameter:Pointer):PtrInt;
var
  KeyBoardData : TKeyboardData;
  Count : longword;
  ledon : Boolean;


begin
  Thread1Execute:=0;

  while True do
        begin
        mytconin.wartaste := False;
              IF (KeyboardRead(@KeyboardData,SizeOf(KeyboardData), Count) = ERROR_SUCCESS) THEN

                          BEGIN
                            ledon := NOT(ledon);
                            IF ledon THEN ActivityLEDON ELSE ActivityLEDOff;


                            //ConsoleWindowWriteLn(Handle1, 'KeyboardData.KeyCode   = ' + IntToHex(KeyboardData.KeyCode,4));
                            //ConsoleWindowWriteLn(Handle1, 'KeyboardData.Modifiers = ' + IntToHex(KeyboardData.Modifiers,4));
                            //ConsoleWindowWriteLn(Handle1, 'KeyboardData.ScanCode  = ' + IntToHex(KeyboardData.ScanCode,4));
                            //ConsoleWindowWriteLn(Handle1,' ');

                         if MutexLock(mytconin.Lock) = ERROR_SUCCESS then begin

                                  try
                                    BEGIN
                                    mytconin.wartaste := True;
                                    mytconin.meinKeyCode :=  KeyBoardData.KeyCode;
                                    mytconin.meinModifier := KeyBoardData.Modifiers;
                                    mytconin.meinScanCode := KeyBoardData.ScanCode;
                                    end;

                                  finally
                                    MutexUnlock(mytconin.Lock);
                                  end;

                                end; { if MutexLock(CPM_CONIN.Lock) = ERROR_SUCCESS then }



                            END;


          sleep(50);
        end; { while True do begin }

     end; { function Thread1Execute }

{==============================================================================}
{TConIn}
constructor TConIn.Create;
begin
 {}
// inherited Create;
ConsoleWindowWriteLn(Handle1,'Now in Create Thread');
  Lock:=MutexCreate;
  ConsoleWindowWriteLn(Handle1,'Now Mutex Created');

 Thread1Handle:=BeginThread(@Thread1Execute,nil,Thread1Handle,THREAD_STACK_DEFAULT_SIZE);

   ConsoleWindowWriteLn(Handle1,'Now Thread1Handle active');


 if Thread1Handle = INVALID_HANDLE_VALUE then
  begin
   {If the thread handle is not valid then BeginThread failed}
   ConsoleWindowWriteLn(Handle1,'Failed to create Thread1');
  end
 else
  begin
   {Otherwise the thread was created and will start running soon, we have a handle
    to reference it if we want. The Thread1Execute function is in the Thread1 unit,
    have a look there to see what it is will be doing.}
   ConsoleWindowWriteLn(Handle1,'Thread1 was created successfully, the handle is ' + IntToHex(Thread1Handle,8));

   {Let's wait a bit to see what happens}
   Sleep(2000);
  end;

  pKeyCode := 0;
  pScancode := 0;
  pModifier := 0;
  meinKeyCode := 0;
  meinScancode := 0;
  meinModifier := 0;




end; { constructor TConIn.Create }



{==============================================================================}
{==============================================================================}
{TConIn}
function TConIn.myReadKey : Boolean;

begin
   myReadkey := False;
  if MutexLock(Lock) = ERROR_SUCCESS then
   begin
    try
      IF wartaste THEN
       BEGIN
          pKeyCode := meinKeyCode;
          pModifier := meinModifier;
          pScancode := meinScanCode;
          myReadKey := wartaste;
       end;

    finally
      MutexUnlock(Lock);
    end;
  end;


  sleep(10);

end; { function TConIn.ReadKey }








destructor  TConIn.Destroy;
begin

  MutexDestroy(Lock);

end; { destructor  TConIn.Destroy }





FUNCTION mymouse : Boolean;

      BEGIN

      mymouse := False;
       IF MousePeek = ERROR_NO_MORE_ITEMS THEN exit;
       IF MousePeek = ERROR_SUCCESS THEN
             BEGIN
               if MouseReadEx(@MouseData,SizeOf(MouseData),MOUSE_FLAG_NON_BLOCK, Count) = ERROR_SUCCESS then
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

          end;
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
//   CreateCursor;

 // writeln seems to work as well

//   We'll use a couple of variables to track the position in response to mouse messages}

  // My new things... and it works
  maxWidth := ScreenWidth;
  maxHeight := ScreenHeight;
  altx:=maxWidth div 2;
  alty:=maxHeight div 2;

  ConsoleWindowSetX(Handle1,altx);
  ConsoleWindowSetY(Handle1,alty);
  CursorSetState(True,altx, alty,False);

  ActivityLEDenable;

  Count := 0;
  writeln('Now try to start the thread1');

  mytconin.create;

  sleep(1000);
  writeln('Now only kyboard input with Thread. Please finish keyboard input with Enter');
  REPEAT
//  sleep(1000);
  IF mytconin.myReadKey THEN
     BEGIN
        ConsoleWindowWriteLn(Handle1, 'KeyboardData.KeyCode   = ' + IntToHex(mytconin.pKeyCode,4));
        ConsoleWindowWriteLn(Handle1, 'KeyboardData.Modifiers = ' + IntToHex(mytconin.pModifier,4));
        ConsoleWindowWriteLn(Handle1, 'KeyboardData.ScanCode  = ' + IntToHex(mytconin.pScanCode,4));
        ConsoleWindowWriteLn(Handle1,' ');
     end;
  UNTIL False;

    writeln('Now only kyboard input with Thread. Please finish keyboard input with Enter');


  REPEAT
  sleep(100);

  until mykeyboard;


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
