    ;包含代码段、数据段和栈段的用户程序
;========================================================================
SECTION header vstart=0                                 ;用户程序头部段
    program_length  dd  program_end                     ;程序总长度[0x00]
    
    ;用户程序入口点
    code_entry      dw  start                           ;偏移地址[0x04]
                    dd  section.code.start              ;段地址[0x06]因为需要提供入口点的段地址和偏移地址，以便用户从这里进入程序执行，重定位覆盖的就是这个地方，被改成了逻辑段地址
                
    realloc_tbl_len dw  (segtbl_end-segtbl_begin)/4     ;段重定位表项个数[0x0A]
    
    ;段重定位表，其中记录了每个段的汇编地址，在程序加载之后及执行之前，加载器会将他们修改为真实的逻辑段地址
    segtbl_begin:
    code_segment    dd  section.code.start              ;[0x0C]，代码段的汇编地址被记录了2次，入口点那也有一次
    data_segment    dd  section.data.start              ;[0x10]
    stack_segment   dd  section.stack.start             ;[0x14]
    segtbl_end:
    
;========================================================================
SECTION code align=16 vstart=0                          ;代码段
    start:
        ;初始执行时，DS和ES指向用户程序头部段
        mov ax,[stack_segment]                          ;设置到用户程序自己的堆栈
        mov ss,ax
        mov sp,stack_pointer                            ;设置初始的栈顶指针
        
        mov ax,[data_segment]                           ;设置到用户程序自己的数据段
        mov ds,ax                                       ;自此ds已经指向数据段
        
        mov ax,0xb800
        mov es,ax                                       ;显存准备好了
        
        mov si,message                                  ;ds设置完毕后，再设置数据段的偏移地址/指针
        mov di,0                                        ;es设置完毕后，再设置显存的偏移地址
        
    next:
        mov al,[si]
        cmp al,0                                        ;因为字符串是以0结尾，要判断是否显示到尾部了
        je exit
        mov byte [es:di],al
        mov byte [es:di+1],0x07                         ;这里并未改变di的值，所以下面要加2
        inc si
        add di,2
        jmp next
        
    exit:
        jmp $
     
;========================================================================
SECTION data align=16 vstart=0                          ;数据段
    message         db  'hello world.',0
    
;========================================================================
SECTION stack align=16 vstart=0                         ;栈段
                    resb 256                            ;栈空间的大小是通过位指令resb来分配的
    stack_pointer:
    
;========================================================================
SECTION trail align=16                                  ;尾部
program_end: