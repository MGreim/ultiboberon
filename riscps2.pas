(* Translate SDL scancodes to PS/2 codeset 2 scancodes.*)

UNIT riscps2;


INTERFACE

USES SDL2;



FUNCTION ps2_encode(sdl_scancode: integer;  make: boolean;  VAR outs : string): integer;


IMPLEMENTATION

TYPE

modety = (K_UNKNOWN, K_NORMAL, K_EXTENDED, K_NUMLOCK_HACK, K_SHIFT_HACK);
codety = 0..255;

k_infoty = RECORD
        code: codety;
        type_: modety;
        END;

keymapty = ARRAY[0..Pred(SDL_NUM_SCANCODES)] of k_infoty;



VAR
keymap : keymapty;

function ps2_encode(sdl_scancode: integer;  make: boolean;  VAR outs : string): integer;

    VAR codes : char;
        info : k_infoty;
        mod_ : TSDL_KeyMod;
    BEGIN
         info := keymap[sdl_scancode];

         ps2_encode := 0;
         outs := '';
         codes := chr(info.code);

         CASE info.type_ OF
    K_UNKNOWN:
           BEGIN
           END;
    K_NORMAL:
           BEGIN
               IF NOT(make) THEN outs := #$F0;
               outs := outs + codes;
           END;
    K_EXTENDED:
           BEGIN
               outs := #$E0;
               IF NOT(make) THEN outs := outs + #$F0;
               outs := outs + codes;
           END;
    K_NUMLOCK_HACK:
           BEGIN
               IF (make) THEN

                 BEGIN
                 outs := #$E0 + #$12 +#$E0 + codes;  (* fake shift press*)
                 END
               ELSE
                 BEGIN
                 outs := #$E0 + #$F0 + codes + #$E0 + #$F0 + #$12;
                 (* fake shift release*)
                 END;
           END;
    K_SHIFT_HACK:
           BEGIN
               mod_ :=SDL_GetModState();
               IF make THEN
                 BEGIN
                 (* fake shift release*)
                 IF ((mod_ and KMOD_LSHIFT) > 0) THEN outs := outs + #$E0 + #$F0 + #$12;
                 IF ((mod_ and KMOD_RSHIFT) > 0) THEN outs := outs + #$E0 + #$F0 + #$59;
                 outs := outs + #$E0;
                 outs := outs + codes;
                 END
               else
                 BEGIN
                 outs := outs + #$E0 + #$F0 + codes;
                 (* fake shift press*)
                 IF ((mod_ and KMOD_RSHIFT) > 0) THEN outs := outs + #$E0 + #$59;
                 IF ((mod_ and KMOD_LSHIFT) > 0) THEN outs := outs + #$E0 + #$12;
                 END;
           END;
         END;{case}
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


keymap[SDL_SCANCODE_A].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_B].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_C].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_D].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_E].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_F].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_G].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_H].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_I].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_J].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_K].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_L].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_M].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_N].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_O].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_P].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_Q].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_R].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_S].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_T].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_U].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_V].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_W].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_X].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_Y].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_Z].type_:=(K_NORMAL);

keymap[SDL_SCANCODE_1].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_2].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_3].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_4].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_5].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_6].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_7].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_8].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_9].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_0].type_:=(K_NORMAL);

keymap[SDL_SCANCODE_RETURN].type_:= (K_NORMAL);
keymap[SDL_SCANCODE_ESCAPE].type_:= (K_NORMAL);
keymap[SDL_SCANCODE_BACKSPACE].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_TAB].type_:= (K_NORMAL);
keymap[SDL_SCANCODE_SPACE].type_:= (K_NORMAL);

keymap[SDL_SCANCODE_MINUS].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_EQUALS].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_LEFTBRACKET].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_RIGHTBRACKET].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_BACKSLASH].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_NONUSHASH].type_:=(K_NORMAL);

keymap[SDL_SCANCODE_SEMICOLON].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_APOSTROPHE].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_GRAVE].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_COMMA].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_PERIOD].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_SLASH].type_:=(K_NORMAL);

keymap[SDL_SCANCODE_F1].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_F2].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_F3].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_F4].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_F5].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_F6].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_F7].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_F8].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_F9].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_F10].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_F11].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_F12].type_:=(K_NORMAL);

keymap[SDL_SCANCODE_INSERT].type_:=(K_NUMLOCK_HACK);
keymap[SDL_SCANCODE_HOME].type_:=(K_NUMLOCK_HACK);
keymap[SDL_SCANCODE_PAGEUP].type_:=(K_NUMLOCK_HACK);
keymap[SDL_SCANCODE_DELETE].type_:=(K_NUMLOCK_HACK);
keymap[SDL_SCANCODE_END].type_:=(K_NUMLOCK_HACK);
keymap[SDL_SCANCODE_PAGEDOWN].type_:=(K_NUMLOCK_HACK);
keymap[SDL_SCANCODE_RIGHT].type_:=(K_NUMLOCK_HACK);
keymap[SDL_SCANCODE_LEFT].type_:=(K_NUMLOCK_HACK);
keymap[SDL_SCANCODE_DOWN].type_:=(K_NUMLOCK_HACK);
keymap[SDL_SCANCODE_UP].type_:=(K_NUMLOCK_HACK);

keymap[SDL_SCANCODE_KP_DIVIDE].type_:=(K_SHIFT_HACK);
keymap[SDL_SCANCODE_KP_MULTIPLY].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_KP_MINUS].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_KP_PLUS].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_KP_ENTER].type_:=(K_EXTENDED);
keymap[SDL_SCANCODE_KP_1].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_KP_2].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_KP_3].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_KP_4].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_KP_5].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_KP_6].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_KP_7].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_KP_8].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_KP_9].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_KP_0].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_KP_PERIOD].type_:=(K_NORMAL);

keymap[SDL_SCANCODE_NONUSBACKSLASH].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_APPLICATION].type_:=(K_EXTENDED);

keymap[SDL_SCANCODE_LCTRL].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_LSHIFT].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_LALT].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_LGUI].type_:=(K_EXTENDED);
keymap[SDL_SCANCODE_RCTRL].type_:=(K_EXTENDED);
keymap[SDL_SCANCODE_RSHIFT].type_:=(K_NORMAL);
keymap[SDL_SCANCODE_RALT].type_:=(K_EXTENDED);
keymap[SDL_SCANCODE_RGUI].type_:=(K_EXTENDED);





END.
