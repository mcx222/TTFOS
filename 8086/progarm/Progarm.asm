NUL equ 0x00
SETCHAR equ 0x07
VIDEOMEM equ 0xb800
STRINGLEN equ 0xffff

section head align=16 vstart=0
    Size dd ProgarmEnd;4b 0x00
    SegmentAddr:
    CodeSeg dd section.code.start;4B 0x04
    DataSeg dd section.data.start;4b 0x08
    StackSeg dd section.stack.start;4b 0x0c
    SegmentNum:
    SegNum db (SegmentNum-SegmentAddr)/4;1B 0x10 段个数
    Entry dw CodeStart;2B 0x11 入口的段地址
          dd section.code.start;4B 0x13 入口的偏移地址
section code align=16 vstart=0
CodeStart:
    mov ax,[DataSeg]
    mov ds,ax
    mov ax,[StackSeg]
    mov ss,ax
    mov sp,StackEnd; 初始化栈指针
    xor si,si
    call PrintLines
    jmp $
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
    or bl, NUL
    jz .return
    cmp bl,0x0d;回车
    jz .putCR
    cmp bl,0x0a;换行
    jz .putLF
    inc si
    mov [es:di],bl
    inc di
    mov [es:di],bh
    inc di
    call SetCursor
    jmp .loopEnd
    
    .putCR:
    mov bl,160
    mov ax,di
    div bl
    shr ax,8;右移8位取的除法运算的余数
    sub di,ax;用di减去余数
    call SetCursor
    inc si
    jmp .loopEnd

    .putLF:
    add di,160
    call SetCursor
    inc si
    jmp .loopEnd
    .loopEnd:
    loop .printchar
    .return:
    ;mov bx,di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

SetCursor:
    push dx
    push bx
    push ax

    mov ax,di
    mov dx,0
    mov bx,2
    div bx

    mov bx,ax;ax中存放的是显示到第几个字符
    mov dx,0x3d4;0x3d4：选择那个寄存器
    mov al,0x0e;0x0e:光标位置高八位
    out dx,al;选择0x0e寄存器
    mov dx,0x3d5;0x3d5端口往0x3d4端口选中的寄存器写入数据
    mov al,bh
    out dx,al
    mov dx,0x3d4
    mov al,0x0f
    out dx,al
    mov dx,0x3d5
    mov al,bl
    out dx,al
    pop ax
    pop bx
    pop dx
    ret    
    
PrintLines:
    mov cx,HelloEnd-Hello
    xor si,si
    mov bl,0x07
    .putc:
    mov al,[si]
    inc si
    mov ah,0x0e
    int 0x10 
    loop .putc
    ret

section data align=16 vstart=0
    Hello db 'Hello, I am from Progarm on sector 1,loader by bootloader!'
          db 0x0d,0x0a
          db 'Haha, This is a new line!'
          db 0x0a
          db 'Just 0a'
          db 0x0d
          db 'Just 0d'
          db 0x0d,0x0a
          db 0x00
    HelloEnd:


section stack align=16 vstart=0
    times 128 db 0
    StackEnd:
section end align=16 
    ProgarmEnd:
