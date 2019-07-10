unit IdentifierTree;

interface

type
	PIdentifierNode = ^IdentifierNode;

  Identifier = string[16];
  PIdentifier = ^Identifier;


	IdentifierNode = object
  	value: Identifier;
    left: PIdentifierNode;
    right: PIdentifierNode;
  	constructor init(val: Identifier);
  end;

  function findElseInsert(s: String): PIdentifier;


implementation

var
	root: ^IdentifierNode;


	function findElseInsert(s: String): PIdentifier;
  begin


  end;


  constructor IdentifierNode.init(val: Identifier);
  begin

  end;
end.