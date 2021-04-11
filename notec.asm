; Zadanie 2 - "Współbieżny Szesnastkator Noteć"
; Antoni Koszowski (418333)

global notec
extern debug

default rel                     ; Ustawienie adresowania relatywnego.


; N:            predefiniowana liczba wszystkich noteci
; n:     rdi    numer instancji danego notecia
; *calc: rsi    wskaźnik na napis ASCIIZ, opisujący obliczenia

section .data
align           8
global_lock     dq 0            ; Inicjalizujemy semafor do ochrony globalnej.
first_lock      dq 0            ; Inicjalizujemy lock na pierwsze krzesło.
second_lock     dq 0            ; Inicjalizujemy lock na drugie krzesło.

section .bss
alignb          8
wait_array    resq N            ; Globalna tablica do synchronizacji Noteci.
first_chair   resq 1            ; Prezent dla pierwszego Notecia.
second_chair  resq 1            ; Prezent dla drugiego Notecia.

section .text

; Przygotowujemy odpowiednio rejestry, które będziemy wykorzystywać,
; a których wartości są zachowywane pomiędzy callami funkcji.
; Dbamy o zgodność z ABI.
notec:
    push    rbp
    mov     rbp, rsp            ; Ustawiamy w rbp adres bazowy ramki.

    push    rbx
    lea     rbx, [rsi]          ; W rbx trzymamy wskaźnik na napis.

    push    r14
    mov     r14D, edi           ; Zapamiętujemy numer instancji danego notecia.

    push    r12
    xor     r12D, r12D          ; W r12 trzymamy informację nt. trybu
                                ; w jakim znajduje się Noteć (wpisywania albo nie).

    push    r13                 ; Przyda się przed wywołaniem funkcji debug.

    push    r15
    mov     r15, r14
    inc     r15                 ; Zapamiętujemy numer+1 instancji danego Notecia
                                ; (na potrzeby synchronizacji).


; Wczytujemy kolejne znaki, opisujące ciąg obliczeń danego Notecia.
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
    sub     sil, 48
    cmp     sil, 9
    jna     choose_mode         ; Cyfra z zakresu (0-9).

    sub     sil, 7
    cmp     sil, 15
    jna     choose_mode         ; Cyfra z zakresu (A-F).

    sub     sil, 32             ; Cyfra z zakresu (a-f).

choose_mode:
    test    r12D, r12D
    jne     enter_mode          ; Jesteśmy w trybie wpisywania

standard_mode:
    push    rsi                 ; Wrzucamy nową wartość na wierzchołek stosu.
    or      r12D, 0x1           ; Ustawiamy tryb wpisywania.
    jmp     calc_loop

enter_mode:
    pop     rax                 ; Pobieramy wartość z wierzchołka stosu.
    shl     rax, 4              ; Robimy miejsce na nową cyfrę.
    add     al, sil            ; Dopisujemy nową cyfrę.
    push    rax                 ; Wrzucamy nową wartość na wierzchołek stosu.
    jmp     calc_loop

; Operacje dla konkretnych znaków.
chr_eq:
    jmp     update_mode

; Wrzucamy jako nowy wierzchołek sumę dwóch wartości zdjętych ze stosu.
chr_add:
    pop     rax
    pop     rcx
    add     rax, rcx
    push    rax
    jmp     update_mode

; Wrzucamy na wierzchołek stosu iloczyn dwóch wartości zdjętych ze stosu.
chr_mul:
    pop     rax
    pop     rcx
    mul     rcx                 ; Mnożymy rax przez rcx (ze znakiem).
    push    rax
    jmp     update_mode

; Odwracamy znak wartości z wierzchołka stosu.
chr_ar_neg:
    pop     rax
    neg     rax
    push    rax
    jmp     update_mode

; Wrzucamy jako nową wartość wierzchołka stosu
; wynik operacji AND na dwóch wartościach zdjętych ze stosu.
chr_and:
    pop     rax
    pop     rcx
    and     rax, rcx
    push    rax
    jmp     update_mode

; Wrzucamy jako nową wartość wierzchołka stosu
; wynik operacji OR na dwóch wartościach zdjętych ze stosu.
chr_or:
    pop     rax
    pop     rcx
    or      rax, rcx
    push    rax
    jmp     update_mode

; Wrzucamy jako nową wartość wierzchołka stosu
; wynik operacji OR na dwóch wartościach zdjętych ze stosu.
chr_xor:
    pop     rax
    pop     rcx
    xor     rax, rcx
    push    rax
    jmp     update_mode

; Negujemy wartość z wierzchołka stosu.
chr_log_neg:
    pop     rax
    not     rax
    push    rax
    jmp     update_mode

; Usuwamy wartość z wierzchołka stosu.
chr_Z:
    pop     rax
    jmp     update_mode

; Duplikujemy wartość z wierzchołka stosu.
chr_Y:
    pop     rax
    push    rax
    push    rax
    jmp     update_mode

; Zamieniamy kolejnością dwie wartości z wierzchu stosu.
chr_X:
    pop     rax
    pop     rcx
    push    rax
    push    rcx
    jmp     update_mode

; Wrzucamy na wierzchołek stosu globalną liczbę Noteci.
chr_N:
    mov     rax, N
    push    rax
    jmp     update_mode

; Wrzucamy na wierzchołek stosu numer instancji danego Notecia.
chr_n:
    mov     eax, r14D
    push    rax
    jmp     calc_loop

; Wywołujemy zewnętrzną funkcję:
; int64_t debug(uint32_t n, uint64_t *stack_pointer).
chr_g:
    mov     r13, rsp            ; Zapamiętujemy pozycję wskaźnika stosu.
    mov     edi, r14D           ; Pierwszy argument - numer instancji Notecia.
    lea     rsi, [rsp]          ; Drugi argument - wskaźnik na wierzchołek stosu.

    and     rsp, -16            ; Wyrównujemy wskaźnik stosu przed wywołaniem
                                ; funkcji debug, tak żeby był podzielny przez 16.
    call    debug               ; Wywołujemy funkcję debug.

; Przywracamy stos sprzed wywołania funkcji debug.
; Przesuwamy wskaźnik na wierzchołek stosu o wartość wskazaną przez funkcję debug.
update_stack:
    mov     rsp, r13            ; Przywracamy stare rsp.
    lea     rcx, [rax * 8]
    add     rsp, rcx            ; Aktualizujemy wskaźnik na wierzchołek stosu.
    jmp     update_mode

; Synchronizacja Noteci.
chr_W:
    pop     rax                 ; Pobieramy numer instancji Notecia,
                                ; z którym chcemy się zsynchronizować.
    pop     rcx                 ; Pobieramy wartość, którą chcemy wymienić.

    mov     r10, rax            ; Na potrzeby synchronizacji przehowujemy numer+1
    inc     r10                 ; instancji Notecia, z którym się synchronizujemy.

; Schemat synchronizacji:
;   -> każdy Noteć sprawdza czy jest pierwszym czy drugim z pary
;      (sprawdzając odpowiednie wartości w globalnej tablicy wait_array,
;       po wcześniejszym uzyskaniu globalnego semafora);
;   -> Noteć, który jest pierwszy zapisuje w globalnej tablicy numer+1 instancji
;      Notecia, z którym chce się zsynchronizować,
;      następnie czeka na powiadomienie od tego drugiego, odbiera wartość "prezent",
;      który drugi mu zostawił, zostawia swój prezent dla drugiego i daje mu
;      o tym znać, pobiera kolejny znak;
;   -> Noteć, który jest drugi zostawia prezent dla pierwszego, zwalnia pierwszego
;      i czeka na komunikat od niego, kiedy otrzyma komunikat odbiera prezent dla
;      siebie, zwalnia globalny semefor, który gwarantował, że tylko oni wymienią
;      się między sobą prezentami, tj wartościami pod wierzchołkiem swoich stosów
;   (numer+1 instancji, bo tablica w sekcji .bss jest zainicjalizowana zerami).

; Ustalamy czy jesteśmy pierwsi, czy drudzy.
check:
    mov     rdx, global_lock
    mov     rsi, 1

check_wait:
    xchg    [rdx], rsi
    test    rsi, rsi
    jnz     check_wait          ; Skaczemy, jeśli semafor jest zamknięty.

check_action:
    lea     r8, [rel wait_array]; Pobieramy adres komórki z tablicy odpowiadającej
    lea     r9, [r8 + rax * 8]  ;  Noteciowi, z którym chcemy się zsynchronizować.
    cmp     r15, [r9]
    je      second              ; Jesteśmy drudzy.

; Jesteśmy pierwsi.
first:
    lea     r8, [rel wait_array]; Pobieramy adres komórki z tablicy odpowiadającej
    lea     r9, [r8 + r14 *8]   ; instancji danego Notecia.
    mov     [r9], r10           ; Wrzucamy numer instancji+1 Notecia, na którego czekamy.
    mov     [rdx], rsi          ; Zwalniamy semafor.

first_wait:
    mov     rsi,  second_lock
    cmp     r15, [rsi]
    jne     first_wait          ; Czekamy na powiadomienie od drugiego Notecia.

first_action:
    mov     rsi, \
            [rel second_chair]  ; Odbieramy prezent od drugiego Notecia.
    push    rsi                 ; Wrzucamy na wierzchołek stosu otrzymaną wartość.

    mov     r8, 0               ; Nie chcemy się synchronizować.
    mov     [rel second_lock], \
            r8                  ; Blokujemy krzesło.

    mov     qword [r9], 0       ; Resetujemy odpowiednie pole w globalnej tablicy.
                                ; Nie musimy zdobywać semafora, bo już jesteśmy w SK.

    mov     [rel first_chair], \
            rcx                 ; Przekazujemy naszą przesyłkę.
    mov     [rel first_lock], \
            r10                 ; Zwalniamy drugiego Notecia, czekającego na przesyłkę.

    jmp     update_mode

; Jesteśmy drudzy. I mamy już globalny semafor.
second:
    mov     [rel second_chair], \
            rcx                 ; Przekazujemy nasz prezent.
    mov     [rel second_lock], \
            r10                 ; Zwalniamy pierwszego, czekającego na prezent.

; Czekamy na komunikat (zwolnione krzesło) od pierwszego Notecia.
second_wait:
    mov     r9, first_lock
    cmp     r15, [r9]
    jne     second_wait         ; Czekamy na pierwsze krzesło.

second_action:
    mov     r9, \
            [rel first_chair]   ; Pobieramy wartość od pierwszego Notecia.
    push    r9                  ; Wrzucamy na wierzchołek stosu otrzymaną wartość.

    mov     r9, first_lock
    mov     qword [r9], 0       ; Blokujemy krzesło.

    mov     [rdx], rsi          ; Zwalniamy globalny semafor.

; Wychodzimy z trybu wpisywania.
update_mode:
    xor     r12D, r12D
    jmp     calc_loop

; Przywracamy wartości wykorzystywanych rejestrów.
; Zachowujemy zgodność z ABI.
return:
    mov     rax, [rsp]          ; Zwracamy wartość z wierzchołka stosu.
    lea     rsp, [rbp - 5*8]    ; Przywracamy bazowy adres.
    pop     r15
    pop     r13
    pop     r12
    pop     r14
    pop     rbx
    pop     rbp                 ; Przywracamy zawartość rejestru rbp.

    ret
