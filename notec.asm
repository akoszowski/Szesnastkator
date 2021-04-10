; Zadanie 2 - "Współbieżny Szesnastkator Noteć"
; Antoni Koszowski (418333)

global notec
extern debug

default rel                     ; Ustawienie adresowania relatywnego.

; Bullet points:
;   -> zgodność z wymaganiami ABI, tzn. rejestry i stos procesora
;   -> sensowne rozwiązanie problemu synchronizacji noteci

; TO DO:
; Czy macro pozwala na zmniejszenie objętości kodu?

; N:     macro  liczba wszystkich noteci
; n:     rdi    numer danego notecia
; *calc: rsi    wskaźnik na napis ASCIIZ, opisujący obliczenie

section .data
table_lock      dq 0            ; Inicjalizujemy lock na "stół synchronizacyjny".
first_lock      dq N            ; Inicjalizujemy lock na pierwsze krzesło.
second_lock     dq N            ; Inicjalizujemy lock na drugie krzesło.

section .bss
wait_array    resq N            ; Globalna tablica do synchronizacji Noteci.
first_chair   resq 1            ; Prezent dla pierwszego Notecia.
second_chair  resq 1            ; Prezent dla drugiego Notecia.

section .text

; Mamy dwa tryby, jak je reprezentować ??? Musimy je aktualizować na bieżąco?

; Argumenty funkcji:
;   -> rdi, rsi, rdx, rcx, r8, r9

; Trzeba zachować:
;   -> rbx, rsp, rbp, r12 - r15

; Można zmieniać:
;   -> rax, rcx, rdx, rsi, rdi, r8 - r11

notec:
    push    rbp
    mov     rbp, rsp            ; Ustawiamy w rbp adres bazowy ramki.

    push    rbx
    push    r14
    lea     rbx, [rsi]          ; W rbx trzymamy wskaźnik na napis.
    mov     r14D, edi           ; Zapamiętujemy numer instancji danego notecia.

    push    r12
    xor     r12D, r12D          ; W r12 trzymamy informację nt. trybu w jakim znajduje się Noteć (wpisywania albo nie).

    push    r13

    lea     r8, [rel wait_array]
    lea     r9, [r8 + r14 * 8]
    mov     qword [r9], N

; Wczytujemy kolejne znaki.
calc_loop:
    xor     rsi, rsi
    mov     sil, [rbx]          ; Pobieramy kolejny znak.
    test    sil, sil
    jz      return              ; Trafiliśmy na NULLa - koniec napisu.

    inc     rbx                 ; Przesuwamy wskażnik na kolejny znak.

    ; Klasyfikujemy dany znak.
    cmp     sil, 0x3D
    je      chr_eq              ; Wczytaliśmy '='.

    cmp     sil, 0x2B
    je      chr_add             ; Wczytaliśmy '+'.

    cmp     sil, 0x2A
    je      chr_mul             ; Wczytaliśmy '*'.

    cmp     sil, 0x2D
    je      chr_ar_neg          ; Wczytaliśmy '-'.

    cmp     sil, 0x26
    je      chr_and             ; Wczytaliśmy '&'.

    cmp     sil, 0x7C
    je      chr_or              ; Wczytaliśmy '|'.

    cmp     sil, 0x5E
    je      chr_xor             ; Wczytaliśmy '^'.

    cmp     sil, 0x7E
    je      chr_log_neg         ; Wczytaliśmy '~'.

    cmp     sil, 0x5A
    je      chr_Z               ; Wczytaliśmy 'Z'.

    cmp     sil, 0x59
    je      chr_Y               ; Wczytaliśmy 'Y'.

    cmp     sil, 0x58
    je      chr_X               ; Wczytaliśmy 'X'.

    cmp     sil, 0x4E
    je      chr_N               ; Wczytaliśmy 'N'.

    cmp     sil, 0x6E
    je      chr_n               ; Wczytaliśmy 'n'.

    cmp     sil, 0x67
    je      chr_g               ; Wczytaliśmy 'g'.

    cmp     sil, 0x57
    je      chr_W               ; Wczytaliśmy 'W'.

    ; Skoro napis zawiera tylko wyspecyfikowane znaki,
    ; to w rsi mamy cyfrę (0-9)|(A-F)|(a-f).
    sub     rsi, 48
    cmp     rsi, 9
    jna     choose_mode         ; Cyfra z zakresu (0-9).

    sub     rsi, 7
    cmp     rsi, 15
    jna     choose_mode         ; Cyfra z zakresu (A-F)

    sub     rsi, 32             ; Cyfra z zakresu (a-f).

choose_mode:
    test    r12D, r12D
    jne     enter_mode          ; Jesteśmy w trybie wpisywania

standard_mode:
    push    rsi                 ; Wrzucamy nową wartość na wierzchołek stosu.
    or      r12D, 0x1           ; Ustawiamy tryb wpisywania
    jmp     calc_loop

enter_mode:
    pop     rax                 ; Pobieramy wartość z wierzchołka stosu.
    shl     rax, 4              ; Robimy miejsce na nową cyfrę.
    add     rax, rsi            ; Dopisujemy nową cyfrę.
    push    rax                 ; Wrzucamy nową wartość na wierzchołek stosu.
    jmp     calc_loop

; Operacje dla konkretnych znaków.
chr_eq:
    ; xor     r12D, r12D          ; Wychodzimy z trybu wpisywania.
    jmp     update_mode

chr_add:
    pop     rax
    pop     rcx
    add     rax, rcx
    push    rax                 ; Wrzucamy jako nowy wierzchołek sumę dwóch wartości zdjętych ze stosu.
    jmp     update_mode

chr_mul:
    pop     rax
    pop     rcx
    mul     rcx                 ; Mnożymy zawartośc rax przez rcx (wartości mogą być ze znakiem).
    push    rax                 ; Wrzucamy na wierzchołek stosu wyliczony wynik.
    jmp     update_mode

chr_ar_neg:
    pop     rax
    neg     rax                 ; Negujemy wartość z wierzchołka stosu.
    push    rax
    jmp     update_mode

chr_and:
    pop     rax
    pop     rcx
    and     rax, rcx
    push    rax                 ; Wrzucamy jako nową wartość wierzchołka stosu wynik operacji AND na dwóch wartościach zdjętych ze stosu.
    jmp     update_mode

chr_or:
    pop     rax
    pop     rcx
    or      rax, rcx
    push    rax                 ; Wrzucamy jako nową wartość wierzchołka stosu wynik operacji OR na dwóch wartościach zdjętych ze stosu.
    jmp     update_mode

chr_xor:
    pop     rax
    pop     rcx
    xor     rax, rcx
    push    rax                 ; Wrzucamy jako nową wartość wierzchołka stosu wynik operacji OR na dwóch wartościach zdjętych ze stosu.
    jmp     update_mode

chr_log_neg:
    pop     rax
    not     rax
    push    rax                 ; Wrzucamy na stos negację dotychczasowej wartości z wierzchołka stosu.
    jmp     update_mode

chr_Z:
    pop     rax                 ; Usuwamy wartość z wierzchołka stosu.
    jmp     update_mode

chr_Y:
    pop     rax
    push    rax
    push    rax                 ; Duplikujemy wartość z wierzchołka stosu.
    jmp     update_mode

chr_X:
    pop     rax
    pop     rcx
    push    rax
    push    rcx                 ; Zamieniamy kolejnością dwie wartości z wierzchu stosu.
    jmp     update_mode

chr_N:
    mov     rax, N
    push    rax                 ; Wrzucamy na wierzchołek stosu liczbę Noteci.
    jmp     update_mode

chr_n:
    mov     eax, r14D
    push    rax                 ; Wrzucamy na wierzchołek stosu numer instancji danego Notecia.
    jmp     calc_loop

; Wywołanie funckji: int64_t debug(uint32_t n, uint64_t *stack_pointer)
chr_g:
    mov     r13, rsp
    mov     edi, r14D       ; Jako pierwszy argument przekazujemy numer instancji Notecia.
    lea     rsi, [rsp]            ; Jako drugi argument przekazujemy wskaźnik na wierzchołek stosu.
    ; Musimy wyrównać wskażnik stosu tak, żeby był podzielny przez 16.

    and     rsp, -16            ; Wyrównujemy stos.
    call    debug               ; Wołamy funkcję debug.

update_stack:
    mov     rsp, r13            ; Przywracamy stare rsp.
    lea     rcx, [rax * 8]
    add     rsp, rcx            ; Aktualizujemy wskaźnik na wierzchołek stosu.
    jmp     update_mode

; TODO: synchronizacja Noteci.
chr_W:
    pop     rax                 ; Pobieramy numer instancji Notecia, z którym chcemy się zsynchronizować.
    pop     rcx                 ; Pobieramy wartość, którą chcemy wymienić.

    lea     r8, \
    [rel wait_array]
    lea     r9, [r8 + rax * 8]  ; Pobieramy adres komórki z tablicy odpowiadającą Noteciowi, z którym chcemy się zsynchronizować.
    mov     rsi, [r9]
    cmp     r14, rsi
    je      second              ; Jesteśmy drudzy.

first:
    lea     r8, \
    [rel wait_array]
    lea     r9, [r8 + r14 *8]   ; Pobieramy adres komórki z tablicy odpowiadającej instancji danego Notecia.
    mov     [r9], rax           ; Wrzucamy numer instancji Notecia, na którego czekamy.

first_wait:
    mov     rsi, [second_lock]
    cmp     r14, rsi
    jne     first_wait          ; Czekamy na drugie krzesło.

first_action:
    mov     rsi, [rel second_chair] ; Pobieramy wartość od drugiego Notecia.
    push    rsi                 ; Wrzucamy na wierzchołek stosu otrzymaną wartość.

    mov     r9, N               ; Nie chcemy się synchronizować.
    mov     [second_lock], r9   ; Blokujemy krzesło.

    mov     [rel first_chair], rcx  ; Przekazujemy naszą przesyłkę.
    mov     [first_lock], rax   ; Zwalniamy drugiego Notecia, czekającego na przesyłkę.

    jmp     calc_loop

second:
    mov     rdx, table_lock   ; Pobieramy adres semafora.
    mov     r9, 1

table_wait:
    xchg    [rdx], r9           ; Zamykamy blokadę.
    test    r9, r9              ; Sprawdzamy czy była otwarta.
    jnz     table_wait          ; Kręcimy się, jeśli była zamknięta.

table_action:
    mov     [rel second_chair], rcx ; Przekazujemy naszą przesyłkę.
    mov     [second_lock], rax  ; Zwalniamy pierwszego Notecia, czekającego na przesyłkę.

second_wait:
    mov     rsi, [first_lock]
    cmp     r14, rsi
    jne     second_wait         ; Czekamy na pierwsze krzesło.

second_action:
    mov     rsi, [rel first_chair]  ; Pobieramy wartość od pierwszego Notecia.
    push    rsi                 ; Wrzucamy na wierzchołek stosu otrzymaną wartość.

    mov     rsi, N
    mov     [first_lock], rsi     ; Blokujemy krzesło.

    mov     [rdx], r9           ; Otwieramy blokadę.

    jmp     calc_loop

update_mode:
    xor     r12D, r12D          ; Wychodzimy z trybu wpisywania.
    jmp     calc_loop

return:
    mov     rax, [rsp]          ; Zwracamy wartość z wierzchołka stosu.
    lea     rsp, [rbp - 4*8]    ; Przywracamy bazowy adres.
    pop     r13
    pop     r12
    pop     r14
    pop     rbx
    pop     rbp                 ; Przywracamy zawartość rejestru rbp.

    ret
