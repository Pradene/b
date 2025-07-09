# B Compiler

This project is a B Compiler to ASM using Flex and Bison.

## Usage 
1. Run dockerfile:
```bash
docker build -t b .
docker run -it b:latest
```

2. Build the program:
```bash
make
```

3. Run the program:
```bash
./B < file.b
```

## Ressources

[Ken thompson paper](https://www.nokia.com/bell-labs/about/dennis-m-ritchie/kbman.html)
