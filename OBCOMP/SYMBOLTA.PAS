unit SymbolTable;
interface

uses
  Lexer;

const
  MAX_SYMBOLS = 100;

type
  PSymbolEntry = ^TSymbolEntry;

  { which symbols can we store in our table? }
  TSymbolType = (
    SPrimitiveType,
    SVariable,
    SArrayType,
    SSimpleType,
    SProcedure,
    SFormalParameter,
    SConstant,
    SRecordType,
    SRecordField
  );

  TFormalParameterFlag = (FPFlagVar, FPFlagReturn);

  TSymbolEntry = record
    id:     string[16];       { ptr to the string identifier }
    scope:  integer; { ptr to enclosing scope }
    loc:    Location;      { of first declaration }
    addr:   integer;       { not used in case of type? }
    { procedure needs to know how much stack space? -> sum of declared formals }

    case symType: TSymbolType of
      SVariable:          (varType:        ^TSymbolEntry);
      SArrayType:         (elementType:    ^TSymbolEntry;
                           size:            integer);
      SConstant:          (constVal:        integer); { TODO: what is a constant? }
      SRecordType:        (baseRecordType: ^TSymbolEntry);
      SFormalParameter:   (fpFlags:         set of TFormalParameterFlag);

  end;

  TSymbolIndex = 1..MAX_SYMBOLS;


  { public procedures for mutating symbol table }
  function DeclareVariable(name: string): boolean;
  function DeclareProcedure(name: string): boolean;
  function DeclareType(name: string): boolean;
  function DeclareRecordType(name: string): boolean;
  function LastEntry: PSymbolEntry;


  procedure EnterScope;
  procedure ExitScope;

  { procedures for looking up symbol table }
  function GetType(tyStr: string): PSymbolEntry;
  function GetVariable(varStr: string): PSymbolEntry;
  function GetProcedure(varProc: string): PSymbolEntry;

  procedure Dump;



implementation

var
  table: array[TSymbolIndex] of TSymbolEntry;
  nos, currScopeStart: TSymbolIndex;
  scope: integer;

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
  function Declare(name: string; stype: TSymbolType): boolean;
  begin
    Declare := false;
    if Find(name) <> nil then 
      exit;

    table[nos].id := name;
    table[nos].loc := currentLocation;
    table[nos].symType := stype;
    table[nos].scope := scope;
    Inc(nos);
    Declare := True;
  end;

  function DeclareVariable(name: string): boolean;
  begin DeclareVariable := Declare(name, SVariable) end;

  { public procedures for mutating symbol table }
  function DeclareType(name: string): boolean; 
  begin DeclareType := Declare(name, SSimpleType) end;

  function DeclareProcedure(name: string): boolean; 
  begin DeclareProcedure := Declare(name, SProcedure) end;

  function DeclareRecordType(name: string): boolean; 
  begin DeclareRecordType := Declare(name, SRecordType) end;


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
  Declare('INTEGER', SPrimitiveType);
  Declare('REAL', SPrimitiveType);
  Declare('CHAR', SPrimitiveType);
  Declare('STRING', SPrimitiveType);
end.
