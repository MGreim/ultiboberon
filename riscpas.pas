(*
Oberon RISC Emulator for Pascal
==============================

translation of the Oberon Risc Emulator from
Peter De Wachter to Freepascal by Markus Greim

I was using:

The origianl C sources from:
  https://github.com/pdewacht/oberon-risc-emu
  (C) Peter de Wachter (Copyright Notice belwow)

For the first try i was unsing
c2pas32  v0.9b
  (c) 2001 Oleg Bulychov
  Gladiators Software
  http://www.astonshell.com/
but this was net a real help..


SDL2 headers translation for Free Pascal
  https://bitbucket.org/p_daniel/sdl-2-for-free-pascal-compiler
  from P. Daniel

SDL
  Simple DirectMedia Layer
  Copyright (C) 1997-2013 Sam Lantinga <slouken@libsdl.org>

The Oberon bootload code
  risc_boot.inc
  http://projectoberon.com/
from Paul Reed

Original Project Oberon Sources and Disk Image:
  http://www.inf.ethz.ch/personal/wirth/ProjectOberon/index.html
  design and source code copyright (C) 1991-2014 Niklaus Wirth (NW) and Joerg Gutknecht (JG)

  -----Peter de Wachter Copyright Notice-----------------------------------------------------------------

Copyright
---------

Copyright (C) 2014 Peter De Wachter

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted, provided that the
above copyright notice and this permission notice appear in all
copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.


===============================================================================================*)
(* Bugs and known issues by Markus Greim:
- 06.may.2014
  - refreshing screen works
  - coredum.txt is created when program called by
    riscpas oeberon.fs 1 10000
    - the numbers are the stored cycles

- 03.may.2014
  Its starting up so far
  - refreshing of the screen only when mouse is moved
  - i am writing a coredump.txt for the first 2999 risc cycles

*)




{*********************************}
{*********************************}

PROGRAM riscpas;

USES SDL2, risccore, riscps2, riscglob;

const
BLACK = $657b83;
WHITE = $fdf6e3;

(*static uint32_t BLACK = 0x000000, WHITE = 0xFFFFFF;*)
(*static uint32_t BLACK = 0x0000FF, WHITE = 0xFFFF00;*)
(*static uint32_t BLACK = 0x000000, WHITE = 0x00FF00;*)

TYPE
cachety =  ARRAY[0..Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT DIV 32)] of uint32_t;
bufferty = ARRAY[0..Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT)] OF uint32_t;


VAR
cache: cachety;
buffer: bufferty;


PROCEDURE init_texture(texture: pSDL_Texture);
     VAR i : longint;

     BEGIN
       fillchar(cache,sizeof(cache), 0);

       FOR  i := 0 TO Pred(RISC_SCREEN_WIDTH*RISC_SCREEN_HEIGHT) DO

           BEGIN
             buffer[i] := BLACK;
           END;

       SDL_UpdateTexture(texture,NIL,@buffer,RISC_SCREEN_WIDTH*4);
     END;

PROCEDURE update_texture(framebufferpointer : uint32_t;  texture: pSDL_Texture);

     VAR
        dirty_y1: integer;
        dirty_y2: integer;
        dirty_x1: integer;
        dirty_x2: integer;
        idx: integer;
        pixels: uint32_t;
        rect: TSDL_Rect;
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
                 SDL_UpdateTexture(texture, @rect, ptr, RISC_SCREEN_WIDTH * 4);

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



FUNCTION scale_display(window : PSDL_WINDOW; VAR rect : TSDL_RECT) : double;

        VAR
        win_w, win_h : plongint;
        w, h : longint;
        oberon_aspect, window_aspect : double;
        scale : double;

        BEGIN
        new(win_w);
        new(win_h);
        SDL_GETWindowSize(window, win_w, win_h);
        oberon_aspect := RISC_SCREEN_WIDTH / RISC_SCREEN_HEIGHT;
        window_aspect := 1;
        IF win_h^ <> 0 THEN  window_aspect := win_w^ / win_h^;
        IF oberon_aspect > window_aspect THEN scale := win_w^ / RISC_SCREEN_WIDTH
                                         ELSE scale := win_h^ / RISC_SCREEN_HEIGHT;
        w := ceil(RISC_SCREEN_WIDTH * scale);
        h := ceil(RISC_SCREEN_HEIGHT * scale);
        rect.w := w;
        rect.h := h;
        rect.x := (win_w^ - w) DIV 2;
        rect.y := (win_h^ - h) DIV 2;

        scale_display := scale;

        dispose(win_w);
        dispose(win_h);
        END;


  FUNCTION b2i(b : boolean) : integer;

        BEGIN
        IF b THEN b2i := 1 ELSE b2i := 0;
        END;

PROCEDURE main;

    var
       window: pSDL_Window;
       renderer: pSDL_Renderer;
       texture: pSDL_Texture;
       done: bool;
       event: PSDL_Event;
       frame_start: uint32_t;

       scancode: keybufty;
       scancode_s : string;
       len : 0..pred(maxkeybufsize);
       l   : 0..pred(maxkeybufsize);

       frame_end: uint32_t;

       delay: longint;
       window_pos, window_flags, display_cnt, i, x, y, scaled_x, scaled_y : longint;
       fullscreen, mouse_is_offscreen, mouse_was_offscreen, down : Boolean;
       bounds, display_rect : PSDL_Rect;
       display_scale : double;
       k : TSDL_keysym;



       BEGIN
       fullscreen := false;
       mouse_was_offscreen := false;
       new(bounds);
       new(display_rect);

         IF paramcount <> 1 THEN
            BEGIN
              writeln('Argv : ', paramcount);
              writeln('Args : ', paramstr(0), ' ', paramstr(1),' ',paramstr(2),' ',paramstr(3));
              writeln('Usage: riscpas disk-file-name [coredumpfile_from_cycle coredumpfile_to_cycle]');
              writeln('Stop with Alt-F4');
              exitcode := 1;
              exit;
            END;

         risc.init(paramstr(1), paramstr(2), paramstr(3));


         IF SDL_Init(SDL_INIT_VIDEO) <> 0 THEN
             BEGIN
               writeln('Unable to initialize SDL: ',SDL_GetError);
               exitcode := 1;
               exit;
             END;

      (*   atexit(SDL_QuitEV); *)
         SDL_EnableScreenSaver;
         SDL_ShowCursor(0);
         SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, 'best');


   (*      risc.init(paramstr(1));  *)
         window_pos := SDL_WINDOWPOS_UNDEFINED;
         window_flags := SDL_WINDOW_HIDDEN;
         IF fullscreen THEN

                BEGIN
                window_flags := window_flags OR SDL_WINDOW_FULLSCREEN_DESKTOP;
                display_cnt := SDL_GetNumVideoDisplays;
                FOR i := 0 TO pred(display_cnt) DO

                        BEGIN
                        SDL_GETDIsplayBounds(i, bounds);
                        IF (bounds^.w >= RISC_SCREEN_WIDTH) AND (bounds^.h = RISC_SCREEN_HEIGHT) THEN

                                BEGIN
(*                                window_pos := SDL_WINDOWPOS_UNDEFINED_DISPLAY(i);
                                IF (bounds.w = RISC_SCREEN_WIDTH) THEN writeln('break?'); *)
                                END;
                        END;
                 END;

         window := SDL_CreateWindow('Project Oberon',window_pos, window_pos, RISC_SCREEN_WIDTH,RISC_SCREEN_HEIGHT, window_flags);
         IF window = NIL THEN

             BEGIN
               writeln('Could not create window: ',SDL_GetError);
               exitcode:= 1;
               exit;
             END;

         renderer := SDL_CreateRenderer(window,-1,0);

         IF renderer= NIL THEN

             BEGIN
               writeln('Could not create renderer: ',SDL_GetError);
               exitcode:= 1;
               exit;
             END;

         texture := SDL_CreateTexture(renderer,SDL_PIXELFORMAT_ARGB8888,
                                      SDL_TEXTUREACCESS_STREAMING,
                                      RISC_SCREEN_WIDTH,RISC_SCREEN_HEIGHT);

         IF texture = NIL THEN

              BEGIN
                writeln('Could not create texture: ',SDL_GetError);
                exitcode:= 1;
                exit;
              END;

         display_scale := scale_display(window, display_rect^);
         init_texture(texture);
         SDL_ShowWindow(window);
         SDL_RenderClear(renderer);
         SDL_RenderCopy(renderer,texture,NIL,display_rect);
         SDL_RenderPresent(renderer);

         done := False;
         mouse_was_offscreen := False;
         new(event);

         WHILE NOT(done) DO

            BEGIN
              frame_start:=SDL_GetTicks;
              WHILE (SDL_PollEvent(event) = 1) DO

                   BEGIN

                   CASE event^.type_ OF

                    SDL_QUITEV:
                            BEGIN
                              done:= True;
                            END;

                    SDL_WINDOWEVENT:
                            BEGIN
                              IF event^.window.event = SDL_WINDOWEVENT_RESIZED THEN

                                BEGIN
                                display_scale := scale_display(window, display_rect^);
                                END;
                            END;

                    SDL_MOUSEMOTION:
                            BEGIN
                              scaled_x := 1;
                              scaled_y := 1;

                              IF display_scale <> 0 THEN scaled_x := round((event^.motion.x - display_rect^.x) / display_scale);
                              IF display_scale <> 0 THEN scaled_y := round((event^.motion.y - display_rect^.y) / display_scale);
                              x := clamp(scaled_x, 0, RISC_SCREEN_WIDTH - 1);
                              y := clamp(scaled_y, 0, RISC_SCREEN_HEIGHT -1 );
                              mouse_is_offscreen := (x <>  scaled_x) OR (y <> scaled_y);
                              IF (mouse_is_offscreen <> mouse_was_offscreen) THEN

                                BEGIN
                                SDL_ShowCursor(b2i(mouse_is_offscreen));
                                mouse_was_offscreen := mouse_is_offscreen;
                                END;

                              risc.mouse_moved(x,RISC_SCREEN_HEIGHT - y -1);
                            END;

                    SDL_MOUSEBUTTONDOWN,
                    SDL_MOUSEBUTTONUP:
                            BEGIN
                              down := event^.button.state=SDL_PRESSED;
                              risc.mouse_button(event^.button.button,down);
                            END;

                    SDL_KEYDOWN,
                    SDL_KEYUP:
                            BEGIN
                                down := (event^.key.state = SDL_PRESSED);
                                k := event^.key.keysym;
                                CASE k.sym OF

                                SDLK_F12:
                                         BEGIN
                                            write('F12');
                                            IF down THEN risc.reset;
                                          END;
                                SDLK_F11:
                                          BEGIN
                                          IF down THEN
                                                BEGIN
                                                fullscreen := NOT(fullscreen);
                                                IF fullscreen THEN SDL_SetWindowFullScreen(window, SDL_WINDOW_FULLSCREEN_DESKTOP)
                                                              ELSE SDL_SetWindowFullscreen(window, 0);
                                                END;
                                          END;
                               SDLK_F4:
                                         BEGIN
                                         IF ((k._mod AND KMOD_ALT) <> 0) THEN

                                                BEGIN
                                                IF down THEN

                                                        BEGIN
                                                        event^.type_ := SDL_QUITEV;
                                                        SDL_PUSHEvent(event)
                                                        END;
                                                END;
                                         END;

                               SDLK_LALT:
                                        BEGIN
                                        risc.mouse_button(2, down);
                                        END;

                               ELSE (* else case keyup *)
                                        (* BEGIN *)
                                        len := ps2_encode(event^.key.keysym.scancode,event^.key.state=SDL_PRESSED,scancode_s);
                                            IF len > 0 THEN

                                                BEGIN
                                                FOR l := 0 TO pred(len) DO

                                                        BEGIN
                                                        scancode[l] := ord(scancode_s[succ(l)]);
                                                      (*  write('|',scancode[l]); *)
                                                        END;
                                                 END;
                                        risc.keyboard_input(scancode, len);
                                        END; (*else case keyup *)
                              END; (* case k.sym *)

                   END;  (* case event^.typ *)
              END;(* while poll event *)
              risc.set_time(frame_start);

              risc.run(CPU_HZ DIV FPS);
              update_texture(risc.get_framebuffer_ptr, texture);
              SDL_RenderClear(renderer);
              SDL_RenderCopy(renderer, texture, NIL, display_rect);
              SDL_RenderPresent(renderer);

              frame_end := SDL_GetTicks;
              delay := frame_start + (1000 div FPS) - frame_end;

              IF delay > 0 THEN SDL_Delay(delay);

              exitcode := 0;
        END; (* while not done *)
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        dispose(event);
        risc.done;
        //shutting down video subsystem
        SDL_Quit;

      END; (* proc *)


BEGIN

 main;

END.
