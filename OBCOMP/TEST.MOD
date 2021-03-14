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
  
TYPE
  x = integer;


VAR
  f, y: integer;
  t: real;
  A: ARRAY 234, 345 OF integer;
  
  
  
BEGIN
  x := ((x[0][1][2][3] + 1) * (3-2)) DIV 4
  
END hello.