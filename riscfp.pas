UNIT riscfp;


INTERFACE

uses riscglob;


TYPE

fpty = OBJECT
        public
        FUNCTION add_(x, y : uint32_t;  u, v : Boolean) : uint32_t;
        FUNCTION mul_(x, y : uint32_t) : uint32_t;
        FUNCTION div_(x, y : uint32_t) : uint32_t;
        CONSTRUCTOR init;
        DESTRUCTOR done;
        END;




VAR fp : fpty;

FUNCTION b2i(b : Boolean) : uint8_t;
FUNCTION i2b(i : uint32_t) : Boolean;


IMPLEMENTATION

FUNCTION b2i(b : Boolean) : uint8_t;

    BEGIN
    IF b THEN b2i := 1 ELSE b2i := 0;
    END;

FUNCTION i2b(i : uint32_t) : Boolean;

        BEGIN
        IF i <> 0 THEN i2b := True ELSE i2b := False;
        END;



CONSTRUCTOR fpty.init;

        BEGIN
        END;


FUNCTION fpty.add_(x, y : uint32_t; u, v : Boolean) : uint32_t;


        VAR ys, xs : Boolean;
            xm, xe, ye, ym, e0, sum, s, e1, t3, shift : uint32_t;
            y0, x0, x3, y3 : int32;



  BEGIN
  xs := (x AND $80000000) <>  0;
  if NOT(u) THEN
    BEGIN
    xe := (x SHR 23) AND $FF;
    xm := ((x AND $7FFFFF) SHL 1) OR $1000000;
    IF xs THEN x0 := -xm ELSE x0 := xm;
    END
  ELSE
    BEGIN
    xe := 150;
    x0 := (((x AND $00FFFFFF) SHL 8) SHR 7);
    END;

  ys := (y AND $80000000) <> 0;
  ye := (y SHR 23) AND $FF;
  ym := ((y AND $7FFFFF) SHL 1);

  IF (NOT(u) AND NOT(v)) THEN ym := ym OR $1000000;
  IF ys THEN y0 := -ym ELSE y0 := ym;

  IF (ye > xe) THEN
    BEGIN
    shift := ye - xe;
    e0 := ye;
    IF (shift > 31) THEN x3 :=  (x0 SHR 31) ELSE x3 := (x0 SHR shift);
    y3 := y0;
    END
  ELSE
    BEGIN
    shift := xe - ye;
    e0    := xe;
    x3    := x0;
    IF (shift > 31) THEN y3 :=  (y0 SHR 31) ELSE y3 := (y0 SHR shift);
    END;


   sum := ((b2i(xs) SHL 26) OR (b2i(xs) SHL 25) OR (x3 AND $01FFFFFF))
    + ((b2i(ys) SHL 26) OR (b2i(ys) SHL 25) OR (y3 AND $01FFFFFF));

  IF ((sum AND (1 SHL 26)) <> 0) THEN s := -sum ELSE s:= sum;
  s := (s + 1) AND $07FFFFFF;

  e1 := e0 + 1;
  t3 := s SHR 1;
  if ((s AND $3FFFFFC) <> 0) THEN

        BEGIN
        WHILE ((t3 AND (1 SHL 24)) = 0) DO
                BEGIN
                t3 := t3 SHL 1;
                dec(e1);
                END
        END
      ELSE
        BEGIN
        t3 := t3 SHL 24;
        e1 := e1 - 24;
        END;

  if v THEN

       BEGIN
       add_ := (sum SHL 5) SHR 6;
       exit;
      END
     ELSE
       BEGIN
       IF ((x AND $7FFFFFFF) = 0) THEN
           BEGIN
           IF NOT(u) THEN add_ := y ELSE add_ := 0;
           exit
           END;

       if ((y AND $7FFFFFFF) = 0) THEN

                BEGIN
                add_ := x;
                exit;
                END;
       if ((t3 AND $01FFFFFF) = 0) OR ((e1 AND $100) <> 0) THEN

                BEGIN
                add_ := 0;
                exit;
                END;
       END;

       add_ :=  ((sum AND $04000000) SHL 5) OR (e1 SHL 23) OR ((t3 SHR 1) AND $7FFFFF);

   END;


FUNCTION fpty.mul_( x,y :  uint32_t) : uint32_t;

       VAR
          sign, xe, ye, xm, ym, e1, z0 : uint32_t;
          m : uint64_t;


      BEGIN
       sign := (x XOR y) AND $80000000;
       xe   := (x SHR 23) AND $FF;
       ye   := (y SHR 23) AND $FF;

       xm    := (x AND $7FFFFF) OR $800000;
       ym    := (y AND $7FFFFF) OR $800000;
       m     := xm * ym;

       e1 := (xe + ye) - 127;
       if ((m AND (1 SHL 47)) <> 0) THEN

                BEGIN
                inc(e1);
                z0 := (m SHR 24) AND $7FFFFF;
                END
              ELSE
                BEGIN
                z0 := (m SHR 23) AND $7FFFFF;
                END;


       IF ((xe = 0) OR (ye = 0)) THEN
             BEGIN
             mul_ := 0;
             exit;
             END;
       IF ((e1 AND $100) = 0) THEN

             BEGIN
             mul_ :=  sign OR ((e1 AND $FF) SHL 23) OR z0;
             exit;
             END;
       IF ((e1 AND $80) = 0) THEN

             BEGIN
             mul_ := sign OR ($FF SHL 23) OR z0;
             exit;
             END;

       mul_ := 0;
      END;


FUNCTION fpty.div_( x,y :  uint32_t ) : uint32_t;

        VAR
        e1, sign, xe, ye, xm, ym, q1,  q2 : uint32_t;


        BEGIN
         sign := (x XOR y)  AND $80000000;
         xe   := (x SHR 23) AND $FF;
         ye   := (y SHR 23) AND $FF;

         xm   := (x AND $7FFFFF) OR $800000;
         ym   := (y AND $7FFFFF) OR $800000;
         q1   := (xm * (1 SHL 23) DIV ym);

         e1   := (xe - ye) + 126;


        if ((q1 AND $800000) <> 0) THEN

                BEGIN
                inc(e1);
                q2 := q1 AND $7FFFFF;
                END
               ELSE
                BEGIN
                q2 := (q1 SHL 1) AND $7FFFFF;
                END;

          IF (xe = 0) THEN

                BEGIN
                div_ := 0;
                exit;
                END;

          IF (ye = 0) THEN

                BEGIN
                div_ :=  sign OR ($FF SHL 23);
                exit;
                END;
          if ((e1 AND $100) = 0) THEN

                BEGIN
                div_ := sign OR ((e1 AND $FF) SHL 23) OR q2;
                exit;
                END;

          if ((e1 AND $80) = 0) THEN

                BEGIN
                div_ :=  sign OR ($FF SHL 23) OR q2;
                exit;
                END;

          div_ := 0;

        END;

DESTRUCTOR fpty.done;

        BEGIN
        END;

END.
