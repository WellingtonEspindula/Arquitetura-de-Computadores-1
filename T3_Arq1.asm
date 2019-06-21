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
CR              EQU    0DH ; codigo ASCII do caractere "carriage return"
LF              EQU    0AH ; codigo ASCII do caractere "line feed"
ATR_TELA        EQU    0BH ; fundo preto, caractere ciano claro
BKSPC           EQU    08H ; caractere ASCII "Backspace"
ESCP            EQU    27  ; caractere ASCII "Escape" (tecla ESC)
HASHTAG         EQU    '#' ; caractere ASCII "#"


; definicao do segmento de dados do programa
dados    segment
msg_ini     db     '>>> Leitor de arquivo com velocidade variavel <<<', CR, LF
ident       db     '>>> Autor: Wellington Espindula #00302367 <<<',CR,LF,LF,'$'
msg_arq     db     'Digite o nome do arquivo: $'
arquivo     db     64 dup (?)
            db     CR, LF, '$'
erro        db     'Arquivo nao encontrado!',CR,LF,LF,'$'
handler     dw     ?
buffer      db     128 dup (?)
feito       db     'FEITOOOO!!',CR,LF,LF,'$'
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

; TODO -> mostrar o tipo do erro de abertura
erro_abrir_arquivo:
        lea     dx, erro
        call    write
        jmp     abre_arquivo


arquivo_aberto:
loop_leitura:
; TODO -> esperar o conta-ticsk
        mov     bx, handler
        lea     dx, buffer
        call    fgetc

        mov     dl, buffer
        cmp     dl, HASHTAG
        je      mudanca_tempo
        call    putch
        jmp     loop_leitura

; TODO -> pegar o tempo e mudar a variavel de contagem
mudanca_tempo:
        lea dx, feito
        call write
        


        

        



; retorno ao DOS com codigo de retorno 0 no AL (fim normal)
fim:
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
fgetc   proc
         mov ah,3fh                 ; le um caractere do arquivo
         mov cx,1
         int 21h
         ret
fgetc   endp


; Recebe caractere no DL
putch   proc
         mov ah,2
         int 21h
         ret
putch   endp

; Subrotina que recebe string do teclado
; Recebe o endereco onde a string sera armazenada no registrador SI
gets   proc
end_str     dw      ?

         mov    end_str, di         ; copia o endereco da string
entrada: 
         mov    ah,1
         int    21h                ; le um caractere com eco

         cmp    al,ESCP            ; compara com ESCAPE (tecla ESC)
         jne     valida_enter
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
gets endp

; TODO
file_open   proc
; abre arquivo para leitura 
         mov    ah,3dh
         mov    al,0
         int    21h

         ret
file_open   endp

file_close  proc
         mov ah,3eh                 ; fecha arquivo
         mov bx,handler
         int 21h

         ret
file_close  endp

espera_tecla proc
         mov    ah,0               ; funcao esperar tecla no AH
         int    16h                ; chamada do DOS
         ret
espera_tecla endp








codigo   ends

; a diretiva a seguir indica o fim do codigo fonte (ultima linha do arquivo)
; e informa que o programa deve comecar a execucao no rotulo "inicio"
         end    inicio 

    