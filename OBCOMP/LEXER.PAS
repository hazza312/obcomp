unit Lexer;

interface

type
	TTokenType = (
  	{ Keywords }
		ArrayToken,		BeginToken,	CaseToken,	ConstToken,		DivToken,	DoToken,
		ElseToken,		ElsifToken,	EndToken,		ImportToken,	IfToken,
		IsToken,			InToken,		ModToken,		ModuleToken,	OfToken,
		PointerToken, RecordToken,RepeatToken,TypeToken,		VarToken,		WithToken,		WhileToken,

    { 2 character tokens }
    AssignToken,	BetweenToken,	LessThanEqualToken,	GreaterThanEqualToken,

    { 1 character tokens }
    PlusToken,					ColonToken,			CommaToken,		GreaterThanToken,
    LeftBracketToken, 	LessThanToken,  DashToken, 		MultiplyToken,
		RightBracketToken,	SemicolonToken,	DotToken,			MinusToken,

    { others }
    IdentifierToken, StringLiteralToken, IntegerToken, RealToken,

    { internal }
		NoneToken, EOFToken
	);

  Location = record
  	line: integer;
    from: integer;
    last: integer;
  end;

  Token = record
  	location: Location;
  	case tokenType: TTokenType of
    	IdentifierToken: 		(identifierString: string); {todo: str pointer?}
      IntegerToken: 			(integerValue: integer);
      RealToken:					(realValue: real);
      StringLiteralToken: (literalString: string);
  end;

  KeywordToken = ArrayToken..WhileToken;


const
	KEYWORDS : packed array[KeywordToken] of string[7] = (
  'ARRAY', 'BEGIN', 'CASE', 'CONST', 'DIV', 'DO', 'ELSE', 'ELSIF',
	'END', 'IMPORT', 'IF', 'IS', 'IN', 'MOD', 'MODULE', 'OF',
	'POINTER', 'RECORD', 'REPEAT', 'TYPE', 'VAR', 'WITH', 'WHILE');

  EOF_CHAR = char(26);


  function hasNext: Boolean;
  procedure nextToken(var t: Token);




implementation

var
	currentLocation: Location;
	currentPeekChar: char;
  hasNextFlag: Boolean;


function nextChar: char;
begin
  if currentPeekChar = Char(10) then
  	begin
  		Inc(currentLocation.line);
  		currentLocation.from := 0;
		end
	else
  	Inc(currentLocation.from);

 	nextChar := currentPeekChar;
  read(currentPeekChar);
end;

function peekChar: char;
begin
	peekChar := currentPeekChar;
end;


function select(c1: char; tt1, tt2: TTokenType): TTokenType;
begin;
	if c1 = peekChar then
  	begin
			select := tt1;
			nextChar; {consume the second char that was peeked}
		end
	else
		select := tt2;
end;


procedure resolveSymbol(var t: Token);
begin
  t.location := currentLocation;

  with t do
  case nextChar of
  { Potentially two character tokens }
	'>': tokenType := select('=', GreaterThanEqualToken, GreaterThanToken);
	'<': tokenType := select('=', LessThanEqualToken,		 LessThanToken);
  '.': tokenType := select('.', BetweenToken, 				 DotToken);
  ':': tokenType := select('=', AssignToken,					 ColonToken);

	'+': tokenType := PlusToken;
  ':': tokenType := ColonToken;
  ',': tokenType := CommaToken;
  '(': tokenType := LeftBracketToken;
  '*': tokenType := MultiplyToken;
  ')': tokenType := RightBracketToken;
  ';': tokenType := SemicolonToken;
  '.': tokenType := DotToken;
  '-': tokenType := DashToken;
  end;

  t.location.last := currentLocation.from;
end;


procedure processKeyword(var t: Token);
var
	i : TTokenType;
begin
  for i:= Low(KeywordToken) to High(KeywordToken) do
  	if KEYWORDS[i] = t.identifierString then
    begin
    	t.tokenType := i;
      exit;
    end;
end;



procedure processIdentifier(var t: Token);
var
	possibleKeyword: boolean;
begin
	possibleKeyword := True;
	t.tokenType := IdentifierToken;
  t.identifierString := '';

  while peekChar in ['a'..'z', 'A'..'Z', '0'..'9'] do
  begin
  	if peekChar in ['a'..'z'] then possibleKeyword := False;
		t.identifierString := t.identifierString + nextChar;
  end;

  if possibleKeyword then processKeyword(t);
end;



procedure processNumber(var t: Token);
const
	BASE = 10; { TODO: change when we process hex digits }
var
  n: integer;
begin
  n := 0;
  t.tokenType := IntegerToken;

	while peekChar in ['0'..'9'] do
  	n := (n * BASE) + (ord(nextChar) - ord('0'));

  t.integerValue := n;
end;


procedure skipWhiteSpace;
begin
	while peekChar in [' ', char(13), char(10)] do nextChar;
end;


procedure processStringLiteral(var t: Token);
begin
	t.literalString := '';
  t.tokenType := StringLiteralToken;

	nextChar; { consume opening " }
  while peekChar <> '"' do
  	t.literalString := t.literalString + nextChar;

  nextChar; { consume closing " }
end;



procedure handleEOF(var t: Token);
begin
	nextChar;
  t.tokenType := EOFToken;
  hasNextFlag := False;
end;



procedure nextToken(var t: Token);
begin
  skipWhiteSpace;
  t.location := currentLocation;
  t.tokenType := NoneToken;

  case peekChar of
  	'a'..'z', 'A'..'Z': processIdentifier(t);
    '0'..'9': 					processNumber(t);
    '"':								processStringLiteral(t);
    EOF_CHAR:						handleEOF(t);
    else								resolveSymbol(t);
  end;

  t.location.last := currentLocation.from -1;

  if (t.tokenType = NoneToken) then
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
  currentLocation.from := 0;
end.