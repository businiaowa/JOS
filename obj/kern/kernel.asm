
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 20 19 10 f0       	push   $0xf0101920
f0100050:	e8 4b 09 00 00       	call   f01009a0 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 fc 06 00 00       	call   f0100777 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 3c 19 10 f0       	push   $0xf010193c
f0100087:	e8 14 09 00 00       	call   f01009a0 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 d8 13 00 00       	call   f0101489 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8f 04 00 00       	call   f0100545 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 57 19 10 f0       	push   $0xf0101957
f01000c3:	e8 d8 08 00 00       	call   f01009a0 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 52 07 00 00       	call   f0100833 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 72 19 10 f0       	push   $0xf0101972
f0100110:	e8 8b 08 00 00       	call   f01009a0 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 5b 08 00 00       	call   f010097a <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ae 19 10 f0 	movl   $0xf01019ae,(%esp)
f0100126:	e8 75 08 00 00       	call   f01009a0 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 fb 06 00 00       	call   f0100833 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 8a 19 10 f0       	push   $0xf010198a
f0100152:	e8 49 08 00 00       	call   f01009a0 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 17 08 00 00       	call   f010097a <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ae 19 10 f0 	movl   $0xf01019ae,(%esp)
f010016a:	e8 31 08 00 00       	call   f01009a0 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f0 00 00 00    	je     f01002d7 <kbd_proc_data+0xfe>
f01001e7:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ec:	ec                   	in     (%dx),%al
f01001ed:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ef:	3c e0                	cmp    $0xe0,%al
f01001f1:	75 0d                	jne    f0100200 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001f3:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001fa:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001ff:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100200:	55                   	push   %ebp
f0100201:	89 e5                	mov    %esp,%ebp
f0100203:	53                   	push   %ebx
f0100204:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100207:	84 c0                	test   %al,%al
f0100209:	79 36                	jns    f0100241 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010020b:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100211:	89 cb                	mov    %ecx,%ebx
f0100213:	83 e3 40             	and    $0x40,%ebx
f0100216:	83 e0 7f             	and    $0x7f,%eax
f0100219:	85 db                	test   %ebx,%ebx
f010021b:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010021e:	0f b6 d2             	movzbl %dl,%edx
f0100221:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f0100228:	83 c8 40             	or     $0x40,%eax
f010022b:	0f b6 c0             	movzbl %al,%eax
f010022e:	f7 d0                	not    %eax
f0100230:	21 c8                	and    %ecx,%eax
f0100232:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100237:	b8 00 00 00 00       	mov    $0x0,%eax
f010023c:	e9 9e 00 00 00       	jmp    f01002df <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100241:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100247:	f6 c1 40             	test   $0x40,%cl
f010024a:	74 0e                	je     f010025a <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010024c:	83 c8 80             	or     $0xffffff80,%eax
f010024f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100251:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100254:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010025a:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010025d:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f0100264:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f010026a:	0f b6 8a 00 1a 10 f0 	movzbl -0xfefe600(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d e0 19 10 f0 	mov    -0xfefe620(,%ecx,4),%ecx
f0100284:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100288:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010028b:	a8 08                	test   $0x8,%al
f010028d:	74 1b                	je     f01002aa <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f010028f:	89 da                	mov    %ebx,%edx
f0100291:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100294:	83 f9 19             	cmp    $0x19,%ecx
f0100297:	77 05                	ja     f010029e <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100299:	83 eb 20             	sub    $0x20,%ebx
f010029c:	eb 0c                	jmp    f01002aa <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010029e:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a1:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a4:	83 fa 19             	cmp    $0x19,%edx
f01002a7:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002aa:	f7 d0                	not    %eax
f01002ac:	a8 06                	test   $0x6,%al
f01002ae:	75 2d                	jne    f01002dd <kbd_proc_data+0x104>
f01002b0:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002b6:	75 25                	jne    f01002dd <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b8:	83 ec 0c             	sub    $0xc,%esp
f01002bb:	68 a4 19 10 f0       	push   $0xf01019a4
f01002c0:	e8 db 06 00 00       	call   f01009a0 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c5:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ca:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cf:	ee                   	out    %al,(%dx)
f01002d0:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
f01002d5:	eb 08                	jmp    f01002df <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002dc:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002dd:	89 d8                	mov    %ebx,%eax
}
f01002df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e2:	c9                   	leave  
f01002e3:	c3                   	ret    

f01002e4 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e4:	55                   	push   %ebp
f01002e5:	89 e5                	mov    %esp,%ebp
f01002e7:	57                   	push   %edi
f01002e8:	56                   	push   %esi
f01002e9:	53                   	push   %ebx
f01002ea:	83 ec 1c             	sub    $0x1c,%esp
f01002ed:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ef:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f4:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002f9:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fe:	eb 09                	jmp    f0100309 <cons_putc+0x25>
f0100300:	89 ca                	mov    %ecx,%edx
f0100302:	ec                   	in     (%dx),%al
f0100303:	ec                   	in     (%dx),%al
f0100304:	ec                   	in     (%dx),%al
f0100305:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100306:	83 c3 01             	add    $0x1,%ebx
f0100309:	89 f2                	mov    %esi,%edx
f010030b:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010030c:	a8 20                	test   $0x20,%al
f010030e:	75 08                	jne    f0100318 <cons_putc+0x34>
f0100310:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100316:	7e e8                	jle    f0100300 <cons_putc+0x1c>
f0100318:	89 f8                	mov    %edi,%eax
f010031a:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100322:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100323:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 09                	jmp    f010033d <cons_putc+0x59>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	83 c3 01             	add    $0x1,%ebx
f010033d:	89 f2                	mov    %esi,%edx
f010033f:	ec                   	in     (%dx),%al
f0100340:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100346:	7f 04                	jg     f010034c <cons_putc+0x68>
f0100348:	84 c0                	test   %al,%al
f010034a:	79 e8                	jns    f0100334 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100351:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100355:	ee                   	out    %al,(%dx)
f0100356:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010035b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100360:	ee                   	out    %al,(%dx)
f0100361:	b8 08 00 00 00       	mov    $0x8,%eax
f0100366:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100367:	89 fa                	mov    %edi,%edx
f0100369:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010036f:	89 f8                	mov    %edi,%eax
f0100371:	80 cc 07             	or     $0x7,%ah
f0100374:	85 d2                	test   %edx,%edx
f0100376:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100379:	89 f8                	mov    %edi,%eax
f010037b:	0f b6 c0             	movzbl %al,%eax
f010037e:	83 f8 09             	cmp    $0x9,%eax
f0100381:	74 74                	je     f01003f7 <cons_putc+0x113>
f0100383:	83 f8 09             	cmp    $0x9,%eax
f0100386:	7f 0a                	jg     f0100392 <cons_putc+0xae>
f0100388:	83 f8 08             	cmp    $0x8,%eax
f010038b:	74 14                	je     f01003a1 <cons_putc+0xbd>
f010038d:	e9 99 00 00 00       	jmp    f010042b <cons_putc+0x147>
f0100392:	83 f8 0a             	cmp    $0xa,%eax
f0100395:	74 3a                	je     f01003d1 <cons_putc+0xed>
f0100397:	83 f8 0d             	cmp    $0xd,%eax
f010039a:	74 3d                	je     f01003d9 <cons_putc+0xf5>
f010039c:	e9 8a 00 00 00       	jmp    f010042b <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003a1:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003a8:	66 85 c0             	test   %ax,%ax
f01003ab:	0f 84 e6 00 00 00    	je     f0100497 <cons_putc+0x1b3>
			crt_pos--;
f01003b1:	83 e8 01             	sub    $0x1,%eax
f01003b4:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003ba:	0f b7 c0             	movzwl %ax,%eax
f01003bd:	66 81 e7 00 ff       	and    $0xff00,%di
f01003c2:	83 cf 20             	or     $0x20,%edi
f01003c5:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cf:	eb 78                	jmp    f0100449 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003d1:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003d8:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d9:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003e0:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e6:	c1 e8 16             	shr    $0x16,%eax
f01003e9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003ec:	c1 e0 04             	shl    $0x4,%eax
f01003ef:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f01003f5:	eb 52                	jmp    f0100449 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fc:	e8 e3 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100401:	b8 20 00 00 00       	mov    $0x20,%eax
f0100406:	e8 d9 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010040b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100410:	e8 cf fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100415:	b8 20 00 00 00       	mov    $0x20,%eax
f010041a:	e8 c5 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010041f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100424:	e8 bb fe ff ff       	call   f01002e4 <cons_putc>
f0100429:	eb 1e                	jmp    f0100449 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010042b:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100432:	8d 50 01             	lea    0x1(%eax),%edx
f0100435:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010043c:	0f b7 c0             	movzwl %ax,%eax
f010043f:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100445:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100449:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100450:	cf 07 
f0100452:	76 43                	jbe    f0100497 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100454:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100459:	83 ec 04             	sub    $0x4,%esp
f010045c:	68 00 0f 00 00       	push   $0xf00
f0100461:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100467:	52                   	push   %edx
f0100468:	50                   	push   %eax
f0100469:	e8 68 10 00 00       	call   f01014d6 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100474:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010047a:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100480:	83 c4 10             	add    $0x10,%esp
f0100483:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100488:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010048b:	39 d0                	cmp    %edx,%eax
f010048d:	75 f4                	jne    f0100483 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010048f:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f0100496:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100497:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f010049d:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004a2:	89 ca                	mov    %ecx,%edx
f01004a4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a5:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ac:	8d 71 01             	lea    0x1(%ecx),%esi
f01004af:	89 d8                	mov    %ebx,%eax
f01004b1:	66 c1 e8 08          	shr    $0x8,%ax
f01004b5:	89 f2                	mov    %esi,%edx
f01004b7:	ee                   	out    %al,(%dx)
f01004b8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004bd:	89 ca                	mov    %ecx,%edx
f01004bf:	ee                   	out    %al,(%dx)
f01004c0:	89 d8                	mov    %ebx,%eax
f01004c2:	89 f2                	mov    %esi,%edx
f01004c4:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c8:	5b                   	pop    %ebx
f01004c9:	5e                   	pop    %esi
f01004ca:	5f                   	pop    %edi
f01004cb:	5d                   	pop    %ebp
f01004cc:	c3                   	ret    

f01004cd <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004cd:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004d4:	74 11                	je     f01004e7 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d6:	55                   	push   %ebp
f01004d7:	89 e5                	mov    %esp,%ebp
f01004d9:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004dc:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004e1:	e8 b0 fc ff ff       	call   f0100196 <cons_intr>
}
f01004e6:	c9                   	leave  
f01004e7:	f3 c3                	repz ret 

f01004e9 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e9:	55                   	push   %ebp
f01004ea:	89 e5                	mov    %esp,%ebp
f01004ec:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ef:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f01004f4:	e8 9d fc ff ff       	call   f0100196 <cons_intr>
}
f01004f9:	c9                   	leave  
f01004fa:	c3                   	ret    

f01004fb <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100501:	e8 c7 ff ff ff       	call   f01004cd <serial_intr>
	kbd_intr();
f0100506:	e8 de ff ff ff       	call   f01004e9 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010050b:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100510:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100516:	74 26                	je     f010053e <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100518:	8d 50 01             	lea    0x1(%eax),%edx
f010051b:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100521:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100528:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010052a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100530:	75 11                	jne    f0100543 <cons_getc+0x48>
			cons.rpos = 0;
f0100532:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100539:	00 00 00 
f010053c:	eb 05                	jmp    f0100543 <cons_getc+0x48>
		return c;
	}
	return 0;
f010053e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	57                   	push   %edi
f0100549:	56                   	push   %esi
f010054a:	53                   	push   %ebx
f010054b:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054e:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100555:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010055c:	5a a5 
	if (*cp != 0xA55A) {
f010055e:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100565:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100569:	74 11                	je     f010057c <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010056b:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100572:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100575:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010057a:	eb 16                	jmp    f0100592 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010057c:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100583:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f010058a:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010058d:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100592:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f0100598:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059d:	89 fa                	mov    %edi,%edx
f010059f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005a0:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a3:	89 da                	mov    %ebx,%edx
f01005a5:	ec                   	in     (%dx),%al
f01005a6:	0f b6 c8             	movzbl %al,%ecx
f01005a9:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ac:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b1:	89 fa                	mov    %edi,%edx
f01005b3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b4:	89 da                	mov    %ebx,%edx
f01005b6:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005b7:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005bd:	0f b6 c0             	movzbl %al,%eax
f01005c0:	09 c8                	or     %ecx,%eax
f01005c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c8:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d2:	89 f2                	mov    %esi,%edx
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005da:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005df:	ee                   	out    %al,(%dx)
f01005e0:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005e5:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005fd:	b8 03 00 00 00       	mov    $0x3,%eax
f0100602:	ee                   	out    %al,(%dx)
f0100603:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100608:	b8 00 00 00 00       	mov    $0x0,%eax
f010060d:	ee                   	out    %al,(%dx)
f010060e:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100613:	b8 01 00 00 00       	mov    $0x1,%eax
f0100618:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100619:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010061e:	ec                   	in     (%dx),%al
f010061f:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100621:	3c ff                	cmp    $0xff,%al
f0100623:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f010062a:	89 f2                	mov    %esi,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 da                	mov    %ebx,%edx
f010062f:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100630:	80 f9 ff             	cmp    $0xff,%cl
f0100633:	75 10                	jne    f0100645 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100635:	83 ec 0c             	sub    $0xc,%esp
f0100638:	68 b0 19 10 f0       	push   $0xf01019b0
f010063d:	e8 5e 03 00 00       	call   f01009a0 <cprintf>
f0100642:	83 c4 10             	add    $0x10,%esp
}
f0100645:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100648:	5b                   	pop    %ebx
f0100649:	5e                   	pop    %esi
f010064a:	5f                   	pop    %edi
f010064b:	5d                   	pop    %ebp
f010064c:	c3                   	ret    

f010064d <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064d:	55                   	push   %ebp
f010064e:	89 e5                	mov    %esp,%ebp
f0100650:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100653:	8b 45 08             	mov    0x8(%ebp),%eax
f0100656:	e8 89 fc ff ff       	call   f01002e4 <cons_putc>
}
f010065b:	c9                   	leave  
f010065c:	c3                   	ret    

f010065d <getchar>:

int
getchar(void)
{
f010065d:	55                   	push   %ebp
f010065e:	89 e5                	mov    %esp,%ebp
f0100660:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100663:	e8 93 fe ff ff       	call   f01004fb <cons_getc>
f0100668:	85 c0                	test   %eax,%eax
f010066a:	74 f7                	je     f0100663 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010066c:	c9                   	leave  
f010066d:	c3                   	ret    

f010066e <iscons>:

int
iscons(int fdnum)
{
f010066e:	55                   	push   %ebp
f010066f:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100671:	b8 01 00 00 00       	mov    $0x1,%eax
f0100676:	5d                   	pop    %ebp
f0100677:	c3                   	ret    

f0100678 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010067e:	68 00 1c 10 f0       	push   $0xf0101c00
f0100683:	68 1e 1c 10 f0       	push   $0xf0101c1e
f0100688:	68 23 1c 10 f0       	push   $0xf0101c23
f010068d:	e8 0e 03 00 00       	call   f01009a0 <cprintf>
f0100692:	83 c4 0c             	add    $0xc,%esp
f0100695:	68 c0 1c 10 f0       	push   $0xf0101cc0
f010069a:	68 2c 1c 10 f0       	push   $0xf0101c2c
f010069f:	68 23 1c 10 f0       	push   $0xf0101c23
f01006a4:	e8 f7 02 00 00       	call   f01009a0 <cprintf>
f01006a9:	83 c4 0c             	add    $0xc,%esp
f01006ac:	68 e8 1c 10 f0       	push   $0xf0101ce8
f01006b1:	68 35 1c 10 f0       	push   $0xf0101c35
f01006b6:	68 23 1c 10 f0       	push   $0xf0101c23
f01006bb:	e8 e0 02 00 00       	call   f01009a0 <cprintf>
	return 0;
}
f01006c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c5:	c9                   	leave  
f01006c6:	c3                   	ret    

f01006c7 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c7:	55                   	push   %ebp
f01006c8:	89 e5                	mov    %esp,%ebp
f01006ca:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006cd:	68 3f 1c 10 f0       	push   $0xf0101c3f
f01006d2:	e8 c9 02 00 00       	call   f01009a0 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d7:	83 c4 08             	add    $0x8,%esp
f01006da:	68 0c 00 10 00       	push   $0x10000c
f01006df:	68 0c 1d 10 f0       	push   $0xf0101d0c
f01006e4:	e8 b7 02 00 00       	call   f01009a0 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e9:	83 c4 0c             	add    $0xc,%esp
f01006ec:	68 0c 00 10 00       	push   $0x10000c
f01006f1:	68 0c 00 10 f0       	push   $0xf010000c
f01006f6:	68 34 1d 10 f0       	push   $0xf0101d34
f01006fb:	e8 a0 02 00 00       	call   f01009a0 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100700:	83 c4 0c             	add    $0xc,%esp
f0100703:	68 11 19 10 00       	push   $0x101911
f0100708:	68 11 19 10 f0       	push   $0xf0101911
f010070d:	68 58 1d 10 f0       	push   $0xf0101d58
f0100712:	e8 89 02 00 00       	call   f01009a0 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100717:	83 c4 0c             	add    $0xc,%esp
f010071a:	68 00 23 11 00       	push   $0x112300
f010071f:	68 00 23 11 f0       	push   $0xf0112300
f0100724:	68 7c 1d 10 f0       	push   $0xf0101d7c
f0100729:	e8 72 02 00 00       	call   f01009a0 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010072e:	83 c4 0c             	add    $0xc,%esp
f0100731:	68 44 29 11 00       	push   $0x112944
f0100736:	68 44 29 11 f0       	push   $0xf0112944
f010073b:	68 a0 1d 10 f0       	push   $0xf0101da0
f0100740:	e8 5b 02 00 00       	call   f01009a0 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100745:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010074a:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010074f:	83 c4 08             	add    $0x8,%esp
f0100752:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100757:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010075d:	85 c0                	test   %eax,%eax
f010075f:	0f 48 c2             	cmovs  %edx,%eax
f0100762:	c1 f8 0a             	sar    $0xa,%eax
f0100765:	50                   	push   %eax
f0100766:	68 c4 1d 10 f0       	push   $0xf0101dc4
f010076b:	e8 30 02 00 00       	call   f01009a0 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100770:	b8 00 00 00 00       	mov    $0x0,%eax
f0100775:	c9                   	leave  
f0100776:	c3                   	ret    

f0100777 <mon_backtrace>:
#define EIP(v)  ((uint32_t)*(v+1))
#define ARG(v, c) ((uint32_t)*((v)+(c)+2))

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100777:	55                   	push   %ebp
f0100778:	89 e5                	mov    %esp,%ebp
f010077a:	57                   	push   %edi
f010077b:	56                   	push   %esi
f010077c:	53                   	push   %ebx
f010077d:	81 ec 34 01 00 00    	sub    $0x134,%esp
	char format[FORMATLEN];
    char details[FORMATLEN];
    strcpy(format, "  ebp %08x  eip  %08x  args %08x %08x %08x %08x %08x\n");
f0100783:	68 f0 1d 10 f0       	push   $0xf0101df0
f0100788:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f010078e:	50                   	push   %eax
f010078f:	e8 b0 0b 00 00       	call   f0101344 <strcpy>
    strcpy(details, "       %s:%d: %.*s+%d\n");
f0100794:	83 c4 08             	add    $0x8,%esp
f0100797:	68 58 1c 10 f0       	push   $0xf0101c58
f010079c:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
f01007a2:	50                   	push   %eax
f01007a3:	e8 9c 0b 00 00       	call   f0101344 <strcpy>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007a8:	89 eb                	mov    %ebp,%ebx
    
    uint32_t *ebpAddr = (uint32_t *) read_ebp();
    struct Eipdebuginfo info;
    
    cprintf("Stack backtrace:\n");
f01007aa:	c7 04 24 6f 1c 10 f0 	movl   $0xf0101c6f,(%esp)
f01007b1:	e8 ea 01 00 00       	call   f01009a0 <cprintf>
    while (ebpAddr) {
f01007b6:	83 c4 10             	add    $0x10,%esp
        debuginfo_eip(EIP(ebpAddr), &info);
f01007b9:	8d bd d0 fe ff ff    	lea    -0x130(%ebp),%edi

        cprintf(format, EBP(ebpAddr), EIP(ebpAddr), ARG(ebpAddr, 0), ARG(ebpAddr, 1), ARG(ebpAddr, 2), ARG(ebpAddr, 3), ARG(ebpAddr, 4));
f01007bf:	8d b5 68 ff ff ff    	lea    -0x98(%ebp),%esi
    
    uint32_t *ebpAddr = (uint32_t *) read_ebp();
    struct Eipdebuginfo info;
    
    cprintf("Stack backtrace:\n");
    while (ebpAddr) {
f01007c5:	eb 5b                	jmp    f0100822 <mon_backtrace+0xab>
        debuginfo_eip(EIP(ebpAddr), &info);
f01007c7:	83 ec 08             	sub    $0x8,%esp
f01007ca:	57                   	push   %edi
f01007cb:	ff 73 04             	pushl  0x4(%ebx)
f01007ce:	e8 d7 02 00 00       	call   f0100aaa <debuginfo_eip>

        cprintf(format, EBP(ebpAddr), EIP(ebpAddr), ARG(ebpAddr, 0), ARG(ebpAddr, 1), ARG(ebpAddr, 2), ARG(ebpAddr, 3), ARG(ebpAddr, 4));
f01007d3:	ff 73 18             	pushl  0x18(%ebx)
f01007d6:	ff 73 14             	pushl  0x14(%ebx)
f01007d9:	ff 73 10             	pushl  0x10(%ebx)
f01007dc:	ff 73 0c             	pushl  0xc(%ebx)
f01007df:	ff 73 08             	pushl  0x8(%ebx)
f01007e2:	ff 73 04             	pushl  0x4(%ebx)
f01007e5:	53                   	push   %ebx
f01007e6:	56                   	push   %esi
f01007e7:	e8 b4 01 00 00       	call   f01009a0 <cprintf>
        cprintf(details, info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, EIP(ebpAddr)-info.eip_fn_addr);
f01007ec:	83 c4 28             	add    $0x28,%esp
f01007ef:	8b 43 04             	mov    0x4(%ebx),%eax
f01007f2:	2b 85 e0 fe ff ff    	sub    -0x120(%ebp),%eax
f01007f8:	50                   	push   %eax
f01007f9:	ff b5 d8 fe ff ff    	pushl  -0x128(%ebp)
f01007ff:	ff b5 dc fe ff ff    	pushl  -0x124(%ebp)
f0100805:	ff b5 d4 fe ff ff    	pushl  -0x12c(%ebp)
f010080b:	ff b5 d0 fe ff ff    	pushl  -0x130(%ebp)
f0100811:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
f0100817:	50                   	push   %eax
f0100818:	e8 83 01 00 00       	call   f01009a0 <cprintf>
        ebpAddr = (uint32_t *)(*ebpAddr);
f010081d:	8b 1b                	mov    (%ebx),%ebx
f010081f:	83 c4 20             	add    $0x20,%esp
    
    uint32_t *ebpAddr = (uint32_t *) read_ebp();
    struct Eipdebuginfo info;
    
    cprintf("Stack backtrace:\n");
    while (ebpAddr) {
f0100822:	85 db                	test   %ebx,%ebx
f0100824:	75 a1                	jne    f01007c7 <mon_backtrace+0x50>
        cprintf(details, info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, EIP(ebpAddr)-info.eip_fn_addr);
        ebpAddr = (uint32_t *)(*ebpAddr);
    }

	return 0;
}
f0100826:	b8 00 00 00 00       	mov    $0x0,%eax
f010082b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010082e:	5b                   	pop    %ebx
f010082f:	5e                   	pop    %esi
f0100830:	5f                   	pop    %edi
f0100831:	5d                   	pop    %ebp
f0100832:	c3                   	ret    

f0100833 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100833:	55                   	push   %ebp
f0100834:	89 e5                	mov    %esp,%ebp
f0100836:	57                   	push   %edi
f0100837:	56                   	push   %esi
f0100838:	53                   	push   %ebx
f0100839:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010083c:	68 28 1e 10 f0       	push   $0xf0101e28
f0100841:	e8 5a 01 00 00       	call   f01009a0 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100846:	c7 04 24 4c 1e 10 f0 	movl   $0xf0101e4c,(%esp)
f010084d:	e8 4e 01 00 00       	call   f01009a0 <cprintf>
f0100852:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100855:	83 ec 0c             	sub    $0xc,%esp
f0100858:	68 81 1c 10 f0       	push   $0xf0101c81
f010085d:	e8 d0 09 00 00       	call   f0101232 <readline>
f0100862:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100864:	83 c4 10             	add    $0x10,%esp
f0100867:	85 c0                	test   %eax,%eax
f0100869:	74 ea                	je     f0100855 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010086b:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100872:	be 00 00 00 00       	mov    $0x0,%esi
f0100877:	eb 0a                	jmp    f0100883 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100879:	c6 03 00             	movb   $0x0,(%ebx)
f010087c:	89 f7                	mov    %esi,%edi
f010087e:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100881:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100883:	0f b6 03             	movzbl (%ebx),%eax
f0100886:	84 c0                	test   %al,%al
f0100888:	74 63                	je     f01008ed <monitor+0xba>
f010088a:	83 ec 08             	sub    $0x8,%esp
f010088d:	0f be c0             	movsbl %al,%eax
f0100890:	50                   	push   %eax
f0100891:	68 85 1c 10 f0       	push   $0xf0101c85
f0100896:	e8 b1 0b 00 00       	call   f010144c <strchr>
f010089b:	83 c4 10             	add    $0x10,%esp
f010089e:	85 c0                	test   %eax,%eax
f01008a0:	75 d7                	jne    f0100879 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01008a2:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008a5:	74 46                	je     f01008ed <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008a7:	83 fe 0f             	cmp    $0xf,%esi
f01008aa:	75 14                	jne    f01008c0 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008ac:	83 ec 08             	sub    $0x8,%esp
f01008af:	6a 10                	push   $0x10
f01008b1:	68 8a 1c 10 f0       	push   $0xf0101c8a
f01008b6:	e8 e5 00 00 00       	call   f01009a0 <cprintf>
f01008bb:	83 c4 10             	add    $0x10,%esp
f01008be:	eb 95                	jmp    f0100855 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01008c0:	8d 7e 01             	lea    0x1(%esi),%edi
f01008c3:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008c7:	eb 03                	jmp    f01008cc <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008c9:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008cc:	0f b6 03             	movzbl (%ebx),%eax
f01008cf:	84 c0                	test   %al,%al
f01008d1:	74 ae                	je     f0100881 <monitor+0x4e>
f01008d3:	83 ec 08             	sub    $0x8,%esp
f01008d6:	0f be c0             	movsbl %al,%eax
f01008d9:	50                   	push   %eax
f01008da:	68 85 1c 10 f0       	push   $0xf0101c85
f01008df:	e8 68 0b 00 00       	call   f010144c <strchr>
f01008e4:	83 c4 10             	add    $0x10,%esp
f01008e7:	85 c0                	test   %eax,%eax
f01008e9:	74 de                	je     f01008c9 <monitor+0x96>
f01008eb:	eb 94                	jmp    f0100881 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008ed:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008f4:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008f5:	85 f6                	test   %esi,%esi
f01008f7:	0f 84 58 ff ff ff    	je     f0100855 <monitor+0x22>
f01008fd:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100902:	83 ec 08             	sub    $0x8,%esp
f0100905:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100908:	ff 34 85 80 1e 10 f0 	pushl  -0xfefe180(,%eax,4)
f010090f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100912:	e8 d7 0a 00 00       	call   f01013ee <strcmp>
f0100917:	83 c4 10             	add    $0x10,%esp
f010091a:	85 c0                	test   %eax,%eax
f010091c:	75 21                	jne    f010093f <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f010091e:	83 ec 04             	sub    $0x4,%esp
f0100921:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100924:	ff 75 08             	pushl  0x8(%ebp)
f0100927:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010092a:	52                   	push   %edx
f010092b:	56                   	push   %esi
f010092c:	ff 14 85 88 1e 10 f0 	call   *-0xfefe178(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	85 c0                	test   %eax,%eax
f0100938:	78 25                	js     f010095f <monitor+0x12c>
f010093a:	e9 16 ff ff ff       	jmp    f0100855 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010093f:	83 c3 01             	add    $0x1,%ebx
f0100942:	83 fb 03             	cmp    $0x3,%ebx
f0100945:	75 bb                	jne    f0100902 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100947:	83 ec 08             	sub    $0x8,%esp
f010094a:	ff 75 a8             	pushl  -0x58(%ebp)
f010094d:	68 a7 1c 10 f0       	push   $0xf0101ca7
f0100952:	e8 49 00 00 00       	call   f01009a0 <cprintf>
f0100957:	83 c4 10             	add    $0x10,%esp
f010095a:	e9 f6 fe ff ff       	jmp    f0100855 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010095f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100962:	5b                   	pop    %ebx
f0100963:	5e                   	pop    %esi
f0100964:	5f                   	pop    %edi
f0100965:	5d                   	pop    %ebp
f0100966:	c3                   	ret    

f0100967 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100967:	55                   	push   %ebp
f0100968:	89 e5                	mov    %esp,%ebp
f010096a:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010096d:	ff 75 08             	pushl  0x8(%ebp)
f0100970:	e8 d8 fc ff ff       	call   f010064d <cputchar>
	*cnt++;
}
f0100975:	83 c4 10             	add    $0x10,%esp
f0100978:	c9                   	leave  
f0100979:	c3                   	ret    

f010097a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010097a:	55                   	push   %ebp
f010097b:	89 e5                	mov    %esp,%ebp
f010097d:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100980:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100987:	ff 75 0c             	pushl  0xc(%ebp)
f010098a:	ff 75 08             	pushl  0x8(%ebp)
f010098d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100990:	50                   	push   %eax
f0100991:	68 67 09 10 f0       	push   $0xf0100967
f0100996:	e8 c9 03 00 00       	call   f0100d64 <vprintfmt>
	return cnt;
}
f010099b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010099e:	c9                   	leave  
f010099f:	c3                   	ret    

f01009a0 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009a0:	55                   	push   %ebp
f01009a1:	89 e5                	mov    %esp,%ebp
f01009a3:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009a6:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009a9:	50                   	push   %eax
f01009aa:	ff 75 08             	pushl  0x8(%ebp)
f01009ad:	e8 c8 ff ff ff       	call   f010097a <vcprintf>
	va_end(ap);

	return cnt;
}
f01009b2:	c9                   	leave  
f01009b3:	c3                   	ret    

f01009b4 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009b4:	55                   	push   %ebp
f01009b5:	89 e5                	mov    %esp,%ebp
f01009b7:	57                   	push   %edi
f01009b8:	56                   	push   %esi
f01009b9:	53                   	push   %ebx
f01009ba:	83 ec 14             	sub    $0x14,%esp
f01009bd:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009c0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01009c3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009c6:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009c9:	8b 1a                	mov    (%edx),%ebx
f01009cb:	8b 01                	mov    (%ecx),%eax
f01009cd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009d0:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009d7:	eb 7f                	jmp    f0100a58 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01009d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009dc:	01 d8                	add    %ebx,%eax
f01009de:	89 c6                	mov    %eax,%esi
f01009e0:	c1 ee 1f             	shr    $0x1f,%esi
f01009e3:	01 c6                	add    %eax,%esi
f01009e5:	d1 fe                	sar    %esi
f01009e7:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009ea:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009ed:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009f0:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009f2:	eb 03                	jmp    f01009f7 <stab_binsearch+0x43>
			m--;
f01009f4:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009f7:	39 c3                	cmp    %eax,%ebx
f01009f9:	7f 0d                	jg     f0100a08 <stab_binsearch+0x54>
f01009fb:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009ff:	83 ea 0c             	sub    $0xc,%edx
f0100a02:	39 f9                	cmp    %edi,%ecx
f0100a04:	75 ee                	jne    f01009f4 <stab_binsearch+0x40>
f0100a06:	eb 05                	jmp    f0100a0d <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a08:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a0b:	eb 4b                	jmp    f0100a58 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a0d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a10:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a13:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a17:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a1a:	76 11                	jbe    f0100a2d <stab_binsearch+0x79>
			*region_left = m;
f0100a1c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a1f:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a21:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a24:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a2b:	eb 2b                	jmp    f0100a58 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a2d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a30:	73 14                	jae    f0100a46 <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a32:	83 e8 01             	sub    $0x1,%eax
f0100a35:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a38:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a3b:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a3d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a44:	eb 12                	jmp    f0100a58 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a46:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a49:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a4b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a4f:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a51:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a58:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a5b:	0f 8e 78 ff ff ff    	jle    f01009d9 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a61:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a65:	75 0f                	jne    f0100a76 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a67:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a6a:	8b 00                	mov    (%eax),%eax
f0100a6c:	83 e8 01             	sub    $0x1,%eax
f0100a6f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a72:	89 06                	mov    %eax,(%esi)
f0100a74:	eb 2c                	jmp    f0100aa2 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a76:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a79:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a7b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a7e:	8b 0e                	mov    (%esi),%ecx
f0100a80:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a83:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a86:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a89:	eb 03                	jmp    f0100a8e <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a8b:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a8e:	39 c8                	cmp    %ecx,%eax
f0100a90:	7e 0b                	jle    f0100a9d <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a92:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a96:	83 ea 0c             	sub    $0xc,%edx
f0100a99:	39 df                	cmp    %ebx,%edi
f0100a9b:	75 ee                	jne    f0100a8b <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a9d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100aa0:	89 06                	mov    %eax,(%esi)
	}
}
f0100aa2:	83 c4 14             	add    $0x14,%esp
f0100aa5:	5b                   	pop    %ebx
f0100aa6:	5e                   	pop    %esi
f0100aa7:	5f                   	pop    %edi
f0100aa8:	5d                   	pop    %ebp
f0100aa9:	c3                   	ret    

f0100aaa <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100aaa:	55                   	push   %ebp
f0100aab:	89 e5                	mov    %esp,%ebp
f0100aad:	57                   	push   %edi
f0100aae:	56                   	push   %esi
f0100aaf:	53                   	push   %ebx
f0100ab0:	83 ec 1c             	sub    $0x1c,%esp
f0100ab3:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100ab6:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ab9:	c7 06 a4 1e 10 f0    	movl   $0xf0101ea4,(%esi)
	info->eip_line = 0;
f0100abf:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100ac6:	c7 46 08 a4 1e 10 f0 	movl   $0xf0101ea4,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100acd:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100ad4:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100ad7:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ade:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100ae4:	76 11                	jbe    f0100af7 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ae6:	b8 b2 73 10 f0       	mov    $0xf01073b2,%eax
f0100aeb:	3d 99 5a 10 f0       	cmp    $0xf0105a99,%eax
f0100af0:	77 19                	ja     f0100b0b <debuginfo_eip+0x61>
f0100af2:	e9 62 01 00 00       	jmp    f0100c59 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100af7:	83 ec 04             	sub    $0x4,%esp
f0100afa:	68 ae 1e 10 f0       	push   $0xf0101eae
f0100aff:	6a 7f                	push   $0x7f
f0100b01:	68 bb 1e 10 f0       	push   $0xf0101ebb
f0100b06:	e8 db f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b0b:	80 3d b1 73 10 f0 00 	cmpb   $0x0,0xf01073b1
f0100b12:	0f 85 48 01 00 00    	jne    f0100c60 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b18:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b1f:	b8 98 5a 10 f0       	mov    $0xf0105a98,%eax
f0100b24:	2d f0 20 10 f0       	sub    $0xf01020f0,%eax
f0100b29:	c1 f8 02             	sar    $0x2,%eax
f0100b2c:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b32:	83 e8 01             	sub    $0x1,%eax
f0100b35:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b38:	83 ec 08             	sub    $0x8,%esp
f0100b3b:	57                   	push   %edi
f0100b3c:	6a 64                	push   $0x64
f0100b3e:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b41:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b44:	b8 f0 20 10 f0       	mov    $0xf01020f0,%eax
f0100b49:	e8 66 fe ff ff       	call   f01009b4 <stab_binsearch>
	if (lfile == 0)
f0100b4e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b51:	83 c4 10             	add    $0x10,%esp
f0100b54:	85 c0                	test   %eax,%eax
f0100b56:	0f 84 0b 01 00 00    	je     f0100c67 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b5c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b5f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b62:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b65:	83 ec 08             	sub    $0x8,%esp
f0100b68:	57                   	push   %edi
f0100b69:	6a 24                	push   $0x24
f0100b6b:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b6e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b71:	b8 f0 20 10 f0       	mov    $0xf01020f0,%eax
f0100b76:	e8 39 fe ff ff       	call   f01009b4 <stab_binsearch>

	if (lfun <= rfun) {
f0100b7b:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100b7e:	83 c4 10             	add    $0x10,%esp
f0100b81:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100b84:	7f 31                	jg     f0100bb7 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b86:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b89:	c1 e0 02             	shl    $0x2,%eax
f0100b8c:	8d 90 f0 20 10 f0    	lea    -0xfefdf10(%eax),%edx
f0100b92:	8b 88 f0 20 10 f0    	mov    -0xfefdf10(%eax),%ecx
f0100b98:	b8 b2 73 10 f0       	mov    $0xf01073b2,%eax
f0100b9d:	2d 99 5a 10 f0       	sub    $0xf0105a99,%eax
f0100ba2:	39 c1                	cmp    %eax,%ecx
f0100ba4:	73 09                	jae    f0100baf <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ba6:	81 c1 99 5a 10 f0    	add    $0xf0105a99,%ecx
f0100bac:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100baf:	8b 42 08             	mov    0x8(%edx),%eax
f0100bb2:	89 46 10             	mov    %eax,0x10(%esi)
f0100bb5:	eb 06                	jmp    f0100bbd <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bb7:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100bba:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bbd:	83 ec 08             	sub    $0x8,%esp
f0100bc0:	6a 3a                	push   $0x3a
f0100bc2:	ff 76 08             	pushl  0x8(%esi)
f0100bc5:	e8 a3 08 00 00       	call   f010146d <strfind>
f0100bca:	2b 46 08             	sub    0x8(%esi),%eax
f0100bcd:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bd0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100bd3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100bd6:	8d 04 85 f0 20 10 f0 	lea    -0xfefdf10(,%eax,4),%eax
f0100bdd:	83 c4 10             	add    $0x10,%esp
f0100be0:	eb 06                	jmp    f0100be8 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100be2:	83 eb 01             	sub    $0x1,%ebx
f0100be5:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100be8:	39 fb                	cmp    %edi,%ebx
f0100bea:	7c 34                	jl     f0100c20 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0100bec:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100bf0:	80 fa 84             	cmp    $0x84,%dl
f0100bf3:	74 0b                	je     f0100c00 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100bf5:	80 fa 64             	cmp    $0x64,%dl
f0100bf8:	75 e8                	jne    f0100be2 <debuginfo_eip+0x138>
f0100bfa:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100bfe:	74 e2                	je     f0100be2 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c00:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c03:	8b 14 85 f0 20 10 f0 	mov    -0xfefdf10(,%eax,4),%edx
f0100c0a:	b8 b2 73 10 f0       	mov    $0xf01073b2,%eax
f0100c0f:	2d 99 5a 10 f0       	sub    $0xf0105a99,%eax
f0100c14:	39 c2                	cmp    %eax,%edx
f0100c16:	73 08                	jae    f0100c20 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c18:	81 c2 99 5a 10 f0    	add    $0xf0105a99,%edx
f0100c1e:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c20:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100c23:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c26:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c2b:	39 cb                	cmp    %ecx,%ebx
f0100c2d:	7d 44                	jge    f0100c73 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0100c2f:	8d 53 01             	lea    0x1(%ebx),%edx
f0100c32:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c35:	8d 04 85 f0 20 10 f0 	lea    -0xfefdf10(,%eax,4),%eax
f0100c3c:	eb 07                	jmp    f0100c45 <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c3e:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c42:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c45:	39 ca                	cmp    %ecx,%edx
f0100c47:	74 25                	je     f0100c6e <debuginfo_eip+0x1c4>
f0100c49:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c4c:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100c50:	74 ec                	je     f0100c3e <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c52:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c57:	eb 1a                	jmp    f0100c73 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c59:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c5e:	eb 13                	jmp    f0100c73 <debuginfo_eip+0x1c9>
f0100c60:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c65:	eb 0c                	jmp    f0100c73 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c67:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c6c:	eb 05                	jmp    f0100c73 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c6e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c73:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c76:	5b                   	pop    %ebx
f0100c77:	5e                   	pop    %esi
f0100c78:	5f                   	pop    %edi
f0100c79:	5d                   	pop    %ebp
f0100c7a:	c3                   	ret    

f0100c7b <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c7b:	55                   	push   %ebp
f0100c7c:	89 e5                	mov    %esp,%ebp
f0100c7e:	57                   	push   %edi
f0100c7f:	56                   	push   %esi
f0100c80:	53                   	push   %ebx
f0100c81:	83 ec 1c             	sub    $0x1c,%esp
f0100c84:	89 c7                	mov    %eax,%edi
f0100c86:	89 d6                	mov    %edx,%esi
f0100c88:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c8b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c8e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c91:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c94:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100c97:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c9c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100c9f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100ca2:	39 d3                	cmp    %edx,%ebx
f0100ca4:	72 05                	jb     f0100cab <printnum+0x30>
f0100ca6:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100ca9:	77 45                	ja     f0100cf0 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100cab:	83 ec 0c             	sub    $0xc,%esp
f0100cae:	ff 75 18             	pushl  0x18(%ebp)
f0100cb1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cb4:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cb7:	53                   	push   %ebx
f0100cb8:	ff 75 10             	pushl  0x10(%ebp)
f0100cbb:	83 ec 08             	sub    $0x8,%esp
f0100cbe:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100cc1:	ff 75 e0             	pushl  -0x20(%ebp)
f0100cc4:	ff 75 dc             	pushl  -0x24(%ebp)
f0100cc7:	ff 75 d8             	pushl  -0x28(%ebp)
f0100cca:	e8 c1 09 00 00       	call   f0101690 <__udivdi3>
f0100ccf:	83 c4 18             	add    $0x18,%esp
f0100cd2:	52                   	push   %edx
f0100cd3:	50                   	push   %eax
f0100cd4:	89 f2                	mov    %esi,%edx
f0100cd6:	89 f8                	mov    %edi,%eax
f0100cd8:	e8 9e ff ff ff       	call   f0100c7b <printnum>
f0100cdd:	83 c4 20             	add    $0x20,%esp
f0100ce0:	eb 18                	jmp    f0100cfa <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100ce2:	83 ec 08             	sub    $0x8,%esp
f0100ce5:	56                   	push   %esi
f0100ce6:	ff 75 18             	pushl  0x18(%ebp)
f0100ce9:	ff d7                	call   *%edi
f0100ceb:	83 c4 10             	add    $0x10,%esp
f0100cee:	eb 03                	jmp    f0100cf3 <printnum+0x78>
f0100cf0:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cf3:	83 eb 01             	sub    $0x1,%ebx
f0100cf6:	85 db                	test   %ebx,%ebx
f0100cf8:	7f e8                	jg     f0100ce2 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100cfa:	83 ec 08             	sub    $0x8,%esp
f0100cfd:	56                   	push   %esi
f0100cfe:	83 ec 04             	sub    $0x4,%esp
f0100d01:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d04:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d07:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d0a:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d0d:	e8 ae 0a 00 00       	call   f01017c0 <__umoddi3>
f0100d12:	83 c4 14             	add    $0x14,%esp
f0100d15:	0f be 80 c9 1e 10 f0 	movsbl -0xfefe137(%eax),%eax
f0100d1c:	50                   	push   %eax
f0100d1d:	ff d7                	call   *%edi
}
f0100d1f:	83 c4 10             	add    $0x10,%esp
f0100d22:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d25:	5b                   	pop    %ebx
f0100d26:	5e                   	pop    %esi
f0100d27:	5f                   	pop    %edi
f0100d28:	5d                   	pop    %ebp
f0100d29:	c3                   	ret    

f0100d2a <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d2a:	55                   	push   %ebp
f0100d2b:	89 e5                	mov    %esp,%ebp
f0100d2d:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d30:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d34:	8b 10                	mov    (%eax),%edx
f0100d36:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d39:	73 0a                	jae    f0100d45 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d3b:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d3e:	89 08                	mov    %ecx,(%eax)
f0100d40:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d43:	88 02                	mov    %al,(%edx)
}
f0100d45:	5d                   	pop    %ebp
f0100d46:	c3                   	ret    

f0100d47 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d47:	55                   	push   %ebp
f0100d48:	89 e5                	mov    %esp,%ebp
f0100d4a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d4d:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d50:	50                   	push   %eax
f0100d51:	ff 75 10             	pushl  0x10(%ebp)
f0100d54:	ff 75 0c             	pushl  0xc(%ebp)
f0100d57:	ff 75 08             	pushl  0x8(%ebp)
f0100d5a:	e8 05 00 00 00       	call   f0100d64 <vprintfmt>
	va_end(ap);
}
f0100d5f:	83 c4 10             	add    $0x10,%esp
f0100d62:	c9                   	leave  
f0100d63:	c3                   	ret    

f0100d64 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d64:	55                   	push   %ebp
f0100d65:	89 e5                	mov    %esp,%ebp
f0100d67:	57                   	push   %edi
f0100d68:	56                   	push   %esi
f0100d69:	53                   	push   %ebx
f0100d6a:	83 ec 2c             	sub    $0x2c,%esp
f0100d6d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d70:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d73:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100d76:	eb 12                	jmp    f0100d8a <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d78:	85 c0                	test   %eax,%eax
f0100d7a:	0f 84 42 04 00 00    	je     f01011c2 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0100d80:	83 ec 08             	sub    $0x8,%esp
f0100d83:	53                   	push   %ebx
f0100d84:	50                   	push   %eax
f0100d85:	ff d6                	call   *%esi
f0100d87:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d8a:	83 c7 01             	add    $0x1,%edi
f0100d8d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100d91:	83 f8 25             	cmp    $0x25,%eax
f0100d94:	75 e2                	jne    f0100d78 <vprintfmt+0x14>
f0100d96:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100d9a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100da1:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100da8:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100daf:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100db4:	eb 07                	jmp    f0100dbd <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100db6:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100db9:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dbd:	8d 47 01             	lea    0x1(%edi),%eax
f0100dc0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100dc3:	0f b6 07             	movzbl (%edi),%eax
f0100dc6:	0f b6 d0             	movzbl %al,%edx
f0100dc9:	83 e8 23             	sub    $0x23,%eax
f0100dcc:	3c 55                	cmp    $0x55,%al
f0100dce:	0f 87 d3 03 00 00    	ja     f01011a7 <vprintfmt+0x443>
f0100dd4:	0f b6 c0             	movzbl %al,%eax
f0100dd7:	ff 24 85 60 1f 10 f0 	jmp    *-0xfefe0a0(,%eax,4)
f0100dde:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100de1:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100de5:	eb d6                	jmp    f0100dbd <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100de7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100dea:	b8 00 00 00 00       	mov    $0x0,%eax
f0100def:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100df2:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100df5:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100df9:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100dfc:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100dff:	83 f9 09             	cmp    $0x9,%ecx
f0100e02:	77 3f                	ja     f0100e43 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e04:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e07:	eb e9                	jmp    f0100df2 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e09:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e0c:	8b 00                	mov    (%eax),%eax
f0100e0e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e11:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e14:	8d 40 04             	lea    0x4(%eax),%eax
f0100e17:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e1a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e1d:	eb 2a                	jmp    f0100e49 <vprintfmt+0xe5>
f0100e1f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e22:	85 c0                	test   %eax,%eax
f0100e24:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e29:	0f 49 d0             	cmovns %eax,%edx
f0100e2c:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e2f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e32:	eb 89                	jmp    f0100dbd <vprintfmt+0x59>
f0100e34:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e37:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e3e:	e9 7a ff ff ff       	jmp    f0100dbd <vprintfmt+0x59>
f0100e43:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100e46:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100e49:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e4d:	0f 89 6a ff ff ff    	jns    f0100dbd <vprintfmt+0x59>
				width = precision, precision = -1;
f0100e53:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100e56:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e59:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e60:	e9 58 ff ff ff       	jmp    f0100dbd <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e65:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e68:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e6b:	e9 4d ff ff ff       	jmp    f0100dbd <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e70:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e73:	8d 78 04             	lea    0x4(%eax),%edi
f0100e76:	83 ec 08             	sub    $0x8,%esp
f0100e79:	53                   	push   %ebx
f0100e7a:	ff 30                	pushl  (%eax)
f0100e7c:	ff d6                	call   *%esi
			break;
f0100e7e:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e81:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e84:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100e87:	e9 fe fe ff ff       	jmp    f0100d8a <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e8c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e8f:	8d 78 04             	lea    0x4(%eax),%edi
f0100e92:	8b 00                	mov    (%eax),%eax
f0100e94:	99                   	cltd   
f0100e95:	31 d0                	xor    %edx,%eax
f0100e97:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100e99:	83 f8 07             	cmp    $0x7,%eax
f0100e9c:	7f 0b                	jg     f0100ea9 <vprintfmt+0x145>
f0100e9e:	8b 14 85 c0 20 10 f0 	mov    -0xfefdf40(,%eax,4),%edx
f0100ea5:	85 d2                	test   %edx,%edx
f0100ea7:	75 1b                	jne    f0100ec4 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0100ea9:	50                   	push   %eax
f0100eaa:	68 e1 1e 10 f0       	push   $0xf0101ee1
f0100eaf:	53                   	push   %ebx
f0100eb0:	56                   	push   %esi
f0100eb1:	e8 91 fe ff ff       	call   f0100d47 <printfmt>
f0100eb6:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100eb9:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ebc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100ebf:	e9 c6 fe ff ff       	jmp    f0100d8a <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100ec4:	52                   	push   %edx
f0100ec5:	68 ea 1e 10 f0       	push   $0xf0101eea
f0100eca:	53                   	push   %ebx
f0100ecb:	56                   	push   %esi
f0100ecc:	e8 76 fe ff ff       	call   f0100d47 <printfmt>
f0100ed1:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ed4:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100eda:	e9 ab fe ff ff       	jmp    f0100d8a <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100edf:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee2:	83 c0 04             	add    $0x4,%eax
f0100ee5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100ee8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eeb:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100eed:	85 ff                	test   %edi,%edi
f0100eef:	b8 da 1e 10 f0       	mov    $0xf0101eda,%eax
f0100ef4:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100ef7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100efb:	0f 8e 94 00 00 00    	jle    f0100f95 <vprintfmt+0x231>
f0100f01:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f05:	0f 84 98 00 00 00    	je     f0100fa3 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f0b:	83 ec 08             	sub    $0x8,%esp
f0100f0e:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f11:	57                   	push   %edi
f0100f12:	e8 0c 04 00 00       	call   f0101323 <strnlen>
f0100f17:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f1a:	29 c1                	sub    %eax,%ecx
f0100f1c:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100f1f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f22:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f26:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f29:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f2c:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f2e:	eb 0f                	jmp    f0100f3f <vprintfmt+0x1db>
					putch(padc, putdat);
f0100f30:	83 ec 08             	sub    $0x8,%esp
f0100f33:	53                   	push   %ebx
f0100f34:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f37:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f39:	83 ef 01             	sub    $0x1,%edi
f0100f3c:	83 c4 10             	add    $0x10,%esp
f0100f3f:	85 ff                	test   %edi,%edi
f0100f41:	7f ed                	jg     f0100f30 <vprintfmt+0x1cc>
f0100f43:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f46:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0100f49:	85 c9                	test   %ecx,%ecx
f0100f4b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f50:	0f 49 c1             	cmovns %ecx,%eax
f0100f53:	29 c1                	sub    %eax,%ecx
f0100f55:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f58:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f5b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f5e:	89 cb                	mov    %ecx,%ebx
f0100f60:	eb 4d                	jmp    f0100faf <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f62:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f66:	74 1b                	je     f0100f83 <vprintfmt+0x21f>
f0100f68:	0f be c0             	movsbl %al,%eax
f0100f6b:	83 e8 20             	sub    $0x20,%eax
f0100f6e:	83 f8 5e             	cmp    $0x5e,%eax
f0100f71:	76 10                	jbe    f0100f83 <vprintfmt+0x21f>
					putch('?', putdat);
f0100f73:	83 ec 08             	sub    $0x8,%esp
f0100f76:	ff 75 0c             	pushl  0xc(%ebp)
f0100f79:	6a 3f                	push   $0x3f
f0100f7b:	ff 55 08             	call   *0x8(%ebp)
f0100f7e:	83 c4 10             	add    $0x10,%esp
f0100f81:	eb 0d                	jmp    f0100f90 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0100f83:	83 ec 08             	sub    $0x8,%esp
f0100f86:	ff 75 0c             	pushl  0xc(%ebp)
f0100f89:	52                   	push   %edx
f0100f8a:	ff 55 08             	call   *0x8(%ebp)
f0100f8d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f90:	83 eb 01             	sub    $0x1,%ebx
f0100f93:	eb 1a                	jmp    f0100faf <vprintfmt+0x24b>
f0100f95:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f98:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f9b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f9e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fa1:	eb 0c                	jmp    f0100faf <vprintfmt+0x24b>
f0100fa3:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fa6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fa9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fac:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100faf:	83 c7 01             	add    $0x1,%edi
f0100fb2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100fb6:	0f be d0             	movsbl %al,%edx
f0100fb9:	85 d2                	test   %edx,%edx
f0100fbb:	74 23                	je     f0100fe0 <vprintfmt+0x27c>
f0100fbd:	85 f6                	test   %esi,%esi
f0100fbf:	78 a1                	js     f0100f62 <vprintfmt+0x1fe>
f0100fc1:	83 ee 01             	sub    $0x1,%esi
f0100fc4:	79 9c                	jns    f0100f62 <vprintfmt+0x1fe>
f0100fc6:	89 df                	mov    %ebx,%edi
f0100fc8:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fcb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fce:	eb 18                	jmp    f0100fe8 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100fd0:	83 ec 08             	sub    $0x8,%esp
f0100fd3:	53                   	push   %ebx
f0100fd4:	6a 20                	push   $0x20
f0100fd6:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100fd8:	83 ef 01             	sub    $0x1,%edi
f0100fdb:	83 c4 10             	add    $0x10,%esp
f0100fde:	eb 08                	jmp    f0100fe8 <vprintfmt+0x284>
f0100fe0:	89 df                	mov    %ebx,%edi
f0100fe2:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fe5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fe8:	85 ff                	test   %edi,%edi
f0100fea:	7f e4                	jg     f0100fd0 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100fec:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100fef:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ff2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ff5:	e9 90 fd ff ff       	jmp    f0100d8a <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100ffa:	83 f9 01             	cmp    $0x1,%ecx
f0100ffd:	7e 19                	jle    f0101018 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0100fff:	8b 45 14             	mov    0x14(%ebp),%eax
f0101002:	8b 50 04             	mov    0x4(%eax),%edx
f0101005:	8b 00                	mov    (%eax),%eax
f0101007:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010100a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010100d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101010:	8d 40 08             	lea    0x8(%eax),%eax
f0101013:	89 45 14             	mov    %eax,0x14(%ebp)
f0101016:	eb 38                	jmp    f0101050 <vprintfmt+0x2ec>
	else if (lflag)
f0101018:	85 c9                	test   %ecx,%ecx
f010101a:	74 1b                	je     f0101037 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f010101c:	8b 45 14             	mov    0x14(%ebp),%eax
f010101f:	8b 00                	mov    (%eax),%eax
f0101021:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101024:	89 c1                	mov    %eax,%ecx
f0101026:	c1 f9 1f             	sar    $0x1f,%ecx
f0101029:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010102c:	8b 45 14             	mov    0x14(%ebp),%eax
f010102f:	8d 40 04             	lea    0x4(%eax),%eax
f0101032:	89 45 14             	mov    %eax,0x14(%ebp)
f0101035:	eb 19                	jmp    f0101050 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0101037:	8b 45 14             	mov    0x14(%ebp),%eax
f010103a:	8b 00                	mov    (%eax),%eax
f010103c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010103f:	89 c1                	mov    %eax,%ecx
f0101041:	c1 f9 1f             	sar    $0x1f,%ecx
f0101044:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101047:	8b 45 14             	mov    0x14(%ebp),%eax
f010104a:	8d 40 04             	lea    0x4(%eax),%eax
f010104d:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101050:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101053:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101056:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010105b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010105f:	0f 89 0e 01 00 00    	jns    f0101173 <vprintfmt+0x40f>
				putch('-', putdat);
f0101065:	83 ec 08             	sub    $0x8,%esp
f0101068:	53                   	push   %ebx
f0101069:	6a 2d                	push   $0x2d
f010106b:	ff d6                	call   *%esi
				num = -(long long) num;
f010106d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101070:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101073:	f7 da                	neg    %edx
f0101075:	83 d1 00             	adc    $0x0,%ecx
f0101078:	f7 d9                	neg    %ecx
f010107a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010107d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101082:	e9 ec 00 00 00       	jmp    f0101173 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101087:	83 f9 01             	cmp    $0x1,%ecx
f010108a:	7e 18                	jle    f01010a4 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f010108c:	8b 45 14             	mov    0x14(%ebp),%eax
f010108f:	8b 10                	mov    (%eax),%edx
f0101091:	8b 48 04             	mov    0x4(%eax),%ecx
f0101094:	8d 40 08             	lea    0x8(%eax),%eax
f0101097:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010109a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010109f:	e9 cf 00 00 00       	jmp    f0101173 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01010a4:	85 c9                	test   %ecx,%ecx
f01010a6:	74 1a                	je     f01010c2 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f01010a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ab:	8b 10                	mov    (%eax),%edx
f01010ad:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010b2:	8d 40 04             	lea    0x4(%eax),%eax
f01010b5:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01010b8:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010bd:	e9 b1 00 00 00       	jmp    f0101173 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01010c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01010c5:	8b 10                	mov    (%eax),%edx
f01010c7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010cc:	8d 40 04             	lea    0x4(%eax),%eax
f01010cf:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01010d2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010d7:	e9 97 00 00 00       	jmp    f0101173 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01010dc:	83 ec 08             	sub    $0x8,%esp
f01010df:	53                   	push   %ebx
f01010e0:	6a 58                	push   $0x58
f01010e2:	ff d6                	call   *%esi
			putch('X', putdat);
f01010e4:	83 c4 08             	add    $0x8,%esp
f01010e7:	53                   	push   %ebx
f01010e8:	6a 58                	push   $0x58
f01010ea:	ff d6                	call   *%esi
			putch('X', putdat);
f01010ec:	83 c4 08             	add    $0x8,%esp
f01010ef:	53                   	push   %ebx
f01010f0:	6a 58                	push   $0x58
f01010f2:	ff d6                	call   *%esi
			break;
f01010f4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010f7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01010fa:	e9 8b fc ff ff       	jmp    f0100d8a <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f01010ff:	83 ec 08             	sub    $0x8,%esp
f0101102:	53                   	push   %ebx
f0101103:	6a 30                	push   $0x30
f0101105:	ff d6                	call   *%esi
			putch('x', putdat);
f0101107:	83 c4 08             	add    $0x8,%esp
f010110a:	53                   	push   %ebx
f010110b:	6a 78                	push   $0x78
f010110d:	ff d6                	call   *%esi
			num = (unsigned long long)
f010110f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101112:	8b 10                	mov    (%eax),%edx
f0101114:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101119:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010111c:	8d 40 04             	lea    0x4(%eax),%eax
f010111f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101122:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101127:	eb 4a                	jmp    f0101173 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101129:	83 f9 01             	cmp    $0x1,%ecx
f010112c:	7e 15                	jle    f0101143 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f010112e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101131:	8b 10                	mov    (%eax),%edx
f0101133:	8b 48 04             	mov    0x4(%eax),%ecx
f0101136:	8d 40 08             	lea    0x8(%eax),%eax
f0101139:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010113c:	b8 10 00 00 00       	mov    $0x10,%eax
f0101141:	eb 30                	jmp    f0101173 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101143:	85 c9                	test   %ecx,%ecx
f0101145:	74 17                	je     f010115e <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0101147:	8b 45 14             	mov    0x14(%ebp),%eax
f010114a:	8b 10                	mov    (%eax),%edx
f010114c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101151:	8d 40 04             	lea    0x4(%eax),%eax
f0101154:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101157:	b8 10 00 00 00       	mov    $0x10,%eax
f010115c:	eb 15                	jmp    f0101173 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f010115e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101161:	8b 10                	mov    (%eax),%edx
f0101163:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101168:	8d 40 04             	lea    0x4(%eax),%eax
f010116b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010116e:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101173:	83 ec 0c             	sub    $0xc,%esp
f0101176:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010117a:	57                   	push   %edi
f010117b:	ff 75 e0             	pushl  -0x20(%ebp)
f010117e:	50                   	push   %eax
f010117f:	51                   	push   %ecx
f0101180:	52                   	push   %edx
f0101181:	89 da                	mov    %ebx,%edx
f0101183:	89 f0                	mov    %esi,%eax
f0101185:	e8 f1 fa ff ff       	call   f0100c7b <printnum>
			break;
f010118a:	83 c4 20             	add    $0x20,%esp
f010118d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101190:	e9 f5 fb ff ff       	jmp    f0100d8a <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101195:	83 ec 08             	sub    $0x8,%esp
f0101198:	53                   	push   %ebx
f0101199:	52                   	push   %edx
f010119a:	ff d6                	call   *%esi
			break;
f010119c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010119f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01011a2:	e9 e3 fb ff ff       	jmp    f0100d8a <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011a7:	83 ec 08             	sub    $0x8,%esp
f01011aa:	53                   	push   %ebx
f01011ab:	6a 25                	push   $0x25
f01011ad:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011af:	83 c4 10             	add    $0x10,%esp
f01011b2:	eb 03                	jmp    f01011b7 <vprintfmt+0x453>
f01011b4:	83 ef 01             	sub    $0x1,%edi
f01011b7:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01011bb:	75 f7                	jne    f01011b4 <vprintfmt+0x450>
f01011bd:	e9 c8 fb ff ff       	jmp    f0100d8a <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01011c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011c5:	5b                   	pop    %ebx
f01011c6:	5e                   	pop    %esi
f01011c7:	5f                   	pop    %edi
f01011c8:	5d                   	pop    %ebp
f01011c9:	c3                   	ret    

f01011ca <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011ca:	55                   	push   %ebp
f01011cb:	89 e5                	mov    %esp,%ebp
f01011cd:	83 ec 18             	sub    $0x18,%esp
f01011d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01011d3:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011d6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011d9:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011dd:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011e7:	85 c0                	test   %eax,%eax
f01011e9:	74 26                	je     f0101211 <vsnprintf+0x47>
f01011eb:	85 d2                	test   %edx,%edx
f01011ed:	7e 22                	jle    f0101211 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011ef:	ff 75 14             	pushl  0x14(%ebp)
f01011f2:	ff 75 10             	pushl  0x10(%ebp)
f01011f5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011f8:	50                   	push   %eax
f01011f9:	68 2a 0d 10 f0       	push   $0xf0100d2a
f01011fe:	e8 61 fb ff ff       	call   f0100d64 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101203:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101206:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101209:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010120c:	83 c4 10             	add    $0x10,%esp
f010120f:	eb 05                	jmp    f0101216 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101211:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101216:	c9                   	leave  
f0101217:	c3                   	ret    

f0101218 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101218:	55                   	push   %ebp
f0101219:	89 e5                	mov    %esp,%ebp
f010121b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010121e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101221:	50                   	push   %eax
f0101222:	ff 75 10             	pushl  0x10(%ebp)
f0101225:	ff 75 0c             	pushl  0xc(%ebp)
f0101228:	ff 75 08             	pushl  0x8(%ebp)
f010122b:	e8 9a ff ff ff       	call   f01011ca <vsnprintf>
	va_end(ap);

	return rc;
}
f0101230:	c9                   	leave  
f0101231:	c3                   	ret    

f0101232 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101232:	55                   	push   %ebp
f0101233:	89 e5                	mov    %esp,%ebp
f0101235:	57                   	push   %edi
f0101236:	56                   	push   %esi
f0101237:	53                   	push   %ebx
f0101238:	83 ec 0c             	sub    $0xc,%esp
f010123b:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010123e:	85 c0                	test   %eax,%eax
f0101240:	74 11                	je     f0101253 <readline+0x21>
		cprintf("%s", prompt);
f0101242:	83 ec 08             	sub    $0x8,%esp
f0101245:	50                   	push   %eax
f0101246:	68 ea 1e 10 f0       	push   $0xf0101eea
f010124b:	e8 50 f7 ff ff       	call   f01009a0 <cprintf>
f0101250:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101253:	83 ec 0c             	sub    $0xc,%esp
f0101256:	6a 00                	push   $0x0
f0101258:	e8 11 f4 ff ff       	call   f010066e <iscons>
f010125d:	89 c7                	mov    %eax,%edi
f010125f:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101262:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101267:	e8 f1 f3 ff ff       	call   f010065d <getchar>
f010126c:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010126e:	85 c0                	test   %eax,%eax
f0101270:	79 18                	jns    f010128a <readline+0x58>
			cprintf("read error: %e\n", c);
f0101272:	83 ec 08             	sub    $0x8,%esp
f0101275:	50                   	push   %eax
f0101276:	68 e0 20 10 f0       	push   $0xf01020e0
f010127b:	e8 20 f7 ff ff       	call   f01009a0 <cprintf>
			return NULL;
f0101280:	83 c4 10             	add    $0x10,%esp
f0101283:	b8 00 00 00 00       	mov    $0x0,%eax
f0101288:	eb 79                	jmp    f0101303 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010128a:	83 f8 08             	cmp    $0x8,%eax
f010128d:	0f 94 c2             	sete   %dl
f0101290:	83 f8 7f             	cmp    $0x7f,%eax
f0101293:	0f 94 c0             	sete   %al
f0101296:	08 c2                	or     %al,%dl
f0101298:	74 1a                	je     f01012b4 <readline+0x82>
f010129a:	85 f6                	test   %esi,%esi
f010129c:	7e 16                	jle    f01012b4 <readline+0x82>
			if (echoing)
f010129e:	85 ff                	test   %edi,%edi
f01012a0:	74 0d                	je     f01012af <readline+0x7d>
				cputchar('\b');
f01012a2:	83 ec 0c             	sub    $0xc,%esp
f01012a5:	6a 08                	push   $0x8
f01012a7:	e8 a1 f3 ff ff       	call   f010064d <cputchar>
f01012ac:	83 c4 10             	add    $0x10,%esp
			i--;
f01012af:	83 ee 01             	sub    $0x1,%esi
f01012b2:	eb b3                	jmp    f0101267 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012b4:	83 fb 1f             	cmp    $0x1f,%ebx
f01012b7:	7e 23                	jle    f01012dc <readline+0xaa>
f01012b9:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012bf:	7f 1b                	jg     f01012dc <readline+0xaa>
			if (echoing)
f01012c1:	85 ff                	test   %edi,%edi
f01012c3:	74 0c                	je     f01012d1 <readline+0x9f>
				cputchar(c);
f01012c5:	83 ec 0c             	sub    $0xc,%esp
f01012c8:	53                   	push   %ebx
f01012c9:	e8 7f f3 ff ff       	call   f010064d <cputchar>
f01012ce:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01012d1:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012d7:	8d 76 01             	lea    0x1(%esi),%esi
f01012da:	eb 8b                	jmp    f0101267 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01012dc:	83 fb 0a             	cmp    $0xa,%ebx
f01012df:	74 05                	je     f01012e6 <readline+0xb4>
f01012e1:	83 fb 0d             	cmp    $0xd,%ebx
f01012e4:	75 81                	jne    f0101267 <readline+0x35>
			if (echoing)
f01012e6:	85 ff                	test   %edi,%edi
f01012e8:	74 0d                	je     f01012f7 <readline+0xc5>
				cputchar('\n');
f01012ea:	83 ec 0c             	sub    $0xc,%esp
f01012ed:	6a 0a                	push   $0xa
f01012ef:	e8 59 f3 ff ff       	call   f010064d <cputchar>
f01012f4:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01012f7:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012fe:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101303:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101306:	5b                   	pop    %ebx
f0101307:	5e                   	pop    %esi
f0101308:	5f                   	pop    %edi
f0101309:	5d                   	pop    %ebp
f010130a:	c3                   	ret    

f010130b <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010130b:	55                   	push   %ebp
f010130c:	89 e5                	mov    %esp,%ebp
f010130e:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101311:	b8 00 00 00 00       	mov    $0x0,%eax
f0101316:	eb 03                	jmp    f010131b <strlen+0x10>
		n++;
f0101318:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010131b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010131f:	75 f7                	jne    f0101318 <strlen+0xd>
		n++;
	return n;
}
f0101321:	5d                   	pop    %ebp
f0101322:	c3                   	ret    

f0101323 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101323:	55                   	push   %ebp
f0101324:	89 e5                	mov    %esp,%ebp
f0101326:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101329:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010132c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101331:	eb 03                	jmp    f0101336 <strnlen+0x13>
		n++;
f0101333:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101336:	39 c2                	cmp    %eax,%edx
f0101338:	74 08                	je     f0101342 <strnlen+0x1f>
f010133a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010133e:	75 f3                	jne    f0101333 <strnlen+0x10>
f0101340:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101342:	5d                   	pop    %ebp
f0101343:	c3                   	ret    

f0101344 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101344:	55                   	push   %ebp
f0101345:	89 e5                	mov    %esp,%ebp
f0101347:	53                   	push   %ebx
f0101348:	8b 45 08             	mov    0x8(%ebp),%eax
f010134b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010134e:	89 c2                	mov    %eax,%edx
f0101350:	83 c2 01             	add    $0x1,%edx
f0101353:	83 c1 01             	add    $0x1,%ecx
f0101356:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010135a:	88 5a ff             	mov    %bl,-0x1(%edx)
f010135d:	84 db                	test   %bl,%bl
f010135f:	75 ef                	jne    f0101350 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101361:	5b                   	pop    %ebx
f0101362:	5d                   	pop    %ebp
f0101363:	c3                   	ret    

f0101364 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101364:	55                   	push   %ebp
f0101365:	89 e5                	mov    %esp,%ebp
f0101367:	53                   	push   %ebx
f0101368:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010136b:	53                   	push   %ebx
f010136c:	e8 9a ff ff ff       	call   f010130b <strlen>
f0101371:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101374:	ff 75 0c             	pushl  0xc(%ebp)
f0101377:	01 d8                	add    %ebx,%eax
f0101379:	50                   	push   %eax
f010137a:	e8 c5 ff ff ff       	call   f0101344 <strcpy>
	return dst;
}
f010137f:	89 d8                	mov    %ebx,%eax
f0101381:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101384:	c9                   	leave  
f0101385:	c3                   	ret    

f0101386 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101386:	55                   	push   %ebp
f0101387:	89 e5                	mov    %esp,%ebp
f0101389:	56                   	push   %esi
f010138a:	53                   	push   %ebx
f010138b:	8b 75 08             	mov    0x8(%ebp),%esi
f010138e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101391:	89 f3                	mov    %esi,%ebx
f0101393:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101396:	89 f2                	mov    %esi,%edx
f0101398:	eb 0f                	jmp    f01013a9 <strncpy+0x23>
		*dst++ = *src;
f010139a:	83 c2 01             	add    $0x1,%edx
f010139d:	0f b6 01             	movzbl (%ecx),%eax
f01013a0:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013a3:	80 39 01             	cmpb   $0x1,(%ecx)
f01013a6:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013a9:	39 da                	cmp    %ebx,%edx
f01013ab:	75 ed                	jne    f010139a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013ad:	89 f0                	mov    %esi,%eax
f01013af:	5b                   	pop    %ebx
f01013b0:	5e                   	pop    %esi
f01013b1:	5d                   	pop    %ebp
f01013b2:	c3                   	ret    

f01013b3 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013b3:	55                   	push   %ebp
f01013b4:	89 e5                	mov    %esp,%ebp
f01013b6:	56                   	push   %esi
f01013b7:	53                   	push   %ebx
f01013b8:	8b 75 08             	mov    0x8(%ebp),%esi
f01013bb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013be:	8b 55 10             	mov    0x10(%ebp),%edx
f01013c1:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013c3:	85 d2                	test   %edx,%edx
f01013c5:	74 21                	je     f01013e8 <strlcpy+0x35>
f01013c7:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01013cb:	89 f2                	mov    %esi,%edx
f01013cd:	eb 09                	jmp    f01013d8 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013cf:	83 c2 01             	add    $0x1,%edx
f01013d2:	83 c1 01             	add    $0x1,%ecx
f01013d5:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013d8:	39 c2                	cmp    %eax,%edx
f01013da:	74 09                	je     f01013e5 <strlcpy+0x32>
f01013dc:	0f b6 19             	movzbl (%ecx),%ebx
f01013df:	84 db                	test   %bl,%bl
f01013e1:	75 ec                	jne    f01013cf <strlcpy+0x1c>
f01013e3:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013e5:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013e8:	29 f0                	sub    %esi,%eax
}
f01013ea:	5b                   	pop    %ebx
f01013eb:	5e                   	pop    %esi
f01013ec:	5d                   	pop    %ebp
f01013ed:	c3                   	ret    

f01013ee <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013ee:	55                   	push   %ebp
f01013ef:	89 e5                	mov    %esp,%ebp
f01013f1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013f4:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013f7:	eb 06                	jmp    f01013ff <strcmp+0x11>
		p++, q++;
f01013f9:	83 c1 01             	add    $0x1,%ecx
f01013fc:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013ff:	0f b6 01             	movzbl (%ecx),%eax
f0101402:	84 c0                	test   %al,%al
f0101404:	74 04                	je     f010140a <strcmp+0x1c>
f0101406:	3a 02                	cmp    (%edx),%al
f0101408:	74 ef                	je     f01013f9 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010140a:	0f b6 c0             	movzbl %al,%eax
f010140d:	0f b6 12             	movzbl (%edx),%edx
f0101410:	29 d0                	sub    %edx,%eax
}
f0101412:	5d                   	pop    %ebp
f0101413:	c3                   	ret    

f0101414 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101414:	55                   	push   %ebp
f0101415:	89 e5                	mov    %esp,%ebp
f0101417:	53                   	push   %ebx
f0101418:	8b 45 08             	mov    0x8(%ebp),%eax
f010141b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010141e:	89 c3                	mov    %eax,%ebx
f0101420:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101423:	eb 06                	jmp    f010142b <strncmp+0x17>
		n--, p++, q++;
f0101425:	83 c0 01             	add    $0x1,%eax
f0101428:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010142b:	39 d8                	cmp    %ebx,%eax
f010142d:	74 15                	je     f0101444 <strncmp+0x30>
f010142f:	0f b6 08             	movzbl (%eax),%ecx
f0101432:	84 c9                	test   %cl,%cl
f0101434:	74 04                	je     f010143a <strncmp+0x26>
f0101436:	3a 0a                	cmp    (%edx),%cl
f0101438:	74 eb                	je     f0101425 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010143a:	0f b6 00             	movzbl (%eax),%eax
f010143d:	0f b6 12             	movzbl (%edx),%edx
f0101440:	29 d0                	sub    %edx,%eax
f0101442:	eb 05                	jmp    f0101449 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101444:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101449:	5b                   	pop    %ebx
f010144a:	5d                   	pop    %ebp
f010144b:	c3                   	ret    

f010144c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010144c:	55                   	push   %ebp
f010144d:	89 e5                	mov    %esp,%ebp
f010144f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101452:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101456:	eb 07                	jmp    f010145f <strchr+0x13>
		if (*s == c)
f0101458:	38 ca                	cmp    %cl,%dl
f010145a:	74 0f                	je     f010146b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010145c:	83 c0 01             	add    $0x1,%eax
f010145f:	0f b6 10             	movzbl (%eax),%edx
f0101462:	84 d2                	test   %dl,%dl
f0101464:	75 f2                	jne    f0101458 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101466:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010146b:	5d                   	pop    %ebp
f010146c:	c3                   	ret    

f010146d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010146d:	55                   	push   %ebp
f010146e:	89 e5                	mov    %esp,%ebp
f0101470:	8b 45 08             	mov    0x8(%ebp),%eax
f0101473:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101477:	eb 03                	jmp    f010147c <strfind+0xf>
f0101479:	83 c0 01             	add    $0x1,%eax
f010147c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010147f:	38 ca                	cmp    %cl,%dl
f0101481:	74 04                	je     f0101487 <strfind+0x1a>
f0101483:	84 d2                	test   %dl,%dl
f0101485:	75 f2                	jne    f0101479 <strfind+0xc>
			break;
	return (char *) s;
}
f0101487:	5d                   	pop    %ebp
f0101488:	c3                   	ret    

f0101489 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101489:	55                   	push   %ebp
f010148a:	89 e5                	mov    %esp,%ebp
f010148c:	57                   	push   %edi
f010148d:	56                   	push   %esi
f010148e:	53                   	push   %ebx
f010148f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101492:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101495:	85 c9                	test   %ecx,%ecx
f0101497:	74 36                	je     f01014cf <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101499:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010149f:	75 28                	jne    f01014c9 <memset+0x40>
f01014a1:	f6 c1 03             	test   $0x3,%cl
f01014a4:	75 23                	jne    f01014c9 <memset+0x40>
		c &= 0xFF;
f01014a6:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014aa:	89 d3                	mov    %edx,%ebx
f01014ac:	c1 e3 08             	shl    $0x8,%ebx
f01014af:	89 d6                	mov    %edx,%esi
f01014b1:	c1 e6 18             	shl    $0x18,%esi
f01014b4:	89 d0                	mov    %edx,%eax
f01014b6:	c1 e0 10             	shl    $0x10,%eax
f01014b9:	09 f0                	or     %esi,%eax
f01014bb:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01014bd:	89 d8                	mov    %ebx,%eax
f01014bf:	09 d0                	or     %edx,%eax
f01014c1:	c1 e9 02             	shr    $0x2,%ecx
f01014c4:	fc                   	cld    
f01014c5:	f3 ab                	rep stos %eax,%es:(%edi)
f01014c7:	eb 06                	jmp    f01014cf <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014c9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014cc:	fc                   	cld    
f01014cd:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014cf:	89 f8                	mov    %edi,%eax
f01014d1:	5b                   	pop    %ebx
f01014d2:	5e                   	pop    %esi
f01014d3:	5f                   	pop    %edi
f01014d4:	5d                   	pop    %ebp
f01014d5:	c3                   	ret    

f01014d6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014d6:	55                   	push   %ebp
f01014d7:	89 e5                	mov    %esp,%ebp
f01014d9:	57                   	push   %edi
f01014da:	56                   	push   %esi
f01014db:	8b 45 08             	mov    0x8(%ebp),%eax
f01014de:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014e1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014e4:	39 c6                	cmp    %eax,%esi
f01014e6:	73 35                	jae    f010151d <memmove+0x47>
f01014e8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014eb:	39 d0                	cmp    %edx,%eax
f01014ed:	73 2e                	jae    f010151d <memmove+0x47>
		s += n;
		d += n;
f01014ef:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014f2:	89 d6                	mov    %edx,%esi
f01014f4:	09 fe                	or     %edi,%esi
f01014f6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014fc:	75 13                	jne    f0101511 <memmove+0x3b>
f01014fe:	f6 c1 03             	test   $0x3,%cl
f0101501:	75 0e                	jne    f0101511 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101503:	83 ef 04             	sub    $0x4,%edi
f0101506:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101509:	c1 e9 02             	shr    $0x2,%ecx
f010150c:	fd                   	std    
f010150d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010150f:	eb 09                	jmp    f010151a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101511:	83 ef 01             	sub    $0x1,%edi
f0101514:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101517:	fd                   	std    
f0101518:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010151a:	fc                   	cld    
f010151b:	eb 1d                	jmp    f010153a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010151d:	89 f2                	mov    %esi,%edx
f010151f:	09 c2                	or     %eax,%edx
f0101521:	f6 c2 03             	test   $0x3,%dl
f0101524:	75 0f                	jne    f0101535 <memmove+0x5f>
f0101526:	f6 c1 03             	test   $0x3,%cl
f0101529:	75 0a                	jne    f0101535 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010152b:	c1 e9 02             	shr    $0x2,%ecx
f010152e:	89 c7                	mov    %eax,%edi
f0101530:	fc                   	cld    
f0101531:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101533:	eb 05                	jmp    f010153a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101535:	89 c7                	mov    %eax,%edi
f0101537:	fc                   	cld    
f0101538:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010153a:	5e                   	pop    %esi
f010153b:	5f                   	pop    %edi
f010153c:	5d                   	pop    %ebp
f010153d:	c3                   	ret    

f010153e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010153e:	55                   	push   %ebp
f010153f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101541:	ff 75 10             	pushl  0x10(%ebp)
f0101544:	ff 75 0c             	pushl  0xc(%ebp)
f0101547:	ff 75 08             	pushl  0x8(%ebp)
f010154a:	e8 87 ff ff ff       	call   f01014d6 <memmove>
}
f010154f:	c9                   	leave  
f0101550:	c3                   	ret    

f0101551 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101551:	55                   	push   %ebp
f0101552:	89 e5                	mov    %esp,%ebp
f0101554:	56                   	push   %esi
f0101555:	53                   	push   %ebx
f0101556:	8b 45 08             	mov    0x8(%ebp),%eax
f0101559:	8b 55 0c             	mov    0xc(%ebp),%edx
f010155c:	89 c6                	mov    %eax,%esi
f010155e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101561:	eb 1a                	jmp    f010157d <memcmp+0x2c>
		if (*s1 != *s2)
f0101563:	0f b6 08             	movzbl (%eax),%ecx
f0101566:	0f b6 1a             	movzbl (%edx),%ebx
f0101569:	38 d9                	cmp    %bl,%cl
f010156b:	74 0a                	je     f0101577 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010156d:	0f b6 c1             	movzbl %cl,%eax
f0101570:	0f b6 db             	movzbl %bl,%ebx
f0101573:	29 d8                	sub    %ebx,%eax
f0101575:	eb 0f                	jmp    f0101586 <memcmp+0x35>
		s1++, s2++;
f0101577:	83 c0 01             	add    $0x1,%eax
f010157a:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010157d:	39 f0                	cmp    %esi,%eax
f010157f:	75 e2                	jne    f0101563 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101581:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101586:	5b                   	pop    %ebx
f0101587:	5e                   	pop    %esi
f0101588:	5d                   	pop    %ebp
f0101589:	c3                   	ret    

f010158a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010158a:	55                   	push   %ebp
f010158b:	89 e5                	mov    %esp,%ebp
f010158d:	53                   	push   %ebx
f010158e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101591:	89 c1                	mov    %eax,%ecx
f0101593:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101596:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010159a:	eb 0a                	jmp    f01015a6 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010159c:	0f b6 10             	movzbl (%eax),%edx
f010159f:	39 da                	cmp    %ebx,%edx
f01015a1:	74 07                	je     f01015aa <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015a3:	83 c0 01             	add    $0x1,%eax
f01015a6:	39 c8                	cmp    %ecx,%eax
f01015a8:	72 f2                	jb     f010159c <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015aa:	5b                   	pop    %ebx
f01015ab:	5d                   	pop    %ebp
f01015ac:	c3                   	ret    

f01015ad <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015ad:	55                   	push   %ebp
f01015ae:	89 e5                	mov    %esp,%ebp
f01015b0:	57                   	push   %edi
f01015b1:	56                   	push   %esi
f01015b2:	53                   	push   %ebx
f01015b3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015b6:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015b9:	eb 03                	jmp    f01015be <strtol+0x11>
		s++;
f01015bb:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015be:	0f b6 01             	movzbl (%ecx),%eax
f01015c1:	3c 20                	cmp    $0x20,%al
f01015c3:	74 f6                	je     f01015bb <strtol+0xe>
f01015c5:	3c 09                	cmp    $0x9,%al
f01015c7:	74 f2                	je     f01015bb <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015c9:	3c 2b                	cmp    $0x2b,%al
f01015cb:	75 0a                	jne    f01015d7 <strtol+0x2a>
		s++;
f01015cd:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015d0:	bf 00 00 00 00       	mov    $0x0,%edi
f01015d5:	eb 11                	jmp    f01015e8 <strtol+0x3b>
f01015d7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015dc:	3c 2d                	cmp    $0x2d,%al
f01015de:	75 08                	jne    f01015e8 <strtol+0x3b>
		s++, neg = 1;
f01015e0:	83 c1 01             	add    $0x1,%ecx
f01015e3:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015e8:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015ee:	75 15                	jne    f0101605 <strtol+0x58>
f01015f0:	80 39 30             	cmpb   $0x30,(%ecx)
f01015f3:	75 10                	jne    f0101605 <strtol+0x58>
f01015f5:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01015f9:	75 7c                	jne    f0101677 <strtol+0xca>
		s += 2, base = 16;
f01015fb:	83 c1 02             	add    $0x2,%ecx
f01015fe:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101603:	eb 16                	jmp    f010161b <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0101605:	85 db                	test   %ebx,%ebx
f0101607:	75 12                	jne    f010161b <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101609:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010160e:	80 39 30             	cmpb   $0x30,(%ecx)
f0101611:	75 08                	jne    f010161b <strtol+0x6e>
		s++, base = 8;
f0101613:	83 c1 01             	add    $0x1,%ecx
f0101616:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010161b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101620:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101623:	0f b6 11             	movzbl (%ecx),%edx
f0101626:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101629:	89 f3                	mov    %esi,%ebx
f010162b:	80 fb 09             	cmp    $0x9,%bl
f010162e:	77 08                	ja     f0101638 <strtol+0x8b>
			dig = *s - '0';
f0101630:	0f be d2             	movsbl %dl,%edx
f0101633:	83 ea 30             	sub    $0x30,%edx
f0101636:	eb 22                	jmp    f010165a <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0101638:	8d 72 9f             	lea    -0x61(%edx),%esi
f010163b:	89 f3                	mov    %esi,%ebx
f010163d:	80 fb 19             	cmp    $0x19,%bl
f0101640:	77 08                	ja     f010164a <strtol+0x9d>
			dig = *s - 'a' + 10;
f0101642:	0f be d2             	movsbl %dl,%edx
f0101645:	83 ea 57             	sub    $0x57,%edx
f0101648:	eb 10                	jmp    f010165a <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010164a:	8d 72 bf             	lea    -0x41(%edx),%esi
f010164d:	89 f3                	mov    %esi,%ebx
f010164f:	80 fb 19             	cmp    $0x19,%bl
f0101652:	77 16                	ja     f010166a <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101654:	0f be d2             	movsbl %dl,%edx
f0101657:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010165a:	3b 55 10             	cmp    0x10(%ebp),%edx
f010165d:	7d 0b                	jge    f010166a <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010165f:	83 c1 01             	add    $0x1,%ecx
f0101662:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101666:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101668:	eb b9                	jmp    f0101623 <strtol+0x76>

	if (endptr)
f010166a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010166e:	74 0d                	je     f010167d <strtol+0xd0>
		*endptr = (char *) s;
f0101670:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101673:	89 0e                	mov    %ecx,(%esi)
f0101675:	eb 06                	jmp    f010167d <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101677:	85 db                	test   %ebx,%ebx
f0101679:	74 98                	je     f0101613 <strtol+0x66>
f010167b:	eb 9e                	jmp    f010161b <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010167d:	89 c2                	mov    %eax,%edx
f010167f:	f7 da                	neg    %edx
f0101681:	85 ff                	test   %edi,%edi
f0101683:	0f 45 c2             	cmovne %edx,%eax
}
f0101686:	5b                   	pop    %ebx
f0101687:	5e                   	pop    %esi
f0101688:	5f                   	pop    %edi
f0101689:	5d                   	pop    %ebp
f010168a:	c3                   	ret    
f010168b:	66 90                	xchg   %ax,%ax
f010168d:	66 90                	xchg   %ax,%ax
f010168f:	90                   	nop

f0101690 <__udivdi3>:
f0101690:	55                   	push   %ebp
f0101691:	57                   	push   %edi
f0101692:	56                   	push   %esi
f0101693:	53                   	push   %ebx
f0101694:	83 ec 1c             	sub    $0x1c,%esp
f0101697:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010169b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010169f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01016a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01016a7:	85 f6                	test   %esi,%esi
f01016a9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01016ad:	89 ca                	mov    %ecx,%edx
f01016af:	89 f8                	mov    %edi,%eax
f01016b1:	75 3d                	jne    f01016f0 <__udivdi3+0x60>
f01016b3:	39 cf                	cmp    %ecx,%edi
f01016b5:	0f 87 c5 00 00 00    	ja     f0101780 <__udivdi3+0xf0>
f01016bb:	85 ff                	test   %edi,%edi
f01016bd:	89 fd                	mov    %edi,%ebp
f01016bf:	75 0b                	jne    f01016cc <__udivdi3+0x3c>
f01016c1:	b8 01 00 00 00       	mov    $0x1,%eax
f01016c6:	31 d2                	xor    %edx,%edx
f01016c8:	f7 f7                	div    %edi
f01016ca:	89 c5                	mov    %eax,%ebp
f01016cc:	89 c8                	mov    %ecx,%eax
f01016ce:	31 d2                	xor    %edx,%edx
f01016d0:	f7 f5                	div    %ebp
f01016d2:	89 c1                	mov    %eax,%ecx
f01016d4:	89 d8                	mov    %ebx,%eax
f01016d6:	89 cf                	mov    %ecx,%edi
f01016d8:	f7 f5                	div    %ebp
f01016da:	89 c3                	mov    %eax,%ebx
f01016dc:	89 d8                	mov    %ebx,%eax
f01016de:	89 fa                	mov    %edi,%edx
f01016e0:	83 c4 1c             	add    $0x1c,%esp
f01016e3:	5b                   	pop    %ebx
f01016e4:	5e                   	pop    %esi
f01016e5:	5f                   	pop    %edi
f01016e6:	5d                   	pop    %ebp
f01016e7:	c3                   	ret    
f01016e8:	90                   	nop
f01016e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016f0:	39 ce                	cmp    %ecx,%esi
f01016f2:	77 74                	ja     f0101768 <__udivdi3+0xd8>
f01016f4:	0f bd fe             	bsr    %esi,%edi
f01016f7:	83 f7 1f             	xor    $0x1f,%edi
f01016fa:	0f 84 98 00 00 00    	je     f0101798 <__udivdi3+0x108>
f0101700:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101705:	89 f9                	mov    %edi,%ecx
f0101707:	89 c5                	mov    %eax,%ebp
f0101709:	29 fb                	sub    %edi,%ebx
f010170b:	d3 e6                	shl    %cl,%esi
f010170d:	89 d9                	mov    %ebx,%ecx
f010170f:	d3 ed                	shr    %cl,%ebp
f0101711:	89 f9                	mov    %edi,%ecx
f0101713:	d3 e0                	shl    %cl,%eax
f0101715:	09 ee                	or     %ebp,%esi
f0101717:	89 d9                	mov    %ebx,%ecx
f0101719:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010171d:	89 d5                	mov    %edx,%ebp
f010171f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101723:	d3 ed                	shr    %cl,%ebp
f0101725:	89 f9                	mov    %edi,%ecx
f0101727:	d3 e2                	shl    %cl,%edx
f0101729:	89 d9                	mov    %ebx,%ecx
f010172b:	d3 e8                	shr    %cl,%eax
f010172d:	09 c2                	or     %eax,%edx
f010172f:	89 d0                	mov    %edx,%eax
f0101731:	89 ea                	mov    %ebp,%edx
f0101733:	f7 f6                	div    %esi
f0101735:	89 d5                	mov    %edx,%ebp
f0101737:	89 c3                	mov    %eax,%ebx
f0101739:	f7 64 24 0c          	mull   0xc(%esp)
f010173d:	39 d5                	cmp    %edx,%ebp
f010173f:	72 10                	jb     f0101751 <__udivdi3+0xc1>
f0101741:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101745:	89 f9                	mov    %edi,%ecx
f0101747:	d3 e6                	shl    %cl,%esi
f0101749:	39 c6                	cmp    %eax,%esi
f010174b:	73 07                	jae    f0101754 <__udivdi3+0xc4>
f010174d:	39 d5                	cmp    %edx,%ebp
f010174f:	75 03                	jne    f0101754 <__udivdi3+0xc4>
f0101751:	83 eb 01             	sub    $0x1,%ebx
f0101754:	31 ff                	xor    %edi,%edi
f0101756:	89 d8                	mov    %ebx,%eax
f0101758:	89 fa                	mov    %edi,%edx
f010175a:	83 c4 1c             	add    $0x1c,%esp
f010175d:	5b                   	pop    %ebx
f010175e:	5e                   	pop    %esi
f010175f:	5f                   	pop    %edi
f0101760:	5d                   	pop    %ebp
f0101761:	c3                   	ret    
f0101762:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101768:	31 ff                	xor    %edi,%edi
f010176a:	31 db                	xor    %ebx,%ebx
f010176c:	89 d8                	mov    %ebx,%eax
f010176e:	89 fa                	mov    %edi,%edx
f0101770:	83 c4 1c             	add    $0x1c,%esp
f0101773:	5b                   	pop    %ebx
f0101774:	5e                   	pop    %esi
f0101775:	5f                   	pop    %edi
f0101776:	5d                   	pop    %ebp
f0101777:	c3                   	ret    
f0101778:	90                   	nop
f0101779:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101780:	89 d8                	mov    %ebx,%eax
f0101782:	f7 f7                	div    %edi
f0101784:	31 ff                	xor    %edi,%edi
f0101786:	89 c3                	mov    %eax,%ebx
f0101788:	89 d8                	mov    %ebx,%eax
f010178a:	89 fa                	mov    %edi,%edx
f010178c:	83 c4 1c             	add    $0x1c,%esp
f010178f:	5b                   	pop    %ebx
f0101790:	5e                   	pop    %esi
f0101791:	5f                   	pop    %edi
f0101792:	5d                   	pop    %ebp
f0101793:	c3                   	ret    
f0101794:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101798:	39 ce                	cmp    %ecx,%esi
f010179a:	72 0c                	jb     f01017a8 <__udivdi3+0x118>
f010179c:	31 db                	xor    %ebx,%ebx
f010179e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01017a2:	0f 87 34 ff ff ff    	ja     f01016dc <__udivdi3+0x4c>
f01017a8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01017ad:	e9 2a ff ff ff       	jmp    f01016dc <__udivdi3+0x4c>
f01017b2:	66 90                	xchg   %ax,%ax
f01017b4:	66 90                	xchg   %ax,%ax
f01017b6:	66 90                	xchg   %ax,%ax
f01017b8:	66 90                	xchg   %ax,%ax
f01017ba:	66 90                	xchg   %ax,%ax
f01017bc:	66 90                	xchg   %ax,%ax
f01017be:	66 90                	xchg   %ax,%ax

f01017c0 <__umoddi3>:
f01017c0:	55                   	push   %ebp
f01017c1:	57                   	push   %edi
f01017c2:	56                   	push   %esi
f01017c3:	53                   	push   %ebx
f01017c4:	83 ec 1c             	sub    $0x1c,%esp
f01017c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01017cb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01017cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01017d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01017d7:	85 d2                	test   %edx,%edx
f01017d9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01017dd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017e1:	89 f3                	mov    %esi,%ebx
f01017e3:	89 3c 24             	mov    %edi,(%esp)
f01017e6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01017ea:	75 1c                	jne    f0101808 <__umoddi3+0x48>
f01017ec:	39 f7                	cmp    %esi,%edi
f01017ee:	76 50                	jbe    f0101840 <__umoddi3+0x80>
f01017f0:	89 c8                	mov    %ecx,%eax
f01017f2:	89 f2                	mov    %esi,%edx
f01017f4:	f7 f7                	div    %edi
f01017f6:	89 d0                	mov    %edx,%eax
f01017f8:	31 d2                	xor    %edx,%edx
f01017fa:	83 c4 1c             	add    $0x1c,%esp
f01017fd:	5b                   	pop    %ebx
f01017fe:	5e                   	pop    %esi
f01017ff:	5f                   	pop    %edi
f0101800:	5d                   	pop    %ebp
f0101801:	c3                   	ret    
f0101802:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101808:	39 f2                	cmp    %esi,%edx
f010180a:	89 d0                	mov    %edx,%eax
f010180c:	77 52                	ja     f0101860 <__umoddi3+0xa0>
f010180e:	0f bd ea             	bsr    %edx,%ebp
f0101811:	83 f5 1f             	xor    $0x1f,%ebp
f0101814:	75 5a                	jne    f0101870 <__umoddi3+0xb0>
f0101816:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010181a:	0f 82 e0 00 00 00    	jb     f0101900 <__umoddi3+0x140>
f0101820:	39 0c 24             	cmp    %ecx,(%esp)
f0101823:	0f 86 d7 00 00 00    	jbe    f0101900 <__umoddi3+0x140>
f0101829:	8b 44 24 08          	mov    0x8(%esp),%eax
f010182d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101831:	83 c4 1c             	add    $0x1c,%esp
f0101834:	5b                   	pop    %ebx
f0101835:	5e                   	pop    %esi
f0101836:	5f                   	pop    %edi
f0101837:	5d                   	pop    %ebp
f0101838:	c3                   	ret    
f0101839:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101840:	85 ff                	test   %edi,%edi
f0101842:	89 fd                	mov    %edi,%ebp
f0101844:	75 0b                	jne    f0101851 <__umoddi3+0x91>
f0101846:	b8 01 00 00 00       	mov    $0x1,%eax
f010184b:	31 d2                	xor    %edx,%edx
f010184d:	f7 f7                	div    %edi
f010184f:	89 c5                	mov    %eax,%ebp
f0101851:	89 f0                	mov    %esi,%eax
f0101853:	31 d2                	xor    %edx,%edx
f0101855:	f7 f5                	div    %ebp
f0101857:	89 c8                	mov    %ecx,%eax
f0101859:	f7 f5                	div    %ebp
f010185b:	89 d0                	mov    %edx,%eax
f010185d:	eb 99                	jmp    f01017f8 <__umoddi3+0x38>
f010185f:	90                   	nop
f0101860:	89 c8                	mov    %ecx,%eax
f0101862:	89 f2                	mov    %esi,%edx
f0101864:	83 c4 1c             	add    $0x1c,%esp
f0101867:	5b                   	pop    %ebx
f0101868:	5e                   	pop    %esi
f0101869:	5f                   	pop    %edi
f010186a:	5d                   	pop    %ebp
f010186b:	c3                   	ret    
f010186c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101870:	8b 34 24             	mov    (%esp),%esi
f0101873:	bf 20 00 00 00       	mov    $0x20,%edi
f0101878:	89 e9                	mov    %ebp,%ecx
f010187a:	29 ef                	sub    %ebp,%edi
f010187c:	d3 e0                	shl    %cl,%eax
f010187e:	89 f9                	mov    %edi,%ecx
f0101880:	89 f2                	mov    %esi,%edx
f0101882:	d3 ea                	shr    %cl,%edx
f0101884:	89 e9                	mov    %ebp,%ecx
f0101886:	09 c2                	or     %eax,%edx
f0101888:	89 d8                	mov    %ebx,%eax
f010188a:	89 14 24             	mov    %edx,(%esp)
f010188d:	89 f2                	mov    %esi,%edx
f010188f:	d3 e2                	shl    %cl,%edx
f0101891:	89 f9                	mov    %edi,%ecx
f0101893:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101897:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010189b:	d3 e8                	shr    %cl,%eax
f010189d:	89 e9                	mov    %ebp,%ecx
f010189f:	89 c6                	mov    %eax,%esi
f01018a1:	d3 e3                	shl    %cl,%ebx
f01018a3:	89 f9                	mov    %edi,%ecx
f01018a5:	89 d0                	mov    %edx,%eax
f01018a7:	d3 e8                	shr    %cl,%eax
f01018a9:	89 e9                	mov    %ebp,%ecx
f01018ab:	09 d8                	or     %ebx,%eax
f01018ad:	89 d3                	mov    %edx,%ebx
f01018af:	89 f2                	mov    %esi,%edx
f01018b1:	f7 34 24             	divl   (%esp)
f01018b4:	89 d6                	mov    %edx,%esi
f01018b6:	d3 e3                	shl    %cl,%ebx
f01018b8:	f7 64 24 04          	mull   0x4(%esp)
f01018bc:	39 d6                	cmp    %edx,%esi
f01018be:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01018c2:	89 d1                	mov    %edx,%ecx
f01018c4:	89 c3                	mov    %eax,%ebx
f01018c6:	72 08                	jb     f01018d0 <__umoddi3+0x110>
f01018c8:	75 11                	jne    f01018db <__umoddi3+0x11b>
f01018ca:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01018ce:	73 0b                	jae    f01018db <__umoddi3+0x11b>
f01018d0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01018d4:	1b 14 24             	sbb    (%esp),%edx
f01018d7:	89 d1                	mov    %edx,%ecx
f01018d9:	89 c3                	mov    %eax,%ebx
f01018db:	8b 54 24 08          	mov    0x8(%esp),%edx
f01018df:	29 da                	sub    %ebx,%edx
f01018e1:	19 ce                	sbb    %ecx,%esi
f01018e3:	89 f9                	mov    %edi,%ecx
f01018e5:	89 f0                	mov    %esi,%eax
f01018e7:	d3 e0                	shl    %cl,%eax
f01018e9:	89 e9                	mov    %ebp,%ecx
f01018eb:	d3 ea                	shr    %cl,%edx
f01018ed:	89 e9                	mov    %ebp,%ecx
f01018ef:	d3 ee                	shr    %cl,%esi
f01018f1:	09 d0                	or     %edx,%eax
f01018f3:	89 f2                	mov    %esi,%edx
f01018f5:	83 c4 1c             	add    $0x1c,%esp
f01018f8:	5b                   	pop    %ebx
f01018f9:	5e                   	pop    %esi
f01018fa:	5f                   	pop    %edi
f01018fb:	5d                   	pop    %ebp
f01018fc:	c3                   	ret    
f01018fd:	8d 76 00             	lea    0x0(%esi),%esi
f0101900:	29 f9                	sub    %edi,%ecx
f0101902:	19 d6                	sbb    %edx,%esi
f0101904:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101908:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010190c:	e9 18 ff ff ff       	jmp    f0101829 <__umoddi3+0x69>
