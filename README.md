# Oberon Compiler
- Hobby Compiler for the [Oberon Language](https://en.wikipedia.org/wiki/Oberon_\(programming_language\)) written in Pascal. 
- Primarily hosted on and targetting x86_64 Linux. 
- Outputs assembly.

## Design
- Single-pass.
- Design inspired by [Wirth's implementation](http://www.projectoberon.com/).
- See [Language report](https://people.inf.ethz.ch/wirth/Oberon/Oberon07.Report.pdf).
- Hopefully flexible to support other output architectures/code generators in the future.

## Building
Under Ubuntu
### Requisites
FreePascal (to build compiler)
nasm, gcc (ld) (to assemble and link compiler output to executable program)

```
apt install fpc
git clone https://github.com/hazza312/obcomp/
cd obcomp 
make build
```
