MODULE forloop;
VAR SUM, I: INTEGER;
BEGIN
    SUM := 0;
    FOR I := 1 TO 10 DO
        SUM := SUM + I
    END;

    RETURN SUM

END forloop.
