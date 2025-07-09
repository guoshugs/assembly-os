         ;�����嵥8-2
         ;�ļ�����c08.asm
         ;�ļ�˵�����û����� 
         ;�������ڣ�2011-5-5 18:17
         
;===============================================================================
SECTION header vstart=0                     ;�����û�����ͷ���� 
    program_length  dd program_end          ;�����ܳ���[0x00]
    
    ;�û�������ڵ�
    code_entry      dw start                ;ƫ�Ƶ�ַ[0x04]
                    dd section.code_1.start ;�ε�ַ[0x06] 
    
    realloc_tbl_len dw (header_end-code_1_segment)/4
                                            ;���ض�λ�������[0x0a]
    
    ;���ض�λ��           
    code_1_segment  dd section.code_1.start ;[0x0c]
    code_2_segment  dd section.code_2.start ;[0x10]
    data_1_segment  dd section.data_1.start ;[0x14]
    data_2_segment  dd section.data_2.start ;[0x18]
    stack_segment   dd section.stack.start  ;[0x1c]
    
    header_end:                
    
;===============================================================================
SECTION code_1 align=16 vstart=0         ;��������1��16�ֽڶ��룩 
put_string:                              ;��ʾ��(0��β)������ַ�������ʱ0��β��
                                         ;���룺DS:BX=����ַ
         mov cl,[bx]                     ;���Ǽ�������Ӱ�쵽��־�Ĵ����е�ĳЩλ��ZF��0��ȡ�õ��ǿ��ַ�0
         or cl,cl                        ;cl=0 ?��cmp cl,0ʱ��ֱ�۵ģ���������һ���������Լ��������㣬����������Լ�
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
         mov dx,0x3d4                    ;ͨ�������˿�3d4�����Կ�������Ҫ����0e�żĴ���
         mov al,0x0e
         out dx,al
         mov dx,0x3d5                    ;ͨ�����ݶ˿�3d5��0e�żĴ�������һ���ֽڵ�����
         in al,dx
         mov ah,al                       ;��al�еĴ��͵�ah�У���ʱ���λ�õĸ�8λ

         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;��8λ  
         mov bx,ax                       ;BX=������λ�õ�16λ������ax����bx����ʱ����
         ;һ��֪���˹���λ�ã�����ζ���ַ�����Ļ�ϵ���ʾλ��ȷ���ˣ��ַ���ͨ��cl����ģ�cl�����ַ��ı���
         cmp cl,0x0d                     ;�س�����
         jnz .put_0a                     ;���ǡ������ǲ��ǻ��е��ַ� 
         mov ax,bx                       ;�˾����Զ��࣬��ȥ���󻹵ø��飬�鷳 
         mov bl,80                       
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor
         ;�ڱ�׼VGA�ı�ģʽ�£�ÿ����25�У�ÿ����80�У�80���ַ���0-24��0-79
 .put_0a:
         cmp cl,0x0a                     ;���з���
         jnz .put_other                  ;���ǣ��Ǿ�������ʾ�ַ� 
         add bx,80
         jmp .roll_screen

 .put_other:                             ;������ʾ�ַ�
         mov ax,0xb800
         mov es,ax
         shl bx,1                        ;���ݹ��λ����ֵ�õ��ַ��Ķ���ƫ�Ƶ�ַ��1���ַ���Ӧ�Դ����2���ֽڵ���Ӧ����Ļ��1�����
         mov [es:bx],cl                  ;�����λ�ó���2�͵õ������Դ��ڲ���ƫ�Ƶ�ַ���߼�����

         ;���½����λ���ƽ�һ���ַ�
         shr bx,1
         add bx,1

 .roll_screen:
         cmp bx,2000                     ;��곬����Ļ������
         jl .set_cursor                  ;��Խ�磬�����ù��
         ;���¾��ǹ��������������Դ���������������
         push bx                         ;ԭ������޸ģ��Ƚ�bxλ�õ�����ѹջ���棬��Ϊ������������ݴ���Ҫ�õ�bx
         mov ax,0xb800
         mov ds,ax
         mov es,ax
         cld                             ;���÷����־������
         mov si,0xa0                     ;����ԭ�������ʼƫ�Ƶ�ַ0xa0��������ַ�Ĵ���si��
         mov di,0x00                     ;������Ŀ�������ƫ�Ƶ�ַ
         mov cx,1920
         rep movsw                       ;��������
         
         mov bx,3840                     ;�����Ļ���һ�У����һ������ߵ��ַ����Դ��е�ƫ�Ƶ�ַ��3840��д��80���ո�
         mov cx,80
 .cls:
         mov word[es:bx],0x0720          ;07�����ԣ�20�ǿո��ʮ�����Ʊ���
         add bx,2                        ;ָ����һ���ո�
         loop .cls

         ;mov bx,1920                    ;Ϊ���޸�ԭ����߼����⣬ɾ�����У�������2��
         pop bx                          ;��������ǹ�곬������Ļ�����½�����ģ����һ���ַ�1999�Ĺ����2000���������Ƶ����һ�е�����Ҳ��Ҫ��80
         sub bx,80                       ;��������ǻ�������ģ���ô���Ӧ�û������һ�е�ĳ��λ�ã���ǰ���Ѿ�����80�ˣ����Լ���

 .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         mov al,bh                       ;���λ�õ���ֵ�����ڼĴ���bx����д�˿�ֻ���üĴ���al
         out dx,al                       ;��ʾ���λ�õĸ�8λ
         mov dx,0x3d4                    ;ͨ��3d4�˿�ָ���Ĵ���0f
         mov al,0x0f
         out dx,al
         mov dx,0x3d5                    ;ͨ��3d5�˿���Ĵ���0fд����λ�õĵ�8λ
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
         ;��ʼִ��ʱ��DS��ESָ���û�����ͷ����
         mov ax,[stack_segment]           ;���õ��û������Լ��Ķ�ջ 
         mov ss,ax
         mov sp,stack_end
         
         mov ax,[data_1_segment]          ;���õ��û������Լ������ݶΣ���ʱֻ��es��ָ��ͷ����
         mov ds,ax

         mov bx,msg0
         call put_string                  ;��ʾ��һ����Ϣ 

         push word [es:code_2_segment]    ;es��ʱ��ָ��ͷ���Σ����ض�λ������ȡ��code2���߼��ε�ַ��ѹջ
         mov ax,begin                     ;��Ҫѹ��Ŀ��λ�õ�ƫ�Ƶ�ַ������begin�ڱ���׶εĻ���ַ����Ϊ��vstart=0�����ԴӶ��׿�ʼ���㣬8086�޷�����һ��������������ͨ��ax
         push ax                          ;����ֱ��push begin,80386+
         
         retf                             ;ת�Ƶ������2ִ�� return farģ��ԭ������ʵ�ֶμ�ת�ƣ���push code2���ʹ�ã���ת�Ƶ�code2ȥִ��
         
  continue:
         mov ax,[es:data_2_segment]       ;�μĴ���DS�л������ݶ�2 ��ds�ֱ��ˣ�es�Բ��䣬dsȡ�����ض�λ����data2���߼��ε�ַ
         mov ds,ax
         
         mov bx,msg1
         call put_string                  ;��ʾ�ڶ�����Ϣ 

         jmp $                            ;ͨ���û�����ִ����Ϻ�Ӧ�����½����Ʒ��ص����������������������Լ����������򣬵������mbr���������ṩ�������

;===============================================================================
SECTION code_2 align=16 vstart=0          ;��������2��16�ֽڶ��룩

  begin:
         push word [es:code_1_segment]    ;��retf���Ǽ�װ�ӹ��̷��أ���װ���������ӳ���es������ָ��header�ģ�����ѹջ�ľ����ض�λ����߼��ε�ַ
         mov ax,continue
         push ax                          ;����ֱ��push continue,80386+
         
         retf                             ;ת�Ƶ������1����ִ�� 
         
;===============================================================================
SECTION data_1 align=16 vstart=0                                ;��Ϊvstart=0������msg0�Ļ���ַ��0���ڳ�������ʱ���Ļ���ַҲ�����Ķ���ƫ�Ƶ�ַ

    msg0 db '  This is NASM - the famous Netwide Assembler. '
         db 'Back at SourceForge and in intensive development! '
         db 'Get the current versions from http://www.nasm.us/.'
         db 0x0d,0x0a,0x0d,0x0a                                 ;0x0d�ǻس���0x0a�ǻ��з�������ͼ���ַ����޷���ʾ��ֻ��ͨ������������            
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
         db 0                                                   ;0������־�ַ����Ľ��������ֱ���Ϊ0��ֹ�ַ���

;===============================================================================
SECTION data_2 align=16 vstart=0

    msg1 db '  The above contents is written by LeeChung. ' ;û�лس����У���һ����ʾ����������6�ĺ���
         db '2011-05-06'
         db 0

;===============================================================================
SECTION stack align=16 vstart=0
           
         resb 256

stack_end:  

;===============================================================================
SECTION trail align=16                      ;��Ҫ���ñ��program_end��һ��16���ƶ���Ļ���ַ    
program_end:                                ;��Ϊû��vstart=0�Ӿ䣬�������Ļ���ַ���ǳ�����ܳ��ȣ����ֽڼ�