         ;�����嵥����Ƶ����

         ;���³������岿�֡��ں˵Ĵ󲿷����ݶ�Ӧ���̶� 
         flat_4gb_code_seg_sel      equ  0x0008   ;ch17��ƽ̹ģ���µ�4GB�����ѡ����
         flat_4gb_data_seg_sel      equ  0x0018   ;ch17��ƽ̹ģ���µ�4GB���ݶ�ѡ���� 

         idt_linear_address     equ  0x8001F000   ;ch15-�жϣ��ж�������������Ե�ַ
         core_lin_alloc_at      equ  0x80100000   ;ch16���ں��п����ڷ������ʼ���Ե�ַ
         core_lin_tcb_addr      equ  0x8001f800   ;ch16���ں�����TCB�ĸ߶����Ե�ַ

;-------------------------------------------------------------------------------
         ;������ϵͳ���ĵ�ͷ�������ڼ��غ��ĳ���
SECTION header vstart=0x80040000

         core_length      dd core_end       ;���ĳ����ܳ���#00

         core_entry       dd start          ;���Ĵ������ڵ�#04

;===============================================================================
         [bits 32]
;===============================================================================
SECTION sys_routine vfollows=header         ;ϵͳ�������̴���� 
;-------------------------------------------------------------------------------
         ;�ַ�����ʾ���̣�������ƽ̹�ڴ�ģ�ͣ�
put_string:                                 ;��ʾ0��ֹ���ַ������ƶ���� 
                                            ;���룺EBX=�ַ��������Ե�ַ
                                            
         push ebx                           ;ch17
         push ecx
         
         cli                                ;ch15-�жϣ��������������ӡ�ж϶��������ź�
         
  .getc:
         mov cl,[ebx]
         or cl,cl
         jz .exit
         call put_char
         inc ebx
         jmp .getc

  .exit:
  
         sti                                ;ch15-�жϣ��������������ӡ�ж϶������ź�
         
         pop ecx
         pop ebx
         
         retf                               ;�μ䷵��

;-------------------------------------------------------------------------------
put_char:                                   ;�ڵ�ǰ��괦��ʾһ���ַ�,���ƽ�
                                            ;��ꡣ�����ڶ��ڵ��� 
                                            ;���룺CL=�ַ�ASCII�� 
         pushad

         ;����ȡ��ǰ���λ��
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;����
         mov ah,al

         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;����
         mov bx,ax                          ;BX=������λ�õ�16λ��
         and ebx,0x0000ffff                 ;ch17��׼��ʹ��32λѰַ��ʽ�����Դ�

         cmp cl,0x0d                        ;�س�����
         jnz .put_0a
         mov ax,bx
         mov bl,80
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

  .put_0a:
         cmp cl,0x0a                        ;���з���
         jnz .put_other
         add bx,80
         jmp .roll_screen

  .put_other:                               ;������ʾ�ַ�
         shl bx,1
         mov [0x800b8000+ebx],cl

         ;���½����λ���ƽ�һ���ַ�
         shr bx,1
         inc bx

  .roll_screen:
         cmp bx,2000                        ;��곬����Ļ������
         jl .set_cursor

         push bx                            ;Ϊ���޸�ԭ�������߼����⣬����
         
         cld
         mov esi,0x800b80a0                 ;ch17:С�ģ�32λģʽ��movsb/w/d 
         mov edi,0x800b8000                 ;ch17:ʹ�õ���esi/edi/ecx 
         mov ecx,1920
         rep movsd
         mov bx,3840                        ;�����Ļ���һ��
         mov ecx,80                         ;32λ����Ӧ��ʹ��ECX
  .cls:
         mov word[0x800b8000+ebx],0x0720    ;ch17
         add bx,2
         loop .cls

         ;mov bx,1920                       ;Ϊ���޸�ԭ�������߼����⣬ɾ��
         pop bx                             ;Ϊ���޸�ԭ�������߼����⣬����
         sub bx,80                          ;Ϊ���޸�ԭ�������߼����⣬����

  .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         mov al,bh
         out dx,al
         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         mov al,bl
         out dx,al

         popad
         ret
         
;-------------------------------------------------------------------------------
read_hard_disk_0:                           ;��Ӳ�̶�ȡһ���߼�����
                                            ;EAX=�߼�������
                                            ;EBX=Ŀ�껺������ַ
                                            ;���أ�EBX=EBX+512
         cli                                ;ch17
         
         push eax 
         push ecx
         push edx
      
         push eax
                  
         mov dx,0x1f2
         mov al,1
         out dx,al                          ;��ȡ��������

         inc dx                             ;0x1f3
         pop eax
         out dx,al                          ;LBA��ַ7~0

         inc dx                             ;0x1f4
         mov cl,8
         shr eax,cl
         out dx,al                          ;LBA��ַ15~8

         inc dx                             ;0x1f5
         shr eax,cl
         out dx,al                          ;LBA��ַ23~16

         inc dx                             ;0x1f6
         shr eax,cl
         or al,0xe0                         ;��һӲ��  LBA��ַ27~24
         out dx,al

         inc dx                             ;0x1f7
         mov al,0x20                        ;������
         out dx,al

  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                         ;��æ����Ӳ����׼�������ݴ��� 

         mov ecx,256                        ;�ܹ�Ҫ��ȡ������
         mov dx,0x1f0
  .readw:
         in ax,dx
         mov [ebx],ax
         add ebx,2
         loop .readw

         pop edx
         pop ecx
         pop eax
         
         sti                                ;ch16����ҳ�޸�
      
         retf                               ;�μ䷵�� 

;-------------------------------------------------------------------------------
;������Գ����Ǽ���һ�γɹ������ҵ��Էǳ����ѡ�������̿����ṩ���� 
put_hex_dword:                              ;�ڵ�ǰ��괦��ʮ��������ʽ��ʾ
                                            ;һ��˫�ֲ��ƽ���� 
                                            ;���룺EDX=Ҫת������ʾ������
                                            ;�������
         pushad
      
         mov ebx,bin_hex                    ;ָ��������ݶ��ڵ�ת����
         mov ecx,8
  .xlt:    
         rol edx,4
         mov eax,edx
         and eax,0x0000000f
         xlat
      
         push ecx
         mov cl,al                           
         call put_char
         pop ecx
       
         loop .xlt
      
         popad
         retf

;-------------------------------------------------------------------------------
set_up_gdt_descriptor:                      ;��GDT�ڰ�װһ���µ�������
                                            ;���룺EDX:EAX=������ 
                                            ;�����CX=��������ѡ����
         push eax
         push ebx
         push edx

         sgdt [pgdt]                        ;�Ա㿪ʼ����GDT

         movzx ebx,word [pgdt]              ;GDT���� 
         inc bx                             ;GDT���ֽ�����Ҳ����һ��������ƫ�� 
         add ebx,[pgdt+2]                   ;��һ�������������Ե�ַ 
      
         mov [ebx],eax
         mov [ebx+4],edx
      
         add word [pgdt],8                  ;����һ���������Ĵ�С   
      
         lgdt [pgdt]                        ;��GDT�ĸ�����Ч 
       
         mov ax,[pgdt]                      ;�õ�GDT����ֵ
         xor dx,dx
         mov bx,8
         div bx                             ;����8��ȥ������
         mov cx,ax                          
         shl cx,3                           ;���������Ƶ���ȷλ�� 

         pop edx
         pop ebx
         pop eax
      
         retf
;-------------------------------------------------------------------------------
make_seg_descriptor:                        ;����洢����ϵͳ�Ķ�������
                                            ;���룺EAX=���Ի���ַ
                                            ;      EBX=�ν���
                                            ;      ECX=���ԡ�������λ����ԭʼ
                                            ;          λ�ã��޹ص�λ���� 
                                            ;���أ�EDX:EAX=������
         mov edx,eax
         shl eax,16
         or ax,bx                           ;������ǰ32λ(EAX)�������

         and edx,0xffff0000                 ;�������ַ���޹ص�λ
         rol edx,8
         bswap edx                          ;װ���ַ��31~24��23~16  (80486+)

         xor bx,bx
         or edx,ebx                         ;װ��ν��޵ĸ�4λ

         or edx,ecx                         ;װ������

         retf
         
;-------------------------------------------------------------------------------
make_gate_descriptor:                       ;ch14�������ŵ��������������ŵȣ�
                                            ;���룺EAX=�Ŵ����ڶ���ƫ�Ƶ�ַ
                                            ;       BX=�Ŵ������ڶε�ѡ���� 
                                            ;       CX=�����ͼ����Եȣ�����
                                            ;          ��λ����ԭʼλ�ã�
                                            ;���أ�EDX:EAX=������������
         push ebx
         push ecx
      
         mov edx,eax
         and edx,0xffff0000                 ;ch15-�жϣ��޸�
         or dx,cx                           ;ch15-�жϣ��޸ģ���װ�����ŵĸ�˫�ֲ���
       
         and eax,0x0000ffff                 ;�õ�ƫ�Ƶ�ַ��16λ 
         shl ebx,16                          
         or eax,ebx                         ;��װ��ѡ���Ӳ���
      
         pop ecx
         pop ebx
      
         retf             

;-------------------------------------------------------------------------------
allocate_a_4k_page:                         ;����һ��4KB��ҳ
                                            ;���룺��
                                            ;�����EAX=ҳ�������ַ
         push ebx
         push ecx
         push edx
         
         xor eax,eax
  .b1:
         bts [page_bit_map],eax
         jnc .b2
         inc eax
         cmp eax,page_map_len*8
         jl .b1
         
         mov ebx,message_3
         call flat_4gb_code_seg_sel:put_string
         hlt                                ;û�п��Է����ҳ��ͣ��
         
  .b2:
         shl eax,12                         ;����4096��0x1000��
         
         pop edx
         pop ecx
         pop ebx
         
         ret
    
;-------------------------------------------------------------------------------
alloc_inst_a_page:                          ;ch16-��ҳ������һ��ҳ������װ�ڵ�ǰ���
                                            ;�㼶��ҳ�ṹ��
                                            ;���룺EBX=ҳ�����Ե�ַ
         push eax
         push ebx
         push ecx
         push esi
         
         ;�������Ե�ַ����Ӧ��ҳ���Ƿ����
         mov esi,ebx
         and esi,0xffc00000                 ;���ҳ��������ҳ��ƫ�Ʋ���
         shr esi,20                         ;��ҳĿ¼��������4��Ϊҳ��ƫ��
         or esi,0xfffff000                  ;ҳĿ¼��������Ե�ַ+����ƫ��
         
         test dword [esi],0x00000001        ;Pλ�Ƿ�Ϊ��1�����������Ե�ַ�Ƿ�
         jnz .b1                            ;�Ѿ��ж�Ӧ��ҳ��
         
         ;��������װ�����Ե�ַ����Ӧ��ҳ��
         call allocate_a_4k_page            ;����һ��ҳ��Ϊҳ��
         or eax,0x00000007
         mov [esi],eax                      ;��ҳĿ¼�еǼǸ�ҳ��
         
         ;��յ�ǰҳ��
         mov eax,ebx
         and eax,0xffc00000
         shr eax,10
         or eax,0xffc00000
         mov ecx,1024
  .cls0:
         mov dword [eax],0x00000000
         add eax,4
         loop .cls0
         
  .b1:
         ;�������Ե�ַ��Ӧ��ҳ���ҳ���Ƿ����
         mov esi,ebx
         and esi,0xfffff000                 ;���ҳ��ƫ�Ʋ���
         shr esi,10                         ;��ҳĿ¼�������ҳ��������ҳ����������4��Ϊҳ��ƫ��
         or esi,0xffc00000                  ;�õ������Ե�ַ��Ӧ��ҳ����
         
         test dword [esi],0x00000001        ;Pλ�Ƿ�Ϊ��1�����������Ե�ַ�Ƿ�
         jnz .b2                            ;�Ѿ��ж�Ӧ��ҳ
         
         ;��������װ�����Ե�ַ����Ӧ��ҳ
         call allocate_a_4k_page            ;����һ��ҳ�������Ҫ��װ��ҳ
         or eax,0x00000007
         mov [esi],eax
         
  .b2:
         pop esi
         pop ecx
         pop ebx
         pop eax
         
         retf

;-------------------------------------------------------------------------------
create_copy_cur_pdir:                       ;ch16-��ҳ��������Ŀ¼ҳ�������Ƶ�ǰҳĿ¼����
                                            ;���룺��
                                            ;�����EAX=��ҳĿ¼�������ַ
         push esi
         push edi
         push ebx
         push ecx
         
         call allocate_a_4k_page
         mov ebx,eax
         or ebx,0x00000007
         mov [0xfffffff8],ebx
         
         invlpg [0xfffffff8]
         
         mov esi,0xfffff000                 ;ESI->��ǰҳĿ¼�����Ե�ַ
         mov edi,0xffffe000                 ;EDI->��ҳĿ¼�����Ե�ַ
         mov ecx,1024                       ;ECX=Ҫ���Ƶ�Ŀ¼����
         cld
         repe movsd
         
         pop ecx
         pop ebx
         pop edi
         pop esi
         
         retf

;-------------------------------------------------------------------------------
task_alloc_memory:                          ;ch16-��ҳ����ָ������������ڴ�ռ��з����ڴ�
                                            ;���룺EBX=������ƿ�TCB�����Ե�ַ
                                            ;      ECX=ϣ��������ֽ���
                                            ;�����ECX=�ѷ������ʼ���Ե�ַ
         push eax
         
         push ebx                           ;to A
         
         ;��ñ����ڴ�������ʼ���Ե�ַ
         mov ebx,[ebx+0x46]                 ;��ñ��η������ʼ���Ե�ַ
         mov eax,ebx
         add ecx,ebx                        ;���η��䣬���һ���ֽ�֮������Ե�ַ
         
         push ecx                           ;to B
         
         ;Ϊ������ڴ����ҳ
         and ebx,0xfffff000
         and ecx,0xfffff000
  .next:
         call flat_4gb_code_seg_sel:alloc_inst_a_page   ;ch17
                                            ;��װ��ǰ���Ե�ַ���ڵ�ҳ
         add ebx,0x1000                     ;+4096
         cmp ebx,ecx
         jle .next
         
         ;��������һ�η�������Ե�ַǿ�ư�4�ֽڶ���
         pop ecx                            ;B
         
         test ecx,0x00000003                ;���Ե�ַ��4�ֽڶ������
         jz .algn                           ;�ǣ�ֱ�ӷ���
         and ecx,4                          ;��ǿ�ư�4�ֽڶ���
         and ecx,0xfffffffc
         
  .algn:
         pop ebx                            ;A
         
         mov [ebx+0x46],ecx                 ;���´η�����õ����Ե�ַ�ش浽TCB��
         mov ecx,eax

         pop eax
         
         retf
         
;-------------------------------------------------------------------------------
allocate_memory:                            ;ch16��ҳ���ڵ�ǰ����ĵ�ַ�ռ��з����ڴ�
                                            ;���룺ECX=ϣ��������ֽ���
                                            ;�����ECX=��ʼ���Ե�ַ
         push eax
         push ebx
         
         ;�õ� TCB�����׽ڵ�����Ե�ַ
         mov eax,[tcb_chain]                ;ch16��EAX=�׽ڵ�����Ե�ַ
         
         ;����״̬Ϊæ����ǰ���񣩵Ľڵ�
  .s0:
         cmp word [eax+0x04],0xffff
         jz .s1                             ;�ҵ�æ�Ľڵ㣬EAX=�ڵ�����Ե�ַ
         mov eax,[eax]
         jmp .s0
         
         ;��ʼ�����ڴ�
  .s1:
         mov ebx,eax
         call flat_4gb_code_seg_sel:task_alloc_memory
         
         pop ebx
         pop eax

         retf

;-------------------------------------------------------------------------------
initiate_task_switch:                       ;ch15���������������л�
                                            ;���룺��
                                            ;������ޡ������أ����������л����ء�
         pushad
         
         mov eax,[tcb_chain]
         cmp eax,0                          ;ch15-�жϣ��޸ġ��ж�TCB�����Ƿ�Ϊ��
         jz .return                         ;ch15-�жϣ��޸ġ����Ϊ���򷵻�
         
         ;����״̬Ϊæ����ǰ���񣩵Ľڵ�
  .b0:
         cmp word [eax+0x04],0xffff
         cmove esi,eax                      ;�ҵ�æ�Ľڵ㣬ESI=�ڵ�����Ե�ַ
         jz .b1
         mov eax,[eax]
         jmp .b0
         
         ;�ӵ�ǰ�ڵ����������������Ľڵ�
  .b1:
         mov ebx,[eax]
         or ebx,ebx
         jz .b2                             ;������β��Ҳδ���־����ڵ㣬��ͷ��
         cmp word [ebx+0x04],0x0000
         cmove edi,ebx                      ;���ҵ������ڵ㣬EDI=�ڵ�����Ե�ַ
         jz .b3
         mov eax,ebx
         jmp .b1

  .b2:
         mov ebx,[tcb_chain]                ;EBX=�����׽ڵ����Ե�ַ
  .b20:
         cmp word [ebx+0x04],0x0000
         cmove edi,ebx                      ;���ҵ������ڵ㣬EDI=�ڵ�����Ե�ַ
         jz .b3
         mov ebx,[ebx]
         or ebx,ebx
         jz .return                         ;ch15:�������Ѿ������ڿ������񣬷���4*4
         jmp .b20
         
         ;��������Ľڵ��Ѿ��ҵ���׼���л���������
  .b3:
         not word [esi+0x04]                ;��æ״̬�Ľڵ��Ϊ����״̬�Ľڵ�
         not word [edi+0x04]                ;������״̬�Ľڵ��Ϊæ״̬�Ľڵ�
         jmp far [edi+0x14]                 ;�����л�
         
  .return:
         popad
         
         retf
         
;-------------------------------------------------------------------------------
terminate_current_task:                     ;��ֹ��ǰ����
                                            ;ע�⣺ִ�д�����ʱ����ǰ��������
                                            ;�����С���������ʼҲ�ǵ�ǰ�����
                                            ;һ����
         mov eax,[es:tcb_chain]
                                            ;EAX=�׽ڵ�����Ե�ַ
         ;����״̬Ϊæ����ǰ���񣩵Ľڵ�
  .s0:
         cmp word [eax+0x04],0xffff  
         jz .s1                             ;�ҵ�æ�Ľڵ㣬EAX=�ڵ�����Ե�ַ
         mov eax,[eax]
         jmp .s0
         
         ;��״̬Ϊæ�Ľڵ�ĳ���ֹ״̬
  .s1:
         mov word [eax+0x04],0x3333
  
         ;��������״̬������
         mov ebx,[es:tcb_chain]             ;EBX=�����׽ڵ�����Ե�ַ
  .s2:
         cmp word [ebx+0x04],0x0000
         jz .s3                             ;���ҵ������ڵ㣬EBX=�����׽ڵ�����Ե�ַ
         mov ebx,[ebx]
         jmp .s2
         
         ;��������Ľڵ��Ѿ��ҵ���׼���л���������
  .s3: 
         not word [ebx+0x04]                ;������״̬�Ľڵ��Ϊæ״̬�Ľڵ�
         jmp far [ebx+0x14]                 ;�����л�
         
;-------------------------------------------------------------------------------
general_interrupt_handler:                  ;ch15-�жϣ�ͨ�õ��жϴ������
         push eax
         
         mov al,0x20                        ;�жϽ�������EOI
         out 0xa0,al                        ;���Ƭ����
         out 0x20,al                        ;����Ƭ����
         
         pop eax
         
         iretd
         
;-------------------------------------------------------------------------------
general_exception_handler:                  ;ch15-�жϣ�ͨ�õ��쳣�������
         mov ebx,excep_msg
         call flat_4gb_code_seg_sel:put_string
         
         cli                                ;ch16����ҳ���޸�
         
         hlt

;-------------------------------------------------------------------------------
rtm_0x70_interrupt_handle:                  ;ch15-�жϣ�ʵʱʱ���жϴ������

         pushad
         
         mov al,0x20                        ;�жϽ�������EOI
         out 0xa0,al                        ;��8259A��Ƭ����
         out 0x20,al                        ;��8259A��Ƭ����
         
         mov al,0x0c                        ;�Ĵ���C���������ҿ���NMI
         out 0x70,al
         in al,0x71                         ;������RTC�ļĴ���C������ֻ����һ���ж�
                                            ;�˴����������Ӻ��������жϵ����
         ;�����������
         call flat_4gb_code_seg_sel:initiate_task_switch
         
         popad
         
         iretd

;-------------------------------------------------------------------------------
do_task_clean:                              ;�����Ѿ���ֹ�����񲢻�����Դ

         ;����TCB�����ҵ�״̬Ϊ��ֹ�Ľڵ�
         ;���ڵ�������в��
         ;��������ռ�õĸ�����Դ�����Դ�����TCB���ҵ���
         
         retf
                 
sys_routine_end:

;===============================================================================
SECTION core_data vfollows=sys_routine      ;ϵͳ���ĵ����ݶ�
;-------------------------------------------------------------------------------
         pgdt             dw  0             ;�������ú��޸�GDT 
                          dd  0

         pidt             dw  0             ;ch15-�жϣ��������ú��޸�IDT 
                          dd  0
         ;ram_alloc        dd  0x00100000    ;�´η����ڴ�ʱ����ʼ��ַ
         page_bit_map     db  0xff,0xff,0xff,0xff,0xff,0xff,0x55,0x55
                          db  0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
                          db  0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
                          db  0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
                          db  0x55,0x55,0x55,0x55,0x55,0x55,0x55,0x55
                          db  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
                          db  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
                          db  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
         page_map_len     equ $-page_bit_map
         
         ;���ŵ�ַ������
         salt:
         salt_1           db  '@PrintString'    ;�ں˵�salt��ÿһ����Ŀ������262���ֽ�
                     times 256-($-salt_1) db 0
                          dd  put_string
                          dw  flat_4gb_code_seg_sel

         salt_2           db  '@ReadDiskData'   ;��1���������������256���ֽ�
                     times 256-($-salt_2) db 0
                          dd  read_hard_disk_0  ;��2���������̵���ڵ�ַ6���ֽڣ�������ѡ���ӺͶ���ƫ����
                          dw  flat_4gb_code_seg_sel

         salt_3           db  '@PrintDwordAsHexString'
                     times 256-($-salt_3) db 0
                          dd  put_hex_dword
                          dw  flat_4gb_code_seg_sel

         salt_4           db  '@TerminateProgram'   ;ch15�޸�
                     times 256-($-salt_4) db 0
                          dd  terminate_current_task
                          dw  flat_4gb_code_seg_sel
                          
         salt_5           db  '@InitTaskSwitch'     ;ch15�����������л�
                     times 256-($-salt_5) db 0
                          dd  initiate_task_switch
                          dw  flat_4gb_code_seg_sel
                          
         salt_6           db  '@malloc'     ;ch16����ҳ
                     times 256-($-salt_6) db 0
                          dd  allocate_memory
                          dw  flat_4gb_code_seg_sel

         salt_item_len   equ $-salt_6               ;������ռ�ÿռ䣬����ÿ����Ŀ�ĳ��ȣ�������262���ֽڣ�ÿ����Ŀ�ֽ���ͬ
         salt_items      equ ($-salt)/salt_item_len ;������е���Ŀ����������4����Ŀ

         message_0        db  '   System core is running in protected mode'     ;ch16����ҳ���޸�
                          db  'IDT is mounted.',0x0d,0x0a,0
                          
         cpu_brnd0        db 0x0d,0x0a,'  ',0
         cpu_brand  times 52 db 0           ;��192���иĳ���49����217�θĻ���52
         cpu_brnd1        db 0x0d,0x0a,0x0d,0x0a,0
                          
         message_1        db  '  Paging is enabled. System core is mapped to'   ;ch16����ҳ���޸�
                          db  ' linear address 0x80000000.',0x0d,0x0a,0
                          
         message_2        db  '  System wide CALL-GATE mounted and test OK.'    ;ch16����ҳ���޸�
                          db  0x0d,0x0a,0
         
         message_3        db  '********No more pages********',0                 ;ch16����ҳ���޸�
         
         excep_msg        db  '********Exception encountered********',0         ;ch15-�жϣ��޸�
                     
         bin_hex          db  '0123456789ABCDEF'
                                            ;put_hex_dword�ӹ����õĲ��ұ�

         core_buf   times 2048 db 0         ;�ں��õĻ�����

         ;������ƿ���
         tcb_chain        dd  0
         
         core_msg1        db  'Core task created',0x0d,0x0a,0   ;ch15-�жϣ��޸ģ����������л�
                          
         core_msg2        db  '[CORE TASK]: I am working!',0x0d,0x0a,0

core_data_end:

;===============================================================================
SECTION core_code vfollows=core_data
;-------------------------------------------------------------------------------
fill_descriptor_in_ldt:                     ;��LDT�ڰ�װһ���µ�������
                                            ;���룺EDX:EAX=������
                                            ;          EBX=TCB����ַ
                                            ;�����CX=��������ѡ����
         push eax
         push edx
         push edi

         mov edi,[ebx+0x0c]                 ;���LDT����ַ
         
         xor ecx,ecx
         mov cx,[ebx+0x0a]                  ;���LDT����
         inc cx                             ;LDT�����ֽ���������������ƫ�Ƶ�ַ
         
         mov [edi+ecx+0x00],eax
         mov [edi+ecx+0x04],edx             ;��װ������

         add cx,8                           
         dec cx                             ;�õ��µ�LDT����ֵ 

         mov [ebx+0x0a],cx                  ;����LDT����ֵ��TCB

         mov ax,cx
         xor dx,dx
         mov cx,8
         div cx
         
         mov cx,ax
         shl cx,3                           ;����3λ������
         or cx,0000_0000_0000_0100B         ;ʹTIλ=1��ָ��LDT�����ʹRPL=00 

         pop edi
         pop edx
         pop eax
     
         ret
      
;------------------------------------------------------------------------------- 
load_relocate_program:                      ;���ز��ض�λ�û�����
                                            ;���룺PUSH �߼�������
                                            ;      PUSH ������ƿ����ַ
                                            ;������� 
         pushad
         
         mov ebp,esp                        ;Ϊ����ͨ����ջ���ݵĲ�����׼��

         ;ch16:��յ�ǰҳĿ¼��ǰ�벿�֣���Ӧ��2GB�ľֲ���ַ�ռ䣩
         mov ebx,0xfffff000
         xor esi,esi
  .clsp:
         mov dword [ebx+esi*4],0x00000000 
         inc esi
         cmp esi,512
         jl .clsp
         
         mov ebx,cr3                        ;ˢ��TLB
         mov cr3,ebx
         
         ;���¿�ʼ�����û�����
         mov eax,[ebp+10*4]                  ;ch17:�Ӷ�ջ��ȡ���û�������ʼ������
         mov ebx,core_buf                    ;��ȡ����ͷ������    
         call flat_4gb_code_seg_sel:read_hard_disk_0

         ;�����ж����������ж��
         mov eax,[core_buf]                 ;����ߴ�
         mov ebx,eax
         and ebx,0xfffffe00                 ;ʹ֮512�ֽڶ��루�ܱ�512���������� 
         add ebx,512                        ;��9λ��Ϊ0 
         test eax,0x000001ff                ;����Ĵ�С������512�ı�����? 
         cmovnz eax,ebx                     ;���ǡ�ʹ�ô����Ľ��
         
         mov esi,[ebp+9*4]                 ;ch17:�Ӷ�ջ��ȡ��TCB�Ļ���ַ
      
         mov ecx,eax                        ;ʵ����Ҫ������ڴ�����
         mov ebx,esi                        ;ch16����ҳ���޸�
         call flat_4gb_code_seg_sel:task_alloc_memory ;ch16����ҳ���޸�
         
         mov ebx,ecx                        ;ebx -> ���뵽���ڴ��׵�ַ
         xor edx,edx                        ;����4�м����û�����ռ�õ���������
         mov ecx,512
         div ecx
         mov ecx,eax                        ;�������� 

         mov eax,[ebp+10*4]                 ;��ʼ������ 
  .b1:
         call flat_4gb_code_seg_sel:read_hard_disk_0
         inc eax
         loop .b1                           ;ѭ������ֱ�����������û�����

         ;ch17:��λ�ã������û������TSS
         mov ecx,104                        ;tss�Ļ����ߴ�
         mov [esi+0x12],cx
         dec word [esi+0x12]             ;�Ǽ�TSS����ֵ��TCB
         call flat_4gb_code_seg_sel:allocate_memory
         mov [esi+0x14],ecx              ;�Ǽ�TSS����ַ��TCB
         
         ;�������봴��LDT����Ҫ���ڴ�
         mov ebx,esi                        ;ch16����ҳ���޸�
         mov ecx,160                        ;����װ20��LDT������
         call flat_4gb_code_seg_sel:task_alloc_memory ;ch16����ҳ���޸�
         mov [esi+0x0c],ecx              ;�Ǽ�LDT����ַ��TCB��
         mov word [esi+0x0a],0xffff      ;�Ǽ�LDT��ʼ�Ľ��޵�TCB��


         ;ch17:�����û���������������
         mov eax,0x00000000
         mov ebx,0x000fffff
         mov ecx,0x00c0f800                 ;�ֽ����ȵĴ��������������Ȩ��3
         call flat_4gb_code_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0011B         ;ch14������ѡ���ӵ���Ȩ��Ϊ3
         
         mov ebx,[esi+0x14]                 ;ch17����TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+76],cx                    ;��дTSS��CS��
         
         ;ch17�������û��������ݶ�������
         mov eax,0x00000000
         mov ebx,0x000fffff
         mov ecx,0x00c0f200                 ;�ֽ����ȵ����ݶ�����������Ȩ��3
         call flat_4gb_code_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0011B         ;ch14������ѡ���ӵ���Ȩ��Ϊ3
         
         mov ebx,[esi+0x14]                 ;ch17����TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+84],cx                    ;��дTSS��DS��
         mov [ebx+72],cx                    ;��дTSS��ES��
         mov [ebx+88],cx                    ;��дTSS��FS��
         mov [ebx+92],cx                    ;��дTSS��GS��
         
         ;ch17:Ϊ�û�����ջ�η���ռ�
         mov ebx,esi
         mov ecx,4096                       ;4KB�Ŀռ�
         call flat_4gb_code_seg_sel:task_alloc_memory

         ;ch17�������û�����ջ��������
         mov eax,0x00000000
         mov ebx,0x000fffff
         mov ecx,0x00c0f200                 ;�ֽ����ȵ����ݶ�����������Ȩ��3
         call flat_4gb_code_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0011B         ;ch14������ѡ���ӵ���Ȩ��Ϊ3
         
         mov ebx,[esi+0x14]                 ;ch17����TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+80],cx                    ;��дTSS��SS��
         mov edx,[esi+0x06]                 ;ch17����ջ�ĸ߶����Ե�ַ=��һ�ɷ����ַ
         mov [ebx+56],edx                   ;��дTSS��ESP��
         
         ;�ض�λSALT��ediһ��ʼָ���û�������ص���ʼλ�ã�+4λ�÷��õ���ͷ����ѡ���ӣ�[]����ȡ�����ֵ
         cld
         ;Ҫ�ճ�es:edi�����ʽ��ͷ����ƫ��24��λ��ȡֵ����ecx��ֱ��ָ��28��ƫ����
         mov ecx,[0x0c]                     ;ch17:�û������SALT��Ŀ����ͨ������4GB��ȡ��
         mov edi,[0x08]                     ;ch17:U-SALT��4GB���ڵ�ƫ��
  .b2: 
         push ecx
         push edi
      
         mov ecx,salt_items
         mov esi,salt
  .b3:
         push edi
         push esi
         push ecx

         mov ecx,64                         ;�������У�ÿ��Ŀ�ıȽϴ��� 
         repe cmpsd                         ;ÿ�αȽ�4�ֽ� 
         jnz .b4
         mov eax,[esi]                      ;��ƥ�䣬��esiǡ��ָ�����ĵ�ַ
         mov [es:edi-256],eax               ;���ַ�����д��ƫ�Ƶ�ַ 
         mov ax,[esi+4]
         or ax,0000000000000011B            ;ch14�����û������Լ�����Ȩ��ʹ�õ�����
                                            ;��RPL=3
         mov [es:edi-252],ax                ;���������ѡ���� 
  .b4:
      
         pop ecx
         pop esi
         add esi,salt_item_len
         pop edi                            ;��ͷ�Ƚ� 
         loop .b3
      
         pop edi
         add edi,256
         pop ecx
         loop .b2
         
         mov esi,[ebp+9*4]                  ;�Ӷ�ջ��ȡ��TCB�Ļ���ַ
          
         ;ch17�����û�����ľֲ���ַ�ռ��ڴ���0��Ȩ����ջ
         mov ebx,esi
         mov ecx,4096                       ;4KB�Ŀռ�
         call flat_4gb_code_seg_sel:task_alloc_memory

         mov eax,0x00000000
         mov ebx,0x000fffff
         mov ecx,0x00c09200                 ;�ֽ����ȵ����ݶ�����������Ȩ��0
         call flat_4gb_code_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0000B         ;ch14������ѡ���ӵ���Ȩ��Ϊ0
         
         mov ebx,[esi+0x14]                 ;ch17����TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+8],cx                    ;��дTSS��SS��
         mov edx,[esi+0x06]                 ;ch17����ջ�ĸ߶����Ե�ַ=��һ�ɷ����ַ
         mov [ebx+4],edx                   ;��дTSS��ESP��
      
         ;ch17�����û�����ľֲ���ַ�ռ��ڴ���1��Ȩ����ջ
         mov ebx,esi
         mov ecx,4096                       ;4KB�Ŀռ�
         call flat_4gb_code_seg_sel:task_alloc_memory

         mov eax,0x00000000
         mov ebx,0x000fffff
         mov ecx,0x00c0b200                 ;�ֽ����ȵ����ݶ�����������Ȩ��1
         call flat_4gb_code_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0001B         ;ch14������ѡ���ӵ���Ȩ��Ϊ1
         
         mov ebx,[esi+0x14]                 ;ch17����TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+16],cx                    ;��дTSS��SS��
         mov edx,[esi+0x06]                 ;ch17����ջ�ĸ߶����Ե�ַ=��һ�ɷ����ַ
         mov [ebx+12],edx                   ;��дTSS��ESP��
         
         ;ch17�����û�����ľֲ���ַ�ռ��ڴ���2��Ȩ����ջ
         mov ebx,esi
         mov ecx,4096                       ;4KB�Ŀռ�
         call flat_4gb_code_seg_sel:task_alloc_memory

         mov eax,0x00000000
         mov ebx,0x000fffff
         mov ecx,0x00c0d200                 ;�ֽ����ȵ����ݶ�����������Ȩ��2
         call flat_4gb_code_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0010B         ;ch14������ѡ���ӵ���Ȩ��Ϊ2
         
         mov ebx,[esi+0x14]                 ;ch17����TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+24],cx                    ;��дTSS��SS��
         mov edx,[esi+0x06]                 ;ch17����ջ�ĸ߶����Ե�ַ=��һ�ɷ����ַ
         mov [ebx+20],edx                   ;��дTSS��ESP��
         
         ;��GDT�еǼ�LDT������
         mov eax,[esi+0x0c]              ;LDT����ʼ���Ե�ַ
         movzx ebx,word [esi+0x0a]       ;LDT�ν���
         mov ecx,0x00008200                 ;LDT����������Ȩ��0��֮ǰ��00408200
         call flat_4gb_code_seg_sel:make_seg_descriptor
         call flat_4gb_code_seg_sel:set_up_gdt_descriptor
         mov [esi+0x10],cx               ;�Ǽ�LDTѡ���ӵ�TCB��
         

         ;ch17���Ǽǻ�����TSS�������
         mov ebx,[esi+0x14]                 ;ch17����TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+96],cx                    ;��дTSS��LDT��
         
         mov word [ebx+0],0                 ;ch15:������=0
         
         mov dx,[esi+0x12]                  ;�γ��ȣ����ޣ�
         mov [ebx+102],dx                   ;��дTSS��I/Oλͼƫ��
         
         mov word [ebx+100],0               ;T=0
         
         mov eax,[0x04]                     ;ch17�������4GB��ַ�ռ��ȡ��ڵ�
         mov [ebx+32],eax                   ;��дTSS��EIP��
         
         pushfd         
         pop dword [ecx+36]                 ;EFLAGS
         
         ;��GDT�еǼ�TSS������
         mov eax,[esi+0x14]                 ;TSS����ʼ���Ե�ַ
         movzx ebx,word [esi+0x12]          ;�γ��ȣ����ޣ�
         mov ecx,0x00008900                 ;TSS����������Ȩ��0��֮���ĳ�00408900
         call flat_4gb_code_seg_sel:make_seg_descriptor
         call flat_4gb_code_seg_sel:set_up_gdt_descriptor
         mov [esi+0x18],cx                  ;�Ǽ�TSSѡ���ӵ�TCB
         
         ;ch16:�����û������ҳĿ¼
         ;ע�⣡ҳ�ķ����ʹ������ҳλͼ�����ģ����Բ�ռ�����Ե�ַ�ռ�
         call flat_4gb_code_seg_sel:create_copy_cur_pdir
         mov ebx,[esi+0x14]              ;��TCB�л�ȡTSS�����Ե�ַ
         mov dword [ebx+28],eax          ;��дTSS��CR3��PDBR����
      
         popad
      
         ret 8                              ;�������ñ�����ǰѹ��Ĳ���
   
;-------------------------------------------------------------------------------
append_to_tcb_link:                         ;��TCB����׷��������ƿ�
                                            ;���룺ECX=TCB���Ի���ַ
         push eax
         push edx

         cli                                ;ch16����ҳ���޸�

         mov dword [ecx+0x00],0         ;��ǰTCBָ��������
                                            ;��ָʾ�������һ��TCB
                                             
         mov eax,[tcb_chain]                ;TCB��ͷָ��
         or eax,eax                         ;����Ϊ�գ�
         jz .notcb 
         
  .searc:
         mov edx,eax
         mov eax,[edx+0x00]
         or eax,eax               
         jnz .searc
         
         mov [es: edx+0x00],ecx
         jmp .retpc
         
  .notcb:       
         mov [tcb_chain],ecx                ;��Ϊ�ձ�ֱ�����ͷָ��ָ��TCB
         
  .retpc:
         sti                                ;ch16����ҳ���޸�

         pop edx
         pop eax
         
         ret

;-------------------------------------------------------------------------------
start:
         ;ch15-�жϣ������ж���������IDT
         ;ע�⣡�ڴ��ڼ䣬���ÿ����жϣ�Ҳ���õ���put_string���̣�
         
         ;ch15-�жϣ�ǰ20�������Ǵ������쳣ʹ�õ�
         mov eax,general_exception_handler      ;�Ŵ����ڶ���ƫ�Ƶ�ַ
         mov bx,flat_4gb_code_seg_sel             ;�Ŵ������ڶε�ѡ����
         mov cx,0x8e00                          ;32λ�ж��ţ�0��Ȩ��
         call flat_4gb_code_seg_sel:make_gate_descriptor
         
         mov ebx,idt_linear_address             ;�ж�������������Ե�ַ
         xor esi,esi
  .idt0:
         mov [ebx+esi*8],eax
         mov [ebx+esi*8+4],edx
         inc esi
         cmp esi,19                             ;��װǰ20���쳣�жϴ������
         jle .idt0
         
         ;ch15-�жϣ�����Ϊ������Ӳ��ʹ�õ��ж�����
         mov eax,general_interrupt_handler      ;�Ŵ����ڶ���ƫ�Ƶ�ַ
         mov bx,flat_4gb_code_seg_sel             ;�Ŵ������ڶε�ѡ����
         mov cx,0x8e00                          ;32λ�ж��ţ�0��Ȩ��
         call flat_4gb_code_seg_sel:make_gate_descriptor
         
         mov ebx,idt_linear_address             ;�ж�������������Ե�ַ
  .idt1:
         mov [ebx+esi*8],eax
         mov [ebx+esi*8+4],edx
         inc esi
         cmp esi,255                            ;��װ��ͨ���жϴ������
         jle .idt1
         
         ;ch15-�жϣ�����ʵʱʱ���жϴ������
         mov eax,rtm_0x70_interrupt_handle      ;�Ŵ����ڶ���ƫ�Ƶ�ַ
         mov bx,flat_4gb_code_seg_sel             ;�Ŵ������ڶε�ѡ����
         mov cx,0x8e00                          ;32λ�ж��ţ�0��Ȩ��
         call flat_4gb_code_seg_sel:make_gate_descriptor
         
         mov ebx,idt_linear_address             ;�ж�������������Ե�ַ
         mov [ebx+0x70*8],eax
         mov [ebx+0x70*8+4],edx

         ;ch15-�жϣ�׼�������ж�
         mov word [pidt],256*8-1                ;IDT�Ľ���
         mov dword [pidt+2],idt_linear_address
         lidt [pidt]                            ;�����ж���������Ĵ���IDTR
         
         ;ch15-�жϣ�����8259A�жϿ�����
         mov al,0x11
         out 0x20,al                            ;ICW1�����ش���/������ʽ
         mov al,0x20
         out 0x21,al                            ;ICW2����ʼ�ж�����
         mov al,0x04
         out 0x21,al                            ;ICW3����Ƭ������IR2
         mov al,0x01
         out 0x21,al                            ;ICW4�������߻��壬ȫǶ�ף�����EOI
         
         mov al,0x11
         out 0xa0,al                            ;ICW1�����ش���/������ʽ
         mov al,0x70
         out 0xa1,al                            ;ICW2����ʼ�ж�����
         mov al,0x04
         out 0xa1,al                            ;ICW3����Ƭ������IR2
         mov al,0x01
         out 0xa1,al                            ;ICW4�������߻��壬ȫǶ�ף�����EOI
         
         ;ch15-�жϣ����ú�ʱ���ж���ص�Ӳ��
         mov al,0x0b                            ;RTC�Ĵ���B
         or al,0x80                             ;���NMI
         out 0x70,al
         mov al,0x12                            ;���üĴ���B����ֹ�������жϣ�����
         out 0x71,al                            ;���½������жϣ�BCD�룬24Сʱ��
         
         in al,0xa1                             ;��8259��Ƭ��IMR�Ĵ���
         and al,0xfe                            ;���bit 0����λ����RTC��
         out 0xa1,al                            ;д�ش˼Ĵ���
         
         mov al,0x0c
         out 0x70,al
         in al,0x71                             ;��RTC�Ĵ���C����λδ�����ж�״̬
         
         sti                                    ;����Ӳ���ж�
         
         mov ebx,message_0
         call flat_4gb_code_seg_sel:put_string
                                         
         ;��ʾ������Ʒ����Ϣ����Ҫ����3�Σ�ÿ�ζ�Ҫ��eax��ebx��ecx��edx������4*4=16 *3 =48���ַ��ı���
         mov eax,0x80000002
         cpuid
         mov [cpu_brand + 0x00],eax
         mov [cpu_brand + 0x04],ebx
         mov [cpu_brand + 0x08],ecx
         mov [cpu_brand + 0x0c],edx
      
         mov eax,0x80000003
         cpuid
         mov [cpu_brand + 0x10],eax
         mov [cpu_brand + 0x14],ebx
         mov [cpu_brand + 0x18],ecx
         mov [cpu_brand + 0x1c],edx

         mov eax,0x80000004
         cpuid
         mov [cpu_brand + 0x20],eax
         mov [cpu_brand + 0x24],ebx
         mov [cpu_brand + 0x28],ecx
         mov [cpu_brand + 0x2c],edx

         mov ebx,cpu_brnd0                   ;��ʾ������Ʒ����Ϣ
         call flat_4gb_code_seg_sel:put_string
         mov ebx,cpu_brand
         call flat_4gb_code_seg_sel:put_string
         mov ebx,cpu_brnd1
         call flat_4gb_code_seg_sel:put_string         

         ;ch14:���¿�ʼ��װΪ����ϵͳ����ĵ����š���Ȩ��֮��Ŀ���ת�Ʊ���ʹ����
         mov edi,salt                       ;C-SALT�����ʼλ�� 
         mov ecx,salt_items                 ;C-SALT�����Ŀ���� 
  .g0:
         push ecx   
         mov eax,[edi+256]                  ;����Ŀ��ڵ��32λƫ�Ƶ�ַ 
         mov bx,[edi+260]                   ;����Ŀ��ڵ�Ķ�ѡ���� 
         mov cx,1_11_0_1100_000_00000B      ;��Ȩ��3�ĵ�����(3���ϵ���Ȩ�����������)��
                                            ;0������(��Ϊ�üĴ������ݲ�������û����ջ)
                                            
         call flat_4gb_code_seg_sel:make_gate_descriptor
         call flat_4gb_code_seg_sel:set_up_gdt_descriptor
         mov [edi+260],cx                   ;�����ص���������ѡ���ӻ���
         add edi,salt_item_len              ;ָ����һ��C-SALT��Ŀ 
         pop ecx
         loop .g0

         ;ch14:���Ž��в��� 
         mov ebx,message_2                  ;ch15-�жϣ��޸�,ch16
         call far [salt_1+256]              ;ͨ������ʾ��Ϣ(ƫ������������) 
      
         ;ch16����ʼ������ȷ���ں�����
         mov ecx,core_lin_tcb_addr          ;�����߶�֮����ں�����TCB���Ե�ַ
         mov word [ecx+0x04],0xffff      ;�����״̬Ϊ��æ��
         mov dword [ecx+0x06],core_lin_alloc_at  ;ch17���Ǽ��ں��п����ڷ������ʼ���Ե�ַ����46��06    

         call append_to_tcb_link            ;���ں������TCB��ӵ�TCB����
         
         mov esi,ecx
         
         ;ch15:Ϊ�ں������TSS�����ڴ�ռ䡣����TSS���봴�����ں˿ռ�
         mov ecx,104
         call flat_4gb_code_seg_sel:allocate_memory
         mov [esi+0x14],ecx              ;���ں�TCB�б���TSS����ַ
         
         ;ch15:�ڳ����������TSS�����ñ�Ҫ����Ŀ
         mov word [ecx+0],0              ;������=0
         mov eax,cr3                        ;ch16
         mov dword [ecx+28],eax          ;ch16����ҳ���޸�.�Ǽ�CR3��PDBR��
         mov word [ecx+96],0             ;û��LDT������������û��LDT������
         mov word [ecx+100],0            ;T=0
                                            ;����Ҫ0��1��2��Ȩ����ջ��0��Ȩ����
                                            ;�������Ȩ��ת�ƿ��ơ�
         mov word [ecx+102],103          ;û��I/Oλͼ��0��Ȩ����ʵ�ϲ���Ҫ��
                                   
         ;ch15:����TSS������������װ��GDT��,ch16
         mov eax,ecx                        ;TSS����ʼ���Ե�ַ
         mov ebx,103                        ;�γ��ȣ����ޣ�
         mov ecx,0x00008900                 ;TSS����������Ȩ��0
         call flat_4gb_code_seg_sel:make_seg_descriptor
         call flat_4gb_code_seg_sel:set_up_gdt_descriptor
         mov word [esi+0x18],cx          ;�Ǽ�TSSѡ���ӵ�TCB
         
         ;ch15:����Ĵ���TR�е�����ʱ������ڵı�־��������Ҳ�����˵�ǰ������˭��
         ;ch15:�����ָ��Ϊ��ǰ����ִ�е�0��Ȩ�����񡰳������������������TSS����
         ltr cx
         
         ;ch15:���ڿ�����Ϊ�������������������ִ����
         mov ebx,core_msg1
         call flat_4gb_code_seg_sel:put_string
         
         ;ch15:���¿�ʼ�����û�����
         mov ecx,0x1a                       ;ch17
         call flat_4gb_code_seg_sel:allocate_memory
         mov word [ecx+0x04],0           ;����״̬������
         mov dword [ecx+0x06],0          ;ch16����ҳ�������ڿ����ڷ���ĳ�ʼ���Ե�ַ����46��06
         
         push dword 50                      ;�û�����λ���߼�50����
         push ecx                           ;ѹ��������ƿ���ʼ���Ե�ַ
         call load_relocate_program
         call append_to_tcb_link            ;ch16-��ҳ������TCB��ӵ�TCB����
         
         ;ch15-�жϣ����Դ���������������磺
         mov ecx,0x1a                       ;ch17
         call flat_4gb_code_seg_sel:allocate_memory
         mov word [ecx+0x04],0           ;����״̬������
         mov dword [ecx+0x06],0          ;ch16�������ڿ����ڷ���ĳ�ʼ���Ե�ַ����46��06
         
         push dword 100                     ;�û�����λ���߼�100����
         push ecx                           ;ѹ��������ƿ���ʼ���Ե�ַ
         
         call load_relocate_program
         call append_to_tcb_link            ;����TCB��ӵ�TCB����
         
  .do_switch:                               ;load_relocate_program�ķ��ص�
         mov ebx,core_msg2
         call flat_4gb_code_seg_sel:put_string
         
         ;���������Ӵ����µ�����Ĺ��ܣ����磺
         ;mov ecx,0x46
         ;call flat_4gb_code_seg_sel:allocate_memory
         ;mov word [es:ecx+0x04],0          ;����״̬������
         ;call append_to_tcb_link           ;����TCB��ӵ�TCB����
         
         ;push dword 50                     ;�û�����λ���߼�50����
         ;push ecx                          ;ѹ��������ƿ���ʼ���Ե�ַ
         
         ;call load_relocate_program
         
         ;�����Ѿ���ֹ�����񣬲���������ռ�õ���Դ
         call flat_4gb_code_seg_sel:do_task_clean

         hlt
         
         jmp .do_switch

  core_code_end:

;-------------------------------------------------------------------------------
SECTION core_trail
;-------------------------------------------------------------------------------
core_end: