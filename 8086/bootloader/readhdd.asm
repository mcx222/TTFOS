HDDPORT equ 0x1f0
NUL equ 0x00
SETCHAR equ 0x07
VIDEOMEM equ 0xb800
STRINGLEN equ 0xffff
section code align=16 vstart=0x7c00

mov si,[READSTART]
mov cx,[READSTART+0x02]
mov al,[SETTORNUM]
push ax

mov ax,[DESTMEN]
mov dx,[DESTMEN+0x02]
mov bx,16
div bx

mov ds,ax
xor di,di
pop ax

call ReadHDD
xor si,si
call PrintString
jmp End

ReadHDD:
    push ax
    push bx
    push cx
    push dx
    
    mov dx,HDDPORT+2
    out dx,al;将要读入的扇区数送到0x1f2寄存器

    mov dx,HDDPORT+3
    mov ax,si
    out dx,al;将LBA参数的0~7位传入0x1f3
    
    mov dx,HDDPORT+4
    mov al,ah
    out dx,al;将LBA参数的8~15位传入0x1f4
    
    mov dx,HDDPORT+5
    mov ax,cx
    out dx,al;将LBA参数的16~23位传入0x1f5

    mov dx,HDDPORT+6
    mov al,ah;将READSTART的最后8位数据传入al
    mov ah,0xe0
    or al,ah;将al的高三位改为1
    out dx,al;传入0x1f6

    mov dx,HDDPORT+7
    mov al,0x20;读取硬盘
    out dx,al

    .waits:;等待读取0x1f7的数据
    in al,dx
    and al,0x88;把3,7位外的其他数据置零
    cmp al,0x08;第七位为0表示硬盘不忙，第三位为1表示硬盘准备好了，所以与0x08比较判断硬盘是否可用
    jnz .waits
    
    mov dx,HDDPORT
    ;mov cx,256
    
    .readword:
    in ax,dx
    mov [ds:di],ax
    add di,2
    or ah,0x00
    jnz .readword
    
    .return:
    pop dx
    pop cx
    pop bx
    pop ax

    ret

PrintString:
    .setup:
    push ax
    push bx
    push cx
    push dx
    mov ax,VIDEOMEM 
    mov es,ax
    xor di,di
    
    mov bh,SETCHAR;字符的属性
    mov cx,STRINGLEN

    .printchar:
    mov bl,[ds:si]
    inc si
    mov [es:di],bl
    inc di
    mov [es:di],bh
    inc di
    or bl, NUL
    jz .return
    loop .printchar
    .return:
    ;mov bx,di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

READSTART dd 10     ;读取第几个扇区
SETTORNUM db 1      ;读取的扇区数
DESTMEN   dd 0x10000;写入内存的位置
End:
    jmp End
times 510-($-$$) db 0
                 db 0x55,0xaa
