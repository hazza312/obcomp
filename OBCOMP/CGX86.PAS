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
procedure VarUse(v: PSymbolEntry);
procedure AllocLocal(lvar: PSymbolEntry);


implementation
    
type
    TRegister = (rax, r8, r9, r10, r11, r12, r13, r14, r15);
    
var
    topRegister: TRegister;
    out: text;
    stackSpace: integer;

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
    
    
procedure AllocLocal(lvar: PSymbolEntry);
begin
  lvar^.addr := stackSpace;
  Dec(stackSpace, 8);
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
        Mul:      writeln(out, chr(9), 'imul ', topRegister, ', ', top);
        Divide:   
          begin
            { TODO make this nicer }
            { X86_64 with 64 bit divisor needs dividend in RDX o RAX }
            { Quotient result in RAX } 

            writeln(out, chr(9), 'mov rax, ', topRegister);
            writeln(out, chr(9), 'idiv ', top);
            writeln(out, chr(9), 'mov ', topRegister, ', ', topRegister);
          end
    end;    
end;


procedure VarUse(v: PSymbolEntry);
begin
     if v^.addr < 0 { local } then
       writeln(out, chr(9), 'mov qword ', GetRegister, ', [rbp', v^.addr, '] ; LV', v^.id)
    else
       writeln(out, chr(9), 'mov qword ', GetRegister, ', [', v^.addr, '] ; LV', v^.id)   
 
end;


procedure DoAssign(assignTo: PSymbolEntry);
begin
    if assignTo^.addr < 0 { local } then
       writeln(out, chr(9), 'mov qword [rbp', assignTo^.addr, '], ', FreeRegister, ' ; LV', assignTo^.id)
    else
       writeln(out, chr(9), 'mov qword [', assignTo^.addr, '], ', FreeRegister, ' ;', assignTo^.id);   
    
end;


{ entry in symbol table }
procedure BeginFunction;
begin
    stackSpace := 0;
    topRegister := R8;
    writeln(out, 'global ', LastEntry^.id);
    writeln(out, LastEntry^.id, ':');
    { reserve some snack space }
end;


procedure EndFunction;
begin
    writeln(out, chr(9), 'mov eax, 60');
    writeln(out, chr(9), 'xor edi, edi');
    writeln(out, chr(9), 'mov rdi, ', FreeRegister);
    writeln(out, chr(9), 'syscall');
    Flush(out);
end;


begin
    Assign(out, ''); 
    rewrite(out);
    SymbolTable.DeclarePrimitive('INTEGER', 8);
    SymbolTable.DeclarePrimitive('REAL', 8);
    SymbolTable.DeclarePrimitive('CHAR', 1);
    SymbolTable.DeclarePrimitive('STRING', 256);
    writeln(out, 'bits 64');
end.
