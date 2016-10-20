
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 33 32 00 00       	call   f0103290 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 37 10 f0       	push   $0xf0103740
f010006f:	e8 33 27 00 00       	call   f01027a7 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 28 10 00 00       	call   f01010a1 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 52 07 00 00       	call   f01007d8 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 5b 37 10 f0       	push   $0xf010375b
f01000b5:	e8 ed 26 00 00       	call   f01027a7 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 bd 26 00 00       	call   f0102781 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 68 3f 10 f0 	movl   $0xf0103f68,(%esp)
f01000cb:	e8 d7 26 00 00       	call   f01027a7 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 fb 06 00 00       	call   f01007d8 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 73 37 10 f0       	push   $0xf0103773
f01000f7:	e8 ab 26 00 00       	call   f01027a7 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 79 26 00 00       	call   f0102781 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 68 3f 10 f0 	movl   $0xf0103f68,(%esp)
f010010f:	e8 93 26 00 00       	call   f01027a7 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100159:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f0 00 00 00    	je     f010027c <kbd_proc_data+0xfe>
f010018c:	ba 60 00 00 00       	mov    $0x60,%edx
f0100191:	ec                   	in     (%dx),%al
f0100192:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100194:	3c e0                	cmp    $0xe0,%al
f0100196:	75 0d                	jne    f01001a5 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f0100198:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f010019f:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001a4:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001a5:	55                   	push   %ebp
f01001a6:	89 e5                	mov    %esp,%ebp
f01001a8:	53                   	push   %ebx
f01001a9:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001ac:	84 c0                	test   %al,%al
f01001ae:	79 36                	jns    f01001e6 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b0:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 e0 38 10 f0 	movzbl -0xfefc720(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 e0 38 10 f0 	movzbl -0xfefc720(%edx),%eax
f0100209:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f010020f:	0f b6 8a e0 37 10 f0 	movzbl -0xfefc820(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d c0 37 10 f0 	mov    -0xfefc840(,%ecx,4),%ecx
f0100229:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010022d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100230:	a8 08                	test   $0x8,%al
f0100232:	74 1b                	je     f010024f <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100234:	89 da                	mov    %ebx,%edx
f0100236:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100239:	83 f9 19             	cmp    $0x19,%ecx
f010023c:	77 05                	ja     f0100243 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f010023e:	83 eb 20             	sub    $0x20,%ebx
f0100241:	eb 0c                	jmp    f010024f <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100243:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100246:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100249:	83 fa 19             	cmp    $0x19,%edx
f010024c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010024f:	f7 d0                	not    %eax
f0100251:	a8 06                	test   $0x6,%al
f0100253:	75 2d                	jne    f0100282 <kbd_proc_data+0x104>
f0100255:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010025b:	75 25                	jne    f0100282 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010025d:	83 ec 0c             	sub    $0xc,%esp
f0100260:	68 8d 37 10 f0       	push   $0xf010378d
f0100265:	e8 3d 25 00 00       	call   f01027a7 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026a:	ba 92 00 00 00       	mov    $0x92,%edx
f010026f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100274:	ee                   	out    %al,(%dx)
f0100275:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100278:	89 d8                	mov    %ebx,%eax
f010027a:	eb 08                	jmp    f0100284 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010027c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100281:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100282:	89 d8                	mov    %ebx,%eax
}
f0100284:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100287:	c9                   	leave  
f0100288:	c3                   	ret    

f0100289 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100289:	55                   	push   %ebp
f010028a:	89 e5                	mov    %esp,%ebp
f010028c:	57                   	push   %edi
f010028d:	56                   	push   %esi
f010028e:	53                   	push   %ebx
f010028f:	83 ec 1c             	sub    $0x1c,%esp
f0100292:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100294:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100299:	be fd 03 00 00       	mov    $0x3fd,%esi
f010029e:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002a3:	eb 09                	jmp    f01002ae <cons_putc+0x25>
f01002a5:	89 ca                	mov    %ecx,%edx
f01002a7:	ec                   	in     (%dx),%al
f01002a8:	ec                   	in     (%dx),%al
f01002a9:	ec                   	in     (%dx),%al
f01002aa:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ab:	83 c3 01             	add    $0x1,%ebx
f01002ae:	89 f2                	mov    %esi,%edx
f01002b0:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002b1:	a8 20                	test   $0x20,%al
f01002b3:	75 08                	jne    f01002bd <cons_putc+0x34>
f01002b5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002bb:	7e e8                	jle    f01002a5 <cons_putc+0x1c>
f01002bd:	89 f8                	mov    %edi,%eax
f01002bf:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c2:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002c7:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002c8:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002cd:	be 79 03 00 00       	mov    $0x379,%esi
f01002d2:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d7:	eb 09                	jmp    f01002e2 <cons_putc+0x59>
f01002d9:	89 ca                	mov    %ecx,%edx
f01002db:	ec                   	in     (%dx),%al
f01002dc:	ec                   	in     (%dx),%al
f01002dd:	ec                   	in     (%dx),%al
f01002de:	ec                   	in     (%dx),%al
f01002df:	83 c3 01             	add    $0x1,%ebx
f01002e2:	89 f2                	mov    %esi,%edx
f01002e4:	ec                   	in     (%dx),%al
f01002e5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002eb:	7f 04                	jg     f01002f1 <cons_putc+0x68>
f01002ed:	84 c0                	test   %al,%al
f01002ef:	79 e8                	jns    f01002d9 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f1:	ba 78 03 00 00       	mov    $0x378,%edx
f01002f6:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01002fa:	ee                   	out    %al,(%dx)
f01002fb:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100300:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100305:	ee                   	out    %al,(%dx)
f0100306:	b8 08 00 00 00       	mov    $0x8,%eax
f010030b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010030c:	89 fa                	mov    %edi,%edx
f010030e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100314:	89 f8                	mov    %edi,%eax
f0100316:	80 cc 07             	or     $0x7,%ah
f0100319:	85 d2                	test   %edx,%edx
f010031b:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010031e:	89 f8                	mov    %edi,%eax
f0100320:	0f b6 c0             	movzbl %al,%eax
f0100323:	83 f8 09             	cmp    $0x9,%eax
f0100326:	74 74                	je     f010039c <cons_putc+0x113>
f0100328:	83 f8 09             	cmp    $0x9,%eax
f010032b:	7f 0a                	jg     f0100337 <cons_putc+0xae>
f010032d:	83 f8 08             	cmp    $0x8,%eax
f0100330:	74 14                	je     f0100346 <cons_putc+0xbd>
f0100332:	e9 99 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
f0100337:	83 f8 0a             	cmp    $0xa,%eax
f010033a:	74 3a                	je     f0100376 <cons_putc+0xed>
f010033c:	83 f8 0d             	cmp    $0xd,%eax
f010033f:	74 3d                	je     f010037e <cons_putc+0xf5>
f0100341:	e9 8a 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100346:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010034d:	66 85 c0             	test   %ax,%ax
f0100350:	0f 84 e6 00 00 00    	je     f010043c <cons_putc+0x1b3>
			crt_pos--;
f0100356:	83 e8 01             	sub    $0x1,%eax
f0100359:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010035f:	0f b7 c0             	movzwl %ax,%eax
f0100362:	66 81 e7 00 ff       	and    $0xff00,%di
f0100367:	83 cf 20             	or     $0x20,%edi
f010036a:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100370:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100374:	eb 78                	jmp    f01003ee <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100376:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f010037d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010037e:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100385:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010038b:	c1 e8 16             	shr    $0x16,%eax
f010038e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100391:	c1 e0 04             	shl    $0x4,%eax
f0100394:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f010039a:	eb 52                	jmp    f01003ee <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f010039c:	b8 20 00 00 00       	mov    $0x20,%eax
f01003a1:	e8 e3 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003a6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ab:	e8 d9 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003b0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b5:	e8 cf fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003ba:	b8 20 00 00 00       	mov    $0x20,%eax
f01003bf:	e8 c5 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c9:	e8 bb fe ff ff       	call   f0100289 <cons_putc>
f01003ce:	eb 1e                	jmp    f01003ee <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003d0:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003d7:	8d 50 01             	lea    0x1(%eax),%edx
f01003da:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f01003e1:	0f b7 c0             	movzwl %ax,%eax
f01003e4:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003ea:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ee:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f01003f5:	cf 07 
f01003f7:	76 43                	jbe    f010043c <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003f9:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f01003fe:	83 ec 04             	sub    $0x4,%esp
f0100401:	68 00 0f 00 00       	push   $0xf00
f0100406:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010040c:	52                   	push   %edx
f010040d:	50                   	push   %eax
f010040e:	e8 ca 2e 00 00       	call   f01032dd <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100413:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100419:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010041f:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100425:	83 c4 10             	add    $0x10,%esp
f0100428:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010042d:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100430:	39 d0                	cmp    %edx,%eax
f0100432:	75 f4                	jne    f0100428 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100434:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f010043b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010043c:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100442:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100447:	89 ca                	mov    %ecx,%edx
f0100449:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010044a:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f0100451:	8d 71 01             	lea    0x1(%ecx),%esi
f0100454:	89 d8                	mov    %ebx,%eax
f0100456:	66 c1 e8 08          	shr    $0x8,%ax
f010045a:	89 f2                	mov    %esi,%edx
f010045c:	ee                   	out    %al,(%dx)
f010045d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100462:	89 ca                	mov    %ecx,%edx
f0100464:	ee                   	out    %al,(%dx)
f0100465:	89 d8                	mov    %ebx,%eax
f0100467:	89 f2                	mov    %esi,%edx
f0100469:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010046a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010046d:	5b                   	pop    %ebx
f010046e:	5e                   	pop    %esi
f010046f:	5f                   	pop    %edi
f0100470:	5d                   	pop    %ebp
f0100471:	c3                   	ret    

f0100472 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100472:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f0100479:	74 11                	je     f010048c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010047b:	55                   	push   %ebp
f010047c:	89 e5                	mov    %esp,%ebp
f010047e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100481:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100486:	e8 b0 fc ff ff       	call   f010013b <cons_intr>
}
f010048b:	c9                   	leave  
f010048c:	f3 c3                	repz ret 

f010048e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010048e:	55                   	push   %ebp
f010048f:	89 e5                	mov    %esp,%ebp
f0100491:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100494:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f0100499:	e8 9d fc ff ff       	call   f010013b <cons_intr>
}
f010049e:	c9                   	leave  
f010049f:	c3                   	ret    

f01004a0 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004a6:	e8 c7 ff ff ff       	call   f0100472 <serial_intr>
	kbd_intr();
f01004ab:	e8 de ff ff ff       	call   f010048e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004b0:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004b5:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004bb:	74 26                	je     f01004e3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004bd:	8d 50 01             	lea    0x1(%eax),%edx
f01004c0:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004c6:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004cd:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004cf:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004d5:	75 11                	jne    f01004e8 <cons_getc+0x48>
			cons.rpos = 0;
f01004d7:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f01004de:	00 00 00 
f01004e1:	eb 05                	jmp    f01004e8 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004e8:	c9                   	leave  
f01004e9:	c3                   	ret    

f01004ea <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ea:	55                   	push   %ebp
f01004eb:	89 e5                	mov    %esp,%ebp
f01004ed:	57                   	push   %edi
f01004ee:	56                   	push   %esi
f01004ef:	53                   	push   %ebx
f01004f0:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004f3:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01004fa:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100501:	5a a5 
	if (*cp != 0xA55A) {
f0100503:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010050a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010050e:	74 11                	je     f0100521 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100510:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f0100517:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010051a:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010051f:	eb 16                	jmp    f0100537 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100521:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100528:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f010052f:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100532:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100537:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
f010053d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100542:	89 fa                	mov    %edi,%edx
f0100544:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100545:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100548:	89 da                	mov    %ebx,%edx
f010054a:	ec                   	in     (%dx),%al
f010054b:	0f b6 c8             	movzbl %al,%ecx
f010054e:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100551:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100556:	89 fa                	mov    %edi,%edx
f0100558:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100559:	89 da                	mov    %ebx,%edx
f010055b:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010055c:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f0100562:	0f b6 c0             	movzbl %al,%eax
f0100565:	09 c8                	or     %ecx,%eax
f0100567:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010056d:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100572:	b8 00 00 00 00       	mov    $0x0,%eax
f0100577:	89 f2                	mov    %esi,%edx
f0100579:	ee                   	out    %al,(%dx)
f010057a:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010057f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100584:	ee                   	out    %al,(%dx)
f0100585:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010058a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010058f:	89 da                	mov    %ebx,%edx
f0100591:	ee                   	out    %al,(%dx)
f0100592:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100597:	b8 00 00 00 00       	mov    $0x0,%eax
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 03 00 00 00       	mov    $0x3,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b2:	ee                   	out    %al,(%dx)
f01005b3:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005b8:	b8 01 00 00 00       	mov    $0x1,%eax
f01005bd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005be:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005c3:	ec                   	in     (%dx),%al
f01005c4:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c6:	3c ff                	cmp    $0xff,%al
f01005c8:	0f 95 05 34 75 11 f0 	setne  0xf0117534
f01005cf:	89 f2                	mov    %esi,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 da                	mov    %ebx,%edx
f01005d4:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d5:	80 f9 ff             	cmp    $0xff,%cl
f01005d8:	75 10                	jne    f01005ea <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005da:	83 ec 0c             	sub    $0xc,%esp
f01005dd:	68 99 37 10 f0       	push   $0xf0103799
f01005e2:	e8 c0 21 00 00       	call   f01027a7 <cprintf>
f01005e7:	83 c4 10             	add    $0x10,%esp
}
f01005ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005ed:	5b                   	pop    %ebx
f01005ee:	5e                   	pop    %esi
f01005ef:	5f                   	pop    %edi
f01005f0:	5d                   	pop    %ebp
f01005f1:	c3                   	ret    

f01005f2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f2:	55                   	push   %ebp
f01005f3:	89 e5                	mov    %esp,%ebp
f01005f5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fb:	e8 89 fc ff ff       	call   f0100289 <cons_putc>
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <getchar>:

int
getchar(void)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100608:	e8 93 fe ff ff       	call   f01004a0 <cons_getc>
f010060d:	85 c0                	test   %eax,%eax
f010060f:	74 f7                	je     f0100608 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <iscons>:

int
iscons(int fdnum)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100616:	b8 01 00 00 00       	mov    $0x1,%eax
f010061b:	5d                   	pop    %ebp
f010061c:	c3                   	ret    

f010061d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010061d:	55                   	push   %ebp
f010061e:	89 e5                	mov    %esp,%ebp
f0100620:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100623:	68 e0 39 10 f0       	push   $0xf01039e0
f0100628:	68 fe 39 10 f0       	push   $0xf01039fe
f010062d:	68 03 3a 10 f0       	push   $0xf0103a03
f0100632:	e8 70 21 00 00       	call   f01027a7 <cprintf>
f0100637:	83 c4 0c             	add    $0xc,%esp
f010063a:	68 a0 3a 10 f0       	push   $0xf0103aa0
f010063f:	68 0c 3a 10 f0       	push   $0xf0103a0c
f0100644:	68 03 3a 10 f0       	push   $0xf0103a03
f0100649:	e8 59 21 00 00       	call   f01027a7 <cprintf>
f010064e:	83 c4 0c             	add    $0xc,%esp
f0100651:	68 c8 3a 10 f0       	push   $0xf0103ac8
f0100656:	68 15 3a 10 f0       	push   $0xf0103a15
f010065b:	68 03 3a 10 f0       	push   $0xf0103a03
f0100660:	e8 42 21 00 00       	call   f01027a7 <cprintf>
	return 0;
}
f0100665:	b8 00 00 00 00       	mov    $0x0,%eax
f010066a:	c9                   	leave  
f010066b:	c3                   	ret    

f010066c <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010066c:	55                   	push   %ebp
f010066d:	89 e5                	mov    %esp,%ebp
f010066f:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100672:	68 1f 3a 10 f0       	push   $0xf0103a1f
f0100677:	e8 2b 21 00 00       	call   f01027a7 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010067c:	83 c4 08             	add    $0x8,%esp
f010067f:	68 0c 00 10 00       	push   $0x10000c
f0100684:	68 ec 3a 10 f0       	push   $0xf0103aec
f0100689:	e8 19 21 00 00       	call   f01027a7 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068e:	83 c4 0c             	add    $0xc,%esp
f0100691:	68 0c 00 10 00       	push   $0x10000c
f0100696:	68 0c 00 10 f0       	push   $0xf010000c
f010069b:	68 14 3b 10 f0       	push   $0xf0103b14
f01006a0:	e8 02 21 00 00       	call   f01027a7 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a5:	83 c4 0c             	add    $0xc,%esp
f01006a8:	68 21 37 10 00       	push   $0x103721
f01006ad:	68 21 37 10 f0       	push   $0xf0103721
f01006b2:	68 38 3b 10 f0       	push   $0xf0103b38
f01006b7:	e8 eb 20 00 00       	call   f01027a7 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006bc:	83 c4 0c             	add    $0xc,%esp
f01006bf:	68 00 73 11 00       	push   $0x117300
f01006c4:	68 00 73 11 f0       	push   $0xf0117300
f01006c9:	68 5c 3b 10 f0       	push   $0xf0103b5c
f01006ce:	e8 d4 20 00 00       	call   f01027a7 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d3:	83 c4 0c             	add    $0xc,%esp
f01006d6:	68 70 79 11 00       	push   $0x117970
f01006db:	68 70 79 11 f0       	push   $0xf0117970
f01006e0:	68 80 3b 10 f0       	push   $0xf0103b80
f01006e5:	e8 bd 20 00 00       	call   f01027a7 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006ea:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f01006ef:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006f4:	83 c4 08             	add    $0x8,%esp
f01006f7:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006fc:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100702:	85 c0                	test   %eax,%eax
f0100704:	0f 48 c2             	cmovs  %edx,%eax
f0100707:	c1 f8 0a             	sar    $0xa,%eax
f010070a:	50                   	push   %eax
f010070b:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100710:	e8 92 20 00 00       	call   f01027a7 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100715:	b8 00 00 00 00       	mov    $0x0,%eax
f010071a:	c9                   	leave  
f010071b:	c3                   	ret    

f010071c <mon_backtrace>:
#define EIP(v)  ((uint32_t)*(v+1))
#define ARG(v, c) ((uint32_t)*((v)+(c)+2))

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010071c:	55                   	push   %ebp
f010071d:	89 e5                	mov    %esp,%ebp
f010071f:	57                   	push   %edi
f0100720:	56                   	push   %esi
f0100721:	53                   	push   %ebx
f0100722:	81 ec 34 01 00 00    	sub    $0x134,%esp
	char format[FORMATLEN];
    char details[FORMATLEN];
    strcpy(format, "  ebp %08x  eip  %08x  args %08x %08x %08x %08x %08x\n");
f0100728:	68 d0 3b 10 f0       	push   $0xf0103bd0
f010072d:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f0100733:	50                   	push   %eax
f0100734:	e8 12 2a 00 00       	call   f010314b <strcpy>
    strcpy(details, "       %s:%d: %.*s+%d\n");
f0100739:	83 c4 08             	add    $0x8,%esp
f010073c:	68 38 3a 10 f0       	push   $0xf0103a38
f0100741:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
f0100747:	50                   	push   %eax
f0100748:	e8 fe 29 00 00       	call   f010314b <strcpy>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010074d:	89 eb                	mov    %ebp,%ebx
    
    uint32_t *ebpAddr = (uint32_t *) read_ebp();
    struct Eipdebuginfo info;
    
    cprintf("Stack backtrace:\n");
f010074f:	c7 04 24 4f 3a 10 f0 	movl   $0xf0103a4f,(%esp)
f0100756:	e8 4c 20 00 00       	call   f01027a7 <cprintf>
    while (ebpAddr) {
f010075b:	83 c4 10             	add    $0x10,%esp
        debuginfo_eip(EIP(ebpAddr), &info);
f010075e:	8d bd d0 fe ff ff    	lea    -0x130(%ebp),%edi

        cprintf(format, EBP(ebpAddr), EIP(ebpAddr), ARG(ebpAddr, 0), ARG(ebpAddr, 1), ARG(ebpAddr, 2), ARG(ebpAddr, 3), ARG(ebpAddr, 4));
f0100764:	8d b5 68 ff ff ff    	lea    -0x98(%ebp),%esi
    
    uint32_t *ebpAddr = (uint32_t *) read_ebp();
    struct Eipdebuginfo info;
    
    cprintf("Stack backtrace:\n");
    while (ebpAddr) {
f010076a:	eb 5b                	jmp    f01007c7 <mon_backtrace+0xab>
        debuginfo_eip(EIP(ebpAddr), &info);
f010076c:	83 ec 08             	sub    $0x8,%esp
f010076f:	57                   	push   %edi
f0100770:	ff 73 04             	pushl  0x4(%ebx)
f0100773:	e8 39 21 00 00       	call   f01028b1 <debuginfo_eip>

        cprintf(format, EBP(ebpAddr), EIP(ebpAddr), ARG(ebpAddr, 0), ARG(ebpAddr, 1), ARG(ebpAddr, 2), ARG(ebpAddr, 3), ARG(ebpAddr, 4));
f0100778:	ff 73 18             	pushl  0x18(%ebx)
f010077b:	ff 73 14             	pushl  0x14(%ebx)
f010077e:	ff 73 10             	pushl  0x10(%ebx)
f0100781:	ff 73 0c             	pushl  0xc(%ebx)
f0100784:	ff 73 08             	pushl  0x8(%ebx)
f0100787:	ff 73 04             	pushl  0x4(%ebx)
f010078a:	53                   	push   %ebx
f010078b:	56                   	push   %esi
f010078c:	e8 16 20 00 00       	call   f01027a7 <cprintf>
        cprintf(details, info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, EIP(ebpAddr)-info.eip_fn_addr);
f0100791:	83 c4 28             	add    $0x28,%esp
f0100794:	8b 43 04             	mov    0x4(%ebx),%eax
f0100797:	2b 85 e0 fe ff ff    	sub    -0x120(%ebp),%eax
f010079d:	50                   	push   %eax
f010079e:	ff b5 d8 fe ff ff    	pushl  -0x128(%ebp)
f01007a4:	ff b5 dc fe ff ff    	pushl  -0x124(%ebp)
f01007aa:	ff b5 d4 fe ff ff    	pushl  -0x12c(%ebp)
f01007b0:	ff b5 d0 fe ff ff    	pushl  -0x130(%ebp)
f01007b6:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
f01007bc:	50                   	push   %eax
f01007bd:	e8 e5 1f 00 00       	call   f01027a7 <cprintf>
        ebpAddr = (uint32_t *)(*ebpAddr);
f01007c2:	8b 1b                	mov    (%ebx),%ebx
f01007c4:	83 c4 20             	add    $0x20,%esp
    
    uint32_t *ebpAddr = (uint32_t *) read_ebp();
    struct Eipdebuginfo info;
    
    cprintf("Stack backtrace:\n");
    while (ebpAddr) {
f01007c7:	85 db                	test   %ebx,%ebx
f01007c9:	75 a1                	jne    f010076c <mon_backtrace+0x50>
        cprintf(details, info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, EIP(ebpAddr)-info.eip_fn_addr);
        ebpAddr = (uint32_t *)(*ebpAddr);
    }

	return 0;
}
f01007cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007d3:	5b                   	pop    %ebx
f01007d4:	5e                   	pop    %esi
f01007d5:	5f                   	pop    %edi
f01007d6:	5d                   	pop    %ebp
f01007d7:	c3                   	ret    

f01007d8 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007d8:	55                   	push   %ebp
f01007d9:	89 e5                	mov    %esp,%ebp
f01007db:	57                   	push   %edi
f01007dc:	56                   	push   %esi
f01007dd:	53                   	push   %ebx
f01007de:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007e1:	68 08 3c 10 f0       	push   $0xf0103c08
f01007e6:	e8 bc 1f 00 00       	call   f01027a7 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007eb:	c7 04 24 2c 3c 10 f0 	movl   $0xf0103c2c,(%esp)
f01007f2:	e8 b0 1f 00 00       	call   f01027a7 <cprintf>
f01007f7:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007fa:	83 ec 0c             	sub    $0xc,%esp
f01007fd:	68 61 3a 10 f0       	push   $0xf0103a61
f0100802:	e8 32 28 00 00       	call   f0103039 <readline>
f0100807:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100809:	83 c4 10             	add    $0x10,%esp
f010080c:	85 c0                	test   %eax,%eax
f010080e:	74 ea                	je     f01007fa <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100810:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100817:	be 00 00 00 00       	mov    $0x0,%esi
f010081c:	eb 0a                	jmp    f0100828 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010081e:	c6 03 00             	movb   $0x0,(%ebx)
f0100821:	89 f7                	mov    %esi,%edi
f0100823:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100826:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100828:	0f b6 03             	movzbl (%ebx),%eax
f010082b:	84 c0                	test   %al,%al
f010082d:	74 63                	je     f0100892 <monitor+0xba>
f010082f:	83 ec 08             	sub    $0x8,%esp
f0100832:	0f be c0             	movsbl %al,%eax
f0100835:	50                   	push   %eax
f0100836:	68 65 3a 10 f0       	push   $0xf0103a65
f010083b:	e8 13 2a 00 00       	call   f0103253 <strchr>
f0100840:	83 c4 10             	add    $0x10,%esp
f0100843:	85 c0                	test   %eax,%eax
f0100845:	75 d7                	jne    f010081e <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100847:	80 3b 00             	cmpb   $0x0,(%ebx)
f010084a:	74 46                	je     f0100892 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010084c:	83 fe 0f             	cmp    $0xf,%esi
f010084f:	75 14                	jne    f0100865 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100851:	83 ec 08             	sub    $0x8,%esp
f0100854:	6a 10                	push   $0x10
f0100856:	68 6a 3a 10 f0       	push   $0xf0103a6a
f010085b:	e8 47 1f 00 00       	call   f01027a7 <cprintf>
f0100860:	83 c4 10             	add    $0x10,%esp
f0100863:	eb 95                	jmp    f01007fa <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100865:	8d 7e 01             	lea    0x1(%esi),%edi
f0100868:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010086c:	eb 03                	jmp    f0100871 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010086e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100871:	0f b6 03             	movzbl (%ebx),%eax
f0100874:	84 c0                	test   %al,%al
f0100876:	74 ae                	je     f0100826 <monitor+0x4e>
f0100878:	83 ec 08             	sub    $0x8,%esp
f010087b:	0f be c0             	movsbl %al,%eax
f010087e:	50                   	push   %eax
f010087f:	68 65 3a 10 f0       	push   $0xf0103a65
f0100884:	e8 ca 29 00 00       	call   f0103253 <strchr>
f0100889:	83 c4 10             	add    $0x10,%esp
f010088c:	85 c0                	test   %eax,%eax
f010088e:	74 de                	je     f010086e <monitor+0x96>
f0100890:	eb 94                	jmp    f0100826 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100892:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100899:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010089a:	85 f6                	test   %esi,%esi
f010089c:	0f 84 58 ff ff ff    	je     f01007fa <monitor+0x22>
f01008a2:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008a7:	83 ec 08             	sub    $0x8,%esp
f01008aa:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008ad:	ff 34 85 60 3c 10 f0 	pushl  -0xfefc3a0(,%eax,4)
f01008b4:	ff 75 a8             	pushl  -0x58(%ebp)
f01008b7:	e8 39 29 00 00       	call   f01031f5 <strcmp>
f01008bc:	83 c4 10             	add    $0x10,%esp
f01008bf:	85 c0                	test   %eax,%eax
f01008c1:	75 21                	jne    f01008e4 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008c3:	83 ec 04             	sub    $0x4,%esp
f01008c6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008c9:	ff 75 08             	pushl  0x8(%ebp)
f01008cc:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008cf:	52                   	push   %edx
f01008d0:	56                   	push   %esi
f01008d1:	ff 14 85 68 3c 10 f0 	call   *-0xfefc398(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008d8:	83 c4 10             	add    $0x10,%esp
f01008db:	85 c0                	test   %eax,%eax
f01008dd:	78 25                	js     f0100904 <monitor+0x12c>
f01008df:	e9 16 ff ff ff       	jmp    f01007fa <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008e4:	83 c3 01             	add    $0x1,%ebx
f01008e7:	83 fb 03             	cmp    $0x3,%ebx
f01008ea:	75 bb                	jne    f01008a7 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008ec:	83 ec 08             	sub    $0x8,%esp
f01008ef:	ff 75 a8             	pushl  -0x58(%ebp)
f01008f2:	68 87 3a 10 f0       	push   $0xf0103a87
f01008f7:	e8 ab 1e 00 00       	call   f01027a7 <cprintf>
f01008fc:	83 c4 10             	add    $0x10,%esp
f01008ff:	e9 f6 fe ff ff       	jmp    f01007fa <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100904:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100907:	5b                   	pop    %ebx
f0100908:	5e                   	pop    %esi
f0100909:	5f                   	pop    %edi
f010090a:	5d                   	pop    %ebp
f010090b:	c3                   	ret    

f010090c <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010090c:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100913:	75 11                	jne    f0100926 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100915:	ba 6f 89 11 f0       	mov    $0xf011896f,%edx
f010091a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100920:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0) {
f0100926:	85 c0                	test   %eax,%eax
f0100928:	75 06                	jne    f0100930 <boot_alloc+0x24>
		return nextfree;
f010092a:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f010092f:	c3                   	ret    
	}

	if(nextfree + n <= nextfree) {
f0100930:	8b 0d 38 75 11 f0    	mov    0xf0117538,%ecx
f0100936:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f0100939:	39 d1                	cmp    %edx,%ecx
f010093b:	72 17                	jb     f0100954 <boot_alloc+0x48>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f010093d:	55                   	push   %ebp
f010093e:	89 e5                	mov    %esp,%ebp
f0100940:	83 ec 0c             	sub    $0xc,%esp
	if(n == 0) {
		return nextfree;
	}

	if(nextfree + n <= nextfree) {
		panic("out of memory!");
f0100943:	68 84 3c 10 f0       	push   $0xf0103c84
f0100948:	6a 6a                	push   $0x6a
f010094a:	68 93 3c 10 f0       	push   $0xf0103c93
f010094f:	e8 37 f7 ff ff       	call   f010008b <_panic>
	}

	result = nextfree;
	nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100954:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f010095a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100960:	89 15 38 75 11 f0    	mov    %edx,0xf0117538

	return result;
f0100966:	89 c8                	mov    %ecx,%eax
}
f0100968:	c3                   	ret    

f0100969 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100969:	89 d1                	mov    %edx,%ecx
f010096b:	c1 e9 16             	shr    $0x16,%ecx
f010096e:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100971:	a8 01                	test   $0x1,%al
f0100973:	74 52                	je     f01009c7 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100975:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010097a:	89 c1                	mov    %eax,%ecx
f010097c:	c1 e9 0c             	shr    $0xc,%ecx
f010097f:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100985:	72 1b                	jb     f01009a2 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100987:	55                   	push   %ebp
f0100988:	89 e5                	mov    %esp,%ebp
f010098a:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010098d:	50                   	push   %eax
f010098e:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0100993:	68 e5 02 00 00       	push   $0x2e5
f0100998:	68 93 3c 10 f0       	push   $0xf0103c93
f010099d:	e8 e9 f6 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009a2:	c1 ea 0c             	shr    $0xc,%edx
f01009a5:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009ab:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009b2:	89 c2                	mov    %eax,%edx
f01009b4:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009b7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009bc:	85 d2                	test   %edx,%edx
f01009be:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009c3:	0f 44 c2             	cmove  %edx,%eax
f01009c6:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009cc:	c3                   	ret    

f01009cd <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009cd:	55                   	push   %ebp
f01009ce:	89 e5                	mov    %esp,%ebp
f01009d0:	57                   	push   %edi
f01009d1:	56                   	push   %esi
f01009d2:	53                   	push   %ebx
f01009d3:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009d6:	84 c0                	test   %al,%al
f01009d8:	0f 85 72 02 00 00    	jne    f0100c50 <check_page_free_list+0x283>
f01009de:	e9 7f 02 00 00       	jmp    f0100c62 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009e3:	83 ec 04             	sub    $0x4,%esp
f01009e6:	68 c0 3f 10 f0       	push   $0xf0103fc0
f01009eb:	68 28 02 00 00       	push   $0x228
f01009f0:	68 93 3c 10 f0       	push   $0xf0103c93
f01009f5:	e8 91 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009fa:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009fd:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a00:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a03:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a06:	89 c2                	mov    %eax,%edx
f0100a08:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0100a0e:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a14:	0f 95 c2             	setne  %dl
f0100a17:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a1a:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a1e:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a20:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a24:	8b 00                	mov    (%eax),%eax
f0100a26:	85 c0                	test   %eax,%eax
f0100a28:	75 dc                	jne    f0100a06 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a2a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a2d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a33:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a36:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a39:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a3b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a3e:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a43:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a48:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100a4e:	eb 53                	jmp    f0100aa3 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a50:	89 d8                	mov    %ebx,%eax
f0100a52:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100a58:	c1 f8 03             	sar    $0x3,%eax
f0100a5b:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a5e:	89 c2                	mov    %eax,%edx
f0100a60:	c1 ea 16             	shr    $0x16,%edx
f0100a63:	39 f2                	cmp    %esi,%edx
f0100a65:	73 3a                	jae    f0100aa1 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a67:	89 c2                	mov    %eax,%edx
f0100a69:	c1 ea 0c             	shr    $0xc,%edx
f0100a6c:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100a72:	72 12                	jb     f0100a86 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a74:	50                   	push   %eax
f0100a75:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0100a7a:	6a 52                	push   $0x52
f0100a7c:	68 9f 3c 10 f0       	push   $0xf0103c9f
f0100a81:	e8 05 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a86:	83 ec 04             	sub    $0x4,%esp
f0100a89:	68 80 00 00 00       	push   $0x80
f0100a8e:	68 97 00 00 00       	push   $0x97
f0100a93:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a98:	50                   	push   %eax
f0100a99:	e8 f2 27 00 00       	call   f0103290 <memset>
f0100a9e:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100aa1:	8b 1b                	mov    (%ebx),%ebx
f0100aa3:	85 db                	test   %ebx,%ebx
f0100aa5:	75 a9                	jne    f0100a50 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100aa7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100aac:	e8 5b fe ff ff       	call   f010090c <boot_alloc>
f0100ab1:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ab4:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aba:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100ac0:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100ac5:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100ac8:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100acb:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ace:	be 00 00 00 00       	mov    $0x0,%esi
f0100ad3:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ad6:	e9 30 01 00 00       	jmp    f0100c0b <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100adb:	39 ca                	cmp    %ecx,%edx
f0100add:	73 19                	jae    f0100af8 <check_page_free_list+0x12b>
f0100adf:	68 ad 3c 10 f0       	push   $0xf0103cad
f0100ae4:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0100ae9:	68 42 02 00 00       	push   $0x242
f0100aee:	68 93 3c 10 f0       	push   $0xf0103c93
f0100af3:	e8 93 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100af8:	39 fa                	cmp    %edi,%edx
f0100afa:	72 19                	jb     f0100b15 <check_page_free_list+0x148>
f0100afc:	68 ce 3c 10 f0       	push   $0xf0103cce
f0100b01:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0100b06:	68 43 02 00 00       	push   $0x243
f0100b0b:	68 93 3c 10 f0       	push   $0xf0103c93
f0100b10:	e8 76 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b15:	89 d0                	mov    %edx,%eax
f0100b17:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b1a:	a8 07                	test   $0x7,%al
f0100b1c:	74 19                	je     f0100b37 <check_page_free_list+0x16a>
f0100b1e:	68 e4 3f 10 f0       	push   $0xf0103fe4
f0100b23:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0100b28:	68 44 02 00 00       	push   $0x244
f0100b2d:	68 93 3c 10 f0       	push   $0xf0103c93
f0100b32:	e8 54 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b37:	c1 f8 03             	sar    $0x3,%eax
f0100b3a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b3d:	85 c0                	test   %eax,%eax
f0100b3f:	75 19                	jne    f0100b5a <check_page_free_list+0x18d>
f0100b41:	68 e2 3c 10 f0       	push   $0xf0103ce2
f0100b46:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0100b4b:	68 47 02 00 00       	push   $0x247
f0100b50:	68 93 3c 10 f0       	push   $0xf0103c93
f0100b55:	e8 31 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b5a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b5f:	75 19                	jne    f0100b7a <check_page_free_list+0x1ad>
f0100b61:	68 f3 3c 10 f0       	push   $0xf0103cf3
f0100b66:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0100b6b:	68 48 02 00 00       	push   $0x248
f0100b70:	68 93 3c 10 f0       	push   $0xf0103c93
f0100b75:	e8 11 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b7a:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b7f:	75 19                	jne    f0100b9a <check_page_free_list+0x1cd>
f0100b81:	68 18 40 10 f0       	push   $0xf0104018
f0100b86:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0100b8b:	68 49 02 00 00       	push   $0x249
f0100b90:	68 93 3c 10 f0       	push   $0xf0103c93
f0100b95:	e8 f1 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b9a:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b9f:	75 19                	jne    f0100bba <check_page_free_list+0x1ed>
f0100ba1:	68 0c 3d 10 f0       	push   $0xf0103d0c
f0100ba6:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0100bab:	68 4a 02 00 00       	push   $0x24a
f0100bb0:	68 93 3c 10 f0       	push   $0xf0103c93
f0100bb5:	e8 d1 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bba:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bbf:	76 3f                	jbe    f0100c00 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bc1:	89 c3                	mov    %eax,%ebx
f0100bc3:	c1 eb 0c             	shr    $0xc,%ebx
f0100bc6:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100bc9:	77 12                	ja     f0100bdd <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bcb:	50                   	push   %eax
f0100bcc:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0100bd1:	6a 52                	push   $0x52
f0100bd3:	68 9f 3c 10 f0       	push   $0xf0103c9f
f0100bd8:	e8 ae f4 ff ff       	call   f010008b <_panic>
f0100bdd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100be2:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100be5:	76 1e                	jbe    f0100c05 <check_page_free_list+0x238>
f0100be7:	68 3c 40 10 f0       	push   $0xf010403c
f0100bec:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0100bf1:	68 4b 02 00 00       	push   $0x24b
f0100bf6:	68 93 3c 10 f0       	push   $0xf0103c93
f0100bfb:	e8 8b f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c00:	83 c6 01             	add    $0x1,%esi
f0100c03:	eb 04                	jmp    f0100c09 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c05:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c09:	8b 12                	mov    (%edx),%edx
f0100c0b:	85 d2                	test   %edx,%edx
f0100c0d:	0f 85 c8 fe ff ff    	jne    f0100adb <check_page_free_list+0x10e>
f0100c13:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c16:	85 f6                	test   %esi,%esi
f0100c18:	7f 19                	jg     f0100c33 <check_page_free_list+0x266>
f0100c1a:	68 26 3d 10 f0       	push   $0xf0103d26
f0100c1f:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0100c24:	68 53 02 00 00       	push   $0x253
f0100c29:	68 93 3c 10 f0       	push   $0xf0103c93
f0100c2e:	e8 58 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c33:	85 db                	test   %ebx,%ebx
f0100c35:	7f 42                	jg     f0100c79 <check_page_free_list+0x2ac>
f0100c37:	68 38 3d 10 f0       	push   $0xf0103d38
f0100c3c:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0100c41:	68 54 02 00 00       	push   $0x254
f0100c46:	68 93 3c 10 f0       	push   $0xf0103c93
f0100c4b:	e8 3b f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c50:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100c55:	85 c0                	test   %eax,%eax
f0100c57:	0f 85 9d fd ff ff    	jne    f01009fa <check_page_free_list+0x2d>
f0100c5d:	e9 81 fd ff ff       	jmp    f01009e3 <check_page_free_list+0x16>
f0100c62:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100c69:	0f 84 74 fd ff ff    	je     f01009e3 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c6f:	be 00 04 00 00       	mov    $0x400,%esi
f0100c74:	e9 cf fd ff ff       	jmp    f0100a48 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c79:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c7c:	5b                   	pop    %ebx
f0100c7d:	5e                   	pop    %esi
f0100c7e:	5f                   	pop    %edi
f0100c7f:	5d                   	pop    %ebp
f0100c80:	c3                   	ret    

f0100c81 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c81:	55                   	push   %ebp
f0100c82:	89 e5                	mov    %esp,%ebp
f0100c84:	56                   	push   %esi
f0100c85:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100c86:	be 00 00 00 00       	mov    $0x0,%esi
f0100c8b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c90:	e9 aa 00 00 00       	jmp    f0100d3f <page_init+0xbe>
		if(i < 1) {//page 0 allocated
f0100c95:	85 db                	test   %ebx,%ebx
f0100c97:	75 10                	jne    f0100ca9 <page_init+0x28>
			pages[i].pp_ref = 1;
f0100c99:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100c9e:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
f0100ca4:	e9 90 00 00 00       	jmp    f0100d39 <page_init+0xb8>
		} else if( i < npages_basemem) {//npages_basemem  free
f0100ca9:	3b 1d 40 75 11 f0    	cmp    0xf0117540,%ebx
f0100caf:	73 25                	jae    f0100cd6 <page_init+0x55>
			pages[i].pp_ref = 0;
f0100cb1:	89 f0                	mov    %esi,%eax
f0100cb3:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100cb9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100cbf:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100cc5:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100cc7:	89 f0                	mov    %esi,%eax
f0100cc9:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100ccf:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
f0100cd4:	eb 63                	jmp    f0100d39 <page_init+0xb8>
		} else if(i < PGNUM(PADDR(boot_alloc(0)))) {//pages allocated
f0100cd6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cdb:	e8 2c fc ff ff       	call   f010090c <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ce0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100ce5:	77 15                	ja     f0100cfc <page_init+0x7b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ce7:	50                   	push   %eax
f0100ce8:	68 84 40 10 f0       	push   $0xf0104084
f0100ced:	68 14 01 00 00       	push   $0x114
f0100cf2:	68 93 3c 10 f0       	push   $0xf0103c93
f0100cf7:	e8 8f f3 ff ff       	call   f010008b <_panic>
f0100cfc:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d01:	c1 e8 0c             	shr    $0xc,%eax
f0100d04:	39 c3                	cmp    %eax,%ebx
f0100d06:	73 0e                	jae    f0100d16 <page_init+0x95>
			pages[i].pp_ref = 1;
f0100d08:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100d0d:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
f0100d14:	eb 23                	jmp    f0100d39 <page_init+0xb8>
		} else {
			pages[i].pp_ref = 0;
f0100d16:	89 f0                	mov    %esi,%eax
f0100d18:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100d1e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100d24:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100d2a:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100d2c:	89 f0                	mov    %esi,%eax
f0100d2e:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100d34:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100d39:	83 c3 01             	add    $0x1,%ebx
f0100d3c:	83 c6 08             	add    $0x8,%esi
f0100d3f:	3b 1d 64 79 11 f0    	cmp    0xf0117964,%ebx
f0100d45:	0f 82 4a ff ff ff    	jb     f0100c95 <page_init+0x14>
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100d4b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d4e:	5b                   	pop    %ebx
f0100d4f:	5e                   	pop    %esi
f0100d50:	5d                   	pop    %ebp
f0100d51:	c3                   	ret    

f0100d52 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d52:	55                   	push   %ebp
f0100d53:	89 e5                	mov    %esp,%ebp
f0100d55:	53                   	push   %ebx
f0100d56:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if (!page_free_list) {
f0100d59:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100d5f:	85 db                	test   %ebx,%ebx
f0100d61:	74 5e                	je     f0100dc1 <page_alloc+0x6f>
        return NULL;
    }

    struct PageInfo *page = page_free_list;
    page_free_list = page_free_list->pp_link;
f0100d63:	8b 03                	mov    (%ebx),%eax
f0100d65:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
    page->pp_link = NULL;
f0100d6a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
    page->pp_ref = 0;
f0100d70:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

    if (alloc_flags & ALLOC_ZERO) {
f0100d76:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d7a:	74 45                	je     f0100dc1 <page_alloc+0x6f>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d7c:	89 d8                	mov    %ebx,%eax
f0100d7e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100d84:	c1 f8 03             	sar    $0x3,%eax
f0100d87:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d8a:	89 c2                	mov    %eax,%edx
f0100d8c:	c1 ea 0c             	shr    $0xc,%edx
f0100d8f:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100d95:	72 12                	jb     f0100da9 <page_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d97:	50                   	push   %eax
f0100d98:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0100d9d:	6a 52                	push   $0x52
f0100d9f:	68 9f 3c 10 f0       	push   $0xf0103c9f
f0100da4:	e8 e2 f2 ff ff       	call   f010008b <_panic>
        memset(page2kva(page), '\0', PGSIZE); 
f0100da9:	83 ec 04             	sub    $0x4,%esp
f0100dac:	68 00 10 00 00       	push   $0x1000
f0100db1:	6a 00                	push   $0x0
f0100db3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100db8:	50                   	push   %eax
f0100db9:	e8 d2 24 00 00       	call   f0103290 <memset>
f0100dbe:	83 c4 10             	add    $0x10,%esp
    }

	return page;
}
f0100dc1:	89 d8                	mov    %ebx,%eax
f0100dc3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100dc6:	c9                   	leave  
f0100dc7:	c3                   	ret    

f0100dc8 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100dc8:	55                   	push   %ebp
f0100dc9:	89 e5                	mov    %esp,%ebp
f0100dcb:	83 ec 08             	sub    $0x8,%esp
f0100dce:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	assert(pp->pp_ref == 0);
f0100dd1:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100dd6:	74 19                	je     f0100df1 <page_free+0x29>
f0100dd8:	68 49 3d 10 f0       	push   $0xf0103d49
f0100ddd:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0100de2:	68 48 01 00 00       	push   $0x148
f0100de7:	68 93 3c 10 f0       	push   $0xf0103c93
f0100dec:	e8 9a f2 ff ff       	call   f010008b <_panic>
	assert(pp->pp_link == NULL);
f0100df1:	83 38 00             	cmpl   $0x0,(%eax)
f0100df4:	74 19                	je     f0100e0f <page_free+0x47>
f0100df6:	68 59 3d 10 f0       	push   $0xf0103d59
f0100dfb:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0100e00:	68 49 01 00 00       	push   $0x149
f0100e05:	68 93 3c 10 f0       	push   $0xf0103c93
f0100e0a:	e8 7c f2 ff ff       	call   f010008b <_panic>

	 pp->pp_link = page_free_list;
f0100e0f:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e15:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e17:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100e1c:	c9                   	leave  
f0100e1d:	c3                   	ret    

f0100e1e <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e1e:	55                   	push   %ebp
f0100e1f:	89 e5                	mov    %esp,%ebp
f0100e21:	83 ec 08             	sub    $0x8,%esp
f0100e24:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e27:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e2b:	83 e8 01             	sub    $0x1,%eax
f0100e2e:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e32:	66 85 c0             	test   %ax,%ax
f0100e35:	75 0c                	jne    f0100e43 <page_decref+0x25>
		page_free(pp);
f0100e37:	83 ec 0c             	sub    $0xc,%esp
f0100e3a:	52                   	push   %edx
f0100e3b:	e8 88 ff ff ff       	call   f0100dc8 <page_free>
f0100e40:	83 c4 10             	add    $0x10,%esp
}
f0100e43:	c9                   	leave  
f0100e44:	c3                   	ret    

f0100e45 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e45:	55                   	push   %ebp
f0100e46:	89 e5                	mov    %esp,%ebp
f0100e48:	57                   	push   %edi
f0100e49:	56                   	push   %esi
f0100e4a:	53                   	push   %ebx
f0100e4b:	83 ec 0c             	sub    $0xc,%esp
f0100e4e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pde_t *pde;
    pte_t *pgtable;

    pde = &pgdir[PDX(va)];
f0100e51:	89 de                	mov    %ebx,%esi
f0100e53:	c1 ee 16             	shr    $0x16,%esi
f0100e56:	c1 e6 02             	shl    $0x2,%esi
f0100e59:	03 75 08             	add    0x8(%ebp),%esi
    if (*pde & PTE_P) {
f0100e5c:	8b 06                	mov    (%esi),%eax
f0100e5e:	a8 01                	test   $0x1,%al
f0100e60:	74 2f                	je     f0100e91 <pgdir_walk+0x4c>
        pgtable = KADDR(PTE_ADDR(*pde));
f0100e62:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e67:	89 c2                	mov    %eax,%edx
f0100e69:	c1 ea 0c             	shr    $0xc,%edx
f0100e6c:	39 15 64 79 11 f0    	cmp    %edx,0xf0117964
f0100e72:	77 15                	ja     f0100e89 <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e74:	50                   	push   %eax
f0100e75:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0100e7a:	68 78 01 00 00       	push   $0x178
f0100e7f:	68 93 3c 10 f0       	push   $0xf0103c93
f0100e84:	e8 02 f2 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100e89:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0100e8f:	eb 7d                	jmp    f0100f0e <pgdir_walk+0xc9>
    } else {
        if (create) {
f0100e91:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e95:	0f 84 81 00 00 00    	je     f0100f1c <pgdir_walk+0xd7>
            struct PageInfo *pp = page_alloc(ALLOC_ZERO);
f0100e9b:	83 ec 0c             	sub    $0xc,%esp
f0100e9e:	6a 01                	push   $0x1
f0100ea0:	e8 ad fe ff ff       	call   f0100d52 <page_alloc>
            if (!pp) {
f0100ea5:	83 c4 10             	add    $0x10,%esp
f0100ea8:	85 c0                	test   %eax,%eax
f0100eaa:	74 77                	je     f0100f23 <pgdir_walk+0xde>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100eac:	89 c1                	mov    %eax,%ecx
f0100eae:	2b 0d 6c 79 11 f0    	sub    0xf011796c,%ecx
f0100eb4:	c1 f9 03             	sar    $0x3,%ecx
f0100eb7:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eba:	89 ca                	mov    %ecx,%edx
f0100ebc:	c1 ea 0c             	shr    $0xc,%edx
f0100ebf:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100ec5:	72 12                	jb     f0100ed9 <pgdir_walk+0x94>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ec7:	51                   	push   %ecx
f0100ec8:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0100ecd:	6a 52                	push   $0x52
f0100ecf:	68 9f 3c 10 f0       	push   $0xf0103c9f
f0100ed4:	e8 b2 f1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100ed9:	8d b9 00 00 00 f0    	lea    -0x10000000(%ecx),%edi
f0100edf:	89 fa                	mov    %edi,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ee1:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0100ee7:	77 15                	ja     f0100efe <pgdir_walk+0xb9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ee9:	57                   	push   %edi
f0100eea:	68 84 40 10 f0       	push   $0xf0104084
f0100eef:	68 80 01 00 00       	push   $0x180
f0100ef4:	68 93 3c 10 f0       	push   $0xf0103c93
f0100ef9:	e8 8d f1 ff ff       	call   f010008b <_panic>
                return NULL;
            }
            pgtable = (pte_t *)page2kva(pp);
            *pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
f0100efe:	83 c9 07             	or     $0x7,%ecx
f0100f01:	89 0e                	mov    %ecx,(%esi)

            pp->pp_ref += 1;
f0100f03:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
            pp->pp_link = NULL;
f0100f08:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
            return NULL;
        }
    
    }
    
	return &pgtable[PTX(va)];
f0100f0e:	c1 eb 0a             	shr    $0xa,%ebx
f0100f11:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100f17:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
f0100f1a:	eb 0c                	jmp    f0100f28 <pgdir_walk+0xe3>

            pp->pp_ref += 1;
            pp->pp_link = NULL;
            
        } else {
            return NULL;
f0100f1c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f21:	eb 05                	jmp    f0100f28 <pgdir_walk+0xe3>
        pgtable = KADDR(PTE_ADDR(*pde));
    } else {
        if (create) {
            struct PageInfo *pp = page_alloc(ALLOC_ZERO);
            if (!pp) {
                return NULL;
f0100f23:	b8 00 00 00 00       	mov    $0x0,%eax
        }
    
    }
    
	return &pgtable[PTX(va)];
}
f0100f28:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f2b:	5b                   	pop    %ebx
f0100f2c:	5e                   	pop    %esi
f0100f2d:	5f                   	pop    %edi
f0100f2e:	5d                   	pop    %ebp
f0100f2f:	c3                   	ret    

f0100f30 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f30:	55                   	push   %ebp
f0100f31:	89 e5                	mov    %esp,%ebp
f0100f33:	57                   	push   %edi
f0100f34:	56                   	push   %esi
f0100f35:	53                   	push   %ebx
f0100f36:	83 ec 1c             	sub    $0x1c,%esp
f0100f39:	89 45 e0             	mov    %eax,-0x20(%ebp)
	// Fill this function in
	size = ROUNDUP(size, PGSIZE);
f0100f3c:	8d b9 ff 0f 00 00    	lea    0xfff(%ecx),%edi
f0100f42:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	for(; size > 0; size-=PGSIZE) {
f0100f48:	89 d6                	mov    %edx,%esi
f0100f4a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f4d:	29 d0                	sub    %edx,%eax
f0100f4f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		pte_t* pte_pointer = pgdir_walk(pgdir, (void *)va, 1);
		*pte_pointer = PTE_ADDR(pa) | perm | PTE_P;
f0100f52:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f55:	83 c8 01             	or     $0x1,%eax
f0100f58:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size = ROUNDUP(size, PGSIZE);
	for(; size > 0; size-=PGSIZE) {
f0100f5b:	eb 28                	jmp    f0100f85 <boot_map_region+0x55>
		pte_t* pte_pointer = pgdir_walk(pgdir, (void *)va, 1);
f0100f5d:	83 ec 04             	sub    $0x4,%esp
f0100f60:	6a 01                	push   $0x1
f0100f62:	56                   	push   %esi
f0100f63:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f66:	e8 da fe ff ff       	call   f0100e45 <pgdir_walk>
		*pte_pointer = PTE_ADDR(pa) | perm | PTE_P;
f0100f6b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0100f71:	0b 5d dc             	or     -0x24(%ebp),%ebx
f0100f74:	89 18                	mov    %ebx,(%eax)
		va += PGSIZE;
f0100f76:	81 c6 00 10 00 00    	add    $0x1000,%esi
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size = ROUNDUP(size, PGSIZE);
	for(; size > 0; size-=PGSIZE) {
f0100f7c:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f0100f82:	83 c4 10             	add    $0x10,%esp
f0100f85:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f88:	8d 1c 30             	lea    (%eax,%esi,1),%ebx
f0100f8b:	85 ff                	test   %edi,%edi
f0100f8d:	75 ce                	jne    f0100f5d <boot_map_region+0x2d>
		pte_t* pte_pointer = pgdir_walk(pgdir, (void *)va, 1);
		*pte_pointer = PTE_ADDR(pa) | perm | PTE_P;
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f0100f8f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f92:	5b                   	pop    %ebx
f0100f93:	5e                   	pop    %esi
f0100f94:	5f                   	pop    %edi
f0100f95:	5d                   	pop    %ebp
f0100f96:	c3                   	ret    

f0100f97 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f97:	55                   	push   %ebp
f0100f98:	89 e5                	mov    %esp,%ebp
f0100f9a:	53                   	push   %ebx
f0100f9b:	83 ec 08             	sub    $0x8,%esp
f0100f9e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte_pointer = pgdir_walk(pgdir, va, 0);
f0100fa1:	6a 00                	push   $0x0
f0100fa3:	ff 75 0c             	pushl  0xc(%ebp)
f0100fa6:	ff 75 08             	pushl  0x8(%ebp)
f0100fa9:	e8 97 fe ff ff       	call   f0100e45 <pgdir_walk>
    if (!pte_pointer || *pte_pointer == 0) {
f0100fae:	83 c4 10             	add    $0x10,%esp
f0100fb1:	85 c0                	test   %eax,%eax
f0100fb3:	74 37                	je     f0100fec <page_lookup+0x55>
f0100fb5:	83 38 00             	cmpl   $0x0,(%eax)
f0100fb8:	74 39                	je     f0100ff3 <page_lookup+0x5c>
        return NULL;
    }

    if (pte_store) {
f0100fba:	85 db                	test   %ebx,%ebx
f0100fbc:	74 02                	je     f0100fc0 <page_lookup+0x29>
        *pte_store = pte_pointer;
f0100fbe:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fc0:	8b 00                	mov    (%eax),%eax
f0100fc2:	c1 e8 0c             	shr    $0xc,%eax
f0100fc5:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100fcb:	72 14                	jb     f0100fe1 <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0100fcd:	83 ec 04             	sub    $0x4,%esp
f0100fd0:	68 a8 40 10 f0       	push   $0xf01040a8
f0100fd5:	6a 4b                	push   $0x4b
f0100fd7:	68 9f 3c 10 f0       	push   $0xf0103c9f
f0100fdc:	e8 aa f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100fe1:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0100fe7:	8d 04 c2             	lea    (%edx,%eax,8),%eax
    }

	return pa2page((physaddr_t) PTE_ADDR(*pte_pointer));
f0100fea:	eb 0c                	jmp    f0100ff8 <page_lookup+0x61>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte_pointer = pgdir_walk(pgdir, va, 0);
    if (!pte_pointer || *pte_pointer == 0) {
        return NULL;
f0100fec:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ff1:	eb 05                	jmp    f0100ff8 <page_lookup+0x61>
f0100ff3:	b8 00 00 00 00       	mov    $0x0,%eax
    if (pte_store) {
        *pte_store = pte_pointer;
    }

	return pa2page((physaddr_t) PTE_ADDR(*pte_pointer));
}
f0100ff8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ffb:	c9                   	leave  
f0100ffc:	c3                   	ret    

f0100ffd <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100ffd:	55                   	push   %ebp
f0100ffe:	89 e5                	mov    %esp,%ebp
f0101000:	53                   	push   %ebx
f0101001:	83 ec 18             	sub    $0x18,%esp
f0101004:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte_pointer;
    struct PageInfo *pp = page_lookup(pgdir, va, &pte_pointer);
f0101007:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010100a:	50                   	push   %eax
f010100b:	53                   	push   %ebx
f010100c:	ff 75 08             	pushl  0x8(%ebp)
f010100f:	e8 83 ff ff ff       	call   f0100f97 <page_lookup>
    if (!pp) {
f0101014:	83 c4 10             	add    $0x10,%esp
f0101017:	85 c0                	test   %eax,%eax
f0101019:	74 18                	je     f0101033 <page_remove+0x36>
        return;
    }

    *pte_pointer = 0;
f010101b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010101e:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
    page_decref(pp); 
f0101024:	83 ec 0c             	sub    $0xc,%esp
f0101027:	50                   	push   %eax
f0101028:	e8 f1 fd ff ff       	call   f0100e1e <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010102d:	0f 01 3b             	invlpg (%ebx)
f0101030:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir, va);
}
f0101033:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101036:	c9                   	leave  
f0101037:	c3                   	ret    

f0101038 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101038:	55                   	push   %ebp
f0101039:	89 e5                	mov    %esp,%ebp
f010103b:	57                   	push   %edi
f010103c:	56                   	push   %esi
f010103d:	53                   	push   %ebx
f010103e:	83 ec 10             	sub    $0x10,%esp
f0101041:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101044:	8b 75 10             	mov    0x10(%ebp),%esi
	// Fill this function in
	pte_t* pte_pointer = pgdir_walk(pgdir, va, 1);
f0101047:	6a 01                	push   $0x1
f0101049:	56                   	push   %esi
f010104a:	ff 75 08             	pushl  0x8(%ebp)
f010104d:	e8 f3 fd ff ff       	call   f0100e45 <pgdir_walk>
	if(!pte_pointer) {
f0101052:	83 c4 10             	add    $0x10,%esp
f0101055:	85 c0                	test   %eax,%eax
f0101057:	74 3b                	je     f0101094 <page_insert+0x5c>
f0101059:	89 c7                	mov    %eax,%edi
		return -E_NO_MEM;
	}

	pp->pp_ref++;
f010105b:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if(*pte_pointer & PTE_P) {
f0101060:	f6 00 01             	testb  $0x1,(%eax)
f0101063:	74 12                	je     f0101077 <page_insert+0x3f>
		page_remove(pgdir, va);
f0101065:	83 ec 08             	sub    $0x8,%esp
f0101068:	56                   	push   %esi
f0101069:	ff 75 08             	pushl  0x8(%ebp)
f010106c:	e8 8c ff ff ff       	call   f0100ffd <page_remove>
f0101071:	0f 01 3e             	invlpg (%esi)
f0101074:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}

	*pte_pointer = PTE_ADDR(page2pa(pp)) | PTE_P | perm;
f0101077:	2b 1d 6c 79 11 f0    	sub    0xf011796c,%ebx
f010107d:	c1 fb 03             	sar    $0x3,%ebx
f0101080:	c1 e3 0c             	shl    $0xc,%ebx
f0101083:	8b 45 14             	mov    0x14(%ebp),%eax
f0101086:	83 c8 01             	or     $0x1,%eax
f0101089:	09 c3                	or     %eax,%ebx
f010108b:	89 1f                	mov    %ebx,(%edi)
	return 0;
f010108d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101092:	eb 05                	jmp    f0101099 <page_insert+0x61>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t* pte_pointer = pgdir_walk(pgdir, va, 1);
	if(!pte_pointer) {
		return -E_NO_MEM;
f0101094:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		tlb_invalidate(pgdir, va);
	}

	*pte_pointer = PTE_ADDR(page2pa(pp)) | PTE_P | perm;
	return 0;
}
f0101099:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010109c:	5b                   	pop    %ebx
f010109d:	5e                   	pop    %esi
f010109e:	5f                   	pop    %edi
f010109f:	5d                   	pop    %ebp
f01010a0:	c3                   	ret    

f01010a1 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010a1:	55                   	push   %ebp
f01010a2:	89 e5                	mov    %esp,%ebp
f01010a4:	57                   	push   %edi
f01010a5:	56                   	push   %esi
f01010a6:	53                   	push   %ebx
f01010a7:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010aa:	6a 15                	push   $0x15
f01010ac:	e8 8f 16 00 00       	call   f0102740 <mc146818_read>
f01010b1:	89 c3                	mov    %eax,%ebx
f01010b3:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01010ba:	e8 81 16 00 00       	call   f0102740 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01010bf:	c1 e0 08             	shl    $0x8,%eax
f01010c2:	09 d8                	or     %ebx,%eax
f01010c4:	c1 e0 0a             	shl    $0xa,%eax
f01010c7:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010cd:	85 c0                	test   %eax,%eax
f01010cf:	0f 48 c2             	cmovs  %edx,%eax
f01010d2:	c1 f8 0c             	sar    $0xc,%eax
f01010d5:	a3 40 75 11 f0       	mov    %eax,0xf0117540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010da:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01010e1:	e8 5a 16 00 00       	call   f0102740 <mc146818_read>
f01010e6:	89 c3                	mov    %eax,%ebx
f01010e8:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01010ef:	e8 4c 16 00 00       	call   f0102740 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01010f4:	c1 e0 08             	shl    $0x8,%eax
f01010f7:	09 d8                	or     %ebx,%eax
f01010f9:	c1 e0 0a             	shl    $0xa,%eax
f01010fc:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101102:	83 c4 10             	add    $0x10,%esp
f0101105:	85 c0                	test   %eax,%eax
f0101107:	0f 48 c2             	cmovs  %edx,%eax
f010110a:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010110d:	85 c0                	test   %eax,%eax
f010110f:	74 0e                	je     f010111f <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101111:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101117:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
f010111d:	eb 0c                	jmp    f010112b <mem_init+0x8a>
	else
		npages = npages_basemem;
f010111f:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f0101125:	89 15 64 79 11 f0    	mov    %edx,0xf0117964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010112b:	c1 e0 0c             	shl    $0xc,%eax
f010112e:	c1 e8 0a             	shr    $0xa,%eax
f0101131:	50                   	push   %eax
f0101132:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f0101137:	c1 e0 0c             	shl    $0xc,%eax
f010113a:	c1 e8 0a             	shr    $0xa,%eax
f010113d:	50                   	push   %eax
f010113e:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0101143:	c1 e0 0c             	shl    $0xc,%eax
f0101146:	c1 e8 0a             	shr    $0xa,%eax
f0101149:	50                   	push   %eax
f010114a:	68 c8 40 10 f0       	push   $0xf01040c8
f010114f:	e8 53 16 00 00       	call   f01027a7 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101154:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101159:	e8 ae f7 ff ff       	call   f010090c <boot_alloc>
f010115e:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f0101163:	83 c4 0c             	add    $0xc,%esp
f0101166:	68 00 10 00 00       	push   $0x1000
f010116b:	6a 00                	push   $0x0
f010116d:	50                   	push   %eax
f010116e:	e8 1d 21 00 00       	call   f0103290 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101173:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101178:	83 c4 10             	add    $0x10,%esp
f010117b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101180:	77 15                	ja     f0101197 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101182:	50                   	push   %eax
f0101183:	68 84 40 10 f0       	push   $0xf0104084
f0101188:	68 94 00 00 00       	push   $0x94
f010118d:	68 93 3c 10 f0       	push   $0xf0103c93
f0101192:	e8 f4 ee ff ff       	call   f010008b <_panic>
f0101197:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010119d:	83 ca 05             	or     $0x5,%edx
f01011a0:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(npages * sizeof(struct PageInfo));
f01011a6:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01011ab:	c1 e0 03             	shl    $0x3,%eax
f01011ae:	e8 59 f7 ff ff       	call   f010090c <boot_alloc>
f01011b3:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01011b8:	83 ec 04             	sub    $0x4,%esp
f01011bb:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f01011c1:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01011c8:	52                   	push   %edx
f01011c9:	6a 00                	push   $0x0
f01011cb:	50                   	push   %eax
f01011cc:	e8 bf 20 00 00       	call   f0103290 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01011d1:	e8 ab fa ff ff       	call   f0100c81 <page_init>

	check_page_free_list(1);
f01011d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01011db:	e8 ed f7 ff ff       	call   f01009cd <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011e0:	83 c4 10             	add    $0x10,%esp
f01011e3:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f01011ea:	75 17                	jne    f0101203 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f01011ec:	83 ec 04             	sub    $0x4,%esp
f01011ef:	68 6d 3d 10 f0       	push   $0xf0103d6d
f01011f4:	68 65 02 00 00       	push   $0x265
f01011f9:	68 93 3c 10 f0       	push   $0xf0103c93
f01011fe:	e8 88 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101203:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101208:	bb 00 00 00 00       	mov    $0x0,%ebx
f010120d:	eb 05                	jmp    f0101214 <mem_init+0x173>
		++nfree;
f010120f:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101212:	8b 00                	mov    (%eax),%eax
f0101214:	85 c0                	test   %eax,%eax
f0101216:	75 f7                	jne    f010120f <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101218:	83 ec 0c             	sub    $0xc,%esp
f010121b:	6a 00                	push   $0x0
f010121d:	e8 30 fb ff ff       	call   f0100d52 <page_alloc>
f0101222:	89 c7                	mov    %eax,%edi
f0101224:	83 c4 10             	add    $0x10,%esp
f0101227:	85 c0                	test   %eax,%eax
f0101229:	75 19                	jne    f0101244 <mem_init+0x1a3>
f010122b:	68 88 3d 10 f0       	push   $0xf0103d88
f0101230:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101235:	68 6d 02 00 00       	push   $0x26d
f010123a:	68 93 3c 10 f0       	push   $0xf0103c93
f010123f:	e8 47 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101244:	83 ec 0c             	sub    $0xc,%esp
f0101247:	6a 00                	push   $0x0
f0101249:	e8 04 fb ff ff       	call   f0100d52 <page_alloc>
f010124e:	89 c6                	mov    %eax,%esi
f0101250:	83 c4 10             	add    $0x10,%esp
f0101253:	85 c0                	test   %eax,%eax
f0101255:	75 19                	jne    f0101270 <mem_init+0x1cf>
f0101257:	68 9e 3d 10 f0       	push   $0xf0103d9e
f010125c:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101261:	68 6e 02 00 00       	push   $0x26e
f0101266:	68 93 3c 10 f0       	push   $0xf0103c93
f010126b:	e8 1b ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101270:	83 ec 0c             	sub    $0xc,%esp
f0101273:	6a 00                	push   $0x0
f0101275:	e8 d8 fa ff ff       	call   f0100d52 <page_alloc>
f010127a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010127d:	83 c4 10             	add    $0x10,%esp
f0101280:	85 c0                	test   %eax,%eax
f0101282:	75 19                	jne    f010129d <mem_init+0x1fc>
f0101284:	68 b4 3d 10 f0       	push   $0xf0103db4
f0101289:	68 b9 3c 10 f0       	push   $0xf0103cb9
f010128e:	68 6f 02 00 00       	push   $0x26f
f0101293:	68 93 3c 10 f0       	push   $0xf0103c93
f0101298:	e8 ee ed ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010129d:	39 f7                	cmp    %esi,%edi
f010129f:	75 19                	jne    f01012ba <mem_init+0x219>
f01012a1:	68 ca 3d 10 f0       	push   $0xf0103dca
f01012a6:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01012ab:	68 72 02 00 00       	push   $0x272
f01012b0:	68 93 3c 10 f0       	push   $0xf0103c93
f01012b5:	e8 d1 ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012ba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012bd:	39 c6                	cmp    %eax,%esi
f01012bf:	74 04                	je     f01012c5 <mem_init+0x224>
f01012c1:	39 c7                	cmp    %eax,%edi
f01012c3:	75 19                	jne    f01012de <mem_init+0x23d>
f01012c5:	68 04 41 10 f0       	push   $0xf0104104
f01012ca:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01012cf:	68 73 02 00 00       	push   $0x273
f01012d4:	68 93 3c 10 f0       	push   $0xf0103c93
f01012d9:	e8 ad ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012de:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012e4:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f01012ea:	c1 e2 0c             	shl    $0xc,%edx
f01012ed:	89 f8                	mov    %edi,%eax
f01012ef:	29 c8                	sub    %ecx,%eax
f01012f1:	c1 f8 03             	sar    $0x3,%eax
f01012f4:	c1 e0 0c             	shl    $0xc,%eax
f01012f7:	39 d0                	cmp    %edx,%eax
f01012f9:	72 19                	jb     f0101314 <mem_init+0x273>
f01012fb:	68 dc 3d 10 f0       	push   $0xf0103ddc
f0101300:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101305:	68 74 02 00 00       	push   $0x274
f010130a:	68 93 3c 10 f0       	push   $0xf0103c93
f010130f:	e8 77 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101314:	89 f0                	mov    %esi,%eax
f0101316:	29 c8                	sub    %ecx,%eax
f0101318:	c1 f8 03             	sar    $0x3,%eax
f010131b:	c1 e0 0c             	shl    $0xc,%eax
f010131e:	39 c2                	cmp    %eax,%edx
f0101320:	77 19                	ja     f010133b <mem_init+0x29a>
f0101322:	68 f9 3d 10 f0       	push   $0xf0103df9
f0101327:	68 b9 3c 10 f0       	push   $0xf0103cb9
f010132c:	68 75 02 00 00       	push   $0x275
f0101331:	68 93 3c 10 f0       	push   $0xf0103c93
f0101336:	e8 50 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010133b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010133e:	29 c8                	sub    %ecx,%eax
f0101340:	c1 f8 03             	sar    $0x3,%eax
f0101343:	c1 e0 0c             	shl    $0xc,%eax
f0101346:	39 c2                	cmp    %eax,%edx
f0101348:	77 19                	ja     f0101363 <mem_init+0x2c2>
f010134a:	68 16 3e 10 f0       	push   $0xf0103e16
f010134f:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101354:	68 76 02 00 00       	push   $0x276
f0101359:	68 93 3c 10 f0       	push   $0xf0103c93
f010135e:	e8 28 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101363:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101368:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010136b:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101372:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101375:	83 ec 0c             	sub    $0xc,%esp
f0101378:	6a 00                	push   $0x0
f010137a:	e8 d3 f9 ff ff       	call   f0100d52 <page_alloc>
f010137f:	83 c4 10             	add    $0x10,%esp
f0101382:	85 c0                	test   %eax,%eax
f0101384:	74 19                	je     f010139f <mem_init+0x2fe>
f0101386:	68 33 3e 10 f0       	push   $0xf0103e33
f010138b:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101390:	68 7d 02 00 00       	push   $0x27d
f0101395:	68 93 3c 10 f0       	push   $0xf0103c93
f010139a:	e8 ec ec ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f010139f:	83 ec 0c             	sub    $0xc,%esp
f01013a2:	57                   	push   %edi
f01013a3:	e8 20 fa ff ff       	call   f0100dc8 <page_free>
	page_free(pp1);
f01013a8:	89 34 24             	mov    %esi,(%esp)
f01013ab:	e8 18 fa ff ff       	call   f0100dc8 <page_free>
	page_free(pp2);
f01013b0:	83 c4 04             	add    $0x4,%esp
f01013b3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01013b6:	e8 0d fa ff ff       	call   f0100dc8 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013bb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013c2:	e8 8b f9 ff ff       	call   f0100d52 <page_alloc>
f01013c7:	89 c6                	mov    %eax,%esi
f01013c9:	83 c4 10             	add    $0x10,%esp
f01013cc:	85 c0                	test   %eax,%eax
f01013ce:	75 19                	jne    f01013e9 <mem_init+0x348>
f01013d0:	68 88 3d 10 f0       	push   $0xf0103d88
f01013d5:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01013da:	68 84 02 00 00       	push   $0x284
f01013df:	68 93 3c 10 f0       	push   $0xf0103c93
f01013e4:	e8 a2 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013e9:	83 ec 0c             	sub    $0xc,%esp
f01013ec:	6a 00                	push   $0x0
f01013ee:	e8 5f f9 ff ff       	call   f0100d52 <page_alloc>
f01013f3:	89 c7                	mov    %eax,%edi
f01013f5:	83 c4 10             	add    $0x10,%esp
f01013f8:	85 c0                	test   %eax,%eax
f01013fa:	75 19                	jne    f0101415 <mem_init+0x374>
f01013fc:	68 9e 3d 10 f0       	push   $0xf0103d9e
f0101401:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101406:	68 85 02 00 00       	push   $0x285
f010140b:	68 93 3c 10 f0       	push   $0xf0103c93
f0101410:	e8 76 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101415:	83 ec 0c             	sub    $0xc,%esp
f0101418:	6a 00                	push   $0x0
f010141a:	e8 33 f9 ff ff       	call   f0100d52 <page_alloc>
f010141f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101422:	83 c4 10             	add    $0x10,%esp
f0101425:	85 c0                	test   %eax,%eax
f0101427:	75 19                	jne    f0101442 <mem_init+0x3a1>
f0101429:	68 b4 3d 10 f0       	push   $0xf0103db4
f010142e:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101433:	68 86 02 00 00       	push   $0x286
f0101438:	68 93 3c 10 f0       	push   $0xf0103c93
f010143d:	e8 49 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101442:	39 fe                	cmp    %edi,%esi
f0101444:	75 19                	jne    f010145f <mem_init+0x3be>
f0101446:	68 ca 3d 10 f0       	push   $0xf0103dca
f010144b:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101450:	68 88 02 00 00       	push   $0x288
f0101455:	68 93 3c 10 f0       	push   $0xf0103c93
f010145a:	e8 2c ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010145f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101462:	39 c7                	cmp    %eax,%edi
f0101464:	74 04                	je     f010146a <mem_init+0x3c9>
f0101466:	39 c6                	cmp    %eax,%esi
f0101468:	75 19                	jne    f0101483 <mem_init+0x3e2>
f010146a:	68 04 41 10 f0       	push   $0xf0104104
f010146f:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101474:	68 89 02 00 00       	push   $0x289
f0101479:	68 93 3c 10 f0       	push   $0xf0103c93
f010147e:	e8 08 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101483:	83 ec 0c             	sub    $0xc,%esp
f0101486:	6a 00                	push   $0x0
f0101488:	e8 c5 f8 ff ff       	call   f0100d52 <page_alloc>
f010148d:	83 c4 10             	add    $0x10,%esp
f0101490:	85 c0                	test   %eax,%eax
f0101492:	74 19                	je     f01014ad <mem_init+0x40c>
f0101494:	68 33 3e 10 f0       	push   $0xf0103e33
f0101499:	68 b9 3c 10 f0       	push   $0xf0103cb9
f010149e:	68 8a 02 00 00       	push   $0x28a
f01014a3:	68 93 3c 10 f0       	push   $0xf0103c93
f01014a8:	e8 de eb ff ff       	call   f010008b <_panic>
f01014ad:	89 f0                	mov    %esi,%eax
f01014af:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01014b5:	c1 f8 03             	sar    $0x3,%eax
f01014b8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014bb:	89 c2                	mov    %eax,%edx
f01014bd:	c1 ea 0c             	shr    $0xc,%edx
f01014c0:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01014c6:	72 12                	jb     f01014da <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014c8:	50                   	push   %eax
f01014c9:	68 9c 3f 10 f0       	push   $0xf0103f9c
f01014ce:	6a 52                	push   $0x52
f01014d0:	68 9f 3c 10 f0       	push   $0xf0103c9f
f01014d5:	e8 b1 eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014da:	83 ec 04             	sub    $0x4,%esp
f01014dd:	68 00 10 00 00       	push   $0x1000
f01014e2:	6a 01                	push   $0x1
f01014e4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014e9:	50                   	push   %eax
f01014ea:	e8 a1 1d 00 00       	call   f0103290 <memset>
	page_free(pp0);
f01014ef:	89 34 24             	mov    %esi,(%esp)
f01014f2:	e8 d1 f8 ff ff       	call   f0100dc8 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014f7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014fe:	e8 4f f8 ff ff       	call   f0100d52 <page_alloc>
f0101503:	83 c4 10             	add    $0x10,%esp
f0101506:	85 c0                	test   %eax,%eax
f0101508:	75 19                	jne    f0101523 <mem_init+0x482>
f010150a:	68 42 3e 10 f0       	push   $0xf0103e42
f010150f:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101514:	68 8f 02 00 00       	push   $0x28f
f0101519:	68 93 3c 10 f0       	push   $0xf0103c93
f010151e:	e8 68 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101523:	39 c6                	cmp    %eax,%esi
f0101525:	74 19                	je     f0101540 <mem_init+0x49f>
f0101527:	68 60 3e 10 f0       	push   $0xf0103e60
f010152c:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101531:	68 90 02 00 00       	push   $0x290
f0101536:	68 93 3c 10 f0       	push   $0xf0103c93
f010153b:	e8 4b eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101540:	89 f0                	mov    %esi,%eax
f0101542:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101548:	c1 f8 03             	sar    $0x3,%eax
f010154b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010154e:	89 c2                	mov    %eax,%edx
f0101550:	c1 ea 0c             	shr    $0xc,%edx
f0101553:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101559:	72 12                	jb     f010156d <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010155b:	50                   	push   %eax
f010155c:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0101561:	6a 52                	push   $0x52
f0101563:	68 9f 3c 10 f0       	push   $0xf0103c9f
f0101568:	e8 1e eb ff ff       	call   f010008b <_panic>
f010156d:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101573:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101579:	80 38 00             	cmpb   $0x0,(%eax)
f010157c:	74 19                	je     f0101597 <mem_init+0x4f6>
f010157e:	68 70 3e 10 f0       	push   $0xf0103e70
f0101583:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101588:	68 93 02 00 00       	push   $0x293
f010158d:	68 93 3c 10 f0       	push   $0xf0103c93
f0101592:	e8 f4 ea ff ff       	call   f010008b <_panic>
f0101597:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010159a:	39 d0                	cmp    %edx,%eax
f010159c:	75 db                	jne    f0101579 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010159e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015a1:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f01015a6:	83 ec 0c             	sub    $0xc,%esp
f01015a9:	56                   	push   %esi
f01015aa:	e8 19 f8 ff ff       	call   f0100dc8 <page_free>
	page_free(pp1);
f01015af:	89 3c 24             	mov    %edi,(%esp)
f01015b2:	e8 11 f8 ff ff       	call   f0100dc8 <page_free>
	page_free(pp2);
f01015b7:	83 c4 04             	add    $0x4,%esp
f01015ba:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015bd:	e8 06 f8 ff ff       	call   f0100dc8 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015c2:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01015c7:	83 c4 10             	add    $0x10,%esp
f01015ca:	eb 05                	jmp    f01015d1 <mem_init+0x530>
		--nfree;
f01015cc:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015cf:	8b 00                	mov    (%eax),%eax
f01015d1:	85 c0                	test   %eax,%eax
f01015d3:	75 f7                	jne    f01015cc <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f01015d5:	85 db                	test   %ebx,%ebx
f01015d7:	74 19                	je     f01015f2 <mem_init+0x551>
f01015d9:	68 7a 3e 10 f0       	push   $0xf0103e7a
f01015de:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01015e3:	68 a0 02 00 00       	push   $0x2a0
f01015e8:	68 93 3c 10 f0       	push   $0xf0103c93
f01015ed:	e8 99 ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015f2:	83 ec 0c             	sub    $0xc,%esp
f01015f5:	68 24 41 10 f0       	push   $0xf0104124
f01015fa:	e8 a8 11 00 00       	call   f01027a7 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015ff:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101606:	e8 47 f7 ff ff       	call   f0100d52 <page_alloc>
f010160b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010160e:	83 c4 10             	add    $0x10,%esp
f0101611:	85 c0                	test   %eax,%eax
f0101613:	75 19                	jne    f010162e <mem_init+0x58d>
f0101615:	68 88 3d 10 f0       	push   $0xf0103d88
f010161a:	68 b9 3c 10 f0       	push   $0xf0103cb9
f010161f:	68 f9 02 00 00       	push   $0x2f9
f0101624:	68 93 3c 10 f0       	push   $0xf0103c93
f0101629:	e8 5d ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010162e:	83 ec 0c             	sub    $0xc,%esp
f0101631:	6a 00                	push   $0x0
f0101633:	e8 1a f7 ff ff       	call   f0100d52 <page_alloc>
f0101638:	89 c3                	mov    %eax,%ebx
f010163a:	83 c4 10             	add    $0x10,%esp
f010163d:	85 c0                	test   %eax,%eax
f010163f:	75 19                	jne    f010165a <mem_init+0x5b9>
f0101641:	68 9e 3d 10 f0       	push   $0xf0103d9e
f0101646:	68 b9 3c 10 f0       	push   $0xf0103cb9
f010164b:	68 fa 02 00 00       	push   $0x2fa
f0101650:	68 93 3c 10 f0       	push   $0xf0103c93
f0101655:	e8 31 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010165a:	83 ec 0c             	sub    $0xc,%esp
f010165d:	6a 00                	push   $0x0
f010165f:	e8 ee f6 ff ff       	call   f0100d52 <page_alloc>
f0101664:	89 c6                	mov    %eax,%esi
f0101666:	83 c4 10             	add    $0x10,%esp
f0101669:	85 c0                	test   %eax,%eax
f010166b:	75 19                	jne    f0101686 <mem_init+0x5e5>
f010166d:	68 b4 3d 10 f0       	push   $0xf0103db4
f0101672:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101677:	68 fb 02 00 00       	push   $0x2fb
f010167c:	68 93 3c 10 f0       	push   $0xf0103c93
f0101681:	e8 05 ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101686:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101689:	75 19                	jne    f01016a4 <mem_init+0x603>
f010168b:	68 ca 3d 10 f0       	push   $0xf0103dca
f0101690:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101695:	68 fe 02 00 00       	push   $0x2fe
f010169a:	68 93 3c 10 f0       	push   $0xf0103c93
f010169f:	e8 e7 e9 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016a4:	39 c3                	cmp    %eax,%ebx
f01016a6:	74 05                	je     f01016ad <mem_init+0x60c>
f01016a8:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01016ab:	75 19                	jne    f01016c6 <mem_init+0x625>
f01016ad:	68 04 41 10 f0       	push   $0xf0104104
f01016b2:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01016b7:	68 ff 02 00 00       	push   $0x2ff
f01016bc:	68 93 3c 10 f0       	push   $0xf0103c93
f01016c1:	e8 c5 e9 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016c6:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01016cb:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016ce:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01016d5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016d8:	83 ec 0c             	sub    $0xc,%esp
f01016db:	6a 00                	push   $0x0
f01016dd:	e8 70 f6 ff ff       	call   f0100d52 <page_alloc>
f01016e2:	83 c4 10             	add    $0x10,%esp
f01016e5:	85 c0                	test   %eax,%eax
f01016e7:	74 19                	je     f0101702 <mem_init+0x661>
f01016e9:	68 33 3e 10 f0       	push   $0xf0103e33
f01016ee:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01016f3:	68 06 03 00 00       	push   $0x306
f01016f8:	68 93 3c 10 f0       	push   $0xf0103c93
f01016fd:	e8 89 e9 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101702:	83 ec 04             	sub    $0x4,%esp
f0101705:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101708:	50                   	push   %eax
f0101709:	6a 00                	push   $0x0
f010170b:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101711:	e8 81 f8 ff ff       	call   f0100f97 <page_lookup>
f0101716:	83 c4 10             	add    $0x10,%esp
f0101719:	85 c0                	test   %eax,%eax
f010171b:	74 19                	je     f0101736 <mem_init+0x695>
f010171d:	68 44 41 10 f0       	push   $0xf0104144
f0101722:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101727:	68 09 03 00 00       	push   $0x309
f010172c:	68 93 3c 10 f0       	push   $0xf0103c93
f0101731:	e8 55 e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101736:	6a 02                	push   $0x2
f0101738:	6a 00                	push   $0x0
f010173a:	53                   	push   %ebx
f010173b:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101741:	e8 f2 f8 ff ff       	call   f0101038 <page_insert>
f0101746:	83 c4 10             	add    $0x10,%esp
f0101749:	85 c0                	test   %eax,%eax
f010174b:	78 19                	js     f0101766 <mem_init+0x6c5>
f010174d:	68 7c 41 10 f0       	push   $0xf010417c
f0101752:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101757:	68 0c 03 00 00       	push   $0x30c
f010175c:	68 93 3c 10 f0       	push   $0xf0103c93
f0101761:	e8 25 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101766:	83 ec 0c             	sub    $0xc,%esp
f0101769:	ff 75 d4             	pushl  -0x2c(%ebp)
f010176c:	e8 57 f6 ff ff       	call   f0100dc8 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101771:	6a 02                	push   $0x2
f0101773:	6a 00                	push   $0x0
f0101775:	53                   	push   %ebx
f0101776:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010177c:	e8 b7 f8 ff ff       	call   f0101038 <page_insert>
f0101781:	83 c4 20             	add    $0x20,%esp
f0101784:	85 c0                	test   %eax,%eax
f0101786:	74 19                	je     f01017a1 <mem_init+0x700>
f0101788:	68 ac 41 10 f0       	push   $0xf01041ac
f010178d:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101792:	68 10 03 00 00       	push   $0x310
f0101797:	68 93 3c 10 f0       	push   $0xf0103c93
f010179c:	e8 ea e8 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01017a1:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017a7:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01017ac:	89 c1                	mov    %eax,%ecx
f01017ae:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01017b1:	8b 17                	mov    (%edi),%edx
f01017b3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01017b9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017bc:	29 c8                	sub    %ecx,%eax
f01017be:	c1 f8 03             	sar    $0x3,%eax
f01017c1:	c1 e0 0c             	shl    $0xc,%eax
f01017c4:	39 c2                	cmp    %eax,%edx
f01017c6:	74 19                	je     f01017e1 <mem_init+0x740>
f01017c8:	68 dc 41 10 f0       	push   $0xf01041dc
f01017cd:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01017d2:	68 11 03 00 00       	push   $0x311
f01017d7:	68 93 3c 10 f0       	push   $0xf0103c93
f01017dc:	e8 aa e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017e1:	ba 00 00 00 00       	mov    $0x0,%edx
f01017e6:	89 f8                	mov    %edi,%eax
f01017e8:	e8 7c f1 ff ff       	call   f0100969 <check_va2pa>
f01017ed:	89 da                	mov    %ebx,%edx
f01017ef:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017f2:	c1 fa 03             	sar    $0x3,%edx
f01017f5:	c1 e2 0c             	shl    $0xc,%edx
f01017f8:	39 d0                	cmp    %edx,%eax
f01017fa:	74 19                	je     f0101815 <mem_init+0x774>
f01017fc:	68 04 42 10 f0       	push   $0xf0104204
f0101801:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101806:	68 12 03 00 00       	push   $0x312
f010180b:	68 93 3c 10 f0       	push   $0xf0103c93
f0101810:	e8 76 e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101815:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010181a:	74 19                	je     f0101835 <mem_init+0x794>
f010181c:	68 85 3e 10 f0       	push   $0xf0103e85
f0101821:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101826:	68 13 03 00 00       	push   $0x313
f010182b:	68 93 3c 10 f0       	push   $0xf0103c93
f0101830:	e8 56 e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101835:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101838:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010183d:	74 19                	je     f0101858 <mem_init+0x7b7>
f010183f:	68 96 3e 10 f0       	push   $0xf0103e96
f0101844:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101849:	68 14 03 00 00       	push   $0x314
f010184e:	68 93 3c 10 f0       	push   $0xf0103c93
f0101853:	e8 33 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101858:	6a 02                	push   $0x2
f010185a:	68 00 10 00 00       	push   $0x1000
f010185f:	56                   	push   %esi
f0101860:	57                   	push   %edi
f0101861:	e8 d2 f7 ff ff       	call   f0101038 <page_insert>
f0101866:	83 c4 10             	add    $0x10,%esp
f0101869:	85 c0                	test   %eax,%eax
f010186b:	74 19                	je     f0101886 <mem_init+0x7e5>
f010186d:	68 34 42 10 f0       	push   $0xf0104234
f0101872:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101877:	68 17 03 00 00       	push   $0x317
f010187c:	68 93 3c 10 f0       	push   $0xf0103c93
f0101881:	e8 05 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101886:	ba 00 10 00 00       	mov    $0x1000,%edx
f010188b:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101890:	e8 d4 f0 ff ff       	call   f0100969 <check_va2pa>
f0101895:	89 f2                	mov    %esi,%edx
f0101897:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010189d:	c1 fa 03             	sar    $0x3,%edx
f01018a0:	c1 e2 0c             	shl    $0xc,%edx
f01018a3:	39 d0                	cmp    %edx,%eax
f01018a5:	74 19                	je     f01018c0 <mem_init+0x81f>
f01018a7:	68 70 42 10 f0       	push   $0xf0104270
f01018ac:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01018b1:	68 18 03 00 00       	push   $0x318
f01018b6:	68 93 3c 10 f0       	push   $0xf0103c93
f01018bb:	e8 cb e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018c0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018c5:	74 19                	je     f01018e0 <mem_init+0x83f>
f01018c7:	68 a7 3e 10 f0       	push   $0xf0103ea7
f01018cc:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01018d1:	68 19 03 00 00       	push   $0x319
f01018d6:	68 93 3c 10 f0       	push   $0xf0103c93
f01018db:	e8 ab e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018e0:	83 ec 0c             	sub    $0xc,%esp
f01018e3:	6a 00                	push   $0x0
f01018e5:	e8 68 f4 ff ff       	call   f0100d52 <page_alloc>
f01018ea:	83 c4 10             	add    $0x10,%esp
f01018ed:	85 c0                	test   %eax,%eax
f01018ef:	74 19                	je     f010190a <mem_init+0x869>
f01018f1:	68 33 3e 10 f0       	push   $0xf0103e33
f01018f6:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01018fb:	68 1c 03 00 00       	push   $0x31c
f0101900:	68 93 3c 10 f0       	push   $0xf0103c93
f0101905:	e8 81 e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010190a:	6a 02                	push   $0x2
f010190c:	68 00 10 00 00       	push   $0x1000
f0101911:	56                   	push   %esi
f0101912:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101918:	e8 1b f7 ff ff       	call   f0101038 <page_insert>
f010191d:	83 c4 10             	add    $0x10,%esp
f0101920:	85 c0                	test   %eax,%eax
f0101922:	74 19                	je     f010193d <mem_init+0x89c>
f0101924:	68 34 42 10 f0       	push   $0xf0104234
f0101929:	68 b9 3c 10 f0       	push   $0xf0103cb9
f010192e:	68 1f 03 00 00       	push   $0x31f
f0101933:	68 93 3c 10 f0       	push   $0xf0103c93
f0101938:	e8 4e e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010193d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101942:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101947:	e8 1d f0 ff ff       	call   f0100969 <check_va2pa>
f010194c:	89 f2                	mov    %esi,%edx
f010194e:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101954:	c1 fa 03             	sar    $0x3,%edx
f0101957:	c1 e2 0c             	shl    $0xc,%edx
f010195a:	39 d0                	cmp    %edx,%eax
f010195c:	74 19                	je     f0101977 <mem_init+0x8d6>
f010195e:	68 70 42 10 f0       	push   $0xf0104270
f0101963:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101968:	68 20 03 00 00       	push   $0x320
f010196d:	68 93 3c 10 f0       	push   $0xf0103c93
f0101972:	e8 14 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101977:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010197c:	74 19                	je     f0101997 <mem_init+0x8f6>
f010197e:	68 a7 3e 10 f0       	push   $0xf0103ea7
f0101983:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101988:	68 21 03 00 00       	push   $0x321
f010198d:	68 93 3c 10 f0       	push   $0xf0103c93
f0101992:	e8 f4 e6 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101997:	83 ec 0c             	sub    $0xc,%esp
f010199a:	6a 00                	push   $0x0
f010199c:	e8 b1 f3 ff ff       	call   f0100d52 <page_alloc>
f01019a1:	83 c4 10             	add    $0x10,%esp
f01019a4:	85 c0                	test   %eax,%eax
f01019a6:	74 19                	je     f01019c1 <mem_init+0x920>
f01019a8:	68 33 3e 10 f0       	push   $0xf0103e33
f01019ad:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01019b2:	68 25 03 00 00       	push   $0x325
f01019b7:	68 93 3c 10 f0       	push   $0xf0103c93
f01019bc:	e8 ca e6 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019c1:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f01019c7:	8b 02                	mov    (%edx),%eax
f01019c9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019ce:	89 c1                	mov    %eax,%ecx
f01019d0:	c1 e9 0c             	shr    $0xc,%ecx
f01019d3:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f01019d9:	72 15                	jb     f01019f0 <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019db:	50                   	push   %eax
f01019dc:	68 9c 3f 10 f0       	push   $0xf0103f9c
f01019e1:	68 28 03 00 00       	push   $0x328
f01019e6:	68 93 3c 10 f0       	push   $0xf0103c93
f01019eb:	e8 9b e6 ff ff       	call   f010008b <_panic>
f01019f0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019f5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019f8:	83 ec 04             	sub    $0x4,%esp
f01019fb:	6a 00                	push   $0x0
f01019fd:	68 00 10 00 00       	push   $0x1000
f0101a02:	52                   	push   %edx
f0101a03:	e8 3d f4 ff ff       	call   f0100e45 <pgdir_walk>
f0101a08:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101a0b:	8d 51 04             	lea    0x4(%ecx),%edx
f0101a0e:	83 c4 10             	add    $0x10,%esp
f0101a11:	39 d0                	cmp    %edx,%eax
f0101a13:	74 19                	je     f0101a2e <mem_init+0x98d>
f0101a15:	68 a0 42 10 f0       	push   $0xf01042a0
f0101a1a:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101a1f:	68 29 03 00 00       	push   $0x329
f0101a24:	68 93 3c 10 f0       	push   $0xf0103c93
f0101a29:	e8 5d e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a2e:	6a 06                	push   $0x6
f0101a30:	68 00 10 00 00       	push   $0x1000
f0101a35:	56                   	push   %esi
f0101a36:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101a3c:	e8 f7 f5 ff ff       	call   f0101038 <page_insert>
f0101a41:	83 c4 10             	add    $0x10,%esp
f0101a44:	85 c0                	test   %eax,%eax
f0101a46:	74 19                	je     f0101a61 <mem_init+0x9c0>
f0101a48:	68 e0 42 10 f0       	push   $0xf01042e0
f0101a4d:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101a52:	68 2c 03 00 00       	push   $0x32c
f0101a57:	68 93 3c 10 f0       	push   $0xf0103c93
f0101a5c:	e8 2a e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a61:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101a67:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a6c:	89 f8                	mov    %edi,%eax
f0101a6e:	e8 f6 ee ff ff       	call   f0100969 <check_va2pa>
f0101a73:	89 f2                	mov    %esi,%edx
f0101a75:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101a7b:	c1 fa 03             	sar    $0x3,%edx
f0101a7e:	c1 e2 0c             	shl    $0xc,%edx
f0101a81:	39 d0                	cmp    %edx,%eax
f0101a83:	74 19                	je     f0101a9e <mem_init+0x9fd>
f0101a85:	68 70 42 10 f0       	push   $0xf0104270
f0101a8a:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101a8f:	68 2d 03 00 00       	push   $0x32d
f0101a94:	68 93 3c 10 f0       	push   $0xf0103c93
f0101a99:	e8 ed e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a9e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101aa3:	74 19                	je     f0101abe <mem_init+0xa1d>
f0101aa5:	68 a7 3e 10 f0       	push   $0xf0103ea7
f0101aaa:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101aaf:	68 2e 03 00 00       	push   $0x32e
f0101ab4:	68 93 3c 10 f0       	push   $0xf0103c93
f0101ab9:	e8 cd e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101abe:	83 ec 04             	sub    $0x4,%esp
f0101ac1:	6a 00                	push   $0x0
f0101ac3:	68 00 10 00 00       	push   $0x1000
f0101ac8:	57                   	push   %edi
f0101ac9:	e8 77 f3 ff ff       	call   f0100e45 <pgdir_walk>
f0101ace:	83 c4 10             	add    $0x10,%esp
f0101ad1:	f6 00 04             	testb  $0x4,(%eax)
f0101ad4:	75 19                	jne    f0101aef <mem_init+0xa4e>
f0101ad6:	68 20 43 10 f0       	push   $0xf0104320
f0101adb:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101ae0:	68 2f 03 00 00       	push   $0x32f
f0101ae5:	68 93 3c 10 f0       	push   $0xf0103c93
f0101aea:	e8 9c e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101aef:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101af4:	f6 00 04             	testb  $0x4,(%eax)
f0101af7:	75 19                	jne    f0101b12 <mem_init+0xa71>
f0101af9:	68 b8 3e 10 f0       	push   $0xf0103eb8
f0101afe:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101b03:	68 30 03 00 00       	push   $0x330
f0101b08:	68 93 3c 10 f0       	push   $0xf0103c93
f0101b0d:	e8 79 e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b12:	6a 02                	push   $0x2
f0101b14:	68 00 10 00 00       	push   $0x1000
f0101b19:	56                   	push   %esi
f0101b1a:	50                   	push   %eax
f0101b1b:	e8 18 f5 ff ff       	call   f0101038 <page_insert>
f0101b20:	83 c4 10             	add    $0x10,%esp
f0101b23:	85 c0                	test   %eax,%eax
f0101b25:	74 19                	je     f0101b40 <mem_init+0xa9f>
f0101b27:	68 34 42 10 f0       	push   $0xf0104234
f0101b2c:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101b31:	68 33 03 00 00       	push   $0x333
f0101b36:	68 93 3c 10 f0       	push   $0xf0103c93
f0101b3b:	e8 4b e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b40:	83 ec 04             	sub    $0x4,%esp
f0101b43:	6a 00                	push   $0x0
f0101b45:	68 00 10 00 00       	push   $0x1000
f0101b4a:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b50:	e8 f0 f2 ff ff       	call   f0100e45 <pgdir_walk>
f0101b55:	83 c4 10             	add    $0x10,%esp
f0101b58:	f6 00 02             	testb  $0x2,(%eax)
f0101b5b:	75 19                	jne    f0101b76 <mem_init+0xad5>
f0101b5d:	68 54 43 10 f0       	push   $0xf0104354
f0101b62:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101b67:	68 34 03 00 00       	push   $0x334
f0101b6c:	68 93 3c 10 f0       	push   $0xf0103c93
f0101b71:	e8 15 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b76:	83 ec 04             	sub    $0x4,%esp
f0101b79:	6a 00                	push   $0x0
f0101b7b:	68 00 10 00 00       	push   $0x1000
f0101b80:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b86:	e8 ba f2 ff ff       	call   f0100e45 <pgdir_walk>
f0101b8b:	83 c4 10             	add    $0x10,%esp
f0101b8e:	f6 00 04             	testb  $0x4,(%eax)
f0101b91:	74 19                	je     f0101bac <mem_init+0xb0b>
f0101b93:	68 88 43 10 f0       	push   $0xf0104388
f0101b98:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101b9d:	68 35 03 00 00       	push   $0x335
f0101ba2:	68 93 3c 10 f0       	push   $0xf0103c93
f0101ba7:	e8 df e4 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101bac:	6a 02                	push   $0x2
f0101bae:	68 00 00 40 00       	push   $0x400000
f0101bb3:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bb6:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101bbc:	e8 77 f4 ff ff       	call   f0101038 <page_insert>
f0101bc1:	83 c4 10             	add    $0x10,%esp
f0101bc4:	85 c0                	test   %eax,%eax
f0101bc6:	78 19                	js     f0101be1 <mem_init+0xb40>
f0101bc8:	68 c0 43 10 f0       	push   $0xf01043c0
f0101bcd:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101bd2:	68 38 03 00 00       	push   $0x338
f0101bd7:	68 93 3c 10 f0       	push   $0xf0103c93
f0101bdc:	e8 aa e4 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101be1:	6a 02                	push   $0x2
f0101be3:	68 00 10 00 00       	push   $0x1000
f0101be8:	53                   	push   %ebx
f0101be9:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101bef:	e8 44 f4 ff ff       	call   f0101038 <page_insert>
f0101bf4:	83 c4 10             	add    $0x10,%esp
f0101bf7:	85 c0                	test   %eax,%eax
f0101bf9:	74 19                	je     f0101c14 <mem_init+0xb73>
f0101bfb:	68 f8 43 10 f0       	push   $0xf01043f8
f0101c00:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101c05:	68 3b 03 00 00       	push   $0x33b
f0101c0a:	68 93 3c 10 f0       	push   $0xf0103c93
f0101c0f:	e8 77 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c14:	83 ec 04             	sub    $0x4,%esp
f0101c17:	6a 00                	push   $0x0
f0101c19:	68 00 10 00 00       	push   $0x1000
f0101c1e:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c24:	e8 1c f2 ff ff       	call   f0100e45 <pgdir_walk>
f0101c29:	83 c4 10             	add    $0x10,%esp
f0101c2c:	f6 00 04             	testb  $0x4,(%eax)
f0101c2f:	74 19                	je     f0101c4a <mem_init+0xba9>
f0101c31:	68 88 43 10 f0       	push   $0xf0104388
f0101c36:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101c3b:	68 3c 03 00 00       	push   $0x33c
f0101c40:	68 93 3c 10 f0       	push   $0xf0103c93
f0101c45:	e8 41 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c4a:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101c50:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c55:	89 f8                	mov    %edi,%eax
f0101c57:	e8 0d ed ff ff       	call   f0100969 <check_va2pa>
f0101c5c:	89 c1                	mov    %eax,%ecx
f0101c5e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c61:	89 d8                	mov    %ebx,%eax
f0101c63:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101c69:	c1 f8 03             	sar    $0x3,%eax
f0101c6c:	c1 e0 0c             	shl    $0xc,%eax
f0101c6f:	39 c1                	cmp    %eax,%ecx
f0101c71:	74 19                	je     f0101c8c <mem_init+0xbeb>
f0101c73:	68 34 44 10 f0       	push   $0xf0104434
f0101c78:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101c7d:	68 3f 03 00 00       	push   $0x33f
f0101c82:	68 93 3c 10 f0       	push   $0xf0103c93
f0101c87:	e8 ff e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c8c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c91:	89 f8                	mov    %edi,%eax
f0101c93:	e8 d1 ec ff ff       	call   f0100969 <check_va2pa>
f0101c98:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c9b:	74 19                	je     f0101cb6 <mem_init+0xc15>
f0101c9d:	68 60 44 10 f0       	push   $0xf0104460
f0101ca2:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101ca7:	68 40 03 00 00       	push   $0x340
f0101cac:	68 93 3c 10 f0       	push   $0xf0103c93
f0101cb1:	e8 d5 e3 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101cb6:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101cbb:	74 19                	je     f0101cd6 <mem_init+0xc35>
f0101cbd:	68 ce 3e 10 f0       	push   $0xf0103ece
f0101cc2:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101cc7:	68 42 03 00 00       	push   $0x342
f0101ccc:	68 93 3c 10 f0       	push   $0xf0103c93
f0101cd1:	e8 b5 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101cd6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101cdb:	74 19                	je     f0101cf6 <mem_init+0xc55>
f0101cdd:	68 df 3e 10 f0       	push   $0xf0103edf
f0101ce2:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101ce7:	68 43 03 00 00       	push   $0x343
f0101cec:	68 93 3c 10 f0       	push   $0xf0103c93
f0101cf1:	e8 95 e3 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cf6:	83 ec 0c             	sub    $0xc,%esp
f0101cf9:	6a 00                	push   $0x0
f0101cfb:	e8 52 f0 ff ff       	call   f0100d52 <page_alloc>
f0101d00:	83 c4 10             	add    $0x10,%esp
f0101d03:	85 c0                	test   %eax,%eax
f0101d05:	74 04                	je     f0101d0b <mem_init+0xc6a>
f0101d07:	39 c6                	cmp    %eax,%esi
f0101d09:	74 19                	je     f0101d24 <mem_init+0xc83>
f0101d0b:	68 90 44 10 f0       	push   $0xf0104490
f0101d10:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101d15:	68 46 03 00 00       	push   $0x346
f0101d1a:	68 93 3c 10 f0       	push   $0xf0103c93
f0101d1f:	e8 67 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d24:	83 ec 08             	sub    $0x8,%esp
f0101d27:	6a 00                	push   $0x0
f0101d29:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101d2f:	e8 c9 f2 ff ff       	call   f0100ffd <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d34:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101d3a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d3f:	89 f8                	mov    %edi,%eax
f0101d41:	e8 23 ec ff ff       	call   f0100969 <check_va2pa>
f0101d46:	83 c4 10             	add    $0x10,%esp
f0101d49:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d4c:	74 19                	je     f0101d67 <mem_init+0xcc6>
f0101d4e:	68 b4 44 10 f0       	push   $0xf01044b4
f0101d53:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101d58:	68 4a 03 00 00       	push   $0x34a
f0101d5d:	68 93 3c 10 f0       	push   $0xf0103c93
f0101d62:	e8 24 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d67:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d6c:	89 f8                	mov    %edi,%eax
f0101d6e:	e8 f6 eb ff ff       	call   f0100969 <check_va2pa>
f0101d73:	89 da                	mov    %ebx,%edx
f0101d75:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101d7b:	c1 fa 03             	sar    $0x3,%edx
f0101d7e:	c1 e2 0c             	shl    $0xc,%edx
f0101d81:	39 d0                	cmp    %edx,%eax
f0101d83:	74 19                	je     f0101d9e <mem_init+0xcfd>
f0101d85:	68 60 44 10 f0       	push   $0xf0104460
f0101d8a:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101d8f:	68 4b 03 00 00       	push   $0x34b
f0101d94:	68 93 3c 10 f0       	push   $0xf0103c93
f0101d99:	e8 ed e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d9e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101da3:	74 19                	je     f0101dbe <mem_init+0xd1d>
f0101da5:	68 85 3e 10 f0       	push   $0xf0103e85
f0101daa:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101daf:	68 4c 03 00 00       	push   $0x34c
f0101db4:	68 93 3c 10 f0       	push   $0xf0103c93
f0101db9:	e8 cd e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101dbe:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101dc3:	74 19                	je     f0101dde <mem_init+0xd3d>
f0101dc5:	68 df 3e 10 f0       	push   $0xf0103edf
f0101dca:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101dcf:	68 4d 03 00 00       	push   $0x34d
f0101dd4:	68 93 3c 10 f0       	push   $0xf0103c93
f0101dd9:	e8 ad e2 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101dde:	6a 00                	push   $0x0
f0101de0:	68 00 10 00 00       	push   $0x1000
f0101de5:	53                   	push   %ebx
f0101de6:	57                   	push   %edi
f0101de7:	e8 4c f2 ff ff       	call   f0101038 <page_insert>
f0101dec:	83 c4 10             	add    $0x10,%esp
f0101def:	85 c0                	test   %eax,%eax
f0101df1:	74 19                	je     f0101e0c <mem_init+0xd6b>
f0101df3:	68 d8 44 10 f0       	push   $0xf01044d8
f0101df8:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101dfd:	68 50 03 00 00       	push   $0x350
f0101e02:	68 93 3c 10 f0       	push   $0xf0103c93
f0101e07:	e8 7f e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101e0c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e11:	75 19                	jne    f0101e2c <mem_init+0xd8b>
f0101e13:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0101e18:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101e1d:	68 51 03 00 00       	push   $0x351
f0101e22:	68 93 3c 10 f0       	push   $0xf0103c93
f0101e27:	e8 5f e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101e2c:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e2f:	74 19                	je     f0101e4a <mem_init+0xda9>
f0101e31:	68 fc 3e 10 f0       	push   $0xf0103efc
f0101e36:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101e3b:	68 52 03 00 00       	push   $0x352
f0101e40:	68 93 3c 10 f0       	push   $0xf0103c93
f0101e45:	e8 41 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e4a:	83 ec 08             	sub    $0x8,%esp
f0101e4d:	68 00 10 00 00       	push   $0x1000
f0101e52:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101e58:	e8 a0 f1 ff ff       	call   f0100ffd <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e5d:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101e63:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e68:	89 f8                	mov    %edi,%eax
f0101e6a:	e8 fa ea ff ff       	call   f0100969 <check_va2pa>
f0101e6f:	83 c4 10             	add    $0x10,%esp
f0101e72:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e75:	74 19                	je     f0101e90 <mem_init+0xdef>
f0101e77:	68 b4 44 10 f0       	push   $0xf01044b4
f0101e7c:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101e81:	68 56 03 00 00       	push   $0x356
f0101e86:	68 93 3c 10 f0       	push   $0xf0103c93
f0101e8b:	e8 fb e1 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e90:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e95:	89 f8                	mov    %edi,%eax
f0101e97:	e8 cd ea ff ff       	call   f0100969 <check_va2pa>
f0101e9c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e9f:	74 19                	je     f0101eba <mem_init+0xe19>
f0101ea1:	68 10 45 10 f0       	push   $0xf0104510
f0101ea6:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101eab:	68 57 03 00 00       	push   $0x357
f0101eb0:	68 93 3c 10 f0       	push   $0xf0103c93
f0101eb5:	e8 d1 e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101eba:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ebf:	74 19                	je     f0101eda <mem_init+0xe39>
f0101ec1:	68 11 3f 10 f0       	push   $0xf0103f11
f0101ec6:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101ecb:	68 58 03 00 00       	push   $0x358
f0101ed0:	68 93 3c 10 f0       	push   $0xf0103c93
f0101ed5:	e8 b1 e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101eda:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101edf:	74 19                	je     f0101efa <mem_init+0xe59>
f0101ee1:	68 df 3e 10 f0       	push   $0xf0103edf
f0101ee6:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101eeb:	68 59 03 00 00       	push   $0x359
f0101ef0:	68 93 3c 10 f0       	push   $0xf0103c93
f0101ef5:	e8 91 e1 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101efa:	83 ec 0c             	sub    $0xc,%esp
f0101efd:	6a 00                	push   $0x0
f0101eff:	e8 4e ee ff ff       	call   f0100d52 <page_alloc>
f0101f04:	83 c4 10             	add    $0x10,%esp
f0101f07:	39 c3                	cmp    %eax,%ebx
f0101f09:	75 04                	jne    f0101f0f <mem_init+0xe6e>
f0101f0b:	85 c0                	test   %eax,%eax
f0101f0d:	75 19                	jne    f0101f28 <mem_init+0xe87>
f0101f0f:	68 38 45 10 f0       	push   $0xf0104538
f0101f14:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101f19:	68 5c 03 00 00       	push   $0x35c
f0101f1e:	68 93 3c 10 f0       	push   $0xf0103c93
f0101f23:	e8 63 e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f28:	83 ec 0c             	sub    $0xc,%esp
f0101f2b:	6a 00                	push   $0x0
f0101f2d:	e8 20 ee ff ff       	call   f0100d52 <page_alloc>
f0101f32:	83 c4 10             	add    $0x10,%esp
f0101f35:	85 c0                	test   %eax,%eax
f0101f37:	74 19                	je     f0101f52 <mem_init+0xeb1>
f0101f39:	68 33 3e 10 f0       	push   $0xf0103e33
f0101f3e:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101f43:	68 5f 03 00 00       	push   $0x35f
f0101f48:	68 93 3c 10 f0       	push   $0xf0103c93
f0101f4d:	e8 39 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f52:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0101f58:	8b 11                	mov    (%ecx),%edx
f0101f5a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f60:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f63:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101f69:	c1 f8 03             	sar    $0x3,%eax
f0101f6c:	c1 e0 0c             	shl    $0xc,%eax
f0101f6f:	39 c2                	cmp    %eax,%edx
f0101f71:	74 19                	je     f0101f8c <mem_init+0xeeb>
f0101f73:	68 dc 41 10 f0       	push   $0xf01041dc
f0101f78:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101f7d:	68 62 03 00 00       	push   $0x362
f0101f82:	68 93 3c 10 f0       	push   $0xf0103c93
f0101f87:	e8 ff e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f8c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f92:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f95:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f9a:	74 19                	je     f0101fb5 <mem_init+0xf14>
f0101f9c:	68 96 3e 10 f0       	push   $0xf0103e96
f0101fa1:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0101fa6:	68 64 03 00 00       	push   $0x364
f0101fab:	68 93 3c 10 f0       	push   $0xf0103c93
f0101fb0:	e8 d6 e0 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101fb5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fb8:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fbe:	83 ec 0c             	sub    $0xc,%esp
f0101fc1:	50                   	push   %eax
f0101fc2:	e8 01 ee ff ff       	call   f0100dc8 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fc7:	83 c4 0c             	add    $0xc,%esp
f0101fca:	6a 01                	push   $0x1
f0101fcc:	68 00 10 40 00       	push   $0x401000
f0101fd1:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101fd7:	e8 69 ee ff ff       	call   f0100e45 <pgdir_walk>
f0101fdc:	89 c7                	mov    %eax,%edi
f0101fde:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fe1:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101fe6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fe9:	8b 40 04             	mov    0x4(%eax),%eax
f0101fec:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ff1:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101ff7:	89 c2                	mov    %eax,%edx
f0101ff9:	c1 ea 0c             	shr    $0xc,%edx
f0101ffc:	83 c4 10             	add    $0x10,%esp
f0101fff:	39 ca                	cmp    %ecx,%edx
f0102001:	72 15                	jb     f0102018 <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102003:	50                   	push   %eax
f0102004:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0102009:	68 6b 03 00 00       	push   $0x36b
f010200e:	68 93 3c 10 f0       	push   $0xf0103c93
f0102013:	e8 73 e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102018:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010201d:	39 c7                	cmp    %eax,%edi
f010201f:	74 19                	je     f010203a <mem_init+0xf99>
f0102021:	68 22 3f 10 f0       	push   $0xf0103f22
f0102026:	68 b9 3c 10 f0       	push   $0xf0103cb9
f010202b:	68 6c 03 00 00       	push   $0x36c
f0102030:	68 93 3c 10 f0       	push   $0xf0103c93
f0102035:	e8 51 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f010203a:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010203d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102044:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102047:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010204d:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102053:	c1 f8 03             	sar    $0x3,%eax
f0102056:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102059:	89 c2                	mov    %eax,%edx
f010205b:	c1 ea 0c             	shr    $0xc,%edx
f010205e:	39 d1                	cmp    %edx,%ecx
f0102060:	77 12                	ja     f0102074 <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102062:	50                   	push   %eax
f0102063:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0102068:	6a 52                	push   $0x52
f010206a:	68 9f 3c 10 f0       	push   $0xf0103c9f
f010206f:	e8 17 e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102074:	83 ec 04             	sub    $0x4,%esp
f0102077:	68 00 10 00 00       	push   $0x1000
f010207c:	68 ff 00 00 00       	push   $0xff
f0102081:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102086:	50                   	push   %eax
f0102087:	e8 04 12 00 00       	call   f0103290 <memset>
	page_free(pp0);
f010208c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010208f:	89 3c 24             	mov    %edi,(%esp)
f0102092:	e8 31 ed ff ff       	call   f0100dc8 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102097:	83 c4 0c             	add    $0xc,%esp
f010209a:	6a 01                	push   $0x1
f010209c:	6a 00                	push   $0x0
f010209e:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01020a4:	e8 9c ed ff ff       	call   f0100e45 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020a9:	89 fa                	mov    %edi,%edx
f01020ab:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01020b1:	c1 fa 03             	sar    $0x3,%edx
f01020b4:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020b7:	89 d0                	mov    %edx,%eax
f01020b9:	c1 e8 0c             	shr    $0xc,%eax
f01020bc:	83 c4 10             	add    $0x10,%esp
f01020bf:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f01020c5:	72 12                	jb     f01020d9 <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020c7:	52                   	push   %edx
f01020c8:	68 9c 3f 10 f0       	push   $0xf0103f9c
f01020cd:	6a 52                	push   $0x52
f01020cf:	68 9f 3c 10 f0       	push   $0xf0103c9f
f01020d4:	e8 b2 df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f01020d9:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020df:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020e2:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020e8:	f6 00 01             	testb  $0x1,(%eax)
f01020eb:	74 19                	je     f0102106 <mem_init+0x1065>
f01020ed:	68 3a 3f 10 f0       	push   $0xf0103f3a
f01020f2:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01020f7:	68 76 03 00 00       	push   $0x376
f01020fc:	68 93 3c 10 f0       	push   $0xf0103c93
f0102101:	e8 85 df ff ff       	call   f010008b <_panic>
f0102106:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102109:	39 d0                	cmp    %edx,%eax
f010210b:	75 db                	jne    f01020e8 <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010210d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102112:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102118:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010211b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102121:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102124:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f010212a:	83 ec 0c             	sub    $0xc,%esp
f010212d:	50                   	push   %eax
f010212e:	e8 95 ec ff ff       	call   f0100dc8 <page_free>
	page_free(pp1);
f0102133:	89 1c 24             	mov    %ebx,(%esp)
f0102136:	e8 8d ec ff ff       	call   f0100dc8 <page_free>
	page_free(pp2);
f010213b:	89 34 24             	mov    %esi,(%esp)
f010213e:	e8 85 ec ff ff       	call   f0100dc8 <page_free>

	cprintf("check_page() succeeded!\n");
f0102143:	c7 04 24 51 3f 10 f0 	movl   $0xf0103f51,(%esp)
f010214a:	e8 58 06 00 00       	call   f01027a7 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	int pages_size = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE); 
f010214f:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0102154:	8d 0c c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%ecx
f010215b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
    boot_map_region(kern_pgdir, UPAGES, pages_size, PADDR(pages), PTE_U);
f0102161:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102166:	83 c4 10             	add    $0x10,%esp
f0102169:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010216e:	77 15                	ja     f0102185 <mem_init+0x10e4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102170:	50                   	push   %eax
f0102171:	68 84 40 10 f0       	push   $0xf0104084
f0102176:	68 b8 00 00 00       	push   $0xb8
f010217b:	68 93 3c 10 f0       	push   $0xf0103c93
f0102180:	e8 06 df ff ff       	call   f010008b <_panic>
f0102185:	83 ec 08             	sub    $0x8,%esp
f0102188:	6a 04                	push   $0x4
f010218a:	05 00 00 00 10       	add    $0x10000000,%eax
f010218f:	50                   	push   %eax
f0102190:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102195:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010219a:	e8 91 ed ff ff       	call   f0100f30 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010219f:	83 c4 10             	add    $0x10,%esp
f01021a2:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f01021a7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021ac:	77 15                	ja     f01021c3 <mem_init+0x1122>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021ae:	50                   	push   %eax
f01021af:	68 84 40 10 f0       	push   $0xf0104084
f01021b4:	68 c6 00 00 00       	push   $0xc6
f01021b9:	68 93 3c 10 f0       	push   $0xf0103c93
f01021be:	e8 c8 de ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, ROUNDUP(KSTKSIZE, PGSIZE), PADDR(bootstack), PTE_W);
f01021c3:	83 ec 08             	sub    $0x8,%esp
f01021c6:	6a 02                	push   $0x2
f01021c8:	68 00 d0 10 00       	push   $0x10d000
f01021cd:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021d2:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021d7:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021dc:	e8 4f ed ff ff       	call   f0100f30 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, ROUNDUP(~KERNBASE+1, PGSIZE), 0, PTE_W);
f01021e1:	83 c4 08             	add    $0x8,%esp
f01021e4:	6a 02                	push   $0x2
f01021e6:	6a 00                	push   $0x0
f01021e8:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01021ed:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021f2:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021f7:	e8 34 ed ff ff       	call   f0100f30 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021fc:	8b 35 68 79 11 f0    	mov    0xf0117968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102202:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0102207:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010220a:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102211:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102216:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102219:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010221f:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102222:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102225:	bb 00 00 00 00       	mov    $0x0,%ebx
f010222a:	eb 55                	jmp    f0102281 <mem_init+0x11e0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010222c:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102232:	89 f0                	mov    %esi,%eax
f0102234:	e8 30 e7 ff ff       	call   f0100969 <check_va2pa>
f0102239:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102240:	77 15                	ja     f0102257 <mem_init+0x11b6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102242:	57                   	push   %edi
f0102243:	68 84 40 10 f0       	push   $0xf0104084
f0102248:	68 b8 02 00 00       	push   $0x2b8
f010224d:	68 93 3c 10 f0       	push   $0xf0103c93
f0102252:	e8 34 de ff ff       	call   f010008b <_panic>
f0102257:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010225e:	39 c2                	cmp    %eax,%edx
f0102260:	74 19                	je     f010227b <mem_init+0x11da>
f0102262:	68 5c 45 10 f0       	push   $0xf010455c
f0102267:	68 b9 3c 10 f0       	push   $0xf0103cb9
f010226c:	68 b8 02 00 00       	push   $0x2b8
f0102271:	68 93 3c 10 f0       	push   $0xf0103c93
f0102276:	e8 10 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010227b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102281:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102284:	77 a6                	ja     f010222c <mem_init+0x118b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102286:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102289:	c1 e7 0c             	shl    $0xc,%edi
f010228c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102291:	eb 30                	jmp    f01022c3 <mem_init+0x1222>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102293:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102299:	89 f0                	mov    %esi,%eax
f010229b:	e8 c9 e6 ff ff       	call   f0100969 <check_va2pa>
f01022a0:	39 c3                	cmp    %eax,%ebx
f01022a2:	74 19                	je     f01022bd <mem_init+0x121c>
f01022a4:	68 90 45 10 f0       	push   $0xf0104590
f01022a9:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01022ae:	68 bd 02 00 00       	push   $0x2bd
f01022b3:	68 93 3c 10 f0       	push   $0xf0103c93
f01022b8:	e8 ce dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022bd:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01022c3:	39 fb                	cmp    %edi,%ebx
f01022c5:	72 cc                	jb     f0102293 <mem_init+0x11f2>
f01022c7:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01022cc:	89 da                	mov    %ebx,%edx
f01022ce:	89 f0                	mov    %esi,%eax
f01022d0:	e8 94 e6 ff ff       	call   f0100969 <check_va2pa>
f01022d5:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f01022db:	39 c2                	cmp    %eax,%edx
f01022dd:	74 19                	je     f01022f8 <mem_init+0x1257>
f01022df:	68 b8 45 10 f0       	push   $0xf01045b8
f01022e4:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01022e9:	68 c1 02 00 00       	push   $0x2c1
f01022ee:	68 93 3c 10 f0       	push   $0xf0103c93
f01022f3:	e8 93 dd ff ff       	call   f010008b <_panic>
f01022f8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022fe:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102304:	75 c6                	jne    f01022cc <mem_init+0x122b>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102306:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010230b:	89 f0                	mov    %esi,%eax
f010230d:	e8 57 e6 ff ff       	call   f0100969 <check_va2pa>
f0102312:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102315:	74 51                	je     f0102368 <mem_init+0x12c7>
f0102317:	68 00 46 10 f0       	push   $0xf0104600
f010231c:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0102321:	68 c2 02 00 00       	push   $0x2c2
f0102326:	68 93 3c 10 f0       	push   $0xf0103c93
f010232b:	e8 5b dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102330:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102335:	72 36                	jb     f010236d <mem_init+0x12cc>
f0102337:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010233c:	76 07                	jbe    f0102345 <mem_init+0x12a4>
f010233e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102343:	75 28                	jne    f010236d <mem_init+0x12cc>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102345:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102349:	0f 85 83 00 00 00    	jne    f01023d2 <mem_init+0x1331>
f010234f:	68 6a 3f 10 f0       	push   $0xf0103f6a
f0102354:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0102359:	68 ca 02 00 00       	push   $0x2ca
f010235e:	68 93 3c 10 f0       	push   $0xf0103c93
f0102363:	e8 23 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102368:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010236d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102372:	76 3f                	jbe    f01023b3 <mem_init+0x1312>
				assert(pgdir[i] & PTE_P);
f0102374:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102377:	f6 c2 01             	test   $0x1,%dl
f010237a:	75 19                	jne    f0102395 <mem_init+0x12f4>
f010237c:	68 6a 3f 10 f0       	push   $0xf0103f6a
f0102381:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0102386:	68 ce 02 00 00       	push   $0x2ce
f010238b:	68 93 3c 10 f0       	push   $0xf0103c93
f0102390:	e8 f6 dc ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102395:	f6 c2 02             	test   $0x2,%dl
f0102398:	75 38                	jne    f01023d2 <mem_init+0x1331>
f010239a:	68 7b 3f 10 f0       	push   $0xf0103f7b
f010239f:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01023a4:	68 cf 02 00 00       	push   $0x2cf
f01023a9:	68 93 3c 10 f0       	push   $0xf0103c93
f01023ae:	e8 d8 dc ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f01023b3:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f01023b7:	74 19                	je     f01023d2 <mem_init+0x1331>
f01023b9:	68 8c 3f 10 f0       	push   $0xf0103f8c
f01023be:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01023c3:	68 d1 02 00 00       	push   $0x2d1
f01023c8:	68 93 3c 10 f0       	push   $0xf0103c93
f01023cd:	e8 b9 dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01023d2:	83 c0 01             	add    $0x1,%eax
f01023d5:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01023da:	0f 86 50 ff ff ff    	jbe    f0102330 <mem_init+0x128f>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01023e0:	83 ec 0c             	sub    $0xc,%esp
f01023e3:	68 30 46 10 f0       	push   $0xf0104630
f01023e8:	e8 ba 03 00 00       	call   f01027a7 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023ed:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023f2:	83 c4 10             	add    $0x10,%esp
f01023f5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023fa:	77 15                	ja     f0102411 <mem_init+0x1370>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023fc:	50                   	push   %eax
f01023fd:	68 84 40 10 f0       	push   $0xf0104084
f0102402:	68 dd 00 00 00       	push   $0xdd
f0102407:	68 93 3c 10 f0       	push   $0xf0103c93
f010240c:	e8 7a dc ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102411:	05 00 00 00 10       	add    $0x10000000,%eax
f0102416:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102419:	b8 00 00 00 00       	mov    $0x0,%eax
f010241e:	e8 aa e5 ff ff       	call   f01009cd <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102423:	0f 20 c0             	mov    %cr0,%eax
f0102426:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102429:	0d 23 00 05 80       	or     $0x80050023,%eax
f010242e:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102431:	83 ec 0c             	sub    $0xc,%esp
f0102434:	6a 00                	push   $0x0
f0102436:	e8 17 e9 ff ff       	call   f0100d52 <page_alloc>
f010243b:	89 c3                	mov    %eax,%ebx
f010243d:	83 c4 10             	add    $0x10,%esp
f0102440:	85 c0                	test   %eax,%eax
f0102442:	75 19                	jne    f010245d <mem_init+0x13bc>
f0102444:	68 88 3d 10 f0       	push   $0xf0103d88
f0102449:	68 b9 3c 10 f0       	push   $0xf0103cb9
f010244e:	68 91 03 00 00       	push   $0x391
f0102453:	68 93 3c 10 f0       	push   $0xf0103c93
f0102458:	e8 2e dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010245d:	83 ec 0c             	sub    $0xc,%esp
f0102460:	6a 00                	push   $0x0
f0102462:	e8 eb e8 ff ff       	call   f0100d52 <page_alloc>
f0102467:	89 c7                	mov    %eax,%edi
f0102469:	83 c4 10             	add    $0x10,%esp
f010246c:	85 c0                	test   %eax,%eax
f010246e:	75 19                	jne    f0102489 <mem_init+0x13e8>
f0102470:	68 9e 3d 10 f0       	push   $0xf0103d9e
f0102475:	68 b9 3c 10 f0       	push   $0xf0103cb9
f010247a:	68 92 03 00 00       	push   $0x392
f010247f:	68 93 3c 10 f0       	push   $0xf0103c93
f0102484:	e8 02 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102489:	83 ec 0c             	sub    $0xc,%esp
f010248c:	6a 00                	push   $0x0
f010248e:	e8 bf e8 ff ff       	call   f0100d52 <page_alloc>
f0102493:	89 c6                	mov    %eax,%esi
f0102495:	83 c4 10             	add    $0x10,%esp
f0102498:	85 c0                	test   %eax,%eax
f010249a:	75 19                	jne    f01024b5 <mem_init+0x1414>
f010249c:	68 b4 3d 10 f0       	push   $0xf0103db4
f01024a1:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01024a6:	68 93 03 00 00       	push   $0x393
f01024ab:	68 93 3c 10 f0       	push   $0xf0103c93
f01024b0:	e8 d6 db ff ff       	call   f010008b <_panic>
	page_free(pp0);
f01024b5:	83 ec 0c             	sub    $0xc,%esp
f01024b8:	53                   	push   %ebx
f01024b9:	e8 0a e9 ff ff       	call   f0100dc8 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024be:	89 f8                	mov    %edi,%eax
f01024c0:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01024c6:	c1 f8 03             	sar    $0x3,%eax
f01024c9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024cc:	89 c2                	mov    %eax,%edx
f01024ce:	c1 ea 0c             	shr    $0xc,%edx
f01024d1:	83 c4 10             	add    $0x10,%esp
f01024d4:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01024da:	72 12                	jb     f01024ee <mem_init+0x144d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024dc:	50                   	push   %eax
f01024dd:	68 9c 3f 10 f0       	push   $0xf0103f9c
f01024e2:	6a 52                	push   $0x52
f01024e4:	68 9f 3c 10 f0       	push   $0xf0103c9f
f01024e9:	e8 9d db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024ee:	83 ec 04             	sub    $0x4,%esp
f01024f1:	68 00 10 00 00       	push   $0x1000
f01024f6:	6a 01                	push   $0x1
f01024f8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024fd:	50                   	push   %eax
f01024fe:	e8 8d 0d 00 00       	call   f0103290 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102503:	89 f0                	mov    %esi,%eax
f0102505:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010250b:	c1 f8 03             	sar    $0x3,%eax
f010250e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102511:	89 c2                	mov    %eax,%edx
f0102513:	c1 ea 0c             	shr    $0xc,%edx
f0102516:	83 c4 10             	add    $0x10,%esp
f0102519:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010251f:	72 12                	jb     f0102533 <mem_init+0x1492>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102521:	50                   	push   %eax
f0102522:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0102527:	6a 52                	push   $0x52
f0102529:	68 9f 3c 10 f0       	push   $0xf0103c9f
f010252e:	e8 58 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102533:	83 ec 04             	sub    $0x4,%esp
f0102536:	68 00 10 00 00       	push   $0x1000
f010253b:	6a 02                	push   $0x2
f010253d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102542:	50                   	push   %eax
f0102543:	e8 48 0d 00 00       	call   f0103290 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102548:	6a 02                	push   $0x2
f010254a:	68 00 10 00 00       	push   $0x1000
f010254f:	57                   	push   %edi
f0102550:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102556:	e8 dd ea ff ff       	call   f0101038 <page_insert>
	assert(pp1->pp_ref == 1);
f010255b:	83 c4 20             	add    $0x20,%esp
f010255e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102563:	74 19                	je     f010257e <mem_init+0x14dd>
f0102565:	68 85 3e 10 f0       	push   $0xf0103e85
f010256a:	68 b9 3c 10 f0       	push   $0xf0103cb9
f010256f:	68 98 03 00 00       	push   $0x398
f0102574:	68 93 3c 10 f0       	push   $0xf0103c93
f0102579:	e8 0d db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010257e:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102585:	01 01 01 
f0102588:	74 19                	je     f01025a3 <mem_init+0x1502>
f010258a:	68 50 46 10 f0       	push   $0xf0104650
f010258f:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0102594:	68 99 03 00 00       	push   $0x399
f0102599:	68 93 3c 10 f0       	push   $0xf0103c93
f010259e:	e8 e8 da ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01025a3:	6a 02                	push   $0x2
f01025a5:	68 00 10 00 00       	push   $0x1000
f01025aa:	56                   	push   %esi
f01025ab:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01025b1:	e8 82 ea ff ff       	call   f0101038 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01025b6:	83 c4 10             	add    $0x10,%esp
f01025b9:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01025c0:	02 02 02 
f01025c3:	74 19                	je     f01025de <mem_init+0x153d>
f01025c5:	68 74 46 10 f0       	push   $0xf0104674
f01025ca:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01025cf:	68 9b 03 00 00       	push   $0x39b
f01025d4:	68 93 3c 10 f0       	push   $0xf0103c93
f01025d9:	e8 ad da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01025de:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025e3:	74 19                	je     f01025fe <mem_init+0x155d>
f01025e5:	68 a7 3e 10 f0       	push   $0xf0103ea7
f01025ea:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01025ef:	68 9c 03 00 00       	push   $0x39c
f01025f4:	68 93 3c 10 f0       	push   $0xf0103c93
f01025f9:	e8 8d da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01025fe:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102603:	74 19                	je     f010261e <mem_init+0x157d>
f0102605:	68 11 3f 10 f0       	push   $0xf0103f11
f010260a:	68 b9 3c 10 f0       	push   $0xf0103cb9
f010260f:	68 9d 03 00 00       	push   $0x39d
f0102614:	68 93 3c 10 f0       	push   $0xf0103c93
f0102619:	e8 6d da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010261e:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102625:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102628:	89 f0                	mov    %esi,%eax
f010262a:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102630:	c1 f8 03             	sar    $0x3,%eax
f0102633:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102636:	89 c2                	mov    %eax,%edx
f0102638:	c1 ea 0c             	shr    $0xc,%edx
f010263b:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102641:	72 12                	jb     f0102655 <mem_init+0x15b4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102643:	50                   	push   %eax
f0102644:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0102649:	6a 52                	push   $0x52
f010264b:	68 9f 3c 10 f0       	push   $0xf0103c9f
f0102650:	e8 36 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102655:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010265c:	03 03 03 
f010265f:	74 19                	je     f010267a <mem_init+0x15d9>
f0102661:	68 98 46 10 f0       	push   $0xf0104698
f0102666:	68 b9 3c 10 f0       	push   $0xf0103cb9
f010266b:	68 9f 03 00 00       	push   $0x39f
f0102670:	68 93 3c 10 f0       	push   $0xf0103c93
f0102675:	e8 11 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010267a:	83 ec 08             	sub    $0x8,%esp
f010267d:	68 00 10 00 00       	push   $0x1000
f0102682:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102688:	e8 70 e9 ff ff       	call   f0100ffd <page_remove>
	assert(pp2->pp_ref == 0);
f010268d:	83 c4 10             	add    $0x10,%esp
f0102690:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102695:	74 19                	je     f01026b0 <mem_init+0x160f>
f0102697:	68 df 3e 10 f0       	push   $0xf0103edf
f010269c:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01026a1:	68 a1 03 00 00       	push   $0x3a1
f01026a6:	68 93 3c 10 f0       	push   $0xf0103c93
f01026ab:	e8 db d9 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01026b0:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f01026b6:	8b 11                	mov    (%ecx),%edx
f01026b8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01026be:	89 d8                	mov    %ebx,%eax
f01026c0:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01026c6:	c1 f8 03             	sar    $0x3,%eax
f01026c9:	c1 e0 0c             	shl    $0xc,%eax
f01026cc:	39 c2                	cmp    %eax,%edx
f01026ce:	74 19                	je     f01026e9 <mem_init+0x1648>
f01026d0:	68 dc 41 10 f0       	push   $0xf01041dc
f01026d5:	68 b9 3c 10 f0       	push   $0xf0103cb9
f01026da:	68 a4 03 00 00       	push   $0x3a4
f01026df:	68 93 3c 10 f0       	push   $0xf0103c93
f01026e4:	e8 a2 d9 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01026e9:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026ef:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026f4:	74 19                	je     f010270f <mem_init+0x166e>
f01026f6:	68 96 3e 10 f0       	push   $0xf0103e96
f01026fb:	68 b9 3c 10 f0       	push   $0xf0103cb9
f0102700:	68 a6 03 00 00       	push   $0x3a6
f0102705:	68 93 3c 10 f0       	push   $0xf0103c93
f010270a:	e8 7c d9 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f010270f:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102715:	83 ec 0c             	sub    $0xc,%esp
f0102718:	53                   	push   %ebx
f0102719:	e8 aa e6 ff ff       	call   f0100dc8 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010271e:	c7 04 24 c4 46 10 f0 	movl   $0xf01046c4,(%esp)
f0102725:	e8 7d 00 00 00       	call   f01027a7 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010272a:	83 c4 10             	add    $0x10,%esp
f010272d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102730:	5b                   	pop    %ebx
f0102731:	5e                   	pop    %esi
f0102732:	5f                   	pop    %edi
f0102733:	5d                   	pop    %ebp
f0102734:	c3                   	ret    

f0102735 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102735:	55                   	push   %ebp
f0102736:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102738:	8b 45 0c             	mov    0xc(%ebp),%eax
f010273b:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010273e:	5d                   	pop    %ebp
f010273f:	c3                   	ret    

f0102740 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102740:	55                   	push   %ebp
f0102741:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102743:	ba 70 00 00 00       	mov    $0x70,%edx
f0102748:	8b 45 08             	mov    0x8(%ebp),%eax
f010274b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010274c:	ba 71 00 00 00       	mov    $0x71,%edx
f0102751:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102752:	0f b6 c0             	movzbl %al,%eax
}
f0102755:	5d                   	pop    %ebp
f0102756:	c3                   	ret    

f0102757 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102757:	55                   	push   %ebp
f0102758:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010275a:	ba 70 00 00 00       	mov    $0x70,%edx
f010275f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102762:	ee                   	out    %al,(%dx)
f0102763:	ba 71 00 00 00       	mov    $0x71,%edx
f0102768:	8b 45 0c             	mov    0xc(%ebp),%eax
f010276b:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010276c:	5d                   	pop    %ebp
f010276d:	c3                   	ret    

f010276e <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010276e:	55                   	push   %ebp
f010276f:	89 e5                	mov    %esp,%ebp
f0102771:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102774:	ff 75 08             	pushl  0x8(%ebp)
f0102777:	e8 76 de ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f010277c:	83 c4 10             	add    $0x10,%esp
f010277f:	c9                   	leave  
f0102780:	c3                   	ret    

f0102781 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102781:	55                   	push   %ebp
f0102782:	89 e5                	mov    %esp,%ebp
f0102784:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102787:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010278e:	ff 75 0c             	pushl  0xc(%ebp)
f0102791:	ff 75 08             	pushl  0x8(%ebp)
f0102794:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102797:	50                   	push   %eax
f0102798:	68 6e 27 10 f0       	push   $0xf010276e
f010279d:	e8 c9 03 00 00       	call   f0102b6b <vprintfmt>
	return cnt;
}
f01027a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01027a5:	c9                   	leave  
f01027a6:	c3                   	ret    

f01027a7 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01027a7:	55                   	push   %ebp
f01027a8:	89 e5                	mov    %esp,%ebp
f01027aa:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01027ad:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01027b0:	50                   	push   %eax
f01027b1:	ff 75 08             	pushl  0x8(%ebp)
f01027b4:	e8 c8 ff ff ff       	call   f0102781 <vcprintf>
	va_end(ap);

	return cnt;
}
f01027b9:	c9                   	leave  
f01027ba:	c3                   	ret    

f01027bb <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01027bb:	55                   	push   %ebp
f01027bc:	89 e5                	mov    %esp,%ebp
f01027be:	57                   	push   %edi
f01027bf:	56                   	push   %esi
f01027c0:	53                   	push   %ebx
f01027c1:	83 ec 14             	sub    $0x14,%esp
f01027c4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01027c7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01027ca:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01027cd:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01027d0:	8b 1a                	mov    (%edx),%ebx
f01027d2:	8b 01                	mov    (%ecx),%eax
f01027d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027d7:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01027de:	eb 7f                	jmp    f010285f <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01027e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01027e3:	01 d8                	add    %ebx,%eax
f01027e5:	89 c6                	mov    %eax,%esi
f01027e7:	c1 ee 1f             	shr    $0x1f,%esi
f01027ea:	01 c6                	add    %eax,%esi
f01027ec:	d1 fe                	sar    %esi
f01027ee:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01027f1:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027f4:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01027f7:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027f9:	eb 03                	jmp    f01027fe <stab_binsearch+0x43>
			m--;
f01027fb:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027fe:	39 c3                	cmp    %eax,%ebx
f0102800:	7f 0d                	jg     f010280f <stab_binsearch+0x54>
f0102802:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102806:	83 ea 0c             	sub    $0xc,%edx
f0102809:	39 f9                	cmp    %edi,%ecx
f010280b:	75 ee                	jne    f01027fb <stab_binsearch+0x40>
f010280d:	eb 05                	jmp    f0102814 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010280f:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102812:	eb 4b                	jmp    f010285f <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102814:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102817:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010281a:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010281e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102821:	76 11                	jbe    f0102834 <stab_binsearch+0x79>
			*region_left = m;
f0102823:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102826:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102828:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010282b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102832:	eb 2b                	jmp    f010285f <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102834:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102837:	73 14                	jae    f010284d <stab_binsearch+0x92>
			*region_right = m - 1;
f0102839:	83 e8 01             	sub    $0x1,%eax
f010283c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010283f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102842:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102844:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010284b:	eb 12                	jmp    f010285f <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010284d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102850:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102852:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102856:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102858:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010285f:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102862:	0f 8e 78 ff ff ff    	jle    f01027e0 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102868:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010286c:	75 0f                	jne    f010287d <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010286e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102871:	8b 00                	mov    (%eax),%eax
f0102873:	83 e8 01             	sub    $0x1,%eax
f0102876:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102879:	89 06                	mov    %eax,(%esi)
f010287b:	eb 2c                	jmp    f01028a9 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010287d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102880:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102882:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102885:	8b 0e                	mov    (%esi),%ecx
f0102887:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010288a:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010288d:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102890:	eb 03                	jmp    f0102895 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102892:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102895:	39 c8                	cmp    %ecx,%eax
f0102897:	7e 0b                	jle    f01028a4 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102899:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010289d:	83 ea 0c             	sub    $0xc,%edx
f01028a0:	39 df                	cmp    %ebx,%edi
f01028a2:	75 ee                	jne    f0102892 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01028a4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01028a7:	89 06                	mov    %eax,(%esi)
	}
}
f01028a9:	83 c4 14             	add    $0x14,%esp
f01028ac:	5b                   	pop    %ebx
f01028ad:	5e                   	pop    %esi
f01028ae:	5f                   	pop    %edi
f01028af:	5d                   	pop    %ebp
f01028b0:	c3                   	ret    

f01028b1 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01028b1:	55                   	push   %ebp
f01028b2:	89 e5                	mov    %esp,%ebp
f01028b4:	57                   	push   %edi
f01028b5:	56                   	push   %esi
f01028b6:	53                   	push   %ebx
f01028b7:	83 ec 1c             	sub    $0x1c,%esp
f01028ba:	8b 7d 08             	mov    0x8(%ebp),%edi
f01028bd:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01028c0:	c7 06 f0 46 10 f0    	movl   $0xf01046f0,(%esi)
	info->eip_line = 0;
f01028c6:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01028cd:	c7 46 08 f0 46 10 f0 	movl   $0xf01046f0,0x8(%esi)
	info->eip_fn_namelen = 9;
f01028d4:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01028db:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01028de:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01028e5:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01028eb:	76 11                	jbe    f01028fe <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028ed:	b8 8b c0 10 f0       	mov    $0xf010c08b,%eax
f01028f2:	3d e9 a2 10 f0       	cmp    $0xf010a2e9,%eax
f01028f7:	77 19                	ja     f0102912 <debuginfo_eip+0x61>
f01028f9:	e9 62 01 00 00       	jmp    f0102a60 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01028fe:	83 ec 04             	sub    $0x4,%esp
f0102901:	68 fa 46 10 f0       	push   $0xf01046fa
f0102906:	6a 7f                	push   $0x7f
f0102908:	68 07 47 10 f0       	push   $0xf0104707
f010290d:	e8 79 d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102912:	80 3d 8a c0 10 f0 00 	cmpb   $0x0,0xf010c08a
f0102919:	0f 85 48 01 00 00    	jne    f0102a67 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010291f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102926:	b8 e8 a2 10 f0       	mov    $0xf010a2e8,%eax
f010292b:	2d 30 49 10 f0       	sub    $0xf0104930,%eax
f0102930:	c1 f8 02             	sar    $0x2,%eax
f0102933:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102939:	83 e8 01             	sub    $0x1,%eax
f010293c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010293f:	83 ec 08             	sub    $0x8,%esp
f0102942:	57                   	push   %edi
f0102943:	6a 64                	push   $0x64
f0102945:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102948:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010294b:	b8 30 49 10 f0       	mov    $0xf0104930,%eax
f0102950:	e8 66 fe ff ff       	call   f01027bb <stab_binsearch>
	if (lfile == 0)
f0102955:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102958:	83 c4 10             	add    $0x10,%esp
f010295b:	85 c0                	test   %eax,%eax
f010295d:	0f 84 0b 01 00 00    	je     f0102a6e <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102963:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102966:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102969:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010296c:	83 ec 08             	sub    $0x8,%esp
f010296f:	57                   	push   %edi
f0102970:	6a 24                	push   $0x24
f0102972:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102975:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102978:	b8 30 49 10 f0       	mov    $0xf0104930,%eax
f010297d:	e8 39 fe ff ff       	call   f01027bb <stab_binsearch>

	if (lfun <= rfun) {
f0102982:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102985:	83 c4 10             	add    $0x10,%esp
f0102988:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010298b:	7f 31                	jg     f01029be <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010298d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102990:	c1 e0 02             	shl    $0x2,%eax
f0102993:	8d 90 30 49 10 f0    	lea    -0xfefb6d0(%eax),%edx
f0102999:	8b 88 30 49 10 f0    	mov    -0xfefb6d0(%eax),%ecx
f010299f:	b8 8b c0 10 f0       	mov    $0xf010c08b,%eax
f01029a4:	2d e9 a2 10 f0       	sub    $0xf010a2e9,%eax
f01029a9:	39 c1                	cmp    %eax,%ecx
f01029ab:	73 09                	jae    f01029b6 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01029ad:	81 c1 e9 a2 10 f0    	add    $0xf010a2e9,%ecx
f01029b3:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01029b6:	8b 42 08             	mov    0x8(%edx),%eax
f01029b9:	89 46 10             	mov    %eax,0x10(%esi)
f01029bc:	eb 06                	jmp    f01029c4 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01029be:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f01029c1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01029c4:	83 ec 08             	sub    $0x8,%esp
f01029c7:	6a 3a                	push   $0x3a
f01029c9:	ff 76 08             	pushl  0x8(%esi)
f01029cc:	e8 a3 08 00 00       	call   f0103274 <strfind>
f01029d1:	2b 46 08             	sub    0x8(%esi),%eax
f01029d4:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029d7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01029da:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01029dd:	8d 04 85 30 49 10 f0 	lea    -0xfefb6d0(,%eax,4),%eax
f01029e4:	83 c4 10             	add    $0x10,%esp
f01029e7:	eb 06                	jmp    f01029ef <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01029e9:	83 eb 01             	sub    $0x1,%ebx
f01029ec:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029ef:	39 fb                	cmp    %edi,%ebx
f01029f1:	7c 34                	jl     f0102a27 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f01029f3:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01029f7:	80 fa 84             	cmp    $0x84,%dl
f01029fa:	74 0b                	je     f0102a07 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01029fc:	80 fa 64             	cmp    $0x64,%dl
f01029ff:	75 e8                	jne    f01029e9 <debuginfo_eip+0x138>
f0102a01:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102a05:	74 e2                	je     f01029e9 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102a07:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102a0a:	8b 14 85 30 49 10 f0 	mov    -0xfefb6d0(,%eax,4),%edx
f0102a11:	b8 8b c0 10 f0       	mov    $0xf010c08b,%eax
f0102a16:	2d e9 a2 10 f0       	sub    $0xf010a2e9,%eax
f0102a1b:	39 c2                	cmp    %eax,%edx
f0102a1d:	73 08                	jae    f0102a27 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102a1f:	81 c2 e9 a2 10 f0    	add    $0xf010a2e9,%edx
f0102a25:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a27:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102a2a:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a2d:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a32:	39 cb                	cmp    %ecx,%ebx
f0102a34:	7d 44                	jge    f0102a7a <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0102a36:	8d 53 01             	lea    0x1(%ebx),%edx
f0102a39:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102a3c:	8d 04 85 30 49 10 f0 	lea    -0xfefb6d0(,%eax,4),%eax
f0102a43:	eb 07                	jmp    f0102a4c <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a45:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102a49:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a4c:	39 ca                	cmp    %ecx,%edx
f0102a4e:	74 25                	je     f0102a75 <debuginfo_eip+0x1c4>
f0102a50:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a53:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0102a57:	74 ec                	je     f0102a45 <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a59:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a5e:	eb 1a                	jmp    f0102a7a <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a60:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a65:	eb 13                	jmp    f0102a7a <debuginfo_eip+0x1c9>
f0102a67:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a6c:	eb 0c                	jmp    f0102a7a <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a6e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a73:	eb 05                	jmp    f0102a7a <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a75:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a7a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a7d:	5b                   	pop    %ebx
f0102a7e:	5e                   	pop    %esi
f0102a7f:	5f                   	pop    %edi
f0102a80:	5d                   	pop    %ebp
f0102a81:	c3                   	ret    

f0102a82 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a82:	55                   	push   %ebp
f0102a83:	89 e5                	mov    %esp,%ebp
f0102a85:	57                   	push   %edi
f0102a86:	56                   	push   %esi
f0102a87:	53                   	push   %ebx
f0102a88:	83 ec 1c             	sub    $0x1c,%esp
f0102a8b:	89 c7                	mov    %eax,%edi
f0102a8d:	89 d6                	mov    %edx,%esi
f0102a8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a92:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a95:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a98:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a9b:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a9e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102aa3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102aa6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102aa9:	39 d3                	cmp    %edx,%ebx
f0102aab:	72 05                	jb     f0102ab2 <printnum+0x30>
f0102aad:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102ab0:	77 45                	ja     f0102af7 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102ab2:	83 ec 0c             	sub    $0xc,%esp
f0102ab5:	ff 75 18             	pushl  0x18(%ebp)
f0102ab8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102abb:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102abe:	53                   	push   %ebx
f0102abf:	ff 75 10             	pushl  0x10(%ebp)
f0102ac2:	83 ec 08             	sub    $0x8,%esp
f0102ac5:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102ac8:	ff 75 e0             	pushl  -0x20(%ebp)
f0102acb:	ff 75 dc             	pushl  -0x24(%ebp)
f0102ace:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ad1:	e8 ca 09 00 00       	call   f01034a0 <__udivdi3>
f0102ad6:	83 c4 18             	add    $0x18,%esp
f0102ad9:	52                   	push   %edx
f0102ada:	50                   	push   %eax
f0102adb:	89 f2                	mov    %esi,%edx
f0102add:	89 f8                	mov    %edi,%eax
f0102adf:	e8 9e ff ff ff       	call   f0102a82 <printnum>
f0102ae4:	83 c4 20             	add    $0x20,%esp
f0102ae7:	eb 18                	jmp    f0102b01 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102ae9:	83 ec 08             	sub    $0x8,%esp
f0102aec:	56                   	push   %esi
f0102aed:	ff 75 18             	pushl  0x18(%ebp)
f0102af0:	ff d7                	call   *%edi
f0102af2:	83 c4 10             	add    $0x10,%esp
f0102af5:	eb 03                	jmp    f0102afa <printnum+0x78>
f0102af7:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102afa:	83 eb 01             	sub    $0x1,%ebx
f0102afd:	85 db                	test   %ebx,%ebx
f0102aff:	7f e8                	jg     f0102ae9 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102b01:	83 ec 08             	sub    $0x8,%esp
f0102b04:	56                   	push   %esi
f0102b05:	83 ec 04             	sub    $0x4,%esp
f0102b08:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b0b:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b0e:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b11:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b14:	e8 b7 0a 00 00       	call   f01035d0 <__umoddi3>
f0102b19:	83 c4 14             	add    $0x14,%esp
f0102b1c:	0f be 80 15 47 10 f0 	movsbl -0xfefb8eb(%eax),%eax
f0102b23:	50                   	push   %eax
f0102b24:	ff d7                	call   *%edi
}
f0102b26:	83 c4 10             	add    $0x10,%esp
f0102b29:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b2c:	5b                   	pop    %ebx
f0102b2d:	5e                   	pop    %esi
f0102b2e:	5f                   	pop    %edi
f0102b2f:	5d                   	pop    %ebp
f0102b30:	c3                   	ret    

f0102b31 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b31:	55                   	push   %ebp
f0102b32:	89 e5                	mov    %esp,%ebp
f0102b34:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b37:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b3b:	8b 10                	mov    (%eax),%edx
f0102b3d:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b40:	73 0a                	jae    f0102b4c <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b42:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b45:	89 08                	mov    %ecx,(%eax)
f0102b47:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b4a:	88 02                	mov    %al,(%edx)
}
f0102b4c:	5d                   	pop    %ebp
f0102b4d:	c3                   	ret    

f0102b4e <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b4e:	55                   	push   %ebp
f0102b4f:	89 e5                	mov    %esp,%ebp
f0102b51:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b54:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b57:	50                   	push   %eax
f0102b58:	ff 75 10             	pushl  0x10(%ebp)
f0102b5b:	ff 75 0c             	pushl  0xc(%ebp)
f0102b5e:	ff 75 08             	pushl  0x8(%ebp)
f0102b61:	e8 05 00 00 00       	call   f0102b6b <vprintfmt>
	va_end(ap);
}
f0102b66:	83 c4 10             	add    $0x10,%esp
f0102b69:	c9                   	leave  
f0102b6a:	c3                   	ret    

f0102b6b <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b6b:	55                   	push   %ebp
f0102b6c:	89 e5                	mov    %esp,%ebp
f0102b6e:	57                   	push   %edi
f0102b6f:	56                   	push   %esi
f0102b70:	53                   	push   %ebx
f0102b71:	83 ec 2c             	sub    $0x2c,%esp
f0102b74:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b77:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b7a:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b7d:	eb 12                	jmp    f0102b91 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b7f:	85 c0                	test   %eax,%eax
f0102b81:	0f 84 42 04 00 00    	je     f0102fc9 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0102b87:	83 ec 08             	sub    $0x8,%esp
f0102b8a:	53                   	push   %ebx
f0102b8b:	50                   	push   %eax
f0102b8c:	ff d6                	call   *%esi
f0102b8e:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b91:	83 c7 01             	add    $0x1,%edi
f0102b94:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b98:	83 f8 25             	cmp    $0x25,%eax
f0102b9b:	75 e2                	jne    f0102b7f <vprintfmt+0x14>
f0102b9d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102ba1:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102ba8:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102baf:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102bb6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102bbb:	eb 07                	jmp    f0102bc4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bbd:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102bc0:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bc4:	8d 47 01             	lea    0x1(%edi),%eax
f0102bc7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102bca:	0f b6 07             	movzbl (%edi),%eax
f0102bcd:	0f b6 d0             	movzbl %al,%edx
f0102bd0:	83 e8 23             	sub    $0x23,%eax
f0102bd3:	3c 55                	cmp    $0x55,%al
f0102bd5:	0f 87 d3 03 00 00    	ja     f0102fae <vprintfmt+0x443>
f0102bdb:	0f b6 c0             	movzbl %al,%eax
f0102bde:	ff 24 85 a0 47 10 f0 	jmp    *-0xfefb860(,%eax,4)
f0102be5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102be8:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102bec:	eb d6                	jmp    f0102bc4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bf1:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bf6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102bf9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102bfc:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102c00:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102c03:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102c06:	83 f9 09             	cmp    $0x9,%ecx
f0102c09:	77 3f                	ja     f0102c4a <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102c0b:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102c0e:	eb e9                	jmp    f0102bf9 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102c10:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c13:	8b 00                	mov    (%eax),%eax
f0102c15:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102c18:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c1b:	8d 40 04             	lea    0x4(%eax),%eax
f0102c1e:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c21:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c24:	eb 2a                	jmp    f0102c50 <vprintfmt+0xe5>
f0102c26:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c29:	85 c0                	test   %eax,%eax
f0102c2b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c30:	0f 49 d0             	cmovns %eax,%edx
f0102c33:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c36:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c39:	eb 89                	jmp    f0102bc4 <vprintfmt+0x59>
f0102c3b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c3e:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c45:	e9 7a ff ff ff       	jmp    f0102bc4 <vprintfmt+0x59>
f0102c4a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102c4d:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c50:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c54:	0f 89 6a ff ff ff    	jns    f0102bc4 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c5a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c5d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c60:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c67:	e9 58 ff ff ff       	jmp    f0102bc4 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c6c:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c6f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c72:	e9 4d ff ff ff       	jmp    f0102bc4 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c77:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c7a:	8d 78 04             	lea    0x4(%eax),%edi
f0102c7d:	83 ec 08             	sub    $0x8,%esp
f0102c80:	53                   	push   %ebx
f0102c81:	ff 30                	pushl  (%eax)
f0102c83:	ff d6                	call   *%esi
			break;
f0102c85:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c88:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c8b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c8e:	e9 fe fe ff ff       	jmp    f0102b91 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c93:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c96:	8d 78 04             	lea    0x4(%eax),%edi
f0102c99:	8b 00                	mov    (%eax),%eax
f0102c9b:	99                   	cltd   
f0102c9c:	31 d0                	xor    %edx,%eax
f0102c9e:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102ca0:	83 f8 07             	cmp    $0x7,%eax
f0102ca3:	7f 0b                	jg     f0102cb0 <vprintfmt+0x145>
f0102ca5:	8b 14 85 00 49 10 f0 	mov    -0xfefb700(,%eax,4),%edx
f0102cac:	85 d2                	test   %edx,%edx
f0102cae:	75 1b                	jne    f0102ccb <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102cb0:	50                   	push   %eax
f0102cb1:	68 2d 47 10 f0       	push   $0xf010472d
f0102cb6:	53                   	push   %ebx
f0102cb7:	56                   	push   %esi
f0102cb8:	e8 91 fe ff ff       	call   f0102b4e <printfmt>
f0102cbd:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102cc0:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cc3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102cc6:	e9 c6 fe ff ff       	jmp    f0102b91 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102ccb:	52                   	push   %edx
f0102ccc:	68 cb 3c 10 f0       	push   $0xf0103ccb
f0102cd1:	53                   	push   %ebx
f0102cd2:	56                   	push   %esi
f0102cd3:	e8 76 fe ff ff       	call   f0102b4e <printfmt>
f0102cd8:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102cdb:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cde:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ce1:	e9 ab fe ff ff       	jmp    f0102b91 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102ce6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ce9:	83 c0 04             	add    $0x4,%eax
f0102cec:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102cef:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cf2:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102cf4:	85 ff                	test   %edi,%edi
f0102cf6:	b8 26 47 10 f0       	mov    $0xf0104726,%eax
f0102cfb:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102cfe:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d02:	0f 8e 94 00 00 00    	jle    f0102d9c <vprintfmt+0x231>
f0102d08:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102d0c:	0f 84 98 00 00 00    	je     f0102daa <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d12:	83 ec 08             	sub    $0x8,%esp
f0102d15:	ff 75 d0             	pushl  -0x30(%ebp)
f0102d18:	57                   	push   %edi
f0102d19:	e8 0c 04 00 00       	call   f010312a <strnlen>
f0102d1e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d21:	29 c1                	sub    %eax,%ecx
f0102d23:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102d26:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d29:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d2d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d30:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d33:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d35:	eb 0f                	jmp    f0102d46 <vprintfmt+0x1db>
					putch(padc, putdat);
f0102d37:	83 ec 08             	sub    $0x8,%esp
f0102d3a:	53                   	push   %ebx
f0102d3b:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d3e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d40:	83 ef 01             	sub    $0x1,%edi
f0102d43:	83 c4 10             	add    $0x10,%esp
f0102d46:	85 ff                	test   %edi,%edi
f0102d48:	7f ed                	jg     f0102d37 <vprintfmt+0x1cc>
f0102d4a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d4d:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102d50:	85 c9                	test   %ecx,%ecx
f0102d52:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d57:	0f 49 c1             	cmovns %ecx,%eax
f0102d5a:	29 c1                	sub    %eax,%ecx
f0102d5c:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d5f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d62:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d65:	89 cb                	mov    %ecx,%ebx
f0102d67:	eb 4d                	jmp    f0102db6 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d69:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d6d:	74 1b                	je     f0102d8a <vprintfmt+0x21f>
f0102d6f:	0f be c0             	movsbl %al,%eax
f0102d72:	83 e8 20             	sub    $0x20,%eax
f0102d75:	83 f8 5e             	cmp    $0x5e,%eax
f0102d78:	76 10                	jbe    f0102d8a <vprintfmt+0x21f>
					putch('?', putdat);
f0102d7a:	83 ec 08             	sub    $0x8,%esp
f0102d7d:	ff 75 0c             	pushl  0xc(%ebp)
f0102d80:	6a 3f                	push   $0x3f
f0102d82:	ff 55 08             	call   *0x8(%ebp)
f0102d85:	83 c4 10             	add    $0x10,%esp
f0102d88:	eb 0d                	jmp    f0102d97 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102d8a:	83 ec 08             	sub    $0x8,%esp
f0102d8d:	ff 75 0c             	pushl  0xc(%ebp)
f0102d90:	52                   	push   %edx
f0102d91:	ff 55 08             	call   *0x8(%ebp)
f0102d94:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d97:	83 eb 01             	sub    $0x1,%ebx
f0102d9a:	eb 1a                	jmp    f0102db6 <vprintfmt+0x24b>
f0102d9c:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d9f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102da2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102da5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102da8:	eb 0c                	jmp    f0102db6 <vprintfmt+0x24b>
f0102daa:	89 75 08             	mov    %esi,0x8(%ebp)
f0102dad:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102db0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102db3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102db6:	83 c7 01             	add    $0x1,%edi
f0102db9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102dbd:	0f be d0             	movsbl %al,%edx
f0102dc0:	85 d2                	test   %edx,%edx
f0102dc2:	74 23                	je     f0102de7 <vprintfmt+0x27c>
f0102dc4:	85 f6                	test   %esi,%esi
f0102dc6:	78 a1                	js     f0102d69 <vprintfmt+0x1fe>
f0102dc8:	83 ee 01             	sub    $0x1,%esi
f0102dcb:	79 9c                	jns    f0102d69 <vprintfmt+0x1fe>
f0102dcd:	89 df                	mov    %ebx,%edi
f0102dcf:	8b 75 08             	mov    0x8(%ebp),%esi
f0102dd2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102dd5:	eb 18                	jmp    f0102def <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102dd7:	83 ec 08             	sub    $0x8,%esp
f0102dda:	53                   	push   %ebx
f0102ddb:	6a 20                	push   $0x20
f0102ddd:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102ddf:	83 ef 01             	sub    $0x1,%edi
f0102de2:	83 c4 10             	add    $0x10,%esp
f0102de5:	eb 08                	jmp    f0102def <vprintfmt+0x284>
f0102de7:	89 df                	mov    %ebx,%edi
f0102de9:	8b 75 08             	mov    0x8(%ebp),%esi
f0102dec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102def:	85 ff                	test   %edi,%edi
f0102df1:	7f e4                	jg     f0102dd7 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102df3:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102df6:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102df9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dfc:	e9 90 fd ff ff       	jmp    f0102b91 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e01:	83 f9 01             	cmp    $0x1,%ecx
f0102e04:	7e 19                	jle    f0102e1f <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102e06:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e09:	8b 50 04             	mov    0x4(%eax),%edx
f0102e0c:	8b 00                	mov    (%eax),%eax
f0102e0e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e11:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102e14:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e17:	8d 40 08             	lea    0x8(%eax),%eax
f0102e1a:	89 45 14             	mov    %eax,0x14(%ebp)
f0102e1d:	eb 38                	jmp    f0102e57 <vprintfmt+0x2ec>
	else if (lflag)
f0102e1f:	85 c9                	test   %ecx,%ecx
f0102e21:	74 1b                	je     f0102e3e <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102e23:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e26:	8b 00                	mov    (%eax),%eax
f0102e28:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e2b:	89 c1                	mov    %eax,%ecx
f0102e2d:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e30:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e33:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e36:	8d 40 04             	lea    0x4(%eax),%eax
f0102e39:	89 45 14             	mov    %eax,0x14(%ebp)
f0102e3c:	eb 19                	jmp    f0102e57 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102e3e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e41:	8b 00                	mov    (%eax),%eax
f0102e43:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e46:	89 c1                	mov    %eax,%ecx
f0102e48:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e4b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e4e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e51:	8d 40 04             	lea    0x4(%eax),%eax
f0102e54:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e57:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e5a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e5d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e62:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e66:	0f 89 0e 01 00 00    	jns    f0102f7a <vprintfmt+0x40f>
				putch('-', putdat);
f0102e6c:	83 ec 08             	sub    $0x8,%esp
f0102e6f:	53                   	push   %ebx
f0102e70:	6a 2d                	push   $0x2d
f0102e72:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e74:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e77:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102e7a:	f7 da                	neg    %edx
f0102e7c:	83 d1 00             	adc    $0x0,%ecx
f0102e7f:	f7 d9                	neg    %ecx
f0102e81:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e84:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e89:	e9 ec 00 00 00       	jmp    f0102f7a <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e8e:	83 f9 01             	cmp    $0x1,%ecx
f0102e91:	7e 18                	jle    f0102eab <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102e93:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e96:	8b 10                	mov    (%eax),%edx
f0102e98:	8b 48 04             	mov    0x4(%eax),%ecx
f0102e9b:	8d 40 08             	lea    0x8(%eax),%eax
f0102e9e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102ea1:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ea6:	e9 cf 00 00 00       	jmp    f0102f7a <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102eab:	85 c9                	test   %ecx,%ecx
f0102ead:	74 1a                	je     f0102ec9 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102eaf:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eb2:	8b 10                	mov    (%eax),%edx
f0102eb4:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102eb9:	8d 40 04             	lea    0x4(%eax),%eax
f0102ebc:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102ebf:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ec4:	e9 b1 00 00 00       	jmp    f0102f7a <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102ec9:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ecc:	8b 10                	mov    (%eax),%edx
f0102ece:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102ed3:	8d 40 04             	lea    0x4(%eax),%eax
f0102ed6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102ed9:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ede:	e9 97 00 00 00       	jmp    f0102f7a <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0102ee3:	83 ec 08             	sub    $0x8,%esp
f0102ee6:	53                   	push   %ebx
f0102ee7:	6a 58                	push   $0x58
f0102ee9:	ff d6                	call   *%esi
			putch('X', putdat);
f0102eeb:	83 c4 08             	add    $0x8,%esp
f0102eee:	53                   	push   %ebx
f0102eef:	6a 58                	push   $0x58
f0102ef1:	ff d6                	call   *%esi
			putch('X', putdat);
f0102ef3:	83 c4 08             	add    $0x8,%esp
f0102ef6:	53                   	push   %ebx
f0102ef7:	6a 58                	push   $0x58
f0102ef9:	ff d6                	call   *%esi
			break;
f0102efb:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102efe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0102f01:	e9 8b fc ff ff       	jmp    f0102b91 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0102f06:	83 ec 08             	sub    $0x8,%esp
f0102f09:	53                   	push   %ebx
f0102f0a:	6a 30                	push   $0x30
f0102f0c:	ff d6                	call   *%esi
			putch('x', putdat);
f0102f0e:	83 c4 08             	add    $0x8,%esp
f0102f11:	53                   	push   %ebx
f0102f12:	6a 78                	push   $0x78
f0102f14:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102f16:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f19:	8b 10                	mov    (%eax),%edx
f0102f1b:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102f20:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102f23:	8d 40 04             	lea    0x4(%eax),%eax
f0102f26:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102f29:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102f2e:	eb 4a                	jmp    f0102f7a <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102f30:	83 f9 01             	cmp    $0x1,%ecx
f0102f33:	7e 15                	jle    f0102f4a <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0102f35:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f38:	8b 10                	mov    (%eax),%edx
f0102f3a:	8b 48 04             	mov    0x4(%eax),%ecx
f0102f3d:	8d 40 08             	lea    0x8(%eax),%eax
f0102f40:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f43:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f48:	eb 30                	jmp    f0102f7a <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102f4a:	85 c9                	test   %ecx,%ecx
f0102f4c:	74 17                	je     f0102f65 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0102f4e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f51:	8b 10                	mov    (%eax),%edx
f0102f53:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f58:	8d 40 04             	lea    0x4(%eax),%eax
f0102f5b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f5e:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f63:	eb 15                	jmp    f0102f7a <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102f65:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f68:	8b 10                	mov    (%eax),%edx
f0102f6a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f6f:	8d 40 04             	lea    0x4(%eax),%eax
f0102f72:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f75:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102f7a:	83 ec 0c             	sub    $0xc,%esp
f0102f7d:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102f81:	57                   	push   %edi
f0102f82:	ff 75 e0             	pushl  -0x20(%ebp)
f0102f85:	50                   	push   %eax
f0102f86:	51                   	push   %ecx
f0102f87:	52                   	push   %edx
f0102f88:	89 da                	mov    %ebx,%edx
f0102f8a:	89 f0                	mov    %esi,%eax
f0102f8c:	e8 f1 fa ff ff       	call   f0102a82 <printnum>
			break;
f0102f91:	83 c4 20             	add    $0x20,%esp
f0102f94:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f97:	e9 f5 fb ff ff       	jmp    f0102b91 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102f9c:	83 ec 08             	sub    $0x8,%esp
f0102f9f:	53                   	push   %ebx
f0102fa0:	52                   	push   %edx
f0102fa1:	ff d6                	call   *%esi
			break;
f0102fa3:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102fa6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102fa9:	e9 e3 fb ff ff       	jmp    f0102b91 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102fae:	83 ec 08             	sub    $0x8,%esp
f0102fb1:	53                   	push   %ebx
f0102fb2:	6a 25                	push   $0x25
f0102fb4:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102fb6:	83 c4 10             	add    $0x10,%esp
f0102fb9:	eb 03                	jmp    f0102fbe <vprintfmt+0x453>
f0102fbb:	83 ef 01             	sub    $0x1,%edi
f0102fbe:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102fc2:	75 f7                	jne    f0102fbb <vprintfmt+0x450>
f0102fc4:	e9 c8 fb ff ff       	jmp    f0102b91 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102fc9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fcc:	5b                   	pop    %ebx
f0102fcd:	5e                   	pop    %esi
f0102fce:	5f                   	pop    %edi
f0102fcf:	5d                   	pop    %ebp
f0102fd0:	c3                   	ret    

f0102fd1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102fd1:	55                   	push   %ebp
f0102fd2:	89 e5                	mov    %esp,%ebp
f0102fd4:	83 ec 18             	sub    $0x18,%esp
f0102fd7:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fda:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102fdd:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102fe0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102fe4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102fe7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102fee:	85 c0                	test   %eax,%eax
f0102ff0:	74 26                	je     f0103018 <vsnprintf+0x47>
f0102ff2:	85 d2                	test   %edx,%edx
f0102ff4:	7e 22                	jle    f0103018 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102ff6:	ff 75 14             	pushl  0x14(%ebp)
f0102ff9:	ff 75 10             	pushl  0x10(%ebp)
f0102ffc:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102fff:	50                   	push   %eax
f0103000:	68 31 2b 10 f0       	push   $0xf0102b31
f0103005:	e8 61 fb ff ff       	call   f0102b6b <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010300a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010300d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103010:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103013:	83 c4 10             	add    $0x10,%esp
f0103016:	eb 05                	jmp    f010301d <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103018:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010301d:	c9                   	leave  
f010301e:	c3                   	ret    

f010301f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010301f:	55                   	push   %ebp
f0103020:	89 e5                	mov    %esp,%ebp
f0103022:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103025:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103028:	50                   	push   %eax
f0103029:	ff 75 10             	pushl  0x10(%ebp)
f010302c:	ff 75 0c             	pushl  0xc(%ebp)
f010302f:	ff 75 08             	pushl  0x8(%ebp)
f0103032:	e8 9a ff ff ff       	call   f0102fd1 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103037:	c9                   	leave  
f0103038:	c3                   	ret    

f0103039 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103039:	55                   	push   %ebp
f010303a:	89 e5                	mov    %esp,%ebp
f010303c:	57                   	push   %edi
f010303d:	56                   	push   %esi
f010303e:	53                   	push   %ebx
f010303f:	83 ec 0c             	sub    $0xc,%esp
f0103042:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103045:	85 c0                	test   %eax,%eax
f0103047:	74 11                	je     f010305a <readline+0x21>
		cprintf("%s", prompt);
f0103049:	83 ec 08             	sub    $0x8,%esp
f010304c:	50                   	push   %eax
f010304d:	68 cb 3c 10 f0       	push   $0xf0103ccb
f0103052:	e8 50 f7 ff ff       	call   f01027a7 <cprintf>
f0103057:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010305a:	83 ec 0c             	sub    $0xc,%esp
f010305d:	6a 00                	push   $0x0
f010305f:	e8 af d5 ff ff       	call   f0100613 <iscons>
f0103064:	89 c7                	mov    %eax,%edi
f0103066:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103069:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010306e:	e8 8f d5 ff ff       	call   f0100602 <getchar>
f0103073:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103075:	85 c0                	test   %eax,%eax
f0103077:	79 18                	jns    f0103091 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103079:	83 ec 08             	sub    $0x8,%esp
f010307c:	50                   	push   %eax
f010307d:	68 20 49 10 f0       	push   $0xf0104920
f0103082:	e8 20 f7 ff ff       	call   f01027a7 <cprintf>
			return NULL;
f0103087:	83 c4 10             	add    $0x10,%esp
f010308a:	b8 00 00 00 00       	mov    $0x0,%eax
f010308f:	eb 79                	jmp    f010310a <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103091:	83 f8 08             	cmp    $0x8,%eax
f0103094:	0f 94 c2             	sete   %dl
f0103097:	83 f8 7f             	cmp    $0x7f,%eax
f010309a:	0f 94 c0             	sete   %al
f010309d:	08 c2                	or     %al,%dl
f010309f:	74 1a                	je     f01030bb <readline+0x82>
f01030a1:	85 f6                	test   %esi,%esi
f01030a3:	7e 16                	jle    f01030bb <readline+0x82>
			if (echoing)
f01030a5:	85 ff                	test   %edi,%edi
f01030a7:	74 0d                	je     f01030b6 <readline+0x7d>
				cputchar('\b');
f01030a9:	83 ec 0c             	sub    $0xc,%esp
f01030ac:	6a 08                	push   $0x8
f01030ae:	e8 3f d5 ff ff       	call   f01005f2 <cputchar>
f01030b3:	83 c4 10             	add    $0x10,%esp
			i--;
f01030b6:	83 ee 01             	sub    $0x1,%esi
f01030b9:	eb b3                	jmp    f010306e <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01030bb:	83 fb 1f             	cmp    $0x1f,%ebx
f01030be:	7e 23                	jle    f01030e3 <readline+0xaa>
f01030c0:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01030c6:	7f 1b                	jg     f01030e3 <readline+0xaa>
			if (echoing)
f01030c8:	85 ff                	test   %edi,%edi
f01030ca:	74 0c                	je     f01030d8 <readline+0x9f>
				cputchar(c);
f01030cc:	83 ec 0c             	sub    $0xc,%esp
f01030cf:	53                   	push   %ebx
f01030d0:	e8 1d d5 ff ff       	call   f01005f2 <cputchar>
f01030d5:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01030d8:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f01030de:	8d 76 01             	lea    0x1(%esi),%esi
f01030e1:	eb 8b                	jmp    f010306e <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01030e3:	83 fb 0a             	cmp    $0xa,%ebx
f01030e6:	74 05                	je     f01030ed <readline+0xb4>
f01030e8:	83 fb 0d             	cmp    $0xd,%ebx
f01030eb:	75 81                	jne    f010306e <readline+0x35>
			if (echoing)
f01030ed:	85 ff                	test   %edi,%edi
f01030ef:	74 0d                	je     f01030fe <readline+0xc5>
				cputchar('\n');
f01030f1:	83 ec 0c             	sub    $0xc,%esp
f01030f4:	6a 0a                	push   $0xa
f01030f6:	e8 f7 d4 ff ff       	call   f01005f2 <cputchar>
f01030fb:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01030fe:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f0103105:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f010310a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010310d:	5b                   	pop    %ebx
f010310e:	5e                   	pop    %esi
f010310f:	5f                   	pop    %edi
f0103110:	5d                   	pop    %ebp
f0103111:	c3                   	ret    

f0103112 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103112:	55                   	push   %ebp
f0103113:	89 e5                	mov    %esp,%ebp
f0103115:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103118:	b8 00 00 00 00       	mov    $0x0,%eax
f010311d:	eb 03                	jmp    f0103122 <strlen+0x10>
		n++;
f010311f:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103122:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103126:	75 f7                	jne    f010311f <strlen+0xd>
		n++;
	return n;
}
f0103128:	5d                   	pop    %ebp
f0103129:	c3                   	ret    

f010312a <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010312a:	55                   	push   %ebp
f010312b:	89 e5                	mov    %esp,%ebp
f010312d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103130:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103133:	ba 00 00 00 00       	mov    $0x0,%edx
f0103138:	eb 03                	jmp    f010313d <strnlen+0x13>
		n++;
f010313a:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010313d:	39 c2                	cmp    %eax,%edx
f010313f:	74 08                	je     f0103149 <strnlen+0x1f>
f0103141:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103145:	75 f3                	jne    f010313a <strnlen+0x10>
f0103147:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103149:	5d                   	pop    %ebp
f010314a:	c3                   	ret    

f010314b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010314b:	55                   	push   %ebp
f010314c:	89 e5                	mov    %esp,%ebp
f010314e:	53                   	push   %ebx
f010314f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103152:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103155:	89 c2                	mov    %eax,%edx
f0103157:	83 c2 01             	add    $0x1,%edx
f010315a:	83 c1 01             	add    $0x1,%ecx
f010315d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103161:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103164:	84 db                	test   %bl,%bl
f0103166:	75 ef                	jne    f0103157 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103168:	5b                   	pop    %ebx
f0103169:	5d                   	pop    %ebp
f010316a:	c3                   	ret    

f010316b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010316b:	55                   	push   %ebp
f010316c:	89 e5                	mov    %esp,%ebp
f010316e:	53                   	push   %ebx
f010316f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103172:	53                   	push   %ebx
f0103173:	e8 9a ff ff ff       	call   f0103112 <strlen>
f0103178:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010317b:	ff 75 0c             	pushl  0xc(%ebp)
f010317e:	01 d8                	add    %ebx,%eax
f0103180:	50                   	push   %eax
f0103181:	e8 c5 ff ff ff       	call   f010314b <strcpy>
	return dst;
}
f0103186:	89 d8                	mov    %ebx,%eax
f0103188:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010318b:	c9                   	leave  
f010318c:	c3                   	ret    

f010318d <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010318d:	55                   	push   %ebp
f010318e:	89 e5                	mov    %esp,%ebp
f0103190:	56                   	push   %esi
f0103191:	53                   	push   %ebx
f0103192:	8b 75 08             	mov    0x8(%ebp),%esi
f0103195:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103198:	89 f3                	mov    %esi,%ebx
f010319a:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010319d:	89 f2                	mov    %esi,%edx
f010319f:	eb 0f                	jmp    f01031b0 <strncpy+0x23>
		*dst++ = *src;
f01031a1:	83 c2 01             	add    $0x1,%edx
f01031a4:	0f b6 01             	movzbl (%ecx),%eax
f01031a7:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01031aa:	80 39 01             	cmpb   $0x1,(%ecx)
f01031ad:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01031b0:	39 da                	cmp    %ebx,%edx
f01031b2:	75 ed                	jne    f01031a1 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01031b4:	89 f0                	mov    %esi,%eax
f01031b6:	5b                   	pop    %ebx
f01031b7:	5e                   	pop    %esi
f01031b8:	5d                   	pop    %ebp
f01031b9:	c3                   	ret    

f01031ba <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01031ba:	55                   	push   %ebp
f01031bb:	89 e5                	mov    %esp,%ebp
f01031bd:	56                   	push   %esi
f01031be:	53                   	push   %ebx
f01031bf:	8b 75 08             	mov    0x8(%ebp),%esi
f01031c2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031c5:	8b 55 10             	mov    0x10(%ebp),%edx
f01031c8:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01031ca:	85 d2                	test   %edx,%edx
f01031cc:	74 21                	je     f01031ef <strlcpy+0x35>
f01031ce:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01031d2:	89 f2                	mov    %esi,%edx
f01031d4:	eb 09                	jmp    f01031df <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01031d6:	83 c2 01             	add    $0x1,%edx
f01031d9:	83 c1 01             	add    $0x1,%ecx
f01031dc:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01031df:	39 c2                	cmp    %eax,%edx
f01031e1:	74 09                	je     f01031ec <strlcpy+0x32>
f01031e3:	0f b6 19             	movzbl (%ecx),%ebx
f01031e6:	84 db                	test   %bl,%bl
f01031e8:	75 ec                	jne    f01031d6 <strlcpy+0x1c>
f01031ea:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01031ec:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01031ef:	29 f0                	sub    %esi,%eax
}
f01031f1:	5b                   	pop    %ebx
f01031f2:	5e                   	pop    %esi
f01031f3:	5d                   	pop    %ebp
f01031f4:	c3                   	ret    

f01031f5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01031f5:	55                   	push   %ebp
f01031f6:	89 e5                	mov    %esp,%ebp
f01031f8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031fb:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01031fe:	eb 06                	jmp    f0103206 <strcmp+0x11>
		p++, q++;
f0103200:	83 c1 01             	add    $0x1,%ecx
f0103203:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103206:	0f b6 01             	movzbl (%ecx),%eax
f0103209:	84 c0                	test   %al,%al
f010320b:	74 04                	je     f0103211 <strcmp+0x1c>
f010320d:	3a 02                	cmp    (%edx),%al
f010320f:	74 ef                	je     f0103200 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103211:	0f b6 c0             	movzbl %al,%eax
f0103214:	0f b6 12             	movzbl (%edx),%edx
f0103217:	29 d0                	sub    %edx,%eax
}
f0103219:	5d                   	pop    %ebp
f010321a:	c3                   	ret    

f010321b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010321b:	55                   	push   %ebp
f010321c:	89 e5                	mov    %esp,%ebp
f010321e:	53                   	push   %ebx
f010321f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103222:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103225:	89 c3                	mov    %eax,%ebx
f0103227:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010322a:	eb 06                	jmp    f0103232 <strncmp+0x17>
		n--, p++, q++;
f010322c:	83 c0 01             	add    $0x1,%eax
f010322f:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103232:	39 d8                	cmp    %ebx,%eax
f0103234:	74 15                	je     f010324b <strncmp+0x30>
f0103236:	0f b6 08             	movzbl (%eax),%ecx
f0103239:	84 c9                	test   %cl,%cl
f010323b:	74 04                	je     f0103241 <strncmp+0x26>
f010323d:	3a 0a                	cmp    (%edx),%cl
f010323f:	74 eb                	je     f010322c <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103241:	0f b6 00             	movzbl (%eax),%eax
f0103244:	0f b6 12             	movzbl (%edx),%edx
f0103247:	29 d0                	sub    %edx,%eax
f0103249:	eb 05                	jmp    f0103250 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010324b:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103250:	5b                   	pop    %ebx
f0103251:	5d                   	pop    %ebp
f0103252:	c3                   	ret    

f0103253 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103253:	55                   	push   %ebp
f0103254:	89 e5                	mov    %esp,%ebp
f0103256:	8b 45 08             	mov    0x8(%ebp),%eax
f0103259:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010325d:	eb 07                	jmp    f0103266 <strchr+0x13>
		if (*s == c)
f010325f:	38 ca                	cmp    %cl,%dl
f0103261:	74 0f                	je     f0103272 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103263:	83 c0 01             	add    $0x1,%eax
f0103266:	0f b6 10             	movzbl (%eax),%edx
f0103269:	84 d2                	test   %dl,%dl
f010326b:	75 f2                	jne    f010325f <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010326d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103272:	5d                   	pop    %ebp
f0103273:	c3                   	ret    

f0103274 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103274:	55                   	push   %ebp
f0103275:	89 e5                	mov    %esp,%ebp
f0103277:	8b 45 08             	mov    0x8(%ebp),%eax
f010327a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010327e:	eb 03                	jmp    f0103283 <strfind+0xf>
f0103280:	83 c0 01             	add    $0x1,%eax
f0103283:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103286:	38 ca                	cmp    %cl,%dl
f0103288:	74 04                	je     f010328e <strfind+0x1a>
f010328a:	84 d2                	test   %dl,%dl
f010328c:	75 f2                	jne    f0103280 <strfind+0xc>
			break;
	return (char *) s;
}
f010328e:	5d                   	pop    %ebp
f010328f:	c3                   	ret    

f0103290 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103290:	55                   	push   %ebp
f0103291:	89 e5                	mov    %esp,%ebp
f0103293:	57                   	push   %edi
f0103294:	56                   	push   %esi
f0103295:	53                   	push   %ebx
f0103296:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103299:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010329c:	85 c9                	test   %ecx,%ecx
f010329e:	74 36                	je     f01032d6 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01032a0:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01032a6:	75 28                	jne    f01032d0 <memset+0x40>
f01032a8:	f6 c1 03             	test   $0x3,%cl
f01032ab:	75 23                	jne    f01032d0 <memset+0x40>
		c &= 0xFF;
f01032ad:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01032b1:	89 d3                	mov    %edx,%ebx
f01032b3:	c1 e3 08             	shl    $0x8,%ebx
f01032b6:	89 d6                	mov    %edx,%esi
f01032b8:	c1 e6 18             	shl    $0x18,%esi
f01032bb:	89 d0                	mov    %edx,%eax
f01032bd:	c1 e0 10             	shl    $0x10,%eax
f01032c0:	09 f0                	or     %esi,%eax
f01032c2:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01032c4:	89 d8                	mov    %ebx,%eax
f01032c6:	09 d0                	or     %edx,%eax
f01032c8:	c1 e9 02             	shr    $0x2,%ecx
f01032cb:	fc                   	cld    
f01032cc:	f3 ab                	rep stos %eax,%es:(%edi)
f01032ce:	eb 06                	jmp    f01032d6 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01032d0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032d3:	fc                   	cld    
f01032d4:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01032d6:	89 f8                	mov    %edi,%eax
f01032d8:	5b                   	pop    %ebx
f01032d9:	5e                   	pop    %esi
f01032da:	5f                   	pop    %edi
f01032db:	5d                   	pop    %ebp
f01032dc:	c3                   	ret    

f01032dd <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01032dd:	55                   	push   %ebp
f01032de:	89 e5                	mov    %esp,%ebp
f01032e0:	57                   	push   %edi
f01032e1:	56                   	push   %esi
f01032e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01032e5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01032e8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01032eb:	39 c6                	cmp    %eax,%esi
f01032ed:	73 35                	jae    f0103324 <memmove+0x47>
f01032ef:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01032f2:	39 d0                	cmp    %edx,%eax
f01032f4:	73 2e                	jae    f0103324 <memmove+0x47>
		s += n;
		d += n;
f01032f6:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032f9:	89 d6                	mov    %edx,%esi
f01032fb:	09 fe                	or     %edi,%esi
f01032fd:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103303:	75 13                	jne    f0103318 <memmove+0x3b>
f0103305:	f6 c1 03             	test   $0x3,%cl
f0103308:	75 0e                	jne    f0103318 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010330a:	83 ef 04             	sub    $0x4,%edi
f010330d:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103310:	c1 e9 02             	shr    $0x2,%ecx
f0103313:	fd                   	std    
f0103314:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103316:	eb 09                	jmp    f0103321 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103318:	83 ef 01             	sub    $0x1,%edi
f010331b:	8d 72 ff             	lea    -0x1(%edx),%esi
f010331e:	fd                   	std    
f010331f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103321:	fc                   	cld    
f0103322:	eb 1d                	jmp    f0103341 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103324:	89 f2                	mov    %esi,%edx
f0103326:	09 c2                	or     %eax,%edx
f0103328:	f6 c2 03             	test   $0x3,%dl
f010332b:	75 0f                	jne    f010333c <memmove+0x5f>
f010332d:	f6 c1 03             	test   $0x3,%cl
f0103330:	75 0a                	jne    f010333c <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103332:	c1 e9 02             	shr    $0x2,%ecx
f0103335:	89 c7                	mov    %eax,%edi
f0103337:	fc                   	cld    
f0103338:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010333a:	eb 05                	jmp    f0103341 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010333c:	89 c7                	mov    %eax,%edi
f010333e:	fc                   	cld    
f010333f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103341:	5e                   	pop    %esi
f0103342:	5f                   	pop    %edi
f0103343:	5d                   	pop    %ebp
f0103344:	c3                   	ret    

f0103345 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103345:	55                   	push   %ebp
f0103346:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103348:	ff 75 10             	pushl  0x10(%ebp)
f010334b:	ff 75 0c             	pushl  0xc(%ebp)
f010334e:	ff 75 08             	pushl  0x8(%ebp)
f0103351:	e8 87 ff ff ff       	call   f01032dd <memmove>
}
f0103356:	c9                   	leave  
f0103357:	c3                   	ret    

f0103358 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103358:	55                   	push   %ebp
f0103359:	89 e5                	mov    %esp,%ebp
f010335b:	56                   	push   %esi
f010335c:	53                   	push   %ebx
f010335d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103360:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103363:	89 c6                	mov    %eax,%esi
f0103365:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103368:	eb 1a                	jmp    f0103384 <memcmp+0x2c>
		if (*s1 != *s2)
f010336a:	0f b6 08             	movzbl (%eax),%ecx
f010336d:	0f b6 1a             	movzbl (%edx),%ebx
f0103370:	38 d9                	cmp    %bl,%cl
f0103372:	74 0a                	je     f010337e <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103374:	0f b6 c1             	movzbl %cl,%eax
f0103377:	0f b6 db             	movzbl %bl,%ebx
f010337a:	29 d8                	sub    %ebx,%eax
f010337c:	eb 0f                	jmp    f010338d <memcmp+0x35>
		s1++, s2++;
f010337e:	83 c0 01             	add    $0x1,%eax
f0103381:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103384:	39 f0                	cmp    %esi,%eax
f0103386:	75 e2                	jne    f010336a <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103388:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010338d:	5b                   	pop    %ebx
f010338e:	5e                   	pop    %esi
f010338f:	5d                   	pop    %ebp
f0103390:	c3                   	ret    

f0103391 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103391:	55                   	push   %ebp
f0103392:	89 e5                	mov    %esp,%ebp
f0103394:	53                   	push   %ebx
f0103395:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103398:	89 c1                	mov    %eax,%ecx
f010339a:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010339d:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01033a1:	eb 0a                	jmp    f01033ad <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01033a3:	0f b6 10             	movzbl (%eax),%edx
f01033a6:	39 da                	cmp    %ebx,%edx
f01033a8:	74 07                	je     f01033b1 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01033aa:	83 c0 01             	add    $0x1,%eax
f01033ad:	39 c8                	cmp    %ecx,%eax
f01033af:	72 f2                	jb     f01033a3 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01033b1:	5b                   	pop    %ebx
f01033b2:	5d                   	pop    %ebp
f01033b3:	c3                   	ret    

f01033b4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01033b4:	55                   	push   %ebp
f01033b5:	89 e5                	mov    %esp,%ebp
f01033b7:	57                   	push   %edi
f01033b8:	56                   	push   %esi
f01033b9:	53                   	push   %ebx
f01033ba:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01033bd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033c0:	eb 03                	jmp    f01033c5 <strtol+0x11>
		s++;
f01033c2:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033c5:	0f b6 01             	movzbl (%ecx),%eax
f01033c8:	3c 20                	cmp    $0x20,%al
f01033ca:	74 f6                	je     f01033c2 <strtol+0xe>
f01033cc:	3c 09                	cmp    $0x9,%al
f01033ce:	74 f2                	je     f01033c2 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01033d0:	3c 2b                	cmp    $0x2b,%al
f01033d2:	75 0a                	jne    f01033de <strtol+0x2a>
		s++;
f01033d4:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01033d7:	bf 00 00 00 00       	mov    $0x0,%edi
f01033dc:	eb 11                	jmp    f01033ef <strtol+0x3b>
f01033de:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01033e3:	3c 2d                	cmp    $0x2d,%al
f01033e5:	75 08                	jne    f01033ef <strtol+0x3b>
		s++, neg = 1;
f01033e7:	83 c1 01             	add    $0x1,%ecx
f01033ea:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01033ef:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01033f5:	75 15                	jne    f010340c <strtol+0x58>
f01033f7:	80 39 30             	cmpb   $0x30,(%ecx)
f01033fa:	75 10                	jne    f010340c <strtol+0x58>
f01033fc:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103400:	75 7c                	jne    f010347e <strtol+0xca>
		s += 2, base = 16;
f0103402:	83 c1 02             	add    $0x2,%ecx
f0103405:	bb 10 00 00 00       	mov    $0x10,%ebx
f010340a:	eb 16                	jmp    f0103422 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010340c:	85 db                	test   %ebx,%ebx
f010340e:	75 12                	jne    f0103422 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103410:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103415:	80 39 30             	cmpb   $0x30,(%ecx)
f0103418:	75 08                	jne    f0103422 <strtol+0x6e>
		s++, base = 8;
f010341a:	83 c1 01             	add    $0x1,%ecx
f010341d:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103422:	b8 00 00 00 00       	mov    $0x0,%eax
f0103427:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010342a:	0f b6 11             	movzbl (%ecx),%edx
f010342d:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103430:	89 f3                	mov    %esi,%ebx
f0103432:	80 fb 09             	cmp    $0x9,%bl
f0103435:	77 08                	ja     f010343f <strtol+0x8b>
			dig = *s - '0';
f0103437:	0f be d2             	movsbl %dl,%edx
f010343a:	83 ea 30             	sub    $0x30,%edx
f010343d:	eb 22                	jmp    f0103461 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010343f:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103442:	89 f3                	mov    %esi,%ebx
f0103444:	80 fb 19             	cmp    $0x19,%bl
f0103447:	77 08                	ja     f0103451 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103449:	0f be d2             	movsbl %dl,%edx
f010344c:	83 ea 57             	sub    $0x57,%edx
f010344f:	eb 10                	jmp    f0103461 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103451:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103454:	89 f3                	mov    %esi,%ebx
f0103456:	80 fb 19             	cmp    $0x19,%bl
f0103459:	77 16                	ja     f0103471 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010345b:	0f be d2             	movsbl %dl,%edx
f010345e:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103461:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103464:	7d 0b                	jge    f0103471 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103466:	83 c1 01             	add    $0x1,%ecx
f0103469:	0f af 45 10          	imul   0x10(%ebp),%eax
f010346d:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010346f:	eb b9                	jmp    f010342a <strtol+0x76>

	if (endptr)
f0103471:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103475:	74 0d                	je     f0103484 <strtol+0xd0>
		*endptr = (char *) s;
f0103477:	8b 75 0c             	mov    0xc(%ebp),%esi
f010347a:	89 0e                	mov    %ecx,(%esi)
f010347c:	eb 06                	jmp    f0103484 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010347e:	85 db                	test   %ebx,%ebx
f0103480:	74 98                	je     f010341a <strtol+0x66>
f0103482:	eb 9e                	jmp    f0103422 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103484:	89 c2                	mov    %eax,%edx
f0103486:	f7 da                	neg    %edx
f0103488:	85 ff                	test   %edi,%edi
f010348a:	0f 45 c2             	cmovne %edx,%eax
}
f010348d:	5b                   	pop    %ebx
f010348e:	5e                   	pop    %esi
f010348f:	5f                   	pop    %edi
f0103490:	5d                   	pop    %ebp
f0103491:	c3                   	ret    
f0103492:	66 90                	xchg   %ax,%ax
f0103494:	66 90                	xchg   %ax,%ax
f0103496:	66 90                	xchg   %ax,%ax
f0103498:	66 90                	xchg   %ax,%ax
f010349a:	66 90                	xchg   %ax,%ax
f010349c:	66 90                	xchg   %ax,%ax
f010349e:	66 90                	xchg   %ax,%ax

f01034a0 <__udivdi3>:
f01034a0:	55                   	push   %ebp
f01034a1:	57                   	push   %edi
f01034a2:	56                   	push   %esi
f01034a3:	53                   	push   %ebx
f01034a4:	83 ec 1c             	sub    $0x1c,%esp
f01034a7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01034ab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01034af:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01034b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01034b7:	85 f6                	test   %esi,%esi
f01034b9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01034bd:	89 ca                	mov    %ecx,%edx
f01034bf:	89 f8                	mov    %edi,%eax
f01034c1:	75 3d                	jne    f0103500 <__udivdi3+0x60>
f01034c3:	39 cf                	cmp    %ecx,%edi
f01034c5:	0f 87 c5 00 00 00    	ja     f0103590 <__udivdi3+0xf0>
f01034cb:	85 ff                	test   %edi,%edi
f01034cd:	89 fd                	mov    %edi,%ebp
f01034cf:	75 0b                	jne    f01034dc <__udivdi3+0x3c>
f01034d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01034d6:	31 d2                	xor    %edx,%edx
f01034d8:	f7 f7                	div    %edi
f01034da:	89 c5                	mov    %eax,%ebp
f01034dc:	89 c8                	mov    %ecx,%eax
f01034de:	31 d2                	xor    %edx,%edx
f01034e0:	f7 f5                	div    %ebp
f01034e2:	89 c1                	mov    %eax,%ecx
f01034e4:	89 d8                	mov    %ebx,%eax
f01034e6:	89 cf                	mov    %ecx,%edi
f01034e8:	f7 f5                	div    %ebp
f01034ea:	89 c3                	mov    %eax,%ebx
f01034ec:	89 d8                	mov    %ebx,%eax
f01034ee:	89 fa                	mov    %edi,%edx
f01034f0:	83 c4 1c             	add    $0x1c,%esp
f01034f3:	5b                   	pop    %ebx
f01034f4:	5e                   	pop    %esi
f01034f5:	5f                   	pop    %edi
f01034f6:	5d                   	pop    %ebp
f01034f7:	c3                   	ret    
f01034f8:	90                   	nop
f01034f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103500:	39 ce                	cmp    %ecx,%esi
f0103502:	77 74                	ja     f0103578 <__udivdi3+0xd8>
f0103504:	0f bd fe             	bsr    %esi,%edi
f0103507:	83 f7 1f             	xor    $0x1f,%edi
f010350a:	0f 84 98 00 00 00    	je     f01035a8 <__udivdi3+0x108>
f0103510:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103515:	89 f9                	mov    %edi,%ecx
f0103517:	89 c5                	mov    %eax,%ebp
f0103519:	29 fb                	sub    %edi,%ebx
f010351b:	d3 e6                	shl    %cl,%esi
f010351d:	89 d9                	mov    %ebx,%ecx
f010351f:	d3 ed                	shr    %cl,%ebp
f0103521:	89 f9                	mov    %edi,%ecx
f0103523:	d3 e0                	shl    %cl,%eax
f0103525:	09 ee                	or     %ebp,%esi
f0103527:	89 d9                	mov    %ebx,%ecx
f0103529:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010352d:	89 d5                	mov    %edx,%ebp
f010352f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103533:	d3 ed                	shr    %cl,%ebp
f0103535:	89 f9                	mov    %edi,%ecx
f0103537:	d3 e2                	shl    %cl,%edx
f0103539:	89 d9                	mov    %ebx,%ecx
f010353b:	d3 e8                	shr    %cl,%eax
f010353d:	09 c2                	or     %eax,%edx
f010353f:	89 d0                	mov    %edx,%eax
f0103541:	89 ea                	mov    %ebp,%edx
f0103543:	f7 f6                	div    %esi
f0103545:	89 d5                	mov    %edx,%ebp
f0103547:	89 c3                	mov    %eax,%ebx
f0103549:	f7 64 24 0c          	mull   0xc(%esp)
f010354d:	39 d5                	cmp    %edx,%ebp
f010354f:	72 10                	jb     f0103561 <__udivdi3+0xc1>
f0103551:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103555:	89 f9                	mov    %edi,%ecx
f0103557:	d3 e6                	shl    %cl,%esi
f0103559:	39 c6                	cmp    %eax,%esi
f010355b:	73 07                	jae    f0103564 <__udivdi3+0xc4>
f010355d:	39 d5                	cmp    %edx,%ebp
f010355f:	75 03                	jne    f0103564 <__udivdi3+0xc4>
f0103561:	83 eb 01             	sub    $0x1,%ebx
f0103564:	31 ff                	xor    %edi,%edi
f0103566:	89 d8                	mov    %ebx,%eax
f0103568:	89 fa                	mov    %edi,%edx
f010356a:	83 c4 1c             	add    $0x1c,%esp
f010356d:	5b                   	pop    %ebx
f010356e:	5e                   	pop    %esi
f010356f:	5f                   	pop    %edi
f0103570:	5d                   	pop    %ebp
f0103571:	c3                   	ret    
f0103572:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103578:	31 ff                	xor    %edi,%edi
f010357a:	31 db                	xor    %ebx,%ebx
f010357c:	89 d8                	mov    %ebx,%eax
f010357e:	89 fa                	mov    %edi,%edx
f0103580:	83 c4 1c             	add    $0x1c,%esp
f0103583:	5b                   	pop    %ebx
f0103584:	5e                   	pop    %esi
f0103585:	5f                   	pop    %edi
f0103586:	5d                   	pop    %ebp
f0103587:	c3                   	ret    
f0103588:	90                   	nop
f0103589:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103590:	89 d8                	mov    %ebx,%eax
f0103592:	f7 f7                	div    %edi
f0103594:	31 ff                	xor    %edi,%edi
f0103596:	89 c3                	mov    %eax,%ebx
f0103598:	89 d8                	mov    %ebx,%eax
f010359a:	89 fa                	mov    %edi,%edx
f010359c:	83 c4 1c             	add    $0x1c,%esp
f010359f:	5b                   	pop    %ebx
f01035a0:	5e                   	pop    %esi
f01035a1:	5f                   	pop    %edi
f01035a2:	5d                   	pop    %ebp
f01035a3:	c3                   	ret    
f01035a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035a8:	39 ce                	cmp    %ecx,%esi
f01035aa:	72 0c                	jb     f01035b8 <__udivdi3+0x118>
f01035ac:	31 db                	xor    %ebx,%ebx
f01035ae:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01035b2:	0f 87 34 ff ff ff    	ja     f01034ec <__udivdi3+0x4c>
f01035b8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01035bd:	e9 2a ff ff ff       	jmp    f01034ec <__udivdi3+0x4c>
f01035c2:	66 90                	xchg   %ax,%ax
f01035c4:	66 90                	xchg   %ax,%ax
f01035c6:	66 90                	xchg   %ax,%ax
f01035c8:	66 90                	xchg   %ax,%ax
f01035ca:	66 90                	xchg   %ax,%ax
f01035cc:	66 90                	xchg   %ax,%ax
f01035ce:	66 90                	xchg   %ax,%ax

f01035d0 <__umoddi3>:
f01035d0:	55                   	push   %ebp
f01035d1:	57                   	push   %edi
f01035d2:	56                   	push   %esi
f01035d3:	53                   	push   %ebx
f01035d4:	83 ec 1c             	sub    $0x1c,%esp
f01035d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01035db:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01035df:	8b 74 24 34          	mov    0x34(%esp),%esi
f01035e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01035e7:	85 d2                	test   %edx,%edx
f01035e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01035ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035f1:	89 f3                	mov    %esi,%ebx
f01035f3:	89 3c 24             	mov    %edi,(%esp)
f01035f6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035fa:	75 1c                	jne    f0103618 <__umoddi3+0x48>
f01035fc:	39 f7                	cmp    %esi,%edi
f01035fe:	76 50                	jbe    f0103650 <__umoddi3+0x80>
f0103600:	89 c8                	mov    %ecx,%eax
f0103602:	89 f2                	mov    %esi,%edx
f0103604:	f7 f7                	div    %edi
f0103606:	89 d0                	mov    %edx,%eax
f0103608:	31 d2                	xor    %edx,%edx
f010360a:	83 c4 1c             	add    $0x1c,%esp
f010360d:	5b                   	pop    %ebx
f010360e:	5e                   	pop    %esi
f010360f:	5f                   	pop    %edi
f0103610:	5d                   	pop    %ebp
f0103611:	c3                   	ret    
f0103612:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103618:	39 f2                	cmp    %esi,%edx
f010361a:	89 d0                	mov    %edx,%eax
f010361c:	77 52                	ja     f0103670 <__umoddi3+0xa0>
f010361e:	0f bd ea             	bsr    %edx,%ebp
f0103621:	83 f5 1f             	xor    $0x1f,%ebp
f0103624:	75 5a                	jne    f0103680 <__umoddi3+0xb0>
f0103626:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010362a:	0f 82 e0 00 00 00    	jb     f0103710 <__umoddi3+0x140>
f0103630:	39 0c 24             	cmp    %ecx,(%esp)
f0103633:	0f 86 d7 00 00 00    	jbe    f0103710 <__umoddi3+0x140>
f0103639:	8b 44 24 08          	mov    0x8(%esp),%eax
f010363d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103641:	83 c4 1c             	add    $0x1c,%esp
f0103644:	5b                   	pop    %ebx
f0103645:	5e                   	pop    %esi
f0103646:	5f                   	pop    %edi
f0103647:	5d                   	pop    %ebp
f0103648:	c3                   	ret    
f0103649:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103650:	85 ff                	test   %edi,%edi
f0103652:	89 fd                	mov    %edi,%ebp
f0103654:	75 0b                	jne    f0103661 <__umoddi3+0x91>
f0103656:	b8 01 00 00 00       	mov    $0x1,%eax
f010365b:	31 d2                	xor    %edx,%edx
f010365d:	f7 f7                	div    %edi
f010365f:	89 c5                	mov    %eax,%ebp
f0103661:	89 f0                	mov    %esi,%eax
f0103663:	31 d2                	xor    %edx,%edx
f0103665:	f7 f5                	div    %ebp
f0103667:	89 c8                	mov    %ecx,%eax
f0103669:	f7 f5                	div    %ebp
f010366b:	89 d0                	mov    %edx,%eax
f010366d:	eb 99                	jmp    f0103608 <__umoddi3+0x38>
f010366f:	90                   	nop
f0103670:	89 c8                	mov    %ecx,%eax
f0103672:	89 f2                	mov    %esi,%edx
f0103674:	83 c4 1c             	add    $0x1c,%esp
f0103677:	5b                   	pop    %ebx
f0103678:	5e                   	pop    %esi
f0103679:	5f                   	pop    %edi
f010367a:	5d                   	pop    %ebp
f010367b:	c3                   	ret    
f010367c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103680:	8b 34 24             	mov    (%esp),%esi
f0103683:	bf 20 00 00 00       	mov    $0x20,%edi
f0103688:	89 e9                	mov    %ebp,%ecx
f010368a:	29 ef                	sub    %ebp,%edi
f010368c:	d3 e0                	shl    %cl,%eax
f010368e:	89 f9                	mov    %edi,%ecx
f0103690:	89 f2                	mov    %esi,%edx
f0103692:	d3 ea                	shr    %cl,%edx
f0103694:	89 e9                	mov    %ebp,%ecx
f0103696:	09 c2                	or     %eax,%edx
f0103698:	89 d8                	mov    %ebx,%eax
f010369a:	89 14 24             	mov    %edx,(%esp)
f010369d:	89 f2                	mov    %esi,%edx
f010369f:	d3 e2                	shl    %cl,%edx
f01036a1:	89 f9                	mov    %edi,%ecx
f01036a3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01036a7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01036ab:	d3 e8                	shr    %cl,%eax
f01036ad:	89 e9                	mov    %ebp,%ecx
f01036af:	89 c6                	mov    %eax,%esi
f01036b1:	d3 e3                	shl    %cl,%ebx
f01036b3:	89 f9                	mov    %edi,%ecx
f01036b5:	89 d0                	mov    %edx,%eax
f01036b7:	d3 e8                	shr    %cl,%eax
f01036b9:	89 e9                	mov    %ebp,%ecx
f01036bb:	09 d8                	or     %ebx,%eax
f01036bd:	89 d3                	mov    %edx,%ebx
f01036bf:	89 f2                	mov    %esi,%edx
f01036c1:	f7 34 24             	divl   (%esp)
f01036c4:	89 d6                	mov    %edx,%esi
f01036c6:	d3 e3                	shl    %cl,%ebx
f01036c8:	f7 64 24 04          	mull   0x4(%esp)
f01036cc:	39 d6                	cmp    %edx,%esi
f01036ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01036d2:	89 d1                	mov    %edx,%ecx
f01036d4:	89 c3                	mov    %eax,%ebx
f01036d6:	72 08                	jb     f01036e0 <__umoddi3+0x110>
f01036d8:	75 11                	jne    f01036eb <__umoddi3+0x11b>
f01036da:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01036de:	73 0b                	jae    f01036eb <__umoddi3+0x11b>
f01036e0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01036e4:	1b 14 24             	sbb    (%esp),%edx
f01036e7:	89 d1                	mov    %edx,%ecx
f01036e9:	89 c3                	mov    %eax,%ebx
f01036eb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01036ef:	29 da                	sub    %ebx,%edx
f01036f1:	19 ce                	sbb    %ecx,%esi
f01036f3:	89 f9                	mov    %edi,%ecx
f01036f5:	89 f0                	mov    %esi,%eax
f01036f7:	d3 e0                	shl    %cl,%eax
f01036f9:	89 e9                	mov    %ebp,%ecx
f01036fb:	d3 ea                	shr    %cl,%edx
f01036fd:	89 e9                	mov    %ebp,%ecx
f01036ff:	d3 ee                	shr    %cl,%esi
f0103701:	09 d0                	or     %edx,%eax
f0103703:	89 f2                	mov    %esi,%edx
f0103705:	83 c4 1c             	add    $0x1c,%esp
f0103708:	5b                   	pop    %ebx
f0103709:	5e                   	pop    %esi
f010370a:	5f                   	pop    %edi
f010370b:	5d                   	pop    %ebp
f010370c:	c3                   	ret    
f010370d:	8d 76 00             	lea    0x0(%esi),%esi
f0103710:	29 f9                	sub    %edi,%ecx
f0103712:	19 d6                	sbb    %edx,%esi
f0103714:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103718:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010371c:	e9 18 ff ff ff       	jmp    f0103639 <__umoddi3+0x69>
