MODULE simplexp;
VAR 
  X: INTEGER;


PROCEDURE hello;
VAR X: INTEGER;
BEGIN
  X := 3
END hello;


PROCEDURE hello2;
VAR X: INTEGER;
BEGIN
  X := 3
END hello2;

PROCEDURE hello3;
VAR X: INTEGER;
BEGIN
  X := 3
END hello2;


BEGIN
  hello;
  hello2;
  hello3;
  X := (7 - 4);
  RETURN (X+ 2) * 4
  
END simplexp.
