         ;文件名：c13_app1.asm
         ;文件说明：用户程序 
     
;===============================================================================
SECTION header vstart=0

         program_length   dd program_end          ;程序总长度#0x00
         
         head_len         dd header_end           ;程序头部的长度#0x04，加载后变成头部段选择子
;为了简单起见，core要求用户程序只能有一个代码段、一个栈段、一个数据段，都只能向上扩展，必须按下面的格式在头部定义和登记
         prgentry         dd start                ;程序入口#0x08，这里的32位偏移量start是0
         code_seg         dd section.code.start   ;代码段位置#0x0c
         code_len         dd code_end             ;代码段长度#0x10
         
         data_seg         dd section.data.start   ;数据段位置#0x14
         data_len         dd data_end             ;数据段长度#0x18
         
         stack_seg        dd section.stack.start  ;栈段位置#0x1c
         stack_len        dd stack_end            ;栈段长度#0x20
         
;-------------------------------------------------------------------------------
         ;符号地址检索表
         salt_items       dd (header_end-salt)/256 ;#0x24，保存表的条目数，表有几行，这里是3行
         
         salt:                                     ;#0x28
         PrintString      db  '@PrintString'       ;用户程序需要哪个子程序就列出，不需要就不列
                     times 256-($-PrintString) db 0
                     
         TerminateProgram db  '@TerminateProgram'  ;用户程序加载之后，这些字符串就变成段内偏移量和段选择子
                     times 256-($-TerminateProgram) db 0
                     
         ReadDiskData     db  '@ReadDiskData'      ;处理的方法是将字符串替换成相应例程在内核中的地址
                     times 256-($-ReadDiskData) db 0
                 
header_end:

;===============================================================================
SECTION data vstart=0    

         buffer times 1024 db  0         ;缓冲区

         message_1         db  0x0d,0x0a,0x0d,0x0a
                           db  '**********User program is runing**********'
                           db  0x0d,0x0a,0
         message_2         db  '  Disk data:',0x0d,0x0a,0

data_end:

;===============================================================================
SECTION stack vstart=0    

         times 2048        db  0                  ;保留2KB的栈空间

stack_end:

;===============================================================================
      [bits 32]
;===============================================================================
SECTION code vstart=0

start:
         mov eax,ds
         mov fs,eax
         
         mov ss,[fs:stack_seg]
         mov esp,stack_end
     
         mov ds,[fs:data_seg]
     
         mov ebx,message_1
         call far [fs:PrintString]
     
         mov eax,100                         ;逻辑扇区号100
         mov ebx,buffer                      ;缓冲区偏移地址
         call far [fs:ReadDiskData]          ;段间调用
     
         mov ebx,message_2
         call far [fs:PrintString]
     
         mov ebx,buffer 
         call far [fs:PrintString]           ;too.
     
         call far [fs:TerminateProgram]       ;将控制权返回到系统 
      
code_end:

;===============================================================================
SECTION trail
;-------------------------------------------------------------------------------
program_end: