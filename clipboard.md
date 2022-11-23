# Taxas de Leitura/Escrita de processos em bash

## Objectivo

Criar um **bash script** que permita obter a **leitura** e a **escrita de processos.**

## Utilização

```bash
./rwstat.sh -c "regex" -s "bottom_date" -e "upper_date" -u "user" -m minPID -M maxPID -p npro 10
```

Este script leva sempre pelo menos **um argumento**, os segundos para o qual ira analisar as taxas de **rw** dos processos.

**Comando:**

```bash
./rwstat.sh 10
```

**Output:**

```
COMM      USER    PID    READB    WRITEB    RATER    RATEW            DATE
nice      tigo     69    77777      6666       42      100    Sep 12 11:45
lit       nlau    420      777     66666       21      200    Sep 19 08:49
nbeast    idk     666     7777         6       12      300    Sep 19 08:49
```

## Comandos para a formatação de informação

**RW de um processo N**

```bash
cat /proc/N/io | sed -n "5,6p" | awk '{print $2}'
```

**Array de elementos do tipo `ID DATE USER USERGROUP`**

```bash

```
