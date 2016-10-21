
obj/user/faultread:     file format elf32-i386


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

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	cprintf("I read %08x from location 0!\n", *(unsigned*)0);
  800039:	ff 35 00 00 00 00    	pushl  0x0
  80003f:	68 00 0e 80 00       	push   $0x800e00
  800044:	e8 f3 00 00 00       	call   80013c <cprintf>
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
  800059:	e8 a7 0a 00 00       	call   800b05 <sys_getenvid>
  80005e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800063:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800066:	c1 e0 05             	shl    $0x5,%eax
  800069:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80006e:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800073:	85 db                	test   %ebx,%ebx
  800075:	7e 07                	jle    80007e <libmain+0x30>
		binaryname = argv[0];
  800077:	8b 06                	mov    (%esi),%eax
  800079:	a3 00 20 80 00       	mov    %eax,0x802000

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
  80009f:	e8 20 0a 00 00       	call   800ac4 <sys_env_destroy>
}
  8000a4:	83 c4 10             	add    $0x10,%esp
  8000a7:	c9                   	leave  
  8000a8:	c3                   	ret    

008000a9 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000a9:	55                   	push   %ebp
  8000aa:	89 e5                	mov    %esp,%ebp
  8000ac:	53                   	push   %ebx
  8000ad:	83 ec 04             	sub    $0x4,%esp
  8000b0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b3:	8b 13                	mov    (%ebx),%edx
  8000b5:	8d 42 01             	lea    0x1(%edx),%eax
  8000b8:	89 03                	mov    %eax,(%ebx)
  8000ba:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000bd:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000c1:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000c6:	75 1a                	jne    8000e2 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000c8:	83 ec 08             	sub    $0x8,%esp
  8000cb:	68 ff 00 00 00       	push   $0xff
  8000d0:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d3:	50                   	push   %eax
  8000d4:	e8 ae 09 00 00       	call   800a87 <sys_cputs>
		b->idx = 0;
  8000d9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000df:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000e2:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000e6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000e9:	c9                   	leave  
  8000ea:	c3                   	ret    

008000eb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000eb:	55                   	push   %ebp
  8000ec:	89 e5                	mov    %esp,%ebp
  8000ee:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000f4:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000fb:	00 00 00 
	b.cnt = 0;
  8000fe:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800105:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800108:	ff 75 0c             	pushl  0xc(%ebp)
  80010b:	ff 75 08             	pushl  0x8(%ebp)
  80010e:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800114:	50                   	push   %eax
  800115:	68 a9 00 80 00       	push   $0x8000a9
  80011a:	e8 1a 01 00 00       	call   800239 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80011f:	83 c4 08             	add    $0x8,%esp
  800122:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800128:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80012e:	50                   	push   %eax
  80012f:	e8 53 09 00 00       	call   800a87 <sys_cputs>

	return b.cnt;
}
  800134:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80013a:	c9                   	leave  
  80013b:	c3                   	ret    

0080013c <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80013c:	55                   	push   %ebp
  80013d:	89 e5                	mov    %esp,%ebp
  80013f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800142:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800145:	50                   	push   %eax
  800146:	ff 75 08             	pushl  0x8(%ebp)
  800149:	e8 9d ff ff ff       	call   8000eb <vcprintf>
	va_end(ap);

	return cnt;
}
  80014e:	c9                   	leave  
  80014f:	c3                   	ret    

00800150 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800150:	55                   	push   %ebp
  800151:	89 e5                	mov    %esp,%ebp
  800153:	57                   	push   %edi
  800154:	56                   	push   %esi
  800155:	53                   	push   %ebx
  800156:	83 ec 1c             	sub    $0x1c,%esp
  800159:	89 c7                	mov    %eax,%edi
  80015b:	89 d6                	mov    %edx,%esi
  80015d:	8b 45 08             	mov    0x8(%ebp),%eax
  800160:	8b 55 0c             	mov    0xc(%ebp),%edx
  800163:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800166:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800169:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80016c:	bb 00 00 00 00       	mov    $0x0,%ebx
  800171:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800174:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800177:	39 d3                	cmp    %edx,%ebx
  800179:	72 05                	jb     800180 <printnum+0x30>
  80017b:	39 45 10             	cmp    %eax,0x10(%ebp)
  80017e:	77 45                	ja     8001c5 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800180:	83 ec 0c             	sub    $0xc,%esp
  800183:	ff 75 18             	pushl  0x18(%ebp)
  800186:	8b 45 14             	mov    0x14(%ebp),%eax
  800189:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80018c:	53                   	push   %ebx
  80018d:	ff 75 10             	pushl  0x10(%ebp)
  800190:	83 ec 08             	sub    $0x8,%esp
  800193:	ff 75 e4             	pushl  -0x1c(%ebp)
  800196:	ff 75 e0             	pushl  -0x20(%ebp)
  800199:	ff 75 dc             	pushl  -0x24(%ebp)
  80019c:	ff 75 d8             	pushl  -0x28(%ebp)
  80019f:	e8 cc 09 00 00       	call   800b70 <__udivdi3>
  8001a4:	83 c4 18             	add    $0x18,%esp
  8001a7:	52                   	push   %edx
  8001a8:	50                   	push   %eax
  8001a9:	89 f2                	mov    %esi,%edx
  8001ab:	89 f8                	mov    %edi,%eax
  8001ad:	e8 9e ff ff ff       	call   800150 <printnum>
  8001b2:	83 c4 20             	add    $0x20,%esp
  8001b5:	eb 18                	jmp    8001cf <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001b7:	83 ec 08             	sub    $0x8,%esp
  8001ba:	56                   	push   %esi
  8001bb:	ff 75 18             	pushl  0x18(%ebp)
  8001be:	ff d7                	call   *%edi
  8001c0:	83 c4 10             	add    $0x10,%esp
  8001c3:	eb 03                	jmp    8001c8 <printnum+0x78>
  8001c5:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001c8:	83 eb 01             	sub    $0x1,%ebx
  8001cb:	85 db                	test   %ebx,%ebx
  8001cd:	7f e8                	jg     8001b7 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001cf:	83 ec 08             	sub    $0x8,%esp
  8001d2:	56                   	push   %esi
  8001d3:	83 ec 04             	sub    $0x4,%esp
  8001d6:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001d9:	ff 75 e0             	pushl  -0x20(%ebp)
  8001dc:	ff 75 dc             	pushl  -0x24(%ebp)
  8001df:	ff 75 d8             	pushl  -0x28(%ebp)
  8001e2:	e8 b9 0a 00 00       	call   800ca0 <__umoddi3>
  8001e7:	83 c4 14             	add    $0x14,%esp
  8001ea:	0f be 80 28 0e 80 00 	movsbl 0x800e28(%eax),%eax
  8001f1:	50                   	push   %eax
  8001f2:	ff d7                	call   *%edi
}
  8001f4:	83 c4 10             	add    $0x10,%esp
  8001f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001fa:	5b                   	pop    %ebx
  8001fb:	5e                   	pop    %esi
  8001fc:	5f                   	pop    %edi
  8001fd:	5d                   	pop    %ebp
  8001fe:	c3                   	ret    

008001ff <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8001ff:	55                   	push   %ebp
  800200:	89 e5                	mov    %esp,%ebp
  800202:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800205:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800209:	8b 10                	mov    (%eax),%edx
  80020b:	3b 50 04             	cmp    0x4(%eax),%edx
  80020e:	73 0a                	jae    80021a <sprintputch+0x1b>
		*b->buf++ = ch;
  800210:	8d 4a 01             	lea    0x1(%edx),%ecx
  800213:	89 08                	mov    %ecx,(%eax)
  800215:	8b 45 08             	mov    0x8(%ebp),%eax
  800218:	88 02                	mov    %al,(%edx)
}
  80021a:	5d                   	pop    %ebp
  80021b:	c3                   	ret    

0080021c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80021c:	55                   	push   %ebp
  80021d:	89 e5                	mov    %esp,%ebp
  80021f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800222:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800225:	50                   	push   %eax
  800226:	ff 75 10             	pushl  0x10(%ebp)
  800229:	ff 75 0c             	pushl  0xc(%ebp)
  80022c:	ff 75 08             	pushl  0x8(%ebp)
  80022f:	e8 05 00 00 00       	call   800239 <vprintfmt>
	va_end(ap);
}
  800234:	83 c4 10             	add    $0x10,%esp
  800237:	c9                   	leave  
  800238:	c3                   	ret    

00800239 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800239:	55                   	push   %ebp
  80023a:	89 e5                	mov    %esp,%ebp
  80023c:	57                   	push   %edi
  80023d:	56                   	push   %esi
  80023e:	53                   	push   %ebx
  80023f:	83 ec 2c             	sub    $0x2c,%esp
  800242:	8b 75 08             	mov    0x8(%ebp),%esi
  800245:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800248:	8b 7d 10             	mov    0x10(%ebp),%edi
  80024b:	eb 12                	jmp    80025f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80024d:	85 c0                	test   %eax,%eax
  80024f:	0f 84 42 04 00 00    	je     800697 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800255:	83 ec 08             	sub    $0x8,%esp
  800258:	53                   	push   %ebx
  800259:	50                   	push   %eax
  80025a:	ff d6                	call   *%esi
  80025c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80025f:	83 c7 01             	add    $0x1,%edi
  800262:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800266:	83 f8 25             	cmp    $0x25,%eax
  800269:	75 e2                	jne    80024d <vprintfmt+0x14>
  80026b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80026f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800276:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80027d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800284:	b9 00 00 00 00       	mov    $0x0,%ecx
  800289:	eb 07                	jmp    800292 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80028b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80028e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800292:	8d 47 01             	lea    0x1(%edi),%eax
  800295:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800298:	0f b6 07             	movzbl (%edi),%eax
  80029b:	0f b6 d0             	movzbl %al,%edx
  80029e:	83 e8 23             	sub    $0x23,%eax
  8002a1:	3c 55                	cmp    $0x55,%al
  8002a3:	0f 87 d3 03 00 00    	ja     80067c <vprintfmt+0x443>
  8002a9:	0f b6 c0             	movzbl %al,%eax
  8002ac:	ff 24 85 c0 0e 80 00 	jmp    *0x800ec0(,%eax,4)
  8002b3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8002b6:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002ba:	eb d6                	jmp    800292 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002bf:	b8 00 00 00 00       	mov    $0x0,%eax
  8002c4:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8002c7:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8002ca:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8002ce:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8002d1:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8002d4:	83 f9 09             	cmp    $0x9,%ecx
  8002d7:	77 3f                	ja     800318 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8002d9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8002dc:	eb e9                	jmp    8002c7 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8002de:	8b 45 14             	mov    0x14(%ebp),%eax
  8002e1:	8b 00                	mov    (%eax),%eax
  8002e3:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8002e6:	8b 45 14             	mov    0x14(%ebp),%eax
  8002e9:	8d 40 04             	lea    0x4(%eax),%eax
  8002ec:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8002f2:	eb 2a                	jmp    80031e <vprintfmt+0xe5>
  8002f4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002f7:	85 c0                	test   %eax,%eax
  8002f9:	ba 00 00 00 00       	mov    $0x0,%edx
  8002fe:	0f 49 d0             	cmovns %eax,%edx
  800301:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800304:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800307:	eb 89                	jmp    800292 <vprintfmt+0x59>
  800309:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80030c:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800313:	e9 7a ff ff ff       	jmp    800292 <vprintfmt+0x59>
  800318:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  80031b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80031e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800322:	0f 89 6a ff ff ff    	jns    800292 <vprintfmt+0x59>
				width = precision, precision = -1;
  800328:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80032b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80032e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800335:	e9 58 ff ff ff       	jmp    800292 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80033a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80033d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800340:	e9 4d ff ff ff       	jmp    800292 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800345:	8b 45 14             	mov    0x14(%ebp),%eax
  800348:	8d 78 04             	lea    0x4(%eax),%edi
  80034b:	83 ec 08             	sub    $0x8,%esp
  80034e:	53                   	push   %ebx
  80034f:	ff 30                	pushl  (%eax)
  800351:	ff d6                	call   *%esi
			break;
  800353:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800356:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800359:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80035c:	e9 fe fe ff ff       	jmp    80025f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800361:	8b 45 14             	mov    0x14(%ebp),%eax
  800364:	8d 78 04             	lea    0x4(%eax),%edi
  800367:	8b 00                	mov    (%eax),%eax
  800369:	99                   	cltd   
  80036a:	31 d0                	xor    %edx,%eax
  80036c:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80036e:	83 f8 07             	cmp    $0x7,%eax
  800371:	7f 0b                	jg     80037e <vprintfmt+0x145>
  800373:	8b 14 85 20 10 80 00 	mov    0x801020(,%eax,4),%edx
  80037a:	85 d2                	test   %edx,%edx
  80037c:	75 1b                	jne    800399 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80037e:	50                   	push   %eax
  80037f:	68 40 0e 80 00       	push   $0x800e40
  800384:	53                   	push   %ebx
  800385:	56                   	push   %esi
  800386:	e8 91 fe ff ff       	call   80021c <printfmt>
  80038b:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80038e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800391:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800394:	e9 c6 fe ff ff       	jmp    80025f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800399:	52                   	push   %edx
  80039a:	68 49 0e 80 00       	push   $0x800e49
  80039f:	53                   	push   %ebx
  8003a0:	56                   	push   %esi
  8003a1:	e8 76 fe ff ff       	call   80021c <printfmt>
  8003a6:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003a9:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003af:	e9 ab fe ff ff       	jmp    80025f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b7:	83 c0 04             	add    $0x4,%eax
  8003ba:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8003bd:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c0:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003c2:	85 ff                	test   %edi,%edi
  8003c4:	b8 39 0e 80 00       	mov    $0x800e39,%eax
  8003c9:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003cc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003d0:	0f 8e 94 00 00 00    	jle    80046a <vprintfmt+0x231>
  8003d6:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8003da:	0f 84 98 00 00 00    	je     800478 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8003e0:	83 ec 08             	sub    $0x8,%esp
  8003e3:	ff 75 d0             	pushl  -0x30(%ebp)
  8003e6:	57                   	push   %edi
  8003e7:	e8 33 03 00 00       	call   80071f <strnlen>
  8003ec:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8003ef:	29 c1                	sub    %eax,%ecx
  8003f1:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8003f4:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8003f7:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8003fb:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003fe:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800401:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800403:	eb 0f                	jmp    800414 <vprintfmt+0x1db>
					putch(padc, putdat);
  800405:	83 ec 08             	sub    $0x8,%esp
  800408:	53                   	push   %ebx
  800409:	ff 75 e0             	pushl  -0x20(%ebp)
  80040c:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80040e:	83 ef 01             	sub    $0x1,%edi
  800411:	83 c4 10             	add    $0x10,%esp
  800414:	85 ff                	test   %edi,%edi
  800416:	7f ed                	jg     800405 <vprintfmt+0x1cc>
  800418:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80041b:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  80041e:	85 c9                	test   %ecx,%ecx
  800420:	b8 00 00 00 00       	mov    $0x0,%eax
  800425:	0f 49 c1             	cmovns %ecx,%eax
  800428:	29 c1                	sub    %eax,%ecx
  80042a:	89 75 08             	mov    %esi,0x8(%ebp)
  80042d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800430:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800433:	89 cb                	mov    %ecx,%ebx
  800435:	eb 4d                	jmp    800484 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800437:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80043b:	74 1b                	je     800458 <vprintfmt+0x21f>
  80043d:	0f be c0             	movsbl %al,%eax
  800440:	83 e8 20             	sub    $0x20,%eax
  800443:	83 f8 5e             	cmp    $0x5e,%eax
  800446:	76 10                	jbe    800458 <vprintfmt+0x21f>
					putch('?', putdat);
  800448:	83 ec 08             	sub    $0x8,%esp
  80044b:	ff 75 0c             	pushl  0xc(%ebp)
  80044e:	6a 3f                	push   $0x3f
  800450:	ff 55 08             	call   *0x8(%ebp)
  800453:	83 c4 10             	add    $0x10,%esp
  800456:	eb 0d                	jmp    800465 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800458:	83 ec 08             	sub    $0x8,%esp
  80045b:	ff 75 0c             	pushl  0xc(%ebp)
  80045e:	52                   	push   %edx
  80045f:	ff 55 08             	call   *0x8(%ebp)
  800462:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800465:	83 eb 01             	sub    $0x1,%ebx
  800468:	eb 1a                	jmp    800484 <vprintfmt+0x24b>
  80046a:	89 75 08             	mov    %esi,0x8(%ebp)
  80046d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800470:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800473:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800476:	eb 0c                	jmp    800484 <vprintfmt+0x24b>
  800478:	89 75 08             	mov    %esi,0x8(%ebp)
  80047b:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80047e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800481:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800484:	83 c7 01             	add    $0x1,%edi
  800487:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80048b:	0f be d0             	movsbl %al,%edx
  80048e:	85 d2                	test   %edx,%edx
  800490:	74 23                	je     8004b5 <vprintfmt+0x27c>
  800492:	85 f6                	test   %esi,%esi
  800494:	78 a1                	js     800437 <vprintfmt+0x1fe>
  800496:	83 ee 01             	sub    $0x1,%esi
  800499:	79 9c                	jns    800437 <vprintfmt+0x1fe>
  80049b:	89 df                	mov    %ebx,%edi
  80049d:	8b 75 08             	mov    0x8(%ebp),%esi
  8004a0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004a3:	eb 18                	jmp    8004bd <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004a5:	83 ec 08             	sub    $0x8,%esp
  8004a8:	53                   	push   %ebx
  8004a9:	6a 20                	push   $0x20
  8004ab:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004ad:	83 ef 01             	sub    $0x1,%edi
  8004b0:	83 c4 10             	add    $0x10,%esp
  8004b3:	eb 08                	jmp    8004bd <vprintfmt+0x284>
  8004b5:	89 df                	mov    %ebx,%edi
  8004b7:	8b 75 08             	mov    0x8(%ebp),%esi
  8004ba:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004bd:	85 ff                	test   %edi,%edi
  8004bf:	7f e4                	jg     8004a5 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004c1:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8004c4:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004c7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004ca:	e9 90 fd ff ff       	jmp    80025f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004cf:	83 f9 01             	cmp    $0x1,%ecx
  8004d2:	7e 19                	jle    8004ed <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8004d4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004d7:	8b 50 04             	mov    0x4(%eax),%edx
  8004da:	8b 00                	mov    (%eax),%eax
  8004dc:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004df:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004e2:	8b 45 14             	mov    0x14(%ebp),%eax
  8004e5:	8d 40 08             	lea    0x8(%eax),%eax
  8004e8:	89 45 14             	mov    %eax,0x14(%ebp)
  8004eb:	eb 38                	jmp    800525 <vprintfmt+0x2ec>
	else if (lflag)
  8004ed:	85 c9                	test   %ecx,%ecx
  8004ef:	74 1b                	je     80050c <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8004f1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f4:	8b 00                	mov    (%eax),%eax
  8004f6:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004f9:	89 c1                	mov    %eax,%ecx
  8004fb:	c1 f9 1f             	sar    $0x1f,%ecx
  8004fe:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800501:	8b 45 14             	mov    0x14(%ebp),%eax
  800504:	8d 40 04             	lea    0x4(%eax),%eax
  800507:	89 45 14             	mov    %eax,0x14(%ebp)
  80050a:	eb 19                	jmp    800525 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  80050c:	8b 45 14             	mov    0x14(%ebp),%eax
  80050f:	8b 00                	mov    (%eax),%eax
  800511:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800514:	89 c1                	mov    %eax,%ecx
  800516:	c1 f9 1f             	sar    $0x1f,%ecx
  800519:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80051c:	8b 45 14             	mov    0x14(%ebp),%eax
  80051f:	8d 40 04             	lea    0x4(%eax),%eax
  800522:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800525:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800528:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80052b:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800530:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800534:	0f 89 0e 01 00 00    	jns    800648 <vprintfmt+0x40f>
				putch('-', putdat);
  80053a:	83 ec 08             	sub    $0x8,%esp
  80053d:	53                   	push   %ebx
  80053e:	6a 2d                	push   $0x2d
  800540:	ff d6                	call   *%esi
				num = -(long long) num;
  800542:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800545:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800548:	f7 da                	neg    %edx
  80054a:	83 d1 00             	adc    $0x0,%ecx
  80054d:	f7 d9                	neg    %ecx
  80054f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800552:	b8 0a 00 00 00       	mov    $0xa,%eax
  800557:	e9 ec 00 00 00       	jmp    800648 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80055c:	83 f9 01             	cmp    $0x1,%ecx
  80055f:	7e 18                	jle    800579 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800561:	8b 45 14             	mov    0x14(%ebp),%eax
  800564:	8b 10                	mov    (%eax),%edx
  800566:	8b 48 04             	mov    0x4(%eax),%ecx
  800569:	8d 40 08             	lea    0x8(%eax),%eax
  80056c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80056f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800574:	e9 cf 00 00 00       	jmp    800648 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800579:	85 c9                	test   %ecx,%ecx
  80057b:	74 1a                	je     800597 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80057d:	8b 45 14             	mov    0x14(%ebp),%eax
  800580:	8b 10                	mov    (%eax),%edx
  800582:	b9 00 00 00 00       	mov    $0x0,%ecx
  800587:	8d 40 04             	lea    0x4(%eax),%eax
  80058a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80058d:	b8 0a 00 00 00       	mov    $0xa,%eax
  800592:	e9 b1 00 00 00       	jmp    800648 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800597:	8b 45 14             	mov    0x14(%ebp),%eax
  80059a:	8b 10                	mov    (%eax),%edx
  80059c:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005a1:	8d 40 04             	lea    0x4(%eax),%eax
  8005a4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005a7:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005ac:	e9 97 00 00 00       	jmp    800648 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  8005b1:	83 ec 08             	sub    $0x8,%esp
  8005b4:	53                   	push   %ebx
  8005b5:	6a 58                	push   $0x58
  8005b7:	ff d6                	call   *%esi
			putch('X', putdat);
  8005b9:	83 c4 08             	add    $0x8,%esp
  8005bc:	53                   	push   %ebx
  8005bd:	6a 58                	push   $0x58
  8005bf:	ff d6                	call   *%esi
			putch('X', putdat);
  8005c1:	83 c4 08             	add    $0x8,%esp
  8005c4:	53                   	push   %ebx
  8005c5:	6a 58                	push   $0x58
  8005c7:	ff d6                	call   *%esi
			break;
  8005c9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8005cf:	e9 8b fc ff ff       	jmp    80025f <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8005d4:	83 ec 08             	sub    $0x8,%esp
  8005d7:	53                   	push   %ebx
  8005d8:	6a 30                	push   $0x30
  8005da:	ff d6                	call   *%esi
			putch('x', putdat);
  8005dc:	83 c4 08             	add    $0x8,%esp
  8005df:	53                   	push   %ebx
  8005e0:	6a 78                	push   $0x78
  8005e2:	ff d6                	call   *%esi
			num = (unsigned long long)
  8005e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e7:	8b 10                	mov    (%eax),%edx
  8005e9:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005ee:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8005f1:	8d 40 04             	lea    0x4(%eax),%eax
  8005f4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8005f7:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8005fc:	eb 4a                	jmp    800648 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005fe:	83 f9 01             	cmp    $0x1,%ecx
  800601:	7e 15                	jle    800618 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  800603:	8b 45 14             	mov    0x14(%ebp),%eax
  800606:	8b 10                	mov    (%eax),%edx
  800608:	8b 48 04             	mov    0x4(%eax),%ecx
  80060b:	8d 40 08             	lea    0x8(%eax),%eax
  80060e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800611:	b8 10 00 00 00       	mov    $0x10,%eax
  800616:	eb 30                	jmp    800648 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800618:	85 c9                	test   %ecx,%ecx
  80061a:	74 17                	je     800633 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  80061c:	8b 45 14             	mov    0x14(%ebp),%eax
  80061f:	8b 10                	mov    (%eax),%edx
  800621:	b9 00 00 00 00       	mov    $0x0,%ecx
  800626:	8d 40 04             	lea    0x4(%eax),%eax
  800629:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80062c:	b8 10 00 00 00       	mov    $0x10,%eax
  800631:	eb 15                	jmp    800648 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800633:	8b 45 14             	mov    0x14(%ebp),%eax
  800636:	8b 10                	mov    (%eax),%edx
  800638:	b9 00 00 00 00       	mov    $0x0,%ecx
  80063d:	8d 40 04             	lea    0x4(%eax),%eax
  800640:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800643:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800648:	83 ec 0c             	sub    $0xc,%esp
  80064b:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80064f:	57                   	push   %edi
  800650:	ff 75 e0             	pushl  -0x20(%ebp)
  800653:	50                   	push   %eax
  800654:	51                   	push   %ecx
  800655:	52                   	push   %edx
  800656:	89 da                	mov    %ebx,%edx
  800658:	89 f0                	mov    %esi,%eax
  80065a:	e8 f1 fa ff ff       	call   800150 <printnum>
			break;
  80065f:	83 c4 20             	add    $0x20,%esp
  800662:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800665:	e9 f5 fb ff ff       	jmp    80025f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80066a:	83 ec 08             	sub    $0x8,%esp
  80066d:	53                   	push   %ebx
  80066e:	52                   	push   %edx
  80066f:	ff d6                	call   *%esi
			break;
  800671:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800674:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800677:	e9 e3 fb ff ff       	jmp    80025f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80067c:	83 ec 08             	sub    $0x8,%esp
  80067f:	53                   	push   %ebx
  800680:	6a 25                	push   $0x25
  800682:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800684:	83 c4 10             	add    $0x10,%esp
  800687:	eb 03                	jmp    80068c <vprintfmt+0x453>
  800689:	83 ef 01             	sub    $0x1,%edi
  80068c:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800690:	75 f7                	jne    800689 <vprintfmt+0x450>
  800692:	e9 c8 fb ff ff       	jmp    80025f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800697:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80069a:	5b                   	pop    %ebx
  80069b:	5e                   	pop    %esi
  80069c:	5f                   	pop    %edi
  80069d:	5d                   	pop    %ebp
  80069e:	c3                   	ret    

0080069f <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80069f:	55                   	push   %ebp
  8006a0:	89 e5                	mov    %esp,%ebp
  8006a2:	83 ec 18             	sub    $0x18,%esp
  8006a5:	8b 45 08             	mov    0x8(%ebp),%eax
  8006a8:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006ab:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006ae:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006b2:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006b5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006bc:	85 c0                	test   %eax,%eax
  8006be:	74 26                	je     8006e6 <vsnprintf+0x47>
  8006c0:	85 d2                	test   %edx,%edx
  8006c2:	7e 22                	jle    8006e6 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006c4:	ff 75 14             	pushl  0x14(%ebp)
  8006c7:	ff 75 10             	pushl  0x10(%ebp)
  8006ca:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006cd:	50                   	push   %eax
  8006ce:	68 ff 01 80 00       	push   $0x8001ff
  8006d3:	e8 61 fb ff ff       	call   800239 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006db:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006de:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006e1:	83 c4 10             	add    $0x10,%esp
  8006e4:	eb 05                	jmp    8006eb <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006e6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006eb:	c9                   	leave  
  8006ec:	c3                   	ret    

008006ed <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006ed:	55                   	push   %ebp
  8006ee:	89 e5                	mov    %esp,%ebp
  8006f0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8006f3:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8006f6:	50                   	push   %eax
  8006f7:	ff 75 10             	pushl  0x10(%ebp)
  8006fa:	ff 75 0c             	pushl  0xc(%ebp)
  8006fd:	ff 75 08             	pushl  0x8(%ebp)
  800700:	e8 9a ff ff ff       	call   80069f <vsnprintf>
	va_end(ap);

	return rc;
}
  800705:	c9                   	leave  
  800706:	c3                   	ret    

00800707 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800707:	55                   	push   %ebp
  800708:	89 e5                	mov    %esp,%ebp
  80070a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80070d:	b8 00 00 00 00       	mov    $0x0,%eax
  800712:	eb 03                	jmp    800717 <strlen+0x10>
		n++;
  800714:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800717:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80071b:	75 f7                	jne    800714 <strlen+0xd>
		n++;
	return n;
}
  80071d:	5d                   	pop    %ebp
  80071e:	c3                   	ret    

0080071f <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80071f:	55                   	push   %ebp
  800720:	89 e5                	mov    %esp,%ebp
  800722:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800725:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800728:	ba 00 00 00 00       	mov    $0x0,%edx
  80072d:	eb 03                	jmp    800732 <strnlen+0x13>
		n++;
  80072f:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800732:	39 c2                	cmp    %eax,%edx
  800734:	74 08                	je     80073e <strnlen+0x1f>
  800736:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80073a:	75 f3                	jne    80072f <strnlen+0x10>
  80073c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80073e:	5d                   	pop    %ebp
  80073f:	c3                   	ret    

00800740 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800740:	55                   	push   %ebp
  800741:	89 e5                	mov    %esp,%ebp
  800743:	53                   	push   %ebx
  800744:	8b 45 08             	mov    0x8(%ebp),%eax
  800747:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80074a:	89 c2                	mov    %eax,%edx
  80074c:	83 c2 01             	add    $0x1,%edx
  80074f:	83 c1 01             	add    $0x1,%ecx
  800752:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800756:	88 5a ff             	mov    %bl,-0x1(%edx)
  800759:	84 db                	test   %bl,%bl
  80075b:	75 ef                	jne    80074c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80075d:	5b                   	pop    %ebx
  80075e:	5d                   	pop    %ebp
  80075f:	c3                   	ret    

00800760 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800760:	55                   	push   %ebp
  800761:	89 e5                	mov    %esp,%ebp
  800763:	53                   	push   %ebx
  800764:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800767:	53                   	push   %ebx
  800768:	e8 9a ff ff ff       	call   800707 <strlen>
  80076d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800770:	ff 75 0c             	pushl  0xc(%ebp)
  800773:	01 d8                	add    %ebx,%eax
  800775:	50                   	push   %eax
  800776:	e8 c5 ff ff ff       	call   800740 <strcpy>
	return dst;
}
  80077b:	89 d8                	mov    %ebx,%eax
  80077d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800780:	c9                   	leave  
  800781:	c3                   	ret    

00800782 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800782:	55                   	push   %ebp
  800783:	89 e5                	mov    %esp,%ebp
  800785:	56                   	push   %esi
  800786:	53                   	push   %ebx
  800787:	8b 75 08             	mov    0x8(%ebp),%esi
  80078a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80078d:	89 f3                	mov    %esi,%ebx
  80078f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800792:	89 f2                	mov    %esi,%edx
  800794:	eb 0f                	jmp    8007a5 <strncpy+0x23>
		*dst++ = *src;
  800796:	83 c2 01             	add    $0x1,%edx
  800799:	0f b6 01             	movzbl (%ecx),%eax
  80079c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80079f:	80 39 01             	cmpb   $0x1,(%ecx)
  8007a2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007a5:	39 da                	cmp    %ebx,%edx
  8007a7:	75 ed                	jne    800796 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007a9:	89 f0                	mov    %esi,%eax
  8007ab:	5b                   	pop    %ebx
  8007ac:	5e                   	pop    %esi
  8007ad:	5d                   	pop    %ebp
  8007ae:	c3                   	ret    

008007af <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007af:	55                   	push   %ebp
  8007b0:	89 e5                	mov    %esp,%ebp
  8007b2:	56                   	push   %esi
  8007b3:	53                   	push   %ebx
  8007b4:	8b 75 08             	mov    0x8(%ebp),%esi
  8007b7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007ba:	8b 55 10             	mov    0x10(%ebp),%edx
  8007bd:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007bf:	85 d2                	test   %edx,%edx
  8007c1:	74 21                	je     8007e4 <strlcpy+0x35>
  8007c3:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8007c7:	89 f2                	mov    %esi,%edx
  8007c9:	eb 09                	jmp    8007d4 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007cb:	83 c2 01             	add    $0x1,%edx
  8007ce:	83 c1 01             	add    $0x1,%ecx
  8007d1:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007d4:	39 c2                	cmp    %eax,%edx
  8007d6:	74 09                	je     8007e1 <strlcpy+0x32>
  8007d8:	0f b6 19             	movzbl (%ecx),%ebx
  8007db:	84 db                	test   %bl,%bl
  8007dd:	75 ec                	jne    8007cb <strlcpy+0x1c>
  8007df:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8007e1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8007e4:	29 f0                	sub    %esi,%eax
}
  8007e6:	5b                   	pop    %ebx
  8007e7:	5e                   	pop    %esi
  8007e8:	5d                   	pop    %ebp
  8007e9:	c3                   	ret    

008007ea <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8007ea:	55                   	push   %ebp
  8007eb:	89 e5                	mov    %esp,%ebp
  8007ed:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007f0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8007f3:	eb 06                	jmp    8007fb <strcmp+0x11>
		p++, q++;
  8007f5:	83 c1 01             	add    $0x1,%ecx
  8007f8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8007fb:	0f b6 01             	movzbl (%ecx),%eax
  8007fe:	84 c0                	test   %al,%al
  800800:	74 04                	je     800806 <strcmp+0x1c>
  800802:	3a 02                	cmp    (%edx),%al
  800804:	74 ef                	je     8007f5 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800806:	0f b6 c0             	movzbl %al,%eax
  800809:	0f b6 12             	movzbl (%edx),%edx
  80080c:	29 d0                	sub    %edx,%eax
}
  80080e:	5d                   	pop    %ebp
  80080f:	c3                   	ret    

00800810 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800810:	55                   	push   %ebp
  800811:	89 e5                	mov    %esp,%ebp
  800813:	53                   	push   %ebx
  800814:	8b 45 08             	mov    0x8(%ebp),%eax
  800817:	8b 55 0c             	mov    0xc(%ebp),%edx
  80081a:	89 c3                	mov    %eax,%ebx
  80081c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80081f:	eb 06                	jmp    800827 <strncmp+0x17>
		n--, p++, q++;
  800821:	83 c0 01             	add    $0x1,%eax
  800824:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800827:	39 d8                	cmp    %ebx,%eax
  800829:	74 15                	je     800840 <strncmp+0x30>
  80082b:	0f b6 08             	movzbl (%eax),%ecx
  80082e:	84 c9                	test   %cl,%cl
  800830:	74 04                	je     800836 <strncmp+0x26>
  800832:	3a 0a                	cmp    (%edx),%cl
  800834:	74 eb                	je     800821 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800836:	0f b6 00             	movzbl (%eax),%eax
  800839:	0f b6 12             	movzbl (%edx),%edx
  80083c:	29 d0                	sub    %edx,%eax
  80083e:	eb 05                	jmp    800845 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800840:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800845:	5b                   	pop    %ebx
  800846:	5d                   	pop    %ebp
  800847:	c3                   	ret    

00800848 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800848:	55                   	push   %ebp
  800849:	89 e5                	mov    %esp,%ebp
  80084b:	8b 45 08             	mov    0x8(%ebp),%eax
  80084e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800852:	eb 07                	jmp    80085b <strchr+0x13>
		if (*s == c)
  800854:	38 ca                	cmp    %cl,%dl
  800856:	74 0f                	je     800867 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800858:	83 c0 01             	add    $0x1,%eax
  80085b:	0f b6 10             	movzbl (%eax),%edx
  80085e:	84 d2                	test   %dl,%dl
  800860:	75 f2                	jne    800854 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800862:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800867:	5d                   	pop    %ebp
  800868:	c3                   	ret    

00800869 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800869:	55                   	push   %ebp
  80086a:	89 e5                	mov    %esp,%ebp
  80086c:	8b 45 08             	mov    0x8(%ebp),%eax
  80086f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800873:	eb 03                	jmp    800878 <strfind+0xf>
  800875:	83 c0 01             	add    $0x1,%eax
  800878:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  80087b:	38 ca                	cmp    %cl,%dl
  80087d:	74 04                	je     800883 <strfind+0x1a>
  80087f:	84 d2                	test   %dl,%dl
  800881:	75 f2                	jne    800875 <strfind+0xc>
			break;
	return (char *) s;
}
  800883:	5d                   	pop    %ebp
  800884:	c3                   	ret    

00800885 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800885:	55                   	push   %ebp
  800886:	89 e5                	mov    %esp,%ebp
  800888:	57                   	push   %edi
  800889:	56                   	push   %esi
  80088a:	53                   	push   %ebx
  80088b:	8b 7d 08             	mov    0x8(%ebp),%edi
  80088e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800891:	85 c9                	test   %ecx,%ecx
  800893:	74 36                	je     8008cb <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800895:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80089b:	75 28                	jne    8008c5 <memset+0x40>
  80089d:	f6 c1 03             	test   $0x3,%cl
  8008a0:	75 23                	jne    8008c5 <memset+0x40>
		c &= 0xFF;
  8008a2:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008a6:	89 d3                	mov    %edx,%ebx
  8008a8:	c1 e3 08             	shl    $0x8,%ebx
  8008ab:	89 d6                	mov    %edx,%esi
  8008ad:	c1 e6 18             	shl    $0x18,%esi
  8008b0:	89 d0                	mov    %edx,%eax
  8008b2:	c1 e0 10             	shl    $0x10,%eax
  8008b5:	09 f0                	or     %esi,%eax
  8008b7:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008b9:	89 d8                	mov    %ebx,%eax
  8008bb:	09 d0                	or     %edx,%eax
  8008bd:	c1 e9 02             	shr    $0x2,%ecx
  8008c0:	fc                   	cld    
  8008c1:	f3 ab                	rep stos %eax,%es:(%edi)
  8008c3:	eb 06                	jmp    8008cb <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008c5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008c8:	fc                   	cld    
  8008c9:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008cb:	89 f8                	mov    %edi,%eax
  8008cd:	5b                   	pop    %ebx
  8008ce:	5e                   	pop    %esi
  8008cf:	5f                   	pop    %edi
  8008d0:	5d                   	pop    %ebp
  8008d1:	c3                   	ret    

008008d2 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008d2:	55                   	push   %ebp
  8008d3:	89 e5                	mov    %esp,%ebp
  8008d5:	57                   	push   %edi
  8008d6:	56                   	push   %esi
  8008d7:	8b 45 08             	mov    0x8(%ebp),%eax
  8008da:	8b 75 0c             	mov    0xc(%ebp),%esi
  8008dd:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8008e0:	39 c6                	cmp    %eax,%esi
  8008e2:	73 35                	jae    800919 <memmove+0x47>
  8008e4:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8008e7:	39 d0                	cmp    %edx,%eax
  8008e9:	73 2e                	jae    800919 <memmove+0x47>
		s += n;
		d += n;
  8008eb:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8008ee:	89 d6                	mov    %edx,%esi
  8008f0:	09 fe                	or     %edi,%esi
  8008f2:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8008f8:	75 13                	jne    80090d <memmove+0x3b>
  8008fa:	f6 c1 03             	test   $0x3,%cl
  8008fd:	75 0e                	jne    80090d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8008ff:	83 ef 04             	sub    $0x4,%edi
  800902:	8d 72 fc             	lea    -0x4(%edx),%esi
  800905:	c1 e9 02             	shr    $0x2,%ecx
  800908:	fd                   	std    
  800909:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80090b:	eb 09                	jmp    800916 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80090d:	83 ef 01             	sub    $0x1,%edi
  800910:	8d 72 ff             	lea    -0x1(%edx),%esi
  800913:	fd                   	std    
  800914:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800916:	fc                   	cld    
  800917:	eb 1d                	jmp    800936 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800919:	89 f2                	mov    %esi,%edx
  80091b:	09 c2                	or     %eax,%edx
  80091d:	f6 c2 03             	test   $0x3,%dl
  800920:	75 0f                	jne    800931 <memmove+0x5f>
  800922:	f6 c1 03             	test   $0x3,%cl
  800925:	75 0a                	jne    800931 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800927:	c1 e9 02             	shr    $0x2,%ecx
  80092a:	89 c7                	mov    %eax,%edi
  80092c:	fc                   	cld    
  80092d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80092f:	eb 05                	jmp    800936 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800931:	89 c7                	mov    %eax,%edi
  800933:	fc                   	cld    
  800934:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800936:	5e                   	pop    %esi
  800937:	5f                   	pop    %edi
  800938:	5d                   	pop    %ebp
  800939:	c3                   	ret    

0080093a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80093a:	55                   	push   %ebp
  80093b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80093d:	ff 75 10             	pushl  0x10(%ebp)
  800940:	ff 75 0c             	pushl  0xc(%ebp)
  800943:	ff 75 08             	pushl  0x8(%ebp)
  800946:	e8 87 ff ff ff       	call   8008d2 <memmove>
}
  80094b:	c9                   	leave  
  80094c:	c3                   	ret    

0080094d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80094d:	55                   	push   %ebp
  80094e:	89 e5                	mov    %esp,%ebp
  800950:	56                   	push   %esi
  800951:	53                   	push   %ebx
  800952:	8b 45 08             	mov    0x8(%ebp),%eax
  800955:	8b 55 0c             	mov    0xc(%ebp),%edx
  800958:	89 c6                	mov    %eax,%esi
  80095a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80095d:	eb 1a                	jmp    800979 <memcmp+0x2c>
		if (*s1 != *s2)
  80095f:	0f b6 08             	movzbl (%eax),%ecx
  800962:	0f b6 1a             	movzbl (%edx),%ebx
  800965:	38 d9                	cmp    %bl,%cl
  800967:	74 0a                	je     800973 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800969:	0f b6 c1             	movzbl %cl,%eax
  80096c:	0f b6 db             	movzbl %bl,%ebx
  80096f:	29 d8                	sub    %ebx,%eax
  800971:	eb 0f                	jmp    800982 <memcmp+0x35>
		s1++, s2++;
  800973:	83 c0 01             	add    $0x1,%eax
  800976:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800979:	39 f0                	cmp    %esi,%eax
  80097b:	75 e2                	jne    80095f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  80097d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800982:	5b                   	pop    %ebx
  800983:	5e                   	pop    %esi
  800984:	5d                   	pop    %ebp
  800985:	c3                   	ret    

00800986 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800986:	55                   	push   %ebp
  800987:	89 e5                	mov    %esp,%ebp
  800989:	53                   	push   %ebx
  80098a:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  80098d:	89 c1                	mov    %eax,%ecx
  80098f:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800992:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800996:	eb 0a                	jmp    8009a2 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800998:	0f b6 10             	movzbl (%eax),%edx
  80099b:	39 da                	cmp    %ebx,%edx
  80099d:	74 07                	je     8009a6 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  80099f:	83 c0 01             	add    $0x1,%eax
  8009a2:	39 c8                	cmp    %ecx,%eax
  8009a4:	72 f2                	jb     800998 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009a6:	5b                   	pop    %ebx
  8009a7:	5d                   	pop    %ebp
  8009a8:	c3                   	ret    

008009a9 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009a9:	55                   	push   %ebp
  8009aa:	89 e5                	mov    %esp,%ebp
  8009ac:	57                   	push   %edi
  8009ad:	56                   	push   %esi
  8009ae:	53                   	push   %ebx
  8009af:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009b2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009b5:	eb 03                	jmp    8009ba <strtol+0x11>
		s++;
  8009b7:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009ba:	0f b6 01             	movzbl (%ecx),%eax
  8009bd:	3c 20                	cmp    $0x20,%al
  8009bf:	74 f6                	je     8009b7 <strtol+0xe>
  8009c1:	3c 09                	cmp    $0x9,%al
  8009c3:	74 f2                	je     8009b7 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009c5:	3c 2b                	cmp    $0x2b,%al
  8009c7:	75 0a                	jne    8009d3 <strtol+0x2a>
		s++;
  8009c9:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009cc:	bf 00 00 00 00       	mov    $0x0,%edi
  8009d1:	eb 11                	jmp    8009e4 <strtol+0x3b>
  8009d3:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  8009d8:	3c 2d                	cmp    $0x2d,%al
  8009da:	75 08                	jne    8009e4 <strtol+0x3b>
		s++, neg = 1;
  8009dc:	83 c1 01             	add    $0x1,%ecx
  8009df:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  8009e4:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  8009ea:	75 15                	jne    800a01 <strtol+0x58>
  8009ec:	80 39 30             	cmpb   $0x30,(%ecx)
  8009ef:	75 10                	jne    800a01 <strtol+0x58>
  8009f1:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  8009f5:	75 7c                	jne    800a73 <strtol+0xca>
		s += 2, base = 16;
  8009f7:	83 c1 02             	add    $0x2,%ecx
  8009fa:	bb 10 00 00 00       	mov    $0x10,%ebx
  8009ff:	eb 16                	jmp    800a17 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a01:	85 db                	test   %ebx,%ebx
  800a03:	75 12                	jne    800a17 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a05:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a0a:	80 39 30             	cmpb   $0x30,(%ecx)
  800a0d:	75 08                	jne    800a17 <strtol+0x6e>
		s++, base = 8;
  800a0f:	83 c1 01             	add    $0x1,%ecx
  800a12:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a17:	b8 00 00 00 00       	mov    $0x0,%eax
  800a1c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a1f:	0f b6 11             	movzbl (%ecx),%edx
  800a22:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a25:	89 f3                	mov    %esi,%ebx
  800a27:	80 fb 09             	cmp    $0x9,%bl
  800a2a:	77 08                	ja     800a34 <strtol+0x8b>
			dig = *s - '0';
  800a2c:	0f be d2             	movsbl %dl,%edx
  800a2f:	83 ea 30             	sub    $0x30,%edx
  800a32:	eb 22                	jmp    800a56 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a34:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a37:	89 f3                	mov    %esi,%ebx
  800a39:	80 fb 19             	cmp    $0x19,%bl
  800a3c:	77 08                	ja     800a46 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a3e:	0f be d2             	movsbl %dl,%edx
  800a41:	83 ea 57             	sub    $0x57,%edx
  800a44:	eb 10                	jmp    800a56 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a46:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a49:	89 f3                	mov    %esi,%ebx
  800a4b:	80 fb 19             	cmp    $0x19,%bl
  800a4e:	77 16                	ja     800a66 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a50:	0f be d2             	movsbl %dl,%edx
  800a53:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a56:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a59:	7d 0b                	jge    800a66 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a5b:	83 c1 01             	add    $0x1,%ecx
  800a5e:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a62:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a64:	eb b9                	jmp    800a1f <strtol+0x76>

	if (endptr)
  800a66:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a6a:	74 0d                	je     800a79 <strtol+0xd0>
		*endptr = (char *) s;
  800a6c:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a6f:	89 0e                	mov    %ecx,(%esi)
  800a71:	eb 06                	jmp    800a79 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a73:	85 db                	test   %ebx,%ebx
  800a75:	74 98                	je     800a0f <strtol+0x66>
  800a77:	eb 9e                	jmp    800a17 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a79:	89 c2                	mov    %eax,%edx
  800a7b:	f7 da                	neg    %edx
  800a7d:	85 ff                	test   %edi,%edi
  800a7f:	0f 45 c2             	cmovne %edx,%eax
}
  800a82:	5b                   	pop    %ebx
  800a83:	5e                   	pop    %esi
  800a84:	5f                   	pop    %edi
  800a85:	5d                   	pop    %ebp
  800a86:	c3                   	ret    

00800a87 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a87:	55                   	push   %ebp
  800a88:	89 e5                	mov    %esp,%ebp
  800a8a:	57                   	push   %edi
  800a8b:	56                   	push   %esi
  800a8c:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a8d:	b8 00 00 00 00       	mov    $0x0,%eax
  800a92:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a95:	8b 55 08             	mov    0x8(%ebp),%edx
  800a98:	89 c3                	mov    %eax,%ebx
  800a9a:	89 c7                	mov    %eax,%edi
  800a9c:	89 c6                	mov    %eax,%esi
  800a9e:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800aa0:	5b                   	pop    %ebx
  800aa1:	5e                   	pop    %esi
  800aa2:	5f                   	pop    %edi
  800aa3:	5d                   	pop    %ebp
  800aa4:	c3                   	ret    

00800aa5 <sys_cgetc>:

int
sys_cgetc(void)
{
  800aa5:	55                   	push   %ebp
  800aa6:	89 e5                	mov    %esp,%ebp
  800aa8:	57                   	push   %edi
  800aa9:	56                   	push   %esi
  800aaa:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800aab:	ba 00 00 00 00       	mov    $0x0,%edx
  800ab0:	b8 01 00 00 00       	mov    $0x1,%eax
  800ab5:	89 d1                	mov    %edx,%ecx
  800ab7:	89 d3                	mov    %edx,%ebx
  800ab9:	89 d7                	mov    %edx,%edi
  800abb:	89 d6                	mov    %edx,%esi
  800abd:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800abf:	5b                   	pop    %ebx
  800ac0:	5e                   	pop    %esi
  800ac1:	5f                   	pop    %edi
  800ac2:	5d                   	pop    %ebp
  800ac3:	c3                   	ret    

00800ac4 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ac4:	55                   	push   %ebp
  800ac5:	89 e5                	mov    %esp,%ebp
  800ac7:	57                   	push   %edi
  800ac8:	56                   	push   %esi
  800ac9:	53                   	push   %ebx
  800aca:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800acd:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ad2:	b8 03 00 00 00       	mov    $0x3,%eax
  800ad7:	8b 55 08             	mov    0x8(%ebp),%edx
  800ada:	89 cb                	mov    %ecx,%ebx
  800adc:	89 cf                	mov    %ecx,%edi
  800ade:	89 ce                	mov    %ecx,%esi
  800ae0:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800ae2:	85 c0                	test   %eax,%eax
  800ae4:	7e 17                	jle    800afd <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ae6:	83 ec 0c             	sub    $0xc,%esp
  800ae9:	50                   	push   %eax
  800aea:	6a 03                	push   $0x3
  800aec:	68 40 10 80 00       	push   $0x801040
  800af1:	6a 23                	push   $0x23
  800af3:	68 5d 10 80 00       	push   $0x80105d
  800af8:	e8 27 00 00 00       	call   800b24 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800afd:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b00:	5b                   	pop    %ebx
  800b01:	5e                   	pop    %esi
  800b02:	5f                   	pop    %edi
  800b03:	5d                   	pop    %ebp
  800b04:	c3                   	ret    

00800b05 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b05:	55                   	push   %ebp
  800b06:	89 e5                	mov    %esp,%ebp
  800b08:	57                   	push   %edi
  800b09:	56                   	push   %esi
  800b0a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b0b:	ba 00 00 00 00       	mov    $0x0,%edx
  800b10:	b8 02 00 00 00       	mov    $0x2,%eax
  800b15:	89 d1                	mov    %edx,%ecx
  800b17:	89 d3                	mov    %edx,%ebx
  800b19:	89 d7                	mov    %edx,%edi
  800b1b:	89 d6                	mov    %edx,%esi
  800b1d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b1f:	5b                   	pop    %ebx
  800b20:	5e                   	pop    %esi
  800b21:	5f                   	pop    %edi
  800b22:	5d                   	pop    %ebp
  800b23:	c3                   	ret    

00800b24 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800b24:	55                   	push   %ebp
  800b25:	89 e5                	mov    %esp,%ebp
  800b27:	56                   	push   %esi
  800b28:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800b29:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800b2c:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800b32:	e8 ce ff ff ff       	call   800b05 <sys_getenvid>
  800b37:	83 ec 0c             	sub    $0xc,%esp
  800b3a:	ff 75 0c             	pushl  0xc(%ebp)
  800b3d:	ff 75 08             	pushl  0x8(%ebp)
  800b40:	56                   	push   %esi
  800b41:	50                   	push   %eax
  800b42:	68 6c 10 80 00       	push   $0x80106c
  800b47:	e8 f0 f5 ff ff       	call   80013c <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800b4c:	83 c4 18             	add    $0x18,%esp
  800b4f:	53                   	push   %ebx
  800b50:	ff 75 10             	pushl  0x10(%ebp)
  800b53:	e8 93 f5 ff ff       	call   8000eb <vcprintf>
	cprintf("\n");
  800b58:	c7 04 24 1c 0e 80 00 	movl   $0x800e1c,(%esp)
  800b5f:	e8 d8 f5 ff ff       	call   80013c <cprintf>
  800b64:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b67:	cc                   	int3   
  800b68:	eb fd                	jmp    800b67 <_panic+0x43>
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
