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


  TSymbolEntry = record
    id:     ^string;       { ptr to the string identifier }
    scope:  ^TSymbolEntry; { ptr to enclosing scope }
    loc:    Location;      { of first declaration }
    addr:   integer;       { not used in case of type? }

    case symType: TSymbolType of
      SVariable:  (varType:   ^TSymbolEntry);
      SArrayType: (arrayType: ^TSymbolEntry;
                   size:       integer);
      SConstant:  (constVal:   integer); { TODO: what is a constant? }
  end;


implementation


end.
