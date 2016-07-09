unit linecircle;

{$mode objfpc}{$H+}

interface


uses
  Classes,
  Console,
  GlobalConst,
  Platform,
  BCM2709,
  SysUtils,
  Mouse,       {Mouse uses USB so that will be included automatically}
  DWCOTG,      {We need to include the USB host driver for the Raspberry Pi}
  HeapManager, {Include the heap manager so we can allocate some different types of memory}
  meicursor;

procedure CreateCursor;
Procedure Line (x1, y1, x2, y2 : LongInt; farbe : LongWord);

implementation



{See the main program below for more info about what this function is for}
procedure CreateCursor;
var
 Row:LongWord;
 Col:LongWord;
 Offset:LongWord;
 Size:LongWord;
 Cursor:PLongWord;
 Address:LongWord;


begin
  {Make our cursor 32 x 32 pixels, each pixel is 4 bytes}
  Size:=32 * 32 * 4;

  {Allocate a block of memory to create our new mouse cursor.

   For different versions of the Raspberry Pi we need to allocate different
   types of memory when communicating with the graphics processor (GPU).

   Check what type of Raspberry Pi we have}
  case BoardGetType of
   BOARD_TYPE_RPIA,BOARD_TYPE_RPIB,
   BOARD_TYPE_RPIA_PLUS,BOARD_TYPE_RPIB_PLUS,
   BOARD_TYPE_RPI_ZERO:begin
     {We have an A/B/A+/B+ or Zero}
     {Allocate some Shared memory for our cursor}
     Cursor:=AllocSharedMem(Size);
    end;
   BOARD_TYPE_RPI2B,BOARD_TYPE_RPI3B:begin
     {We have a 2B or 3B}
     {Allocate some No Cache memory instead}
     Cursor:=AllocNoCacheMem(Size);
    end;
   else
    begin
     {No idea what board this is}
     Cursor:=nil;
    end;
  end;

  {Check if we allocated some memory for our cursor}
  if Cursor <> nil then
   begin
    {Loop through all of the LongWord positions in our cursor and set alternating
     color pixels. I'll leave it to you to work out what is happening here and
     how to change it to get different mouse cursor effects. The cursor is just
     a bitmap so you can make anything you can imagine.

     The color bits are Alpha, Red, Green and Blue}
    Offset:=0;

   loadcursor('C:\cursor10.pnm');

    for Row:=0 to 31 do
     begin
      for Col:=0 to 31 do
          begin
          offset := Row*32 + Col;
          Cursor[Offset] := mycursor[offset];
          end;
     end;





    {Convert our cursor pointer into an address that the GPU can understand, this
     is because it sees the world differently to what we do and uses different
     address ranges}
    Address:=PhysicalToBusAddress(Cursor);

    {Now call Cursor Set Info to load our new cursor into the GPU}
    CursorSetInfo(32,32,0,0,Pointer(Address),Size);

    {And finally free the memory that we allocated}
    FreeMem(Cursor);
   end;
end;

{ 03.jul.2016 MG
  The Line procedure is from the web site
  http://www.cirsovius.de/CPM/Projekte/Artikel/Grafik/LinearAlgorithmus/LineDraw.html
  the original paper was published 1987 by Holger Schmidt in the former computer magazine mc
  which not published namore since the early 1990ies. Its a slightly modified
  Bresenham algorithm designed for TurboPacal for CP/M
  the English comments are translated by me}



Procedure Line (x1, y1, x2, y2 : LongInt; farbe : LongWord);
{ Die Prozedur verbindet die Punkte P1(x1,y1) und P2(x2,y2) mit der in   }
{ 'farbe' spezifizierten Zeichenfarbe.                                   }
//The Procedure is connecting P1 and P2 with color farbe

VAR xl, yl, x, y,                             { Hilfsvariablen  / auxiliary vars         }
    dx, dy,
     a,  b, e,
    help,                                     { Variablentausch   / swap variables        }
    ende                 : LongInt;           { Kennzeichnung Linienende / line end}
    winkelhalbierende    : BOOLEAN;

    PROCEDURE Plot(x, y, farbe : longint);

              BEGIN

                    FramebufferConsoleDrawPixel(ConsoleDeviceGetDefault,x,y,farbe);
              end;

BEGIN { Prozedur 'Line' Anfang }

   { Defaultwerte für Variablen / defaults }
   xl   :=  1; yl :=  1;
   x    := x1;  y := y1;
   ende := x2;
   dx   := x2 - x1;
   dy   := y2 - y1;
   winkelhalbierende := False;

   { Spiegelung an y-Achse / flip on the y-axis }
   IF dx < 0 THEN
      BEGIN
         dx := -dx;
         xl := -1;
      END;

   { Spiegelung an x-Achse / flip on the x-axis}
   IF dy < 0 THEN
      BEGIN
         dy :=  -dy;
         yl :=  -1;
      END;

   { Spiegelung an Winkelhalbierender des 1. Quadranten / flip on the bisectrix of the 1. quadrant}
   IF dx < dy THEN
      BEGIN
         help :=  x;  x :=  y;  y := help;
         help := dx; dx := dy; dy := help;
         help := xl; xl := yl; yl := help;
         ende := y2;
         winkelhalbierende := True;
      END;

   { Hilfsvariablen / auxiliary vars}
   a := dy shl 1;
   b := dx shl 1 - a;
   e := a - dx;

  { Zeichnen der Geraden / plot the line }
  IF winkelhalbierende THEN
     BEGIN
        Plot (y, x, farbe);
        WHILE x <> ende DO
           BEGIN
              x := x + xl;
              IF e > 0 THEN
                 BEGIN
                    y := y + yl;
                    e := e -  b;
                 END
              ELSE
                 e := e + a;
              Plot (y, x, farbe);

           END
     END
  ELSE
     BEGIN

         Plot (x, y, farbe);
         WHILE x <> ende DO
            BEGIN
               x := x + xl;
               IF e > 0 THEN
                  BEGIN
                     y := y + yl;
                     e := e -  b;
                  END
               ELSE
                  e := e + a;
               Plot (x, y, farbe);
            END
     END;
END; { Prozedur 'Line' Ende }


end.

