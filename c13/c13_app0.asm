         ;�ļ�����c13_app0.asm
         ;�ļ�˵�����û����� 
     
;===============================================================================
SECTION header vstart=0

         program_length   dd program_end          ;�����ܳ���#0x00
         
         head_len         dd header_end           ;����ͷ���ĳ���#0x04
;Ϊ�˼������coreҪ���û�����ֻ����һ������Ρ�һ��ջ�Ρ�һ�����ݶΣ���ֻ��������չ�����밴����ĸ�ʽ��ͷ������͵Ǽ�
         prgentry         dd start                ;�������#0x08�������32λƫ����start��0
         code_seg         dd section.code.start   ;�����λ��#0x0c
         code_len         dd code_end             ;����γ���#0x10
         
         data_seg         dd section.data.start   ;���ݶ�λ��#0x14
         data_len         dd data_end             ;���ݶγ���#0x18
         
         stack_seg        dd section.stack.start  ;ջ��λ��#0x1c
         stack_len        dd stack_end            ;ջ�γ���#0x20
                 
header_end:

;===============================================================================
SECTION data vstart=0    

         message_1         db  0x0d,0x0a,0x0d,0x0a
                           db  '**********User program is runing**********'
                           db  0x0d,0x0a,0

data_end:

;===============================================================================
SECTION stack vstart=0    

         times 2048        db  0                  ;����2KB��ջ�ռ�

stack_end:

;===============================================================================
      [bits 32]
;===============================================================================
SECTION code vstart=0

start:
         mov eax,ds
         mov fs,eax
         
         ;mov eax,[stack_seg]
         ;mov ss,eax
         ;mov esp,stack_end
         
         ;mov eax,[data_seg]
         ;mov ds,eax
         
         ;�û�����Ҫ�������飨ʡ�ԣ�
         
         retf           ;������Ȩ���ص�ϵͳ
      
code_end:

;===============================================================================
SECTION trail
;-------------------------------------------------------------------------------
program_end: