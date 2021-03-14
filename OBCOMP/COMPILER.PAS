program Compiler;

uses Lexer, Debug;

var
  peekToken: TTokenType;


{ Internal Parser Functions ************************************************* }

function Next: TTokenType;
begin
  Next := peekToken;
  peekToken := Lexer.nextToken;
end;

procedure Error(msg: string);
begin
  with currentLocation do
  writeln(line, ':', from, '-', last, ' - Parse error ' + msg);
  halt(1);
end;


function Accept(tokenType: TTokenType): boolean;
begin
  Accept := peekToken = tokenType;
  if Accept then Next;
end;


procedure Expect(tokenType: TTokenType; msg: string);
begin
  { adapt so we don't fail fast and try to do rest of file }

  if peekToken <> tokenType then
    error(msg);

  Next;
end;



{ Begin Recursive Descent parse Procedures ********************************** }
procedure parseExpression; forward;                    { forward declarations }
procedure parseDesignator; forward;
procedure parseActualParameters; forward;
procedure parseType; forward;

{ RD Identifier Parsing ***************************************************** }

procedure parseIdentifier;
begin
  { writeln(Lexer.t.identifierString); }
  { expect(IdentifierToken, 'Identifier Expected'); }
end;

procedure parseQualident;
begin
  repeat
    expect(IdentifierToken, 'identifier expected');
    parseIdentifier;
  until not accept(DotToken);
end;

procedure parseIdentList;
begin
  expect(IdentifierToken, 'Identifier expected');
  while accept(CommaToken) do
    expect(IdentifierToken, 'Identifier expected following comma in identlist');
end;

procedure parseFormalType;
begin
  if accept(ArrayToken) then
    expect(OfToken, 'ARRAY without OF in formal parameter');

  parseQualIdent;
end;

procedure parseFPSection;
begin
  if accept(VarToken) then
    ;

  expect(IdentifierToken, 'Identifier expected');
  while accept(CommaToken) do
    expect(IdentifierToken, 'Identifier expected');

  expect(ColonToken, 'Colon token expected');
  parseFormalType;
end;

procedure parseFormalParameters;
begin
  { left brack accepted }
  if not accept(RightBracketToken) then
    begin
      repeat
        parseFPSection;
      until not accept(SemiColonToken);

      expect(RightBracketToken, ') expected');
  end;

  if accept(ColonToken) then
    parseQualident
end;

procedure ParseImport;
begin
  expect(IdentifierToken, 'Identifier expected as import');
  if accept(AssignToken) then
    expect(IdentifierToken, 'Identifier expected following import assign');
end;

procedure ParseImportList;
begin
  { IMPORT keyword has been accepted }
  expect(IdentifierToken, 'Identifier expected as import');
  while accept(CommaToken) do
    ParseImport;

  expect(SemiColonToken, 'Semicolon expected to conclude Import list');
end;

procedure parseElement;
begin
  parseExpression;
  if accept(BetweenToken) then
    parseExpression
end;

procedure parseSet;
begin
  { Leftcurly has been accepted }
  if not accept(RightCurlyToken) then
    begin
      parseElement;
      while accept(CommaToken) do
        parseElement;

      expect(RightCurlyToken, 'set terminator expected');
    end;
end;

{ RD Expressions ************************************************************ }

procedure parseFactor;
begin
  { writeln('parse factor'); }
  if accept(NilToken) then
  else if accept(FalseToken) then
  else if accept(IntegerToken) then
  else if accept(StringLiteralToken) then
    begin
      parseIdentifier;  { hack for now }
      expect(StringLiteralToken, 'closing " required');
    end
  else if accept(LeftCurlyToken) then
      parseSet
  else if accept(LeftBracketToken) then
    begin
      parseExpression;
      expect(RightBracketToken, ') expected to close expression');
    end
  else if accept(TildeToken) then
    parseFactor
  else
    begin
      parseDesignator;
      if accept(LeftBracketToken) then
        begin
          parseActualParameters;
          expect(RightBracketToken, ') expected to close AP');
        end;
    end;
end;

procedure parseTerm;
const
  mulop = [StarToken, SlashToken, DivToken, ModToken, AndToken];
begin
  parseFactor;
  while peekToken in mulop do
    parseFactor
end;

procedure parseConstExpression;
begin
  parseExpression;
end;

procedure parseSimpleExpression;
const
  plusOps = [PlusToken, DashToken, OrToken];
var
  negate: boolean;
  n: integer;
begin
  { }
  negate := accept(DashToken); accept(PlusToken);
  parseTerm;
  while peekToken in plusOps do
    { do something specific with the token }
    parseTerm;
end;

procedure parseExpression;
const
  relop = [EqualsToken, HashToken, LTToken, LTEToken, GTToken, GTEToken, InToken, IsToken];
begin
  parseSimpleExpression;
  if peekToken in relop then parseSimpleExpression;
end;

{ Declarations ************************************************************** }

procedure parseConstDeclaration;
begin
  expect(IdentifierToken, 'Identifier expected on LHS const decl');
  { do something with the identifier }
  if accept(StarToken) then
    { do something with the public* };

  expect(EqualsToken, 'Expected = in const declar');
  parseExpression;
  { do something with the (Const)expression }
end;

procedure parseArrayType;
begin
  { ARRAY accepted }
  parseConstExpression; { length }
  while accept(CommaToken) do
    parseConstExpression;

  expect(OfToken, 'OF expected');
  parseType;
end;

procedure parseFieldList;
begin
  parseIdentList;
  expect(ColonToken, ': expected');
  parseType;
end;

procedure parseFieldListSequence;
begin
  parseFieldList;
  while accept(SemicolonToken) do
    parseFieldList;
end;

{ RD Parse Types ************************************************************ }

procedure parseRecordType;
begin
  { RECORD accepted }
  if accept(LeftSquareToken) then
    begin
      parseQualIdent;
      expect(RightSquareToken, '] expected to close record base type');
    end;

  if not accept(EndToken) then
    begin
      parseFieldListSequence;
      expect(EndToken, 'END token expected at end of record');
    end;
end;

procedure parsePointerType;
begin
  { POINTER accepted }
  expect(ToToken, 'TO expected after POINTER');
  parseType;
end;

procedure parseProcedureType;
begin
  { PROCEDURE accepted }
  if accept(LeftBracketToken) then
    parseFormalParameters;
end;

procedure parseType;
begin
  if accept(ArrayToken) then
     parseArrayType { it is an array }
  else if accept(RecordToken) then
     parseRecordType { it is a record }
  else if accept(PointerToken) then
     parsePointerType { it is a pointer }
  else if accept(ProcedureToken) then
     parseProcedureType { it is a procedure }
  else if accept(IdentifierToken) then
     parseIdentifier { it is a (qual)ident }
  else
    { it's not a proper type }
    error('Bad type declaration, expected ARRAY|RECORD|POINTER|PROCEDURE|QUALIDENT');
    ;
end;

procedure parseTypeDeclaration;
begin
  expect(IdentifierToken, 'Identifier expected on LHS type decl');
  { do something with the identifier }
  if accept(StarToken) then
    ; { do something with the public* }

  expect(EqualsToken, '= expected in type declaration');
  parseType;
end;

procedure parseVarDeclaration;
begin
  ParseIdentList;
  expect(ColonToken, 'Colon expected after identlist');
  parseType;
end;

procedure parseStatementSequence; forward;

procedure parseProcedureHeading;
begin
  expect(ProcedureToken, 'PROCEDURE expected');
  expect(IdentifierToken, 'Identifier expected');
  if accept(LeftBracketToken) then
    parseFormalParameters;
end;


procedure parseLabel;
begin
  if accept(IntegerToken) then

  else if accept(StringLiteralToken) then
    { do something with the string literal }
  else
    parseQualIdent;

end;


procedure parseLabelRange;
begin
  parseLabel;
  if accept(BetweenToken) then
    parseLabel;
end;


procedure parseCaseLabelList;
begin
  repeat
    parseLabelRange;
  until not accept(CommaToken);
end;

{ RD Statement Parsing ******************************************************* }


procedure parseCase; { singular? }
begin
  parseCaseLabelList;
  expect(ColonToken, ': expected');
  parseStatementSequence;
end;


procedure parseCaseStatement;
begin
  { CASE token accepted }
  parseExpression;
  expect(OfToken, 'OF expected in CASE');
  repeat
    parseCase;
  until not accept(PipeToken);

  expect(EndToken, 'END expected concluding CASE');
end;


procedure parseIfStatement;
begin
  { IF token accepted }
  parseExpression;
  expect(ThenToken, 'THEN expected');
  parseStatementSequence;

  while accept(ElsifToken) do
    begin
      parseExpression;
      parseStatementSequence;
    end;

  if accept(ElseToken) then
    parseStatementSequence;

  expect(EndToken, 'END expeted in IF statement');
end;

procedure parseWhileStatement;
begin
  { WHILE accepted }
  parseExpression;
  expect(DoToken, 'DO expected');

  parseStatementSequence;
  while accept(ElsifToken) do
    begin
      parseExpression;
      expect(DoToken, 'DO expected');
      parseStatementSequence;
    end;
  expect(EndToken, 'END expected after WHILE');
end;

procedure parseRepeatStatement;
begin
  { REPEAT accepted }
  parseStatementSequence;
  expect(UntilToken, 'UNTIL expected after REPEAT');
  parseExpression;
end;

procedure parseForStatement;
begin
  { FOR token accepted }
  parseIdentifier;
  expect(AssignToken, 'Assignment expected in FOR header');
  parseExpression;
  expect(ToToken, 'TO expected in FOR header');

  if accept(ByToken) then
    parseExpression;

  expect(DoToken, 'DO token expected');
  parseStatementSequence;
  expect(EndToken, 'END token expected');
end;

procedure parseExpressionList;
begin
  repeat
    parseExpression;
  until not accept(CommaToken);
end;

procedure parseDesignator;
const
  selectorStarts = [DotToken, LeftSquareToken, CaretToken, LeftBracketToken];

begin
  parseQualident;
  while peekToken in selectorStarts do
  begin
    if accept(DotToken) then
      parseIdentifier
    else if accept(LeftSquareToken) then
      begin
        parseExpressionList;
        expect(RightSquareToken, 'Closing ] expected');
      end
    else if accept(CaretToken) then

    { This is the problematc one -- typeguard to distinguish func call from selector? }
    else if accept(LeftBracketToken) then
     begin
        parseQualident;
        expect(RightBracketToken, ') expected');
      end
  end;
end;

procedure parseActualParameters;
begin
  { ( accepted }
  if not accept(RightBracketToken) then
    parseExpressionList

end;

procedure parseAssignmentOrCall;
begin
  parseDesignator;
  if accept(AssignToken) then
    begin
      parseExpression
    end
  else if accept(LeftBracketToken) then
    begin
      parseActualParameters;
      expect(RightBracketToken, ') expected');
    end;
end;

procedure parseStatement;
begin
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
  else
    parseAssignmentOrCall;
end;

procedure parseStatementSequence;
begin
  repeat
    parseStatement;
    { do something with the statement }
  until not accept(SemicolonToken);
end;

{ some forward references }
procedure parseDeclarationSequence; forward;

procedure parseProcedureBody;
begin
  parseDeclarationSequence;
  if accept(BeginToken) then
    parseStatementSequence;

  if accept(ReturnToken) then
    parseExpression;

  expect(EndToken, 'END expected');
end;

procedure parseProcedureDeclaration;
begin
  parseProcedureHeading;
  { do something with the procedure heading }
  expect(SemicolonToken, 'Semicolon expected after procedure heading');
  parseProcedureBody;
end;

procedure ParseDeclarationSequence;
const
  moveOn = [ConstToken, TypeToken, VarToken, BeginToken];

begin
  while peekToken in [ConstToken, TypeToken, VarToken] do
    begin
      if accept(ConstToken) then
        repeat parseConstDeclaration; expect(SemiColonToken, '; sep expected') until peekToken in MoveOn

      else if accept(TypeToken) then
        repeat parseTypeDeclaration; expect(SemiColonToken, '; sep expected') until peekToken in MoveOn

      else if accept(VarToken) then
      repeat parseVarDeclaration; expect(SemiColonToken, '; sep expected') until peekToken in MoveOn
    end;
end;

procedure ParseModule;
begin
  expect(ModuleToken, 'MODULE expected to begin file');
  expect(IdentifierToken, 'Identifier expected after module');
  expect(SemicolonToken, 'Semicolon expected');
  if accept(ImportToken) then
    ParseImportList;

  ParseDeclarationSequence;
  if accept(BeginToken) then
    parseStatementSequence;

  expect(EndToken, 'END expected closing module');
  expect(IdentifierToken, 'Identifier expected closing module');
  expect(DotToken, 'Dot required to close module');
end;


var
  i: integer;
begin
  Next; { prime pump }
  ParseModule;
end.
