program Compiler;

uses Lexer, Debug;

{ Internal Parser Functions ************************************************* }

procedure error(msg: string);
begin
  with currentLocation do
  writeln(line, ':', from, '-', last, ' - Parse error ' + msg);
  halt(1);
end;

procedure expect(tokenType: TTokenType; msg: string);
var
  tt: TTokenType;
begin
  tt := nextToken;
  if tt <> tokenType then begin error(msg) end;
end;

function accept(tokenType: TTokenType): boolean;
begin
  accept := nextToken = tokenType;
  { TODO don't consume the token if unaccepted }
end;


{ Begin Recursive Descent parse Procedures ********************************** }
procedure parseExpression; forward;                    { forward declarations }
procedure parseDesignator; forward;
procedure parseActualParameters; forward;
procedure parseType; forward;

procedure parseIdentifier;
begin
  expect(IdentifierToken, 'Identifier Expected');
end;

procedure parseQualident;
begin
  repeat
    parseIdentifier;
  until not accept(DotToken);
end;

procedure parseIdentList;
begin
  repeat
    expect(IdentifierToken, 'Identifier expected');
    { do something with the identifier }

  until not accept(ColonToken);
end;

procedure parseFormalType;
begin
  if accept(ArrayToken) then
    begin
      expect(OfToken, 'ARRAY without OF in formal parameter');
      { do something to note open array }
    end;

    parseQualIdent;
end;

procedure parseFPSection;
begin
  if accept(VarToken) then
  ; { note that it is var }

  expect(IdentifierToken, 'Identifier expected');
  { do something with the identifier }
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
      { we must have at least one FPSection }
      parseFPSection;
      while accept(SemiColonToken) do
        parseFPSection;

      expect(RightBracketToken, ') expected');
  end;

  if accept(ColonToken) then
    parseQualident;
end;

procedure ParseImport;
begin
  expect(IdentifierToken, 'Identifier expected as import');
  { do something with the identifier }
  if accept(AssignToken) then
  begin
    expect(IdentifierToken, 'Identifier expected following import assign');
    { do something with the identifier }
  end;
end;

procedure ParseImportList;
begin
  { IMPORT keyword has been accepted }
  expect(IdentifierToken, 'Identifier expected as import');
  { do something with the identifier }
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
    repeat
      parseElement
    until not accept(CommaToken);
end;

procedure parseFactor;
begin
  if accept(NilToken) then
  else if accept(FalseToken) then
  else if accept(IntegerToken) then
  else if accept(StringLiteralToken) then
  else if accept(LeftCurlyToken) then
    begin
      parseSet;
      expect(RightCurlyToken, '} expected to close set');
    end
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
begin
  parseFactor;
  while true do
    begin
      if accept(StarToken) then
      else if accept(SlashToken) then
      else if accept(DivToken) then
      else if accept(ModToken) then
      else if accept(AndToken) then
      else exit;
      parseFactor ;
  end;
end;

procedure parseConstExpression;
begin
  parseExpression;
end;

procedure parseSimpleExpression;
begin
  if accept(PlusToken) then
  else if accept(DashToken) then
  ;

  parseTerm;
  while true do
    begin
      if accept(PlusToken) then
      else if accept(DashToken) then
      else if accept(OrToken) then
      else break;

    end;
end;

procedure parseExpression;
begin
  parseSimpleExpression;
  if       accept(EqualsToken) then
  else if  accept(HashToken)  then
  else if accept(LTToken) then
  else if accept(LTEToken) then
  else if accept(GTToken) then
  else if accept(GTEToken) then
  else if accept(InToken) then
  else if accept(IsToken) then

end;

procedure parseConstDeclaration;
begin
  expect(IdentifierToken, 'Identifier expected on LHS const decl');
  { do something with the identifier }
  if accept(StarToken) then
    { do something with the public* };

  expect(AssignToken, 'Expected an assignment operator in const declar');
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

  expect(AssignToken, 'Assign token expected in type declaration');
  parseType;
end;

procedure parseVarDeclaration;
begin
  ParseIdentList;
  { do something with the identifier list }
  expect(ColonToken, 'Colon expected after identlist');
  parseType;
  { do something with the type }
end;

procedure parseStatementSequence; forward;

procedure parseProcedureHeading;
begin
  expect(ProcedureToken, 'PROCEDURE expected');
  expect(IdentifierToken, 'Identifier expected');
  { do something with the identifier }

  if accept(LeftBracketToken) then
    parseFormalParameters;
end;


procedure parseLabel;
begin
  if accept(IntegerToken) then
    { do something with the integer }
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
begin
  parseQualident;
  if accept(DotToken) then
    parseIdentifier
  else if accept(LeftSquareToken) then
    begin
      parseExpressionList;
      expect(RightSquareToken, 'Closing ] expected');
    end
  else if accept(CaretToken) then

  else if accept(LeftBracketToken) then
    begin
      parseDesignator;
      expect(RightBracketToken, ') expected');
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
    parseExpression
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
begin
  if accept(ConstToken) then
    begin
      parseConstDeclaration;
      expect(SemiColonToken, 'Semicolon expected to conclude const decl seq');
    end

  else if accept(TypeToken) then
    begin
      parseTypeDeclaration;
      expect(SemiColonToken, 'Semicolon expected to conclude type decl seq');
    end

  else if accept(VarToken) then
    begin
      parseVarDeclaration;
      expect(SemiColonToken, 'Semicolon expected to conclude bar decl seq');
    end

end;

procedure ParseModule;
begin
  expect(ModuleToken, 'MODULE expected to begin file');
  expect(IdentifierToken, 'Identifier expected after module');
  { do something with the identifier }
  expect(SemicolonToken, 'Semicolon expected');
  if accept(ImportToken) then
    ParseImportList;

  ParseDeclarationSequence;

  readln;
end;


var
  i: integer;
begin
  ParseModule;
end.
