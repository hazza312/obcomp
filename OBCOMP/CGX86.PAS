unit CGX86;
interface
uses
  SymbolTable;


type
  TBinOp = (Add, Sub, Mul, Divide);


procedure BeginFunction;
procedure EndFunction;
procedure DoConstant(op: integer);
procedure DoOperation(op: TBinOp);
procedure DoAssign(assignTo: PSymbolEntry); {TODO}


implementation
    
type
    TRegister = (R0, R8, R9, R10, R11, R12, R13, R14, R15);
    TRegisterAllocation = set of TRegister;
    
var
    topRegister: TRegister;
    out: text;

{ register allocation }
function getRegister: TRegister;
begin
    Inc(topRegister);
    getRegister := topRegister;
end;

function freeRegister: TRegister;
begin
    freeRegister := topRegister;
    Dec(topRegister);
end;
    
    


procedure DoConstant(op: integer);
begin
    writeln(out, chr(9), 'mov ', getRegister, ', ', op);
end;


procedure DoOperation(op: TBinOp);
var
    top: TRegister;
begin
    top := FreeRegister;
    case op of 
        Add:      writeln(out, chr(9), 'add ', topRegister, ', ', top);
        Sub:      writeln(out, chr(9), 'sub ', topRegister, ', ', top);
        Mul:      writeln(out, chr(9), 'mul ', topRegister, ', ', top);
        Divide:   writeln(out, chr(9), 'div ', topRegister, ', ', top);
    end;    
end;


procedure DoAssign(assignTo: PSymbolEntry);
begin
    writeln(out, chr(9), 'mov ', assignTo^.id, ', ', FreeRegister);
end;


{ entry in symbol table }
procedure BeginFunction;
begin
    topRegister := R0;
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
