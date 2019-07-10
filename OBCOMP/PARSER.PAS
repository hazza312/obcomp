unit Parser;

interface
	uses LinkedList;

type

	BinaryOp = (AddOp, SubOp, MulOp, DivOp, ModOp);

  PASTNode = ^ASTNode;

	ASTNode = object
  	Parent: PASTNode;
  end;


  IdentifierNode = object(ASTNode)
  	Name: string;
  end;


  ImportNode = object(ASTNode)

  end;

  DeclarationNode = object(ASTNode)

  end;


  StatementNode = object(ASTNode)

  end;

  ModuleNode = object(ASTNode)
  	Name: ^IdentifierNode;
    Imports: ^List;
    ConstDeclarations: ^List;
    TypeDeclarations: ^List;
    VarDeclarations: ^List;
    ProcedureDeclarations: ^List;
    ForwardDeclarations: ^List;
  	Statements: ^List;
  end;




implementation

var
	P: Pointer;

procedure Visit(n: ASTNode);
begin

end;






end.