
obj/user/divzero:     file format elf32-i386


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
  80002c:	e8 2f 00 00 00       	call   800060 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

int zero;

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	zero = 0;
  800039:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800040:	00 00 00 
	cprintf("1/0 is %08x!\n", 1/zero);
  800043:	b8 01 00 00 00       	mov    $0x1,%eax
  800048:	b9 00 00 00 00       	mov    $0x0,%ecx
  80004d:	99                   	cltd   
  80004e:	f7 f9                	idiv   %ecx
  800050:	50                   	push   %eax
  800051:	68 20 0e 80 00       	push   $0x800e20
  800056:	e8 f3 00 00 00       	call   80014e <cprintf>
}
  80005b:	83 c4 10             	add    $0x10,%esp
  80005e:	c9                   	leave  
  80005f:	c3                   	ret    

00800060 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800060:	55                   	push   %ebp
  800061:	89 e5                	mov    %esp,%ebp
  800063:	56                   	push   %esi
  800064:	53                   	push   %ebx
  800065:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800068:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  80006b:	e8 a7 0a 00 00       	call   800b17 <sys_getenvid>
  800070:	25 ff 03 00 00       	and    $0x3ff,%eax
  800075:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800078:	c1 e0 05             	shl    $0x5,%eax
  80007b:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800080:	a3 08 20 80 00       	mov    %eax,0x802008

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800085:	85 db                	test   %ebx,%ebx
  800087:	7e 07                	jle    800090 <libmain+0x30>
		binaryname = argv[0];
  800089:	8b 06                	mov    (%esi),%eax
  80008b:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800090:	83 ec 08             	sub    $0x8,%esp
  800093:	56                   	push   %esi
  800094:	53                   	push   %ebx
  800095:	e8 99 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80009a:	e8 0a 00 00 00       	call   8000a9 <exit>
}
  80009f:	83 c4 10             	add    $0x10,%esp
  8000a2:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8000a5:	5b                   	pop    %ebx
  8000a6:	5e                   	pop    %esi
  8000a7:	5d                   	pop    %ebp
  8000a8:	c3                   	ret    

008000a9 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000a9:	55                   	push   %ebp
  8000aa:	89 e5                	mov    %esp,%ebp
  8000ac:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000af:	6a 00                	push   $0x0
  8000b1:	e8 20 0a 00 00       	call   800ad6 <sys_env_destroy>
}
  8000b6:	83 c4 10             	add    $0x10,%esp
  8000b9:	c9                   	leave  
  8000ba:	c3                   	ret    

008000bb <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000bb:	55                   	push   %ebp
  8000bc:	89 e5                	mov    %esp,%ebp
  8000be:	53                   	push   %ebx
  8000bf:	83 ec 04             	sub    $0x4,%esp
  8000c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c5:	8b 13                	mov    (%ebx),%edx
  8000c7:	8d 42 01             	lea    0x1(%edx),%eax
  8000ca:	89 03                	mov    %eax,(%ebx)
  8000cc:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000cf:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000d3:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000d8:	75 1a                	jne    8000f4 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000da:	83 ec 08             	sub    $0x8,%esp
  8000dd:	68 ff 00 00 00       	push   $0xff
  8000e2:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e5:	50                   	push   %eax
  8000e6:	e8 ae 09 00 00       	call   800a99 <sys_cputs>
		b->idx = 0;
  8000eb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000f1:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000f4:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000f8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000fb:	c9                   	leave  
  8000fc:	c3                   	ret    

008000fd <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000fd:	55                   	push   %ebp
  8000fe:	89 e5                	mov    %esp,%ebp
  800100:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800106:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80010d:	00 00 00 
	b.cnt = 0;
  800110:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800117:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80011a:	ff 75 0c             	pushl  0xc(%ebp)
  80011d:	ff 75 08             	pushl  0x8(%ebp)
  800120:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800126:	50                   	push   %eax
  800127:	68 bb 00 80 00       	push   $0x8000bb
  80012c:	e8 1a 01 00 00       	call   80024b <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800131:	83 c4 08             	add    $0x8,%esp
  800134:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80013a:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800140:	50                   	push   %eax
  800141:	e8 53 09 00 00       	call   800a99 <sys_cputs>

	return b.cnt;
}
  800146:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80014c:	c9                   	leave  
  80014d:	c3                   	ret    

0080014e <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80014e:	55                   	push   %ebp
  80014f:	89 e5                	mov    %esp,%ebp
  800151:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800154:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800157:	50                   	push   %eax
  800158:	ff 75 08             	pushl  0x8(%ebp)
  80015b:	e8 9d ff ff ff       	call   8000fd <vcprintf>
	va_end(ap);

	return cnt;
}
  800160:	c9                   	leave  
  800161:	c3                   	ret    

00800162 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800162:	55                   	push   %ebp
  800163:	89 e5                	mov    %esp,%ebp
  800165:	57                   	push   %edi
  800166:	56                   	push   %esi
  800167:	53                   	push   %ebx
  800168:	83 ec 1c             	sub    $0x1c,%esp
  80016b:	89 c7                	mov    %eax,%edi
  80016d:	89 d6                	mov    %edx,%esi
  80016f:	8b 45 08             	mov    0x8(%ebp),%eax
  800172:	8b 55 0c             	mov    0xc(%ebp),%edx
  800175:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800178:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80017b:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80017e:	bb 00 00 00 00       	mov    $0x0,%ebx
  800183:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800186:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800189:	39 d3                	cmp    %edx,%ebx
  80018b:	72 05                	jb     800192 <printnum+0x30>
  80018d:	39 45 10             	cmp    %eax,0x10(%ebp)
  800190:	77 45                	ja     8001d7 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800192:	83 ec 0c             	sub    $0xc,%esp
  800195:	ff 75 18             	pushl  0x18(%ebp)
  800198:	8b 45 14             	mov    0x14(%ebp),%eax
  80019b:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80019e:	53                   	push   %ebx
  80019f:	ff 75 10             	pushl  0x10(%ebp)
  8001a2:	83 ec 08             	sub    $0x8,%esp
  8001a5:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001a8:	ff 75 e0             	pushl  -0x20(%ebp)
  8001ab:	ff 75 dc             	pushl  -0x24(%ebp)
  8001ae:	ff 75 d8             	pushl  -0x28(%ebp)
  8001b1:	e8 ca 09 00 00       	call   800b80 <__udivdi3>
  8001b6:	83 c4 18             	add    $0x18,%esp
  8001b9:	52                   	push   %edx
  8001ba:	50                   	push   %eax
  8001bb:	89 f2                	mov    %esi,%edx
  8001bd:	89 f8                	mov    %edi,%eax
  8001bf:	e8 9e ff ff ff       	call   800162 <printnum>
  8001c4:	83 c4 20             	add    $0x20,%esp
  8001c7:	eb 18                	jmp    8001e1 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001c9:	83 ec 08             	sub    $0x8,%esp
  8001cc:	56                   	push   %esi
  8001cd:	ff 75 18             	pushl  0x18(%ebp)
  8001d0:	ff d7                	call   *%edi
  8001d2:	83 c4 10             	add    $0x10,%esp
  8001d5:	eb 03                	jmp    8001da <printnum+0x78>
  8001d7:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001da:	83 eb 01             	sub    $0x1,%ebx
  8001dd:	85 db                	test   %ebx,%ebx
  8001df:	7f e8                	jg     8001c9 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001e1:	83 ec 08             	sub    $0x8,%esp
  8001e4:	56                   	push   %esi
  8001e5:	83 ec 04             	sub    $0x4,%esp
  8001e8:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001eb:	ff 75 e0             	pushl  -0x20(%ebp)
  8001ee:	ff 75 dc             	pushl  -0x24(%ebp)
  8001f1:	ff 75 d8             	pushl  -0x28(%ebp)
  8001f4:	e8 b7 0a 00 00       	call   800cb0 <__umoddi3>
  8001f9:	83 c4 14             	add    $0x14,%esp
  8001fc:	0f be 80 38 0e 80 00 	movsbl 0x800e38(%eax),%eax
  800203:	50                   	push   %eax
  800204:	ff d7                	call   *%edi
}
  800206:	83 c4 10             	add    $0x10,%esp
  800209:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80020c:	5b                   	pop    %ebx
  80020d:	5e                   	pop    %esi
  80020e:	5f                   	pop    %edi
  80020f:	5d                   	pop    %ebp
  800210:	c3                   	ret    

00800211 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800211:	55                   	push   %ebp
  800212:	89 e5                	mov    %esp,%ebp
  800214:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800217:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80021b:	8b 10                	mov    (%eax),%edx
  80021d:	3b 50 04             	cmp    0x4(%eax),%edx
  800220:	73 0a                	jae    80022c <sprintputch+0x1b>
		*b->buf++ = ch;
  800222:	8d 4a 01             	lea    0x1(%edx),%ecx
  800225:	89 08                	mov    %ecx,(%eax)
  800227:	8b 45 08             	mov    0x8(%ebp),%eax
  80022a:	88 02                	mov    %al,(%edx)
}
  80022c:	5d                   	pop    %ebp
  80022d:	c3                   	ret    

0080022e <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80022e:	55                   	push   %ebp
  80022f:	89 e5                	mov    %esp,%ebp
  800231:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800234:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800237:	50                   	push   %eax
  800238:	ff 75 10             	pushl  0x10(%ebp)
  80023b:	ff 75 0c             	pushl  0xc(%ebp)
  80023e:	ff 75 08             	pushl  0x8(%ebp)
  800241:	e8 05 00 00 00       	call   80024b <vprintfmt>
	va_end(ap);
}
  800246:	83 c4 10             	add    $0x10,%esp
  800249:	c9                   	leave  
  80024a:	c3                   	ret    

0080024b <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80024b:	55                   	push   %ebp
  80024c:	89 e5                	mov    %esp,%ebp
  80024e:	57                   	push   %edi
  80024f:	56                   	push   %esi
  800250:	53                   	push   %ebx
  800251:	83 ec 2c             	sub    $0x2c,%esp
  800254:	8b 75 08             	mov    0x8(%ebp),%esi
  800257:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80025a:	8b 7d 10             	mov    0x10(%ebp),%edi
  80025d:	eb 12                	jmp    800271 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80025f:	85 c0                	test   %eax,%eax
  800261:	0f 84 42 04 00 00    	je     8006a9 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800267:	83 ec 08             	sub    $0x8,%esp
  80026a:	53                   	push   %ebx
  80026b:	50                   	push   %eax
  80026c:	ff d6                	call   *%esi
  80026e:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800271:	83 c7 01             	add    $0x1,%edi
  800274:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800278:	83 f8 25             	cmp    $0x25,%eax
  80027b:	75 e2                	jne    80025f <vprintfmt+0x14>
  80027d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800281:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800288:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80028f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800296:	b9 00 00 00 00       	mov    $0x0,%ecx
  80029b:	eb 07                	jmp    8002a4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80029d:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002a0:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002a4:	8d 47 01             	lea    0x1(%edi),%eax
  8002a7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002aa:	0f b6 07             	movzbl (%edi),%eax
  8002ad:	0f b6 d0             	movzbl %al,%edx
  8002b0:	83 e8 23             	sub    $0x23,%eax
  8002b3:	3c 55                	cmp    $0x55,%al
  8002b5:	0f 87 d3 03 00 00    	ja     80068e <vprintfmt+0x443>
  8002bb:	0f b6 c0             	movzbl %al,%eax
  8002be:	ff 24 85 e0 0e 80 00 	jmp    *0x800ee0(,%eax,4)
  8002c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8002c8:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002cc:	eb d6                	jmp    8002a4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002ce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002d1:	b8 00 00 00 00       	mov    $0x0,%eax
  8002d6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8002d9:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8002dc:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8002e0:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8002e3:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8002e6:	83 f9 09             	cmp    $0x9,%ecx
  8002e9:	77 3f                	ja     80032a <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8002eb:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8002ee:	eb e9                	jmp    8002d9 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8002f0:	8b 45 14             	mov    0x14(%ebp),%eax
  8002f3:	8b 00                	mov    (%eax),%eax
  8002f5:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8002f8:	8b 45 14             	mov    0x14(%ebp),%eax
  8002fb:	8d 40 04             	lea    0x4(%eax),%eax
  8002fe:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800301:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800304:	eb 2a                	jmp    800330 <vprintfmt+0xe5>
  800306:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800309:	85 c0                	test   %eax,%eax
  80030b:	ba 00 00 00 00       	mov    $0x0,%edx
  800310:	0f 49 d0             	cmovns %eax,%edx
  800313:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800316:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800319:	eb 89                	jmp    8002a4 <vprintfmt+0x59>
  80031b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80031e:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800325:	e9 7a ff ff ff       	jmp    8002a4 <vprintfmt+0x59>
  80032a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  80032d:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800330:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800334:	0f 89 6a ff ff ff    	jns    8002a4 <vprintfmt+0x59>
				width = precision, precision = -1;
  80033a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80033d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800340:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800347:	e9 58 ff ff ff       	jmp    8002a4 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80034c:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800352:	e9 4d ff ff ff       	jmp    8002a4 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800357:	8b 45 14             	mov    0x14(%ebp),%eax
  80035a:	8d 78 04             	lea    0x4(%eax),%edi
  80035d:	83 ec 08             	sub    $0x8,%esp
  800360:	53                   	push   %ebx
  800361:	ff 30                	pushl  (%eax)
  800363:	ff d6                	call   *%esi
			break;
  800365:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800368:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80036b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80036e:	e9 fe fe ff ff       	jmp    800271 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800373:	8b 45 14             	mov    0x14(%ebp),%eax
  800376:	8d 78 04             	lea    0x4(%eax),%edi
  800379:	8b 00                	mov    (%eax),%eax
  80037b:	99                   	cltd   
  80037c:	31 d0                	xor    %edx,%eax
  80037e:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800380:	83 f8 07             	cmp    $0x7,%eax
  800383:	7f 0b                	jg     800390 <vprintfmt+0x145>
  800385:	8b 14 85 40 10 80 00 	mov    0x801040(,%eax,4),%edx
  80038c:	85 d2                	test   %edx,%edx
  80038e:	75 1b                	jne    8003ab <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800390:	50                   	push   %eax
  800391:	68 50 0e 80 00       	push   $0x800e50
  800396:	53                   	push   %ebx
  800397:	56                   	push   %esi
  800398:	e8 91 fe ff ff       	call   80022e <printfmt>
  80039d:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003a0:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003a6:	e9 c6 fe ff ff       	jmp    800271 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003ab:	52                   	push   %edx
  8003ac:	68 59 0e 80 00       	push   $0x800e59
  8003b1:	53                   	push   %ebx
  8003b2:	56                   	push   %esi
  8003b3:	e8 76 fe ff ff       	call   80022e <printfmt>
  8003b8:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003bb:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003be:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003c1:	e9 ab fe ff ff       	jmp    800271 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003c6:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c9:	83 c0 04             	add    $0x4,%eax
  8003cc:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8003cf:	8b 45 14             	mov    0x14(%ebp),%eax
  8003d2:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003d4:	85 ff                	test   %edi,%edi
  8003d6:	b8 49 0e 80 00       	mov    $0x800e49,%eax
  8003db:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003de:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003e2:	0f 8e 94 00 00 00    	jle    80047c <vprintfmt+0x231>
  8003e8:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8003ec:	0f 84 98 00 00 00    	je     80048a <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8003f2:	83 ec 08             	sub    $0x8,%esp
  8003f5:	ff 75 d0             	pushl  -0x30(%ebp)
  8003f8:	57                   	push   %edi
  8003f9:	e8 33 03 00 00       	call   800731 <strnlen>
  8003fe:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800401:	29 c1                	sub    %eax,%ecx
  800403:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  800406:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800409:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80040d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800410:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800413:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800415:	eb 0f                	jmp    800426 <vprintfmt+0x1db>
					putch(padc, putdat);
  800417:	83 ec 08             	sub    $0x8,%esp
  80041a:	53                   	push   %ebx
  80041b:	ff 75 e0             	pushl  -0x20(%ebp)
  80041e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800420:	83 ef 01             	sub    $0x1,%edi
  800423:	83 c4 10             	add    $0x10,%esp
  800426:	85 ff                	test   %edi,%edi
  800428:	7f ed                	jg     800417 <vprintfmt+0x1cc>
  80042a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80042d:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800430:	85 c9                	test   %ecx,%ecx
  800432:	b8 00 00 00 00       	mov    $0x0,%eax
  800437:	0f 49 c1             	cmovns %ecx,%eax
  80043a:	29 c1                	sub    %eax,%ecx
  80043c:	89 75 08             	mov    %esi,0x8(%ebp)
  80043f:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800442:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800445:	89 cb                	mov    %ecx,%ebx
  800447:	eb 4d                	jmp    800496 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800449:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80044d:	74 1b                	je     80046a <vprintfmt+0x21f>
  80044f:	0f be c0             	movsbl %al,%eax
  800452:	83 e8 20             	sub    $0x20,%eax
  800455:	83 f8 5e             	cmp    $0x5e,%eax
  800458:	76 10                	jbe    80046a <vprintfmt+0x21f>
					putch('?', putdat);
  80045a:	83 ec 08             	sub    $0x8,%esp
  80045d:	ff 75 0c             	pushl  0xc(%ebp)
  800460:	6a 3f                	push   $0x3f
  800462:	ff 55 08             	call   *0x8(%ebp)
  800465:	83 c4 10             	add    $0x10,%esp
  800468:	eb 0d                	jmp    800477 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  80046a:	83 ec 08             	sub    $0x8,%esp
  80046d:	ff 75 0c             	pushl  0xc(%ebp)
  800470:	52                   	push   %edx
  800471:	ff 55 08             	call   *0x8(%ebp)
  800474:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800477:	83 eb 01             	sub    $0x1,%ebx
  80047a:	eb 1a                	jmp    800496 <vprintfmt+0x24b>
  80047c:	89 75 08             	mov    %esi,0x8(%ebp)
  80047f:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800482:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800485:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800488:	eb 0c                	jmp    800496 <vprintfmt+0x24b>
  80048a:	89 75 08             	mov    %esi,0x8(%ebp)
  80048d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800490:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800493:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800496:	83 c7 01             	add    $0x1,%edi
  800499:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80049d:	0f be d0             	movsbl %al,%edx
  8004a0:	85 d2                	test   %edx,%edx
  8004a2:	74 23                	je     8004c7 <vprintfmt+0x27c>
  8004a4:	85 f6                	test   %esi,%esi
  8004a6:	78 a1                	js     800449 <vprintfmt+0x1fe>
  8004a8:	83 ee 01             	sub    $0x1,%esi
  8004ab:	79 9c                	jns    800449 <vprintfmt+0x1fe>
  8004ad:	89 df                	mov    %ebx,%edi
  8004af:	8b 75 08             	mov    0x8(%ebp),%esi
  8004b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004b5:	eb 18                	jmp    8004cf <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004b7:	83 ec 08             	sub    $0x8,%esp
  8004ba:	53                   	push   %ebx
  8004bb:	6a 20                	push   $0x20
  8004bd:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004bf:	83 ef 01             	sub    $0x1,%edi
  8004c2:	83 c4 10             	add    $0x10,%esp
  8004c5:	eb 08                	jmp    8004cf <vprintfmt+0x284>
  8004c7:	89 df                	mov    %ebx,%edi
  8004c9:	8b 75 08             	mov    0x8(%ebp),%esi
  8004cc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004cf:	85 ff                	test   %edi,%edi
  8004d1:	7f e4                	jg     8004b7 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004d3:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8004d6:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004dc:	e9 90 fd ff ff       	jmp    800271 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004e1:	83 f9 01             	cmp    $0x1,%ecx
  8004e4:	7e 19                	jle    8004ff <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8004e6:	8b 45 14             	mov    0x14(%ebp),%eax
  8004e9:	8b 50 04             	mov    0x4(%eax),%edx
  8004ec:	8b 00                	mov    (%eax),%eax
  8004ee:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004f1:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f7:	8d 40 08             	lea    0x8(%eax),%eax
  8004fa:	89 45 14             	mov    %eax,0x14(%ebp)
  8004fd:	eb 38                	jmp    800537 <vprintfmt+0x2ec>
	else if (lflag)
  8004ff:	85 c9                	test   %ecx,%ecx
  800501:	74 1b                	je     80051e <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  800503:	8b 45 14             	mov    0x14(%ebp),%eax
  800506:	8b 00                	mov    (%eax),%eax
  800508:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80050b:	89 c1                	mov    %eax,%ecx
  80050d:	c1 f9 1f             	sar    $0x1f,%ecx
  800510:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800513:	8b 45 14             	mov    0x14(%ebp),%eax
  800516:	8d 40 04             	lea    0x4(%eax),%eax
  800519:	89 45 14             	mov    %eax,0x14(%ebp)
  80051c:	eb 19                	jmp    800537 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  80051e:	8b 45 14             	mov    0x14(%ebp),%eax
  800521:	8b 00                	mov    (%eax),%eax
  800523:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800526:	89 c1                	mov    %eax,%ecx
  800528:	c1 f9 1f             	sar    $0x1f,%ecx
  80052b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80052e:	8b 45 14             	mov    0x14(%ebp),%eax
  800531:	8d 40 04             	lea    0x4(%eax),%eax
  800534:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800537:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80053a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80053d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800542:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800546:	0f 89 0e 01 00 00    	jns    80065a <vprintfmt+0x40f>
				putch('-', putdat);
  80054c:	83 ec 08             	sub    $0x8,%esp
  80054f:	53                   	push   %ebx
  800550:	6a 2d                	push   $0x2d
  800552:	ff d6                	call   *%esi
				num = -(long long) num;
  800554:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800557:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80055a:	f7 da                	neg    %edx
  80055c:	83 d1 00             	adc    $0x0,%ecx
  80055f:	f7 d9                	neg    %ecx
  800561:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800564:	b8 0a 00 00 00       	mov    $0xa,%eax
  800569:	e9 ec 00 00 00       	jmp    80065a <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80056e:	83 f9 01             	cmp    $0x1,%ecx
  800571:	7e 18                	jle    80058b <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800573:	8b 45 14             	mov    0x14(%ebp),%eax
  800576:	8b 10                	mov    (%eax),%edx
  800578:	8b 48 04             	mov    0x4(%eax),%ecx
  80057b:	8d 40 08             	lea    0x8(%eax),%eax
  80057e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800581:	b8 0a 00 00 00       	mov    $0xa,%eax
  800586:	e9 cf 00 00 00       	jmp    80065a <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80058b:	85 c9                	test   %ecx,%ecx
  80058d:	74 1a                	je     8005a9 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80058f:	8b 45 14             	mov    0x14(%ebp),%eax
  800592:	8b 10                	mov    (%eax),%edx
  800594:	b9 00 00 00 00       	mov    $0x0,%ecx
  800599:	8d 40 04             	lea    0x4(%eax),%eax
  80059c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80059f:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005a4:	e9 b1 00 00 00       	jmp    80065a <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8005a9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ac:	8b 10                	mov    (%eax),%edx
  8005ae:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005b3:	8d 40 04             	lea    0x4(%eax),%eax
  8005b6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005b9:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005be:	e9 97 00 00 00       	jmp    80065a <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  8005c3:	83 ec 08             	sub    $0x8,%esp
  8005c6:	53                   	push   %ebx
  8005c7:	6a 58                	push   $0x58
  8005c9:	ff d6                	call   *%esi
			putch('X', putdat);
  8005cb:	83 c4 08             	add    $0x8,%esp
  8005ce:	53                   	push   %ebx
  8005cf:	6a 58                	push   $0x58
  8005d1:	ff d6                	call   *%esi
			putch('X', putdat);
  8005d3:	83 c4 08             	add    $0x8,%esp
  8005d6:	53                   	push   %ebx
  8005d7:	6a 58                	push   $0x58
  8005d9:	ff d6                	call   *%esi
			break;
  8005db:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005de:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8005e1:	e9 8b fc ff ff       	jmp    800271 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8005e6:	83 ec 08             	sub    $0x8,%esp
  8005e9:	53                   	push   %ebx
  8005ea:	6a 30                	push   $0x30
  8005ec:	ff d6                	call   *%esi
			putch('x', putdat);
  8005ee:	83 c4 08             	add    $0x8,%esp
  8005f1:	53                   	push   %ebx
  8005f2:	6a 78                	push   $0x78
  8005f4:	ff d6                	call   *%esi
			num = (unsigned long long)
  8005f6:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f9:	8b 10                	mov    (%eax),%edx
  8005fb:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800600:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800603:	8d 40 04             	lea    0x4(%eax),%eax
  800606:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  800609:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  80060e:	eb 4a                	jmp    80065a <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800610:	83 f9 01             	cmp    $0x1,%ecx
  800613:	7e 15                	jle    80062a <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  800615:	8b 45 14             	mov    0x14(%ebp),%eax
  800618:	8b 10                	mov    (%eax),%edx
  80061a:	8b 48 04             	mov    0x4(%eax),%ecx
  80061d:	8d 40 08             	lea    0x8(%eax),%eax
  800620:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800623:	b8 10 00 00 00       	mov    $0x10,%eax
  800628:	eb 30                	jmp    80065a <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80062a:	85 c9                	test   %ecx,%ecx
  80062c:	74 17                	je     800645 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  80062e:	8b 45 14             	mov    0x14(%ebp),%eax
  800631:	8b 10                	mov    (%eax),%edx
  800633:	b9 00 00 00 00       	mov    $0x0,%ecx
  800638:	8d 40 04             	lea    0x4(%eax),%eax
  80063b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80063e:	b8 10 00 00 00       	mov    $0x10,%eax
  800643:	eb 15                	jmp    80065a <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800645:	8b 45 14             	mov    0x14(%ebp),%eax
  800648:	8b 10                	mov    (%eax),%edx
  80064a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80064f:	8d 40 04             	lea    0x4(%eax),%eax
  800652:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800655:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  80065a:	83 ec 0c             	sub    $0xc,%esp
  80065d:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800661:	57                   	push   %edi
  800662:	ff 75 e0             	pushl  -0x20(%ebp)
  800665:	50                   	push   %eax
  800666:	51                   	push   %ecx
  800667:	52                   	push   %edx
  800668:	89 da                	mov    %ebx,%edx
  80066a:	89 f0                	mov    %esi,%eax
  80066c:	e8 f1 fa ff ff       	call   800162 <printnum>
			break;
  800671:	83 c4 20             	add    $0x20,%esp
  800674:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800677:	e9 f5 fb ff ff       	jmp    800271 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80067c:	83 ec 08             	sub    $0x8,%esp
  80067f:	53                   	push   %ebx
  800680:	52                   	push   %edx
  800681:	ff d6                	call   *%esi
			break;
  800683:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800686:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800689:	e9 e3 fb ff ff       	jmp    800271 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80068e:	83 ec 08             	sub    $0x8,%esp
  800691:	53                   	push   %ebx
  800692:	6a 25                	push   $0x25
  800694:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800696:	83 c4 10             	add    $0x10,%esp
  800699:	eb 03                	jmp    80069e <vprintfmt+0x453>
  80069b:	83 ef 01             	sub    $0x1,%edi
  80069e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006a2:	75 f7                	jne    80069b <vprintfmt+0x450>
  8006a4:	e9 c8 fb ff ff       	jmp    800271 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006a9:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006ac:	5b                   	pop    %ebx
  8006ad:	5e                   	pop    %esi
  8006ae:	5f                   	pop    %edi
  8006af:	5d                   	pop    %ebp
  8006b0:	c3                   	ret    

008006b1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006b1:	55                   	push   %ebp
  8006b2:	89 e5                	mov    %esp,%ebp
  8006b4:	83 ec 18             	sub    $0x18,%esp
  8006b7:	8b 45 08             	mov    0x8(%ebp),%eax
  8006ba:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006bd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006c0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006c4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006ce:	85 c0                	test   %eax,%eax
  8006d0:	74 26                	je     8006f8 <vsnprintf+0x47>
  8006d2:	85 d2                	test   %edx,%edx
  8006d4:	7e 22                	jle    8006f8 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006d6:	ff 75 14             	pushl  0x14(%ebp)
  8006d9:	ff 75 10             	pushl  0x10(%ebp)
  8006dc:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006df:	50                   	push   %eax
  8006e0:	68 11 02 80 00       	push   $0x800211
  8006e5:	e8 61 fb ff ff       	call   80024b <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006ea:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006ed:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006f3:	83 c4 10             	add    $0x10,%esp
  8006f6:	eb 05                	jmp    8006fd <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006f8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006fd:	c9                   	leave  
  8006fe:	c3                   	ret    

008006ff <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006ff:	55                   	push   %ebp
  800700:	89 e5                	mov    %esp,%ebp
  800702:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800705:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800708:	50                   	push   %eax
  800709:	ff 75 10             	pushl  0x10(%ebp)
  80070c:	ff 75 0c             	pushl  0xc(%ebp)
  80070f:	ff 75 08             	pushl  0x8(%ebp)
  800712:	e8 9a ff ff ff       	call   8006b1 <vsnprintf>
	va_end(ap);

	return rc;
}
  800717:	c9                   	leave  
  800718:	c3                   	ret    

00800719 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800719:	55                   	push   %ebp
  80071a:	89 e5                	mov    %esp,%ebp
  80071c:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80071f:	b8 00 00 00 00       	mov    $0x0,%eax
  800724:	eb 03                	jmp    800729 <strlen+0x10>
		n++;
  800726:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800729:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80072d:	75 f7                	jne    800726 <strlen+0xd>
		n++;
	return n;
}
  80072f:	5d                   	pop    %ebp
  800730:	c3                   	ret    

00800731 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800731:	55                   	push   %ebp
  800732:	89 e5                	mov    %esp,%ebp
  800734:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800737:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80073a:	ba 00 00 00 00       	mov    $0x0,%edx
  80073f:	eb 03                	jmp    800744 <strnlen+0x13>
		n++;
  800741:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800744:	39 c2                	cmp    %eax,%edx
  800746:	74 08                	je     800750 <strnlen+0x1f>
  800748:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80074c:	75 f3                	jne    800741 <strnlen+0x10>
  80074e:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800750:	5d                   	pop    %ebp
  800751:	c3                   	ret    

00800752 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800752:	55                   	push   %ebp
  800753:	89 e5                	mov    %esp,%ebp
  800755:	53                   	push   %ebx
  800756:	8b 45 08             	mov    0x8(%ebp),%eax
  800759:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80075c:	89 c2                	mov    %eax,%edx
  80075e:	83 c2 01             	add    $0x1,%edx
  800761:	83 c1 01             	add    $0x1,%ecx
  800764:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800768:	88 5a ff             	mov    %bl,-0x1(%edx)
  80076b:	84 db                	test   %bl,%bl
  80076d:	75 ef                	jne    80075e <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80076f:	5b                   	pop    %ebx
  800770:	5d                   	pop    %ebp
  800771:	c3                   	ret    

00800772 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800772:	55                   	push   %ebp
  800773:	89 e5                	mov    %esp,%ebp
  800775:	53                   	push   %ebx
  800776:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800779:	53                   	push   %ebx
  80077a:	e8 9a ff ff ff       	call   800719 <strlen>
  80077f:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800782:	ff 75 0c             	pushl  0xc(%ebp)
  800785:	01 d8                	add    %ebx,%eax
  800787:	50                   	push   %eax
  800788:	e8 c5 ff ff ff       	call   800752 <strcpy>
	return dst;
}
  80078d:	89 d8                	mov    %ebx,%eax
  80078f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800792:	c9                   	leave  
  800793:	c3                   	ret    

00800794 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800794:	55                   	push   %ebp
  800795:	89 e5                	mov    %esp,%ebp
  800797:	56                   	push   %esi
  800798:	53                   	push   %ebx
  800799:	8b 75 08             	mov    0x8(%ebp),%esi
  80079c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80079f:	89 f3                	mov    %esi,%ebx
  8007a1:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007a4:	89 f2                	mov    %esi,%edx
  8007a6:	eb 0f                	jmp    8007b7 <strncpy+0x23>
		*dst++ = *src;
  8007a8:	83 c2 01             	add    $0x1,%edx
  8007ab:	0f b6 01             	movzbl (%ecx),%eax
  8007ae:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007b1:	80 39 01             	cmpb   $0x1,(%ecx)
  8007b4:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007b7:	39 da                	cmp    %ebx,%edx
  8007b9:	75 ed                	jne    8007a8 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007bb:	89 f0                	mov    %esi,%eax
  8007bd:	5b                   	pop    %ebx
  8007be:	5e                   	pop    %esi
  8007bf:	5d                   	pop    %ebp
  8007c0:	c3                   	ret    

008007c1 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007c1:	55                   	push   %ebp
  8007c2:	89 e5                	mov    %esp,%ebp
  8007c4:	56                   	push   %esi
  8007c5:	53                   	push   %ebx
  8007c6:	8b 75 08             	mov    0x8(%ebp),%esi
  8007c9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007cc:	8b 55 10             	mov    0x10(%ebp),%edx
  8007cf:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007d1:	85 d2                	test   %edx,%edx
  8007d3:	74 21                	je     8007f6 <strlcpy+0x35>
  8007d5:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8007d9:	89 f2                	mov    %esi,%edx
  8007db:	eb 09                	jmp    8007e6 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007dd:	83 c2 01             	add    $0x1,%edx
  8007e0:	83 c1 01             	add    $0x1,%ecx
  8007e3:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007e6:	39 c2                	cmp    %eax,%edx
  8007e8:	74 09                	je     8007f3 <strlcpy+0x32>
  8007ea:	0f b6 19             	movzbl (%ecx),%ebx
  8007ed:	84 db                	test   %bl,%bl
  8007ef:	75 ec                	jne    8007dd <strlcpy+0x1c>
  8007f1:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8007f3:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8007f6:	29 f0                	sub    %esi,%eax
}
  8007f8:	5b                   	pop    %ebx
  8007f9:	5e                   	pop    %esi
  8007fa:	5d                   	pop    %ebp
  8007fb:	c3                   	ret    

008007fc <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8007fc:	55                   	push   %ebp
  8007fd:	89 e5                	mov    %esp,%ebp
  8007ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800802:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800805:	eb 06                	jmp    80080d <strcmp+0x11>
		p++, q++;
  800807:	83 c1 01             	add    $0x1,%ecx
  80080a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80080d:	0f b6 01             	movzbl (%ecx),%eax
  800810:	84 c0                	test   %al,%al
  800812:	74 04                	je     800818 <strcmp+0x1c>
  800814:	3a 02                	cmp    (%edx),%al
  800816:	74 ef                	je     800807 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800818:	0f b6 c0             	movzbl %al,%eax
  80081b:	0f b6 12             	movzbl (%edx),%edx
  80081e:	29 d0                	sub    %edx,%eax
}
  800820:	5d                   	pop    %ebp
  800821:	c3                   	ret    

00800822 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800822:	55                   	push   %ebp
  800823:	89 e5                	mov    %esp,%ebp
  800825:	53                   	push   %ebx
  800826:	8b 45 08             	mov    0x8(%ebp),%eax
  800829:	8b 55 0c             	mov    0xc(%ebp),%edx
  80082c:	89 c3                	mov    %eax,%ebx
  80082e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800831:	eb 06                	jmp    800839 <strncmp+0x17>
		n--, p++, q++;
  800833:	83 c0 01             	add    $0x1,%eax
  800836:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800839:	39 d8                	cmp    %ebx,%eax
  80083b:	74 15                	je     800852 <strncmp+0x30>
  80083d:	0f b6 08             	movzbl (%eax),%ecx
  800840:	84 c9                	test   %cl,%cl
  800842:	74 04                	je     800848 <strncmp+0x26>
  800844:	3a 0a                	cmp    (%edx),%cl
  800846:	74 eb                	je     800833 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800848:	0f b6 00             	movzbl (%eax),%eax
  80084b:	0f b6 12             	movzbl (%edx),%edx
  80084e:	29 d0                	sub    %edx,%eax
  800850:	eb 05                	jmp    800857 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800852:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800857:	5b                   	pop    %ebx
  800858:	5d                   	pop    %ebp
  800859:	c3                   	ret    

0080085a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80085a:	55                   	push   %ebp
  80085b:	89 e5                	mov    %esp,%ebp
  80085d:	8b 45 08             	mov    0x8(%ebp),%eax
  800860:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800864:	eb 07                	jmp    80086d <strchr+0x13>
		if (*s == c)
  800866:	38 ca                	cmp    %cl,%dl
  800868:	74 0f                	je     800879 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80086a:	83 c0 01             	add    $0x1,%eax
  80086d:	0f b6 10             	movzbl (%eax),%edx
  800870:	84 d2                	test   %dl,%dl
  800872:	75 f2                	jne    800866 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800874:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800879:	5d                   	pop    %ebp
  80087a:	c3                   	ret    

0080087b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80087b:	55                   	push   %ebp
  80087c:	89 e5                	mov    %esp,%ebp
  80087e:	8b 45 08             	mov    0x8(%ebp),%eax
  800881:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800885:	eb 03                	jmp    80088a <strfind+0xf>
  800887:	83 c0 01             	add    $0x1,%eax
  80088a:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  80088d:	38 ca                	cmp    %cl,%dl
  80088f:	74 04                	je     800895 <strfind+0x1a>
  800891:	84 d2                	test   %dl,%dl
  800893:	75 f2                	jne    800887 <strfind+0xc>
			break;
	return (char *) s;
}
  800895:	5d                   	pop    %ebp
  800896:	c3                   	ret    

00800897 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800897:	55                   	push   %ebp
  800898:	89 e5                	mov    %esp,%ebp
  80089a:	57                   	push   %edi
  80089b:	56                   	push   %esi
  80089c:	53                   	push   %ebx
  80089d:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008a0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008a3:	85 c9                	test   %ecx,%ecx
  8008a5:	74 36                	je     8008dd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008a7:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008ad:	75 28                	jne    8008d7 <memset+0x40>
  8008af:	f6 c1 03             	test   $0x3,%cl
  8008b2:	75 23                	jne    8008d7 <memset+0x40>
		c &= 0xFF;
  8008b4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008b8:	89 d3                	mov    %edx,%ebx
  8008ba:	c1 e3 08             	shl    $0x8,%ebx
  8008bd:	89 d6                	mov    %edx,%esi
  8008bf:	c1 e6 18             	shl    $0x18,%esi
  8008c2:	89 d0                	mov    %edx,%eax
  8008c4:	c1 e0 10             	shl    $0x10,%eax
  8008c7:	09 f0                	or     %esi,%eax
  8008c9:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008cb:	89 d8                	mov    %ebx,%eax
  8008cd:	09 d0                	or     %edx,%eax
  8008cf:	c1 e9 02             	shr    $0x2,%ecx
  8008d2:	fc                   	cld    
  8008d3:	f3 ab                	rep stos %eax,%es:(%edi)
  8008d5:	eb 06                	jmp    8008dd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008d7:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008da:	fc                   	cld    
  8008db:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008dd:	89 f8                	mov    %edi,%eax
  8008df:	5b                   	pop    %ebx
  8008e0:	5e                   	pop    %esi
  8008e1:	5f                   	pop    %edi
  8008e2:	5d                   	pop    %ebp
  8008e3:	c3                   	ret    

008008e4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008e4:	55                   	push   %ebp
  8008e5:	89 e5                	mov    %esp,%ebp
  8008e7:	57                   	push   %edi
  8008e8:	56                   	push   %esi
  8008e9:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ec:	8b 75 0c             	mov    0xc(%ebp),%esi
  8008ef:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8008f2:	39 c6                	cmp    %eax,%esi
  8008f4:	73 35                	jae    80092b <memmove+0x47>
  8008f6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8008f9:	39 d0                	cmp    %edx,%eax
  8008fb:	73 2e                	jae    80092b <memmove+0x47>
		s += n;
		d += n;
  8008fd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800900:	89 d6                	mov    %edx,%esi
  800902:	09 fe                	or     %edi,%esi
  800904:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80090a:	75 13                	jne    80091f <memmove+0x3b>
  80090c:	f6 c1 03             	test   $0x3,%cl
  80090f:	75 0e                	jne    80091f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800911:	83 ef 04             	sub    $0x4,%edi
  800914:	8d 72 fc             	lea    -0x4(%edx),%esi
  800917:	c1 e9 02             	shr    $0x2,%ecx
  80091a:	fd                   	std    
  80091b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80091d:	eb 09                	jmp    800928 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80091f:	83 ef 01             	sub    $0x1,%edi
  800922:	8d 72 ff             	lea    -0x1(%edx),%esi
  800925:	fd                   	std    
  800926:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800928:	fc                   	cld    
  800929:	eb 1d                	jmp    800948 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80092b:	89 f2                	mov    %esi,%edx
  80092d:	09 c2                	or     %eax,%edx
  80092f:	f6 c2 03             	test   $0x3,%dl
  800932:	75 0f                	jne    800943 <memmove+0x5f>
  800934:	f6 c1 03             	test   $0x3,%cl
  800937:	75 0a                	jne    800943 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800939:	c1 e9 02             	shr    $0x2,%ecx
  80093c:	89 c7                	mov    %eax,%edi
  80093e:	fc                   	cld    
  80093f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800941:	eb 05                	jmp    800948 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800943:	89 c7                	mov    %eax,%edi
  800945:	fc                   	cld    
  800946:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800948:	5e                   	pop    %esi
  800949:	5f                   	pop    %edi
  80094a:	5d                   	pop    %ebp
  80094b:	c3                   	ret    

0080094c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80094c:	55                   	push   %ebp
  80094d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80094f:	ff 75 10             	pushl  0x10(%ebp)
  800952:	ff 75 0c             	pushl  0xc(%ebp)
  800955:	ff 75 08             	pushl  0x8(%ebp)
  800958:	e8 87 ff ff ff       	call   8008e4 <memmove>
}
  80095d:	c9                   	leave  
  80095e:	c3                   	ret    

0080095f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80095f:	55                   	push   %ebp
  800960:	89 e5                	mov    %esp,%ebp
  800962:	56                   	push   %esi
  800963:	53                   	push   %ebx
  800964:	8b 45 08             	mov    0x8(%ebp),%eax
  800967:	8b 55 0c             	mov    0xc(%ebp),%edx
  80096a:	89 c6                	mov    %eax,%esi
  80096c:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80096f:	eb 1a                	jmp    80098b <memcmp+0x2c>
		if (*s1 != *s2)
  800971:	0f b6 08             	movzbl (%eax),%ecx
  800974:	0f b6 1a             	movzbl (%edx),%ebx
  800977:	38 d9                	cmp    %bl,%cl
  800979:	74 0a                	je     800985 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  80097b:	0f b6 c1             	movzbl %cl,%eax
  80097e:	0f b6 db             	movzbl %bl,%ebx
  800981:	29 d8                	sub    %ebx,%eax
  800983:	eb 0f                	jmp    800994 <memcmp+0x35>
		s1++, s2++;
  800985:	83 c0 01             	add    $0x1,%eax
  800988:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80098b:	39 f0                	cmp    %esi,%eax
  80098d:	75 e2                	jne    800971 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  80098f:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800994:	5b                   	pop    %ebx
  800995:	5e                   	pop    %esi
  800996:	5d                   	pop    %ebp
  800997:	c3                   	ret    

00800998 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800998:	55                   	push   %ebp
  800999:	89 e5                	mov    %esp,%ebp
  80099b:	53                   	push   %ebx
  80099c:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  80099f:	89 c1                	mov    %eax,%ecx
  8009a1:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009a4:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009a8:	eb 0a                	jmp    8009b4 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009aa:	0f b6 10             	movzbl (%eax),%edx
  8009ad:	39 da                	cmp    %ebx,%edx
  8009af:	74 07                	je     8009b8 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009b1:	83 c0 01             	add    $0x1,%eax
  8009b4:	39 c8                	cmp    %ecx,%eax
  8009b6:	72 f2                	jb     8009aa <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009b8:	5b                   	pop    %ebx
  8009b9:	5d                   	pop    %ebp
  8009ba:	c3                   	ret    

008009bb <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009bb:	55                   	push   %ebp
  8009bc:	89 e5                	mov    %esp,%ebp
  8009be:	57                   	push   %edi
  8009bf:	56                   	push   %esi
  8009c0:	53                   	push   %ebx
  8009c1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009c4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009c7:	eb 03                	jmp    8009cc <strtol+0x11>
		s++;
  8009c9:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009cc:	0f b6 01             	movzbl (%ecx),%eax
  8009cf:	3c 20                	cmp    $0x20,%al
  8009d1:	74 f6                	je     8009c9 <strtol+0xe>
  8009d3:	3c 09                	cmp    $0x9,%al
  8009d5:	74 f2                	je     8009c9 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009d7:	3c 2b                	cmp    $0x2b,%al
  8009d9:	75 0a                	jne    8009e5 <strtol+0x2a>
		s++;
  8009db:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009de:	bf 00 00 00 00       	mov    $0x0,%edi
  8009e3:	eb 11                	jmp    8009f6 <strtol+0x3b>
  8009e5:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  8009ea:	3c 2d                	cmp    $0x2d,%al
  8009ec:	75 08                	jne    8009f6 <strtol+0x3b>
		s++, neg = 1;
  8009ee:	83 c1 01             	add    $0x1,%ecx
  8009f1:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  8009f6:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  8009fc:	75 15                	jne    800a13 <strtol+0x58>
  8009fe:	80 39 30             	cmpb   $0x30,(%ecx)
  800a01:	75 10                	jne    800a13 <strtol+0x58>
  800a03:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a07:	75 7c                	jne    800a85 <strtol+0xca>
		s += 2, base = 16;
  800a09:	83 c1 02             	add    $0x2,%ecx
  800a0c:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a11:	eb 16                	jmp    800a29 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a13:	85 db                	test   %ebx,%ebx
  800a15:	75 12                	jne    800a29 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a17:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a1c:	80 39 30             	cmpb   $0x30,(%ecx)
  800a1f:	75 08                	jne    800a29 <strtol+0x6e>
		s++, base = 8;
  800a21:	83 c1 01             	add    $0x1,%ecx
  800a24:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a29:	b8 00 00 00 00       	mov    $0x0,%eax
  800a2e:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a31:	0f b6 11             	movzbl (%ecx),%edx
  800a34:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a37:	89 f3                	mov    %esi,%ebx
  800a39:	80 fb 09             	cmp    $0x9,%bl
  800a3c:	77 08                	ja     800a46 <strtol+0x8b>
			dig = *s - '0';
  800a3e:	0f be d2             	movsbl %dl,%edx
  800a41:	83 ea 30             	sub    $0x30,%edx
  800a44:	eb 22                	jmp    800a68 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a46:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a49:	89 f3                	mov    %esi,%ebx
  800a4b:	80 fb 19             	cmp    $0x19,%bl
  800a4e:	77 08                	ja     800a58 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a50:	0f be d2             	movsbl %dl,%edx
  800a53:	83 ea 57             	sub    $0x57,%edx
  800a56:	eb 10                	jmp    800a68 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a58:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a5b:	89 f3                	mov    %esi,%ebx
  800a5d:	80 fb 19             	cmp    $0x19,%bl
  800a60:	77 16                	ja     800a78 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a62:	0f be d2             	movsbl %dl,%edx
  800a65:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a68:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a6b:	7d 0b                	jge    800a78 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a6d:	83 c1 01             	add    $0x1,%ecx
  800a70:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a74:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a76:	eb b9                	jmp    800a31 <strtol+0x76>

	if (endptr)
  800a78:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a7c:	74 0d                	je     800a8b <strtol+0xd0>
		*endptr = (char *) s;
  800a7e:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a81:	89 0e                	mov    %ecx,(%esi)
  800a83:	eb 06                	jmp    800a8b <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a85:	85 db                	test   %ebx,%ebx
  800a87:	74 98                	je     800a21 <strtol+0x66>
  800a89:	eb 9e                	jmp    800a29 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a8b:	89 c2                	mov    %eax,%edx
  800a8d:	f7 da                	neg    %edx
  800a8f:	85 ff                	test   %edi,%edi
  800a91:	0f 45 c2             	cmovne %edx,%eax
}
  800a94:	5b                   	pop    %ebx
  800a95:	5e                   	pop    %esi
  800a96:	5f                   	pop    %edi
  800a97:	5d                   	pop    %ebp
  800a98:	c3                   	ret    

00800a99 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a99:	55                   	push   %ebp
  800a9a:	89 e5                	mov    %esp,%ebp
  800a9c:	57                   	push   %edi
  800a9d:	56                   	push   %esi
  800a9e:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a9f:	b8 00 00 00 00       	mov    $0x0,%eax
  800aa4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800aa7:	8b 55 08             	mov    0x8(%ebp),%edx
  800aaa:	89 c3                	mov    %eax,%ebx
  800aac:	89 c7                	mov    %eax,%edi
  800aae:	89 c6                	mov    %eax,%esi
  800ab0:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800ab2:	5b                   	pop    %ebx
  800ab3:	5e                   	pop    %esi
  800ab4:	5f                   	pop    %edi
  800ab5:	5d                   	pop    %ebp
  800ab6:	c3                   	ret    

00800ab7 <sys_cgetc>:

int
sys_cgetc(void)
{
  800ab7:	55                   	push   %ebp
  800ab8:	89 e5                	mov    %esp,%ebp
  800aba:	57                   	push   %edi
  800abb:	56                   	push   %esi
  800abc:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800abd:	ba 00 00 00 00       	mov    $0x0,%edx
  800ac2:	b8 01 00 00 00       	mov    $0x1,%eax
  800ac7:	89 d1                	mov    %edx,%ecx
  800ac9:	89 d3                	mov    %edx,%ebx
  800acb:	89 d7                	mov    %edx,%edi
  800acd:	89 d6                	mov    %edx,%esi
  800acf:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800ad1:	5b                   	pop    %ebx
  800ad2:	5e                   	pop    %esi
  800ad3:	5f                   	pop    %edi
  800ad4:	5d                   	pop    %ebp
  800ad5:	c3                   	ret    

00800ad6 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ad6:	55                   	push   %ebp
  800ad7:	89 e5                	mov    %esp,%ebp
  800ad9:	57                   	push   %edi
  800ada:	56                   	push   %esi
  800adb:	53                   	push   %ebx
  800adc:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800adf:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ae4:	b8 03 00 00 00       	mov    $0x3,%eax
  800ae9:	8b 55 08             	mov    0x8(%ebp),%edx
  800aec:	89 cb                	mov    %ecx,%ebx
  800aee:	89 cf                	mov    %ecx,%edi
  800af0:	89 ce                	mov    %ecx,%esi
  800af2:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800af4:	85 c0                	test   %eax,%eax
  800af6:	7e 17                	jle    800b0f <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800af8:	83 ec 0c             	sub    $0xc,%esp
  800afb:	50                   	push   %eax
  800afc:	6a 03                	push   $0x3
  800afe:	68 60 10 80 00       	push   $0x801060
  800b03:	6a 23                	push   $0x23
  800b05:	68 7d 10 80 00       	push   $0x80107d
  800b0a:	e8 27 00 00 00       	call   800b36 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b0f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b12:	5b                   	pop    %ebx
  800b13:	5e                   	pop    %esi
  800b14:	5f                   	pop    %edi
  800b15:	5d                   	pop    %ebp
  800b16:	c3                   	ret    

00800b17 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b17:	55                   	push   %ebp
  800b18:	89 e5                	mov    %esp,%ebp
  800b1a:	57                   	push   %edi
  800b1b:	56                   	push   %esi
  800b1c:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b1d:	ba 00 00 00 00       	mov    $0x0,%edx
  800b22:	b8 02 00 00 00       	mov    $0x2,%eax
  800b27:	89 d1                	mov    %edx,%ecx
  800b29:	89 d3                	mov    %edx,%ebx
  800b2b:	89 d7                	mov    %edx,%edi
  800b2d:	89 d6                	mov    %edx,%esi
  800b2f:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b31:	5b                   	pop    %ebx
  800b32:	5e                   	pop    %esi
  800b33:	5f                   	pop    %edi
  800b34:	5d                   	pop    %ebp
  800b35:	c3                   	ret    

00800b36 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800b36:	55                   	push   %ebp
  800b37:	89 e5                	mov    %esp,%ebp
  800b39:	56                   	push   %esi
  800b3a:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800b3b:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800b3e:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800b44:	e8 ce ff ff ff       	call   800b17 <sys_getenvid>
  800b49:	83 ec 0c             	sub    $0xc,%esp
  800b4c:	ff 75 0c             	pushl  0xc(%ebp)
  800b4f:	ff 75 08             	pushl  0x8(%ebp)
  800b52:	56                   	push   %esi
  800b53:	50                   	push   %eax
  800b54:	68 8c 10 80 00       	push   $0x80108c
  800b59:	e8 f0 f5 ff ff       	call   80014e <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800b5e:	83 c4 18             	add    $0x18,%esp
  800b61:	53                   	push   %ebx
  800b62:	ff 75 10             	pushl  0x10(%ebp)
  800b65:	e8 93 f5 ff ff       	call   8000fd <vcprintf>
	cprintf("\n");
  800b6a:	c7 04 24 2c 0e 80 00 	movl   $0x800e2c,(%esp)
  800b71:	e8 d8 f5 ff ff       	call   80014e <cprintf>
  800b76:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b79:	cc                   	int3   
  800b7a:	eb fd                	jmp    800b79 <_panic+0x43>
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
