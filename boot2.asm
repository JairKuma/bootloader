; Entrar no modo grafico
;mov ax, 006Ah ; 0013h
;int 10h

org 0x7E00

jmp start

clear_screen_x: dd 0
clear_screen_y: dd 0
draw_pixel_x: dd 0
draw_pixel_y: dd 0
vesa_info: times 256 db 0

GlobalDescriptorTable:   

	; the global descriptor table is the heart of protected mode
	; entries are used to map virtual to physical memory
	; among other things
	;
	; each descriptor contains 8 bytes, "organized" as follows:
	;
	; |----------------------2 bytes--------------------|
	;
	; +-------------------------------------------------+
	; | segment address 24-31  | flags #2  | len 16-19  | +6
	; +-------------------------------------------------+
	; | flags #1               | segment address 16-23  | +4
	; +-------------------------------------------------+
	; | segment address bits 0-15                       | +2
	; +-------------------------------------------------+
	; | segment length bits 0-15                        | +0
	; +-------------------------------------------------+

	; the high-order bit of flags #2 controls "granularity"
	; setting it to 1 multiplies the segment length by 4096

	;======================================================

	; create two descriptors:
	; one for the GDT itself, plus a 4 gibabyte data segment

	dw GlobalDescriptorTableEnd - GlobalDescriptorTable - 1 
	; segment address bits 0-15, 16-23
	dw GlobalDescriptorTable 
	db 0	
	; flags 1, segment length 16-19 + flags 2
	db 0, 0
	; segment address bits 24-31
	db 0 

	; a data segment based at address 0, 4 gibabytes long
	; 
    dw 0xFFFF 	; segment length 0-15
	db 0, 0, 0 	; segment address 0-15, 16-23
	db 0x91 	; flags 1
	db 0xCF 	; flags 2, segment length 16-19
	db 0		; segment address 24-31
	;
GlobalDescriptorTableEnd:

protected_mode:
	xor edx,edx ; edx = 0
    mov dx,ds   ; get the data segment
    shl edx,4   ; shift it left a nibble
    add [GlobalDescriptorTable+2],edx ; GDT's base addr = edx
	
    lgdt [GlobalDescriptorTable] ; load the GDT  
    mov eax,cr0 ; eax = machine status word (MSW)
    or al,1     ; set the protection enable bit of the MSW to 1
	
    cli         ; disable interrupts
    mov cr0,eax ; start protected mode
	
    mov bx,0x08 ; the size of a GDT descriptor is 8 bytes
    mov fs,bx   ; fs = the 2nd GDT descriptor, a 4 GB data seg

    ret

draw_pixel:
	; ah: r, al: g, bh: b

	; Monta a cor e salva em ecx
	mov ecx, 0
	add ch, ah
	add cl, al
	shl ecx, 8
	add cl, bh

	; Transfere a cor pra pilha
	push ecx

	mov eax, 0x7E0
	mov esi, eax

	; Adiciona o endereço base
	mov edi, vesa_info
	;add edi, 28h

	; Pega o endereço base e guarda em edx
	;mov di, vesa_info
	;add di, 28h ; Offset do physical address of linear video buffer
	;mov edx, dword [es:di]

	mov eax, 0
	mov ax, word [es:di+12h]
	mul dword [draw_pixel_y]
	mov ebx, 3
	mul ebx
	
	mov ebx, eax

	mov eax, 3
	mul dword [draw_pixel_x]

	pop ecx

	add eax, dword[es:di+28h]
	add eax, ebx
	mov dword [eax], ecx

	ret

screen_width:
	mov eax, 0x7E0
	mov esi, eax

	mov edi, vesa_info
	mov ax, word [es:di+12h]
	ret

screen_height:
	mov eax, 0x7E0
	mov esi, eax

	mov edi, vesa_info
	mov ax, word [es:di+14h]
	ret

clear_screen:
	mov dword [clear_screen_x], 0
	mov dword [clear_screen_y], 0

	clear_screen_loop_y:
		cmp dword [clear_screen_y], 768
		je clear_screen_loop_y_fim

		clear_screen_loop_x:
			mov edx, dword [clear_screen_x]
			cmp edx, 1024
			je clear_screen_loop_x_fim

			add dword [clear_screen_x], 1

			mov dword [draw_pixel_x], edx

			mov edx, dword [clear_screen_y]
			mov dword [draw_pixel_y], edx

			mov ah, 240
			mov al, 240
			mov bh, 240
			call draw_pixel

			jmp clear_screen_loop_x

		clear_screen_loop_x_fim:
		add dword [clear_screen_y], 1
		mov dword [clear_screen_x], 0
		jmp clear_screen_loop_y

	clear_screen_loop_y_fim:
	iret

start:
	mov ax, 0
	mov es, ax
	mov dword [es:0x80], clear_screen

	; Entra no modo gráfico VESA 1024x768x256
	mov ah, 0x4F
	mov al, 0x02
	mov bx, 118h;105h

	int 10h

	; Obter informações sobre o modo de vídeo
	mov ax, 0x7E0
	mov es, ax
	mov di, vesa_info

	mov ah, 0x4F
	mov al, 0x01
	mov cx, 105h
	int 10h

	; Entrar no modo protegido
	call protected_mode

	sti
	int 20h
	;call clear_screen

	q: jmp q

	;mov di, 28h ; Offset do physical address of linear video buffer
	;mov ax, word [es:di]
	;mov word [eax], 0xFFFF