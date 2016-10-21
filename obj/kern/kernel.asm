
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
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
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
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


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
f0100046:	b8 10 db 17 f0       	mov    $0xf017db10,%eax
f010004b:	2d ee cb 17 f0       	sub    $0xf017cbee,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 ee cb 17 f0       	push   $0xf017cbee
f0100058:	e8 c2 42 00 00       	call   f010431f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 9d 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 47 10 f0       	push   $0xf01047c0
f010006f:	e8 60 2f 00 00       	call   f0102fd4 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 31 10 00 00       	call   f01010aa <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 93 29 00 00       	call   f0102a11 <env_init>
	trap_init();
f010007e:	e8 c2 2f 00 00       	call   f0103045 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 b3 11 f0       	push   $0xf011b356
f010008d:	e8 44 2b 00 00       	call   f0102bd6 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 4c ce 17 f0    	pushl  0xf017ce4c
f010009b:	e8 6b 2e 00 00       	call   f0102f0b <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 00 db 17 f0 00 	cmpl   $0x0,0xf017db00
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 00 db 17 f0    	mov    %esi,0xf017db00

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 db 47 10 f0       	push   $0xf01047db
f01000ca:	e8 05 2f 00 00       	call   f0102fd4 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 d5 2e 00 00       	call   f0102fae <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 e8 4f 10 f0 	movl   $0xf0104fe8,(%esp)
f01000e0:	e8 ef 2e 00 00       	call   f0102fd4 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 fb 06 00 00       	call   f01007ed <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 f3 47 10 f0       	push   $0xf01047f3
f010010c:	e8 c3 2e 00 00       	call   f0102fd4 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 91 2e 00 00       	call   f0102fae <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 e8 4f 10 f0 	movl   $0xf0104fe8,(%esp)
f0100124:	e8 ab 2e 00 00       	call   f0102fd4 <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 24 ce 17 f0    	mov    0xf017ce24,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 24 ce 17 f0    	mov    %edx,0xf017ce24
f010016e:	88 81 20 cc 17 f0    	mov    %al,-0xfe833e0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 24 ce 17 f0 00 	movl   $0x0,0xf017ce24
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f0 00 00 00    	je     f0100291 <kbd_proc_data+0xfe>
f01001a1:	ba 60 00 00 00       	mov    $0x60,%edx
f01001a6:	ec                   	in     (%dx),%al
f01001a7:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001a9:	3c e0                	cmp    $0xe0,%al
f01001ab:	75 0d                	jne    f01001ba <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001ad:	83 0d 00 cc 17 f0 40 	orl    $0x40,0xf017cc00
		return 0;
f01001b4:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001b9:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ba:	55                   	push   %ebp
f01001bb:	89 e5                	mov    %esp,%ebp
f01001bd:	53                   	push   %ebx
f01001be:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c1:	84 c0                	test   %al,%al
f01001c3:	79 36                	jns    f01001fb <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001c5:	8b 0d 00 cc 17 f0    	mov    0xf017cc00,%ecx
f01001cb:	89 cb                	mov    %ecx,%ebx
f01001cd:	83 e3 40             	and    $0x40,%ebx
f01001d0:	83 e0 7f             	and    $0x7f,%eax
f01001d3:	85 db                	test   %ebx,%ebx
f01001d5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d8:	0f b6 d2             	movzbl %dl,%edx
f01001db:	0f b6 82 60 49 10 f0 	movzbl -0xfefb6a0(%edx),%eax
f01001e2:	83 c8 40             	or     $0x40,%eax
f01001e5:	0f b6 c0             	movzbl %al,%eax
f01001e8:	f7 d0                	not    %eax
f01001ea:	21 c8                	and    %ecx,%eax
f01001ec:	a3 00 cc 17 f0       	mov    %eax,0xf017cc00
		return 0;
f01001f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f6:	e9 9e 00 00 00       	jmp    f0100299 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001fb:	8b 0d 00 cc 17 f0    	mov    0xf017cc00,%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 0d 00 cc 17 f0    	mov    %ecx,0xf017cc00
	}

	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100217:	0f b6 82 60 49 10 f0 	movzbl -0xfefb6a0(%edx),%eax
f010021e:	0b 05 00 cc 17 f0    	or     0xf017cc00,%eax
f0100224:	0f b6 8a 60 48 10 f0 	movzbl -0xfefb7a0(%edx),%ecx
f010022b:	31 c8                	xor    %ecx,%eax
f010022d:	a3 00 cc 17 f0       	mov    %eax,0xf017cc00

	c = charcode[shift & (CTL | SHIFT)][data];
f0100232:	89 c1                	mov    %eax,%ecx
f0100234:	83 e1 03             	and    $0x3,%ecx
f0100237:	8b 0c 8d 40 48 10 f0 	mov    -0xfefb7c0(,%ecx,4),%ecx
f010023e:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100242:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100245:	a8 08                	test   $0x8,%al
f0100247:	74 1b                	je     f0100264 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100249:	89 da                	mov    %ebx,%edx
f010024b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010024e:	83 f9 19             	cmp    $0x19,%ecx
f0100251:	77 05                	ja     f0100258 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100253:	83 eb 20             	sub    $0x20,%ebx
f0100256:	eb 0c                	jmp    f0100264 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100258:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010025b:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010025e:	83 fa 19             	cmp    $0x19,%edx
f0100261:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100264:	f7 d0                	not    %eax
f0100266:	a8 06                	test   $0x6,%al
f0100268:	75 2d                	jne    f0100297 <kbd_proc_data+0x104>
f010026a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100270:	75 25                	jne    f0100297 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f0100272:	83 ec 0c             	sub    $0xc,%esp
f0100275:	68 0d 48 10 f0       	push   $0xf010480d
f010027a:	e8 55 2d 00 00       	call   f0102fd4 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010027f:	ba 92 00 00 00       	mov    $0x92,%edx
f0100284:	b8 03 00 00 00       	mov    $0x3,%eax
f0100289:	ee                   	out    %al,(%dx)
f010028a:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010028d:	89 d8                	mov    %ebx,%eax
f010028f:	eb 08                	jmp    f0100299 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100291:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100296:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100297:	89 d8                	mov    %ebx,%eax
}
f0100299:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010029c:	c9                   	leave  
f010029d:	c3                   	ret    

f010029e <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010029e:	55                   	push   %ebp
f010029f:	89 e5                	mov    %esp,%ebp
f01002a1:	57                   	push   %edi
f01002a2:	56                   	push   %esi
f01002a3:	53                   	push   %ebx
f01002a4:	83 ec 1c             	sub    $0x1c,%esp
f01002a7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a9:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ae:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002b3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b8:	eb 09                	jmp    f01002c3 <cons_putc+0x25>
f01002ba:	89 ca                	mov    %ecx,%edx
f01002bc:	ec                   	in     (%dx),%al
f01002bd:	ec                   	in     (%dx),%al
f01002be:	ec                   	in     (%dx),%al
f01002bf:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002c0:	83 c3 01             	add    $0x1,%ebx
f01002c3:	89 f2                	mov    %esi,%edx
f01002c5:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002c6:	a8 20                	test   $0x20,%al
f01002c8:	75 08                	jne    f01002d2 <cons_putc+0x34>
f01002ca:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002d0:	7e e8                	jle    f01002ba <cons_putc+0x1c>
f01002d2:	89 f8                	mov    %edi,%eax
f01002d4:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d7:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002dc:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002dd:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e2:	be 79 03 00 00       	mov    $0x379,%esi
f01002e7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002ec:	eb 09                	jmp    f01002f7 <cons_putc+0x59>
f01002ee:	89 ca                	mov    %ecx,%edx
f01002f0:	ec                   	in     (%dx),%al
f01002f1:	ec                   	in     (%dx),%al
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	ec                   	in     (%dx),%al
f01002f4:	83 c3 01             	add    $0x1,%ebx
f01002f7:	89 f2                	mov    %esi,%edx
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100300:	7f 04                	jg     f0100306 <cons_putc+0x68>
f0100302:	84 c0                	test   %al,%al
f0100304:	79 e8                	jns    f01002ee <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100306:	ba 78 03 00 00       	mov    $0x378,%edx
f010030b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010030f:	ee                   	out    %al,(%dx)
f0100310:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100315:	b8 0d 00 00 00       	mov    $0xd,%eax
f010031a:	ee                   	out    %al,(%dx)
f010031b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100320:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100321:	89 fa                	mov    %edi,%edx
f0100323:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100329:	89 f8                	mov    %edi,%eax
f010032b:	80 cc 07             	or     $0x7,%ah
f010032e:	85 d2                	test   %edx,%edx
f0100330:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100333:	89 f8                	mov    %edi,%eax
f0100335:	0f b6 c0             	movzbl %al,%eax
f0100338:	83 f8 09             	cmp    $0x9,%eax
f010033b:	74 74                	je     f01003b1 <cons_putc+0x113>
f010033d:	83 f8 09             	cmp    $0x9,%eax
f0100340:	7f 0a                	jg     f010034c <cons_putc+0xae>
f0100342:	83 f8 08             	cmp    $0x8,%eax
f0100345:	74 14                	je     f010035b <cons_putc+0xbd>
f0100347:	e9 99 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
f010034c:	83 f8 0a             	cmp    $0xa,%eax
f010034f:	74 3a                	je     f010038b <cons_putc+0xed>
f0100351:	83 f8 0d             	cmp    $0xd,%eax
f0100354:	74 3d                	je     f0100393 <cons_putc+0xf5>
f0100356:	e9 8a 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010035b:	0f b7 05 28 ce 17 f0 	movzwl 0xf017ce28,%eax
f0100362:	66 85 c0             	test   %ax,%ax
f0100365:	0f 84 e6 00 00 00    	je     f0100451 <cons_putc+0x1b3>
			crt_pos--;
f010036b:	83 e8 01             	sub    $0x1,%eax
f010036e:	66 a3 28 ce 17 f0    	mov    %ax,0xf017ce28
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100374:	0f b7 c0             	movzwl %ax,%eax
f0100377:	66 81 e7 00 ff       	and    $0xff00,%di
f010037c:	83 cf 20             	or     $0x20,%edi
f010037f:	8b 15 2c ce 17 f0    	mov    0xf017ce2c,%edx
f0100385:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100389:	eb 78                	jmp    f0100403 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010038b:	66 83 05 28 ce 17 f0 	addw   $0x50,0xf017ce28
f0100392:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100393:	0f b7 05 28 ce 17 f0 	movzwl 0xf017ce28,%eax
f010039a:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a0:	c1 e8 16             	shr    $0x16,%eax
f01003a3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a6:	c1 e0 04             	shl    $0x4,%eax
f01003a9:	66 a3 28 ce 17 f0    	mov    %ax,0xf017ce28
f01003af:	eb 52                	jmp    f0100403 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003b1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b6:	e8 e3 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003bb:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c0:	e8 d9 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003c5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ca:	e8 cf fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003cf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d4:	e8 c5 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003d9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003de:	e8 bb fe ff ff       	call   f010029e <cons_putc>
f01003e3:	eb 1e                	jmp    f0100403 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003e5:	0f b7 05 28 ce 17 f0 	movzwl 0xf017ce28,%eax
f01003ec:	8d 50 01             	lea    0x1(%eax),%edx
f01003ef:	66 89 15 28 ce 17 f0 	mov    %dx,0xf017ce28
f01003f6:	0f b7 c0             	movzwl %ax,%eax
f01003f9:	8b 15 2c ce 17 f0    	mov    0xf017ce2c,%edx
f01003ff:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100403:	66 81 3d 28 ce 17 f0 	cmpw   $0x7cf,0xf017ce28
f010040a:	cf 07 
f010040c:	76 43                	jbe    f0100451 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040e:	a1 2c ce 17 f0       	mov    0xf017ce2c,%eax
f0100413:	83 ec 04             	sub    $0x4,%esp
f0100416:	68 00 0f 00 00       	push   $0xf00
f010041b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100421:	52                   	push   %edx
f0100422:	50                   	push   %eax
f0100423:	e8 44 3f 00 00       	call   f010436c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100428:	8b 15 2c ce 17 f0    	mov    0xf017ce2c,%edx
f010042e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100434:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010043a:	83 c4 10             	add    $0x10,%esp
f010043d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100442:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100445:	39 d0                	cmp    %edx,%eax
f0100447:	75 f4                	jne    f010043d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100449:	66 83 2d 28 ce 17 f0 	subw   $0x50,0xf017ce28
f0100450:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100451:	8b 0d 30 ce 17 f0    	mov    0xf017ce30,%ecx
f0100457:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045c:	89 ca                	mov    %ecx,%edx
f010045e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045f:	0f b7 1d 28 ce 17 f0 	movzwl 0xf017ce28,%ebx
f0100466:	8d 71 01             	lea    0x1(%ecx),%esi
f0100469:	89 d8                	mov    %ebx,%eax
f010046b:	66 c1 e8 08          	shr    $0x8,%ax
f010046f:	89 f2                	mov    %esi,%edx
f0100471:	ee                   	out    %al,(%dx)
f0100472:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100477:	89 ca                	mov    %ecx,%edx
f0100479:	ee                   	out    %al,(%dx)
f010047a:	89 d8                	mov    %ebx,%eax
f010047c:	89 f2                	mov    %esi,%edx
f010047e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100482:	5b                   	pop    %ebx
f0100483:	5e                   	pop    %esi
f0100484:	5f                   	pop    %edi
f0100485:	5d                   	pop    %ebp
f0100486:	c3                   	ret    

f0100487 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100487:	80 3d 34 ce 17 f0 00 	cmpb   $0x0,0xf017ce34
f010048e:	74 11                	je     f01004a1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100490:	55                   	push   %ebp
f0100491:	89 e5                	mov    %esp,%ebp
f0100493:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100496:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f010049b:	e8 b0 fc ff ff       	call   f0100150 <cons_intr>
}
f01004a0:	c9                   	leave  
f01004a1:	f3 c3                	repz ret 

f01004a3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a3:	55                   	push   %ebp
f01004a4:	89 e5                	mov    %esp,%ebp
f01004a6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a9:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004ae:	e8 9d fc ff ff       	call   f0100150 <cons_intr>
}
f01004b3:	c9                   	leave  
f01004b4:	c3                   	ret    

f01004b5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b5:	55                   	push   %ebp
f01004b6:	89 e5                	mov    %esp,%ebp
f01004b8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bb:	e8 c7 ff ff ff       	call   f0100487 <serial_intr>
	kbd_intr();
f01004c0:	e8 de ff ff ff       	call   f01004a3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c5:	a1 20 ce 17 f0       	mov    0xf017ce20,%eax
f01004ca:	3b 05 24 ce 17 f0    	cmp    0xf017ce24,%eax
f01004d0:	74 26                	je     f01004f8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004d2:	8d 50 01             	lea    0x1(%eax),%edx
f01004d5:	89 15 20 ce 17 f0    	mov    %edx,0xf017ce20
f01004db:	0f b6 88 20 cc 17 f0 	movzbl -0xfe833e0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004e2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004e4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ea:	75 11                	jne    f01004fd <cons_getc+0x48>
			cons.rpos = 0;
f01004ec:	c7 05 20 ce 17 f0 00 	movl   $0x0,0xf017ce20
f01004f3:	00 00 00 
f01004f6:	eb 05                	jmp    f01004fd <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004fd:	c9                   	leave  
f01004fe:	c3                   	ret    

f01004ff <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ff:	55                   	push   %ebp
f0100500:	89 e5                	mov    %esp,%ebp
f0100502:	57                   	push   %edi
f0100503:	56                   	push   %esi
f0100504:	53                   	push   %ebx
f0100505:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100508:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100516:	5a a5 
	if (*cp != 0xA55A) {
f0100518:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100523:	74 11                	je     f0100536 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100525:	c7 05 30 ce 17 f0 b4 	movl   $0x3b4,0xf017ce30
f010052c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100534:	eb 16                	jmp    f010054c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100536:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053d:	c7 05 30 ce 17 f0 d4 	movl   $0x3d4,0xf017ce30
f0100544:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100547:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010054c:	8b 3d 30 ce 17 f0    	mov    0xf017ce30,%edi
f0100552:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100557:	89 fa                	mov    %edi,%edx
f0100559:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010055a:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055d:	89 da                	mov    %ebx,%edx
f010055f:	ec                   	in     (%dx),%al
f0100560:	0f b6 c8             	movzbl %al,%ecx
f0100563:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100566:	b8 0f 00 00 00       	mov    $0xf,%eax
f010056b:	89 fa                	mov    %edi,%edx
f010056d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056e:	89 da                	mov    %ebx,%edx
f0100570:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100571:	89 35 2c ce 17 f0    	mov    %esi,0xf017ce2c
	crt_pos = pos;
f0100577:	0f b6 c0             	movzbl %al,%eax
f010057a:	09 c8                	or     %ecx,%eax
f010057c:	66 a3 28 ce 17 f0    	mov    %ax,0xf017ce28
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100582:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100587:	b8 00 00 00 00       	mov    $0x0,%eax
f010058c:	89 f2                	mov    %esi,%edx
f010058e:	ee                   	out    %al,(%dx)
f010058f:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100594:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100599:	ee                   	out    %al,(%dx)
f010059a:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010059f:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a4:	89 da                	mov    %ebx,%edx
f01005a6:	ee                   	out    %al,(%dx)
f01005a7:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b7:	b8 03 00 00 00       	mov    $0x3,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005cd:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d8:	ec                   	in     (%dx),%al
f01005d9:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005db:	3c ff                	cmp    $0xff,%al
f01005dd:	0f 95 05 34 ce 17 f0 	setne  0xf017ce34
f01005e4:	89 f2                	mov    %esi,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 da                	mov    %ebx,%edx
f01005e9:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005ea:	80 f9 ff             	cmp    $0xff,%cl
f01005ed:	75 10                	jne    f01005ff <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005ef:	83 ec 0c             	sub    $0xc,%esp
f01005f2:	68 19 48 10 f0       	push   $0xf0104819
f01005f7:	e8 d8 29 00 00       	call   f0102fd4 <cprintf>
f01005fc:	83 c4 10             	add    $0x10,%esp
}
f01005ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5e                   	pop    %esi
f0100604:	5f                   	pop    %edi
f0100605:	5d                   	pop    %ebp
f0100606:	c3                   	ret    

f0100607 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100607:	55                   	push   %ebp
f0100608:	89 e5                	mov    %esp,%ebp
f010060a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010060d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100610:	e8 89 fc ff ff       	call   f010029e <cons_putc>
}
f0100615:	c9                   	leave  
f0100616:	c3                   	ret    

f0100617 <getchar>:

int
getchar(void)
{
f0100617:	55                   	push   %ebp
f0100618:	89 e5                	mov    %esp,%ebp
f010061a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010061d:	e8 93 fe ff ff       	call   f01004b5 <cons_getc>
f0100622:	85 c0                	test   %eax,%eax
f0100624:	74 f7                	je     f010061d <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100626:	c9                   	leave  
f0100627:	c3                   	ret    

f0100628 <iscons>:

int
iscons(int fdnum)
{
f0100628:	55                   	push   %ebp
f0100629:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010062b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100630:	5d                   	pop    %ebp
f0100631:	c3                   	ret    

f0100632 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100632:	55                   	push   %ebp
f0100633:	89 e5                	mov    %esp,%ebp
f0100635:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100638:	68 60 4a 10 f0       	push   $0xf0104a60
f010063d:	68 7e 4a 10 f0       	push   $0xf0104a7e
f0100642:	68 83 4a 10 f0       	push   $0xf0104a83
f0100647:	e8 88 29 00 00       	call   f0102fd4 <cprintf>
f010064c:	83 c4 0c             	add    $0xc,%esp
f010064f:	68 20 4b 10 f0       	push   $0xf0104b20
f0100654:	68 8c 4a 10 f0       	push   $0xf0104a8c
f0100659:	68 83 4a 10 f0       	push   $0xf0104a83
f010065e:	e8 71 29 00 00       	call   f0102fd4 <cprintf>
f0100663:	83 c4 0c             	add    $0xc,%esp
f0100666:	68 48 4b 10 f0       	push   $0xf0104b48
f010066b:	68 95 4a 10 f0       	push   $0xf0104a95
f0100670:	68 83 4a 10 f0       	push   $0xf0104a83
f0100675:	e8 5a 29 00 00       	call   f0102fd4 <cprintf>
	return 0;
}
f010067a:	b8 00 00 00 00       	mov    $0x0,%eax
f010067f:	c9                   	leave  
f0100680:	c3                   	ret    

f0100681 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100681:	55                   	push   %ebp
f0100682:	89 e5                	mov    %esp,%ebp
f0100684:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100687:	68 9f 4a 10 f0       	push   $0xf0104a9f
f010068c:	e8 43 29 00 00       	call   f0102fd4 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100691:	83 c4 08             	add    $0x8,%esp
f0100694:	68 0c 00 10 00       	push   $0x10000c
f0100699:	68 6c 4b 10 f0       	push   $0xf0104b6c
f010069e:	e8 31 29 00 00       	call   f0102fd4 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a3:	83 c4 0c             	add    $0xc,%esp
f01006a6:	68 0c 00 10 00       	push   $0x10000c
f01006ab:	68 0c 00 10 f0       	push   $0xf010000c
f01006b0:	68 94 4b 10 f0       	push   $0xf0104b94
f01006b5:	e8 1a 29 00 00       	call   f0102fd4 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ba:	83 c4 0c             	add    $0xc,%esp
f01006bd:	68 b1 47 10 00       	push   $0x1047b1
f01006c2:	68 b1 47 10 f0       	push   $0xf01047b1
f01006c7:	68 b8 4b 10 f0       	push   $0xf0104bb8
f01006cc:	e8 03 29 00 00       	call   f0102fd4 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006d1:	83 c4 0c             	add    $0xc,%esp
f01006d4:	68 ee cb 17 00       	push   $0x17cbee
f01006d9:	68 ee cb 17 f0       	push   $0xf017cbee
f01006de:	68 dc 4b 10 f0       	push   $0xf0104bdc
f01006e3:	e8 ec 28 00 00       	call   f0102fd4 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e8:	83 c4 0c             	add    $0xc,%esp
f01006eb:	68 10 db 17 00       	push   $0x17db10
f01006f0:	68 10 db 17 f0       	push   $0xf017db10
f01006f5:	68 00 4c 10 f0       	push   $0xf0104c00
f01006fa:	e8 d5 28 00 00       	call   f0102fd4 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006ff:	b8 0f df 17 f0       	mov    $0xf017df0f,%eax
f0100704:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100709:	83 c4 08             	add    $0x8,%esp
f010070c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100711:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100717:	85 c0                	test   %eax,%eax
f0100719:	0f 48 c2             	cmovs  %edx,%eax
f010071c:	c1 f8 0a             	sar    $0xa,%eax
f010071f:	50                   	push   %eax
f0100720:	68 24 4c 10 f0       	push   $0xf0104c24
f0100725:	e8 aa 28 00 00       	call   f0102fd4 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010072a:	b8 00 00 00 00       	mov    $0x0,%eax
f010072f:	c9                   	leave  
f0100730:	c3                   	ret    

f0100731 <mon_backtrace>:
#define EIP(v)  ((uint32_t)*(v+1))
#define ARG(v, c) ((uint32_t)*((v)+(c)+2))

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100731:	55                   	push   %ebp
f0100732:	89 e5                	mov    %esp,%ebp
f0100734:	57                   	push   %edi
f0100735:	56                   	push   %esi
f0100736:	53                   	push   %ebx
f0100737:	81 ec 34 01 00 00    	sub    $0x134,%esp
	char format[FORMATLEN];
    char details[FORMATLEN];
    strcpy(format, "  ebp %08x  eip  %08x  args %08x %08x %08x %08x %08x\n");
f010073d:	68 50 4c 10 f0       	push   $0xf0104c50
f0100742:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f0100748:	50                   	push   %eax
f0100749:	e8 8c 3a 00 00       	call   f01041da <strcpy>
    strcpy(details, "       %s:%d: %.*s+%d\n");
f010074e:	83 c4 08             	add    $0x8,%esp
f0100751:	68 b8 4a 10 f0       	push   $0xf0104ab8
f0100756:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
f010075c:	50                   	push   %eax
f010075d:	e8 78 3a 00 00       	call   f01041da <strcpy>

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100762:	89 eb                	mov    %ebp,%ebx
    
    uint32_t *ebpAddr = (uint32_t *) read_ebp();
    struct Eipdebuginfo info;
    
    cprintf("Stack backtrace:\n");
f0100764:	c7 04 24 cf 4a 10 f0 	movl   $0xf0104acf,(%esp)
f010076b:	e8 64 28 00 00       	call   f0102fd4 <cprintf>
    while (ebpAddr) {
f0100770:	83 c4 10             	add    $0x10,%esp
        debuginfo_eip(EIP(ebpAddr), &info);
f0100773:	8d bd d0 fe ff ff    	lea    -0x130(%ebp),%edi

        cprintf(format, EBP(ebpAddr), EIP(ebpAddr), ARG(ebpAddr, 0), ARG(ebpAddr, 1), ARG(ebpAddr, 2), ARG(ebpAddr, 3), ARG(ebpAddr, 4));
f0100779:	8d b5 68 ff ff ff    	lea    -0x98(%ebp),%esi
    
    uint32_t *ebpAddr = (uint32_t *) read_ebp();
    struct Eipdebuginfo info;
    
    cprintf("Stack backtrace:\n");
    while (ebpAddr) {
f010077f:	eb 5b                	jmp    f01007dc <mon_backtrace+0xab>
        debuginfo_eip(EIP(ebpAddr), &info);
f0100781:	83 ec 08             	sub    $0x8,%esp
f0100784:	57                   	push   %edi
f0100785:	ff 73 04             	pushl  0x4(%ebx)
f0100788:	e8 b4 31 00 00       	call   f0103941 <debuginfo_eip>

        cprintf(format, EBP(ebpAddr), EIP(ebpAddr), ARG(ebpAddr, 0), ARG(ebpAddr, 1), ARG(ebpAddr, 2), ARG(ebpAddr, 3), ARG(ebpAddr, 4));
f010078d:	ff 73 18             	pushl  0x18(%ebx)
f0100790:	ff 73 14             	pushl  0x14(%ebx)
f0100793:	ff 73 10             	pushl  0x10(%ebx)
f0100796:	ff 73 0c             	pushl  0xc(%ebx)
f0100799:	ff 73 08             	pushl  0x8(%ebx)
f010079c:	ff 73 04             	pushl  0x4(%ebx)
f010079f:	53                   	push   %ebx
f01007a0:	56                   	push   %esi
f01007a1:	e8 2e 28 00 00       	call   f0102fd4 <cprintf>
        cprintf(details, info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, EIP(ebpAddr)-info.eip_fn_addr);
f01007a6:	83 c4 28             	add    $0x28,%esp
f01007a9:	8b 43 04             	mov    0x4(%ebx),%eax
f01007ac:	2b 85 e0 fe ff ff    	sub    -0x120(%ebp),%eax
f01007b2:	50                   	push   %eax
f01007b3:	ff b5 d8 fe ff ff    	pushl  -0x128(%ebp)
f01007b9:	ff b5 dc fe ff ff    	pushl  -0x124(%ebp)
f01007bf:	ff b5 d4 fe ff ff    	pushl  -0x12c(%ebp)
f01007c5:	ff b5 d0 fe ff ff    	pushl  -0x130(%ebp)
f01007cb:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
f01007d1:	50                   	push   %eax
f01007d2:	e8 fd 27 00 00       	call   f0102fd4 <cprintf>
        ebpAddr = (uint32_t *)(*ebpAddr);
f01007d7:	8b 1b                	mov    (%ebx),%ebx
f01007d9:	83 c4 20             	add    $0x20,%esp
    
    uint32_t *ebpAddr = (uint32_t *) read_ebp();
    struct Eipdebuginfo info;
    
    cprintf("Stack backtrace:\n");
    while (ebpAddr) {
f01007dc:	85 db                	test   %ebx,%ebx
f01007de:	75 a1                	jne    f0100781 <mon_backtrace+0x50>
        cprintf(details, info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, EIP(ebpAddr)-info.eip_fn_addr);
        ebpAddr = (uint32_t *)(*ebpAddr);
    }

	return 0;
}
f01007e0:	b8 00 00 00 00       	mov    $0x0,%eax
f01007e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007e8:	5b                   	pop    %ebx
f01007e9:	5e                   	pop    %esi
f01007ea:	5f                   	pop    %edi
f01007eb:	5d                   	pop    %ebp
f01007ec:	c3                   	ret    

f01007ed <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007ed:	55                   	push   %ebp
f01007ee:	89 e5                	mov    %esp,%ebp
f01007f0:	57                   	push   %edi
f01007f1:	56                   	push   %esi
f01007f2:	53                   	push   %ebx
f01007f3:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007f6:	68 88 4c 10 f0       	push   $0xf0104c88
f01007fb:	e8 d4 27 00 00       	call   f0102fd4 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100800:	c7 04 24 ac 4c 10 f0 	movl   $0xf0104cac,(%esp)
f0100807:	e8 c8 27 00 00       	call   f0102fd4 <cprintf>

	if (tf != NULL)
f010080c:	83 c4 10             	add    $0x10,%esp
f010080f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100813:	74 0e                	je     f0100823 <monitor+0x36>
		print_trapframe(tf);
f0100815:	83 ec 0c             	sub    $0xc,%esp
f0100818:	ff 75 08             	pushl  0x8(%ebp)
f010081b:	e8 ee 2b 00 00       	call   f010340e <print_trapframe>
f0100820:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100823:	83 ec 0c             	sub    $0xc,%esp
f0100826:	68 e1 4a 10 f0       	push   $0xf0104ae1
f010082b:	e8 98 38 00 00       	call   f01040c8 <readline>
f0100830:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100832:	83 c4 10             	add    $0x10,%esp
f0100835:	85 c0                	test   %eax,%eax
f0100837:	74 ea                	je     f0100823 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100839:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100840:	be 00 00 00 00       	mov    $0x0,%esi
f0100845:	eb 0a                	jmp    f0100851 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100847:	c6 03 00             	movb   $0x0,(%ebx)
f010084a:	89 f7                	mov    %esi,%edi
f010084c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010084f:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100851:	0f b6 03             	movzbl (%ebx),%eax
f0100854:	84 c0                	test   %al,%al
f0100856:	74 63                	je     f01008bb <monitor+0xce>
f0100858:	83 ec 08             	sub    $0x8,%esp
f010085b:	0f be c0             	movsbl %al,%eax
f010085e:	50                   	push   %eax
f010085f:	68 e5 4a 10 f0       	push   $0xf0104ae5
f0100864:	e8 79 3a 00 00       	call   f01042e2 <strchr>
f0100869:	83 c4 10             	add    $0x10,%esp
f010086c:	85 c0                	test   %eax,%eax
f010086e:	75 d7                	jne    f0100847 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100870:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100873:	74 46                	je     f01008bb <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100875:	83 fe 0f             	cmp    $0xf,%esi
f0100878:	75 14                	jne    f010088e <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010087a:	83 ec 08             	sub    $0x8,%esp
f010087d:	6a 10                	push   $0x10
f010087f:	68 ea 4a 10 f0       	push   $0xf0104aea
f0100884:	e8 4b 27 00 00       	call   f0102fd4 <cprintf>
f0100889:	83 c4 10             	add    $0x10,%esp
f010088c:	eb 95                	jmp    f0100823 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f010088e:	8d 7e 01             	lea    0x1(%esi),%edi
f0100891:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100895:	eb 03                	jmp    f010089a <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100897:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010089a:	0f b6 03             	movzbl (%ebx),%eax
f010089d:	84 c0                	test   %al,%al
f010089f:	74 ae                	je     f010084f <monitor+0x62>
f01008a1:	83 ec 08             	sub    $0x8,%esp
f01008a4:	0f be c0             	movsbl %al,%eax
f01008a7:	50                   	push   %eax
f01008a8:	68 e5 4a 10 f0       	push   $0xf0104ae5
f01008ad:	e8 30 3a 00 00       	call   f01042e2 <strchr>
f01008b2:	83 c4 10             	add    $0x10,%esp
f01008b5:	85 c0                	test   %eax,%eax
f01008b7:	74 de                	je     f0100897 <monitor+0xaa>
f01008b9:	eb 94                	jmp    f010084f <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01008bb:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008c2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008c3:	85 f6                	test   %esi,%esi
f01008c5:	0f 84 58 ff ff ff    	je     f0100823 <monitor+0x36>
f01008cb:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008d0:	83 ec 08             	sub    $0x8,%esp
f01008d3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008d6:	ff 34 85 e0 4c 10 f0 	pushl  -0xfefb320(,%eax,4)
f01008dd:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e0:	e8 9f 39 00 00       	call   f0104284 <strcmp>
f01008e5:	83 c4 10             	add    $0x10,%esp
f01008e8:	85 c0                	test   %eax,%eax
f01008ea:	75 21                	jne    f010090d <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f01008ec:	83 ec 04             	sub    $0x4,%esp
f01008ef:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008f2:	ff 75 08             	pushl  0x8(%ebp)
f01008f5:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008f8:	52                   	push   %edx
f01008f9:	56                   	push   %esi
f01008fa:	ff 14 85 e8 4c 10 f0 	call   *-0xfefb318(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100901:	83 c4 10             	add    $0x10,%esp
f0100904:	85 c0                	test   %eax,%eax
f0100906:	78 25                	js     f010092d <monitor+0x140>
f0100908:	e9 16 ff ff ff       	jmp    f0100823 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010090d:	83 c3 01             	add    $0x1,%ebx
f0100910:	83 fb 03             	cmp    $0x3,%ebx
f0100913:	75 bb                	jne    f01008d0 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100915:	83 ec 08             	sub    $0x8,%esp
f0100918:	ff 75 a8             	pushl  -0x58(%ebp)
f010091b:	68 07 4b 10 f0       	push   $0xf0104b07
f0100920:	e8 af 26 00 00       	call   f0102fd4 <cprintf>
f0100925:	83 c4 10             	add    $0x10,%esp
f0100928:	e9 f6 fe ff ff       	jmp    f0100823 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010092d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100930:	5b                   	pop    %ebx
f0100931:	5e                   	pop    %esi
f0100932:	5f                   	pop    %edi
f0100933:	5d                   	pop    %ebp
f0100934:	c3                   	ret    

f0100935 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100935:	83 3d 38 ce 17 f0 00 	cmpl   $0x0,0xf017ce38
f010093c:	75 11                	jne    f010094f <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010093e:	ba 0f eb 17 f0       	mov    $0xf017eb0f,%edx
f0100943:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100949:	89 15 38 ce 17 f0    	mov    %edx,0xf017ce38
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0) {
f010094f:	85 c0                	test   %eax,%eax
f0100951:	75 06                	jne    f0100959 <boot_alloc+0x24>
		return nextfree;
f0100953:	a1 38 ce 17 f0       	mov    0xf017ce38,%eax
f0100958:	c3                   	ret    
	}

	if(nextfree + n <= nextfree) {
f0100959:	8b 0d 38 ce 17 f0    	mov    0xf017ce38,%ecx
f010095f:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f0100962:	39 d1                	cmp    %edx,%ecx
f0100964:	72 17                	jb     f010097d <boot_alloc+0x48>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100966:	55                   	push   %ebp
f0100967:	89 e5                	mov    %esp,%ebp
f0100969:	83 ec 0c             	sub    $0xc,%esp
	if(n == 0) {
		return nextfree;
	}

	if(nextfree + n <= nextfree) {
		panic("out of memory!");
f010096c:	68 04 4d 10 f0       	push   $0xf0104d04
f0100971:	6a 6b                	push   $0x6b
f0100973:	68 13 4d 10 f0       	push   $0xf0104d13
f0100978:	e8 23 f7 ff ff       	call   f01000a0 <_panic>
	}

	result = nextfree;
	nextfree = ROUNDUP(nextfree + n, PGSIZE);
f010097d:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100983:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100989:	89 15 38 ce 17 f0    	mov    %edx,0xf017ce38

	return result;
f010098f:	89 c8                	mov    %ecx,%eax
}
f0100991:	c3                   	ret    

f0100992 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100992:	89 d1                	mov    %edx,%ecx
f0100994:	c1 e9 16             	shr    $0x16,%ecx
f0100997:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010099a:	a8 01                	test   $0x1,%al
f010099c:	74 52                	je     f01009f0 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010099e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009a3:	89 c1                	mov    %eax,%ecx
f01009a5:	c1 e9 0c             	shr    $0xc,%ecx
f01009a8:	3b 0d 04 db 17 f0    	cmp    0xf017db04,%ecx
f01009ae:	72 1b                	jb     f01009cb <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009b0:	55                   	push   %ebp
f01009b1:	89 e5                	mov    %esp,%ebp
f01009b3:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009b6:	50                   	push   %eax
f01009b7:	68 1c 50 10 f0       	push   $0xf010501c
f01009bc:	68 33 03 00 00       	push   $0x333
f01009c1:	68 13 4d 10 f0       	push   $0xf0104d13
f01009c6:	e8 d5 f6 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009cb:	c1 ea 0c             	shr    $0xc,%edx
f01009ce:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009d4:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009db:	89 c2                	mov    %eax,%edx
f01009dd:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009e0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009e5:	85 d2                	test   %edx,%edx
f01009e7:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009ec:	0f 44 c2             	cmove  %edx,%eax
f01009ef:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009f5:	c3                   	ret    

f01009f6 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009f6:	55                   	push   %ebp
f01009f7:	89 e5                	mov    %esp,%ebp
f01009f9:	57                   	push   %edi
f01009fa:	56                   	push   %esi
f01009fb:	53                   	push   %ebx
f01009fc:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009ff:	84 c0                	test   %al,%al
f0100a01:	0f 85 72 02 00 00    	jne    f0100c79 <check_page_free_list+0x283>
f0100a07:	e9 7f 02 00 00       	jmp    f0100c8b <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a0c:	83 ec 04             	sub    $0x4,%esp
f0100a0f:	68 40 50 10 f0       	push   $0xf0105040
f0100a14:	68 71 02 00 00       	push   $0x271
f0100a19:	68 13 4d 10 f0       	push   $0xf0104d13
f0100a1e:	e8 7d f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a23:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a26:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a29:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a2c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a2f:	89 c2                	mov    %eax,%edx
f0100a31:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f0100a37:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a3d:	0f 95 c2             	setne  %dl
f0100a40:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a43:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a47:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a49:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a4d:	8b 00                	mov    (%eax),%eax
f0100a4f:	85 c0                	test   %eax,%eax
f0100a51:	75 dc                	jne    f0100a2f <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a53:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a56:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a5c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a5f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a62:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a64:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a67:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a6c:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a71:	8b 1d 40 ce 17 f0    	mov    0xf017ce40,%ebx
f0100a77:	eb 53                	jmp    f0100acc <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a79:	89 d8                	mov    %ebx,%eax
f0100a7b:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0100a81:	c1 f8 03             	sar    $0x3,%eax
f0100a84:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a87:	89 c2                	mov    %eax,%edx
f0100a89:	c1 ea 16             	shr    $0x16,%edx
f0100a8c:	39 f2                	cmp    %esi,%edx
f0100a8e:	73 3a                	jae    f0100aca <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a90:	89 c2                	mov    %eax,%edx
f0100a92:	c1 ea 0c             	shr    $0xc,%edx
f0100a95:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0100a9b:	72 12                	jb     f0100aaf <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a9d:	50                   	push   %eax
f0100a9e:	68 1c 50 10 f0       	push   $0xf010501c
f0100aa3:	6a 56                	push   $0x56
f0100aa5:	68 1f 4d 10 f0       	push   $0xf0104d1f
f0100aaa:	e8 f1 f5 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aaf:	83 ec 04             	sub    $0x4,%esp
f0100ab2:	68 80 00 00 00       	push   $0x80
f0100ab7:	68 97 00 00 00       	push   $0x97
f0100abc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ac1:	50                   	push   %eax
f0100ac2:	e8 58 38 00 00       	call   f010431f <memset>
f0100ac7:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100aca:	8b 1b                	mov    (%ebx),%ebx
f0100acc:	85 db                	test   %ebx,%ebx
f0100ace:	75 a9                	jne    f0100a79 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ad0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ad5:	e8 5b fe ff ff       	call   f0100935 <boot_alloc>
f0100ada:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100add:	8b 15 40 ce 17 f0    	mov    0xf017ce40,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ae3:	8b 0d 0c db 17 f0    	mov    0xf017db0c,%ecx
		assert(pp < pages + npages);
f0100ae9:	a1 04 db 17 f0       	mov    0xf017db04,%eax
f0100aee:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100af1:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100af4:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100af7:	be 00 00 00 00       	mov    $0x0,%esi
f0100afc:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aff:	e9 30 01 00 00       	jmp    f0100c34 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b04:	39 ca                	cmp    %ecx,%edx
f0100b06:	73 19                	jae    f0100b21 <check_page_free_list+0x12b>
f0100b08:	68 2d 4d 10 f0       	push   $0xf0104d2d
f0100b0d:	68 39 4d 10 f0       	push   $0xf0104d39
f0100b12:	68 8b 02 00 00       	push   $0x28b
f0100b17:	68 13 4d 10 f0       	push   $0xf0104d13
f0100b1c:	e8 7f f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b21:	39 fa                	cmp    %edi,%edx
f0100b23:	72 19                	jb     f0100b3e <check_page_free_list+0x148>
f0100b25:	68 4e 4d 10 f0       	push   $0xf0104d4e
f0100b2a:	68 39 4d 10 f0       	push   $0xf0104d39
f0100b2f:	68 8c 02 00 00       	push   $0x28c
f0100b34:	68 13 4d 10 f0       	push   $0xf0104d13
f0100b39:	e8 62 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b3e:	89 d0                	mov    %edx,%eax
f0100b40:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b43:	a8 07                	test   $0x7,%al
f0100b45:	74 19                	je     f0100b60 <check_page_free_list+0x16a>
f0100b47:	68 64 50 10 f0       	push   $0xf0105064
f0100b4c:	68 39 4d 10 f0       	push   $0xf0104d39
f0100b51:	68 8d 02 00 00       	push   $0x28d
f0100b56:	68 13 4d 10 f0       	push   $0xf0104d13
f0100b5b:	e8 40 f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b60:	c1 f8 03             	sar    $0x3,%eax
f0100b63:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b66:	85 c0                	test   %eax,%eax
f0100b68:	75 19                	jne    f0100b83 <check_page_free_list+0x18d>
f0100b6a:	68 62 4d 10 f0       	push   $0xf0104d62
f0100b6f:	68 39 4d 10 f0       	push   $0xf0104d39
f0100b74:	68 90 02 00 00       	push   $0x290
f0100b79:	68 13 4d 10 f0       	push   $0xf0104d13
f0100b7e:	e8 1d f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b83:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b88:	75 19                	jne    f0100ba3 <check_page_free_list+0x1ad>
f0100b8a:	68 73 4d 10 f0       	push   $0xf0104d73
f0100b8f:	68 39 4d 10 f0       	push   $0xf0104d39
f0100b94:	68 91 02 00 00       	push   $0x291
f0100b99:	68 13 4d 10 f0       	push   $0xf0104d13
f0100b9e:	e8 fd f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ba3:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ba8:	75 19                	jne    f0100bc3 <check_page_free_list+0x1cd>
f0100baa:	68 98 50 10 f0       	push   $0xf0105098
f0100baf:	68 39 4d 10 f0       	push   $0xf0104d39
f0100bb4:	68 92 02 00 00       	push   $0x292
f0100bb9:	68 13 4d 10 f0       	push   $0xf0104d13
f0100bbe:	e8 dd f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bc3:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bc8:	75 19                	jne    f0100be3 <check_page_free_list+0x1ed>
f0100bca:	68 8c 4d 10 f0       	push   $0xf0104d8c
f0100bcf:	68 39 4d 10 f0       	push   $0xf0104d39
f0100bd4:	68 93 02 00 00       	push   $0x293
f0100bd9:	68 13 4d 10 f0       	push   $0xf0104d13
f0100bde:	e8 bd f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100be3:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100be8:	76 3f                	jbe    f0100c29 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bea:	89 c3                	mov    %eax,%ebx
f0100bec:	c1 eb 0c             	shr    $0xc,%ebx
f0100bef:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100bf2:	77 12                	ja     f0100c06 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bf4:	50                   	push   %eax
f0100bf5:	68 1c 50 10 f0       	push   $0xf010501c
f0100bfa:	6a 56                	push   $0x56
f0100bfc:	68 1f 4d 10 f0       	push   $0xf0104d1f
f0100c01:	e8 9a f4 ff ff       	call   f01000a0 <_panic>
f0100c06:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c0b:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c0e:	76 1e                	jbe    f0100c2e <check_page_free_list+0x238>
f0100c10:	68 bc 50 10 f0       	push   $0xf01050bc
f0100c15:	68 39 4d 10 f0       	push   $0xf0104d39
f0100c1a:	68 94 02 00 00       	push   $0x294
f0100c1f:	68 13 4d 10 f0       	push   $0xf0104d13
f0100c24:	e8 77 f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c29:	83 c6 01             	add    $0x1,%esi
f0100c2c:	eb 04                	jmp    f0100c32 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c2e:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c32:	8b 12                	mov    (%edx),%edx
f0100c34:	85 d2                	test   %edx,%edx
f0100c36:	0f 85 c8 fe ff ff    	jne    f0100b04 <check_page_free_list+0x10e>
f0100c3c:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c3f:	85 f6                	test   %esi,%esi
f0100c41:	7f 19                	jg     f0100c5c <check_page_free_list+0x266>
f0100c43:	68 a6 4d 10 f0       	push   $0xf0104da6
f0100c48:	68 39 4d 10 f0       	push   $0xf0104d39
f0100c4d:	68 9c 02 00 00       	push   $0x29c
f0100c52:	68 13 4d 10 f0       	push   $0xf0104d13
f0100c57:	e8 44 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c5c:	85 db                	test   %ebx,%ebx
f0100c5e:	7f 42                	jg     f0100ca2 <check_page_free_list+0x2ac>
f0100c60:	68 b8 4d 10 f0       	push   $0xf0104db8
f0100c65:	68 39 4d 10 f0       	push   $0xf0104d39
f0100c6a:	68 9d 02 00 00       	push   $0x29d
f0100c6f:	68 13 4d 10 f0       	push   $0xf0104d13
f0100c74:	e8 27 f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c79:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
f0100c7e:	85 c0                	test   %eax,%eax
f0100c80:	0f 85 9d fd ff ff    	jne    f0100a23 <check_page_free_list+0x2d>
f0100c86:	e9 81 fd ff ff       	jmp    f0100a0c <check_page_free_list+0x16>
f0100c8b:	83 3d 40 ce 17 f0 00 	cmpl   $0x0,0xf017ce40
f0100c92:	0f 84 74 fd ff ff    	je     f0100a0c <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c98:	be 00 04 00 00       	mov    $0x400,%esi
f0100c9d:	e9 cf fd ff ff       	jmp    f0100a71 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100ca2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ca5:	5b                   	pop    %ebx
f0100ca6:	5e                   	pop    %esi
f0100ca7:	5f                   	pop    %edi
f0100ca8:	5d                   	pop    %ebp
f0100ca9:	c3                   	ret    

f0100caa <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100caa:	55                   	push   %ebp
f0100cab:	89 e5                	mov    %esp,%ebp
f0100cad:	56                   	push   %esi
f0100cae:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100caf:	be 00 00 00 00       	mov    $0x0,%esi
f0100cb4:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cb9:	e9 aa 00 00 00       	jmp    f0100d68 <page_init+0xbe>
		if(i < 1) {//page 0 allocated
f0100cbe:	85 db                	test   %ebx,%ebx
f0100cc0:	75 10                	jne    f0100cd2 <page_init+0x28>
			pages[i].pp_ref = 1;
f0100cc2:	a1 0c db 17 f0       	mov    0xf017db0c,%eax
f0100cc7:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
f0100ccd:	e9 90 00 00 00       	jmp    f0100d62 <page_init+0xb8>
		} else if( i < npages_basemem) {//npages_basemem  free
f0100cd2:	3b 1d 44 ce 17 f0    	cmp    0xf017ce44,%ebx
f0100cd8:	73 25                	jae    f0100cff <page_init+0x55>
			pages[i].pp_ref = 0;
f0100cda:	89 f0                	mov    %esi,%eax
f0100cdc:	03 05 0c db 17 f0    	add    0xf017db0c,%eax
f0100ce2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100ce8:	8b 15 40 ce 17 f0    	mov    0xf017ce40,%edx
f0100cee:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100cf0:	89 f0                	mov    %esi,%eax
f0100cf2:	03 05 0c db 17 f0    	add    0xf017db0c,%eax
f0100cf8:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40
f0100cfd:	eb 63                	jmp    f0100d62 <page_init+0xb8>
		} else if(i < PGNUM(PADDR(boot_alloc(0)))) {//pages allocated
f0100cff:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d04:	e8 2c fc ff ff       	call   f0100935 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d09:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d0e:	77 15                	ja     f0100d25 <page_init+0x7b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d10:	50                   	push   %eax
f0100d11:	68 04 51 10 f0       	push   $0xf0105104
f0100d16:	68 26 01 00 00       	push   $0x126
f0100d1b:	68 13 4d 10 f0       	push   $0xf0104d13
f0100d20:	e8 7b f3 ff ff       	call   f01000a0 <_panic>
f0100d25:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d2a:	c1 e8 0c             	shr    $0xc,%eax
f0100d2d:	39 c3                	cmp    %eax,%ebx
f0100d2f:	73 0e                	jae    f0100d3f <page_init+0x95>
			pages[i].pp_ref = 1;
f0100d31:	a1 0c db 17 f0       	mov    0xf017db0c,%eax
f0100d36:	66 c7 44 30 04 01 00 	movw   $0x1,0x4(%eax,%esi,1)
f0100d3d:	eb 23                	jmp    f0100d62 <page_init+0xb8>
		} else {
			pages[i].pp_ref = 0;
f0100d3f:	89 f0                	mov    %esi,%eax
f0100d41:	03 05 0c db 17 f0    	add    0xf017db0c,%eax
f0100d47:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100d4d:	8b 15 40 ce 17 f0    	mov    0xf017ce40,%edx
f0100d53:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100d55:	89 f0                	mov    %esi,%eax
f0100d57:	03 05 0c db 17 f0    	add    0xf017db0c,%eax
f0100d5d:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100d62:	83 c3 01             	add    $0x1,%ebx
f0100d65:	83 c6 08             	add    $0x8,%esi
f0100d68:	3b 1d 04 db 17 f0    	cmp    0xf017db04,%ebx
f0100d6e:	0f 82 4a ff ff ff    	jb     f0100cbe <page_init+0x14>
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100d74:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d77:	5b                   	pop    %ebx
f0100d78:	5e                   	pop    %esi
f0100d79:	5d                   	pop    %ebp
f0100d7a:	c3                   	ret    

f0100d7b <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d7b:	55                   	push   %ebp
f0100d7c:	89 e5                	mov    %esp,%ebp
f0100d7e:	53                   	push   %ebx
f0100d7f:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if (page_free_list == NULL) {
f0100d82:	8b 1d 40 ce 17 f0    	mov    0xf017ce40,%ebx
f0100d88:	85 db                	test   %ebx,%ebx
f0100d8a:	74 5e                	je     f0100dea <page_alloc+0x6f>
        return NULL;
    }

    struct PageInfo *page = page_free_list;
    page_free_list = page_free_list->pp_link;
f0100d8c:	8b 03                	mov    (%ebx),%eax
f0100d8e:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40
    page->pp_link = NULL;
f0100d93:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
    page->pp_ref = 0;
f0100d99:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

    if (alloc_flags & ALLOC_ZERO) {
f0100d9f:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100da3:	74 45                	je     f0100dea <page_alloc+0x6f>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100da5:	89 d8                	mov    %ebx,%eax
f0100da7:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0100dad:	c1 f8 03             	sar    $0x3,%eax
f0100db0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100db3:	89 c2                	mov    %eax,%edx
f0100db5:	c1 ea 0c             	shr    $0xc,%edx
f0100db8:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0100dbe:	72 12                	jb     f0100dd2 <page_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dc0:	50                   	push   %eax
f0100dc1:	68 1c 50 10 f0       	push   $0xf010501c
f0100dc6:	6a 56                	push   $0x56
f0100dc8:	68 1f 4d 10 f0       	push   $0xf0104d1f
f0100dcd:	e8 ce f2 ff ff       	call   f01000a0 <_panic>
        memset(page2kva(page), '\0', PGSIZE); 
f0100dd2:	83 ec 04             	sub    $0x4,%esp
f0100dd5:	68 00 10 00 00       	push   $0x1000
f0100dda:	6a 00                	push   $0x0
f0100ddc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100de1:	50                   	push   %eax
f0100de2:	e8 38 35 00 00       	call   f010431f <memset>
f0100de7:	83 c4 10             	add    $0x10,%esp
    }

	return page;
}
f0100dea:	89 d8                	mov    %ebx,%eax
f0100dec:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100def:	c9                   	leave  
f0100df0:	c3                   	ret    

f0100df1 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100df1:	55                   	push   %ebp
f0100df2:	89 e5                	mov    %esp,%ebp
f0100df4:	83 ec 08             	sub    $0x8,%esp
f0100df7:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	assert(pp->pp_ref == 0);
f0100dfa:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100dff:	74 19                	je     f0100e1a <page_free+0x29>
f0100e01:	68 c9 4d 10 f0       	push   $0xf0104dc9
f0100e06:	68 39 4d 10 f0       	push   $0xf0104d39
f0100e0b:	68 5a 01 00 00       	push   $0x15a
f0100e10:	68 13 4d 10 f0       	push   $0xf0104d13
f0100e15:	e8 86 f2 ff ff       	call   f01000a0 <_panic>
	assert(pp->pp_link == NULL);
f0100e1a:	83 38 00             	cmpl   $0x0,(%eax)
f0100e1d:	74 19                	je     f0100e38 <page_free+0x47>
f0100e1f:	68 d9 4d 10 f0       	push   $0xf0104dd9
f0100e24:	68 39 4d 10 f0       	push   $0xf0104d39
f0100e29:	68 5b 01 00 00       	push   $0x15b
f0100e2e:	68 13 4d 10 f0       	push   $0xf0104d13
f0100e33:	e8 68 f2 ff ff       	call   f01000a0 <_panic>

	pp->pp_link = page_free_list;
f0100e38:	8b 15 40 ce 17 f0    	mov    0xf017ce40,%edx
f0100e3e:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e40:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40
}
f0100e45:	c9                   	leave  
f0100e46:	c3                   	ret    

f0100e47 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e47:	55                   	push   %ebp
f0100e48:	89 e5                	mov    %esp,%ebp
f0100e4a:	83 ec 08             	sub    $0x8,%esp
f0100e4d:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e50:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e54:	83 e8 01             	sub    $0x1,%eax
f0100e57:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e5b:	66 85 c0             	test   %ax,%ax
f0100e5e:	75 0c                	jne    f0100e6c <page_decref+0x25>
		page_free(pp);
f0100e60:	83 ec 0c             	sub    $0xc,%esp
f0100e63:	52                   	push   %edx
f0100e64:	e8 88 ff ff ff       	call   f0100df1 <page_free>
f0100e69:	83 c4 10             	add    $0x10,%esp
}
f0100e6c:	c9                   	leave  
f0100e6d:	c3                   	ret    

f0100e6e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e6e:	55                   	push   %ebp
f0100e6f:	89 e5                	mov    %esp,%ebp
f0100e71:	56                   	push   %esi
f0100e72:	53                   	push   %ebx
f0100e73:	8b 75 0c             	mov    0xc(%ebp),%esi
	pde_t *pde_pointer = &pgdir[PDX(va)];
f0100e76:	89 f3                	mov    %esi,%ebx
f0100e78:	c1 eb 16             	shr    $0x16,%ebx
f0100e7b:	c1 e3 02             	shl    $0x2,%ebx
f0100e7e:	03 5d 08             	add    0x8(%ebp),%ebx
	if(*pde_pointer & PTE_P) {
f0100e81:	8b 03                	mov    (%ebx),%eax
f0100e83:	a8 01                	test   $0x1,%al
f0100e85:	74 39                	je     f0100ec0 <pgdir_walk+0x52>
		pte_t *page_table =  KADDR(PTE_ADDR(*pde_pointer));
f0100e87:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e8c:	89 c2                	mov    %eax,%edx
f0100e8e:	c1 ea 0c             	shr    $0xc,%edx
f0100e91:	39 15 04 db 17 f0    	cmp    %edx,0xf017db04
f0100e97:	77 15                	ja     f0100eae <pgdir_walk+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e99:	50                   	push   %eax
f0100e9a:	68 1c 50 10 f0       	push   $0xf010501c
f0100e9f:	68 87 01 00 00       	push   $0x187
f0100ea4:	68 13 4d 10 f0       	push   $0xf0104d13
f0100ea9:	e8 f2 f1 ff ff       	call   f01000a0 <_panic>
		return &page_table[PTX(va)];
f0100eae:	c1 ee 0a             	shr    $0xa,%esi
f0100eb1:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100eb7:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100ebe:	eb 72                	jmp    f0100f32 <pgdir_walk+0xc4>
	}

	if(create) {
f0100ec0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ec4:	74 60                	je     f0100f26 <pgdir_walk+0xb8>
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0100ec6:	83 ec 0c             	sub    $0xc,%esp
f0100ec9:	6a 01                	push   $0x1
f0100ecb:	e8 ab fe ff ff       	call   f0100d7b <page_alloc>
		if(page != NULL) {
f0100ed0:	83 c4 10             	add    $0x10,%esp
f0100ed3:	85 c0                	test   %eax,%eax
f0100ed5:	74 56                	je     f0100f2d <pgdir_walk+0xbf>
			page->pp_link = NULL;
f0100ed7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			page->pp_ref++;
f0100edd:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ee2:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0100ee8:	c1 f8 03             	sar    $0x3,%eax
f0100eeb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eee:	89 c2                	mov    %eax,%edx
f0100ef0:	c1 ea 0c             	shr    $0xc,%edx
f0100ef3:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0100ef9:	72 12                	jb     f0100f0d <pgdir_walk+0x9f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100efb:	50                   	push   %eax
f0100efc:	68 1c 50 10 f0       	push   $0xf010501c
f0100f01:	6a 56                	push   $0x56
f0100f03:	68 1f 4d 10 f0       	push   $0xf0104d1f
f0100f08:	e8 93 f1 ff ff       	call   f01000a0 <_panic>

			pte_t *page_table = (pte_t *)page2kva(page);
			*pde_pointer = page2pa(page) | PTE_P | PTE_W | PTE_U;
f0100f0d:	89 c2                	mov    %eax,%edx
f0100f0f:	83 ca 07             	or     $0x7,%edx
f0100f12:	89 13                	mov    %edx,(%ebx)
			return &page_table[PTX(va)];
f0100f14:	c1 ee 0a             	shr    $0xa,%esi
f0100f17:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100f1d:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100f24:	eb 0c                	jmp    f0100f32 <pgdir_walk+0xc4>
		}
	}

	return NULL;
f0100f26:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f2b:	eb 05                	jmp    f0100f32 <pgdir_walk+0xc4>
f0100f2d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100f32:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f35:	5b                   	pop    %ebx
f0100f36:	5e                   	pop    %esi
f0100f37:	5d                   	pop    %ebp
f0100f38:	c3                   	ret    

f0100f39 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f39:	55                   	push   %ebp
f0100f3a:	89 e5                	mov    %esp,%ebp
f0100f3c:	57                   	push   %edi
f0100f3d:	56                   	push   %esi
f0100f3e:	53                   	push   %ebx
f0100f3f:	83 ec 1c             	sub    $0x1c,%esp
f0100f42:	89 45 e0             	mov    %eax,-0x20(%ebp)
	// Fill this function in
	size = ROUNDUP(size, PGSIZE);
f0100f45:	8d b9 ff 0f 00 00    	lea    0xfff(%ecx),%edi
f0100f4b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	for(; size > 0; size-=PGSIZE) {
f0100f51:	89 d6                	mov    %edx,%esi
f0100f53:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f56:	29 d0                	sub    %edx,%eax
f0100f58:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		pte_t* pte_pointer = pgdir_walk(pgdir, (void *)va, 1);
		*pte_pointer = PTE_ADDR(pa) | perm | PTE_P;
f0100f5b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f5e:	83 c8 01             	or     $0x1,%eax
f0100f61:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size = ROUNDUP(size, PGSIZE);
	for(; size > 0; size-=PGSIZE) {
f0100f64:	eb 28                	jmp    f0100f8e <boot_map_region+0x55>
		pte_t* pte_pointer = pgdir_walk(pgdir, (void *)va, 1);
f0100f66:	83 ec 04             	sub    $0x4,%esp
f0100f69:	6a 01                	push   $0x1
f0100f6b:	56                   	push   %esi
f0100f6c:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f6f:	e8 fa fe ff ff       	call   f0100e6e <pgdir_walk>
		*pte_pointer = PTE_ADDR(pa) | perm | PTE_P;
f0100f74:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0100f7a:	0b 5d dc             	or     -0x24(%ebp),%ebx
f0100f7d:	89 18                	mov    %ebx,(%eax)
		va += PGSIZE;
f0100f7f:	81 c6 00 10 00 00    	add    $0x1000,%esi
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size = ROUNDUP(size, PGSIZE);
	for(; size > 0; size-=PGSIZE) {
f0100f85:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f0100f8b:	83 c4 10             	add    $0x10,%esp
f0100f8e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f91:	8d 1c 30             	lea    (%eax,%esi,1),%ebx
f0100f94:	85 ff                	test   %edi,%edi
f0100f96:	75 ce                	jne    f0100f66 <boot_map_region+0x2d>
		pte_t* pte_pointer = pgdir_walk(pgdir, (void *)va, 1);
		*pte_pointer = PTE_ADDR(pa) | perm | PTE_P;
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f0100f98:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f9b:	5b                   	pop    %ebx
f0100f9c:	5e                   	pop    %esi
f0100f9d:	5f                   	pop    %edi
f0100f9e:	5d                   	pop    %ebp
f0100f9f:	c3                   	ret    

f0100fa0 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100fa0:	55                   	push   %ebp
f0100fa1:	89 e5                	mov    %esp,%ebp
f0100fa3:	53                   	push   %ebx
f0100fa4:	83 ec 08             	sub    $0x8,%esp
f0100fa7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte_pointer = pgdir_walk(pgdir, va, 0);
f0100faa:	6a 00                	push   $0x0
f0100fac:	ff 75 0c             	pushl  0xc(%ebp)
f0100faf:	ff 75 08             	pushl  0x8(%ebp)
f0100fb2:	e8 b7 fe ff ff       	call   f0100e6e <pgdir_walk>
    if (pte_pointer == NULL || *pte_pointer == 0) {
f0100fb7:	83 c4 10             	add    $0x10,%esp
f0100fba:	85 c0                	test   %eax,%eax
f0100fbc:	74 37                	je     f0100ff5 <page_lookup+0x55>
f0100fbe:	83 38 00             	cmpl   $0x0,(%eax)
f0100fc1:	74 39                	je     f0100ffc <page_lookup+0x5c>
        return NULL;
    }

    if (pte_store != NULL) {
f0100fc3:	85 db                	test   %ebx,%ebx
f0100fc5:	74 02                	je     f0100fc9 <page_lookup+0x29>
        *pte_store = pte_pointer;
f0100fc7:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fc9:	8b 00                	mov    (%eax),%eax
f0100fcb:	c1 e8 0c             	shr    $0xc,%eax
f0100fce:	3b 05 04 db 17 f0    	cmp    0xf017db04,%eax
f0100fd4:	72 14                	jb     f0100fea <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0100fd6:	83 ec 04             	sub    $0x4,%esp
f0100fd9:	68 28 51 10 f0       	push   $0xf0105128
f0100fde:	6a 4f                	push   $0x4f
f0100fe0:	68 1f 4d 10 f0       	push   $0xf0104d1f
f0100fe5:	e8 b6 f0 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100fea:	8b 15 0c db 17 f0    	mov    0xf017db0c,%edx
f0100ff0:	8d 04 c2             	lea    (%edx,%eax,8),%eax
    }

	return pa2page((physaddr_t) PTE_ADDR(*pte_pointer));
f0100ff3:	eb 0c                	jmp    f0101001 <page_lookup+0x61>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte_pointer = pgdir_walk(pgdir, va, 0);
    if (pte_pointer == NULL || *pte_pointer == 0) {
        return NULL;
f0100ff5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ffa:	eb 05                	jmp    f0101001 <page_lookup+0x61>
f0100ffc:	b8 00 00 00 00       	mov    $0x0,%eax
    if (pte_store != NULL) {
        *pte_store = pte_pointer;
    }

	return pa2page((physaddr_t) PTE_ADDR(*pte_pointer));
}
f0101001:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101004:	c9                   	leave  
f0101005:	c3                   	ret    

f0101006 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101006:	55                   	push   %ebp
f0101007:	89 e5                	mov    %esp,%ebp
f0101009:	53                   	push   %ebx
f010100a:	83 ec 18             	sub    $0x18,%esp
f010100d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte_pointer;
    struct PageInfo *page = page_lookup(pgdir, va, &pte_pointer);
f0101010:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101013:	50                   	push   %eax
f0101014:	53                   	push   %ebx
f0101015:	ff 75 08             	pushl  0x8(%ebp)
f0101018:	e8 83 ff ff ff       	call   f0100fa0 <page_lookup>
    if (page == NULL) {
f010101d:	83 c4 10             	add    $0x10,%esp
f0101020:	85 c0                	test   %eax,%eax
f0101022:	74 18                	je     f010103c <page_remove+0x36>
        return;
    }

    *pte_pointer = 0;
f0101024:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101027:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
    page_decref(page); 
f010102d:	83 ec 0c             	sub    $0xc,%esp
f0101030:	50                   	push   %eax
f0101031:	e8 11 fe ff ff       	call   f0100e47 <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101036:	0f 01 3b             	invlpg (%ebx)
f0101039:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir, va);
}
f010103c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010103f:	c9                   	leave  
f0101040:	c3                   	ret    

f0101041 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101041:	55                   	push   %ebp
f0101042:	89 e5                	mov    %esp,%ebp
f0101044:	57                   	push   %edi
f0101045:	56                   	push   %esi
f0101046:	53                   	push   %ebx
f0101047:	83 ec 10             	sub    $0x10,%esp
f010104a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010104d:	8b 75 10             	mov    0x10(%ebp),%esi
	// Fill this function in
	pte_t* pte_pointer = pgdir_walk(pgdir, va, 1);
f0101050:	6a 01                	push   $0x1
f0101052:	56                   	push   %esi
f0101053:	ff 75 08             	pushl  0x8(%ebp)
f0101056:	e8 13 fe ff ff       	call   f0100e6e <pgdir_walk>
	if(!pte_pointer) {
f010105b:	83 c4 10             	add    $0x10,%esp
f010105e:	85 c0                	test   %eax,%eax
f0101060:	74 3b                	je     f010109d <page_insert+0x5c>
f0101062:	89 c7                	mov    %eax,%edi
		return -E_NO_MEM;
	}

	pp->pp_ref++;
f0101064:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if(*pte_pointer & PTE_P) {
f0101069:	f6 00 01             	testb  $0x1,(%eax)
f010106c:	74 12                	je     f0101080 <page_insert+0x3f>
		page_remove(pgdir, va);
f010106e:	83 ec 08             	sub    $0x8,%esp
f0101071:	56                   	push   %esi
f0101072:	ff 75 08             	pushl  0x8(%ebp)
f0101075:	e8 8c ff ff ff       	call   f0101006 <page_remove>
f010107a:	0f 01 3e             	invlpg (%esi)
f010107d:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}

	*pte_pointer = PTE_ADDR(page2pa(pp)) | PTE_P | perm;
f0101080:	2b 1d 0c db 17 f0    	sub    0xf017db0c,%ebx
f0101086:	c1 fb 03             	sar    $0x3,%ebx
f0101089:	c1 e3 0c             	shl    $0xc,%ebx
f010108c:	8b 45 14             	mov    0x14(%ebp),%eax
f010108f:	83 c8 01             	or     $0x1,%eax
f0101092:	09 c3                	or     %eax,%ebx
f0101094:	89 1f                	mov    %ebx,(%edi)
	return 0;
f0101096:	b8 00 00 00 00       	mov    $0x0,%eax
f010109b:	eb 05                	jmp    f01010a2 <page_insert+0x61>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t* pte_pointer = pgdir_walk(pgdir, va, 1);
	if(!pte_pointer) {
		return -E_NO_MEM;
f010109d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		tlb_invalidate(pgdir, va);
	}

	*pte_pointer = PTE_ADDR(page2pa(pp)) | PTE_P | perm;
	return 0;
}
f01010a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010a5:	5b                   	pop    %ebx
f01010a6:	5e                   	pop    %esi
f01010a7:	5f                   	pop    %edi
f01010a8:	5d                   	pop    %ebp
f01010a9:	c3                   	ret    

f01010aa <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010aa:	55                   	push   %ebp
f01010ab:	89 e5                	mov    %esp,%ebp
f01010ad:	57                   	push   %edi
f01010ae:	56                   	push   %esi
f01010af:	53                   	push   %ebx
f01010b0:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010b3:	6a 15                	push   $0x15
f01010b5:	e8 b3 1e 00 00       	call   f0102f6d <mc146818_read>
f01010ba:	89 c3                	mov    %eax,%ebx
f01010bc:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01010c3:	e8 a5 1e 00 00       	call   f0102f6d <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01010c8:	c1 e0 08             	shl    $0x8,%eax
f01010cb:	09 d8                	or     %ebx,%eax
f01010cd:	c1 e0 0a             	shl    $0xa,%eax
f01010d0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010d6:	85 c0                	test   %eax,%eax
f01010d8:	0f 48 c2             	cmovs  %edx,%eax
f01010db:	c1 f8 0c             	sar    $0xc,%eax
f01010de:	a3 44 ce 17 f0       	mov    %eax,0xf017ce44
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01010e3:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01010ea:	e8 7e 1e 00 00       	call   f0102f6d <mc146818_read>
f01010ef:	89 c3                	mov    %eax,%ebx
f01010f1:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01010f8:	e8 70 1e 00 00       	call   f0102f6d <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01010fd:	c1 e0 08             	shl    $0x8,%eax
f0101100:	09 d8                	or     %ebx,%eax
f0101102:	c1 e0 0a             	shl    $0xa,%eax
f0101105:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010110b:	83 c4 10             	add    $0x10,%esp
f010110e:	85 c0                	test   %eax,%eax
f0101110:	0f 48 c2             	cmovs  %edx,%eax
f0101113:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101116:	85 c0                	test   %eax,%eax
f0101118:	74 0e                	je     f0101128 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010111a:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101120:	89 15 04 db 17 f0    	mov    %edx,0xf017db04
f0101126:	eb 0c                	jmp    f0101134 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101128:	8b 15 44 ce 17 f0    	mov    0xf017ce44,%edx
f010112e:	89 15 04 db 17 f0    	mov    %edx,0xf017db04

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101134:	c1 e0 0c             	shl    $0xc,%eax
f0101137:	c1 e8 0a             	shr    $0xa,%eax
f010113a:	50                   	push   %eax
f010113b:	a1 44 ce 17 f0       	mov    0xf017ce44,%eax
f0101140:	c1 e0 0c             	shl    $0xc,%eax
f0101143:	c1 e8 0a             	shr    $0xa,%eax
f0101146:	50                   	push   %eax
f0101147:	a1 04 db 17 f0       	mov    0xf017db04,%eax
f010114c:	c1 e0 0c             	shl    $0xc,%eax
f010114f:	c1 e8 0a             	shr    $0xa,%eax
f0101152:	50                   	push   %eax
f0101153:	68 48 51 10 f0       	push   $0xf0105148
f0101158:	e8 77 1e 00 00       	call   f0102fd4 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010115d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101162:	e8 ce f7 ff ff       	call   f0100935 <boot_alloc>
f0101167:	a3 08 db 17 f0       	mov    %eax,0xf017db08
	memset(kern_pgdir, 0, PGSIZE);
f010116c:	83 c4 0c             	add    $0xc,%esp
f010116f:	68 00 10 00 00       	push   $0x1000
f0101174:	6a 00                	push   $0x0
f0101176:	50                   	push   %eax
f0101177:	e8 a3 31 00 00       	call   f010431f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010117c:	a1 08 db 17 f0       	mov    0xf017db08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101181:	83 c4 10             	add    $0x10,%esp
f0101184:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101189:	77 15                	ja     f01011a0 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010118b:	50                   	push   %eax
f010118c:	68 04 51 10 f0       	push   $0xf0105104
f0101191:	68 95 00 00 00       	push   $0x95
f0101196:	68 13 4d 10 f0       	push   $0xf0104d13
f010119b:	e8 00 ef ff ff       	call   f01000a0 <_panic>
f01011a0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01011a6:	83 ca 05             	or     $0x5,%edx
f01011a9:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(npages * sizeof(struct PageInfo));
f01011af:	a1 04 db 17 f0       	mov    0xf017db04,%eax
f01011b4:	c1 e0 03             	shl    $0x3,%eax
f01011b7:	e8 79 f7 ff ff       	call   f0100935 <boot_alloc>
f01011bc:	a3 0c db 17 f0       	mov    %eax,0xf017db0c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01011c1:	83 ec 04             	sub    $0x4,%esp
f01011c4:	8b 3d 04 db 17 f0    	mov    0xf017db04,%edi
f01011ca:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f01011d1:	52                   	push   %edx
f01011d2:	6a 00                	push   $0x0
f01011d4:	50                   	push   %eax
f01011d5:	e8 45 31 00 00       	call   f010431f <memset>


	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*) boot_alloc(NENV * sizeof(struct Env));
f01011da:	b8 00 80 01 00       	mov    $0x18000,%eax
f01011df:	e8 51 f7 ff ff       	call   f0100935 <boot_alloc>
f01011e4:	a3 4c ce 17 f0       	mov    %eax,0xf017ce4c
	memset(envs, 0, NENV * sizeof(struct Env));
f01011e9:	83 c4 0c             	add    $0xc,%esp
f01011ec:	68 00 80 01 00       	push   $0x18000
f01011f1:	6a 00                	push   $0x0
f01011f3:	50                   	push   %eax
f01011f4:	e8 26 31 00 00       	call   f010431f <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01011f9:	e8 ac fa ff ff       	call   f0100caa <page_init>

	check_page_free_list(1);
f01011fe:	b8 01 00 00 00       	mov    $0x1,%eax
f0101203:	e8 ee f7 ff ff       	call   f01009f6 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101208:	83 c4 10             	add    $0x10,%esp
f010120b:	83 3d 0c db 17 f0 00 	cmpl   $0x0,0xf017db0c
f0101212:	75 17                	jne    f010122b <mem_init+0x181>
		panic("'pages' is a null pointer!");
f0101214:	83 ec 04             	sub    $0x4,%esp
f0101217:	68 ed 4d 10 f0       	push   $0xf0104ded
f010121c:	68 ae 02 00 00       	push   $0x2ae
f0101221:	68 13 4d 10 f0       	push   $0xf0104d13
f0101226:	e8 75 ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010122b:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
f0101230:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101235:	eb 05                	jmp    f010123c <mem_init+0x192>
		++nfree;
f0101237:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010123a:	8b 00                	mov    (%eax),%eax
f010123c:	85 c0                	test   %eax,%eax
f010123e:	75 f7                	jne    f0101237 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101240:	83 ec 0c             	sub    $0xc,%esp
f0101243:	6a 00                	push   $0x0
f0101245:	e8 31 fb ff ff       	call   f0100d7b <page_alloc>
f010124a:	89 c7                	mov    %eax,%edi
f010124c:	83 c4 10             	add    $0x10,%esp
f010124f:	85 c0                	test   %eax,%eax
f0101251:	75 19                	jne    f010126c <mem_init+0x1c2>
f0101253:	68 08 4e 10 f0       	push   $0xf0104e08
f0101258:	68 39 4d 10 f0       	push   $0xf0104d39
f010125d:	68 b6 02 00 00       	push   $0x2b6
f0101262:	68 13 4d 10 f0       	push   $0xf0104d13
f0101267:	e8 34 ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010126c:	83 ec 0c             	sub    $0xc,%esp
f010126f:	6a 00                	push   $0x0
f0101271:	e8 05 fb ff ff       	call   f0100d7b <page_alloc>
f0101276:	89 c6                	mov    %eax,%esi
f0101278:	83 c4 10             	add    $0x10,%esp
f010127b:	85 c0                	test   %eax,%eax
f010127d:	75 19                	jne    f0101298 <mem_init+0x1ee>
f010127f:	68 1e 4e 10 f0       	push   $0xf0104e1e
f0101284:	68 39 4d 10 f0       	push   $0xf0104d39
f0101289:	68 b7 02 00 00       	push   $0x2b7
f010128e:	68 13 4d 10 f0       	push   $0xf0104d13
f0101293:	e8 08 ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101298:	83 ec 0c             	sub    $0xc,%esp
f010129b:	6a 00                	push   $0x0
f010129d:	e8 d9 fa ff ff       	call   f0100d7b <page_alloc>
f01012a2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012a5:	83 c4 10             	add    $0x10,%esp
f01012a8:	85 c0                	test   %eax,%eax
f01012aa:	75 19                	jne    f01012c5 <mem_init+0x21b>
f01012ac:	68 34 4e 10 f0       	push   $0xf0104e34
f01012b1:	68 39 4d 10 f0       	push   $0xf0104d39
f01012b6:	68 b8 02 00 00       	push   $0x2b8
f01012bb:	68 13 4d 10 f0       	push   $0xf0104d13
f01012c0:	e8 db ed ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012c5:	39 f7                	cmp    %esi,%edi
f01012c7:	75 19                	jne    f01012e2 <mem_init+0x238>
f01012c9:	68 4a 4e 10 f0       	push   $0xf0104e4a
f01012ce:	68 39 4d 10 f0       	push   $0xf0104d39
f01012d3:	68 bb 02 00 00       	push   $0x2bb
f01012d8:	68 13 4d 10 f0       	push   $0xf0104d13
f01012dd:	e8 be ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012e2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012e5:	39 c6                	cmp    %eax,%esi
f01012e7:	74 04                	je     f01012ed <mem_init+0x243>
f01012e9:	39 c7                	cmp    %eax,%edi
f01012eb:	75 19                	jne    f0101306 <mem_init+0x25c>
f01012ed:	68 84 51 10 f0       	push   $0xf0105184
f01012f2:	68 39 4d 10 f0       	push   $0xf0104d39
f01012f7:	68 bc 02 00 00       	push   $0x2bc
f01012fc:	68 13 4d 10 f0       	push   $0xf0104d13
f0101301:	e8 9a ed ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101306:	8b 0d 0c db 17 f0    	mov    0xf017db0c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010130c:	8b 15 04 db 17 f0    	mov    0xf017db04,%edx
f0101312:	c1 e2 0c             	shl    $0xc,%edx
f0101315:	89 f8                	mov    %edi,%eax
f0101317:	29 c8                	sub    %ecx,%eax
f0101319:	c1 f8 03             	sar    $0x3,%eax
f010131c:	c1 e0 0c             	shl    $0xc,%eax
f010131f:	39 d0                	cmp    %edx,%eax
f0101321:	72 19                	jb     f010133c <mem_init+0x292>
f0101323:	68 5c 4e 10 f0       	push   $0xf0104e5c
f0101328:	68 39 4d 10 f0       	push   $0xf0104d39
f010132d:	68 bd 02 00 00       	push   $0x2bd
f0101332:	68 13 4d 10 f0       	push   $0xf0104d13
f0101337:	e8 64 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010133c:	89 f0                	mov    %esi,%eax
f010133e:	29 c8                	sub    %ecx,%eax
f0101340:	c1 f8 03             	sar    $0x3,%eax
f0101343:	c1 e0 0c             	shl    $0xc,%eax
f0101346:	39 c2                	cmp    %eax,%edx
f0101348:	77 19                	ja     f0101363 <mem_init+0x2b9>
f010134a:	68 79 4e 10 f0       	push   $0xf0104e79
f010134f:	68 39 4d 10 f0       	push   $0xf0104d39
f0101354:	68 be 02 00 00       	push   $0x2be
f0101359:	68 13 4d 10 f0       	push   $0xf0104d13
f010135e:	e8 3d ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101363:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101366:	29 c8                	sub    %ecx,%eax
f0101368:	c1 f8 03             	sar    $0x3,%eax
f010136b:	c1 e0 0c             	shl    $0xc,%eax
f010136e:	39 c2                	cmp    %eax,%edx
f0101370:	77 19                	ja     f010138b <mem_init+0x2e1>
f0101372:	68 96 4e 10 f0       	push   $0xf0104e96
f0101377:	68 39 4d 10 f0       	push   $0xf0104d39
f010137c:	68 bf 02 00 00       	push   $0x2bf
f0101381:	68 13 4d 10 f0       	push   $0xf0104d13
f0101386:	e8 15 ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010138b:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
f0101390:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101393:	c7 05 40 ce 17 f0 00 	movl   $0x0,0xf017ce40
f010139a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010139d:	83 ec 0c             	sub    $0xc,%esp
f01013a0:	6a 00                	push   $0x0
f01013a2:	e8 d4 f9 ff ff       	call   f0100d7b <page_alloc>
f01013a7:	83 c4 10             	add    $0x10,%esp
f01013aa:	85 c0                	test   %eax,%eax
f01013ac:	74 19                	je     f01013c7 <mem_init+0x31d>
f01013ae:	68 b3 4e 10 f0       	push   $0xf0104eb3
f01013b3:	68 39 4d 10 f0       	push   $0xf0104d39
f01013b8:	68 c6 02 00 00       	push   $0x2c6
f01013bd:	68 13 4d 10 f0       	push   $0xf0104d13
f01013c2:	e8 d9 ec ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01013c7:	83 ec 0c             	sub    $0xc,%esp
f01013ca:	57                   	push   %edi
f01013cb:	e8 21 fa ff ff       	call   f0100df1 <page_free>
	page_free(pp1);
f01013d0:	89 34 24             	mov    %esi,(%esp)
f01013d3:	e8 19 fa ff ff       	call   f0100df1 <page_free>
	page_free(pp2);
f01013d8:	83 c4 04             	add    $0x4,%esp
f01013db:	ff 75 d4             	pushl  -0x2c(%ebp)
f01013de:	e8 0e fa ff ff       	call   f0100df1 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013ea:	e8 8c f9 ff ff       	call   f0100d7b <page_alloc>
f01013ef:	89 c6                	mov    %eax,%esi
f01013f1:	83 c4 10             	add    $0x10,%esp
f01013f4:	85 c0                	test   %eax,%eax
f01013f6:	75 19                	jne    f0101411 <mem_init+0x367>
f01013f8:	68 08 4e 10 f0       	push   $0xf0104e08
f01013fd:	68 39 4d 10 f0       	push   $0xf0104d39
f0101402:	68 cd 02 00 00       	push   $0x2cd
f0101407:	68 13 4d 10 f0       	push   $0xf0104d13
f010140c:	e8 8f ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101411:	83 ec 0c             	sub    $0xc,%esp
f0101414:	6a 00                	push   $0x0
f0101416:	e8 60 f9 ff ff       	call   f0100d7b <page_alloc>
f010141b:	89 c7                	mov    %eax,%edi
f010141d:	83 c4 10             	add    $0x10,%esp
f0101420:	85 c0                	test   %eax,%eax
f0101422:	75 19                	jne    f010143d <mem_init+0x393>
f0101424:	68 1e 4e 10 f0       	push   $0xf0104e1e
f0101429:	68 39 4d 10 f0       	push   $0xf0104d39
f010142e:	68 ce 02 00 00       	push   $0x2ce
f0101433:	68 13 4d 10 f0       	push   $0xf0104d13
f0101438:	e8 63 ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010143d:	83 ec 0c             	sub    $0xc,%esp
f0101440:	6a 00                	push   $0x0
f0101442:	e8 34 f9 ff ff       	call   f0100d7b <page_alloc>
f0101447:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010144a:	83 c4 10             	add    $0x10,%esp
f010144d:	85 c0                	test   %eax,%eax
f010144f:	75 19                	jne    f010146a <mem_init+0x3c0>
f0101451:	68 34 4e 10 f0       	push   $0xf0104e34
f0101456:	68 39 4d 10 f0       	push   $0xf0104d39
f010145b:	68 cf 02 00 00       	push   $0x2cf
f0101460:	68 13 4d 10 f0       	push   $0xf0104d13
f0101465:	e8 36 ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010146a:	39 fe                	cmp    %edi,%esi
f010146c:	75 19                	jne    f0101487 <mem_init+0x3dd>
f010146e:	68 4a 4e 10 f0       	push   $0xf0104e4a
f0101473:	68 39 4d 10 f0       	push   $0xf0104d39
f0101478:	68 d1 02 00 00       	push   $0x2d1
f010147d:	68 13 4d 10 f0       	push   $0xf0104d13
f0101482:	e8 19 ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101487:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010148a:	39 c7                	cmp    %eax,%edi
f010148c:	74 04                	je     f0101492 <mem_init+0x3e8>
f010148e:	39 c6                	cmp    %eax,%esi
f0101490:	75 19                	jne    f01014ab <mem_init+0x401>
f0101492:	68 84 51 10 f0       	push   $0xf0105184
f0101497:	68 39 4d 10 f0       	push   $0xf0104d39
f010149c:	68 d2 02 00 00       	push   $0x2d2
f01014a1:	68 13 4d 10 f0       	push   $0xf0104d13
f01014a6:	e8 f5 eb ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f01014ab:	83 ec 0c             	sub    $0xc,%esp
f01014ae:	6a 00                	push   $0x0
f01014b0:	e8 c6 f8 ff ff       	call   f0100d7b <page_alloc>
f01014b5:	83 c4 10             	add    $0x10,%esp
f01014b8:	85 c0                	test   %eax,%eax
f01014ba:	74 19                	je     f01014d5 <mem_init+0x42b>
f01014bc:	68 b3 4e 10 f0       	push   $0xf0104eb3
f01014c1:	68 39 4d 10 f0       	push   $0xf0104d39
f01014c6:	68 d3 02 00 00       	push   $0x2d3
f01014cb:	68 13 4d 10 f0       	push   $0xf0104d13
f01014d0:	e8 cb eb ff ff       	call   f01000a0 <_panic>
f01014d5:	89 f0                	mov    %esi,%eax
f01014d7:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f01014dd:	c1 f8 03             	sar    $0x3,%eax
f01014e0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014e3:	89 c2                	mov    %eax,%edx
f01014e5:	c1 ea 0c             	shr    $0xc,%edx
f01014e8:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f01014ee:	72 12                	jb     f0101502 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014f0:	50                   	push   %eax
f01014f1:	68 1c 50 10 f0       	push   $0xf010501c
f01014f6:	6a 56                	push   $0x56
f01014f8:	68 1f 4d 10 f0       	push   $0xf0104d1f
f01014fd:	e8 9e eb ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101502:	83 ec 04             	sub    $0x4,%esp
f0101505:	68 00 10 00 00       	push   $0x1000
f010150a:	6a 01                	push   $0x1
f010150c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101511:	50                   	push   %eax
f0101512:	e8 08 2e 00 00       	call   f010431f <memset>
	page_free(pp0);
f0101517:	89 34 24             	mov    %esi,(%esp)
f010151a:	e8 d2 f8 ff ff       	call   f0100df1 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010151f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101526:	e8 50 f8 ff ff       	call   f0100d7b <page_alloc>
f010152b:	83 c4 10             	add    $0x10,%esp
f010152e:	85 c0                	test   %eax,%eax
f0101530:	75 19                	jne    f010154b <mem_init+0x4a1>
f0101532:	68 c2 4e 10 f0       	push   $0xf0104ec2
f0101537:	68 39 4d 10 f0       	push   $0xf0104d39
f010153c:	68 d8 02 00 00       	push   $0x2d8
f0101541:	68 13 4d 10 f0       	push   $0xf0104d13
f0101546:	e8 55 eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f010154b:	39 c6                	cmp    %eax,%esi
f010154d:	74 19                	je     f0101568 <mem_init+0x4be>
f010154f:	68 e0 4e 10 f0       	push   $0xf0104ee0
f0101554:	68 39 4d 10 f0       	push   $0xf0104d39
f0101559:	68 d9 02 00 00       	push   $0x2d9
f010155e:	68 13 4d 10 f0       	push   $0xf0104d13
f0101563:	e8 38 eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101568:	89 f0                	mov    %esi,%eax
f010156a:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0101570:	c1 f8 03             	sar    $0x3,%eax
f0101573:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101576:	89 c2                	mov    %eax,%edx
f0101578:	c1 ea 0c             	shr    $0xc,%edx
f010157b:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0101581:	72 12                	jb     f0101595 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101583:	50                   	push   %eax
f0101584:	68 1c 50 10 f0       	push   $0xf010501c
f0101589:	6a 56                	push   $0x56
f010158b:	68 1f 4d 10 f0       	push   $0xf0104d1f
f0101590:	e8 0b eb ff ff       	call   f01000a0 <_panic>
f0101595:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010159b:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01015a1:	80 38 00             	cmpb   $0x0,(%eax)
f01015a4:	74 19                	je     f01015bf <mem_init+0x515>
f01015a6:	68 f0 4e 10 f0       	push   $0xf0104ef0
f01015ab:	68 39 4d 10 f0       	push   $0xf0104d39
f01015b0:	68 dc 02 00 00       	push   $0x2dc
f01015b5:	68 13 4d 10 f0       	push   $0xf0104d13
f01015ba:	e8 e1 ea ff ff       	call   f01000a0 <_panic>
f01015bf:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01015c2:	39 d0                	cmp    %edx,%eax
f01015c4:	75 db                	jne    f01015a1 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01015c6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015c9:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40

	// free the pages we took
	page_free(pp0);
f01015ce:	83 ec 0c             	sub    $0xc,%esp
f01015d1:	56                   	push   %esi
f01015d2:	e8 1a f8 ff ff       	call   f0100df1 <page_free>
	page_free(pp1);
f01015d7:	89 3c 24             	mov    %edi,(%esp)
f01015da:	e8 12 f8 ff ff       	call   f0100df1 <page_free>
	page_free(pp2);
f01015df:	83 c4 04             	add    $0x4,%esp
f01015e2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015e5:	e8 07 f8 ff ff       	call   f0100df1 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015ea:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
f01015ef:	83 c4 10             	add    $0x10,%esp
f01015f2:	eb 05                	jmp    f01015f9 <mem_init+0x54f>
		--nfree;
f01015f4:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015f7:	8b 00                	mov    (%eax),%eax
f01015f9:	85 c0                	test   %eax,%eax
f01015fb:	75 f7                	jne    f01015f4 <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f01015fd:	85 db                	test   %ebx,%ebx
f01015ff:	74 19                	je     f010161a <mem_init+0x570>
f0101601:	68 fa 4e 10 f0       	push   $0xf0104efa
f0101606:	68 39 4d 10 f0       	push   $0xf0104d39
f010160b:	68 e9 02 00 00       	push   $0x2e9
f0101610:	68 13 4d 10 f0       	push   $0xf0104d13
f0101615:	e8 86 ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010161a:	83 ec 0c             	sub    $0xc,%esp
f010161d:	68 a4 51 10 f0       	push   $0xf01051a4
f0101622:	e8 ad 19 00 00       	call   f0102fd4 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101627:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010162e:	e8 48 f7 ff ff       	call   f0100d7b <page_alloc>
f0101633:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101636:	83 c4 10             	add    $0x10,%esp
f0101639:	85 c0                	test   %eax,%eax
f010163b:	75 19                	jne    f0101656 <mem_init+0x5ac>
f010163d:	68 08 4e 10 f0       	push   $0xf0104e08
f0101642:	68 39 4d 10 f0       	push   $0xf0104d39
f0101647:	68 47 03 00 00       	push   $0x347
f010164c:	68 13 4d 10 f0       	push   $0xf0104d13
f0101651:	e8 4a ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101656:	83 ec 0c             	sub    $0xc,%esp
f0101659:	6a 00                	push   $0x0
f010165b:	e8 1b f7 ff ff       	call   f0100d7b <page_alloc>
f0101660:	89 c3                	mov    %eax,%ebx
f0101662:	83 c4 10             	add    $0x10,%esp
f0101665:	85 c0                	test   %eax,%eax
f0101667:	75 19                	jne    f0101682 <mem_init+0x5d8>
f0101669:	68 1e 4e 10 f0       	push   $0xf0104e1e
f010166e:	68 39 4d 10 f0       	push   $0xf0104d39
f0101673:	68 48 03 00 00       	push   $0x348
f0101678:	68 13 4d 10 f0       	push   $0xf0104d13
f010167d:	e8 1e ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101682:	83 ec 0c             	sub    $0xc,%esp
f0101685:	6a 00                	push   $0x0
f0101687:	e8 ef f6 ff ff       	call   f0100d7b <page_alloc>
f010168c:	89 c6                	mov    %eax,%esi
f010168e:	83 c4 10             	add    $0x10,%esp
f0101691:	85 c0                	test   %eax,%eax
f0101693:	75 19                	jne    f01016ae <mem_init+0x604>
f0101695:	68 34 4e 10 f0       	push   $0xf0104e34
f010169a:	68 39 4d 10 f0       	push   $0xf0104d39
f010169f:	68 49 03 00 00       	push   $0x349
f01016a4:	68 13 4d 10 f0       	push   $0xf0104d13
f01016a9:	e8 f2 e9 ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016ae:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01016b1:	75 19                	jne    f01016cc <mem_init+0x622>
f01016b3:	68 4a 4e 10 f0       	push   $0xf0104e4a
f01016b8:	68 39 4d 10 f0       	push   $0xf0104d39
f01016bd:	68 4c 03 00 00       	push   $0x34c
f01016c2:	68 13 4d 10 f0       	push   $0xf0104d13
f01016c7:	e8 d4 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016cc:	39 c3                	cmp    %eax,%ebx
f01016ce:	74 05                	je     f01016d5 <mem_init+0x62b>
f01016d0:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01016d3:	75 19                	jne    f01016ee <mem_init+0x644>
f01016d5:	68 84 51 10 f0       	push   $0xf0105184
f01016da:	68 39 4d 10 f0       	push   $0xf0104d39
f01016df:	68 4d 03 00 00       	push   $0x34d
f01016e4:	68 13 4d 10 f0       	push   $0xf0104d13
f01016e9:	e8 b2 e9 ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016ee:	a1 40 ce 17 f0       	mov    0xf017ce40,%eax
f01016f3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016f6:	c7 05 40 ce 17 f0 00 	movl   $0x0,0xf017ce40
f01016fd:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101700:	83 ec 0c             	sub    $0xc,%esp
f0101703:	6a 00                	push   $0x0
f0101705:	e8 71 f6 ff ff       	call   f0100d7b <page_alloc>
f010170a:	83 c4 10             	add    $0x10,%esp
f010170d:	85 c0                	test   %eax,%eax
f010170f:	74 19                	je     f010172a <mem_init+0x680>
f0101711:	68 b3 4e 10 f0       	push   $0xf0104eb3
f0101716:	68 39 4d 10 f0       	push   $0xf0104d39
f010171b:	68 54 03 00 00       	push   $0x354
f0101720:	68 13 4d 10 f0       	push   $0xf0104d13
f0101725:	e8 76 e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010172a:	83 ec 04             	sub    $0x4,%esp
f010172d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101730:	50                   	push   %eax
f0101731:	6a 00                	push   $0x0
f0101733:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101739:	e8 62 f8 ff ff       	call   f0100fa0 <page_lookup>
f010173e:	83 c4 10             	add    $0x10,%esp
f0101741:	85 c0                	test   %eax,%eax
f0101743:	74 19                	je     f010175e <mem_init+0x6b4>
f0101745:	68 c4 51 10 f0       	push   $0xf01051c4
f010174a:	68 39 4d 10 f0       	push   $0xf0104d39
f010174f:	68 57 03 00 00       	push   $0x357
f0101754:	68 13 4d 10 f0       	push   $0xf0104d13
f0101759:	e8 42 e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010175e:	6a 02                	push   $0x2
f0101760:	6a 00                	push   $0x0
f0101762:	53                   	push   %ebx
f0101763:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101769:	e8 d3 f8 ff ff       	call   f0101041 <page_insert>
f010176e:	83 c4 10             	add    $0x10,%esp
f0101771:	85 c0                	test   %eax,%eax
f0101773:	78 19                	js     f010178e <mem_init+0x6e4>
f0101775:	68 fc 51 10 f0       	push   $0xf01051fc
f010177a:	68 39 4d 10 f0       	push   $0xf0104d39
f010177f:	68 5a 03 00 00       	push   $0x35a
f0101784:	68 13 4d 10 f0       	push   $0xf0104d13
f0101789:	e8 12 e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010178e:	83 ec 0c             	sub    $0xc,%esp
f0101791:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101794:	e8 58 f6 ff ff       	call   f0100df1 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101799:	6a 02                	push   $0x2
f010179b:	6a 00                	push   $0x0
f010179d:	53                   	push   %ebx
f010179e:	ff 35 08 db 17 f0    	pushl  0xf017db08
f01017a4:	e8 98 f8 ff ff       	call   f0101041 <page_insert>
f01017a9:	83 c4 20             	add    $0x20,%esp
f01017ac:	85 c0                	test   %eax,%eax
f01017ae:	74 19                	je     f01017c9 <mem_init+0x71f>
f01017b0:	68 2c 52 10 f0       	push   $0xf010522c
f01017b5:	68 39 4d 10 f0       	push   $0xf0104d39
f01017ba:	68 5e 03 00 00       	push   $0x35e
f01017bf:	68 13 4d 10 f0       	push   $0xf0104d13
f01017c4:	e8 d7 e8 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01017c9:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017cf:	a1 0c db 17 f0       	mov    0xf017db0c,%eax
f01017d4:	89 c1                	mov    %eax,%ecx
f01017d6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01017d9:	8b 17                	mov    (%edi),%edx
f01017db:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01017e1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017e4:	29 c8                	sub    %ecx,%eax
f01017e6:	c1 f8 03             	sar    $0x3,%eax
f01017e9:	c1 e0 0c             	shl    $0xc,%eax
f01017ec:	39 c2                	cmp    %eax,%edx
f01017ee:	74 19                	je     f0101809 <mem_init+0x75f>
f01017f0:	68 5c 52 10 f0       	push   $0xf010525c
f01017f5:	68 39 4d 10 f0       	push   $0xf0104d39
f01017fa:	68 5f 03 00 00       	push   $0x35f
f01017ff:	68 13 4d 10 f0       	push   $0xf0104d13
f0101804:	e8 97 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101809:	ba 00 00 00 00       	mov    $0x0,%edx
f010180e:	89 f8                	mov    %edi,%eax
f0101810:	e8 7d f1 ff ff       	call   f0100992 <check_va2pa>
f0101815:	89 da                	mov    %ebx,%edx
f0101817:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010181a:	c1 fa 03             	sar    $0x3,%edx
f010181d:	c1 e2 0c             	shl    $0xc,%edx
f0101820:	39 d0                	cmp    %edx,%eax
f0101822:	74 19                	je     f010183d <mem_init+0x793>
f0101824:	68 84 52 10 f0       	push   $0xf0105284
f0101829:	68 39 4d 10 f0       	push   $0xf0104d39
f010182e:	68 60 03 00 00       	push   $0x360
f0101833:	68 13 4d 10 f0       	push   $0xf0104d13
f0101838:	e8 63 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f010183d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101842:	74 19                	je     f010185d <mem_init+0x7b3>
f0101844:	68 05 4f 10 f0       	push   $0xf0104f05
f0101849:	68 39 4d 10 f0       	push   $0xf0104d39
f010184e:	68 61 03 00 00       	push   $0x361
f0101853:	68 13 4d 10 f0       	push   $0xf0104d13
f0101858:	e8 43 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f010185d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101860:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101865:	74 19                	je     f0101880 <mem_init+0x7d6>
f0101867:	68 16 4f 10 f0       	push   $0xf0104f16
f010186c:	68 39 4d 10 f0       	push   $0xf0104d39
f0101871:	68 62 03 00 00       	push   $0x362
f0101876:	68 13 4d 10 f0       	push   $0xf0104d13
f010187b:	e8 20 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101880:	6a 02                	push   $0x2
f0101882:	68 00 10 00 00       	push   $0x1000
f0101887:	56                   	push   %esi
f0101888:	57                   	push   %edi
f0101889:	e8 b3 f7 ff ff       	call   f0101041 <page_insert>
f010188e:	83 c4 10             	add    $0x10,%esp
f0101891:	85 c0                	test   %eax,%eax
f0101893:	74 19                	je     f01018ae <mem_init+0x804>
f0101895:	68 b4 52 10 f0       	push   $0xf01052b4
f010189a:	68 39 4d 10 f0       	push   $0xf0104d39
f010189f:	68 65 03 00 00       	push   $0x365
f01018a4:	68 13 4d 10 f0       	push   $0xf0104d13
f01018a9:	e8 f2 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018ae:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018b3:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f01018b8:	e8 d5 f0 ff ff       	call   f0100992 <check_va2pa>
f01018bd:	89 f2                	mov    %esi,%edx
f01018bf:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f01018c5:	c1 fa 03             	sar    $0x3,%edx
f01018c8:	c1 e2 0c             	shl    $0xc,%edx
f01018cb:	39 d0                	cmp    %edx,%eax
f01018cd:	74 19                	je     f01018e8 <mem_init+0x83e>
f01018cf:	68 f0 52 10 f0       	push   $0xf01052f0
f01018d4:	68 39 4d 10 f0       	push   $0xf0104d39
f01018d9:	68 66 03 00 00       	push   $0x366
f01018de:	68 13 4d 10 f0       	push   $0xf0104d13
f01018e3:	e8 b8 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01018e8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018ed:	74 19                	je     f0101908 <mem_init+0x85e>
f01018ef:	68 27 4f 10 f0       	push   $0xf0104f27
f01018f4:	68 39 4d 10 f0       	push   $0xf0104d39
f01018f9:	68 67 03 00 00       	push   $0x367
f01018fe:	68 13 4d 10 f0       	push   $0xf0104d13
f0101903:	e8 98 e7 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101908:	83 ec 0c             	sub    $0xc,%esp
f010190b:	6a 00                	push   $0x0
f010190d:	e8 69 f4 ff ff       	call   f0100d7b <page_alloc>
f0101912:	83 c4 10             	add    $0x10,%esp
f0101915:	85 c0                	test   %eax,%eax
f0101917:	74 19                	je     f0101932 <mem_init+0x888>
f0101919:	68 b3 4e 10 f0       	push   $0xf0104eb3
f010191e:	68 39 4d 10 f0       	push   $0xf0104d39
f0101923:	68 6a 03 00 00       	push   $0x36a
f0101928:	68 13 4d 10 f0       	push   $0xf0104d13
f010192d:	e8 6e e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101932:	6a 02                	push   $0x2
f0101934:	68 00 10 00 00       	push   $0x1000
f0101939:	56                   	push   %esi
f010193a:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101940:	e8 fc f6 ff ff       	call   f0101041 <page_insert>
f0101945:	83 c4 10             	add    $0x10,%esp
f0101948:	85 c0                	test   %eax,%eax
f010194a:	74 19                	je     f0101965 <mem_init+0x8bb>
f010194c:	68 b4 52 10 f0       	push   $0xf01052b4
f0101951:	68 39 4d 10 f0       	push   $0xf0104d39
f0101956:	68 6d 03 00 00       	push   $0x36d
f010195b:	68 13 4d 10 f0       	push   $0xf0104d13
f0101960:	e8 3b e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101965:	ba 00 10 00 00       	mov    $0x1000,%edx
f010196a:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f010196f:	e8 1e f0 ff ff       	call   f0100992 <check_va2pa>
f0101974:	89 f2                	mov    %esi,%edx
f0101976:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f010197c:	c1 fa 03             	sar    $0x3,%edx
f010197f:	c1 e2 0c             	shl    $0xc,%edx
f0101982:	39 d0                	cmp    %edx,%eax
f0101984:	74 19                	je     f010199f <mem_init+0x8f5>
f0101986:	68 f0 52 10 f0       	push   $0xf01052f0
f010198b:	68 39 4d 10 f0       	push   $0xf0104d39
f0101990:	68 6e 03 00 00       	push   $0x36e
f0101995:	68 13 4d 10 f0       	push   $0xf0104d13
f010199a:	e8 01 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010199f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019a4:	74 19                	je     f01019bf <mem_init+0x915>
f01019a6:	68 27 4f 10 f0       	push   $0xf0104f27
f01019ab:	68 39 4d 10 f0       	push   $0xf0104d39
f01019b0:	68 6f 03 00 00       	push   $0x36f
f01019b5:	68 13 4d 10 f0       	push   $0xf0104d13
f01019ba:	e8 e1 e6 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01019bf:	83 ec 0c             	sub    $0xc,%esp
f01019c2:	6a 00                	push   $0x0
f01019c4:	e8 b2 f3 ff ff       	call   f0100d7b <page_alloc>
f01019c9:	83 c4 10             	add    $0x10,%esp
f01019cc:	85 c0                	test   %eax,%eax
f01019ce:	74 19                	je     f01019e9 <mem_init+0x93f>
f01019d0:	68 b3 4e 10 f0       	push   $0xf0104eb3
f01019d5:	68 39 4d 10 f0       	push   $0xf0104d39
f01019da:	68 73 03 00 00       	push   $0x373
f01019df:	68 13 4d 10 f0       	push   $0xf0104d13
f01019e4:	e8 b7 e6 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01019e9:	8b 15 08 db 17 f0    	mov    0xf017db08,%edx
f01019ef:	8b 02                	mov    (%edx),%eax
f01019f1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019f6:	89 c1                	mov    %eax,%ecx
f01019f8:	c1 e9 0c             	shr    $0xc,%ecx
f01019fb:	3b 0d 04 db 17 f0    	cmp    0xf017db04,%ecx
f0101a01:	72 15                	jb     f0101a18 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a03:	50                   	push   %eax
f0101a04:	68 1c 50 10 f0       	push   $0xf010501c
f0101a09:	68 76 03 00 00       	push   $0x376
f0101a0e:	68 13 4d 10 f0       	push   $0xf0104d13
f0101a13:	e8 88 e6 ff ff       	call   f01000a0 <_panic>
f0101a18:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a1d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a20:	83 ec 04             	sub    $0x4,%esp
f0101a23:	6a 00                	push   $0x0
f0101a25:	68 00 10 00 00       	push   $0x1000
f0101a2a:	52                   	push   %edx
f0101a2b:	e8 3e f4 ff ff       	call   f0100e6e <pgdir_walk>
f0101a30:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a33:	8d 57 04             	lea    0x4(%edi),%edx
f0101a36:	83 c4 10             	add    $0x10,%esp
f0101a39:	39 d0                	cmp    %edx,%eax
f0101a3b:	74 19                	je     f0101a56 <mem_init+0x9ac>
f0101a3d:	68 20 53 10 f0       	push   $0xf0105320
f0101a42:	68 39 4d 10 f0       	push   $0xf0104d39
f0101a47:	68 77 03 00 00       	push   $0x377
f0101a4c:	68 13 4d 10 f0       	push   $0xf0104d13
f0101a51:	e8 4a e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101a56:	6a 06                	push   $0x6
f0101a58:	68 00 10 00 00       	push   $0x1000
f0101a5d:	56                   	push   %esi
f0101a5e:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101a64:	e8 d8 f5 ff ff       	call   f0101041 <page_insert>
f0101a69:	83 c4 10             	add    $0x10,%esp
f0101a6c:	85 c0                	test   %eax,%eax
f0101a6e:	74 19                	je     f0101a89 <mem_init+0x9df>
f0101a70:	68 60 53 10 f0       	push   $0xf0105360
f0101a75:	68 39 4d 10 f0       	push   $0xf0104d39
f0101a7a:	68 7a 03 00 00       	push   $0x37a
f0101a7f:	68 13 4d 10 f0       	push   $0xf0104d13
f0101a84:	e8 17 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a89:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
f0101a8f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a94:	89 f8                	mov    %edi,%eax
f0101a96:	e8 f7 ee ff ff       	call   f0100992 <check_va2pa>
f0101a9b:	89 f2                	mov    %esi,%edx
f0101a9d:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f0101aa3:	c1 fa 03             	sar    $0x3,%edx
f0101aa6:	c1 e2 0c             	shl    $0xc,%edx
f0101aa9:	39 d0                	cmp    %edx,%eax
f0101aab:	74 19                	je     f0101ac6 <mem_init+0xa1c>
f0101aad:	68 f0 52 10 f0       	push   $0xf01052f0
f0101ab2:	68 39 4d 10 f0       	push   $0xf0104d39
f0101ab7:	68 7b 03 00 00       	push   $0x37b
f0101abc:	68 13 4d 10 f0       	push   $0xf0104d13
f0101ac1:	e8 da e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101ac6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101acb:	74 19                	je     f0101ae6 <mem_init+0xa3c>
f0101acd:	68 27 4f 10 f0       	push   $0xf0104f27
f0101ad2:	68 39 4d 10 f0       	push   $0xf0104d39
f0101ad7:	68 7c 03 00 00       	push   $0x37c
f0101adc:	68 13 4d 10 f0       	push   $0xf0104d13
f0101ae1:	e8 ba e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ae6:	83 ec 04             	sub    $0x4,%esp
f0101ae9:	6a 00                	push   $0x0
f0101aeb:	68 00 10 00 00       	push   $0x1000
f0101af0:	57                   	push   %edi
f0101af1:	e8 78 f3 ff ff       	call   f0100e6e <pgdir_walk>
f0101af6:	83 c4 10             	add    $0x10,%esp
f0101af9:	f6 00 04             	testb  $0x4,(%eax)
f0101afc:	75 19                	jne    f0101b17 <mem_init+0xa6d>
f0101afe:	68 a0 53 10 f0       	push   $0xf01053a0
f0101b03:	68 39 4d 10 f0       	push   $0xf0104d39
f0101b08:	68 7d 03 00 00       	push   $0x37d
f0101b0d:	68 13 4d 10 f0       	push   $0xf0104d13
f0101b12:	e8 89 e5 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101b17:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0101b1c:	f6 00 04             	testb  $0x4,(%eax)
f0101b1f:	75 19                	jne    f0101b3a <mem_init+0xa90>
f0101b21:	68 38 4f 10 f0       	push   $0xf0104f38
f0101b26:	68 39 4d 10 f0       	push   $0xf0104d39
f0101b2b:	68 7e 03 00 00       	push   $0x37e
f0101b30:	68 13 4d 10 f0       	push   $0xf0104d13
f0101b35:	e8 66 e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b3a:	6a 02                	push   $0x2
f0101b3c:	68 00 10 00 00       	push   $0x1000
f0101b41:	56                   	push   %esi
f0101b42:	50                   	push   %eax
f0101b43:	e8 f9 f4 ff ff       	call   f0101041 <page_insert>
f0101b48:	83 c4 10             	add    $0x10,%esp
f0101b4b:	85 c0                	test   %eax,%eax
f0101b4d:	74 19                	je     f0101b68 <mem_init+0xabe>
f0101b4f:	68 b4 52 10 f0       	push   $0xf01052b4
f0101b54:	68 39 4d 10 f0       	push   $0xf0104d39
f0101b59:	68 81 03 00 00       	push   $0x381
f0101b5e:	68 13 4d 10 f0       	push   $0xf0104d13
f0101b63:	e8 38 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b68:	83 ec 04             	sub    $0x4,%esp
f0101b6b:	6a 00                	push   $0x0
f0101b6d:	68 00 10 00 00       	push   $0x1000
f0101b72:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101b78:	e8 f1 f2 ff ff       	call   f0100e6e <pgdir_walk>
f0101b7d:	83 c4 10             	add    $0x10,%esp
f0101b80:	f6 00 02             	testb  $0x2,(%eax)
f0101b83:	75 19                	jne    f0101b9e <mem_init+0xaf4>
f0101b85:	68 d4 53 10 f0       	push   $0xf01053d4
f0101b8a:	68 39 4d 10 f0       	push   $0xf0104d39
f0101b8f:	68 82 03 00 00       	push   $0x382
f0101b94:	68 13 4d 10 f0       	push   $0xf0104d13
f0101b99:	e8 02 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b9e:	83 ec 04             	sub    $0x4,%esp
f0101ba1:	6a 00                	push   $0x0
f0101ba3:	68 00 10 00 00       	push   $0x1000
f0101ba8:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101bae:	e8 bb f2 ff ff       	call   f0100e6e <pgdir_walk>
f0101bb3:	83 c4 10             	add    $0x10,%esp
f0101bb6:	f6 00 04             	testb  $0x4,(%eax)
f0101bb9:	74 19                	je     f0101bd4 <mem_init+0xb2a>
f0101bbb:	68 08 54 10 f0       	push   $0xf0105408
f0101bc0:	68 39 4d 10 f0       	push   $0xf0104d39
f0101bc5:	68 83 03 00 00       	push   $0x383
f0101bca:	68 13 4d 10 f0       	push   $0xf0104d13
f0101bcf:	e8 cc e4 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101bd4:	6a 02                	push   $0x2
f0101bd6:	68 00 00 40 00       	push   $0x400000
f0101bdb:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bde:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101be4:	e8 58 f4 ff ff       	call   f0101041 <page_insert>
f0101be9:	83 c4 10             	add    $0x10,%esp
f0101bec:	85 c0                	test   %eax,%eax
f0101bee:	78 19                	js     f0101c09 <mem_init+0xb5f>
f0101bf0:	68 40 54 10 f0       	push   $0xf0105440
f0101bf5:	68 39 4d 10 f0       	push   $0xf0104d39
f0101bfa:	68 86 03 00 00       	push   $0x386
f0101bff:	68 13 4d 10 f0       	push   $0xf0104d13
f0101c04:	e8 97 e4 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c09:	6a 02                	push   $0x2
f0101c0b:	68 00 10 00 00       	push   $0x1000
f0101c10:	53                   	push   %ebx
f0101c11:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101c17:	e8 25 f4 ff ff       	call   f0101041 <page_insert>
f0101c1c:	83 c4 10             	add    $0x10,%esp
f0101c1f:	85 c0                	test   %eax,%eax
f0101c21:	74 19                	je     f0101c3c <mem_init+0xb92>
f0101c23:	68 78 54 10 f0       	push   $0xf0105478
f0101c28:	68 39 4d 10 f0       	push   $0xf0104d39
f0101c2d:	68 89 03 00 00       	push   $0x389
f0101c32:	68 13 4d 10 f0       	push   $0xf0104d13
f0101c37:	e8 64 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c3c:	83 ec 04             	sub    $0x4,%esp
f0101c3f:	6a 00                	push   $0x0
f0101c41:	68 00 10 00 00       	push   $0x1000
f0101c46:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101c4c:	e8 1d f2 ff ff       	call   f0100e6e <pgdir_walk>
f0101c51:	83 c4 10             	add    $0x10,%esp
f0101c54:	f6 00 04             	testb  $0x4,(%eax)
f0101c57:	74 19                	je     f0101c72 <mem_init+0xbc8>
f0101c59:	68 08 54 10 f0       	push   $0xf0105408
f0101c5e:	68 39 4d 10 f0       	push   $0xf0104d39
f0101c63:	68 8a 03 00 00       	push   $0x38a
f0101c68:	68 13 4d 10 f0       	push   $0xf0104d13
f0101c6d:	e8 2e e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c72:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
f0101c78:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c7d:	89 f8                	mov    %edi,%eax
f0101c7f:	e8 0e ed ff ff       	call   f0100992 <check_va2pa>
f0101c84:	89 c1                	mov    %eax,%ecx
f0101c86:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c89:	89 d8                	mov    %ebx,%eax
f0101c8b:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0101c91:	c1 f8 03             	sar    $0x3,%eax
f0101c94:	c1 e0 0c             	shl    $0xc,%eax
f0101c97:	39 c1                	cmp    %eax,%ecx
f0101c99:	74 19                	je     f0101cb4 <mem_init+0xc0a>
f0101c9b:	68 b4 54 10 f0       	push   $0xf01054b4
f0101ca0:	68 39 4d 10 f0       	push   $0xf0104d39
f0101ca5:	68 8d 03 00 00       	push   $0x38d
f0101caa:	68 13 4d 10 f0       	push   $0xf0104d13
f0101caf:	e8 ec e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cb4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cb9:	89 f8                	mov    %edi,%eax
f0101cbb:	e8 d2 ec ff ff       	call   f0100992 <check_va2pa>
f0101cc0:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101cc3:	74 19                	je     f0101cde <mem_init+0xc34>
f0101cc5:	68 e0 54 10 f0       	push   $0xf01054e0
f0101cca:	68 39 4d 10 f0       	push   $0xf0104d39
f0101ccf:	68 8e 03 00 00       	push   $0x38e
f0101cd4:	68 13 4d 10 f0       	push   $0xf0104d13
f0101cd9:	e8 c2 e3 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101cde:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ce3:	74 19                	je     f0101cfe <mem_init+0xc54>
f0101ce5:	68 4e 4f 10 f0       	push   $0xf0104f4e
f0101cea:	68 39 4d 10 f0       	push   $0xf0104d39
f0101cef:	68 90 03 00 00       	push   $0x390
f0101cf4:	68 13 4d 10 f0       	push   $0xf0104d13
f0101cf9:	e8 a2 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101cfe:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d03:	74 19                	je     f0101d1e <mem_init+0xc74>
f0101d05:	68 5f 4f 10 f0       	push   $0xf0104f5f
f0101d0a:	68 39 4d 10 f0       	push   $0xf0104d39
f0101d0f:	68 91 03 00 00       	push   $0x391
f0101d14:	68 13 4d 10 f0       	push   $0xf0104d13
f0101d19:	e8 82 e3 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d1e:	83 ec 0c             	sub    $0xc,%esp
f0101d21:	6a 00                	push   $0x0
f0101d23:	e8 53 f0 ff ff       	call   f0100d7b <page_alloc>
f0101d28:	83 c4 10             	add    $0x10,%esp
f0101d2b:	85 c0                	test   %eax,%eax
f0101d2d:	74 04                	je     f0101d33 <mem_init+0xc89>
f0101d2f:	39 c6                	cmp    %eax,%esi
f0101d31:	74 19                	je     f0101d4c <mem_init+0xca2>
f0101d33:	68 10 55 10 f0       	push   $0xf0105510
f0101d38:	68 39 4d 10 f0       	push   $0xf0104d39
f0101d3d:	68 94 03 00 00       	push   $0x394
f0101d42:	68 13 4d 10 f0       	push   $0xf0104d13
f0101d47:	e8 54 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d4c:	83 ec 08             	sub    $0x8,%esp
f0101d4f:	6a 00                	push   $0x0
f0101d51:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101d57:	e8 aa f2 ff ff       	call   f0101006 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d5c:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
f0101d62:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d67:	89 f8                	mov    %edi,%eax
f0101d69:	e8 24 ec ff ff       	call   f0100992 <check_va2pa>
f0101d6e:	83 c4 10             	add    $0x10,%esp
f0101d71:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d74:	74 19                	je     f0101d8f <mem_init+0xce5>
f0101d76:	68 34 55 10 f0       	push   $0xf0105534
f0101d7b:	68 39 4d 10 f0       	push   $0xf0104d39
f0101d80:	68 98 03 00 00       	push   $0x398
f0101d85:	68 13 4d 10 f0       	push   $0xf0104d13
f0101d8a:	e8 11 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d8f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d94:	89 f8                	mov    %edi,%eax
f0101d96:	e8 f7 eb ff ff       	call   f0100992 <check_va2pa>
f0101d9b:	89 da                	mov    %ebx,%edx
f0101d9d:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f0101da3:	c1 fa 03             	sar    $0x3,%edx
f0101da6:	c1 e2 0c             	shl    $0xc,%edx
f0101da9:	39 d0                	cmp    %edx,%eax
f0101dab:	74 19                	je     f0101dc6 <mem_init+0xd1c>
f0101dad:	68 e0 54 10 f0       	push   $0xf01054e0
f0101db2:	68 39 4d 10 f0       	push   $0xf0104d39
f0101db7:	68 99 03 00 00       	push   $0x399
f0101dbc:	68 13 4d 10 f0       	push   $0xf0104d13
f0101dc1:	e8 da e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101dc6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101dcb:	74 19                	je     f0101de6 <mem_init+0xd3c>
f0101dcd:	68 05 4f 10 f0       	push   $0xf0104f05
f0101dd2:	68 39 4d 10 f0       	push   $0xf0104d39
f0101dd7:	68 9a 03 00 00       	push   $0x39a
f0101ddc:	68 13 4d 10 f0       	push   $0xf0104d13
f0101de1:	e8 ba e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101de6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101deb:	74 19                	je     f0101e06 <mem_init+0xd5c>
f0101ded:	68 5f 4f 10 f0       	push   $0xf0104f5f
f0101df2:	68 39 4d 10 f0       	push   $0xf0104d39
f0101df7:	68 9b 03 00 00       	push   $0x39b
f0101dfc:	68 13 4d 10 f0       	push   $0xf0104d13
f0101e01:	e8 9a e2 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e06:	6a 00                	push   $0x0
f0101e08:	68 00 10 00 00       	push   $0x1000
f0101e0d:	53                   	push   %ebx
f0101e0e:	57                   	push   %edi
f0101e0f:	e8 2d f2 ff ff       	call   f0101041 <page_insert>
f0101e14:	83 c4 10             	add    $0x10,%esp
f0101e17:	85 c0                	test   %eax,%eax
f0101e19:	74 19                	je     f0101e34 <mem_init+0xd8a>
f0101e1b:	68 58 55 10 f0       	push   $0xf0105558
f0101e20:	68 39 4d 10 f0       	push   $0xf0104d39
f0101e25:	68 9e 03 00 00       	push   $0x39e
f0101e2a:	68 13 4d 10 f0       	push   $0xf0104d13
f0101e2f:	e8 6c e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101e34:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e39:	75 19                	jne    f0101e54 <mem_init+0xdaa>
f0101e3b:	68 70 4f 10 f0       	push   $0xf0104f70
f0101e40:	68 39 4d 10 f0       	push   $0xf0104d39
f0101e45:	68 9f 03 00 00       	push   $0x39f
f0101e4a:	68 13 4d 10 f0       	push   $0xf0104d13
f0101e4f:	e8 4c e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101e54:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101e57:	74 19                	je     f0101e72 <mem_init+0xdc8>
f0101e59:	68 7c 4f 10 f0       	push   $0xf0104f7c
f0101e5e:	68 39 4d 10 f0       	push   $0xf0104d39
f0101e63:	68 a0 03 00 00       	push   $0x3a0
f0101e68:	68 13 4d 10 f0       	push   $0xf0104d13
f0101e6d:	e8 2e e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e72:	83 ec 08             	sub    $0x8,%esp
f0101e75:	68 00 10 00 00       	push   $0x1000
f0101e7a:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101e80:	e8 81 f1 ff ff       	call   f0101006 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e85:	8b 3d 08 db 17 f0    	mov    0xf017db08,%edi
f0101e8b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e90:	89 f8                	mov    %edi,%eax
f0101e92:	e8 fb ea ff ff       	call   f0100992 <check_va2pa>
f0101e97:	83 c4 10             	add    $0x10,%esp
f0101e9a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e9d:	74 19                	je     f0101eb8 <mem_init+0xe0e>
f0101e9f:	68 34 55 10 f0       	push   $0xf0105534
f0101ea4:	68 39 4d 10 f0       	push   $0xf0104d39
f0101ea9:	68 a4 03 00 00       	push   $0x3a4
f0101eae:	68 13 4d 10 f0       	push   $0xf0104d13
f0101eb3:	e8 e8 e1 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101eb8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ebd:	89 f8                	mov    %edi,%eax
f0101ebf:	e8 ce ea ff ff       	call   f0100992 <check_va2pa>
f0101ec4:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ec7:	74 19                	je     f0101ee2 <mem_init+0xe38>
f0101ec9:	68 90 55 10 f0       	push   $0xf0105590
f0101ece:	68 39 4d 10 f0       	push   $0xf0104d39
f0101ed3:	68 a5 03 00 00       	push   $0x3a5
f0101ed8:	68 13 4d 10 f0       	push   $0xf0104d13
f0101edd:	e8 be e1 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101ee2:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ee7:	74 19                	je     f0101f02 <mem_init+0xe58>
f0101ee9:	68 91 4f 10 f0       	push   $0xf0104f91
f0101eee:	68 39 4d 10 f0       	push   $0xf0104d39
f0101ef3:	68 a6 03 00 00       	push   $0x3a6
f0101ef8:	68 13 4d 10 f0       	push   $0xf0104d13
f0101efd:	e8 9e e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101f02:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f07:	74 19                	je     f0101f22 <mem_init+0xe78>
f0101f09:	68 5f 4f 10 f0       	push   $0xf0104f5f
f0101f0e:	68 39 4d 10 f0       	push   $0xf0104d39
f0101f13:	68 a7 03 00 00       	push   $0x3a7
f0101f18:	68 13 4d 10 f0       	push   $0xf0104d13
f0101f1d:	e8 7e e1 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f22:	83 ec 0c             	sub    $0xc,%esp
f0101f25:	6a 00                	push   $0x0
f0101f27:	e8 4f ee ff ff       	call   f0100d7b <page_alloc>
f0101f2c:	83 c4 10             	add    $0x10,%esp
f0101f2f:	39 c3                	cmp    %eax,%ebx
f0101f31:	75 04                	jne    f0101f37 <mem_init+0xe8d>
f0101f33:	85 c0                	test   %eax,%eax
f0101f35:	75 19                	jne    f0101f50 <mem_init+0xea6>
f0101f37:	68 b8 55 10 f0       	push   $0xf01055b8
f0101f3c:	68 39 4d 10 f0       	push   $0xf0104d39
f0101f41:	68 aa 03 00 00       	push   $0x3aa
f0101f46:	68 13 4d 10 f0       	push   $0xf0104d13
f0101f4b:	e8 50 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f50:	83 ec 0c             	sub    $0xc,%esp
f0101f53:	6a 00                	push   $0x0
f0101f55:	e8 21 ee ff ff       	call   f0100d7b <page_alloc>
f0101f5a:	83 c4 10             	add    $0x10,%esp
f0101f5d:	85 c0                	test   %eax,%eax
f0101f5f:	74 19                	je     f0101f7a <mem_init+0xed0>
f0101f61:	68 b3 4e 10 f0       	push   $0xf0104eb3
f0101f66:	68 39 4d 10 f0       	push   $0xf0104d39
f0101f6b:	68 ad 03 00 00       	push   $0x3ad
f0101f70:	68 13 4d 10 f0       	push   $0xf0104d13
f0101f75:	e8 26 e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f7a:	8b 0d 08 db 17 f0    	mov    0xf017db08,%ecx
f0101f80:	8b 11                	mov    (%ecx),%edx
f0101f82:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f88:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f8b:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0101f91:	c1 f8 03             	sar    $0x3,%eax
f0101f94:	c1 e0 0c             	shl    $0xc,%eax
f0101f97:	39 c2                	cmp    %eax,%edx
f0101f99:	74 19                	je     f0101fb4 <mem_init+0xf0a>
f0101f9b:	68 5c 52 10 f0       	push   $0xf010525c
f0101fa0:	68 39 4d 10 f0       	push   $0xf0104d39
f0101fa5:	68 b0 03 00 00       	push   $0x3b0
f0101faa:	68 13 4d 10 f0       	push   $0xf0104d13
f0101faf:	e8 ec e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101fb4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101fba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fbd:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101fc2:	74 19                	je     f0101fdd <mem_init+0xf33>
f0101fc4:	68 16 4f 10 f0       	push   $0xf0104f16
f0101fc9:	68 39 4d 10 f0       	push   $0xf0104d39
f0101fce:	68 b2 03 00 00       	push   $0x3b2
f0101fd3:	68 13 4d 10 f0       	push   $0xf0104d13
f0101fd8:	e8 c3 e0 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101fdd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fe0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101fe6:	83 ec 0c             	sub    $0xc,%esp
f0101fe9:	50                   	push   %eax
f0101fea:	e8 02 ee ff ff       	call   f0100df1 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101fef:	83 c4 0c             	add    $0xc,%esp
f0101ff2:	6a 01                	push   $0x1
f0101ff4:	68 00 10 40 00       	push   $0x401000
f0101ff9:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0101fff:	e8 6a ee ff ff       	call   f0100e6e <pgdir_walk>
f0102004:	89 c7                	mov    %eax,%edi
f0102006:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102009:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f010200e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102011:	8b 40 04             	mov    0x4(%eax),%eax
f0102014:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102019:	8b 0d 04 db 17 f0    	mov    0xf017db04,%ecx
f010201f:	89 c2                	mov    %eax,%edx
f0102021:	c1 ea 0c             	shr    $0xc,%edx
f0102024:	83 c4 10             	add    $0x10,%esp
f0102027:	39 ca                	cmp    %ecx,%edx
f0102029:	72 15                	jb     f0102040 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010202b:	50                   	push   %eax
f010202c:	68 1c 50 10 f0       	push   $0xf010501c
f0102031:	68 b9 03 00 00       	push   $0x3b9
f0102036:	68 13 4d 10 f0       	push   $0xf0104d13
f010203b:	e8 60 e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102040:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102045:	39 c7                	cmp    %eax,%edi
f0102047:	74 19                	je     f0102062 <mem_init+0xfb8>
f0102049:	68 a2 4f 10 f0       	push   $0xf0104fa2
f010204e:	68 39 4d 10 f0       	push   $0xf0104d39
f0102053:	68 ba 03 00 00       	push   $0x3ba
f0102058:	68 13 4d 10 f0       	push   $0xf0104d13
f010205d:	e8 3e e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102062:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102065:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f010206c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010206f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102075:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f010207b:	c1 f8 03             	sar    $0x3,%eax
f010207e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102081:	89 c2                	mov    %eax,%edx
f0102083:	c1 ea 0c             	shr    $0xc,%edx
f0102086:	39 d1                	cmp    %edx,%ecx
f0102088:	77 12                	ja     f010209c <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010208a:	50                   	push   %eax
f010208b:	68 1c 50 10 f0       	push   $0xf010501c
f0102090:	6a 56                	push   $0x56
f0102092:	68 1f 4d 10 f0       	push   $0xf0104d1f
f0102097:	e8 04 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010209c:	83 ec 04             	sub    $0x4,%esp
f010209f:	68 00 10 00 00       	push   $0x1000
f01020a4:	68 ff 00 00 00       	push   $0xff
f01020a9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020ae:	50                   	push   %eax
f01020af:	e8 6b 22 00 00       	call   f010431f <memset>
	page_free(pp0);
f01020b4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01020b7:	89 3c 24             	mov    %edi,(%esp)
f01020ba:	e8 32 ed ff ff       	call   f0100df1 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01020bf:	83 c4 0c             	add    $0xc,%esp
f01020c2:	6a 01                	push   $0x1
f01020c4:	6a 00                	push   $0x0
f01020c6:	ff 35 08 db 17 f0    	pushl  0xf017db08
f01020cc:	e8 9d ed ff ff       	call   f0100e6e <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020d1:	89 fa                	mov    %edi,%edx
f01020d3:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f01020d9:	c1 fa 03             	sar    $0x3,%edx
f01020dc:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020df:	89 d0                	mov    %edx,%eax
f01020e1:	c1 e8 0c             	shr    $0xc,%eax
f01020e4:	83 c4 10             	add    $0x10,%esp
f01020e7:	3b 05 04 db 17 f0    	cmp    0xf017db04,%eax
f01020ed:	72 12                	jb     f0102101 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020ef:	52                   	push   %edx
f01020f0:	68 1c 50 10 f0       	push   $0xf010501c
f01020f5:	6a 56                	push   $0x56
f01020f7:	68 1f 4d 10 f0       	push   $0xf0104d1f
f01020fc:	e8 9f df ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102101:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102107:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010210a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102110:	f6 00 01             	testb  $0x1,(%eax)
f0102113:	74 19                	je     f010212e <mem_init+0x1084>
f0102115:	68 ba 4f 10 f0       	push   $0xf0104fba
f010211a:	68 39 4d 10 f0       	push   $0xf0104d39
f010211f:	68 c4 03 00 00       	push   $0x3c4
f0102124:	68 13 4d 10 f0       	push   $0xf0104d13
f0102129:	e8 72 df ff ff       	call   f01000a0 <_panic>
f010212e:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102131:	39 c2                	cmp    %eax,%edx
f0102133:	75 db                	jne    f0102110 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102135:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f010213a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102140:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102143:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102149:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010214c:	89 3d 40 ce 17 f0    	mov    %edi,0xf017ce40

	// free the pages we took
	page_free(pp0);
f0102152:	83 ec 0c             	sub    $0xc,%esp
f0102155:	50                   	push   %eax
f0102156:	e8 96 ec ff ff       	call   f0100df1 <page_free>
	page_free(pp1);
f010215b:	89 1c 24             	mov    %ebx,(%esp)
f010215e:	e8 8e ec ff ff       	call   f0100df1 <page_free>
	page_free(pp2);
f0102163:	89 34 24             	mov    %esi,(%esp)
f0102166:	e8 86 ec ff ff       	call   f0100df1 <page_free>

	cprintf("check_page() succeeded!\n");
f010216b:	c7 04 24 d1 4f 10 f0 	movl   $0xf0104fd1,(%esp)
f0102172:	e8 5d 0e 00 00       	call   f0102fd4 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	int pages_size = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE); 
f0102177:	a1 04 db 17 f0       	mov    0xf017db04,%eax
f010217c:	8d 0c c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%ecx
f0102183:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
    boot_map_region(kern_pgdir, UPAGES, pages_size, PADDR(pages), PTE_U | PTE_P);
f0102189:	a1 0c db 17 f0       	mov    0xf017db0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010218e:	83 c4 10             	add    $0x10,%esp
f0102191:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102196:	77 15                	ja     f01021ad <mem_init+0x1103>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102198:	50                   	push   %eax
f0102199:	68 04 51 10 f0       	push   $0xf0105104
f010219e:	68 c0 00 00 00       	push   $0xc0
f01021a3:	68 13 4d 10 f0       	push   $0xf0104d13
f01021a8:	e8 f3 de ff ff       	call   f01000a0 <_panic>
f01021ad:	83 ec 08             	sub    $0x8,%esp
f01021b0:	6a 05                	push   $0x5
f01021b2:	05 00 00 00 10       	add    $0x10000000,%eax
f01021b7:	50                   	push   %eax
f01021b8:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01021bd:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f01021c2:	e8 72 ed ff ff       	call   f0100f39 <boot_map_region>
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	int envs_size = ROUNDUP(NENV * sizeof(struct Env), PGSIZE);
	boot_map_region(kern_pgdir, UENVS, envs_size, PADDR(envs), PTE_U | PTE_P);
f01021c7:	a1 4c ce 17 f0       	mov    0xf017ce4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021cc:	83 c4 10             	add    $0x10,%esp
f01021cf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021d4:	77 15                	ja     f01021eb <mem_init+0x1141>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021d6:	50                   	push   %eax
f01021d7:	68 04 51 10 f0       	push   $0xf0105104
f01021dc:	68 cb 00 00 00       	push   $0xcb
f01021e1:	68 13 4d 10 f0       	push   $0xf0104d13
f01021e6:	e8 b5 de ff ff       	call   f01000a0 <_panic>
f01021eb:	83 ec 08             	sub    $0x8,%esp
f01021ee:	6a 05                	push   $0x5
f01021f0:	05 00 00 00 10       	add    $0x10000000,%eax
f01021f5:	50                   	push   %eax
f01021f6:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01021fb:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102200:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0102205:	e8 2f ed ff ff       	call   f0100f39 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010220a:	83 c4 10             	add    $0x10,%esp
f010220d:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f0102212:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102217:	77 15                	ja     f010222e <mem_init+0x1184>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102219:	50                   	push   %eax
f010221a:	68 04 51 10 f0       	push   $0xf0105104
f010221f:	68 d8 00 00 00       	push   $0xd8
f0102224:	68 13 4d 10 f0       	push   $0xf0104d13
f0102229:	e8 72 de ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, ROUNDUP(KSTKSIZE, PGSIZE), PADDR(bootstack), PTE_W);
f010222e:	83 ec 08             	sub    $0x8,%esp
f0102231:	6a 02                	push   $0x2
f0102233:	68 00 10 11 00       	push   $0x111000
f0102238:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010223d:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102242:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0102247:	e8 ed ec ff ff       	call   f0100f39 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, ROUNDUP(~KERNBASE+1, PGSIZE), 0, PTE_W);
f010224c:	83 c4 08             	add    $0x8,%esp
f010224f:	6a 02                	push   $0x2
f0102251:	6a 00                	push   $0x0
f0102253:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102258:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010225d:	a1 08 db 17 f0       	mov    0xf017db08,%eax
f0102262:	e8 d2 ec ff ff       	call   f0100f39 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102267:	8b 1d 08 db 17 f0    	mov    0xf017db08,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010226d:	a1 04 db 17 f0       	mov    0xf017db04,%eax
f0102272:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102275:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010227c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102281:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102284:	8b 3d 0c db 17 f0    	mov    0xf017db0c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010228a:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010228d:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102290:	be 00 00 00 00       	mov    $0x0,%esi
f0102295:	eb 55                	jmp    f01022ec <mem_init+0x1242>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102297:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f010229d:	89 d8                	mov    %ebx,%eax
f010229f:	e8 ee e6 ff ff       	call   f0100992 <check_va2pa>
f01022a4:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01022ab:	77 15                	ja     f01022c2 <mem_init+0x1218>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022ad:	57                   	push   %edi
f01022ae:	68 04 51 10 f0       	push   $0xf0105104
f01022b3:	68 01 03 00 00       	push   $0x301
f01022b8:	68 13 4d 10 f0       	push   $0xf0104d13
f01022bd:	e8 de dd ff ff       	call   f01000a0 <_panic>
f01022c2:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01022c9:	39 d0                	cmp    %edx,%eax
f01022cb:	74 19                	je     f01022e6 <mem_init+0x123c>
f01022cd:	68 dc 55 10 f0       	push   $0xf01055dc
f01022d2:	68 39 4d 10 f0       	push   $0xf0104d39
f01022d7:	68 01 03 00 00       	push   $0x301
f01022dc:	68 13 4d 10 f0       	push   $0xf0104d13
f01022e1:	e8 ba dd ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022e6:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01022ec:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01022ef:	77 a6                	ja     f0102297 <mem_init+0x11ed>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01022f1:	8b 3d 4c ce 17 f0    	mov    0xf017ce4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022f7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01022fa:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01022ff:	89 f2                	mov    %esi,%edx
f0102301:	89 d8                	mov    %ebx,%eax
f0102303:	e8 8a e6 ff ff       	call   f0100992 <check_va2pa>
f0102308:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f010230f:	77 15                	ja     f0102326 <mem_init+0x127c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102311:	57                   	push   %edi
f0102312:	68 04 51 10 f0       	push   $0xf0105104
f0102317:	68 06 03 00 00       	push   $0x306
f010231c:	68 13 4d 10 f0       	push   $0xf0104d13
f0102321:	e8 7a dd ff ff       	call   f01000a0 <_panic>
f0102326:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f010232d:	39 c2                	cmp    %eax,%edx
f010232f:	74 19                	je     f010234a <mem_init+0x12a0>
f0102331:	68 10 56 10 f0       	push   $0xf0105610
f0102336:	68 39 4d 10 f0       	push   $0xf0104d39
f010233b:	68 06 03 00 00       	push   $0x306
f0102340:	68 13 4d 10 f0       	push   $0xf0104d13
f0102345:	e8 56 dd ff ff       	call   f01000a0 <_panic>
f010234a:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102350:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102356:	75 a7                	jne    f01022ff <mem_init+0x1255>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102358:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010235b:	c1 e7 0c             	shl    $0xc,%edi
f010235e:	be 00 00 00 00       	mov    $0x0,%esi
f0102363:	eb 30                	jmp    f0102395 <mem_init+0x12eb>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102365:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f010236b:	89 d8                	mov    %ebx,%eax
f010236d:	e8 20 e6 ff ff       	call   f0100992 <check_va2pa>
f0102372:	39 c6                	cmp    %eax,%esi
f0102374:	74 19                	je     f010238f <mem_init+0x12e5>
f0102376:	68 44 56 10 f0       	push   $0xf0105644
f010237b:	68 39 4d 10 f0       	push   $0xf0104d39
f0102380:	68 0a 03 00 00       	push   $0x30a
f0102385:	68 13 4d 10 f0       	push   $0xf0104d13
f010238a:	e8 11 dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010238f:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102395:	39 fe                	cmp    %edi,%esi
f0102397:	72 cc                	jb     f0102365 <mem_init+0x12bb>
f0102399:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010239e:	89 f2                	mov    %esi,%edx
f01023a0:	89 d8                	mov    %ebx,%eax
f01023a2:	e8 eb e5 ff ff       	call   f0100992 <check_va2pa>
f01023a7:	8d 96 00 90 11 10    	lea    0x10119000(%esi),%edx
f01023ad:	39 c2                	cmp    %eax,%edx
f01023af:	74 19                	je     f01023ca <mem_init+0x1320>
f01023b1:	68 6c 56 10 f0       	push   $0xf010566c
f01023b6:	68 39 4d 10 f0       	push   $0xf0104d39
f01023bb:	68 0e 03 00 00       	push   $0x30e
f01023c0:	68 13 4d 10 f0       	push   $0xf0104d13
f01023c5:	e8 d6 dc ff ff       	call   f01000a0 <_panic>
f01023ca:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01023d0:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01023d6:	75 c6                	jne    f010239e <mem_init+0x12f4>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023d8:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01023dd:	89 d8                	mov    %ebx,%eax
f01023df:	e8 ae e5 ff ff       	call   f0100992 <check_va2pa>
f01023e4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023e7:	74 51                	je     f010243a <mem_init+0x1390>
f01023e9:	68 b4 56 10 f0       	push   $0xf01056b4
f01023ee:	68 39 4d 10 f0       	push   $0xf0104d39
f01023f3:	68 0f 03 00 00       	push   $0x30f
f01023f8:	68 13 4d 10 f0       	push   $0xf0104d13
f01023fd:	e8 9e dc ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102402:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102407:	72 36                	jb     f010243f <mem_init+0x1395>
f0102409:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010240e:	76 07                	jbe    f0102417 <mem_init+0x136d>
f0102410:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102415:	75 28                	jne    f010243f <mem_init+0x1395>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102417:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010241b:	0f 85 83 00 00 00    	jne    f01024a4 <mem_init+0x13fa>
f0102421:	68 ea 4f 10 f0       	push   $0xf0104fea
f0102426:	68 39 4d 10 f0       	push   $0xf0104d39
f010242b:	68 18 03 00 00       	push   $0x318
f0102430:	68 13 4d 10 f0       	push   $0xf0104d13
f0102435:	e8 66 dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010243a:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010243f:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102444:	76 3f                	jbe    f0102485 <mem_init+0x13db>
				assert(pgdir[i] & PTE_P);
f0102446:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102449:	f6 c2 01             	test   $0x1,%dl
f010244c:	75 19                	jne    f0102467 <mem_init+0x13bd>
f010244e:	68 ea 4f 10 f0       	push   $0xf0104fea
f0102453:	68 39 4d 10 f0       	push   $0xf0104d39
f0102458:	68 1c 03 00 00       	push   $0x31c
f010245d:	68 13 4d 10 f0       	push   $0xf0104d13
f0102462:	e8 39 dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f0102467:	f6 c2 02             	test   $0x2,%dl
f010246a:	75 38                	jne    f01024a4 <mem_init+0x13fa>
f010246c:	68 fb 4f 10 f0       	push   $0xf0104ffb
f0102471:	68 39 4d 10 f0       	push   $0xf0104d39
f0102476:	68 1d 03 00 00       	push   $0x31d
f010247b:	68 13 4d 10 f0       	push   $0xf0104d13
f0102480:	e8 1b dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102485:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102489:	74 19                	je     f01024a4 <mem_init+0x13fa>
f010248b:	68 0c 50 10 f0       	push   $0xf010500c
f0102490:	68 39 4d 10 f0       	push   $0xf0104d39
f0102495:	68 1f 03 00 00       	push   $0x31f
f010249a:	68 13 4d 10 f0       	push   $0xf0104d13
f010249f:	e8 fc db ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01024a4:	83 c0 01             	add    $0x1,%eax
f01024a7:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01024ac:	0f 86 50 ff ff ff    	jbe    f0102402 <mem_init+0x1358>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01024b2:	83 ec 0c             	sub    $0xc,%esp
f01024b5:	68 e4 56 10 f0       	push   $0xf01056e4
f01024ba:	e8 15 0b 00 00       	call   f0102fd4 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01024bf:	a1 08 db 17 f0       	mov    0xf017db08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024c4:	83 c4 10             	add    $0x10,%esp
f01024c7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024cc:	77 15                	ja     f01024e3 <mem_init+0x1439>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024ce:	50                   	push   %eax
f01024cf:	68 04 51 10 f0       	push   $0xf0105104
f01024d4:	68 ef 00 00 00       	push   $0xef
f01024d9:	68 13 4d 10 f0       	push   $0xf0104d13
f01024de:	e8 bd db ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01024e3:	05 00 00 00 10       	add    $0x10000000,%eax
f01024e8:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01024eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01024f0:	e8 01 e5 ff ff       	call   f01009f6 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01024f5:	0f 20 c0             	mov    %cr0,%eax
f01024f8:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01024fb:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102500:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102503:	83 ec 0c             	sub    $0xc,%esp
f0102506:	6a 00                	push   $0x0
f0102508:	e8 6e e8 ff ff       	call   f0100d7b <page_alloc>
f010250d:	89 c3                	mov    %eax,%ebx
f010250f:	83 c4 10             	add    $0x10,%esp
f0102512:	85 c0                	test   %eax,%eax
f0102514:	75 19                	jne    f010252f <mem_init+0x1485>
f0102516:	68 08 4e 10 f0       	push   $0xf0104e08
f010251b:	68 39 4d 10 f0       	push   $0xf0104d39
f0102520:	68 df 03 00 00       	push   $0x3df
f0102525:	68 13 4d 10 f0       	push   $0xf0104d13
f010252a:	e8 71 db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010252f:	83 ec 0c             	sub    $0xc,%esp
f0102532:	6a 00                	push   $0x0
f0102534:	e8 42 e8 ff ff       	call   f0100d7b <page_alloc>
f0102539:	89 c7                	mov    %eax,%edi
f010253b:	83 c4 10             	add    $0x10,%esp
f010253e:	85 c0                	test   %eax,%eax
f0102540:	75 19                	jne    f010255b <mem_init+0x14b1>
f0102542:	68 1e 4e 10 f0       	push   $0xf0104e1e
f0102547:	68 39 4d 10 f0       	push   $0xf0104d39
f010254c:	68 e0 03 00 00       	push   $0x3e0
f0102551:	68 13 4d 10 f0       	push   $0xf0104d13
f0102556:	e8 45 db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010255b:	83 ec 0c             	sub    $0xc,%esp
f010255e:	6a 00                	push   $0x0
f0102560:	e8 16 e8 ff ff       	call   f0100d7b <page_alloc>
f0102565:	89 c6                	mov    %eax,%esi
f0102567:	83 c4 10             	add    $0x10,%esp
f010256a:	85 c0                	test   %eax,%eax
f010256c:	75 19                	jne    f0102587 <mem_init+0x14dd>
f010256e:	68 34 4e 10 f0       	push   $0xf0104e34
f0102573:	68 39 4d 10 f0       	push   $0xf0104d39
f0102578:	68 e1 03 00 00       	push   $0x3e1
f010257d:	68 13 4d 10 f0       	push   $0xf0104d13
f0102582:	e8 19 db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f0102587:	83 ec 0c             	sub    $0xc,%esp
f010258a:	53                   	push   %ebx
f010258b:	e8 61 e8 ff ff       	call   f0100df1 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102590:	89 f8                	mov    %edi,%eax
f0102592:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0102598:	c1 f8 03             	sar    $0x3,%eax
f010259b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010259e:	89 c2                	mov    %eax,%edx
f01025a0:	c1 ea 0c             	shr    $0xc,%edx
f01025a3:	83 c4 10             	add    $0x10,%esp
f01025a6:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f01025ac:	72 12                	jb     f01025c0 <mem_init+0x1516>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025ae:	50                   	push   %eax
f01025af:	68 1c 50 10 f0       	push   $0xf010501c
f01025b4:	6a 56                	push   $0x56
f01025b6:	68 1f 4d 10 f0       	push   $0xf0104d1f
f01025bb:	e8 e0 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01025c0:	83 ec 04             	sub    $0x4,%esp
f01025c3:	68 00 10 00 00       	push   $0x1000
f01025c8:	6a 01                	push   $0x1
f01025ca:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025cf:	50                   	push   %eax
f01025d0:	e8 4a 1d 00 00       	call   f010431f <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025d5:	89 f0                	mov    %esi,%eax
f01025d7:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f01025dd:	c1 f8 03             	sar    $0x3,%eax
f01025e0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025e3:	89 c2                	mov    %eax,%edx
f01025e5:	c1 ea 0c             	shr    $0xc,%edx
f01025e8:	83 c4 10             	add    $0x10,%esp
f01025eb:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f01025f1:	72 12                	jb     f0102605 <mem_init+0x155b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025f3:	50                   	push   %eax
f01025f4:	68 1c 50 10 f0       	push   $0xf010501c
f01025f9:	6a 56                	push   $0x56
f01025fb:	68 1f 4d 10 f0       	push   $0xf0104d1f
f0102600:	e8 9b da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102605:	83 ec 04             	sub    $0x4,%esp
f0102608:	68 00 10 00 00       	push   $0x1000
f010260d:	6a 02                	push   $0x2
f010260f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102614:	50                   	push   %eax
f0102615:	e8 05 1d 00 00       	call   f010431f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010261a:	6a 02                	push   $0x2
f010261c:	68 00 10 00 00       	push   $0x1000
f0102621:	57                   	push   %edi
f0102622:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0102628:	e8 14 ea ff ff       	call   f0101041 <page_insert>
	assert(pp1->pp_ref == 1);
f010262d:	83 c4 20             	add    $0x20,%esp
f0102630:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102635:	74 19                	je     f0102650 <mem_init+0x15a6>
f0102637:	68 05 4f 10 f0       	push   $0xf0104f05
f010263c:	68 39 4d 10 f0       	push   $0xf0104d39
f0102641:	68 e6 03 00 00       	push   $0x3e6
f0102646:	68 13 4d 10 f0       	push   $0xf0104d13
f010264b:	e8 50 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102650:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102657:	01 01 01 
f010265a:	74 19                	je     f0102675 <mem_init+0x15cb>
f010265c:	68 04 57 10 f0       	push   $0xf0105704
f0102661:	68 39 4d 10 f0       	push   $0xf0104d39
f0102666:	68 e7 03 00 00       	push   $0x3e7
f010266b:	68 13 4d 10 f0       	push   $0xf0104d13
f0102670:	e8 2b da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102675:	6a 02                	push   $0x2
f0102677:	68 00 10 00 00       	push   $0x1000
f010267c:	56                   	push   %esi
f010267d:	ff 35 08 db 17 f0    	pushl  0xf017db08
f0102683:	e8 b9 e9 ff ff       	call   f0101041 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102688:	83 c4 10             	add    $0x10,%esp
f010268b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102692:	02 02 02 
f0102695:	74 19                	je     f01026b0 <mem_init+0x1606>
f0102697:	68 28 57 10 f0       	push   $0xf0105728
f010269c:	68 39 4d 10 f0       	push   $0xf0104d39
f01026a1:	68 e9 03 00 00       	push   $0x3e9
f01026a6:	68 13 4d 10 f0       	push   $0xf0104d13
f01026ab:	e8 f0 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01026b0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01026b5:	74 19                	je     f01026d0 <mem_init+0x1626>
f01026b7:	68 27 4f 10 f0       	push   $0xf0104f27
f01026bc:	68 39 4d 10 f0       	push   $0xf0104d39
f01026c1:	68 ea 03 00 00       	push   $0x3ea
f01026c6:	68 13 4d 10 f0       	push   $0xf0104d13
f01026cb:	e8 d0 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01026d0:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01026d5:	74 19                	je     f01026f0 <mem_init+0x1646>
f01026d7:	68 91 4f 10 f0       	push   $0xf0104f91
f01026dc:	68 39 4d 10 f0       	push   $0xf0104d39
f01026e1:	68 eb 03 00 00       	push   $0x3eb
f01026e6:	68 13 4d 10 f0       	push   $0xf0104d13
f01026eb:	e8 b0 d9 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01026f0:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01026f7:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01026fa:	89 f0                	mov    %esi,%eax
f01026fc:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0102702:	c1 f8 03             	sar    $0x3,%eax
f0102705:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102708:	89 c2                	mov    %eax,%edx
f010270a:	c1 ea 0c             	shr    $0xc,%edx
f010270d:	3b 15 04 db 17 f0    	cmp    0xf017db04,%edx
f0102713:	72 12                	jb     f0102727 <mem_init+0x167d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102715:	50                   	push   %eax
f0102716:	68 1c 50 10 f0       	push   $0xf010501c
f010271b:	6a 56                	push   $0x56
f010271d:	68 1f 4d 10 f0       	push   $0xf0104d1f
f0102722:	e8 79 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102727:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010272e:	03 03 03 
f0102731:	74 19                	je     f010274c <mem_init+0x16a2>
f0102733:	68 4c 57 10 f0       	push   $0xf010574c
f0102738:	68 39 4d 10 f0       	push   $0xf0104d39
f010273d:	68 ed 03 00 00       	push   $0x3ed
f0102742:	68 13 4d 10 f0       	push   $0xf0104d13
f0102747:	e8 54 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010274c:	83 ec 08             	sub    $0x8,%esp
f010274f:	68 00 10 00 00       	push   $0x1000
f0102754:	ff 35 08 db 17 f0    	pushl  0xf017db08
f010275a:	e8 a7 e8 ff ff       	call   f0101006 <page_remove>
	assert(pp2->pp_ref == 0);
f010275f:	83 c4 10             	add    $0x10,%esp
f0102762:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102767:	74 19                	je     f0102782 <mem_init+0x16d8>
f0102769:	68 5f 4f 10 f0       	push   $0xf0104f5f
f010276e:	68 39 4d 10 f0       	push   $0xf0104d39
f0102773:	68 ef 03 00 00       	push   $0x3ef
f0102778:	68 13 4d 10 f0       	push   $0xf0104d13
f010277d:	e8 1e d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102782:	8b 0d 08 db 17 f0    	mov    0xf017db08,%ecx
f0102788:	8b 11                	mov    (%ecx),%edx
f010278a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102790:	89 d8                	mov    %ebx,%eax
f0102792:	2b 05 0c db 17 f0    	sub    0xf017db0c,%eax
f0102798:	c1 f8 03             	sar    $0x3,%eax
f010279b:	c1 e0 0c             	shl    $0xc,%eax
f010279e:	39 c2                	cmp    %eax,%edx
f01027a0:	74 19                	je     f01027bb <mem_init+0x1711>
f01027a2:	68 5c 52 10 f0       	push   $0xf010525c
f01027a7:	68 39 4d 10 f0       	push   $0xf0104d39
f01027ac:	68 f2 03 00 00       	push   $0x3f2
f01027b1:	68 13 4d 10 f0       	push   $0xf0104d13
f01027b6:	e8 e5 d8 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01027bb:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01027c1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01027c6:	74 19                	je     f01027e1 <mem_init+0x1737>
f01027c8:	68 16 4f 10 f0       	push   $0xf0104f16
f01027cd:	68 39 4d 10 f0       	push   $0xf0104d39
f01027d2:	68 f4 03 00 00       	push   $0x3f4
f01027d7:	68 13 4d 10 f0       	push   $0xf0104d13
f01027dc:	e8 bf d8 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01027e1:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01027e7:	83 ec 0c             	sub    $0xc,%esp
f01027ea:	53                   	push   %ebx
f01027eb:	e8 01 e6 ff ff       	call   f0100df1 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01027f0:	c7 04 24 78 57 10 f0 	movl   $0xf0105778,(%esp)
f01027f7:	e8 d8 07 00 00       	call   f0102fd4 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01027fc:	83 c4 10             	add    $0x10,%esp
f01027ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102802:	5b                   	pop    %ebx
f0102803:	5e                   	pop    %esi
f0102804:	5f                   	pop    %edi
f0102805:	5d                   	pop    %ebp
f0102806:	c3                   	ret    

f0102807 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102807:	55                   	push   %ebp
f0102808:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010280a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010280d:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102810:	5d                   	pop    %ebp
f0102811:	c3                   	ret    

f0102812 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102812:	55                   	push   %ebp
f0102813:	89 e5                	mov    %esp,%ebp
f0102815:	57                   	push   %edi
f0102816:	56                   	push   %esi
f0102817:	53                   	push   %ebx
f0102818:	83 ec 1c             	sub    $0x1c,%esp
f010281b:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	    void *va_ = ROUNDDOWN((void *)va, PGSIZE);
f010281e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102821:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
    void *end_ = ROUNDUP((void *)(va + len), PGSIZE);
f0102827:	8b 45 0c             	mov    0xc(%ebp),%eax
f010282a:	03 45 10             	add    0x10(%ebp),%eax
f010282d:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102832:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102837:	89 45 e4             	mov    %eax,-0x1c(%ebp)

    perm |= PTE_P;
f010283a:	8b 75 14             	mov    0x14(%ebp),%esi
f010283d:	83 ce 01             	or     $0x1,%esi

    pte_t *pte;
    for (; va_ < end_; va_ += PGSIZE) {
f0102840:	eb 3f                	jmp    f0102881 <user_mem_check+0x6f>
        pte = pgdir_walk(env->env_pgdir, va_, 0);
f0102842:	83 ec 04             	sub    $0x4,%esp
f0102845:	6a 00                	push   $0x0
f0102847:	53                   	push   %ebx
f0102848:	ff 77 5c             	pushl  0x5c(%edi)
f010284b:	e8 1e e6 ff ff       	call   f0100e6e <pgdir_walk>
        if (va_ >= (void *)ULIM || 
f0102850:	83 c4 10             	add    $0x10,%esp
f0102853:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102859:	77 0c                	ja     f0102867 <user_mem_check+0x55>
f010285b:	85 c0                	test   %eax,%eax
f010285d:	74 08                	je     f0102867 <user_mem_check+0x55>
            !pte ||
f010285f:	89 f2                	mov    %esi,%edx
f0102861:	23 10                	and    (%eax),%edx
f0102863:	39 d6                	cmp    %edx,%esi
f0102865:	74 14                	je     f010287b <user_mem_check+0x69>
            (*pte & perm) != perm) {

            user_mem_check_addr = (uintptr_t)((va_ < va)? va: va_);
f0102867:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f010286a:	0f 42 5d 0c          	cmovb  0xc(%ebp),%ebx
f010286e:	89 1d 3c ce 17 f0    	mov    %ebx,0xf017ce3c
            return -E_FAULT;
f0102874:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102879:	eb 10                	jmp    f010288b <user_mem_check+0x79>
    void *end_ = ROUNDUP((void *)(va + len), PGSIZE);

    perm |= PTE_P;

    pte_t *pte;
    for (; va_ < end_; va_ += PGSIZE) {
f010287b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102881:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102884:	72 bc                	jb     f0102842 <user_mem_check+0x30>
            user_mem_check_addr = (uintptr_t)((va_ < va)? va: va_);
            return -E_FAULT;
        }
    }

	return 0;
f0102886:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010288b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010288e:	5b                   	pop    %ebx
f010288f:	5e                   	pop    %esi
f0102890:	5f                   	pop    %edi
f0102891:	5d                   	pop    %ebp
f0102892:	c3                   	ret    

f0102893 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102893:	55                   	push   %ebp
f0102894:	89 e5                	mov    %esp,%ebp
f0102896:	53                   	push   %ebx
f0102897:	83 ec 04             	sub    $0x4,%esp
f010289a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f010289d:	8b 45 14             	mov    0x14(%ebp),%eax
f01028a0:	83 c8 04             	or     $0x4,%eax
f01028a3:	50                   	push   %eax
f01028a4:	ff 75 10             	pushl  0x10(%ebp)
f01028a7:	ff 75 0c             	pushl  0xc(%ebp)
f01028aa:	53                   	push   %ebx
f01028ab:	e8 62 ff ff ff       	call   f0102812 <user_mem_check>
f01028b0:	83 c4 10             	add    $0x10,%esp
f01028b3:	85 c0                	test   %eax,%eax
f01028b5:	79 21                	jns    f01028d8 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f01028b7:	83 ec 04             	sub    $0x4,%esp
f01028ba:	ff 35 3c ce 17 f0    	pushl  0xf017ce3c
f01028c0:	ff 73 48             	pushl  0x48(%ebx)
f01028c3:	68 a4 57 10 f0       	push   $0xf01057a4
f01028c8:	e8 07 07 00 00       	call   f0102fd4 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f01028cd:	89 1c 24             	mov    %ebx,(%esp)
f01028d0:	e8 e6 05 00 00       	call   f0102ebb <env_destroy>
f01028d5:	83 c4 10             	add    $0x10,%esp
	}
}
f01028d8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01028db:	c9                   	leave  
f01028dc:	c3                   	ret    

f01028dd <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01028dd:	55                   	push   %ebp
f01028de:	89 e5                	mov    %esp,%ebp
f01028e0:	57                   	push   %edi
f01028e1:	56                   	push   %esi
f01028e2:	53                   	push   %ebx
f01028e3:	83 ec 0c             	sub    $0xc,%esp
f01028e6:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)

	void *start = (void *)ROUNDDOWN(va, PGSIZE);
f01028e8:	89 d3                	mov    %edx,%ebx
f01028ea:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void *end = (void *)ROUNDUP(va+len, PGSIZE);
f01028f0:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01028f7:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *page;
	int ret;
	for(; start < end; start += PGSIZE){
f01028fd:	eb 58                	jmp    f0102957 <region_alloc+0x7a>
		page = page_alloc(0);
f01028ff:	83 ec 0c             	sub    $0xc,%esp
f0102902:	6a 00                	push   $0x0
f0102904:	e8 72 e4 ff ff       	call   f0100d7b <page_alloc>
		if(page == NULL) {
f0102909:	83 c4 10             	add    $0x10,%esp
f010290c:	85 c0                	test   %eax,%eax
f010290e:	75 17                	jne    f0102927 <region_alloc+0x4a>
			panic("region_alloc page_alloc error!");
f0102910:	83 ec 04             	sub    $0x4,%esp
f0102913:	68 dc 57 10 f0       	push   $0xf01057dc
f0102918:	68 27 01 00 00       	push   $0x127
f010291d:	68 5a 58 10 f0       	push   $0xf010585a
f0102922:	e8 79 d7 ff ff       	call   f01000a0 <_panic>
		}

		ret = page_insert(e->env_pgdir, page, start, PTE_W | PTE_U);
f0102927:	6a 06                	push   $0x6
f0102929:	53                   	push   %ebx
f010292a:	50                   	push   %eax
f010292b:	ff 77 5c             	pushl  0x5c(%edi)
f010292e:	e8 0e e7 ff ff       	call   f0101041 <page_insert>
		if(ret < 0) {
f0102933:	83 c4 10             	add    $0x10,%esp
f0102936:	85 c0                	test   %eax,%eax
f0102938:	79 17                	jns    f0102951 <region_alloc+0x74>
			panic("region_alloc error!");
f010293a:	83 ec 04             	sub    $0x4,%esp
f010293d:	68 65 58 10 f0       	push   $0xf0105865
f0102942:	68 2c 01 00 00       	push   $0x12c
f0102947:	68 5a 58 10 f0       	push   $0xf010585a
f010294c:	e8 4f d7 ff ff       	call   f01000a0 <_panic>

	void *start = (void *)ROUNDDOWN(va, PGSIZE);
	void *end = (void *)ROUNDUP(va+len, PGSIZE);
	struct PageInfo *page;
	int ret;
	for(; start < end; start += PGSIZE){
f0102951:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102957:	39 f3                	cmp    %esi,%ebx
f0102959:	72 a4                	jb     f01028ff <region_alloc+0x22>
		ret = page_insert(e->env_pgdir, page, start, PTE_W | PTE_U);
		if(ret < 0) {
			panic("region_alloc error!");
		}
	}
}
f010295b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010295e:	5b                   	pop    %ebx
f010295f:	5e                   	pop    %esi
f0102960:	5f                   	pop    %edi
f0102961:	5d                   	pop    %ebp
f0102962:	c3                   	ret    

f0102963 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102963:	55                   	push   %ebp
f0102964:	89 e5                	mov    %esp,%ebp
f0102966:	8b 55 08             	mov    0x8(%ebp),%edx
f0102969:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010296c:	85 d2                	test   %edx,%edx
f010296e:	75 11                	jne    f0102981 <envid2env+0x1e>
		*env_store = curenv;
f0102970:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f0102975:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102978:	89 01                	mov    %eax,(%ecx)
		return 0;
f010297a:	b8 00 00 00 00       	mov    $0x0,%eax
f010297f:	eb 5e                	jmp    f01029df <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102981:	89 d0                	mov    %edx,%eax
f0102983:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102988:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010298b:	c1 e0 05             	shl    $0x5,%eax
f010298e:	03 05 4c ce 17 f0    	add    0xf017ce4c,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102994:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102998:	74 05                	je     f010299f <envid2env+0x3c>
f010299a:	3b 50 48             	cmp    0x48(%eax),%edx
f010299d:	74 10                	je     f01029af <envid2env+0x4c>
		*env_store = 0;
f010299f:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029a2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01029a8:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01029ad:	eb 30                	jmp    f01029df <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01029af:	84 c9                	test   %cl,%cl
f01029b1:	74 22                	je     f01029d5 <envid2env+0x72>
f01029b3:	8b 15 48 ce 17 f0    	mov    0xf017ce48,%edx
f01029b9:	39 d0                	cmp    %edx,%eax
f01029bb:	74 18                	je     f01029d5 <envid2env+0x72>
f01029bd:	8b 4a 48             	mov    0x48(%edx),%ecx
f01029c0:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01029c3:	74 10                	je     f01029d5 <envid2env+0x72>
		*env_store = 0;
f01029c5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029c8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01029ce:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01029d3:	eb 0a                	jmp    f01029df <envid2env+0x7c>
	}

	*env_store = e;
f01029d5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01029d8:	89 01                	mov    %eax,(%ecx)
	return 0;
f01029da:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01029df:	5d                   	pop    %ebp
f01029e0:	c3                   	ret    

f01029e1 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01029e1:	55                   	push   %ebp
f01029e2:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01029e4:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f01029e9:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01029ec:	b8 23 00 00 00       	mov    $0x23,%eax
f01029f1:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01029f3:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01029f5:	b8 10 00 00 00       	mov    $0x10,%eax
f01029fa:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01029fc:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01029fe:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102a00:	ea 07 2a 10 f0 08 00 	ljmp   $0x8,$0xf0102a07
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102a07:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a0c:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102a0f:	5d                   	pop    %ebp
f0102a10:	c3                   	ret    

f0102a11 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102a11:	55                   	push   %ebp
f0102a12:	89 e5                	mov    %esp,%ebp
f0102a14:	56                   	push   %esi
f0102a15:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (int i = NENV-1; i >= 0; i--) {
        envs[i].env_id = 0;
f0102a16:	8b 35 4c ce 17 f0    	mov    0xf017ce4c,%esi
f0102a1c:	8b 15 50 ce 17 f0    	mov    0xf017ce50,%edx
f0102a22:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102a28:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102a2b:	89 c1                	mov    %eax,%ecx
f0102a2d:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
        envs[i].env_link = env_free_list;
f0102a34:	89 50 44             	mov    %edx,0x44(%eax)
f0102a37:	83 e8 60             	sub    $0x60,%eax
        env_free_list = &envs[i];
f0102a3a:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (int i = NENV-1; i >= 0; i--) {
f0102a3c:	39 d8                	cmp    %ebx,%eax
f0102a3e:	75 eb                	jne    f0102a2b <env_init+0x1a>
f0102a40:	89 35 50 ce 17 f0    	mov    %esi,0xf017ce50
        envs[i].env_id = 0;
        envs[i].env_link = env_free_list;
        env_free_list = &envs[i];
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0102a46:	e8 96 ff ff ff       	call   f01029e1 <env_init_percpu>
}
f0102a4b:	5b                   	pop    %ebx
f0102a4c:	5e                   	pop    %esi
f0102a4d:	5d                   	pop    %ebp
f0102a4e:	c3                   	ret    

f0102a4f <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102a4f:	55                   	push   %ebp
f0102a50:	89 e5                	mov    %esp,%ebp
f0102a52:	53                   	push   %ebx
f0102a53:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102a56:	8b 1d 50 ce 17 f0    	mov    0xf017ce50,%ebx
f0102a5c:	85 db                	test   %ebx,%ebx
f0102a5e:	0f 84 61 01 00 00    	je     f0102bc5 <env_alloc+0x176>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102a64:	83 ec 0c             	sub    $0xc,%esp
f0102a67:	6a 01                	push   $0x1
f0102a69:	e8 0d e3 ff ff       	call   f0100d7b <page_alloc>
f0102a6e:	83 c4 10             	add    $0x10,%esp
f0102a71:	85 c0                	test   %eax,%eax
f0102a73:	0f 84 53 01 00 00    	je     f0102bcc <env_alloc+0x17d>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a79:	89 c2                	mov    %eax,%edx
f0102a7b:	2b 15 0c db 17 f0    	sub    0xf017db0c,%edx
f0102a81:	c1 fa 03             	sar    $0x3,%edx
f0102a84:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a87:	89 d1                	mov    %edx,%ecx
f0102a89:	c1 e9 0c             	shr    $0xc,%ecx
f0102a8c:	3b 0d 04 db 17 f0    	cmp    0xf017db04,%ecx
f0102a92:	72 12                	jb     f0102aa6 <env_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a94:	52                   	push   %edx
f0102a95:	68 1c 50 10 f0       	push   $0xf010501c
f0102a9a:	6a 56                	push   $0x56
f0102a9c:	68 1f 4d 10 f0       	push   $0xf0104d1f
f0102aa1:	e8 fa d5 ff ff       	call   f01000a0 <_panic>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = page2kva(p);
f0102aa6:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102aac:	89 53 5c             	mov    %edx,0x5c(%ebx)
	p->pp_ref++;
f0102aaf:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f0102ab4:	b8 00 00 00 00       	mov    $0x0,%eax

	//Map the directory below UTOP.
	for(i = 0; i < PDX(UTOP); i++) {
		e->env_pgdir[i] = 0;		
f0102ab9:	8b 53 5c             	mov    0x5c(%ebx),%edx
f0102abc:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f0102ac3:	83 c0 04             	add    $0x4,%eax
	// LAB 3: Your code here.
	e->env_pgdir = page2kva(p);
	p->pp_ref++;

	//Map the directory below UTOP.
	for(i = 0; i < PDX(UTOP); i++) {
f0102ac6:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f0102acb:	75 ec                	jne    f0102ab9 <env_alloc+0x6a>
		e->env_pgdir[i] = 0;		
	}

	//Map the directory above UTOP
	for(i = PDX(UTOP); i < NPDENTRIES; i++) {
		e->env_pgdir[i] = kern_pgdir[i];
f0102acd:	8b 15 08 db 17 f0    	mov    0xf017db08,%edx
f0102ad3:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0102ad6:	8b 53 5c             	mov    0x5c(%ebx),%edx
f0102ad9:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0102adc:	83 c0 04             	add    $0x4,%eax
	for(i = 0; i < PDX(UTOP); i++) {
		e->env_pgdir[i] = 0;		
	}

	//Map the directory above UTOP
	for(i = PDX(UTOP); i < NPDENTRIES; i++) {
f0102adf:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102ae4:	75 e7                	jne    f0102acd <env_alloc+0x7e>
		e->env_pgdir[i] = kern_pgdir[i];
	}
		
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102ae6:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ae9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102aee:	77 15                	ja     f0102b05 <env_alloc+0xb6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102af0:	50                   	push   %eax
f0102af1:	68 04 51 10 f0       	push   $0xf0105104
f0102af6:	68 ca 00 00 00       	push   $0xca
f0102afb:	68 5a 58 10 f0       	push   $0xf010585a
f0102b00:	e8 9b d5 ff ff       	call   f01000a0 <_panic>
f0102b05:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102b0b:	83 ca 05             	or     $0x5,%edx
f0102b0e:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102b14:	8b 43 48             	mov    0x48(%ebx),%eax
f0102b17:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102b1c:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102b21:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102b26:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102b29:	89 da                	mov    %ebx,%edx
f0102b2b:	2b 15 4c ce 17 f0    	sub    0xf017ce4c,%edx
f0102b31:	c1 fa 05             	sar    $0x5,%edx
f0102b34:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102b3a:	09 d0                	or     %edx,%eax
f0102b3c:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102b3f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b42:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102b45:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102b4c:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102b53:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102b5a:	83 ec 04             	sub    $0x4,%esp
f0102b5d:	6a 44                	push   $0x44
f0102b5f:	6a 00                	push   $0x0
f0102b61:	53                   	push   %ebx
f0102b62:	e8 b8 17 00 00       	call   f010431f <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102b67:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102b6d:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102b73:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102b79:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102b80:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102b86:	8b 43 44             	mov    0x44(%ebx),%eax
f0102b89:	a3 50 ce 17 f0       	mov    %eax,0xf017ce50
	*newenv_store = e;
f0102b8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b91:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102b93:	8b 53 48             	mov    0x48(%ebx),%edx
f0102b96:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f0102b9b:	83 c4 10             	add    $0x10,%esp
f0102b9e:	85 c0                	test   %eax,%eax
f0102ba0:	74 05                	je     f0102ba7 <env_alloc+0x158>
f0102ba2:	8b 40 48             	mov    0x48(%eax),%eax
f0102ba5:	eb 05                	jmp    f0102bac <env_alloc+0x15d>
f0102ba7:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bac:	83 ec 04             	sub    $0x4,%esp
f0102baf:	52                   	push   %edx
f0102bb0:	50                   	push   %eax
f0102bb1:	68 79 58 10 f0       	push   $0xf0105879
f0102bb6:	e8 19 04 00 00       	call   f0102fd4 <cprintf>
	return 0;
f0102bbb:	83 c4 10             	add    $0x10,%esp
f0102bbe:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bc3:	eb 0c                	jmp    f0102bd1 <env_alloc+0x182>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102bc5:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102bca:	eb 05                	jmp    f0102bd1 <env_alloc+0x182>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102bcc:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102bd1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102bd4:	c9                   	leave  
f0102bd5:	c3                   	ret    

f0102bd6 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102bd6:	55                   	push   %ebp
f0102bd7:	89 e5                	mov    %esp,%ebp
f0102bd9:	57                   	push   %edi
f0102bda:	56                   	push   %esi
f0102bdb:	53                   	push   %ebx
f0102bdc:	83 ec 34             	sub    $0x34,%esp
f0102bdf:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int rc;
	if((rc = env_alloc(&e, 0)) != 0) {
f0102be2:	6a 00                	push   $0x0
f0102be4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102be7:	50                   	push   %eax
f0102be8:	e8 62 fe ff ff       	call   f0102a4f <env_alloc>
f0102bed:	83 c4 10             	add    $0x10,%esp
f0102bf0:	85 c0                	test   %eax,%eax
f0102bf2:	74 17                	je     f0102c0b <env_create+0x35>
		panic("env_create failed: env_alloc failed.\n");
f0102bf4:	83 ec 04             	sub    $0x4,%esp
f0102bf7:	68 fc 57 10 f0       	push   $0xf01057fc
f0102bfc:	68 96 01 00 00       	push   $0x196
f0102c01:	68 5a 58 10 f0       	push   $0xf010585a
f0102c06:	e8 95 d4 ff ff       	call   f01000a0 <_panic>
	}

	load_icode(e, binary);
f0102c0b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c0e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	 struct Elf *elf = (struct Elf *) binary;
    if (elf->e_magic != ELF_MAGIC) {
f0102c11:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102c17:	74 17                	je     f0102c30 <env_create+0x5a>
        panic("ELF format error");
f0102c19:	83 ec 04             	sub    $0x4,%esp
f0102c1c:	68 8e 58 10 f0       	push   $0xf010588e
f0102c21:	68 69 01 00 00       	push   $0x169
f0102c26:	68 5a 58 10 f0       	push   $0xf010585a
f0102c2b:	e8 70 d4 ff ff       	call   f01000a0 <_panic>
    }

    struct Proghdr *ph, *eph;
    ph = (struct Proghdr *) (binary + elf->e_phoff);
f0102c30:	89 fb                	mov    %edi,%ebx
f0102c32:	03 5f 1c             	add    0x1c(%edi),%ebx
    eph = ph + elf->e_phnum;
f0102c35:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102c39:	c1 e6 05             	shl    $0x5,%esi
f0102c3c:	01 de                	add    %ebx,%esi

    lcr3(PADDR(e->env_pgdir));
f0102c3e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c41:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c44:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c49:	77 15                	ja     f0102c60 <env_create+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c4b:	50                   	push   %eax
f0102c4c:	68 04 51 10 f0       	push   $0xf0105104
f0102c51:	68 70 01 00 00       	push   $0x170
f0102c56:	68 5a 58 10 f0       	push   $0xf010585a
f0102c5b:	e8 40 d4 ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102c60:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c65:	0f 22 d8             	mov    %eax,%cr3
f0102c68:	eb 3d                	jmp    f0102ca7 <env_create+0xd1>

    for (; ph < eph; ph++) {
        if (ph->p_type != ELF_PROG_LOAD) {
f0102c6a:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102c6d:	75 35                	jne    f0102ca4 <env_create+0xce>
            continue;
        }

        //cprintf("va = %p\n", ph->p_va);
        region_alloc(e, (void *)ph->p_va, ph->p_memsz); 
f0102c6f:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102c72:	8b 53 08             	mov    0x8(%ebx),%edx
f0102c75:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c78:	e8 60 fc ff ff       	call   f01028dd <region_alloc>
        memset((void *)ph->p_va, 0, ph->p_memsz);
f0102c7d:	83 ec 04             	sub    $0x4,%esp
f0102c80:	ff 73 14             	pushl  0x14(%ebx)
f0102c83:	6a 00                	push   $0x0
f0102c85:	ff 73 08             	pushl  0x8(%ebx)
f0102c88:	e8 92 16 00 00       	call   f010431f <memset>
        memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0102c8d:	83 c4 0c             	add    $0xc,%esp
f0102c90:	ff 73 10             	pushl  0x10(%ebx)
f0102c93:	89 f8                	mov    %edi,%eax
f0102c95:	03 43 04             	add    0x4(%ebx),%eax
f0102c98:	50                   	push   %eax
f0102c99:	ff 73 08             	pushl  0x8(%ebx)
f0102c9c:	e8 33 17 00 00       	call   f01043d4 <memcpy>
f0102ca1:	83 c4 10             	add    $0x10,%esp
    ph = (struct Proghdr *) (binary + elf->e_phoff);
    eph = ph + elf->e_phnum;

    lcr3(PADDR(e->env_pgdir));

    for (; ph < eph; ph++) {
f0102ca4:	83 c3 20             	add    $0x20,%ebx
f0102ca7:	39 de                	cmp    %ebx,%esi
f0102ca9:	77 bf                	ja     f0102c6a <env_create+0x94>
        region_alloc(e, (void *)ph->p_va, ph->p_memsz); 
        memset((void *)ph->p_va, 0, ph->p_memsz);
        memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
    }

    e->env_tf.tf_eip = elf->e_entry;
f0102cab:	8b 47 18             	mov    0x18(%edi),%eax
f0102cae:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102cb1:	89 47 30             	mov    %eax,0x30(%edi)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
    region_alloc(e, (void *)(USTACKTOP - PGSIZE), PGSIZE);
f0102cb4:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102cb9:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102cbe:	89 f8                	mov    %edi,%eax
f0102cc0:	e8 18 fc ff ff       	call   f01028dd <region_alloc>
	lcr3(PADDR(kern_pgdir));
f0102cc5:	a1 08 db 17 f0       	mov    0xf017db08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102cca:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ccf:	77 15                	ja     f0102ce6 <env_create+0x110>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102cd1:	50                   	push   %eax
f0102cd2:	68 04 51 10 f0       	push   $0xf0105104
f0102cd7:	68 85 01 00 00       	push   $0x185
f0102cdc:	68 5a 58 10 f0       	push   $0xf010585a
f0102ce1:	e8 ba d3 ff ff       	call   f01000a0 <_panic>
f0102ce6:	05 00 00 00 10       	add    $0x10000000,%eax
f0102ceb:	0f 22 d8             	mov    %eax,%cr3
	if((rc = env_alloc(&e, 0)) != 0) {
		panic("env_create failed: env_alloc failed.\n");
	}

	load_icode(e, binary);
	e->env_type = type;
f0102cee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102cf1:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102cf4:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102cf7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102cfa:	5b                   	pop    %ebx
f0102cfb:	5e                   	pop    %esi
f0102cfc:	5f                   	pop    %edi
f0102cfd:	5d                   	pop    %ebp
f0102cfe:	c3                   	ret    

f0102cff <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102cff:	55                   	push   %ebp
f0102d00:	89 e5                	mov    %esp,%ebp
f0102d02:	57                   	push   %edi
f0102d03:	56                   	push   %esi
f0102d04:	53                   	push   %ebx
f0102d05:	83 ec 1c             	sub    $0x1c,%esp
f0102d08:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102d0b:	8b 15 48 ce 17 f0    	mov    0xf017ce48,%edx
f0102d11:	39 fa                	cmp    %edi,%edx
f0102d13:	75 29                	jne    f0102d3e <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102d15:	a1 08 db 17 f0       	mov    0xf017db08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d1a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d1f:	77 15                	ja     f0102d36 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d21:	50                   	push   %eax
f0102d22:	68 04 51 10 f0       	push   $0xf0105104
f0102d27:	68 ab 01 00 00       	push   $0x1ab
f0102d2c:	68 5a 58 10 f0       	push   $0xf010585a
f0102d31:	e8 6a d3 ff ff       	call   f01000a0 <_panic>
f0102d36:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d3b:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102d3e:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102d41:	85 d2                	test   %edx,%edx
f0102d43:	74 05                	je     f0102d4a <env_free+0x4b>
f0102d45:	8b 42 48             	mov    0x48(%edx),%eax
f0102d48:	eb 05                	jmp    f0102d4f <env_free+0x50>
f0102d4a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d4f:	83 ec 04             	sub    $0x4,%esp
f0102d52:	51                   	push   %ecx
f0102d53:	50                   	push   %eax
f0102d54:	68 9f 58 10 f0       	push   $0xf010589f
f0102d59:	e8 76 02 00 00       	call   f0102fd4 <cprintf>
f0102d5e:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d61:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102d68:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102d6b:	89 d0                	mov    %edx,%eax
f0102d6d:	c1 e0 02             	shl    $0x2,%eax
f0102d70:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102d73:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d76:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102d79:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102d7f:	0f 84 a8 00 00 00    	je     f0102e2d <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102d85:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d8b:	89 f0                	mov    %esi,%eax
f0102d8d:	c1 e8 0c             	shr    $0xc,%eax
f0102d90:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d93:	39 05 04 db 17 f0    	cmp    %eax,0xf017db04
f0102d99:	77 15                	ja     f0102db0 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d9b:	56                   	push   %esi
f0102d9c:	68 1c 50 10 f0       	push   $0xf010501c
f0102da1:	68 ba 01 00 00       	push   $0x1ba
f0102da6:	68 5a 58 10 f0       	push   $0xf010585a
f0102dab:	e8 f0 d2 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102db0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102db3:	c1 e0 16             	shl    $0x16,%eax
f0102db6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102db9:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102dbe:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102dc5:	01 
f0102dc6:	74 17                	je     f0102ddf <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102dc8:	83 ec 08             	sub    $0x8,%esp
f0102dcb:	89 d8                	mov    %ebx,%eax
f0102dcd:	c1 e0 0c             	shl    $0xc,%eax
f0102dd0:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102dd3:	50                   	push   %eax
f0102dd4:	ff 77 5c             	pushl  0x5c(%edi)
f0102dd7:	e8 2a e2 ff ff       	call   f0101006 <page_remove>
f0102ddc:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102ddf:	83 c3 01             	add    $0x1,%ebx
f0102de2:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102de8:	75 d4                	jne    f0102dbe <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102dea:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102ded:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102df0:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102df7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102dfa:	3b 05 04 db 17 f0    	cmp    0xf017db04,%eax
f0102e00:	72 14                	jb     f0102e16 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102e02:	83 ec 04             	sub    $0x4,%esp
f0102e05:	68 28 51 10 f0       	push   $0xf0105128
f0102e0a:	6a 4f                	push   $0x4f
f0102e0c:	68 1f 4d 10 f0       	push   $0xf0104d1f
f0102e11:	e8 8a d2 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102e16:	83 ec 0c             	sub    $0xc,%esp
f0102e19:	a1 0c db 17 f0       	mov    0xf017db0c,%eax
f0102e1e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e21:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102e24:	50                   	push   %eax
f0102e25:	e8 1d e0 ff ff       	call   f0100e47 <page_decref>
f0102e2a:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102e2d:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102e31:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102e34:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102e39:	0f 85 29 ff ff ff    	jne    f0102d68 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102e3f:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e42:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e47:	77 15                	ja     f0102e5e <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e49:	50                   	push   %eax
f0102e4a:	68 04 51 10 f0       	push   $0xf0105104
f0102e4f:	68 c8 01 00 00       	push   $0x1c8
f0102e54:	68 5a 58 10 f0       	push   $0xf010585a
f0102e59:	e8 42 d2 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102e5e:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e65:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e6a:	c1 e8 0c             	shr    $0xc,%eax
f0102e6d:	3b 05 04 db 17 f0    	cmp    0xf017db04,%eax
f0102e73:	72 14                	jb     f0102e89 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102e75:	83 ec 04             	sub    $0x4,%esp
f0102e78:	68 28 51 10 f0       	push   $0xf0105128
f0102e7d:	6a 4f                	push   $0x4f
f0102e7f:	68 1f 4d 10 f0       	push   $0xf0104d1f
f0102e84:	e8 17 d2 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102e89:	83 ec 0c             	sub    $0xc,%esp
f0102e8c:	8b 15 0c db 17 f0    	mov    0xf017db0c,%edx
f0102e92:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102e95:	50                   	push   %eax
f0102e96:	e8 ac df ff ff       	call   f0100e47 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102e9b:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102ea2:	a1 50 ce 17 f0       	mov    0xf017ce50,%eax
f0102ea7:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102eaa:	89 3d 50 ce 17 f0    	mov    %edi,0xf017ce50
}
f0102eb0:	83 c4 10             	add    $0x10,%esp
f0102eb3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102eb6:	5b                   	pop    %ebx
f0102eb7:	5e                   	pop    %esi
f0102eb8:	5f                   	pop    %edi
f0102eb9:	5d                   	pop    %ebp
f0102eba:	c3                   	ret    

f0102ebb <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102ebb:	55                   	push   %ebp
f0102ebc:	89 e5                	mov    %esp,%ebp
f0102ebe:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102ec1:	ff 75 08             	pushl  0x8(%ebp)
f0102ec4:	e8 36 fe ff ff       	call   f0102cff <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102ec9:	c7 04 24 24 58 10 f0 	movl   $0xf0105824,(%esp)
f0102ed0:	e8 ff 00 00 00       	call   f0102fd4 <cprintf>
f0102ed5:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102ed8:	83 ec 0c             	sub    $0xc,%esp
f0102edb:	6a 00                	push   $0x0
f0102edd:	e8 0b d9 ff ff       	call   f01007ed <monitor>
f0102ee2:	83 c4 10             	add    $0x10,%esp
f0102ee5:	eb f1                	jmp    f0102ed8 <env_destroy+0x1d>

f0102ee7 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102ee7:	55                   	push   %ebp
f0102ee8:	89 e5                	mov    %esp,%ebp
f0102eea:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102eed:	8b 65 08             	mov    0x8(%ebp),%esp
f0102ef0:	61                   	popa   
f0102ef1:	07                   	pop    %es
f0102ef2:	1f                   	pop    %ds
f0102ef3:	83 c4 08             	add    $0x8,%esp
f0102ef6:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102ef7:	68 b5 58 10 f0       	push   $0xf01058b5
f0102efc:	68 f0 01 00 00       	push   $0x1f0
f0102f01:	68 5a 58 10 f0       	push   $0xf010585a
f0102f06:	e8 95 d1 ff ff       	call   f01000a0 <_panic>

f0102f0b <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102f0b:	55                   	push   %ebp
f0102f0c:	89 e5                	mov    %esp,%ebp
f0102f0e:	83 ec 08             	sub    $0x8,%esp
f0102f11:	8b 45 08             	mov    0x8(%ebp),%eax
	//	   4. Update its 'env_runs' counter,
	//	   5. Use lcr3() to switch to its address space.
	// Step 2: Use env_pop_tf() to restore the environment's
	//	   registers and drop into user mode in the
	//	   environment.
	if(curenv != NULL && curenv->env_status == ENV_RUNNING) {
f0102f14:	8b 15 48 ce 17 f0    	mov    0xf017ce48,%edx
f0102f1a:	85 d2                	test   %edx,%edx
f0102f1c:	74 0d                	je     f0102f2b <env_run+0x20>
f0102f1e:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102f22:	75 07                	jne    f0102f2b <env_run+0x20>
		curenv->env_status = ENV_RUNNABLE;
f0102f24:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}

	curenv = e;
f0102f2b:	a3 48 ce 17 f0       	mov    %eax,0xf017ce48
	curenv->env_status = ENV_RUNNING;
f0102f30:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0102f37:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv->env_pgdir));
f0102f3b:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f3e:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102f44:	77 15                	ja     f0102f5b <env_run+0x50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f46:	52                   	push   %edx
f0102f47:	68 04 51 10 f0       	push   $0xf0105104
f0102f4c:	68 0e 02 00 00       	push   $0x20e
f0102f51:	68 5a 58 10 f0       	push   $0xf010585a
f0102f56:	e8 45 d1 ff ff       	call   f01000a0 <_panic>
f0102f5b:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102f61:	0f 22 da             	mov    %edx,%cr3
	// Hint: This function loads the new environment's state from
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.
	env_pop_tf(&curenv->env_tf);
f0102f64:	83 ec 0c             	sub    $0xc,%esp
f0102f67:	50                   	push   %eax
f0102f68:	e8 7a ff ff ff       	call   f0102ee7 <env_pop_tf>

f0102f6d <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102f6d:	55                   	push   %ebp
f0102f6e:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f70:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f75:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f78:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102f79:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f7e:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102f7f:	0f b6 c0             	movzbl %al,%eax
}
f0102f82:	5d                   	pop    %ebp
f0102f83:	c3                   	ret    

f0102f84 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102f84:	55                   	push   %ebp
f0102f85:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f87:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f8c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f8f:	ee                   	out    %al,(%dx)
f0102f90:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f95:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f98:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102f99:	5d                   	pop    %ebp
f0102f9a:	c3                   	ret    

f0102f9b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102f9b:	55                   	push   %ebp
f0102f9c:	89 e5                	mov    %esp,%ebp
f0102f9e:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102fa1:	ff 75 08             	pushl  0x8(%ebp)
f0102fa4:	e8 5e d6 ff ff       	call   f0100607 <cputchar>
	*cnt++;
}
f0102fa9:	83 c4 10             	add    $0x10,%esp
f0102fac:	c9                   	leave  
f0102fad:	c3                   	ret    

f0102fae <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102fae:	55                   	push   %ebp
f0102faf:	89 e5                	mov    %esp,%ebp
f0102fb1:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102fb4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102fbb:	ff 75 0c             	pushl  0xc(%ebp)
f0102fbe:	ff 75 08             	pushl  0x8(%ebp)
f0102fc1:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102fc4:	50                   	push   %eax
f0102fc5:	68 9b 2f 10 f0       	push   $0xf0102f9b
f0102fca:	e8 2b 0c 00 00       	call   f0103bfa <vprintfmt>
	return cnt;
}
f0102fcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fd2:	c9                   	leave  
f0102fd3:	c3                   	ret    

f0102fd4 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102fd4:	55                   	push   %ebp
f0102fd5:	89 e5                	mov    %esp,%ebp
f0102fd7:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102fda:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102fdd:	50                   	push   %eax
f0102fde:	ff 75 08             	pushl  0x8(%ebp)
f0102fe1:	e8 c8 ff ff ff       	call   f0102fae <vcprintf>
	va_end(ap);

	return cnt;
}
f0102fe6:	c9                   	leave  
f0102fe7:	c3                   	ret    

f0102fe8 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102fe8:	55                   	push   %ebp
f0102fe9:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102feb:	b8 80 d6 17 f0       	mov    $0xf017d680,%eax
f0102ff0:	c7 05 84 d6 17 f0 00 	movl   $0xf0000000,0xf017d684
f0102ff7:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102ffa:	66 c7 05 88 d6 17 f0 	movw   $0x10,0xf017d688
f0103001:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103003:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f010300a:	67 00 
f010300c:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f0103012:	89 c2                	mov    %eax,%edx
f0103014:	c1 ea 10             	shr    $0x10,%edx
f0103017:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f010301d:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0103024:	c1 e8 18             	shr    $0x18,%eax
f0103027:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f010302c:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0103033:	b8 28 00 00 00       	mov    $0x28,%eax
f0103038:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f010303b:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0103040:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103043:	5d                   	pop    %ebp
f0103044:	c3                   	ret    

f0103045 <trap_init>:
}


void
trap_init(void)
{
f0103045:	55                   	push   %ebp
f0103046:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f0103048:	b8 06 37 10 f0       	mov    $0xf0103706,%eax
f010304d:	66 a3 60 ce 17 f0    	mov    %ax,0xf017ce60
f0103053:	66 c7 05 62 ce 17 f0 	movw   $0x8,0xf017ce62
f010305a:	08 00 
f010305c:	c6 05 64 ce 17 f0 00 	movb   $0x0,0xf017ce64
f0103063:	c6 05 65 ce 17 f0 8e 	movb   $0x8e,0xf017ce65
f010306a:	c1 e8 10             	shr    $0x10,%eax
f010306d:	66 a3 66 ce 17 f0    	mov    %ax,0xf017ce66
	SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f0103073:	b8 0c 37 10 f0       	mov    $0xf010370c,%eax
f0103078:	66 a3 68 ce 17 f0    	mov    %ax,0xf017ce68
f010307e:	66 c7 05 6a ce 17 f0 	movw   $0x8,0xf017ce6a
f0103085:	08 00 
f0103087:	c6 05 6c ce 17 f0 00 	movb   $0x0,0xf017ce6c
f010308e:	c6 05 6d ce 17 f0 8e 	movb   $0x8e,0xf017ce6d
f0103095:	c1 e8 10             	shr    $0x10,%eax
f0103098:	66 a3 6e ce 17 f0    	mov    %ax,0xf017ce6e
	SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f010309e:	b8 12 37 10 f0       	mov    $0xf0103712,%eax
f01030a3:	66 a3 70 ce 17 f0    	mov    %ax,0xf017ce70
f01030a9:	66 c7 05 72 ce 17 f0 	movw   $0x8,0xf017ce72
f01030b0:	08 00 
f01030b2:	c6 05 74 ce 17 f0 00 	movb   $0x0,0xf017ce74
f01030b9:	c6 05 75 ce 17 f0 8e 	movb   $0x8e,0xf017ce75
f01030c0:	c1 e8 10             	shr    $0x10,%eax
f01030c3:	66 a3 76 ce 17 f0    	mov    %ax,0xf017ce76
	SETGATE(idt[T_BRKPT], 0, GD_KT, t_brkpt, 3);
f01030c9:	b8 18 37 10 f0       	mov    $0xf0103718,%eax
f01030ce:	66 a3 78 ce 17 f0    	mov    %ax,0xf017ce78
f01030d4:	66 c7 05 7a ce 17 f0 	movw   $0x8,0xf017ce7a
f01030db:	08 00 
f01030dd:	c6 05 7c ce 17 f0 00 	movb   $0x0,0xf017ce7c
f01030e4:	c6 05 7d ce 17 f0 ee 	movb   $0xee,0xf017ce7d
f01030eb:	c1 e8 10             	shr    $0x10,%eax
f01030ee:	66 a3 7e ce 17 f0    	mov    %ax,0xf017ce7e
	SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f01030f4:	b8 1e 37 10 f0       	mov    $0xf010371e,%eax
f01030f9:	66 a3 80 ce 17 f0    	mov    %ax,0xf017ce80
f01030ff:	66 c7 05 82 ce 17 f0 	movw   $0x8,0xf017ce82
f0103106:	08 00 
f0103108:	c6 05 84 ce 17 f0 00 	movb   $0x0,0xf017ce84
f010310f:	c6 05 85 ce 17 f0 8e 	movb   $0x8e,0xf017ce85
f0103116:	c1 e8 10             	shr    $0x10,%eax
f0103119:	66 a3 86 ce 17 f0    	mov    %ax,0xf017ce86
	SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f010311f:	b8 24 37 10 f0       	mov    $0xf0103724,%eax
f0103124:	66 a3 88 ce 17 f0    	mov    %ax,0xf017ce88
f010312a:	66 c7 05 8a ce 17 f0 	movw   $0x8,0xf017ce8a
f0103131:	08 00 
f0103133:	c6 05 8c ce 17 f0 00 	movb   $0x0,0xf017ce8c
f010313a:	c6 05 8d ce 17 f0 8e 	movb   $0x8e,0xf017ce8d
f0103141:	c1 e8 10             	shr    $0x10,%eax
f0103144:	66 a3 8e ce 17 f0    	mov    %ax,0xf017ce8e
	SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f010314a:	b8 2a 37 10 f0       	mov    $0xf010372a,%eax
f010314f:	66 a3 90 ce 17 f0    	mov    %ax,0xf017ce90
f0103155:	66 c7 05 92 ce 17 f0 	movw   $0x8,0xf017ce92
f010315c:	08 00 
f010315e:	c6 05 94 ce 17 f0 00 	movb   $0x0,0xf017ce94
f0103165:	c6 05 95 ce 17 f0 8e 	movb   $0x8e,0xf017ce95
f010316c:	c1 e8 10             	shr    $0x10,%eax
f010316f:	66 a3 96 ce 17 f0    	mov    %ax,0xf017ce96
	SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f0103175:	b8 30 37 10 f0       	mov    $0xf0103730,%eax
f010317a:	66 a3 98 ce 17 f0    	mov    %ax,0xf017ce98
f0103180:	66 c7 05 9a ce 17 f0 	movw   $0x8,0xf017ce9a
f0103187:	08 00 
f0103189:	c6 05 9c ce 17 f0 00 	movb   $0x0,0xf017ce9c
f0103190:	c6 05 9d ce 17 f0 8e 	movb   $0x8e,0xf017ce9d
f0103197:	c1 e8 10             	shr    $0x10,%eax
f010319a:	66 a3 9e ce 17 f0    	mov    %ax,0xf017ce9e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f01031a0:	b8 36 37 10 f0       	mov    $0xf0103736,%eax
f01031a5:	66 a3 a0 ce 17 f0    	mov    %ax,0xf017cea0
f01031ab:	66 c7 05 a2 ce 17 f0 	movw   $0x8,0xf017cea2
f01031b2:	08 00 
f01031b4:	c6 05 a4 ce 17 f0 00 	movb   $0x0,0xf017cea4
f01031bb:	c6 05 a5 ce 17 f0 8e 	movb   $0x8e,0xf017cea5
f01031c2:	c1 e8 10             	shr    $0x10,%eax
f01031c5:	66 a3 a6 ce 17 f0    	mov    %ax,0xf017cea6
	SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f01031cb:	b8 3a 37 10 f0       	mov    $0xf010373a,%eax
f01031d0:	66 a3 b0 ce 17 f0    	mov    %ax,0xf017ceb0
f01031d6:	66 c7 05 b2 ce 17 f0 	movw   $0x8,0xf017ceb2
f01031dd:	08 00 
f01031df:	c6 05 b4 ce 17 f0 00 	movb   $0x0,0xf017ceb4
f01031e6:	c6 05 b5 ce 17 f0 8e 	movb   $0x8e,0xf017ceb5
f01031ed:	c1 e8 10             	shr    $0x10,%eax
f01031f0:	66 a3 b6 ce 17 f0    	mov    %ax,0xf017ceb6
	SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f01031f6:	b8 3e 37 10 f0       	mov    $0xf010373e,%eax
f01031fb:	66 a3 b8 ce 17 f0    	mov    %ax,0xf017ceb8
f0103201:	66 c7 05 ba ce 17 f0 	movw   $0x8,0xf017ceba
f0103208:	08 00 
f010320a:	c6 05 bc ce 17 f0 00 	movb   $0x0,0xf017cebc
f0103211:	c6 05 bd ce 17 f0 8e 	movb   $0x8e,0xf017cebd
f0103218:	c1 e8 10             	shr    $0x10,%eax
f010321b:	66 a3 be ce 17 f0    	mov    %ax,0xf017cebe
	SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f0103221:	b8 42 37 10 f0       	mov    $0xf0103742,%eax
f0103226:	66 a3 c0 ce 17 f0    	mov    %ax,0xf017cec0
f010322c:	66 c7 05 c2 ce 17 f0 	movw   $0x8,0xf017cec2
f0103233:	08 00 
f0103235:	c6 05 c4 ce 17 f0 00 	movb   $0x0,0xf017cec4
f010323c:	c6 05 c5 ce 17 f0 8e 	movb   $0x8e,0xf017cec5
f0103243:	c1 e8 10             	shr    $0x10,%eax
f0103246:	66 a3 c6 ce 17 f0    	mov    %ax,0xf017cec6
	SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f010324c:	b8 46 37 10 f0       	mov    $0xf0103746,%eax
f0103251:	66 a3 c8 ce 17 f0    	mov    %ax,0xf017cec8
f0103257:	66 c7 05 ca ce 17 f0 	movw   $0x8,0xf017ceca
f010325e:	08 00 
f0103260:	c6 05 cc ce 17 f0 00 	movb   $0x0,0xf017cecc
f0103267:	c6 05 cd ce 17 f0 8e 	movb   $0x8e,0xf017cecd
f010326e:	c1 e8 10             	shr    $0x10,%eax
f0103271:	66 a3 ce ce 17 f0    	mov    %ax,0xf017cece
	SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f0103277:	b8 4a 37 10 f0       	mov    $0xf010374a,%eax
f010327c:	66 a3 d0 ce 17 f0    	mov    %ax,0xf017ced0
f0103282:	66 c7 05 d2 ce 17 f0 	movw   $0x8,0xf017ced2
f0103289:	08 00 
f010328b:	c6 05 d4 ce 17 f0 00 	movb   $0x0,0xf017ced4
f0103292:	c6 05 d5 ce 17 f0 8e 	movb   $0x8e,0xf017ced5
f0103299:	c1 e8 10             	shr    $0x10,%eax
f010329c:	66 a3 d6 ce 17 f0    	mov    %ax,0xf017ced6
	SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f01032a2:	b8 4e 37 10 f0       	mov    $0xf010374e,%eax
f01032a7:	66 a3 e0 ce 17 f0    	mov    %ax,0xf017cee0
f01032ad:	66 c7 05 e2 ce 17 f0 	movw   $0x8,0xf017cee2
f01032b4:	08 00 
f01032b6:	c6 05 e4 ce 17 f0 00 	movb   $0x0,0xf017cee4
f01032bd:	c6 05 e5 ce 17 f0 8e 	movb   $0x8e,0xf017cee5
f01032c4:	c1 e8 10             	shr    $0x10,%eax
f01032c7:	66 a3 e6 ce 17 f0    	mov    %ax,0xf017cee6
	SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f01032cd:	b8 54 37 10 f0       	mov    $0xf0103754,%eax
f01032d2:	66 a3 e8 ce 17 f0    	mov    %ax,0xf017cee8
f01032d8:	66 c7 05 ea ce 17 f0 	movw   $0x8,0xf017ceea
f01032df:	08 00 
f01032e1:	c6 05 ec ce 17 f0 00 	movb   $0x0,0xf017ceec
f01032e8:	c6 05 ed ce 17 f0 8e 	movb   $0x8e,0xf017ceed
f01032ef:	c1 e8 10             	shr    $0x10,%eax
f01032f2:	66 a3 ee ce 17 f0    	mov    %ax,0xf017ceee
	SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f01032f8:	b8 58 37 10 f0       	mov    $0xf0103758,%eax
f01032fd:	66 a3 f0 ce 17 f0    	mov    %ax,0xf017cef0
f0103303:	66 c7 05 f2 ce 17 f0 	movw   $0x8,0xf017cef2
f010330a:	08 00 
f010330c:	c6 05 f4 ce 17 f0 00 	movb   $0x0,0xf017cef4
f0103313:	c6 05 f5 ce 17 f0 8e 	movb   $0x8e,0xf017cef5
f010331a:	c1 e8 10             	shr    $0x10,%eax
f010331d:	66 a3 f6 ce 17 f0    	mov    %ax,0xf017cef6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f0103323:	b8 5e 37 10 f0       	mov    $0xf010375e,%eax
f0103328:	66 a3 f8 ce 17 f0    	mov    %ax,0xf017cef8
f010332e:	66 c7 05 fa ce 17 f0 	movw   $0x8,0xf017cefa
f0103335:	08 00 
f0103337:	c6 05 fc ce 17 f0 00 	movb   $0x0,0xf017cefc
f010333e:	c6 05 fd ce 17 f0 8e 	movb   $0x8e,0xf017cefd
f0103345:	c1 e8 10             	shr    $0x10,%eax
f0103348:	66 a3 fe ce 17 f0    	mov    %ax,0xf017cefe
	SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f010334e:	b8 64 37 10 f0       	mov    $0xf0103764,%eax
f0103353:	66 a3 e0 cf 17 f0    	mov    %ax,0xf017cfe0
f0103359:	66 c7 05 e2 cf 17 f0 	movw   $0x8,0xf017cfe2
f0103360:	08 00 
f0103362:	c6 05 e4 cf 17 f0 00 	movb   $0x0,0xf017cfe4
f0103369:	c6 05 e5 cf 17 f0 ee 	movb   $0xee,0xf017cfe5
f0103370:	c1 e8 10             	shr    $0x10,%eax
f0103373:	66 a3 e6 cf 17 f0    	mov    %ax,0xf017cfe6
	// Per-CPU setup 
	trap_init_percpu();
f0103379:	e8 6a fc ff ff       	call   f0102fe8 <trap_init_percpu>
}
f010337e:	5d                   	pop    %ebp
f010337f:	c3                   	ret    

f0103380 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103380:	55                   	push   %ebp
f0103381:	89 e5                	mov    %esp,%ebp
f0103383:	53                   	push   %ebx
f0103384:	83 ec 0c             	sub    $0xc,%esp
f0103387:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010338a:	ff 33                	pushl  (%ebx)
f010338c:	68 c1 58 10 f0       	push   $0xf01058c1
f0103391:	e8 3e fc ff ff       	call   f0102fd4 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103396:	83 c4 08             	add    $0x8,%esp
f0103399:	ff 73 04             	pushl  0x4(%ebx)
f010339c:	68 d0 58 10 f0       	push   $0xf01058d0
f01033a1:	e8 2e fc ff ff       	call   f0102fd4 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01033a6:	83 c4 08             	add    $0x8,%esp
f01033a9:	ff 73 08             	pushl  0x8(%ebx)
f01033ac:	68 df 58 10 f0       	push   $0xf01058df
f01033b1:	e8 1e fc ff ff       	call   f0102fd4 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01033b6:	83 c4 08             	add    $0x8,%esp
f01033b9:	ff 73 0c             	pushl  0xc(%ebx)
f01033bc:	68 ee 58 10 f0       	push   $0xf01058ee
f01033c1:	e8 0e fc ff ff       	call   f0102fd4 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01033c6:	83 c4 08             	add    $0x8,%esp
f01033c9:	ff 73 10             	pushl  0x10(%ebx)
f01033cc:	68 fd 58 10 f0       	push   $0xf01058fd
f01033d1:	e8 fe fb ff ff       	call   f0102fd4 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01033d6:	83 c4 08             	add    $0x8,%esp
f01033d9:	ff 73 14             	pushl  0x14(%ebx)
f01033dc:	68 0c 59 10 f0       	push   $0xf010590c
f01033e1:	e8 ee fb ff ff       	call   f0102fd4 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01033e6:	83 c4 08             	add    $0x8,%esp
f01033e9:	ff 73 18             	pushl  0x18(%ebx)
f01033ec:	68 1b 59 10 f0       	push   $0xf010591b
f01033f1:	e8 de fb ff ff       	call   f0102fd4 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01033f6:	83 c4 08             	add    $0x8,%esp
f01033f9:	ff 73 1c             	pushl  0x1c(%ebx)
f01033fc:	68 2a 59 10 f0       	push   $0xf010592a
f0103401:	e8 ce fb ff ff       	call   f0102fd4 <cprintf>
}
f0103406:	83 c4 10             	add    $0x10,%esp
f0103409:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010340c:	c9                   	leave  
f010340d:	c3                   	ret    

f010340e <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f010340e:	55                   	push   %ebp
f010340f:	89 e5                	mov    %esp,%ebp
f0103411:	56                   	push   %esi
f0103412:	53                   	push   %ebx
f0103413:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103416:	83 ec 08             	sub    $0x8,%esp
f0103419:	53                   	push   %ebx
f010341a:	68 7b 59 10 f0       	push   $0xf010597b
f010341f:	e8 b0 fb ff ff       	call   f0102fd4 <cprintf>
	print_regs(&tf->tf_regs);
f0103424:	89 1c 24             	mov    %ebx,(%esp)
f0103427:	e8 54 ff ff ff       	call   f0103380 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010342c:	83 c4 08             	add    $0x8,%esp
f010342f:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103433:	50                   	push   %eax
f0103434:	68 8d 59 10 f0       	push   $0xf010598d
f0103439:	e8 96 fb ff ff       	call   f0102fd4 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010343e:	83 c4 08             	add    $0x8,%esp
f0103441:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103445:	50                   	push   %eax
f0103446:	68 a0 59 10 f0       	push   $0xf01059a0
f010344b:	e8 84 fb ff ff       	call   f0102fd4 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103450:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103453:	83 c4 10             	add    $0x10,%esp
f0103456:	83 f8 13             	cmp    $0x13,%eax
f0103459:	77 09                	ja     f0103464 <print_trapframe+0x56>
		return excnames[trapno];
f010345b:	8b 14 85 20 5c 10 f0 	mov    -0xfefa3e0(,%eax,4),%edx
f0103462:	eb 10                	jmp    f0103474 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0103464:	83 f8 30             	cmp    $0x30,%eax
f0103467:	b9 45 59 10 f0       	mov    $0xf0105945,%ecx
f010346c:	ba 39 59 10 f0       	mov    $0xf0105939,%edx
f0103471:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103474:	83 ec 04             	sub    $0x4,%esp
f0103477:	52                   	push   %edx
f0103478:	50                   	push   %eax
f0103479:	68 b3 59 10 f0       	push   $0xf01059b3
f010347e:	e8 51 fb ff ff       	call   f0102fd4 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103483:	83 c4 10             	add    $0x10,%esp
f0103486:	3b 1d 60 d6 17 f0    	cmp    0xf017d660,%ebx
f010348c:	75 1a                	jne    f01034a8 <print_trapframe+0x9a>
f010348e:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103492:	75 14                	jne    f01034a8 <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103494:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103497:	83 ec 08             	sub    $0x8,%esp
f010349a:	50                   	push   %eax
f010349b:	68 c5 59 10 f0       	push   $0xf01059c5
f01034a0:	e8 2f fb ff ff       	call   f0102fd4 <cprintf>
f01034a5:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f01034a8:	83 ec 08             	sub    $0x8,%esp
f01034ab:	ff 73 2c             	pushl  0x2c(%ebx)
f01034ae:	68 d4 59 10 f0       	push   $0xf01059d4
f01034b3:	e8 1c fb ff ff       	call   f0102fd4 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01034b8:	83 c4 10             	add    $0x10,%esp
f01034bb:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01034bf:	75 49                	jne    f010350a <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f01034c1:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f01034c4:	89 c2                	mov    %eax,%edx
f01034c6:	83 e2 01             	and    $0x1,%edx
f01034c9:	ba 5f 59 10 f0       	mov    $0xf010595f,%edx
f01034ce:	b9 54 59 10 f0       	mov    $0xf0105954,%ecx
f01034d3:	0f 44 ca             	cmove  %edx,%ecx
f01034d6:	89 c2                	mov    %eax,%edx
f01034d8:	83 e2 02             	and    $0x2,%edx
f01034db:	ba 71 59 10 f0       	mov    $0xf0105971,%edx
f01034e0:	be 6b 59 10 f0       	mov    $0xf010596b,%esi
f01034e5:	0f 45 d6             	cmovne %esi,%edx
f01034e8:	83 e0 04             	and    $0x4,%eax
f01034eb:	be 82 5a 10 f0       	mov    $0xf0105a82,%esi
f01034f0:	b8 76 59 10 f0       	mov    $0xf0105976,%eax
f01034f5:	0f 44 c6             	cmove  %esi,%eax
f01034f8:	51                   	push   %ecx
f01034f9:	52                   	push   %edx
f01034fa:	50                   	push   %eax
f01034fb:	68 e2 59 10 f0       	push   $0xf01059e2
f0103500:	e8 cf fa ff ff       	call   f0102fd4 <cprintf>
f0103505:	83 c4 10             	add    $0x10,%esp
f0103508:	eb 10                	jmp    f010351a <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f010350a:	83 ec 0c             	sub    $0xc,%esp
f010350d:	68 e8 4f 10 f0       	push   $0xf0104fe8
f0103512:	e8 bd fa ff ff       	call   f0102fd4 <cprintf>
f0103517:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010351a:	83 ec 08             	sub    $0x8,%esp
f010351d:	ff 73 30             	pushl  0x30(%ebx)
f0103520:	68 f1 59 10 f0       	push   $0xf01059f1
f0103525:	e8 aa fa ff ff       	call   f0102fd4 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010352a:	83 c4 08             	add    $0x8,%esp
f010352d:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103531:	50                   	push   %eax
f0103532:	68 00 5a 10 f0       	push   $0xf0105a00
f0103537:	e8 98 fa ff ff       	call   f0102fd4 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010353c:	83 c4 08             	add    $0x8,%esp
f010353f:	ff 73 38             	pushl  0x38(%ebx)
f0103542:	68 13 5a 10 f0       	push   $0xf0105a13
f0103547:	e8 88 fa ff ff       	call   f0102fd4 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010354c:	83 c4 10             	add    $0x10,%esp
f010354f:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103553:	74 25                	je     f010357a <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103555:	83 ec 08             	sub    $0x8,%esp
f0103558:	ff 73 3c             	pushl  0x3c(%ebx)
f010355b:	68 22 5a 10 f0       	push   $0xf0105a22
f0103560:	e8 6f fa ff ff       	call   f0102fd4 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103565:	83 c4 08             	add    $0x8,%esp
f0103568:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010356c:	50                   	push   %eax
f010356d:	68 31 5a 10 f0       	push   $0xf0105a31
f0103572:	e8 5d fa ff ff       	call   f0102fd4 <cprintf>
f0103577:	83 c4 10             	add    $0x10,%esp
	}
}
f010357a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010357d:	5b                   	pop    %ebx
f010357e:	5e                   	pop    %esi
f010357f:	5d                   	pop    %ebp
f0103580:	c3                   	ret    

f0103581 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103581:	55                   	push   %ebp
f0103582:	89 e5                	mov    %esp,%ebp
f0103584:	53                   	push   %ebx
f0103585:	83 ec 04             	sub    $0x4,%esp
f0103588:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010358b:	0f 20 d0             	mov    %cr2,%eax
	
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010358e:	ff 73 30             	pushl  0x30(%ebx)
f0103591:	50                   	push   %eax
f0103592:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f0103597:	ff 70 48             	pushl  0x48(%eax)
f010359a:	68 cc 5b 10 f0       	push   $0xf0105bcc
f010359f:	e8 30 fa ff ff       	call   f0102fd4 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01035a4:	89 1c 24             	mov    %ebx,(%esp)
f01035a7:	e8 62 fe ff ff       	call   f010340e <print_trapframe>
	env_destroy(curenv);
f01035ac:	83 c4 04             	add    $0x4,%esp
f01035af:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f01035b5:	e8 01 f9 ff ff       	call   f0102ebb <env_destroy>
f01035ba:	83 c4 10             	add    $0x10,%esp
f01035bd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01035c0:	c9                   	leave  
f01035c1:	c3                   	ret    

f01035c2 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01035c2:	55                   	push   %ebp
f01035c3:	89 e5                	mov    %esp,%ebp
f01035c5:	57                   	push   %edi
f01035c6:	56                   	push   %esi
f01035c7:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01035ca:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f01035cb:	9c                   	pushf  
f01035cc:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01035cd:	f6 c4 02             	test   $0x2,%ah
f01035d0:	74 19                	je     f01035eb <trap+0x29>
f01035d2:	68 44 5a 10 f0       	push   $0xf0105a44
f01035d7:	68 39 4d 10 f0       	push   $0xf0104d39
f01035dc:	68 e6 00 00 00       	push   $0xe6
f01035e1:	68 5d 5a 10 f0       	push   $0xf0105a5d
f01035e6:	e8 b5 ca ff ff       	call   f01000a0 <_panic>

	//cprintf("Incoming TRAP frame at %p\n", tf);

	if ((tf->tf_cs & 3) == 3) {
f01035eb:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01035ef:	83 e0 03             	and    $0x3,%eax
f01035f2:	66 83 f8 03          	cmp    $0x3,%ax
f01035f6:	75 31                	jne    f0103629 <trap+0x67>
		// Trapped from user mode.
		assert(curenv);
f01035f8:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f01035fd:	85 c0                	test   %eax,%eax
f01035ff:	75 19                	jne    f010361a <trap+0x58>
f0103601:	68 69 5a 10 f0       	push   $0xf0105a69
f0103606:	68 39 4d 10 f0       	push   $0xf0104d39
f010360b:	68 ec 00 00 00       	push   $0xec
f0103610:	68 5d 5a 10 f0       	push   $0xf0105a5d
f0103615:	e8 86 ca ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f010361a:	b9 11 00 00 00       	mov    $0x11,%ecx
f010361f:	89 c7                	mov    %eax,%edi
f0103621:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103623:	8b 35 48 ce 17 f0    	mov    0xf017ce48,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103629:	89 35 60 d6 17 f0    	mov    %esi,0xf017d660
{
	
	int32_t ret_code;
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf->tf_trapno) {
f010362f:	8b 46 28             	mov    0x28(%esi),%eax
f0103632:	83 f8 03             	cmp    $0x3,%eax
f0103635:	74 26                	je     f010365d <trap+0x9b>
f0103637:	83 f8 03             	cmp    $0x3,%eax
f010363a:	77 07                	ja     f0103643 <trap+0x81>
f010363c:	83 f8 01             	cmp    $0x1,%eax
f010363f:	74 2a                	je     f010366b <trap+0xa9>
f0103641:	eb 57                	jmp    f010369a <trap+0xd8>
f0103643:	83 f8 0e             	cmp    $0xe,%eax
f0103646:	74 07                	je     f010364f <trap+0x8d>
f0103648:	83 f8 30             	cmp    $0x30,%eax
f010364b:	74 2c                	je     f0103679 <trap+0xb7>
f010364d:	eb 4b                	jmp    f010369a <trap+0xd8>
		case (T_PGFLT):
			page_fault_handler(tf);
f010364f:	83 ec 0c             	sub    $0xc,%esp
f0103652:	56                   	push   %esi
f0103653:	e8 29 ff ff ff       	call   f0103581 <page_fault_handler>
f0103658:	83 c4 10             	add    $0x10,%esp
f010365b:	eb 78                	jmp    f01036d5 <trap+0x113>
			break; 
		case (T_BRKPT):
			//print_trapframe(tf);
			monitor(tf);		
f010365d:	83 ec 0c             	sub    $0xc,%esp
f0103660:	56                   	push   %esi
f0103661:	e8 87 d1 ff ff       	call   f01007ed <monitor>
f0103666:	83 c4 10             	add    $0x10,%esp
f0103669:	eb 6a                	jmp    f01036d5 <trap+0x113>
			break;
		case (T_DEBUG):
			monitor(tf);
f010366b:	83 ec 0c             	sub    $0xc,%esp
f010366e:	56                   	push   %esi
f010366f:	e8 79 d1 ff ff       	call   f01007ed <monitor>
f0103674:	83 c4 10             	add    $0x10,%esp
f0103677:	eb 5c                	jmp    f01036d5 <trap+0x113>
			break;
		case (T_SYSCALL):
			//print_trapframe(tf);
			ret_code = syscall(
f0103679:	83 ec 08             	sub    $0x8,%esp
f010367c:	ff 76 04             	pushl  0x4(%esi)
f010367f:	ff 36                	pushl  (%esi)
f0103681:	ff 76 10             	pushl  0x10(%esi)
f0103684:	ff 76 18             	pushl  0x18(%esi)
f0103687:	ff 76 14             	pushl  0x14(%esi)
f010368a:	ff 76 1c             	pushl  0x1c(%esi)
f010368d:	e8 ea 00 00 00       	call   f010377c <syscall>
					tf->tf_regs.reg_edx,
					tf->tf_regs.reg_ecx,
					tf->tf_regs.reg_ebx,
					tf->tf_regs.reg_edi,
					tf->tf_regs.reg_esi);
			tf->tf_regs.reg_eax = ret_code;
f0103692:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103695:	83 c4 20             	add    $0x20,%esp
f0103698:	eb 3b                	jmp    f01036d5 <trap+0x113>
			break;
 		default:
			// Unexpected trap: The user process or the kernel has a bug.
			print_trapframe(tf);
f010369a:	83 ec 0c             	sub    $0xc,%esp
f010369d:	56                   	push   %esi
f010369e:	e8 6b fd ff ff       	call   f010340e <print_trapframe>
			if (tf->tf_cs == GD_KT)
f01036a3:	83 c4 10             	add    $0x10,%esp
f01036a6:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01036ab:	75 17                	jne    f01036c4 <trap+0x102>
				panic("unhandled trap in kernel");
f01036ad:	83 ec 04             	sub    $0x4,%esp
f01036b0:	68 70 5a 10 f0       	push   $0xf0105a70
f01036b5:	68 d4 00 00 00       	push   $0xd4
f01036ba:	68 5d 5a 10 f0       	push   $0xf0105a5d
f01036bf:	e8 dc c9 ff ff       	call   f01000a0 <_panic>
			else {
				env_destroy(curenv);
f01036c4:	83 ec 0c             	sub    $0xc,%esp
f01036c7:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f01036cd:	e8 e9 f7 ff ff       	call   f0102ebb <env_destroy>
f01036d2:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01036d5:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f01036da:	85 c0                	test   %eax,%eax
f01036dc:	74 06                	je     f01036e4 <trap+0x122>
f01036de:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01036e2:	74 19                	je     f01036fd <trap+0x13b>
f01036e4:	68 f0 5b 10 f0       	push   $0xf0105bf0
f01036e9:	68 39 4d 10 f0       	push   $0xf0104d39
f01036ee:	68 fe 00 00 00       	push   $0xfe
f01036f3:	68 5d 5a 10 f0       	push   $0xf0105a5d
f01036f8:	e8 a3 c9 ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f01036fd:	83 ec 0c             	sub    $0xc,%esp
f0103700:	50                   	push   %eax
f0103701:	e8 05 f8 ff ff       	call   f0102f0b <env_run>

f0103706 <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
f0103706:	6a 00                	push   $0x0
f0103708:	6a 00                	push   $0x0
f010370a:	eb 5e                	jmp    f010376a <_alltraps>

f010370c <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
f010370c:	6a 00                	push   $0x0
f010370e:	6a 01                	push   $0x1
f0103710:	eb 58                	jmp    f010376a <_alltraps>

f0103712 <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)
f0103712:	6a 00                	push   $0x0
f0103714:	6a 02                	push   $0x2
f0103716:	eb 52                	jmp    f010376a <_alltraps>

f0103718 <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
f0103718:	6a 00                	push   $0x0
f010371a:	6a 03                	push   $0x3
f010371c:	eb 4c                	jmp    f010376a <_alltraps>

f010371e <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
f010371e:	6a 00                	push   $0x0
f0103720:	6a 04                	push   $0x4
f0103722:	eb 46                	jmp    f010376a <_alltraps>

f0103724 <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)
f0103724:	6a 00                	push   $0x0
f0103726:	6a 05                	push   $0x5
f0103728:	eb 40                	jmp    f010376a <_alltraps>

f010372a <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
f010372a:	6a 00                	push   $0x0
f010372c:	6a 06                	push   $0x6
f010372e:	eb 3a                	jmp    f010376a <_alltraps>

f0103730 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)
f0103730:	6a 00                	push   $0x0
f0103732:	6a 07                	push   $0x7
f0103734:	eb 34                	jmp    f010376a <_alltraps>

f0103736 <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)
f0103736:	6a 08                	push   $0x8
f0103738:	eb 30                	jmp    f010376a <_alltraps>

f010373a <t_tss>:
TRAPHANDLER(t_tss, T_TSS)
f010373a:	6a 0a                	push   $0xa
f010373c:	eb 2c                	jmp    f010376a <_alltraps>

f010373e <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)
f010373e:	6a 0b                	push   $0xb
f0103740:	eb 28                	jmp    f010376a <_alltraps>

f0103742 <t_stack>:
TRAPHANDLER(t_stack, T_STACK)
f0103742:	6a 0c                	push   $0xc
f0103744:	eb 24                	jmp    f010376a <_alltraps>

f0103746 <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)
f0103746:	6a 0d                	push   $0xd
f0103748:	eb 20                	jmp    f010376a <_alltraps>

f010374a <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)
f010374a:	6a 0e                	push   $0xe
f010374c:	eb 1c                	jmp    f010376a <_alltraps>

f010374e <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR)
f010374e:	6a 00                	push   $0x0
f0103750:	6a 10                	push   $0x10
f0103752:	eb 16                	jmp    f010376a <_alltraps>

f0103754 <t_align>:
TRAPHANDLER(t_align, T_ALIGN)
f0103754:	6a 11                	push   $0x11
f0103756:	eb 12                	jmp    f010376a <_alltraps>

f0103758 <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
f0103758:	6a 00                	push   $0x0
f010375a:	6a 12                	push   $0x12
f010375c:	eb 0c                	jmp    f010376a <_alltraps>

f010375e <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)
f010375e:	6a 00                	push   $0x0
f0103760:	6a 13                	push   $0x13
f0103762:	eb 06                	jmp    f010376a <_alltraps>

f0103764 <t_syscall>:

TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)
f0103764:	6a 00                	push   $0x0
f0103766:	6a 30                	push   $0x30
f0103768:	eb 00                	jmp    f010376a <_alltraps>

f010376a <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f010376a:	1e                   	push   %ds
	pushl %es
f010376b:	06                   	push   %es
	pushal 
f010376c:	60                   	pusha  

	movl $GD_KD, %eax
f010376d:	b8 10 00 00 00       	mov    $0x10,%eax
	movw %ax, %ds
f0103772:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0103774:	8e c0                	mov    %eax,%es

	push %esp
f0103776:	54                   	push   %esp
f0103777:	e8 46 fe ff ff       	call   f01035c2 <trap>

f010377c <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010377c:	55                   	push   %ebp
f010377d:	89 e5                	mov    %esp,%ebp
f010377f:	83 ec 18             	sub    $0x18,%esp
f0103782:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f0103785:	83 f8 01             	cmp    $0x1,%eax
f0103788:	74 44                	je     f01037ce <syscall+0x52>
f010378a:	83 f8 01             	cmp    $0x1,%eax
f010378d:	72 0f                	jb     f010379e <syscall+0x22>
f010378f:	83 f8 02             	cmp    $0x2,%eax
f0103792:	74 41                	je     f01037d5 <syscall+0x59>
f0103794:	83 f8 03             	cmp    $0x3,%eax
f0103797:	74 46                	je     f01037df <syscall+0x63>
f0103799:	e9 a6 00 00 00       	jmp    f0103844 <syscall+0xc8>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U | PTE_P);
f010379e:	6a 05                	push   $0x5
f01037a0:	ff 75 10             	pushl  0x10(%ebp)
f01037a3:	ff 75 0c             	pushl  0xc(%ebp)
f01037a6:	ff 35 48 ce 17 f0    	pushl  0xf017ce48
f01037ac:	e8 e2 f0 ff ff       	call   f0102893 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01037b1:	83 c4 0c             	add    $0xc,%esp
f01037b4:	ff 75 0c             	pushl  0xc(%ebp)
f01037b7:	ff 75 10             	pushl  0x10(%ebp)
f01037ba:	68 70 5c 10 f0       	push   $0xf0105c70
f01037bf:	e8 10 f8 ff ff       	call   f0102fd4 <cprintf>
f01037c4:	83 c4 10             	add    $0x10,%esp
	//panic("syscall not implemented");

	switch (syscallno) {
		case (SYS_cputs):
			sys_cputs((const char *)a1, a2);
			return 0;
f01037c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01037cc:	eb 7b                	jmp    f0103849 <syscall+0xcd>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01037ce:	e8 e2 cc ff ff       	call   f01004b5 <cons_getc>
	switch (syscallno) {
		case (SYS_cputs):
			sys_cputs((const char *)a1, a2);
			return 0;
		case (SYS_cgetc):
			return sys_cgetc();
f01037d3:	eb 74                	jmp    f0103849 <syscall+0xcd>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01037d5:	a1 48 ce 17 f0       	mov    0xf017ce48,%eax
f01037da:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char *)a1, a2);
			return 0;
		case (SYS_cgetc):
			return sys_cgetc();
		case (SYS_getenvid):
			return sys_getenvid();
f01037dd:	eb 6a                	jmp    f0103849 <syscall+0xcd>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01037df:	83 ec 04             	sub    $0x4,%esp
f01037e2:	6a 01                	push   $0x1
f01037e4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01037e7:	50                   	push   %eax
f01037e8:	ff 75 0c             	pushl  0xc(%ebp)
f01037eb:	e8 73 f1 ff ff       	call   f0102963 <envid2env>
f01037f0:	83 c4 10             	add    $0x10,%esp
f01037f3:	85 c0                	test   %eax,%eax
f01037f5:	78 52                	js     f0103849 <syscall+0xcd>
		return r;
	if (e == curenv)
f01037f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01037fa:	8b 15 48 ce 17 f0    	mov    0xf017ce48,%edx
f0103800:	39 d0                	cmp    %edx,%eax
f0103802:	75 15                	jne    f0103819 <syscall+0x9d>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103804:	83 ec 08             	sub    $0x8,%esp
f0103807:	ff 70 48             	pushl  0x48(%eax)
f010380a:	68 75 5c 10 f0       	push   $0xf0105c75
f010380f:	e8 c0 f7 ff ff       	call   f0102fd4 <cprintf>
f0103814:	83 c4 10             	add    $0x10,%esp
f0103817:	eb 16                	jmp    f010382f <syscall+0xb3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103819:	83 ec 04             	sub    $0x4,%esp
f010381c:	ff 70 48             	pushl  0x48(%eax)
f010381f:	ff 72 48             	pushl  0x48(%edx)
f0103822:	68 90 5c 10 f0       	push   $0xf0105c90
f0103827:	e8 a8 f7 ff ff       	call   f0102fd4 <cprintf>
f010382c:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010382f:	83 ec 0c             	sub    $0xc,%esp
f0103832:	ff 75 f4             	pushl  -0xc(%ebp)
f0103835:	e8 81 f6 ff ff       	call   f0102ebb <env_destroy>
f010383a:	83 c4 10             	add    $0x10,%esp
	return 0;
f010383d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103842:	eb 05                	jmp    f0103849 <syscall+0xcd>
		case (SYS_getenvid):
			return sys_getenvid();
		case (SYS_env_destroy):
			return sys_env_destroy(a1);
		default:
			return -E_INVAL;
f0103844:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f0103849:	c9                   	leave  
f010384a:	c3                   	ret    

f010384b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010384b:	55                   	push   %ebp
f010384c:	89 e5                	mov    %esp,%ebp
f010384e:	57                   	push   %edi
f010384f:	56                   	push   %esi
f0103850:	53                   	push   %ebx
f0103851:	83 ec 14             	sub    $0x14,%esp
f0103854:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103857:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010385a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010385d:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103860:	8b 1a                	mov    (%edx),%ebx
f0103862:	8b 01                	mov    (%ecx),%eax
f0103864:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103867:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010386e:	eb 7f                	jmp    f01038ef <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0103870:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103873:	01 d8                	add    %ebx,%eax
f0103875:	89 c6                	mov    %eax,%esi
f0103877:	c1 ee 1f             	shr    $0x1f,%esi
f010387a:	01 c6                	add    %eax,%esi
f010387c:	d1 fe                	sar    %esi
f010387e:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103881:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103884:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103887:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103889:	eb 03                	jmp    f010388e <stab_binsearch+0x43>
			m--;
f010388b:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010388e:	39 c3                	cmp    %eax,%ebx
f0103890:	7f 0d                	jg     f010389f <stab_binsearch+0x54>
f0103892:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103896:	83 ea 0c             	sub    $0xc,%edx
f0103899:	39 f9                	cmp    %edi,%ecx
f010389b:	75 ee                	jne    f010388b <stab_binsearch+0x40>
f010389d:	eb 05                	jmp    f01038a4 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010389f:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01038a2:	eb 4b                	jmp    f01038ef <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01038a4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01038a7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01038aa:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01038ae:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01038b1:	76 11                	jbe    f01038c4 <stab_binsearch+0x79>
			*region_left = m;
f01038b3:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01038b6:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01038b8:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01038bb:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01038c2:	eb 2b                	jmp    f01038ef <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01038c4:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01038c7:	73 14                	jae    f01038dd <stab_binsearch+0x92>
			*region_right = m - 1;
f01038c9:	83 e8 01             	sub    $0x1,%eax
f01038cc:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01038cf:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01038d2:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01038d4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01038db:	eb 12                	jmp    f01038ef <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01038dd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01038e0:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01038e2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01038e6:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01038e8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01038ef:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01038f2:	0f 8e 78 ff ff ff    	jle    f0103870 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01038f8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01038fc:	75 0f                	jne    f010390d <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01038fe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103901:	8b 00                	mov    (%eax),%eax
f0103903:	83 e8 01             	sub    $0x1,%eax
f0103906:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103909:	89 06                	mov    %eax,(%esi)
f010390b:	eb 2c                	jmp    f0103939 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010390d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103910:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103912:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103915:	8b 0e                	mov    (%esi),%ecx
f0103917:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010391a:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010391d:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103920:	eb 03                	jmp    f0103925 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103922:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103925:	39 c8                	cmp    %ecx,%eax
f0103927:	7e 0b                	jle    f0103934 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103929:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010392d:	83 ea 0c             	sub    $0xc,%edx
f0103930:	39 df                	cmp    %ebx,%edi
f0103932:	75 ee                	jne    f0103922 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103934:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103937:	89 06                	mov    %eax,(%esi)
	}
}
f0103939:	83 c4 14             	add    $0x14,%esp
f010393c:	5b                   	pop    %ebx
f010393d:	5e                   	pop    %esi
f010393e:	5f                   	pop    %edi
f010393f:	5d                   	pop    %ebp
f0103940:	c3                   	ret    

f0103941 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103941:	55                   	push   %ebp
f0103942:	89 e5                	mov    %esp,%ebp
f0103944:	57                   	push   %edi
f0103945:	56                   	push   %esi
f0103946:	53                   	push   %ebx
f0103947:	83 ec 2c             	sub    $0x2c,%esp
f010394a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010394d:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103950:	c7 06 a8 5c 10 f0    	movl   $0xf0105ca8,(%esi)
	info->eip_line = 0;
f0103956:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010395d:	c7 46 08 a8 5c 10 f0 	movl   $0xf0105ca8,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103964:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010396b:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f010396e:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103975:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010397b:	77 21                	ja     f010399e <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f010397d:	a1 00 00 20 00       	mov    0x200000,%eax
f0103982:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f0103985:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f010398a:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0103990:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f0103993:	8b 0d 0c 00 20 00    	mov    0x20000c,%ecx
f0103999:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010399c:	eb 1a                	jmp    f01039b8 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010399e:	c7 45 d0 83 01 11 f0 	movl   $0xf0110183,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01039a5:	c7 45 cc 19 d7 10 f0 	movl   $0xf010d719,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01039ac:	b8 18 d7 10 f0       	mov    $0xf010d718,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01039b1:	c7 45 d4 d0 5e 10 f0 	movl   $0xf0105ed0,-0x2c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01039b8:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01039bb:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f01039be:	0f 83 2b 01 00 00    	jae    f0103aef <debuginfo_eip+0x1ae>
f01039c4:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f01039c8:	0f 85 28 01 00 00    	jne    f0103af6 <debuginfo_eip+0x1b5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01039ce:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01039d5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01039d8:	29 d8                	sub    %ebx,%eax
f01039da:	c1 f8 02             	sar    $0x2,%eax
f01039dd:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01039e3:	83 e8 01             	sub    $0x1,%eax
f01039e6:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01039e9:	57                   	push   %edi
f01039ea:	6a 64                	push   $0x64
f01039ec:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01039ef:	89 c1                	mov    %eax,%ecx
f01039f1:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01039f4:	89 d8                	mov    %ebx,%eax
f01039f6:	e8 50 fe ff ff       	call   f010384b <stab_binsearch>
	if (lfile == 0)
f01039fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01039fe:	83 c4 08             	add    $0x8,%esp
f0103a01:	85 c0                	test   %eax,%eax
f0103a03:	0f 84 f4 00 00 00    	je     f0103afd <debuginfo_eip+0x1bc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103a09:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103a0c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a0f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103a12:	57                   	push   %edi
f0103a13:	6a 24                	push   $0x24
f0103a15:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0103a18:	89 c1                	mov    %eax,%ecx
f0103a1a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103a1d:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0103a20:	89 d8                	mov    %ebx,%eax
f0103a22:	e8 24 fe ff ff       	call   f010384b <stab_binsearch>

	if (lfun <= rfun) {
f0103a27:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103a2a:	83 c4 08             	add    $0x8,%esp
f0103a2d:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0103a30:	7f 24                	jg     f0103a56 <debuginfo_eip+0x115>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103a32:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103a35:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103a38:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103a3b:	8b 02                	mov    (%edx),%eax
f0103a3d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103a40:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103a43:	29 f9                	sub    %edi,%ecx
f0103a45:	39 c8                	cmp    %ecx,%eax
f0103a47:	73 05                	jae    f0103a4e <debuginfo_eip+0x10d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103a49:	01 f8                	add    %edi,%eax
f0103a4b:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103a4e:	8b 42 08             	mov    0x8(%edx),%eax
f0103a51:	89 46 10             	mov    %eax,0x10(%esi)
f0103a54:	eb 06                	jmp    f0103a5c <debuginfo_eip+0x11b>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103a56:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0103a59:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103a5c:	83 ec 08             	sub    $0x8,%esp
f0103a5f:	6a 3a                	push   $0x3a
f0103a61:	ff 76 08             	pushl  0x8(%esi)
f0103a64:	e8 9a 08 00 00       	call   f0104303 <strfind>
f0103a69:	2b 46 08             	sub    0x8(%esi),%eax
f0103a6c:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103a6f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a72:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103a75:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103a78:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0103a7b:	83 c4 10             	add    $0x10,%esp
f0103a7e:	eb 06                	jmp    f0103a86 <debuginfo_eip+0x145>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103a80:	83 eb 01             	sub    $0x1,%ebx
f0103a83:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103a86:	39 fb                	cmp    %edi,%ebx
f0103a88:	7c 2d                	jl     f0103ab7 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0103a8a:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0103a8e:	80 fa 84             	cmp    $0x84,%dl
f0103a91:	74 0b                	je     f0103a9e <debuginfo_eip+0x15d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103a93:	80 fa 64             	cmp    $0x64,%dl
f0103a96:	75 e8                	jne    f0103a80 <debuginfo_eip+0x13f>
f0103a98:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0103a9c:	74 e2                	je     f0103a80 <debuginfo_eip+0x13f>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103a9e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103aa1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103aa4:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103aa7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103aaa:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103aad:	29 f8                	sub    %edi,%eax
f0103aaf:	39 c2                	cmp    %eax,%edx
f0103ab1:	73 04                	jae    f0103ab7 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103ab3:	01 fa                	add    %edi,%edx
f0103ab5:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103ab7:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103aba:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103abd:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103ac2:	39 cb                	cmp    %ecx,%ebx
f0103ac4:	7d 43                	jge    f0103b09 <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
f0103ac6:	8d 53 01             	lea    0x1(%ebx),%edx
f0103ac9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103acc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103acf:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0103ad2:	eb 07                	jmp    f0103adb <debuginfo_eip+0x19a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103ad4:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103ad8:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103adb:	39 ca                	cmp    %ecx,%edx
f0103add:	74 25                	je     f0103b04 <debuginfo_eip+0x1c3>
f0103adf:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103ae2:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0103ae6:	74 ec                	je     f0103ad4 <debuginfo_eip+0x193>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103ae8:	b8 00 00 00 00       	mov    $0x0,%eax
f0103aed:	eb 1a                	jmp    f0103b09 <debuginfo_eip+0x1c8>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103aef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103af4:	eb 13                	jmp    f0103b09 <debuginfo_eip+0x1c8>
f0103af6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103afb:	eb 0c                	jmp    f0103b09 <debuginfo_eip+0x1c8>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103afd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b02:	eb 05                	jmp    f0103b09 <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b04:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b09:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b0c:	5b                   	pop    %ebx
f0103b0d:	5e                   	pop    %esi
f0103b0e:	5f                   	pop    %edi
f0103b0f:	5d                   	pop    %ebp
f0103b10:	c3                   	ret    

f0103b11 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103b11:	55                   	push   %ebp
f0103b12:	89 e5                	mov    %esp,%ebp
f0103b14:	57                   	push   %edi
f0103b15:	56                   	push   %esi
f0103b16:	53                   	push   %ebx
f0103b17:	83 ec 1c             	sub    $0x1c,%esp
f0103b1a:	89 c7                	mov    %eax,%edi
f0103b1c:	89 d6                	mov    %edx,%esi
f0103b1e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b21:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b24:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103b27:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103b2a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103b2d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103b32:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103b35:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103b38:	39 d3                	cmp    %edx,%ebx
f0103b3a:	72 05                	jb     f0103b41 <printnum+0x30>
f0103b3c:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103b3f:	77 45                	ja     f0103b86 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103b41:	83 ec 0c             	sub    $0xc,%esp
f0103b44:	ff 75 18             	pushl  0x18(%ebp)
f0103b47:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b4a:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103b4d:	53                   	push   %ebx
f0103b4e:	ff 75 10             	pushl  0x10(%ebp)
f0103b51:	83 ec 08             	sub    $0x8,%esp
f0103b54:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103b57:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b5a:	ff 75 dc             	pushl  -0x24(%ebp)
f0103b5d:	ff 75 d8             	pushl  -0x28(%ebp)
f0103b60:	e8 cb 09 00 00       	call   f0104530 <__udivdi3>
f0103b65:	83 c4 18             	add    $0x18,%esp
f0103b68:	52                   	push   %edx
f0103b69:	50                   	push   %eax
f0103b6a:	89 f2                	mov    %esi,%edx
f0103b6c:	89 f8                	mov    %edi,%eax
f0103b6e:	e8 9e ff ff ff       	call   f0103b11 <printnum>
f0103b73:	83 c4 20             	add    $0x20,%esp
f0103b76:	eb 18                	jmp    f0103b90 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103b78:	83 ec 08             	sub    $0x8,%esp
f0103b7b:	56                   	push   %esi
f0103b7c:	ff 75 18             	pushl  0x18(%ebp)
f0103b7f:	ff d7                	call   *%edi
f0103b81:	83 c4 10             	add    $0x10,%esp
f0103b84:	eb 03                	jmp    f0103b89 <printnum+0x78>
f0103b86:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103b89:	83 eb 01             	sub    $0x1,%ebx
f0103b8c:	85 db                	test   %ebx,%ebx
f0103b8e:	7f e8                	jg     f0103b78 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103b90:	83 ec 08             	sub    $0x8,%esp
f0103b93:	56                   	push   %esi
f0103b94:	83 ec 04             	sub    $0x4,%esp
f0103b97:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103b9a:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b9d:	ff 75 dc             	pushl  -0x24(%ebp)
f0103ba0:	ff 75 d8             	pushl  -0x28(%ebp)
f0103ba3:	e8 b8 0a 00 00       	call   f0104660 <__umoddi3>
f0103ba8:	83 c4 14             	add    $0x14,%esp
f0103bab:	0f be 80 b2 5c 10 f0 	movsbl -0xfefa34e(%eax),%eax
f0103bb2:	50                   	push   %eax
f0103bb3:	ff d7                	call   *%edi
}
f0103bb5:	83 c4 10             	add    $0x10,%esp
f0103bb8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103bbb:	5b                   	pop    %ebx
f0103bbc:	5e                   	pop    %esi
f0103bbd:	5f                   	pop    %edi
f0103bbe:	5d                   	pop    %ebp
f0103bbf:	c3                   	ret    

f0103bc0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103bc0:	55                   	push   %ebp
f0103bc1:	89 e5                	mov    %esp,%ebp
f0103bc3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103bc6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103bca:	8b 10                	mov    (%eax),%edx
f0103bcc:	3b 50 04             	cmp    0x4(%eax),%edx
f0103bcf:	73 0a                	jae    f0103bdb <sprintputch+0x1b>
		*b->buf++ = ch;
f0103bd1:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103bd4:	89 08                	mov    %ecx,(%eax)
f0103bd6:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bd9:	88 02                	mov    %al,(%edx)
}
f0103bdb:	5d                   	pop    %ebp
f0103bdc:	c3                   	ret    

f0103bdd <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103bdd:	55                   	push   %ebp
f0103bde:	89 e5                	mov    %esp,%ebp
f0103be0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103be3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103be6:	50                   	push   %eax
f0103be7:	ff 75 10             	pushl  0x10(%ebp)
f0103bea:	ff 75 0c             	pushl  0xc(%ebp)
f0103bed:	ff 75 08             	pushl  0x8(%ebp)
f0103bf0:	e8 05 00 00 00       	call   f0103bfa <vprintfmt>
	va_end(ap);
}
f0103bf5:	83 c4 10             	add    $0x10,%esp
f0103bf8:	c9                   	leave  
f0103bf9:	c3                   	ret    

f0103bfa <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103bfa:	55                   	push   %ebp
f0103bfb:	89 e5                	mov    %esp,%ebp
f0103bfd:	57                   	push   %edi
f0103bfe:	56                   	push   %esi
f0103bff:	53                   	push   %ebx
f0103c00:	83 ec 2c             	sub    $0x2c,%esp
f0103c03:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c06:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c09:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103c0c:	eb 12                	jmp    f0103c20 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103c0e:	85 c0                	test   %eax,%eax
f0103c10:	0f 84 42 04 00 00    	je     f0104058 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0103c16:	83 ec 08             	sub    $0x8,%esp
f0103c19:	53                   	push   %ebx
f0103c1a:	50                   	push   %eax
f0103c1b:	ff d6                	call   *%esi
f0103c1d:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103c20:	83 c7 01             	add    $0x1,%edi
f0103c23:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103c27:	83 f8 25             	cmp    $0x25,%eax
f0103c2a:	75 e2                	jne    f0103c0e <vprintfmt+0x14>
f0103c2c:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103c30:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103c37:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103c3e:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103c45:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103c4a:	eb 07                	jmp    f0103c53 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c4c:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103c4f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c53:	8d 47 01             	lea    0x1(%edi),%eax
f0103c56:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103c59:	0f b6 07             	movzbl (%edi),%eax
f0103c5c:	0f b6 d0             	movzbl %al,%edx
f0103c5f:	83 e8 23             	sub    $0x23,%eax
f0103c62:	3c 55                	cmp    $0x55,%al
f0103c64:	0f 87 d3 03 00 00    	ja     f010403d <vprintfmt+0x443>
f0103c6a:	0f b6 c0             	movzbl %al,%eax
f0103c6d:	ff 24 85 40 5d 10 f0 	jmp    *-0xfefa2c0(,%eax,4)
f0103c74:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103c77:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103c7b:	eb d6                	jmp    f0103c53 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c7d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c80:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c85:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103c88:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103c8b:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103c8f:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103c92:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103c95:	83 f9 09             	cmp    $0x9,%ecx
f0103c98:	77 3f                	ja     f0103cd9 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103c9a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103c9d:	eb e9                	jmp    f0103c88 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103c9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ca2:	8b 00                	mov    (%eax),%eax
f0103ca4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103ca7:	8b 45 14             	mov    0x14(%ebp),%eax
f0103caa:	8d 40 04             	lea    0x4(%eax),%eax
f0103cad:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cb0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103cb3:	eb 2a                	jmp    f0103cdf <vprintfmt+0xe5>
f0103cb5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103cb8:	85 c0                	test   %eax,%eax
f0103cba:	ba 00 00 00 00       	mov    $0x0,%edx
f0103cbf:	0f 49 d0             	cmovns %eax,%edx
f0103cc2:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cc5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103cc8:	eb 89                	jmp    f0103c53 <vprintfmt+0x59>
f0103cca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103ccd:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103cd4:	e9 7a ff ff ff       	jmp    f0103c53 <vprintfmt+0x59>
f0103cd9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103cdc:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103cdf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103ce3:	0f 89 6a ff ff ff    	jns    f0103c53 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103ce9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103cec:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103cef:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103cf6:	e9 58 ff ff ff       	jmp    f0103c53 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103cfb:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cfe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103d01:	e9 4d ff ff ff       	jmp    f0103c53 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103d06:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d09:	8d 78 04             	lea    0x4(%eax),%edi
f0103d0c:	83 ec 08             	sub    $0x8,%esp
f0103d0f:	53                   	push   %ebx
f0103d10:	ff 30                	pushl  (%eax)
f0103d12:	ff d6                	call   *%esi
			break;
f0103d14:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103d17:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d1a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103d1d:	e9 fe fe ff ff       	jmp    f0103c20 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103d22:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d25:	8d 78 04             	lea    0x4(%eax),%edi
f0103d28:	8b 00                	mov    (%eax),%eax
f0103d2a:	99                   	cltd   
f0103d2b:	31 d0                	xor    %edx,%eax
f0103d2d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103d2f:	83 f8 07             	cmp    $0x7,%eax
f0103d32:	7f 0b                	jg     f0103d3f <vprintfmt+0x145>
f0103d34:	8b 14 85 a0 5e 10 f0 	mov    -0xfefa160(,%eax,4),%edx
f0103d3b:	85 d2                	test   %edx,%edx
f0103d3d:	75 1b                	jne    f0103d5a <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0103d3f:	50                   	push   %eax
f0103d40:	68 ca 5c 10 f0       	push   $0xf0105cca
f0103d45:	53                   	push   %ebx
f0103d46:	56                   	push   %esi
f0103d47:	e8 91 fe ff ff       	call   f0103bdd <printfmt>
f0103d4c:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103d4f:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103d55:	e9 c6 fe ff ff       	jmp    f0103c20 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103d5a:	52                   	push   %edx
f0103d5b:	68 4b 4d 10 f0       	push   $0xf0104d4b
f0103d60:	53                   	push   %ebx
f0103d61:	56                   	push   %esi
f0103d62:	e8 76 fe ff ff       	call   f0103bdd <printfmt>
f0103d67:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103d6a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d6d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d70:	e9 ab fe ff ff       	jmp    f0103c20 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103d75:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d78:	83 c0 04             	add    $0x4,%eax
f0103d7b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103d7e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d81:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103d83:	85 ff                	test   %edi,%edi
f0103d85:	b8 c3 5c 10 f0       	mov    $0xf0105cc3,%eax
f0103d8a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103d8d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103d91:	0f 8e 94 00 00 00    	jle    f0103e2b <vprintfmt+0x231>
f0103d97:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103d9b:	0f 84 98 00 00 00    	je     f0103e39 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103da1:	83 ec 08             	sub    $0x8,%esp
f0103da4:	ff 75 d0             	pushl  -0x30(%ebp)
f0103da7:	57                   	push   %edi
f0103da8:	e8 0c 04 00 00       	call   f01041b9 <strnlen>
f0103dad:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103db0:	29 c1                	sub    %eax,%ecx
f0103db2:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103db5:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103db8:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103dbc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103dbf:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103dc2:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103dc4:	eb 0f                	jmp    f0103dd5 <vprintfmt+0x1db>
					putch(padc, putdat);
f0103dc6:	83 ec 08             	sub    $0x8,%esp
f0103dc9:	53                   	push   %ebx
f0103dca:	ff 75 e0             	pushl  -0x20(%ebp)
f0103dcd:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103dcf:	83 ef 01             	sub    $0x1,%edi
f0103dd2:	83 c4 10             	add    $0x10,%esp
f0103dd5:	85 ff                	test   %edi,%edi
f0103dd7:	7f ed                	jg     f0103dc6 <vprintfmt+0x1cc>
f0103dd9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103ddc:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103ddf:	85 c9                	test   %ecx,%ecx
f0103de1:	b8 00 00 00 00       	mov    $0x0,%eax
f0103de6:	0f 49 c1             	cmovns %ecx,%eax
f0103de9:	29 c1                	sub    %eax,%ecx
f0103deb:	89 75 08             	mov    %esi,0x8(%ebp)
f0103dee:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103df1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103df4:	89 cb                	mov    %ecx,%ebx
f0103df6:	eb 4d                	jmp    f0103e45 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103df8:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103dfc:	74 1b                	je     f0103e19 <vprintfmt+0x21f>
f0103dfe:	0f be c0             	movsbl %al,%eax
f0103e01:	83 e8 20             	sub    $0x20,%eax
f0103e04:	83 f8 5e             	cmp    $0x5e,%eax
f0103e07:	76 10                	jbe    f0103e19 <vprintfmt+0x21f>
					putch('?', putdat);
f0103e09:	83 ec 08             	sub    $0x8,%esp
f0103e0c:	ff 75 0c             	pushl  0xc(%ebp)
f0103e0f:	6a 3f                	push   $0x3f
f0103e11:	ff 55 08             	call   *0x8(%ebp)
f0103e14:	83 c4 10             	add    $0x10,%esp
f0103e17:	eb 0d                	jmp    f0103e26 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0103e19:	83 ec 08             	sub    $0x8,%esp
f0103e1c:	ff 75 0c             	pushl  0xc(%ebp)
f0103e1f:	52                   	push   %edx
f0103e20:	ff 55 08             	call   *0x8(%ebp)
f0103e23:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103e26:	83 eb 01             	sub    $0x1,%ebx
f0103e29:	eb 1a                	jmp    f0103e45 <vprintfmt+0x24b>
f0103e2b:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e2e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e31:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e34:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103e37:	eb 0c                	jmp    f0103e45 <vprintfmt+0x24b>
f0103e39:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e3c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e3f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e42:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103e45:	83 c7 01             	add    $0x1,%edi
f0103e48:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103e4c:	0f be d0             	movsbl %al,%edx
f0103e4f:	85 d2                	test   %edx,%edx
f0103e51:	74 23                	je     f0103e76 <vprintfmt+0x27c>
f0103e53:	85 f6                	test   %esi,%esi
f0103e55:	78 a1                	js     f0103df8 <vprintfmt+0x1fe>
f0103e57:	83 ee 01             	sub    $0x1,%esi
f0103e5a:	79 9c                	jns    f0103df8 <vprintfmt+0x1fe>
f0103e5c:	89 df                	mov    %ebx,%edi
f0103e5e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103e61:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103e64:	eb 18                	jmp    f0103e7e <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103e66:	83 ec 08             	sub    $0x8,%esp
f0103e69:	53                   	push   %ebx
f0103e6a:	6a 20                	push   $0x20
f0103e6c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103e6e:	83 ef 01             	sub    $0x1,%edi
f0103e71:	83 c4 10             	add    $0x10,%esp
f0103e74:	eb 08                	jmp    f0103e7e <vprintfmt+0x284>
f0103e76:	89 df                	mov    %ebx,%edi
f0103e78:	8b 75 08             	mov    0x8(%ebp),%esi
f0103e7b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103e7e:	85 ff                	test   %edi,%edi
f0103e80:	7f e4                	jg     f0103e66 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103e82:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103e85:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e88:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e8b:	e9 90 fd ff ff       	jmp    f0103c20 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103e90:	83 f9 01             	cmp    $0x1,%ecx
f0103e93:	7e 19                	jle    f0103eae <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0103e95:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e98:	8b 50 04             	mov    0x4(%eax),%edx
f0103e9b:	8b 00                	mov    (%eax),%eax
f0103e9d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ea0:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103ea3:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ea6:	8d 40 08             	lea    0x8(%eax),%eax
f0103ea9:	89 45 14             	mov    %eax,0x14(%ebp)
f0103eac:	eb 38                	jmp    f0103ee6 <vprintfmt+0x2ec>
	else if (lflag)
f0103eae:	85 c9                	test   %ecx,%ecx
f0103eb0:	74 1b                	je     f0103ecd <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0103eb2:	8b 45 14             	mov    0x14(%ebp),%eax
f0103eb5:	8b 00                	mov    (%eax),%eax
f0103eb7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103eba:	89 c1                	mov    %eax,%ecx
f0103ebc:	c1 f9 1f             	sar    $0x1f,%ecx
f0103ebf:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103ec2:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ec5:	8d 40 04             	lea    0x4(%eax),%eax
f0103ec8:	89 45 14             	mov    %eax,0x14(%ebp)
f0103ecb:	eb 19                	jmp    f0103ee6 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0103ecd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ed0:	8b 00                	mov    (%eax),%eax
f0103ed2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ed5:	89 c1                	mov    %eax,%ecx
f0103ed7:	c1 f9 1f             	sar    $0x1f,%ecx
f0103eda:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103edd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ee0:	8d 40 04             	lea    0x4(%eax),%eax
f0103ee3:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103ee6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103ee9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103eec:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103ef1:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103ef5:	0f 89 0e 01 00 00    	jns    f0104009 <vprintfmt+0x40f>
				putch('-', putdat);
f0103efb:	83 ec 08             	sub    $0x8,%esp
f0103efe:	53                   	push   %ebx
f0103eff:	6a 2d                	push   $0x2d
f0103f01:	ff d6                	call   *%esi
				num = -(long long) num;
f0103f03:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103f06:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103f09:	f7 da                	neg    %edx
f0103f0b:	83 d1 00             	adc    $0x0,%ecx
f0103f0e:	f7 d9                	neg    %ecx
f0103f10:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103f13:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103f18:	e9 ec 00 00 00       	jmp    f0104009 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103f1d:	83 f9 01             	cmp    $0x1,%ecx
f0103f20:	7e 18                	jle    f0103f3a <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0103f22:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f25:	8b 10                	mov    (%eax),%edx
f0103f27:	8b 48 04             	mov    0x4(%eax),%ecx
f0103f2a:	8d 40 08             	lea    0x8(%eax),%eax
f0103f2d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103f30:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103f35:	e9 cf 00 00 00       	jmp    f0104009 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103f3a:	85 c9                	test   %ecx,%ecx
f0103f3c:	74 1a                	je     f0103f58 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0103f3e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f41:	8b 10                	mov    (%eax),%edx
f0103f43:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103f48:	8d 40 04             	lea    0x4(%eax),%eax
f0103f4b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103f4e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103f53:	e9 b1 00 00 00       	jmp    f0104009 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103f58:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f5b:	8b 10                	mov    (%eax),%edx
f0103f5d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103f62:	8d 40 04             	lea    0x4(%eax),%eax
f0103f65:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103f68:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103f6d:	e9 97 00 00 00       	jmp    f0104009 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0103f72:	83 ec 08             	sub    $0x8,%esp
f0103f75:	53                   	push   %ebx
f0103f76:	6a 58                	push   $0x58
f0103f78:	ff d6                	call   *%esi
			putch('X', putdat);
f0103f7a:	83 c4 08             	add    $0x8,%esp
f0103f7d:	53                   	push   %ebx
f0103f7e:	6a 58                	push   $0x58
f0103f80:	ff d6                	call   *%esi
			putch('X', putdat);
f0103f82:	83 c4 08             	add    $0x8,%esp
f0103f85:	53                   	push   %ebx
f0103f86:	6a 58                	push   $0x58
f0103f88:	ff d6                	call   *%esi
			break;
f0103f8a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f8d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0103f90:	e9 8b fc ff ff       	jmp    f0103c20 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0103f95:	83 ec 08             	sub    $0x8,%esp
f0103f98:	53                   	push   %ebx
f0103f99:	6a 30                	push   $0x30
f0103f9b:	ff d6                	call   *%esi
			putch('x', putdat);
f0103f9d:	83 c4 08             	add    $0x8,%esp
f0103fa0:	53                   	push   %ebx
f0103fa1:	6a 78                	push   $0x78
f0103fa3:	ff d6                	call   *%esi
			num = (unsigned long long)
f0103fa5:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fa8:	8b 10                	mov    (%eax),%edx
f0103faa:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103faf:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103fb2:	8d 40 04             	lea    0x4(%eax),%eax
f0103fb5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103fb8:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103fbd:	eb 4a                	jmp    f0104009 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103fbf:	83 f9 01             	cmp    $0x1,%ecx
f0103fc2:	7e 15                	jle    f0103fd9 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0103fc4:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fc7:	8b 10                	mov    (%eax),%edx
f0103fc9:	8b 48 04             	mov    0x4(%eax),%ecx
f0103fcc:	8d 40 08             	lea    0x8(%eax),%eax
f0103fcf:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103fd2:	b8 10 00 00 00       	mov    $0x10,%eax
f0103fd7:	eb 30                	jmp    f0104009 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103fd9:	85 c9                	test   %ecx,%ecx
f0103fdb:	74 17                	je     f0103ff4 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0103fdd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fe0:	8b 10                	mov    (%eax),%edx
f0103fe2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103fe7:	8d 40 04             	lea    0x4(%eax),%eax
f0103fea:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103fed:	b8 10 00 00 00       	mov    $0x10,%eax
f0103ff2:	eb 15                	jmp    f0104009 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103ff4:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ff7:	8b 10                	mov    (%eax),%edx
f0103ff9:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103ffe:	8d 40 04             	lea    0x4(%eax),%eax
f0104001:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0104004:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104009:	83 ec 0c             	sub    $0xc,%esp
f010400c:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104010:	57                   	push   %edi
f0104011:	ff 75 e0             	pushl  -0x20(%ebp)
f0104014:	50                   	push   %eax
f0104015:	51                   	push   %ecx
f0104016:	52                   	push   %edx
f0104017:	89 da                	mov    %ebx,%edx
f0104019:	89 f0                	mov    %esi,%eax
f010401b:	e8 f1 fa ff ff       	call   f0103b11 <printnum>
			break;
f0104020:	83 c4 20             	add    $0x20,%esp
f0104023:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104026:	e9 f5 fb ff ff       	jmp    f0103c20 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010402b:	83 ec 08             	sub    $0x8,%esp
f010402e:	53                   	push   %ebx
f010402f:	52                   	push   %edx
f0104030:	ff d6                	call   *%esi
			break;
f0104032:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104035:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104038:	e9 e3 fb ff ff       	jmp    f0103c20 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010403d:	83 ec 08             	sub    $0x8,%esp
f0104040:	53                   	push   %ebx
f0104041:	6a 25                	push   $0x25
f0104043:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104045:	83 c4 10             	add    $0x10,%esp
f0104048:	eb 03                	jmp    f010404d <vprintfmt+0x453>
f010404a:	83 ef 01             	sub    $0x1,%edi
f010404d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104051:	75 f7                	jne    f010404a <vprintfmt+0x450>
f0104053:	e9 c8 fb ff ff       	jmp    f0103c20 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104058:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010405b:	5b                   	pop    %ebx
f010405c:	5e                   	pop    %esi
f010405d:	5f                   	pop    %edi
f010405e:	5d                   	pop    %ebp
f010405f:	c3                   	ret    

f0104060 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104060:	55                   	push   %ebp
f0104061:	89 e5                	mov    %esp,%ebp
f0104063:	83 ec 18             	sub    $0x18,%esp
f0104066:	8b 45 08             	mov    0x8(%ebp),%eax
f0104069:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010406c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010406f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104073:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104076:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010407d:	85 c0                	test   %eax,%eax
f010407f:	74 26                	je     f01040a7 <vsnprintf+0x47>
f0104081:	85 d2                	test   %edx,%edx
f0104083:	7e 22                	jle    f01040a7 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104085:	ff 75 14             	pushl  0x14(%ebp)
f0104088:	ff 75 10             	pushl  0x10(%ebp)
f010408b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010408e:	50                   	push   %eax
f010408f:	68 c0 3b 10 f0       	push   $0xf0103bc0
f0104094:	e8 61 fb ff ff       	call   f0103bfa <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104099:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010409c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010409f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01040a2:	83 c4 10             	add    $0x10,%esp
f01040a5:	eb 05                	jmp    f01040ac <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01040a7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01040ac:	c9                   	leave  
f01040ad:	c3                   	ret    

f01040ae <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01040ae:	55                   	push   %ebp
f01040af:	89 e5                	mov    %esp,%ebp
f01040b1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01040b4:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01040b7:	50                   	push   %eax
f01040b8:	ff 75 10             	pushl  0x10(%ebp)
f01040bb:	ff 75 0c             	pushl  0xc(%ebp)
f01040be:	ff 75 08             	pushl  0x8(%ebp)
f01040c1:	e8 9a ff ff ff       	call   f0104060 <vsnprintf>
	va_end(ap);

	return rc;
}
f01040c6:	c9                   	leave  
f01040c7:	c3                   	ret    

f01040c8 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01040c8:	55                   	push   %ebp
f01040c9:	89 e5                	mov    %esp,%ebp
f01040cb:	57                   	push   %edi
f01040cc:	56                   	push   %esi
f01040cd:	53                   	push   %ebx
f01040ce:	83 ec 0c             	sub    $0xc,%esp
f01040d1:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01040d4:	85 c0                	test   %eax,%eax
f01040d6:	74 11                	je     f01040e9 <readline+0x21>
		cprintf("%s", prompt);
f01040d8:	83 ec 08             	sub    $0x8,%esp
f01040db:	50                   	push   %eax
f01040dc:	68 4b 4d 10 f0       	push   $0xf0104d4b
f01040e1:	e8 ee ee ff ff       	call   f0102fd4 <cprintf>
f01040e6:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01040e9:	83 ec 0c             	sub    $0xc,%esp
f01040ec:	6a 00                	push   $0x0
f01040ee:	e8 35 c5 ff ff       	call   f0100628 <iscons>
f01040f3:	89 c7                	mov    %eax,%edi
f01040f5:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01040f8:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01040fd:	e8 15 c5 ff ff       	call   f0100617 <getchar>
f0104102:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104104:	85 c0                	test   %eax,%eax
f0104106:	79 18                	jns    f0104120 <readline+0x58>
			cprintf("read error: %e\n", c);
f0104108:	83 ec 08             	sub    $0x8,%esp
f010410b:	50                   	push   %eax
f010410c:	68 c0 5e 10 f0       	push   $0xf0105ec0
f0104111:	e8 be ee ff ff       	call   f0102fd4 <cprintf>
			return NULL;
f0104116:	83 c4 10             	add    $0x10,%esp
f0104119:	b8 00 00 00 00       	mov    $0x0,%eax
f010411e:	eb 79                	jmp    f0104199 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104120:	83 f8 08             	cmp    $0x8,%eax
f0104123:	0f 94 c2             	sete   %dl
f0104126:	83 f8 7f             	cmp    $0x7f,%eax
f0104129:	0f 94 c0             	sete   %al
f010412c:	08 c2                	or     %al,%dl
f010412e:	74 1a                	je     f010414a <readline+0x82>
f0104130:	85 f6                	test   %esi,%esi
f0104132:	7e 16                	jle    f010414a <readline+0x82>
			if (echoing)
f0104134:	85 ff                	test   %edi,%edi
f0104136:	74 0d                	je     f0104145 <readline+0x7d>
				cputchar('\b');
f0104138:	83 ec 0c             	sub    $0xc,%esp
f010413b:	6a 08                	push   $0x8
f010413d:	e8 c5 c4 ff ff       	call   f0100607 <cputchar>
f0104142:	83 c4 10             	add    $0x10,%esp
			i--;
f0104145:	83 ee 01             	sub    $0x1,%esi
f0104148:	eb b3                	jmp    f01040fd <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010414a:	83 fb 1f             	cmp    $0x1f,%ebx
f010414d:	7e 23                	jle    f0104172 <readline+0xaa>
f010414f:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104155:	7f 1b                	jg     f0104172 <readline+0xaa>
			if (echoing)
f0104157:	85 ff                	test   %edi,%edi
f0104159:	74 0c                	je     f0104167 <readline+0x9f>
				cputchar(c);
f010415b:	83 ec 0c             	sub    $0xc,%esp
f010415e:	53                   	push   %ebx
f010415f:	e8 a3 c4 ff ff       	call   f0100607 <cputchar>
f0104164:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104167:	88 9e 00 d7 17 f0    	mov    %bl,-0xfe82900(%esi)
f010416d:	8d 76 01             	lea    0x1(%esi),%esi
f0104170:	eb 8b                	jmp    f01040fd <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104172:	83 fb 0a             	cmp    $0xa,%ebx
f0104175:	74 05                	je     f010417c <readline+0xb4>
f0104177:	83 fb 0d             	cmp    $0xd,%ebx
f010417a:	75 81                	jne    f01040fd <readline+0x35>
			if (echoing)
f010417c:	85 ff                	test   %edi,%edi
f010417e:	74 0d                	je     f010418d <readline+0xc5>
				cputchar('\n');
f0104180:	83 ec 0c             	sub    $0xc,%esp
f0104183:	6a 0a                	push   $0xa
f0104185:	e8 7d c4 ff ff       	call   f0100607 <cputchar>
f010418a:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010418d:	c6 86 00 d7 17 f0 00 	movb   $0x0,-0xfe82900(%esi)
			return buf;
f0104194:	b8 00 d7 17 f0       	mov    $0xf017d700,%eax
		}
	}
}
f0104199:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010419c:	5b                   	pop    %ebx
f010419d:	5e                   	pop    %esi
f010419e:	5f                   	pop    %edi
f010419f:	5d                   	pop    %ebp
f01041a0:	c3                   	ret    

f01041a1 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01041a1:	55                   	push   %ebp
f01041a2:	89 e5                	mov    %esp,%ebp
f01041a4:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01041a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01041ac:	eb 03                	jmp    f01041b1 <strlen+0x10>
		n++;
f01041ae:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01041b1:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01041b5:	75 f7                	jne    f01041ae <strlen+0xd>
		n++;
	return n;
}
f01041b7:	5d                   	pop    %ebp
f01041b8:	c3                   	ret    

f01041b9 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01041b9:	55                   	push   %ebp
f01041ba:	89 e5                	mov    %esp,%ebp
f01041bc:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01041bf:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01041c2:	ba 00 00 00 00       	mov    $0x0,%edx
f01041c7:	eb 03                	jmp    f01041cc <strnlen+0x13>
		n++;
f01041c9:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01041cc:	39 c2                	cmp    %eax,%edx
f01041ce:	74 08                	je     f01041d8 <strnlen+0x1f>
f01041d0:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01041d4:	75 f3                	jne    f01041c9 <strnlen+0x10>
f01041d6:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01041d8:	5d                   	pop    %ebp
f01041d9:	c3                   	ret    

f01041da <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01041da:	55                   	push   %ebp
f01041db:	89 e5                	mov    %esp,%ebp
f01041dd:	53                   	push   %ebx
f01041de:	8b 45 08             	mov    0x8(%ebp),%eax
f01041e1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01041e4:	89 c2                	mov    %eax,%edx
f01041e6:	83 c2 01             	add    $0x1,%edx
f01041e9:	83 c1 01             	add    $0x1,%ecx
f01041ec:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01041f0:	88 5a ff             	mov    %bl,-0x1(%edx)
f01041f3:	84 db                	test   %bl,%bl
f01041f5:	75 ef                	jne    f01041e6 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01041f7:	5b                   	pop    %ebx
f01041f8:	5d                   	pop    %ebp
f01041f9:	c3                   	ret    

f01041fa <strcat>:

char *
strcat(char *dst, const char *src)
{
f01041fa:	55                   	push   %ebp
f01041fb:	89 e5                	mov    %esp,%ebp
f01041fd:	53                   	push   %ebx
f01041fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104201:	53                   	push   %ebx
f0104202:	e8 9a ff ff ff       	call   f01041a1 <strlen>
f0104207:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010420a:	ff 75 0c             	pushl  0xc(%ebp)
f010420d:	01 d8                	add    %ebx,%eax
f010420f:	50                   	push   %eax
f0104210:	e8 c5 ff ff ff       	call   f01041da <strcpy>
	return dst;
}
f0104215:	89 d8                	mov    %ebx,%eax
f0104217:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010421a:	c9                   	leave  
f010421b:	c3                   	ret    

f010421c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010421c:	55                   	push   %ebp
f010421d:	89 e5                	mov    %esp,%ebp
f010421f:	56                   	push   %esi
f0104220:	53                   	push   %ebx
f0104221:	8b 75 08             	mov    0x8(%ebp),%esi
f0104224:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104227:	89 f3                	mov    %esi,%ebx
f0104229:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010422c:	89 f2                	mov    %esi,%edx
f010422e:	eb 0f                	jmp    f010423f <strncpy+0x23>
		*dst++ = *src;
f0104230:	83 c2 01             	add    $0x1,%edx
f0104233:	0f b6 01             	movzbl (%ecx),%eax
f0104236:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104239:	80 39 01             	cmpb   $0x1,(%ecx)
f010423c:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010423f:	39 da                	cmp    %ebx,%edx
f0104241:	75 ed                	jne    f0104230 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104243:	89 f0                	mov    %esi,%eax
f0104245:	5b                   	pop    %ebx
f0104246:	5e                   	pop    %esi
f0104247:	5d                   	pop    %ebp
f0104248:	c3                   	ret    

f0104249 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104249:	55                   	push   %ebp
f010424a:	89 e5                	mov    %esp,%ebp
f010424c:	56                   	push   %esi
f010424d:	53                   	push   %ebx
f010424e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104251:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104254:	8b 55 10             	mov    0x10(%ebp),%edx
f0104257:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104259:	85 d2                	test   %edx,%edx
f010425b:	74 21                	je     f010427e <strlcpy+0x35>
f010425d:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104261:	89 f2                	mov    %esi,%edx
f0104263:	eb 09                	jmp    f010426e <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104265:	83 c2 01             	add    $0x1,%edx
f0104268:	83 c1 01             	add    $0x1,%ecx
f010426b:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010426e:	39 c2                	cmp    %eax,%edx
f0104270:	74 09                	je     f010427b <strlcpy+0x32>
f0104272:	0f b6 19             	movzbl (%ecx),%ebx
f0104275:	84 db                	test   %bl,%bl
f0104277:	75 ec                	jne    f0104265 <strlcpy+0x1c>
f0104279:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010427b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010427e:	29 f0                	sub    %esi,%eax
}
f0104280:	5b                   	pop    %ebx
f0104281:	5e                   	pop    %esi
f0104282:	5d                   	pop    %ebp
f0104283:	c3                   	ret    

f0104284 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104284:	55                   	push   %ebp
f0104285:	89 e5                	mov    %esp,%ebp
f0104287:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010428a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010428d:	eb 06                	jmp    f0104295 <strcmp+0x11>
		p++, q++;
f010428f:	83 c1 01             	add    $0x1,%ecx
f0104292:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104295:	0f b6 01             	movzbl (%ecx),%eax
f0104298:	84 c0                	test   %al,%al
f010429a:	74 04                	je     f01042a0 <strcmp+0x1c>
f010429c:	3a 02                	cmp    (%edx),%al
f010429e:	74 ef                	je     f010428f <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01042a0:	0f b6 c0             	movzbl %al,%eax
f01042a3:	0f b6 12             	movzbl (%edx),%edx
f01042a6:	29 d0                	sub    %edx,%eax
}
f01042a8:	5d                   	pop    %ebp
f01042a9:	c3                   	ret    

f01042aa <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01042aa:	55                   	push   %ebp
f01042ab:	89 e5                	mov    %esp,%ebp
f01042ad:	53                   	push   %ebx
f01042ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01042b1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01042b4:	89 c3                	mov    %eax,%ebx
f01042b6:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01042b9:	eb 06                	jmp    f01042c1 <strncmp+0x17>
		n--, p++, q++;
f01042bb:	83 c0 01             	add    $0x1,%eax
f01042be:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01042c1:	39 d8                	cmp    %ebx,%eax
f01042c3:	74 15                	je     f01042da <strncmp+0x30>
f01042c5:	0f b6 08             	movzbl (%eax),%ecx
f01042c8:	84 c9                	test   %cl,%cl
f01042ca:	74 04                	je     f01042d0 <strncmp+0x26>
f01042cc:	3a 0a                	cmp    (%edx),%cl
f01042ce:	74 eb                	je     f01042bb <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01042d0:	0f b6 00             	movzbl (%eax),%eax
f01042d3:	0f b6 12             	movzbl (%edx),%edx
f01042d6:	29 d0                	sub    %edx,%eax
f01042d8:	eb 05                	jmp    f01042df <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01042da:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01042df:	5b                   	pop    %ebx
f01042e0:	5d                   	pop    %ebp
f01042e1:	c3                   	ret    

f01042e2 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01042e2:	55                   	push   %ebp
f01042e3:	89 e5                	mov    %esp,%ebp
f01042e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01042e8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01042ec:	eb 07                	jmp    f01042f5 <strchr+0x13>
		if (*s == c)
f01042ee:	38 ca                	cmp    %cl,%dl
f01042f0:	74 0f                	je     f0104301 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01042f2:	83 c0 01             	add    $0x1,%eax
f01042f5:	0f b6 10             	movzbl (%eax),%edx
f01042f8:	84 d2                	test   %dl,%dl
f01042fa:	75 f2                	jne    f01042ee <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01042fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104301:	5d                   	pop    %ebp
f0104302:	c3                   	ret    

f0104303 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104303:	55                   	push   %ebp
f0104304:	89 e5                	mov    %esp,%ebp
f0104306:	8b 45 08             	mov    0x8(%ebp),%eax
f0104309:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010430d:	eb 03                	jmp    f0104312 <strfind+0xf>
f010430f:	83 c0 01             	add    $0x1,%eax
f0104312:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104315:	38 ca                	cmp    %cl,%dl
f0104317:	74 04                	je     f010431d <strfind+0x1a>
f0104319:	84 d2                	test   %dl,%dl
f010431b:	75 f2                	jne    f010430f <strfind+0xc>
			break;
	return (char *) s;
}
f010431d:	5d                   	pop    %ebp
f010431e:	c3                   	ret    

f010431f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010431f:	55                   	push   %ebp
f0104320:	89 e5                	mov    %esp,%ebp
f0104322:	57                   	push   %edi
f0104323:	56                   	push   %esi
f0104324:	53                   	push   %ebx
f0104325:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104328:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010432b:	85 c9                	test   %ecx,%ecx
f010432d:	74 36                	je     f0104365 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010432f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104335:	75 28                	jne    f010435f <memset+0x40>
f0104337:	f6 c1 03             	test   $0x3,%cl
f010433a:	75 23                	jne    f010435f <memset+0x40>
		c &= 0xFF;
f010433c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104340:	89 d3                	mov    %edx,%ebx
f0104342:	c1 e3 08             	shl    $0x8,%ebx
f0104345:	89 d6                	mov    %edx,%esi
f0104347:	c1 e6 18             	shl    $0x18,%esi
f010434a:	89 d0                	mov    %edx,%eax
f010434c:	c1 e0 10             	shl    $0x10,%eax
f010434f:	09 f0                	or     %esi,%eax
f0104351:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104353:	89 d8                	mov    %ebx,%eax
f0104355:	09 d0                	or     %edx,%eax
f0104357:	c1 e9 02             	shr    $0x2,%ecx
f010435a:	fc                   	cld    
f010435b:	f3 ab                	rep stos %eax,%es:(%edi)
f010435d:	eb 06                	jmp    f0104365 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010435f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104362:	fc                   	cld    
f0104363:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104365:	89 f8                	mov    %edi,%eax
f0104367:	5b                   	pop    %ebx
f0104368:	5e                   	pop    %esi
f0104369:	5f                   	pop    %edi
f010436a:	5d                   	pop    %ebp
f010436b:	c3                   	ret    

f010436c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010436c:	55                   	push   %ebp
f010436d:	89 e5                	mov    %esp,%ebp
f010436f:	57                   	push   %edi
f0104370:	56                   	push   %esi
f0104371:	8b 45 08             	mov    0x8(%ebp),%eax
f0104374:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104377:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010437a:	39 c6                	cmp    %eax,%esi
f010437c:	73 35                	jae    f01043b3 <memmove+0x47>
f010437e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104381:	39 d0                	cmp    %edx,%eax
f0104383:	73 2e                	jae    f01043b3 <memmove+0x47>
		s += n;
		d += n;
f0104385:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104388:	89 d6                	mov    %edx,%esi
f010438a:	09 fe                	or     %edi,%esi
f010438c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104392:	75 13                	jne    f01043a7 <memmove+0x3b>
f0104394:	f6 c1 03             	test   $0x3,%cl
f0104397:	75 0e                	jne    f01043a7 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104399:	83 ef 04             	sub    $0x4,%edi
f010439c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010439f:	c1 e9 02             	shr    $0x2,%ecx
f01043a2:	fd                   	std    
f01043a3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01043a5:	eb 09                	jmp    f01043b0 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01043a7:	83 ef 01             	sub    $0x1,%edi
f01043aa:	8d 72 ff             	lea    -0x1(%edx),%esi
f01043ad:	fd                   	std    
f01043ae:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01043b0:	fc                   	cld    
f01043b1:	eb 1d                	jmp    f01043d0 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01043b3:	89 f2                	mov    %esi,%edx
f01043b5:	09 c2                	or     %eax,%edx
f01043b7:	f6 c2 03             	test   $0x3,%dl
f01043ba:	75 0f                	jne    f01043cb <memmove+0x5f>
f01043bc:	f6 c1 03             	test   $0x3,%cl
f01043bf:	75 0a                	jne    f01043cb <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01043c1:	c1 e9 02             	shr    $0x2,%ecx
f01043c4:	89 c7                	mov    %eax,%edi
f01043c6:	fc                   	cld    
f01043c7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01043c9:	eb 05                	jmp    f01043d0 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01043cb:	89 c7                	mov    %eax,%edi
f01043cd:	fc                   	cld    
f01043ce:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01043d0:	5e                   	pop    %esi
f01043d1:	5f                   	pop    %edi
f01043d2:	5d                   	pop    %ebp
f01043d3:	c3                   	ret    

f01043d4 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01043d4:	55                   	push   %ebp
f01043d5:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01043d7:	ff 75 10             	pushl  0x10(%ebp)
f01043da:	ff 75 0c             	pushl  0xc(%ebp)
f01043dd:	ff 75 08             	pushl  0x8(%ebp)
f01043e0:	e8 87 ff ff ff       	call   f010436c <memmove>
}
f01043e5:	c9                   	leave  
f01043e6:	c3                   	ret    

f01043e7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01043e7:	55                   	push   %ebp
f01043e8:	89 e5                	mov    %esp,%ebp
f01043ea:	56                   	push   %esi
f01043eb:	53                   	push   %ebx
f01043ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01043ef:	8b 55 0c             	mov    0xc(%ebp),%edx
f01043f2:	89 c6                	mov    %eax,%esi
f01043f4:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01043f7:	eb 1a                	jmp    f0104413 <memcmp+0x2c>
		if (*s1 != *s2)
f01043f9:	0f b6 08             	movzbl (%eax),%ecx
f01043fc:	0f b6 1a             	movzbl (%edx),%ebx
f01043ff:	38 d9                	cmp    %bl,%cl
f0104401:	74 0a                	je     f010440d <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104403:	0f b6 c1             	movzbl %cl,%eax
f0104406:	0f b6 db             	movzbl %bl,%ebx
f0104409:	29 d8                	sub    %ebx,%eax
f010440b:	eb 0f                	jmp    f010441c <memcmp+0x35>
		s1++, s2++;
f010440d:	83 c0 01             	add    $0x1,%eax
f0104410:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104413:	39 f0                	cmp    %esi,%eax
f0104415:	75 e2                	jne    f01043f9 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104417:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010441c:	5b                   	pop    %ebx
f010441d:	5e                   	pop    %esi
f010441e:	5d                   	pop    %ebp
f010441f:	c3                   	ret    

f0104420 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104420:	55                   	push   %ebp
f0104421:	89 e5                	mov    %esp,%ebp
f0104423:	53                   	push   %ebx
f0104424:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104427:	89 c1                	mov    %eax,%ecx
f0104429:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010442c:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104430:	eb 0a                	jmp    f010443c <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104432:	0f b6 10             	movzbl (%eax),%edx
f0104435:	39 da                	cmp    %ebx,%edx
f0104437:	74 07                	je     f0104440 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104439:	83 c0 01             	add    $0x1,%eax
f010443c:	39 c8                	cmp    %ecx,%eax
f010443e:	72 f2                	jb     f0104432 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104440:	5b                   	pop    %ebx
f0104441:	5d                   	pop    %ebp
f0104442:	c3                   	ret    

f0104443 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104443:	55                   	push   %ebp
f0104444:	89 e5                	mov    %esp,%ebp
f0104446:	57                   	push   %edi
f0104447:	56                   	push   %esi
f0104448:	53                   	push   %ebx
f0104449:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010444c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010444f:	eb 03                	jmp    f0104454 <strtol+0x11>
		s++;
f0104451:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104454:	0f b6 01             	movzbl (%ecx),%eax
f0104457:	3c 20                	cmp    $0x20,%al
f0104459:	74 f6                	je     f0104451 <strtol+0xe>
f010445b:	3c 09                	cmp    $0x9,%al
f010445d:	74 f2                	je     f0104451 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010445f:	3c 2b                	cmp    $0x2b,%al
f0104461:	75 0a                	jne    f010446d <strtol+0x2a>
		s++;
f0104463:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104466:	bf 00 00 00 00       	mov    $0x0,%edi
f010446b:	eb 11                	jmp    f010447e <strtol+0x3b>
f010446d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104472:	3c 2d                	cmp    $0x2d,%al
f0104474:	75 08                	jne    f010447e <strtol+0x3b>
		s++, neg = 1;
f0104476:	83 c1 01             	add    $0x1,%ecx
f0104479:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010447e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104484:	75 15                	jne    f010449b <strtol+0x58>
f0104486:	80 39 30             	cmpb   $0x30,(%ecx)
f0104489:	75 10                	jne    f010449b <strtol+0x58>
f010448b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010448f:	75 7c                	jne    f010450d <strtol+0xca>
		s += 2, base = 16;
f0104491:	83 c1 02             	add    $0x2,%ecx
f0104494:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104499:	eb 16                	jmp    f01044b1 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010449b:	85 db                	test   %ebx,%ebx
f010449d:	75 12                	jne    f01044b1 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010449f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01044a4:	80 39 30             	cmpb   $0x30,(%ecx)
f01044a7:	75 08                	jne    f01044b1 <strtol+0x6e>
		s++, base = 8;
f01044a9:	83 c1 01             	add    $0x1,%ecx
f01044ac:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01044b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01044b6:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01044b9:	0f b6 11             	movzbl (%ecx),%edx
f01044bc:	8d 72 d0             	lea    -0x30(%edx),%esi
f01044bf:	89 f3                	mov    %esi,%ebx
f01044c1:	80 fb 09             	cmp    $0x9,%bl
f01044c4:	77 08                	ja     f01044ce <strtol+0x8b>
			dig = *s - '0';
f01044c6:	0f be d2             	movsbl %dl,%edx
f01044c9:	83 ea 30             	sub    $0x30,%edx
f01044cc:	eb 22                	jmp    f01044f0 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01044ce:	8d 72 9f             	lea    -0x61(%edx),%esi
f01044d1:	89 f3                	mov    %esi,%ebx
f01044d3:	80 fb 19             	cmp    $0x19,%bl
f01044d6:	77 08                	ja     f01044e0 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01044d8:	0f be d2             	movsbl %dl,%edx
f01044db:	83 ea 57             	sub    $0x57,%edx
f01044de:	eb 10                	jmp    f01044f0 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01044e0:	8d 72 bf             	lea    -0x41(%edx),%esi
f01044e3:	89 f3                	mov    %esi,%ebx
f01044e5:	80 fb 19             	cmp    $0x19,%bl
f01044e8:	77 16                	ja     f0104500 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01044ea:	0f be d2             	movsbl %dl,%edx
f01044ed:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01044f0:	3b 55 10             	cmp    0x10(%ebp),%edx
f01044f3:	7d 0b                	jge    f0104500 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01044f5:	83 c1 01             	add    $0x1,%ecx
f01044f8:	0f af 45 10          	imul   0x10(%ebp),%eax
f01044fc:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01044fe:	eb b9                	jmp    f01044b9 <strtol+0x76>

	if (endptr)
f0104500:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104504:	74 0d                	je     f0104513 <strtol+0xd0>
		*endptr = (char *) s;
f0104506:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104509:	89 0e                	mov    %ecx,(%esi)
f010450b:	eb 06                	jmp    f0104513 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010450d:	85 db                	test   %ebx,%ebx
f010450f:	74 98                	je     f01044a9 <strtol+0x66>
f0104511:	eb 9e                	jmp    f01044b1 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104513:	89 c2                	mov    %eax,%edx
f0104515:	f7 da                	neg    %edx
f0104517:	85 ff                	test   %edi,%edi
f0104519:	0f 45 c2             	cmovne %edx,%eax
}
f010451c:	5b                   	pop    %ebx
f010451d:	5e                   	pop    %esi
f010451e:	5f                   	pop    %edi
f010451f:	5d                   	pop    %ebp
f0104520:	c3                   	ret    
f0104521:	66 90                	xchg   %ax,%ax
f0104523:	66 90                	xchg   %ax,%ax
f0104525:	66 90                	xchg   %ax,%ax
f0104527:	66 90                	xchg   %ax,%ax
f0104529:	66 90                	xchg   %ax,%ax
f010452b:	66 90                	xchg   %ax,%ax
f010452d:	66 90                	xchg   %ax,%ax
f010452f:	90                   	nop

f0104530 <__udivdi3>:
f0104530:	55                   	push   %ebp
f0104531:	57                   	push   %edi
f0104532:	56                   	push   %esi
f0104533:	53                   	push   %ebx
f0104534:	83 ec 1c             	sub    $0x1c,%esp
f0104537:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010453b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010453f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104543:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104547:	85 f6                	test   %esi,%esi
f0104549:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010454d:	89 ca                	mov    %ecx,%edx
f010454f:	89 f8                	mov    %edi,%eax
f0104551:	75 3d                	jne    f0104590 <__udivdi3+0x60>
f0104553:	39 cf                	cmp    %ecx,%edi
f0104555:	0f 87 c5 00 00 00    	ja     f0104620 <__udivdi3+0xf0>
f010455b:	85 ff                	test   %edi,%edi
f010455d:	89 fd                	mov    %edi,%ebp
f010455f:	75 0b                	jne    f010456c <__udivdi3+0x3c>
f0104561:	b8 01 00 00 00       	mov    $0x1,%eax
f0104566:	31 d2                	xor    %edx,%edx
f0104568:	f7 f7                	div    %edi
f010456a:	89 c5                	mov    %eax,%ebp
f010456c:	89 c8                	mov    %ecx,%eax
f010456e:	31 d2                	xor    %edx,%edx
f0104570:	f7 f5                	div    %ebp
f0104572:	89 c1                	mov    %eax,%ecx
f0104574:	89 d8                	mov    %ebx,%eax
f0104576:	89 cf                	mov    %ecx,%edi
f0104578:	f7 f5                	div    %ebp
f010457a:	89 c3                	mov    %eax,%ebx
f010457c:	89 d8                	mov    %ebx,%eax
f010457e:	89 fa                	mov    %edi,%edx
f0104580:	83 c4 1c             	add    $0x1c,%esp
f0104583:	5b                   	pop    %ebx
f0104584:	5e                   	pop    %esi
f0104585:	5f                   	pop    %edi
f0104586:	5d                   	pop    %ebp
f0104587:	c3                   	ret    
f0104588:	90                   	nop
f0104589:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104590:	39 ce                	cmp    %ecx,%esi
f0104592:	77 74                	ja     f0104608 <__udivdi3+0xd8>
f0104594:	0f bd fe             	bsr    %esi,%edi
f0104597:	83 f7 1f             	xor    $0x1f,%edi
f010459a:	0f 84 98 00 00 00    	je     f0104638 <__udivdi3+0x108>
f01045a0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01045a5:	89 f9                	mov    %edi,%ecx
f01045a7:	89 c5                	mov    %eax,%ebp
f01045a9:	29 fb                	sub    %edi,%ebx
f01045ab:	d3 e6                	shl    %cl,%esi
f01045ad:	89 d9                	mov    %ebx,%ecx
f01045af:	d3 ed                	shr    %cl,%ebp
f01045b1:	89 f9                	mov    %edi,%ecx
f01045b3:	d3 e0                	shl    %cl,%eax
f01045b5:	09 ee                	or     %ebp,%esi
f01045b7:	89 d9                	mov    %ebx,%ecx
f01045b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01045bd:	89 d5                	mov    %edx,%ebp
f01045bf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01045c3:	d3 ed                	shr    %cl,%ebp
f01045c5:	89 f9                	mov    %edi,%ecx
f01045c7:	d3 e2                	shl    %cl,%edx
f01045c9:	89 d9                	mov    %ebx,%ecx
f01045cb:	d3 e8                	shr    %cl,%eax
f01045cd:	09 c2                	or     %eax,%edx
f01045cf:	89 d0                	mov    %edx,%eax
f01045d1:	89 ea                	mov    %ebp,%edx
f01045d3:	f7 f6                	div    %esi
f01045d5:	89 d5                	mov    %edx,%ebp
f01045d7:	89 c3                	mov    %eax,%ebx
f01045d9:	f7 64 24 0c          	mull   0xc(%esp)
f01045dd:	39 d5                	cmp    %edx,%ebp
f01045df:	72 10                	jb     f01045f1 <__udivdi3+0xc1>
f01045e1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01045e5:	89 f9                	mov    %edi,%ecx
f01045e7:	d3 e6                	shl    %cl,%esi
f01045e9:	39 c6                	cmp    %eax,%esi
f01045eb:	73 07                	jae    f01045f4 <__udivdi3+0xc4>
f01045ed:	39 d5                	cmp    %edx,%ebp
f01045ef:	75 03                	jne    f01045f4 <__udivdi3+0xc4>
f01045f1:	83 eb 01             	sub    $0x1,%ebx
f01045f4:	31 ff                	xor    %edi,%edi
f01045f6:	89 d8                	mov    %ebx,%eax
f01045f8:	89 fa                	mov    %edi,%edx
f01045fa:	83 c4 1c             	add    $0x1c,%esp
f01045fd:	5b                   	pop    %ebx
f01045fe:	5e                   	pop    %esi
f01045ff:	5f                   	pop    %edi
f0104600:	5d                   	pop    %ebp
f0104601:	c3                   	ret    
f0104602:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104608:	31 ff                	xor    %edi,%edi
f010460a:	31 db                	xor    %ebx,%ebx
f010460c:	89 d8                	mov    %ebx,%eax
f010460e:	89 fa                	mov    %edi,%edx
f0104610:	83 c4 1c             	add    $0x1c,%esp
f0104613:	5b                   	pop    %ebx
f0104614:	5e                   	pop    %esi
f0104615:	5f                   	pop    %edi
f0104616:	5d                   	pop    %ebp
f0104617:	c3                   	ret    
f0104618:	90                   	nop
f0104619:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104620:	89 d8                	mov    %ebx,%eax
f0104622:	f7 f7                	div    %edi
f0104624:	31 ff                	xor    %edi,%edi
f0104626:	89 c3                	mov    %eax,%ebx
f0104628:	89 d8                	mov    %ebx,%eax
f010462a:	89 fa                	mov    %edi,%edx
f010462c:	83 c4 1c             	add    $0x1c,%esp
f010462f:	5b                   	pop    %ebx
f0104630:	5e                   	pop    %esi
f0104631:	5f                   	pop    %edi
f0104632:	5d                   	pop    %ebp
f0104633:	c3                   	ret    
f0104634:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104638:	39 ce                	cmp    %ecx,%esi
f010463a:	72 0c                	jb     f0104648 <__udivdi3+0x118>
f010463c:	31 db                	xor    %ebx,%ebx
f010463e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104642:	0f 87 34 ff ff ff    	ja     f010457c <__udivdi3+0x4c>
f0104648:	bb 01 00 00 00       	mov    $0x1,%ebx
f010464d:	e9 2a ff ff ff       	jmp    f010457c <__udivdi3+0x4c>
f0104652:	66 90                	xchg   %ax,%ax
f0104654:	66 90                	xchg   %ax,%ax
f0104656:	66 90                	xchg   %ax,%ax
f0104658:	66 90                	xchg   %ax,%ax
f010465a:	66 90                	xchg   %ax,%ax
f010465c:	66 90                	xchg   %ax,%ax
f010465e:	66 90                	xchg   %ax,%ax

f0104660 <__umoddi3>:
f0104660:	55                   	push   %ebp
f0104661:	57                   	push   %edi
f0104662:	56                   	push   %esi
f0104663:	53                   	push   %ebx
f0104664:	83 ec 1c             	sub    $0x1c,%esp
f0104667:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010466b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010466f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104673:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104677:	85 d2                	test   %edx,%edx
f0104679:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010467d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104681:	89 f3                	mov    %esi,%ebx
f0104683:	89 3c 24             	mov    %edi,(%esp)
f0104686:	89 74 24 04          	mov    %esi,0x4(%esp)
f010468a:	75 1c                	jne    f01046a8 <__umoddi3+0x48>
f010468c:	39 f7                	cmp    %esi,%edi
f010468e:	76 50                	jbe    f01046e0 <__umoddi3+0x80>
f0104690:	89 c8                	mov    %ecx,%eax
f0104692:	89 f2                	mov    %esi,%edx
f0104694:	f7 f7                	div    %edi
f0104696:	89 d0                	mov    %edx,%eax
f0104698:	31 d2                	xor    %edx,%edx
f010469a:	83 c4 1c             	add    $0x1c,%esp
f010469d:	5b                   	pop    %ebx
f010469e:	5e                   	pop    %esi
f010469f:	5f                   	pop    %edi
f01046a0:	5d                   	pop    %ebp
f01046a1:	c3                   	ret    
f01046a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01046a8:	39 f2                	cmp    %esi,%edx
f01046aa:	89 d0                	mov    %edx,%eax
f01046ac:	77 52                	ja     f0104700 <__umoddi3+0xa0>
f01046ae:	0f bd ea             	bsr    %edx,%ebp
f01046b1:	83 f5 1f             	xor    $0x1f,%ebp
f01046b4:	75 5a                	jne    f0104710 <__umoddi3+0xb0>
f01046b6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01046ba:	0f 82 e0 00 00 00    	jb     f01047a0 <__umoddi3+0x140>
f01046c0:	39 0c 24             	cmp    %ecx,(%esp)
f01046c3:	0f 86 d7 00 00 00    	jbe    f01047a0 <__umoddi3+0x140>
f01046c9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01046cd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01046d1:	83 c4 1c             	add    $0x1c,%esp
f01046d4:	5b                   	pop    %ebx
f01046d5:	5e                   	pop    %esi
f01046d6:	5f                   	pop    %edi
f01046d7:	5d                   	pop    %ebp
f01046d8:	c3                   	ret    
f01046d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01046e0:	85 ff                	test   %edi,%edi
f01046e2:	89 fd                	mov    %edi,%ebp
f01046e4:	75 0b                	jne    f01046f1 <__umoddi3+0x91>
f01046e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01046eb:	31 d2                	xor    %edx,%edx
f01046ed:	f7 f7                	div    %edi
f01046ef:	89 c5                	mov    %eax,%ebp
f01046f1:	89 f0                	mov    %esi,%eax
f01046f3:	31 d2                	xor    %edx,%edx
f01046f5:	f7 f5                	div    %ebp
f01046f7:	89 c8                	mov    %ecx,%eax
f01046f9:	f7 f5                	div    %ebp
f01046fb:	89 d0                	mov    %edx,%eax
f01046fd:	eb 99                	jmp    f0104698 <__umoddi3+0x38>
f01046ff:	90                   	nop
f0104700:	89 c8                	mov    %ecx,%eax
f0104702:	89 f2                	mov    %esi,%edx
f0104704:	83 c4 1c             	add    $0x1c,%esp
f0104707:	5b                   	pop    %ebx
f0104708:	5e                   	pop    %esi
f0104709:	5f                   	pop    %edi
f010470a:	5d                   	pop    %ebp
f010470b:	c3                   	ret    
f010470c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104710:	8b 34 24             	mov    (%esp),%esi
f0104713:	bf 20 00 00 00       	mov    $0x20,%edi
f0104718:	89 e9                	mov    %ebp,%ecx
f010471a:	29 ef                	sub    %ebp,%edi
f010471c:	d3 e0                	shl    %cl,%eax
f010471e:	89 f9                	mov    %edi,%ecx
f0104720:	89 f2                	mov    %esi,%edx
f0104722:	d3 ea                	shr    %cl,%edx
f0104724:	89 e9                	mov    %ebp,%ecx
f0104726:	09 c2                	or     %eax,%edx
f0104728:	89 d8                	mov    %ebx,%eax
f010472a:	89 14 24             	mov    %edx,(%esp)
f010472d:	89 f2                	mov    %esi,%edx
f010472f:	d3 e2                	shl    %cl,%edx
f0104731:	89 f9                	mov    %edi,%ecx
f0104733:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104737:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010473b:	d3 e8                	shr    %cl,%eax
f010473d:	89 e9                	mov    %ebp,%ecx
f010473f:	89 c6                	mov    %eax,%esi
f0104741:	d3 e3                	shl    %cl,%ebx
f0104743:	89 f9                	mov    %edi,%ecx
f0104745:	89 d0                	mov    %edx,%eax
f0104747:	d3 e8                	shr    %cl,%eax
f0104749:	89 e9                	mov    %ebp,%ecx
f010474b:	09 d8                	or     %ebx,%eax
f010474d:	89 d3                	mov    %edx,%ebx
f010474f:	89 f2                	mov    %esi,%edx
f0104751:	f7 34 24             	divl   (%esp)
f0104754:	89 d6                	mov    %edx,%esi
f0104756:	d3 e3                	shl    %cl,%ebx
f0104758:	f7 64 24 04          	mull   0x4(%esp)
f010475c:	39 d6                	cmp    %edx,%esi
f010475e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104762:	89 d1                	mov    %edx,%ecx
f0104764:	89 c3                	mov    %eax,%ebx
f0104766:	72 08                	jb     f0104770 <__umoddi3+0x110>
f0104768:	75 11                	jne    f010477b <__umoddi3+0x11b>
f010476a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010476e:	73 0b                	jae    f010477b <__umoddi3+0x11b>
f0104770:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104774:	1b 14 24             	sbb    (%esp),%edx
f0104777:	89 d1                	mov    %edx,%ecx
f0104779:	89 c3                	mov    %eax,%ebx
f010477b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010477f:	29 da                	sub    %ebx,%edx
f0104781:	19 ce                	sbb    %ecx,%esi
f0104783:	89 f9                	mov    %edi,%ecx
f0104785:	89 f0                	mov    %esi,%eax
f0104787:	d3 e0                	shl    %cl,%eax
f0104789:	89 e9                	mov    %ebp,%ecx
f010478b:	d3 ea                	shr    %cl,%edx
f010478d:	89 e9                	mov    %ebp,%ecx
f010478f:	d3 ee                	shr    %cl,%esi
f0104791:	09 d0                	or     %edx,%eax
f0104793:	89 f2                	mov    %esi,%edx
f0104795:	83 c4 1c             	add    $0x1c,%esp
f0104798:	5b                   	pop    %ebx
f0104799:	5e                   	pop    %esi
f010479a:	5f                   	pop    %edi
f010479b:	5d                   	pop    %ebp
f010479c:	c3                   	ret    
f010479d:	8d 76 00             	lea    0x0(%esi),%esi
f01047a0:	29 f9                	sub    %edi,%ecx
f01047a2:	19 d6                	sbb    %edx,%esi
f01047a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01047a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01047ac:	e9 18 ff ff ff       	jmp    f01046c9 <__umoddi3+0x69>
