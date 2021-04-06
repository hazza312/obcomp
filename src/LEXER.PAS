unit Lexer;
{ 
    Lexer for the Oberon Language.

    function nextToken: TTokenType will return the next TTokenType in the input stream,
    until the end of the input stream.

    This will be the keyword or symbol itself. For identifiers and literals, the Lexer
    will return the type (IdentifierToken, IntegerToken etc). This indicates that the 
    valid lex result for that type can be read from the lex result variables.

    Newlines and comments and handled transparently to calling unit. Comments can
    be nested.
}

interface { ******************************************************************** }

uses 
    Common;

type
    { The different types of tokens the Lexer can identify }
    TTokenType = (
        { Keywords }
        ArrayToken,  BeginToken, ByToken,      CaseToken,      ConstToken,   DivToken,
        DoToken,     ElseToken,  ElsifToken,   EndToken,       FalseToken,   ForToken,
        ImportToken, IfToken,    IsToken,      InToken,        ModToken,     ModuleToken,  
        NilToken,    OfToken,    PointerToken, ProcedureToken, RecordToken,  RepeatToken, 
        ReturnToken, ThenToken,  ToToken,      TrueToken,      TypeToken,    UntilToken,  
        VarToken,    WithToken,  WhileToken,

        { relational operators }
        EqualsToken, HashToken, LTToken, LTEToken, GTToken, GTEToken, {InToken, IsToken,}

        { binary operators }
        AndToken, PlusToken, DashToken, OrToken, StarToken {also ptr}, SlashToken,

        { selectors }
        LeftSquareToken, RightSquareToken, CaretToken, DotToken,

        { other syntactic elements }
        ColonToken,         CommaToken,         LeftBracketToken,   RightBracketToken,
        SemicolonToken,     PipeToken,          AssignToken,        BetweenToken,
        LeftCurlyToken,     RightCurlyToken,    TildeToken,
        StartCommentToken,  EndCommentToken,

        { lex result converted type }
        IdentifierToken,    StringLiteralToken, IntegerToken,   RealToken,

        { internal }
        NoneToken, EOFToken, BadToken
    );

    KeywordToken = ArrayToken..WhileToken;


    { retrieves the nextToken from the input stream }
    function nextToken: TTokenType;


var
    currentLocation: Location;

    { lex results for different types stored here }
    { TODO: make these private/function wrappers for these }
    integerLiteral: integer;
    realLiteral: real;
    stringLiteral: string;
    identifier: string;



implementation { ************************************************************* }


const
    KEYWORDS : packed array[KeywordToken] of string[9] = (
        'ARRAY',  'BEGIN',    'BY',       'CASE',         'CONST',    'DIV', 
        'DO',     'ELSE',     'ELSIF',    'END',          'FALSE',    'FOR', 
        'IMPORT', 'IF',       'IS',       'IN',           'MOD',      'MODULE', 
        'NIL',    'OF',       'POINTER',  'PROCEDURE',    'RECORD',   'REPEAT', 
        'RETURN', 'THEN',     'TO',       'TRUE',         'TYPE',     'UNTIL', 
        'VAR',    'WITH',     'WHILE'
    );

    EOF_CHAR = char(26);
    NEWLINE_CHAR = char(10);


var
    peekChar: char;


{ Advance a single character, mindful of newlines and updating location.
    @private
    @post       character is always consumed
    @global     currentLocation, peekChar }
function nextChar: char;
begin
    if peekChar = NEWLINE_CHAR then
        begin
            Inc(currentLocation.line);
            currentLocation.from := 1;
            currentLocation.last := 1;
        end
    else
        Inc(currentLocation.last);

    nextChar := peekChar;
    read(peekChar);
end;


{ Resolve a 1 or 2 character character symbol sequence to its TokenType.
  Comment tokens are handled slightly differently. See NextToken.  
    @private
    @pre        token is either a symbol token, or invalid
    @post       one or two characters are always consumed }
function resolveSymbol: TTokenType;

    { Select tt1 and consume peekChar if peekChar is c1, else tt2 }
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


begin
    case nextChar of
    { Potentially two character tokens }
    '>': resolveSymbol := select('=', GTEToken,            GTToken);
    '<': resolveSymbol := select('=', LTEToken,            LTToken);
    '.': resolveSymbol := select('.', BetweenToken,        DotToken);
    ':': resolveSymbol := select('=', AssignToken,         ColonToken);
    '(': resolveSymbol := select('*', StartCommentToken,   LeftBracketToken);
    '*': resolveSymbol := select(')', EndCommentToken,     StarToken);

    { single character tokens }
    '+': resolveSymbol := PlusToken;
    ',': resolveSymbol := CommaToken;
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

    { we tried }
    otherwise resolveSymbol := BadToken;
    end;
end;


{ Having lexed an identifier, check if it is a keyword. Else, it's an identifier.
    @private
    @pre        identifier contains potential keyword }
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


{ Process an identifier. Then check to see if it was a keyword.
    @private
    @pre        peekChar is a valid identifier/keyword begin character 
    @post       identifier contains the lexed identifier/keyword,
                consumes at least one character
    @global     identifier }
function processIdentifier: TTokenType;
var
    possibleKeyword: boolean;
begin
    possibleKeyword := True;
    identifier := '';

    while peekChar in ['a'..'z', 'A'..'Z', '0'..'9'] do
        begin
            if peekChar in ['a'..'z'] then possibleKeyword := False; {keywords all upper}
            identifier  := identifier  + nextChar;
        end;

    if possibleKeyword then
        processIdentifier := processKeyword
    else
        processIdentifier := IdentifierToken;
end;


{ Process and convert a numeric literal. 
    @private
    @pre        peekChar is a valid numeric literal begin character
    @post       integerLiteral contains the lexed literal
    @global     integerLiteral
    TODO: reals, different bases }
function processNumber: TTokenType;
const
    BASE = 10;
var
    n: integer;
begin
    n := 0;
    while peekChar in ['0'..'9'] do
        n := (n * BASE) + (ord(nextChar) - ord('0'));

    integerLiteral := n;
    processNumber := IntegerToken;
end;


{ Process and convert a string literal. 
    @private
    @pre        peekChar is the " character
    @post       processStringLiteral contains the lexed literal
    @global     processStringLiteral }
function processStringLiteral: TTokenType;
begin
    stringLiteral := '';
    nextChar; { consume opening " }
    while peekChar <> '"' do
        stringLiteral := stringLiteral + nextChar;

    nextChar; { consume closing " }
    processStringLiteral := StringLiteralToken;
end;


{ Skip anything in the stream until end comment.
    @private
    @pre        StartCommentToken was last token
    @post       consumes multiple characters 
    @error      when unmatched
}
procedure processComment;
var
    p1: char;
    commentDepth: integer;
begin
    commentDepth := 1;
    while commentDepth > 0 do                
        begin
            p1 := nextChar;
            if peekChar = EOF_CHAR then
                Error('Lex', currentLocation, 'Unmatched comment open')

            else if (p1 = '(') and (peekChar = '*') then
                Inc(commentDepth)

            else if (p1 = '*') and (peekChar = ')') then
                Dec(commentDepth);

        end;

    nextChar;
end;




function nextToken: TTokenType;
var
    commentDepth: integer;
    p1: char;

begin
    { skip whitespace }
    while peekChar in [' ', char(13), char(10)] do nextChar;

    currentLocation.from := currentLocation.last;
    case peekChar of
        'a'..'z', 'A'..'Z': nextToken := processIdentifier;
        '0'..'9':           nextToken := processNumber;
        '"':                nextToken := processStringLiteral;
        EOF_CHAR:           nextToken := EOFToken;
        else                nextToken := resolveSymbol;
    end;

    Dec(currentLocation.last);
    if (nextToken = NoneToken) then
        Error('Lex', currentLocation, 'Could not lex symbol')

    else if nextToken = StartCommentToken then
        begin
            processComment;
            nextToken := nextToken();
        end;
end;



begin
    { prime the pump.. }
    nextChar;
    currentLocation.line := 1;
    currentLocation.from := 1;
    currentLocation.last := 1;
end.
