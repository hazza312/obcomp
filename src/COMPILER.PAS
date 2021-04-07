program Compiler;

uses 
    Lexer, SymbolTable, CGX86, Common;

var
    peekToken: TTokenType;
    statements: boolean;
    nloops: integer;


{ Internal Parser Functions ************************************************* }
function Next: TTokenType;
begin
    Next := peekToken;
    peekToken := Lexer.nextToken;
end;


function Accept(tokenType: TTokenType): boolean;
begin
    Accept := peekToken = tokenType;
    if Accept then Next
end;


procedure Expect(tokenType: TTokenType);
var
    errStr: string;

begin
    if peekToken <> tokenType then
        begin
            Writestr(errStr, peekToken);
            Error('Parse', currentLocation, ' unexpected token ' + errStr)
        end;
    Next;
end;



{ Begin Recursive Descent parse Procedures ********************************** }
procedure parseExpression; forward;                  { forward declarations }
function parseDesignator: PSymbolEntry; forward;
procedure parseActualParameters; forward;
function parseType: PSymbolEntry; forward;
procedure parseProcedureDeclaration; forward;

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
    var 
        start, last: TSymbolIndex;
        ty: PSymbolEntry;
        isvar: boolean;
    begin
        isvar := accept(VarToken);   
        start := SymbolTable.CurrentSymbolIndex;
        repeat
            expect(IdentifierToken);
            SymbolTable.DeclareFormalParameter(identifier, isvar);
        until not accept(CommaToken);

        expect(ColonToken);
        if accept(ArrayToken) then 
            expect(OfToken);

        ty := parseQualIdent;

        for start := start to SymbolTable.CurrentSymbolIndex do
            SymbolTable.AssignType(SymbolTable.IToPSym(start), ty);

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



procedure parseVarUseOrCall;
var
    desig: PSymbolEntry;

begin
    desig := parseDesignator;

    if desig^.symType in [SVariable, SFormalParameter] then
        CGX86.VarUse(desig)

    else if desig^.symType = SProcedure then 
        begin
            if accept(LeftBracketToken) then
                begin { need to do something with the parameters }
                    parseActualParameters;
                    expect(RightBracketToken);
                end;

            CGX86.DoCall(desig);          
        end

    else
        Error('Type', currentLocation, 'Variable or function type expected');
end;





{ RD Expressions ************************************************************ }
procedure parseFactor;
var desig: PSymbolEntry;
begin
    if accept(NilToken) then

    else if accept(FalseToken) then

    else if accept(IntegerToken) then
        CGX86.DoConstant(Lexer.integerLiteral)
        
    else if accept(StringLiteralToken) then

    else if accept(LeftCurlyToken) then
        parseSet

    else if accept(LeftBracketToken) then
        begin
            parseExpression;
            expect(RightBracketToken);
        end

    else if accept(TildeToken) then { not sure what this does }
        parseFactor

    else
        parseVarUseOrCall;

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

function parseProcedureHeading: PSymbolEntry;
begin
    { expect(ProcedureToken, 'PROCEDURE expected'); accepted }
    expect(IdentifierToken);
    parseProcedureHeading := SymbolTable.EnterProcedure(identifier);

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
var 
    loopVar: PSymbolEntry;
begin
    { FOR token accepted }
    expect(IdentifierToken);
    loopVar := Find(identifier);    

    expect(AssignToken);
    parseExpression;
    expect(ToToken);
    parseExpression;

    Inc(nloops);
    CGX86.EnterFor(loopVar, nloops);
    { TODO }
    if accept(ByToken) then
        parseExpression;

    expect(DoToken);
    parseStatementSequence;

    CGX86.ExitFor(loopVar, nloops);
    Dec(nloops);

    expect(EndToken);
end;



function parseDesignator: PSymbolEntry;
const
    selectorStarts = [DotToken, LeftSquareToken, CaretToken, LeftBracketToken];

begin
    parseDesignator := parseQualident;

    if parseDesignator = nil then
        Error('Type', currentLocation, 'Unknown identifier!');

    while peekToken in selectorStarts do
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

        { use typeguard to ensure not a procedure call }
        else if (peekToken = LeftBracketToken) then
            if (parseDesignator^.symType = SProcedure) then
                exit
            else
                begin
                    accept(LeftBracketToken);
                    parseQualident;
                    expect(RightBracketToken);
                end;

end;


procedure parseActualParameters;
begin
    { ( accepted }
    if not accept(RightBracketToken) then
        repeat
            parseExpression;
            CGX86.PushArg;
        until not accept(CommaToken);
end;


procedure parseAssignmentOrCall;
var 
    desig: PSymbolEntry;
begin
    desig := parseDesignator;
    if desig = nil then 
        writeln('nl!');
  
  if accept(AssignToken) then
    begin
      parseExpression;
      CGX86.DoAssign(desig)
    end
  else if accept(LeftBracketToken) then
    begin
      parseActualParameters;
      expect(RightBracketToken);
    end
  else { call without params? }
    CGX86.DoCall(desig)   
    
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
  parseDeclarationSequence;
  if accept(BeginToken) then
    parseStatementSequence;

  expect(EndToken);
  expect(IdentifierToken);
end;


procedure parseProcedureDeclaration;
begin
    CGX86.BeginFunction(parseProcedureHeading);
    expect(SemicolonToken);
    parseProcedureBody;
    SymbolTable.ExitProcedure;
    CGX86.EndFunction;
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
            CGX86.BeginFunction(SymbolTable.EnterProcedure('_start'));
            parseStatementSequence;
            CGX86.EndModule;
        end;

    expect(EndToken); 
    expect(IdentifierToken);    
    expect(DotToken);
end;


begin
    nloops := 0;
    Next; { prime pump }
    ParseModule;
    
end.
