unit SymbolTable;
interface

uses
  Lexer;

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
    SRecordType
  );

  TFormalParameterFlag = (FPFlagVar, FPFlagReturn);

  TSymbolEntry = record
    id:     ^string;       { ptr to the string identifier }
    scope:  ^TSymbolEntry; { ptr to enclosing scope }
    loc:    Location;      { of first declaration }
    addr:   integer;       { not used in case of type? }

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
  function DeclareType(name: string): boolean;
  function EnterScope: boolean;
  function LeaveScope: boolean;

  { procedures for looking up symbol table }
  function GetType(tyStr: string): PSymbolEntry;
  function GetVariable(varStr: string): PSymbolEntry;
  function GetProcedure(varProc: string): PSymbolEntry;



implementation
const
  MAX_SYMBOLS = 100;
  MAX_IDENTIFIER_CHARS = 1000;

var
  table: array[1..MAX_SYMBOLS] of TSymbolEntry;
  ids: array[1..MAX_IDENTIFIER_CHARS] of char;

  { some private helpers }



  function DeclareVariable(name: string; ty: PSymbolEntry): boolean;
  begin
  ;
  end;

  { public procedures for mutating symbol table }
  function DeclareVariable(name: string): boolean; begin end;
  function DeclareType(name: string): boolean; begin end;
  function EnterScope: boolean; begin end;
  function LeaveScope: boolean; begin end;

  { procedures for looking up symbol table }
  function GetType(tyStr: string): PSymbolEntry; begin end;
  function GetVariable(varStr: string): PSymbolEntry; begin end;
  function GetProcedure(varProc: string): PSymbolEntry; begin end;

end.
