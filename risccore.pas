{*********************************}
{ The core of the RISC 5 machine  }
{*********************************}

UNIT risccore;

INTERFACE

USES riscsd, riscfp, riscglob;

CONST
maxregister = 16;
MemSize =   $100000;
MemWords = (MemSize div 4);
ROMWords = 512;
maxkeybufsize = MAX_PS2_CODE_LEN;
DISPLAYEND =  $0FFF00;
Displaystart = Displayend - RISC_SCREEN_WIDTH * RISC_SCREEN_HEIGHT DIV 8;

TYPE

regspace = 0..pred(maxregister);
regty    = ARRAY[0..pred(maxregister)] of uint32_t;

keybufty = ARRAY [0..Pred(maxkeybufsize)] of uint8_t;


RISCty = OBJECT
      PRIVATE
        PC: uint32_t;
        R: ARRAY [0..Pred(maxregister)] of uint32_t;
        H: uint32_t;
        Z: bool;
        N: bool;
        C: bool;
        V: bool;
        progress: uint32_t;
        current_tick: uint32_t;
        mouse: uint32_t;
        key_buf: keybufty;
        key_cnt: uint32_t;
        leds: uint32_t;
        spi_selected: uint32_t;
        sd_card: Boolean;
        ROM: ARRAY [0..Pred(ROMWords)] of uint32_t;
(* Fore Debugging *)
        cyclecounter : qword;
        DUMP : TEXT;
        lastop : uint32_t;
        lastinstruction : uint32_t;
        lasttyp : uint32_t;
        lastpc : uint32_t;
        lasta_val, lastb_val, lastc_val, lastaddress : uint32_t;
        coredumpfromcycle, coredumptocycle : uint32_t;
(* end only for debugging *)
      PUBLIC
        RAM: ARRAY [0..Pred(MemWords)] of uint32_t;
      PRIVATE
        PROCEDURE single_step;
        PROCEDURE set_register(reg: integer;  value: uint32_t);
        FUNCTION load_word(address: uint32_t): uint32_t;
        FUNCTION load_byte(address: uint32_t): uint8_t;
        PROCEDURE store_word(address: uint32_t;  value: uint32_t);
        PROCEDURE store_byte(address: uint32_t;  value: uint8_t);
        FUNCTION load_io(address: uint32_t): uint32_t;
        PROCEDURE store_io(address: uint32_t;  value: uint32_t);
        PROCEDURE coredump;
        PROCEDURE coredumpinit(froms, tos : string);
        PROCEDURE coredumpclose;
      PUBLIC
        CONSTRUCTOR init(filename : string; froms, tos : string);
        PROCEDURE run(cycles : uint32_t);
        PROCEDURE set_time(tick: uint32_t);
        PROCEDURE mouse_moved(mouse_x: integer;  mouse_y: integer);
        PROCEDURE mouse_button(button: integer;  down: bool);
        PROCEDURE keyboard_input(scancodes: keybufty;  len: uint32_t);
        FUNCTION  get_framebuffer_ptr: uint32_t;


        PROCEDURE reset;
        DESTRUCTOR done;
        END;



VAR risc : riscty;


implementation

CONST
IOStart =      $0FFFC0; (* = 1048521 *)
ROMStart =     $0FE000;
ROMbootsize =  388;

(* bootloader: ARRAY [0..Pred(ROMWords)] of uint32_t = ( *)
(* 388 otherwise i have to fill up the risc files, or i have to read it dynamically *)
bootloader: ARRAY[0..Pred(ROMbootsize)] of uint32_t = ({$include "./risc-boot.inc"});



TYPE
enumtype = (
  MOV_ = 0,
  LSL_ = 1,
  ASR_ = 2,
  ROR_ = 3,
  AND_ = 4,
  ANN_ = 5,
  IOR_ = 6,
  XOR_ = 7,
  ADD_ = 8,
  SUB_ = 9,
  MUL_ = 10,
  DIV_ = 11,
  FAD_ = 12,
  FSB_ = 13,
  FML_ = 14,
  FDV_ = 15
  );

(*
VAR

riscoperator :  ARRAY[0..15] OF string = (
  'MOV',
  'LSL',
  'ASR',
  'ROR',
  'AND',
  'ANN',
  'IOR',
  'XOR',
  'ADD',
  'SUB',
  'MUL',
  'DIV',
  'FAD',
  'FSB',
  'FML',
  'FDV'
  );

*)

CONSTRUCTOR riscty.init(filename : string; froms, tos : string);

        var lauf : integer;
        BEGIN
        for lauf := 0 to pred(ROMbootsize) do

                BEGIN
                rom[lauf] := bootloader[lauf];
                END;

        PC:= ROMStart div 4;
        coredumpinit(froms, tos);
        disk.init(filename);
        cyclecounter := 1;
        fp.init;
        sd_card := Disk.sdcard;
(*        writeln('Riscty init PC : ', PC);
        writeln('SD Card ', sd_card); *)

        END;

DESTRUCTOR riscty.done;
BEGIN
END;


PROCEDURE riscty.coredumpinit(froms, tos : string);


        FUNCTION validnumber(s : string) : uint32_t;

                VAR code : word;
                    v : double;

                BEGIN
                validnumber := 0;
                val(s, v, code);
                IF code <> 0 THEN v := 0;
                validnumber := abs(round(v));
                END;


        BEGIN
        IF froms = '' THEN exit;
        IF tos = '' THEN exit;
        coredumpfromcycle := 0;
        coredumptocycle := 0;

{$I-}
        assign(DUMP, 'coredump.txt');
        rewrite(DUMP);
        append(DUMP);
{$I+}
        IF ioresult <> 0 THEN

                BEGIN
                exit;
                END
              ELSE
                BEGIN
                coredumpfromcycle := validnumber(froms);
                coredumptocycle := validnumber(tos);
                END;
        IF coredumptocycle < coredumpfromcycle THEN coredumptocycle := coredumptocycle;
        lasta_val := 0;
        lastb_val := 0;
        lastc_val := 0;
        END;


PROCEDURE riscty.coredumpclose;

        BEGIN
        close(DUMP);
        writeln('Dumpfile, closed');
        END;


PROCEDURE riscty.coredump;


        VAR lauf : integer;

        FUNCTION bc(b : Boolean) : string;
                BEGIN
                IF b THEN bc := '1' ELSE bc := '0';
                END;

        BEGIN
        write(DUMP, 'Cycle ',cyclecounter,#9,'PC ', lastpc,#9, 'OP ',lastop,#9, 'Type ', lasttyp,#9, 'Instruction ',lastinstruction,#9,'Address ',lastaddress,#9);
        write(DUMP, 'Z ', bc(Z),#9);
        write(DUMP, ' N ', bc(N),#9);
        write(DUMP, ' C ', bc(C),#9);
        write(DUMP, ' V ', bc(V),#9);



        write(DUMP, ' A ', (lasta_val),#9);
        write(DUMP, ' B ', (lastb_val), #9);
        write(DUMP, ' C ', (lastc_val), #9);
        write(DUMP, 'R ');
        FOR lauf := 0 TO 15 DO

                BEGIN
                write(DUMP, longint(R[lauf]),#9);
                END;

        writeln(DUMP);
        END;

PROCEDURE riscty.run(cycles :  uint32_t);

        VAR i : uint32_t;
      BEGIN
        progress := 20; (* The progress value is used to detect that the RISC cpu is busy*)
        (* waiting on the millisecond counter or on the keyboard ready*)
        (* bit. In that case it's better to just pause emulation until the*)
        (* next frame.*)
        i := 0;
        WHILE (progress > 0) AND (i < cycles) DO

              BEGIN
              single_step;
              inc(i);
              inc(cyclecounter);
              END;
      (*  writeln(' i ', i, ' progress ', progress); *)
      END;

      PROCEDURE riscty.single_step;
      const
         pbit: uint32_t = $80000000;
         qbit: uint32_t = $40000000;
         ubit: uint32_t = $20000000;
         vbit: uint32_t = $10000000;
      var
          ir: uint32_t;
          a: uint32_t;
          b: uint32_t;
          op: uint32_t;
          im: uint32_t;
          c_ : uint32_t;
          a_val: uint32_t;
          b_val: uint32_t;
          c_val: uint32_t;
          tmp: uint64_t;
          off: uint32_t;
          address: uint32_t;
          t, cx: Boolean;


      BEGIN

        IF PC < (ROMStart div 4)  THEN  ir := RAM[PC]  ELSE  ir:= ROM[PC - (ROMStart div 4)];
        lastinstruction := ir;

        inc(PC);
        lastpc := PC;
        lasta_val := 0;
        lastb_val := 0;
        lastc_val := 0;
        lastaddress := 0;
        a_val := 0;
        b_val := 0;
        c_val := 0;
        address := 0;
        off := 0;

        IF (ir and pbit) = 0  THEN
        BEGIN
          (* Register instructions*)
          a  := (ir and $0F000000) shr 24;
          b  := (ir and $00F00000) shr 20;
          op := (ir and $000F0000) shr 16;
          im := (ir and $0000FFFF);
          c_  := (ir and $0000000F);

          b_val := R[b];
          IF (ir and qbit) = 0 THEN  c_val:= R[c_] ELSE

                      BEGIN
                      IF (ir and vbit) = 0 THEN  c_val := im ELSE  c_val := ($FFFF0000 or im);
                      END;
        lastop := op;
        lasttyp := 1;

        CASE op of

         ord(MOV_) : BEGIN
                      IF (ir and ubit) = 0  THEN a_val := c_val ELSE
                            BEGIN
                            IF (ir and qbit) <>0  THEN  a_val := (c_val shl 16)
                                                ELSE
                                                 BEGIN
                                                 IF (ir and vbit) <> 0  THEN a_val := $D0 or (b2i(N) * $80000000) or (b2i(Z) * $40000000) or (b2i(C) * $20000000) or (b2i(V) * $10000000)
                                                                        ELSE   a_val := H;
                                                 END;(* ELSE*)
                            END;
                     END; (*case sequence *)

          ord(LSL_) : BEGIN
                      a_val := b_val shl (c_val and 31);
                      END;

          ord(ASR_) : BEGIN
                      a_val := (longword(b_val)) shr (c_val and 31);
                      END;

          ord(ROR_) : BEGIN
                      a_val := (b_val shr (c_val and 31)) or (b_val shl (-c_val and 31));
                      END;

          ord(AND_):  BEGIN
                      a_val := b_val and c_val;
                      END;

          ord(ANN_):  BEGIN
                      a_val:= b_val and  not(c_val);
                      END;

          ord(IOR_):  BEGIN
                      a_val:= b_val or c_val;
                      END;

          ord(XOR_):  BEGIN
                      a_val:= b_val xor c_val;
                      END;

          ord(ADD_):  BEGIN
      {$R-}
                      a_val := b_val + c_val;
      {$R+}
                      IF (((ir and ubit) <> 0) and risc.C) THEN a_val := a_val + 1;
                      risc.C:= a_val < b_val;

                      risc.V:= ((not(b_val xor c_val) and (a_val xor b_val)) shr 31) <> 0;
                      END;

          ord(SUB_):  BEGIN
                      cx := c_val > b_val;

      {$R-}
                      a_val := b_val - c_val;
      {$R+}

                      IF (((ir and ubit) <> 0) and C) THEN a_val := a_val - 1;
                      risc.C := cx;
                      risc.V := (((b_val xor c_val) and (a_val xor b_val)) shr 31) <> 0;
                      END;

          ord(MUL_):  BEGIN
                      IF (ir and ubit) = 0  THEN
                              BEGIN
                              tmp:= qword(integer(b_val)) * qword(integer(c_val));
                              END
                            ELSE
                             BEGIN
                             tmp:= qword(b_val) * qword(c_val);
                             END;
                       a_val:= tmp;
                       H:= tmp shr 32;
                      END;

          ord(DIV_): BEGIN
                      (* what to do with a negative divisor?*)
                      IF c_val <= 0 THEN

                              BEGIN
//                              writeln(' ERROR: PC ', (PC * 4 - 4) , ': divisor ',c_val, ' is not positive');
                              a_val := $DEADBEEF;
                              H     := $DEADBEEF;

                              END
                            ELSE
                              BEGIN
                              a_val := longint(b_val) div longint(c_val);
                              H:= longint(b_val) mod longint(c_val);
                              IF longint(H) < 0 THEN
                                      BEGIN
                                      dec(a_val);
                                      H := H + (c_val);
                                      END;
                              END;
                      END;


            ord(FAD_): BEGIN

                       a_val := fp.add_(b_val, c_val, i2b(ir AND ubit), i2b(ir AND vbit) );
                       END;

            ord(FSB_): BEGIN
                         a_val := fp.add_(b_val, (c_val XOR $80000000), i2b(ir AND ubit), i2b(ir AND vbit));
                        END;

            ord(FML_): BEGIN
                       a_val := fp.mul_(b_val, c_val);
                       END;

            ord(FDV_): BEGIN
                       a_val := fp.div_(b_val, c_val);
                       END;
            END;{case}

            set_register(a, a_val);
        END (* IF*)
       ELSE
         IF (ir and qbit) = 0 THEN
              BEGIN
                   lasttyp := 2;
                   (* Memory instructions*)
                   a   := (ir and $0F000000) shr 24;
                   b   := (ir and $00F00000) shr 20;
                   off :=  ir and $000FFFFF;
                   address := (R[b] + off) mod MemSize;
                   lastaddress := address;

                   IF (ir and ubit) = 0 THEN
                       BEGIN
                        IF (ir and vbit) = 0  THEN  a_val:= load_word(address)
                               ELSE a_val:= load_byte(address);
                       set_register(a, a_val);

                       END
                     ELSE
                       BEGIN
                        IF (ir and vbit) = 0 THEN store_word(address, R[a])
                          ELSE  store_byte(address, byte(R[a]));
                       END;
              END
            ELSE
              BEGIN
                  (* Branch instructions*)
                  lasttyp := 3;
                  CASE ((ir shr 24) and 15) OF
                    0: t := N;
                    1: t := Z;
                    2: t:=  C;
                    3: t:=  V;
                    4: t:= C or Z;
                    5: t:= N <> V;
                    6: t:= (N <> V) or Z;
                    7: t:= true;
                    8: t:= not(N);
                    9: t:= not(Z);
                    10: t:= not(C);
                    11: t:= not(V);
                    12: t:= not(C or Z);
                    13: t:= not(N <> V);
                    14: t:= not((N <> V) or Z);
                    15: t:= false;
                    END; (*case*)

                   IF t THEN
                      BEGIN
                       IF ((ir and vbit)<>0) THEN

                              BEGIN
                              set_register(15, PC*4);
                              END;

                       IF (ir and ubit) = 0 THEN
                          BEGIN
                                 c_ := ir and $0000000F;
                                 PC:= (R[c_] div 4) mod MemWords;
                          END
                        ELSE
                          BEGIN
                                 off:= ir and $00FFFFFF;
                                 PC:= (PC + off) mod MemWords;
                          END;
                      END;(* t *)
             END; (* IF Branch *)

      lasta_val := a_val;
      lastb_val := b_val;
      lastc_val := c_val;
      IF (cyclecounter >= coredumpfromcycle) AND (cyclecounter < coredumptocycle) THEN coredump;
      IF cyclecounter = coredumptocycle THEN coredumpclose;
      END; (* proc *)

PROCEDURE riscty.set_register(reg: integer;  value: uint32_t);

        VAR temp : longint;

        BEGIN
        R[reg]:= value;
        Z := (value = 0);

             (*   N := (value  < 0); this will never happen ??  *)
{$R-}
        temp := longint(value);
{$R+}
        N := (temp < 0);
        END;

FUNCTION riscty.load_word(address: uint32_t): uint32_t;

      BEGIN
       IF address < IOStart  THEN
         BEGIN
           load_word := RAM[address div 4];
          END
       ELSE
          BEGIN
           load_word := load_io(address);
          END;
       END;

FUNCTION riscty.load_byte(address: uint32_t): uint8_t;

  var
    w: uint32_t;

   BEGIN
    w := load_word(address);
    load_byte := byte(w shr ((address MOD 4)*8));
   END;

PROCEDURE riscty.store_word(address: uint32_t;  value: uint32_t);
  BEGIN
    IF address < IOStart THEN RAM[address div 4] := value
     ELSE
      store_io(address, value);
  END;

PROCEDURE riscty.store_byte(address: uint32_t;  value: uint8_t);

        VAR
         w: uint32_t;
         shift: uint32_t;

        BEGIN



        IF address < IOStart  THEN
           BEGIN
             w := RAM[address DIV 4];
             shift := (address and 3)*8;
             w := w and ( not($00FF shl shift));
             w := w or (longword(value) shl shift);
             RAM[address DIV 4] := w;
           END
         ELSE
           BEGIN
           store_io(address, longword(value));
           END;
      END;

FUNCTION riscty.load_io(address: uint32_t): uint32_t;
        var
        tmouse: uint32_t;
        scancodebyte : uint8_t;

      BEGIN
        CASE address-IOStart OF

            0: BEGIN
              (* Millisecond counter*)
               dec(progress);
               load_io := current_tick;
              END;

            4: BEGIN
              (* Switches*)
                load_io := 0;
               END;

           8: BEGIN
              (* load_io := pclink.rdata; *)
              END;

          12: BEGIN
              (* load_io := pclink.rstat;  *)
              END;

          16: BEGIN
              (* SPI data*)
              IF ((spi_selected = 1) and sd_card)  THEN

                      BEGIN
                      load_io := disk.read_;
                      END
                     ELSE
                      BEGIN
                      load_io := 255;
                      END;
              END;

          20: BEGIN
              (* SPI status*)
              (* Bit 0: rx ready*)
              (* Other bits unused*)
                load_io := 1;
              END;

          24: BEGIN
              (* Mouse input / keyboard status*)
              tmouse := mouse;
               IF key_cnt > 0  THEN tmouse:= (tmouse or ($10000000)) ELSE  dec(progress);
               load_io := tmouse;
              END;

          28: BEGIN
              (* Keyboard input*)
              IF key_cnt > 0  THEN
                   BEGIN
                   scancodebyte := key_buf[0];
                   dec(key_cnt);
                   move(key_buf[1], key_buf[0], key_cnt);
                   load_io := scancodebyte;
                   END;
              END;

           ELSE load_io := 0;
        END; (* case *)
      END;

PROCEDURE riscty.store_io(address: uint32_t;  value: uint32_t);

      VAR i : 0..7;

      BEGIN
        CASE address - IOStart of
          4:  BEGIN
              (* LED control*)
              leds:= value;
              //write('LEDs: ');
              //        FOR i := 7 DOWNTO 0 DO
              //          BEGIN
              //            IF ((leds and (1 shl i)) > 0) THEN  write(i) ELSE write('-');
              //          END;
              //writeln;
              END;

          8: BEGIN
             (* pclink.Tdata(value); *)
             END;

          16:BEGIN
              (* SPI write*)
              IF ((spi_selected = 1) and sd_card) THEN disk.write_(value);
              END;
          20: BEGIN
              (* SPI control*)
              (* Bit 0-1: slave select*)
              (* Bit 2:   fast mode*)
              (* Bit 3:   netwerk enable*)
              (* Other bits unused*)
              spi_selected := value and 3;
              END;
        END;{case}
      END;

PROCEDURE riscty.set_time(tick: uint32_t);
        BEGIN
        current_tick:= tick;
        END;

PROCEDURE riscty.mouse_moved(mouse_x: integer;  mouse_y: integer);
 BEGIN
  IF (mouse_x >= 0) and (mouse_x < 1024) THEN mouse:= (mouse and  not($00000FFF)) or mouse_x;
  IF (mouse_y >= 0) and (mouse_y < 1024) THEN mouse:= (mouse and  not($00FFF000)) or (mouse_y shl 12);
 END;

PROCEDURE riscty.mouse_button(button: integer;  down: bool);
 var  bit: longint;

 BEGIN
  IF ((button >= 1) and (button < 4))  THEN
   BEGIN
    bit := 1 shl (27-button);
    IF down  THEN mouse:= mouse or bit
        ELSE  mouse:= mouse and (not(bit));
   END;
 END;

PROCEDURE riscty.keyboard_input(scancodes: keybufty;  len: uint32_t);

 BEGIN
  IF sizeof(key_buf) - key_cnt >= len  THEN
   BEGIN
    move(scancodes, key_buf[key_cnt],  len);
    key_cnt:= key_cnt + len;
   END;
END;

FUNCTION riscty.get_framebuffer_ptr: uint32_t;

 BEGIN
     get_framebuffer_ptr := DisplayStart div 4;
  END;

PROCEDURE riscty.reset;

        BEGIN
        PC := ROMSTART DIV 4;
        END;







END.

