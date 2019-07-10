unit Debug;

interface
	uses Lexer;

	procedure dumpToken(var t: Token);

implementation

procedure dumpToken(var t: Token);
begin

	write(t.location.line, ':', t.location.from, '-', t.location.last,
		char(9));

  if t.tokenType in [ArrayToken..WhileToken] then
  	writeln('<', Lexer.KEYWORDS[t.tokenType], '>')

  else
    case t.tokenType of
    IdentifierToken:		writeln('<Identifier> ', t.identifierString);
    IntegerToken:				writeln('<Number> ', t.integerValue);
    SemicolonToken:			writeln('<Semicolon>');
    LeftBracketToken:		writeln('<LeftBracket>');
    RightBracketToken: 	writeln('<RightBracket>');
    DotToken:						writeln('<DotToken>');
    StringLiteralToken:	writeln('<StringLiteral>' , t.literalString);
    EOFToken:						writeln('<EOFToken>');
    else								writeln('<Other> (', integer(t.tokenType), ')');
  	end;
  end;
end.