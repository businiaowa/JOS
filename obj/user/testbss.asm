
obj/user/testbss:     file format elf32-i386


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
  80002c:	e8 ab 00 00 00       	call   8000dc <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

uint32_t bigarray[ARRAYSIZE];

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 14             	sub    $0x14,%esp
	int i;

	cprintf("Making sure bss works right...\n");
  800039:	68 a0 0e 80 00       	push   $0x800ea0
  80003e:	e8 cd 01 00 00       	call   800210 <cprintf>
  800043:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < ARRAYSIZE; i++)
  800046:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
  80004b:	83 3c 85 20 20 80 00 	cmpl   $0x0,0x802020(,%eax,4)
  800052:	00 
  800053:	74 12                	je     800067 <umain+0x34>
			panic("bigarray[%d] isn't cleared!\n", i);
  800055:	50                   	push   %eax
  800056:	68 1b 0f 80 00       	push   $0x800f1b
  80005b:	6a 11                	push   $0x11
  80005d:	68 38 0f 80 00       	push   $0x800f38
  800062:	e8 d0 00 00 00       	call   800137 <_panic>
umain(int argc, char **argv)
{
	int i;

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
  800067:	83 c0 01             	add    $0x1,%eax
  80006a:	3d 00 00 10 00       	cmp    $0x100000,%eax
  80006f:	75 da                	jne    80004b <umain+0x18>
  800071:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
  800076:	89 04 85 20 20 80 00 	mov    %eax,0x802020(,%eax,4)

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
  80007d:	83 c0 01             	add    $0x1,%eax
  800080:	3d 00 00 10 00       	cmp    $0x100000,%eax
  800085:	75 ef                	jne    800076 <umain+0x43>
  800087:	b8 00 00 00 00       	mov    $0x0,%eax
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != i)
  80008c:	3b 04 85 20 20 80 00 	cmp    0x802020(,%eax,4),%eax
  800093:	74 12                	je     8000a7 <umain+0x74>
			panic("bigarray[%d] didn't hold its value!\n", i);
  800095:	50                   	push   %eax
  800096:	68 c0 0e 80 00       	push   $0x800ec0
  80009b:	6a 16                	push   $0x16
  80009d:	68 38 0f 80 00       	push   $0x800f38
  8000a2:	e8 90 00 00 00       	call   800137 <_panic>
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
  8000a7:	83 c0 01             	add    $0x1,%eax
  8000aa:	3d 00 00 10 00       	cmp    $0x100000,%eax
  8000af:	75 db                	jne    80008c <umain+0x59>
		if (bigarray[i] != i)
			panic("bigarray[%d] didn't hold its value!\n", i);

	cprintf("Yes, good.  Now doing a wild write off the end...\n");
  8000b1:	83 ec 0c             	sub    $0xc,%esp
  8000b4:	68 e8 0e 80 00       	push   $0x800ee8
  8000b9:	e8 52 01 00 00       	call   800210 <cprintf>
	bigarray[ARRAYSIZE+1024] = 0;
  8000be:	c7 05 20 30 c0 00 00 	movl   $0x0,0xc03020
  8000c5:	00 00 00 
	panic("SHOULD HAVE TRAPPED!!!");
  8000c8:	83 c4 0c             	add    $0xc,%esp
  8000cb:	68 47 0f 80 00       	push   $0x800f47
  8000d0:	6a 1a                	push   $0x1a
  8000d2:	68 38 0f 80 00       	push   $0x800f38
  8000d7:	e8 5b 00 00 00       	call   800137 <_panic>

008000dc <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000dc:	55                   	push   %ebp
  8000dd:	89 e5                	mov    %esp,%ebp
  8000df:	56                   	push   %esi
  8000e0:	53                   	push   %ebx
  8000e1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000e4:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  8000e7:	e8 ed 0a 00 00       	call   800bd9 <sys_getenvid>
  8000ec:	25 ff 03 00 00       	and    $0x3ff,%eax
  8000f1:	8d 04 40             	lea    (%eax,%eax,2),%eax
  8000f4:	c1 e0 05             	shl    $0x5,%eax
  8000f7:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8000fc:	a3 20 20 c0 00       	mov    %eax,0xc02020

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800101:	85 db                	test   %ebx,%ebx
  800103:	7e 07                	jle    80010c <libmain+0x30>
		binaryname = argv[0];
  800105:	8b 06                	mov    (%esi),%eax
  800107:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80010c:	83 ec 08             	sub    $0x8,%esp
  80010f:	56                   	push   %esi
  800110:	53                   	push   %ebx
  800111:	e8 1d ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800116:	e8 0a 00 00 00       	call   800125 <exit>
}
  80011b:	83 c4 10             	add    $0x10,%esp
  80011e:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800121:	5b                   	pop    %ebx
  800122:	5e                   	pop    %esi
  800123:	5d                   	pop    %ebp
  800124:	c3                   	ret    

00800125 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800125:	55                   	push   %ebp
  800126:	89 e5                	mov    %esp,%ebp
  800128:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80012b:	6a 00                	push   $0x0
  80012d:	e8 66 0a 00 00       	call   800b98 <sys_env_destroy>
}
  800132:	83 c4 10             	add    $0x10,%esp
  800135:	c9                   	leave  
  800136:	c3                   	ret    

00800137 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800137:	55                   	push   %ebp
  800138:	89 e5                	mov    %esp,%ebp
  80013a:	56                   	push   %esi
  80013b:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80013c:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80013f:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800145:	e8 8f 0a 00 00       	call   800bd9 <sys_getenvid>
  80014a:	83 ec 0c             	sub    $0xc,%esp
  80014d:	ff 75 0c             	pushl  0xc(%ebp)
  800150:	ff 75 08             	pushl  0x8(%ebp)
  800153:	56                   	push   %esi
  800154:	50                   	push   %eax
  800155:	68 68 0f 80 00       	push   $0x800f68
  80015a:	e8 b1 00 00 00       	call   800210 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80015f:	83 c4 18             	add    $0x18,%esp
  800162:	53                   	push   %ebx
  800163:	ff 75 10             	pushl  0x10(%ebp)
  800166:	e8 54 00 00 00       	call   8001bf <vcprintf>
	cprintf("\n");
  80016b:	c7 04 24 36 0f 80 00 	movl   $0x800f36,(%esp)
  800172:	e8 99 00 00 00       	call   800210 <cprintf>
  800177:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80017a:	cc                   	int3   
  80017b:	eb fd                	jmp    80017a <_panic+0x43>

0080017d <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80017d:	55                   	push   %ebp
  80017e:	89 e5                	mov    %esp,%ebp
  800180:	53                   	push   %ebx
  800181:	83 ec 04             	sub    $0x4,%esp
  800184:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800187:	8b 13                	mov    (%ebx),%edx
  800189:	8d 42 01             	lea    0x1(%edx),%eax
  80018c:	89 03                	mov    %eax,(%ebx)
  80018e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800191:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800195:	3d ff 00 00 00       	cmp    $0xff,%eax
  80019a:	75 1a                	jne    8001b6 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  80019c:	83 ec 08             	sub    $0x8,%esp
  80019f:	68 ff 00 00 00       	push   $0xff
  8001a4:	8d 43 08             	lea    0x8(%ebx),%eax
  8001a7:	50                   	push   %eax
  8001a8:	e8 ae 09 00 00       	call   800b5b <sys_cputs>
		b->idx = 0;
  8001ad:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001b3:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001b6:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001ba:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001bd:	c9                   	leave  
  8001be:	c3                   	ret    

008001bf <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001bf:	55                   	push   %ebp
  8001c0:	89 e5                	mov    %esp,%ebp
  8001c2:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001c8:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001cf:	00 00 00 
	b.cnt = 0;
  8001d2:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001d9:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001dc:	ff 75 0c             	pushl  0xc(%ebp)
  8001df:	ff 75 08             	pushl  0x8(%ebp)
  8001e2:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001e8:	50                   	push   %eax
  8001e9:	68 7d 01 80 00       	push   $0x80017d
  8001ee:	e8 1a 01 00 00       	call   80030d <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001f3:	83 c4 08             	add    $0x8,%esp
  8001f6:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001fc:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800202:	50                   	push   %eax
  800203:	e8 53 09 00 00       	call   800b5b <sys_cputs>

	return b.cnt;
}
  800208:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80020e:	c9                   	leave  
  80020f:	c3                   	ret    

00800210 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800210:	55                   	push   %ebp
  800211:	89 e5                	mov    %esp,%ebp
  800213:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800216:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800219:	50                   	push   %eax
  80021a:	ff 75 08             	pushl  0x8(%ebp)
  80021d:	e8 9d ff ff ff       	call   8001bf <vcprintf>
	va_end(ap);

	return cnt;
}
  800222:	c9                   	leave  
  800223:	c3                   	ret    

00800224 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800224:	55                   	push   %ebp
  800225:	89 e5                	mov    %esp,%ebp
  800227:	57                   	push   %edi
  800228:	56                   	push   %esi
  800229:	53                   	push   %ebx
  80022a:	83 ec 1c             	sub    $0x1c,%esp
  80022d:	89 c7                	mov    %eax,%edi
  80022f:	89 d6                	mov    %edx,%esi
  800231:	8b 45 08             	mov    0x8(%ebp),%eax
  800234:	8b 55 0c             	mov    0xc(%ebp),%edx
  800237:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80023a:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80023d:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800240:	bb 00 00 00 00       	mov    $0x0,%ebx
  800245:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800248:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80024b:	39 d3                	cmp    %edx,%ebx
  80024d:	72 05                	jb     800254 <printnum+0x30>
  80024f:	39 45 10             	cmp    %eax,0x10(%ebp)
  800252:	77 45                	ja     800299 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800254:	83 ec 0c             	sub    $0xc,%esp
  800257:	ff 75 18             	pushl  0x18(%ebp)
  80025a:	8b 45 14             	mov    0x14(%ebp),%eax
  80025d:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800260:	53                   	push   %ebx
  800261:	ff 75 10             	pushl  0x10(%ebp)
  800264:	83 ec 08             	sub    $0x8,%esp
  800267:	ff 75 e4             	pushl  -0x1c(%ebp)
  80026a:	ff 75 e0             	pushl  -0x20(%ebp)
  80026d:	ff 75 dc             	pushl  -0x24(%ebp)
  800270:	ff 75 d8             	pushl  -0x28(%ebp)
  800273:	e8 88 09 00 00       	call   800c00 <__udivdi3>
  800278:	83 c4 18             	add    $0x18,%esp
  80027b:	52                   	push   %edx
  80027c:	50                   	push   %eax
  80027d:	89 f2                	mov    %esi,%edx
  80027f:	89 f8                	mov    %edi,%eax
  800281:	e8 9e ff ff ff       	call   800224 <printnum>
  800286:	83 c4 20             	add    $0x20,%esp
  800289:	eb 18                	jmp    8002a3 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80028b:	83 ec 08             	sub    $0x8,%esp
  80028e:	56                   	push   %esi
  80028f:	ff 75 18             	pushl  0x18(%ebp)
  800292:	ff d7                	call   *%edi
  800294:	83 c4 10             	add    $0x10,%esp
  800297:	eb 03                	jmp    80029c <printnum+0x78>
  800299:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80029c:	83 eb 01             	sub    $0x1,%ebx
  80029f:	85 db                	test   %ebx,%ebx
  8002a1:	7f e8                	jg     80028b <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002a3:	83 ec 08             	sub    $0x8,%esp
  8002a6:	56                   	push   %esi
  8002a7:	83 ec 04             	sub    $0x4,%esp
  8002aa:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002ad:	ff 75 e0             	pushl  -0x20(%ebp)
  8002b0:	ff 75 dc             	pushl  -0x24(%ebp)
  8002b3:	ff 75 d8             	pushl  -0x28(%ebp)
  8002b6:	e8 75 0a 00 00       	call   800d30 <__umoddi3>
  8002bb:	83 c4 14             	add    $0x14,%esp
  8002be:	0f be 80 8c 0f 80 00 	movsbl 0x800f8c(%eax),%eax
  8002c5:	50                   	push   %eax
  8002c6:	ff d7                	call   *%edi
}
  8002c8:	83 c4 10             	add    $0x10,%esp
  8002cb:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002ce:	5b                   	pop    %ebx
  8002cf:	5e                   	pop    %esi
  8002d0:	5f                   	pop    %edi
  8002d1:	5d                   	pop    %ebp
  8002d2:	c3                   	ret    

008002d3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002d3:	55                   	push   %ebp
  8002d4:	89 e5                	mov    %esp,%ebp
  8002d6:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002d9:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002dd:	8b 10                	mov    (%eax),%edx
  8002df:	3b 50 04             	cmp    0x4(%eax),%edx
  8002e2:	73 0a                	jae    8002ee <sprintputch+0x1b>
		*b->buf++ = ch;
  8002e4:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002e7:	89 08                	mov    %ecx,(%eax)
  8002e9:	8b 45 08             	mov    0x8(%ebp),%eax
  8002ec:	88 02                	mov    %al,(%edx)
}
  8002ee:	5d                   	pop    %ebp
  8002ef:	c3                   	ret    

008002f0 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002f0:	55                   	push   %ebp
  8002f1:	89 e5                	mov    %esp,%ebp
  8002f3:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8002f6:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002f9:	50                   	push   %eax
  8002fa:	ff 75 10             	pushl  0x10(%ebp)
  8002fd:	ff 75 0c             	pushl  0xc(%ebp)
  800300:	ff 75 08             	pushl  0x8(%ebp)
  800303:	e8 05 00 00 00       	call   80030d <vprintfmt>
	va_end(ap);
}
  800308:	83 c4 10             	add    $0x10,%esp
  80030b:	c9                   	leave  
  80030c:	c3                   	ret    

0080030d <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80030d:	55                   	push   %ebp
  80030e:	89 e5                	mov    %esp,%ebp
  800310:	57                   	push   %edi
  800311:	56                   	push   %esi
  800312:	53                   	push   %ebx
  800313:	83 ec 2c             	sub    $0x2c,%esp
  800316:	8b 75 08             	mov    0x8(%ebp),%esi
  800319:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80031c:	8b 7d 10             	mov    0x10(%ebp),%edi
  80031f:	eb 12                	jmp    800333 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800321:	85 c0                	test   %eax,%eax
  800323:	0f 84 42 04 00 00    	je     80076b <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800329:	83 ec 08             	sub    $0x8,%esp
  80032c:	53                   	push   %ebx
  80032d:	50                   	push   %eax
  80032e:	ff d6                	call   *%esi
  800330:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800333:	83 c7 01             	add    $0x1,%edi
  800336:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80033a:	83 f8 25             	cmp    $0x25,%eax
  80033d:	75 e2                	jne    800321 <vprintfmt+0x14>
  80033f:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800343:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80034a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800351:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800358:	b9 00 00 00 00       	mov    $0x0,%ecx
  80035d:	eb 07                	jmp    800366 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80035f:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800362:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800366:	8d 47 01             	lea    0x1(%edi),%eax
  800369:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80036c:	0f b6 07             	movzbl (%edi),%eax
  80036f:	0f b6 d0             	movzbl %al,%edx
  800372:	83 e8 23             	sub    $0x23,%eax
  800375:	3c 55                	cmp    $0x55,%al
  800377:	0f 87 d3 03 00 00    	ja     800750 <vprintfmt+0x443>
  80037d:	0f b6 c0             	movzbl %al,%eax
  800380:	ff 24 85 20 10 80 00 	jmp    *0x801020(,%eax,4)
  800387:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80038a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80038e:	eb d6                	jmp    800366 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800390:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800393:	b8 00 00 00 00       	mov    $0x0,%eax
  800398:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  80039b:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80039e:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8003a2:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8003a5:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8003a8:	83 f9 09             	cmp    $0x9,%ecx
  8003ab:	77 3f                	ja     8003ec <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003ad:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003b0:	eb e9                	jmp    80039b <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003b2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b5:	8b 00                	mov    (%eax),%eax
  8003b7:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8003ba:	8b 45 14             	mov    0x14(%ebp),%eax
  8003bd:	8d 40 04             	lea    0x4(%eax),%eax
  8003c0:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003c6:	eb 2a                	jmp    8003f2 <vprintfmt+0xe5>
  8003c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003cb:	85 c0                	test   %eax,%eax
  8003cd:	ba 00 00 00 00       	mov    $0x0,%edx
  8003d2:	0f 49 d0             	cmovns %eax,%edx
  8003d5:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003db:	eb 89                	jmp    800366 <vprintfmt+0x59>
  8003dd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003e0:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8003e7:	e9 7a ff ff ff       	jmp    800366 <vprintfmt+0x59>
  8003ec:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  8003ef:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8003f2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003f6:	0f 89 6a ff ff ff    	jns    800366 <vprintfmt+0x59>
				width = precision, precision = -1;
  8003fc:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8003ff:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800402:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800409:	e9 58 ff ff ff       	jmp    800366 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80040e:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800411:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800414:	e9 4d ff ff ff       	jmp    800366 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800419:	8b 45 14             	mov    0x14(%ebp),%eax
  80041c:	8d 78 04             	lea    0x4(%eax),%edi
  80041f:	83 ec 08             	sub    $0x8,%esp
  800422:	53                   	push   %ebx
  800423:	ff 30                	pushl  (%eax)
  800425:	ff d6                	call   *%esi
			break;
  800427:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80042a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80042d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800430:	e9 fe fe ff ff       	jmp    800333 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800435:	8b 45 14             	mov    0x14(%ebp),%eax
  800438:	8d 78 04             	lea    0x4(%eax),%edi
  80043b:	8b 00                	mov    (%eax),%eax
  80043d:	99                   	cltd   
  80043e:	31 d0                	xor    %edx,%eax
  800440:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800442:	83 f8 07             	cmp    $0x7,%eax
  800445:	7f 0b                	jg     800452 <vprintfmt+0x145>
  800447:	8b 14 85 80 11 80 00 	mov    0x801180(,%eax,4),%edx
  80044e:	85 d2                	test   %edx,%edx
  800450:	75 1b                	jne    80046d <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800452:	50                   	push   %eax
  800453:	68 a4 0f 80 00       	push   $0x800fa4
  800458:	53                   	push   %ebx
  800459:	56                   	push   %esi
  80045a:	e8 91 fe ff ff       	call   8002f0 <printfmt>
  80045f:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800462:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800465:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800468:	e9 c6 fe ff ff       	jmp    800333 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80046d:	52                   	push   %edx
  80046e:	68 ad 0f 80 00       	push   $0x800fad
  800473:	53                   	push   %ebx
  800474:	56                   	push   %esi
  800475:	e8 76 fe ff ff       	call   8002f0 <printfmt>
  80047a:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80047d:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800480:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800483:	e9 ab fe ff ff       	jmp    800333 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800488:	8b 45 14             	mov    0x14(%ebp),%eax
  80048b:	83 c0 04             	add    $0x4,%eax
  80048e:	89 45 cc             	mov    %eax,-0x34(%ebp)
  800491:	8b 45 14             	mov    0x14(%ebp),%eax
  800494:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800496:	85 ff                	test   %edi,%edi
  800498:	b8 9d 0f 80 00       	mov    $0x800f9d,%eax
  80049d:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004a0:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004a4:	0f 8e 94 00 00 00    	jle    80053e <vprintfmt+0x231>
  8004aa:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004ae:	0f 84 98 00 00 00    	je     80054c <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004b4:	83 ec 08             	sub    $0x8,%esp
  8004b7:	ff 75 d0             	pushl  -0x30(%ebp)
  8004ba:	57                   	push   %edi
  8004bb:	e8 33 03 00 00       	call   8007f3 <strnlen>
  8004c0:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004c3:	29 c1                	sub    %eax,%ecx
  8004c5:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8004c8:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004cb:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004cf:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004d2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004d5:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004d7:	eb 0f                	jmp    8004e8 <vprintfmt+0x1db>
					putch(padc, putdat);
  8004d9:	83 ec 08             	sub    $0x8,%esp
  8004dc:	53                   	push   %ebx
  8004dd:	ff 75 e0             	pushl  -0x20(%ebp)
  8004e0:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004e2:	83 ef 01             	sub    $0x1,%edi
  8004e5:	83 c4 10             	add    $0x10,%esp
  8004e8:	85 ff                	test   %edi,%edi
  8004ea:	7f ed                	jg     8004d9 <vprintfmt+0x1cc>
  8004ec:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8004ef:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  8004f2:	85 c9                	test   %ecx,%ecx
  8004f4:	b8 00 00 00 00       	mov    $0x0,%eax
  8004f9:	0f 49 c1             	cmovns %ecx,%eax
  8004fc:	29 c1                	sub    %eax,%ecx
  8004fe:	89 75 08             	mov    %esi,0x8(%ebp)
  800501:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800504:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800507:	89 cb                	mov    %ecx,%ebx
  800509:	eb 4d                	jmp    800558 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80050b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80050f:	74 1b                	je     80052c <vprintfmt+0x21f>
  800511:	0f be c0             	movsbl %al,%eax
  800514:	83 e8 20             	sub    $0x20,%eax
  800517:	83 f8 5e             	cmp    $0x5e,%eax
  80051a:	76 10                	jbe    80052c <vprintfmt+0x21f>
					putch('?', putdat);
  80051c:	83 ec 08             	sub    $0x8,%esp
  80051f:	ff 75 0c             	pushl  0xc(%ebp)
  800522:	6a 3f                	push   $0x3f
  800524:	ff 55 08             	call   *0x8(%ebp)
  800527:	83 c4 10             	add    $0x10,%esp
  80052a:	eb 0d                	jmp    800539 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  80052c:	83 ec 08             	sub    $0x8,%esp
  80052f:	ff 75 0c             	pushl  0xc(%ebp)
  800532:	52                   	push   %edx
  800533:	ff 55 08             	call   *0x8(%ebp)
  800536:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800539:	83 eb 01             	sub    $0x1,%ebx
  80053c:	eb 1a                	jmp    800558 <vprintfmt+0x24b>
  80053e:	89 75 08             	mov    %esi,0x8(%ebp)
  800541:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800544:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800547:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80054a:	eb 0c                	jmp    800558 <vprintfmt+0x24b>
  80054c:	89 75 08             	mov    %esi,0x8(%ebp)
  80054f:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800552:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800555:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800558:	83 c7 01             	add    $0x1,%edi
  80055b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80055f:	0f be d0             	movsbl %al,%edx
  800562:	85 d2                	test   %edx,%edx
  800564:	74 23                	je     800589 <vprintfmt+0x27c>
  800566:	85 f6                	test   %esi,%esi
  800568:	78 a1                	js     80050b <vprintfmt+0x1fe>
  80056a:	83 ee 01             	sub    $0x1,%esi
  80056d:	79 9c                	jns    80050b <vprintfmt+0x1fe>
  80056f:	89 df                	mov    %ebx,%edi
  800571:	8b 75 08             	mov    0x8(%ebp),%esi
  800574:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800577:	eb 18                	jmp    800591 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800579:	83 ec 08             	sub    $0x8,%esp
  80057c:	53                   	push   %ebx
  80057d:	6a 20                	push   $0x20
  80057f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800581:	83 ef 01             	sub    $0x1,%edi
  800584:	83 c4 10             	add    $0x10,%esp
  800587:	eb 08                	jmp    800591 <vprintfmt+0x284>
  800589:	89 df                	mov    %ebx,%edi
  80058b:	8b 75 08             	mov    0x8(%ebp),%esi
  80058e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800591:	85 ff                	test   %edi,%edi
  800593:	7f e4                	jg     800579 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800595:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800598:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80059b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80059e:	e9 90 fd ff ff       	jmp    800333 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005a3:	83 f9 01             	cmp    $0x1,%ecx
  8005a6:	7e 19                	jle    8005c1 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8005a8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ab:	8b 50 04             	mov    0x4(%eax),%edx
  8005ae:	8b 00                	mov    (%eax),%eax
  8005b0:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005b3:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005b6:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b9:	8d 40 08             	lea    0x8(%eax),%eax
  8005bc:	89 45 14             	mov    %eax,0x14(%ebp)
  8005bf:	eb 38                	jmp    8005f9 <vprintfmt+0x2ec>
	else if (lflag)
  8005c1:	85 c9                	test   %ecx,%ecx
  8005c3:	74 1b                	je     8005e0 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8005c5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005c8:	8b 00                	mov    (%eax),%eax
  8005ca:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005cd:	89 c1                	mov    %eax,%ecx
  8005cf:	c1 f9 1f             	sar    $0x1f,%ecx
  8005d2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005d5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d8:	8d 40 04             	lea    0x4(%eax),%eax
  8005db:	89 45 14             	mov    %eax,0x14(%ebp)
  8005de:	eb 19                	jmp    8005f9 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8005e0:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e3:	8b 00                	mov    (%eax),%eax
  8005e5:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005e8:	89 c1                	mov    %eax,%ecx
  8005ea:	c1 f9 1f             	sar    $0x1f,%ecx
  8005ed:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005f0:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f3:	8d 40 04             	lea    0x4(%eax),%eax
  8005f6:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005f9:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8005fc:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005ff:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800604:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800608:	0f 89 0e 01 00 00    	jns    80071c <vprintfmt+0x40f>
				putch('-', putdat);
  80060e:	83 ec 08             	sub    $0x8,%esp
  800611:	53                   	push   %ebx
  800612:	6a 2d                	push   $0x2d
  800614:	ff d6                	call   *%esi
				num = -(long long) num;
  800616:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800619:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80061c:	f7 da                	neg    %edx
  80061e:	83 d1 00             	adc    $0x0,%ecx
  800621:	f7 d9                	neg    %ecx
  800623:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800626:	b8 0a 00 00 00       	mov    $0xa,%eax
  80062b:	e9 ec 00 00 00       	jmp    80071c <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800630:	83 f9 01             	cmp    $0x1,%ecx
  800633:	7e 18                	jle    80064d <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800635:	8b 45 14             	mov    0x14(%ebp),%eax
  800638:	8b 10                	mov    (%eax),%edx
  80063a:	8b 48 04             	mov    0x4(%eax),%ecx
  80063d:	8d 40 08             	lea    0x8(%eax),%eax
  800640:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800643:	b8 0a 00 00 00       	mov    $0xa,%eax
  800648:	e9 cf 00 00 00       	jmp    80071c <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80064d:	85 c9                	test   %ecx,%ecx
  80064f:	74 1a                	je     80066b <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800651:	8b 45 14             	mov    0x14(%ebp),%eax
  800654:	8b 10                	mov    (%eax),%edx
  800656:	b9 00 00 00 00       	mov    $0x0,%ecx
  80065b:	8d 40 04             	lea    0x4(%eax),%eax
  80065e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800661:	b8 0a 00 00 00       	mov    $0xa,%eax
  800666:	e9 b1 00 00 00       	jmp    80071c <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80066b:	8b 45 14             	mov    0x14(%ebp),%eax
  80066e:	8b 10                	mov    (%eax),%edx
  800670:	b9 00 00 00 00       	mov    $0x0,%ecx
  800675:	8d 40 04             	lea    0x4(%eax),%eax
  800678:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80067b:	b8 0a 00 00 00       	mov    $0xa,%eax
  800680:	e9 97 00 00 00       	jmp    80071c <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800685:	83 ec 08             	sub    $0x8,%esp
  800688:	53                   	push   %ebx
  800689:	6a 58                	push   $0x58
  80068b:	ff d6                	call   *%esi
			putch('X', putdat);
  80068d:	83 c4 08             	add    $0x8,%esp
  800690:	53                   	push   %ebx
  800691:	6a 58                	push   $0x58
  800693:	ff d6                	call   *%esi
			putch('X', putdat);
  800695:	83 c4 08             	add    $0x8,%esp
  800698:	53                   	push   %ebx
  800699:	6a 58                	push   $0x58
  80069b:	ff d6                	call   *%esi
			break;
  80069d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8006a3:	e9 8b fc ff ff       	jmp    800333 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8006a8:	83 ec 08             	sub    $0x8,%esp
  8006ab:	53                   	push   %ebx
  8006ac:	6a 30                	push   $0x30
  8006ae:	ff d6                	call   *%esi
			putch('x', putdat);
  8006b0:	83 c4 08             	add    $0x8,%esp
  8006b3:	53                   	push   %ebx
  8006b4:	6a 78                	push   $0x78
  8006b6:	ff d6                	call   *%esi
			num = (unsigned long long)
  8006b8:	8b 45 14             	mov    0x14(%ebp),%eax
  8006bb:	8b 10                	mov    (%eax),%edx
  8006bd:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006c2:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006c5:	8d 40 04             	lea    0x4(%eax),%eax
  8006c8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8006cb:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8006d0:	eb 4a                	jmp    80071c <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006d2:	83 f9 01             	cmp    $0x1,%ecx
  8006d5:	7e 15                	jle    8006ec <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8006d7:	8b 45 14             	mov    0x14(%ebp),%eax
  8006da:	8b 10                	mov    (%eax),%edx
  8006dc:	8b 48 04             	mov    0x4(%eax),%ecx
  8006df:	8d 40 08             	lea    0x8(%eax),%eax
  8006e2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8006e5:	b8 10 00 00 00       	mov    $0x10,%eax
  8006ea:	eb 30                	jmp    80071c <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006ec:	85 c9                	test   %ecx,%ecx
  8006ee:	74 17                	je     800707 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  8006f0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006f3:	8b 10                	mov    (%eax),%edx
  8006f5:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006fa:	8d 40 04             	lea    0x4(%eax),%eax
  8006fd:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800700:	b8 10 00 00 00       	mov    $0x10,%eax
  800705:	eb 15                	jmp    80071c <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800707:	8b 45 14             	mov    0x14(%ebp),%eax
  80070a:	8b 10                	mov    (%eax),%edx
  80070c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800711:	8d 40 04             	lea    0x4(%eax),%eax
  800714:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800717:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  80071c:	83 ec 0c             	sub    $0xc,%esp
  80071f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800723:	57                   	push   %edi
  800724:	ff 75 e0             	pushl  -0x20(%ebp)
  800727:	50                   	push   %eax
  800728:	51                   	push   %ecx
  800729:	52                   	push   %edx
  80072a:	89 da                	mov    %ebx,%edx
  80072c:	89 f0                	mov    %esi,%eax
  80072e:	e8 f1 fa ff ff       	call   800224 <printnum>
			break;
  800733:	83 c4 20             	add    $0x20,%esp
  800736:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800739:	e9 f5 fb ff ff       	jmp    800333 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80073e:	83 ec 08             	sub    $0x8,%esp
  800741:	53                   	push   %ebx
  800742:	52                   	push   %edx
  800743:	ff d6                	call   *%esi
			break;
  800745:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800748:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80074b:	e9 e3 fb ff ff       	jmp    800333 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800750:	83 ec 08             	sub    $0x8,%esp
  800753:	53                   	push   %ebx
  800754:	6a 25                	push   $0x25
  800756:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800758:	83 c4 10             	add    $0x10,%esp
  80075b:	eb 03                	jmp    800760 <vprintfmt+0x453>
  80075d:	83 ef 01             	sub    $0x1,%edi
  800760:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800764:	75 f7                	jne    80075d <vprintfmt+0x450>
  800766:	e9 c8 fb ff ff       	jmp    800333 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80076b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80076e:	5b                   	pop    %ebx
  80076f:	5e                   	pop    %esi
  800770:	5f                   	pop    %edi
  800771:	5d                   	pop    %ebp
  800772:	c3                   	ret    

00800773 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800773:	55                   	push   %ebp
  800774:	89 e5                	mov    %esp,%ebp
  800776:	83 ec 18             	sub    $0x18,%esp
  800779:	8b 45 08             	mov    0x8(%ebp),%eax
  80077c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80077f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800782:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800786:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800789:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800790:	85 c0                	test   %eax,%eax
  800792:	74 26                	je     8007ba <vsnprintf+0x47>
  800794:	85 d2                	test   %edx,%edx
  800796:	7e 22                	jle    8007ba <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800798:	ff 75 14             	pushl  0x14(%ebp)
  80079b:	ff 75 10             	pushl  0x10(%ebp)
  80079e:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007a1:	50                   	push   %eax
  8007a2:	68 d3 02 80 00       	push   $0x8002d3
  8007a7:	e8 61 fb ff ff       	call   80030d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007ac:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007af:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007b5:	83 c4 10             	add    $0x10,%esp
  8007b8:	eb 05                	jmp    8007bf <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007ba:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007bf:	c9                   	leave  
  8007c0:	c3                   	ret    

008007c1 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007c1:	55                   	push   %ebp
  8007c2:	89 e5                	mov    %esp,%ebp
  8007c4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007c7:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007ca:	50                   	push   %eax
  8007cb:	ff 75 10             	pushl  0x10(%ebp)
  8007ce:	ff 75 0c             	pushl  0xc(%ebp)
  8007d1:	ff 75 08             	pushl  0x8(%ebp)
  8007d4:	e8 9a ff ff ff       	call   800773 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007d9:	c9                   	leave  
  8007da:	c3                   	ret    

008007db <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007db:	55                   	push   %ebp
  8007dc:	89 e5                	mov    %esp,%ebp
  8007de:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007e1:	b8 00 00 00 00       	mov    $0x0,%eax
  8007e6:	eb 03                	jmp    8007eb <strlen+0x10>
		n++;
  8007e8:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007eb:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007ef:	75 f7                	jne    8007e8 <strlen+0xd>
		n++;
	return n;
}
  8007f1:	5d                   	pop    %ebp
  8007f2:	c3                   	ret    

008007f3 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8007f3:	55                   	push   %ebp
  8007f4:	89 e5                	mov    %esp,%ebp
  8007f6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007f9:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007fc:	ba 00 00 00 00       	mov    $0x0,%edx
  800801:	eb 03                	jmp    800806 <strnlen+0x13>
		n++;
  800803:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800806:	39 c2                	cmp    %eax,%edx
  800808:	74 08                	je     800812 <strnlen+0x1f>
  80080a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80080e:	75 f3                	jne    800803 <strnlen+0x10>
  800810:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800812:	5d                   	pop    %ebp
  800813:	c3                   	ret    

00800814 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800814:	55                   	push   %ebp
  800815:	89 e5                	mov    %esp,%ebp
  800817:	53                   	push   %ebx
  800818:	8b 45 08             	mov    0x8(%ebp),%eax
  80081b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80081e:	89 c2                	mov    %eax,%edx
  800820:	83 c2 01             	add    $0x1,%edx
  800823:	83 c1 01             	add    $0x1,%ecx
  800826:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80082a:	88 5a ff             	mov    %bl,-0x1(%edx)
  80082d:	84 db                	test   %bl,%bl
  80082f:	75 ef                	jne    800820 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800831:	5b                   	pop    %ebx
  800832:	5d                   	pop    %ebp
  800833:	c3                   	ret    

00800834 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800834:	55                   	push   %ebp
  800835:	89 e5                	mov    %esp,%ebp
  800837:	53                   	push   %ebx
  800838:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80083b:	53                   	push   %ebx
  80083c:	e8 9a ff ff ff       	call   8007db <strlen>
  800841:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800844:	ff 75 0c             	pushl  0xc(%ebp)
  800847:	01 d8                	add    %ebx,%eax
  800849:	50                   	push   %eax
  80084a:	e8 c5 ff ff ff       	call   800814 <strcpy>
	return dst;
}
  80084f:	89 d8                	mov    %ebx,%eax
  800851:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800854:	c9                   	leave  
  800855:	c3                   	ret    

00800856 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800856:	55                   	push   %ebp
  800857:	89 e5                	mov    %esp,%ebp
  800859:	56                   	push   %esi
  80085a:	53                   	push   %ebx
  80085b:	8b 75 08             	mov    0x8(%ebp),%esi
  80085e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800861:	89 f3                	mov    %esi,%ebx
  800863:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800866:	89 f2                	mov    %esi,%edx
  800868:	eb 0f                	jmp    800879 <strncpy+0x23>
		*dst++ = *src;
  80086a:	83 c2 01             	add    $0x1,%edx
  80086d:	0f b6 01             	movzbl (%ecx),%eax
  800870:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800873:	80 39 01             	cmpb   $0x1,(%ecx)
  800876:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800879:	39 da                	cmp    %ebx,%edx
  80087b:	75 ed                	jne    80086a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80087d:	89 f0                	mov    %esi,%eax
  80087f:	5b                   	pop    %ebx
  800880:	5e                   	pop    %esi
  800881:	5d                   	pop    %ebp
  800882:	c3                   	ret    

00800883 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800883:	55                   	push   %ebp
  800884:	89 e5                	mov    %esp,%ebp
  800886:	56                   	push   %esi
  800887:	53                   	push   %ebx
  800888:	8b 75 08             	mov    0x8(%ebp),%esi
  80088b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80088e:	8b 55 10             	mov    0x10(%ebp),%edx
  800891:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800893:	85 d2                	test   %edx,%edx
  800895:	74 21                	je     8008b8 <strlcpy+0x35>
  800897:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80089b:	89 f2                	mov    %esi,%edx
  80089d:	eb 09                	jmp    8008a8 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80089f:	83 c2 01             	add    $0x1,%edx
  8008a2:	83 c1 01             	add    $0x1,%ecx
  8008a5:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008a8:	39 c2                	cmp    %eax,%edx
  8008aa:	74 09                	je     8008b5 <strlcpy+0x32>
  8008ac:	0f b6 19             	movzbl (%ecx),%ebx
  8008af:	84 db                	test   %bl,%bl
  8008b1:	75 ec                	jne    80089f <strlcpy+0x1c>
  8008b3:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8008b5:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8008b8:	29 f0                	sub    %esi,%eax
}
  8008ba:	5b                   	pop    %ebx
  8008bb:	5e                   	pop    %esi
  8008bc:	5d                   	pop    %ebp
  8008bd:	c3                   	ret    

008008be <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008be:	55                   	push   %ebp
  8008bf:	89 e5                	mov    %esp,%ebp
  8008c1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008c4:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008c7:	eb 06                	jmp    8008cf <strcmp+0x11>
		p++, q++;
  8008c9:	83 c1 01             	add    $0x1,%ecx
  8008cc:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008cf:	0f b6 01             	movzbl (%ecx),%eax
  8008d2:	84 c0                	test   %al,%al
  8008d4:	74 04                	je     8008da <strcmp+0x1c>
  8008d6:	3a 02                	cmp    (%edx),%al
  8008d8:	74 ef                	je     8008c9 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008da:	0f b6 c0             	movzbl %al,%eax
  8008dd:	0f b6 12             	movzbl (%edx),%edx
  8008e0:	29 d0                	sub    %edx,%eax
}
  8008e2:	5d                   	pop    %ebp
  8008e3:	c3                   	ret    

008008e4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008e4:	55                   	push   %ebp
  8008e5:	89 e5                	mov    %esp,%ebp
  8008e7:	53                   	push   %ebx
  8008e8:	8b 45 08             	mov    0x8(%ebp),%eax
  8008eb:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008ee:	89 c3                	mov    %eax,%ebx
  8008f0:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8008f3:	eb 06                	jmp    8008fb <strncmp+0x17>
		n--, p++, q++;
  8008f5:	83 c0 01             	add    $0x1,%eax
  8008f8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008fb:	39 d8                	cmp    %ebx,%eax
  8008fd:	74 15                	je     800914 <strncmp+0x30>
  8008ff:	0f b6 08             	movzbl (%eax),%ecx
  800902:	84 c9                	test   %cl,%cl
  800904:	74 04                	je     80090a <strncmp+0x26>
  800906:	3a 0a                	cmp    (%edx),%cl
  800908:	74 eb                	je     8008f5 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80090a:	0f b6 00             	movzbl (%eax),%eax
  80090d:	0f b6 12             	movzbl (%edx),%edx
  800910:	29 d0                	sub    %edx,%eax
  800912:	eb 05                	jmp    800919 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800914:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800919:	5b                   	pop    %ebx
  80091a:	5d                   	pop    %ebp
  80091b:	c3                   	ret    

0080091c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80091c:	55                   	push   %ebp
  80091d:	89 e5                	mov    %esp,%ebp
  80091f:	8b 45 08             	mov    0x8(%ebp),%eax
  800922:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800926:	eb 07                	jmp    80092f <strchr+0x13>
		if (*s == c)
  800928:	38 ca                	cmp    %cl,%dl
  80092a:	74 0f                	je     80093b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80092c:	83 c0 01             	add    $0x1,%eax
  80092f:	0f b6 10             	movzbl (%eax),%edx
  800932:	84 d2                	test   %dl,%dl
  800934:	75 f2                	jne    800928 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800936:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80093b:	5d                   	pop    %ebp
  80093c:	c3                   	ret    

0080093d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80093d:	55                   	push   %ebp
  80093e:	89 e5                	mov    %esp,%ebp
  800940:	8b 45 08             	mov    0x8(%ebp),%eax
  800943:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800947:	eb 03                	jmp    80094c <strfind+0xf>
  800949:	83 c0 01             	add    $0x1,%eax
  80094c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  80094f:	38 ca                	cmp    %cl,%dl
  800951:	74 04                	je     800957 <strfind+0x1a>
  800953:	84 d2                	test   %dl,%dl
  800955:	75 f2                	jne    800949 <strfind+0xc>
			break;
	return (char *) s;
}
  800957:	5d                   	pop    %ebp
  800958:	c3                   	ret    

00800959 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800959:	55                   	push   %ebp
  80095a:	89 e5                	mov    %esp,%ebp
  80095c:	57                   	push   %edi
  80095d:	56                   	push   %esi
  80095e:	53                   	push   %ebx
  80095f:	8b 7d 08             	mov    0x8(%ebp),%edi
  800962:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800965:	85 c9                	test   %ecx,%ecx
  800967:	74 36                	je     80099f <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800969:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80096f:	75 28                	jne    800999 <memset+0x40>
  800971:	f6 c1 03             	test   $0x3,%cl
  800974:	75 23                	jne    800999 <memset+0x40>
		c &= 0xFF;
  800976:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80097a:	89 d3                	mov    %edx,%ebx
  80097c:	c1 e3 08             	shl    $0x8,%ebx
  80097f:	89 d6                	mov    %edx,%esi
  800981:	c1 e6 18             	shl    $0x18,%esi
  800984:	89 d0                	mov    %edx,%eax
  800986:	c1 e0 10             	shl    $0x10,%eax
  800989:	09 f0                	or     %esi,%eax
  80098b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  80098d:	89 d8                	mov    %ebx,%eax
  80098f:	09 d0                	or     %edx,%eax
  800991:	c1 e9 02             	shr    $0x2,%ecx
  800994:	fc                   	cld    
  800995:	f3 ab                	rep stos %eax,%es:(%edi)
  800997:	eb 06                	jmp    80099f <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800999:	8b 45 0c             	mov    0xc(%ebp),%eax
  80099c:	fc                   	cld    
  80099d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80099f:	89 f8                	mov    %edi,%eax
  8009a1:	5b                   	pop    %ebx
  8009a2:	5e                   	pop    %esi
  8009a3:	5f                   	pop    %edi
  8009a4:	5d                   	pop    %ebp
  8009a5:	c3                   	ret    

008009a6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009a6:	55                   	push   %ebp
  8009a7:	89 e5                	mov    %esp,%ebp
  8009a9:	57                   	push   %edi
  8009aa:	56                   	push   %esi
  8009ab:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ae:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009b1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009b4:	39 c6                	cmp    %eax,%esi
  8009b6:	73 35                	jae    8009ed <memmove+0x47>
  8009b8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009bb:	39 d0                	cmp    %edx,%eax
  8009bd:	73 2e                	jae    8009ed <memmove+0x47>
		s += n;
		d += n;
  8009bf:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009c2:	89 d6                	mov    %edx,%esi
  8009c4:	09 fe                	or     %edi,%esi
  8009c6:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009cc:	75 13                	jne    8009e1 <memmove+0x3b>
  8009ce:	f6 c1 03             	test   $0x3,%cl
  8009d1:	75 0e                	jne    8009e1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8009d3:	83 ef 04             	sub    $0x4,%edi
  8009d6:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009d9:	c1 e9 02             	shr    $0x2,%ecx
  8009dc:	fd                   	std    
  8009dd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009df:	eb 09                	jmp    8009ea <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009e1:	83 ef 01             	sub    $0x1,%edi
  8009e4:	8d 72 ff             	lea    -0x1(%edx),%esi
  8009e7:	fd                   	std    
  8009e8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009ea:	fc                   	cld    
  8009eb:	eb 1d                	jmp    800a0a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009ed:	89 f2                	mov    %esi,%edx
  8009ef:	09 c2                	or     %eax,%edx
  8009f1:	f6 c2 03             	test   $0x3,%dl
  8009f4:	75 0f                	jne    800a05 <memmove+0x5f>
  8009f6:	f6 c1 03             	test   $0x3,%cl
  8009f9:	75 0a                	jne    800a05 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8009fb:	c1 e9 02             	shr    $0x2,%ecx
  8009fe:	89 c7                	mov    %eax,%edi
  800a00:	fc                   	cld    
  800a01:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a03:	eb 05                	jmp    800a0a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a05:	89 c7                	mov    %eax,%edi
  800a07:	fc                   	cld    
  800a08:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a0a:	5e                   	pop    %esi
  800a0b:	5f                   	pop    %edi
  800a0c:	5d                   	pop    %ebp
  800a0d:	c3                   	ret    

00800a0e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a0e:	55                   	push   %ebp
  800a0f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a11:	ff 75 10             	pushl  0x10(%ebp)
  800a14:	ff 75 0c             	pushl  0xc(%ebp)
  800a17:	ff 75 08             	pushl  0x8(%ebp)
  800a1a:	e8 87 ff ff ff       	call   8009a6 <memmove>
}
  800a1f:	c9                   	leave  
  800a20:	c3                   	ret    

00800a21 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a21:	55                   	push   %ebp
  800a22:	89 e5                	mov    %esp,%ebp
  800a24:	56                   	push   %esi
  800a25:	53                   	push   %ebx
  800a26:	8b 45 08             	mov    0x8(%ebp),%eax
  800a29:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a2c:	89 c6                	mov    %eax,%esi
  800a2e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a31:	eb 1a                	jmp    800a4d <memcmp+0x2c>
		if (*s1 != *s2)
  800a33:	0f b6 08             	movzbl (%eax),%ecx
  800a36:	0f b6 1a             	movzbl (%edx),%ebx
  800a39:	38 d9                	cmp    %bl,%cl
  800a3b:	74 0a                	je     800a47 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a3d:	0f b6 c1             	movzbl %cl,%eax
  800a40:	0f b6 db             	movzbl %bl,%ebx
  800a43:	29 d8                	sub    %ebx,%eax
  800a45:	eb 0f                	jmp    800a56 <memcmp+0x35>
		s1++, s2++;
  800a47:	83 c0 01             	add    $0x1,%eax
  800a4a:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a4d:	39 f0                	cmp    %esi,%eax
  800a4f:	75 e2                	jne    800a33 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a51:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a56:	5b                   	pop    %ebx
  800a57:	5e                   	pop    %esi
  800a58:	5d                   	pop    %ebp
  800a59:	c3                   	ret    

00800a5a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a5a:	55                   	push   %ebp
  800a5b:	89 e5                	mov    %esp,%ebp
  800a5d:	53                   	push   %ebx
  800a5e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a61:	89 c1                	mov    %eax,%ecx
  800a63:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a66:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a6a:	eb 0a                	jmp    800a76 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a6c:	0f b6 10             	movzbl (%eax),%edx
  800a6f:	39 da                	cmp    %ebx,%edx
  800a71:	74 07                	je     800a7a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a73:	83 c0 01             	add    $0x1,%eax
  800a76:	39 c8                	cmp    %ecx,%eax
  800a78:	72 f2                	jb     800a6c <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a7a:	5b                   	pop    %ebx
  800a7b:	5d                   	pop    %ebp
  800a7c:	c3                   	ret    

00800a7d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a7d:	55                   	push   %ebp
  800a7e:	89 e5                	mov    %esp,%ebp
  800a80:	57                   	push   %edi
  800a81:	56                   	push   %esi
  800a82:	53                   	push   %ebx
  800a83:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a86:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a89:	eb 03                	jmp    800a8e <strtol+0x11>
		s++;
  800a8b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a8e:	0f b6 01             	movzbl (%ecx),%eax
  800a91:	3c 20                	cmp    $0x20,%al
  800a93:	74 f6                	je     800a8b <strtol+0xe>
  800a95:	3c 09                	cmp    $0x9,%al
  800a97:	74 f2                	je     800a8b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a99:	3c 2b                	cmp    $0x2b,%al
  800a9b:	75 0a                	jne    800aa7 <strtol+0x2a>
		s++;
  800a9d:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800aa0:	bf 00 00 00 00       	mov    $0x0,%edi
  800aa5:	eb 11                	jmp    800ab8 <strtol+0x3b>
  800aa7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800aac:	3c 2d                	cmp    $0x2d,%al
  800aae:	75 08                	jne    800ab8 <strtol+0x3b>
		s++, neg = 1;
  800ab0:	83 c1 01             	add    $0x1,%ecx
  800ab3:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800ab8:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800abe:	75 15                	jne    800ad5 <strtol+0x58>
  800ac0:	80 39 30             	cmpb   $0x30,(%ecx)
  800ac3:	75 10                	jne    800ad5 <strtol+0x58>
  800ac5:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ac9:	75 7c                	jne    800b47 <strtol+0xca>
		s += 2, base = 16;
  800acb:	83 c1 02             	add    $0x2,%ecx
  800ace:	bb 10 00 00 00       	mov    $0x10,%ebx
  800ad3:	eb 16                	jmp    800aeb <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800ad5:	85 db                	test   %ebx,%ebx
  800ad7:	75 12                	jne    800aeb <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ad9:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ade:	80 39 30             	cmpb   $0x30,(%ecx)
  800ae1:	75 08                	jne    800aeb <strtol+0x6e>
		s++, base = 8;
  800ae3:	83 c1 01             	add    $0x1,%ecx
  800ae6:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800aeb:	b8 00 00 00 00       	mov    $0x0,%eax
  800af0:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800af3:	0f b6 11             	movzbl (%ecx),%edx
  800af6:	8d 72 d0             	lea    -0x30(%edx),%esi
  800af9:	89 f3                	mov    %esi,%ebx
  800afb:	80 fb 09             	cmp    $0x9,%bl
  800afe:	77 08                	ja     800b08 <strtol+0x8b>
			dig = *s - '0';
  800b00:	0f be d2             	movsbl %dl,%edx
  800b03:	83 ea 30             	sub    $0x30,%edx
  800b06:	eb 22                	jmp    800b2a <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b08:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b0b:	89 f3                	mov    %esi,%ebx
  800b0d:	80 fb 19             	cmp    $0x19,%bl
  800b10:	77 08                	ja     800b1a <strtol+0x9d>
			dig = *s - 'a' + 10;
  800b12:	0f be d2             	movsbl %dl,%edx
  800b15:	83 ea 57             	sub    $0x57,%edx
  800b18:	eb 10                	jmp    800b2a <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800b1a:	8d 72 bf             	lea    -0x41(%edx),%esi
  800b1d:	89 f3                	mov    %esi,%ebx
  800b1f:	80 fb 19             	cmp    $0x19,%bl
  800b22:	77 16                	ja     800b3a <strtol+0xbd>
			dig = *s - 'A' + 10;
  800b24:	0f be d2             	movsbl %dl,%edx
  800b27:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800b2a:	3b 55 10             	cmp    0x10(%ebp),%edx
  800b2d:	7d 0b                	jge    800b3a <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800b2f:	83 c1 01             	add    $0x1,%ecx
  800b32:	0f af 45 10          	imul   0x10(%ebp),%eax
  800b36:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800b38:	eb b9                	jmp    800af3 <strtol+0x76>

	if (endptr)
  800b3a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b3e:	74 0d                	je     800b4d <strtol+0xd0>
		*endptr = (char *) s;
  800b40:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b43:	89 0e                	mov    %ecx,(%esi)
  800b45:	eb 06                	jmp    800b4d <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b47:	85 db                	test   %ebx,%ebx
  800b49:	74 98                	je     800ae3 <strtol+0x66>
  800b4b:	eb 9e                	jmp    800aeb <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800b4d:	89 c2                	mov    %eax,%edx
  800b4f:	f7 da                	neg    %edx
  800b51:	85 ff                	test   %edi,%edi
  800b53:	0f 45 c2             	cmovne %edx,%eax
}
  800b56:	5b                   	pop    %ebx
  800b57:	5e                   	pop    %esi
  800b58:	5f                   	pop    %edi
  800b59:	5d                   	pop    %ebp
  800b5a:	c3                   	ret    

00800b5b <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b5b:	55                   	push   %ebp
  800b5c:	89 e5                	mov    %esp,%ebp
  800b5e:	57                   	push   %edi
  800b5f:	56                   	push   %esi
  800b60:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b61:	b8 00 00 00 00       	mov    $0x0,%eax
  800b66:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b69:	8b 55 08             	mov    0x8(%ebp),%edx
  800b6c:	89 c3                	mov    %eax,%ebx
  800b6e:	89 c7                	mov    %eax,%edi
  800b70:	89 c6                	mov    %eax,%esi
  800b72:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b74:	5b                   	pop    %ebx
  800b75:	5e                   	pop    %esi
  800b76:	5f                   	pop    %edi
  800b77:	5d                   	pop    %ebp
  800b78:	c3                   	ret    

00800b79 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b79:	55                   	push   %ebp
  800b7a:	89 e5                	mov    %esp,%ebp
  800b7c:	57                   	push   %edi
  800b7d:	56                   	push   %esi
  800b7e:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b7f:	ba 00 00 00 00       	mov    $0x0,%edx
  800b84:	b8 01 00 00 00       	mov    $0x1,%eax
  800b89:	89 d1                	mov    %edx,%ecx
  800b8b:	89 d3                	mov    %edx,%ebx
  800b8d:	89 d7                	mov    %edx,%edi
  800b8f:	89 d6                	mov    %edx,%esi
  800b91:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b93:	5b                   	pop    %ebx
  800b94:	5e                   	pop    %esi
  800b95:	5f                   	pop    %edi
  800b96:	5d                   	pop    %ebp
  800b97:	c3                   	ret    

00800b98 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b98:	55                   	push   %ebp
  800b99:	89 e5                	mov    %esp,%ebp
  800b9b:	57                   	push   %edi
  800b9c:	56                   	push   %esi
  800b9d:	53                   	push   %ebx
  800b9e:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ba1:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ba6:	b8 03 00 00 00       	mov    $0x3,%eax
  800bab:	8b 55 08             	mov    0x8(%ebp),%edx
  800bae:	89 cb                	mov    %ecx,%ebx
  800bb0:	89 cf                	mov    %ecx,%edi
  800bb2:	89 ce                	mov    %ecx,%esi
  800bb4:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800bb6:	85 c0                	test   %eax,%eax
  800bb8:	7e 17                	jle    800bd1 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bba:	83 ec 0c             	sub    $0xc,%esp
  800bbd:	50                   	push   %eax
  800bbe:	6a 03                	push   $0x3
  800bc0:	68 a0 11 80 00       	push   $0x8011a0
  800bc5:	6a 23                	push   $0x23
  800bc7:	68 bd 11 80 00       	push   $0x8011bd
  800bcc:	e8 66 f5 ff ff       	call   800137 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800bd1:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800bd4:	5b                   	pop    %ebx
  800bd5:	5e                   	pop    %esi
  800bd6:	5f                   	pop    %edi
  800bd7:	5d                   	pop    %ebp
  800bd8:	c3                   	ret    

00800bd9 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800bd9:	55                   	push   %ebp
  800bda:	89 e5                	mov    %esp,%ebp
  800bdc:	57                   	push   %edi
  800bdd:	56                   	push   %esi
  800bde:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bdf:	ba 00 00 00 00       	mov    $0x0,%edx
  800be4:	b8 02 00 00 00       	mov    $0x2,%eax
  800be9:	89 d1                	mov    %edx,%ecx
  800beb:	89 d3                	mov    %edx,%ebx
  800bed:	89 d7                	mov    %edx,%edi
  800bef:	89 d6                	mov    %edx,%esi
  800bf1:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800bf3:	5b                   	pop    %ebx
  800bf4:	5e                   	pop    %esi
  800bf5:	5f                   	pop    %edi
  800bf6:	5d                   	pop    %ebp
  800bf7:	c3                   	ret    
  800bf8:	66 90                	xchg   %ax,%ax
  800bfa:	66 90                	xchg   %ax,%ax
  800bfc:	66 90                	xchg   %ax,%ax
  800bfe:	66 90                	xchg   %ax,%ax

00800c00 <__udivdi3>:
  800c00:	55                   	push   %ebp
  800c01:	57                   	push   %edi
  800c02:	56                   	push   %esi
  800c03:	53                   	push   %ebx
  800c04:	83 ec 1c             	sub    $0x1c,%esp
  800c07:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800c0b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800c0f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800c13:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c17:	85 f6                	test   %esi,%esi
  800c19:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800c1d:	89 ca                	mov    %ecx,%edx
  800c1f:	89 f8                	mov    %edi,%eax
  800c21:	75 3d                	jne    800c60 <__udivdi3+0x60>
  800c23:	39 cf                	cmp    %ecx,%edi
  800c25:	0f 87 c5 00 00 00    	ja     800cf0 <__udivdi3+0xf0>
  800c2b:	85 ff                	test   %edi,%edi
  800c2d:	89 fd                	mov    %edi,%ebp
  800c2f:	75 0b                	jne    800c3c <__udivdi3+0x3c>
  800c31:	b8 01 00 00 00       	mov    $0x1,%eax
  800c36:	31 d2                	xor    %edx,%edx
  800c38:	f7 f7                	div    %edi
  800c3a:	89 c5                	mov    %eax,%ebp
  800c3c:	89 c8                	mov    %ecx,%eax
  800c3e:	31 d2                	xor    %edx,%edx
  800c40:	f7 f5                	div    %ebp
  800c42:	89 c1                	mov    %eax,%ecx
  800c44:	89 d8                	mov    %ebx,%eax
  800c46:	89 cf                	mov    %ecx,%edi
  800c48:	f7 f5                	div    %ebp
  800c4a:	89 c3                	mov    %eax,%ebx
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
  800c60:	39 ce                	cmp    %ecx,%esi
  800c62:	77 74                	ja     800cd8 <__udivdi3+0xd8>
  800c64:	0f bd fe             	bsr    %esi,%edi
  800c67:	83 f7 1f             	xor    $0x1f,%edi
  800c6a:	0f 84 98 00 00 00    	je     800d08 <__udivdi3+0x108>
  800c70:	bb 20 00 00 00       	mov    $0x20,%ebx
  800c75:	89 f9                	mov    %edi,%ecx
  800c77:	89 c5                	mov    %eax,%ebp
  800c79:	29 fb                	sub    %edi,%ebx
  800c7b:	d3 e6                	shl    %cl,%esi
  800c7d:	89 d9                	mov    %ebx,%ecx
  800c7f:	d3 ed                	shr    %cl,%ebp
  800c81:	89 f9                	mov    %edi,%ecx
  800c83:	d3 e0                	shl    %cl,%eax
  800c85:	09 ee                	or     %ebp,%esi
  800c87:	89 d9                	mov    %ebx,%ecx
  800c89:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800c8d:	89 d5                	mov    %edx,%ebp
  800c8f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c93:	d3 ed                	shr    %cl,%ebp
  800c95:	89 f9                	mov    %edi,%ecx
  800c97:	d3 e2                	shl    %cl,%edx
  800c99:	89 d9                	mov    %ebx,%ecx
  800c9b:	d3 e8                	shr    %cl,%eax
  800c9d:	09 c2                	or     %eax,%edx
  800c9f:	89 d0                	mov    %edx,%eax
  800ca1:	89 ea                	mov    %ebp,%edx
  800ca3:	f7 f6                	div    %esi
  800ca5:	89 d5                	mov    %edx,%ebp
  800ca7:	89 c3                	mov    %eax,%ebx
  800ca9:	f7 64 24 0c          	mull   0xc(%esp)
  800cad:	39 d5                	cmp    %edx,%ebp
  800caf:	72 10                	jb     800cc1 <__udivdi3+0xc1>
  800cb1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800cb5:	89 f9                	mov    %edi,%ecx
  800cb7:	d3 e6                	shl    %cl,%esi
  800cb9:	39 c6                	cmp    %eax,%esi
  800cbb:	73 07                	jae    800cc4 <__udivdi3+0xc4>
  800cbd:	39 d5                	cmp    %edx,%ebp
  800cbf:	75 03                	jne    800cc4 <__udivdi3+0xc4>
  800cc1:	83 eb 01             	sub    $0x1,%ebx
  800cc4:	31 ff                	xor    %edi,%edi
  800cc6:	89 d8                	mov    %ebx,%eax
  800cc8:	89 fa                	mov    %edi,%edx
  800cca:	83 c4 1c             	add    $0x1c,%esp
  800ccd:	5b                   	pop    %ebx
  800cce:	5e                   	pop    %esi
  800ccf:	5f                   	pop    %edi
  800cd0:	5d                   	pop    %ebp
  800cd1:	c3                   	ret    
  800cd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cd8:	31 ff                	xor    %edi,%edi
  800cda:	31 db                	xor    %ebx,%ebx
  800cdc:	89 d8                	mov    %ebx,%eax
  800cde:	89 fa                	mov    %edi,%edx
  800ce0:	83 c4 1c             	add    $0x1c,%esp
  800ce3:	5b                   	pop    %ebx
  800ce4:	5e                   	pop    %esi
  800ce5:	5f                   	pop    %edi
  800ce6:	5d                   	pop    %ebp
  800ce7:	c3                   	ret    
  800ce8:	90                   	nop
  800ce9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800cf0:	89 d8                	mov    %ebx,%eax
  800cf2:	f7 f7                	div    %edi
  800cf4:	31 ff                	xor    %edi,%edi
  800cf6:	89 c3                	mov    %eax,%ebx
  800cf8:	89 d8                	mov    %ebx,%eax
  800cfa:	89 fa                	mov    %edi,%edx
  800cfc:	83 c4 1c             	add    $0x1c,%esp
  800cff:	5b                   	pop    %ebx
  800d00:	5e                   	pop    %esi
  800d01:	5f                   	pop    %edi
  800d02:	5d                   	pop    %ebp
  800d03:	c3                   	ret    
  800d04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d08:	39 ce                	cmp    %ecx,%esi
  800d0a:	72 0c                	jb     800d18 <__udivdi3+0x118>
  800d0c:	31 db                	xor    %ebx,%ebx
  800d0e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800d12:	0f 87 34 ff ff ff    	ja     800c4c <__udivdi3+0x4c>
  800d18:	bb 01 00 00 00       	mov    $0x1,%ebx
  800d1d:	e9 2a ff ff ff       	jmp    800c4c <__udivdi3+0x4c>
  800d22:	66 90                	xchg   %ax,%ax
  800d24:	66 90                	xchg   %ax,%ax
  800d26:	66 90                	xchg   %ax,%ax
  800d28:	66 90                	xchg   %ax,%ax
  800d2a:	66 90                	xchg   %ax,%ax
  800d2c:	66 90                	xchg   %ax,%ax
  800d2e:	66 90                	xchg   %ax,%ax

00800d30 <__umoddi3>:
  800d30:	55                   	push   %ebp
  800d31:	57                   	push   %edi
  800d32:	56                   	push   %esi
  800d33:	53                   	push   %ebx
  800d34:	83 ec 1c             	sub    $0x1c,%esp
  800d37:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800d3b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800d3f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800d43:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800d47:	85 d2                	test   %edx,%edx
  800d49:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800d4d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d51:	89 f3                	mov    %esi,%ebx
  800d53:	89 3c 24             	mov    %edi,(%esp)
  800d56:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d5a:	75 1c                	jne    800d78 <__umoddi3+0x48>
  800d5c:	39 f7                	cmp    %esi,%edi
  800d5e:	76 50                	jbe    800db0 <__umoddi3+0x80>
  800d60:	89 c8                	mov    %ecx,%eax
  800d62:	89 f2                	mov    %esi,%edx
  800d64:	f7 f7                	div    %edi
  800d66:	89 d0                	mov    %edx,%eax
  800d68:	31 d2                	xor    %edx,%edx
  800d6a:	83 c4 1c             	add    $0x1c,%esp
  800d6d:	5b                   	pop    %ebx
  800d6e:	5e                   	pop    %esi
  800d6f:	5f                   	pop    %edi
  800d70:	5d                   	pop    %ebp
  800d71:	c3                   	ret    
  800d72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d78:	39 f2                	cmp    %esi,%edx
  800d7a:	89 d0                	mov    %edx,%eax
  800d7c:	77 52                	ja     800dd0 <__umoddi3+0xa0>
  800d7e:	0f bd ea             	bsr    %edx,%ebp
  800d81:	83 f5 1f             	xor    $0x1f,%ebp
  800d84:	75 5a                	jne    800de0 <__umoddi3+0xb0>
  800d86:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800d8a:	0f 82 e0 00 00 00    	jb     800e70 <__umoddi3+0x140>
  800d90:	39 0c 24             	cmp    %ecx,(%esp)
  800d93:	0f 86 d7 00 00 00    	jbe    800e70 <__umoddi3+0x140>
  800d99:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d9d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800da1:	83 c4 1c             	add    $0x1c,%esp
  800da4:	5b                   	pop    %ebx
  800da5:	5e                   	pop    %esi
  800da6:	5f                   	pop    %edi
  800da7:	5d                   	pop    %ebp
  800da8:	c3                   	ret    
  800da9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800db0:	85 ff                	test   %edi,%edi
  800db2:	89 fd                	mov    %edi,%ebp
  800db4:	75 0b                	jne    800dc1 <__umoddi3+0x91>
  800db6:	b8 01 00 00 00       	mov    $0x1,%eax
  800dbb:	31 d2                	xor    %edx,%edx
  800dbd:	f7 f7                	div    %edi
  800dbf:	89 c5                	mov    %eax,%ebp
  800dc1:	89 f0                	mov    %esi,%eax
  800dc3:	31 d2                	xor    %edx,%edx
  800dc5:	f7 f5                	div    %ebp
  800dc7:	89 c8                	mov    %ecx,%eax
  800dc9:	f7 f5                	div    %ebp
  800dcb:	89 d0                	mov    %edx,%eax
  800dcd:	eb 99                	jmp    800d68 <__umoddi3+0x38>
  800dcf:	90                   	nop
  800dd0:	89 c8                	mov    %ecx,%eax
  800dd2:	89 f2                	mov    %esi,%edx
  800dd4:	83 c4 1c             	add    $0x1c,%esp
  800dd7:	5b                   	pop    %ebx
  800dd8:	5e                   	pop    %esi
  800dd9:	5f                   	pop    %edi
  800dda:	5d                   	pop    %ebp
  800ddb:	c3                   	ret    
  800ddc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800de0:	8b 34 24             	mov    (%esp),%esi
  800de3:	bf 20 00 00 00       	mov    $0x20,%edi
  800de8:	89 e9                	mov    %ebp,%ecx
  800dea:	29 ef                	sub    %ebp,%edi
  800dec:	d3 e0                	shl    %cl,%eax
  800dee:	89 f9                	mov    %edi,%ecx
  800df0:	89 f2                	mov    %esi,%edx
  800df2:	d3 ea                	shr    %cl,%edx
  800df4:	89 e9                	mov    %ebp,%ecx
  800df6:	09 c2                	or     %eax,%edx
  800df8:	89 d8                	mov    %ebx,%eax
  800dfa:	89 14 24             	mov    %edx,(%esp)
  800dfd:	89 f2                	mov    %esi,%edx
  800dff:	d3 e2                	shl    %cl,%edx
  800e01:	89 f9                	mov    %edi,%ecx
  800e03:	89 54 24 04          	mov    %edx,0x4(%esp)
  800e07:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800e0b:	d3 e8                	shr    %cl,%eax
  800e0d:	89 e9                	mov    %ebp,%ecx
  800e0f:	89 c6                	mov    %eax,%esi
  800e11:	d3 e3                	shl    %cl,%ebx
  800e13:	89 f9                	mov    %edi,%ecx
  800e15:	89 d0                	mov    %edx,%eax
  800e17:	d3 e8                	shr    %cl,%eax
  800e19:	89 e9                	mov    %ebp,%ecx
  800e1b:	09 d8                	or     %ebx,%eax
  800e1d:	89 d3                	mov    %edx,%ebx
  800e1f:	89 f2                	mov    %esi,%edx
  800e21:	f7 34 24             	divl   (%esp)
  800e24:	89 d6                	mov    %edx,%esi
  800e26:	d3 e3                	shl    %cl,%ebx
  800e28:	f7 64 24 04          	mull   0x4(%esp)
  800e2c:	39 d6                	cmp    %edx,%esi
  800e2e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800e32:	89 d1                	mov    %edx,%ecx
  800e34:	89 c3                	mov    %eax,%ebx
  800e36:	72 08                	jb     800e40 <__umoddi3+0x110>
  800e38:	75 11                	jne    800e4b <__umoddi3+0x11b>
  800e3a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800e3e:	73 0b                	jae    800e4b <__umoddi3+0x11b>
  800e40:	2b 44 24 04          	sub    0x4(%esp),%eax
  800e44:	1b 14 24             	sbb    (%esp),%edx
  800e47:	89 d1                	mov    %edx,%ecx
  800e49:	89 c3                	mov    %eax,%ebx
  800e4b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800e4f:	29 da                	sub    %ebx,%edx
  800e51:	19 ce                	sbb    %ecx,%esi
  800e53:	89 f9                	mov    %edi,%ecx
  800e55:	89 f0                	mov    %esi,%eax
  800e57:	d3 e0                	shl    %cl,%eax
  800e59:	89 e9                	mov    %ebp,%ecx
  800e5b:	d3 ea                	shr    %cl,%edx
  800e5d:	89 e9                	mov    %ebp,%ecx
  800e5f:	d3 ee                	shr    %cl,%esi
  800e61:	09 d0                	or     %edx,%eax
  800e63:	89 f2                	mov    %esi,%edx
  800e65:	83 c4 1c             	add    $0x1c,%esp
  800e68:	5b                   	pop    %ebx
  800e69:	5e                   	pop    %esi
  800e6a:	5f                   	pop    %edi
  800e6b:	5d                   	pop    %ebp
  800e6c:	c3                   	ret    
  800e6d:	8d 76 00             	lea    0x0(%esi),%esi
  800e70:	29 f9                	sub    %edi,%ecx
  800e72:	19 d6                	sbb    %edx,%esi
  800e74:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e78:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e7c:	e9 18 ff ff ff       	jmp    800d99 <__umoddi3+0x69>
