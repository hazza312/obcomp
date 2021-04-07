MODULE simplexp;
VAR 
    Y: INTEGER;


PROCEDURE double(X: INTEGER): INTEGER;
BEGIN
    RETURN X + X
END hello;


BEGIN
    Y := 10;
    RETURN 2 * Y + double(Y + 3)
  
END simplexp.
