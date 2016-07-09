PROGRAM pm2array;

(* This program converts a 32x 32 PNM file to an array of 4 byte Values to make an ultobo cursor *)

USES hexwrite;

VAR meincursor : ARRAY[0..1023] OF longword;
    pixel : longword;
    lauf : integer;

FUNCTION inthex(s : string) : string;

        VAR wert : byte;
                dummy : integer;

        BEGIN
        val(s, wert, dummy);
        inthex := hexbyte(wert);
        END;


PROCEDURE makepasvar;

VAR ein, aus : TEXT;
    zeile : string;
    lauf,i : integer;


BEGIN
assign(EIN, 'cursor2.pnm');
assign(AUS, 'meicursor.pas');
reset(EIN);
rewrite(AUS);

write(AUS, ' mycursor  : ARRAY[0..1023] OF longword =(');
i := 0;
WHILE NOT(eof(EIN)) DO

        BEGIN
        IF i <= 3 THEN

                BEGIN
                readln(EIN, zeile);
                inc(i);
                END
             ELSE
                BEGIN
                write(AUS, '$AF');
                FOR lauf := 1 TO 3 DO

                        BEGIN
                        readln(EIN, zeile);
                        write(AUS, inthex(zeile));
                        END;

                writeln(AUS,', ');
                i := i+3;
                END;
        END;

// writeln(' i = ', i);                                                                                      r

// writeln(AUS, ');');

close(AUS);

close(EIN);

END;



PROCEDURE makecursor;

VAR ein : TEXT;
    zeile : string;
    lauf,i, i2 : integer;
    dummy : integer;
    wert : byte;
    longwert : longword;


BEGIN
{$I-}
assign(EIN, 'cursor2.pnm');
reset(EIN);
{$I+}

IF ioresult <> 0 THEN
        BEGIN
        writeln('unable to open cursor file');
        exit;
        END;
i := 0;
i2 := 0;
WHILE NOT(eof(EIN)) DO

        BEGIN
        IF i <= 3 THEN

                BEGIN
                readln(EIN, zeile);
                inc(i);
                END
             ELSE
                BEGIN
                pixel := $af000000;

                FOR lauf := 2 DOWNTO 0 DO

                        BEGIN
                        readln(EIN, zeile);
                        val(zeile, wert, dummy);
//                        writeln(lauf, ' wert : ', wert, ' ', hexbyte(wert),' dummy : ', dummy, ' Pixel ' , hexlongword(pixel));

                        longwert := 0;
                        longwert := wert;
                        longwert := longwert SHL (8*lauf);
                        pixel := pixel OR longwert;
//                        writeln(lauf, ' wert : ', wert, ' longwert ', hexlongword(longwert),' ', hexbyte(wert),' dummy : ', dummy, ' Pixel ', hexlongword(pixel));

                        END;

                meincursor[i2] := pixel;
                writeln(pixel);
                inc(i2);
                i := i+3;
                END;
        END;
close(EIN);

END;


BEGIN

makecursor;
readln;
FOR lauf := 0 TO 1023 DO

        BEGIN
        writeln(lauf, ' ', meincursor[lauf], ' ',hexlongword(meincursor[lauf]));
        END;

END.
