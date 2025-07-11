         ;代码清单11-1
         ;文件名：c11_mbr0.asm
         ;文件说明：硬盘主引导扇区代码 
         ;创建日期：2020-6-7 15:00
      
         ;计算GDT所在的逻辑段地址 
         mov ax,[cs:gdt_base+0x7c00]        ;低16位，这是以cs=0为起始的段，所以ax里存的就是物理地址
         mov dx,[cs:gdt_base+0x7c00+0x02]   ;高16位，gdt_base其实是一个偏移量
         mov bx,16        
         div bx                             ;除以16就得到了逻辑段地址和偏移地址
         mov ds,ax                          ;令ds指向该段逻辑段地址以进行操作
         mov bx,dx                          ;令bx指向段内起始偏移地址 
      
         ;创建0#描述符，它是空描述符，这是处理器的要求
         mov dword [bx+0x00],0x00
         mov dword [bx+0x04],0x00

         ;创建#1描述符，保护模式下的数据段描述符（文本模式下的显示缓冲区） 
         mov dword [bx+0x08],0x8000ffff     
         mov dword [bx+0x0c],0x0040920b     ;段描述符里有很多信息，这里的段基地址是000b8000

         ;初始化描述符表寄存器GDTR
         mov word [cs: gdt_size+0x7c00],15  ;描述符表的界限（总字节数减一）   
                                             
         lgdt [cs: gdt_size+0x7c00]
      
         in al,0x92                         ;南桥芯片内的端口 
         or al,0000_0010B
         out 0x92,al                        ;打开A20

         cli                                ;保护模式下中断机制尚未建立，应禁止中断 
                                            
         mov eax,cr0
         or eax,1
         mov cr0,eax                        ;设置PE位
         
         ;以下进入保护模式... ...
         
         mov cx,00000000000_01_000B         ;加载数据段选择子(0x01)到段选择器，发现要选的是1号描述符，就是第2个，里面存的段基地址是000b8000
         mov ds,cx                          ;让段选择器ds指向显存，现在ds描述符高速缓存器里里保存的基地址是b8000

         ;以下在屏幕上显示"Protect mode OK." 
         mov byte [0x00],'P'  
         mov byte [0x02],'r'
         mov byte [0x04],'o'
         mov byte [0x06],'t'
         mov byte [0x08],'e'
         mov byte [0x0a],'c'
         mov byte [0x0c],'t'
         mov byte [0x0e],' '
         mov byte [0x10],'m'
         mov byte [0x12],'o'
         mov byte [0x14],'d'
         mov byte [0x16],'e'
         mov byte [0x18],' '
         mov byte [0x1a],'O'
         mov byte [0x1c],'K'

         hlt                                ;已经禁止中断，处理器将不会被唤醒 

;-------------------------------------------------------------------------------
     
         gdt_size         dw 0              ;保存GDT的界限值
         gdt_base         dd 0x00007e00     ;GDT的物理地址 
                             
         times 510-($-$$) db 0
                          db 0x55,0xaa