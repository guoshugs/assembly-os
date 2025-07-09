		jmp start

mytext  db 'L',0x07,'a',0x07,'b',0x07,'e',0x07,'l',0x07,' ',0x07,"o",0x07,\
		   'f',0x07,'f',0x07,'s',0x07,'e',0x07,'t',0x07,':',0x07
		   
start:
		mov ax,0x7c0
		mov ds,ax				;用7c00代替0000开辟一个新的逻辑段，这样7c00的就没有偏移了
		
		mov ax,0xb800
		mov es,ax
		
		;用数据串的传送指令可以传送一串数据
		cld						;无操作数指令，CLear Direction flag将FLAGS寄存器的DF标志置0，指示传送是正向的从低地址到高地址，与STD相反
		mov si,mytext
		mov di,0
		mov cx,(start-mytext)/2	;实际上等于13
		rep movsw				;movsw只能执行一次，用rep可以反复执行，重复的次数由cx来指定，每次执行前会检查cx，不为0才执行
		
		;得到标号所代表的汇编地址
		mov ax,number			;标号和数字是等效的，编译后标号可以转化为一个数字，这条指令实际上是把立即数传送到ax寄存器
		
		;分解各个数位
		mov bx,ax
		mov cx,5				;循环次数
		mov si,10				;除数
		
digit:
		xor dx,dx
		div si
		mov [bx],dl				;保存数位
		;[bx]这种写法意味着访问内存时所使用的偏移地址来自于bx寄存器，就需要bx寄存器保存着偏移地址
		;因为之前number代表的地址已经传给了ax，又间接传给了bx，使用的就是bx的内容存放的内存地址
		;在8086CPU上，如果要用寄存器来提供偏移地址/移动指针，只能用bx,si,di,bp，不能用其他寄存器
		inc bx
		loop digit				;操作码是E2，跟着8位相对偏移量，所以标号的位置不能太远，不然用8位表示不了
		;loop的执行过程：将寄存器cx的内容减1，若cx不为零才循环
		
		;显示各个数位
		mov bx,number
		mov si,4
show:
		mov al,[bx+si]			;bx是基地址，si是最后一个，取出它
		add al,0x30
		mov ah,0x04
		mov [es:di],ax
		add di,2
		dec si
		jns show				;如果标志寄存器的符号位置是0则转移至标志位置执行
		;sf是flags寄存器的第7位signflag,0表示正数，1表示复数，由于si的初始值是4，第1次执行，si变3，都能将sf位清0
		;4次减完，si变成16个1，于是要将sf位置1
		
		jmp $					;让jmp指令不断执行自身
		
number	db 0, 0, 0, 0, 0
		
		times 510-($-$$) db 0	;一个$代表当前行的汇编地址，两个$$代表当前程序段的汇编地址/程序起始的汇编地址
		db 0x55, 0xaa
		
		