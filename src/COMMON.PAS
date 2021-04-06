unit Common;

interface
type
    Location = record
        line, from, last: integer;
    end;

    procedure Error(errType: string; loc: Location; msg: string);


implementation 

procedure Error(errType: string; loc: Location; msg: string);
begin
    with loc do
        writeln(errType, ' error ', line, ': ', from, '-', last, '  ', msg);

    halt(1);
end;

    

end.
