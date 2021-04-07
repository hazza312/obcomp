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

    procedure EnterFor(loopvar: PSymbolEntry; loopid: integer);
    procedure ExitFor(loopvar: PSymbolEntry; loopid: integer);

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

{ get the assembly representation of some storage location by a symbol }
function GetRef(sym: PSymbolEntry): string;
var straddr: string;
begin
    Str(sym^.addr, straddr);
    if sym^.symType = SVariable then 
        if sym^.addr < 0 { local } then
            GetRef := '[rbp' + straddr + ']'
        else
            GetRef := '[' + straddr + ']'  

    else if sym^.symType = SFormalParameter then
        GetRef := 'rdi'; { TODO }

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
    writeln(out, chr(9), 'mov qword ', GetRegister, ', ', GetRef(v), ';LV', v^.id); 
end;


procedure DoAssign(assignTo: PSymbolEntry);
begin
    writeln(out, chr(9), 'mov qword ', GetRef(assignTo), ', ', FreeRegister, ' ; LV', assignTo^.id) 
end;


procedure DoCall(fn: PSymbolEntry);
var
    curr: TRegister;

begin
    { TODO multiple params passed }
    writeln(out, chr(9), 'mov rdi, ', FreeRegister);

    for curr := r10 to topRegister do
        writeln(out, chr(9), 'push ', curr);

    writeln(out, chr(9), 'call ', fn^.id);

    for curr := topRegister downto r10 do
        writeln(out, chr(9), 'pop ', curr);

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
    topRegister := rnul;
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


procedure EnterFor(loopvar: PSymbolEntry; loopid: integer);
begin
    { move end point somewhere TODO this wont work nested }
    writeln(out, chr(9), 'mov rbx, ', FreeRegister);
    DoAssign(loopvar);

    { jumplabel }
    writeln(out, '.forloopcheck_', loopid, ':');

    { compare loopvar with end point: greater than? }
    { jump if so to end }
    writeln(out, chr(9), 'cmp ', GetRef(loopvar), ', rbx');
    writeln(out, chr(9), 'jg ', '.forloopafter_', loopid);
end;



procedure ExitFor(loopvar: PSymbolEntry; loopid: integer);
begin
    { increment/decrement loop var }
    writeln(out, chr(9), 'inc qword ', GetRef(loopvar));

    { unconditional jmp back to loop check }
    writeln(out, chr(9), 'jmp ', '.forloopcheck_', loopid);

    { label for after }
    writeln(out, '.forloopafter_', loopid, ':');
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
