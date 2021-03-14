unit Lexer;

interface

type
  TTokenType = (
    { Keywords }
    ArrayToken,     BeginToken,   ByToken,     CaseToken,   ConstToken,   DivToken,
    DoToken,        ElseToken,    ElsifToken,  EndToken,    FalseToken,
    ForToken,     ImportToken,
    IfToken,        IsToken,      InToken,   ModToken,    ModuleToken,   NilToken,
    OfToken,
    ProcedureToken, PointerToken, RecordToken, RepeatToken, ReturnToken,  ThenToken,
    ToToken,        TrueToken, TypeToken,    UntilToken,  VarToken,    WithToken,    WhileToken,

    { relational operators }
    EqualsToken, HashToken, LTToken, LTEToken, GTToken, GTEToken, {InToken, IsToken,}

    { binary operators }
    AndToken, PlusToken, DashToken, OrToken, StarToken {also ptr}, SlashToken,

    { selectors }
    LeftSquareToken, RightSquareToken, CaretToken, DotToken,

    { other syntactic elements }
    ColonToken, CommaToken, LeftBracketToken, RightBracketToken,
    SemicolonToken, PipeToken, AssignToken,  BetweenToken,
    LeftCurlyToken, RightCurlyToken, TildeToken,

    { lex result converted type }
    IdentifierToken, StringLiteralToken, IntegerToken, RealToken,

    { internal }
    NoneToken, EOFToken, BadToken
  );

  Location = record
    line: integer;
    from: integer;
    last: integer;
  end;

  Token = record
    location: Location;
    case tokenType: TTokenType of
      IdentifierToken:     (identifierString: string); {todo: str pointer?}
      IntegerToken:       (integerValue: integer);
      RealToken:          (realValue: real);
      StringLiteralToken: (literalString: string);
  end;

  KeywordToken = ArrayToken..WhileToken;


const
  KEYWORDS : packed array[KeywordToken] of string[9] = (
  'ARRAY', 'BEGIN', 'BY', 'CASE', 'CONST', 'DIV', 'DO', 'ELSE', 'ELSIF',
  'END', 'FALSE', 'FOR', 'IMPORT', 'IF', 'IS', 'IN', 'MOD', 'MODULE', 'NIL', 'OF',
  'POINTER', 'PROCEDURE', 'RECORD', 'REPEAT', 'RETURN', 'THEN', 'TO',
  'TRUE', 'TYPE', 'UNTIL', 'VAR', 'WITH', 'WHILE');

  EOF_CHAR = char(26);


  function hasNext: Boolean;
  function nextToken: TTokenType;


var
  currentLocation: Location;
  identifier: string;
  integerLiteral: integer;
  realLiteral: real;
  stringLiteral: string;

implementation

var
  currentPeekChar: char;
  hasNextFlag: Boolean;


function nextChar: char;
begin
  if currentPeekChar = Char(10) then
    begin
      Inc(currentLocation.line);
      currentLocation.from := 1;
      currentLocation.last := 1;
    end
  else
    Inc(currentLocation.last);

  nextChar := currentPeekChar;
  read(currentPeekChar);
end;

function peekChar: char;
begin
  peekChar := currentPeekChar;
end;




function resolveSymbol: TTokenType;

  procedure select(c1: char; tt1, tt2: TTokenType);
  begin;
    if c1 = peekChar then
      begin
        resolveSymbol := tt1;
        nextChar; {consume the second char that was peeked}
      end
    else
      resolveSymbol := tt2;
  end;


begin
  case nextChar of
  { Potentially two character tokens }
  '>': select('=', GTEToken,     GTToken);
  '<': select('=', LTEToken,     LTToken);
  '.': select('.', BetweenToken, DotToken);
  ':': select('=', AssignToken,  ColonToken);

  '+': resolvesymbol := PlusToken;
  ',': resolveSymbol := CommaToken;
  '(': resolveSymbol := LeftBracketToken;
  '*': resolveSymbol := StarToken;
  ')': resolveSymbol := RightBracketToken;
  ';': resolveSymbol := SemicolonToken;
  '-': resolveSymbol := DashToken;
  '=': resolveSymbol := EqualsToken;
  '|': resolveSymbol := PipeToken;
  '[': resolveSymbol := LeftSquareToken;
  ']': resolveSymbol := RightSquareToken;
  '#': resolveSymbol := HashToken;
  '^': resolveSymbol := CaretToken;
  '{': resolveSymbol := LeftCurlyToken;
  '}': resolveSymbol := RightCurlyToken;
  '&': resolveSymbol := AndToken;
  '/': resolveSymbol := SlashToken;
  '~': resolveSymbol := TildeToken;
  end;
end;


function processKeyword: TTokenType;
var
  i : TTokenType;
begin
  for i:= Low(KeywordToken) to High(KeywordToken) do
    if KEYWORDS[i] = identifier then
    begin
      processKeyword := i;
      exit;
    end;
  processKeyword := IdentifierToken;
end;



function processIdentifier: TTokenType;
var
  possibleKeyword: boolean;
begin
  possibleKeyword := True;
  identifier := '';

  while peekChar in ['a'..'z', 'A'..'Z', '0'..'9'] do
  begin
    if peekChar in ['a'..'z'] then possibleKeyword := False;
    identifier := identifier + nextChar;
    Inc(currentLocation.last);
  end;

  if possibleKeyword then
    processIdentifier := processKeyword
  else
    processIdentifier := IdentifierToken;
end;



function processNumber: TTokenType;
const
  BASE = 10; { TODO: change when we process hex digits }
var
  n: integer;
begin
  n := 0;
  while peekChar in ['0'..'9'] do
    n := (n * BASE) + (ord(nextChar) - ord('0'));

  integerLiteral := n;
  processNumber := IntegerToken;
end;


procedure skipWhiteSpace;
begin
  while peekChar in [' ', char(13), char(10)] do nextChar;
end;


function processStringLiteral: TTokenType;
begin
  stringLiteral := '';
  nextChar; { consume opening " }
  while peekChar <> '"' do
    stringLiteral := stringLiteral + nextChar;

  nextChar; { consume closing " }
  processStringLiteral := StringLiteralToken;
end;



function handleEOF: TTokenType;
begin
  nextChar;
  hasNextFlag := False;
  handleEOF := EOFToken;
end;



function nextToken: TTokenType;
begin
  skipWhiteSpace;
  if peekChar = '!' then
    while peekChar <> Char(10) do
      NextChar;

  currentLocation.from := currentLocation.last;

  case peekChar of
    'a'..'z', 'A'..'Z': nextToken := processIdentifier;
    '0'..'9':           nextToken := processNumber;
    '"':                nextToken := processStringLiteral;
    EOF_CHAR:           nextToken := handleEOF;
    else                nextToken := resolveSymbol;
  end;

  currentLocation.last := currentLocation.last -1;
  if (nextToken = NoneToken) then
    with currentLocation do
    begin
      writeln('LEX failure at ', line, ':', from);
      halt(1);
    end;
end;


function hasNext: Boolean;
begin
   hasNext := hasNextFlag;
end;


begin
  { prime the pump.. }
  hasNextFlag := True;
  nextChar;
  currentLocation.line := 1;
  currentLocation.from := 1;
  currentLocation.last := 1;
end.
