         ;文件说明：用户程序
         ;创建日期：2020-10-30
     
;===============================================================================
SECTION header vstart=0

         program_length   dd program_end          ;程序总长度#0x00
         entry_point      dd start                ;程序入口#0x04
         salt_position    dd salt                 ;SALT表起始偏移量#0x08
         salt_items       dd (header_end-salt)/256 ;SALT条目数#0x0C，保存表的条目数
         
;-------------------------------------------------------------------------------
         ;符号地址检索表
         salt:                                     ;#0x28
         PrintString      db  '@PrintString'       ;用户程序需要哪个子程序就列出，不需要就不列
                     times 256-($-PrintString) db 0
                     
         TerminateProgram db  '@TerminateProgram'  ;用户程序加载之后，这些字符串就变成段内偏移量和段选择子
                     times 256-($-TerminateProgram) db 0
                     
         ReadDiskData     db  '@ReadDiskData'      ;处理的方法是将字符串替换成相应例程在内核中的地址
                     times 256-($-ReadDiskData) db 0
                     
         InitTaskSwitch   db  '@InitTaskSwitch'     ;处理的方法是将字符串替换成相应例程在内核中的地址
                     times 256-($-InitTaskSwitch) db 0
                     
         malloc           db  '@malloc'             ;处理的方法是将字符串替换成相应例程在内核中的地址
                     times 256-($-malloc) db 0
header_end:

;===============================================================================
SECTION data vfollows=header

         message_1         db  '[USER TASK]:CCCCCCCCCCCCCCCCCCC',0x0d,0x0a,0
         
         reserved   times   4096*5  db  0            ;保留一个空白区，以演示分页
         
data_end:

;===============================================================================
      [bits 32]
;===============================================================================
SECTION code vfollows=data                          ;ch17全部修改
start:
         mov ebx,message_1
         call far [PrintString]
         jmp start
         
code_end:

;===============================================================================
SECTION trail
;-------------------------------------------------------------------------------
program_end: