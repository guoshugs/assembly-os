         ;�����嵥7-1
         ;�ļ�����c07_mbr.asm
         ;�ļ�˵����Ӳ����������������
         ;�������ڣ�2011-4-13 18:02
         
         jmp near start
	
 message db '1+2+3+...+100='
        
 start:
         mov ax,0x7c0 
         mov ds,ax				;7c00�������ݶ�ds���������ݶεĶλ���ַ

         mov ax,0xb800          ;���ø��Ӷλ�ַ����ʾ������
         mov es,ax

         ;������ʾ�ַ��� 
         mov si,message          
         mov di,0
         mov cx,start-message	;��������ѹ��ջ�еģ�������Ҫ�����������ס�ж��ٸ���
     @g:
         mov al,[si]			;��si���ڵ�ַȡ��һλ
         mov [es:di],al			;���������Դ�
         inc di					;ƫ���Դ�
         mov byte [es:di],0x07	;��������
         inc di					;���ݶ�ƫ��1
         inc si					;
         loop @g

         ;���¼���1��100�ĺ� 
         xor ax,ax
         mov cx,1
     @f:
         add ax,cx				;���5050�Ѿ�����ax����
         inc cx
         cmp cx,100
         jle @f

         ;���·ֽ��ۼӺ�5050��ÿ����λ 
         xor cx,cx              ;���ö�ջ�εĶλ���ַ
         mov ss,cx
         mov sp,cx

         mov bx,10
         xor cx,cx
     @d:
         inc cx
         xor dx,dx
         div bx					;��λ�ķֽ⻹��Ҫ�õ������㷨
         or dl,0x30
         push dx				;16λ��8086�������ϣ�ѹջ�ͳ�ջ��ֻ����16λ������Ҫ��dxһ������
		 ;��ջ���̣��Ȱ�sp��ȥ���������ֳ���8086����2��Ȼ������ջ
         cmp ax,0				;ÿ�γ������жϣ�����0����ǰ����
         jne @d

         ;������ʾ������λ 
     @a:
         pop dx
         mov [es:di],dl			;ǰ����ʾ�ַ�����ʱ�������di�ṩƫ�Ƶ�ַ����˴�ʱdi����ָ���ַ���β
         inc di
         mov byte [es:di],0x07
         inc di
         loop @a
       
         jmp near $ 
       

times 510-($-$$) db 0
                 db 0x55,0xaa