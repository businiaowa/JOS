
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
f0100058:	e8 13 32 00 00       	call   f0103270 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 20 37 10 f0       	push   $0xf0103720
f010006f:	e8 13 27 00 00       	call   f0102787 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 08 10 00 00       	call   f0101081 <mem_init>
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
f01000b0:	68 3b 37 10 f0       	push   $0xf010373b
f01000b5:	e8 cd 26 00 00       	call   f0102787 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 9d 26 00 00       	call   f0102761 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 48 3f 10 f0 	movl   $0xf0103f48,(%esp)
f01000cb:	e8 b7 26 00 00       	call   f0102787 <cprintf>
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
f01000f2:	68 53 37 10 f0       	push   $0xf0103753
f01000f7:	e8 8b 26 00 00       	call   f0102787 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 59 26 00 00       	call   f0102761 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 48 3f 10 f0 	movl   $0xf0103f48,(%esp)
f010010f:	e8 73 26 00 00       	call   f0102787 <cprintf>
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
f01001c6:	0f b6 82 c0 38 10 f0 	movzbl -0xfefc740(%edx),%eax
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
f0100202:	0f b6 82 c0 38 10 f0 	movzbl -0xfefc740(%edx),%eax
f0100209:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f010020f:	0f b6 8a c0 37 10 f0 	movzbl -0xfefc840(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d a0 37 10 f0 	mov    -0xfefc860(,%ecx,4),%ecx
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
f0100260:	68 6d 37 10 f0       	push   $0xf010376d
f0100265:	e8 1d 25 00 00       	call   f0102787 <cprintf>
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
f010040e:	e8 aa 2e 00 00       	call   f01032bd <memmove>
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
f01005dd:	68 79 37 10 f0       	push   $0xf0103779
f01005e2:	e8 a0 21 00 00       	call   f0102787 <cprintf>
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
f0100623:	68 c0 39 10 f0       	push   $0xf01039c0
f0100628:	68 de 39 10 f0       	push   $0xf01039de
f010062d:	68 e3 39 10 f0       	push   $0xf01039e3
f0100632:	e8 50 21 00 00       	call   f0102787 <cprintf>
f0100637:	83 c4 0c             	add    $0xc,%esp
f010063a:	68 80 3a 10 f0       	push   $0xf0103a80
f010063f:	68 ec 39 10 f0       	push   $0xf01039ec
f0100644:	68 e3 39 10 f0       	push   $0xf01039e3
f0100649:	e8 39 21 00 00       	call   f0102787 <cprintf>
f010064e:	83 c4 0c             	add    $0xc,%esp
f0100651:	68 a8 3a 10 f0       	push   $0xf0103aa8
f0100656:	68 f5 39 10 f0       	push   $0xf01039f5
f010065b:	68 e3 39 10 f0       	push   $0xf01039e3
f0100660:	e8 22 21 00 00       	call   f0102787 <cprintf>
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
f0100672:	68 ff 39 10 f0       	push   $0xf01039ff
f0100677:	e8 0b 21 00 00       	call   f0102787 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010067c:	83 c4 08             	add    $0x8,%esp
f010067f:	68 0c 00 10 00       	push   $0x10000c
f0100684:	68 cc 3a 10 f0       	push   $0xf0103acc
f0100689:	e8 f9 20 00 00       	call   f0102787 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068e:	83 c4 0c             	add    $0xc,%esp
f0100691:	68 0c 00 10 00       	push   $0x10000c
f0100696:	68 0c 00 10 f0       	push   $0xf010000c
f010069b:	68 f4 3a 10 f0       	push   $0xf0103af4
f01006a0:	e8 e2 20 00 00       	call   f0102787 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a5:	83 c4 0c             	add    $0xc,%esp
f01006a8:	68 01 37 10 00       	push   $0x103701
f01006ad:	68 01 37 10 f0       	push   $0xf0103701
f01006b2:	68 18 3b 10 f0       	push   $0xf0103b18
f01006b7:	e8 cb 20 00 00       	call   f0102787 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006bc:	83 c4 0c             	add    $0xc,%esp
f01006bf:	68 00 73 11 00       	push   $0x117300
f01006c4:	68 00 73 11 f0       	push   $0xf0117300
f01006c9:	68 3c 3b 10 f0       	push   $0xf0103b3c
f01006ce:	e8 b4 20 00 00       	call   f0102787 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d3:	83 c4 0c             	add    $0xc,%esp
f01006d6:	68 70 79 11 00       	push   $0x117970
f01006db:	68 70 79 11 f0       	push   $0xf0117970
f01006e0:	68 60 3b 10 f0       	push   $0xf0103b60
f01006e5:	e8 9d 20 00 00       	call   f0102787 <cprintf>
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
f010070b:	68 84 3b 10 f0       	push   $0xf0103b84
f0100710:	e8 72 20 00 00       	call   f0102787 <cprintf>
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
f0100728:	68 b0 3b 10 f0       	push   $0xf0103bb0
f010072d:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f0100733:	50                   	push   %eax
f0100734:	e8 f2 29 00 00       	call   f010312b <strcpy>
    strcpy(details, "       %s:%d: %.*s+%d\n");
f0100739:	83 c4 08             	add    $0x8,%esp
f010073c:	68 18 3a 10 f0       	push   $0xf0103a18
f0100741:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
f0100747:	50                   	push   %eax
f0100748:	e8 de 29 00 00       	call   f010312b <strcpy>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010074d:	89 eb                	mov    %ebp,%ebx
    
    uint32_t *ebpAddr = (uint32_t *) read_ebp();
    struct Eipdebuginfo info;
    
    cprintf("Stack backtrace:\n");
f010074f:	c7 04 24 2f 3a 10 f0 	movl   $0xf0103a2f,(%esp)
f0100756:	e8 2c 20 00 00       	call   f0102787 <cprintf>
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
f0100773:	e8 19 21 00 00       	call   f0102891 <debuginfo_eip>

        cprintf(format, EBP(ebpAddr), EIP(ebpAddr), ARG(ebpAddr, 0), ARG(ebpAddr, 1), ARG(ebpAddr, 2), ARG(ebpAddr, 3), ARG(ebpAddr, 4));
f0100778:	ff 73 18             	pushl  0x18(%ebx)
f010077b:	ff 73 14             	pushl  0x14(%ebx)
f010077e:	ff 73 10             	pushl  0x10(%ebx)
f0100781:	ff 73 0c             	pushl  0xc(%ebx)
f0100784:	ff 73 08             	pushl  0x8(%ebx)
f0100787:	ff 73 04             	pushl  0x4(%ebx)
f010078a:	53                   	push   %ebx
f010078b:	56                   	push   %esi
f010078c:	e8 f6 1f 00 00       	call   f0102787 <cprintf>
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
f01007bd:	e8 c5 1f 00 00       	call   f0102787 <cprintf>
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
f01007e1:	68 e8 3b 10 f0       	push   $0xf0103be8
f01007e6:	e8 9c 1f 00 00       	call   f0102787 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007eb:	c7 04 24 0c 3c 10 f0 	movl   $0xf0103c0c,(%esp)
f01007f2:	e8 90 1f 00 00       	call   f0102787 <cprintf>
f01007f7:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007fa:	83 ec 0c             	sub    $0xc,%esp
f01007fd:	68 41 3a 10 f0       	push   $0xf0103a41
f0100802:	e8 12 28 00 00       	call   f0103019 <readline>
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
f0100836:	68 45 3a 10 f0       	push   $0xf0103a45
f010083b:	e8 f3 29 00 00       	call   f0103233 <strchr>
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
f0100856:	68 4a 3a 10 f0       	push   $0xf0103a4a
f010085b:	e8 27 1f 00 00       	call   f0102787 <cprintf>
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
f010087f:	68 45 3a 10 f0       	push   $0xf0103a45
f0100884:	e8 aa 29 00 00       	call   f0103233 <strchr>
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
f01008ad:	ff 34 85 40 3c 10 f0 	pushl  -0xfefc3c0(,%eax,4)
f01008b4:	ff 75 a8             	pushl  -0x58(%ebp)
f01008b7:	e8 19 29 00 00       	call   f01031d5 <strcmp>
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
f01008d1:	ff 14 85 48 3c 10 f0 	call   *-0xfefc3b8(,%eax,4)


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
f01008f2:	68 67 3a 10 f0       	push   $0xf0103a67
f01008f7:	e8 8b 1e 00 00       	call   f0102787 <cprintf>
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
f0100943:	68 64 3c 10 f0       	push   $0xf0103c64
f0100948:	6a 6a                	push   $0x6a
f010094a:	68 73 3c 10 f0       	push   $0xf0103c73
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
f010098e:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0100993:	68 df 02 00 00       	push   $0x2df
f0100998:	68 73 3c 10 f0       	push   $0xf0103c73
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
f01009e6:	68 a0 3f 10 f0       	push   $0xf0103fa0
f01009eb:	68 22 02 00 00       	push   $0x222
f01009f0:	68 73 3c 10 f0       	push   $0xf0103c73
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
f0100a75:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0100a7a:	6a 52                	push   $0x52
f0100a7c:	68 7f 3c 10 f0       	push   $0xf0103c7f
f0100a81:	e8 05 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a86:	83 ec 04             	sub    $0x4,%esp
f0100a89:	68 80 00 00 00       	push   $0x80
f0100a8e:	68 97 00 00 00       	push   $0x97
f0100a93:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a98:	50                   	push   %eax
f0100a99:	e8 d2 27 00 00       	call   f0103270 <memset>
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
f0100adf:	68 8d 3c 10 f0       	push   $0xf0103c8d
f0100ae4:	68 99 3c 10 f0       	push   $0xf0103c99
f0100ae9:	68 3c 02 00 00       	push   $0x23c
f0100aee:	68 73 3c 10 f0       	push   $0xf0103c73
f0100af3:	e8 93 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100af8:	39 fa                	cmp    %edi,%edx
f0100afa:	72 19                	jb     f0100b15 <check_page_free_list+0x148>
f0100afc:	68 ae 3c 10 f0       	push   $0xf0103cae
f0100b01:	68 99 3c 10 f0       	push   $0xf0103c99
f0100b06:	68 3d 02 00 00       	push   $0x23d
f0100b0b:	68 73 3c 10 f0       	push   $0xf0103c73
f0100b10:	e8 76 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b15:	89 d0                	mov    %edx,%eax
f0100b17:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b1a:	a8 07                	test   $0x7,%al
f0100b1c:	74 19                	je     f0100b37 <check_page_free_list+0x16a>
f0100b1e:	68 c4 3f 10 f0       	push   $0xf0103fc4
f0100b23:	68 99 3c 10 f0       	push   $0xf0103c99
f0100b28:	68 3e 02 00 00       	push   $0x23e
f0100b2d:	68 73 3c 10 f0       	push   $0xf0103c73
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
f0100b41:	68 c2 3c 10 f0       	push   $0xf0103cc2
f0100b46:	68 99 3c 10 f0       	push   $0xf0103c99
f0100b4b:	68 41 02 00 00       	push   $0x241
f0100b50:	68 73 3c 10 f0       	push   $0xf0103c73
f0100b55:	e8 31 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b5a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b5f:	75 19                	jne    f0100b7a <check_page_free_list+0x1ad>
f0100b61:	68 d3 3c 10 f0       	push   $0xf0103cd3
f0100b66:	68 99 3c 10 f0       	push   $0xf0103c99
f0100b6b:	68 42 02 00 00       	push   $0x242
f0100b70:	68 73 3c 10 f0       	push   $0xf0103c73
f0100b75:	e8 11 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b7a:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b7f:	75 19                	jne    f0100b9a <check_page_free_list+0x1cd>
f0100b81:	68 f8 3f 10 f0       	push   $0xf0103ff8
f0100b86:	68 99 3c 10 f0       	push   $0xf0103c99
f0100b8b:	68 43 02 00 00       	push   $0x243
f0100b90:	68 73 3c 10 f0       	push   $0xf0103c73
f0100b95:	e8 f1 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b9a:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b9f:	75 19                	jne    f0100bba <check_page_free_list+0x1ed>
f0100ba1:	68 ec 3c 10 f0       	push   $0xf0103cec
f0100ba6:	68 99 3c 10 f0       	push   $0xf0103c99
f0100bab:	68 44 02 00 00       	push   $0x244
f0100bb0:	68 73 3c 10 f0       	push   $0xf0103c73
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
f0100bcc:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0100bd1:	6a 52                	push   $0x52
f0100bd3:	68 7f 3c 10 f0       	push   $0xf0103c7f
f0100bd8:	e8 ae f4 ff ff       	call   f010008b <_panic>
f0100bdd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100be2:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100be5:	76 1e                	jbe    f0100c05 <check_page_free_list+0x238>
f0100be7:	68 1c 40 10 f0       	push   $0xf010401c
f0100bec:	68 99 3c 10 f0       	push   $0xf0103c99
f0100bf1:	68 45 02 00 00       	push   $0x245
f0100bf6:	68 73 3c 10 f0       	push   $0xf0103c73
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
f0100c1a:	68 06 3d 10 f0       	push   $0xf0103d06
f0100c1f:	68 99 3c 10 f0       	push   $0xf0103c99
f0100c24:	68 4d 02 00 00       	push   $0x24d
f0100c29:	68 73 3c 10 f0       	push   $0xf0103c73
f0100c2e:	e8 58 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c33:	85 db                	test   %ebx,%ebx
f0100c35:	7f 42                	jg     f0100c79 <check_page_free_list+0x2ac>
f0100c37:	68 18 3d 10 f0       	push   $0xf0103d18
f0100c3c:	68 99 3c 10 f0       	push   $0xf0103c99
f0100c41:	68 4e 02 00 00       	push   $0x24e
f0100c46:	68 73 3c 10 f0       	push   $0xf0103c73
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
f0100ce8:	68 64 40 10 f0       	push   $0xf0104064
f0100ced:	68 14 01 00 00       	push   $0x114
f0100cf2:	68 73 3c 10 f0       	push   $0xf0103c73
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
	if (page_free_list == NULL) {
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
f0100d98:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0100d9d:	6a 52                	push   $0x52
f0100d9f:	68 7f 3c 10 f0       	push   $0xf0103c7f
f0100da4:	e8 e2 f2 ff ff       	call   f010008b <_panic>
        memset(page2kva(page), '\0', PGSIZE); 
f0100da9:	83 ec 04             	sub    $0x4,%esp
f0100dac:	68 00 10 00 00       	push   $0x1000
f0100db1:	6a 00                	push   $0x0
f0100db3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100db8:	50                   	push   %eax
f0100db9:	e8 b2 24 00 00       	call   f0103270 <memset>
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
f0100dd8:	68 29 3d 10 f0       	push   $0xf0103d29
f0100ddd:	68 99 3c 10 f0       	push   $0xf0103c99
f0100de2:	68 48 01 00 00       	push   $0x148
f0100de7:	68 73 3c 10 f0       	push   $0xf0103c73
f0100dec:	e8 9a f2 ff ff       	call   f010008b <_panic>
	assert(pp->pp_link == NULL);
f0100df1:	83 38 00             	cmpl   $0x0,(%eax)
f0100df4:	74 19                	je     f0100e0f <page_free+0x47>
f0100df6:	68 39 3d 10 f0       	push   $0xf0103d39
f0100dfb:	68 99 3c 10 f0       	push   $0xf0103c99
f0100e00:	68 49 01 00 00       	push   $0x149
f0100e05:	68 73 3c 10 f0       	push   $0xf0103c73
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
f0100e48:	56                   	push   %esi
f0100e49:	53                   	push   %ebx
f0100e4a:	8b 75 0c             	mov    0xc(%ebp),%esi
	pde_t *pde_pointer = &pgdir[PDX(va)];
f0100e4d:	89 f3                	mov    %esi,%ebx
f0100e4f:	c1 eb 16             	shr    $0x16,%ebx
f0100e52:	c1 e3 02             	shl    $0x2,%ebx
f0100e55:	03 5d 08             	add    0x8(%ebp),%ebx
	if(*pde_pointer & PTE_P) {
f0100e58:	8b 03                	mov    (%ebx),%eax
f0100e5a:	a8 01                	test   $0x1,%al
f0100e5c:	74 39                	je     f0100e97 <pgdir_walk+0x52>
		pte_t *page_table =  KADDR(PTE_ADDR(*pde_pointer));
f0100e5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e63:	89 c2                	mov    %eax,%edx
f0100e65:	c1 ea 0c             	shr    $0xc,%edx
f0100e68:	39 15 64 79 11 f0    	cmp    %edx,0xf0117964
f0100e6e:	77 15                	ja     f0100e85 <pgdir_walk+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e70:	50                   	push   %eax
f0100e71:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0100e76:	68 75 01 00 00       	push   $0x175
f0100e7b:	68 73 3c 10 f0       	push   $0xf0103c73
f0100e80:	e8 06 f2 ff ff       	call   f010008b <_panic>
		return &page_table[PTX(va)];
f0100e85:	c1 ee 0a             	shr    $0xa,%esi
f0100e88:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100e8e:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100e95:	eb 72                	jmp    f0100f09 <pgdir_walk+0xc4>
	}

	if(create) {
f0100e97:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e9b:	74 60                	je     f0100efd <pgdir_walk+0xb8>
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0100e9d:	83 ec 0c             	sub    $0xc,%esp
f0100ea0:	6a 01                	push   $0x1
f0100ea2:	e8 ab fe ff ff       	call   f0100d52 <page_alloc>
		if(page != NULL) {
f0100ea7:	83 c4 10             	add    $0x10,%esp
f0100eaa:	85 c0                	test   %eax,%eax
f0100eac:	74 56                	je     f0100f04 <pgdir_walk+0xbf>
			page->pp_link = NULL;
f0100eae:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			page->pp_ref++;
f0100eb4:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100eb9:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100ebf:	c1 f8 03             	sar    $0x3,%eax
f0100ec2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ec5:	89 c2                	mov    %eax,%edx
f0100ec7:	c1 ea 0c             	shr    $0xc,%edx
f0100eca:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100ed0:	72 12                	jb     f0100ee4 <pgdir_walk+0x9f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ed2:	50                   	push   %eax
f0100ed3:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0100ed8:	6a 52                	push   $0x52
f0100eda:	68 7f 3c 10 f0       	push   $0xf0103c7f
f0100edf:	e8 a7 f1 ff ff       	call   f010008b <_panic>

			pte_t *page_table = (pte_t *)page2kva(page);
			*pde_pointer = page2pa(page) | PTE_P | PTE_W | PTE_U;
f0100ee4:	89 c2                	mov    %eax,%edx
f0100ee6:	83 ca 07             	or     $0x7,%edx
f0100ee9:	89 13                	mov    %edx,(%ebx)
			return &page_table[PTX(va)];
f0100eeb:	c1 ee 0a             	shr    $0xa,%esi
f0100eee:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100ef4:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100efb:	eb 0c                	jmp    f0100f09 <pgdir_walk+0xc4>
		}
	}

	return NULL;
f0100efd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f02:	eb 05                	jmp    f0100f09 <pgdir_walk+0xc4>
f0100f04:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100f09:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f0c:	5b                   	pop    %ebx
f0100f0d:	5e                   	pop    %esi
f0100f0e:	5d                   	pop    %ebp
f0100f0f:	c3                   	ret    

f0100f10 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f10:	55                   	push   %ebp
f0100f11:	89 e5                	mov    %esp,%ebp
f0100f13:	57                   	push   %edi
f0100f14:	56                   	push   %esi
f0100f15:	53                   	push   %ebx
f0100f16:	83 ec 1c             	sub    $0x1c,%esp
f0100f19:	89 45 e0             	mov    %eax,-0x20(%ebp)
	// Fill this function in
	size = ROUNDUP(size, PGSIZE);
f0100f1c:	8d b9 ff 0f 00 00    	lea    0xfff(%ecx),%edi
f0100f22:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	for(; size > 0; size-=PGSIZE) {
f0100f28:	89 d6                	mov    %edx,%esi
f0100f2a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f2d:	29 d0                	sub    %edx,%eax
f0100f2f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		pte_t* pte_pointer = pgdir_walk(pgdir, (void *)va, 1);
		*pte_pointer = PTE_ADDR(pa) | perm | PTE_P;
f0100f32:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f35:	83 c8 01             	or     $0x1,%eax
f0100f38:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size = ROUNDUP(size, PGSIZE);
	for(; size > 0; size-=PGSIZE) {
f0100f3b:	eb 28                	jmp    f0100f65 <boot_map_region+0x55>
		pte_t* pte_pointer = pgdir_walk(pgdir, (void *)va, 1);
f0100f3d:	83 ec 04             	sub    $0x4,%esp
f0100f40:	6a 01                	push   $0x1
f0100f42:	56                   	push   %esi
f0100f43:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f46:	e8 fa fe ff ff       	call   f0100e45 <pgdir_walk>
		*pte_pointer = PTE_ADDR(pa) | perm | PTE_P;
f0100f4b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0100f51:	0b 5d dc             	or     -0x24(%ebp),%ebx
f0100f54:	89 18                	mov    %ebx,(%eax)
		va += PGSIZE;
f0100f56:	81 c6 00 10 00 00    	add    $0x1000,%esi
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size = ROUNDUP(size, PGSIZE);
	for(; size > 0; size-=PGSIZE) {
f0100f5c:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f0100f62:	83 c4 10             	add    $0x10,%esp
f0100f65:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f68:	8d 1c 30             	lea    (%eax,%esi,1),%ebx
f0100f6b:	85 ff                	test   %edi,%edi
f0100f6d:	75 ce                	jne    f0100f3d <boot_map_region+0x2d>
		pte_t* pte_pointer = pgdir_walk(pgdir, (void *)va, 1);
		*pte_pointer = PTE_ADDR(pa) | perm | PTE_P;
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f0100f6f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f72:	5b                   	pop    %ebx
f0100f73:	5e                   	pop    %esi
f0100f74:	5f                   	pop    %edi
f0100f75:	5d                   	pop    %ebp
f0100f76:	c3                   	ret    

f0100f77 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f77:	55                   	push   %ebp
f0100f78:	89 e5                	mov    %esp,%ebp
f0100f7a:	53                   	push   %ebx
f0100f7b:	83 ec 08             	sub    $0x8,%esp
f0100f7e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte_pointer = pgdir_walk(pgdir, va, 0);
f0100f81:	6a 00                	push   $0x0
f0100f83:	ff 75 0c             	pushl  0xc(%ebp)
f0100f86:	ff 75 08             	pushl  0x8(%ebp)
f0100f89:	e8 b7 fe ff ff       	call   f0100e45 <pgdir_walk>
    if (pte_pointer == NULL || *pte_pointer == 0) {
f0100f8e:	83 c4 10             	add    $0x10,%esp
f0100f91:	85 c0                	test   %eax,%eax
f0100f93:	74 37                	je     f0100fcc <page_lookup+0x55>
f0100f95:	83 38 00             	cmpl   $0x0,(%eax)
f0100f98:	74 39                	je     f0100fd3 <page_lookup+0x5c>
        return NULL;
    }

    if (pte_store != NULL) {
f0100f9a:	85 db                	test   %ebx,%ebx
f0100f9c:	74 02                	je     f0100fa0 <page_lookup+0x29>
        *pte_store = pte_pointer;
f0100f9e:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fa0:	8b 00                	mov    (%eax),%eax
f0100fa2:	c1 e8 0c             	shr    $0xc,%eax
f0100fa5:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100fab:	72 14                	jb     f0100fc1 <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0100fad:	83 ec 04             	sub    $0x4,%esp
f0100fb0:	68 88 40 10 f0       	push   $0xf0104088
f0100fb5:	6a 4b                	push   $0x4b
f0100fb7:	68 7f 3c 10 f0       	push   $0xf0103c7f
f0100fbc:	e8 ca f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100fc1:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0100fc7:	8d 04 c2             	lea    (%edx,%eax,8),%eax
    }

	return pa2page((physaddr_t) PTE_ADDR(*pte_pointer));
f0100fca:	eb 0c                	jmp    f0100fd8 <page_lookup+0x61>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte_pointer = pgdir_walk(pgdir, va, 0);
    if (pte_pointer == NULL || *pte_pointer == 0) {
        return NULL;
f0100fcc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fd1:	eb 05                	jmp    f0100fd8 <page_lookup+0x61>
f0100fd3:	b8 00 00 00 00       	mov    $0x0,%eax
    if (pte_store != NULL) {
        *pte_store = pte_pointer;
    }

	return pa2page((physaddr_t) PTE_ADDR(*pte_pointer));
}
f0100fd8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fdb:	c9                   	leave  
f0100fdc:	c3                   	ret    

f0100fdd <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100fdd:	55                   	push   %ebp
f0100fde:	89 e5                	mov    %esp,%ebp
f0100fe0:	53                   	push   %ebx
f0100fe1:	83 ec 18             	sub    $0x18,%esp
f0100fe4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte_pointer;
    struct PageInfo *page = page_lookup(pgdir, va, &pte_pointer);
f0100fe7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fea:	50                   	push   %eax
f0100feb:	53                   	push   %ebx
f0100fec:	ff 75 08             	pushl  0x8(%ebp)
f0100fef:	e8 83 ff ff ff       	call   f0100f77 <page_lookup>
    if (page == NULL) {
f0100ff4:	83 c4 10             	add    $0x10,%esp
f0100ff7:	85 c0                	test   %eax,%eax
f0100ff9:	74 18                	je     f0101013 <page_remove+0x36>
        return;
    }

    *pte_pointer = 0;
f0100ffb:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100ffe:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
    page_decref(page); 
f0101004:	83 ec 0c             	sub    $0xc,%esp
f0101007:	50                   	push   %eax
f0101008:	e8 11 fe ff ff       	call   f0100e1e <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010100d:	0f 01 3b             	invlpg (%ebx)
f0101010:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir, va);
}
f0101013:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101016:	c9                   	leave  
f0101017:	c3                   	ret    

f0101018 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101018:	55                   	push   %ebp
f0101019:	89 e5                	mov    %esp,%ebp
f010101b:	57                   	push   %edi
f010101c:	56                   	push   %esi
f010101d:	53                   	push   %ebx
f010101e:	83 ec 10             	sub    $0x10,%esp
f0101021:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101024:	8b 75 10             	mov    0x10(%ebp),%esi
	// Fill this function in
	pte_t* pte_pointer = pgdir_walk(pgdir, va, 1);
f0101027:	6a 01                	push   $0x1
f0101029:	56                   	push   %esi
f010102a:	ff 75 08             	pushl  0x8(%ebp)
f010102d:	e8 13 fe ff ff       	call   f0100e45 <pgdir_walk>
	if(!pte_pointer) {
f0101032:	83 c4 10             	add    $0x10,%esp
f0101035:	85 c0                	test   %eax,%eax
f0101037:	74 3b                	je     f0101074 <page_insert+0x5c>
f0101039:	89 c7                	mov    %eax,%edi
		return -E_NO_MEM;
	}

	pp->pp_ref++;
f010103b:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if(*pte_pointer & PTE_P) {
f0101040:	f6 00 01             	testb  $0x1,(%eax)
f0101043:	74 12                	je     f0101057 <page_insert+0x3f>
		page_remove(pgdir, va);
f0101045:	83 ec 08             	sub    $0x8,%esp
f0101048:	56                   	push   %esi
f0101049:	ff 75 08             	pushl  0x8(%ebp)
f010104c:	e8 8c ff ff ff       	call   f0100fdd <page_remove>
f0101051:	0f 01 3e             	invlpg (%esi)
f0101054:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}

	*pte_pointer = PTE_ADDR(page2pa(pp)) | PTE_P | perm;
f0101057:	2b 1d 6c 79 11 f0    	sub    0xf011796c,%ebx
f010105d:	c1 fb 03             	sar    $0x3,%ebx
f0101060:	c1 e3 0c             	shl    $0xc,%ebx
f0101063:	8b 45 14             	mov    0x14(%ebp),%eax
f0101066:	83 c8 01             	or     $0x1,%eax
f0101069:	09 c3                	or     %eax,%ebx
f010106b:	89 1f                	mov    %ebx,(%edi)
	return 0;
f010106d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101072:	eb 05                	jmp    f0101079 <page_insert+0x61>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t* pte_pointer = pgdir_walk(pgdir, va, 1);
	if(!pte_pointer) {
		return -E_NO_MEM;
f0101074:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		tlb_invalidate(pgdir, va);
	}

	*pte_pointer = PTE_ADDR(page2pa(pp)) | PTE_P | perm;
	return 0;
}
f0101079:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010107c:	5b                   	pop    %ebx
f010107d:	5e                   	pop    %esi
f010107e:	5f                   	pop    %edi
f010107f:	5d                   	pop    %ebp
f0101080:	c3                   	ret    

f0101081 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101081:	55                   	push   %ebp
f0101082:	89 e5                	mov    %esp,%ebp
f0101084:	57                   	push   %edi
f0101085:	56                   	push   %esi
f0101086:	53                   	push   %ebx
f0101087:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010108a:	6a 15                	push   $0x15
f010108c:	e8 8f 16 00 00       	call   f0102720 <mc146818_read>
f0101091:	89 c3                	mov    %eax,%ebx
f0101093:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010109a:	e8 81 16 00 00       	call   f0102720 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010109f:	c1 e0 08             	shl    $0x8,%eax
f01010a2:	09 d8                	or     %ebx,%eax
f01010a4:	c1 e0 0a             	shl    $0xa,%eax
f01010a7:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010ad:	85 c0                	test   %eax,%eax
f01010af:	0f 48 c2             	cmovs  %edx,%eax
f01010b2:	c1 f8 0c             	sar    $0xc,%eax
f01010b5:	a3 40 75 11 f0       	mov    %eax,0xf0117540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010ba:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01010c1:	e8 5a 16 00 00       	call   f0102720 <mc146818_read>
f01010c6:	89 c3                	mov    %eax,%ebx
f01010c8:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01010cf:	e8 4c 16 00 00       	call   f0102720 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01010d4:	c1 e0 08             	shl    $0x8,%eax
f01010d7:	09 d8                	or     %ebx,%eax
f01010d9:	c1 e0 0a             	shl    $0xa,%eax
f01010dc:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010e2:	83 c4 10             	add    $0x10,%esp
f01010e5:	85 c0                	test   %eax,%eax
f01010e7:	0f 48 c2             	cmovs  %edx,%eax
f01010ea:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01010ed:	85 c0                	test   %eax,%eax
f01010ef:	74 0e                	je     f01010ff <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01010f1:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01010f7:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
f01010fd:	eb 0c                	jmp    f010110b <mem_init+0x8a>
	else
		npages = npages_basemem;
f01010ff:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f0101105:	89 15 64 79 11 f0    	mov    %edx,0xf0117964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010110b:	c1 e0 0c             	shl    $0xc,%eax
f010110e:	c1 e8 0a             	shr    $0xa,%eax
f0101111:	50                   	push   %eax
f0101112:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f0101117:	c1 e0 0c             	shl    $0xc,%eax
f010111a:	c1 e8 0a             	shr    $0xa,%eax
f010111d:	50                   	push   %eax
f010111e:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0101123:	c1 e0 0c             	shl    $0xc,%eax
f0101126:	c1 e8 0a             	shr    $0xa,%eax
f0101129:	50                   	push   %eax
f010112a:	68 a8 40 10 f0       	push   $0xf01040a8
f010112f:	e8 53 16 00 00       	call   f0102787 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101134:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101139:	e8 ce f7 ff ff       	call   f010090c <boot_alloc>
f010113e:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f0101143:	83 c4 0c             	add    $0xc,%esp
f0101146:	68 00 10 00 00       	push   $0x1000
f010114b:	6a 00                	push   $0x0
f010114d:	50                   	push   %eax
f010114e:	e8 1d 21 00 00       	call   f0103270 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101153:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101158:	83 c4 10             	add    $0x10,%esp
f010115b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101160:	77 15                	ja     f0101177 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101162:	50                   	push   %eax
f0101163:	68 64 40 10 f0       	push   $0xf0104064
f0101168:	68 94 00 00 00       	push   $0x94
f010116d:	68 73 3c 10 f0       	push   $0xf0103c73
f0101172:	e8 14 ef ff ff       	call   f010008b <_panic>
f0101177:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010117d:	83 ca 05             	or     $0x5,%edx
f0101180:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(npages * sizeof(struct PageInfo));
f0101186:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010118b:	c1 e0 03             	shl    $0x3,%eax
f010118e:	e8 79 f7 ff ff       	call   f010090c <boot_alloc>
f0101193:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101198:	83 ec 04             	sub    $0x4,%esp
f010119b:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f01011a1:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01011a8:	52                   	push   %edx
f01011a9:	6a 00                	push   $0x0
f01011ab:	50                   	push   %eax
f01011ac:	e8 bf 20 00 00       	call   f0103270 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01011b1:	e8 cb fa ff ff       	call   f0100c81 <page_init>

	check_page_free_list(1);
f01011b6:	b8 01 00 00 00       	mov    $0x1,%eax
f01011bb:	e8 0d f8 ff ff       	call   f01009cd <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011c0:	83 c4 10             	add    $0x10,%esp
f01011c3:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f01011ca:	75 17                	jne    f01011e3 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f01011cc:	83 ec 04             	sub    $0x4,%esp
f01011cf:	68 4d 3d 10 f0       	push   $0xf0103d4d
f01011d4:	68 5f 02 00 00       	push   $0x25f
f01011d9:	68 73 3c 10 f0       	push   $0xf0103c73
f01011de:	e8 a8 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011e3:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01011e8:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011ed:	eb 05                	jmp    f01011f4 <mem_init+0x173>
		++nfree;
f01011ef:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011f2:	8b 00                	mov    (%eax),%eax
f01011f4:	85 c0                	test   %eax,%eax
f01011f6:	75 f7                	jne    f01011ef <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011f8:	83 ec 0c             	sub    $0xc,%esp
f01011fb:	6a 00                	push   $0x0
f01011fd:	e8 50 fb ff ff       	call   f0100d52 <page_alloc>
f0101202:	89 c7                	mov    %eax,%edi
f0101204:	83 c4 10             	add    $0x10,%esp
f0101207:	85 c0                	test   %eax,%eax
f0101209:	75 19                	jne    f0101224 <mem_init+0x1a3>
f010120b:	68 68 3d 10 f0       	push   $0xf0103d68
f0101210:	68 99 3c 10 f0       	push   $0xf0103c99
f0101215:	68 67 02 00 00       	push   $0x267
f010121a:	68 73 3c 10 f0       	push   $0xf0103c73
f010121f:	e8 67 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101224:	83 ec 0c             	sub    $0xc,%esp
f0101227:	6a 00                	push   $0x0
f0101229:	e8 24 fb ff ff       	call   f0100d52 <page_alloc>
f010122e:	89 c6                	mov    %eax,%esi
f0101230:	83 c4 10             	add    $0x10,%esp
f0101233:	85 c0                	test   %eax,%eax
f0101235:	75 19                	jne    f0101250 <mem_init+0x1cf>
f0101237:	68 7e 3d 10 f0       	push   $0xf0103d7e
f010123c:	68 99 3c 10 f0       	push   $0xf0103c99
f0101241:	68 68 02 00 00       	push   $0x268
f0101246:	68 73 3c 10 f0       	push   $0xf0103c73
f010124b:	e8 3b ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101250:	83 ec 0c             	sub    $0xc,%esp
f0101253:	6a 00                	push   $0x0
f0101255:	e8 f8 fa ff ff       	call   f0100d52 <page_alloc>
f010125a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010125d:	83 c4 10             	add    $0x10,%esp
f0101260:	85 c0                	test   %eax,%eax
f0101262:	75 19                	jne    f010127d <mem_init+0x1fc>
f0101264:	68 94 3d 10 f0       	push   $0xf0103d94
f0101269:	68 99 3c 10 f0       	push   $0xf0103c99
f010126e:	68 69 02 00 00       	push   $0x269
f0101273:	68 73 3c 10 f0       	push   $0xf0103c73
f0101278:	e8 0e ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010127d:	39 f7                	cmp    %esi,%edi
f010127f:	75 19                	jne    f010129a <mem_init+0x219>
f0101281:	68 aa 3d 10 f0       	push   $0xf0103daa
f0101286:	68 99 3c 10 f0       	push   $0xf0103c99
f010128b:	68 6c 02 00 00       	push   $0x26c
f0101290:	68 73 3c 10 f0       	push   $0xf0103c73
f0101295:	e8 f1 ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010129a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010129d:	39 c6                	cmp    %eax,%esi
f010129f:	74 04                	je     f01012a5 <mem_init+0x224>
f01012a1:	39 c7                	cmp    %eax,%edi
f01012a3:	75 19                	jne    f01012be <mem_init+0x23d>
f01012a5:	68 e4 40 10 f0       	push   $0xf01040e4
f01012aa:	68 99 3c 10 f0       	push   $0xf0103c99
f01012af:	68 6d 02 00 00       	push   $0x26d
f01012b4:	68 73 3c 10 f0       	push   $0xf0103c73
f01012b9:	e8 cd ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012be:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012c4:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f01012ca:	c1 e2 0c             	shl    $0xc,%edx
f01012cd:	89 f8                	mov    %edi,%eax
f01012cf:	29 c8                	sub    %ecx,%eax
f01012d1:	c1 f8 03             	sar    $0x3,%eax
f01012d4:	c1 e0 0c             	shl    $0xc,%eax
f01012d7:	39 d0                	cmp    %edx,%eax
f01012d9:	72 19                	jb     f01012f4 <mem_init+0x273>
f01012db:	68 bc 3d 10 f0       	push   $0xf0103dbc
f01012e0:	68 99 3c 10 f0       	push   $0xf0103c99
f01012e5:	68 6e 02 00 00       	push   $0x26e
f01012ea:	68 73 3c 10 f0       	push   $0xf0103c73
f01012ef:	e8 97 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012f4:	89 f0                	mov    %esi,%eax
f01012f6:	29 c8                	sub    %ecx,%eax
f01012f8:	c1 f8 03             	sar    $0x3,%eax
f01012fb:	c1 e0 0c             	shl    $0xc,%eax
f01012fe:	39 c2                	cmp    %eax,%edx
f0101300:	77 19                	ja     f010131b <mem_init+0x29a>
f0101302:	68 d9 3d 10 f0       	push   $0xf0103dd9
f0101307:	68 99 3c 10 f0       	push   $0xf0103c99
f010130c:	68 6f 02 00 00       	push   $0x26f
f0101311:	68 73 3c 10 f0       	push   $0xf0103c73
f0101316:	e8 70 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010131b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010131e:	29 c8                	sub    %ecx,%eax
f0101320:	c1 f8 03             	sar    $0x3,%eax
f0101323:	c1 e0 0c             	shl    $0xc,%eax
f0101326:	39 c2                	cmp    %eax,%edx
f0101328:	77 19                	ja     f0101343 <mem_init+0x2c2>
f010132a:	68 f6 3d 10 f0       	push   $0xf0103df6
f010132f:	68 99 3c 10 f0       	push   $0xf0103c99
f0101334:	68 70 02 00 00       	push   $0x270
f0101339:	68 73 3c 10 f0       	push   $0xf0103c73
f010133e:	e8 48 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101343:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101348:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010134b:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101352:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101355:	83 ec 0c             	sub    $0xc,%esp
f0101358:	6a 00                	push   $0x0
f010135a:	e8 f3 f9 ff ff       	call   f0100d52 <page_alloc>
f010135f:	83 c4 10             	add    $0x10,%esp
f0101362:	85 c0                	test   %eax,%eax
f0101364:	74 19                	je     f010137f <mem_init+0x2fe>
f0101366:	68 13 3e 10 f0       	push   $0xf0103e13
f010136b:	68 99 3c 10 f0       	push   $0xf0103c99
f0101370:	68 77 02 00 00       	push   $0x277
f0101375:	68 73 3c 10 f0       	push   $0xf0103c73
f010137a:	e8 0c ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f010137f:	83 ec 0c             	sub    $0xc,%esp
f0101382:	57                   	push   %edi
f0101383:	e8 40 fa ff ff       	call   f0100dc8 <page_free>
	page_free(pp1);
f0101388:	89 34 24             	mov    %esi,(%esp)
f010138b:	e8 38 fa ff ff       	call   f0100dc8 <page_free>
	page_free(pp2);
f0101390:	83 c4 04             	add    $0x4,%esp
f0101393:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101396:	e8 2d fa ff ff       	call   f0100dc8 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010139b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013a2:	e8 ab f9 ff ff       	call   f0100d52 <page_alloc>
f01013a7:	89 c6                	mov    %eax,%esi
f01013a9:	83 c4 10             	add    $0x10,%esp
f01013ac:	85 c0                	test   %eax,%eax
f01013ae:	75 19                	jne    f01013c9 <mem_init+0x348>
f01013b0:	68 68 3d 10 f0       	push   $0xf0103d68
f01013b5:	68 99 3c 10 f0       	push   $0xf0103c99
f01013ba:	68 7e 02 00 00       	push   $0x27e
f01013bf:	68 73 3c 10 f0       	push   $0xf0103c73
f01013c4:	e8 c2 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013c9:	83 ec 0c             	sub    $0xc,%esp
f01013cc:	6a 00                	push   $0x0
f01013ce:	e8 7f f9 ff ff       	call   f0100d52 <page_alloc>
f01013d3:	89 c7                	mov    %eax,%edi
f01013d5:	83 c4 10             	add    $0x10,%esp
f01013d8:	85 c0                	test   %eax,%eax
f01013da:	75 19                	jne    f01013f5 <mem_init+0x374>
f01013dc:	68 7e 3d 10 f0       	push   $0xf0103d7e
f01013e1:	68 99 3c 10 f0       	push   $0xf0103c99
f01013e6:	68 7f 02 00 00       	push   $0x27f
f01013eb:	68 73 3c 10 f0       	push   $0xf0103c73
f01013f0:	e8 96 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013f5:	83 ec 0c             	sub    $0xc,%esp
f01013f8:	6a 00                	push   $0x0
f01013fa:	e8 53 f9 ff ff       	call   f0100d52 <page_alloc>
f01013ff:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101402:	83 c4 10             	add    $0x10,%esp
f0101405:	85 c0                	test   %eax,%eax
f0101407:	75 19                	jne    f0101422 <mem_init+0x3a1>
f0101409:	68 94 3d 10 f0       	push   $0xf0103d94
f010140e:	68 99 3c 10 f0       	push   $0xf0103c99
f0101413:	68 80 02 00 00       	push   $0x280
f0101418:	68 73 3c 10 f0       	push   $0xf0103c73
f010141d:	e8 69 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101422:	39 fe                	cmp    %edi,%esi
f0101424:	75 19                	jne    f010143f <mem_init+0x3be>
f0101426:	68 aa 3d 10 f0       	push   $0xf0103daa
f010142b:	68 99 3c 10 f0       	push   $0xf0103c99
f0101430:	68 82 02 00 00       	push   $0x282
f0101435:	68 73 3c 10 f0       	push   $0xf0103c73
f010143a:	e8 4c ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010143f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101442:	39 c7                	cmp    %eax,%edi
f0101444:	74 04                	je     f010144a <mem_init+0x3c9>
f0101446:	39 c6                	cmp    %eax,%esi
f0101448:	75 19                	jne    f0101463 <mem_init+0x3e2>
f010144a:	68 e4 40 10 f0       	push   $0xf01040e4
f010144f:	68 99 3c 10 f0       	push   $0xf0103c99
f0101454:	68 83 02 00 00       	push   $0x283
f0101459:	68 73 3c 10 f0       	push   $0xf0103c73
f010145e:	e8 28 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101463:	83 ec 0c             	sub    $0xc,%esp
f0101466:	6a 00                	push   $0x0
f0101468:	e8 e5 f8 ff ff       	call   f0100d52 <page_alloc>
f010146d:	83 c4 10             	add    $0x10,%esp
f0101470:	85 c0                	test   %eax,%eax
f0101472:	74 19                	je     f010148d <mem_init+0x40c>
f0101474:	68 13 3e 10 f0       	push   $0xf0103e13
f0101479:	68 99 3c 10 f0       	push   $0xf0103c99
f010147e:	68 84 02 00 00       	push   $0x284
f0101483:	68 73 3c 10 f0       	push   $0xf0103c73
f0101488:	e8 fe eb ff ff       	call   f010008b <_panic>
f010148d:	89 f0                	mov    %esi,%eax
f010148f:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101495:	c1 f8 03             	sar    $0x3,%eax
f0101498:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010149b:	89 c2                	mov    %eax,%edx
f010149d:	c1 ea 0c             	shr    $0xc,%edx
f01014a0:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01014a6:	72 12                	jb     f01014ba <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014a8:	50                   	push   %eax
f01014a9:	68 7c 3f 10 f0       	push   $0xf0103f7c
f01014ae:	6a 52                	push   $0x52
f01014b0:	68 7f 3c 10 f0       	push   $0xf0103c7f
f01014b5:	e8 d1 eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014ba:	83 ec 04             	sub    $0x4,%esp
f01014bd:	68 00 10 00 00       	push   $0x1000
f01014c2:	6a 01                	push   $0x1
f01014c4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014c9:	50                   	push   %eax
f01014ca:	e8 a1 1d 00 00       	call   f0103270 <memset>
	page_free(pp0);
f01014cf:	89 34 24             	mov    %esi,(%esp)
f01014d2:	e8 f1 f8 ff ff       	call   f0100dc8 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014d7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014de:	e8 6f f8 ff ff       	call   f0100d52 <page_alloc>
f01014e3:	83 c4 10             	add    $0x10,%esp
f01014e6:	85 c0                	test   %eax,%eax
f01014e8:	75 19                	jne    f0101503 <mem_init+0x482>
f01014ea:	68 22 3e 10 f0       	push   $0xf0103e22
f01014ef:	68 99 3c 10 f0       	push   $0xf0103c99
f01014f4:	68 89 02 00 00       	push   $0x289
f01014f9:	68 73 3c 10 f0       	push   $0xf0103c73
f01014fe:	e8 88 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101503:	39 c6                	cmp    %eax,%esi
f0101505:	74 19                	je     f0101520 <mem_init+0x49f>
f0101507:	68 40 3e 10 f0       	push   $0xf0103e40
f010150c:	68 99 3c 10 f0       	push   $0xf0103c99
f0101511:	68 8a 02 00 00       	push   $0x28a
f0101516:	68 73 3c 10 f0       	push   $0xf0103c73
f010151b:	e8 6b eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101520:	89 f0                	mov    %esi,%eax
f0101522:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101528:	c1 f8 03             	sar    $0x3,%eax
f010152b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010152e:	89 c2                	mov    %eax,%edx
f0101530:	c1 ea 0c             	shr    $0xc,%edx
f0101533:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101539:	72 12                	jb     f010154d <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010153b:	50                   	push   %eax
f010153c:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0101541:	6a 52                	push   $0x52
f0101543:	68 7f 3c 10 f0       	push   $0xf0103c7f
f0101548:	e8 3e eb ff ff       	call   f010008b <_panic>
f010154d:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101553:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101559:	80 38 00             	cmpb   $0x0,(%eax)
f010155c:	74 19                	je     f0101577 <mem_init+0x4f6>
f010155e:	68 50 3e 10 f0       	push   $0xf0103e50
f0101563:	68 99 3c 10 f0       	push   $0xf0103c99
f0101568:	68 8d 02 00 00       	push   $0x28d
f010156d:	68 73 3c 10 f0       	push   $0xf0103c73
f0101572:	e8 14 eb ff ff       	call   f010008b <_panic>
f0101577:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010157a:	39 d0                	cmp    %edx,%eax
f010157c:	75 db                	jne    f0101559 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010157e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101581:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101586:	83 ec 0c             	sub    $0xc,%esp
f0101589:	56                   	push   %esi
f010158a:	e8 39 f8 ff ff       	call   f0100dc8 <page_free>
	page_free(pp1);
f010158f:	89 3c 24             	mov    %edi,(%esp)
f0101592:	e8 31 f8 ff ff       	call   f0100dc8 <page_free>
	page_free(pp2);
f0101597:	83 c4 04             	add    $0x4,%esp
f010159a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010159d:	e8 26 f8 ff ff       	call   f0100dc8 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015a2:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01015a7:	83 c4 10             	add    $0x10,%esp
f01015aa:	eb 05                	jmp    f01015b1 <mem_init+0x530>
		--nfree;
f01015ac:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015af:	8b 00                	mov    (%eax),%eax
f01015b1:	85 c0                	test   %eax,%eax
f01015b3:	75 f7                	jne    f01015ac <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f01015b5:	85 db                	test   %ebx,%ebx
f01015b7:	74 19                	je     f01015d2 <mem_init+0x551>
f01015b9:	68 5a 3e 10 f0       	push   $0xf0103e5a
f01015be:	68 99 3c 10 f0       	push   $0xf0103c99
f01015c3:	68 9a 02 00 00       	push   $0x29a
f01015c8:	68 73 3c 10 f0       	push   $0xf0103c73
f01015cd:	e8 b9 ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015d2:	83 ec 0c             	sub    $0xc,%esp
f01015d5:	68 04 41 10 f0       	push   $0xf0104104
f01015da:	e8 a8 11 00 00       	call   f0102787 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015df:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015e6:	e8 67 f7 ff ff       	call   f0100d52 <page_alloc>
f01015eb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015ee:	83 c4 10             	add    $0x10,%esp
f01015f1:	85 c0                	test   %eax,%eax
f01015f3:	75 19                	jne    f010160e <mem_init+0x58d>
f01015f5:	68 68 3d 10 f0       	push   $0xf0103d68
f01015fa:	68 99 3c 10 f0       	push   $0xf0103c99
f01015ff:	68 f3 02 00 00       	push   $0x2f3
f0101604:	68 73 3c 10 f0       	push   $0xf0103c73
f0101609:	e8 7d ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010160e:	83 ec 0c             	sub    $0xc,%esp
f0101611:	6a 00                	push   $0x0
f0101613:	e8 3a f7 ff ff       	call   f0100d52 <page_alloc>
f0101618:	89 c3                	mov    %eax,%ebx
f010161a:	83 c4 10             	add    $0x10,%esp
f010161d:	85 c0                	test   %eax,%eax
f010161f:	75 19                	jne    f010163a <mem_init+0x5b9>
f0101621:	68 7e 3d 10 f0       	push   $0xf0103d7e
f0101626:	68 99 3c 10 f0       	push   $0xf0103c99
f010162b:	68 f4 02 00 00       	push   $0x2f4
f0101630:	68 73 3c 10 f0       	push   $0xf0103c73
f0101635:	e8 51 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010163a:	83 ec 0c             	sub    $0xc,%esp
f010163d:	6a 00                	push   $0x0
f010163f:	e8 0e f7 ff ff       	call   f0100d52 <page_alloc>
f0101644:	89 c6                	mov    %eax,%esi
f0101646:	83 c4 10             	add    $0x10,%esp
f0101649:	85 c0                	test   %eax,%eax
f010164b:	75 19                	jne    f0101666 <mem_init+0x5e5>
f010164d:	68 94 3d 10 f0       	push   $0xf0103d94
f0101652:	68 99 3c 10 f0       	push   $0xf0103c99
f0101657:	68 f5 02 00 00       	push   $0x2f5
f010165c:	68 73 3c 10 f0       	push   $0xf0103c73
f0101661:	e8 25 ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101666:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101669:	75 19                	jne    f0101684 <mem_init+0x603>
f010166b:	68 aa 3d 10 f0       	push   $0xf0103daa
f0101670:	68 99 3c 10 f0       	push   $0xf0103c99
f0101675:	68 f8 02 00 00       	push   $0x2f8
f010167a:	68 73 3c 10 f0       	push   $0xf0103c73
f010167f:	e8 07 ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101684:	39 c3                	cmp    %eax,%ebx
f0101686:	74 05                	je     f010168d <mem_init+0x60c>
f0101688:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010168b:	75 19                	jne    f01016a6 <mem_init+0x625>
f010168d:	68 e4 40 10 f0       	push   $0xf01040e4
f0101692:	68 99 3c 10 f0       	push   $0xf0103c99
f0101697:	68 f9 02 00 00       	push   $0x2f9
f010169c:	68 73 3c 10 f0       	push   $0xf0103c73
f01016a1:	e8 e5 e9 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016a6:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01016ab:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016ae:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01016b5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016b8:	83 ec 0c             	sub    $0xc,%esp
f01016bb:	6a 00                	push   $0x0
f01016bd:	e8 90 f6 ff ff       	call   f0100d52 <page_alloc>
f01016c2:	83 c4 10             	add    $0x10,%esp
f01016c5:	85 c0                	test   %eax,%eax
f01016c7:	74 19                	je     f01016e2 <mem_init+0x661>
f01016c9:	68 13 3e 10 f0       	push   $0xf0103e13
f01016ce:	68 99 3c 10 f0       	push   $0xf0103c99
f01016d3:	68 00 03 00 00       	push   $0x300
f01016d8:	68 73 3c 10 f0       	push   $0xf0103c73
f01016dd:	e8 a9 e9 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016e2:	83 ec 04             	sub    $0x4,%esp
f01016e5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016e8:	50                   	push   %eax
f01016e9:	6a 00                	push   $0x0
f01016eb:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01016f1:	e8 81 f8 ff ff       	call   f0100f77 <page_lookup>
f01016f6:	83 c4 10             	add    $0x10,%esp
f01016f9:	85 c0                	test   %eax,%eax
f01016fb:	74 19                	je     f0101716 <mem_init+0x695>
f01016fd:	68 24 41 10 f0       	push   $0xf0104124
f0101702:	68 99 3c 10 f0       	push   $0xf0103c99
f0101707:	68 03 03 00 00       	push   $0x303
f010170c:	68 73 3c 10 f0       	push   $0xf0103c73
f0101711:	e8 75 e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101716:	6a 02                	push   $0x2
f0101718:	6a 00                	push   $0x0
f010171a:	53                   	push   %ebx
f010171b:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101721:	e8 f2 f8 ff ff       	call   f0101018 <page_insert>
f0101726:	83 c4 10             	add    $0x10,%esp
f0101729:	85 c0                	test   %eax,%eax
f010172b:	78 19                	js     f0101746 <mem_init+0x6c5>
f010172d:	68 5c 41 10 f0       	push   $0xf010415c
f0101732:	68 99 3c 10 f0       	push   $0xf0103c99
f0101737:	68 06 03 00 00       	push   $0x306
f010173c:	68 73 3c 10 f0       	push   $0xf0103c73
f0101741:	e8 45 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101746:	83 ec 0c             	sub    $0xc,%esp
f0101749:	ff 75 d4             	pushl  -0x2c(%ebp)
f010174c:	e8 77 f6 ff ff       	call   f0100dc8 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101751:	6a 02                	push   $0x2
f0101753:	6a 00                	push   $0x0
f0101755:	53                   	push   %ebx
f0101756:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010175c:	e8 b7 f8 ff ff       	call   f0101018 <page_insert>
f0101761:	83 c4 20             	add    $0x20,%esp
f0101764:	85 c0                	test   %eax,%eax
f0101766:	74 19                	je     f0101781 <mem_init+0x700>
f0101768:	68 8c 41 10 f0       	push   $0xf010418c
f010176d:	68 99 3c 10 f0       	push   $0xf0103c99
f0101772:	68 0a 03 00 00       	push   $0x30a
f0101777:	68 73 3c 10 f0       	push   $0xf0103c73
f010177c:	e8 0a e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101781:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101787:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f010178c:	89 c1                	mov    %eax,%ecx
f010178e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101791:	8b 17                	mov    (%edi),%edx
f0101793:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101799:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010179c:	29 c8                	sub    %ecx,%eax
f010179e:	c1 f8 03             	sar    $0x3,%eax
f01017a1:	c1 e0 0c             	shl    $0xc,%eax
f01017a4:	39 c2                	cmp    %eax,%edx
f01017a6:	74 19                	je     f01017c1 <mem_init+0x740>
f01017a8:	68 bc 41 10 f0       	push   $0xf01041bc
f01017ad:	68 99 3c 10 f0       	push   $0xf0103c99
f01017b2:	68 0b 03 00 00       	push   $0x30b
f01017b7:	68 73 3c 10 f0       	push   $0xf0103c73
f01017bc:	e8 ca e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017c1:	ba 00 00 00 00       	mov    $0x0,%edx
f01017c6:	89 f8                	mov    %edi,%eax
f01017c8:	e8 9c f1 ff ff       	call   f0100969 <check_va2pa>
f01017cd:	89 da                	mov    %ebx,%edx
f01017cf:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017d2:	c1 fa 03             	sar    $0x3,%edx
f01017d5:	c1 e2 0c             	shl    $0xc,%edx
f01017d8:	39 d0                	cmp    %edx,%eax
f01017da:	74 19                	je     f01017f5 <mem_init+0x774>
f01017dc:	68 e4 41 10 f0       	push   $0xf01041e4
f01017e1:	68 99 3c 10 f0       	push   $0xf0103c99
f01017e6:	68 0c 03 00 00       	push   $0x30c
f01017eb:	68 73 3c 10 f0       	push   $0xf0103c73
f01017f0:	e8 96 e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01017f5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017fa:	74 19                	je     f0101815 <mem_init+0x794>
f01017fc:	68 65 3e 10 f0       	push   $0xf0103e65
f0101801:	68 99 3c 10 f0       	push   $0xf0103c99
f0101806:	68 0d 03 00 00       	push   $0x30d
f010180b:	68 73 3c 10 f0       	push   $0xf0103c73
f0101810:	e8 76 e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101815:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101818:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010181d:	74 19                	je     f0101838 <mem_init+0x7b7>
f010181f:	68 76 3e 10 f0       	push   $0xf0103e76
f0101824:	68 99 3c 10 f0       	push   $0xf0103c99
f0101829:	68 0e 03 00 00       	push   $0x30e
f010182e:	68 73 3c 10 f0       	push   $0xf0103c73
f0101833:	e8 53 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101838:	6a 02                	push   $0x2
f010183a:	68 00 10 00 00       	push   $0x1000
f010183f:	56                   	push   %esi
f0101840:	57                   	push   %edi
f0101841:	e8 d2 f7 ff ff       	call   f0101018 <page_insert>
f0101846:	83 c4 10             	add    $0x10,%esp
f0101849:	85 c0                	test   %eax,%eax
f010184b:	74 19                	je     f0101866 <mem_init+0x7e5>
f010184d:	68 14 42 10 f0       	push   $0xf0104214
f0101852:	68 99 3c 10 f0       	push   $0xf0103c99
f0101857:	68 11 03 00 00       	push   $0x311
f010185c:	68 73 3c 10 f0       	push   $0xf0103c73
f0101861:	e8 25 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101866:	ba 00 10 00 00       	mov    $0x1000,%edx
f010186b:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101870:	e8 f4 f0 ff ff       	call   f0100969 <check_va2pa>
f0101875:	89 f2                	mov    %esi,%edx
f0101877:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010187d:	c1 fa 03             	sar    $0x3,%edx
f0101880:	c1 e2 0c             	shl    $0xc,%edx
f0101883:	39 d0                	cmp    %edx,%eax
f0101885:	74 19                	je     f01018a0 <mem_init+0x81f>
f0101887:	68 50 42 10 f0       	push   $0xf0104250
f010188c:	68 99 3c 10 f0       	push   $0xf0103c99
f0101891:	68 12 03 00 00       	push   $0x312
f0101896:	68 73 3c 10 f0       	push   $0xf0103c73
f010189b:	e8 eb e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018a0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018a5:	74 19                	je     f01018c0 <mem_init+0x83f>
f01018a7:	68 87 3e 10 f0       	push   $0xf0103e87
f01018ac:	68 99 3c 10 f0       	push   $0xf0103c99
f01018b1:	68 13 03 00 00       	push   $0x313
f01018b6:	68 73 3c 10 f0       	push   $0xf0103c73
f01018bb:	e8 cb e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018c0:	83 ec 0c             	sub    $0xc,%esp
f01018c3:	6a 00                	push   $0x0
f01018c5:	e8 88 f4 ff ff       	call   f0100d52 <page_alloc>
f01018ca:	83 c4 10             	add    $0x10,%esp
f01018cd:	85 c0                	test   %eax,%eax
f01018cf:	74 19                	je     f01018ea <mem_init+0x869>
f01018d1:	68 13 3e 10 f0       	push   $0xf0103e13
f01018d6:	68 99 3c 10 f0       	push   $0xf0103c99
f01018db:	68 16 03 00 00       	push   $0x316
f01018e0:	68 73 3c 10 f0       	push   $0xf0103c73
f01018e5:	e8 a1 e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018ea:	6a 02                	push   $0x2
f01018ec:	68 00 10 00 00       	push   $0x1000
f01018f1:	56                   	push   %esi
f01018f2:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01018f8:	e8 1b f7 ff ff       	call   f0101018 <page_insert>
f01018fd:	83 c4 10             	add    $0x10,%esp
f0101900:	85 c0                	test   %eax,%eax
f0101902:	74 19                	je     f010191d <mem_init+0x89c>
f0101904:	68 14 42 10 f0       	push   $0xf0104214
f0101909:	68 99 3c 10 f0       	push   $0xf0103c99
f010190e:	68 19 03 00 00       	push   $0x319
f0101913:	68 73 3c 10 f0       	push   $0xf0103c73
f0101918:	e8 6e e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010191d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101922:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101927:	e8 3d f0 ff ff       	call   f0100969 <check_va2pa>
f010192c:	89 f2                	mov    %esi,%edx
f010192e:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101934:	c1 fa 03             	sar    $0x3,%edx
f0101937:	c1 e2 0c             	shl    $0xc,%edx
f010193a:	39 d0                	cmp    %edx,%eax
f010193c:	74 19                	je     f0101957 <mem_init+0x8d6>
f010193e:	68 50 42 10 f0       	push   $0xf0104250
f0101943:	68 99 3c 10 f0       	push   $0xf0103c99
f0101948:	68 1a 03 00 00       	push   $0x31a
f010194d:	68 73 3c 10 f0       	push   $0xf0103c73
f0101952:	e8 34 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101957:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010195c:	74 19                	je     f0101977 <mem_init+0x8f6>
f010195e:	68 87 3e 10 f0       	push   $0xf0103e87
f0101963:	68 99 3c 10 f0       	push   $0xf0103c99
f0101968:	68 1b 03 00 00       	push   $0x31b
f010196d:	68 73 3c 10 f0       	push   $0xf0103c73
f0101972:	e8 14 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101977:	83 ec 0c             	sub    $0xc,%esp
f010197a:	6a 00                	push   $0x0
f010197c:	e8 d1 f3 ff ff       	call   f0100d52 <page_alloc>
f0101981:	83 c4 10             	add    $0x10,%esp
f0101984:	85 c0                	test   %eax,%eax
f0101986:	74 19                	je     f01019a1 <mem_init+0x920>
f0101988:	68 13 3e 10 f0       	push   $0xf0103e13
f010198d:	68 99 3c 10 f0       	push   $0xf0103c99
f0101992:	68 1f 03 00 00       	push   $0x31f
f0101997:	68 73 3c 10 f0       	push   $0xf0103c73
f010199c:	e8 ea e6 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019a1:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f01019a7:	8b 02                	mov    (%edx),%eax
f01019a9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019ae:	89 c1                	mov    %eax,%ecx
f01019b0:	c1 e9 0c             	shr    $0xc,%ecx
f01019b3:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f01019b9:	72 15                	jb     f01019d0 <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019bb:	50                   	push   %eax
f01019bc:	68 7c 3f 10 f0       	push   $0xf0103f7c
f01019c1:	68 22 03 00 00       	push   $0x322
f01019c6:	68 73 3c 10 f0       	push   $0xf0103c73
f01019cb:	e8 bb e6 ff ff       	call   f010008b <_panic>
f01019d0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019d5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019d8:	83 ec 04             	sub    $0x4,%esp
f01019db:	6a 00                	push   $0x0
f01019dd:	68 00 10 00 00       	push   $0x1000
f01019e2:	52                   	push   %edx
f01019e3:	e8 5d f4 ff ff       	call   f0100e45 <pgdir_walk>
f01019e8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01019eb:	8d 51 04             	lea    0x4(%ecx),%edx
f01019ee:	83 c4 10             	add    $0x10,%esp
f01019f1:	39 d0                	cmp    %edx,%eax
f01019f3:	74 19                	je     f0101a0e <mem_init+0x98d>
f01019f5:	68 80 42 10 f0       	push   $0xf0104280
f01019fa:	68 99 3c 10 f0       	push   $0xf0103c99
f01019ff:	68 23 03 00 00       	push   $0x323
f0101a04:	68 73 3c 10 f0       	push   $0xf0103c73
f0101a09:	e8 7d e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a0e:	6a 06                	push   $0x6
f0101a10:	68 00 10 00 00       	push   $0x1000
f0101a15:	56                   	push   %esi
f0101a16:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101a1c:	e8 f7 f5 ff ff       	call   f0101018 <page_insert>
f0101a21:	83 c4 10             	add    $0x10,%esp
f0101a24:	85 c0                	test   %eax,%eax
f0101a26:	74 19                	je     f0101a41 <mem_init+0x9c0>
f0101a28:	68 c0 42 10 f0       	push   $0xf01042c0
f0101a2d:	68 99 3c 10 f0       	push   $0xf0103c99
f0101a32:	68 26 03 00 00       	push   $0x326
f0101a37:	68 73 3c 10 f0       	push   $0xf0103c73
f0101a3c:	e8 4a e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a41:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101a47:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a4c:	89 f8                	mov    %edi,%eax
f0101a4e:	e8 16 ef ff ff       	call   f0100969 <check_va2pa>
f0101a53:	89 f2                	mov    %esi,%edx
f0101a55:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101a5b:	c1 fa 03             	sar    $0x3,%edx
f0101a5e:	c1 e2 0c             	shl    $0xc,%edx
f0101a61:	39 d0                	cmp    %edx,%eax
f0101a63:	74 19                	je     f0101a7e <mem_init+0x9fd>
f0101a65:	68 50 42 10 f0       	push   $0xf0104250
f0101a6a:	68 99 3c 10 f0       	push   $0xf0103c99
f0101a6f:	68 27 03 00 00       	push   $0x327
f0101a74:	68 73 3c 10 f0       	push   $0xf0103c73
f0101a79:	e8 0d e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a7e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a83:	74 19                	je     f0101a9e <mem_init+0xa1d>
f0101a85:	68 87 3e 10 f0       	push   $0xf0103e87
f0101a8a:	68 99 3c 10 f0       	push   $0xf0103c99
f0101a8f:	68 28 03 00 00       	push   $0x328
f0101a94:	68 73 3c 10 f0       	push   $0xf0103c73
f0101a99:	e8 ed e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a9e:	83 ec 04             	sub    $0x4,%esp
f0101aa1:	6a 00                	push   $0x0
f0101aa3:	68 00 10 00 00       	push   $0x1000
f0101aa8:	57                   	push   %edi
f0101aa9:	e8 97 f3 ff ff       	call   f0100e45 <pgdir_walk>
f0101aae:	83 c4 10             	add    $0x10,%esp
f0101ab1:	f6 00 04             	testb  $0x4,(%eax)
f0101ab4:	75 19                	jne    f0101acf <mem_init+0xa4e>
f0101ab6:	68 00 43 10 f0       	push   $0xf0104300
f0101abb:	68 99 3c 10 f0       	push   $0xf0103c99
f0101ac0:	68 29 03 00 00       	push   $0x329
f0101ac5:	68 73 3c 10 f0       	push   $0xf0103c73
f0101aca:	e8 bc e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101acf:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101ad4:	f6 00 04             	testb  $0x4,(%eax)
f0101ad7:	75 19                	jne    f0101af2 <mem_init+0xa71>
f0101ad9:	68 98 3e 10 f0       	push   $0xf0103e98
f0101ade:	68 99 3c 10 f0       	push   $0xf0103c99
f0101ae3:	68 2a 03 00 00       	push   $0x32a
f0101ae8:	68 73 3c 10 f0       	push   $0xf0103c73
f0101aed:	e8 99 e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101af2:	6a 02                	push   $0x2
f0101af4:	68 00 10 00 00       	push   $0x1000
f0101af9:	56                   	push   %esi
f0101afa:	50                   	push   %eax
f0101afb:	e8 18 f5 ff ff       	call   f0101018 <page_insert>
f0101b00:	83 c4 10             	add    $0x10,%esp
f0101b03:	85 c0                	test   %eax,%eax
f0101b05:	74 19                	je     f0101b20 <mem_init+0xa9f>
f0101b07:	68 14 42 10 f0       	push   $0xf0104214
f0101b0c:	68 99 3c 10 f0       	push   $0xf0103c99
f0101b11:	68 2d 03 00 00       	push   $0x32d
f0101b16:	68 73 3c 10 f0       	push   $0xf0103c73
f0101b1b:	e8 6b e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b20:	83 ec 04             	sub    $0x4,%esp
f0101b23:	6a 00                	push   $0x0
f0101b25:	68 00 10 00 00       	push   $0x1000
f0101b2a:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b30:	e8 10 f3 ff ff       	call   f0100e45 <pgdir_walk>
f0101b35:	83 c4 10             	add    $0x10,%esp
f0101b38:	f6 00 02             	testb  $0x2,(%eax)
f0101b3b:	75 19                	jne    f0101b56 <mem_init+0xad5>
f0101b3d:	68 34 43 10 f0       	push   $0xf0104334
f0101b42:	68 99 3c 10 f0       	push   $0xf0103c99
f0101b47:	68 2e 03 00 00       	push   $0x32e
f0101b4c:	68 73 3c 10 f0       	push   $0xf0103c73
f0101b51:	e8 35 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b56:	83 ec 04             	sub    $0x4,%esp
f0101b59:	6a 00                	push   $0x0
f0101b5b:	68 00 10 00 00       	push   $0x1000
f0101b60:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b66:	e8 da f2 ff ff       	call   f0100e45 <pgdir_walk>
f0101b6b:	83 c4 10             	add    $0x10,%esp
f0101b6e:	f6 00 04             	testb  $0x4,(%eax)
f0101b71:	74 19                	je     f0101b8c <mem_init+0xb0b>
f0101b73:	68 68 43 10 f0       	push   $0xf0104368
f0101b78:	68 99 3c 10 f0       	push   $0xf0103c99
f0101b7d:	68 2f 03 00 00       	push   $0x32f
f0101b82:	68 73 3c 10 f0       	push   $0xf0103c73
f0101b87:	e8 ff e4 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b8c:	6a 02                	push   $0x2
f0101b8e:	68 00 00 40 00       	push   $0x400000
f0101b93:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b96:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b9c:	e8 77 f4 ff ff       	call   f0101018 <page_insert>
f0101ba1:	83 c4 10             	add    $0x10,%esp
f0101ba4:	85 c0                	test   %eax,%eax
f0101ba6:	78 19                	js     f0101bc1 <mem_init+0xb40>
f0101ba8:	68 a0 43 10 f0       	push   $0xf01043a0
f0101bad:	68 99 3c 10 f0       	push   $0xf0103c99
f0101bb2:	68 32 03 00 00       	push   $0x332
f0101bb7:	68 73 3c 10 f0       	push   $0xf0103c73
f0101bbc:	e8 ca e4 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101bc1:	6a 02                	push   $0x2
f0101bc3:	68 00 10 00 00       	push   $0x1000
f0101bc8:	53                   	push   %ebx
f0101bc9:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101bcf:	e8 44 f4 ff ff       	call   f0101018 <page_insert>
f0101bd4:	83 c4 10             	add    $0x10,%esp
f0101bd7:	85 c0                	test   %eax,%eax
f0101bd9:	74 19                	je     f0101bf4 <mem_init+0xb73>
f0101bdb:	68 d8 43 10 f0       	push   $0xf01043d8
f0101be0:	68 99 3c 10 f0       	push   $0xf0103c99
f0101be5:	68 35 03 00 00       	push   $0x335
f0101bea:	68 73 3c 10 f0       	push   $0xf0103c73
f0101bef:	e8 97 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bf4:	83 ec 04             	sub    $0x4,%esp
f0101bf7:	6a 00                	push   $0x0
f0101bf9:	68 00 10 00 00       	push   $0x1000
f0101bfe:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c04:	e8 3c f2 ff ff       	call   f0100e45 <pgdir_walk>
f0101c09:	83 c4 10             	add    $0x10,%esp
f0101c0c:	f6 00 04             	testb  $0x4,(%eax)
f0101c0f:	74 19                	je     f0101c2a <mem_init+0xba9>
f0101c11:	68 68 43 10 f0       	push   $0xf0104368
f0101c16:	68 99 3c 10 f0       	push   $0xf0103c99
f0101c1b:	68 36 03 00 00       	push   $0x336
f0101c20:	68 73 3c 10 f0       	push   $0xf0103c73
f0101c25:	e8 61 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c2a:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101c30:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c35:	89 f8                	mov    %edi,%eax
f0101c37:	e8 2d ed ff ff       	call   f0100969 <check_va2pa>
f0101c3c:	89 c1                	mov    %eax,%ecx
f0101c3e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c41:	89 d8                	mov    %ebx,%eax
f0101c43:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101c49:	c1 f8 03             	sar    $0x3,%eax
f0101c4c:	c1 e0 0c             	shl    $0xc,%eax
f0101c4f:	39 c1                	cmp    %eax,%ecx
f0101c51:	74 19                	je     f0101c6c <mem_init+0xbeb>
f0101c53:	68 14 44 10 f0       	push   $0xf0104414
f0101c58:	68 99 3c 10 f0       	push   $0xf0103c99
f0101c5d:	68 39 03 00 00       	push   $0x339
f0101c62:	68 73 3c 10 f0       	push   $0xf0103c73
f0101c67:	e8 1f e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c6c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c71:	89 f8                	mov    %edi,%eax
f0101c73:	e8 f1 ec ff ff       	call   f0100969 <check_va2pa>
f0101c78:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c7b:	74 19                	je     f0101c96 <mem_init+0xc15>
f0101c7d:	68 40 44 10 f0       	push   $0xf0104440
f0101c82:	68 99 3c 10 f0       	push   $0xf0103c99
f0101c87:	68 3a 03 00 00       	push   $0x33a
f0101c8c:	68 73 3c 10 f0       	push   $0xf0103c73
f0101c91:	e8 f5 e3 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c96:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c9b:	74 19                	je     f0101cb6 <mem_init+0xc35>
f0101c9d:	68 ae 3e 10 f0       	push   $0xf0103eae
f0101ca2:	68 99 3c 10 f0       	push   $0xf0103c99
f0101ca7:	68 3c 03 00 00       	push   $0x33c
f0101cac:	68 73 3c 10 f0       	push   $0xf0103c73
f0101cb1:	e8 d5 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101cb6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101cbb:	74 19                	je     f0101cd6 <mem_init+0xc55>
f0101cbd:	68 bf 3e 10 f0       	push   $0xf0103ebf
f0101cc2:	68 99 3c 10 f0       	push   $0xf0103c99
f0101cc7:	68 3d 03 00 00       	push   $0x33d
f0101ccc:	68 73 3c 10 f0       	push   $0xf0103c73
f0101cd1:	e8 b5 e3 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cd6:	83 ec 0c             	sub    $0xc,%esp
f0101cd9:	6a 00                	push   $0x0
f0101cdb:	e8 72 f0 ff ff       	call   f0100d52 <page_alloc>
f0101ce0:	83 c4 10             	add    $0x10,%esp
f0101ce3:	85 c0                	test   %eax,%eax
f0101ce5:	74 04                	je     f0101ceb <mem_init+0xc6a>
f0101ce7:	39 c6                	cmp    %eax,%esi
f0101ce9:	74 19                	je     f0101d04 <mem_init+0xc83>
f0101ceb:	68 70 44 10 f0       	push   $0xf0104470
f0101cf0:	68 99 3c 10 f0       	push   $0xf0103c99
f0101cf5:	68 40 03 00 00       	push   $0x340
f0101cfa:	68 73 3c 10 f0       	push   $0xf0103c73
f0101cff:	e8 87 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d04:	83 ec 08             	sub    $0x8,%esp
f0101d07:	6a 00                	push   $0x0
f0101d09:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101d0f:	e8 c9 f2 ff ff       	call   f0100fdd <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d14:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101d1a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d1f:	89 f8                	mov    %edi,%eax
f0101d21:	e8 43 ec ff ff       	call   f0100969 <check_va2pa>
f0101d26:	83 c4 10             	add    $0x10,%esp
f0101d29:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d2c:	74 19                	je     f0101d47 <mem_init+0xcc6>
f0101d2e:	68 94 44 10 f0       	push   $0xf0104494
f0101d33:	68 99 3c 10 f0       	push   $0xf0103c99
f0101d38:	68 44 03 00 00       	push   $0x344
f0101d3d:	68 73 3c 10 f0       	push   $0xf0103c73
f0101d42:	e8 44 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d47:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d4c:	89 f8                	mov    %edi,%eax
f0101d4e:	e8 16 ec ff ff       	call   f0100969 <check_va2pa>
f0101d53:	89 da                	mov    %ebx,%edx
f0101d55:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101d5b:	c1 fa 03             	sar    $0x3,%edx
f0101d5e:	c1 e2 0c             	shl    $0xc,%edx
f0101d61:	39 d0                	cmp    %edx,%eax
f0101d63:	74 19                	je     f0101d7e <mem_init+0xcfd>
f0101d65:	68 40 44 10 f0       	push   $0xf0104440
f0101d6a:	68 99 3c 10 f0       	push   $0xf0103c99
f0101d6f:	68 45 03 00 00       	push   $0x345
f0101d74:	68 73 3c 10 f0       	push   $0xf0103c73
f0101d79:	e8 0d e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d7e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d83:	74 19                	je     f0101d9e <mem_init+0xd1d>
f0101d85:	68 65 3e 10 f0       	push   $0xf0103e65
f0101d8a:	68 99 3c 10 f0       	push   $0xf0103c99
f0101d8f:	68 46 03 00 00       	push   $0x346
f0101d94:	68 73 3c 10 f0       	push   $0xf0103c73
f0101d99:	e8 ed e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d9e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101da3:	74 19                	je     f0101dbe <mem_init+0xd3d>
f0101da5:	68 bf 3e 10 f0       	push   $0xf0103ebf
f0101daa:	68 99 3c 10 f0       	push   $0xf0103c99
f0101daf:	68 47 03 00 00       	push   $0x347
f0101db4:	68 73 3c 10 f0       	push   $0xf0103c73
f0101db9:	e8 cd e2 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101dbe:	6a 00                	push   $0x0
f0101dc0:	68 00 10 00 00       	push   $0x1000
f0101dc5:	53                   	push   %ebx
f0101dc6:	57                   	push   %edi
f0101dc7:	e8 4c f2 ff ff       	call   f0101018 <page_insert>
f0101dcc:	83 c4 10             	add    $0x10,%esp
f0101dcf:	85 c0                	test   %eax,%eax
f0101dd1:	74 19                	je     f0101dec <mem_init+0xd6b>
f0101dd3:	68 b8 44 10 f0       	push   $0xf01044b8
f0101dd8:	68 99 3c 10 f0       	push   $0xf0103c99
f0101ddd:	68 4a 03 00 00       	push   $0x34a
f0101de2:	68 73 3c 10 f0       	push   $0xf0103c73
f0101de7:	e8 9f e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101dec:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101df1:	75 19                	jne    f0101e0c <mem_init+0xd8b>
f0101df3:	68 d0 3e 10 f0       	push   $0xf0103ed0
f0101df8:	68 99 3c 10 f0       	push   $0xf0103c99
f0101dfd:	68 4b 03 00 00       	push   $0x34b
f0101e02:	68 73 3c 10 f0       	push   $0xf0103c73
f0101e07:	e8 7f e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101e0c:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e0f:	74 19                	je     f0101e2a <mem_init+0xda9>
f0101e11:	68 dc 3e 10 f0       	push   $0xf0103edc
f0101e16:	68 99 3c 10 f0       	push   $0xf0103c99
f0101e1b:	68 4c 03 00 00       	push   $0x34c
f0101e20:	68 73 3c 10 f0       	push   $0xf0103c73
f0101e25:	e8 61 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e2a:	83 ec 08             	sub    $0x8,%esp
f0101e2d:	68 00 10 00 00       	push   $0x1000
f0101e32:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101e38:	e8 a0 f1 ff ff       	call   f0100fdd <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e3d:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101e43:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e48:	89 f8                	mov    %edi,%eax
f0101e4a:	e8 1a eb ff ff       	call   f0100969 <check_va2pa>
f0101e4f:	83 c4 10             	add    $0x10,%esp
f0101e52:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e55:	74 19                	je     f0101e70 <mem_init+0xdef>
f0101e57:	68 94 44 10 f0       	push   $0xf0104494
f0101e5c:	68 99 3c 10 f0       	push   $0xf0103c99
f0101e61:	68 50 03 00 00       	push   $0x350
f0101e66:	68 73 3c 10 f0       	push   $0xf0103c73
f0101e6b:	e8 1b e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e70:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e75:	89 f8                	mov    %edi,%eax
f0101e77:	e8 ed ea ff ff       	call   f0100969 <check_va2pa>
f0101e7c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e7f:	74 19                	je     f0101e9a <mem_init+0xe19>
f0101e81:	68 f0 44 10 f0       	push   $0xf01044f0
f0101e86:	68 99 3c 10 f0       	push   $0xf0103c99
f0101e8b:	68 51 03 00 00       	push   $0x351
f0101e90:	68 73 3c 10 f0       	push   $0xf0103c73
f0101e95:	e8 f1 e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e9a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e9f:	74 19                	je     f0101eba <mem_init+0xe39>
f0101ea1:	68 f1 3e 10 f0       	push   $0xf0103ef1
f0101ea6:	68 99 3c 10 f0       	push   $0xf0103c99
f0101eab:	68 52 03 00 00       	push   $0x352
f0101eb0:	68 73 3c 10 f0       	push   $0xf0103c73
f0101eb5:	e8 d1 e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101eba:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ebf:	74 19                	je     f0101eda <mem_init+0xe59>
f0101ec1:	68 bf 3e 10 f0       	push   $0xf0103ebf
f0101ec6:	68 99 3c 10 f0       	push   $0xf0103c99
f0101ecb:	68 53 03 00 00       	push   $0x353
f0101ed0:	68 73 3c 10 f0       	push   $0xf0103c73
f0101ed5:	e8 b1 e1 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101eda:	83 ec 0c             	sub    $0xc,%esp
f0101edd:	6a 00                	push   $0x0
f0101edf:	e8 6e ee ff ff       	call   f0100d52 <page_alloc>
f0101ee4:	83 c4 10             	add    $0x10,%esp
f0101ee7:	39 c3                	cmp    %eax,%ebx
f0101ee9:	75 04                	jne    f0101eef <mem_init+0xe6e>
f0101eeb:	85 c0                	test   %eax,%eax
f0101eed:	75 19                	jne    f0101f08 <mem_init+0xe87>
f0101eef:	68 18 45 10 f0       	push   $0xf0104518
f0101ef4:	68 99 3c 10 f0       	push   $0xf0103c99
f0101ef9:	68 56 03 00 00       	push   $0x356
f0101efe:	68 73 3c 10 f0       	push   $0xf0103c73
f0101f03:	e8 83 e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f08:	83 ec 0c             	sub    $0xc,%esp
f0101f0b:	6a 00                	push   $0x0
f0101f0d:	e8 40 ee ff ff       	call   f0100d52 <page_alloc>
f0101f12:	83 c4 10             	add    $0x10,%esp
f0101f15:	85 c0                	test   %eax,%eax
f0101f17:	74 19                	je     f0101f32 <mem_init+0xeb1>
f0101f19:	68 13 3e 10 f0       	push   $0xf0103e13
f0101f1e:	68 99 3c 10 f0       	push   $0xf0103c99
f0101f23:	68 59 03 00 00       	push   $0x359
f0101f28:	68 73 3c 10 f0       	push   $0xf0103c73
f0101f2d:	e8 59 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f32:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0101f38:	8b 11                	mov    (%ecx),%edx
f0101f3a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f40:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f43:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101f49:	c1 f8 03             	sar    $0x3,%eax
f0101f4c:	c1 e0 0c             	shl    $0xc,%eax
f0101f4f:	39 c2                	cmp    %eax,%edx
f0101f51:	74 19                	je     f0101f6c <mem_init+0xeeb>
f0101f53:	68 bc 41 10 f0       	push   $0xf01041bc
f0101f58:	68 99 3c 10 f0       	push   $0xf0103c99
f0101f5d:	68 5c 03 00 00       	push   $0x35c
f0101f62:	68 73 3c 10 f0       	push   $0xf0103c73
f0101f67:	e8 1f e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f6c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f72:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f75:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f7a:	74 19                	je     f0101f95 <mem_init+0xf14>
f0101f7c:	68 76 3e 10 f0       	push   $0xf0103e76
f0101f81:	68 99 3c 10 f0       	push   $0xf0103c99
f0101f86:	68 5e 03 00 00       	push   $0x35e
f0101f8b:	68 73 3c 10 f0       	push   $0xf0103c73
f0101f90:	e8 f6 e0 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f95:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f98:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f9e:	83 ec 0c             	sub    $0xc,%esp
f0101fa1:	50                   	push   %eax
f0101fa2:	e8 21 ee ff ff       	call   f0100dc8 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fa7:	83 c4 0c             	add    $0xc,%esp
f0101faa:	6a 01                	push   $0x1
f0101fac:	68 00 10 40 00       	push   $0x401000
f0101fb1:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101fb7:	e8 89 ee ff ff       	call   f0100e45 <pgdir_walk>
f0101fbc:	89 c7                	mov    %eax,%edi
f0101fbe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fc1:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101fc6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fc9:	8b 40 04             	mov    0x4(%eax),%eax
f0101fcc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fd1:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101fd7:	89 c2                	mov    %eax,%edx
f0101fd9:	c1 ea 0c             	shr    $0xc,%edx
f0101fdc:	83 c4 10             	add    $0x10,%esp
f0101fdf:	39 ca                	cmp    %ecx,%edx
f0101fe1:	72 15                	jb     f0101ff8 <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fe3:	50                   	push   %eax
f0101fe4:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0101fe9:	68 65 03 00 00       	push   $0x365
f0101fee:	68 73 3c 10 f0       	push   $0xf0103c73
f0101ff3:	e8 93 e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101ff8:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101ffd:	39 c7                	cmp    %eax,%edi
f0101fff:	74 19                	je     f010201a <mem_init+0xf99>
f0102001:	68 02 3f 10 f0       	push   $0xf0103f02
f0102006:	68 99 3c 10 f0       	push   $0xf0103c99
f010200b:	68 66 03 00 00       	push   $0x366
f0102010:	68 73 3c 10 f0       	push   $0xf0103c73
f0102015:	e8 71 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f010201a:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010201d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102024:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102027:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010202d:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102033:	c1 f8 03             	sar    $0x3,%eax
f0102036:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102039:	89 c2                	mov    %eax,%edx
f010203b:	c1 ea 0c             	shr    $0xc,%edx
f010203e:	39 d1                	cmp    %edx,%ecx
f0102040:	77 12                	ja     f0102054 <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102042:	50                   	push   %eax
f0102043:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0102048:	6a 52                	push   $0x52
f010204a:	68 7f 3c 10 f0       	push   $0xf0103c7f
f010204f:	e8 37 e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102054:	83 ec 04             	sub    $0x4,%esp
f0102057:	68 00 10 00 00       	push   $0x1000
f010205c:	68 ff 00 00 00       	push   $0xff
f0102061:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102066:	50                   	push   %eax
f0102067:	e8 04 12 00 00       	call   f0103270 <memset>
	page_free(pp0);
f010206c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010206f:	89 3c 24             	mov    %edi,(%esp)
f0102072:	e8 51 ed ff ff       	call   f0100dc8 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102077:	83 c4 0c             	add    $0xc,%esp
f010207a:	6a 01                	push   $0x1
f010207c:	6a 00                	push   $0x0
f010207e:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102084:	e8 bc ed ff ff       	call   f0100e45 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102089:	89 fa                	mov    %edi,%edx
f010208b:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102091:	c1 fa 03             	sar    $0x3,%edx
f0102094:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102097:	89 d0                	mov    %edx,%eax
f0102099:	c1 e8 0c             	shr    $0xc,%eax
f010209c:	83 c4 10             	add    $0x10,%esp
f010209f:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f01020a5:	72 12                	jb     f01020b9 <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020a7:	52                   	push   %edx
f01020a8:	68 7c 3f 10 f0       	push   $0xf0103f7c
f01020ad:	6a 52                	push   $0x52
f01020af:	68 7f 3c 10 f0       	push   $0xf0103c7f
f01020b4:	e8 d2 df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f01020b9:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020bf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020c2:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020c8:	f6 00 01             	testb  $0x1,(%eax)
f01020cb:	74 19                	je     f01020e6 <mem_init+0x1065>
f01020cd:	68 1a 3f 10 f0       	push   $0xf0103f1a
f01020d2:	68 99 3c 10 f0       	push   $0xf0103c99
f01020d7:	68 70 03 00 00       	push   $0x370
f01020dc:	68 73 3c 10 f0       	push   $0xf0103c73
f01020e1:	e8 a5 df ff ff       	call   f010008b <_panic>
f01020e6:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020e9:	39 d0                	cmp    %edx,%eax
f01020eb:	75 db                	jne    f01020c8 <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020ed:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01020f2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020fb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102101:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102104:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f010210a:	83 ec 0c             	sub    $0xc,%esp
f010210d:	50                   	push   %eax
f010210e:	e8 b5 ec ff ff       	call   f0100dc8 <page_free>
	page_free(pp1);
f0102113:	89 1c 24             	mov    %ebx,(%esp)
f0102116:	e8 ad ec ff ff       	call   f0100dc8 <page_free>
	page_free(pp2);
f010211b:	89 34 24             	mov    %esi,(%esp)
f010211e:	e8 a5 ec ff ff       	call   f0100dc8 <page_free>

	cprintf("check_page() succeeded!\n");
f0102123:	c7 04 24 31 3f 10 f0 	movl   $0xf0103f31,(%esp)
f010212a:	e8 58 06 00 00       	call   f0102787 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	int pages_size = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE); 
f010212f:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0102134:	8d 0c c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%ecx
f010213b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
    boot_map_region(kern_pgdir, UPAGES, pages_size, PADDR(pages), PTE_U);
f0102141:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102146:	83 c4 10             	add    $0x10,%esp
f0102149:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010214e:	77 15                	ja     f0102165 <mem_init+0x10e4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102150:	50                   	push   %eax
f0102151:	68 64 40 10 f0       	push   $0xf0104064
f0102156:	68 b8 00 00 00       	push   $0xb8
f010215b:	68 73 3c 10 f0       	push   $0xf0103c73
f0102160:	e8 26 df ff ff       	call   f010008b <_panic>
f0102165:	83 ec 08             	sub    $0x8,%esp
f0102168:	6a 04                	push   $0x4
f010216a:	05 00 00 00 10       	add    $0x10000000,%eax
f010216f:	50                   	push   %eax
f0102170:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102175:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010217a:	e8 91 ed ff ff       	call   f0100f10 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010217f:	83 c4 10             	add    $0x10,%esp
f0102182:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f0102187:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010218c:	77 15                	ja     f01021a3 <mem_init+0x1122>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010218e:	50                   	push   %eax
f010218f:	68 64 40 10 f0       	push   $0xf0104064
f0102194:	68 c6 00 00 00       	push   $0xc6
f0102199:	68 73 3c 10 f0       	push   $0xf0103c73
f010219e:	e8 e8 de ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, ROUNDUP(KSTKSIZE, PGSIZE), PADDR(bootstack), PTE_W);
f01021a3:	83 ec 08             	sub    $0x8,%esp
f01021a6:	6a 02                	push   $0x2
f01021a8:	68 00 d0 10 00       	push   $0x10d000
f01021ad:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021b2:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021b7:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021bc:	e8 4f ed ff ff       	call   f0100f10 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, ROUNDUP(~KERNBASE+1, PGSIZE), 0, PTE_W);
f01021c1:	83 c4 08             	add    $0x8,%esp
f01021c4:	6a 02                	push   $0x2
f01021c6:	6a 00                	push   $0x0
f01021c8:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01021cd:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021d2:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01021d7:	e8 34 ed ff ff       	call   f0100f10 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021dc:	8b 35 68 79 11 f0    	mov    0xf0117968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021e2:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01021e7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021ea:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021f1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021f6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021f9:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021ff:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102202:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102205:	bb 00 00 00 00       	mov    $0x0,%ebx
f010220a:	eb 55                	jmp    f0102261 <mem_init+0x11e0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010220c:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102212:	89 f0                	mov    %esi,%eax
f0102214:	e8 50 e7 ff ff       	call   f0100969 <check_va2pa>
f0102219:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102220:	77 15                	ja     f0102237 <mem_init+0x11b6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102222:	57                   	push   %edi
f0102223:	68 64 40 10 f0       	push   $0xf0104064
f0102228:	68 b2 02 00 00       	push   $0x2b2
f010222d:	68 73 3c 10 f0       	push   $0xf0103c73
f0102232:	e8 54 de ff ff       	call   f010008b <_panic>
f0102237:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010223e:	39 c2                	cmp    %eax,%edx
f0102240:	74 19                	je     f010225b <mem_init+0x11da>
f0102242:	68 3c 45 10 f0       	push   $0xf010453c
f0102247:	68 99 3c 10 f0       	push   $0xf0103c99
f010224c:	68 b2 02 00 00       	push   $0x2b2
f0102251:	68 73 3c 10 f0       	push   $0xf0103c73
f0102256:	e8 30 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010225b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102261:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102264:	77 a6                	ja     f010220c <mem_init+0x118b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102266:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102269:	c1 e7 0c             	shl    $0xc,%edi
f010226c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102271:	eb 30                	jmp    f01022a3 <mem_init+0x1222>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102273:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102279:	89 f0                	mov    %esi,%eax
f010227b:	e8 e9 e6 ff ff       	call   f0100969 <check_va2pa>
f0102280:	39 c3                	cmp    %eax,%ebx
f0102282:	74 19                	je     f010229d <mem_init+0x121c>
f0102284:	68 70 45 10 f0       	push   $0xf0104570
f0102289:	68 99 3c 10 f0       	push   $0xf0103c99
f010228e:	68 b7 02 00 00       	push   $0x2b7
f0102293:	68 73 3c 10 f0       	push   $0xf0103c73
f0102298:	e8 ee dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010229d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01022a3:	39 fb                	cmp    %edi,%ebx
f01022a5:	72 cc                	jb     f0102273 <mem_init+0x11f2>
f01022a7:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01022ac:	89 da                	mov    %ebx,%edx
f01022ae:	89 f0                	mov    %esi,%eax
f01022b0:	e8 b4 e6 ff ff       	call   f0100969 <check_va2pa>
f01022b5:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f01022bb:	39 c2                	cmp    %eax,%edx
f01022bd:	74 19                	je     f01022d8 <mem_init+0x1257>
f01022bf:	68 98 45 10 f0       	push   $0xf0104598
f01022c4:	68 99 3c 10 f0       	push   $0xf0103c99
f01022c9:	68 bb 02 00 00       	push   $0x2bb
f01022ce:	68 73 3c 10 f0       	push   $0xf0103c73
f01022d3:	e8 b3 dd ff ff       	call   f010008b <_panic>
f01022d8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022de:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01022e4:	75 c6                	jne    f01022ac <mem_init+0x122b>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022e6:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022eb:	89 f0                	mov    %esi,%eax
f01022ed:	e8 77 e6 ff ff       	call   f0100969 <check_va2pa>
f01022f2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022f5:	74 51                	je     f0102348 <mem_init+0x12c7>
f01022f7:	68 e0 45 10 f0       	push   $0xf01045e0
f01022fc:	68 99 3c 10 f0       	push   $0xf0103c99
f0102301:	68 bc 02 00 00       	push   $0x2bc
f0102306:	68 73 3c 10 f0       	push   $0xf0103c73
f010230b:	e8 7b dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102310:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102315:	72 36                	jb     f010234d <mem_init+0x12cc>
f0102317:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010231c:	76 07                	jbe    f0102325 <mem_init+0x12a4>
f010231e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102323:	75 28                	jne    f010234d <mem_init+0x12cc>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102325:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102329:	0f 85 83 00 00 00    	jne    f01023b2 <mem_init+0x1331>
f010232f:	68 4a 3f 10 f0       	push   $0xf0103f4a
f0102334:	68 99 3c 10 f0       	push   $0xf0103c99
f0102339:	68 c4 02 00 00       	push   $0x2c4
f010233e:	68 73 3c 10 f0       	push   $0xf0103c73
f0102343:	e8 43 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102348:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010234d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102352:	76 3f                	jbe    f0102393 <mem_init+0x1312>
				assert(pgdir[i] & PTE_P);
f0102354:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102357:	f6 c2 01             	test   $0x1,%dl
f010235a:	75 19                	jne    f0102375 <mem_init+0x12f4>
f010235c:	68 4a 3f 10 f0       	push   $0xf0103f4a
f0102361:	68 99 3c 10 f0       	push   $0xf0103c99
f0102366:	68 c8 02 00 00       	push   $0x2c8
f010236b:	68 73 3c 10 f0       	push   $0xf0103c73
f0102370:	e8 16 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102375:	f6 c2 02             	test   $0x2,%dl
f0102378:	75 38                	jne    f01023b2 <mem_init+0x1331>
f010237a:	68 5b 3f 10 f0       	push   $0xf0103f5b
f010237f:	68 99 3c 10 f0       	push   $0xf0103c99
f0102384:	68 c9 02 00 00       	push   $0x2c9
f0102389:	68 73 3c 10 f0       	push   $0xf0103c73
f010238e:	e8 f8 dc ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102393:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102397:	74 19                	je     f01023b2 <mem_init+0x1331>
f0102399:	68 6c 3f 10 f0       	push   $0xf0103f6c
f010239e:	68 99 3c 10 f0       	push   $0xf0103c99
f01023a3:	68 cb 02 00 00       	push   $0x2cb
f01023a8:	68 73 3c 10 f0       	push   $0xf0103c73
f01023ad:	e8 d9 dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01023b2:	83 c0 01             	add    $0x1,%eax
f01023b5:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01023ba:	0f 86 50 ff ff ff    	jbe    f0102310 <mem_init+0x128f>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01023c0:	83 ec 0c             	sub    $0xc,%esp
f01023c3:	68 10 46 10 f0       	push   $0xf0104610
f01023c8:	e8 ba 03 00 00       	call   f0102787 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023cd:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023d2:	83 c4 10             	add    $0x10,%esp
f01023d5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023da:	77 15                	ja     f01023f1 <mem_init+0x1370>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023dc:	50                   	push   %eax
f01023dd:	68 64 40 10 f0       	push   $0xf0104064
f01023e2:	68 dd 00 00 00       	push   $0xdd
f01023e7:	68 73 3c 10 f0       	push   $0xf0103c73
f01023ec:	e8 9a dc ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01023f1:	05 00 00 00 10       	add    $0x10000000,%eax
f01023f6:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01023f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01023fe:	e8 ca e5 ff ff       	call   f01009cd <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102403:	0f 20 c0             	mov    %cr0,%eax
f0102406:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102409:	0d 23 00 05 80       	or     $0x80050023,%eax
f010240e:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102411:	83 ec 0c             	sub    $0xc,%esp
f0102414:	6a 00                	push   $0x0
f0102416:	e8 37 e9 ff ff       	call   f0100d52 <page_alloc>
f010241b:	89 c3                	mov    %eax,%ebx
f010241d:	83 c4 10             	add    $0x10,%esp
f0102420:	85 c0                	test   %eax,%eax
f0102422:	75 19                	jne    f010243d <mem_init+0x13bc>
f0102424:	68 68 3d 10 f0       	push   $0xf0103d68
f0102429:	68 99 3c 10 f0       	push   $0xf0103c99
f010242e:	68 8b 03 00 00       	push   $0x38b
f0102433:	68 73 3c 10 f0       	push   $0xf0103c73
f0102438:	e8 4e dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010243d:	83 ec 0c             	sub    $0xc,%esp
f0102440:	6a 00                	push   $0x0
f0102442:	e8 0b e9 ff ff       	call   f0100d52 <page_alloc>
f0102447:	89 c7                	mov    %eax,%edi
f0102449:	83 c4 10             	add    $0x10,%esp
f010244c:	85 c0                	test   %eax,%eax
f010244e:	75 19                	jne    f0102469 <mem_init+0x13e8>
f0102450:	68 7e 3d 10 f0       	push   $0xf0103d7e
f0102455:	68 99 3c 10 f0       	push   $0xf0103c99
f010245a:	68 8c 03 00 00       	push   $0x38c
f010245f:	68 73 3c 10 f0       	push   $0xf0103c73
f0102464:	e8 22 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102469:	83 ec 0c             	sub    $0xc,%esp
f010246c:	6a 00                	push   $0x0
f010246e:	e8 df e8 ff ff       	call   f0100d52 <page_alloc>
f0102473:	89 c6                	mov    %eax,%esi
f0102475:	83 c4 10             	add    $0x10,%esp
f0102478:	85 c0                	test   %eax,%eax
f010247a:	75 19                	jne    f0102495 <mem_init+0x1414>
f010247c:	68 94 3d 10 f0       	push   $0xf0103d94
f0102481:	68 99 3c 10 f0       	push   $0xf0103c99
f0102486:	68 8d 03 00 00       	push   $0x38d
f010248b:	68 73 3c 10 f0       	push   $0xf0103c73
f0102490:	e8 f6 db ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102495:	83 ec 0c             	sub    $0xc,%esp
f0102498:	53                   	push   %ebx
f0102499:	e8 2a e9 ff ff       	call   f0100dc8 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010249e:	89 f8                	mov    %edi,%eax
f01024a0:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01024a6:	c1 f8 03             	sar    $0x3,%eax
f01024a9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024ac:	89 c2                	mov    %eax,%edx
f01024ae:	c1 ea 0c             	shr    $0xc,%edx
f01024b1:	83 c4 10             	add    $0x10,%esp
f01024b4:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01024ba:	72 12                	jb     f01024ce <mem_init+0x144d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024bc:	50                   	push   %eax
f01024bd:	68 7c 3f 10 f0       	push   $0xf0103f7c
f01024c2:	6a 52                	push   $0x52
f01024c4:	68 7f 3c 10 f0       	push   $0xf0103c7f
f01024c9:	e8 bd db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024ce:	83 ec 04             	sub    $0x4,%esp
f01024d1:	68 00 10 00 00       	push   $0x1000
f01024d6:	6a 01                	push   $0x1
f01024d8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024dd:	50                   	push   %eax
f01024de:	e8 8d 0d 00 00       	call   f0103270 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024e3:	89 f0                	mov    %esi,%eax
f01024e5:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01024eb:	c1 f8 03             	sar    $0x3,%eax
f01024ee:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024f1:	89 c2                	mov    %eax,%edx
f01024f3:	c1 ea 0c             	shr    $0xc,%edx
f01024f6:	83 c4 10             	add    $0x10,%esp
f01024f9:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01024ff:	72 12                	jb     f0102513 <mem_init+0x1492>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102501:	50                   	push   %eax
f0102502:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0102507:	6a 52                	push   $0x52
f0102509:	68 7f 3c 10 f0       	push   $0xf0103c7f
f010250e:	e8 78 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102513:	83 ec 04             	sub    $0x4,%esp
f0102516:	68 00 10 00 00       	push   $0x1000
f010251b:	6a 02                	push   $0x2
f010251d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102522:	50                   	push   %eax
f0102523:	e8 48 0d 00 00       	call   f0103270 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102528:	6a 02                	push   $0x2
f010252a:	68 00 10 00 00       	push   $0x1000
f010252f:	57                   	push   %edi
f0102530:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102536:	e8 dd ea ff ff       	call   f0101018 <page_insert>
	assert(pp1->pp_ref == 1);
f010253b:	83 c4 20             	add    $0x20,%esp
f010253e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102543:	74 19                	je     f010255e <mem_init+0x14dd>
f0102545:	68 65 3e 10 f0       	push   $0xf0103e65
f010254a:	68 99 3c 10 f0       	push   $0xf0103c99
f010254f:	68 92 03 00 00       	push   $0x392
f0102554:	68 73 3c 10 f0       	push   $0xf0103c73
f0102559:	e8 2d db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010255e:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102565:	01 01 01 
f0102568:	74 19                	je     f0102583 <mem_init+0x1502>
f010256a:	68 30 46 10 f0       	push   $0xf0104630
f010256f:	68 99 3c 10 f0       	push   $0xf0103c99
f0102574:	68 93 03 00 00       	push   $0x393
f0102579:	68 73 3c 10 f0       	push   $0xf0103c73
f010257e:	e8 08 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102583:	6a 02                	push   $0x2
f0102585:	68 00 10 00 00       	push   $0x1000
f010258a:	56                   	push   %esi
f010258b:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102591:	e8 82 ea ff ff       	call   f0101018 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102596:	83 c4 10             	add    $0x10,%esp
f0102599:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01025a0:	02 02 02 
f01025a3:	74 19                	je     f01025be <mem_init+0x153d>
f01025a5:	68 54 46 10 f0       	push   $0xf0104654
f01025aa:	68 99 3c 10 f0       	push   $0xf0103c99
f01025af:	68 95 03 00 00       	push   $0x395
f01025b4:	68 73 3c 10 f0       	push   $0xf0103c73
f01025b9:	e8 cd da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01025be:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025c3:	74 19                	je     f01025de <mem_init+0x155d>
f01025c5:	68 87 3e 10 f0       	push   $0xf0103e87
f01025ca:	68 99 3c 10 f0       	push   $0xf0103c99
f01025cf:	68 96 03 00 00       	push   $0x396
f01025d4:	68 73 3c 10 f0       	push   $0xf0103c73
f01025d9:	e8 ad da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01025de:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025e3:	74 19                	je     f01025fe <mem_init+0x157d>
f01025e5:	68 f1 3e 10 f0       	push   $0xf0103ef1
f01025ea:	68 99 3c 10 f0       	push   $0xf0103c99
f01025ef:	68 97 03 00 00       	push   $0x397
f01025f4:	68 73 3c 10 f0       	push   $0xf0103c73
f01025f9:	e8 8d da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01025fe:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102605:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102608:	89 f0                	mov    %esi,%eax
f010260a:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102610:	c1 f8 03             	sar    $0x3,%eax
f0102613:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102616:	89 c2                	mov    %eax,%edx
f0102618:	c1 ea 0c             	shr    $0xc,%edx
f010261b:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102621:	72 12                	jb     f0102635 <mem_init+0x15b4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102623:	50                   	push   %eax
f0102624:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0102629:	6a 52                	push   $0x52
f010262b:	68 7f 3c 10 f0       	push   $0xf0103c7f
f0102630:	e8 56 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102635:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010263c:	03 03 03 
f010263f:	74 19                	je     f010265a <mem_init+0x15d9>
f0102641:	68 78 46 10 f0       	push   $0xf0104678
f0102646:	68 99 3c 10 f0       	push   $0xf0103c99
f010264b:	68 99 03 00 00       	push   $0x399
f0102650:	68 73 3c 10 f0       	push   $0xf0103c73
f0102655:	e8 31 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010265a:	83 ec 08             	sub    $0x8,%esp
f010265d:	68 00 10 00 00       	push   $0x1000
f0102662:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102668:	e8 70 e9 ff ff       	call   f0100fdd <page_remove>
	assert(pp2->pp_ref == 0);
f010266d:	83 c4 10             	add    $0x10,%esp
f0102670:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102675:	74 19                	je     f0102690 <mem_init+0x160f>
f0102677:	68 bf 3e 10 f0       	push   $0xf0103ebf
f010267c:	68 99 3c 10 f0       	push   $0xf0103c99
f0102681:	68 9b 03 00 00       	push   $0x39b
f0102686:	68 73 3c 10 f0       	push   $0xf0103c73
f010268b:	e8 fb d9 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102690:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0102696:	8b 11                	mov    (%ecx),%edx
f0102698:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010269e:	89 d8                	mov    %ebx,%eax
f01026a0:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01026a6:	c1 f8 03             	sar    $0x3,%eax
f01026a9:	c1 e0 0c             	shl    $0xc,%eax
f01026ac:	39 c2                	cmp    %eax,%edx
f01026ae:	74 19                	je     f01026c9 <mem_init+0x1648>
f01026b0:	68 bc 41 10 f0       	push   $0xf01041bc
f01026b5:	68 99 3c 10 f0       	push   $0xf0103c99
f01026ba:	68 9e 03 00 00       	push   $0x39e
f01026bf:	68 73 3c 10 f0       	push   $0xf0103c73
f01026c4:	e8 c2 d9 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01026c9:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026cf:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026d4:	74 19                	je     f01026ef <mem_init+0x166e>
f01026d6:	68 76 3e 10 f0       	push   $0xf0103e76
f01026db:	68 99 3c 10 f0       	push   $0xf0103c99
f01026e0:	68 a0 03 00 00       	push   $0x3a0
f01026e5:	68 73 3c 10 f0       	push   $0xf0103c73
f01026ea:	e8 9c d9 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01026ef:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01026f5:	83 ec 0c             	sub    $0xc,%esp
f01026f8:	53                   	push   %ebx
f01026f9:	e8 ca e6 ff ff       	call   f0100dc8 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01026fe:	c7 04 24 a4 46 10 f0 	movl   $0xf01046a4,(%esp)
f0102705:	e8 7d 00 00 00       	call   f0102787 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010270a:	83 c4 10             	add    $0x10,%esp
f010270d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102710:	5b                   	pop    %ebx
f0102711:	5e                   	pop    %esi
f0102712:	5f                   	pop    %edi
f0102713:	5d                   	pop    %ebp
f0102714:	c3                   	ret    

f0102715 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102715:	55                   	push   %ebp
f0102716:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102718:	8b 45 0c             	mov    0xc(%ebp),%eax
f010271b:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010271e:	5d                   	pop    %ebp
f010271f:	c3                   	ret    

f0102720 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102720:	55                   	push   %ebp
f0102721:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102723:	ba 70 00 00 00       	mov    $0x70,%edx
f0102728:	8b 45 08             	mov    0x8(%ebp),%eax
f010272b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010272c:	ba 71 00 00 00       	mov    $0x71,%edx
f0102731:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102732:	0f b6 c0             	movzbl %al,%eax
}
f0102735:	5d                   	pop    %ebp
f0102736:	c3                   	ret    

f0102737 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102737:	55                   	push   %ebp
f0102738:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010273a:	ba 70 00 00 00       	mov    $0x70,%edx
f010273f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102742:	ee                   	out    %al,(%dx)
f0102743:	ba 71 00 00 00       	mov    $0x71,%edx
f0102748:	8b 45 0c             	mov    0xc(%ebp),%eax
f010274b:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010274c:	5d                   	pop    %ebp
f010274d:	c3                   	ret    

f010274e <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010274e:	55                   	push   %ebp
f010274f:	89 e5                	mov    %esp,%ebp
f0102751:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102754:	ff 75 08             	pushl  0x8(%ebp)
f0102757:	e8 96 de ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f010275c:	83 c4 10             	add    $0x10,%esp
f010275f:	c9                   	leave  
f0102760:	c3                   	ret    

f0102761 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102761:	55                   	push   %ebp
f0102762:	89 e5                	mov    %esp,%ebp
f0102764:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102767:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010276e:	ff 75 0c             	pushl  0xc(%ebp)
f0102771:	ff 75 08             	pushl  0x8(%ebp)
f0102774:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102777:	50                   	push   %eax
f0102778:	68 4e 27 10 f0       	push   $0xf010274e
f010277d:	e8 c9 03 00 00       	call   f0102b4b <vprintfmt>
	return cnt;
}
f0102782:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102785:	c9                   	leave  
f0102786:	c3                   	ret    

f0102787 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102787:	55                   	push   %ebp
f0102788:	89 e5                	mov    %esp,%ebp
f010278a:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010278d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102790:	50                   	push   %eax
f0102791:	ff 75 08             	pushl  0x8(%ebp)
f0102794:	e8 c8 ff ff ff       	call   f0102761 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102799:	c9                   	leave  
f010279a:	c3                   	ret    

f010279b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010279b:	55                   	push   %ebp
f010279c:	89 e5                	mov    %esp,%ebp
f010279e:	57                   	push   %edi
f010279f:	56                   	push   %esi
f01027a0:	53                   	push   %ebx
f01027a1:	83 ec 14             	sub    $0x14,%esp
f01027a4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01027a7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01027aa:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01027ad:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01027b0:	8b 1a                	mov    (%edx),%ebx
f01027b2:	8b 01                	mov    (%ecx),%eax
f01027b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027b7:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01027be:	eb 7f                	jmp    f010283f <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01027c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01027c3:	01 d8                	add    %ebx,%eax
f01027c5:	89 c6                	mov    %eax,%esi
f01027c7:	c1 ee 1f             	shr    $0x1f,%esi
f01027ca:	01 c6                	add    %eax,%esi
f01027cc:	d1 fe                	sar    %esi
f01027ce:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01027d1:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027d4:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01027d7:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027d9:	eb 03                	jmp    f01027de <stab_binsearch+0x43>
			m--;
f01027db:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027de:	39 c3                	cmp    %eax,%ebx
f01027e0:	7f 0d                	jg     f01027ef <stab_binsearch+0x54>
f01027e2:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01027e6:	83 ea 0c             	sub    $0xc,%edx
f01027e9:	39 f9                	cmp    %edi,%ecx
f01027eb:	75 ee                	jne    f01027db <stab_binsearch+0x40>
f01027ed:	eb 05                	jmp    f01027f4 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01027ef:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01027f2:	eb 4b                	jmp    f010283f <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01027f4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027f7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027fa:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01027fe:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102801:	76 11                	jbe    f0102814 <stab_binsearch+0x79>
			*region_left = m;
f0102803:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102806:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102808:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010280b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102812:	eb 2b                	jmp    f010283f <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102814:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102817:	73 14                	jae    f010282d <stab_binsearch+0x92>
			*region_right = m - 1;
f0102819:	83 e8 01             	sub    $0x1,%eax
f010281c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010281f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102822:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102824:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010282b:	eb 12                	jmp    f010283f <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010282d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102830:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102832:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102836:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102838:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010283f:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102842:	0f 8e 78 ff ff ff    	jle    f01027c0 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102848:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010284c:	75 0f                	jne    f010285d <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010284e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102851:	8b 00                	mov    (%eax),%eax
f0102853:	83 e8 01             	sub    $0x1,%eax
f0102856:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102859:	89 06                	mov    %eax,(%esi)
f010285b:	eb 2c                	jmp    f0102889 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010285d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102860:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102862:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102865:	8b 0e                	mov    (%esi),%ecx
f0102867:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010286a:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010286d:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102870:	eb 03                	jmp    f0102875 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102872:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102875:	39 c8                	cmp    %ecx,%eax
f0102877:	7e 0b                	jle    f0102884 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102879:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010287d:	83 ea 0c             	sub    $0xc,%edx
f0102880:	39 df                	cmp    %ebx,%edi
f0102882:	75 ee                	jne    f0102872 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102884:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102887:	89 06                	mov    %eax,(%esi)
	}
}
f0102889:	83 c4 14             	add    $0x14,%esp
f010288c:	5b                   	pop    %ebx
f010288d:	5e                   	pop    %esi
f010288e:	5f                   	pop    %edi
f010288f:	5d                   	pop    %ebp
f0102890:	c3                   	ret    

f0102891 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102891:	55                   	push   %ebp
f0102892:	89 e5                	mov    %esp,%ebp
f0102894:	57                   	push   %edi
f0102895:	56                   	push   %esi
f0102896:	53                   	push   %ebx
f0102897:	83 ec 1c             	sub    $0x1c,%esp
f010289a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010289d:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01028a0:	c7 06 d0 46 10 f0    	movl   $0xf01046d0,(%esi)
	info->eip_line = 0;
f01028a6:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01028ad:	c7 46 08 d0 46 10 f0 	movl   $0xf01046d0,0x8(%esi)
	info->eip_fn_namelen = 9;
f01028b4:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01028bb:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01028be:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01028c5:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01028cb:	76 11                	jbe    f01028de <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028cd:	b8 0f c0 10 f0       	mov    $0xf010c00f,%eax
f01028d2:	3d 69 a2 10 f0       	cmp    $0xf010a269,%eax
f01028d7:	77 19                	ja     f01028f2 <debuginfo_eip+0x61>
f01028d9:	e9 62 01 00 00       	jmp    f0102a40 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01028de:	83 ec 04             	sub    $0x4,%esp
f01028e1:	68 da 46 10 f0       	push   $0xf01046da
f01028e6:	6a 7f                	push   $0x7f
f01028e8:	68 e7 46 10 f0       	push   $0xf01046e7
f01028ed:	e8 99 d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028f2:	80 3d 0e c0 10 f0 00 	cmpb   $0x0,0xf010c00e
f01028f9:	0f 85 48 01 00 00    	jne    f0102a47 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01028ff:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102906:	b8 68 a2 10 f0       	mov    $0xf010a268,%eax
f010290b:	2d 10 49 10 f0       	sub    $0xf0104910,%eax
f0102910:	c1 f8 02             	sar    $0x2,%eax
f0102913:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102919:	83 e8 01             	sub    $0x1,%eax
f010291c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010291f:	83 ec 08             	sub    $0x8,%esp
f0102922:	57                   	push   %edi
f0102923:	6a 64                	push   $0x64
f0102925:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102928:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010292b:	b8 10 49 10 f0       	mov    $0xf0104910,%eax
f0102930:	e8 66 fe ff ff       	call   f010279b <stab_binsearch>
	if (lfile == 0)
f0102935:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102938:	83 c4 10             	add    $0x10,%esp
f010293b:	85 c0                	test   %eax,%eax
f010293d:	0f 84 0b 01 00 00    	je     f0102a4e <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102943:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102946:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102949:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010294c:	83 ec 08             	sub    $0x8,%esp
f010294f:	57                   	push   %edi
f0102950:	6a 24                	push   $0x24
f0102952:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102955:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102958:	b8 10 49 10 f0       	mov    $0xf0104910,%eax
f010295d:	e8 39 fe ff ff       	call   f010279b <stab_binsearch>

	if (lfun <= rfun) {
f0102962:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102965:	83 c4 10             	add    $0x10,%esp
f0102968:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010296b:	7f 31                	jg     f010299e <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010296d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102970:	c1 e0 02             	shl    $0x2,%eax
f0102973:	8d 90 10 49 10 f0    	lea    -0xfefb6f0(%eax),%edx
f0102979:	8b 88 10 49 10 f0    	mov    -0xfefb6f0(%eax),%ecx
f010297f:	b8 0f c0 10 f0       	mov    $0xf010c00f,%eax
f0102984:	2d 69 a2 10 f0       	sub    $0xf010a269,%eax
f0102989:	39 c1                	cmp    %eax,%ecx
f010298b:	73 09                	jae    f0102996 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010298d:	81 c1 69 a2 10 f0    	add    $0xf010a269,%ecx
f0102993:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102996:	8b 42 08             	mov    0x8(%edx),%eax
f0102999:	89 46 10             	mov    %eax,0x10(%esi)
f010299c:	eb 06                	jmp    f01029a4 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010299e:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f01029a1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01029a4:	83 ec 08             	sub    $0x8,%esp
f01029a7:	6a 3a                	push   $0x3a
f01029a9:	ff 76 08             	pushl  0x8(%esi)
f01029ac:	e8 a3 08 00 00       	call   f0103254 <strfind>
f01029b1:	2b 46 08             	sub    0x8(%esi),%eax
f01029b4:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029b7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01029ba:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01029bd:	8d 04 85 10 49 10 f0 	lea    -0xfefb6f0(,%eax,4),%eax
f01029c4:	83 c4 10             	add    $0x10,%esp
f01029c7:	eb 06                	jmp    f01029cf <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01029c9:	83 eb 01             	sub    $0x1,%ebx
f01029cc:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029cf:	39 fb                	cmp    %edi,%ebx
f01029d1:	7c 34                	jl     f0102a07 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f01029d3:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01029d7:	80 fa 84             	cmp    $0x84,%dl
f01029da:	74 0b                	je     f01029e7 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01029dc:	80 fa 64             	cmp    $0x64,%dl
f01029df:	75 e8                	jne    f01029c9 <debuginfo_eip+0x138>
f01029e1:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01029e5:	74 e2                	je     f01029c9 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01029e7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01029ea:	8b 14 85 10 49 10 f0 	mov    -0xfefb6f0(,%eax,4),%edx
f01029f1:	b8 0f c0 10 f0       	mov    $0xf010c00f,%eax
f01029f6:	2d 69 a2 10 f0       	sub    $0xf010a269,%eax
f01029fb:	39 c2                	cmp    %eax,%edx
f01029fd:	73 08                	jae    f0102a07 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01029ff:	81 c2 69 a2 10 f0    	add    $0xf010a269,%edx
f0102a05:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a07:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102a0a:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a0d:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a12:	39 cb                	cmp    %ecx,%ebx
f0102a14:	7d 44                	jge    f0102a5a <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0102a16:	8d 53 01             	lea    0x1(%ebx),%edx
f0102a19:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102a1c:	8d 04 85 10 49 10 f0 	lea    -0xfefb6f0(,%eax,4),%eax
f0102a23:	eb 07                	jmp    f0102a2c <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a25:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102a29:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a2c:	39 ca                	cmp    %ecx,%edx
f0102a2e:	74 25                	je     f0102a55 <debuginfo_eip+0x1c4>
f0102a30:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a33:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0102a37:	74 ec                	je     f0102a25 <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a39:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a3e:	eb 1a                	jmp    f0102a5a <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a45:	eb 13                	jmp    f0102a5a <debuginfo_eip+0x1c9>
f0102a47:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a4c:	eb 0c                	jmp    f0102a5a <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a53:	eb 05                	jmp    f0102a5a <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a55:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a5a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a5d:	5b                   	pop    %ebx
f0102a5e:	5e                   	pop    %esi
f0102a5f:	5f                   	pop    %edi
f0102a60:	5d                   	pop    %ebp
f0102a61:	c3                   	ret    

f0102a62 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a62:	55                   	push   %ebp
f0102a63:	89 e5                	mov    %esp,%ebp
f0102a65:	57                   	push   %edi
f0102a66:	56                   	push   %esi
f0102a67:	53                   	push   %ebx
f0102a68:	83 ec 1c             	sub    $0x1c,%esp
f0102a6b:	89 c7                	mov    %eax,%edi
f0102a6d:	89 d6                	mov    %edx,%esi
f0102a6f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a72:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a75:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a78:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a7b:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a7e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a83:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a86:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102a89:	39 d3                	cmp    %edx,%ebx
f0102a8b:	72 05                	jb     f0102a92 <printnum+0x30>
f0102a8d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a90:	77 45                	ja     f0102ad7 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a92:	83 ec 0c             	sub    $0xc,%esp
f0102a95:	ff 75 18             	pushl  0x18(%ebp)
f0102a98:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a9b:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a9e:	53                   	push   %ebx
f0102a9f:	ff 75 10             	pushl  0x10(%ebp)
f0102aa2:	83 ec 08             	sub    $0x8,%esp
f0102aa5:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102aa8:	ff 75 e0             	pushl  -0x20(%ebp)
f0102aab:	ff 75 dc             	pushl  -0x24(%ebp)
f0102aae:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ab1:	e8 ca 09 00 00       	call   f0103480 <__udivdi3>
f0102ab6:	83 c4 18             	add    $0x18,%esp
f0102ab9:	52                   	push   %edx
f0102aba:	50                   	push   %eax
f0102abb:	89 f2                	mov    %esi,%edx
f0102abd:	89 f8                	mov    %edi,%eax
f0102abf:	e8 9e ff ff ff       	call   f0102a62 <printnum>
f0102ac4:	83 c4 20             	add    $0x20,%esp
f0102ac7:	eb 18                	jmp    f0102ae1 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102ac9:	83 ec 08             	sub    $0x8,%esp
f0102acc:	56                   	push   %esi
f0102acd:	ff 75 18             	pushl  0x18(%ebp)
f0102ad0:	ff d7                	call   *%edi
f0102ad2:	83 c4 10             	add    $0x10,%esp
f0102ad5:	eb 03                	jmp    f0102ada <printnum+0x78>
f0102ad7:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102ada:	83 eb 01             	sub    $0x1,%ebx
f0102add:	85 db                	test   %ebx,%ebx
f0102adf:	7f e8                	jg     f0102ac9 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102ae1:	83 ec 08             	sub    $0x8,%esp
f0102ae4:	56                   	push   %esi
f0102ae5:	83 ec 04             	sub    $0x4,%esp
f0102ae8:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102aeb:	ff 75 e0             	pushl  -0x20(%ebp)
f0102aee:	ff 75 dc             	pushl  -0x24(%ebp)
f0102af1:	ff 75 d8             	pushl  -0x28(%ebp)
f0102af4:	e8 b7 0a 00 00       	call   f01035b0 <__umoddi3>
f0102af9:	83 c4 14             	add    $0x14,%esp
f0102afc:	0f be 80 f5 46 10 f0 	movsbl -0xfefb90b(%eax),%eax
f0102b03:	50                   	push   %eax
f0102b04:	ff d7                	call   *%edi
}
f0102b06:	83 c4 10             	add    $0x10,%esp
f0102b09:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b0c:	5b                   	pop    %ebx
f0102b0d:	5e                   	pop    %esi
f0102b0e:	5f                   	pop    %edi
f0102b0f:	5d                   	pop    %ebp
f0102b10:	c3                   	ret    

f0102b11 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b11:	55                   	push   %ebp
f0102b12:	89 e5                	mov    %esp,%ebp
f0102b14:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b17:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b1b:	8b 10                	mov    (%eax),%edx
f0102b1d:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b20:	73 0a                	jae    f0102b2c <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b22:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b25:	89 08                	mov    %ecx,(%eax)
f0102b27:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b2a:	88 02                	mov    %al,(%edx)
}
f0102b2c:	5d                   	pop    %ebp
f0102b2d:	c3                   	ret    

f0102b2e <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b2e:	55                   	push   %ebp
f0102b2f:	89 e5                	mov    %esp,%ebp
f0102b31:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b34:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b37:	50                   	push   %eax
f0102b38:	ff 75 10             	pushl  0x10(%ebp)
f0102b3b:	ff 75 0c             	pushl  0xc(%ebp)
f0102b3e:	ff 75 08             	pushl  0x8(%ebp)
f0102b41:	e8 05 00 00 00       	call   f0102b4b <vprintfmt>
	va_end(ap);
}
f0102b46:	83 c4 10             	add    $0x10,%esp
f0102b49:	c9                   	leave  
f0102b4a:	c3                   	ret    

f0102b4b <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b4b:	55                   	push   %ebp
f0102b4c:	89 e5                	mov    %esp,%ebp
f0102b4e:	57                   	push   %edi
f0102b4f:	56                   	push   %esi
f0102b50:	53                   	push   %ebx
f0102b51:	83 ec 2c             	sub    $0x2c,%esp
f0102b54:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b57:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b5a:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b5d:	eb 12                	jmp    f0102b71 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b5f:	85 c0                	test   %eax,%eax
f0102b61:	0f 84 42 04 00 00    	je     f0102fa9 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0102b67:	83 ec 08             	sub    $0x8,%esp
f0102b6a:	53                   	push   %ebx
f0102b6b:	50                   	push   %eax
f0102b6c:	ff d6                	call   *%esi
f0102b6e:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b71:	83 c7 01             	add    $0x1,%edi
f0102b74:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b78:	83 f8 25             	cmp    $0x25,%eax
f0102b7b:	75 e2                	jne    f0102b5f <vprintfmt+0x14>
f0102b7d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102b81:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102b88:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b8f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102b96:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102b9b:	eb 07                	jmp    f0102ba4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b9d:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102ba0:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ba4:	8d 47 01             	lea    0x1(%edi),%eax
f0102ba7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102baa:	0f b6 07             	movzbl (%edi),%eax
f0102bad:	0f b6 d0             	movzbl %al,%edx
f0102bb0:	83 e8 23             	sub    $0x23,%eax
f0102bb3:	3c 55                	cmp    $0x55,%al
f0102bb5:	0f 87 d3 03 00 00    	ja     f0102f8e <vprintfmt+0x443>
f0102bbb:	0f b6 c0             	movzbl %al,%eax
f0102bbe:	ff 24 85 80 47 10 f0 	jmp    *-0xfefb880(,%eax,4)
f0102bc5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102bc8:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102bcc:	eb d6                	jmp    f0102ba4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bd1:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bd6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102bd9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102bdc:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102be0:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102be3:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102be6:	83 f9 09             	cmp    $0x9,%ecx
f0102be9:	77 3f                	ja     f0102c2a <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102beb:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102bee:	eb e9                	jmp    f0102bd9 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102bf0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bf3:	8b 00                	mov    (%eax),%eax
f0102bf5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102bf8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bfb:	8d 40 04             	lea    0x4(%eax),%eax
f0102bfe:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c01:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c04:	eb 2a                	jmp    f0102c30 <vprintfmt+0xe5>
f0102c06:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c09:	85 c0                	test   %eax,%eax
f0102c0b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c10:	0f 49 d0             	cmovns %eax,%edx
f0102c13:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c16:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c19:	eb 89                	jmp    f0102ba4 <vprintfmt+0x59>
f0102c1b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c1e:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c25:	e9 7a ff ff ff       	jmp    f0102ba4 <vprintfmt+0x59>
f0102c2a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102c2d:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c30:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c34:	0f 89 6a ff ff ff    	jns    f0102ba4 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c3a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c3d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c40:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c47:	e9 58 ff ff ff       	jmp    f0102ba4 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c4c:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c4f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c52:	e9 4d ff ff ff       	jmp    f0102ba4 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c57:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c5a:	8d 78 04             	lea    0x4(%eax),%edi
f0102c5d:	83 ec 08             	sub    $0x8,%esp
f0102c60:	53                   	push   %ebx
f0102c61:	ff 30                	pushl  (%eax)
f0102c63:	ff d6                	call   *%esi
			break;
f0102c65:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c68:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c6b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c6e:	e9 fe fe ff ff       	jmp    f0102b71 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c73:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c76:	8d 78 04             	lea    0x4(%eax),%edi
f0102c79:	8b 00                	mov    (%eax),%eax
f0102c7b:	99                   	cltd   
f0102c7c:	31 d0                	xor    %edx,%eax
f0102c7e:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102c80:	83 f8 07             	cmp    $0x7,%eax
f0102c83:	7f 0b                	jg     f0102c90 <vprintfmt+0x145>
f0102c85:	8b 14 85 e0 48 10 f0 	mov    -0xfefb720(,%eax,4),%edx
f0102c8c:	85 d2                	test   %edx,%edx
f0102c8e:	75 1b                	jne    f0102cab <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102c90:	50                   	push   %eax
f0102c91:	68 0d 47 10 f0       	push   $0xf010470d
f0102c96:	53                   	push   %ebx
f0102c97:	56                   	push   %esi
f0102c98:	e8 91 fe ff ff       	call   f0102b2e <printfmt>
f0102c9d:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102ca0:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ca3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102ca6:	e9 c6 fe ff ff       	jmp    f0102b71 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102cab:	52                   	push   %edx
f0102cac:	68 ab 3c 10 f0       	push   $0xf0103cab
f0102cb1:	53                   	push   %ebx
f0102cb2:	56                   	push   %esi
f0102cb3:	e8 76 fe ff ff       	call   f0102b2e <printfmt>
f0102cb8:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102cbb:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cbe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cc1:	e9 ab fe ff ff       	jmp    f0102b71 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102cc6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cc9:	83 c0 04             	add    $0x4,%eax
f0102ccc:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102ccf:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cd2:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102cd4:	85 ff                	test   %edi,%edi
f0102cd6:	b8 06 47 10 f0       	mov    $0xf0104706,%eax
f0102cdb:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102cde:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102ce2:	0f 8e 94 00 00 00    	jle    f0102d7c <vprintfmt+0x231>
f0102ce8:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102cec:	0f 84 98 00 00 00    	je     f0102d8a <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cf2:	83 ec 08             	sub    $0x8,%esp
f0102cf5:	ff 75 d0             	pushl  -0x30(%ebp)
f0102cf8:	57                   	push   %edi
f0102cf9:	e8 0c 04 00 00       	call   f010310a <strnlen>
f0102cfe:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d01:	29 c1                	sub    %eax,%ecx
f0102d03:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102d06:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d09:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d0d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d10:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d13:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d15:	eb 0f                	jmp    f0102d26 <vprintfmt+0x1db>
					putch(padc, putdat);
f0102d17:	83 ec 08             	sub    $0x8,%esp
f0102d1a:	53                   	push   %ebx
f0102d1b:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d1e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d20:	83 ef 01             	sub    $0x1,%edi
f0102d23:	83 c4 10             	add    $0x10,%esp
f0102d26:	85 ff                	test   %edi,%edi
f0102d28:	7f ed                	jg     f0102d17 <vprintfmt+0x1cc>
f0102d2a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d2d:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102d30:	85 c9                	test   %ecx,%ecx
f0102d32:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d37:	0f 49 c1             	cmovns %ecx,%eax
f0102d3a:	29 c1                	sub    %eax,%ecx
f0102d3c:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d3f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d42:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d45:	89 cb                	mov    %ecx,%ebx
f0102d47:	eb 4d                	jmp    f0102d96 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d49:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d4d:	74 1b                	je     f0102d6a <vprintfmt+0x21f>
f0102d4f:	0f be c0             	movsbl %al,%eax
f0102d52:	83 e8 20             	sub    $0x20,%eax
f0102d55:	83 f8 5e             	cmp    $0x5e,%eax
f0102d58:	76 10                	jbe    f0102d6a <vprintfmt+0x21f>
					putch('?', putdat);
f0102d5a:	83 ec 08             	sub    $0x8,%esp
f0102d5d:	ff 75 0c             	pushl  0xc(%ebp)
f0102d60:	6a 3f                	push   $0x3f
f0102d62:	ff 55 08             	call   *0x8(%ebp)
f0102d65:	83 c4 10             	add    $0x10,%esp
f0102d68:	eb 0d                	jmp    f0102d77 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102d6a:	83 ec 08             	sub    $0x8,%esp
f0102d6d:	ff 75 0c             	pushl  0xc(%ebp)
f0102d70:	52                   	push   %edx
f0102d71:	ff 55 08             	call   *0x8(%ebp)
f0102d74:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d77:	83 eb 01             	sub    $0x1,%ebx
f0102d7a:	eb 1a                	jmp    f0102d96 <vprintfmt+0x24b>
f0102d7c:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d7f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d82:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d85:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d88:	eb 0c                	jmp    f0102d96 <vprintfmt+0x24b>
f0102d8a:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d8d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d90:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d93:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d96:	83 c7 01             	add    $0x1,%edi
f0102d99:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d9d:	0f be d0             	movsbl %al,%edx
f0102da0:	85 d2                	test   %edx,%edx
f0102da2:	74 23                	je     f0102dc7 <vprintfmt+0x27c>
f0102da4:	85 f6                	test   %esi,%esi
f0102da6:	78 a1                	js     f0102d49 <vprintfmt+0x1fe>
f0102da8:	83 ee 01             	sub    $0x1,%esi
f0102dab:	79 9c                	jns    f0102d49 <vprintfmt+0x1fe>
f0102dad:	89 df                	mov    %ebx,%edi
f0102daf:	8b 75 08             	mov    0x8(%ebp),%esi
f0102db2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102db5:	eb 18                	jmp    f0102dcf <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102db7:	83 ec 08             	sub    $0x8,%esp
f0102dba:	53                   	push   %ebx
f0102dbb:	6a 20                	push   $0x20
f0102dbd:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102dbf:	83 ef 01             	sub    $0x1,%edi
f0102dc2:	83 c4 10             	add    $0x10,%esp
f0102dc5:	eb 08                	jmp    f0102dcf <vprintfmt+0x284>
f0102dc7:	89 df                	mov    %ebx,%edi
f0102dc9:	8b 75 08             	mov    0x8(%ebp),%esi
f0102dcc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102dcf:	85 ff                	test   %edi,%edi
f0102dd1:	7f e4                	jg     f0102db7 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102dd3:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102dd6:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dd9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ddc:	e9 90 fd ff ff       	jmp    f0102b71 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102de1:	83 f9 01             	cmp    $0x1,%ecx
f0102de4:	7e 19                	jle    f0102dff <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102de6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102de9:	8b 50 04             	mov    0x4(%eax),%edx
f0102dec:	8b 00                	mov    (%eax),%eax
f0102dee:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102df1:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102df4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102df7:	8d 40 08             	lea    0x8(%eax),%eax
f0102dfa:	89 45 14             	mov    %eax,0x14(%ebp)
f0102dfd:	eb 38                	jmp    f0102e37 <vprintfmt+0x2ec>
	else if (lflag)
f0102dff:	85 c9                	test   %ecx,%ecx
f0102e01:	74 1b                	je     f0102e1e <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102e03:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e06:	8b 00                	mov    (%eax),%eax
f0102e08:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e0b:	89 c1                	mov    %eax,%ecx
f0102e0d:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e10:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e13:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e16:	8d 40 04             	lea    0x4(%eax),%eax
f0102e19:	89 45 14             	mov    %eax,0x14(%ebp)
f0102e1c:	eb 19                	jmp    f0102e37 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102e1e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e21:	8b 00                	mov    (%eax),%eax
f0102e23:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e26:	89 c1                	mov    %eax,%ecx
f0102e28:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e2b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e2e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e31:	8d 40 04             	lea    0x4(%eax),%eax
f0102e34:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e37:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e3a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e3d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e42:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e46:	0f 89 0e 01 00 00    	jns    f0102f5a <vprintfmt+0x40f>
				putch('-', putdat);
f0102e4c:	83 ec 08             	sub    $0x8,%esp
f0102e4f:	53                   	push   %ebx
f0102e50:	6a 2d                	push   $0x2d
f0102e52:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e54:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e57:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102e5a:	f7 da                	neg    %edx
f0102e5c:	83 d1 00             	adc    $0x0,%ecx
f0102e5f:	f7 d9                	neg    %ecx
f0102e61:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e64:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e69:	e9 ec 00 00 00       	jmp    f0102f5a <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e6e:	83 f9 01             	cmp    $0x1,%ecx
f0102e71:	7e 18                	jle    f0102e8b <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102e73:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e76:	8b 10                	mov    (%eax),%edx
f0102e78:	8b 48 04             	mov    0x4(%eax),%ecx
f0102e7b:	8d 40 08             	lea    0x8(%eax),%eax
f0102e7e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102e81:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e86:	e9 cf 00 00 00       	jmp    f0102f5a <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102e8b:	85 c9                	test   %ecx,%ecx
f0102e8d:	74 1a                	je     f0102ea9 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102e8f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e92:	8b 10                	mov    (%eax),%edx
f0102e94:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102e99:	8d 40 04             	lea    0x4(%eax),%eax
f0102e9c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102e9f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ea4:	e9 b1 00 00 00       	jmp    f0102f5a <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102ea9:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eac:	8b 10                	mov    (%eax),%edx
f0102eae:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102eb3:	8d 40 04             	lea    0x4(%eax),%eax
f0102eb6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102eb9:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ebe:	e9 97 00 00 00       	jmp    f0102f5a <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0102ec3:	83 ec 08             	sub    $0x8,%esp
f0102ec6:	53                   	push   %ebx
f0102ec7:	6a 58                	push   $0x58
f0102ec9:	ff d6                	call   *%esi
			putch('X', putdat);
f0102ecb:	83 c4 08             	add    $0x8,%esp
f0102ece:	53                   	push   %ebx
f0102ecf:	6a 58                	push   $0x58
f0102ed1:	ff d6                	call   *%esi
			putch('X', putdat);
f0102ed3:	83 c4 08             	add    $0x8,%esp
f0102ed6:	53                   	push   %ebx
f0102ed7:	6a 58                	push   $0x58
f0102ed9:	ff d6                	call   *%esi
			break;
f0102edb:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ede:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0102ee1:	e9 8b fc ff ff       	jmp    f0102b71 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0102ee6:	83 ec 08             	sub    $0x8,%esp
f0102ee9:	53                   	push   %ebx
f0102eea:	6a 30                	push   $0x30
f0102eec:	ff d6                	call   *%esi
			putch('x', putdat);
f0102eee:	83 c4 08             	add    $0x8,%esp
f0102ef1:	53                   	push   %ebx
f0102ef2:	6a 78                	push   $0x78
f0102ef4:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102ef6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ef9:	8b 10                	mov    (%eax),%edx
f0102efb:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102f00:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102f03:	8d 40 04             	lea    0x4(%eax),%eax
f0102f06:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102f09:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102f0e:	eb 4a                	jmp    f0102f5a <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102f10:	83 f9 01             	cmp    $0x1,%ecx
f0102f13:	7e 15                	jle    f0102f2a <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0102f15:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f18:	8b 10                	mov    (%eax),%edx
f0102f1a:	8b 48 04             	mov    0x4(%eax),%ecx
f0102f1d:	8d 40 08             	lea    0x8(%eax),%eax
f0102f20:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f23:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f28:	eb 30                	jmp    f0102f5a <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102f2a:	85 c9                	test   %ecx,%ecx
f0102f2c:	74 17                	je     f0102f45 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0102f2e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f31:	8b 10                	mov    (%eax),%edx
f0102f33:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f38:	8d 40 04             	lea    0x4(%eax),%eax
f0102f3b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f3e:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f43:	eb 15                	jmp    f0102f5a <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102f45:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f48:	8b 10                	mov    (%eax),%edx
f0102f4a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f4f:	8d 40 04             	lea    0x4(%eax),%eax
f0102f52:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f55:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102f5a:	83 ec 0c             	sub    $0xc,%esp
f0102f5d:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102f61:	57                   	push   %edi
f0102f62:	ff 75 e0             	pushl  -0x20(%ebp)
f0102f65:	50                   	push   %eax
f0102f66:	51                   	push   %ecx
f0102f67:	52                   	push   %edx
f0102f68:	89 da                	mov    %ebx,%edx
f0102f6a:	89 f0                	mov    %esi,%eax
f0102f6c:	e8 f1 fa ff ff       	call   f0102a62 <printnum>
			break;
f0102f71:	83 c4 20             	add    $0x20,%esp
f0102f74:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f77:	e9 f5 fb ff ff       	jmp    f0102b71 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102f7c:	83 ec 08             	sub    $0x8,%esp
f0102f7f:	53                   	push   %ebx
f0102f80:	52                   	push   %edx
f0102f81:	ff d6                	call   *%esi
			break;
f0102f83:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f86:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102f89:	e9 e3 fb ff ff       	jmp    f0102b71 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102f8e:	83 ec 08             	sub    $0x8,%esp
f0102f91:	53                   	push   %ebx
f0102f92:	6a 25                	push   $0x25
f0102f94:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102f96:	83 c4 10             	add    $0x10,%esp
f0102f99:	eb 03                	jmp    f0102f9e <vprintfmt+0x453>
f0102f9b:	83 ef 01             	sub    $0x1,%edi
f0102f9e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102fa2:	75 f7                	jne    f0102f9b <vprintfmt+0x450>
f0102fa4:	e9 c8 fb ff ff       	jmp    f0102b71 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102fa9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fac:	5b                   	pop    %ebx
f0102fad:	5e                   	pop    %esi
f0102fae:	5f                   	pop    %edi
f0102faf:	5d                   	pop    %ebp
f0102fb0:	c3                   	ret    

f0102fb1 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102fb1:	55                   	push   %ebp
f0102fb2:	89 e5                	mov    %esp,%ebp
f0102fb4:	83 ec 18             	sub    $0x18,%esp
f0102fb7:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fba:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102fbd:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102fc0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102fc4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102fc7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102fce:	85 c0                	test   %eax,%eax
f0102fd0:	74 26                	je     f0102ff8 <vsnprintf+0x47>
f0102fd2:	85 d2                	test   %edx,%edx
f0102fd4:	7e 22                	jle    f0102ff8 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102fd6:	ff 75 14             	pushl  0x14(%ebp)
f0102fd9:	ff 75 10             	pushl  0x10(%ebp)
f0102fdc:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102fdf:	50                   	push   %eax
f0102fe0:	68 11 2b 10 f0       	push   $0xf0102b11
f0102fe5:	e8 61 fb ff ff       	call   f0102b4b <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102fea:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102fed:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102ff0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102ff3:	83 c4 10             	add    $0x10,%esp
f0102ff6:	eb 05                	jmp    f0102ffd <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102ff8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102ffd:	c9                   	leave  
f0102ffe:	c3                   	ret    

f0102fff <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102fff:	55                   	push   %ebp
f0103000:	89 e5                	mov    %esp,%ebp
f0103002:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103005:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103008:	50                   	push   %eax
f0103009:	ff 75 10             	pushl  0x10(%ebp)
f010300c:	ff 75 0c             	pushl  0xc(%ebp)
f010300f:	ff 75 08             	pushl  0x8(%ebp)
f0103012:	e8 9a ff ff ff       	call   f0102fb1 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103017:	c9                   	leave  
f0103018:	c3                   	ret    

f0103019 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103019:	55                   	push   %ebp
f010301a:	89 e5                	mov    %esp,%ebp
f010301c:	57                   	push   %edi
f010301d:	56                   	push   %esi
f010301e:	53                   	push   %ebx
f010301f:	83 ec 0c             	sub    $0xc,%esp
f0103022:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103025:	85 c0                	test   %eax,%eax
f0103027:	74 11                	je     f010303a <readline+0x21>
		cprintf("%s", prompt);
f0103029:	83 ec 08             	sub    $0x8,%esp
f010302c:	50                   	push   %eax
f010302d:	68 ab 3c 10 f0       	push   $0xf0103cab
f0103032:	e8 50 f7 ff ff       	call   f0102787 <cprintf>
f0103037:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010303a:	83 ec 0c             	sub    $0xc,%esp
f010303d:	6a 00                	push   $0x0
f010303f:	e8 cf d5 ff ff       	call   f0100613 <iscons>
f0103044:	89 c7                	mov    %eax,%edi
f0103046:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103049:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010304e:	e8 af d5 ff ff       	call   f0100602 <getchar>
f0103053:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103055:	85 c0                	test   %eax,%eax
f0103057:	79 18                	jns    f0103071 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103059:	83 ec 08             	sub    $0x8,%esp
f010305c:	50                   	push   %eax
f010305d:	68 00 49 10 f0       	push   $0xf0104900
f0103062:	e8 20 f7 ff ff       	call   f0102787 <cprintf>
			return NULL;
f0103067:	83 c4 10             	add    $0x10,%esp
f010306a:	b8 00 00 00 00       	mov    $0x0,%eax
f010306f:	eb 79                	jmp    f01030ea <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103071:	83 f8 08             	cmp    $0x8,%eax
f0103074:	0f 94 c2             	sete   %dl
f0103077:	83 f8 7f             	cmp    $0x7f,%eax
f010307a:	0f 94 c0             	sete   %al
f010307d:	08 c2                	or     %al,%dl
f010307f:	74 1a                	je     f010309b <readline+0x82>
f0103081:	85 f6                	test   %esi,%esi
f0103083:	7e 16                	jle    f010309b <readline+0x82>
			if (echoing)
f0103085:	85 ff                	test   %edi,%edi
f0103087:	74 0d                	je     f0103096 <readline+0x7d>
				cputchar('\b');
f0103089:	83 ec 0c             	sub    $0xc,%esp
f010308c:	6a 08                	push   $0x8
f010308e:	e8 5f d5 ff ff       	call   f01005f2 <cputchar>
f0103093:	83 c4 10             	add    $0x10,%esp
			i--;
f0103096:	83 ee 01             	sub    $0x1,%esi
f0103099:	eb b3                	jmp    f010304e <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010309b:	83 fb 1f             	cmp    $0x1f,%ebx
f010309e:	7e 23                	jle    f01030c3 <readline+0xaa>
f01030a0:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01030a6:	7f 1b                	jg     f01030c3 <readline+0xaa>
			if (echoing)
f01030a8:	85 ff                	test   %edi,%edi
f01030aa:	74 0c                	je     f01030b8 <readline+0x9f>
				cputchar(c);
f01030ac:	83 ec 0c             	sub    $0xc,%esp
f01030af:	53                   	push   %ebx
f01030b0:	e8 3d d5 ff ff       	call   f01005f2 <cputchar>
f01030b5:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01030b8:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f01030be:	8d 76 01             	lea    0x1(%esi),%esi
f01030c1:	eb 8b                	jmp    f010304e <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01030c3:	83 fb 0a             	cmp    $0xa,%ebx
f01030c6:	74 05                	je     f01030cd <readline+0xb4>
f01030c8:	83 fb 0d             	cmp    $0xd,%ebx
f01030cb:	75 81                	jne    f010304e <readline+0x35>
			if (echoing)
f01030cd:	85 ff                	test   %edi,%edi
f01030cf:	74 0d                	je     f01030de <readline+0xc5>
				cputchar('\n');
f01030d1:	83 ec 0c             	sub    $0xc,%esp
f01030d4:	6a 0a                	push   $0xa
f01030d6:	e8 17 d5 ff ff       	call   f01005f2 <cputchar>
f01030db:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01030de:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f01030e5:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f01030ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030ed:	5b                   	pop    %ebx
f01030ee:	5e                   	pop    %esi
f01030ef:	5f                   	pop    %edi
f01030f0:	5d                   	pop    %ebp
f01030f1:	c3                   	ret    

f01030f2 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01030f2:	55                   	push   %ebp
f01030f3:	89 e5                	mov    %esp,%ebp
f01030f5:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01030f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01030fd:	eb 03                	jmp    f0103102 <strlen+0x10>
		n++;
f01030ff:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103102:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103106:	75 f7                	jne    f01030ff <strlen+0xd>
		n++;
	return n;
}
f0103108:	5d                   	pop    %ebp
f0103109:	c3                   	ret    

f010310a <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010310a:	55                   	push   %ebp
f010310b:	89 e5                	mov    %esp,%ebp
f010310d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103110:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103113:	ba 00 00 00 00       	mov    $0x0,%edx
f0103118:	eb 03                	jmp    f010311d <strnlen+0x13>
		n++;
f010311a:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010311d:	39 c2                	cmp    %eax,%edx
f010311f:	74 08                	je     f0103129 <strnlen+0x1f>
f0103121:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103125:	75 f3                	jne    f010311a <strnlen+0x10>
f0103127:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103129:	5d                   	pop    %ebp
f010312a:	c3                   	ret    

f010312b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010312b:	55                   	push   %ebp
f010312c:	89 e5                	mov    %esp,%ebp
f010312e:	53                   	push   %ebx
f010312f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103132:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103135:	89 c2                	mov    %eax,%edx
f0103137:	83 c2 01             	add    $0x1,%edx
f010313a:	83 c1 01             	add    $0x1,%ecx
f010313d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103141:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103144:	84 db                	test   %bl,%bl
f0103146:	75 ef                	jne    f0103137 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103148:	5b                   	pop    %ebx
f0103149:	5d                   	pop    %ebp
f010314a:	c3                   	ret    

f010314b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010314b:	55                   	push   %ebp
f010314c:	89 e5                	mov    %esp,%ebp
f010314e:	53                   	push   %ebx
f010314f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103152:	53                   	push   %ebx
f0103153:	e8 9a ff ff ff       	call   f01030f2 <strlen>
f0103158:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010315b:	ff 75 0c             	pushl  0xc(%ebp)
f010315e:	01 d8                	add    %ebx,%eax
f0103160:	50                   	push   %eax
f0103161:	e8 c5 ff ff ff       	call   f010312b <strcpy>
	return dst;
}
f0103166:	89 d8                	mov    %ebx,%eax
f0103168:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010316b:	c9                   	leave  
f010316c:	c3                   	ret    

f010316d <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010316d:	55                   	push   %ebp
f010316e:	89 e5                	mov    %esp,%ebp
f0103170:	56                   	push   %esi
f0103171:	53                   	push   %ebx
f0103172:	8b 75 08             	mov    0x8(%ebp),%esi
f0103175:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103178:	89 f3                	mov    %esi,%ebx
f010317a:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010317d:	89 f2                	mov    %esi,%edx
f010317f:	eb 0f                	jmp    f0103190 <strncpy+0x23>
		*dst++ = *src;
f0103181:	83 c2 01             	add    $0x1,%edx
f0103184:	0f b6 01             	movzbl (%ecx),%eax
f0103187:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010318a:	80 39 01             	cmpb   $0x1,(%ecx)
f010318d:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103190:	39 da                	cmp    %ebx,%edx
f0103192:	75 ed                	jne    f0103181 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103194:	89 f0                	mov    %esi,%eax
f0103196:	5b                   	pop    %ebx
f0103197:	5e                   	pop    %esi
f0103198:	5d                   	pop    %ebp
f0103199:	c3                   	ret    

f010319a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010319a:	55                   	push   %ebp
f010319b:	89 e5                	mov    %esp,%ebp
f010319d:	56                   	push   %esi
f010319e:	53                   	push   %ebx
f010319f:	8b 75 08             	mov    0x8(%ebp),%esi
f01031a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031a5:	8b 55 10             	mov    0x10(%ebp),%edx
f01031a8:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01031aa:	85 d2                	test   %edx,%edx
f01031ac:	74 21                	je     f01031cf <strlcpy+0x35>
f01031ae:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01031b2:	89 f2                	mov    %esi,%edx
f01031b4:	eb 09                	jmp    f01031bf <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01031b6:	83 c2 01             	add    $0x1,%edx
f01031b9:	83 c1 01             	add    $0x1,%ecx
f01031bc:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01031bf:	39 c2                	cmp    %eax,%edx
f01031c1:	74 09                	je     f01031cc <strlcpy+0x32>
f01031c3:	0f b6 19             	movzbl (%ecx),%ebx
f01031c6:	84 db                	test   %bl,%bl
f01031c8:	75 ec                	jne    f01031b6 <strlcpy+0x1c>
f01031ca:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01031cc:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01031cf:	29 f0                	sub    %esi,%eax
}
f01031d1:	5b                   	pop    %ebx
f01031d2:	5e                   	pop    %esi
f01031d3:	5d                   	pop    %ebp
f01031d4:	c3                   	ret    

f01031d5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01031d5:	55                   	push   %ebp
f01031d6:	89 e5                	mov    %esp,%ebp
f01031d8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031db:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01031de:	eb 06                	jmp    f01031e6 <strcmp+0x11>
		p++, q++;
f01031e0:	83 c1 01             	add    $0x1,%ecx
f01031e3:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01031e6:	0f b6 01             	movzbl (%ecx),%eax
f01031e9:	84 c0                	test   %al,%al
f01031eb:	74 04                	je     f01031f1 <strcmp+0x1c>
f01031ed:	3a 02                	cmp    (%edx),%al
f01031ef:	74 ef                	je     f01031e0 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01031f1:	0f b6 c0             	movzbl %al,%eax
f01031f4:	0f b6 12             	movzbl (%edx),%edx
f01031f7:	29 d0                	sub    %edx,%eax
}
f01031f9:	5d                   	pop    %ebp
f01031fa:	c3                   	ret    

f01031fb <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01031fb:	55                   	push   %ebp
f01031fc:	89 e5                	mov    %esp,%ebp
f01031fe:	53                   	push   %ebx
f01031ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0103202:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103205:	89 c3                	mov    %eax,%ebx
f0103207:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010320a:	eb 06                	jmp    f0103212 <strncmp+0x17>
		n--, p++, q++;
f010320c:	83 c0 01             	add    $0x1,%eax
f010320f:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103212:	39 d8                	cmp    %ebx,%eax
f0103214:	74 15                	je     f010322b <strncmp+0x30>
f0103216:	0f b6 08             	movzbl (%eax),%ecx
f0103219:	84 c9                	test   %cl,%cl
f010321b:	74 04                	je     f0103221 <strncmp+0x26>
f010321d:	3a 0a                	cmp    (%edx),%cl
f010321f:	74 eb                	je     f010320c <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103221:	0f b6 00             	movzbl (%eax),%eax
f0103224:	0f b6 12             	movzbl (%edx),%edx
f0103227:	29 d0                	sub    %edx,%eax
f0103229:	eb 05                	jmp    f0103230 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010322b:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103230:	5b                   	pop    %ebx
f0103231:	5d                   	pop    %ebp
f0103232:	c3                   	ret    

f0103233 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103233:	55                   	push   %ebp
f0103234:	89 e5                	mov    %esp,%ebp
f0103236:	8b 45 08             	mov    0x8(%ebp),%eax
f0103239:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010323d:	eb 07                	jmp    f0103246 <strchr+0x13>
		if (*s == c)
f010323f:	38 ca                	cmp    %cl,%dl
f0103241:	74 0f                	je     f0103252 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103243:	83 c0 01             	add    $0x1,%eax
f0103246:	0f b6 10             	movzbl (%eax),%edx
f0103249:	84 d2                	test   %dl,%dl
f010324b:	75 f2                	jne    f010323f <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010324d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103252:	5d                   	pop    %ebp
f0103253:	c3                   	ret    

f0103254 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103254:	55                   	push   %ebp
f0103255:	89 e5                	mov    %esp,%ebp
f0103257:	8b 45 08             	mov    0x8(%ebp),%eax
f010325a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010325e:	eb 03                	jmp    f0103263 <strfind+0xf>
f0103260:	83 c0 01             	add    $0x1,%eax
f0103263:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103266:	38 ca                	cmp    %cl,%dl
f0103268:	74 04                	je     f010326e <strfind+0x1a>
f010326a:	84 d2                	test   %dl,%dl
f010326c:	75 f2                	jne    f0103260 <strfind+0xc>
			break;
	return (char *) s;
}
f010326e:	5d                   	pop    %ebp
f010326f:	c3                   	ret    

f0103270 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103270:	55                   	push   %ebp
f0103271:	89 e5                	mov    %esp,%ebp
f0103273:	57                   	push   %edi
f0103274:	56                   	push   %esi
f0103275:	53                   	push   %ebx
f0103276:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103279:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010327c:	85 c9                	test   %ecx,%ecx
f010327e:	74 36                	je     f01032b6 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103280:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103286:	75 28                	jne    f01032b0 <memset+0x40>
f0103288:	f6 c1 03             	test   $0x3,%cl
f010328b:	75 23                	jne    f01032b0 <memset+0x40>
		c &= 0xFF;
f010328d:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103291:	89 d3                	mov    %edx,%ebx
f0103293:	c1 e3 08             	shl    $0x8,%ebx
f0103296:	89 d6                	mov    %edx,%esi
f0103298:	c1 e6 18             	shl    $0x18,%esi
f010329b:	89 d0                	mov    %edx,%eax
f010329d:	c1 e0 10             	shl    $0x10,%eax
f01032a0:	09 f0                	or     %esi,%eax
f01032a2:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01032a4:	89 d8                	mov    %ebx,%eax
f01032a6:	09 d0                	or     %edx,%eax
f01032a8:	c1 e9 02             	shr    $0x2,%ecx
f01032ab:	fc                   	cld    
f01032ac:	f3 ab                	rep stos %eax,%es:(%edi)
f01032ae:	eb 06                	jmp    f01032b6 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01032b0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032b3:	fc                   	cld    
f01032b4:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01032b6:	89 f8                	mov    %edi,%eax
f01032b8:	5b                   	pop    %ebx
f01032b9:	5e                   	pop    %esi
f01032ba:	5f                   	pop    %edi
f01032bb:	5d                   	pop    %ebp
f01032bc:	c3                   	ret    

f01032bd <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01032bd:	55                   	push   %ebp
f01032be:	89 e5                	mov    %esp,%ebp
f01032c0:	57                   	push   %edi
f01032c1:	56                   	push   %esi
f01032c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01032c5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01032c8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01032cb:	39 c6                	cmp    %eax,%esi
f01032cd:	73 35                	jae    f0103304 <memmove+0x47>
f01032cf:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01032d2:	39 d0                	cmp    %edx,%eax
f01032d4:	73 2e                	jae    f0103304 <memmove+0x47>
		s += n;
		d += n;
f01032d6:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032d9:	89 d6                	mov    %edx,%esi
f01032db:	09 fe                	or     %edi,%esi
f01032dd:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01032e3:	75 13                	jne    f01032f8 <memmove+0x3b>
f01032e5:	f6 c1 03             	test   $0x3,%cl
f01032e8:	75 0e                	jne    f01032f8 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01032ea:	83 ef 04             	sub    $0x4,%edi
f01032ed:	8d 72 fc             	lea    -0x4(%edx),%esi
f01032f0:	c1 e9 02             	shr    $0x2,%ecx
f01032f3:	fd                   	std    
f01032f4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032f6:	eb 09                	jmp    f0103301 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01032f8:	83 ef 01             	sub    $0x1,%edi
f01032fb:	8d 72 ff             	lea    -0x1(%edx),%esi
f01032fe:	fd                   	std    
f01032ff:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103301:	fc                   	cld    
f0103302:	eb 1d                	jmp    f0103321 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103304:	89 f2                	mov    %esi,%edx
f0103306:	09 c2                	or     %eax,%edx
f0103308:	f6 c2 03             	test   $0x3,%dl
f010330b:	75 0f                	jne    f010331c <memmove+0x5f>
f010330d:	f6 c1 03             	test   $0x3,%cl
f0103310:	75 0a                	jne    f010331c <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103312:	c1 e9 02             	shr    $0x2,%ecx
f0103315:	89 c7                	mov    %eax,%edi
f0103317:	fc                   	cld    
f0103318:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010331a:	eb 05                	jmp    f0103321 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010331c:	89 c7                	mov    %eax,%edi
f010331e:	fc                   	cld    
f010331f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103321:	5e                   	pop    %esi
f0103322:	5f                   	pop    %edi
f0103323:	5d                   	pop    %ebp
f0103324:	c3                   	ret    

f0103325 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103325:	55                   	push   %ebp
f0103326:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103328:	ff 75 10             	pushl  0x10(%ebp)
f010332b:	ff 75 0c             	pushl  0xc(%ebp)
f010332e:	ff 75 08             	pushl  0x8(%ebp)
f0103331:	e8 87 ff ff ff       	call   f01032bd <memmove>
}
f0103336:	c9                   	leave  
f0103337:	c3                   	ret    

f0103338 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103338:	55                   	push   %ebp
f0103339:	89 e5                	mov    %esp,%ebp
f010333b:	56                   	push   %esi
f010333c:	53                   	push   %ebx
f010333d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103340:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103343:	89 c6                	mov    %eax,%esi
f0103345:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103348:	eb 1a                	jmp    f0103364 <memcmp+0x2c>
		if (*s1 != *s2)
f010334a:	0f b6 08             	movzbl (%eax),%ecx
f010334d:	0f b6 1a             	movzbl (%edx),%ebx
f0103350:	38 d9                	cmp    %bl,%cl
f0103352:	74 0a                	je     f010335e <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103354:	0f b6 c1             	movzbl %cl,%eax
f0103357:	0f b6 db             	movzbl %bl,%ebx
f010335a:	29 d8                	sub    %ebx,%eax
f010335c:	eb 0f                	jmp    f010336d <memcmp+0x35>
		s1++, s2++;
f010335e:	83 c0 01             	add    $0x1,%eax
f0103361:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103364:	39 f0                	cmp    %esi,%eax
f0103366:	75 e2                	jne    f010334a <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103368:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010336d:	5b                   	pop    %ebx
f010336e:	5e                   	pop    %esi
f010336f:	5d                   	pop    %ebp
f0103370:	c3                   	ret    

f0103371 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103371:	55                   	push   %ebp
f0103372:	89 e5                	mov    %esp,%ebp
f0103374:	53                   	push   %ebx
f0103375:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103378:	89 c1                	mov    %eax,%ecx
f010337a:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010337d:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103381:	eb 0a                	jmp    f010338d <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103383:	0f b6 10             	movzbl (%eax),%edx
f0103386:	39 da                	cmp    %ebx,%edx
f0103388:	74 07                	je     f0103391 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010338a:	83 c0 01             	add    $0x1,%eax
f010338d:	39 c8                	cmp    %ecx,%eax
f010338f:	72 f2                	jb     f0103383 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103391:	5b                   	pop    %ebx
f0103392:	5d                   	pop    %ebp
f0103393:	c3                   	ret    

f0103394 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103394:	55                   	push   %ebp
f0103395:	89 e5                	mov    %esp,%ebp
f0103397:	57                   	push   %edi
f0103398:	56                   	push   %esi
f0103399:	53                   	push   %ebx
f010339a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010339d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033a0:	eb 03                	jmp    f01033a5 <strtol+0x11>
		s++;
f01033a2:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033a5:	0f b6 01             	movzbl (%ecx),%eax
f01033a8:	3c 20                	cmp    $0x20,%al
f01033aa:	74 f6                	je     f01033a2 <strtol+0xe>
f01033ac:	3c 09                	cmp    $0x9,%al
f01033ae:	74 f2                	je     f01033a2 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01033b0:	3c 2b                	cmp    $0x2b,%al
f01033b2:	75 0a                	jne    f01033be <strtol+0x2a>
		s++;
f01033b4:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01033b7:	bf 00 00 00 00       	mov    $0x0,%edi
f01033bc:	eb 11                	jmp    f01033cf <strtol+0x3b>
f01033be:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01033c3:	3c 2d                	cmp    $0x2d,%al
f01033c5:	75 08                	jne    f01033cf <strtol+0x3b>
		s++, neg = 1;
f01033c7:	83 c1 01             	add    $0x1,%ecx
f01033ca:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01033cf:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01033d5:	75 15                	jne    f01033ec <strtol+0x58>
f01033d7:	80 39 30             	cmpb   $0x30,(%ecx)
f01033da:	75 10                	jne    f01033ec <strtol+0x58>
f01033dc:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01033e0:	75 7c                	jne    f010345e <strtol+0xca>
		s += 2, base = 16;
f01033e2:	83 c1 02             	add    $0x2,%ecx
f01033e5:	bb 10 00 00 00       	mov    $0x10,%ebx
f01033ea:	eb 16                	jmp    f0103402 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01033ec:	85 db                	test   %ebx,%ebx
f01033ee:	75 12                	jne    f0103402 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01033f0:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033f5:	80 39 30             	cmpb   $0x30,(%ecx)
f01033f8:	75 08                	jne    f0103402 <strtol+0x6e>
		s++, base = 8;
f01033fa:	83 c1 01             	add    $0x1,%ecx
f01033fd:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103402:	b8 00 00 00 00       	mov    $0x0,%eax
f0103407:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010340a:	0f b6 11             	movzbl (%ecx),%edx
f010340d:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103410:	89 f3                	mov    %esi,%ebx
f0103412:	80 fb 09             	cmp    $0x9,%bl
f0103415:	77 08                	ja     f010341f <strtol+0x8b>
			dig = *s - '0';
f0103417:	0f be d2             	movsbl %dl,%edx
f010341a:	83 ea 30             	sub    $0x30,%edx
f010341d:	eb 22                	jmp    f0103441 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010341f:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103422:	89 f3                	mov    %esi,%ebx
f0103424:	80 fb 19             	cmp    $0x19,%bl
f0103427:	77 08                	ja     f0103431 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103429:	0f be d2             	movsbl %dl,%edx
f010342c:	83 ea 57             	sub    $0x57,%edx
f010342f:	eb 10                	jmp    f0103441 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103431:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103434:	89 f3                	mov    %esi,%ebx
f0103436:	80 fb 19             	cmp    $0x19,%bl
f0103439:	77 16                	ja     f0103451 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010343b:	0f be d2             	movsbl %dl,%edx
f010343e:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103441:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103444:	7d 0b                	jge    f0103451 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103446:	83 c1 01             	add    $0x1,%ecx
f0103449:	0f af 45 10          	imul   0x10(%ebp),%eax
f010344d:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010344f:	eb b9                	jmp    f010340a <strtol+0x76>

	if (endptr)
f0103451:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103455:	74 0d                	je     f0103464 <strtol+0xd0>
		*endptr = (char *) s;
f0103457:	8b 75 0c             	mov    0xc(%ebp),%esi
f010345a:	89 0e                	mov    %ecx,(%esi)
f010345c:	eb 06                	jmp    f0103464 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010345e:	85 db                	test   %ebx,%ebx
f0103460:	74 98                	je     f01033fa <strtol+0x66>
f0103462:	eb 9e                	jmp    f0103402 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103464:	89 c2                	mov    %eax,%edx
f0103466:	f7 da                	neg    %edx
f0103468:	85 ff                	test   %edi,%edi
f010346a:	0f 45 c2             	cmovne %edx,%eax
}
f010346d:	5b                   	pop    %ebx
f010346e:	5e                   	pop    %esi
f010346f:	5f                   	pop    %edi
f0103470:	5d                   	pop    %ebp
f0103471:	c3                   	ret    
f0103472:	66 90                	xchg   %ax,%ax
f0103474:	66 90                	xchg   %ax,%ax
f0103476:	66 90                	xchg   %ax,%ax
f0103478:	66 90                	xchg   %ax,%ax
f010347a:	66 90                	xchg   %ax,%ax
f010347c:	66 90                	xchg   %ax,%ax
f010347e:	66 90                	xchg   %ax,%ax

f0103480 <__udivdi3>:
f0103480:	55                   	push   %ebp
f0103481:	57                   	push   %edi
f0103482:	56                   	push   %esi
f0103483:	53                   	push   %ebx
f0103484:	83 ec 1c             	sub    $0x1c,%esp
f0103487:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010348b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010348f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103493:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103497:	85 f6                	test   %esi,%esi
f0103499:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010349d:	89 ca                	mov    %ecx,%edx
f010349f:	89 f8                	mov    %edi,%eax
f01034a1:	75 3d                	jne    f01034e0 <__udivdi3+0x60>
f01034a3:	39 cf                	cmp    %ecx,%edi
f01034a5:	0f 87 c5 00 00 00    	ja     f0103570 <__udivdi3+0xf0>
f01034ab:	85 ff                	test   %edi,%edi
f01034ad:	89 fd                	mov    %edi,%ebp
f01034af:	75 0b                	jne    f01034bc <__udivdi3+0x3c>
f01034b1:	b8 01 00 00 00       	mov    $0x1,%eax
f01034b6:	31 d2                	xor    %edx,%edx
f01034b8:	f7 f7                	div    %edi
f01034ba:	89 c5                	mov    %eax,%ebp
f01034bc:	89 c8                	mov    %ecx,%eax
f01034be:	31 d2                	xor    %edx,%edx
f01034c0:	f7 f5                	div    %ebp
f01034c2:	89 c1                	mov    %eax,%ecx
f01034c4:	89 d8                	mov    %ebx,%eax
f01034c6:	89 cf                	mov    %ecx,%edi
f01034c8:	f7 f5                	div    %ebp
f01034ca:	89 c3                	mov    %eax,%ebx
f01034cc:	89 d8                	mov    %ebx,%eax
f01034ce:	89 fa                	mov    %edi,%edx
f01034d0:	83 c4 1c             	add    $0x1c,%esp
f01034d3:	5b                   	pop    %ebx
f01034d4:	5e                   	pop    %esi
f01034d5:	5f                   	pop    %edi
f01034d6:	5d                   	pop    %ebp
f01034d7:	c3                   	ret    
f01034d8:	90                   	nop
f01034d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034e0:	39 ce                	cmp    %ecx,%esi
f01034e2:	77 74                	ja     f0103558 <__udivdi3+0xd8>
f01034e4:	0f bd fe             	bsr    %esi,%edi
f01034e7:	83 f7 1f             	xor    $0x1f,%edi
f01034ea:	0f 84 98 00 00 00    	je     f0103588 <__udivdi3+0x108>
f01034f0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01034f5:	89 f9                	mov    %edi,%ecx
f01034f7:	89 c5                	mov    %eax,%ebp
f01034f9:	29 fb                	sub    %edi,%ebx
f01034fb:	d3 e6                	shl    %cl,%esi
f01034fd:	89 d9                	mov    %ebx,%ecx
f01034ff:	d3 ed                	shr    %cl,%ebp
f0103501:	89 f9                	mov    %edi,%ecx
f0103503:	d3 e0                	shl    %cl,%eax
f0103505:	09 ee                	or     %ebp,%esi
f0103507:	89 d9                	mov    %ebx,%ecx
f0103509:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010350d:	89 d5                	mov    %edx,%ebp
f010350f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103513:	d3 ed                	shr    %cl,%ebp
f0103515:	89 f9                	mov    %edi,%ecx
f0103517:	d3 e2                	shl    %cl,%edx
f0103519:	89 d9                	mov    %ebx,%ecx
f010351b:	d3 e8                	shr    %cl,%eax
f010351d:	09 c2                	or     %eax,%edx
f010351f:	89 d0                	mov    %edx,%eax
f0103521:	89 ea                	mov    %ebp,%edx
f0103523:	f7 f6                	div    %esi
f0103525:	89 d5                	mov    %edx,%ebp
f0103527:	89 c3                	mov    %eax,%ebx
f0103529:	f7 64 24 0c          	mull   0xc(%esp)
f010352d:	39 d5                	cmp    %edx,%ebp
f010352f:	72 10                	jb     f0103541 <__udivdi3+0xc1>
f0103531:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103535:	89 f9                	mov    %edi,%ecx
f0103537:	d3 e6                	shl    %cl,%esi
f0103539:	39 c6                	cmp    %eax,%esi
f010353b:	73 07                	jae    f0103544 <__udivdi3+0xc4>
f010353d:	39 d5                	cmp    %edx,%ebp
f010353f:	75 03                	jne    f0103544 <__udivdi3+0xc4>
f0103541:	83 eb 01             	sub    $0x1,%ebx
f0103544:	31 ff                	xor    %edi,%edi
f0103546:	89 d8                	mov    %ebx,%eax
f0103548:	89 fa                	mov    %edi,%edx
f010354a:	83 c4 1c             	add    $0x1c,%esp
f010354d:	5b                   	pop    %ebx
f010354e:	5e                   	pop    %esi
f010354f:	5f                   	pop    %edi
f0103550:	5d                   	pop    %ebp
f0103551:	c3                   	ret    
f0103552:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103558:	31 ff                	xor    %edi,%edi
f010355a:	31 db                	xor    %ebx,%ebx
f010355c:	89 d8                	mov    %ebx,%eax
f010355e:	89 fa                	mov    %edi,%edx
f0103560:	83 c4 1c             	add    $0x1c,%esp
f0103563:	5b                   	pop    %ebx
f0103564:	5e                   	pop    %esi
f0103565:	5f                   	pop    %edi
f0103566:	5d                   	pop    %ebp
f0103567:	c3                   	ret    
f0103568:	90                   	nop
f0103569:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103570:	89 d8                	mov    %ebx,%eax
f0103572:	f7 f7                	div    %edi
f0103574:	31 ff                	xor    %edi,%edi
f0103576:	89 c3                	mov    %eax,%ebx
f0103578:	89 d8                	mov    %ebx,%eax
f010357a:	89 fa                	mov    %edi,%edx
f010357c:	83 c4 1c             	add    $0x1c,%esp
f010357f:	5b                   	pop    %ebx
f0103580:	5e                   	pop    %esi
f0103581:	5f                   	pop    %edi
f0103582:	5d                   	pop    %ebp
f0103583:	c3                   	ret    
f0103584:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103588:	39 ce                	cmp    %ecx,%esi
f010358a:	72 0c                	jb     f0103598 <__udivdi3+0x118>
f010358c:	31 db                	xor    %ebx,%ebx
f010358e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103592:	0f 87 34 ff ff ff    	ja     f01034cc <__udivdi3+0x4c>
f0103598:	bb 01 00 00 00       	mov    $0x1,%ebx
f010359d:	e9 2a ff ff ff       	jmp    f01034cc <__udivdi3+0x4c>
f01035a2:	66 90                	xchg   %ax,%ax
f01035a4:	66 90                	xchg   %ax,%ax
f01035a6:	66 90                	xchg   %ax,%ax
f01035a8:	66 90                	xchg   %ax,%ax
f01035aa:	66 90                	xchg   %ax,%ax
f01035ac:	66 90                	xchg   %ax,%ax
f01035ae:	66 90                	xchg   %ax,%ax

f01035b0 <__umoddi3>:
f01035b0:	55                   	push   %ebp
f01035b1:	57                   	push   %edi
f01035b2:	56                   	push   %esi
f01035b3:	53                   	push   %ebx
f01035b4:	83 ec 1c             	sub    $0x1c,%esp
f01035b7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01035bb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01035bf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01035c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01035c7:	85 d2                	test   %edx,%edx
f01035c9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01035cd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035d1:	89 f3                	mov    %esi,%ebx
f01035d3:	89 3c 24             	mov    %edi,(%esp)
f01035d6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035da:	75 1c                	jne    f01035f8 <__umoddi3+0x48>
f01035dc:	39 f7                	cmp    %esi,%edi
f01035de:	76 50                	jbe    f0103630 <__umoddi3+0x80>
f01035e0:	89 c8                	mov    %ecx,%eax
f01035e2:	89 f2                	mov    %esi,%edx
f01035e4:	f7 f7                	div    %edi
f01035e6:	89 d0                	mov    %edx,%eax
f01035e8:	31 d2                	xor    %edx,%edx
f01035ea:	83 c4 1c             	add    $0x1c,%esp
f01035ed:	5b                   	pop    %ebx
f01035ee:	5e                   	pop    %esi
f01035ef:	5f                   	pop    %edi
f01035f0:	5d                   	pop    %ebp
f01035f1:	c3                   	ret    
f01035f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01035f8:	39 f2                	cmp    %esi,%edx
f01035fa:	89 d0                	mov    %edx,%eax
f01035fc:	77 52                	ja     f0103650 <__umoddi3+0xa0>
f01035fe:	0f bd ea             	bsr    %edx,%ebp
f0103601:	83 f5 1f             	xor    $0x1f,%ebp
f0103604:	75 5a                	jne    f0103660 <__umoddi3+0xb0>
f0103606:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010360a:	0f 82 e0 00 00 00    	jb     f01036f0 <__umoddi3+0x140>
f0103610:	39 0c 24             	cmp    %ecx,(%esp)
f0103613:	0f 86 d7 00 00 00    	jbe    f01036f0 <__umoddi3+0x140>
f0103619:	8b 44 24 08          	mov    0x8(%esp),%eax
f010361d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103621:	83 c4 1c             	add    $0x1c,%esp
f0103624:	5b                   	pop    %ebx
f0103625:	5e                   	pop    %esi
f0103626:	5f                   	pop    %edi
f0103627:	5d                   	pop    %ebp
f0103628:	c3                   	ret    
f0103629:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103630:	85 ff                	test   %edi,%edi
f0103632:	89 fd                	mov    %edi,%ebp
f0103634:	75 0b                	jne    f0103641 <__umoddi3+0x91>
f0103636:	b8 01 00 00 00       	mov    $0x1,%eax
f010363b:	31 d2                	xor    %edx,%edx
f010363d:	f7 f7                	div    %edi
f010363f:	89 c5                	mov    %eax,%ebp
f0103641:	89 f0                	mov    %esi,%eax
f0103643:	31 d2                	xor    %edx,%edx
f0103645:	f7 f5                	div    %ebp
f0103647:	89 c8                	mov    %ecx,%eax
f0103649:	f7 f5                	div    %ebp
f010364b:	89 d0                	mov    %edx,%eax
f010364d:	eb 99                	jmp    f01035e8 <__umoddi3+0x38>
f010364f:	90                   	nop
f0103650:	89 c8                	mov    %ecx,%eax
f0103652:	89 f2                	mov    %esi,%edx
f0103654:	83 c4 1c             	add    $0x1c,%esp
f0103657:	5b                   	pop    %ebx
f0103658:	5e                   	pop    %esi
f0103659:	5f                   	pop    %edi
f010365a:	5d                   	pop    %ebp
f010365b:	c3                   	ret    
f010365c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103660:	8b 34 24             	mov    (%esp),%esi
f0103663:	bf 20 00 00 00       	mov    $0x20,%edi
f0103668:	89 e9                	mov    %ebp,%ecx
f010366a:	29 ef                	sub    %ebp,%edi
f010366c:	d3 e0                	shl    %cl,%eax
f010366e:	89 f9                	mov    %edi,%ecx
f0103670:	89 f2                	mov    %esi,%edx
f0103672:	d3 ea                	shr    %cl,%edx
f0103674:	89 e9                	mov    %ebp,%ecx
f0103676:	09 c2                	or     %eax,%edx
f0103678:	89 d8                	mov    %ebx,%eax
f010367a:	89 14 24             	mov    %edx,(%esp)
f010367d:	89 f2                	mov    %esi,%edx
f010367f:	d3 e2                	shl    %cl,%edx
f0103681:	89 f9                	mov    %edi,%ecx
f0103683:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103687:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010368b:	d3 e8                	shr    %cl,%eax
f010368d:	89 e9                	mov    %ebp,%ecx
f010368f:	89 c6                	mov    %eax,%esi
f0103691:	d3 e3                	shl    %cl,%ebx
f0103693:	89 f9                	mov    %edi,%ecx
f0103695:	89 d0                	mov    %edx,%eax
f0103697:	d3 e8                	shr    %cl,%eax
f0103699:	89 e9                	mov    %ebp,%ecx
f010369b:	09 d8                	or     %ebx,%eax
f010369d:	89 d3                	mov    %edx,%ebx
f010369f:	89 f2                	mov    %esi,%edx
f01036a1:	f7 34 24             	divl   (%esp)
f01036a4:	89 d6                	mov    %edx,%esi
f01036a6:	d3 e3                	shl    %cl,%ebx
f01036a8:	f7 64 24 04          	mull   0x4(%esp)
f01036ac:	39 d6                	cmp    %edx,%esi
f01036ae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01036b2:	89 d1                	mov    %edx,%ecx
f01036b4:	89 c3                	mov    %eax,%ebx
f01036b6:	72 08                	jb     f01036c0 <__umoddi3+0x110>
f01036b8:	75 11                	jne    f01036cb <__umoddi3+0x11b>
f01036ba:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01036be:	73 0b                	jae    f01036cb <__umoddi3+0x11b>
f01036c0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01036c4:	1b 14 24             	sbb    (%esp),%edx
f01036c7:	89 d1                	mov    %edx,%ecx
f01036c9:	89 c3                	mov    %eax,%ebx
f01036cb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01036cf:	29 da                	sub    %ebx,%edx
f01036d1:	19 ce                	sbb    %ecx,%esi
f01036d3:	89 f9                	mov    %edi,%ecx
f01036d5:	89 f0                	mov    %esi,%eax
f01036d7:	d3 e0                	shl    %cl,%eax
f01036d9:	89 e9                	mov    %ebp,%ecx
f01036db:	d3 ea                	shr    %cl,%edx
f01036dd:	89 e9                	mov    %ebp,%ecx
f01036df:	d3 ee                	shr    %cl,%esi
f01036e1:	09 d0                	or     %edx,%eax
f01036e3:	89 f2                	mov    %esi,%edx
f01036e5:	83 c4 1c             	add    $0x1c,%esp
f01036e8:	5b                   	pop    %ebx
f01036e9:	5e                   	pop    %esi
f01036ea:	5f                   	pop    %edi
f01036eb:	5d                   	pop    %ebp
f01036ec:	c3                   	ret    
f01036ed:	8d 76 00             	lea    0x0(%esi),%esi
f01036f0:	29 f9                	sub    %edi,%ecx
f01036f2:	19 d6                	sbb    %edx,%esi
f01036f4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036f8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036fc:	e9 18 ff ff ff       	jmp    f0103619 <__umoddi3+0x69>
