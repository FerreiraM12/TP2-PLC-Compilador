# TP2-PLC-Compilador
Linguagem de programação imperativa simples

### Para instalar o flex e o bison:
```
$ sudo apt-get update

$ sudo apt-get install flex

$ sudo apt-get install bison
```


### Para correr o programa:
- Criar o ficheiro lex.yy.c a partir do scanner.l
```
/TP2-PLC-Compilador$ flex scanner.l
```
- Criar os ficheiros grammar.tab.c e grammar.tab.y a partir do grammar.y
```
/TP2-PLC-Compilador$ bison -d grammar.y
```
- Compilar o grammar.tab.c e hashTable.c e criar um executável
```
/TP2-PLC-Compilador$ cc grammar.tab.c hashTable.c
```
- Correr o programa no terminal
```
/TP2-PLC-Compilador$ ./a.out
```
