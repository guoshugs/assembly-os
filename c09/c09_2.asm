         ;代码清单9-2
         ;文件名：c09_2.asm
         ;文件说明：用于演示BIOS中断的用户程序 
         ;创建日期：2012-3-28 20:35
         
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
start:
      mov ax,[stack_segment]
      mov ss,ax
      mov sp,ss_pointer
      mov ax,[data_segment]
      mov ds,ax
      
      mov cx,msg_end-message            ;因为下面要loop，所以之前要cx计算字符串的长度
      mov bx,message                    ;取得字符串的首地址，并放到基址寄存器bx，因为字符串是从标号message开始的，它有vstart=0
      
 .putc:
      mov ah,0x0e                       ;显示字符串，并没有自己写代码，用的是bios功能调用，中断0x10下面的0x0e号子功能
      mov al,[bx]                       ;首先将功能号0e传送到ah寄存器，然后访存，用bx里的值作为偏移地址访问数据段取出一个字符传送到al寄存器
      int 0x10                          ;0x0e是显示一个字符并推进光标，执行软中断0x10
      inc bx                            
      loop .putc                        ;因为要显示一串字符，所以循环

 .reps:                                 ;从键盘读取按下的那个键并把它显示在屏幕上，需要访问硬件，写一堆指令，但因为有了bios功能调用，只需要几条语句就可以
      mov ah,0x00                       ;在中断返回之后ah中存放是字符的ascii码
      int 0x16                          ;使用软中断0x16从键盘读字符，读完之后al中是字符编码，ah中是扫描码
      
      mov ah,0x0e                       ;是显示一个字符并推进光标，执行软中断0x10
      mov bl,0x07
      int 0x10                          ;又一次使用0x10号中断及其0x0e号子功能

      jmp .reps

;===============================================================================
SECTION data align=16 vstart=0

    message       db 'Hello, friend!',0x0d,0x0a
                  db 'This simple procedure used to demonstrate '
                  db 'the BIOS interrupt.',0x0d,0x0a
                  db 'Please press the keys on the keyboard ->'
    msg_end:
                   
;===============================================================================
SECTION stack align=16 vstart=0
           
                 resb 256
ss_pointer:
 
;===============================================================================
SECTION program_trail
program_end: