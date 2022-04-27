setion Initial vstart=0x9000
LoadGDT:	;告知cpu
	mov word [GDTStart],GDTEnd-GDTStart
	mov dword [GDTStart+2],GDTStart
	LGDT [GDTStart]
	
EnableProtectBit: ;修改cr0的PE位
	mov eax,cr0
	or eax,0x00000001
	mov cr0,eax	;清空流水线
	jmp CodeDescriptor:dword ProtectModeLand
BITS 32;告知编译器后面生成32位代码
ProtectModeLand: ;32位代码落地
GDTStart:
NullDescriptor equ $-GDTStart
	dw 0;段界限
	dw 0;段基址：15~0
	db 0;段基址：23~16
	db 0;段属性
	db 0;段界限 19：16
	db 0;段基址 31：24
	
DataDescriptor equ $-GDTStart
	dw 0xfff;段界限
	dw 0;段基址：15~0
	db 0;段基址：23~16
	db 0x93;段属性
	db 0xcf;段界限 19：16
	db 0;段基址 31：24
	
CodeDescriptor equ $-GDTStart
	dw 0xfff;段界限
	dw 0;段基址：15~0
	db 0;段基址：23~16
	db 0x9b;段属性
	db 0xcf;段界限 19：16
	db 0;段基址 31：24
	
VideoDescriptor equ $-GDTStart
	dw 0x7fff;段界限
	dw 0x8000;段基址：15~0
	db 0x0b;段基址：23~16
	db 0x93;段属性
	db 0xc0;段界限 19：16
	db 0;段基址 31：24
GDTEnd:

	
	
	