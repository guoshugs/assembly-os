         ;代码清单7-1
         ;文件名：c07_mbr.asm
         ;文件说明：硬盘主引导扇区代码
         ;创建日期：2011-4-13 18:02
         
         jmp near start
	
 message db '1+2+3+...+100='
        
 start:
         mov ax,0x7c0 
         mov ds,ax				;7c00传入数据段ds，设置数据段的段基地址

         mov ax,0xb800          ;设置附加段基址到显示缓冲区
         mov es,ax

         ;以下显示字符串 
         mov si,message          
         mov di,0
         mov cx,start-message	;由于商是压入栈中的，将来还要弹出，必须记住有多少个数
     @g:
         mov al,[si]			;把si所在地址取出一位
         mov [es:di],al			;把它存入显存
         inc di					;偏移显存
         mov byte [es:di],0x07	;存入属性
         inc di					;数据段偏移1
         inc si					;
         loop @g

         ;以下计算1到100的和 
         xor ax,ax
         mov cx,1
     @f:
         add ax,cx				;结果5050已经放入ax里了
         inc cx
         cmp cx,100
         jle @f

         ;以下分解累加和5050的每个数位 
         xor cx,cx              ;设置堆栈段的段基地址
         mov ss,cx
         mov sp,cx

         mov bx,10
         xor cx,cx
     @d:
         inc cx
         xor dx,dx
         div bx					;数位的分解还是要用到除法算法
         or dl,0x30
         push dx				;16位的8086处理器上，压栈和出栈都只能是16位，所以要把dx一块用了
		 ;入栈过程：先把sp减去处理器的字长，8086上是2，然后再入栈
         cmp ax,0				;每次除法后都判断，商是0就提前结束
         jne @d

         ;以下显示各个数位 
     @a:
         pop dx
         mov [es:di],dl			;前面显示字符串的时候就是用di提供偏移地址，因此此时di正好指向字符串尾
         inc di
         mov byte [es:di],0x07
         inc di
         loop @a
       
         jmp near $ 
       

times 510-($-$$) db 0
                 db 0x55,0xaa