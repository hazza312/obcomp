MODULE hello;
IMPORT Out;

CONST
  b1 = 3;
  b3 = {};
  b4 = {1};
  b5 = {1,2};
  b6 = "hello";
  b7 = "hello there";


TYPE
  a1 = INTEGER;
  a2 = REAL;
  a3 = RECORD 
    day, month, year: INTEGER;
    age: INTEGER
  END;




VAR
  f, y: INTEGER;
  t: REAL;
  A: ARRAY 234, 345 OF INTEGER;
  C*, D*: INTEGER;
  

PROCEDURE ProcNoArgsNoReturn;
BEGIN
  f
END ProcNoArgsNoReturn;
  

PROCEDURE ProcNoArgsReturna: INTEGER;
BEGIN
  f
END ProcNoArgsReturna;


PROCEDURE ProcNoArgsBracketsReturn(): INTEGER;
BEGIN
  ProcNoArgsBracketsReturn
END ProcNoArgsBracketsReturn;


PROCEDURE Proc1arg(x:  INTEGER): INTEGER;
BEGIN
  Proc1arg
END Proc1arg;



PROCEDURE Procargsametype(x, y: INTEGER; z: REAL; d: SOMETHINGELSE): INTEGER;
VAR
  x : INTEGER;
BEGIN
  Procargsametype
END Procargsametype;


PROCEDURE Nested;
    PROCEDURE Nesteda;
    VAR
        yy: INTEGER;
    BEGIN
        Nested
    END Nesteda;


VAR
  x: INTEGER;
    

BEGIN
    Procargsametype
END Nested;






PROCEDURE Public* (x, y, z:  INTEGER; z: REAL): INTEGER;
BEGIN f END Public;



BEGIN
  f := ((A[0][1][2][3] + 1) * (3-2)) DIV 4
  
END hello.