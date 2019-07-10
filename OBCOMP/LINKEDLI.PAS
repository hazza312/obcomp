unit LinkedList;
{$F+}
interface

type

	PNode = ^Node;

  MapFn = function(p: Pointer): Pointer;
  ForEachFn = procedure(p: Pointer);


	Node = object
  private
  	element: Pointer;
    next: PNode;
    constructor create(val: Pointer);
  end;


	List = object
  private
  	head: ^Node;
    tail: ^Node;
    size: integer;


  public
    function 	getSize: integer;
  	procedure append(item: Pointer);
    procedure prepend(item: Pointer);
    procedure forEach(fn: ForEachFn);
    procedure map(fn: MapFn);
    procedure dump;

    constructor init;
  	destructor destroy;
  end;


implementation

	constructor Node.create(val: Pointer);
  begin
  	element := val;
    next := nil;
  end;


	function List.getSize: integer;
  begin
  	getSize := size;
  end;


  constructor List.Init;
  begin
    head := nil;
    tail := nil;
  end;



  procedure List.append(item: Pointer);
  var
  	nextNode : ^Node;

  begin
  	New(nextNode, Create(item));
    tail^.next := nextNode;
    tail := nextNode;
  	Inc(size);

    if head = nil then
    	head := nextNode;
  end;



  procedure List.prepend(item: Pointer);
  var
  	prevNode : ^Node;

  begin
  	New(prevNode, Create(item));
    prevNode^.next := head;
    head := prevNode;
    Inc(size);

    if tail = nil then
    	tail := prevNode;
  end;



  procedure List.dump;
  var
  	curr: ^Node;
    i: integer;

  begin
  	i := 0;
    curr := head;

  	while (curr <> nil) do
    begin
    	writeln('Node=', i, ' ref=', longint(curr^.element));
      curr := curr^.next;
    	Inc(i);
    end;

  end;


  procedure List.forEach(fn: ForEachFn);
  var
  	curr: ^Node;

  begin
  	while (curr <> nil) do
    begin
    	fn(curr^.element);
      curr := curr^.next;
    end;
  end;


  procedure List.map(fn: MapFn);
  var
  	curr: ^Node;

	begin
  	while (curr <> nil) do
    begin
    	curr^.element := fn(curr^.element);
      curr := curr^.next;
    end;
  end;




  destructor List.destroy;
  begin { TODO: implement } end;

end.