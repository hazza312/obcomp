program Compiler;
	uses Lexer, Debug;


procedure error(msg: string);
begin
  writeln(currentLocation.line, ':', currentLocation.from,
          currentLocation.last, + ' : Parse error ' + msg);
  readln; readln;
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

procedure parseExpression; begin ; end;


procedure parseConstDeclaration;
begin
  expect(IdentifierToken, 'Identifier expected on LHS const decl');
  { do something with the identifier }
  if accept(MultiplyToken) then
    { do something with the public* };

  expect(AssignToken, 'Expected an assignment operator in const declar');
  parseExpression;
  { do something with the (Const)expression }
end;


procedure parseType;
begin
  if accept(ArrayToken) then
     { it is an array }
  else if accept(RecordToken) then
     { it is a record }
  else if accept(PointerToken) then
     { it is a pointer }
  else if accept(ProcedureToken) then
     { it is a procedure }
  else if accept(IdentifierToken) then
     { it is a (qual)ident }
  else
    { it's not a proper type }
    error('Bad type declaration, expected ARRAY|RECORD|POINTER|PROCEDURE|QUALIDENT');
    ;
end;



procedure parseTypeDeclaration;
begin
  expect(IdentifierToken, 'Identifier expected on LHS type decl');
  { do something with the identifier }
  if accept(MultiplyToken) then
    ; { do something with the public* }

  expect(AssignToken, 'Assign token expected in type declaration');
  parseType;
end;


procedure parseIdentList;
begin
  repeat
    expect(IdentifierToken, 'Identifier expected');
    { do something with the identifier }

  until not accept(ColonToken);
end;



procedure parseVarDeclaration;
begin
  ParseIdentList;
  { do something with the identifier list }
  expect(ColonToken, 'Colon expected after identlist');
  parseType;
  { do something with the type }
end;


procedure parseFormalParameters;
begin

end;


procedure parseProcedureHeading;
begin
  expect(ProcedureToken, 'PROCEDURE expected');
  expect(IdentifierToken, 'Identifier expected');
  { do something with the identifier }

  parseFormalParameters;
end;


procedure parseProcedureBody;
begin
;
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


begin
  writeln(ord(IsToken));
  ParseModule;
  readln;
end.
