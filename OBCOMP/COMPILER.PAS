program Compiler;

uses 
  Lexer, SymbolTable, CGX86;

var
  peekToken: TTokenType;
  couldHaveAccepted: set of TTokenType;
  statements: boolean;
  identifier: string;


{ Internal Parser Functions ************************************************* }
function Next: TTokenType;
begin
  Next := peekToken;
  identifier := Lexer.identifier;
  peekToken := Lexer.nextToken;
end;


function Accept(tokenType: TTokenType): boolean;
begin
  Accept := peekToken = tokenType;
  if Accept then 
    begin
      couldHaveAccepted := [];
      Next
    end
  else
    couldHaveAccepted := couldHaveAccepted + [tokenType];
end;


procedure Expect(tokenType: TTokenType);
var
  possible:  TTokenType;

begin
  { adapt so we don't fail fast and try to do rest of file }

  if peekToken <> tokenType then
    begin
      with currentLocation do
      write(line, ':', from, '-', last, ' Parse error!');
      writeln(' got ', peekToken, ' but wanted one of: ');
      writeln('=> ', tokenType);
      for possible := Low(TTokenType) to High(TTokenType) do
        if possible in couldHaveAccepted then 
          writeln('=> ', possible);

      halt(1);
    end;
  Next;
end;



{ Begin Recursive Descent parse Procedures ********************************** }
procedure parseExpression; forward;                  { forward declarations }
function parseDesignator: PSymbolEntry; forward;
procedure parseActualParameters; forward;
function parseType: PSymbolEntry; forward;

{ RD Identifier Parsing ***************************************************** }
function parseQualident: PSymbolEntry;
begin
  repeat
    expect(IdentifierToken);
    parseQualident := SymbolTable.Find(identifier);
  until not accept(DotToken);
end;


procedure parseIdentList;
begin
  repeat
  expect(IdentifierToken); 
  accept(StarToken);
  until not accept(CommaToken);
end;


procedure parseFormalParameters;
  procedure parseFPSection;
  begin
    accept(VarToken);
    expect(IdentifierToken);
    while accept(CommaToken) do
      expect(IdentifierToken);

    expect(ColonToken);
    if accept(ArrayToken) then
      expect(OfToken);

    parseQualIdent;
  end;

begin
  if accept(LeftBracketToken) then
    if not accept(RightBracketToken) then
      begin
        repeat parseFPSection until not accept(SemiColonToken);    
        expect(RightBracketToken);
      end;

  if accept(ColonToken) then parseQualident;
end;


procedure parseSet;
begin
  { Leftcurly has been accepted }
  if not accept(RightCurlyToken) then
    begin
      repeat 
        parseExpression; { element }
        if accept(BetweenToken) then
          parseExpression
      until not accept(CommaToken);

      expect(RightCurlyToken);
    end;
end;


{ RD Expressions ************************************************************ }
procedure parseFactor;
var desig: PSymbolEntry;
begin
  { writeln('parse factor'); }
  if accept(NilToken) then
  else if accept(FalseToken) then
  else if accept(IntegerToken) then
    begin if statements then CGX86.DoConstant(Lexer.integerLiteral) end
        
  else if accept(StringLiteralToken) then
    
  else if accept(LeftCurlyToken) then
      parseSet
  else if accept(LeftBracketToken) then
    begin
      parseExpression;
      expect(RightBracketToken);
    end
  else if accept(TildeToken) then
    parseFactor
  else
    begin
      desig := parseDesignator;

      CGX86.VarUse(desig); { TODO if fun call }
      if accept(LeftBracketToken) then
        begin
          parseActualParameters;
          expect(RightBracketToken);
        end;
    end;
end;


procedure parseTerm;
const
  mulop = [StarToken, SlashToken, DivToken, ModToken, AndToken];
var
  lastOp: TTokenType;
begin
  parseFactor;
  while peekToken in mulop do
    begin
      lastOp := peekToken;      
      Next; { accept the mulop }
      parseFactor;
      { type check }
      case lastOp of
        StarToken:  CGX86.DoOperation(CGX86.Mul);
        SlashToken: CGX86.DoOperation(CGX86.Divide);        
      end;
    end;
end;


procedure parseSimpleExpression;
const
  plusOps = [PlusToken, DashToken, OrToken];
var 
  lastOp: TTokenType;

begin
  {negate := accept(DashToken); accept(PlusToken);}
  parseTerm;
  while peekToken in plusOps do
    begin
      lastOp := peekToken;
      Next; { consume }
      parseTerm;
      
      { type check }
      case lastOp of
        PlusToken: CGX86.DoOperation(CGX86.Add);
        DashToken: CGX86.DoOperation(CGX86.Sub);        
      end;
    end;
end;


procedure parseExpression;
const
  relop = [EqualsToken, HashToken, LTToken, LTEToken, GTToken, GTEToken, InToken, IsToken];
begin

  parseSimpleExpression;
  if peekToken in relop then 
  begin 
    Next;
    parseSimpleExpression;
  end;
end;

{ Declarations ************************************************************** }
procedure parseConstDeclaration;
begin
  expect(IdentifierToken);
  accept(StarToken);
  expect(EqualsToken);
  parseExpression;
end;


procedure parseArrayType;
begin
  { ARRAY accepted }
  repeat 
    parseExpression; { length }
  until not accept(CommaToken);

  expect(OfToken);
  parseType;
end;


procedure parseFieldListSequence;
begin
  repeat
    parseIdentList;
    expect(ColonToken);
    parseType;
  until not accept(SemicolonToken);
end;


{ RD Parse Types ************************************************************ }
procedure parseRecordType;
begin
  { RECORD accepted }
  if accept(LeftSquareToken) then
    begin
      parseQualIdent; { the base type }
      expect(RightSquareToken);
    end;

  if not accept(EndToken) then
    begin
      parseFieldListSequence;
      expect(EndToken);
    end;
end;


function parseType: PSymbolEntry;
begin
  if accept(ArrayToken) then
     parseArrayType
  else if accept(RecordToken) then
    begin
       SymbolTable.DeclareRecordType(identifier);
       parseRecordType
    end
  else if accept(PointerToken) then
     begin
         expect(ToToken);
         parseType := parseType;

     end
  else if accept(ProcedureToken) then
     begin
         if accept(LeftBracketToken) then
           parseFormalParameters
     end
  else if accept(IdentifierToken) then
    SymbolTable.DeclareType(identifier)
end;

procedure parseTypeDeclaration;
begin
  expect(IdentifierToken);
  if accept(StarToken) then
    ; { do something with the public* }

  expect(EqualsToken);
  parseType;
end;


procedure parseVarDeclaration;
var 
  start, last: TSymbolIndex;
  varType, lvar: PSymbolEntry;
begin
  start := SymbolTable.CurrentSymbolIndex;

  repeat
    expect(IdentifierToken); 
    accept(StarToken); { allowed in LVs?? }
    SymbolTable.DeclareVariable(identifier);
  until not accept(CommaToken);
  
  last := SymbolTable.CurrentSymbolIndex;
  expect(ColonToken);
  varType := parseType;
  
  for start := start to last do
  begin
    lvar := IToPSym(start); 
    SymbolTable.AssignType(lvar, varType);
    CGX86.AllocLocal(lvar);
  end;

end;

procedure parseStatementSequence; forward;

procedure parseProcedureHeading;
begin
  { expect(ProcedureToken, 'PROCEDURE expected'); accepted }
  expect(IdentifierToken);
  SymbolTable.DeclareProcedure(identifier);
  accept(StarToken);
  if peekToken in [ColonToken, LeftBracketToken] then
    parseFormalParameters

end;


procedure parseCaseLabelList;
  procedure parseLabel;
  begin
    if accept(IntegerToken) then

    else if accept(StringLiteralToken) then
      { do something with the string literal }
    else
      parseQualIdent;
  end;

begin
  repeat
    parseLabel;
    if accept(BetweenToken) then
      parseLabel;
  until not accept(CommaToken);
end;


{ RD Statement Parsing ******************************************************* }
procedure parseCase; { singular? }
begin
  parseCaseLabelList;
  expect(ColonToken);
  parseStatementSequence;
end;


procedure parseCaseStatement;
begin
  { CASE token accepted }
  parseExpression;
  expect(OfToken);
  repeat
    parseCase;
  until not accept(PipeToken);

  expect(EndToken);
end;


procedure parseIfStatement;
begin
  { IF token accepted }
  parseExpression;
  expect(ThenToken);
  parseStatementSequence;

  while accept(ElsifToken) do
    begin
      parseExpression;
      parseStatementSequence;
    end;

  if accept(ElseToken) then
    parseStatementSequence;

  expect(EndToken);
end;


procedure parseWhileStatement;
begin
  { WHILE accepted }
  parseExpression;
  expect(DoToken);

  parseStatementSequence;
  while accept(ElsifToken) do
    begin
      parseExpression;
      expect(DoToken);
      parseStatementSequence;
    end;
  expect(EndToken);
end;


procedure parseRepeatStatement;
begin
  { REPEAT accepted }
  parseStatementSequence;
  expect(UntilToken);
  parseExpression;
end;


procedure parseForStatement;
begin
  { FOR token accepted }
  expect(AssignToken);
  parseExpression;
  expect(ToToken);

  if accept(ByToken) then
    parseExpression;

  expect(DoToken);
  parseStatementSequence;
  expect(EndToken);
end;



function parseDesignator: PSymbolEntry;
const
  selectorStarts = [DotToken, LeftSquareToken, CaretToken, LeftBracketToken];

begin
  parseDesignator := parseQualident;
  while peekToken in selectorStarts do
  begin
    if accept(DotToken) then
      expect(IdentifierToken)
    else if accept(LeftSquareToken) then
      begin
          repeat
            parseExpression; { check type }
          until not accept(CommaToken);
        expect(RightSquareToken);
      end
      
    else if accept(CaretToken) then

    { This is the problematc one -- typeguard to distinguish func call from selector? }
    else if accept(LeftBracketToken) then
     begin
        parseQualident;
        expect(RightBracketToken);
      end
  end;
end;

procedure parseActualParameters;
begin
  { ( accepted }
  if not accept(RightBracketToken) then
      repeat
        parseExpression;
      until not accept(CommaToken);
end;

procedure parseAssignmentOrCall;
var 
  store: PSymbolEntry;
begin
  store := parseDesignator;
  if store = nil then 
    writeln('nl!');
  
  if accept(AssignToken) then
    begin
      parseExpression;
      CGX86.DoAssign(store)
    end
  else if accept(LeftBracketToken) then
    begin
      parseActualParameters;
      expect(RightBracketToken);
    end;
end;

procedure parseStatementSequence;
begin
  statements := true;
  repeat 
    if accept(IfToken) then
      parseIfStatement
    else if accept(CaseToken) then
      parseCaseStatement
    else if accept(WhileToken) then
      parseWhileStatement
    else if accept(RepeatToken) then
      parseRepeatStatement
    else if accept(ForToken) then
      parseForStatement
    else if accept(ReturnToken) then
      begin
        parseExpression;
        break;        
      end
    else
      parseAssignmentOrCall

  until not accept(SemicolonToken);
  statements := false;
end;

procedure parseProcedureDeclaration; forward;

procedure ParseDeclarationSequence;
const
  moveOn = [ConstToken, TypeToken, VarToken, BeginToken, ProcedureToken];

begin
  while peekToken in [ConstToken, TypeToken, VarToken, ProcedureToken] do
    begin
      if accept(ConstToken) then
        repeat parseConstDeclaration; expect(SemiColonToken) until peekToken in MoveOn

      else if accept(TypeToken) then
        repeat parseTypeDeclaration; expect(SemiColonToken) until peekToken in MoveOn

      else if accept(VarToken) then
      repeat parseVarDeclaration; expect(SemiColonToken) until peekToken in MoveOn

      else if accept(ProcedureToken) then
      repeat parseProcedureDeclaration; expect(SemiColonToken) until peekToken in MoveOn
    end;
end;


procedure parseProcedureBody;
begin
  SymbolTable.EnterScope;
  CGX86.BeginFunction;
  parseDeclarationSequence;
  if accept(BeginToken) then
    parseStatementSequence;

  expect(EndToken);
  expect(IdentifierToken);
  SymbolTable.ExitScope;
  EndFunction;
end;


procedure parseProcedureDeclaration;
begin
  parseProcedureHeading;
  expect(SemicolonToken);
  parseProcedureBody;
end;


procedure ParseModule;
begin
  expect(ModuleToken);      
  expect(IdentifierToken);    
  SymbolTable.DeclareModule(identifier);
  expect(SemicolonToken);
  if accept(ImportToken) then
    begin
      expect(IdentifierToken);
      while accept(CommaToken) do
        begin
          expect(IdentifierToken);
          if accept(AssignToken) then
            expect(IdentifierToken);
      end;

      expect(SemiColonToken);
    end;

  ParseDeclarationSequence;
  if accept(BeginToken) then
  begin
    SymbolTable.DeclareProcedure('_start');
    CGX86.BeginFunction;
    parseStatementSequence;
    CGX86.EndFunction;

  end;
  expect(EndToken); expect(IdentifierToken); expect(DotToken);
end;


begin
  Next; { prime pump }
  ParseModule;
end.
