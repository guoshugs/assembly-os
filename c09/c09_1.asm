         ;代码清单9-1
         ;文件名：c09_1.asm
         ;文件说明：用户程序 
         ;创建日期：2011-4-16 22:03
         
;===============================================================================
SECTION header vstart=0                     ;定义用户程序头部段 
    program_length  dd program_end          ;程序总长度[0x00]
    
    ;用户程序入口点
    code_entry      dw start                ;偏移地址[0x04]
                    dd section.code.start   ;段地址[0x06] 
    
    realloc_tbl_len dw (header_end-realloc_begin)/4
                                            ;段重定位表项个数[0x0a]
    
    realloc_begin:
    ;段重定位表           
    code_segment    dd section.code.start   ;[0x0c]
    data_segment    dd section.data.start   ;[0x14]
    stack_segment   dd section.stack.start  ;[0x1c]
    
header_end:                
    
;===============================================================================
SECTION code align=16 vstart=0           ;定义代码段（16字节对齐） 
new_int_0x70:
      push ax
      push bx
      push cx
      push dx
      push es                           ;将中断处理过程用到的寄存器压栈保存，将来返回的时候再还原
      
  .w0:                                 ;读取RTC寄存器A。因为在读取前需要先确认rtc是否处在更新周期，看寄存器A的位7判断
      mov al,0x0a                        ;阻断NMI。当然，通常是不必要的
      or al,0x80                         ;最高位置1，从而阻断非屏蔽中断NMI
      out 0x70,al                        ;通过索引端口0x70来指定寄存器A，然后通过数据端口0x71来读寄存器A
      in al,0x71                         ;读寄存器A
      test al,0x80                       ;测试第7位UIP，是否是1，1就是正处于更新周期，0安全
      jnz .w0                            ;以上代码对于更新周期结束中断来说 
                                         ;是不必要的 
      xor al,al
      or al,0x80
      out 0x70,al                       ;用于读取cmosram里面的时分秒，并在屏幕上显示。
      in al,0x71                         ;读RTC当前时间(秒)
      push ax                               ;8086只支持word压栈，不支持字节压栈

      mov al,2
      or al,0x80
      out 0x70,al
      in al,0x71                         ;读RTC当前时间(分)
      push ax

      mov al,4
      or al,0x80
      out 0x70,al
      in al,0x71                         ;读RTC当前时间(时)
      push ax
                                        ;寄存器c是读敏感的
      mov al,0x0c                        ;寄存器C的索引。且开放NMI 
      out 0x70,al
      in al,0x71                         ;读一下RTC的寄存器C，使得所有中断标志复位，告诉RTC所有中断已经得到处理，可以继续下一次中断，否则RTC不会再产生中断信号，只发生一次中断
                                         ;此处不考虑闹钟和周期性中断的情况 
      mov ax,0xb800                     ;es一开始已经压栈保存了，所以可以随便改变es的值    
      mov es,ax

      pop ax                            ;弹小时
      call bcd_to_ascii                 ;时间使用bcd编码表示的，要想再屏幕上显示日期和时间，必须转换成字符编码
      mov bx,12*160 + 36*2               ;从屏幕上的12行36列开始显示，为了再屏幕上连续显示内容，最好采用基址寻址来访问内存

      mov [es:bx],ah
      mov [es:bx+2],al                   ;显示两位小时数字，使用的是原来的属性

      mov al,':'
      mov [es:bx+4],al                   ;显示分隔符':'
      not byte [es:bx+5]                 ;反转显示属性 

      pop ax
      call bcd_to_ascii
      mov [es:bx+6],ah
      mov [es:bx+8],al                   ;显示两位分钟数字

      mov al,':'
      mov [es:bx+10],al                  ;显示分隔符':'
      not byte [es:bx+11]                ;反转显示属性

      pop ax
      call bcd_to_ascii
      mov [es:bx+12],ah
      mov [es:bx+14],al                  ;显示两位小时数字
      
      mov al,0x20                        ;中断结束命令EOI 
      out 0xa0,al                        ;向从片发送 
      out 0x20,al                        ;向主片发送 

      pop es
      pop dx
      pop cx
      pop bx
      pop ax

      iret

;-------------------------------------------------------------------------------
bcd_to_ascii:                            ;BCD码转ASCII
                                         ;输入：AL=bcd码
                                         ;输出：AX=ascii
      mov ah,al                          ;分拆成两个数字 
      and al,0x0f                        ;仅保留低4位 
      add al,0x30                        ;转换成ASCII 

      shr ah,4                           ;逻辑右移4位 
      and ah,0x0f                        
      add ah,0x30

      ret

;-------------------------------------------------------------------------------
start:
      mov ax,[stack_segment]
      mov ss,ax                         ;当处理器执行任何一条改变栈段寄存器ss的指令时，它会在下一条指令执行完起间禁止中断，即，在mov ss,ss_pointer之前禁止任何中断
      mov sp,ss_pointer                 ;因为中断是依靠栈来工作的，出现中断时要压入标志寄存器cs，ip，然后转去执行中断处理过程，将来还要依靠内容来返回，若ss和sp之间中断了，就找不到压入的cs'ip了
      mov ax,[data_segment]             ;所以，ss，sp必须挨着设置
      mov ds,ax
      ;任务是演示中断处理，要用自己的实时中断处理过程取代系统开机后默认的处理过程。下面在中断向量表中安装实时时钟中断的入口地址
      mov bx,init_msg                    ;显示初始信息 
      call put_string

      mov bx,inst_msg                    ;显示安装信息 
      call put_string
      ;上面显示2行提示信息，表明我们我安装中断向量了
      mov al,0x70
      mov bl,4                           ;0x70乘以4，就是0x70号登记项的物理地址
      mul bl                             ;计算0x70号中断在IVT中的偏移
      mov bx,ax                          

      cli                                ;防止改动期间发生新的0x70号中断，先清零关中断，以禁止修改向量表期间处理器响应中断
        ;接下来访问中断向量表所在的段，修改0x70号中断所对应的表项
      push es                               ;中断向量表对应的段地址
      mov ax,0x0000                         ;中断本来就加载在00000-0ffff之间，所以可看成是0000的段+自己物理地址可看成是偏移地址
      mov es,ax                             ;可看作中断向量表位于段地址为0的段中
      mov word [es:bx],new_int_0x70      ;偏移地址。新的中断处理过程从此处开始
                                          
      mov word [es:bx+2],cs              ;写入中断处理过程的段地址，段寄存器cs的内容就是当前代码段的段地址
      pop es

      mov al,0x0b                        ;RTC寄存器B。要禁止或允许实时中断信号，必须通过端口0x70访问寄存器b
      or al,0x80                         ;阻断NMI 
      out 0x70,al
      mov al,0x12                        ;设置寄存器B，禁止周期性中断，开放更新结束后中断，BCD码，24小时制 
      out 0x71,al                        ;通过端口0x71将上面的设置发送给寄存器B

      mov al,0x0c                        ;因为这次没有将0x0c的最高位置1，毕竟这是最后一次在主程序中访问RTC
      out 0x70,al                        ;在向索引端口0x70写入的同时，应该利用这个机会打开了NMI
      in al,0x71                         ;读RTC寄存器C，使之开始产生中断信号，复位未决的中断状态
      ;此时RTC芯片设置完毕，再打通它到8259A的最后一道屏障，正常情况下，8259A芯片是不会允许RTC芯片的，要修改其内部的中断寄存器IMR
      in al,0xa1                         ;读8259从片的IMR寄存器 
      and al,0xfe                        ;清除bit 0(此位连接RTC)，用逻辑与指令and对齐进行运算
      out 0xa1,al                        ;写回此寄存器 

      sti                                ;重新开放中断 

      mov bx,done_msg                    ;显示安装完成信息 
      call put_string

      mov bx,tips_msg                    ;显示提示信息
      call put_string
      
      mov cx,0xb800
      mov ds,cx
      mov byte [12*160 + 33*2],'@'       ;屏幕第12行，35列
       
 .idle:
      hlt                                ;使CPU进入低功耗状态，直到用中断唤醒
      not byte [12*160 + 33*2+1]         ;反转显示属性 
      jmp .idle

;-------------------------------------------------------------------------------
put_string:                              ;显示串(0结尾)。
                                         ;输入：DS:BX=串地址
         mov cl,[bx]
         or cl,cl                        ;cl=0 ?
         jz .exit                        ;是的，返回主程序 
         call put_char
         inc bx                          ;下一个字符 
         jmp put_string

   .exit:
         ret

;-------------------------------------------------------------------------------
put_char:                                ;显示一个字符
                                         ;输入：cl=字符ascii
         push ax
         push bx
         push cx
         push dx
         push ds
         push es

         ;以下取当前光标位置
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;高8位 
         mov ah,al

         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;低8位 
         mov bx,ax                       ;BX=代表光标位置的16位数

         cmp cl,0x0d                     ;回车符？
         jnz .put_0a                     ;不是。看看是不是换行等字符 
         mov ax,bx                       ; 
         mov bl,80                       
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

 .put_0a:
         cmp cl,0x0a                     ;换行符？
         jnz .put_other                  ;不是，那就正常显示字符 
         add bx,80
         jmp .roll_screen

 .put_other:                             ;正常显示字符
         mov ax,0xb800
         mov es,ax
         shl bx,1
         mov [es:bx],cl

         ;以下将光标位置推进一个字符
         shr bx,1
         add bx,1

 .roll_screen:
         cmp bx,2000                     ;光标超出屏幕？滚屏
         jl .set_cursor

         mov ax,0xb800
         mov ds,ax
         mov es,ax
         cld
         mov si,0xa0
         mov di,0x00
         mov cx,1920
         rep movsw
         mov bx,3840                     ;清除屏幕最底一行
         mov cx,80
 .cls:
         mov word[es:bx],0x0720
         add bx,2
         loop .cls

         mov bx,1920

 .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         mov al,bh
         out dx,al
         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         mov al,bl
         out dx,al

         pop es
         pop ds
         pop dx
         pop cx
         pop bx
         pop ax

         ret

;===============================================================================
SECTION data align=16 vstart=0

    init_msg       db 'Starting...',0x0d,0x0a,0
                   
    inst_msg       db 'Installing a new interrupt 70H...',0 ;正在安装新的70号中断处理过程
    
    done_msg       db 'Done.',0x0d,0x0a,0

    tips_msg       db 'Clock is now working.',0
                   
;===============================================================================
SECTION stack align=16 vstart=0
           
                 resb 256
ss_pointer:
 
;===============================================================================
SECTION program_trail
program_end: