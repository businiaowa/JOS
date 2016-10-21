
obj/user/buggyhello2:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 1d 00 00 00       	call   80004e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

const char *hello = "hello, world\n";

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	sys_cputs(hello, 1024*1024);
  800039:	68 00 00 10 00       	push   $0x100000
  80003e:	ff 35 00 20 80 00    	pushl  0x802000
  800044:	e8 60 00 00 00       	call   8000a9 <sys_cputs>
}
  800049:	83 c4 10             	add    $0x10,%esp
  80004c:	c9                   	leave  
  80004d:	c3                   	ret    

0080004e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80004e:	55                   	push   %ebp
  80004f:	89 e5                	mov    %esp,%ebp
  800051:	56                   	push   %esi
  800052:	53                   	push   %ebx
  800053:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800056:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  800059:	e8 c9 00 00 00       	call   800127 <sys_getenvid>
  80005e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800063:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800066:	c1 e0 05             	shl    $0x5,%eax
  800069:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80006e:	a3 08 20 80 00       	mov    %eax,0x802008

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800073:	85 db                	test   %ebx,%ebx
  800075:	7e 07                	jle    80007e <libmain+0x30>
		binaryname = argv[0];
  800077:	8b 06                	mov    (%esi),%eax
  800079:	a3 04 20 80 00       	mov    %eax,0x802004

	// call user main routine
	umain(argc, argv);
  80007e:	83 ec 08             	sub    $0x8,%esp
  800081:	56                   	push   %esi
  800082:	53                   	push   %ebx
  800083:	e8 ab ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800088:	e8 0a 00 00 00       	call   800097 <exit>
}
  80008d:	83 c4 10             	add    $0x10,%esp
  800090:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800093:	5b                   	pop    %ebx
  800094:	5e                   	pop    %esi
  800095:	5d                   	pop    %ebp
  800096:	c3                   	ret    

00800097 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800097:	55                   	push   %ebp
  800098:	89 e5                	mov    %esp,%ebp
  80009a:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80009d:	6a 00                	push   $0x0
  80009f:	e8 42 00 00 00       	call   8000e6 <sys_env_destroy>
}
  8000a4:	83 c4 10             	add    $0x10,%esp
  8000a7:	c9                   	leave  
  8000a8:	c3                   	ret    

008000a9 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000a9:	55                   	push   %ebp
  8000aa:	89 e5                	mov    %esp,%ebp
  8000ac:	57                   	push   %edi
  8000ad:	56                   	push   %esi
  8000ae:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000af:	b8 00 00 00 00       	mov    $0x0,%eax
  8000b4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000b7:	8b 55 08             	mov    0x8(%ebp),%edx
  8000ba:	89 c3                	mov    %eax,%ebx
  8000bc:	89 c7                	mov    %eax,%edi
  8000be:	89 c6                	mov    %eax,%esi
  8000c0:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000c2:	5b                   	pop    %ebx
  8000c3:	5e                   	pop    %esi
  8000c4:	5f                   	pop    %edi
  8000c5:	5d                   	pop    %ebp
  8000c6:	c3                   	ret    

008000c7 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000c7:	55                   	push   %ebp
  8000c8:	89 e5                	mov    %esp,%ebp
  8000ca:	57                   	push   %edi
  8000cb:	56                   	push   %esi
  8000cc:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000cd:	ba 00 00 00 00       	mov    $0x0,%edx
  8000d2:	b8 01 00 00 00       	mov    $0x1,%eax
  8000d7:	89 d1                	mov    %edx,%ecx
  8000d9:	89 d3                	mov    %edx,%ebx
  8000db:	89 d7                	mov    %edx,%edi
  8000dd:	89 d6                	mov    %edx,%esi
  8000df:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000e1:	5b                   	pop    %ebx
  8000e2:	5e                   	pop    %esi
  8000e3:	5f                   	pop    %edi
  8000e4:	5d                   	pop    %ebp
  8000e5:	c3                   	ret    

008000e6 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000e6:	55                   	push   %ebp
  8000e7:	89 e5                	mov    %esp,%ebp
  8000e9:	57                   	push   %edi
  8000ea:	56                   	push   %esi
  8000eb:	53                   	push   %ebx
  8000ec:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000ef:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000f4:	b8 03 00 00 00       	mov    $0x3,%eax
  8000f9:	8b 55 08             	mov    0x8(%ebp),%edx
  8000fc:	89 cb                	mov    %ecx,%ebx
  8000fe:	89 cf                	mov    %ecx,%edi
  800100:	89 ce                	mov    %ecx,%esi
  800102:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800104:	85 c0                	test   %eax,%eax
  800106:	7e 17                	jle    80011f <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800108:	83 ec 0c             	sub    $0xc,%esp
  80010b:	50                   	push   %eax
  80010c:	6a 03                	push   $0x3
  80010e:	68 18 0e 80 00       	push   $0x800e18
  800113:	6a 23                	push   $0x23
  800115:	68 35 0e 80 00       	push   $0x800e35
  80011a:	e8 27 00 00 00       	call   800146 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80011f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800122:	5b                   	pop    %ebx
  800123:	5e                   	pop    %esi
  800124:	5f                   	pop    %edi
  800125:	5d                   	pop    %ebp
  800126:	c3                   	ret    

00800127 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800127:	55                   	push   %ebp
  800128:	89 e5                	mov    %esp,%ebp
  80012a:	57                   	push   %edi
  80012b:	56                   	push   %esi
  80012c:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80012d:	ba 00 00 00 00       	mov    $0x0,%edx
  800132:	b8 02 00 00 00       	mov    $0x2,%eax
  800137:	89 d1                	mov    %edx,%ecx
  800139:	89 d3                	mov    %edx,%ebx
  80013b:	89 d7                	mov    %edx,%edi
  80013d:	89 d6                	mov    %edx,%esi
  80013f:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800141:	5b                   	pop    %ebx
  800142:	5e                   	pop    %esi
  800143:	5f                   	pop    %edi
  800144:	5d                   	pop    %ebp
  800145:	c3                   	ret    

00800146 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800146:	55                   	push   %ebp
  800147:	89 e5                	mov    %esp,%ebp
  800149:	56                   	push   %esi
  80014a:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80014b:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80014e:	8b 35 04 20 80 00    	mov    0x802004,%esi
  800154:	e8 ce ff ff ff       	call   800127 <sys_getenvid>
  800159:	83 ec 0c             	sub    $0xc,%esp
  80015c:	ff 75 0c             	pushl  0xc(%ebp)
  80015f:	ff 75 08             	pushl  0x8(%ebp)
  800162:	56                   	push   %esi
  800163:	50                   	push   %eax
  800164:	68 44 0e 80 00       	push   $0x800e44
  800169:	e8 b1 00 00 00       	call   80021f <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80016e:	83 c4 18             	add    $0x18,%esp
  800171:	53                   	push   %ebx
  800172:	ff 75 10             	pushl  0x10(%ebp)
  800175:	e8 54 00 00 00       	call   8001ce <vcprintf>
	cprintf("\n");
  80017a:	c7 04 24 0c 0e 80 00 	movl   $0x800e0c,(%esp)
  800181:	e8 99 00 00 00       	call   80021f <cprintf>
  800186:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800189:	cc                   	int3   
  80018a:	eb fd                	jmp    800189 <_panic+0x43>

0080018c <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80018c:	55                   	push   %ebp
  80018d:	89 e5                	mov    %esp,%ebp
  80018f:	53                   	push   %ebx
  800190:	83 ec 04             	sub    $0x4,%esp
  800193:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800196:	8b 13                	mov    (%ebx),%edx
  800198:	8d 42 01             	lea    0x1(%edx),%eax
  80019b:	89 03                	mov    %eax,(%ebx)
  80019d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001a0:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001a4:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001a9:	75 1a                	jne    8001c5 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001ab:	83 ec 08             	sub    $0x8,%esp
  8001ae:	68 ff 00 00 00       	push   $0xff
  8001b3:	8d 43 08             	lea    0x8(%ebx),%eax
  8001b6:	50                   	push   %eax
  8001b7:	e8 ed fe ff ff       	call   8000a9 <sys_cputs>
		b->idx = 0;
  8001bc:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001c2:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001c5:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001c9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001cc:	c9                   	leave  
  8001cd:	c3                   	ret    

008001ce <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001ce:	55                   	push   %ebp
  8001cf:	89 e5                	mov    %esp,%ebp
  8001d1:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001d7:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001de:	00 00 00 
	b.cnt = 0;
  8001e1:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001e8:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001eb:	ff 75 0c             	pushl  0xc(%ebp)
  8001ee:	ff 75 08             	pushl  0x8(%ebp)
  8001f1:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001f7:	50                   	push   %eax
  8001f8:	68 8c 01 80 00       	push   $0x80018c
  8001fd:	e8 1a 01 00 00       	call   80031c <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800202:	83 c4 08             	add    $0x8,%esp
  800205:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80020b:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800211:	50                   	push   %eax
  800212:	e8 92 fe ff ff       	call   8000a9 <sys_cputs>

	return b.cnt;
}
  800217:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80021d:	c9                   	leave  
  80021e:	c3                   	ret    

0080021f <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80021f:	55                   	push   %ebp
  800220:	89 e5                	mov    %esp,%ebp
  800222:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800225:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800228:	50                   	push   %eax
  800229:	ff 75 08             	pushl  0x8(%ebp)
  80022c:	e8 9d ff ff ff       	call   8001ce <vcprintf>
	va_end(ap);

	return cnt;
}
  800231:	c9                   	leave  
  800232:	c3                   	ret    

00800233 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800233:	55                   	push   %ebp
  800234:	89 e5                	mov    %esp,%ebp
  800236:	57                   	push   %edi
  800237:	56                   	push   %esi
  800238:	53                   	push   %ebx
  800239:	83 ec 1c             	sub    $0x1c,%esp
  80023c:	89 c7                	mov    %eax,%edi
  80023e:	89 d6                	mov    %edx,%esi
  800240:	8b 45 08             	mov    0x8(%ebp),%eax
  800243:	8b 55 0c             	mov    0xc(%ebp),%edx
  800246:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800249:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80024c:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80024f:	bb 00 00 00 00       	mov    $0x0,%ebx
  800254:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800257:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80025a:	39 d3                	cmp    %edx,%ebx
  80025c:	72 05                	jb     800263 <printnum+0x30>
  80025e:	39 45 10             	cmp    %eax,0x10(%ebp)
  800261:	77 45                	ja     8002a8 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800263:	83 ec 0c             	sub    $0xc,%esp
  800266:	ff 75 18             	pushl  0x18(%ebp)
  800269:	8b 45 14             	mov    0x14(%ebp),%eax
  80026c:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80026f:	53                   	push   %ebx
  800270:	ff 75 10             	pushl  0x10(%ebp)
  800273:	83 ec 08             	sub    $0x8,%esp
  800276:	ff 75 e4             	pushl  -0x1c(%ebp)
  800279:	ff 75 e0             	pushl  -0x20(%ebp)
  80027c:	ff 75 dc             	pushl  -0x24(%ebp)
  80027f:	ff 75 d8             	pushl  -0x28(%ebp)
  800282:	e8 e9 08 00 00       	call   800b70 <__udivdi3>
  800287:	83 c4 18             	add    $0x18,%esp
  80028a:	52                   	push   %edx
  80028b:	50                   	push   %eax
  80028c:	89 f2                	mov    %esi,%edx
  80028e:	89 f8                	mov    %edi,%eax
  800290:	e8 9e ff ff ff       	call   800233 <printnum>
  800295:	83 c4 20             	add    $0x20,%esp
  800298:	eb 18                	jmp    8002b2 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80029a:	83 ec 08             	sub    $0x8,%esp
  80029d:	56                   	push   %esi
  80029e:	ff 75 18             	pushl  0x18(%ebp)
  8002a1:	ff d7                	call   *%edi
  8002a3:	83 c4 10             	add    $0x10,%esp
  8002a6:	eb 03                	jmp    8002ab <printnum+0x78>
  8002a8:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002ab:	83 eb 01             	sub    $0x1,%ebx
  8002ae:	85 db                	test   %ebx,%ebx
  8002b0:	7f e8                	jg     80029a <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002b2:	83 ec 08             	sub    $0x8,%esp
  8002b5:	56                   	push   %esi
  8002b6:	83 ec 04             	sub    $0x4,%esp
  8002b9:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002bc:	ff 75 e0             	pushl  -0x20(%ebp)
  8002bf:	ff 75 dc             	pushl  -0x24(%ebp)
  8002c2:	ff 75 d8             	pushl  -0x28(%ebp)
  8002c5:	e8 d6 09 00 00       	call   800ca0 <__umoddi3>
  8002ca:	83 c4 14             	add    $0x14,%esp
  8002cd:	0f be 80 68 0e 80 00 	movsbl 0x800e68(%eax),%eax
  8002d4:	50                   	push   %eax
  8002d5:	ff d7                	call   *%edi
}
  8002d7:	83 c4 10             	add    $0x10,%esp
  8002da:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002dd:	5b                   	pop    %ebx
  8002de:	5e                   	pop    %esi
  8002df:	5f                   	pop    %edi
  8002e0:	5d                   	pop    %ebp
  8002e1:	c3                   	ret    

008002e2 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002e2:	55                   	push   %ebp
  8002e3:	89 e5                	mov    %esp,%ebp
  8002e5:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002e8:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002ec:	8b 10                	mov    (%eax),%edx
  8002ee:	3b 50 04             	cmp    0x4(%eax),%edx
  8002f1:	73 0a                	jae    8002fd <sprintputch+0x1b>
		*b->buf++ = ch;
  8002f3:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002f6:	89 08                	mov    %ecx,(%eax)
  8002f8:	8b 45 08             	mov    0x8(%ebp),%eax
  8002fb:	88 02                	mov    %al,(%edx)
}
  8002fd:	5d                   	pop    %ebp
  8002fe:	c3                   	ret    

008002ff <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002ff:	55                   	push   %ebp
  800300:	89 e5                	mov    %esp,%ebp
  800302:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800305:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800308:	50                   	push   %eax
  800309:	ff 75 10             	pushl  0x10(%ebp)
  80030c:	ff 75 0c             	pushl  0xc(%ebp)
  80030f:	ff 75 08             	pushl  0x8(%ebp)
  800312:	e8 05 00 00 00       	call   80031c <vprintfmt>
	va_end(ap);
}
  800317:	83 c4 10             	add    $0x10,%esp
  80031a:	c9                   	leave  
  80031b:	c3                   	ret    

0080031c <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80031c:	55                   	push   %ebp
  80031d:	89 e5                	mov    %esp,%ebp
  80031f:	57                   	push   %edi
  800320:	56                   	push   %esi
  800321:	53                   	push   %ebx
  800322:	83 ec 2c             	sub    $0x2c,%esp
  800325:	8b 75 08             	mov    0x8(%ebp),%esi
  800328:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80032b:	8b 7d 10             	mov    0x10(%ebp),%edi
  80032e:	eb 12                	jmp    800342 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800330:	85 c0                	test   %eax,%eax
  800332:	0f 84 42 04 00 00    	je     80077a <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800338:	83 ec 08             	sub    $0x8,%esp
  80033b:	53                   	push   %ebx
  80033c:	50                   	push   %eax
  80033d:	ff d6                	call   *%esi
  80033f:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800342:	83 c7 01             	add    $0x1,%edi
  800345:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800349:	83 f8 25             	cmp    $0x25,%eax
  80034c:	75 e2                	jne    800330 <vprintfmt+0x14>
  80034e:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800352:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800359:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800360:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800367:	b9 00 00 00 00       	mov    $0x0,%ecx
  80036c:	eb 07                	jmp    800375 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80036e:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800371:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800375:	8d 47 01             	lea    0x1(%edi),%eax
  800378:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80037b:	0f b6 07             	movzbl (%edi),%eax
  80037e:	0f b6 d0             	movzbl %al,%edx
  800381:	83 e8 23             	sub    $0x23,%eax
  800384:	3c 55                	cmp    $0x55,%al
  800386:	0f 87 d3 03 00 00    	ja     80075f <vprintfmt+0x443>
  80038c:	0f b6 c0             	movzbl %al,%eax
  80038f:	ff 24 85 00 0f 80 00 	jmp    *0x800f00(,%eax,4)
  800396:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800399:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80039d:	eb d6                	jmp    800375 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003a2:	b8 00 00 00 00       	mov    $0x0,%eax
  8003a7:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003aa:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003ad:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8003b1:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8003b4:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8003b7:	83 f9 09             	cmp    $0x9,%ecx
  8003ba:	77 3f                	ja     8003fb <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003bc:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003bf:	eb e9                	jmp    8003aa <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c4:	8b 00                	mov    (%eax),%eax
  8003c6:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003c9:	8b 45 14             	mov    0x14(%ebp),%eax
  8003cc:	8d 40 04             	lea    0x4(%eax),%eax
  8003cf:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003d5:	eb 2a                	jmp    800401 <vprintfmt+0xe5>
  8003d7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003da:	85 c0                	test   %eax,%eax
  8003dc:	ba 00 00 00 00       	mov    $0x0,%edx
  8003e1:	0f 49 d0             	cmovns %eax,%edx
  8003e4:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003ea:	eb 89                	jmp    800375 <vprintfmt+0x59>
  8003ec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003ef:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003f6:	e9 7a ff ff ff       	jmp    800375 <vprintfmt+0x59>
  8003fb:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003fe:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800401:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800405:	0f 89 6a ff ff ff    	jns    800375 <vprintfmt+0x59>
				width = precision, precision = -1;
  80040b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80040e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800411:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800418:	e9 58 ff ff ff       	jmp    800375 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80041d:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800420:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800423:	e9 4d ff ff ff       	jmp    800375 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800428:	8b 45 14             	mov    0x14(%ebp),%eax
  80042b:	8d 78 04             	lea    0x4(%eax),%edi
  80042e:	83 ec 08             	sub    $0x8,%esp
  800431:	53                   	push   %ebx
  800432:	ff 30                	pushl  (%eax)
  800434:	ff d6                	call   *%esi
			break;
  800436:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800439:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80043c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80043f:	e9 fe fe ff ff       	jmp    800342 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800444:	8b 45 14             	mov    0x14(%ebp),%eax
  800447:	8d 78 04             	lea    0x4(%eax),%edi
  80044a:	8b 00                	mov    (%eax),%eax
  80044c:	99                   	cltd   
  80044d:	31 d0                	xor    %edx,%eax
  80044f:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800451:	83 f8 07             	cmp    $0x7,%eax
  800454:	7f 0b                	jg     800461 <vprintfmt+0x145>
  800456:	8b 14 85 60 10 80 00 	mov    0x801060(,%eax,4),%edx
  80045d:	85 d2                	test   %edx,%edx
  80045f:	75 1b                	jne    80047c <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800461:	50                   	push   %eax
  800462:	68 80 0e 80 00       	push   $0x800e80
  800467:	53                   	push   %ebx
  800468:	56                   	push   %esi
  800469:	e8 91 fe ff ff       	call   8002ff <printfmt>
  80046e:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800471:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800474:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800477:	e9 c6 fe ff ff       	jmp    800342 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80047c:	52                   	push   %edx
  80047d:	68 89 0e 80 00       	push   $0x800e89
  800482:	53                   	push   %ebx
  800483:	56                   	push   %esi
  800484:	e8 76 fe ff ff       	call   8002ff <printfmt>
  800489:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80048c:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80048f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800492:	e9 ab fe ff ff       	jmp    800342 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800497:	8b 45 14             	mov    0x14(%ebp),%eax
  80049a:	83 c0 04             	add    $0x4,%eax
  80049d:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8004a0:	8b 45 14             	mov    0x14(%ebp),%eax
  8004a3:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004a5:	85 ff                	test   %edi,%edi
  8004a7:	b8 79 0e 80 00       	mov    $0x800e79,%eax
  8004ac:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004af:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004b3:	0f 8e 94 00 00 00    	jle    80054d <vprintfmt+0x231>
  8004b9:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004bd:	0f 84 98 00 00 00    	je     80055b <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004c3:	83 ec 08             	sub    $0x8,%esp
  8004c6:	ff 75 d0             	pushl  -0x30(%ebp)
  8004c9:	57                   	push   %edi
  8004ca:	e8 33 03 00 00       	call   800802 <strnlen>
  8004cf:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004d2:	29 c1                	sub    %eax,%ecx
  8004d4:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004d7:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004da:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004de:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004e1:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004e4:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004e6:	eb 0f                	jmp    8004f7 <vprintfmt+0x1db>
					putch(padc, putdat);
  8004e8:	83 ec 08             	sub    $0x8,%esp
  8004eb:	53                   	push   %ebx
  8004ec:	ff 75 e0             	pushl  -0x20(%ebp)
  8004ef:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004f1:	83 ef 01             	sub    $0x1,%edi
  8004f4:	83 c4 10             	add    $0x10,%esp
  8004f7:	85 ff                	test   %edi,%edi
  8004f9:	7f ed                	jg     8004e8 <vprintfmt+0x1cc>
  8004fb:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004fe:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800501:	85 c9                	test   %ecx,%ecx
  800503:	b8 00 00 00 00       	mov    $0x0,%eax
  800508:	0f 49 c1             	cmovns %ecx,%eax
  80050b:	29 c1                	sub    %eax,%ecx
  80050d:	89 75 08             	mov    %esi,0x8(%ebp)
  800510:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800513:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800516:	89 cb                	mov    %ecx,%ebx
  800518:	eb 4d                	jmp    800567 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80051a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80051e:	74 1b                	je     80053b <vprintfmt+0x21f>
  800520:	0f be c0             	movsbl %al,%eax
  800523:	83 e8 20             	sub    $0x20,%eax
  800526:	83 f8 5e             	cmp    $0x5e,%eax
  800529:	76 10                	jbe    80053b <vprintfmt+0x21f>
					putch('?', putdat);
  80052b:	83 ec 08             	sub    $0x8,%esp
  80052e:	ff 75 0c             	pushl  0xc(%ebp)
  800531:	6a 3f                	push   $0x3f
  800533:	ff 55 08             	call   *0x8(%ebp)
  800536:	83 c4 10             	add    $0x10,%esp
  800539:	eb 0d                	jmp    800548 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  80053b:	83 ec 08             	sub    $0x8,%esp
  80053e:	ff 75 0c             	pushl  0xc(%ebp)
  800541:	52                   	push   %edx
  800542:	ff 55 08             	call   *0x8(%ebp)
  800545:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800548:	83 eb 01             	sub    $0x1,%ebx
  80054b:	eb 1a                	jmp    800567 <vprintfmt+0x24b>
  80054d:	89 75 08             	mov    %esi,0x8(%ebp)
  800550:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800553:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800556:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800559:	eb 0c                	jmp    800567 <vprintfmt+0x24b>
  80055b:	89 75 08             	mov    %esi,0x8(%ebp)
  80055e:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800561:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800564:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800567:	83 c7 01             	add    $0x1,%edi
  80056a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80056e:	0f be d0             	movsbl %al,%edx
  800571:	85 d2                	test   %edx,%edx
  800573:	74 23                	je     800598 <vprintfmt+0x27c>
  800575:	85 f6                	test   %esi,%esi
  800577:	78 a1                	js     80051a <vprintfmt+0x1fe>
  800579:	83 ee 01             	sub    $0x1,%esi
  80057c:	79 9c                	jns    80051a <vprintfmt+0x1fe>
  80057e:	89 df                	mov    %ebx,%edi
  800580:	8b 75 08             	mov    0x8(%ebp),%esi
  800583:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800586:	eb 18                	jmp    8005a0 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800588:	83 ec 08             	sub    $0x8,%esp
  80058b:	53                   	push   %ebx
  80058c:	6a 20                	push   $0x20
  80058e:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800590:	83 ef 01             	sub    $0x1,%edi
  800593:	83 c4 10             	add    $0x10,%esp
  800596:	eb 08                	jmp    8005a0 <vprintfmt+0x284>
  800598:	89 df                	mov    %ebx,%edi
  80059a:	8b 75 08             	mov    0x8(%ebp),%esi
  80059d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005a0:	85 ff                	test   %edi,%edi
  8005a2:	7f e4                	jg     800588 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8005a4:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8005a7:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005aa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005ad:	e9 90 fd ff ff       	jmp    800342 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005b2:	83 f9 01             	cmp    $0x1,%ecx
  8005b5:	7e 19                	jle    8005d0 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8005b7:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ba:	8b 50 04             	mov    0x4(%eax),%edx
  8005bd:	8b 00                	mov    (%eax),%eax
  8005bf:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005c2:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005c5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c8:	8d 40 08             	lea    0x8(%eax),%eax
  8005cb:	89 45 14             	mov    %eax,0x14(%ebp)
  8005ce:	eb 38                	jmp    800608 <vprintfmt+0x2ec>
	else if (lflag)
  8005d0:	85 c9                	test   %ecx,%ecx
  8005d2:	74 1b                	je     8005ef <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005d4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d7:	8b 00                	mov    (%eax),%eax
  8005d9:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005dc:	89 c1                	mov    %eax,%ecx
  8005de:	c1 f9 1f             	sar    $0x1f,%ecx
  8005e1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e7:	8d 40 04             	lea    0x4(%eax),%eax
  8005ea:	89 45 14             	mov    %eax,0x14(%ebp)
  8005ed:	eb 19                	jmp    800608 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005ef:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f2:	8b 00                	mov    (%eax),%eax
  8005f4:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005f7:	89 c1                	mov    %eax,%ecx
  8005f9:	c1 f9 1f             	sar    $0x1f,%ecx
  8005fc:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005ff:	8b 45 14             	mov    0x14(%ebp),%eax
  800602:	8d 40 04             	lea    0x4(%eax),%eax
  800605:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800608:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80060b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80060e:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800613:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800617:	0f 89 0e 01 00 00    	jns    80072b <vprintfmt+0x40f>
				putch('-', putdat);
  80061d:	83 ec 08             	sub    $0x8,%esp
  800620:	53                   	push   %ebx
  800621:	6a 2d                	push   $0x2d
  800623:	ff d6                	call   *%esi
				num = -(long long) num;
  800625:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800628:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80062b:	f7 da                	neg    %edx
  80062d:	83 d1 00             	adc    $0x0,%ecx
  800630:	f7 d9                	neg    %ecx
  800632:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800635:	b8 0a 00 00 00       	mov    $0xa,%eax
  80063a:	e9 ec 00 00 00       	jmp    80072b <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80063f:	83 f9 01             	cmp    $0x1,%ecx
  800642:	7e 18                	jle    80065c <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800644:	8b 45 14             	mov    0x14(%ebp),%eax
  800647:	8b 10                	mov    (%eax),%edx
  800649:	8b 48 04             	mov    0x4(%eax),%ecx
  80064c:	8d 40 08             	lea    0x8(%eax),%eax
  80064f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800652:	b8 0a 00 00 00       	mov    $0xa,%eax
  800657:	e9 cf 00 00 00       	jmp    80072b <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80065c:	85 c9                	test   %ecx,%ecx
  80065e:	74 1a                	je     80067a <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800660:	8b 45 14             	mov    0x14(%ebp),%eax
  800663:	8b 10                	mov    (%eax),%edx
  800665:	b9 00 00 00 00       	mov    $0x0,%ecx
  80066a:	8d 40 04             	lea    0x4(%eax),%eax
  80066d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800670:	b8 0a 00 00 00       	mov    $0xa,%eax
  800675:	e9 b1 00 00 00       	jmp    80072b <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80067a:	8b 45 14             	mov    0x14(%ebp),%eax
  80067d:	8b 10                	mov    (%eax),%edx
  80067f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800684:	8d 40 04             	lea    0x4(%eax),%eax
  800687:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80068a:	b8 0a 00 00 00       	mov    $0xa,%eax
  80068f:	e9 97 00 00 00       	jmp    80072b <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800694:	83 ec 08             	sub    $0x8,%esp
  800697:	53                   	push   %ebx
  800698:	6a 58                	push   $0x58
  80069a:	ff d6                	call   *%esi
			putch('X', putdat);
  80069c:	83 c4 08             	add    $0x8,%esp
  80069f:	53                   	push   %ebx
  8006a0:	6a 58                	push   $0x58
  8006a2:	ff d6                	call   *%esi
			putch('X', putdat);
  8006a4:	83 c4 08             	add    $0x8,%esp
  8006a7:	53                   	push   %ebx
  8006a8:	6a 58                	push   $0x58
  8006aa:	ff d6                	call   *%esi
			break;
  8006ac:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8006b2:	e9 8b fc ff ff       	jmp    800342 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8006b7:	83 ec 08             	sub    $0x8,%esp
  8006ba:	53                   	push   %ebx
  8006bb:	6a 30                	push   $0x30
  8006bd:	ff d6                	call   *%esi
			putch('x', putdat);
  8006bf:	83 c4 08             	add    $0x8,%esp
  8006c2:	53                   	push   %ebx
  8006c3:	6a 78                	push   $0x78
  8006c5:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006c7:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ca:	8b 10                	mov    (%eax),%edx
  8006cc:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006d1:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006d4:	8d 40 04             	lea    0x4(%eax),%eax
  8006d7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006da:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006df:	eb 4a                	jmp    80072b <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006e1:	83 f9 01             	cmp    $0x1,%ecx
  8006e4:	7e 15                	jle    8006fb <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8006e6:	8b 45 14             	mov    0x14(%ebp),%eax
  8006e9:	8b 10                	mov    (%eax),%edx
  8006eb:	8b 48 04             	mov    0x4(%eax),%ecx
  8006ee:	8d 40 08             	lea    0x8(%eax),%eax
  8006f1:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006f4:	b8 10 00 00 00       	mov    $0x10,%eax
  8006f9:	eb 30                	jmp    80072b <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006fb:	85 c9                	test   %ecx,%ecx
  8006fd:	74 17                	je     800716 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8006ff:	8b 45 14             	mov    0x14(%ebp),%eax
  800702:	8b 10                	mov    (%eax),%edx
  800704:	b9 00 00 00 00       	mov    $0x0,%ecx
  800709:	8d 40 04             	lea    0x4(%eax),%eax
  80070c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80070f:	b8 10 00 00 00       	mov    $0x10,%eax
  800714:	eb 15                	jmp    80072b <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800716:	8b 45 14             	mov    0x14(%ebp),%eax
  800719:	8b 10                	mov    (%eax),%edx
  80071b:	b9 00 00 00 00       	mov    $0x0,%ecx
  800720:	8d 40 04             	lea    0x4(%eax),%eax
  800723:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800726:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  80072b:	83 ec 0c             	sub    $0xc,%esp
  80072e:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800732:	57                   	push   %edi
  800733:	ff 75 e0             	pushl  -0x20(%ebp)
  800736:	50                   	push   %eax
  800737:	51                   	push   %ecx
  800738:	52                   	push   %edx
  800739:	89 da                	mov    %ebx,%edx
  80073b:	89 f0                	mov    %esi,%eax
  80073d:	e8 f1 fa ff ff       	call   800233 <printnum>
			break;
  800742:	83 c4 20             	add    $0x20,%esp
  800745:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800748:	e9 f5 fb ff ff       	jmp    800342 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80074d:	83 ec 08             	sub    $0x8,%esp
  800750:	53                   	push   %ebx
  800751:	52                   	push   %edx
  800752:	ff d6                	call   *%esi
			break;
  800754:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800757:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80075a:	e9 e3 fb ff ff       	jmp    800342 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80075f:	83 ec 08             	sub    $0x8,%esp
  800762:	53                   	push   %ebx
  800763:	6a 25                	push   $0x25
  800765:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800767:	83 c4 10             	add    $0x10,%esp
  80076a:	eb 03                	jmp    80076f <vprintfmt+0x453>
  80076c:	83 ef 01             	sub    $0x1,%edi
  80076f:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800773:	75 f7                	jne    80076c <vprintfmt+0x450>
  800775:	e9 c8 fb ff ff       	jmp    800342 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80077a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80077d:	5b                   	pop    %ebx
  80077e:	5e                   	pop    %esi
  80077f:	5f                   	pop    %edi
  800780:	5d                   	pop    %ebp
  800781:	c3                   	ret    

00800782 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800782:	55                   	push   %ebp
  800783:	89 e5                	mov    %esp,%ebp
  800785:	83 ec 18             	sub    $0x18,%esp
  800788:	8b 45 08             	mov    0x8(%ebp),%eax
  80078b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80078e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800791:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800795:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800798:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80079f:	85 c0                	test   %eax,%eax
  8007a1:	74 26                	je     8007c9 <vsnprintf+0x47>
  8007a3:	85 d2                	test   %edx,%edx
  8007a5:	7e 22                	jle    8007c9 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007a7:	ff 75 14             	pushl  0x14(%ebp)
  8007aa:	ff 75 10             	pushl  0x10(%ebp)
  8007ad:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007b0:	50                   	push   %eax
  8007b1:	68 e2 02 80 00       	push   $0x8002e2
  8007b6:	e8 61 fb ff ff       	call   80031c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007be:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007c4:	83 c4 10             	add    $0x10,%esp
  8007c7:	eb 05                	jmp    8007ce <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007c9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007ce:	c9                   	leave  
  8007cf:	c3                   	ret    

008007d0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007d0:	55                   	push   %ebp
  8007d1:	89 e5                	mov    %esp,%ebp
  8007d3:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007d6:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007d9:	50                   	push   %eax
  8007da:	ff 75 10             	pushl  0x10(%ebp)
  8007dd:	ff 75 0c             	pushl  0xc(%ebp)
  8007e0:	ff 75 08             	pushl  0x8(%ebp)
  8007e3:	e8 9a ff ff ff       	call   800782 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007e8:	c9                   	leave  
  8007e9:	c3                   	ret    

008007ea <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007ea:	55                   	push   %ebp
  8007eb:	89 e5                	mov    %esp,%ebp
  8007ed:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007f0:	b8 00 00 00 00       	mov    $0x0,%eax
  8007f5:	eb 03                	jmp    8007fa <strlen+0x10>
		n++;
  8007f7:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007fa:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007fe:	75 f7                	jne    8007f7 <strlen+0xd>
		n++;
	return n;
}
  800800:	5d                   	pop    %ebp
  800801:	c3                   	ret    

00800802 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800802:	55                   	push   %ebp
  800803:	89 e5                	mov    %esp,%ebp
  800805:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800808:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80080b:	ba 00 00 00 00       	mov    $0x0,%edx
  800810:	eb 03                	jmp    800815 <strnlen+0x13>
		n++;
  800812:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800815:	39 c2                	cmp    %eax,%edx
  800817:	74 08                	je     800821 <strnlen+0x1f>
  800819:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80081d:	75 f3                	jne    800812 <strnlen+0x10>
  80081f:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800821:	5d                   	pop    %ebp
  800822:	c3                   	ret    

00800823 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800823:	55                   	push   %ebp
  800824:	89 e5                	mov    %esp,%ebp
  800826:	53                   	push   %ebx
  800827:	8b 45 08             	mov    0x8(%ebp),%eax
  80082a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80082d:	89 c2                	mov    %eax,%edx
  80082f:	83 c2 01             	add    $0x1,%edx
  800832:	83 c1 01             	add    $0x1,%ecx
  800835:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800839:	88 5a ff             	mov    %bl,-0x1(%edx)
  80083c:	84 db                	test   %bl,%bl
  80083e:	75 ef                	jne    80082f <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800840:	5b                   	pop    %ebx
  800841:	5d                   	pop    %ebp
  800842:	c3                   	ret    

00800843 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800843:	55                   	push   %ebp
  800844:	89 e5                	mov    %esp,%ebp
  800846:	53                   	push   %ebx
  800847:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80084a:	53                   	push   %ebx
  80084b:	e8 9a ff ff ff       	call   8007ea <strlen>
  800850:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800853:	ff 75 0c             	pushl  0xc(%ebp)
  800856:	01 d8                	add    %ebx,%eax
  800858:	50                   	push   %eax
  800859:	e8 c5 ff ff ff       	call   800823 <strcpy>
	return dst;
}
  80085e:	89 d8                	mov    %ebx,%eax
  800860:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800863:	c9                   	leave  
  800864:	c3                   	ret    

00800865 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800865:	55                   	push   %ebp
  800866:	89 e5                	mov    %esp,%ebp
  800868:	56                   	push   %esi
  800869:	53                   	push   %ebx
  80086a:	8b 75 08             	mov    0x8(%ebp),%esi
  80086d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800870:	89 f3                	mov    %esi,%ebx
  800872:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800875:	89 f2                	mov    %esi,%edx
  800877:	eb 0f                	jmp    800888 <strncpy+0x23>
		*dst++ = *src;
  800879:	83 c2 01             	add    $0x1,%edx
  80087c:	0f b6 01             	movzbl (%ecx),%eax
  80087f:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800882:	80 39 01             	cmpb   $0x1,(%ecx)
  800885:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800888:	39 da                	cmp    %ebx,%edx
  80088a:	75 ed                	jne    800879 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80088c:	89 f0                	mov    %esi,%eax
  80088e:	5b                   	pop    %ebx
  80088f:	5e                   	pop    %esi
  800890:	5d                   	pop    %ebp
  800891:	c3                   	ret    

00800892 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800892:	55                   	push   %ebp
  800893:	89 e5                	mov    %esp,%ebp
  800895:	56                   	push   %esi
  800896:	53                   	push   %ebx
  800897:	8b 75 08             	mov    0x8(%ebp),%esi
  80089a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80089d:	8b 55 10             	mov    0x10(%ebp),%edx
  8008a0:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008a2:	85 d2                	test   %edx,%edx
  8008a4:	74 21                	je     8008c7 <strlcpy+0x35>
  8008a6:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8008aa:	89 f2                	mov    %esi,%edx
  8008ac:	eb 09                	jmp    8008b7 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008ae:	83 c2 01             	add    $0x1,%edx
  8008b1:	83 c1 01             	add    $0x1,%ecx
  8008b4:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008b7:	39 c2                	cmp    %eax,%edx
  8008b9:	74 09                	je     8008c4 <strlcpy+0x32>
  8008bb:	0f b6 19             	movzbl (%ecx),%ebx
  8008be:	84 db                	test   %bl,%bl
  8008c0:	75 ec                	jne    8008ae <strlcpy+0x1c>
  8008c2:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008c4:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008c7:	29 f0                	sub    %esi,%eax
}
  8008c9:	5b                   	pop    %ebx
  8008ca:	5e                   	pop    %esi
  8008cb:	5d                   	pop    %ebp
  8008cc:	c3                   	ret    

008008cd <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008cd:	55                   	push   %ebp
  8008ce:	89 e5                	mov    %esp,%ebp
  8008d0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008d3:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008d6:	eb 06                	jmp    8008de <strcmp+0x11>
		p++, q++;
  8008d8:	83 c1 01             	add    $0x1,%ecx
  8008db:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008de:	0f b6 01             	movzbl (%ecx),%eax
  8008e1:	84 c0                	test   %al,%al
  8008e3:	74 04                	je     8008e9 <strcmp+0x1c>
  8008e5:	3a 02                	cmp    (%edx),%al
  8008e7:	74 ef                	je     8008d8 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008e9:	0f b6 c0             	movzbl %al,%eax
  8008ec:	0f b6 12             	movzbl (%edx),%edx
  8008ef:	29 d0                	sub    %edx,%eax
}
  8008f1:	5d                   	pop    %ebp
  8008f2:	c3                   	ret    

008008f3 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008f3:	55                   	push   %ebp
  8008f4:	89 e5                	mov    %esp,%ebp
  8008f6:	53                   	push   %ebx
  8008f7:	8b 45 08             	mov    0x8(%ebp),%eax
  8008fa:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008fd:	89 c3                	mov    %eax,%ebx
  8008ff:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800902:	eb 06                	jmp    80090a <strncmp+0x17>
		n--, p++, q++;
  800904:	83 c0 01             	add    $0x1,%eax
  800907:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80090a:	39 d8                	cmp    %ebx,%eax
  80090c:	74 15                	je     800923 <strncmp+0x30>
  80090e:	0f b6 08             	movzbl (%eax),%ecx
  800911:	84 c9                	test   %cl,%cl
  800913:	74 04                	je     800919 <strncmp+0x26>
  800915:	3a 0a                	cmp    (%edx),%cl
  800917:	74 eb                	je     800904 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800919:	0f b6 00             	movzbl (%eax),%eax
  80091c:	0f b6 12             	movzbl (%edx),%edx
  80091f:	29 d0                	sub    %edx,%eax
  800921:	eb 05                	jmp    800928 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800923:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800928:	5b                   	pop    %ebx
  800929:	5d                   	pop    %ebp
  80092a:	c3                   	ret    

0080092b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80092b:	55                   	push   %ebp
  80092c:	89 e5                	mov    %esp,%ebp
  80092e:	8b 45 08             	mov    0x8(%ebp),%eax
  800931:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800935:	eb 07                	jmp    80093e <strchr+0x13>
		if (*s == c)
  800937:	38 ca                	cmp    %cl,%dl
  800939:	74 0f                	je     80094a <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80093b:	83 c0 01             	add    $0x1,%eax
  80093e:	0f b6 10             	movzbl (%eax),%edx
  800941:	84 d2                	test   %dl,%dl
  800943:	75 f2                	jne    800937 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800945:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80094a:	5d                   	pop    %ebp
  80094b:	c3                   	ret    

0080094c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80094c:	55                   	push   %ebp
  80094d:	89 e5                	mov    %esp,%ebp
  80094f:	8b 45 08             	mov    0x8(%ebp),%eax
  800952:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800956:	eb 03                	jmp    80095b <strfind+0xf>
  800958:	83 c0 01             	add    $0x1,%eax
  80095b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  80095e:	38 ca                	cmp    %cl,%dl
  800960:	74 04                	je     800966 <strfind+0x1a>
  800962:	84 d2                	test   %dl,%dl
  800964:	75 f2                	jne    800958 <strfind+0xc>
			break;
	return (char *) s;
}
  800966:	5d                   	pop    %ebp
  800967:	c3                   	ret    

00800968 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800968:	55                   	push   %ebp
  800969:	89 e5                	mov    %esp,%ebp
  80096b:	57                   	push   %edi
  80096c:	56                   	push   %esi
  80096d:	53                   	push   %ebx
  80096e:	8b 7d 08             	mov    0x8(%ebp),%edi
  800971:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800974:	85 c9                	test   %ecx,%ecx
  800976:	74 36                	je     8009ae <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800978:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80097e:	75 28                	jne    8009a8 <memset+0x40>
  800980:	f6 c1 03             	test   $0x3,%cl
  800983:	75 23                	jne    8009a8 <memset+0x40>
		c &= 0xFF;
  800985:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800989:	89 d3                	mov    %edx,%ebx
  80098b:	c1 e3 08             	shl    $0x8,%ebx
  80098e:	89 d6                	mov    %edx,%esi
  800990:	c1 e6 18             	shl    $0x18,%esi
  800993:	89 d0                	mov    %edx,%eax
  800995:	c1 e0 10             	shl    $0x10,%eax
  800998:	09 f0                	or     %esi,%eax
  80099a:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  80099c:	89 d8                	mov    %ebx,%eax
  80099e:	09 d0                	or     %edx,%eax
  8009a0:	c1 e9 02             	shr    $0x2,%ecx
  8009a3:	fc                   	cld    
  8009a4:	f3 ab                	rep stos %eax,%es:(%edi)
  8009a6:	eb 06                	jmp    8009ae <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009a8:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009ab:	fc                   	cld    
  8009ac:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009ae:	89 f8                	mov    %edi,%eax
  8009b0:	5b                   	pop    %ebx
  8009b1:	5e                   	pop    %esi
  8009b2:	5f                   	pop    %edi
  8009b3:	5d                   	pop    %ebp
  8009b4:	c3                   	ret    

008009b5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009b5:	55                   	push   %ebp
  8009b6:	89 e5                	mov    %esp,%ebp
  8009b8:	57                   	push   %edi
  8009b9:	56                   	push   %esi
  8009ba:	8b 45 08             	mov    0x8(%ebp),%eax
  8009bd:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009c0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009c3:	39 c6                	cmp    %eax,%esi
  8009c5:	73 35                	jae    8009fc <memmove+0x47>
  8009c7:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009ca:	39 d0                	cmp    %edx,%eax
  8009cc:	73 2e                	jae    8009fc <memmove+0x47>
		s += n;
		d += n;
  8009ce:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009d1:	89 d6                	mov    %edx,%esi
  8009d3:	09 fe                	or     %edi,%esi
  8009d5:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009db:	75 13                	jne    8009f0 <memmove+0x3b>
  8009dd:	f6 c1 03             	test   $0x3,%cl
  8009e0:	75 0e                	jne    8009f0 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009e2:	83 ef 04             	sub    $0x4,%edi
  8009e5:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009e8:	c1 e9 02             	shr    $0x2,%ecx
  8009eb:	fd                   	std    
  8009ec:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009ee:	eb 09                	jmp    8009f9 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009f0:	83 ef 01             	sub    $0x1,%edi
  8009f3:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009f6:	fd                   	std    
  8009f7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009f9:	fc                   	cld    
  8009fa:	eb 1d                	jmp    800a19 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009fc:	89 f2                	mov    %esi,%edx
  8009fe:	09 c2                	or     %eax,%edx
  800a00:	f6 c2 03             	test   $0x3,%dl
  800a03:	75 0f                	jne    800a14 <memmove+0x5f>
  800a05:	f6 c1 03             	test   $0x3,%cl
  800a08:	75 0a                	jne    800a14 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800a0a:	c1 e9 02             	shr    $0x2,%ecx
  800a0d:	89 c7                	mov    %eax,%edi
  800a0f:	fc                   	cld    
  800a10:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a12:	eb 05                	jmp    800a19 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a14:	89 c7                	mov    %eax,%edi
  800a16:	fc                   	cld    
  800a17:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a19:	5e                   	pop    %esi
  800a1a:	5f                   	pop    %edi
  800a1b:	5d                   	pop    %ebp
  800a1c:	c3                   	ret    

00800a1d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a1d:	55                   	push   %ebp
  800a1e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a20:	ff 75 10             	pushl  0x10(%ebp)
  800a23:	ff 75 0c             	pushl  0xc(%ebp)
  800a26:	ff 75 08             	pushl  0x8(%ebp)
  800a29:	e8 87 ff ff ff       	call   8009b5 <memmove>
}
  800a2e:	c9                   	leave  
  800a2f:	c3                   	ret    

00800a30 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a30:	55                   	push   %ebp
  800a31:	89 e5                	mov    %esp,%ebp
  800a33:	56                   	push   %esi
  800a34:	53                   	push   %ebx
  800a35:	8b 45 08             	mov    0x8(%ebp),%eax
  800a38:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a3b:	89 c6                	mov    %eax,%esi
  800a3d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a40:	eb 1a                	jmp    800a5c <memcmp+0x2c>
		if (*s1 != *s2)
  800a42:	0f b6 08             	movzbl (%eax),%ecx
  800a45:	0f b6 1a             	movzbl (%edx),%ebx
  800a48:	38 d9                	cmp    %bl,%cl
  800a4a:	74 0a                	je     800a56 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a4c:	0f b6 c1             	movzbl %cl,%eax
  800a4f:	0f b6 db             	movzbl %bl,%ebx
  800a52:	29 d8                	sub    %ebx,%eax
  800a54:	eb 0f                	jmp    800a65 <memcmp+0x35>
		s1++, s2++;
  800a56:	83 c0 01             	add    $0x1,%eax
  800a59:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a5c:	39 f0                	cmp    %esi,%eax
  800a5e:	75 e2                	jne    800a42 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a60:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a65:	5b                   	pop    %ebx
  800a66:	5e                   	pop    %esi
  800a67:	5d                   	pop    %ebp
  800a68:	c3                   	ret    

00800a69 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a69:	55                   	push   %ebp
  800a6a:	89 e5                	mov    %esp,%ebp
  800a6c:	53                   	push   %ebx
  800a6d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a70:	89 c1                	mov    %eax,%ecx
  800a72:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a75:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a79:	eb 0a                	jmp    800a85 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a7b:	0f b6 10             	movzbl (%eax),%edx
  800a7e:	39 da                	cmp    %ebx,%edx
  800a80:	74 07                	je     800a89 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a82:	83 c0 01             	add    $0x1,%eax
  800a85:	39 c8                	cmp    %ecx,%eax
  800a87:	72 f2                	jb     800a7b <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a89:	5b                   	pop    %ebx
  800a8a:	5d                   	pop    %ebp
  800a8b:	c3                   	ret    

00800a8c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a8c:	55                   	push   %ebp
  800a8d:	89 e5                	mov    %esp,%ebp
  800a8f:	57                   	push   %edi
  800a90:	56                   	push   %esi
  800a91:	53                   	push   %ebx
  800a92:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a95:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a98:	eb 03                	jmp    800a9d <strtol+0x11>
		s++;
  800a9a:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a9d:	0f b6 01             	movzbl (%ecx),%eax
  800aa0:	3c 20                	cmp    $0x20,%al
  800aa2:	74 f6                	je     800a9a <strtol+0xe>
  800aa4:	3c 09                	cmp    $0x9,%al
  800aa6:	74 f2                	je     800a9a <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800aa8:	3c 2b                	cmp    $0x2b,%al
  800aaa:	75 0a                	jne    800ab6 <strtol+0x2a>
		s++;
  800aac:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800aaf:	bf 00 00 00 00       	mov    $0x0,%edi
  800ab4:	eb 11                	jmp    800ac7 <strtol+0x3b>
  800ab6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800abb:	3c 2d                	cmp    $0x2d,%al
  800abd:	75 08                	jne    800ac7 <strtol+0x3b>
		s++, neg = 1;
  800abf:	83 c1 01             	add    $0x1,%ecx
  800ac2:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800ac7:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800acd:	75 15                	jne    800ae4 <strtol+0x58>
  800acf:	80 39 30             	cmpb   $0x30,(%ecx)
  800ad2:	75 10                	jne    800ae4 <strtol+0x58>
  800ad4:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ad8:	75 7c                	jne    800b56 <strtol+0xca>
		s += 2, base = 16;
  800ada:	83 c1 02             	add    $0x2,%ecx
  800add:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ae2:	eb 16                	jmp    800afa <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800ae4:	85 db                	test   %ebx,%ebx
  800ae6:	75 12                	jne    800afa <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ae8:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800aed:	80 39 30             	cmpb   $0x30,(%ecx)
  800af0:	75 08                	jne    800afa <strtol+0x6e>
		s++, base = 8;
  800af2:	83 c1 01             	add    $0x1,%ecx
  800af5:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800afa:	b8 00 00 00 00       	mov    $0x0,%eax
  800aff:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b02:	0f b6 11             	movzbl (%ecx),%edx
  800b05:	8d 72 d0             	lea    -0x30(%edx),%esi
  800b08:	89 f3                	mov    %esi,%ebx
  800b0a:	80 fb 09             	cmp    $0x9,%bl
  800b0d:	77 08                	ja     800b17 <strtol+0x8b>
			dig = *s - '0';
  800b0f:	0f be d2             	movsbl %dl,%edx
  800b12:	83 ea 30             	sub    $0x30,%edx
  800b15:	eb 22                	jmp    800b39 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b17:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b1a:	89 f3                	mov    %esi,%ebx
  800b1c:	80 fb 19             	cmp    $0x19,%bl
  800b1f:	77 08                	ja     800b29 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b21:	0f be d2             	movsbl %dl,%edx
  800b24:	83 ea 57             	sub    $0x57,%edx
  800b27:	eb 10                	jmp    800b39 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b29:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b2c:	89 f3                	mov    %esi,%ebx
  800b2e:	80 fb 19             	cmp    $0x19,%bl
  800b31:	77 16                	ja     800b49 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b33:	0f be d2             	movsbl %dl,%edx
  800b36:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b39:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b3c:	7d 0b                	jge    800b49 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b3e:	83 c1 01             	add    $0x1,%ecx
  800b41:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b45:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b47:	eb b9                	jmp    800b02 <strtol+0x76>

	if (endptr)
  800b49:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b4d:	74 0d                	je     800b5c <strtol+0xd0>
		*endptr = (char *) s;
  800b4f:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b52:	89 0e                	mov    %ecx,(%esi)
  800b54:	eb 06                	jmp    800b5c <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b56:	85 db                	test   %ebx,%ebx
  800b58:	74 98                	je     800af2 <strtol+0x66>
  800b5a:	eb 9e                	jmp    800afa <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b5c:	89 c2                	mov    %eax,%edx
  800b5e:	f7 da                	neg    %edx
  800b60:	85 ff                	test   %edi,%edi
  800b62:	0f 45 c2             	cmovne %edx,%eax
}
  800b65:	5b                   	pop    %ebx
  800b66:	5e                   	pop    %esi
  800b67:	5f                   	pop    %edi
  800b68:	5d                   	pop    %ebp
  800b69:	c3                   	ret    
  800b6a:	66 90                	xchg   %ax,%ax
  800b6c:	66 90                	xchg   %ax,%ax
  800b6e:	66 90                	xchg   %ax,%ax

00800b70 <__udivdi3>:
  800b70:	55                   	push   %ebp
  800b71:	57                   	push   %edi
  800b72:	56                   	push   %esi
  800b73:	53                   	push   %ebx
  800b74:	83 ec 1c             	sub    $0x1c,%esp
  800b77:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b7b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b7f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b83:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b87:	85 f6                	test   %esi,%esi
  800b89:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b8d:	89 ca                	mov    %ecx,%edx
  800b8f:	89 f8                	mov    %edi,%eax
  800b91:	75 3d                	jne    800bd0 <__udivdi3+0x60>
  800b93:	39 cf                	cmp    %ecx,%edi
  800b95:	0f 87 c5 00 00 00    	ja     800c60 <__udivdi3+0xf0>
  800b9b:	85 ff                	test   %edi,%edi
  800b9d:	89 fd                	mov    %edi,%ebp
  800b9f:	75 0b                	jne    800bac <__udivdi3+0x3c>
  800ba1:	b8 01 00 00 00       	mov    $0x1,%eax
  800ba6:	31 d2                	xor    %edx,%edx
  800ba8:	f7 f7                	div    %edi
  800baa:	89 c5                	mov    %eax,%ebp
  800bac:	89 c8                	mov    %ecx,%eax
  800bae:	31 d2                	xor    %edx,%edx
  800bb0:	f7 f5                	div    %ebp
  800bb2:	89 c1                	mov    %eax,%ecx
  800bb4:	89 d8                	mov    %ebx,%eax
  800bb6:	89 cf                	mov    %ecx,%edi
  800bb8:	f7 f5                	div    %ebp
  800bba:	89 c3                	mov    %eax,%ebx
  800bbc:	89 d8                	mov    %ebx,%eax
  800bbe:	89 fa                	mov    %edi,%edx
  800bc0:	83 c4 1c             	add    $0x1c,%esp
  800bc3:	5b                   	pop    %ebx
  800bc4:	5e                   	pop    %esi
  800bc5:	5f                   	pop    %edi
  800bc6:	5d                   	pop    %ebp
  800bc7:	c3                   	ret    
  800bc8:	90                   	nop
  800bc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bd0:	39 ce                	cmp    %ecx,%esi
  800bd2:	77 74                	ja     800c48 <__udivdi3+0xd8>
  800bd4:	0f bd fe             	bsr    %esi,%edi
  800bd7:	83 f7 1f             	xor    $0x1f,%edi
  800bda:	0f 84 98 00 00 00    	je     800c78 <__udivdi3+0x108>
  800be0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800be5:	89 f9                	mov    %edi,%ecx
  800be7:	89 c5                	mov    %eax,%ebp
  800be9:	29 fb                	sub    %edi,%ebx
  800beb:	d3 e6                	shl    %cl,%esi
  800bed:	89 d9                	mov    %ebx,%ecx
  800bef:	d3 ed                	shr    %cl,%ebp
  800bf1:	89 f9                	mov    %edi,%ecx
  800bf3:	d3 e0                	shl    %cl,%eax
  800bf5:	09 ee                	or     %ebp,%esi
  800bf7:	89 d9                	mov    %ebx,%ecx
  800bf9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800bfd:	89 d5                	mov    %edx,%ebp
  800bff:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c03:	d3 ed                	shr    %cl,%ebp
  800c05:	89 f9                	mov    %edi,%ecx
  800c07:	d3 e2                	shl    %cl,%edx
  800c09:	89 d9                	mov    %ebx,%ecx
  800c0b:	d3 e8                	shr    %cl,%eax
  800c0d:	09 c2                	or     %eax,%edx
  800c0f:	89 d0                	mov    %edx,%eax
  800c11:	89 ea                	mov    %ebp,%edx
  800c13:	f7 f6                	div    %esi
  800c15:	89 d5                	mov    %edx,%ebp
  800c17:	89 c3                	mov    %eax,%ebx
  800c19:	f7 64 24 0c          	mull   0xc(%esp)
  800c1d:	39 d5                	cmp    %edx,%ebp
  800c1f:	72 10                	jb     800c31 <__udivdi3+0xc1>
  800c21:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c25:	89 f9                	mov    %edi,%ecx
  800c27:	d3 e6                	shl    %cl,%esi
  800c29:	39 c6                	cmp    %eax,%esi
  800c2b:	73 07                	jae    800c34 <__udivdi3+0xc4>
  800c2d:	39 d5                	cmp    %edx,%ebp
  800c2f:	75 03                	jne    800c34 <__udivdi3+0xc4>
  800c31:	83 eb 01             	sub    $0x1,%ebx
  800c34:	31 ff                	xor    %edi,%edi
  800c36:	89 d8                	mov    %ebx,%eax
  800c38:	89 fa                	mov    %edi,%edx
  800c3a:	83 c4 1c             	add    $0x1c,%esp
  800c3d:	5b                   	pop    %ebx
  800c3e:	5e                   	pop    %esi
  800c3f:	5f                   	pop    %edi
  800c40:	5d                   	pop    %ebp
  800c41:	c3                   	ret    
  800c42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c48:	31 ff                	xor    %edi,%edi
  800c4a:	31 db                	xor    %ebx,%ebx
  800c4c:	89 d8                	mov    %ebx,%eax
  800c4e:	89 fa                	mov    %edi,%edx
  800c50:	83 c4 1c             	add    $0x1c,%esp
  800c53:	5b                   	pop    %ebx
  800c54:	5e                   	pop    %esi
  800c55:	5f                   	pop    %edi
  800c56:	5d                   	pop    %ebp
  800c57:	c3                   	ret    
  800c58:	90                   	nop
  800c59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c60:	89 d8                	mov    %ebx,%eax
  800c62:	f7 f7                	div    %edi
  800c64:	31 ff                	xor    %edi,%edi
  800c66:	89 c3                	mov    %eax,%ebx
  800c68:	89 d8                	mov    %ebx,%eax
  800c6a:	89 fa                	mov    %edi,%edx
  800c6c:	83 c4 1c             	add    $0x1c,%esp
  800c6f:	5b                   	pop    %ebx
  800c70:	5e                   	pop    %esi
  800c71:	5f                   	pop    %edi
  800c72:	5d                   	pop    %ebp
  800c73:	c3                   	ret    
  800c74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c78:	39 ce                	cmp    %ecx,%esi
  800c7a:	72 0c                	jb     800c88 <__udivdi3+0x118>
  800c7c:	31 db                	xor    %ebx,%ebx
  800c7e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c82:	0f 87 34 ff ff ff    	ja     800bbc <__udivdi3+0x4c>
  800c88:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c8d:	e9 2a ff ff ff       	jmp    800bbc <__udivdi3+0x4c>
  800c92:	66 90                	xchg   %ax,%ax
  800c94:	66 90                	xchg   %ax,%ax
  800c96:	66 90                	xchg   %ax,%ax
  800c98:	66 90                	xchg   %ax,%ax
  800c9a:	66 90                	xchg   %ax,%ax
  800c9c:	66 90                	xchg   %ax,%ax
  800c9e:	66 90                	xchg   %ax,%ax

00800ca0 <__umoddi3>:
  800ca0:	55                   	push   %ebp
  800ca1:	57                   	push   %edi
  800ca2:	56                   	push   %esi
  800ca3:	53                   	push   %ebx
  800ca4:	83 ec 1c             	sub    $0x1c,%esp
  800ca7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800cab:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800caf:	8b 74 24 34          	mov    0x34(%esp),%esi
  800cb3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800cb7:	85 d2                	test   %edx,%edx
  800cb9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800cbd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800cc1:	89 f3                	mov    %esi,%ebx
  800cc3:	89 3c 24             	mov    %edi,(%esp)
  800cc6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800cca:	75 1c                	jne    800ce8 <__umoddi3+0x48>
  800ccc:	39 f7                	cmp    %esi,%edi
  800cce:	76 50                	jbe    800d20 <__umoddi3+0x80>
  800cd0:	89 c8                	mov    %ecx,%eax
  800cd2:	89 f2                	mov    %esi,%edx
  800cd4:	f7 f7                	div    %edi
  800cd6:	89 d0                	mov    %edx,%eax
  800cd8:	31 d2                	xor    %edx,%edx
  800cda:	83 c4 1c             	add    $0x1c,%esp
  800cdd:	5b                   	pop    %ebx
  800cde:	5e                   	pop    %esi
  800cdf:	5f                   	pop    %edi
  800ce0:	5d                   	pop    %ebp
  800ce1:	c3                   	ret    
  800ce2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ce8:	39 f2                	cmp    %esi,%edx
  800cea:	89 d0                	mov    %edx,%eax
  800cec:	77 52                	ja     800d40 <__umoddi3+0xa0>
  800cee:	0f bd ea             	bsr    %edx,%ebp
  800cf1:	83 f5 1f             	xor    $0x1f,%ebp
  800cf4:	75 5a                	jne    800d50 <__umoddi3+0xb0>
  800cf6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800cfa:	0f 82 e0 00 00 00    	jb     800de0 <__umoddi3+0x140>
  800d00:	39 0c 24             	cmp    %ecx,(%esp)
  800d03:	0f 86 d7 00 00 00    	jbe    800de0 <__umoddi3+0x140>
  800d09:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d0d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d11:	83 c4 1c             	add    $0x1c,%esp
  800d14:	5b                   	pop    %ebx
  800d15:	5e                   	pop    %esi
  800d16:	5f                   	pop    %edi
  800d17:	5d                   	pop    %ebp
  800d18:	c3                   	ret    
  800d19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d20:	85 ff                	test   %edi,%edi
  800d22:	89 fd                	mov    %edi,%ebp
  800d24:	75 0b                	jne    800d31 <__umoddi3+0x91>
  800d26:	b8 01 00 00 00       	mov    $0x1,%eax
  800d2b:	31 d2                	xor    %edx,%edx
  800d2d:	f7 f7                	div    %edi
  800d2f:	89 c5                	mov    %eax,%ebp
  800d31:	89 f0                	mov    %esi,%eax
  800d33:	31 d2                	xor    %edx,%edx
  800d35:	f7 f5                	div    %ebp
  800d37:	89 c8                	mov    %ecx,%eax
  800d39:	f7 f5                	div    %ebp
  800d3b:	89 d0                	mov    %edx,%eax
  800d3d:	eb 99                	jmp    800cd8 <__umoddi3+0x38>
  800d3f:	90                   	nop
  800d40:	89 c8                	mov    %ecx,%eax
  800d42:	89 f2                	mov    %esi,%edx
  800d44:	83 c4 1c             	add    $0x1c,%esp
  800d47:	5b                   	pop    %ebx
  800d48:	5e                   	pop    %esi
  800d49:	5f                   	pop    %edi
  800d4a:	5d                   	pop    %ebp
  800d4b:	c3                   	ret    
  800d4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d50:	8b 34 24             	mov    (%esp),%esi
  800d53:	bf 20 00 00 00       	mov    $0x20,%edi
  800d58:	89 e9                	mov    %ebp,%ecx
  800d5a:	29 ef                	sub    %ebp,%edi
  800d5c:	d3 e0                	shl    %cl,%eax
  800d5e:	89 f9                	mov    %edi,%ecx
  800d60:	89 f2                	mov    %esi,%edx
  800d62:	d3 ea                	shr    %cl,%edx
  800d64:	89 e9                	mov    %ebp,%ecx
  800d66:	09 c2                	or     %eax,%edx
  800d68:	89 d8                	mov    %ebx,%eax
  800d6a:	89 14 24             	mov    %edx,(%esp)
  800d6d:	89 f2                	mov    %esi,%edx
  800d6f:	d3 e2                	shl    %cl,%edx
  800d71:	89 f9                	mov    %edi,%ecx
  800d73:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d77:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d7b:	d3 e8                	shr    %cl,%eax
  800d7d:	89 e9                	mov    %ebp,%ecx
  800d7f:	89 c6                	mov    %eax,%esi
  800d81:	d3 e3                	shl    %cl,%ebx
  800d83:	89 f9                	mov    %edi,%ecx
  800d85:	89 d0                	mov    %edx,%eax
  800d87:	d3 e8                	shr    %cl,%eax
  800d89:	89 e9                	mov    %ebp,%ecx
  800d8b:	09 d8                	or     %ebx,%eax
  800d8d:	89 d3                	mov    %edx,%ebx
  800d8f:	89 f2                	mov    %esi,%edx
  800d91:	f7 34 24             	divl   (%esp)
  800d94:	89 d6                	mov    %edx,%esi
  800d96:	d3 e3                	shl    %cl,%ebx
  800d98:	f7 64 24 04          	mull   0x4(%esp)
  800d9c:	39 d6                	cmp    %edx,%esi
  800d9e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800da2:	89 d1                	mov    %edx,%ecx
  800da4:	89 c3                	mov    %eax,%ebx
  800da6:	72 08                	jb     800db0 <__umoddi3+0x110>
  800da8:	75 11                	jne    800dbb <__umoddi3+0x11b>
  800daa:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800dae:	73 0b                	jae    800dbb <__umoddi3+0x11b>
  800db0:	2b 44 24 04          	sub    0x4(%esp),%eax
  800db4:	1b 14 24             	sbb    (%esp),%edx
  800db7:	89 d1                	mov    %edx,%ecx
  800db9:	89 c3                	mov    %eax,%ebx
  800dbb:	8b 54 24 08          	mov    0x8(%esp),%edx
  800dbf:	29 da                	sub    %ebx,%edx
  800dc1:	19 ce                	sbb    %ecx,%esi
  800dc3:	89 f9                	mov    %edi,%ecx
  800dc5:	89 f0                	mov    %esi,%eax
  800dc7:	d3 e0                	shl    %cl,%eax
  800dc9:	89 e9                	mov    %ebp,%ecx
  800dcb:	d3 ea                	shr    %cl,%edx
  800dcd:	89 e9                	mov    %ebp,%ecx
  800dcf:	d3 ee                	shr    %cl,%esi
  800dd1:	09 d0                	or     %edx,%eax
  800dd3:	89 f2                	mov    %esi,%edx
  800dd5:	83 c4 1c             	add    $0x1c,%esp
  800dd8:	5b                   	pop    %ebx
  800dd9:	5e                   	pop    %esi
  800dda:	5f                   	pop    %edi
  800ddb:	5d                   	pop    %ebp
  800ddc:	c3                   	ret    
  800ddd:	8d 76 00             	lea    0x0(%esi),%esi
  800de0:	29 f9                	sub    %edi,%ecx
  800de2:	19 d6                	sbb    %edx,%esi
  800de4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800de8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800dec:	e9 18 ff ff ff       	jmp    800d09 <__umoddi3+0x69>
