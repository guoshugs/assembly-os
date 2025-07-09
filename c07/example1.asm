		;就地反转字符串中的内容
		jmp start
		
string	db 'abcdefghijklmnopqrstuvwxyz'		;0002

start:
		mov ax,0x7c0			;设置数据段的段基地址，001c
		;如果将数据段的段基地址设置成7c00，就能方便的访问上面的字符串
		;因为标号string的汇编地址=它在段内的偏移地址
		mov ds,ax
		
		mov ax,cs				;设置栈段的段基地址
		mov ss,ax				;intel处理器不允许在2个段寄存器之间直接传送。传送后，代码段和栈段都属于同一个段
		mov sp,0				;初始化栈顶指针
		
		mov cx,start-string		;循环次数，从26到1，共26次,001a=26，26个字节
		mov bx,string			;数据区基址寄存器bx的内容就是字符串的偏移地址，bx装的是0002颠倒0200
		;此时出现bx，要给bx也指定一个地址，其实实在所有指令的汇编地址0042之后，开辟的新的地址0043
lppush:
		mov al,[bx]				;采用基址寻址，因为采用了bx，其实也可以将bx统统改成si，就变成了变址寻址
		push ax
		inc bx
		loop lppush				;循环压栈
		
		mov cx,start-string
		mov bx,string
lppop:
		pop ax
		mov [bx],al				;从栈中依次弹出，放回bx车子，bx刚刚重新获取过了，用弹出的内容区覆盖源地址上的a
								;目的操作数也采用了基址寻址，也是因为采用了bx，其实也可以将bx统统改成si
		inc bx
		loop lppop				;循环出栈
		
		
;95看完留作业，完成在屏幕上显示字符串的程序
;观察调试栈内地址情况

		mov ax,0xb800 
		mov es,ax

		;以下显示字符串
		mov si,string
		mov di,0
		mov cx,start-string
 showmsg:
		mov al,[si]
		mov [es:di],al
		inc di
		mov byte [es:di],0x07
		inc di
		inc si
		loop showmsg
		
		jmp $
		
		times 510-($-$$) db 0
		db 0x55,0xaa