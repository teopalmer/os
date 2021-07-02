.386p

descr struc
	limit 	dw 0	; Граница (биты 0..15)
	base_l 	dw 0	; База, биты 0..15
	base_m 	db 0	; База, биты 16..23
	attr_1 	db 0	; Байт атрибутов 1
	arrt_2 	db 0	; Граница(биты 16..19) и атрибуты 2
	base_h 	db 0	; База, биты 24..31
descr ends

data segment
	gdt_null descr <0,0,0,0,0,0> ; Нулевой дескриптор
	gdt_data descr <data_size-1,0,0,92h,0,0> ; Сегмент данных, селектор 8
	gdt_code descr <code_size-1,0,0,98h,0,0> ; Сегмент команд, селектор 16
	gdt_stack descr <255,0,0,92h,0,0> ; Сегмент стека, селектор 24
	gdt_screen descr <4095,8000h,0Bh,92h,0,0> ; Видеобуфер, селектор 32
	gdt_size=$-gdt_null ; Размер GDT
	pdescr dq 0 ; Псевдодескриптор
	mes db "Real mode$" 
	mes1 db "Protected mode$" 
	mes2 db "Real mode again$" 

	data_size=$-gdt_null ; Размер сегмента данных
data ends ; Конец сегмента данных

text segment 'code' use16 
										
	assume CS:text, DS:data

main proc
		xor EAX,EAX 
		mov AX,data 
		mov DS,AX 
		shl EAX,4
		mov EBP,EAX 
		mov EBX,offset gdt_data ; В EBX адрес дескриптора
		mov [BX].base_l,AX
		rol EAX,16 
		mov [BX].base_m,AL 
		xor EAX,EAX
		mov AX,CS
		shl EAX,4
		mov EBX,offset gdt_code
		mov [BX].base_l,AX
		rol EAX,16
		mov [BX].base_m,AL

		xor EAX,EAX
		mov AX, SS
		shl EAX,4
		mov EBX,offset gdt_stack
		mov [BX].base_l,AX
		rol EAX,16
		mov [BX].base_m,AL

		mov dword ptr pdescr+2,EBP 
		mov word ptr pdescr,gdt_size-1 
		lgdt pdescr 

		mov esi, offset mes
		mov ax, 0b800h
		mov es, ax
		mov di, 3520
		mov cx, 9
scr:
		lodsb
		mov ah, 0Ah
		stosw
		loop scr

		cli 
		mov AL,80h
		out 70h,AL

		mov EAX,CR0
		or EAX,1 ; Установим бит PE
		mov CR0,EAX 

		db 0EAh ; Код команды far jmp
		dw offset continue ; смещение
		dw 16 ; селектор сегмента команд

continue:
		mov AX,8 ; Селектор сегмента данных
		mov DS,AX

		mov AX,24 ; Селектор сегмента стека
		mov SS,AX
; Делаем адресуемыми видеобуфер и выводим сообщение о переходе
		mov AX,32
		mov ES,AX
		mov BX,3680
		mov CX,15
		mov SI,0

screen:
		mov EAX,word ptr mes1[SI]
		mov ES:[BX],EAX
		add BX,2
		inc SI
		loop screen

		mov gdt_data.limit,0FFFFh ; Граница сегмента данных
		mov gdt_code.limit,0FFFFh ; Граница сегмента кода
		mov gdt_stack.limit,0FFFFh ; Граница сегмента стека
		mov gdt_screen.limit,0FFFFh ; Граница сегмента видеобуфера

		mov AX,8 
		mov DS,AX 
		mov AX,24 
		mov SS,AX 
		mov AX,32 
		mov ES,AX 

		db 0EAh 
		dw offset go 
		dw 16 ; сегмент команд
go:
		mov EAX,CR0
		and EAX,0FFFFFFFEh ; Сброс бита PE
		mov CR0,EAX
		db 0EAh 
		dw offset return 
		dw text 
return:
		mov AX,data 
		mov DS,AX 
		mov AX,stk 
		mov SS,AX 

		sti 
		mov AL,0 
		out 70h,AL
		mov esi, offset mes2
		mov ax, 0b800h
		mov es, ax
		mov di, 3880
		mov cx, 15
scr1:
		lodsb
		mov ah, 0Ah
		stosw
		loop scr1

		mov AH,09h ; Вывод сообщения
		mov EDX,offset mes2
		int 21h
		mov AX,4C00h ; Завершение программы
		int 21h
		main endp

		code_size=$-main ; Размер сегмента кода(команд)
text ends

stk segment stack 'stack' ; Сегмент стека
		db 256 dup ('^')
stk ends

end main