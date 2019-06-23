;************************************************************************************
;
; TRABALHO 3 - ARQUITETURA DE COMPUTADORES 1
; UNIVERSIDADE FEDERAL DO RIO GRANDE DO SUL
;
; Autor: Wellington Espindula (wmespindula@inf.ufrgs.br)
; #: 00302367
;
; Versao: 2019.1.0
;
; Resumo: 
;
;************************************************************************************

                  assume cs:codigo,ds:dados,es:dados,ss:pilha

; CONSTANTES
NULL            EQU     00H ; codigo ASCII do fim de string
CR              EQU     0DH ; codigo ASCII do caractere "carriage return"
LF              EQU     0AH ; codigo ASCII do caractere "line feed"
ATR_TELA        EQU     0BH ; fundo preto, caractere ciano claro
BKSPC           EQU     08H ; caractere ASCII "Backspace"
ESCP            EQU     27  ; caractere ASCII "Escape" (tecla ESC)
HASHTAG         EQU     23H ; caractere ASCII "#"
ZERO            EQU     30H ; caractere ASCII '0'
NOVE            EQU     39H ; caractere ASCII '9'


; definicao do segmento de dados do programa
dados    segment
msg_ini         db     '>>> Leitor de arquivo com velocidade variavel <<<', CR, LF
ident           db     '>>> Autor: Wellington Espindula #00302367 <<<',CR,LF,LF,'$'
msg_arq         db     'Digite o nome do arquivo: $'
arquivo         db     64 dup (?)
                db     CR, LF, '$'
erro1_arq       db     'Erro 1: Arquivo nao encontrado',CR,LF,LF,'$'
erro2_arq       db     'Erro 2: Caminho nao existe',CR,LF,LF,'$'
erro3_arq       db     'Erro 3: Arquivos demais',CR,LF,LF,'$'
erro4_arq       db     'Erro 4: Acesso negado',CR,LF,LF,'$'
erro5_tag       db     'Erro 5: Arquivo com "tag" invalida',CR,LF,LF,'$'
handler         dw     ?
buffer          db     128 dup (?)
feito           db     'FEITOOOO!!',CR,LF,LF,'$'
ticks           db      0
tempo_i         db      0
dados    ends

; definicao do segmento de pilha do programa
pilha    segment stack ; permite inicializacao automatica de SS:SP
         dw     128 dup('@@')
pilha    ends
         
; definicao do segmento de codigo do programa
codigo   segment

inicio:  ; CS e IP sao inicializados com este endereco
         mov    ax,dados ; inicializa DS
         mov    ds,ax    ; com endereco do segmento DADOS
         mov    es,ax    ; idem em ES
; fim da carga inicial dos registradores de segmento

; inicio do programa
programa:
        call    cls             ; limpa a tela
        lea     dx, msg_ini     ; escreve mensagens iniciais
        call    write    

        mov     ticks, 00H      ; zera o tempo

abre_arquivo:        
        lea     dx, msg_arq
        call    write
        lea     di, arquivo
        call    gets
        lea     dx, arquivo
        call    file_open
        jc      erro_abrir_arquivo
        mov     handler, ax
        jmp     arquivo_aberto

erro_abrir_arquivo:             ; aqui trata o erro na abertura de arquivo
; Verifica tipo de erro de abertura de arquivo
        cmp     ax,2
        je      erro1
        cmp     ax,3
        je      erro2
        cmp     ax,4
        je      erro3
        cmp     ax,5
        je      erro4

; Tipificacao das mensagens de erro
erro1:                          ; file not found
        lea     dx, erro1_arq
        jmp     escreve_erro
erro2:                          ; path does not exist
        lea     dx, erro2_arq
        jmp     escreve_erro
erro3:                          ; no handle available (too many files)
        lea     dx, erro3_arq
        jmp     escreve_erro
erro4:                          ; access denied
        lea     dx, erro4_arq
escreve_erro:                   ; escreve mensagem de erros
        call    write
        jmp     abre_arquivo


arquivo_aberto:
        call    cls             ; limpa a tela antes de comecar a exibir o arquivo

loop_leitura:
        mov     ah, 00h             
        int     1ah                 ; chama o gettime do DOS
        mov     tempo_i, dl         ; salva o tempo inicial

        mov     bx, handler     ; passa o handler como parametro pelo reg BX   
        lea     dx, buffer      ; passa o buffer como param pelo reg DX
        call    fgetc           ; file getchar
       
        cmp     ax,cx
        jne     fim

        cmp     buffer, HASHTAG     ;tempo verifica se tem '#'
        je      mudanca_tempo   ; se sim, muda o tempo de espera para digitar cada caractere
        
        ; mov     ax, 97       ; passa o tempo como parametro para espera_tempo
        ; mov     dl, tempo_i     ; passa o tempo inicial como parametro
        ; call    espera_tempo    ; espera...
        
        mov     dl, buffer
        call    putch           ; putchar

        jmp     loop_leitura

; TODO -> pegar o tempo e mudar a variavel de contagem
mudanca_tempo:        
primeiro_caractere:
        mov     bx, handler     ; passa o handler como parametro pelo reg BX   
        lea     dx, buffer      ; passa o buffer como param pelo reg DX
        call    fgetc           ; file getchar
        mov     dl, buffer      ; busca o caractere retornado pelo fgetc e move pro reg DL

; Verifica se caractere esta entre 0-9
valida_int_1:
; (char < '0') && (char > '9') -> caractere invalido
        cmp     dl, ZERO
        jl      erro5
        cmp     dl, NOVE
        jg      erro5

        jmp     add_primer_carac

erro5:                          ; tag invalida
        lea     dx, erro5_tag
        call    write
        jmp     fim

add_primer_carac:
        sub     dl, ZERO        ; tranforma numero (ASCII) em inteiro
        mov     al, AH
        mul     dl              ; multiplica por 10
        mov     ticks, dl
        
segundo_caractere:
        mov     bx, handler     ; passa o handler como parametro pelo reg BX   
        lea     dx, buffer      ; passa o buffer como param pelo reg DX
        call    fgetc           ; file getchar
        mov     dl, buffer      ; busca o caractere retornado pelo fgetc e move pro reg DL

; Verifica se caractere esta entre 0-9
valida_int_2:
; (char < '0') && (char > '9') -> caractere invalido
        cmp     dl, ZERO
        jl      erro5
        cmp     dl, NOVE
        jg      erro5
        jmp     add_segund_carac


add_segund_carac:
        sub     dl, ZERO         ; tranforma numero (ASCII) em inteiro
        add     ticks, dl

        ; REMOVER
        ; Testes
        ; mov     dl, ticks
        ; call    putch

        jmp     loop_leitura
        

        



; retorno ao DOS com codigo de retorno 0 no AL (fim normal)
fim:
         mov    bx, handler
         call   file_close
         mov    ax,4c00h           ; funcao retornar ao DOS no AH
         int    21h                ; chamada do DOS





; --------------------- SUBROTIRNAS -----------------------

; Subrotina que limpa a tela e move cursor pro inicio (0,0)
cls     proc
; limpa a tela usando atributos de tela definidos aqui
limpa_tela:
         mov     ch,0         ; linha zero  - canto superior esquerdo 
         mov     cl,0         ; coluna zero - da janela
         mov     dh,24        ; linha 24    - canto inferior direito
         mov     dl,79        ; coluna 79   - da janela
         mov     bh,ATR_TELA  ; atributo de preenchimento
         mov     al,0         ; numero de linhas (zero = toda a janela)
         mov     ah,6         ; rola janela para cima
         int     10h          ; chamada BIOS (video)  

; posiciona cursor no canto superior esquerdo
posiciona_cursor:
         mov     dh,0         ; linha zero  
         mov     dl,0         ; coluna zero
         mov     bh,0         ; numero da pagina (zero = primeira)
         mov     ah,2         ; define posicao do cursor
         int     10h          ; chamada BIOS (video)
         ret
cls     endp

write   proc
; supoe que dx aponta para a mensagem
         mov    ah,9               ; funcao exibir mensagem no AH
         int    21h                ; chamada do DOS
         ret
write   endp

; Recebe file handler no BX e recebe ponteiro pro buffer no DX
; Retorna caractere lido no reg DL
fgetc   proc
         mov ah,3fh                 ; le um caractere do arquivo
         mov cx,1
         int 21h
         ret
fgetc   endp


; Recebe caractere no DL
putch   proc
         mov ax,0
         mov ah,2
         int 21h
         ret
putch   endp

; Subrotina que recebe string do teclado
; Recebe o endereco onde a string sera armazenada no registrador SI
gets    proc
end_str     dw      ?

         mov    end_str, di         ; copia o endereco da string
entrada: 
         mov    ah,1
         int    21h                ; le um caractere com eco

         cmp    al,ESCP            ; compara com ESCAPE (tecla ESC)
         jne    valida_enter
         jmp    terminar 
         
valida_enter:
         cmp    al,CR              ; compara com carriage return (tecla ENTER)
         je     continua

valida_bksp:
         cmp    al,BKSPC           ; compara com 'backspace'
         je     backspace

         mov    [di],al            ; coloca caractere lido no buffer
         inc    di
         jmp    entrada

backspace:
         cmp    di,end_str
         jne    adiante
         mov    dl,' '              ; avanca cursor na tela
         mov    ah,2
         int    21h
         jmp    entrada
adiante:
         mov    dl,' '              ; apaga ultimo caractere digitado
         mov    ah,2
         int    21h
         mov    dl,BKSPC            ; recua cusor na tela
         mov    ah,2
         int    21h
         dec    di
         jmp    entrada

continua: 
         mov    byte ptr [di],0     ; forma string ASCIIZ com o nome do arquivo
         mov    dl,LF               ; escreve LF na tela
         mov    ah,2
         int    21h
         jmp    retorna

terminar:
         mov    ax,4c00h            ; funcao retornar ao DOS no AH
                                    ; codigo de retorno 0 no AL
         int    21h                 ; chamada do DOS

retorna:
         ret
gets    endp

; Abre arquivo para leitura 
; TODO -> Comentario
file_open       proc
         mov    ah,3dh
         mov    al,0
         int    21h

         ret
file_open       endp

file_close      proc
         mov ah,3eh                 ; fecha arquivo
         int 21h

         ret
file_close      endp

espera_tecla    proc
         mov    ah,0               ; funcao esperar tecla no AH
         int    16h                ; chamada do DOS
         ret
espera_tecla    endp

; Recebe tempo (em ticks) no registrador AL
; Recebe tempo inicialtempo_inicial no registrador DL
espera_tempo    proc

; -- variaveis locais
ticks_local     db      0
tempo_i_local   db      0

; antes de entrar no loop
pre_loop:
        mov     ticks_local, al         ; salva o numero de ticks
        mov     tempo_i_local, dl       ; salva o tempo inicial

loop_espera:
        mov     ah, 00h             
        int     1ah                 ; chama o gettime do DOS
        sub     dl, tempo_i_local   ; dl <- tempo_final (dl) - tempo_inicial
        
        cmp     ticks, dl           ; 
        jle     retorna_espera      ; ticks <= delta(tempo) -> retorna
        jmp     loop_espera

retorna_espera:        
        ret
espera_tempo endp

; Verifica se a string esta vazia
; TODO
str_empty       proc
        ret
str_empty       endp


codigo   ends

; a diretiva a seguir indica o fim do codigo fonte (ultima linha do arquivo)
; e informa que o programa deve comecar a execucao no rotulo "inicio"
         end    inicio 

    