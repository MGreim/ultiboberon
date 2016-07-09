(*********************************
Reading and writing to and from
the Oberon filesystem, which is kept
in one single file. (MG)

*********************************)

UNIT riscsd;


INTERFACE

USES sysutils, riscglob;

CONST BUFSBYTE = 512;
      BUFSWORD = BUFSBYTE DIV 4;

TYPE
diskstatetype = (diskCommand, diskRead, diskWrite, diskWriting);


bufty   =   ARRAY[0..Pred(BUFSWORD)  ] OF uint32_t;
buftyp2 =   ARRAY[0..Pred(BUFSWORD)+2] OF uint32_t;

bytebufty = ARRAY[0..pred(BUFSBYTE)  ] OF uint8_t;

Diskty = OBJECT
      PRIVATE
        state : diskstatetype;
        myfile: THandle;
        rx_buf: bufty;
        rx_idx: longint;
        tx_buf: buftyp2;
        tx_cnt: longint;
        tx_idx: longint;
        offset : uint32_t;
      PUBLIC
        sdcard : Boolean;
        CONSTRUCTOR init(filename : string);
        PROCEDURE run_command;
      PRIVATE
        PROCEDURE read_sector(VAR buffer : bufty);
        PROCEDURE read_sector2(VAR buffer : buftyp2);
        PROCEDURE write_sector(buffer : bufty);
      PUBLIC
        FUNCTION  read_: uint32_t;
        PROCEDURE write_(value: uint32_t);
        DESTRUCTOR done;

END;


VAR disk : Diskty;

IMPLEMENTATION


CONSTRUCTOR diskty.init(filename : string);

        VAR buffer : bufty;

        BEGIN
        state := diskCommand;
        sdcard := False;
        buffer[0] := 0;
{$I-}
        writeln(' Filename : ', filename);
        myfile := fileOpen(filename, fmOpenReadWrite);
{$I+}
        IF myfile = 0 THEN
                BEGIN
                writeln('Can''t open file : ', filename,' ', ioresult);
                exit;
                END;

        (* Check FOR filesystem-only image, starting directly at sector 1 (DiskAdr 29) *)
        read_sector(buffer);
        IF (buffer[0] = $9B1EA38D) THEN offset := $80002 ELSE offset := 0;
        writeln(' File Offset : ', offset);
        sdcard := True;

        END;



DESTRUCTOR diskty.done;

      BEGIN
         fileclose(myfile);
       END;

PROCEDURE diskty.write_(value: uint32_t);

        BEGIN
          inc(tx_idx);
          (* case statements in Pascal are breaking the case loop if
             the first condition is true, not so in C  *)
          CASE state of
            diskCommand:  BEGIN
                          IF ((byte(value)<>$FF) OR (rx_idx<>0)) THEN
                             BEGIN
                                 rx_buf[rx_idx]:= value;
                                 inc(rx_idx);
                                 IF rx_idx = 6 THEN

                                    BEGIN
                                     run_command;
                                     rx_idx:= 0;
                                    END;
                             END;
                           END;
              diskRead:  BEGIN
                          IF tx_idx = tx_cnt  THEN

                                BEGIN
                                 state:= diskCommand;
                                 tx_cnt:= 0;
                                 tx_idx:= 0;
                                END;
                         END;

            diskWrite:   BEGIN
                           IF value = 254 THEN state:= diskWriting;
                         END;

            diskWriting: BEGIN
                          IF rx_idx < BUFSWORD THEN rx_buf[rx_idx]:= value;
                          inc(rx_idx);
                          IF rx_idx = BUFSWORD THEN write_sector(rx_buf);

                          IF rx_idx = 130  THEN
                              BEGIN
                                tx_buf[0] := 5;
                                tx_cnt := 1;
                                tx_idx:= -1;
                                rx_idx:= 0;
                                state:= diskCommand;
                              END;
                         END;
               END;{case}
           END;

FUNCTION diskty.read_: uint32_t;

      VAR resu: uint32_t;

      BEGIN
        IF (tx_idx >= 0) AND (tx_idx < tx_cnt)  THEN

              BEGIN
              resu := tx_buf[tx_idx];
              END
            ELSE
              BEGIN
              resu := 255;
              END;
        read_ := resu;
      END;

PROCEDURE diskty.run_command;

      VAR cmd: uint32_t;
          arg: uint32_t;
          (* myreadpos, mywritepos : longint; *)

      BEGIN
        cmd := rx_buf[0];
        arg := (rx_buf[1] shl 24) or (rx_buf[2] shl 16) or (rx_buf[3] shl 8) or rx_buf[4];

        CASE cmd OF
        81: BEGIN
              state:= diskRead;
              tx_buf[0] := 0;
              tx_buf[1] := 254;
              (* myreadpos :=*) fileseek(myfile, (arg - offset) * BUFSBYTE, fsFromBeginning);
              read_sector2(tx_buf);
              tx_cnt:=  2 + BUFSWORD;
            END;

        88: BEGIN
              state:= diskWrite;
              (* mywritepos := *) fileseek(myfile, (arg - offset) * BUFSBYTE, fsFromBeginning);
              tx_buf[0] := 0;
              tx_cnt := 1;
            END;
          ELSE
            BEGIN
              tx_buf[0] := 0;
              tx_cnt := 1;
            END;
        END;(*case*)

        tx_idx := -1;
     END;

PROCEDURE diskty.read_sector(VAR buffer : bufty);

     VAR   bytes: bytebufty;
           i : 0..pred(BUFSWORD);
           i2 : 0..pred(BUFSBYTE);


     BEGIN
       FOR i2 := 0 TO pred(BUFSBYTE) DO

             BEGIN
             bytes[i2] := 0;
             END;

       fileread(myfile, bytes, BUFSBYTE);

       FOR i := 0 to Pred(BUFSWORD)  DO

             BEGIN
              buffer[i]:= longword(bytes[i*4+0]) or (longword(bytes[i*4+1]) shl 8) or (longword(bytes[i*4+2]) shl 16) or (longword(bytes[i*4+3]) shl 24);
             END;

     END;


PROCEDURE diskty.read_sector2(VAR buffer : buftyp2);

    VAR   bytes : bytebufty;
             i  : 0..pred(BUFSWORD);
            i2  : 0..pred(BUFSBYTE);

   BEGIN
     FOR i2 := 0 to pred(BUFSBYTE) DO

           BEGIN
           bytes[i2] := 0;
           END;

     fileread(myfile, bytes, BUFSBYTE);

     FOR i := 0 to Pred(BUFSWORD)  DO

          BEGIN
           buffer[i+2]:= longword(bytes[i*4+0]) or (longword(bytes[i*4+1]) shl 8) or (longword(bytes[i*4+2]) shl 16) or (longword(bytes[i*4+3]) shl 24);
          END;

   END;




PROCEDURE diskty.write_sector(buffer : bufty);

     VAR  bytes: bytebufty;
          i : 0..pred(BUFSWORD);
     BEGIN

      FOR i := 0 to Pred(BUFSWORD) DO

         BEGIN
           bytes[i*4+0]:= byte((buffer[i]) and $FF);
           bytes[i*4+1]:= byte((buffer[i] shr 8) and $FF);
           bytes[i*4+2]:= byte((buffer[i] shr 16) and $FF);
           bytes[i*4+3]:= byte((buffer[i] shr 24) and $FF);
         END;
      filewrite(myfile, bytes, BUFSBYTE);
    END;

END.
