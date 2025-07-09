		;就地反转字符串中的内容——采用基址变址寻址方式
		;不使用栈就可以完成和栈相同的功能
		jmp start
		
string	db 'abcdefghijklmnopqrstuvwxyz'		;0002

start:
		mov ax,0x7c0			;设置数据段的段基地址，001c
		mov ds,ax
		
		mov bx,string			;数据区首地址
		mov si,0				;正向索引，0是a在字符串内的偏移量
		mov di,start-string-1	;反向索引，n-1是z在字符串内的偏移量
rever:
		mov ah,[bx+si]
		mov al,[bx+di]
		mov [bx+si],al
		mov [bx+di],ah			;以上4行用于交换首位数据
		inc si
		dec di
		cmp si,di
		jl rever				;首位没有相遇，或者没有超越，继续交换
		

		jmp $
		
		times 510-($-$$) db 0
		db 0x55,0xaa