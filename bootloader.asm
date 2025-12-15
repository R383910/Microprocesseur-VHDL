; --- BOOTLOADER SYSTEME 16-bits ---
; Ce programme est execute au demarrage depuis la ROM.
; Il ecoute l'UART et remplit l'iRAM.

DEBUT:
    ; 1. Initialisation du curseur d'ecriture
    ; On utilise la case memoire 255 comme pointeur
    LDA 0
    STA 255     ; Pointeur RAM[255] = 0

    ; 2. Clignotement LED pour dire "Je suis pret"
    LDA 255     ; Allume tout
    OUT 0
    LDA 0       ; Eteint tout
    OUT 0

WAIT_SIZE:
    ; 3. Attente de la taille (Header)
    ; On lit juste l'octet pour vider le buffer, on ne s'en sert pas ici
    JE WAIT_SIZE
    IN 0 

LOOP_LOAD:
    ; --- RECEPTION OCTET HAUT ---
WAIT_H:
    JE WAIT_H   ; Attente passive si buffer vide
    IN 0        ; Lecture de l'octet H
    LHI         ; Stockage dans le registre de Page (H-REG)

    ; --- RECEPTION OCTET BAS ---
WAIT_L:
    JE WAIT_L   ; Attente
    IN 0        ; Lecture de l'octet L (Reste dans ACC)

    ; --- ECRITURE EN IRAM ---
    ; STI utilise la valeur dans RAM[255] comme adresse de destination
    ; Il combine le H-REG (stocké avant) et l'ACC actuel.
    STI 255     

    ; --- INCREMENTATION DU POINTEUR ---
    LDR 255     ; Charge la valeur du pointeur
    ADD 1       ; Ajoute 1
    STA 255     ; Sauvegarde

    ; --- VISUALISATION ---
    ; Affiche l'adresse en cours sur les LEDs pour voir que ca charge
    OUT 0       

    ; On boucle a l'infini (jusqu'a ce que le PC ait fini d'envoyer)
    JMP LOOP_LOAD