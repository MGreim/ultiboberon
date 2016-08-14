(* Translate SDL scancodes to PS/2 codeset 2 scancodes.*)

UNIT riscps2;


INTERFACE


FUNCTION ps2_encode(sdl_scancode: integer;  make: boolean;  mod_ : word; VAR outs : string): integer;


IMPLEMENTATION

USES keyboard;

const
  SDL_SCANCODE_UNKNOWN=0;

  SDL_SCANCODE_A=4;
  SDL_SCANCODE_B=5;
  SDL_SCANCODE_C=6;
  SDL_SCANCODE_D=7;
  SDL_SCANCODE_E=8;
  SDL_SCANCODE_F=9;
  SDL_SCANCODE_G=10;
  SDL_SCANCODE_H=11;
  SDL_SCANCODE_I=12;
  SDL_SCANCODE_J=13;
  SDL_SCANCODE_K=14;
  SDL_SCANCODE_L=15;
  SDL_SCANCODE_M=16;
  SDL_SCANCODE_N=17;
  SDL_SCANCODE_O=18;
  SDL_SCANCODE_P=19;
  SDL_SCANCODE_Q=20;
  SDL_SCANCODE_R=21;
  SDL_SCANCODE_S=22;
  SDL_SCANCODE_T=23;
  SDL_SCANCODE_U=24;
  SDL_SCANCODE_V=25;
  SDL_SCANCODE_W=26;
  SDL_SCANCODE_X=27;
  SDL_SCANCODE_Y=28;
  SDL_SCANCODE_Z=29;

  SDL_SCANCODE_1=30;
  SDL_SCANCODE_2=31;
  SDL_SCANCODE_3=32;
  SDL_SCANCODE_4=33;
  SDL_SCANCODE_5=34;
  SDL_SCANCODE_6=35;
  SDL_SCANCODE_7=36;
  SDL_SCANCODE_8=37;
  SDL_SCANCODE_9=38;
  SDL_SCANCODE_0=39;

  SDL_SCANCODE_RETURN=40;
  SDL_SCANCODE_ESCAPE=41;
  SDL_SCANCODE_BACKSPACE=42;
  SDL_SCANCODE_TAB=43;
  SDL_SCANCODE_SPACE=44;

  SDL_SCANCODE_MINUS=45;
  SDL_SCANCODE_EQUALS=46;
  SDL_SCANCODE_LEFTBRACKET=47;
  SDL_SCANCODE_RIGHTBRACKET=48;
  SDL_SCANCODE_BACKSLASH=49;
  SDL_SCANCODE_NONUSHASH=50;
  SDL_SCANCODE_SEMICOLON=51;
  SDL_SCANCODE_APOSTROPHE=52;
  SDL_SCANCODE_GRAVE=53;
  SDL_SCANCODE_COMMA=54;
  SDL_SCANCODE_PERIOD=55;
  SDL_SCANCODE_SLASH=56;

  SDL_SCANCODE_CAPSLOCK=57;

  SDL_SCANCODE_F1=58;
  SDL_SCANCODE_F2=59;
  SDL_SCANCODE_F3=60;
  SDL_SCANCODE_F4=61;
  SDL_SCANCODE_F5=62;
  SDL_SCANCODE_F6=63;
  SDL_SCANCODE_F7=64;
  SDL_SCANCODE_F8=65;
  SDL_SCANCODE_F9=66;
  SDL_SCANCODE_F10=67;
  SDL_SCANCODE_F11=68;
  SDL_SCANCODE_F12=69;

    SDL_SCANCODE_INSERT=73;
  SDL_SCANCODE_HOME=74;
  SDL_SCANCODE_PAGEUP=75;
  SDL_SCANCODE_DELETE=76;
  SDL_SCANCODE_END=77;
  SDL_SCANCODE_PAGEDOWN=78;
  SDL_SCANCODE_RIGHT=79;
  SDL_SCANCODE_LEFT=80;
  SDL_SCANCODE_DOWN=81;
  SDL_SCANCODE_UP=82;


  SDL_SCANCODE_KP_DIVIDE=84;
  SDL_SCANCODE_KP_MULTIPLY=85;
  SDL_SCANCODE_KP_MINUS=86;
  SDL_SCANCODE_KP_PLUS=87;
  SDL_SCANCODE_KP_ENTER=88;
  SDL_SCANCODE_KP_1=89;
  SDL_SCANCODE_KP_2=90;
  SDL_SCANCODE_KP_3=91;
  SDL_SCANCODE_KP_4=92;
  SDL_SCANCODE_KP_5=93;
  SDL_SCANCODE_KP_6=94;
  SDL_SCANCODE_KP_7=95;
  SDL_SCANCODE_KP_8=96;
  SDL_SCANCODE_KP_9=97;
  SDL_SCANCODE_KP_0=98;
  SDL_SCANCODE_KP_PERIOD=99;

  SDL_SCANCODE_NONUSBACKSLASH=100;
  SDL_SCANCODE_APPLICATION=101;




  SDL_SCANCODE_LCTRL=224;
  SDL_SCANCODE_LSHIFT=225;
  SDL_SCANCODE_LALT=226;
  SDL_SCANCODE_LGUI=227;
  SDL_SCANCODE_RCTRL=228;
  SDL_SCANCODE_RSHIFT=229;
  SDL_SCANCODE_RALT=230;
  SDL_SCANCODE_RGUI=231;


  SDL_NUM_SCANCODES=512;


TYPE


codety = 0..255;

k_infoty = RECORD
        code: codety;
        END;

keymapty = ARRAY[0..Pred(SDL_NUM_SCANCODES)] of k_infoty;



VAR
keymap : keymapty;

//Below the Oberon code for the character recognition. So only the shift and Control
//modifiers are used.

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




function ps2_encode(sdl_scancode: integer;  make: boolean; mod_ : word; VAR outs : string): integer;

    VAR codes : char;
        info : k_infoty;

    BEGIN
         info := keymap[sdl_scancode];

         ps2_encode := 0;
         outs := '';
         codes := chr(info.code);

         //IF mod_ = 0 THEN
         //
         //  BEGIN
         //       IF NOT(make) THEN outs := #$F0;
         //       outs := outs + codes;
         //  END
         //   ELSE
         //  BEGIN

               IF make THEN
                 BEGIN
                 (*  press *)
                 IF ((mod_ and KEYBOARD_LEFT_SHIFT) > 0) THEN outs := outs +  #$12;
                 IF ((mod_ and KEYBOARD_RIGHT_SHIFT) > 0) THEN outs := outs + #$59;
                 IF ((mod_ AND KEYBOARD_CAPS_LOCK) > 0) THEN outs := outs + #$59;
                 IF ((mod_ AND KEYBOARD_LEFT_CTRL) > 0) THEN outs := outs + #$14;
                 IF ((mod_ AND KEYBOARD_RIGHT_CTRL) > 0) THEN outs := outs + #$E0 + #$14;

                 outs := outs + codes;
                 END
               else
                 BEGIN
                 outs := outs + #$F0 + codes;
                 (* release *)
                 IF ((mod_ and KEYBOARD_RIGHT_SHIFT) > 0) THEN outs := outs + #$F0 +  #$59;
                 IF ((mod_ and KEYBOARD_LEFT_SHIFT) > 0) THEN outs := outs + #$F0 +  #$12;
                 IF ((mod_ AND KEYBOARD_CAPS_LOCK) > 0) THEN outs := outs + #$F0 + #$59;
                 IF ((mod_ AND KEYBOARD_LEFT_CTRL) > 0) THEN outs := outs + #$F0+ #$14;
                 IF ((mod_ AND KEYBOARD_RIGHT_CTRL) > 0) THEN outs := outs + #$E0 + #$F0 + #$14;

                 END;
//           END;

    ps2_encode := length(outs);
    END;

BEGIN

keymap[SDL_SCANCODE_A].code:=($1C);
keymap[SDL_SCANCODE_B].code:=($32);
keymap[SDL_SCANCODE_C].code:=($21);
keymap[SDL_SCANCODE_D].code:=($23);
keymap[SDL_SCANCODE_E].code:=($24);
keymap[SDL_SCANCODE_F].code:=($2B);
keymap[SDL_SCANCODE_G].code:=($34);
keymap[SDL_SCANCODE_H].code:=($33);
keymap[SDL_SCANCODE_I].code:=($43);
keymap[SDL_SCANCODE_J].code:=($3B);
keymap[SDL_SCANCODE_K].code:=($42);
keymap[SDL_SCANCODE_L].code:=($4B);
keymap[SDL_SCANCODE_M].code:=($3A);
keymap[SDL_SCANCODE_N].code:=($31);
keymap[SDL_SCANCODE_O].code:=($44);
keymap[SDL_SCANCODE_P].code:=($4D);
keymap[SDL_SCANCODE_Q].code:=($15);
keymap[SDL_SCANCODE_R].code:=($2D);
keymap[SDL_SCANCODE_S].code:=($1B);
keymap[SDL_SCANCODE_T].code:=($2C);
keymap[SDL_SCANCODE_U].code:=($3C);
keymap[SDL_SCANCODE_V].code:=($2A);
keymap[SDL_SCANCODE_W].code:=($1D);
keymap[SDL_SCANCODE_X].code:=($22);
keymap[SDL_SCANCODE_Y].code:=($35);
keymap[SDL_SCANCODE_Z].code:=($1A);

keymap[SDL_SCANCODE_1].code:=($16);
keymap[SDL_SCANCODE_2].code:=($1E);
keymap[SDL_SCANCODE_3].code:=($26);
keymap[SDL_SCANCODE_4].code:=($25);
keymap[SDL_SCANCODE_5].code:=($2E);
keymap[SDL_SCANCODE_6].code:=($36);
keymap[SDL_SCANCODE_7].code:=($3D);
keymap[SDL_SCANCODE_8].code:=($3E);
keymap[SDL_SCANCODE_9].code:=($46);
keymap[SDL_SCANCODE_0].code:=($45);

keymap[SDL_SCANCODE_RETURN].code:= ($5a);
keymap[SDL_SCANCODE_ESCAPE].code:= ($76);
keymap[SDL_SCANCODE_BACKSPACE].code:=($66);
keymap[SDL_SCANCODE_TAB].code:= ($0D);
keymap[SDL_SCANCODE_SPACE].code:= ($29);

keymap[SDL_SCANCODE_MINUS].code:=($4E);
keymap[SDL_SCANCODE_EQUALS].code:=($55);
keymap[SDL_SCANCODE_LEFTBRACKET].code:=($54);
keymap[SDL_SCANCODE_RIGHTBRACKET].code:=($5B);
keymap[SDL_SCANCODE_BACKSLASH].code:=($5D);
keymap[SDL_SCANCODE_NONUSHASH].code:=($5D);

keymap[SDL_SCANCODE_SEMICOLON].code:=($4C);
keymap[SDL_SCANCODE_APOSTROPHE].code:=($52);
keymap[SDL_SCANCODE_GRAVE].code:=($0E);
keymap[SDL_SCANCODE_COMMA].code:=($41);
keymap[SDL_SCANCODE_PERIOD].code:=($49);
keymap[SDL_SCANCODE_SLASH].code:=($4A);

keymap[SDL_SCANCODE_F1].code:=($05);
keymap[SDL_SCANCODE_F2].code:=($06);
keymap[SDL_SCANCODE_F3].code:=($04);
keymap[SDL_SCANCODE_F4].code:=($0c);
keymap[SDL_SCANCODE_F5].code:=($03);
keymap[SDL_SCANCODE_F6].code:=($0B);
keymap[SDL_SCANCODE_F7].code:=($83);
keymap[SDL_SCANCODE_F8].code:=($0A);
keymap[SDL_SCANCODE_F9].code:=($01);
keymap[SDL_SCANCODE_F10].code:=($09);
keymap[SDL_SCANCODE_F11].code:=($78);
keymap[SDL_SCANCODE_F12].code:=($07);

keymap[SDL_SCANCODE_INSERT].code:=($70);
keymap[SDL_SCANCODE_HOME].code:=($6C);
keymap[SDL_SCANCODE_PAGEUP].code:=($7D);
keymap[SDL_SCANCODE_DELETE].code:=($71);
keymap[SDL_SCANCODE_END].code:=($69);
keymap[SDL_SCANCODE_PAGEDOWN].code:=($7A);
keymap[SDL_SCANCODE_RIGHT].code:=($74);
keymap[SDL_SCANCODE_LEFT].code:=($6B);
keymap[SDL_SCANCODE_DOWN].code:=($72);
keymap[SDL_SCANCODE_UP].code:=($75);

keymap[SDL_SCANCODE_KP_DIVIDE].code:=($4A);
keymap[SDL_SCANCODE_KP_MULTIPLY].code:=($7C);
keymap[SDL_SCANCODE_KP_MINUS].code:=($7B);
keymap[SDL_SCANCODE_KP_PLUS].code:=($79);
keymap[SDL_SCANCODE_KP_ENTER].code:=($5A);
keymap[SDL_SCANCODE_KP_1].code:=($69);
keymap[SDL_SCANCODE_KP_2].code:=($72);
keymap[SDL_SCANCODE_KP_3].code:=($7A);
keymap[SDL_SCANCODE_KP_4].code:=($6B);
keymap[SDL_SCANCODE_KP_5].code:=($73);
keymap[SDL_SCANCODE_KP_6].code:=($74);
keymap[SDL_SCANCODE_KP_7].code:=($6C);
keymap[SDL_SCANCODE_KP_8].code:=($75);
keymap[SDL_SCANCODE_KP_9].code:=($7D);
keymap[SDL_SCANCODE_KP_0].code:=($70);
keymap[SDL_SCANCODE_KP_PERIOD].code:=($71);

keymap[SDL_SCANCODE_NONUSBACKSLASH].code:=($61);
keymap[SDL_SCANCODE_APPLICATION].code:=($2F);

keymap[SDL_SCANCODE_LCTRL].code:=($14);
keymap[SDL_SCANCODE_LSHIFT].code:=($12);
keymap[SDL_SCANCODE_LALT].code:=($11);
keymap[SDL_SCANCODE_LGUI].code:=($1F);
keymap[SDL_SCANCODE_RCTRL].code:=($14);
keymap[SDL_SCANCODE_RSHIFT].code:=($59);
keymap[SDL_SCANCODE_RALT].code:=($11);
keymap[SDL_SCANCODE_RGUI].code:=($27);






END.
