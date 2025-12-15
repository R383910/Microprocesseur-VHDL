# DOCUMENTATION DU MICROPROCESSEUR (VHDL & ASSEMBLEUR)

## 1. Vue d'ensemble (Architecture)

Ce projet implémente un microprocesseur personnalisé sur FPGA (Intel/Altera DE10-Lite).
Il s'agit d'une architecture hybride :

- **Bus de Données :** 8 bits.
- **Bus d'Adresse :** 16 bits (Espace d'adressage virtuel de 64 Ko).
- **Mémoire Physique :** Optimisée pour le FPGA (256 octets de ROM, 4 Ko de RAM).
- **Exécution :** Single-Cycle (1 instruction = 1 cycle d'horloge).
- **Programmation :** Capable de se reprogrammer dynamiquement via UART (Bootloader intégré).

---

# PARTIE 1 : MATÉRIEL (VHDL)

## 1.1 Description des Composants

| Composant | Fichier | Description |
| --- | --- | --- |
| **Control Unit** | `control_unit.vhd` | Le cerveau. Décode l'instruction (16 bits) et active les signaux de commande (`mem_write`, `pc_jump`, `alu_op`, etc.). |
| **ALU** | `alu.vhd` | Unité Arithmétique et Logique. Gère les calculs (`ADD`, `SUB`) et la logique (`AND`, `OR`, `XOR`). Génère le `Z_FLAG`. |
| **PC** | `pc.vhd` | Compteur de Programme (16 bits). Pointe vers la prochaine instruction. Gère l'incrémentation et les sauts (`JMP`, `CALL`, `RET`). |
| **ACC** | `acc.vhd` | Accumulateur (8 bits). Registre de travail principal. |
| **Stack Pointer** | `stack_pointer.vhd` | Pointeur de Pile (16 bits). Initialisé à `FFFF` (virtuel). Gère la sauvegarde contextuelle pour `PUSH`, `POP`, `CALL`, `RET`. |
| **ROM** | `rom.vhd` | Mémoire Programme *Lecture Seule*. Contient le **Bootloader**. Taille physique : **256 mots**. Initialisée via fichier `.mif`. |
| **iRAM** | `instruction_ram.vhd` | Mémoire Programme *Inscriptible*. Contient le code utilisateur téléchargé. Taille physique : **4 Ko**. |
| **RAM** | `ram.vhd` | Mémoire de Données. Stocke les variables et la Stack. Taille physique : **4 Ko** (Adresses 0 à 4095). |
| **UART (TX/RX)** | `uart_tx.vhd`, `uart_rx.vhd` | Gestion de la communication série avec le PC. |
| **FIFO** | `fifo.vhd` | Tampons mémoire pour l'UART afin de ne pas bloquer le processeur. |

## 1.2 Mécanismes Avancés

### A. Le "Grand Switch" (ROM vs iRAM)

Le processeur possède deux modes d'exécution, commender par l'instruction `RUN`.

- **Mode 0 (Bootloader) :** Le PC exécute les instructions figées dans la **ROM**.
- **Mode 1 (User Program) :** Le PC bascule et exécute les instructions stockées dans l'**iRAM**.

### B. L'Adressage Étendu 16 bits

Les instructions ne disposant que de 8 bits pour l'opérande, l'adresse complète 16 bits est construite par concaténation :

> **Adresse Finale (16b) = High_Byte_Buffer (8b) & Operande (8b)**

- Le `High_Byte_Buffer` est défini par l'instruction `LHI`.

### C. Le Bootloader & Écriture Indirecte

Pour permettre au processeur d'écrire son propre programme :

- L'instruction `STI` permet d'écrire dans l'iRAM.
- L'adresse d'écriture n'est pas l'opérande, mais la valeur stockée dans la RAM de données (Pointeur).

---

# PARTIE 2 : LOGICIEL (ASSEMBLEUR)

## 2.1 Registres Accessibles au Programmeur

| Registre | Taille | Rôle |
| --- | --- | --- |
| **ACC** | 8 bits | **Accumulateur**. Utilisé pour toutes les opérations mathématiques et E/S. |
| **PC** | 16 bits | **Program Counter**. Adresse de l'instruction en cours. |
| **SP** | 16 bits | **Stack Pointer**. Adresse du sommet de la pile (décroissant). |
| **H-REG** | 8 bits | **Registre de Page**. Partie haute de l'adresse mémoire. |

## 2.2 Instruction Set

### Transfert de Données & Mémoire

| Mnémonique | OpCode | Binaire | Action | Description |
| --- | --- | --- | --- | --- |
| **LDA** *val* | 0   | `00000000` | `ACC <= val` | Charge une valeur immédiate (8 bits) dans l'ACC. |
| **STA** *addr* | 5   | `00000101` | `RAM[H:addr] <= ACC` | Sauvegarde l'ACC en RAM à l'adresse indiquée. |
| **LDR** *addr* | 6   | `00000110` | `ACC <= RAM[H:addr]` | Lit une valeur depuis la RAM vers l'ACC. |
| **LHI** | 10  | `00001010` | `H-REG <= ACC` | Charge l'ACC dans le registre de Page (Adresse Haute). |
| **STI** *ptr* | 11  | `00001011` | `iRAM[RAM[ptr]] <= 16b` | **Bootloader**. Écrit l'instruction reçue en iRAM à l'adresse pointée par la RAM. |

### Arithmétique & Logique (ALU)

| Mnémonique | OpCode | Binaire | Action | Description |
| --- | --- | --- | --- | --- |
| **ADD** *val* | 1   | `00000001` | `ACC <= ACC + val` | Addition (sans retenue carry pour l'instant). |
| **SUB** *val* | 4   | `00000100` | `ACC <= ACC - val` | Soustraction. |
| **AND** *val* | 13  | `00001101` | `ACC <= ACC & val` | Opération ET logique. |
| **OR** *val* | 14  | `00001110` | `ACC <= ACC \\| val` | Opération OU logique. |
| **XOR** *val* | 15  | `00001111` | `ACC <= ACC ^ val` | Opération OU Exclusif. |

### Contrôle de Flux (Sauts)

| Mnémonique | OpCode | Binaire | Action | Description |
| --- | --- | --- | --- | --- |
| **JMP** *addr* | 7   | `00000111` | `PC <= H:addr` | Saut inconditionnel vers l'adresse. |
| **JZ** *addr* | 3   | `00000011` | `Si Z=1, PC <= H:addr` | Saut si le résultat précédent était Zéro. |
| **JE** *addr* | 9   | `00001001` | `Si RX=0, PC <= H:addr` | Saut si le tampon UART est vide (Attente). |
| **RUN** *mode* | 12  | `00001100` | `Mode <= mode` | `RUN 0` = Exécute la ROM. `RUN 1` = Exécute l'iRAM. |

### Entrées / Sorties (Périphériques)

| Mnémonique | OpCode | Binaire | Action | Description |
| --- | --- | --- | --- | --- |
| **OUT** *port* | 2   | `00000010` | `TX <= ACC` | Envoie la valeur de l'ACC vers l'UART (PC) et les LEDs. |
| **IN** *port* | 8   | `00001000` | `ACC <= RX` | Lit un octet reçu depuis l'UART. |

### Pile (Stack) & Sous-Programmes

| Mnémonique | OpCode | Binaire | Action | Description |
| --- | --- | --- | --- | --- |
| **PUSH** | 16  | `00010000` | `RAM[SP--] <= ACC` | Sauvegarde l'ACC sur la pile. |
| **POP** | 17  | `00010001` | `ACC <= RAM[++SP]` | Récupère la valeur de la pile dans l'ACC. |
| **CALL** *addr* | 18  | `00010010` | `PUSH (PC+1)`, `JMP` | Appelle une fonction (Sauvegarde le retour). |
| **RET** | 19  | `00010011` | `POP PC` | Retourne d'une fonction (Restaure le PC). |

---

# PARTIE 3 : CHAÎNE DE COMPILATION

Le projet utilise un **Compilateur C++** (`assembleur.exe`) pour gérer à la fois la création du système (Bootloader) et des programmes utilisateurs.

## 3.1 Compilation de l'outil

Le compilateur doit être compilé depuis le fichier source C++ :

```bash
g++ main.cpp -o assembleur.exe -std=c++17
```

## 3.2 Utilisation

L'outil prend en charge deux formats de sortie via un argument.

### Cas A : Générer le Bootloader (Pour Quartus)

Pour graver le code initial dans la ROM du FPGA, il faut générer un fichier `.mif`.

```bash
./assembleur.exe bootloader.asm -mif
```

- **Sortie :** `programme.mif`
  
- **Action :** Placer ce fichier dans le dossier du projet Quartus et recompiler le design.
  

### Cas B : Générer un Programme Utilisateur (Pour Upload)

Pour envoyer un programme (Jeu, Test) via USB vers le processeur en marche, il faut générer un fichier binaire `.bin`.

```
./assembleur.exe programme.asm -bin
```

- **Sortie :** `programme.bin`
  
- **Action :** Utiliser le script Python `send_bin.py` pour envoyer ce fichier au FPGA via UART.
  

```bash
python send_bin.py
```
