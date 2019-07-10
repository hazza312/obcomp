unit ParseStack;

interface
	uses Parser;

type

	Action = (FieldEdit, ListAppend);

	StackEntry = record
  	target: PASTNode;
    field: Pointer;
  	action: Action;
  end;


  procedure push(target: PASTNode; field: Pointer; action: Action);
  procedure pop(var entry: StackEntry);



implementation

const
	MAX_DEPTH = 100;

var
	stackArray: array[0..MAX_DEPTH] of StackEntry;
  tosIndex: integer;


  procedure push(target: PASTNode; field: Pointer; action: Action);
  begin
  	Inc(tosIndex);
    stackArray[tosIndex].target := target;
    stackArray[tosIndex].field := field;
    stackArray[tosIndex].action := action;
  end;

  procedure pop(var entry: StackEntry);
  begin
  	entry := stackArray[tosIndex];
    Dec(tosIndex);
  end;

begin
	{initialisation}
  tosIndex := -1;

end.