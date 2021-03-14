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
    id:     array[1..16] of char;       { ptr to the string identifier }
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

  { public procedures for mutating symbol table }
  function DeclareVariable(name: string): boolean;
  function DeclareProcedure(name: string): boolean;
  function DeclareType(name: string): boolean;
  function DeclareRecordType(name: string): boolean;


  function EnterScope: boolean;
  function ExitScope: boolean;

  { procedures for looking up symbol table }
  function GetType(tyStr: string): PSymbolEntry;
  function GetVariable(varStr: string): PSymbolEntry;
  function GetProcedure(varProc: string): PSymbolEntry;

  procedure Dump;



implementation

var
  table: array[1..MAX_SYMBOLS] of TSymbolEntry;
  nos: 1..MAX_SYMBOLS;
  scope: integer;

  { some private helpers }

  function Declare(name: string; stype: TSymbolType): boolean;
  begin
    table[nos].id := name;
    table[nos].loc := currentLocation;
    table[nos].symType := stype;
    table[nos].scope := scope;
    Inc(nos);
  end;

  function DeclareVariable(name: string): boolean;
  begin Declare(name, SVariable) end;

  { public procedures for mutating symbol table }
  function DeclareType(name: string): boolean; 
  begin Declare(name, SSimpleType) end;

  function DeclareProcedure(name: string): boolean; 
  begin Declare(name, SProcedure) end;

  function DeclareRecordType(name: string): boolean; 
  begin Declare(name, SRecordType) end;


  function EnterScope: boolean; begin Inc(scope) end;
  function ExitScope: boolean; begin Dec(scope) end;

  { procedures for looking up symbol table }
  function GetType(tyStr: string): PSymbolEntry; begin end;
  function GetVariable(varStr: string): PSymbolEntry; begin end;
  function GetProcedure(varProc: string): PSymbolEntry; begin end;

  procedure Dump;
  var i: integer;
  begin
    writeln('L':3, ' ',  'type':12, 'sco':5, '@':20, 'name':20);
    for i := 1 to nos-1 do
      begin
        with table[i] do
          begin
            writeln(loc.line:3, ' ',  table[i].symType:12, table[i].scope:5, addr:20, id:20);
          end;
      end
  end;

begin
  nos := 1;
  scope := 0;
end.
