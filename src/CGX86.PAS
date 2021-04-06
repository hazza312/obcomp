unit CGX86;
interface
uses
    SymbolTable;


type
    TBinOp = (Add, Sub, Mul, Divide);


    procedure BeginFunction(fn: PSymbolEntry);
    procedure EndFunction;
    procedure EndModule;
    procedure DoConstant(op: integer);
    procedure DoOperation(op: TBinOp);
    procedure DoAssign(assignTo: PSymbolEntry); {TODO}

    procedure DoCall(fn: PSymbolEntry);
    procedure PushArg;

    procedure VarUse(v: PSymbolEntry);
    procedure AllocLocal(lvar: PSymbolEntry);


implementation
    
type
    TRegister = (
        { parameter registers }
        rdi, rsi, rdx, rcx, r8, r9,

        { scratch registers }
        rnul, r10, r11, r12, r13, r14, r15
    );

    TParameterRegister = rdi..r9;
    TScratchRegister = r10..r15;
    
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
    if v^.symType = SVariable then 
        if v^.addr < 0 { local } then
            writeln(out, chr(9), 'mov qword ', GetRegister, ', [rbp', v^.addr, '] ; LV', v^.id)
        else
            writeln(out, chr(9), 'mov qword ', GetRegister, ', [', v^.addr, '] ; LV', v^.id)  

    else if v^.symType = SFormalParameter then
        writeln(out, chr(9), 'mov ', GetRegister, ', rdi')
 
end;


procedure DoAssign(assignTo: PSymbolEntry);
begin
    if assignTo^.addr < 0 { local } then
       writeln(out, chr(9), 'mov qword [rbp', assignTo^.addr, '], ', FreeRegister, ' ; LV', assignTo^.id)
    else
       writeln(out, chr(9), 'mov qword [', assignTo^.addr, '], ', FreeRegister, ' ;', assignTo^.id);   
    
end;


procedure DoCall(fn: PSymbolEntry);
var
    curr: TRegister;

begin
    { TODO preserve registers }

    { TODO multiple params passed }
    writeln(out, chr(9), 'mov rdi, ', FreeRegister);

    writeln(out, chr(9), 'call ', fn^.id);
    { TODO restore  registers }

    { TODO return type(s) }
    writeln(out, chr(9), 'mov ', GetRegister, ', rax')
end;

procedure PushArg;
begin
    {writeln(out, chr(9), 'push ', FreeRegister);}
end;


{ entry in symbol table }
procedure BeginFunction(fn: PSymbolEntry);
begin
    topRegister := r10;
    writeln(out, 'global ', fn^.id); { TODO }
    writeln(out, fn^.id, ':');
    writeln(out, chr(9), 'enter ', -StackSpace, ', 0');
    { reserve some snack space }
end;


procedure EndModule;
begin
    writeln(out, chr(9), 'mov eax, 60');
    writeln(out, chr(9), 'xor edi, edi');
    writeln(out, chr(9), 'mov rdi, ', FreeRegister);
    writeln(out, chr(9), 'syscall');
    Flush(out);
end;


procedure EndFunction;
begin
    writeln(out, chr(9), 'mov rax, ', topRegister);
    writeln(out, chr(9), 'leave');
    writeln(out, chr(9), 'ret');
    stackSpace := 0;
end;


begin
    stackSpace := 0;
    Assign(out, ''); 
    rewrite(out);
    SymbolTable.DeclarePrimitive('INTEGER', 8);
    SymbolTable.DeclarePrimitive('REAL', 8);
    SymbolTable.DeclarePrimitive('CHAR', 1);
    SymbolTable.DeclarePrimitive('STRING', 256);
    writeln(out, 'bits 64');
end.
