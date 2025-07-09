start:
		;在屏幕上显示数字65535
		mov ax, 65535
		xor dx, dx					;将dx清零
		mov bx, 10
		div bx						;ax里存放的是商6553，dx里存放余数5
		
		add dl, 0x30				;将数字转换为对应的数字字符
		
		mov cx, 0
		mov ds, cx					;段地址不能直接存放必须用通用寄存器中转
		
		mov [0x7c00+buffer], dl		;7c00+8a=7c8a，颠倒一下变成8a7c
		
		xor dx, dx
		div bx
		add dl, 0x30
		mov [0x7c00+buffer+1], dl
		
		xor dx, dx
		div bx
		add dl, 0x30
		mov [0x7c00+buffer+2], dl
		
		xor dx, dx
		div bx
		add dl, 0x30
		mov [0x7c00+buffer+3], dl
		
		xor dx, dx
		div bx
		add dl, 0x30
		mov [0x7c00+buffer+4], dl
		
		;最后再将al中字符编码写入现存内偏移地址为0的地方，对应着显示器左上角的位置
		;取数字字符用段寄存器ds，操作显存用附加段寄存器es
		mov cx, 0xb800
		mov es, cx
		
		mov al, [0x7c00+buffer+4]	;默认使用的是段寄存器ds
		mov [es:0x00], al			;接着用段寄存器es来填充显存
		mov byte [es:0x01], 0x2f	;接着写入属性字节，此时因为同时不知道数字和地址的长度，所以标明byte
		
		mov al, [0x7c00+buffer+3]
		mov [es:0x02], al
		mov byte [es:0x03], 0x2f
		
		mov al, [0x7c00+buffer+2]
		mov [es:0x04], al
		mov byte [es:0x05], 0x2f
		
		mov al, [0x7c00+buffer+1]
		mov [es:0x06], al
		mov byte [es:0x07], 0x2f
		
		mov al, [0x7c00+buffer]
		mov [es:0x08], al
		mov byte [es:0x09], 0x2f
		
again:
		jmp again					;为了防止处理器跑飞
	
buffer	db 0, 0, 0, 0, 0			;buffer开辟的空间随着代码段顺延到了008a的位置，但是后来又复制了一份到7c00的后面

current:
		times 510-(current-start) db 0
		
		db 0x55, 0xaa
