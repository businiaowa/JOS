
obj/user/hello:     file format elf32-i386


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
  80002c:	e8 2d 00 00 00       	call   80005e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 14             	sub    $0x14,%esp
	cprintf("hello, world\n");
  800039:	68 20 0e 80 00       	push   $0x800e20
  80003e:	e8 09 01 00 00       	call   80014c <cprintf>
	cprintf("i am environment %08x\n", thisenv->env_id);
  800043:	a1 04 20 80 00       	mov    0x802004,%eax
  800048:	8b 40 48             	mov    0x48(%eax),%eax
  80004b:	83 c4 08             	add    $0x8,%esp
  80004e:	50                   	push   %eax
  80004f:	68 2e 0e 80 00       	push   $0x800e2e
  800054:	e8 f3 00 00 00       	call   80014c <cprintf>
}
  800059:	83 c4 10             	add    $0x10,%esp
  80005c:	c9                   	leave  
  80005d:	c3                   	ret    

0080005e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005e:	55                   	push   %ebp
  80005f:	89 e5                	mov    %esp,%ebp
  800061:	56                   	push   %esi
  800062:	53                   	push   %ebx
  800063:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800066:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  800069:	e8 a7 0a 00 00       	call   800b15 <sys_getenvid>
  80006e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800073:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800076:	c1 e0 05             	shl    $0x5,%eax
  800079:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80007e:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800083:	85 db                	test   %ebx,%ebx
  800085:	7e 07                	jle    80008e <libmain+0x30>
		binaryname = argv[0];
  800087:	8b 06                	mov    (%esi),%eax
  800089:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80008e:	83 ec 08             	sub    $0x8,%esp
  800091:	56                   	push   %esi
  800092:	53                   	push   %ebx
  800093:	e8 9b ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800098:	e8 0a 00 00 00       	call   8000a7 <exit>
}
  80009d:	83 c4 10             	add    $0x10,%esp
  8000a0:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8000a3:	5b                   	pop    %ebx
  8000a4:	5e                   	pop    %esi
  8000a5:	5d                   	pop    %ebp
  8000a6:	c3                   	ret    

008000a7 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000a7:	55                   	push   %ebp
  8000a8:	89 e5                	mov    %esp,%ebp
  8000aa:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000ad:	6a 00                	push   $0x0
  8000af:	e8 20 0a 00 00       	call   800ad4 <sys_env_destroy>
}
  8000b4:	83 c4 10             	add    $0x10,%esp
  8000b7:	c9                   	leave  
  8000b8:	c3                   	ret    

008000b9 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000b9:	55                   	push   %ebp
  8000ba:	89 e5                	mov    %esp,%ebp
  8000bc:	53                   	push   %ebx
  8000bd:	83 ec 04             	sub    $0x4,%esp
  8000c0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c3:	8b 13                	mov    (%ebx),%edx
  8000c5:	8d 42 01             	lea    0x1(%edx),%eax
  8000c8:	89 03                	mov    %eax,(%ebx)
  8000ca:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000cd:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000d1:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000d6:	75 1a                	jne    8000f2 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000d8:	83 ec 08             	sub    $0x8,%esp
  8000db:	68 ff 00 00 00       	push   $0xff
  8000e0:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e3:	50                   	push   %eax
  8000e4:	e8 ae 09 00 00       	call   800a97 <sys_cputs>
		b->idx = 0;
  8000e9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000ef:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000f2:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000f6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000f9:	c9                   	leave  
  8000fa:	c3                   	ret    

008000fb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000fb:	55                   	push   %ebp
  8000fc:	89 e5                	mov    %esp,%ebp
  8000fe:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800104:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80010b:	00 00 00 
	b.cnt = 0;
  80010e:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800115:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800118:	ff 75 0c             	pushl  0xc(%ebp)
  80011b:	ff 75 08             	pushl  0x8(%ebp)
  80011e:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800124:	50                   	push   %eax
  800125:	68 b9 00 80 00       	push   $0x8000b9
  80012a:	e8 1a 01 00 00       	call   800249 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80012f:	83 c4 08             	add    $0x8,%esp
  800132:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800138:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80013e:	50                   	push   %eax
  80013f:	e8 53 09 00 00       	call   800a97 <sys_cputs>

	return b.cnt;
}
  800144:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80014a:	c9                   	leave  
  80014b:	c3                   	ret    

0080014c <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80014c:	55                   	push   %ebp
  80014d:	89 e5                	mov    %esp,%ebp
  80014f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800152:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800155:	50                   	push   %eax
  800156:	ff 75 08             	pushl  0x8(%ebp)
  800159:	e8 9d ff ff ff       	call   8000fb <vcprintf>
	va_end(ap);

	return cnt;
}
  80015e:	c9                   	leave  
  80015f:	c3                   	ret    

00800160 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800160:	55                   	push   %ebp
  800161:	89 e5                	mov    %esp,%ebp
  800163:	57                   	push   %edi
  800164:	56                   	push   %esi
  800165:	53                   	push   %ebx
  800166:	83 ec 1c             	sub    $0x1c,%esp
  800169:	89 c7                	mov    %eax,%edi
  80016b:	89 d6                	mov    %edx,%esi
  80016d:	8b 45 08             	mov    0x8(%ebp),%eax
  800170:	8b 55 0c             	mov    0xc(%ebp),%edx
  800173:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800176:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800179:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80017c:	bb 00 00 00 00       	mov    $0x0,%ebx
  800181:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800184:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800187:	39 d3                	cmp    %edx,%ebx
  800189:	72 05                	jb     800190 <printnum+0x30>
  80018b:	39 45 10             	cmp    %eax,0x10(%ebp)
  80018e:	77 45                	ja     8001d5 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800190:	83 ec 0c             	sub    $0xc,%esp
  800193:	ff 75 18             	pushl  0x18(%ebp)
  800196:	8b 45 14             	mov    0x14(%ebp),%eax
  800199:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80019c:	53                   	push   %ebx
  80019d:	ff 75 10             	pushl  0x10(%ebp)
  8001a0:	83 ec 08             	sub    $0x8,%esp
  8001a3:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001a6:	ff 75 e0             	pushl  -0x20(%ebp)
  8001a9:	ff 75 dc             	pushl  -0x24(%ebp)
  8001ac:	ff 75 d8             	pushl  -0x28(%ebp)
  8001af:	e8 cc 09 00 00       	call   800b80 <__udivdi3>
  8001b4:	83 c4 18             	add    $0x18,%esp
  8001b7:	52                   	push   %edx
  8001b8:	50                   	push   %eax
  8001b9:	89 f2                	mov    %esi,%edx
  8001bb:	89 f8                	mov    %edi,%eax
  8001bd:	e8 9e ff ff ff       	call   800160 <printnum>
  8001c2:	83 c4 20             	add    $0x20,%esp
  8001c5:	eb 18                	jmp    8001df <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001c7:	83 ec 08             	sub    $0x8,%esp
  8001ca:	56                   	push   %esi
  8001cb:	ff 75 18             	pushl  0x18(%ebp)
  8001ce:	ff d7                	call   *%edi
  8001d0:	83 c4 10             	add    $0x10,%esp
  8001d3:	eb 03                	jmp    8001d8 <printnum+0x78>
  8001d5:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001d8:	83 eb 01             	sub    $0x1,%ebx
  8001db:	85 db                	test   %ebx,%ebx
  8001dd:	7f e8                	jg     8001c7 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001df:	83 ec 08             	sub    $0x8,%esp
  8001e2:	56                   	push   %esi
  8001e3:	83 ec 04             	sub    $0x4,%esp
  8001e6:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001e9:	ff 75 e0             	pushl  -0x20(%ebp)
  8001ec:	ff 75 dc             	pushl  -0x24(%ebp)
  8001ef:	ff 75 d8             	pushl  -0x28(%ebp)
  8001f2:	e8 b9 0a 00 00       	call   800cb0 <__umoddi3>
  8001f7:	83 c4 14             	add    $0x14,%esp
  8001fa:	0f be 80 4f 0e 80 00 	movsbl 0x800e4f(%eax),%eax
  800201:	50                   	push   %eax
  800202:	ff d7                	call   *%edi
}
  800204:	83 c4 10             	add    $0x10,%esp
  800207:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80020a:	5b                   	pop    %ebx
  80020b:	5e                   	pop    %esi
  80020c:	5f                   	pop    %edi
  80020d:	5d                   	pop    %ebp
  80020e:	c3                   	ret    

0080020f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80020f:	55                   	push   %ebp
  800210:	89 e5                	mov    %esp,%ebp
  800212:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800215:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800219:	8b 10                	mov    (%eax),%edx
  80021b:	3b 50 04             	cmp    0x4(%eax),%edx
  80021e:	73 0a                	jae    80022a <sprintputch+0x1b>
		*b->buf++ = ch;
  800220:	8d 4a 01             	lea    0x1(%edx),%ecx
  800223:	89 08                	mov    %ecx,(%eax)
  800225:	8b 45 08             	mov    0x8(%ebp),%eax
  800228:	88 02                	mov    %al,(%edx)
}
  80022a:	5d                   	pop    %ebp
  80022b:	c3                   	ret    

0080022c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80022c:	55                   	push   %ebp
  80022d:	89 e5                	mov    %esp,%ebp
  80022f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800232:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800235:	50                   	push   %eax
  800236:	ff 75 10             	pushl  0x10(%ebp)
  800239:	ff 75 0c             	pushl  0xc(%ebp)
  80023c:	ff 75 08             	pushl  0x8(%ebp)
  80023f:	e8 05 00 00 00       	call   800249 <vprintfmt>
	va_end(ap);
}
  800244:	83 c4 10             	add    $0x10,%esp
  800247:	c9                   	leave  
  800248:	c3                   	ret    

00800249 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800249:	55                   	push   %ebp
  80024a:	89 e5                	mov    %esp,%ebp
  80024c:	57                   	push   %edi
  80024d:	56                   	push   %esi
  80024e:	53                   	push   %ebx
  80024f:	83 ec 2c             	sub    $0x2c,%esp
  800252:	8b 75 08             	mov    0x8(%ebp),%esi
  800255:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800258:	8b 7d 10             	mov    0x10(%ebp),%edi
  80025b:	eb 12                	jmp    80026f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80025d:	85 c0                	test   %eax,%eax
  80025f:	0f 84 42 04 00 00    	je     8006a7 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800265:	83 ec 08             	sub    $0x8,%esp
  800268:	53                   	push   %ebx
  800269:	50                   	push   %eax
  80026a:	ff d6                	call   *%esi
  80026c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80026f:	83 c7 01             	add    $0x1,%edi
  800272:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800276:	83 f8 25             	cmp    $0x25,%eax
  800279:	75 e2                	jne    80025d <vprintfmt+0x14>
  80027b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80027f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800286:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80028d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800294:	b9 00 00 00 00       	mov    $0x0,%ecx
  800299:	eb 07                	jmp    8002a2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80029b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80029e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002a2:	8d 47 01             	lea    0x1(%edi),%eax
  8002a5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002a8:	0f b6 07             	movzbl (%edi),%eax
  8002ab:	0f b6 d0             	movzbl %al,%edx
  8002ae:	83 e8 23             	sub    $0x23,%eax
  8002b1:	3c 55                	cmp    $0x55,%al
  8002b3:	0f 87 d3 03 00 00    	ja     80068c <vprintfmt+0x443>
  8002b9:	0f b6 c0             	movzbl %al,%eax
  8002bc:	ff 24 85 e0 0e 80 00 	jmp    *0x800ee0(,%eax,4)
  8002c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8002c6:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002ca:	eb d6                	jmp    8002a2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002cf:	b8 00 00 00 00       	mov    $0x0,%eax
  8002d4:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8002d7:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8002da:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8002de:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8002e1:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8002e4:	83 f9 09             	cmp    $0x9,%ecx
  8002e7:	77 3f                	ja     800328 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8002e9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8002ec:	eb e9                	jmp    8002d7 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8002ee:	8b 45 14             	mov    0x14(%ebp),%eax
  8002f1:	8b 00                	mov    (%eax),%eax
  8002f3:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8002f6:	8b 45 14             	mov    0x14(%ebp),%eax
  8002f9:	8d 40 04             	lea    0x4(%eax),%eax
  8002fc:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002ff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800302:	eb 2a                	jmp    80032e <vprintfmt+0xe5>
  800304:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800307:	85 c0                	test   %eax,%eax
  800309:	ba 00 00 00 00       	mov    $0x0,%edx
  80030e:	0f 49 d0             	cmovns %eax,%edx
  800311:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800314:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800317:	eb 89                	jmp    8002a2 <vprintfmt+0x59>
  800319:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80031c:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800323:	e9 7a ff ff ff       	jmp    8002a2 <vprintfmt+0x59>
  800328:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  80032b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80032e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800332:	0f 89 6a ff ff ff    	jns    8002a2 <vprintfmt+0x59>
				width = precision, precision = -1;
  800338:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80033b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80033e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800345:	e9 58 ff ff ff       	jmp    8002a2 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80034a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800350:	e9 4d ff ff ff       	jmp    8002a2 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800355:	8b 45 14             	mov    0x14(%ebp),%eax
  800358:	8d 78 04             	lea    0x4(%eax),%edi
  80035b:	83 ec 08             	sub    $0x8,%esp
  80035e:	53                   	push   %ebx
  80035f:	ff 30                	pushl  (%eax)
  800361:	ff d6                	call   *%esi
			break;
  800363:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800366:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800369:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80036c:	e9 fe fe ff ff       	jmp    80026f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800371:	8b 45 14             	mov    0x14(%ebp),%eax
  800374:	8d 78 04             	lea    0x4(%eax),%edi
  800377:	8b 00                	mov    (%eax),%eax
  800379:	99                   	cltd   
  80037a:	31 d0                	xor    %edx,%eax
  80037c:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80037e:	83 f8 07             	cmp    $0x7,%eax
  800381:	7f 0b                	jg     80038e <vprintfmt+0x145>
  800383:	8b 14 85 40 10 80 00 	mov    0x801040(,%eax,4),%edx
  80038a:	85 d2                	test   %edx,%edx
  80038c:	75 1b                	jne    8003a9 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80038e:	50                   	push   %eax
  80038f:	68 67 0e 80 00       	push   $0x800e67
  800394:	53                   	push   %ebx
  800395:	56                   	push   %esi
  800396:	e8 91 fe ff ff       	call   80022c <printfmt>
  80039b:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80039e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003a4:	e9 c6 fe ff ff       	jmp    80026f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003a9:	52                   	push   %edx
  8003aa:	68 70 0e 80 00       	push   $0x800e70
  8003af:	53                   	push   %ebx
  8003b0:	56                   	push   %esi
  8003b1:	e8 76 fe ff ff       	call   80022c <printfmt>
  8003b6:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003b9:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003bf:	e9 ab fe ff ff       	jmp    80026f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003c4:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c7:	83 c0 04             	add    $0x4,%eax
  8003ca:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8003cd:	8b 45 14             	mov    0x14(%ebp),%eax
  8003d0:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003d2:	85 ff                	test   %edi,%edi
  8003d4:	b8 60 0e 80 00       	mov    $0x800e60,%eax
  8003d9:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003dc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003e0:	0f 8e 94 00 00 00    	jle    80047a <vprintfmt+0x231>
  8003e6:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8003ea:	0f 84 98 00 00 00    	je     800488 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8003f0:	83 ec 08             	sub    $0x8,%esp
  8003f3:	ff 75 d0             	pushl  -0x30(%ebp)
  8003f6:	57                   	push   %edi
  8003f7:	e8 33 03 00 00       	call   80072f <strnlen>
  8003fc:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8003ff:	29 c1                	sub    %eax,%ecx
  800401:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  800404:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800407:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80040b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80040e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800411:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800413:	eb 0f                	jmp    800424 <vprintfmt+0x1db>
					putch(padc, putdat);
  800415:	83 ec 08             	sub    $0x8,%esp
  800418:	53                   	push   %ebx
  800419:	ff 75 e0             	pushl  -0x20(%ebp)
  80041c:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80041e:	83 ef 01             	sub    $0x1,%edi
  800421:	83 c4 10             	add    $0x10,%esp
  800424:	85 ff                	test   %edi,%edi
  800426:	7f ed                	jg     800415 <vprintfmt+0x1cc>
  800428:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80042b:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  80042e:	85 c9                	test   %ecx,%ecx
  800430:	b8 00 00 00 00       	mov    $0x0,%eax
  800435:	0f 49 c1             	cmovns %ecx,%eax
  800438:	29 c1                	sub    %eax,%ecx
  80043a:	89 75 08             	mov    %esi,0x8(%ebp)
  80043d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800440:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800443:	89 cb                	mov    %ecx,%ebx
  800445:	eb 4d                	jmp    800494 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800447:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80044b:	74 1b                	je     800468 <vprintfmt+0x21f>
  80044d:	0f be c0             	movsbl %al,%eax
  800450:	83 e8 20             	sub    $0x20,%eax
  800453:	83 f8 5e             	cmp    $0x5e,%eax
  800456:	76 10                	jbe    800468 <vprintfmt+0x21f>
					putch('?', putdat);
  800458:	83 ec 08             	sub    $0x8,%esp
  80045b:	ff 75 0c             	pushl  0xc(%ebp)
  80045e:	6a 3f                	push   $0x3f
  800460:	ff 55 08             	call   *0x8(%ebp)
  800463:	83 c4 10             	add    $0x10,%esp
  800466:	eb 0d                	jmp    800475 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800468:	83 ec 08             	sub    $0x8,%esp
  80046b:	ff 75 0c             	pushl  0xc(%ebp)
  80046e:	52                   	push   %edx
  80046f:	ff 55 08             	call   *0x8(%ebp)
  800472:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800475:	83 eb 01             	sub    $0x1,%ebx
  800478:	eb 1a                	jmp    800494 <vprintfmt+0x24b>
  80047a:	89 75 08             	mov    %esi,0x8(%ebp)
  80047d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800480:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800483:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800486:	eb 0c                	jmp    800494 <vprintfmt+0x24b>
  800488:	89 75 08             	mov    %esi,0x8(%ebp)
  80048b:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80048e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800491:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800494:	83 c7 01             	add    $0x1,%edi
  800497:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80049b:	0f be d0             	movsbl %al,%edx
  80049e:	85 d2                	test   %edx,%edx
  8004a0:	74 23                	je     8004c5 <vprintfmt+0x27c>
  8004a2:	85 f6                	test   %esi,%esi
  8004a4:	78 a1                	js     800447 <vprintfmt+0x1fe>
  8004a6:	83 ee 01             	sub    $0x1,%esi
  8004a9:	79 9c                	jns    800447 <vprintfmt+0x1fe>
  8004ab:	89 df                	mov    %ebx,%edi
  8004ad:	8b 75 08             	mov    0x8(%ebp),%esi
  8004b0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004b3:	eb 18                	jmp    8004cd <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004b5:	83 ec 08             	sub    $0x8,%esp
  8004b8:	53                   	push   %ebx
  8004b9:	6a 20                	push   $0x20
  8004bb:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004bd:	83 ef 01             	sub    $0x1,%edi
  8004c0:	83 c4 10             	add    $0x10,%esp
  8004c3:	eb 08                	jmp    8004cd <vprintfmt+0x284>
  8004c5:	89 df                	mov    %ebx,%edi
  8004c7:	8b 75 08             	mov    0x8(%ebp),%esi
  8004ca:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004cd:	85 ff                	test   %edi,%edi
  8004cf:	7f e4                	jg     8004b5 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004d1:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8004d4:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004da:	e9 90 fd ff ff       	jmp    80026f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004df:	83 f9 01             	cmp    $0x1,%ecx
  8004e2:	7e 19                	jle    8004fd <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8004e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004e7:	8b 50 04             	mov    0x4(%eax),%edx
  8004ea:	8b 00                	mov    (%eax),%eax
  8004ec:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004ef:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004f2:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f5:	8d 40 08             	lea    0x8(%eax),%eax
  8004f8:	89 45 14             	mov    %eax,0x14(%ebp)
  8004fb:	eb 38                	jmp    800535 <vprintfmt+0x2ec>
	else if (lflag)
  8004fd:	85 c9                	test   %ecx,%ecx
  8004ff:	74 1b                	je     80051c <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  800501:	8b 45 14             	mov    0x14(%ebp),%eax
  800504:	8b 00                	mov    (%eax),%eax
  800506:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800509:	89 c1                	mov    %eax,%ecx
  80050b:	c1 f9 1f             	sar    $0x1f,%ecx
  80050e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800511:	8b 45 14             	mov    0x14(%ebp),%eax
  800514:	8d 40 04             	lea    0x4(%eax),%eax
  800517:	89 45 14             	mov    %eax,0x14(%ebp)
  80051a:	eb 19                	jmp    800535 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  80051c:	8b 45 14             	mov    0x14(%ebp),%eax
  80051f:	8b 00                	mov    (%eax),%eax
  800521:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800524:	89 c1                	mov    %eax,%ecx
  800526:	c1 f9 1f             	sar    $0x1f,%ecx
  800529:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80052c:	8b 45 14             	mov    0x14(%ebp),%eax
  80052f:	8d 40 04             	lea    0x4(%eax),%eax
  800532:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800535:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800538:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80053b:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800540:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800544:	0f 89 0e 01 00 00    	jns    800658 <vprintfmt+0x40f>
				putch('-', putdat);
  80054a:	83 ec 08             	sub    $0x8,%esp
  80054d:	53                   	push   %ebx
  80054e:	6a 2d                	push   $0x2d
  800550:	ff d6                	call   *%esi
				num = -(long long) num;
  800552:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800555:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800558:	f7 da                	neg    %edx
  80055a:	83 d1 00             	adc    $0x0,%ecx
  80055d:	f7 d9                	neg    %ecx
  80055f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800562:	b8 0a 00 00 00       	mov    $0xa,%eax
  800567:	e9 ec 00 00 00       	jmp    800658 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80056c:	83 f9 01             	cmp    $0x1,%ecx
  80056f:	7e 18                	jle    800589 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800571:	8b 45 14             	mov    0x14(%ebp),%eax
  800574:	8b 10                	mov    (%eax),%edx
  800576:	8b 48 04             	mov    0x4(%eax),%ecx
  800579:	8d 40 08             	lea    0x8(%eax),%eax
  80057c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80057f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800584:	e9 cf 00 00 00       	jmp    800658 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800589:	85 c9                	test   %ecx,%ecx
  80058b:	74 1a                	je     8005a7 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80058d:	8b 45 14             	mov    0x14(%ebp),%eax
  800590:	8b 10                	mov    (%eax),%edx
  800592:	b9 00 00 00 00       	mov    $0x0,%ecx
  800597:	8d 40 04             	lea    0x4(%eax),%eax
  80059a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80059d:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005a2:	e9 b1 00 00 00       	jmp    800658 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8005a7:	8b 45 14             	mov    0x14(%ebp),%eax
  8005aa:	8b 10                	mov    (%eax),%edx
  8005ac:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005b1:	8d 40 04             	lea    0x4(%eax),%eax
  8005b4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005b7:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005bc:	e9 97 00 00 00       	jmp    800658 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  8005c1:	83 ec 08             	sub    $0x8,%esp
  8005c4:	53                   	push   %ebx
  8005c5:	6a 58                	push   $0x58
  8005c7:	ff d6                	call   *%esi
			putch('X', putdat);
  8005c9:	83 c4 08             	add    $0x8,%esp
  8005cc:	53                   	push   %ebx
  8005cd:	6a 58                	push   $0x58
  8005cf:	ff d6                	call   *%esi
			putch('X', putdat);
  8005d1:	83 c4 08             	add    $0x8,%esp
  8005d4:	53                   	push   %ebx
  8005d5:	6a 58                	push   $0x58
  8005d7:	ff d6                	call   *%esi
			break;
  8005d9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005dc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8005df:	e9 8b fc ff ff       	jmp    80026f <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8005e4:	83 ec 08             	sub    $0x8,%esp
  8005e7:	53                   	push   %ebx
  8005e8:	6a 30                	push   $0x30
  8005ea:	ff d6                	call   *%esi
			putch('x', putdat);
  8005ec:	83 c4 08             	add    $0x8,%esp
  8005ef:	53                   	push   %ebx
  8005f0:	6a 78                	push   $0x78
  8005f2:	ff d6                	call   *%esi
			num = (unsigned long long)
  8005f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f7:	8b 10                	mov    (%eax),%edx
  8005f9:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005fe:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800601:	8d 40 04             	lea    0x4(%eax),%eax
  800604:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  800607:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  80060c:	eb 4a                	jmp    800658 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80060e:	83 f9 01             	cmp    $0x1,%ecx
  800611:	7e 15                	jle    800628 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  800613:	8b 45 14             	mov    0x14(%ebp),%eax
  800616:	8b 10                	mov    (%eax),%edx
  800618:	8b 48 04             	mov    0x4(%eax),%ecx
  80061b:	8d 40 08             	lea    0x8(%eax),%eax
  80061e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800621:	b8 10 00 00 00       	mov    $0x10,%eax
  800626:	eb 30                	jmp    800658 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800628:	85 c9                	test   %ecx,%ecx
  80062a:	74 17                	je     800643 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  80062c:	8b 45 14             	mov    0x14(%ebp),%eax
  80062f:	8b 10                	mov    (%eax),%edx
  800631:	b9 00 00 00 00       	mov    $0x0,%ecx
  800636:	8d 40 04             	lea    0x4(%eax),%eax
  800639:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80063c:	b8 10 00 00 00       	mov    $0x10,%eax
  800641:	eb 15                	jmp    800658 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800643:	8b 45 14             	mov    0x14(%ebp),%eax
  800646:	8b 10                	mov    (%eax),%edx
  800648:	b9 00 00 00 00       	mov    $0x0,%ecx
  80064d:	8d 40 04             	lea    0x4(%eax),%eax
  800650:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800653:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800658:	83 ec 0c             	sub    $0xc,%esp
  80065b:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80065f:	57                   	push   %edi
  800660:	ff 75 e0             	pushl  -0x20(%ebp)
  800663:	50                   	push   %eax
  800664:	51                   	push   %ecx
  800665:	52                   	push   %edx
  800666:	89 da                	mov    %ebx,%edx
  800668:	89 f0                	mov    %esi,%eax
  80066a:	e8 f1 fa ff ff       	call   800160 <printnum>
			break;
  80066f:	83 c4 20             	add    $0x20,%esp
  800672:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800675:	e9 f5 fb ff ff       	jmp    80026f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80067a:	83 ec 08             	sub    $0x8,%esp
  80067d:	53                   	push   %ebx
  80067e:	52                   	push   %edx
  80067f:	ff d6                	call   *%esi
			break;
  800681:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800684:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800687:	e9 e3 fb ff ff       	jmp    80026f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80068c:	83 ec 08             	sub    $0x8,%esp
  80068f:	53                   	push   %ebx
  800690:	6a 25                	push   $0x25
  800692:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800694:	83 c4 10             	add    $0x10,%esp
  800697:	eb 03                	jmp    80069c <vprintfmt+0x453>
  800699:	83 ef 01             	sub    $0x1,%edi
  80069c:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006a0:	75 f7                	jne    800699 <vprintfmt+0x450>
  8006a2:	e9 c8 fb ff ff       	jmp    80026f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006a7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006aa:	5b                   	pop    %ebx
  8006ab:	5e                   	pop    %esi
  8006ac:	5f                   	pop    %edi
  8006ad:	5d                   	pop    %ebp
  8006ae:	c3                   	ret    

008006af <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006af:	55                   	push   %ebp
  8006b0:	89 e5                	mov    %esp,%ebp
  8006b2:	83 ec 18             	sub    $0x18,%esp
  8006b5:	8b 45 08             	mov    0x8(%ebp),%eax
  8006b8:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006bb:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006be:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006c2:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006c5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006cc:	85 c0                	test   %eax,%eax
  8006ce:	74 26                	je     8006f6 <vsnprintf+0x47>
  8006d0:	85 d2                	test   %edx,%edx
  8006d2:	7e 22                	jle    8006f6 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006d4:	ff 75 14             	pushl  0x14(%ebp)
  8006d7:	ff 75 10             	pushl  0x10(%ebp)
  8006da:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006dd:	50                   	push   %eax
  8006de:	68 0f 02 80 00       	push   $0x80020f
  8006e3:	e8 61 fb ff ff       	call   800249 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006e8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006eb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006f1:	83 c4 10             	add    $0x10,%esp
  8006f4:	eb 05                	jmp    8006fb <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006f6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006fb:	c9                   	leave  
  8006fc:	c3                   	ret    

008006fd <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006fd:	55                   	push   %ebp
  8006fe:	89 e5                	mov    %esp,%ebp
  800700:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800703:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800706:	50                   	push   %eax
  800707:	ff 75 10             	pushl  0x10(%ebp)
  80070a:	ff 75 0c             	pushl  0xc(%ebp)
  80070d:	ff 75 08             	pushl  0x8(%ebp)
  800710:	e8 9a ff ff ff       	call   8006af <vsnprintf>
	va_end(ap);

	return rc;
}
  800715:	c9                   	leave  
  800716:	c3                   	ret    

00800717 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800717:	55                   	push   %ebp
  800718:	89 e5                	mov    %esp,%ebp
  80071a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80071d:	b8 00 00 00 00       	mov    $0x0,%eax
  800722:	eb 03                	jmp    800727 <strlen+0x10>
		n++;
  800724:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800727:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80072b:	75 f7                	jne    800724 <strlen+0xd>
		n++;
	return n;
}
  80072d:	5d                   	pop    %ebp
  80072e:	c3                   	ret    

0080072f <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80072f:	55                   	push   %ebp
  800730:	89 e5                	mov    %esp,%ebp
  800732:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800735:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800738:	ba 00 00 00 00       	mov    $0x0,%edx
  80073d:	eb 03                	jmp    800742 <strnlen+0x13>
		n++;
  80073f:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800742:	39 c2                	cmp    %eax,%edx
  800744:	74 08                	je     80074e <strnlen+0x1f>
  800746:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80074a:	75 f3                	jne    80073f <strnlen+0x10>
  80074c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80074e:	5d                   	pop    %ebp
  80074f:	c3                   	ret    

00800750 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800750:	55                   	push   %ebp
  800751:	89 e5                	mov    %esp,%ebp
  800753:	53                   	push   %ebx
  800754:	8b 45 08             	mov    0x8(%ebp),%eax
  800757:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80075a:	89 c2                	mov    %eax,%edx
  80075c:	83 c2 01             	add    $0x1,%edx
  80075f:	83 c1 01             	add    $0x1,%ecx
  800762:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800766:	88 5a ff             	mov    %bl,-0x1(%edx)
  800769:	84 db                	test   %bl,%bl
  80076b:	75 ef                	jne    80075c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80076d:	5b                   	pop    %ebx
  80076e:	5d                   	pop    %ebp
  80076f:	c3                   	ret    

00800770 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800770:	55                   	push   %ebp
  800771:	89 e5                	mov    %esp,%ebp
  800773:	53                   	push   %ebx
  800774:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800777:	53                   	push   %ebx
  800778:	e8 9a ff ff ff       	call   800717 <strlen>
  80077d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800780:	ff 75 0c             	pushl  0xc(%ebp)
  800783:	01 d8                	add    %ebx,%eax
  800785:	50                   	push   %eax
  800786:	e8 c5 ff ff ff       	call   800750 <strcpy>
	return dst;
}
  80078b:	89 d8                	mov    %ebx,%eax
  80078d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800790:	c9                   	leave  
  800791:	c3                   	ret    

00800792 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800792:	55                   	push   %ebp
  800793:	89 e5                	mov    %esp,%ebp
  800795:	56                   	push   %esi
  800796:	53                   	push   %ebx
  800797:	8b 75 08             	mov    0x8(%ebp),%esi
  80079a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80079d:	89 f3                	mov    %esi,%ebx
  80079f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007a2:	89 f2                	mov    %esi,%edx
  8007a4:	eb 0f                	jmp    8007b5 <strncpy+0x23>
		*dst++ = *src;
  8007a6:	83 c2 01             	add    $0x1,%edx
  8007a9:	0f b6 01             	movzbl (%ecx),%eax
  8007ac:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007af:	80 39 01             	cmpb   $0x1,(%ecx)
  8007b2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007b5:	39 da                	cmp    %ebx,%edx
  8007b7:	75 ed                	jne    8007a6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007b9:	89 f0                	mov    %esi,%eax
  8007bb:	5b                   	pop    %ebx
  8007bc:	5e                   	pop    %esi
  8007bd:	5d                   	pop    %ebp
  8007be:	c3                   	ret    

008007bf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007bf:	55                   	push   %ebp
  8007c0:	89 e5                	mov    %esp,%ebp
  8007c2:	56                   	push   %esi
  8007c3:	53                   	push   %ebx
  8007c4:	8b 75 08             	mov    0x8(%ebp),%esi
  8007c7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007ca:	8b 55 10             	mov    0x10(%ebp),%edx
  8007cd:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007cf:	85 d2                	test   %edx,%edx
  8007d1:	74 21                	je     8007f4 <strlcpy+0x35>
  8007d3:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8007d7:	89 f2                	mov    %esi,%edx
  8007d9:	eb 09                	jmp    8007e4 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007db:	83 c2 01             	add    $0x1,%edx
  8007de:	83 c1 01             	add    $0x1,%ecx
  8007e1:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007e4:	39 c2                	cmp    %eax,%edx
  8007e6:	74 09                	je     8007f1 <strlcpy+0x32>
  8007e8:	0f b6 19             	movzbl (%ecx),%ebx
  8007eb:	84 db                	test   %bl,%bl
  8007ed:	75 ec                	jne    8007db <strlcpy+0x1c>
  8007ef:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8007f1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8007f4:	29 f0                	sub    %esi,%eax
}
  8007f6:	5b                   	pop    %ebx
  8007f7:	5e                   	pop    %esi
  8007f8:	5d                   	pop    %ebp
  8007f9:	c3                   	ret    

008007fa <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8007fa:	55                   	push   %ebp
  8007fb:	89 e5                	mov    %esp,%ebp
  8007fd:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800800:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800803:	eb 06                	jmp    80080b <strcmp+0x11>
		p++, q++;
  800805:	83 c1 01             	add    $0x1,%ecx
  800808:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80080b:	0f b6 01             	movzbl (%ecx),%eax
  80080e:	84 c0                	test   %al,%al
  800810:	74 04                	je     800816 <strcmp+0x1c>
  800812:	3a 02                	cmp    (%edx),%al
  800814:	74 ef                	je     800805 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800816:	0f b6 c0             	movzbl %al,%eax
  800819:	0f b6 12             	movzbl (%edx),%edx
  80081c:	29 d0                	sub    %edx,%eax
}
  80081e:	5d                   	pop    %ebp
  80081f:	c3                   	ret    

00800820 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800820:	55                   	push   %ebp
  800821:	89 e5                	mov    %esp,%ebp
  800823:	53                   	push   %ebx
  800824:	8b 45 08             	mov    0x8(%ebp),%eax
  800827:	8b 55 0c             	mov    0xc(%ebp),%edx
  80082a:	89 c3                	mov    %eax,%ebx
  80082c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80082f:	eb 06                	jmp    800837 <strncmp+0x17>
		n--, p++, q++;
  800831:	83 c0 01             	add    $0x1,%eax
  800834:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800837:	39 d8                	cmp    %ebx,%eax
  800839:	74 15                	je     800850 <strncmp+0x30>
  80083b:	0f b6 08             	movzbl (%eax),%ecx
  80083e:	84 c9                	test   %cl,%cl
  800840:	74 04                	je     800846 <strncmp+0x26>
  800842:	3a 0a                	cmp    (%edx),%cl
  800844:	74 eb                	je     800831 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800846:	0f b6 00             	movzbl (%eax),%eax
  800849:	0f b6 12             	movzbl (%edx),%edx
  80084c:	29 d0                	sub    %edx,%eax
  80084e:	eb 05                	jmp    800855 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800850:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800855:	5b                   	pop    %ebx
  800856:	5d                   	pop    %ebp
  800857:	c3                   	ret    

00800858 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800858:	55                   	push   %ebp
  800859:	89 e5                	mov    %esp,%ebp
  80085b:	8b 45 08             	mov    0x8(%ebp),%eax
  80085e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800862:	eb 07                	jmp    80086b <strchr+0x13>
		if (*s == c)
  800864:	38 ca                	cmp    %cl,%dl
  800866:	74 0f                	je     800877 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800868:	83 c0 01             	add    $0x1,%eax
  80086b:	0f b6 10             	movzbl (%eax),%edx
  80086e:	84 d2                	test   %dl,%dl
  800870:	75 f2                	jne    800864 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800872:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800877:	5d                   	pop    %ebp
  800878:	c3                   	ret    

00800879 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800879:	55                   	push   %ebp
  80087a:	89 e5                	mov    %esp,%ebp
  80087c:	8b 45 08             	mov    0x8(%ebp),%eax
  80087f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800883:	eb 03                	jmp    800888 <strfind+0xf>
  800885:	83 c0 01             	add    $0x1,%eax
  800888:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  80088b:	38 ca                	cmp    %cl,%dl
  80088d:	74 04                	je     800893 <strfind+0x1a>
  80088f:	84 d2                	test   %dl,%dl
  800891:	75 f2                	jne    800885 <strfind+0xc>
			break;
	return (char *) s;
}
  800893:	5d                   	pop    %ebp
  800894:	c3                   	ret    

00800895 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800895:	55                   	push   %ebp
  800896:	89 e5                	mov    %esp,%ebp
  800898:	57                   	push   %edi
  800899:	56                   	push   %esi
  80089a:	53                   	push   %ebx
  80089b:	8b 7d 08             	mov    0x8(%ebp),%edi
  80089e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008a1:	85 c9                	test   %ecx,%ecx
  8008a3:	74 36                	je     8008db <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008a5:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008ab:	75 28                	jne    8008d5 <memset+0x40>
  8008ad:	f6 c1 03             	test   $0x3,%cl
  8008b0:	75 23                	jne    8008d5 <memset+0x40>
		c &= 0xFF;
  8008b2:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008b6:	89 d3                	mov    %edx,%ebx
  8008b8:	c1 e3 08             	shl    $0x8,%ebx
  8008bb:	89 d6                	mov    %edx,%esi
  8008bd:	c1 e6 18             	shl    $0x18,%esi
  8008c0:	89 d0                	mov    %edx,%eax
  8008c2:	c1 e0 10             	shl    $0x10,%eax
  8008c5:	09 f0                	or     %esi,%eax
  8008c7:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008c9:	89 d8                	mov    %ebx,%eax
  8008cb:	09 d0                	or     %edx,%eax
  8008cd:	c1 e9 02             	shr    $0x2,%ecx
  8008d0:	fc                   	cld    
  8008d1:	f3 ab                	rep stos %eax,%es:(%edi)
  8008d3:	eb 06                	jmp    8008db <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008d5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008d8:	fc                   	cld    
  8008d9:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008db:	89 f8                	mov    %edi,%eax
  8008dd:	5b                   	pop    %ebx
  8008de:	5e                   	pop    %esi
  8008df:	5f                   	pop    %edi
  8008e0:	5d                   	pop    %ebp
  8008e1:	c3                   	ret    

008008e2 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008e2:	55                   	push   %ebp
  8008e3:	89 e5                	mov    %esp,%ebp
  8008e5:	57                   	push   %edi
  8008e6:	56                   	push   %esi
  8008e7:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ea:	8b 75 0c             	mov    0xc(%ebp),%esi
  8008ed:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8008f0:	39 c6                	cmp    %eax,%esi
  8008f2:	73 35                	jae    800929 <memmove+0x47>
  8008f4:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8008f7:	39 d0                	cmp    %edx,%eax
  8008f9:	73 2e                	jae    800929 <memmove+0x47>
		s += n;
		d += n;
  8008fb:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8008fe:	89 d6                	mov    %edx,%esi
  800900:	09 fe                	or     %edi,%esi
  800902:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800908:	75 13                	jne    80091d <memmove+0x3b>
  80090a:	f6 c1 03             	test   $0x3,%cl
  80090d:	75 0e                	jne    80091d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80090f:	83 ef 04             	sub    $0x4,%edi
  800912:	8d 72 fc             	lea    -0x4(%edx),%esi
  800915:	c1 e9 02             	shr    $0x2,%ecx
  800918:	fd                   	std    
  800919:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80091b:	eb 09                	jmp    800926 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80091d:	83 ef 01             	sub    $0x1,%edi
  800920:	8d 72 ff             	lea    -0x1(%edx),%esi
  800923:	fd                   	std    
  800924:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800926:	fc                   	cld    
  800927:	eb 1d                	jmp    800946 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800929:	89 f2                	mov    %esi,%edx
  80092b:	09 c2                	or     %eax,%edx
  80092d:	f6 c2 03             	test   $0x3,%dl
  800930:	75 0f                	jne    800941 <memmove+0x5f>
  800932:	f6 c1 03             	test   $0x3,%cl
  800935:	75 0a                	jne    800941 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800937:	c1 e9 02             	shr    $0x2,%ecx
  80093a:	89 c7                	mov    %eax,%edi
  80093c:	fc                   	cld    
  80093d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80093f:	eb 05                	jmp    800946 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800941:	89 c7                	mov    %eax,%edi
  800943:	fc                   	cld    
  800944:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800946:	5e                   	pop    %esi
  800947:	5f                   	pop    %edi
  800948:	5d                   	pop    %ebp
  800949:	c3                   	ret    

0080094a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80094a:	55                   	push   %ebp
  80094b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80094d:	ff 75 10             	pushl  0x10(%ebp)
  800950:	ff 75 0c             	pushl  0xc(%ebp)
  800953:	ff 75 08             	pushl  0x8(%ebp)
  800956:	e8 87 ff ff ff       	call   8008e2 <memmove>
}
  80095b:	c9                   	leave  
  80095c:	c3                   	ret    

0080095d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80095d:	55                   	push   %ebp
  80095e:	89 e5                	mov    %esp,%ebp
  800960:	56                   	push   %esi
  800961:	53                   	push   %ebx
  800962:	8b 45 08             	mov    0x8(%ebp),%eax
  800965:	8b 55 0c             	mov    0xc(%ebp),%edx
  800968:	89 c6                	mov    %eax,%esi
  80096a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80096d:	eb 1a                	jmp    800989 <memcmp+0x2c>
		if (*s1 != *s2)
  80096f:	0f b6 08             	movzbl (%eax),%ecx
  800972:	0f b6 1a             	movzbl (%edx),%ebx
  800975:	38 d9                	cmp    %bl,%cl
  800977:	74 0a                	je     800983 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800979:	0f b6 c1             	movzbl %cl,%eax
  80097c:	0f b6 db             	movzbl %bl,%ebx
  80097f:	29 d8                	sub    %ebx,%eax
  800981:	eb 0f                	jmp    800992 <memcmp+0x35>
		s1++, s2++;
  800983:	83 c0 01             	add    $0x1,%eax
  800986:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800989:	39 f0                	cmp    %esi,%eax
  80098b:	75 e2                	jne    80096f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  80098d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800992:	5b                   	pop    %ebx
  800993:	5e                   	pop    %esi
  800994:	5d                   	pop    %ebp
  800995:	c3                   	ret    

00800996 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800996:	55                   	push   %ebp
  800997:	89 e5                	mov    %esp,%ebp
  800999:	53                   	push   %ebx
  80099a:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  80099d:	89 c1                	mov    %eax,%ecx
  80099f:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009a2:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009a6:	eb 0a                	jmp    8009b2 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009a8:	0f b6 10             	movzbl (%eax),%edx
  8009ab:	39 da                	cmp    %ebx,%edx
  8009ad:	74 07                	je     8009b6 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009af:	83 c0 01             	add    $0x1,%eax
  8009b2:	39 c8                	cmp    %ecx,%eax
  8009b4:	72 f2                	jb     8009a8 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009b6:	5b                   	pop    %ebx
  8009b7:	5d                   	pop    %ebp
  8009b8:	c3                   	ret    

008009b9 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009b9:	55                   	push   %ebp
  8009ba:	89 e5                	mov    %esp,%ebp
  8009bc:	57                   	push   %edi
  8009bd:	56                   	push   %esi
  8009be:	53                   	push   %ebx
  8009bf:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009c2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009c5:	eb 03                	jmp    8009ca <strtol+0x11>
		s++;
  8009c7:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009ca:	0f b6 01             	movzbl (%ecx),%eax
  8009cd:	3c 20                	cmp    $0x20,%al
  8009cf:	74 f6                	je     8009c7 <strtol+0xe>
  8009d1:	3c 09                	cmp    $0x9,%al
  8009d3:	74 f2                	je     8009c7 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009d5:	3c 2b                	cmp    $0x2b,%al
  8009d7:	75 0a                	jne    8009e3 <strtol+0x2a>
		s++;
  8009d9:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009dc:	bf 00 00 00 00       	mov    $0x0,%edi
  8009e1:	eb 11                	jmp    8009f4 <strtol+0x3b>
  8009e3:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  8009e8:	3c 2d                	cmp    $0x2d,%al
  8009ea:	75 08                	jne    8009f4 <strtol+0x3b>
		s++, neg = 1;
  8009ec:	83 c1 01             	add    $0x1,%ecx
  8009ef:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  8009f4:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  8009fa:	75 15                	jne    800a11 <strtol+0x58>
  8009fc:	80 39 30             	cmpb   $0x30,(%ecx)
  8009ff:	75 10                	jne    800a11 <strtol+0x58>
  800a01:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a05:	75 7c                	jne    800a83 <strtol+0xca>
		s += 2, base = 16;
  800a07:	83 c1 02             	add    $0x2,%ecx
  800a0a:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a0f:	eb 16                	jmp    800a27 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a11:	85 db                	test   %ebx,%ebx
  800a13:	75 12                	jne    800a27 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a15:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a1a:	80 39 30             	cmpb   $0x30,(%ecx)
  800a1d:	75 08                	jne    800a27 <strtol+0x6e>
		s++, base = 8;
  800a1f:	83 c1 01             	add    $0x1,%ecx
  800a22:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a27:	b8 00 00 00 00       	mov    $0x0,%eax
  800a2c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a2f:	0f b6 11             	movzbl (%ecx),%edx
  800a32:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a35:	89 f3                	mov    %esi,%ebx
  800a37:	80 fb 09             	cmp    $0x9,%bl
  800a3a:	77 08                	ja     800a44 <strtol+0x8b>
			dig = *s - '0';
  800a3c:	0f be d2             	movsbl %dl,%edx
  800a3f:	83 ea 30             	sub    $0x30,%edx
  800a42:	eb 22                	jmp    800a66 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a44:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a47:	89 f3                	mov    %esi,%ebx
  800a49:	80 fb 19             	cmp    $0x19,%bl
  800a4c:	77 08                	ja     800a56 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a4e:	0f be d2             	movsbl %dl,%edx
  800a51:	83 ea 57             	sub    $0x57,%edx
  800a54:	eb 10                	jmp    800a66 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a56:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a59:	89 f3                	mov    %esi,%ebx
  800a5b:	80 fb 19             	cmp    $0x19,%bl
  800a5e:	77 16                	ja     800a76 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a60:	0f be d2             	movsbl %dl,%edx
  800a63:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a66:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a69:	7d 0b                	jge    800a76 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a6b:	83 c1 01             	add    $0x1,%ecx
  800a6e:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a72:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a74:	eb b9                	jmp    800a2f <strtol+0x76>

	if (endptr)
  800a76:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a7a:	74 0d                	je     800a89 <strtol+0xd0>
		*endptr = (char *) s;
  800a7c:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a7f:	89 0e                	mov    %ecx,(%esi)
  800a81:	eb 06                	jmp    800a89 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a83:	85 db                	test   %ebx,%ebx
  800a85:	74 98                	je     800a1f <strtol+0x66>
  800a87:	eb 9e                	jmp    800a27 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a89:	89 c2                	mov    %eax,%edx
  800a8b:	f7 da                	neg    %edx
  800a8d:	85 ff                	test   %edi,%edi
  800a8f:	0f 45 c2             	cmovne %edx,%eax
}
  800a92:	5b                   	pop    %ebx
  800a93:	5e                   	pop    %esi
  800a94:	5f                   	pop    %edi
  800a95:	5d                   	pop    %ebp
  800a96:	c3                   	ret    

00800a97 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a97:	55                   	push   %ebp
  800a98:	89 e5                	mov    %esp,%ebp
  800a9a:	57                   	push   %edi
  800a9b:	56                   	push   %esi
  800a9c:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a9d:	b8 00 00 00 00       	mov    $0x0,%eax
  800aa2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800aa5:	8b 55 08             	mov    0x8(%ebp),%edx
  800aa8:	89 c3                	mov    %eax,%ebx
  800aaa:	89 c7                	mov    %eax,%edi
  800aac:	89 c6                	mov    %eax,%esi
  800aae:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800ab0:	5b                   	pop    %ebx
  800ab1:	5e                   	pop    %esi
  800ab2:	5f                   	pop    %edi
  800ab3:	5d                   	pop    %ebp
  800ab4:	c3                   	ret    

00800ab5 <sys_cgetc>:

int
sys_cgetc(void)
{
  800ab5:	55                   	push   %ebp
  800ab6:	89 e5                	mov    %esp,%ebp
  800ab8:	57                   	push   %edi
  800ab9:	56                   	push   %esi
  800aba:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800abb:	ba 00 00 00 00       	mov    $0x0,%edx
  800ac0:	b8 01 00 00 00       	mov    $0x1,%eax
  800ac5:	89 d1                	mov    %edx,%ecx
  800ac7:	89 d3                	mov    %edx,%ebx
  800ac9:	89 d7                	mov    %edx,%edi
  800acb:	89 d6                	mov    %edx,%esi
  800acd:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800acf:	5b                   	pop    %ebx
  800ad0:	5e                   	pop    %esi
  800ad1:	5f                   	pop    %edi
  800ad2:	5d                   	pop    %ebp
  800ad3:	c3                   	ret    

00800ad4 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ad4:	55                   	push   %ebp
  800ad5:	89 e5                	mov    %esp,%ebp
  800ad7:	57                   	push   %edi
  800ad8:	56                   	push   %esi
  800ad9:	53                   	push   %ebx
  800ada:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800add:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ae2:	b8 03 00 00 00       	mov    $0x3,%eax
  800ae7:	8b 55 08             	mov    0x8(%ebp),%edx
  800aea:	89 cb                	mov    %ecx,%ebx
  800aec:	89 cf                	mov    %ecx,%edi
  800aee:	89 ce                	mov    %ecx,%esi
  800af0:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800af2:	85 c0                	test   %eax,%eax
  800af4:	7e 17                	jle    800b0d <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800af6:	83 ec 0c             	sub    $0xc,%esp
  800af9:	50                   	push   %eax
  800afa:	6a 03                	push   $0x3
  800afc:	68 60 10 80 00       	push   $0x801060
  800b01:	6a 23                	push   $0x23
  800b03:	68 7d 10 80 00       	push   $0x80107d
  800b08:	e8 27 00 00 00       	call   800b34 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b0d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b10:	5b                   	pop    %ebx
  800b11:	5e                   	pop    %esi
  800b12:	5f                   	pop    %edi
  800b13:	5d                   	pop    %ebp
  800b14:	c3                   	ret    

00800b15 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b15:	55                   	push   %ebp
  800b16:	89 e5                	mov    %esp,%ebp
  800b18:	57                   	push   %edi
  800b19:	56                   	push   %esi
  800b1a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b1b:	ba 00 00 00 00       	mov    $0x0,%edx
  800b20:	b8 02 00 00 00       	mov    $0x2,%eax
  800b25:	89 d1                	mov    %edx,%ecx
  800b27:	89 d3                	mov    %edx,%ebx
  800b29:	89 d7                	mov    %edx,%edi
  800b2b:	89 d6                	mov    %edx,%esi
  800b2d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b2f:	5b                   	pop    %ebx
  800b30:	5e                   	pop    %esi
  800b31:	5f                   	pop    %edi
  800b32:	5d                   	pop    %ebp
  800b33:	c3                   	ret    

00800b34 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800b34:	55                   	push   %ebp
  800b35:	89 e5                	mov    %esp,%ebp
  800b37:	56                   	push   %esi
  800b38:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800b39:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800b3c:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800b42:	e8 ce ff ff ff       	call   800b15 <sys_getenvid>
  800b47:	83 ec 0c             	sub    $0xc,%esp
  800b4a:	ff 75 0c             	pushl  0xc(%ebp)
  800b4d:	ff 75 08             	pushl  0x8(%ebp)
  800b50:	56                   	push   %esi
  800b51:	50                   	push   %eax
  800b52:	68 8c 10 80 00       	push   $0x80108c
  800b57:	e8 f0 f5 ff ff       	call   80014c <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800b5c:	83 c4 18             	add    $0x18,%esp
  800b5f:	53                   	push   %ebx
  800b60:	ff 75 10             	pushl  0x10(%ebp)
  800b63:	e8 93 f5 ff ff       	call   8000fb <vcprintf>
	cprintf("\n");
  800b68:	c7 04 24 2c 0e 80 00 	movl   $0x800e2c,(%esp)
  800b6f:	e8 d8 f5 ff ff       	call   80014c <cprintf>
  800b74:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b77:	cc                   	int3   
  800b78:	eb fd                	jmp    800b77 <_panic+0x43>
  800b7a:	66 90                	xchg   %ax,%ax
  800b7c:	66 90                	xchg   %ax,%ax
  800b7e:	66 90                	xchg   %ax,%ax

00800b80 <__udivdi3>:
  800b80:	55                   	push   %ebp
  800b81:	57                   	push   %edi
  800b82:	56                   	push   %esi
  800b83:	53                   	push   %ebx
  800b84:	83 ec 1c             	sub    $0x1c,%esp
  800b87:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b8b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b8f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b93:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b97:	85 f6                	test   %esi,%esi
  800b99:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b9d:	89 ca                	mov    %ecx,%edx
  800b9f:	89 f8                	mov    %edi,%eax
  800ba1:	75 3d                	jne    800be0 <__udivdi3+0x60>
  800ba3:	39 cf                	cmp    %ecx,%edi
  800ba5:	0f 87 c5 00 00 00    	ja     800c70 <__udivdi3+0xf0>
  800bab:	85 ff                	test   %edi,%edi
  800bad:	89 fd                	mov    %edi,%ebp
  800baf:	75 0b                	jne    800bbc <__udivdi3+0x3c>
  800bb1:	b8 01 00 00 00       	mov    $0x1,%eax
  800bb6:	31 d2                	xor    %edx,%edx
  800bb8:	f7 f7                	div    %edi
  800bba:	89 c5                	mov    %eax,%ebp
  800bbc:	89 c8                	mov    %ecx,%eax
  800bbe:	31 d2                	xor    %edx,%edx
  800bc0:	f7 f5                	div    %ebp
  800bc2:	89 c1                	mov    %eax,%ecx
  800bc4:	89 d8                	mov    %ebx,%eax
  800bc6:	89 cf                	mov    %ecx,%edi
  800bc8:	f7 f5                	div    %ebp
  800bca:	89 c3                	mov    %eax,%ebx
  800bcc:	89 d8                	mov    %ebx,%eax
  800bce:	89 fa                	mov    %edi,%edx
  800bd0:	83 c4 1c             	add    $0x1c,%esp
  800bd3:	5b                   	pop    %ebx
  800bd4:	5e                   	pop    %esi
  800bd5:	5f                   	pop    %edi
  800bd6:	5d                   	pop    %ebp
  800bd7:	c3                   	ret    
  800bd8:	90                   	nop
  800bd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800be0:	39 ce                	cmp    %ecx,%esi
  800be2:	77 74                	ja     800c58 <__udivdi3+0xd8>
  800be4:	0f bd fe             	bsr    %esi,%edi
  800be7:	83 f7 1f             	xor    $0x1f,%edi
  800bea:	0f 84 98 00 00 00    	je     800c88 <__udivdi3+0x108>
  800bf0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800bf5:	89 f9                	mov    %edi,%ecx
  800bf7:	89 c5                	mov    %eax,%ebp
  800bf9:	29 fb                	sub    %edi,%ebx
  800bfb:	d3 e6                	shl    %cl,%esi
  800bfd:	89 d9                	mov    %ebx,%ecx
  800bff:	d3 ed                	shr    %cl,%ebp
  800c01:	89 f9                	mov    %edi,%ecx
  800c03:	d3 e0                	shl    %cl,%eax
  800c05:	09 ee                	or     %ebp,%esi
  800c07:	89 d9                	mov    %ebx,%ecx
  800c09:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800c0d:	89 d5                	mov    %edx,%ebp
  800c0f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c13:	d3 ed                	shr    %cl,%ebp
  800c15:	89 f9                	mov    %edi,%ecx
  800c17:	d3 e2                	shl    %cl,%edx
  800c19:	89 d9                	mov    %ebx,%ecx
  800c1b:	d3 e8                	shr    %cl,%eax
  800c1d:	09 c2                	or     %eax,%edx
  800c1f:	89 d0                	mov    %edx,%eax
  800c21:	89 ea                	mov    %ebp,%edx
  800c23:	f7 f6                	div    %esi
  800c25:	89 d5                	mov    %edx,%ebp
  800c27:	89 c3                	mov    %eax,%ebx
  800c29:	f7 64 24 0c          	mull   0xc(%esp)
  800c2d:	39 d5                	cmp    %edx,%ebp
  800c2f:	72 10                	jb     800c41 <__udivdi3+0xc1>
  800c31:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c35:	89 f9                	mov    %edi,%ecx
  800c37:	d3 e6                	shl    %cl,%esi
  800c39:	39 c6                	cmp    %eax,%esi
  800c3b:	73 07                	jae    800c44 <__udivdi3+0xc4>
  800c3d:	39 d5                	cmp    %edx,%ebp
  800c3f:	75 03                	jne    800c44 <__udivdi3+0xc4>
  800c41:	83 eb 01             	sub    $0x1,%ebx
  800c44:	31 ff                	xor    %edi,%edi
  800c46:	89 d8                	mov    %ebx,%eax
  800c48:	89 fa                	mov    %edi,%edx
  800c4a:	83 c4 1c             	add    $0x1c,%esp
  800c4d:	5b                   	pop    %ebx
  800c4e:	5e                   	pop    %esi
  800c4f:	5f                   	pop    %edi
  800c50:	5d                   	pop    %ebp
  800c51:	c3                   	ret    
  800c52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c58:	31 ff                	xor    %edi,%edi
  800c5a:	31 db                	xor    %ebx,%ebx
  800c5c:	89 d8                	mov    %ebx,%eax
  800c5e:	89 fa                	mov    %edi,%edx
  800c60:	83 c4 1c             	add    $0x1c,%esp
  800c63:	5b                   	pop    %ebx
  800c64:	5e                   	pop    %esi
  800c65:	5f                   	pop    %edi
  800c66:	5d                   	pop    %ebp
  800c67:	c3                   	ret    
  800c68:	90                   	nop
  800c69:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c70:	89 d8                	mov    %ebx,%eax
  800c72:	f7 f7                	div    %edi
  800c74:	31 ff                	xor    %edi,%edi
  800c76:	89 c3                	mov    %eax,%ebx
  800c78:	89 d8                	mov    %ebx,%eax
  800c7a:	89 fa                	mov    %edi,%edx
  800c7c:	83 c4 1c             	add    $0x1c,%esp
  800c7f:	5b                   	pop    %ebx
  800c80:	5e                   	pop    %esi
  800c81:	5f                   	pop    %edi
  800c82:	5d                   	pop    %ebp
  800c83:	c3                   	ret    
  800c84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c88:	39 ce                	cmp    %ecx,%esi
  800c8a:	72 0c                	jb     800c98 <__udivdi3+0x118>
  800c8c:	31 db                	xor    %ebx,%ebx
  800c8e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c92:	0f 87 34 ff ff ff    	ja     800bcc <__udivdi3+0x4c>
  800c98:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c9d:	e9 2a ff ff ff       	jmp    800bcc <__udivdi3+0x4c>
  800ca2:	66 90                	xchg   %ax,%ax
  800ca4:	66 90                	xchg   %ax,%ax
  800ca6:	66 90                	xchg   %ax,%ax
  800ca8:	66 90                	xchg   %ax,%ax
  800caa:	66 90                	xchg   %ax,%ax
  800cac:	66 90                	xchg   %ax,%ax
  800cae:	66 90                	xchg   %ax,%ax

00800cb0 <__umoddi3>:
  800cb0:	55                   	push   %ebp
  800cb1:	57                   	push   %edi
  800cb2:	56                   	push   %esi
  800cb3:	53                   	push   %ebx
  800cb4:	83 ec 1c             	sub    $0x1c,%esp
  800cb7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800cbb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800cbf:	8b 74 24 34          	mov    0x34(%esp),%esi
  800cc3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800cc7:	85 d2                	test   %edx,%edx
  800cc9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800ccd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800cd1:	89 f3                	mov    %esi,%ebx
  800cd3:	89 3c 24             	mov    %edi,(%esp)
  800cd6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800cda:	75 1c                	jne    800cf8 <__umoddi3+0x48>
  800cdc:	39 f7                	cmp    %esi,%edi
  800cde:	76 50                	jbe    800d30 <__umoddi3+0x80>
  800ce0:	89 c8                	mov    %ecx,%eax
  800ce2:	89 f2                	mov    %esi,%edx
  800ce4:	f7 f7                	div    %edi
  800ce6:	89 d0                	mov    %edx,%eax
  800ce8:	31 d2                	xor    %edx,%edx
  800cea:	83 c4 1c             	add    $0x1c,%esp
  800ced:	5b                   	pop    %ebx
  800cee:	5e                   	pop    %esi
  800cef:	5f                   	pop    %edi
  800cf0:	5d                   	pop    %ebp
  800cf1:	c3                   	ret    
  800cf2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cf8:	39 f2                	cmp    %esi,%edx
  800cfa:	89 d0                	mov    %edx,%eax
  800cfc:	77 52                	ja     800d50 <__umoddi3+0xa0>
  800cfe:	0f bd ea             	bsr    %edx,%ebp
  800d01:	83 f5 1f             	xor    $0x1f,%ebp
  800d04:	75 5a                	jne    800d60 <__umoddi3+0xb0>
  800d06:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800d0a:	0f 82 e0 00 00 00    	jb     800df0 <__umoddi3+0x140>
  800d10:	39 0c 24             	cmp    %ecx,(%esp)
  800d13:	0f 86 d7 00 00 00    	jbe    800df0 <__umoddi3+0x140>
  800d19:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d1d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d21:	83 c4 1c             	add    $0x1c,%esp
  800d24:	5b                   	pop    %ebx
  800d25:	5e                   	pop    %esi
  800d26:	5f                   	pop    %edi
  800d27:	5d                   	pop    %ebp
  800d28:	c3                   	ret    
  800d29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d30:	85 ff                	test   %edi,%edi
  800d32:	89 fd                	mov    %edi,%ebp
  800d34:	75 0b                	jne    800d41 <__umoddi3+0x91>
  800d36:	b8 01 00 00 00       	mov    $0x1,%eax
  800d3b:	31 d2                	xor    %edx,%edx
  800d3d:	f7 f7                	div    %edi
  800d3f:	89 c5                	mov    %eax,%ebp
  800d41:	89 f0                	mov    %esi,%eax
  800d43:	31 d2                	xor    %edx,%edx
  800d45:	f7 f5                	div    %ebp
  800d47:	89 c8                	mov    %ecx,%eax
  800d49:	f7 f5                	div    %ebp
  800d4b:	89 d0                	mov    %edx,%eax
  800d4d:	eb 99                	jmp    800ce8 <__umoddi3+0x38>
  800d4f:	90                   	nop
  800d50:	89 c8                	mov    %ecx,%eax
  800d52:	89 f2                	mov    %esi,%edx
  800d54:	83 c4 1c             	add    $0x1c,%esp
  800d57:	5b                   	pop    %ebx
  800d58:	5e                   	pop    %esi
  800d59:	5f                   	pop    %edi
  800d5a:	5d                   	pop    %ebp
  800d5b:	c3                   	ret    
  800d5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d60:	8b 34 24             	mov    (%esp),%esi
  800d63:	bf 20 00 00 00       	mov    $0x20,%edi
  800d68:	89 e9                	mov    %ebp,%ecx
  800d6a:	29 ef                	sub    %ebp,%edi
  800d6c:	d3 e0                	shl    %cl,%eax
  800d6e:	89 f9                	mov    %edi,%ecx
  800d70:	89 f2                	mov    %esi,%edx
  800d72:	d3 ea                	shr    %cl,%edx
  800d74:	89 e9                	mov    %ebp,%ecx
  800d76:	09 c2                	or     %eax,%edx
  800d78:	89 d8                	mov    %ebx,%eax
  800d7a:	89 14 24             	mov    %edx,(%esp)
  800d7d:	89 f2                	mov    %esi,%edx
  800d7f:	d3 e2                	shl    %cl,%edx
  800d81:	89 f9                	mov    %edi,%ecx
  800d83:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d87:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d8b:	d3 e8                	shr    %cl,%eax
  800d8d:	89 e9                	mov    %ebp,%ecx
  800d8f:	89 c6                	mov    %eax,%esi
  800d91:	d3 e3                	shl    %cl,%ebx
  800d93:	89 f9                	mov    %edi,%ecx
  800d95:	89 d0                	mov    %edx,%eax
  800d97:	d3 e8                	shr    %cl,%eax
  800d99:	89 e9                	mov    %ebp,%ecx
  800d9b:	09 d8                	or     %ebx,%eax
  800d9d:	89 d3                	mov    %edx,%ebx
  800d9f:	89 f2                	mov    %esi,%edx
  800da1:	f7 34 24             	divl   (%esp)
  800da4:	89 d6                	mov    %edx,%esi
  800da6:	d3 e3                	shl    %cl,%ebx
  800da8:	f7 64 24 04          	mull   0x4(%esp)
  800dac:	39 d6                	cmp    %edx,%esi
  800dae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800db2:	89 d1                	mov    %edx,%ecx
  800db4:	89 c3                	mov    %eax,%ebx
  800db6:	72 08                	jb     800dc0 <__umoddi3+0x110>
  800db8:	75 11                	jne    800dcb <__umoddi3+0x11b>
  800dba:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800dbe:	73 0b                	jae    800dcb <__umoddi3+0x11b>
  800dc0:	2b 44 24 04          	sub    0x4(%esp),%eax
  800dc4:	1b 14 24             	sbb    (%esp),%edx
  800dc7:	89 d1                	mov    %edx,%ecx
  800dc9:	89 c3                	mov    %eax,%ebx
  800dcb:	8b 54 24 08          	mov    0x8(%esp),%edx
  800dcf:	29 da                	sub    %ebx,%edx
  800dd1:	19 ce                	sbb    %ecx,%esi
  800dd3:	89 f9                	mov    %edi,%ecx
  800dd5:	89 f0                	mov    %esi,%eax
  800dd7:	d3 e0                	shl    %cl,%eax
  800dd9:	89 e9                	mov    %ebp,%ecx
  800ddb:	d3 ea                	shr    %cl,%edx
  800ddd:	89 e9                	mov    %ebp,%ecx
  800ddf:	d3 ee                	shr    %cl,%esi
  800de1:	09 d0                	or     %edx,%eax
  800de3:	89 f2                	mov    %esi,%edx
  800de5:	83 c4 1c             	add    $0x1c,%esp
  800de8:	5b                   	pop    %ebx
  800de9:	5e                   	pop    %esi
  800dea:	5f                   	pop    %edi
  800deb:	5d                   	pop    %ebp
  800dec:	c3                   	ret    
  800ded:	8d 76 00             	lea    0x0(%esi),%esi
  800df0:	29 f9                	sub    %edi,%ecx
  800df2:	19 d6                	sbb    %edx,%esi
  800df4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800df8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800dfc:	e9 18 ff ff ff       	jmp    800d19 <__umoddi3+0x69>
