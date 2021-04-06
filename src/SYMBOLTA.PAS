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
    id:     string[32];       { ptr to the string identifier }
    scope:  integer;          { ptr to enclosing scope }
    loc:    Location;         { of first declaration }
    addr:   integer;       { not used in case of type? }
    { procedure needs to know how much stack space? -> sum of declared formals }

    case symType: TSymbolType of
      SVariable:          (varType:        ^TSymbolEntry);
      SArrayType:         (elementType:    ^TSymbolEntry);
      SConstant:          (constVal:        integer); { TODO: what is a constant? }
      SRecordType:        (baseRecordType: ^TSymbolEntry);
      SFormalParameter:   (fpFlags:         set of TFormalParameterFlag);
      SPrimitiveType:     (primitiveSize:   integer);
  end;

  TSymbolIndex = 1..MAX_SYMBOLS;


  { public procedures for mutating symbol table }
  function DeclarePrimitive(name: string; size: integer): boolean;
  function DeclareModule(name: string): boolean;
  function DeclareVariable(name: string): boolean;
  function DeclareProcedure(name: string): boolean;
  function DeclareType(name: string): boolean;
  function DeclareRecordType(name: string): boolean;
  function CurrentSymbolIndex: TSymbolIndex;
  function LastEntry: PSymbolEntry;
  function Find(name: string): PSymbolEntry;

  procedure AssignType(v: PSymbolEntry; ty: PSymbolEntry);
  function IToPSym(i: TSymbolIndex): PSymbolEntry;
  

  procedure EnterScope;
  procedure ExitScope;

  { procedures for looking up symbol table }
  function GetType(tyStr: string): PSymbolEntry;
  function GetVariable(varStr: string): PSymbolEntry;
  function GetProcedure(varProc: string): PSymbolEntry;
  
  { qualident lookups }
  { procedure StartQualident;
  function QualidentSelector(entry: PSymbolEntry); }

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
      begin
      if (table[i].id = name) then
        begin
          Find := @table[i];
          exit
        end
      end
  end;

  function LastEntry: PSymbolEntry; 
  begin 
    LastEntry := @table[nos - 1] 
  end;

  { some private helpers }
  function Declare(name: string; stype: TSymbolType): PSymbolEntry;
  begin
    Declare := nil;
    if Find(name) <> nil then 
      exit;

    table[nos].id := name;
    table[nos].loc := currentLocation;
    table[nos].symType := stype;
    table[nos].scope := scope;
    Inc(nos);
    Declare := @table[nos];
  end;

  function DeclareVariable(name: string): boolean;
  begin DeclareVariable := Declare(name, SVariable) <> nil end;

  { public procedures for mutating symbol table }
  function DeclareType(name: string): boolean; 
  begin DeclareType := Declare(name, SSimpleType) <> nil end;

  function DeclareProcedure(name: string): boolean; 
  begin DeclareProcedure := Declare(name, SProcedure) <> nil end;

  function DeclareRecordType(name: string): boolean; 
  begin DeclareRecordType := Declare(name, SRecordType) <> nil end;

  function DeclareModule(name: string): boolean; 
  begin DeclareModule := Declare(name, SModule) <> nil end;

  function DeclarePrimitive(name: string; size: integer): boolean; 
  begin 
    Declare(name, SPrimitiveType)^.primitiveSize := size;
    DeclarePrimitive := true;
  end;
  


  function CurrentSymbolIndex: TSymbolIndex;
  begin
    CurrentSymbolIndex := nos-1;
  end;

  procedure EnterScope; 
  begin 
    Inc(scope);
    currScopeStart := nos;
  end;


  procedure ExitScope; 
  begin 
    nos := currScopeStart;
    while (currScopeStart = table[currScopeStart].scope) do Dec(currScopeStart);
   end;

  { procedures for looking up symbol table }
  function GetType(tyStr: string): PSymbolEntry; begin GetType := nil end;
  function GetVariable(varStr: string): PSymbolEntry; begin GetVariable := nil end;
  function GetProcedure(varProc: string): PSymbolEntry; begin GetProcedure := nil end;


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
