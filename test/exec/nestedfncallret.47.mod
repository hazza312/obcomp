MODULE simplexp;
VAR 
    Y: INTEGER;

PROCEDURE add1(X: INTEGER): INTEGER;
BEGIN
    RETURN X + 1
END add1;


PROCEDURE double(X: INTEGER): INTEGER;
BEGIN
    RETURN X + X
END hello;


PROCEDURE doubleplus1(X: INTEGER): INTEGER;
BEGIN
    RETURN add1(double(X))
END doubleplus1;

BEGIN
    Y := 10;
    RETURN 1 + Y + doubleplus1(Y + 2) + Y + 1
  
END simplexp.
