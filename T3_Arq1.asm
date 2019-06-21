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
CR       EQU    0DH ; codigo ASCII do caractere "carriage return"
LF       EQU    0AH ; codigo ASCII do caractere "line feed"
ATR_TELA EQU    0BH ; fundo preto, caractere ciano claro


; definicao do segmento de dados do programa
dados    segment
msg_ini     db     '>>> Leitor de arquivo com velocidade variavel <<<', CR, LF
ident       db     '>>> Autor: Wellington Espindula #00302367 <<<',CR,LF,LF,'$'
msg_arq     db     'Digite o nome do arquivo: $'
arquivo     dd     ?
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
        lea     dx, msg_arq
        call    write
        call    espera_tecla

        



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

espera_tecla proc
         mov    ah,0               ; funcao esperar tecla no AH
         int    16h                ; chamada do DOS
         ret
espera_tecla endp








codigo   ends

; a diretiva a seguir indica o fim do codigo fonte (ultima linha do arquivo)
; e informa que o programa deve comecar a execucao no rotulo "inicio"
         end    inicio 

    