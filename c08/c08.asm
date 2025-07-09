         ;代码清单8-2
         ;文件名：c08.asm
         ;文件说明：用户程序 
         ;创建日期：2011-5-5 18:17
         
;===============================================================================
SECTION header vstart=0                     ;定义用户程序头部段 
    program_length  dd program_end          ;程序总长度[0x00]
    
    ;用户程序入口点
    code_entry      dw start                ;偏移地址[0x04]
                    dd section.code_1.start ;段地址[0x06] 
    
    realloc_tbl_len dw (header_end-code_1_segment)/4
                                            ;段重定位表项个数[0x0a]
    
    ;段重定位表           
    code_1_segment  dd section.code_1.start ;[0x0c]
    code_2_segment  dd section.code_2.start ;[0x10]
    data_1_segment  dd section.data_1.start ;[0x14]
    data_2_segment  dd section.data_2.start ;[0x18]
    stack_segment   dd section.stack.start  ;[0x1c]
    
    header_end:                
    
;===============================================================================
SECTION code_1 align=16 vstart=0         ;定义代码段1（16字节对齐） 
put_string:                              ;显示串(0结尾)，这个字符串必须时0结尾的
                                         ;输入：DS:BX=串地址
         mov cl,[bx]                     ;但是计算结果回影响到标志寄存器中的某些位，ZF是0则取得的是空字符0
         or cl,cl                        ;cl=0 ?用cmp cl,0时最直观的，但这里是一个数和他自己做或运算，结果还是它自己
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
         mov dx,0x3d4                    ;通过索引端口3d4告诉显卡，现在要操作0e号寄存器
         mov al,0x0e
         out dx,al
         mov dx,0x3d5                    ;通过数据端口3d5从0e号寄存器读出一个字节的数据
         in al,dx
         mov ah,al                       ;把al中的传送到ah中，这时光标位置的高8位

         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;低8位  
         mov bx,ax                       ;BX=代表光标位置的16位数，把ax传到bx中临时保存
         ;一旦知道了光标的位置，就意味着字符在屏幕上的显示位置确定了，字符是通过cl传入的，cl中是字符的编码
         cmp cl,0x0d                     ;回车符？
         jnz .put_0a                     ;不是。看看是不是换行等字符 
         mov ax,bx                       ;此句略显多余，但去掉后还得改书，麻烦 
         mov bl,80                       
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor
         ;在标准VGA文本模式下，每屏是25行，每行是80列，80个字符，0-24，0-79
 .put_0a:
         cmp cl,0x0a                     ;换行符？
         jnz .put_other                  ;不是，那就正常显示字符 
         add bx,80
         jmp .roll_screen

 .put_other:                             ;正常显示字符
         mov ax,0xb800
         mov es,ax
         shl bx,1                        ;根据光标位置数值得到字符的段内偏移地址，1个字符对应显存里的2个字节但对应着屏幕上1个光标
         mov [es:bx],cl                  ;将光标位置乘以2就得到了在显存内部的偏移地址，逻辑左移

         ;以下将光标位置推进一个字符
         shr bx,1
         add bx,1

 .roll_screen:
         cmp bx,2000                     ;光标超出屏幕？滚屏
         jl .set_cursor                  ;不越界，就设置光标
         ;以下就是滚屏操作，是在显存里批量传输数据
         push bx                         ;原书出错，修改：先将bx位置的数据压栈保存，因为后面的批量数据传送要用道bx
         mov ax,0xb800
         mov ds,ax
         mov es,ax
         cld                             ;设置方向标志正向传送
         mov si,0xa0                     ;设置原区域的起始偏移地址0xa0，传到变址寄存器si中
         mov di,0x00                     ;再设置目标区域的偏移地址
         mov cx,1920
         rep movsw                       ;批量传送
         
         mov bx,3840                     ;清除屏幕最底一行，最后一行最左边的字符在显存中的偏移地址是3840，写入80个空格
         mov cx,80
 .cls:
         mov word[es:bx],0x0720          ;07是属性，20是空格的十六进制编码
         add bx,2                        ;指向下一个空格
         loop .cls

         ;mov bx,1920                    ;为了修改原书的逻辑问题，删除此行，新增下2行
         pop bx                          ;如果滚屏是光标超出了屏幕的右下角引起的，最后一个字符1999的光标是2000，滚屏后移到最后一行的行首也需要减80
         sub bx,80                       ;如果滚屏是换行引起的，那么光标应该还在最后一行的某个位置，而前面已经加上80了，所以减掉

 .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         mov al,bh                       ;光标位置的数值保存在寄存器bx，但写端口只能用寄存器al
         out dx,al                       ;显示光标位置的高8位
         mov dx,0x3d4                    ;通过3d4端口指定寄存器0f
         mov al,0x0f
         out dx,al
         mov dx,0x3d5                    ;通过3d5端口向寄存器0f写入光标位置的低8位
         mov al,bl
         out dx,al

         pop es
         pop ds
         pop dx
         pop cx
         pop bx
         pop ax

         ret

;-------------------------------------------------------------------------------
  start:
         ;初始执行时，DS和ES指向用户程序头部段
         mov ax,[stack_segment]           ;设置到用户程序自己的堆栈 
         mov ss,ax
         mov sp,stack_end
         
         mov ax,[data_1_segment]          ;设置到用户程序自己的数据段，此时只有es还指向头部段
         mov ds,ax

         mov bx,msg0
         call put_string                  ;显示第一段信息 

         push word [es:code_2_segment]    ;es此时还指向头部段，从重定位表那里取得code2的逻辑段地址，压栈
         mov ax,begin                     ;还要压入目标位置的偏移地址，就是begin在编译阶段的汇编地址，因为又vstart=0，所以从段首开始计算，8086无法传入一个立即数，所以通过ax
         push ax                          ;可以直接push begin,80386+
         
         retf                             ;转移到代码段2执行 return far模拟原返回以实现段间转移，与push code2结合使用，会转移到code2去执行
         
  continue:
         mov ax,[es:data_2_segment]       ;段寄存器DS切换到数据段2 ，ds又变了，es仍不变，ds取得了重定位表中data2的逻辑段地址
         mov ds,ax
         
         mov bx,msg1
         call put_string                  ;显示第二段信息 

         jmp $                            ;通常用户程序执行完毕后，应该重新将控制返回到加载器，这样加载器可以加载其他程序，但这里的mbr加载器不提供这个功能

;===============================================================================
SECTION code_2 align=16 vstart=0          ;定义代码段2（16字节对齐）

  begin:
         push word [es:code_1_segment]    ;用retf就是假装从过程返回，假装主程序是子程序。es仍是是指向header的，所以压栈的就是重定位表的逻辑段地址
         mov ax,continue
         push ax                          ;可以直接push continue,80386+
         
         retf                             ;转移到代码段1接着执行 
         
;===============================================================================
SECTION data_1 align=16 vstart=0                                ;因为vstart=0，所以msg0的汇编地址是0，在程序运行时它的汇编地址也是它的段内偏移地址

    msg0 db '  This is NASM - the famous Netwide Assembler. '
         db 'Back at SourceForge and in intensive development! '
         db 'Get the current versions from http://www.nasm.us/.'
         db 0x0d,0x0a,0x0d,0x0a                                 ;0x0d是回车，0x0a是换行符，不是图形字符，无法显示，只能通过编码来引用            
         db '  Example code for calculate 1+2+...+1000:',0x0d,0x0a,0x0d,0x0a
         db '     xor dx,dx',0x0d,0x0a
         db '     xor ax,ax',0x0d,0x0a
         db '     xor cx,cx',0x0d,0x0a
         db '  @@:',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     add ax,cx',0x0d,0x0a
         db '     adc dx,0',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     cmp cx,1000',0x0d,0x0a
         db '     jle @@',0x0d,0x0a
         db '     ... ...(Some other codes)',0x0d,0x0a,0x0d,0x0a
         db 0                                                   ;0用来标志字符串的结束，这种被称为0终止字符串

;===============================================================================
SECTION data_2 align=16 vstart=0

    msg1 db '  The above contents is written by LeeChung. ' ;没有回车换行，在一行显示，光标最后在6的后面
         db '2011-05-06'
         db 0

;===============================================================================
SECTION stack align=16 vstart=0
           
         resb 256

stack_end:  

;===============================================================================
SECTION trail align=16                      ;主要是让标号program_end有一个16进制对齐的汇编地址    
program_end:                                ;因为没有vstart=0子句，所以它的汇编地址就是程序的总长度，以字节计