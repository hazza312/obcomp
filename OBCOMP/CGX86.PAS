unit CGX86;
interface

procedure BeginFunction;
procedure EndFunction;


implementation
uses SymbolTable;
var
    out: text;


{ reg allocator? }
{ calling convention? }


{ entry in symbol table }
procedure BeginFunction;
begin
    writeln(out, ';', LastEntry^.id);
    { reserve some snack space }
end;


procedure EndFunction;
begin
    writeln(out, chr(9), 'RET');
end;


begin
    Assign(out, ''); 
    rewrite(out);
end.
