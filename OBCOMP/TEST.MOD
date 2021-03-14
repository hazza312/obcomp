MODULE hello;
IMPORT Out;

TYPE
  a1 = integer;
  a2 = real;
  a3 = RECORD 
    day, month, year: INTEGER;
    age: INTEGER
  END;
  
  a4 = ARRAY 1 OF integer;
  a5 = ARRAY x OF integer;
  a6 = ARRAY 1, x, 5 OF integer;

CONST
  b1 = 3;
  b2 = t;
  b3 = {};
  b4 = {1};
  b5 = {1,2,3};
  b6 = "hello";
  b7 = "hello there";

VAR
  f, y: integer;
  t: real;
  A: ARRAY 234, 345 OF integer;
  

PROCEDURE ProcNoArgsNoReturn;
BEGIN
  null
END ProcNoArgsNoReturn;
  

PROCEDURE ProcNoArgsReturn: INTEGER;
BEGIN
  null
END ProcNoArgsReturn;


PROCEDURE ProcNoArgsBracketsReturn(): INTEGER;
BEGIN
  null
END ProcNoArgsBracketsReturn;


PROCEDURE Proc1arg(x:  INTEGER): INTEGER;
BEGIN
  null
END Proc1arg;


PROCEDURE Proc2argsametype(x, y:  INTEGER): INTEGER;
BEGIN
  null
END Proc2argsametype;


PROCEDURE Proc2argsametype(x, y: INTEGER; z: REAL; d: SOMETHINGELSE): INTEGER;
BEGIN
  null
END Proc2argsametype;


PROCEDURE Public* (x, y, z:  INTEGER; z: REAL): INTEGER;
BEGIN null END Public;



BEGIN
  x := ((x[0][1][2][3] + 1) * (3-2)) DIV 4
  
END hello.