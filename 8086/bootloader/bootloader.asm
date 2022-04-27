HDDPORT equ 0x1f0
section code align=16 vstart=0x7c00
    mov si,[READSTART]
    mov cx,[READSTART+2]
    mov al,[SETTORNUM]
    push ax

    mov ax,[DESTMEN]
    mov dx,[DESTMEN+2]
    mov bx,16
    div bx

    mov ds,ax
    xor di,di
    pop ax
    call ReadHDD ;把第一个扇区的数据写入的内存0x10000的位置

    ResetSegment:
    mov bx,0x04;代码段的位置
    mov cl,[0x10];0x10处存储的事下一个程序段的个数

    .reset:;初始化各个段的地址
    mov ax,[bx];将第一个段的汇编地址放入ax
    mov dx,[bx+2]
    add ax,[cs:DESTMEN];将下一个程序写入内存的位置与汇编地址相加得到真实地址
    adc dx,[cs:DESTMEN+2]

    mov si,16
    div si;段的段首址
    mov [bx],ax 
    add bx,4
    loop .reset

    ResetEntry:
    mov ax,[0x13]
    mov dx,[0x15]
    add ax,[cs:DESTMEN]
    adc dx,[cs:DESTMEN+2]

    mov si,16
    div si
    mov [0x13],ax

    jmp far [0x11]


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
    mov cx,256
    
    .readword:
    in ax,dx
    mov [ds:di],ax
    add di,2
    ;or ah,0x00
    ;jnz .readword
    loop .readword
    
    .return:
    pop dx
    pop cx
    pop bx
    pop ax

    ret

READSTART dd 1     ;读取第几个扇区
SETTORNUM db 1      ;读取的扇区数
DESTMEN   dd 0x10000;写入内存的位置
End:
    jmp End
times 510-($-$$) db 0
                 db 0x55,0xaa
