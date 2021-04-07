build:	src/*.PAS
	mkdir -p build
	fpc -g -FEbuild/ src/COMPILER.PAS


clean:
	rm -rf build


test:	build
	python3 test/runner.py

