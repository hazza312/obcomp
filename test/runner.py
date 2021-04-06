from glob import glob
from subprocess import run
from os.path import basename, exists
import os

# compile, assemble, link, run, test
def CALRT(path):
    in_file = open(path)
    ret = run(['./build/COMPILER'], capture_output=True, encoding="utf-8", stdin=open(path))
    in_file.close()
    if ret.returncode != 0:
        print(f"{path} test FAILED (compiler error) " + ret.stdout)
        return

    asm_file = open("tmp.asm", "w")
    asm_file.write(ret.stdout)
    asm_file.close()
    ret = run(['nasm', '-f', 'elf64', 'tmp.asm', '-o', 'tmp.o'], encoding="utf-8", capture_output=True)
    if ret.returncode != 0:
        print(f"{path} test FAILED (assemble error) " + ret.stdout + ret.stderr)
        return

    ret = run(['ld', 'tmp.o', '-o', 'tmp'], encoding="utf-8", capture_output=True)
    if ret.returncode != 0:
        print(f"{path} test FAILED (linker error) " + ret.stdout)
        return
    

    try:
        ret = run(['./tmp'])
        parts = basename(path).split(".")
        if len(parts) == 3:
            if ret.returncode != int(parts[1]):
                # then test the output
                print(f"{path} test FAILED (wrong result), got {ret.returncode} wanted {int(parts[1])}")
                return
            else:
                print(f"{path} test OK (correct result), got {ret.returncode}")
        else:
            print(f"{path} test OK (compiled and ran ok)")
    except:
        print(f"{path} test FAILED (bad binary)")

    
try:
    # run the exec tests and compare return codes
    for f in glob("test/exec/*.mod"):
        CALRT(f)
finally:
    os.remove("./tmp")
    os.remove("tmp.o")
    os.remove("tmp.asm")
