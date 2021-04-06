build:	clean
	mkdir build
	fpc -g -FEbuild/ src/COMPILER.PAS

clean:
	rm -rf build


test:	test_parse test_build
	


test_parse:	build
	# just see if the files can be parsed correctly
	./build/COMPILER < test/comments.mod
	./build/COMPILER < test/TEST.MOD 
	./build/COMPILER < test/SIMPLEEXP.MOD > /dev/null
	./build/COMPILER < test/SELECTORS.MOD > /dev/null
	./build/COMPILER < test/EXPRESSIONS.MOD > /dev/null


test_build:	build
	# CALR: compile, assemble, link, run
	./build/COMPILER < test/TEST.MOD > out.asm 				&& nasm -f elf64 out.asm -o test/out.o && ld test/test.o -o test/test && ./test/test
	./build/COMPILER < test/SIMPLEEXP.MOD > /dev/null		&& nasm -f elf64 out.asm -o test/out.o && ld test/test.o -o test/test && ./test/test
	./build/COMPILER < test/SELECTORS.MOD > /dev/null		&& nasm -f elf64 out.asm -o test/out.o && ld test/test.o -o test/test && ./test/test
	./build/COMPILER < test/EXPRESSIONS.MOD > /dev/null		&& nasm -f elf64 out.asm -o test/out.o && ld test/test.o -o test/test && ./test/test
