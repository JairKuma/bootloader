org 0x7c00 
jmp 0x0000:start

print_str: times 100 dw 0

start:

	; nunca se esqueca de zerar o ds,
	; pois apartir dele que o processador busca os 
	; dados utilizados no programa.
	
	xor ax, ax
	mov ds, ax

	;Início do seu código

	; O endereço onde sera carregado o boot2 (es:bx) = 0x7E00
	mov ax, 0x7E0
	mov es, ax
	mov bx, 0

	; Carrega o boot2 do disco (1024 bytes = 2 setores) que esta localizado no segundo setor
	mov ah, 2
	mov al, 2
	call ler_disco

	; Pula pro boot2
	jmp 0x7E00

ler_disco:
	; parametros:
	;  ah: numero do setor
	;  al: quantidade de setores

	mov cl, ah

	mov ah, 2
	mov al, al ; Numero de setores para ler
	mov ch, 0 ; Numero do cilindro
	mov cl, cl ; Numero do setor
	mov dh, 0 ; Numero da cabeça
	mov dl, 0 ; Numero do drive
	int 13h

	ret

print_char:
    mov ah, 0xE
    mov al, al
    mov bh, 1
    mov bl, 0
    int 10h

    ret

print:
	mov [print_str], ax ; Salva o endereco da string em print_str
	print_loop_start:
    	mov bx, [print_str]

    	cmp byte [bx], 0
    	je print_loop_fim ; Se o caractere for zero, sai do loop

    	; Imprimir o caractere na tela
    	mov al, byte [bx]
    	call print_char

    	; Incrementa o endereco
    	mov bx, [print_str]
    	add bx, 1
    	mov [print_str], bx

    	; Volta para o comeco do loop
    	jmp print_loop_start

	print_loop_fim:
    	ret
	
times 510-($-$$) db 0		; preenche o resto do setor com zeros 
dw 0xaa55					; coloca a assinatura de boot no final
							; do setor (x86 : little endian)


