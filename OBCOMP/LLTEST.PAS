program LLTest;
	uses LinkedList;

var
	L : ^List;
  i: integer;

begin
	New(L, init);


  for i:= 1 to 5 do
		L^.prepend(Pointer(i));


  for i := 1 to 5 do
  	L^.append(Pointer(i));


  L^.dump;

	readln;
end.