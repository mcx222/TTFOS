;程序基础设置
section Initial vstart=0x7c00
ZeroTheSegmentRegister:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov ss,ax
;程序开始前的设置，把段寄存器置0，后续所有地址都是相对于0x0000的偏移
SetupTheStcakPointer:
    mov sp,0x7c00
    ;栈空间位于0x7c00及往前的空间，栈顶在0x7c00
Start:
    mov si,BOOTLOADERSTART
    call PrintString
;查看是否支持扩展int 13h
CheckInt13:
    mov ah,0x41
    mov bx,0x55aa
    mov dl,0x80
    int 13h
    cmp bx,0x55aa
    mov byte [SHITHAPPENS+0x06],0x31
    jnz BootLoaderEnd
;寻找MBR分区表的活动分区，看分区的第一个字节是否是0x80
SeekTheActivePartition:
;分区表位与0x7c00+446=0x7c00+0x1be=0x7dbe,用di作为基地址
    mov di,0x7dbe
    mov cx,4
    isActivePartition:
    mov bl,[di]
    cmp bl,0x80
    ;如果是证明找到了活动分区，跳转到接下来执行的代码
    je ActivePartitionFound
    ;没找到继续下一个分区项
    add di,16
    loop isActivePartition

ActionPartitionNotFound:
    mov byte [SHITHAPPENS+0x06],0x32
    jmp BootLoaderEnd
;找到活动分区后，di目前就是活动分区项的首地址
ActionPartitionFound:
    mov si,PartitionFound
    call PrintString
    ;ebx保存活动分区起始扇区号
    mov ebx,[di+8]
    mov dword [BlockLow],ebx
    ;目标内存起始地址
    mov word [ButfferOffset],0x7e00
    mov byte [BlockCount],1
    ;读取第一个扇区
    call ReadDisk
GetFirstFat:
    mov di,0x7e00
    ;ebx目前为活动分区起始扇区号
    xor ebx,ebx
    mov bx,[di+0x0e];bx为保留扇区数
    ;FirstFat起始扇区号=分区前已使用块数+保留扇区
    mov eax,[di+0x1c]
    add ebx,eax;eax目前为FirstFat起始扇区号
;获取数据区起始扇区号
GetDataAreaBase:
    mov eax,[di+0x24];FAT表的大小
    xor cx,cx
    mov cl,[di+0x10];FAT表的个数
    AddFatSize:
        add ebx,eax;数据区的起始扇区
        loop AddFatSize
;读取数据区8个扇区/1个簇
ReadRootDirectory:
    mov [BlockLow],ebx
    mov word [BufferOffset],0x8000
    mov di,0x8000
    mov byte [BlockCount],8
    call ReadDisk
    mov byte [ShitHappens+0x06],0x34
SeekTheInitialBin:
    cmp dword [di],'INIT'
    jne nextFile
    cmp dword [di+4],'IAl '
    jne nextFile
    cmp dword [di+8],'BIN '
    jne nextFile
    jmp InitialBinFound
    nextFile:
    cmp di,0x9000
    ja BootLoadeEnd
    add di,32
    jmp SeekTheInitialBin
    
InitialBinFound:
    mov si,InitialFound 
    call PrintString
    mov ax,[di+0x1c]
    mov dx,[di+0x1e];文件大小高2字节
    mov cx,512
    div cx
    ;如果余数不为0，则需要多读一个扇区
    cmp dx,0
    je NoRemainder
    inc ax;ax是要读取的扇区数
    mov [BlockCount],ax
    Remainder:
    ;文件起始簇号，乘8就是扇区号
    mov ax,[di+0x1a];ax开始簇的低2字节
    sub ax,2;是从第二个簇开始的
    mov cx,8
    mul cx;扇区数
    ;现在文件起始扇区号存在dx:ax，直接保存到ebx，这个起始是相对于DataBase 0x32,72
    ;所以待会计算真正的起始扇区号还需要加上DataBase
    and eax,0x0000ffff
    add ebx,eax
    mov ax,dx
    shl eax,16
    add ebx,eax
    mov [BlockLow],ebx
    mov word [BufferOffset],0x9000
    mov di,0x9000
    call ReadDisk
    ;跳转到Initial.bin继续执行
    mov si,Gotoinitial
    call PrintString
    jmp di
    NoRemainder:
    mov [BlockCount],ax
    ;文件起始簇号，乘8就是扇区号
    mov ax,[di+0x1a];ax开始簇的低2字节
    sub ax,2;是从第二个簇开始的
    mov cx,8
    mul cx;扇区数
    ;现在文件起始扇区号存在dx:ax，直接保存到ebx，这个起始是相对于DataBase 0x32,72
    ;所以待会计算真正的起始扇区号还需要加上DataBase
    and eax,0x0000ffff
    add ebx,eax
    mov ax,dx
    shl eax,16
    add ebx,eax
    mov [BlockLow],ebx
    mov word [BufferOffset],0x9000
    mov di,0x9000
    call ReadDisk
    ;跳转到Initial.bin继续执行
    mov si,Gotoinitial
    call PrintString
    jmp di
ReadDisk:
  mov ah, 0x42
  mov dl, 0x80
  mov si, DiskAddressPacket
  int 0x13
  test ah, ah
  mov byte [ShitHappens+0x06], 0x33
  jnz BootLoaderEnd
  ret

;打印以0x0a结尾的字符串
PrintString:
  push ax
  push cx
  push si
  mov cx, 512
  PrintChar:
    mov al, [si]
    mov ah, 0x0e
    int 0x10
    cmp byte [si], 0x0a
    je Return
    inc si
    loop PrintChar
  Return:
    pop si
    pop cx
    pop ax
    ret

DiskAddressPacket:
  ;包大小，目前恒等于16/0x10，0x00
  PackSize      db 0x10
  ;保留字节，恒等于0，0x01
  Reserved      db 0
  ;要读取的数据块个数，0x02
  BlockCount    dw 0
  ;目标内存地址的偏移，0x04
  BufferOffset  dw 0
  ;目标内存地址的段，让它等于0，0x06
  BufferSegment dw 0
  ;磁盘起始绝对地址，扇区为单位，这是低字节部分，0x08
  BlockLow      dd 0
  ;这是高字节部分，0x0c
  BlockHigh     dd 0
ImportantTips:
  
  BootLoaderStart   db 'Start Booting!'
                    db 0x0d, 0x0a
  PartitionFound    db 'Get Partition!'
                    db 0x0d, 0x0a
  InitialFound      db 'Get Initial!'
                    db 0x0d, 0x0a
  GotoInitial       db 'Go to Initial!'
                    db 0x0d, 0x0a
  ShitHappens       db 'Error 0, Shit happens, check your code!'
                    db 0x0d, 0x0a