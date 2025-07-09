         ;�����嵥9-1
         ;�ļ�����c09_1.asm
         ;�ļ�˵�����û����� 
         ;�������ڣ�2011-4-16 22:03
         
;===============================================================================
SECTION header vstart=0                     ;�����û�����ͷ���� 
    program_length  dd program_end          ;�����ܳ���[0x00]
    
    ;�û�������ڵ�
    code_entry      dw start                ;ƫ�Ƶ�ַ[0x04]
                    dd section.code.start   ;�ε�ַ[0x06] 
    
    realloc_tbl_len dw (header_end-realloc_begin)/4
                                            ;���ض�λ�������[0x0a]
    
    realloc_begin:
    ;���ض�λ��           
    code_segment    dd section.code.start   ;[0x0c]
    data_segment    dd section.data.start   ;[0x14]
    stack_segment   dd section.stack.start  ;[0x1c]
    
header_end:                
    
;===============================================================================
SECTION code align=16 vstart=0           ;�������Σ�16�ֽڶ��룩 
new_int_0x70:
      push ax
      push bx
      push cx
      push dx
      push es                           ;���жϴ�������õ��ļĴ���ѹջ���棬�������ص�ʱ���ٻ�ԭ
      
  .w0:                                 ;��ȡRTC�Ĵ���A����Ϊ�ڶ�ȡǰ��Ҫ��ȷ��rtc�Ƿ��ڸ������ڣ����Ĵ���A��λ7�ж�
      mov al,0x0a                        ;���NMI����Ȼ��ͨ���ǲ���Ҫ��
      or al,0x80                         ;���λ��1���Ӷ���Ϸ������ж�NMI
      out 0x70,al                        ;ͨ�������˿�0x70��ָ���Ĵ���A��Ȼ��ͨ�����ݶ˿�0x71�����Ĵ���A
      in al,0x71                         ;���Ĵ���A
      test al,0x80                       ;���Ե�7λUIP���Ƿ���1��1���������ڸ������ڣ�0��ȫ
      jnz .w0                            ;���ϴ�����ڸ������ڽ����ж���˵ 
                                         ;�ǲ���Ҫ�� 
      xor al,al
      or al,0x80
      out 0x70,al                       ;���ڶ�ȡcmosram�����ʱ���룬������Ļ����ʾ��
      in al,0x71                         ;��RTC��ǰʱ��(��)
      push ax                               ;8086ֻ֧��wordѹջ����֧���ֽ�ѹջ

      mov al,2
      or al,0x80
      out 0x70,al
      in al,0x71                         ;��RTC��ǰʱ��(��)
      push ax

      mov al,4
      or al,0x80
      out 0x70,al
      in al,0x71                         ;��RTC��ǰʱ��(ʱ)
      push ax
                                        ;�Ĵ���c�Ƕ����е�
      mov al,0x0c                        ;�Ĵ���C���������ҿ���NMI 
      out 0x70,al
      in al,0x71                         ;��һ��RTC�ļĴ���C��ʹ�������жϱ�־��λ������RTC�����ж��Ѿ��õ��������Լ�����һ���жϣ�����RTC�����ٲ����ж��źţ�ֻ����һ���ж�
                                         ;�˴����������Ӻ��������жϵ���� 
      mov ax,0xb800                     ;esһ��ʼ�Ѿ�ѹջ�����ˣ����Կ������ı�es��ֵ    
      mov es,ax

      pop ax                            ;��Сʱ
      call bcd_to_ascii                 ;ʱ��ʹ��bcd�����ʾ�ģ�Ҫ������Ļ����ʾ���ں�ʱ�䣬����ת�����ַ�����
      mov bx,12*160 + 36*2               ;����Ļ�ϵ�12��36�п�ʼ��ʾ��Ϊ������Ļ��������ʾ���ݣ���ò��û�ַѰַ�������ڴ�

      mov [es:bx],ah
      mov [es:bx+2],al                   ;��ʾ��λСʱ���֣�ʹ�õ���ԭ��������

      mov al,':'
      mov [es:bx+4],al                   ;��ʾ�ָ���':'
      not byte [es:bx+5]                 ;��ת��ʾ���� 

      pop ax
      call bcd_to_ascii
      mov [es:bx+6],ah
      mov [es:bx+8],al                   ;��ʾ��λ��������

      mov al,':'
      mov [es:bx+10],al                  ;��ʾ�ָ���':'
      not byte [es:bx+11]                ;��ת��ʾ����

      pop ax
      call bcd_to_ascii
      mov [es:bx+12],ah
      mov [es:bx+14],al                  ;��ʾ��λСʱ����
      
      mov al,0x20                        ;�жϽ�������EOI 
      out 0xa0,al                        ;���Ƭ���� 
      out 0x20,al                        ;����Ƭ���� 

      pop es
      pop dx
      pop cx
      pop bx
      pop ax

      iret

;-------------------------------------------------------------------------------
bcd_to_ascii:                            ;BCD��תASCII
                                         ;���룺AL=bcd��
                                         ;�����AX=ascii
      mov ah,al                          ;�ֲ���������� 
      and al,0x0f                        ;��������4λ 
      add al,0x30                        ;ת����ASCII 

      shr ah,4                           ;�߼�����4λ 
      and ah,0x0f                        
      add ah,0x30

      ret

;-------------------------------------------------------------------------------
start:
      mov ax,[stack_segment]
      mov ss,ax                         ;��������ִ���κ�һ���ı�ջ�μĴ���ss��ָ��ʱ����������һ��ָ��ִ��������ֹ�жϣ�������mov ss,ss_pointer֮ǰ��ֹ�κ��ж�
      mov sp,ss_pointer                 ;��Ϊ�ж�������ջ�������ģ������ж�ʱҪѹ���־�Ĵ���cs��ip��Ȼ��תȥִ���жϴ�����̣�������Ҫ�������������أ���ss��sp֮���ж��ˣ����Ҳ���ѹ���cs'ip��
      mov ax,[data_segment]             ;���ԣ�ss��sp���밤������
      mov ds,ax
      ;��������ʾ�жϴ���Ҫ���Լ���ʵʱ�жϴ������ȡ��ϵͳ������Ĭ�ϵĴ�����̡��������ж��������а�װʵʱʱ���жϵ���ڵ�ַ
      mov bx,init_msg                    ;��ʾ��ʼ��Ϣ 
      call put_string

      mov bx,inst_msg                    ;��ʾ��װ��Ϣ 
      call put_string
      ;������ʾ2����ʾ��Ϣ�����������Ұ�װ�ж�������
      mov al,0x70
      mov bl,4                           ;0x70����4������0x70�ŵǼ���������ַ
      mul bl                             ;����0x70���ж���IVT�е�ƫ��
      mov bx,ax                          

      cli                                ;��ֹ�Ķ��ڼ䷢���µ�0x70���жϣ���������жϣ��Խ�ֹ�޸��������ڼ䴦������Ӧ�ж�
        ;�����������ж����������ڵĶΣ��޸�0x70���ж�����Ӧ�ı���
      push es                               ;�ж��������Ӧ�Ķε�ַ
      mov ax,0x0000                         ;�жϱ����ͼ�����00000-0ffff֮�䣬���Կɿ�����0000�Ķ�+�Լ������ַ�ɿ�����ƫ�Ƶ�ַ
      mov es,ax                             ;�ɿ����ж�������λ�ڶε�ַΪ0�Ķ���
      mov word [es:bx],new_int_0x70      ;ƫ�Ƶ�ַ���µ��жϴ�����̴Ӵ˴���ʼ
                                          
      mov word [es:bx+2],cs              ;д���жϴ�����̵Ķε�ַ���μĴ���cs�����ݾ��ǵ�ǰ����εĶε�ַ
      pop es

      mov al,0x0b                        ;RTC�Ĵ���B��Ҫ��ֹ������ʵʱ�ж��źţ�����ͨ���˿�0x70���ʼĴ���b
      or al,0x80                         ;���NMI 
      out 0x70,al
      mov al,0x12                        ;���üĴ���B����ֹ�������жϣ����Ÿ��½������жϣ�BCD�룬24Сʱ�� 
      out 0x71,al                        ;ͨ���˿�0x71����������÷��͸��Ĵ���B

      mov al,0x0c                        ;��Ϊ���û�н�0x0c�����λ��1���Ͼ��������һ�����������з���RTC
      out 0x70,al                        ;���������˿�0x70д���ͬʱ��Ӧ����������������NMI
      in al,0x71                         ;��RTC�Ĵ���C��ʹ֮��ʼ�����ж��źţ���λδ�����ж�״̬
      ;��ʱRTCоƬ������ϣ��ٴ�ͨ����8259A�����һ�����ϣ���������£�8259AоƬ�ǲ�������RTCоƬ�ģ�Ҫ�޸����ڲ����жϼĴ���IMR
      in al,0xa1                         ;��8259��Ƭ��IMR�Ĵ��� 
      and al,0xfe                        ;���bit 0(��λ����RTC)�����߼���ָ��and�����������
      out 0xa1,al                        ;д�ش˼Ĵ��� 

      sti                                ;���¿����ж� 

      mov bx,done_msg                    ;��ʾ��װ�����Ϣ 
      call put_string

      mov bx,tips_msg                    ;��ʾ��ʾ��Ϣ
      call put_string
      
      mov cx,0xb800
      mov ds,cx
      mov byte [12*160 + 33*2],'@'       ;��Ļ��12�У�35��
       
 .idle:
      hlt                                ;ʹCPU����͹���״̬��ֱ�����жϻ���
      not byte [12*160 + 33*2+1]         ;��ת��ʾ���� 
      jmp .idle

;-------------------------------------------------------------------------------
put_string:                              ;��ʾ��(0��β)��
                                         ;���룺DS:BX=����ַ
         mov cl,[bx]
         or cl,cl                        ;cl=0 ?
         jz .exit                        ;�ǵģ����������� 
         call put_char
         inc bx                          ;��һ���ַ� 
         jmp put_string

   .exit:
         ret

;-------------------------------------------------------------------------------
put_char:                                ;��ʾһ���ַ�
                                         ;���룺cl=�ַ�ascii
         push ax
         push bx
         push cx
         push dx
         push ds
         push es

         ;����ȡ��ǰ���λ��
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;��8λ 
         mov ah,al

         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;��8λ 
         mov bx,ax                       ;BX=������λ�õ�16λ��

         cmp cl,0x0d                     ;�س�����
         jnz .put_0a                     ;���ǡ������ǲ��ǻ��е��ַ� 
         mov ax,bx                       ; 
         mov bl,80                       
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

 .put_0a:
         cmp cl,0x0a                     ;���з���
         jnz .put_other                  ;���ǣ��Ǿ�������ʾ�ַ� 
         add bx,80
         jmp .roll_screen

 .put_other:                             ;������ʾ�ַ�
         mov ax,0xb800
         mov es,ax
         shl bx,1
         mov [es:bx],cl

         ;���½����λ���ƽ�һ���ַ�
         shr bx,1
         add bx,1

 .roll_screen:
         cmp bx,2000                     ;��곬����Ļ������
         jl .set_cursor

         mov ax,0xb800
         mov ds,ax
         mov es,ax
         cld
         mov si,0xa0
         mov di,0x00
         mov cx,1920
         rep movsw
         mov bx,3840                     ;�����Ļ���һ��
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
                   
    inst_msg       db 'Installing a new interrupt 70H...',0 ;���ڰ�װ�µ�70���жϴ������
    
    done_msg       db 'Done.',0x0d,0x0a,0

    tips_msg       db 'Clock is now working.',0
                   
;===============================================================================
SECTION stack align=16 vstart=0
           
                 resb 256
ss_pointer:
 
;===============================================================================
SECTION program_trail
program_end: