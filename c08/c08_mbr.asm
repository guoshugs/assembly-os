         ;代码清单8-1
         ;文件名：c08_mbr.asm
         ;文件说明：硬盘主引导扇区代码（加载程序） 
         ;创建日期：2011-5-5 18:17
         ;用户程序在硬盘上的位置必须从逻辑扇区号100开始，加载器也从这个位置加载用户程序
         app_lba_start equ 100           ;声明常数（用户程序起始逻辑扇区号）
                                         ;常数的声明不会占用汇编地址
                                    
SECTION mbr align=16 vstart=0x7c00                                     

         ;设置堆栈段和栈指针 
         mov ax,0      
         mov ss,ax
         mov sp,ax
         
         mov ax,[cs:phy_base]            ;计算用于加载用户程序的逻辑段地址,benchen0x10000
         mov dx,[cs:phy_base+0x02]
         mov bx,16        
         div bx                          ;最后的商在ax中，这个商就是16位的段地址
         mov ds,ax                       ;令DS和ES指向该段以进行操作
         mov es,ax                       ;本程序段地址ds,es是0x1000
    
         ;以下读取程序的起始部分 
         xor di,di
         mov si,app_lba_start            ;程序在硬盘上的起始逻辑扇区号 
         xor bx,bx                       ;加载到DS:0x0000处 
         call read_hard_disk_0           ;处理器在进入子程序之前，先将指令指针寄存器ip的内容压栈，就是下一行
      
         ;以下判断整个程序有多大
         mov dx,[2]                      ;不要把dx写成ds，用户程序总长度的高16位取出 
         mov ax,[0]                      ;用户程序总长度的低16位，因为ds是指向用户程序头部段的，所以上2条指令执行时是ds左移四位+0或2
         mov bx,512                      ;512字节每扇区
         div bx
         cmp dx,0
         jnz @1                          ;未除尽，因此结果比实际扇区数少1 
         dec ax                          ;已经读了一个扇区，扇区总数减1 
   @1:
         cmp ax,0                        ;考虑实际长度小于等于512个字节的情况 
         jz direct
         
         ;读取剩余的扇区，但最多也就只能读64k，ffff字节的地址，所以要临时改变一下ds。读完再恢复
         push ds                         ;以下要用到并改变DS寄存器 

         mov cx,ax                       ;循环次数（剩余扇区数）要想循环，必须先设置cx
   @2:
         mov ax,ds
         add ax,0x20                     ;得到下一个以512字节为边界的段地址
         mov ds,ax  
                              
         xor bx,bx                       ;每次读时，偏移地址始终为0x0000 
         inc si                          ;下一个逻辑扇区 
         call read_hard_disk_0
         loop @2                         ;循环读，直到读完整个功能程序 

         pop ds                          ;恢复数据段基址到用户程序头部段 
      
         ;计算入口点代码段基址 
   direct:
         mov dx,[0x08]                   ;取出代码段地址的高16位并传送到dx
         mov ax,[0x06]                   ;取出低16位
         call calc_segment_base          ;一旦获得了入口点代码段的汇编地址，下面就是根据整个程序加载的起始物理地址来计算出该段的逻辑段地址，调用子程序来计算
         mov [0x06],ax                   ;获得了16位的代码段逻辑段地址，回填修正后的入口点代码段基址，覆盖掉原来的代码段汇编地址，这就完成了入口点的重定位
      
         ;开始处理段重定位表
         mov cx,[0x0a]                   ;需要重定位的项目数量
         mov bx,0x0c                     ;重定位表首地址
          
 realloc:                                ;bx指向每一个表项，表项的内容是段的汇编地址，双字长度
         mov dx,[bx+0x02]                ;取得32位汇编地址的高16位 
         mov ax,[bx]                     ;取得32位汇编地址的低16位
         call calc_segment_base          ;用段的汇编地址生成逻辑段地址，返回给ax
         mov [bx],ax                     ;用生成的逻辑段地址回填覆盖给这个段的汇编地址基址，bx是汇编地址所在的偏移地址
         add bx,4                        ;下一个重定位项（每项占4个字节） 
         loop realloc 
      
         jmp far [0x04]                  ;间接绝对语言转移指令，转移到用户程序  
 
;-------------------------------------------------------------------------------
read_hard_disk_0:                        ;从硬盘读取一个逻辑扇区
                                         ;输入：DI:SI=起始逻辑扇区号
                                         ;      DS:BX=目标缓冲区地址
         ;在过程调用之前，调用者可能正在使用某些寄存器，在进入子程序之后，
         ;应该保证不破坏这些寄存器的内容，为了使程序在过程调用的前后不失连续性，
         ;在过程开头，应该将本过程用到的寄存器临时压栈，并在返回到调用点之前出栈恢复
         push ax
         push bx
         push cx
         push dx
      
         mov dx,0x1f2
         mov al,1
         out dx,al                       ;读取的扇区数

         inc dx                          ;0x1f3
         mov ax,si
         out dx,al                       ;LBA地址7~0

         inc dx                          ;0x1f4
         mov al,ah
         out dx,al                       ;LBA地址15~8

         inc dx                          ;0x1f5
         mov ax,di
         out dx,al                       ;LBA地址23~16

         inc dx                          ;0x1f6
         mov al,0xe0                     ;LBA28模式，主盘
         or al,ah                        ;LBA地址27~24
         out dx,al

         inc dx                          ;0x1f7
         mov al,0x20                     ;读命令
         out dx,al

  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                      ;不忙，且硬盘已准备好数据传输 

         mov cx,256                      ;总共要读取的字数
         mov dx,0x1f0
  .readw:
         in ax,dx
         mov [bx],ax
         add bx,2
         loop .readw

         pop dx
         pop cx
         pop bx
         pop ax
      
         ret                             ;需要一条明确return指令让过程从哪里来回哪里去

;-------------------------------------------------------------------------------
calc_segment_base:                       ;计算16位段地址，要求在调用时必须先输入一个32位的汇编地址并分成2部分
                                         ;输入：DX:AX=32位物理地址
                                         ;返回：AX=16位段基地址 
         push dx                         
         
         add ax,[cs:phy_base]            ;如果有进位，cf标志是1
         adc dx,[cs:phy_base+0x02]       ;8086无法做32位的加法，需要2个寄存器做2个16位的加法，adc是带进位的加法指令
         shr ax,4                        ;用逻辑右移指令shr将ax整体右移4次
         ror dx,4                        ;用循环右移指令将dx的内容右移4次
         and dx,0xf000                   ;先用dx与f000逻辑与，确保dx低12位全是0，虽然多余，但当phybase指定的不对时就有意义了
         or ax,dx                        ;将2部分逻辑或，合成一个完整的16位逻辑段地址并回送到ax
         
         pop dx
         
         ret

;-------------------------------------------------------------------------------
         phy_base dd 0x10000             ;用户程序被加载的物理起始地址
         ;开辟了一个16字节的空间来存储是为了方便，可以改为其他地方，只要最后一位是0能够对齐就可以
         
 times 510-($-$$) db 0
                  db 0x55,0xaa