unit SymbolTable;
interface

uses
    Common, Lexer;

const
    MAX_SYMBOLS = 100;

type
    PSymbolEntry = ^TSymbolEntry;

    { which symbols can we store in our table? }
    TSymbolType = (
        SPrimitiveType,
        SVariable,
        SArrayType,
        SArrayDimension,
        SSimpleType,
        SProcedure,
        SModule,
        SFormalParameter,
        SConstant,
        SRecordType,
        SRecordField
    );

    TFormalParameterFlag = (FPFlagVar, FPFlagReturn);

    TSymbolEntry = record
        id:     string[32];
        scope:  integer;    { scope depth, 0=main }
        loc:    Location;   { of declaration }
        addr:   integer;    { not used in case of type? to be filled by code gen }


    case symType: TSymbolType of
        SVariable:          (varType:        PSymbolEntry);
        SArrayType:         (elementType:    PSymbolEntry);
        SConstant:          (constVal:       integer);
        SRecordType:        (baseRecordType: PSymbolEntry);
        SFormalParameter:   (fpFlags:        set of TFormalParameterFlag);
        SPrimitiveType:     (primitiveSize:  integer);
    end;

    TSymbolIndex = 1..MAX_SYMBOLS;


    { public procedures for mutating symbol table }
    function EnterProcedure(name: string): PSymbolEntry;
    procedure ExitProcedure;

    function DeclarePrimitive(name: string; size: integer): PSymbolEntry;
    function DeclareModule(name: string): PSymbolEntry;
    function DeclareVariable(name: string): PSymbolEntry;
    function DeclareFormalParameter(name: string; isvar: boolean): PSymbolEntry;

    function DeclareType(name: string): PSymbolEntry;
    function DeclareRecordType(name: string): PSymbolEntry;
    function CurrentSymbolIndex: TSymbolIndex;
    function LastEntry: PSymbolEntry;
    function Find(name: string): PSymbolEntry;

    procedure AssignType(v: PSymbolEntry; ty: PSymbolEntry);
    function IToPSym(i: TSymbolIndex): PSymbolEntry;

    procedure Dump;



implementation

var
    table: array[TSymbolIndex] of TSymbolEntry;
    nos, currScopeStart: TSymbolIndex;
    scope: integer;
  
  
procedure AssignType(v: PSymbolEntry; ty: PSymbolEntry);
begin
    v^.varType := ty;
end;


function IToPSym(i: TSymbolIndex): PSymbolEntry;
begin
    IToPSym := @table[i];
end;
  

function Find(name: string): PSymbolEntry;
var 
    i: integer;
begin
    Find := nil;
    for i := 1 to nos do
        if (table[i].id = name) then
            begin
              Find := @table[i];
              exit
            end
end;


function LastEntry: PSymbolEntry; 
begin 
    LastEntry := @table[nos - 1] 
end;

{ some private helpers }
function Declare(name: string; stype: TSymbolType): PSymbolEntry;
begin
    {Declare := nil;
    if Find(name) <> nil then 
        exit;}

    table[nos].id := name;
    table[nos].loc := currentLocation;
    table[nos].symType := stype;
    table[nos].scope := scope;
    Declare := @table[nos];    
    Inc(nos);
end;


function DeclareVariable(name: string): PSymbolEntry;
begin DeclareVariable := Declare(name, SVariable) end;


{ public procedures for mutating symbol table }
function DeclareType(name: string): PSymbolEntry; 
begin DeclareType := Declare(name, SSimpleType)  end;


function EnterProcedure(name: string): PSymbolEntry; 
begin 
    EnterProcedure := Declare(name, SProcedure);
    Inc(scope);
    currScopeStart := nos;
end;


procedure ExitProcedure; 
begin 
    { nos := currScopeStart;
    while (currScopeStart = table[currScopeStart].scope) do Dec(currScopeStart); }
end;


function DeclareRecordType(name: string): PSymbolEntry; 
begin DeclareRecordType := Declare(name, SRecordType) end;


function DeclareModule(name: string): PSymbolEntry; 
begin DeclareModule := Declare(name, SModule) end;


function DeclarePrimitive(name: string; size: integer): PSymbolEntry; 
begin 
    DeclarePrimitive := Declare(name, SPrimitiveType);
    DeclarePrimitive^.primitiveSize := size;
end;


function DeclareFormalParameter(name: string; isvar: boolean): PSymbolEntry; 
begin 
    DeclareFormalParameter := Declare(name, SFormalParameter);
end;
  

function CurrentSymbolIndex: TSymbolIndex;
begin
    CurrentSymbolIndex := nos-1;
end;



procedure Dump;
var i: integer;
begin
    writeln('L':3, ' ',  'type':20, 'sco':5, '@':20, 'name':20);
    for i := 1 to nos-1 do
        with table[i] do
            writeln(loc.line:3, ' ',  table[i].symType:20, table[i].scope:5, addr:20, id:20);
end;


begin
  nos := 1;
  scope := 0;
  currScopeStart := 1;
end.
