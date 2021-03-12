unit Lexer;

interface

type
	TTokenType = (
  	{ Keywords }
		ArrayToken,		BeginToken,	CaseToken,	ConstToken,		DivToken,	DoToken,
		ElseToken,		ElsifToken,	EndToken,		ImportToken,	IfToken,
		IsToken,			InToken,		ModToken,		ModuleToken,	OfToken,  ProcedureToken,
		PointerToken, RecordToken,RepeatToken,TypeToken,		VarToken,		WithToken,		WhileToken,

    { 2 character tokens }
    AssignToken,	BetweenToken,	LessThanEqualToken,	GreaterThanEqualToken,

    { 1 character tokens }
    PlusToken,					ColonToken,			CommaToken,		GreaterThanToken,
    LeftBracketToken, 	LessThanToken,  DashToken, 		MultiplyToken,
		RightBracketToken,	SemicolonToken,	DotToken,			MinusToken,
    EqualsToken,

    { others }
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
    	IdentifierToken: 		(identifierString: string); {todo: str pointer?}
      IntegerToken: 			(integerValue: integer);
      RealToken:					(realValue: real);
      StringLiteralToken: (literalString: string);
  end;

  KeywordToken = ArrayToken..WhileToken;


const
	KEYWORDS : packed array[KeywordToken] of string[9] = (
  'ARRAY', 'BEGIN', 'CASE', 'CONST', 'DIV', 'DO', 'ELSE', 'ELSIF',
	'END', 'IMPORT', 'IF', 'IS', 'IN', 'MOD', 'MODULE', 'OF',
	'POINTER', 'PROCEDURE', 'RECORD', 'REPEAT', 'TYPE', 'VAR', 'WITH', 'WHILE');

  EOF_CHAR = char(26);


  function hasNext: Boolean;
  function nextToken: TTokenType;


var
  currentLocation: Location;

implementation

var
	currentPeekChar: char;
  hasNextFlag: Boolean;
  t: Token;

function nextChar: char;
begin
  if currentPeekChar = Char(10) then
  	begin
  		Inc(currentLocation.line);
  		currentLocation.from := 1;
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


function resolveSymbol: TTokenType;
var tokenType: TTokenType;
begin
  t.location := currentLocation;

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
  '=': tokenType := EqualsToken;
  end;

  t.location.last := currentLocation.from;
  resolveSymbol := tokenType;
end;


function processKeyword: TTokenType;
var
	i : TTokenType;
begin
  for i:= Low(KeywordToken) to High(KeywordToken) do
  	if KEYWORDS[i] = t.identifierString then
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
  t.identifierString := '';

  while peekChar in ['a'..'z', 'A'..'Z', '0'..'9'] do
  begin
  	if peekChar in ['a'..'z'] then possibleKeyword := False;
		t.identifierString := t.identifierString + nextChar;
  end;

  if possibleKeyword then
    processIdentifier := processKeyword
  else
    processIdentifier := IdentifierToken;
end;



procedure processNumber;
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


procedure processStringLiteral;
begin
	t.literalString := '';
  t.tokenType := StringLiteralToken;

	nextChar; { consume opening " }
  while peekChar <> '"' do
  	t.literalString := t.literalString + nextChar;

  nextChar; { consume closing " }
end;



procedure handleEOF;
begin
	nextChar;
  t.tokenType := EOFToken;
  hasNextFlag := False;
end;



function nextToken: TTokenType;
begin
  skipWhiteSpace;
  t.location := currentLocation;
  t.tokenType := NoneToken;

  case peekChar of
  	'a'..'z', 'A'..'Z': nextToken := processIdentifier;
    '0'..'9': 					processNumber;
    '"':								processStringLiteral;
    EOF_CHAR:						handleEOF;
    else								nextToken := resolveSymbol;
  end;

  t.location.last := currentLocation.from -1;

  if (t.tokenType = NoneToken) then
  	with currentLocation do
    begin
  		writeln('LEX failure at ', line, ':', from);
     	halt(1);
    end;

  nextToken := t.tokenType;
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