program Compiler;
	uses Lexer, Debug;

var
	t: Token;
begin
	while Lexer.hasNext do
  begin
  	Lexer.nextToken(t);
    Debug.dumpToken(t);
  end;
end.
