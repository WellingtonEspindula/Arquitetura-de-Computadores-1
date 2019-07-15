;************************************************************************************
;
; TRABALHO 3 - ARQUITETURA DE COMPUTADORES 1
; UNIVERSIDADE FEDERAL DO RIO GRANDE DO SUL
;
; Autor: Wellington Espindula (wmespindula@inf.ufrgs.br)
; #: 00302367
; 
; Sobre direitos de codigo:
; Trabalho de autoria propria, porem alguns trechos 
; de codigo presentes aqui foram extraidos dos exemplos
; disponibilizados pelo Prof.º Dr.º Carlos Arthur Lang Lisboa.
;
; Versao: 2019.1.0
;
; Resumo: O presente trabalho tem por objetivo implementar,
; em Assembly nos processadores Intel 8086, um programa que
; le arquivos de texto e exibe os caracteres lidos na tela,
; um de cada vez, dado que a velocidade de exibicao eh variavel.
; A velocidade de exibicao, inicialmente 0, eh alterada por 
; "tags" no texto lido. Assim, as tags sao sequencias de 3
; caracteres iniciadas por '#' e seguidos de 2 digitos decimais.
;
;************************************************************************************

                  assume cs:codigo,ds:dados,es:dados,ss:pilha

; CONSTANTES
NULL            EQU     00H ; codigo ASCII do fim de string
CR              EQU     0DH ; codigo ASCII do caractere "carriage return"
LF              EQU     0AH ; codigo ASCII do caractere "line feed"
ATR_TELA        EQU     0BH ; fundo preto, caractere ciano claro
BKSPC           EQU     08H ; codeigo ASCII "Backspace"
ESCP            EQU     27  ; codeigo ASCII "Escape" (tecla ESC)
HASHTAG         EQU     23H ; codeigo ASCII "#"
ZERO            EQU     30H ; codeigo ASCII '0'
NOVE            EQU     39H ; codeigo ASCII '9'
r_min           EQU     72H ; codeigo ASCII 'r'
R_mai           EQU     52H ; codeigo ASCII 'R'
n_min           EQU     6EH ; codeigo ASCII 'n'
N_mai           EQU     4EH ; codeigo ASCII 'N'


; definicao do segmento de dados do programa
dados    segment
msg_ini         db      '>>> Leitor de arquivo com velocidade variavel <<<', CR, LF
ident           db      '>>> Autor: Wellington Espindula #00302367 <<<',CR,LF,LF,'$'
msg_arq         db      'Digite o nome do arquivo: $'
arquivo         db      64 dup (?)
                db      CR, LF, '$'
erro1_arq       db      'Erro 1: Arquivo nao encontrado',CR,LF,LF,'$'
erro2_arq       db      'Erro 2: Caminho nao existe',CR,LF,LF,'$'
erro3_arq       db      'Erro 3: Arquivos demais',CR,LF,LF,'$'
erro4_arq       db      'Erro 4: Acesso negado',CR,LF,LF,'$'
erro5_tag       db      'Erro 5: Arquivo com "tag" invalida',CR,LF,LF,'$'
handler         dw      ?
buffer          db      128 dup (?)
feito           db      'FEITOOOO!!',CR,LF,LF,'$'
ticks           db      0
tempo_i         db      0
msg_fim         db      'Execucao interrompida normalmente a pedido do usuario',CR,LF,'$'
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



; -------------- INICIO DO PROGRAMA ------------------------
programa:
        call    cls             ; limpa a tela
        lea     dx, msg_ini     ; escreve mensagens iniciais
        call    write    

etapa2:
abre_arquivo:        
        lea     dx, msg_arq     ; passa endereco de msg_arq como parametro para write
        call    write           ; escreve mensagens na tela
        lea     di, arquivo     ; passa endereco da string arquivo como parametro para gets
        call    gets            ; pega string do usuario e carrega no endereco passado

        mov     al, [arquivo]   ; move primeiro byte da string arquivo pra al
        cmp     al, NULL        ; verifica se a string esteja vazia
        je      jmp_exibe_fim   ; se sim, mostra mensagem de fim de execucao

r_pressed:
        lea     dx, arquivo     ; passa string arquivo como parametro
        call    file_open       ; abre o arquivo
        jc      erro_abrir_arquivo      ; em caso de erro de abertura, mostra o erro
        mov     handler, ax     ; move saida do handler do arquivo pro handler
        jmp     arquivo_aberto  ; faz operacoes...


jmp_exibe_fim:
        jmp     exibe_fim       ; pula pro fim


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

; ------------------ ERROS ----------------------------------
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


; ---------------- ARQUIVO ABERTO -----------------------
etapa3:
arquivo_aberto:
        call    cls                     ; limpa a tela antes de comecar a exibir o arquivo
        mov     ticks, 00H              ; zera o tempo
        mov     ah, 00h             
        int     1ah                     ; chama o gettime do DOS
        mov     tempo_i, dl             ; salva o tempo inicial

etapa4:
loop_leitura:
        mov     ah, 00h             
        int     1ah                     ; chama o gettime do DOS
        mov     tempo_i, dl             ; salva o tempo inicial

        mov     bx, handler             ; passa o handler como parametro pelo reg BX   
        lea     dx, buffer              ; passa o buffer como param pelo reg DX
        call    fgetc                   ; file getchar
       
        cmp     ax,cx
        jne     verifica_digitacao

        cmp     buffer, HASHTAG         ; verifica se tem '#'
        je      mudanca_tempo           ; se sim, muda o tempo de espera para digitar cada caractere
        
        call    espera_tempo            ; espera...
        
        mov     dl, buffer
        call    putch                   ; putchar

        mov     ah, 01H                 ; kbhit
        int     16h                     ;
        jnz      verifica_digitacao      ; caso tecla tenha sido pressionada, verifica o que houve

        jmp     loop_leitura


etapa7:
        mov     bx, handler     ; passa arquivo como parametro
        call    file_close      ; fecha arquivo
        call    cls             ; limpa a tela
        jmp     etapa2          ; volta a etapa 2

verifica_digitacao:
        call    getchar         ; getchar()
        cmp     al, r_min       ; char == 'r'
        je      jmp_r_pressed   ; reinicia leitura
        cmp     al, R_mai       ; char == 'R'
        je      jmp_r_pressed   ; idem

        cmp     al, n_min       ; char == 'n'
        je      etapa7          ; pula pra etapa 7 (limpa tela, fecha arquivo, pede arquivo)
        cmp     al, N_mai       ; char == 'N'
        je      etapa7          ; idem

        cmp     al, ESCP        ; char == ESC
        je      exibe_fim       ; pula pro fim
        
        jmp     loop_leitura


jmp_r_pressed:                  ; reinicia a exibicao do arqvuido 
        mov     bx, handler     ; passa arquivo como parametro
        call    file_close      ; fecha arquivo
        call    cls             ; limpa a tela
        jmp     r_pressed       ; abre arquivo, confere erros, leitura, ...


exibe_fim:                      ; exibe mensagem de fim e termina o programa
        lea     dx, msg_fim     ; move mensagem de fim pro reg DX
        call    write           ; escreve na tela
        jmp     fim             ; encerra


; ------------------- MUDANCA DE TEMPO --------------------------- ;
mudanca_tempo:        
        mov     ticks, 0
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
        lea     dx, erro5_tag   ; mostra erro
        call    write
        call    getchar         ; getchar()
        jmp     etapa7          ; limpa tela, fecha arquivoo e volta pra etapa 2

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

        jmp     loop_leitura


;---------------------- FIM ------------------------------
; retorno ao DOS com codigo de retorno 0 no AL (fim normal)
fim:
        mov    ax,4c00h        ; funcao retornar ao DOS no AH
        int    21h             ; chamada do DOS





; --------------------- SUBROTIRNAS -----------------------

;------------- CLS ---------------
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

;------------- WRITE ---------------
; Recebe string (endereco) da mensagem no reg DX
write   proc
         mov    ah,9               ; funcao exibir mensagem no AH
         int    21h                ; chamada do DOS
         ret
write   endp

;------------- FGETC -------------------
; Recebe file handler no BX e recebe ponteiro pro buffer no DX
; Retorna caractere lido no reg DL
fgetc   proc
        mov ah,3fh                 ; le um caractere do arquivo
        mov cx,1
        int 21h
        ret
fgetc   endp


;------------- PUTCH -----------
; Escreve caractere na tela
; Recebe caractere no DL
putch   proc
         mov ax,0
         mov ah,2
         int 21h
         ret
putch   endp


;------------- GETS --------------------
; Subrotina que recebe string do teclado, tratando backspace e enter
; Recebe o endereco onde a string sera armazenada no registrador SI
; Devolve o que foi lido na string entrada
end_str     dw      ?
gets    proc

        mov    end_str, di         ; copia o endereco da string
entrada: 
        mov    ah,1
        int    21h                ; le um caractere com eco
         
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

retorna:
        ret
gets    endp

;------------- FILE OPEN -------
; Abre arquivo para leitura 
; Recebe string (endereco) do arquivo no reg DX
; Retorna handler em AX.
; CF = 1 se arquivo nao foi aberto adequadamente
file_open       proc
        mov    ah,3dh
        mov    al,0
        int    21h

        ret
file_open       endp


;------------- FILE CLOSE ------
; Fecha arquivo
; Recebe handler no reg BX
file_close      proc
        mov ah,3eh                 ; fecha arquivo
        int 21h

        ret
file_close      endp

;------------- GETCHAR --------
; Pega caractere do teclado
; Retorna o codigo ASCII do caractere em AL
; Retorna codigo de varredura em AH
getchar    proc
        mov    ah,0               ; funcao esperar tecla no AH
        int    16h                ; chamada do DOS
        ret
getchar    endp

;------------- ESPERA_TEMPO ---------
; Espera o tempo (ticks) usando funcoes do DOS
espera_tempo    proc
loop_espera:
        mov     ah, 00h             
        int     1ah             ; chama o gettime do DOS
        sub     dl, tempo_i     ; dl <- tempo_final (dl) - tempo_inicial
        
        cmp     ticks, dl       ; 
        jg      loop_espera     ; while (ticks > delta(t))
        ret
espera_tempo endp
codigo   ends

; a diretiva a seguir indica o fim do codigo fonte (ultima linha do arquivo)
; e informa que o programa deve comecar a execucao no rotulo "inicio"
         end    inicio 

    