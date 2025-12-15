; --- DIAGNOSTIC COMPLET DU CPU 16-BITS ---

MAIN:
    ; ==========================================
    ; ETAPE 1 : TEST ALU (Addition)
    ; ==========================================
    LDA 10
    ADD 5       ; 10 + 5 = 15
    OUT 0       ; Doit afficher 00001111 (15) en binaire
    
    ; ==========================================
    ; ETAPE 2 : TEST LOGIQUE (AND)
    ; ==========================================
    ; On a 15 (00001111) dans l'ACC
    AND 3       ; 15 AND 3 (00000011) -> Resultat 3
    OUT 0       ; Doit afficher 3
    
    ; ==========================================
    ; ETAPE 3 : TEST STACK & FONCTION
    ; ==========================================
    LDA 2       ; Charge 2
    CALL FOIS_DEUX ; Appel fonction (Sauvegarde PC, Saut)
    
    ; --- RETOUR DE FONCTION ---
    ; Ici ACC doit valoir 4
    ADD 1       ; 4 + 1 = 5
    OUT 0       ; Doit afficher 5

    ; ==========================================
    ; ETAPE 4 : TEST EXTENSION MEMOIRE (16-bits)
    ; ==========================================
    ; On va ecrire 42 dans la Page 1 (Adresse 256)
    
    LDA 1       ; Selection Page 1
    LHI         ; H-REG = 1
    
    LDA 42      ; La reponse universelle
    STA 0       ; Ecrit a l'adresse 0x0100 (Page 1, Offset 0)
    
    ; Verification : On efface l'ACC
    LDA 0
    
    ; On relit la memoire etendue
    LDA 1
    LHI         ; On se remet sur la page 1 (par securite)
    LDR 0       ; Lit 0x0100
    
    OUT 0       ; Doit afficher 42 (00101010)

    ; ==========================================
    ; ETAPE 5 : VICTOIRE (BOUCLE INFINIE)
    ; ==========================================
    ; Si on arrive ici, tout marche.
    
FIN:
    LDA 255
    OUT 0       ; Allume tout
    LDA 0
    OUT 0       ; Eteint tout
    JMP FIN     ; Recommence
    

; --- ZONE DES SOUS-PROGRAMMES ---

FOIS_DEUX:
    ; Fonction qui multiplie par 2 (via addition)
    ; Entree : ACC
    ; Sortie : ACC * 2
    
    STA 100     ; Sauvegarde temporaire en RAM (Page 0 par defaut)
    ADD 0       ; (Astuce : ADD ne prend pas d'adresse, faut recharger)
    
    ADD 2       ; 2 + 2 = 4
    RET         ; Retour au MAIN (Depile PC)