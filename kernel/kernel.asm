
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	2cc78793          	addi	a5,a5,716 # 80006330 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	38e080e7          	jalr	910(ra) # 800024ba <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	810080e7          	jalr	-2032(ra) # 800019d4 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	ee0080e7          	jalr	-288(ra) # 800020b4 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	254080e7          	jalr	596(ra) # 80002464 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	21e080e7          	jalr	542(ra) # 80002510 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	dfa080e7          	jalr	-518(ra) # 80002240 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	b1878793          	addi	a5,a5,-1256 # 80022f90 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	9a0080e7          	jalr	-1632(ra) # 80002240 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	788080e7          	jalr	1928(ra) # 800020b4 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00026797          	auipc	a5,0x26
    80000a10:	5f478793          	addi	a5,a5,1524 # 80027000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00026517          	auipc	a0,0x26
    80000ae0:	52450513          	addi	a0,a0,1316 # 80027000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e3a080e7          	jalr	-454(ra) # 800019b8 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	e08080e7          	jalr	-504(ra) # 800019b8 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dfc080e7          	jalr	-516(ra) # 800019b8 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	de4080e7          	jalr	-540(ra) # 800019b8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	da4080e7          	jalr	-604(ra) # 800019b8 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d78080e7          	jalr	-648(ra) # 800019b8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b12080e7          	jalr	-1262(ra) # 800019a8 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	af6080e7          	jalr	-1290(ra) # 800019a8 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	d26080e7          	jalr	-730(ra) # 80002bfa <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	494080e7          	jalr	1172(ra) # 80006370 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	8b0080e7          	jalr	-1872(ra) # 80002794 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	c86080e7          	jalr	-890(ra) # 80002bd2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	ca6080e7          	jalr	-858(ra) # 80002bfa <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	3fe080e7          	jalr	1022(ra) # 8000635a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	40c080e7          	jalr	1036(ra) # 80006370 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	5ee080e7          	jalr	1518(ra) # 8000355a <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	c7e080e7          	jalr	-898(ra) # 80003bf2 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	c28080e7          	jalr	-984(ra) # 80004ba4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	50e080e7          	jalr	1294(ra) # 80006492 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	dae080e7          	jalr	-594(ra) # 80001d3a <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000186e:	00017a17          	auipc	s4,0x17
    80001872:	a62a0a13          	addi	s4,s4,-1438 # 800182d0 <mlfq>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if (pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a8:	1b048493          	addi	s1,s1,432
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  for (int i = 0; i < MAX_Q; i++)
    800018e8:	00017797          	auipc	a5,0x17
    800018ec:	9e878793          	addi	a5,a5,-1560 # 800182d0 <mlfq>
    800018f0:	00017717          	auipc	a4,0x17
    800018f4:	45870713          	addi	a4,a4,1112 # 80018d48 <tickslock>
  {
    mlfq[i].q_size = 0;
    800018f8:	0007a023          	sw	zero,0(a5)
    mlfq[i].q_head = 0;
    800018fc:	0007a223          	sw	zero,4(a5)
    mlfq[i].q_tail = 0;
    80001900:	0007a423          	sw	zero,8(a5)
  for (int i = 0; i < MAX_Q; i++)
    80001904:	21878793          	addi	a5,a5,536
    80001908:	fee798e3          	bne	a5,a4,800018f8 <procinit+0x24>
  }
  initlock(&pid_lock, "nextpid");
    8000190c:	00007597          	auipc	a1,0x7
    80001910:	8d458593          	addi	a1,a1,-1836 # 800081e0 <digits+0x1a0>
    80001914:	00010517          	auipc	a0,0x10
    80001918:	98c50513          	addi	a0,a0,-1652 # 800112a0 <pid_lock>
    8000191c:	fffff097          	auipc	ra,0xfffff
    80001920:	238080e7          	jalr	568(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001924:	00007597          	auipc	a1,0x7
    80001928:	8c458593          	addi	a1,a1,-1852 # 800081e8 <digits+0x1a8>
    8000192c:	00010517          	auipc	a0,0x10
    80001930:	98c50513          	addi	a0,a0,-1652 # 800112b8 <wait_lock>
    80001934:	fffff097          	auipc	ra,0xfffff
    80001938:	220080e7          	jalr	544(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000193c:	00010497          	auipc	s1,0x10
    80001940:	d9448493          	addi	s1,s1,-620 # 800116d0 <proc>
  {
    initlock(&p->lock, "proc");
    80001944:	00007b17          	auipc	s6,0x7
    80001948:	8b4b0b13          	addi	s6,s6,-1868 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    8000194c:	8aa6                	mv	s5,s1
    8000194e:	00006a17          	auipc	s4,0x6
    80001952:	6b2a0a13          	addi	s4,s4,1714 # 80008000 <etext>
    80001956:	04000937          	lui	s2,0x4000
    8000195a:	197d                	addi	s2,s2,-1
    8000195c:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000195e:	00017997          	auipc	s3,0x17
    80001962:	97298993          	addi	s3,s3,-1678 # 800182d0 <mlfq>
    initlock(&p->lock, "proc");
    80001966:	85da                	mv	a1,s6
    80001968:	8526                	mv	a0,s1
    8000196a:	fffff097          	auipc	ra,0xfffff
    8000196e:	1ea080e7          	jalr	490(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001972:	415487b3          	sub	a5,s1,s5
    80001976:	8791                	srai	a5,a5,0x4
    80001978:	000a3703          	ld	a4,0(s4)
    8000197c:	02e787b3          	mul	a5,a5,a4
    80001980:	2785                	addiw	a5,a5,1
    80001982:	00d7979b          	slliw	a5,a5,0xd
    80001986:	40f907b3          	sub	a5,s2,a5
    8000198a:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000198c:	1b048493          	addi	s1,s1,432
    80001990:	fd349be3          	bne	s1,s3,80001966 <procinit+0x92>
  }
}
    80001994:	70e2                	ld	ra,56(sp)
    80001996:	7442                	ld	s0,48(sp)
    80001998:	74a2                	ld	s1,40(sp)
    8000199a:	7902                	ld	s2,32(sp)
    8000199c:	69e2                	ld	s3,24(sp)
    8000199e:	6a42                	ld	s4,16(sp)
    800019a0:	6aa2                	ld	s5,8(sp)
    800019a2:	6b02                	ld	s6,0(sp)
    800019a4:	6121                	addi	sp,sp,64
    800019a6:	8082                	ret

00000000800019a8 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    800019a8:	1141                	addi	sp,sp,-16
    800019aa:	e422                	sd	s0,8(sp)
    800019ac:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019ae:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019b0:	2501                	sext.w	a0,a0
    800019b2:	6422                	ld	s0,8(sp)
    800019b4:	0141                	addi	sp,sp,16
    800019b6:	8082                	ret

00000000800019b8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019b8:	1141                	addi	sp,sp,-16
    800019ba:	e422                	sd	s0,8(sp)
    800019bc:	0800                	addi	s0,sp,16
    800019be:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
  return c;
}
    800019c4:	00010517          	auipc	a0,0x10
    800019c8:	90c50513          	addi	a0,a0,-1780 # 800112d0 <cpus>
    800019cc:	953e                	add	a0,a0,a5
    800019ce:	6422                	ld	s0,8(sp)
    800019d0:	0141                	addi	sp,sp,16
    800019d2:	8082                	ret

00000000800019d4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019d4:	1101                	addi	sp,sp,-32
    800019d6:	ec06                	sd	ra,24(sp)
    800019d8:	e822                	sd	s0,16(sp)
    800019da:	e426                	sd	s1,8(sp)
    800019dc:	1000                	addi	s0,sp,32
  push_off();
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	1ba080e7          	jalr	442(ra) # 80000b98 <push_off>
    800019e6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019e8:	2781                	sext.w	a5,a5
    800019ea:	079e                	slli	a5,a5,0x7
    800019ec:	00010717          	auipc	a4,0x10
    800019f0:	8b470713          	addi	a4,a4,-1868 # 800112a0 <pid_lock>
    800019f4:	97ba                	add	a5,a5,a4
    800019f6:	7b84                	ld	s1,48(a5)
  pop_off();
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	240080e7          	jalr	576(ra) # 80000c38 <pop_off>
  return p;
}
    80001a00:	8526                	mv	a0,s1
    80001a02:	60e2                	ld	ra,24(sp)
    80001a04:	6442                	ld	s0,16(sp)
    80001a06:	64a2                	ld	s1,8(sp)
    80001a08:	6105                	addi	sp,sp,32
    80001a0a:	8082                	ret

0000000080001a0c <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a0c:	1141                	addi	sp,sp,-16
    80001a0e:	e406                	sd	ra,8(sp)
    80001a10:	e022                	sd	s0,0(sp)
    80001a12:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a14:	00000097          	auipc	ra,0x0
    80001a18:	fc0080e7          	jalr	-64(ra) # 800019d4 <myproc>
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	27c080e7          	jalr	636(ra) # 80000c98 <release>

  if (first)
    80001a24:	00007797          	auipc	a5,0x7
    80001a28:	f8c7a783          	lw	a5,-116(a5) # 800089b0 <first.1739>
    80001a2c:	eb89                	bnez	a5,80001a3e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a2e:	00001097          	auipc	ra,0x1
    80001a32:	1e4080e7          	jalr	484(ra) # 80002c12 <usertrapret>
}
    80001a36:	60a2                	ld	ra,8(sp)
    80001a38:	6402                	ld	s0,0(sp)
    80001a3a:	0141                	addi	sp,sp,16
    80001a3c:	8082                	ret
    first = 0;
    80001a3e:	00007797          	auipc	a5,0x7
    80001a42:	f607a923          	sw	zero,-142(a5) # 800089b0 <first.1739>
    fsinit(ROOTDEV);
    80001a46:	4505                	li	a0,1
    80001a48:	00002097          	auipc	ra,0x2
    80001a4c:	12a080e7          	jalr	298(ra) # 80003b72 <fsinit>
    80001a50:	bff9                	j	80001a2e <forkret+0x22>

0000000080001a52 <allocpid>:
{
    80001a52:	1101                	addi	sp,sp,-32
    80001a54:	ec06                	sd	ra,24(sp)
    80001a56:	e822                	sd	s0,16(sp)
    80001a58:	e426                	sd	s1,8(sp)
    80001a5a:	e04a                	sd	s2,0(sp)
    80001a5c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a5e:	00010917          	auipc	s2,0x10
    80001a62:	84290913          	addi	s2,s2,-1982 # 800112a0 <pid_lock>
    80001a66:	854a                	mv	a0,s2
    80001a68:	fffff097          	auipc	ra,0xfffff
    80001a6c:	17c080e7          	jalr	380(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a70:	00007797          	auipc	a5,0x7
    80001a74:	f4478793          	addi	a5,a5,-188 # 800089b4 <nextpid>
    80001a78:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a7a:	0014871b          	addiw	a4,s1,1
    80001a7e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a80:	854a                	mv	a0,s2
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	216080e7          	jalr	534(ra) # 80000c98 <release>
}
    80001a8a:	8526                	mv	a0,s1
    80001a8c:	60e2                	ld	ra,24(sp)
    80001a8e:	6442                	ld	s0,16(sp)
    80001a90:	64a2                	ld	s1,8(sp)
    80001a92:	6902                	ld	s2,0(sp)
    80001a94:	6105                	addi	sp,sp,32
    80001a96:	8082                	ret

0000000080001a98 <proc_pagetable>:
{
    80001a98:	1101                	addi	sp,sp,-32
    80001a9a:	ec06                	sd	ra,24(sp)
    80001a9c:	e822                	sd	s0,16(sp)
    80001a9e:	e426                	sd	s1,8(sp)
    80001aa0:	e04a                	sd	s2,0(sp)
    80001aa2:	1000                	addi	s0,sp,32
    80001aa4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aa6:	00000097          	auipc	ra,0x0
    80001aaa:	894080e7          	jalr	-1900(ra) # 8000133a <uvmcreate>
    80001aae:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001ab0:	c121                	beqz	a0,80001af0 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ab2:	4729                	li	a4,10
    80001ab4:	00005697          	auipc	a3,0x5
    80001ab8:	54c68693          	addi	a3,a3,1356 # 80007000 <_trampoline>
    80001abc:	6605                	lui	a2,0x1
    80001abe:	040005b7          	lui	a1,0x4000
    80001ac2:	15fd                	addi	a1,a1,-1
    80001ac4:	05b2                	slli	a1,a1,0xc
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	5ea080e7          	jalr	1514(ra) # 800010b0 <mappages>
    80001ace:	02054863          	bltz	a0,80001afe <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ad2:	4719                	li	a4,6
    80001ad4:	05893683          	ld	a3,88(s2)
    80001ad8:	6605                	lui	a2,0x1
    80001ada:	020005b7          	lui	a1,0x2000
    80001ade:	15fd                	addi	a1,a1,-1
    80001ae0:	05b6                	slli	a1,a1,0xd
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	fffff097          	auipc	ra,0xfffff
    80001ae8:	5cc080e7          	jalr	1484(ra) # 800010b0 <mappages>
    80001aec:	02054163          	bltz	a0,80001b0e <proc_pagetable+0x76>
}
    80001af0:	8526                	mv	a0,s1
    80001af2:	60e2                	ld	ra,24(sp)
    80001af4:	6442                	ld	s0,16(sp)
    80001af6:	64a2                	ld	s1,8(sp)
    80001af8:	6902                	ld	s2,0(sp)
    80001afa:	6105                	addi	sp,sp,32
    80001afc:	8082                	ret
    uvmfree(pagetable, 0);
    80001afe:	4581                	li	a1,0
    80001b00:	8526                	mv	a0,s1
    80001b02:	00000097          	auipc	ra,0x0
    80001b06:	a34080e7          	jalr	-1484(ra) # 80001536 <uvmfree>
    return 0;
    80001b0a:	4481                	li	s1,0
    80001b0c:	b7d5                	j	80001af0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b0e:	4681                	li	a3,0
    80001b10:	4605                	li	a2,1
    80001b12:	040005b7          	lui	a1,0x4000
    80001b16:	15fd                	addi	a1,a1,-1
    80001b18:	05b2                	slli	a1,a1,0xc
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	75a080e7          	jalr	1882(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b24:	4581                	li	a1,0
    80001b26:	8526                	mv	a0,s1
    80001b28:	00000097          	auipc	ra,0x0
    80001b2c:	a0e080e7          	jalr	-1522(ra) # 80001536 <uvmfree>
    return 0;
    80001b30:	4481                	li	s1,0
    80001b32:	bf7d                	j	80001af0 <proc_pagetable+0x58>

0000000080001b34 <proc_freepagetable>:
{
    80001b34:	1101                	addi	sp,sp,-32
    80001b36:	ec06                	sd	ra,24(sp)
    80001b38:	e822                	sd	s0,16(sp)
    80001b3a:	e426                	sd	s1,8(sp)
    80001b3c:	e04a                	sd	s2,0(sp)
    80001b3e:	1000                	addi	s0,sp,32
    80001b40:	84aa                	mv	s1,a0
    80001b42:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b44:	4681                	li	a3,0
    80001b46:	4605                	li	a2,1
    80001b48:	040005b7          	lui	a1,0x4000
    80001b4c:	15fd                	addi	a1,a1,-1
    80001b4e:	05b2                	slli	a1,a1,0xc
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	726080e7          	jalr	1830(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b58:	4681                	li	a3,0
    80001b5a:	4605                	li	a2,1
    80001b5c:	020005b7          	lui	a1,0x2000
    80001b60:	15fd                	addi	a1,a1,-1
    80001b62:	05b6                	slli	a1,a1,0xd
    80001b64:	8526                	mv	a0,s1
    80001b66:	fffff097          	auipc	ra,0xfffff
    80001b6a:	710080e7          	jalr	1808(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b6e:	85ca                	mv	a1,s2
    80001b70:	8526                	mv	a0,s1
    80001b72:	00000097          	auipc	ra,0x0
    80001b76:	9c4080e7          	jalr	-1596(ra) # 80001536 <uvmfree>
}
    80001b7a:	60e2                	ld	ra,24(sp)
    80001b7c:	6442                	ld	s0,16(sp)
    80001b7e:	64a2                	ld	s1,8(sp)
    80001b80:	6902                	ld	s2,0(sp)
    80001b82:	6105                	addi	sp,sp,32
    80001b84:	8082                	ret

0000000080001b86 <freeproc>:
{
    80001b86:	1101                	addi	sp,sp,-32
    80001b88:	ec06                	sd	ra,24(sp)
    80001b8a:	e822                	sd	s0,16(sp)
    80001b8c:	e426                	sd	s1,8(sp)
    80001b8e:	1000                	addi	s0,sp,32
    80001b90:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b92:	6d28                	ld	a0,88(a0)
    80001b94:	c509                	beqz	a0,80001b9e <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	e62080e7          	jalr	-414(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b9e:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001ba2:	68a8                	ld	a0,80(s1)
    80001ba4:	c511                	beqz	a0,80001bb0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba6:	64ac                	ld	a1,72(s1)
    80001ba8:	00000097          	auipc	ra,0x0
    80001bac:	f8c080e7          	jalr	-116(ra) # 80001b34 <proc_freepagetable>
  p->pagetable = 0;
    80001bb0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bb4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bb8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bbc:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bc0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bc4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bcc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bd0:	0004ac23          	sw	zero,24(s1)
}
    80001bd4:	60e2                	ld	ra,24(sp)
    80001bd6:	6442                	ld	s0,16(sp)
    80001bd8:	64a2                	ld	s1,8(sp)
    80001bda:	6105                	addi	sp,sp,32
    80001bdc:	8082                	ret

0000000080001bde <allocproc>:
{
    80001bde:	1101                	addi	sp,sp,-32
    80001be0:	ec06                	sd	ra,24(sp)
    80001be2:	e822                	sd	s0,16(sp)
    80001be4:	e426                	sd	s1,8(sp)
    80001be6:	e04a                	sd	s2,0(sp)
    80001be8:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	00010497          	auipc	s1,0x10
    80001bee:	ae648493          	addi	s1,s1,-1306 # 800116d0 <proc>
    80001bf2:	00016917          	auipc	s2,0x16
    80001bf6:	6de90913          	addi	s2,s2,1758 # 800182d0 <mlfq>
    acquire(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	fe8080e7          	jalr	-24(ra) # 80000be4 <acquire>
    if (p->state == UNUSED)
    80001c04:	4c9c                	lw	a5,24(s1)
    80001c06:	cf81                	beqz	a5,80001c1e <allocproc+0x40>
      release(&p->lock);
    80001c08:	8526                	mv	a0,s1
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	08e080e7          	jalr	142(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c12:	1b048493          	addi	s1,s1,432
    80001c16:	ff2492e3          	bne	s1,s2,80001bfa <allocproc+0x1c>
  return 0;
    80001c1a:	4481                	li	s1,0
    80001c1c:	a0c5                	j	80001cfc <allocproc+0x11e>
  p->pid = allocpid();
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	e34080e7          	jalr	-460(ra) # 80001a52 <allocpid>
    80001c26:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c28:	4785                	li	a5,1
    80001c2a:	cc9c                	sw	a5,24(s1)
  acquire(&tickslock);
    80001c2c:	00017517          	auipc	a0,0x17
    80001c30:	11c50513          	addi	a0,a0,284 # 80018d48 <tickslock>
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	fb0080e7          	jalr	-80(ra) # 80000be4 <acquire>
  p->crt_time = ticks;
    80001c3c:	00007917          	auipc	s2,0x7
    80001c40:	3f490913          	addi	s2,s2,1012 # 80009030 <ticks>
    80001c44:	00092783          	lw	a5,0(s2)
    80001c48:	16f4a423          	sw	a5,360(s1)
  p->runtime = 0;
    80001c4c:	1604a823          	sw	zero,368(s1)
  release(&tickslock);
    80001c50:	00017517          	auipc	a0,0x17
    80001c54:	0f850513          	addi	a0,a0,248 # 80018d48 <tickslock>
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	040080e7          	jalr	64(ra) # 80000c98 <release>
  p->static_priority = 60;
    80001c60:	03c00793          	li	a5,60
    80001c64:	16f4ae23          	sw	a5,380(s1)
  p->niceness = 5;
    80001c68:	4795                	li	a5,5
    80001c6a:	16f4ac23          	sw	a5,376(s1)
  p->level = 0;
    80001c6e:	1804a423          	sw	zero,392(s1)
  p->curr_q = 0;
    80001c72:	1804a023          	sw	zero,384(s1)
  acquire(&tickslock);
    80001c76:	00017517          	auipc	a0,0x17
    80001c7a:	0d250513          	addi	a0,a0,210 # 80018d48 <tickslock>
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	f66080e7          	jalr	-154(ra) # 80000be4 <acquire>
  p->enter_q = ticks;
    80001c86:	00092783          	lw	a5,0(s2)
    80001c8a:	18f4a823          	sw	a5,400(s1)
  release(&tickslock);
    80001c8e:	00017517          	auipc	a0,0x17
    80001c92:	0ba50513          	addi	a0,a0,186 # 80018d48 <tickslock>
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	002080e7          	jalr	2(ra) # 80000c98 <release>
  p->num_sched = 0;
    80001c9e:	1804a623          	sw	zero,396(s1)
  p->sleep_time = 0;
    80001ca2:	1804aa23          	sw	zero,404(s1)
    p->q[i] = 0;
    80001ca6:	1804ac23          	sw	zero,408(s1)
    80001caa:	1804ae23          	sw	zero,412(s1)
    80001cae:	1a04a023          	sw	zero,416(s1)
    80001cb2:	1a04a223          	sw	zero,420(s1)
    80001cb6:	1a04a423          	sw	zero,424(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	e3a080e7          	jalr	-454(ra) # 80000af4 <kalloc>
    80001cc2:	892a                	mv	s2,a0
    80001cc4:	eca8                	sd	a0,88(s1)
    80001cc6:	c131                	beqz	a0,80001d0a <allocproc+0x12c>
  p->pagetable = proc_pagetable(p);
    80001cc8:	8526                	mv	a0,s1
    80001cca:	00000097          	auipc	ra,0x0
    80001cce:	dce080e7          	jalr	-562(ra) # 80001a98 <proc_pagetable>
    80001cd2:	892a                	mv	s2,a0
    80001cd4:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001cd6:	c531                	beqz	a0,80001d22 <allocproc+0x144>
  memset(&p->context, 0, sizeof(p->context));
    80001cd8:	07000613          	li	a2,112
    80001cdc:	4581                	li	a1,0
    80001cde:	06048513          	addi	a0,s1,96
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	ffe080e7          	jalr	-2(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001cea:	00000797          	auipc	a5,0x0
    80001cee:	d2278793          	addi	a5,a5,-734 # 80001a0c <forkret>
    80001cf2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cf4:	60bc                	ld	a5,64(s1)
    80001cf6:	6705                	lui	a4,0x1
    80001cf8:	97ba                	add	a5,a5,a4
    80001cfa:	f4bc                	sd	a5,104(s1)
}
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	60e2                	ld	ra,24(sp)
    80001d00:	6442                	ld	s0,16(sp)
    80001d02:	64a2                	ld	s1,8(sp)
    80001d04:	6902                	ld	s2,0(sp)
    80001d06:	6105                	addi	sp,sp,32
    80001d08:	8082                	ret
    freeproc(p);
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	00000097          	auipc	ra,0x0
    80001d10:	e7a080e7          	jalr	-390(ra) # 80001b86 <freeproc>
    release(&p->lock);
    80001d14:	8526                	mv	a0,s1
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	f82080e7          	jalr	-126(ra) # 80000c98 <release>
    return 0;
    80001d1e:	84ca                	mv	s1,s2
    80001d20:	bff1                	j	80001cfc <allocproc+0x11e>
    freeproc(p);
    80001d22:	8526                	mv	a0,s1
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	e62080e7          	jalr	-414(ra) # 80001b86 <freeproc>
    release(&p->lock);
    80001d2c:	8526                	mv	a0,s1
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	f6a080e7          	jalr	-150(ra) # 80000c98 <release>
    return 0;
    80001d36:	84ca                	mv	s1,s2
    80001d38:	b7d1                	j	80001cfc <allocproc+0x11e>

0000000080001d3a <userinit>:
{
    80001d3a:	1101                	addi	sp,sp,-32
    80001d3c:	ec06                	sd	ra,24(sp)
    80001d3e:	e822                	sd	s0,16(sp)
    80001d40:	e426                	sd	s1,8(sp)
    80001d42:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d44:	00000097          	auipc	ra,0x0
    80001d48:	e9a080e7          	jalr	-358(ra) # 80001bde <allocproc>
    80001d4c:	84aa                	mv	s1,a0
  initproc = p;
    80001d4e:	00007797          	auipc	a5,0x7
    80001d52:	2ca7bd23          	sd	a0,730(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d56:	03400613          	li	a2,52
    80001d5a:	00007597          	auipc	a1,0x7
    80001d5e:	c6658593          	addi	a1,a1,-922 # 800089c0 <initcode>
    80001d62:	6928                	ld	a0,80(a0)
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	604080e7          	jalr	1540(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d6c:	6785                	lui	a5,0x1
    80001d6e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d70:	6cb8                	ld	a4,88(s1)
    80001d72:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d76:	6cb8                	ld	a4,88(s1)
    80001d78:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d7a:	4641                	li	a2,16
    80001d7c:	00006597          	auipc	a1,0x6
    80001d80:	48458593          	addi	a1,a1,1156 # 80008200 <digits+0x1c0>
    80001d84:	15848513          	addi	a0,s1,344
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	0aa080e7          	jalr	170(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d90:	00006517          	auipc	a0,0x6
    80001d94:	48050513          	addi	a0,a0,1152 # 80008210 <digits+0x1d0>
    80001d98:	00003097          	auipc	ra,0x3
    80001d9c:	808080e7          	jalr	-2040(ra) # 800045a0 <namei>
    80001da0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001da4:	478d                	li	a5,3
    80001da6:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001da8:	8526                	mv	a0,s1
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	eee080e7          	jalr	-274(ra) # 80000c98 <release>
}
    80001db2:	60e2                	ld	ra,24(sp)
    80001db4:	6442                	ld	s0,16(sp)
    80001db6:	64a2                	ld	s1,8(sp)
    80001db8:	6105                	addi	sp,sp,32
    80001dba:	8082                	ret

0000000080001dbc <growproc>:
{
    80001dbc:	1101                	addi	sp,sp,-32
    80001dbe:	ec06                	sd	ra,24(sp)
    80001dc0:	e822                	sd	s0,16(sp)
    80001dc2:	e426                	sd	s1,8(sp)
    80001dc4:	e04a                	sd	s2,0(sp)
    80001dc6:	1000                	addi	s0,sp,32
    80001dc8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	c0a080e7          	jalr	-1014(ra) # 800019d4 <myproc>
    80001dd2:	892a                	mv	s2,a0
  sz = p->sz;
    80001dd4:	652c                	ld	a1,72(a0)
    80001dd6:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001dda:	00904f63          	bgtz	s1,80001df8 <growproc+0x3c>
  else if (n < 0)
    80001dde:	0204cc63          	bltz	s1,80001e16 <growproc+0x5a>
  p->sz = sz;
    80001de2:	1602                	slli	a2,a2,0x20
    80001de4:	9201                	srli	a2,a2,0x20
    80001de6:	04c93423          	sd	a2,72(s2)
  return 0;
    80001dea:	4501                	li	a0,0
}
    80001dec:	60e2                	ld	ra,24(sp)
    80001dee:	6442                	ld	s0,16(sp)
    80001df0:	64a2                	ld	s1,8(sp)
    80001df2:	6902                	ld	s2,0(sp)
    80001df4:	6105                	addi	sp,sp,32
    80001df6:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001df8:	9e25                	addw	a2,a2,s1
    80001dfa:	1602                	slli	a2,a2,0x20
    80001dfc:	9201                	srli	a2,a2,0x20
    80001dfe:	1582                	slli	a1,a1,0x20
    80001e00:	9181                	srli	a1,a1,0x20
    80001e02:	6928                	ld	a0,80(a0)
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	61e080e7          	jalr	1566(ra) # 80001422 <uvmalloc>
    80001e0c:	0005061b          	sext.w	a2,a0
    80001e10:	fa69                	bnez	a2,80001de2 <growproc+0x26>
      return -1;
    80001e12:	557d                	li	a0,-1
    80001e14:	bfe1                	j	80001dec <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e16:	9e25                	addw	a2,a2,s1
    80001e18:	1602                	slli	a2,a2,0x20
    80001e1a:	9201                	srli	a2,a2,0x20
    80001e1c:	1582                	slli	a1,a1,0x20
    80001e1e:	9181                	srli	a1,a1,0x20
    80001e20:	6928                	ld	a0,80(a0)
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	5b8080e7          	jalr	1464(ra) # 800013da <uvmdealloc>
    80001e2a:	0005061b          	sext.w	a2,a0
    80001e2e:	bf55                	j	80001de2 <growproc+0x26>

0000000080001e30 <get_dynamic>:
{
    80001e30:	1141                	addi	sp,sp,-16
    80001e32:	e422                	sd	s0,8(sp)
    80001e34:	0800                	addi	s0,sp,16
  int val = priority - niceness + 5;
    80001e36:	9d0d                	subw	a0,a0,a1
    80001e38:	2515                	addiw	a0,a0,5
    80001e3a:	0005071b          	sext.w	a4,a0
    80001e3e:	06400793          	li	a5,100
    80001e42:	00e7d463          	bge	a5,a4,80001e4a <get_dynamic+0x1a>
    80001e46:	06400513          	li	a0,100
    80001e4a:	0005079b          	sext.w	a5,a0
    80001e4e:	fff7c793          	not	a5,a5
    80001e52:	97fd                	srai	a5,a5,0x3f
    80001e54:	8d7d                	and	a0,a0,a5
}
    80001e56:	2501                	sext.w	a0,a0
    80001e58:	6422                	ld	s0,8(sp)
    80001e5a:	0141                	addi	sp,sp,16
    80001e5c:	8082                	ret

0000000080001e5e <fork>:
{
    80001e5e:	7179                	addi	sp,sp,-48
    80001e60:	f406                	sd	ra,40(sp)
    80001e62:	f022                	sd	s0,32(sp)
    80001e64:	ec26                	sd	s1,24(sp)
    80001e66:	e84a                	sd	s2,16(sp)
    80001e68:	e44e                	sd	s3,8(sp)
    80001e6a:	e052                	sd	s4,0(sp)
    80001e6c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e6e:	00000097          	auipc	ra,0x0
    80001e72:	b66080e7          	jalr	-1178(ra) # 800019d4 <myproc>
    80001e76:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001e78:	00000097          	auipc	ra,0x0
    80001e7c:	d66080e7          	jalr	-666(ra) # 80001bde <allocproc>
    80001e80:	10050f63          	beqz	a0,80001f9e <fork+0x140>
    80001e84:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e86:	04893603          	ld	a2,72(s2)
    80001e8a:	692c                	ld	a1,80(a0)
    80001e8c:	05093503          	ld	a0,80(s2)
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	6de080e7          	jalr	1758(ra) # 8000156e <uvmcopy>
    80001e98:	04054a63          	bltz	a0,80001eec <fork+0x8e>
  np->sz = p->sz;
    80001e9c:	04893783          	ld	a5,72(s2)
    80001ea0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ea4:	05893683          	ld	a3,88(s2)
    80001ea8:	87b6                	mv	a5,a3
    80001eaa:	0589b703          	ld	a4,88(s3)
    80001eae:	12068693          	addi	a3,a3,288
    80001eb2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001eb6:	6788                	ld	a0,8(a5)
    80001eb8:	6b8c                	ld	a1,16(a5)
    80001eba:	6f90                	ld	a2,24(a5)
    80001ebc:	01073023          	sd	a6,0(a4)
    80001ec0:	e708                	sd	a0,8(a4)
    80001ec2:	eb0c                	sd	a1,16(a4)
    80001ec4:	ef10                	sd	a2,24(a4)
    80001ec6:	02078793          	addi	a5,a5,32
    80001eca:	02070713          	addi	a4,a4,32
    80001ece:	fed792e3          	bne	a5,a3,80001eb2 <fork+0x54>
  np->trapframe->a0 = 0;
    80001ed2:	0589b783          	ld	a5,88(s3)
    80001ed6:	0607b823          	sd	zero,112(a5)
  np->mask = p->mask;
    80001eda:	03492783          	lw	a5,52(s2)
    80001ede:	02f9aa23          	sw	a5,52(s3)
    80001ee2:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001ee6:	15000a13          	li	s4,336
    80001eea:	a03d                	j	80001f18 <fork+0xba>
    freeproc(np);
    80001eec:	854e                	mv	a0,s3
    80001eee:	00000097          	auipc	ra,0x0
    80001ef2:	c98080e7          	jalr	-872(ra) # 80001b86 <freeproc>
    release(&np->lock);
    80001ef6:	854e                	mv	a0,s3
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	da0080e7          	jalr	-608(ra) # 80000c98 <release>
    return -1;
    80001f00:	5a7d                	li	s4,-1
    80001f02:	a069                	j	80001f8c <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f04:	00003097          	auipc	ra,0x3
    80001f08:	d32080e7          	jalr	-718(ra) # 80004c36 <filedup>
    80001f0c:	009987b3          	add	a5,s3,s1
    80001f10:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001f12:	04a1                	addi	s1,s1,8
    80001f14:	01448763          	beq	s1,s4,80001f22 <fork+0xc4>
    if (p->ofile[i])
    80001f18:	009907b3          	add	a5,s2,s1
    80001f1c:	6388                	ld	a0,0(a5)
    80001f1e:	f17d                	bnez	a0,80001f04 <fork+0xa6>
    80001f20:	bfcd                	j	80001f12 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001f22:	15093503          	ld	a0,336(s2)
    80001f26:	00002097          	auipc	ra,0x2
    80001f2a:	e86080e7          	jalr	-378(ra) # 80003dac <idup>
    80001f2e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f32:	4641                	li	a2,16
    80001f34:	15890593          	addi	a1,s2,344
    80001f38:	15898513          	addi	a0,s3,344
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	ef6080e7          	jalr	-266(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f44:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f48:	854e                	mv	a0,s3
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	d4e080e7          	jalr	-690(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f52:	0000f497          	auipc	s1,0xf
    80001f56:	36648493          	addi	s1,s1,870 # 800112b8 <wait_lock>
    80001f5a:	8526                	mv	a0,s1
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	c88080e7          	jalr	-888(ra) # 80000be4 <acquire>
  np->parent = p;
    80001f64:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f68:	8526                	mv	a0,s1
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	d2e080e7          	jalr	-722(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f72:	854e                	mv	a0,s3
    80001f74:	fffff097          	auipc	ra,0xfffff
    80001f78:	c70080e7          	jalr	-912(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001f7c:	478d                	li	a5,3
    80001f7e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f82:	854e                	mv	a0,s3
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	d14080e7          	jalr	-748(ra) # 80000c98 <release>
}
    80001f8c:	8552                	mv	a0,s4
    80001f8e:	70a2                	ld	ra,40(sp)
    80001f90:	7402                	ld	s0,32(sp)
    80001f92:	64e2                	ld	s1,24(sp)
    80001f94:	6942                	ld	s2,16(sp)
    80001f96:	69a2                	ld	s3,8(sp)
    80001f98:	6a02                	ld	s4,0(sp)
    80001f9a:	6145                	addi	sp,sp,48
    80001f9c:	8082                	ret
    return -1;
    80001f9e:	5a7d                	li	s4,-1
    80001fa0:	b7f5                	j	80001f8c <fork+0x12e>

0000000080001fa2 <sched>:
{
    80001fa2:	7179                	addi	sp,sp,-48
    80001fa4:	f406                	sd	ra,40(sp)
    80001fa6:	f022                	sd	s0,32(sp)
    80001fa8:	ec26                	sd	s1,24(sp)
    80001faa:	e84a                	sd	s2,16(sp)
    80001fac:	e44e                	sd	s3,8(sp)
    80001fae:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fb0:	00000097          	auipc	ra,0x0
    80001fb4:	a24080e7          	jalr	-1500(ra) # 800019d4 <myproc>
    80001fb8:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001fba:	fffff097          	auipc	ra,0xfffff
    80001fbe:	bb0080e7          	jalr	-1104(ra) # 80000b6a <holding>
    80001fc2:	c93d                	beqz	a0,80002038 <sched+0x96>
    80001fc4:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001fc6:	2781                	sext.w	a5,a5
    80001fc8:	079e                	slli	a5,a5,0x7
    80001fca:	0000f717          	auipc	a4,0xf
    80001fce:	2d670713          	addi	a4,a4,726 # 800112a0 <pid_lock>
    80001fd2:	97ba                	add	a5,a5,a4
    80001fd4:	0a87a703          	lw	a4,168(a5)
    80001fd8:	4785                	li	a5,1
    80001fda:	06f71763          	bne	a4,a5,80002048 <sched+0xa6>
  if (p->state == RUNNING)
    80001fde:	4c98                	lw	a4,24(s1)
    80001fe0:	4791                	li	a5,4
    80001fe2:	06f70b63          	beq	a4,a5,80002058 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fea:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fec:	efb5                	bnez	a5,80002068 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fee:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001ff0:	0000f917          	auipc	s2,0xf
    80001ff4:	2b090913          	addi	s2,s2,688 # 800112a0 <pid_lock>
    80001ff8:	2781                	sext.w	a5,a5
    80001ffa:	079e                	slli	a5,a5,0x7
    80001ffc:	97ca                	add	a5,a5,s2
    80001ffe:	0ac7a983          	lw	s3,172(a5)
    80002002:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002004:	2781                	sext.w	a5,a5
    80002006:	079e                	slli	a5,a5,0x7
    80002008:	0000f597          	auipc	a1,0xf
    8000200c:	2d058593          	addi	a1,a1,720 # 800112d8 <cpus+0x8>
    80002010:	95be                	add	a1,a1,a5
    80002012:	06048513          	addi	a0,s1,96
    80002016:	00001097          	auipc	ra,0x1
    8000201a:	b52080e7          	jalr	-1198(ra) # 80002b68 <swtch>
    8000201e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002020:	2781                	sext.w	a5,a5
    80002022:	079e                	slli	a5,a5,0x7
    80002024:	97ca                	add	a5,a5,s2
    80002026:	0b37a623          	sw	s3,172(a5)
}
    8000202a:	70a2                	ld	ra,40(sp)
    8000202c:	7402                	ld	s0,32(sp)
    8000202e:	64e2                	ld	s1,24(sp)
    80002030:	6942                	ld	s2,16(sp)
    80002032:	69a2                	ld	s3,8(sp)
    80002034:	6145                	addi	sp,sp,48
    80002036:	8082                	ret
    panic("sched p->lock");
    80002038:	00006517          	auipc	a0,0x6
    8000203c:	1e050513          	addi	a0,a0,480 # 80008218 <digits+0x1d8>
    80002040:	ffffe097          	auipc	ra,0xffffe
    80002044:	4fe080e7          	jalr	1278(ra) # 8000053e <panic>
    panic("sched locks");
    80002048:	00006517          	auipc	a0,0x6
    8000204c:	1e050513          	addi	a0,a0,480 # 80008228 <digits+0x1e8>
    80002050:	ffffe097          	auipc	ra,0xffffe
    80002054:	4ee080e7          	jalr	1262(ra) # 8000053e <panic>
    panic("sched running");
    80002058:	00006517          	auipc	a0,0x6
    8000205c:	1e050513          	addi	a0,a0,480 # 80008238 <digits+0x1f8>
    80002060:	ffffe097          	auipc	ra,0xffffe
    80002064:	4de080e7          	jalr	1246(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002068:	00006517          	auipc	a0,0x6
    8000206c:	1e050513          	addi	a0,a0,480 # 80008248 <digits+0x208>
    80002070:	ffffe097          	auipc	ra,0xffffe
    80002074:	4ce080e7          	jalr	1230(ra) # 8000053e <panic>

0000000080002078 <yield>:
{
    80002078:	1101                	addi	sp,sp,-32
    8000207a:	ec06                	sd	ra,24(sp)
    8000207c:	e822                	sd	s0,16(sp)
    8000207e:	e426                	sd	s1,8(sp)
    80002080:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002082:	00000097          	auipc	ra,0x0
    80002086:	952080e7          	jalr	-1710(ra) # 800019d4 <myproc>
    8000208a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	b58080e7          	jalr	-1192(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002094:	478d                	li	a5,3
    80002096:	cc9c                	sw	a5,24(s1)
  sched();
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	f0a080e7          	jalr	-246(ra) # 80001fa2 <sched>
  release(&p->lock);
    800020a0:	8526                	mv	a0,s1
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	bf6080e7          	jalr	-1034(ra) # 80000c98 <release>
}
    800020aa:	60e2                	ld	ra,24(sp)
    800020ac:	6442                	ld	s0,16(sp)
    800020ae:	64a2                	ld	s1,8(sp)
    800020b0:	6105                	addi	sp,sp,32
    800020b2:	8082                	ret

00000000800020b4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020b4:	7179                	addi	sp,sp,-48
    800020b6:	f406                	sd	ra,40(sp)
    800020b8:	f022                	sd	s0,32(sp)
    800020ba:	ec26                	sd	s1,24(sp)
    800020bc:	e84a                	sd	s2,16(sp)
    800020be:	e44e                	sd	s3,8(sp)
    800020c0:	1800                	addi	s0,sp,48
    800020c2:	89aa                	mv	s3,a0
    800020c4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020c6:	00000097          	auipc	ra,0x0
    800020ca:	90e080e7          	jalr	-1778(ra) # 800019d4 <myproc>
    800020ce:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	b14080e7          	jalr	-1260(ra) # 80000be4 <acquire>
  release(lk);
    800020d8:	854a                	mv	a0,s2
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	bbe080e7          	jalr	-1090(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800020e2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020e6:	4789                	li	a5,2
    800020e8:	cc9c                	sw	a5,24(s1)

  sched();
    800020ea:	00000097          	auipc	ra,0x0
    800020ee:	eb8080e7          	jalr	-328(ra) # 80001fa2 <sched>

  // Tidy up.
  p->chan = 0;
    800020f2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	ba0080e7          	jalr	-1120(ra) # 80000c98 <release>
  acquire(lk);
    80002100:	854a                	mv	a0,s2
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ae2080e7          	jalr	-1310(ra) # 80000be4 <acquire>
}
    8000210a:	70a2                	ld	ra,40(sp)
    8000210c:	7402                	ld	s0,32(sp)
    8000210e:	64e2                	ld	s1,24(sp)
    80002110:	6942                	ld	s2,16(sp)
    80002112:	69a2                	ld	s3,8(sp)
    80002114:	6145                	addi	sp,sp,48
    80002116:	8082                	ret

0000000080002118 <wait>:
{
    80002118:	715d                	addi	sp,sp,-80
    8000211a:	e486                	sd	ra,72(sp)
    8000211c:	e0a2                	sd	s0,64(sp)
    8000211e:	fc26                	sd	s1,56(sp)
    80002120:	f84a                	sd	s2,48(sp)
    80002122:	f44e                	sd	s3,40(sp)
    80002124:	f052                	sd	s4,32(sp)
    80002126:	ec56                	sd	s5,24(sp)
    80002128:	e85a                	sd	s6,16(sp)
    8000212a:	e45e                	sd	s7,8(sp)
    8000212c:	e062                	sd	s8,0(sp)
    8000212e:	0880                	addi	s0,sp,80
    80002130:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002132:	00000097          	auipc	ra,0x0
    80002136:	8a2080e7          	jalr	-1886(ra) # 800019d4 <myproc>
    8000213a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000213c:	0000f517          	auipc	a0,0xf
    80002140:	17c50513          	addi	a0,a0,380 # 800112b8 <wait_lock>
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	aa0080e7          	jalr	-1376(ra) # 80000be4 <acquire>
    havekids = 0;
    8000214c:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    8000214e:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002150:	00016997          	auipc	s3,0x16
    80002154:	18098993          	addi	s3,s3,384 # 800182d0 <mlfq>
        havekids = 1;
    80002158:	4a85                	li	s5,1
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000215a:	0000fc17          	auipc	s8,0xf
    8000215e:	15ec0c13          	addi	s8,s8,350 # 800112b8 <wait_lock>
    havekids = 0;
    80002162:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002164:	0000f497          	auipc	s1,0xf
    80002168:	56c48493          	addi	s1,s1,1388 # 800116d0 <proc>
    8000216c:	a0bd                	j	800021da <wait+0xc2>
          pid = np->pid;
    8000216e:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002172:	000b0e63          	beqz	s6,8000218e <wait+0x76>
    80002176:	4691                	li	a3,4
    80002178:	02c48613          	addi	a2,s1,44
    8000217c:	85da                	mv	a1,s6
    8000217e:	05093503          	ld	a0,80(s2)
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	4f0080e7          	jalr	1264(ra) # 80001672 <copyout>
    8000218a:	02054563          	bltz	a0,800021b4 <wait+0x9c>
          freeproc(np);
    8000218e:	8526                	mv	a0,s1
    80002190:	00000097          	auipc	ra,0x0
    80002194:	9f6080e7          	jalr	-1546(ra) # 80001b86 <freeproc>
          release(&np->lock);
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	afe080e7          	jalr	-1282(ra) # 80000c98 <release>
          release(&wait_lock);
    800021a2:	0000f517          	auipc	a0,0xf
    800021a6:	11650513          	addi	a0,a0,278 # 800112b8 <wait_lock>
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	aee080e7          	jalr	-1298(ra) # 80000c98 <release>
          return pid;
    800021b2:	a09d                	j	80002218 <wait+0x100>
            release(&np->lock);
    800021b4:	8526                	mv	a0,s1
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	ae2080e7          	jalr	-1310(ra) # 80000c98 <release>
            release(&wait_lock);
    800021be:	0000f517          	auipc	a0,0xf
    800021c2:	0fa50513          	addi	a0,a0,250 # 800112b8 <wait_lock>
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	ad2080e7          	jalr	-1326(ra) # 80000c98 <release>
            return -1;
    800021ce:	59fd                	li	s3,-1
    800021d0:	a0a1                	j	80002218 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800021d2:	1b048493          	addi	s1,s1,432
    800021d6:	03348463          	beq	s1,s3,800021fe <wait+0xe6>
      if (np->parent == p)
    800021da:	7c9c                	ld	a5,56(s1)
    800021dc:	ff279be3          	bne	a5,s2,800021d2 <wait+0xba>
        acquire(&np->lock);
    800021e0:	8526                	mv	a0,s1
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	a02080e7          	jalr	-1534(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    800021ea:	4c9c                	lw	a5,24(s1)
    800021ec:	f94781e3          	beq	a5,s4,8000216e <wait+0x56>
        release(&np->lock);
    800021f0:	8526                	mv	a0,s1
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	aa6080e7          	jalr	-1370(ra) # 80000c98 <release>
        havekids = 1;
    800021fa:	8756                	mv	a4,s5
    800021fc:	bfd9                	j	800021d2 <wait+0xba>
    if (!havekids || p->killed)
    800021fe:	c701                	beqz	a4,80002206 <wait+0xee>
    80002200:	02892783          	lw	a5,40(s2)
    80002204:	c79d                	beqz	a5,80002232 <wait+0x11a>
      release(&wait_lock);
    80002206:	0000f517          	auipc	a0,0xf
    8000220a:	0b250513          	addi	a0,a0,178 # 800112b8 <wait_lock>
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	a8a080e7          	jalr	-1398(ra) # 80000c98 <release>
      return -1;
    80002216:	59fd                	li	s3,-1
}
    80002218:	854e                	mv	a0,s3
    8000221a:	60a6                	ld	ra,72(sp)
    8000221c:	6406                	ld	s0,64(sp)
    8000221e:	74e2                	ld	s1,56(sp)
    80002220:	7942                	ld	s2,48(sp)
    80002222:	79a2                	ld	s3,40(sp)
    80002224:	7a02                	ld	s4,32(sp)
    80002226:	6ae2                	ld	s5,24(sp)
    80002228:	6b42                	ld	s6,16(sp)
    8000222a:	6ba2                	ld	s7,8(sp)
    8000222c:	6c02                	ld	s8,0(sp)
    8000222e:	6161                	addi	sp,sp,80
    80002230:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002232:	85e2                	mv	a1,s8
    80002234:	854a                	mv	a0,s2
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	e7e080e7          	jalr	-386(ra) # 800020b4 <sleep>
    havekids = 0;
    8000223e:	b715                	j	80002162 <wait+0x4a>

0000000080002240 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002240:	7139                	addi	sp,sp,-64
    80002242:	fc06                	sd	ra,56(sp)
    80002244:	f822                	sd	s0,48(sp)
    80002246:	f426                	sd	s1,40(sp)
    80002248:	f04a                	sd	s2,32(sp)
    8000224a:	ec4e                	sd	s3,24(sp)
    8000224c:	e852                	sd	s4,16(sp)
    8000224e:	e456                	sd	s5,8(sp)
    80002250:	0080                	addi	s0,sp,64
    80002252:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002254:	0000f497          	auipc	s1,0xf
    80002258:	47c48493          	addi	s1,s1,1148 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000225c:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000225e:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002260:	00016917          	auipc	s2,0x16
    80002264:	07090913          	addi	s2,s2,112 # 800182d0 <mlfq>
    80002268:	a821                	j	80002280 <wakeup+0x40>
        p->state = RUNNABLE;
    8000226a:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000226e:	8526                	mv	a0,s1
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	a28080e7          	jalr	-1496(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002278:	1b048493          	addi	s1,s1,432
    8000227c:	03248463          	beq	s1,s2,800022a4 <wakeup+0x64>
    if (p != myproc())
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	754080e7          	jalr	1876(ra) # 800019d4 <myproc>
    80002288:	fea488e3          	beq	s1,a0,80002278 <wakeup+0x38>
      acquire(&p->lock);
    8000228c:	8526                	mv	a0,s1
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	956080e7          	jalr	-1706(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002296:	4c9c                	lw	a5,24(s1)
    80002298:	fd379be3          	bne	a5,s3,8000226e <wakeup+0x2e>
    8000229c:	709c                	ld	a5,32(s1)
    8000229e:	fd4798e3          	bne	a5,s4,8000226e <wakeup+0x2e>
    800022a2:	b7e1                	j	8000226a <wakeup+0x2a>
    }
  }
}
    800022a4:	70e2                	ld	ra,56(sp)
    800022a6:	7442                	ld	s0,48(sp)
    800022a8:	74a2                	ld	s1,40(sp)
    800022aa:	7902                	ld	s2,32(sp)
    800022ac:	69e2                	ld	s3,24(sp)
    800022ae:	6a42                	ld	s4,16(sp)
    800022b0:	6aa2                	ld	s5,8(sp)
    800022b2:	6121                	addi	sp,sp,64
    800022b4:	8082                	ret

00000000800022b6 <reparent>:
{
    800022b6:	7179                	addi	sp,sp,-48
    800022b8:	f406                	sd	ra,40(sp)
    800022ba:	f022                	sd	s0,32(sp)
    800022bc:	ec26                	sd	s1,24(sp)
    800022be:	e84a                	sd	s2,16(sp)
    800022c0:	e44e                	sd	s3,8(sp)
    800022c2:	e052                	sd	s4,0(sp)
    800022c4:	1800                	addi	s0,sp,48
    800022c6:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022c8:	0000f497          	auipc	s1,0xf
    800022cc:	40848493          	addi	s1,s1,1032 # 800116d0 <proc>
      pp->parent = initproc;
    800022d0:	00007a17          	auipc	s4,0x7
    800022d4:	d58a0a13          	addi	s4,s4,-680 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022d8:	00016997          	auipc	s3,0x16
    800022dc:	ff898993          	addi	s3,s3,-8 # 800182d0 <mlfq>
    800022e0:	a029                	j	800022ea <reparent+0x34>
    800022e2:	1b048493          	addi	s1,s1,432
    800022e6:	01348d63          	beq	s1,s3,80002300 <reparent+0x4a>
    if (pp->parent == p)
    800022ea:	7c9c                	ld	a5,56(s1)
    800022ec:	ff279be3          	bne	a5,s2,800022e2 <reparent+0x2c>
      pp->parent = initproc;
    800022f0:	000a3503          	ld	a0,0(s4)
    800022f4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	f4a080e7          	jalr	-182(ra) # 80002240 <wakeup>
    800022fe:	b7d5                	j	800022e2 <reparent+0x2c>
}
    80002300:	70a2                	ld	ra,40(sp)
    80002302:	7402                	ld	s0,32(sp)
    80002304:	64e2                	ld	s1,24(sp)
    80002306:	6942                	ld	s2,16(sp)
    80002308:	69a2                	ld	s3,8(sp)
    8000230a:	6a02                	ld	s4,0(sp)
    8000230c:	6145                	addi	sp,sp,48
    8000230e:	8082                	ret

0000000080002310 <exit>:
{
    80002310:	7179                	addi	sp,sp,-48
    80002312:	f406                	sd	ra,40(sp)
    80002314:	f022                	sd	s0,32(sp)
    80002316:	ec26                	sd	s1,24(sp)
    80002318:	e84a                	sd	s2,16(sp)
    8000231a:	e44e                	sd	s3,8(sp)
    8000231c:	e052                	sd	s4,0(sp)
    8000231e:	1800                	addi	s0,sp,48
    80002320:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	6b2080e7          	jalr	1714(ra) # 800019d4 <myproc>
    8000232a:	89aa                	mv	s3,a0
  if (p == initproc)
    8000232c:	00007797          	auipc	a5,0x7
    80002330:	cfc7b783          	ld	a5,-772(a5) # 80009028 <initproc>
    80002334:	0d050493          	addi	s1,a0,208
    80002338:	15050913          	addi	s2,a0,336
    8000233c:	02a79363          	bne	a5,a0,80002362 <exit+0x52>
    panic("init exiting");
    80002340:	00006517          	auipc	a0,0x6
    80002344:	f2050513          	addi	a0,a0,-224 # 80008260 <digits+0x220>
    80002348:	ffffe097          	auipc	ra,0xffffe
    8000234c:	1f6080e7          	jalr	502(ra) # 8000053e <panic>
      fileclose(f);
    80002350:	00003097          	auipc	ra,0x3
    80002354:	938080e7          	jalr	-1736(ra) # 80004c88 <fileclose>
      p->ofile[fd] = 0;
    80002358:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000235c:	04a1                	addi	s1,s1,8
    8000235e:	01248563          	beq	s1,s2,80002368 <exit+0x58>
    if (p->ofile[fd])
    80002362:	6088                	ld	a0,0(s1)
    80002364:	f575                	bnez	a0,80002350 <exit+0x40>
    80002366:	bfdd                	j	8000235c <exit+0x4c>
  begin_op();
    80002368:	00002097          	auipc	ra,0x2
    8000236c:	454080e7          	jalr	1108(ra) # 800047bc <begin_op>
  iput(p->cwd);
    80002370:	1509b503          	ld	a0,336(s3)
    80002374:	00002097          	auipc	ra,0x2
    80002378:	c30080e7          	jalr	-976(ra) # 80003fa4 <iput>
  end_op();
    8000237c:	00002097          	auipc	ra,0x2
    80002380:	4c0080e7          	jalr	1216(ra) # 8000483c <end_op>
  p->cwd = 0;
    80002384:	1409b823          	sd	zero,336(s3)
  p->end_time = ticks;
    80002388:	00007797          	auipc	a5,0x7
    8000238c:	ca87a783          	lw	a5,-856(a5) # 80009030 <ticks>
    80002390:	16f9a623          	sw	a5,364(s3)
  acquire(&wait_lock);
    80002394:	0000f497          	auipc	s1,0xf
    80002398:	f2448493          	addi	s1,s1,-220 # 800112b8 <wait_lock>
    8000239c:	8526                	mv	a0,s1
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	846080e7          	jalr	-1978(ra) # 80000be4 <acquire>
  reparent(p);
    800023a6:	854e                	mv	a0,s3
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	f0e080e7          	jalr	-242(ra) # 800022b6 <reparent>
  wakeup(p->parent);
    800023b0:	0389b503          	ld	a0,56(s3)
    800023b4:	00000097          	auipc	ra,0x0
    800023b8:	e8c080e7          	jalr	-372(ra) # 80002240 <wakeup>
  acquire(&p->lock);
    800023bc:	854e                	mv	a0,s3
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	826080e7          	jalr	-2010(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023c6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023ca:	4795                	li	a5,5
    800023cc:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8c6080e7          	jalr	-1850(ra) # 80000c98 <release>
  sched();
    800023da:	00000097          	auipc	ra,0x0
    800023de:	bc8080e7          	jalr	-1080(ra) # 80001fa2 <sched>
  panic("zombie exit");
    800023e2:	00006517          	auipc	a0,0x6
    800023e6:	e8e50513          	addi	a0,a0,-370 # 80008270 <digits+0x230>
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	154080e7          	jalr	340(ra) # 8000053e <panic>

00000000800023f2 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800023f2:	7179                	addi	sp,sp,-48
    800023f4:	f406                	sd	ra,40(sp)
    800023f6:	f022                	sd	s0,32(sp)
    800023f8:	ec26                	sd	s1,24(sp)
    800023fa:	e84a                	sd	s2,16(sp)
    800023fc:	e44e                	sd	s3,8(sp)
    800023fe:	1800                	addi	s0,sp,48
    80002400:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002402:	0000f497          	auipc	s1,0xf
    80002406:	2ce48493          	addi	s1,s1,718 # 800116d0 <proc>
    8000240a:	00016997          	auipc	s3,0x16
    8000240e:	ec698993          	addi	s3,s3,-314 # 800182d0 <mlfq>
  {
    acquire(&p->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	ffffe097          	auipc	ra,0xffffe
    80002418:	7d0080e7          	jalr	2000(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    8000241c:	589c                	lw	a5,48(s1)
    8000241e:	01278d63          	beq	a5,s2,80002438 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002422:	8526                	mv	a0,s1
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	874080e7          	jalr	-1932(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000242c:	1b048493          	addi	s1,s1,432
    80002430:	ff3491e3          	bne	s1,s3,80002412 <kill+0x20>
  }
  return -1;
    80002434:	557d                	li	a0,-1
    80002436:	a829                	j	80002450 <kill+0x5e>
      p->killed = 1;
    80002438:	4785                	li	a5,1
    8000243a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000243c:	4c98                	lw	a4,24(s1)
    8000243e:	4789                	li	a5,2
    80002440:	00f70f63          	beq	a4,a5,8000245e <kill+0x6c>
      release(&p->lock);
    80002444:	8526                	mv	a0,s1
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	852080e7          	jalr	-1966(ra) # 80000c98 <release>
      return 0;
    8000244e:	4501                	li	a0,0
}
    80002450:	70a2                	ld	ra,40(sp)
    80002452:	7402                	ld	s0,32(sp)
    80002454:	64e2                	ld	s1,24(sp)
    80002456:	6942                	ld	s2,16(sp)
    80002458:	69a2                	ld	s3,8(sp)
    8000245a:	6145                	addi	sp,sp,48
    8000245c:	8082                	ret
        p->state = RUNNABLE;
    8000245e:	478d                	li	a5,3
    80002460:	cc9c                	sw	a5,24(s1)
    80002462:	b7cd                	j	80002444 <kill+0x52>

0000000080002464 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002464:	7179                	addi	sp,sp,-48
    80002466:	f406                	sd	ra,40(sp)
    80002468:	f022                	sd	s0,32(sp)
    8000246a:	ec26                	sd	s1,24(sp)
    8000246c:	e84a                	sd	s2,16(sp)
    8000246e:	e44e                	sd	s3,8(sp)
    80002470:	e052                	sd	s4,0(sp)
    80002472:	1800                	addi	s0,sp,48
    80002474:	84aa                	mv	s1,a0
    80002476:	892e                	mv	s2,a1
    80002478:	89b2                	mv	s3,a2
    8000247a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	558080e7          	jalr	1368(ra) # 800019d4 <myproc>
  if (user_dst)
    80002484:	c08d                	beqz	s1,800024a6 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002486:	86d2                	mv	a3,s4
    80002488:	864e                	mv	a2,s3
    8000248a:	85ca                	mv	a1,s2
    8000248c:	6928                	ld	a0,80(a0)
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	1e4080e7          	jalr	484(ra) # 80001672 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002496:	70a2                	ld	ra,40(sp)
    80002498:	7402                	ld	s0,32(sp)
    8000249a:	64e2                	ld	s1,24(sp)
    8000249c:	6942                	ld	s2,16(sp)
    8000249e:	69a2                	ld	s3,8(sp)
    800024a0:	6a02                	ld	s4,0(sp)
    800024a2:	6145                	addi	sp,sp,48
    800024a4:	8082                	ret
    memmove((char *)dst, src, len);
    800024a6:	000a061b          	sext.w	a2,s4
    800024aa:	85ce                	mv	a1,s3
    800024ac:	854a                	mv	a0,s2
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	892080e7          	jalr	-1902(ra) # 80000d40 <memmove>
    return 0;
    800024b6:	8526                	mv	a0,s1
    800024b8:	bff9                	j	80002496 <either_copyout+0x32>

00000000800024ba <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024ba:	7179                	addi	sp,sp,-48
    800024bc:	f406                	sd	ra,40(sp)
    800024be:	f022                	sd	s0,32(sp)
    800024c0:	ec26                	sd	s1,24(sp)
    800024c2:	e84a                	sd	s2,16(sp)
    800024c4:	e44e                	sd	s3,8(sp)
    800024c6:	e052                	sd	s4,0(sp)
    800024c8:	1800                	addi	s0,sp,48
    800024ca:	892a                	mv	s2,a0
    800024cc:	84ae                	mv	s1,a1
    800024ce:	89b2                	mv	s3,a2
    800024d0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	502080e7          	jalr	1282(ra) # 800019d4 <myproc>
  if (user_src)
    800024da:	c08d                	beqz	s1,800024fc <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800024dc:	86d2                	mv	a3,s4
    800024de:	864e                	mv	a2,s3
    800024e0:	85ca                	mv	a1,s2
    800024e2:	6928                	ld	a0,80(a0)
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	21a080e7          	jalr	538(ra) # 800016fe <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800024ec:	70a2                	ld	ra,40(sp)
    800024ee:	7402                	ld	s0,32(sp)
    800024f0:	64e2                	ld	s1,24(sp)
    800024f2:	6942                	ld	s2,16(sp)
    800024f4:	69a2                	ld	s3,8(sp)
    800024f6:	6a02                	ld	s4,0(sp)
    800024f8:	6145                	addi	sp,sp,48
    800024fa:	8082                	ret
    memmove(dst, (char *)src, len);
    800024fc:	000a061b          	sext.w	a2,s4
    80002500:	85ce                	mv	a1,s3
    80002502:	854a                	mv	a0,s2
    80002504:	fffff097          	auipc	ra,0xfffff
    80002508:	83c080e7          	jalr	-1988(ra) # 80000d40 <memmove>
    return 0;
    8000250c:	8526                	mv	a0,s1
    8000250e:	bff9                	j	800024ec <either_copyin+0x32>

0000000080002510 <procdump>:
//     printf("\n");
//   }
// }

void procdump(void)
{
    80002510:	715d                	addi	sp,sp,-80
    80002512:	e486                	sd	ra,72(sp)
    80002514:	e0a2                	sd	s0,64(sp)
    80002516:	fc26                	sd	s1,56(sp)
    80002518:	f84a                	sd	s2,48(sp)
    8000251a:	f44e                	sd	s3,40(sp)
    8000251c:	f052                	sd	s4,32(sp)
    8000251e:	ec56                	sd	s5,24(sp)
    80002520:	e85a                	sd	s6,16(sp)
    80002522:	e45e                	sd	s7,8(sp)
    80002524:	0880                	addi	s0,sp,80
      [RUNNING] "running",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *status;

  printf("\n");
    80002526:	00006517          	auipc	a0,0x6
    8000252a:	ba250513          	addi	a0,a0,-1118 # 800080c8 <digits+0x88>
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	05a080e7          	jalr	90(ra) # 80000588 <printf>

#ifdef PBS
  printf("PID   Priority\tState\t  rtime\t wtime\tnrun\n");
#endif

  for (p = proc; p < &proc[NPROC]; p++)
    80002536:	0000f497          	auipc	s1,0xf
    8000253a:	2f248493          	addi	s1,s1,754 # 80011828 <proc+0x158>
    8000253e:	00016917          	auipc	s2,0x16
    80002542:	eea90913          	addi	s2,s2,-278 # 80018428 <mlfq+0x158>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(all_states) && all_states[p->state])
    80002546:	4b15                	li	s6,5
      status = all_states[p->state];
    else
      status = "???";
    80002548:	00006997          	auipc	s3,0x6
    8000254c:	d3898993          	addi	s3,s3,-712 # 80008280 <digits+0x240>

    printf("%d\t%d\t%s    %d\t  %d\t%d", p->pid, p->static_priority, status, p->runtime, time, p->num_sched);

#else

    printf("%d %s %s", p->pid, status, p->name);
    80002550:	00006a97          	auipc	s5,0x6
    80002554:	d38a8a93          	addi	s5,s5,-712 # 80008288 <digits+0x248>

#endif
    printf("\n");
    80002558:	00006a17          	auipc	s4,0x6
    8000255c:	b70a0a13          	addi	s4,s4,-1168 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(all_states) && all_states[p->state])
    80002560:	00006b97          	auipc	s7,0x6
    80002564:	d88b8b93          	addi	s7,s7,-632 # 800082e8 <all_states.1776>
    80002568:	a00d                	j	8000258a <procdump+0x7a>
    printf("%d %s %s", p->pid, status, p->name);
    8000256a:	ed86a583          	lw	a1,-296(a3)
    8000256e:	8556                	mv	a0,s5
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	018080e7          	jalr	24(ra) # 80000588 <printf>
    printf("\n");
    80002578:	8552                	mv	a0,s4
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	00e080e7          	jalr	14(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002582:	1b048493          	addi	s1,s1,432
    80002586:	03248163          	beq	s1,s2,800025a8 <procdump+0x98>
    if (p->state == UNUSED)
    8000258a:	86a6                	mv	a3,s1
    8000258c:	ec04a783          	lw	a5,-320(s1)
    80002590:	dbed                	beqz	a5,80002582 <procdump+0x72>
      status = "???";
    80002592:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(all_states) && all_states[p->state])
    80002594:	fcfb6be3          	bltu	s6,a5,8000256a <procdump+0x5a>
    80002598:	1782                	slli	a5,a5,0x20
    8000259a:	9381                	srli	a5,a5,0x20
    8000259c:	078e                	slli	a5,a5,0x3
    8000259e:	97de                	add	a5,a5,s7
    800025a0:	6390                	ld	a2,0(a5)
    800025a2:	f661                	bnez	a2,8000256a <procdump+0x5a>
      status = "???";
    800025a4:	864e                	mv	a2,s3
    800025a6:	b7d1                	j	8000256a <procdump+0x5a>
  }
}
    800025a8:	60a6                	ld	ra,72(sp)
    800025aa:	6406                	ld	s0,64(sp)
    800025ac:	74e2                	ld	s1,56(sp)
    800025ae:	7942                	ld	s2,48(sp)
    800025b0:	79a2                	ld	s3,40(sp)
    800025b2:	7a02                	ld	s4,32(sp)
    800025b4:	6ae2                	ld	s5,24(sp)
    800025b6:	6b42                	ld	s6,16(sp)
    800025b8:	6ba2                	ld	s7,8(sp)
    800025ba:	6161                	addi	sp,sp,80
    800025bc:	8082                	ret

00000000800025be <push_elem>:
}

void push_elem(queue *q, struct proc *elem)
{
  int capacity = NPROC;
  if (q->q_size == capacity)
    800025be:	4114                	lw	a3,0(a0)
    800025c0:	04000793          	li	a5,64
    800025c4:	02f68363          	beq	a3,a5,800025ea <push_elem+0x2c>
  {
    panic("queue is full");
  }
  q->elem_array[q->q_tail] = elem;
    800025c8:	4518                	lw	a4,8(a0)
    800025ca:	00270793          	addi	a5,a4,2
    800025ce:	078e                	slli	a5,a5,0x3
    800025d0:	97aa                	add	a5,a5,a0
    800025d2:	e38c                	sd	a1,0(a5)
  q->q_tail++;
    800025d4:	2705                	addiw	a4,a4,1
    800025d6:	0007061b          	sext.w	a2,a4
  if (q->q_tail == capacity + 1)
    800025da:	04100793          	li	a5,65
    800025de:	02f60263          	beq	a2,a5,80002602 <push_elem+0x44>
  q->q_tail++;
    800025e2:	c518                	sw	a4,8(a0)
  {
    q->q_tail = 0;
  }
  q->q_size++;
    800025e4:	2685                	addiw	a3,a3,1
    800025e6:	c114                	sw	a3,0(a0)
    800025e8:	8082                	ret
{
    800025ea:	1141                	addi	sp,sp,-16
    800025ec:	e406                	sd	ra,8(sp)
    800025ee:	e022                	sd	s0,0(sp)
    800025f0:	0800                	addi	s0,sp,16
    panic("queue is full");
    800025f2:	00006517          	auipc	a0,0x6
    800025f6:	ca650513          	addi	a0,a0,-858 # 80008298 <digits+0x258>
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	f44080e7          	jalr	-188(ra) # 8000053e <panic>
    q->q_tail = 0;
    80002602:	00052423          	sw	zero,8(a0)
    80002606:	bff9                	j	800025e4 <push_elem+0x26>

0000000080002608 <pop_elem>:
}

void pop_elem(queue *q)
{
  int capacity = NPROC;
  if (q->q_size == 0)
    80002608:	411c                	lw	a5,0(a0)
    8000260a:	cf89                	beqz	a5,80002624 <pop_elem+0x1c>
  {
    panic("queue is empty");
  }
  q->q_head++;
    8000260c:	4158                	lw	a4,4(a0)
    8000260e:	2705                	addiw	a4,a4,1
    80002610:	0007061b          	sext.w	a2,a4
  if (q->q_head == capacity + 1)
    80002614:	04100693          	li	a3,65
    80002618:	02d60263          	beq	a2,a3,8000263c <pop_elem+0x34>
  q->q_head++;
    8000261c:	c158                	sw	a4,4(a0)
  {
    q->q_head = 0;
  }
  q->q_size--;
    8000261e:	37fd                	addiw	a5,a5,-1
    80002620:	c11c                	sw	a5,0(a0)
    80002622:	8082                	ret
{
    80002624:	1141                	addi	sp,sp,-16
    80002626:	e406                	sd	ra,8(sp)
    80002628:	e022                	sd	s0,0(sp)
    8000262a:	0800                	addi	s0,sp,16
    panic("queue is empty");
    8000262c:	00006517          	auipc	a0,0x6
    80002630:	c7c50513          	addi	a0,a0,-900 # 800082a8 <digits+0x268>
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	f0a080e7          	jalr	-246(ra) # 8000053e <panic>
    q->q_head = 0;
    8000263c:	00052223          	sw	zero,4(a0)
    80002640:	bff9                	j	8000261e <pop_elem+0x16>

0000000080002642 <front>:
}

struct proc *front(queue *q)
{
  if (q->q_size == 0)
    80002642:	411c                	lw	a5,0(a0)
    80002644:	cb91                	beqz	a5,80002658 <front+0x16>
  {
    panic("queue is empty");
  }
  if (q->q_head == q->q_tail)
    80002646:	415c                	lw	a5,4(a0)
    80002648:	4518                	lw	a4,8(a0)
    8000264a:	02f70363          	beq	a4,a5,80002670 <front+0x2e>
  {
    return 0;
  }
  return q->elem_array[q->q_head];
    8000264e:	0789                	addi	a5,a5,2
    80002650:	078e                	slli	a5,a5,0x3
    80002652:	953e                	add	a0,a0,a5
    80002654:	6108                	ld	a0,0(a0)
    80002656:	8082                	ret
{
    80002658:	1141                	addi	sp,sp,-16
    8000265a:	e406                	sd	ra,8(sp)
    8000265c:	e022                	sd	s0,0(sp)
    8000265e:	0800                	addi	s0,sp,16
    panic("queue is empty");
    80002660:	00006517          	auipc	a0,0x6
    80002664:	c4850513          	addi	a0,a0,-952 # 800082a8 <digits+0x268>
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	ed6080e7          	jalr	-298(ra) # 8000053e <panic>
    return 0;
    80002670:	4501                	li	a0,0
}
    80002672:	8082                	ret

0000000080002674 <erase>:

void erase(queue *q, int pid)
{
    80002674:	1141                	addi	sp,sp,-16
    80002676:	e422                	sd	s0,8(sp)
    80002678:	0800                	addi	s0,sp,16
  int capacity = NPROC;
  for (int elem = q->q_head; elem != q->q_tail; elem = (elem + 1) % (capacity + 1))
    8000267a:	415c                	lw	a5,4(a0)
    8000267c:	00852803          	lw	a6,8(a0)
    80002680:	03078d63          	beq	a5,a6,800026ba <erase+0x46>
  {
    if (q->elem_array[elem]->pid == pid)
    {
      struct proc *temp_elem = q->elem_array[elem];
      q->elem_array[elem] = q->elem_array[(elem + 1) % (capacity + 1)];
    80002684:	04100893          	li	a7,65
    80002688:	a031                	j	80002694 <erase+0x20>
  for (int elem = q->q_head; elem != q->q_tail; elem = (elem + 1) % (capacity + 1))
    8000268a:	2785                	addiw	a5,a5,1
    8000268c:	0317e7bb          	remw	a5,a5,a7
    80002690:	03078563          	beq	a5,a6,800026ba <erase+0x46>
    if (q->elem_array[elem]->pid == pid)
    80002694:	00379713          	slli	a4,a5,0x3
    80002698:	972a                	add	a4,a4,a0
    8000269a:	6b10                	ld	a2,16(a4)
    8000269c:	5a14                	lw	a3,48(a2)
    8000269e:	feb696e3          	bne	a3,a1,8000268a <erase+0x16>
      q->elem_array[elem] = q->elem_array[(elem + 1) % (capacity + 1)];
    800026a2:	0017869b          	addiw	a3,a5,1
    800026a6:	0316e6bb          	remw	a3,a3,a7
    800026aa:	068e                	slli	a3,a3,0x3
    800026ac:	96aa                	add	a3,a3,a0
    800026ae:	0106b303          	ld	t1,16(a3)
    800026b2:	00673823          	sd	t1,16(a4)
      q->elem_array[(elem + 1) % (capacity + 1)] = temp_elem;
    800026b6:	ea90                	sd	a2,16(a3)
    800026b8:	bfc9                	j	8000268a <erase+0x16>
    }
  }
  q->q_tail--;
    800026ba:	387d                	addiw	a6,a6,-1
    800026bc:	01052423          	sw	a6,8(a0)
  q->q_size--;
    800026c0:	411c                	lw	a5,0(a0)
    800026c2:	37fd                	addiw	a5,a5,-1
    800026c4:	c11c                	sw	a5,0(a0)
  if (q->q_tail < 0)
    800026c6:	02081793          	slli	a5,a6,0x20
    800026ca:	0007c563          	bltz	a5,800026d4 <erase+0x60>
  {
    q->q_tail = capacity;
  }
}
    800026ce:	6422                	ld	s0,8(sp)
    800026d0:	0141                	addi	sp,sp,16
    800026d2:	8082                	ret
    q->q_tail = capacity;
    800026d4:	04000793          	li	a5,64
    800026d8:	c51c                	sw	a5,8(a0)
}
    800026da:	bfd5                	j	800026ce <erase+0x5a>

00000000800026dc <aging_func>:
{
    800026dc:	7139                	addi	sp,sp,-64
    800026de:	fc06                	sd	ra,56(sp)
    800026e0:	f822                	sd	s0,48(sp)
    800026e2:	f426                	sd	s1,40(sp)
    800026e4:	f04a                	sd	s2,32(sp)
    800026e6:	ec4e                	sd	s3,24(sp)
    800026e8:	e852                	sd	s4,16(sp)
    800026ea:	e456                	sd	s5,8(sp)
    800026ec:	e05a                	sd	s6,0(sp)
    800026ee:	0080                	addi	s0,sp,64
  for (p = proc; p < &proc[NPROC]; p++)
    800026f0:	0000f497          	auipc	s1,0xf
    800026f4:	fe048493          	addi	s1,s1,-32 # 800116d0 <proc>
    if (p->state == RUNNABLE && p->enter_q <= ticks - AGETICK)
    800026f8:	498d                	li	s3,3
    800026fa:	00007a17          	auipc	s4,0x7
    800026fe:	936a0a13          	addi	s4,s4,-1738 # 80009030 <ticks>
        erase(&mlfq[p->level], p->pid);
    80002702:	21800b13          	li	s6,536
    80002706:	00016a97          	auipc	s5,0x16
    8000270a:	bcaa8a93          	addi	s5,s5,-1078 # 800182d0 <mlfq>
  for (p = proc; p < &proc[NPROC]; p++)
    8000270e:	00016917          	auipc	s2,0x16
    80002712:	bc290913          	addi	s2,s2,-1086 # 800182d0 <mlfq>
    80002716:	a81d                	j	8000274c <aging_func+0x70>
        erase(&mlfq[p->level], p->pid);
    80002718:	1884a503          	lw	a0,392(s1)
    8000271c:	03650533          	mul	a0,a0,s6
    80002720:	588c                	lw	a1,48(s1)
    80002722:	9556                	add	a0,a0,s5
    80002724:	00000097          	auipc	ra,0x0
    80002728:	f50080e7          	jalr	-176(ra) # 80002674 <erase>
        p->curr_q = 0;
    8000272c:	1804a023          	sw	zero,384(s1)
    80002730:	a089                	j	80002772 <aging_func+0x96>
      p->enter_q = ticks;
    80002732:	000a2783          	lw	a5,0(s4)
    80002736:	18f4a823          	sw	a5,400(s1)
    release(&p->lock);
    8000273a:	8526                	mv	a0,s1
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	55c080e7          	jalr	1372(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002744:	1b048493          	addi	s1,s1,432
    80002748:	03248c63          	beq	s1,s2,80002780 <aging_func+0xa4>
    acquire(&p->lock);
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	496080e7          	jalr	1174(ra) # 80000be4 <acquire>
    if (p->state == RUNNABLE && p->enter_q <= ticks - AGETICK)
    80002756:	4c9c                	lw	a5,24(s1)
    80002758:	ff3791e3          	bne	a5,s3,8000273a <aging_func+0x5e>
    8000275c:	000a2783          	lw	a5,0(s4)
    80002760:	1904a703          	lw	a4,400(s1)
    80002764:	f807879b          	addiw	a5,a5,-128
    80002768:	fce7e9e3          	bltu	a5,a4,8000273a <aging_func+0x5e>
      if (p->curr_q)
    8000276c:	1804a783          	lw	a5,384(s1)
    80002770:	f7c5                	bnez	a5,80002718 <aging_func+0x3c>
      if (p->level != 0)
    80002772:	1884a783          	lw	a5,392(s1)
    80002776:	dfd5                	beqz	a5,80002732 <aging_func+0x56>
        p->level--;
    80002778:	37fd                	addiw	a5,a5,-1
    8000277a:	18f4a423          	sw	a5,392(s1)
    8000277e:	bf55                	j	80002732 <aging_func+0x56>
}
    80002780:	70e2                	ld	ra,56(sp)
    80002782:	7442                	ld	s0,48(sp)
    80002784:	74a2                	ld	s1,40(sp)
    80002786:	7902                	ld	s2,32(sp)
    80002788:	69e2                	ld	s3,24(sp)
    8000278a:	6a42                	ld	s4,16(sp)
    8000278c:	6aa2                	ld	s5,8(sp)
    8000278e:	6b02                	ld	s6,0(sp)
    80002790:	6121                	addi	sp,sp,64
    80002792:	8082                	ret

0000000080002794 <scheduler>:
{
    80002794:	711d                	addi	sp,sp,-96
    80002796:	ec86                	sd	ra,88(sp)
    80002798:	e8a2                	sd	s0,80(sp)
    8000279a:	e4a6                	sd	s1,72(sp)
    8000279c:	e0ca                	sd	s2,64(sp)
    8000279e:	fc4e                	sd	s3,56(sp)
    800027a0:	f852                	sd	s4,48(sp)
    800027a2:	f456                	sd	s5,40(sp)
    800027a4:	f05a                	sd	s6,32(sp)
    800027a6:	ec5e                	sd	s7,24(sp)
    800027a8:	e862                	sd	s8,16(sp)
    800027aa:	e466                	sd	s9,8(sp)
    800027ac:	e06a                	sd	s10,0(sp)
    800027ae:	1080                	addi	s0,sp,96
    800027b0:	8792                	mv	a5,tp
  int id = r_tp();
    800027b2:	2781                	sext.w	a5,a5
  c->proc = 0;
    800027b4:	00779b93          	slli	s7,a5,0x7
    800027b8:	0000f717          	auipc	a4,0xf
    800027bc:	ae870713          	addi	a4,a4,-1304 # 800112a0 <pid_lock>
    800027c0:	975e                	add	a4,a4,s7
    800027c2:	02073823          	sd	zero,48(a4)
    swtch(&c->context, &ans->context);
    800027c6:	0000f717          	auipc	a4,0xf
    800027ca:	b1270713          	addi	a4,a4,-1262 # 800112d8 <cpus+0x8>
    800027ce:	9bba                	add	s7,s7,a4
      if (p->state == RUNNABLE && p->curr_q == 0)
    800027d0:	490d                	li	s2,3
        push_elem(&mlfq[p->level], p);
    800027d2:	00016a97          	auipc	s5,0x16
    800027d6:	afea8a93          	addi	s5,s5,-1282 # 800182d0 <mlfq>
        p->curr_q = 1;
    800027da:	4a05                	li	s4,1
    c->proc = ans;
    800027dc:	079e                	slli	a5,a5,0x7
    800027de:	0000fb17          	auipc	s6,0xf
    800027e2:	ac2b0b13          	addi	s6,s6,-1342 # 800112a0 <pid_lock>
    800027e6:	9b3e                	add	s6,s6,a5
    800027e8:	a205                	j	80002908 <scheduler+0x174>
        push_elem(&mlfq[p->level], p);
    800027ea:	1884a503          	lw	a0,392(s1)
    800027ee:	03850533          	mul	a0,a0,s8
    800027f2:	85a6                	mv	a1,s1
    800027f4:	9556                	add	a0,a0,s5
    800027f6:	00000097          	auipc	ra,0x0
    800027fa:	dc8080e7          	jalr	-568(ra) # 800025be <push_elem>
        p->curr_q = 1;
    800027fe:	1944a023          	sw	s4,384(s1)
      release(&p->lock);
    80002802:	8526                	mv	a0,s1
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	494080e7          	jalr	1172(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000280c:	1b048493          	addi	s1,s1,432
    80002810:	01348e63          	beq	s1,s3,8000282c <scheduler+0x98>
      acquire(&p->lock);
    80002814:	8526                	mv	a0,s1
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	3ce080e7          	jalr	974(ra) # 80000be4 <acquire>
      if (p->state == RUNNABLE && p->curr_q == 0)
    8000281e:	4c9c                	lw	a5,24(s1)
    80002820:	ff2791e3          	bne	a5,s2,80002802 <scheduler+0x6e>
    80002824:	1804a783          	lw	a5,384(s1)
    80002828:	ffe9                	bnez	a5,80002802 <scheduler+0x6e>
    8000282a:	b7c1                	j	800027ea <scheduler+0x56>
    8000282c:	00016c17          	auipc	s8,0x16
    80002830:	aa4c0c13          	addi	s8,s8,-1372 # 800182d0 <mlfq>
    80002834:	00016c97          	auipc	s9,0x16
    80002838:	514c8c93          	addi	s9,s9,1300 # 80018d48 <tickslock>
      while (mlfq[lev].q_size > 0)
    8000283c:	89e2                	mv	s3,s8
    8000283e:	000c2783          	lw	a5,0(s8)
    80002842:	04f05063          	blez	a5,80002882 <scheduler+0xee>
        struct proc *p = front(&mlfq[lev]);
    80002846:	854e                	mv	a0,s3
    80002848:	00000097          	auipc	ra,0x0
    8000284c:	dfa080e7          	jalr	-518(ra) # 80002642 <front>
    80002850:	84aa                	mv	s1,a0
        pop_elem(&mlfq[lev]);
    80002852:	854e                	mv	a0,s3
    80002854:	00000097          	auipc	ra,0x0
    80002858:	db4080e7          	jalr	-588(ra) # 80002608 <pop_elem>
        acquire(&p->lock);
    8000285c:	8526                	mv	a0,s1
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	386080e7          	jalr	902(ra) # 80000be4 <acquire>
        p->curr_q = 0;
    80002866:	1804a023          	sw	zero,384(s1)
        if (p->state == RUNNABLE)
    8000286a:	4c9c                	lw	a5,24(s1)
    8000286c:	03278163          	beq	a5,s2,8000288e <scheduler+0xfa>
          release(&p->lock);
    80002870:	8526                	mv	a0,s1
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	426080e7          	jalr	1062(ra) # 80000c98 <release>
      while (mlfq[lev].q_size > 0)
    8000287a:	0009a783          	lw	a5,0(s3)
    8000287e:	fcf044e3          	bgtz	a5,80002846 <scheduler+0xb2>
    for (; lev < MAX_Q; lev++)
    80002882:	218c0c13          	addi	s8,s8,536
    80002886:	fb9c1be3          	bne	s8,s9,8000283c <scheduler+0xa8>
    8000288a:	4481                	li	s1,0
    8000288c:	a005                	j	800028ac <scheduler+0x118>
          acquire(&ans->lock);
    8000288e:	4501                	li	a0,0
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	354080e7          	jalr	852(ra) # 80000be4 <acquire>
          release(&p->lock);
    80002898:	8526                	mv	a0,s1
    8000289a:	ffffe097          	auipc	ra,0xffffe
    8000289e:	3fe080e7          	jalr	1022(ra) # 80000c98 <release>
          release(&ans->lock);
    800028a2:	8526                	mv	a0,s1
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	3f4080e7          	jalr	1012(ra) # 80000c98 <release>
    acquire(&ans->lock);
    800028ac:	8526                	mv	a0,s1
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	336080e7          	jalr	822(ra) # 80000be4 <acquire>
    ans->change_q = 1 << ans->level;
    800028b6:	1884a783          	lw	a5,392(s1)
    800028ba:	00fa17bb          	sllw	a5,s4,a5
    800028be:	18f4a223          	sw	a5,388(s1)
    ans->state = RUNNING;
    800028c2:	4791                	li	a5,4
    800028c4:	cc9c                	sw	a5,24(s1)
    ans->enter_q = ticks;
    800028c6:	00006997          	auipc	s3,0x6
    800028ca:	76a98993          	addi	s3,s3,1898 # 80009030 <ticks>
    800028ce:	0009a783          	lw	a5,0(s3)
    800028d2:	18f4a823          	sw	a5,400(s1)
    ans->num_sched++;
    800028d6:	18c4a783          	lw	a5,396(s1)
    800028da:	2785                	addiw	a5,a5,1
    800028dc:	18f4a623          	sw	a5,396(s1)
    c->proc = ans;
    800028e0:	029b3823          	sd	s1,48(s6)
    swtch(&c->context, &ans->context);
    800028e4:	06048593          	addi	a1,s1,96
    800028e8:	855e                	mv	a0,s7
    800028ea:	00000097          	auipc	ra,0x0
    800028ee:	27e080e7          	jalr	638(ra) # 80002b68 <swtch>
    c->proc = 0;
    800028f2:	020b3823          	sd	zero,48(s6)
    ans->enter_q = ticks;
    800028f6:	0009a783          	lw	a5,0(s3)
    800028fa:	18f4a823          	sw	a5,400(s1)
    release(&ans->lock);
    800028fe:	8526                	mv	a0,s1
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	398080e7          	jalr	920(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002908:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000290c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002910:	10079073          	csrw	sstatus,a5
    aging_func();
    80002914:	00000097          	auipc	ra,0x0
    80002918:	dc8080e7          	jalr	-568(ra) # 800026dc <aging_func>
    for (p = proc; p < &proc[NPROC]; p++)
    8000291c:	0000f497          	auipc	s1,0xf
    80002920:	db448493          	addi	s1,s1,-588 # 800116d0 <proc>
        push_elem(&mlfq[p->level], p);
    80002924:	21800c13          	li	s8,536
    for (p = proc; p < &proc[NPROC]; p++)
    80002928:	00016997          	auipc	s3,0x16
    8000292c:	9a898993          	addi	s3,s3,-1624 # 800182d0 <mlfq>
    80002930:	b5d5                	j	80002814 <scheduler+0x80>

0000000080002932 <waitx>:
// ************************

int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002932:	711d                	addi	sp,sp,-96
    80002934:	ec86                	sd	ra,88(sp)
    80002936:	e8a2                	sd	s0,80(sp)
    80002938:	e4a6                	sd	s1,72(sp)
    8000293a:	e0ca                	sd	s2,64(sp)
    8000293c:	fc4e                	sd	s3,56(sp)
    8000293e:	f852                	sd	s4,48(sp)
    80002940:	f456                	sd	s5,40(sp)
    80002942:	f05a                	sd	s6,32(sp)
    80002944:	ec5e                	sd	s7,24(sp)
    80002946:	e862                	sd	s8,16(sp)
    80002948:	e466                	sd	s9,8(sp)
    8000294a:	e06a                	sd	s10,0(sp)
    8000294c:	1080                	addi	s0,sp,96
    8000294e:	8b2a                	mv	s6,a0
    80002950:	8bae                	mv	s7,a1
    80002952:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002954:	fffff097          	auipc	ra,0xfffff
    80002958:	080080e7          	jalr	128(ra) # 800019d4 <myproc>
    8000295c:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000295e:	0000f517          	auipc	a0,0xf
    80002962:	95a50513          	addi	a0,a0,-1702 # 800112b8 <wait_lock>
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	27e080e7          	jalr	638(ra) # 80000be4 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000296e:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002970:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002972:	00016997          	auipc	s3,0x16
    80002976:	95e98993          	addi	s3,s3,-1698 # 800182d0 <mlfq>
        havekids = 1;
    8000297a:	4a85                	li	s5,1
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000297c:	0000fd17          	auipc	s10,0xf
    80002980:	93cd0d13          	addi	s10,s10,-1732 # 800112b8 <wait_lock>
    havekids = 0;
    80002984:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002986:	0000f497          	auipc	s1,0xf
    8000298a:	d4a48493          	addi	s1,s1,-694 # 800116d0 <proc>
    8000298e:	a059                	j	80002a14 <waitx+0xe2>
          pid = np->pid;
    80002990:	0304a983          	lw	s3,48(s1)
          *rtime = np->runtime;
    80002994:	1704a703          	lw	a4,368(s1)
    80002998:	00ec2023          	sw	a4,0(s8)
          *wtime = np->end_time - np->crt_time - np->runtime;
    8000299c:	1684a783          	lw	a5,360(s1)
    800029a0:	9f3d                	addw	a4,a4,a5
    800029a2:	16c4a783          	lw	a5,364(s1)
    800029a6:	9f99                	subw	a5,a5,a4
    800029a8:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate, sizeof(np->xstate)) < 0)
    800029ac:	000b0e63          	beqz	s6,800029c8 <waitx+0x96>
    800029b0:	4691                	li	a3,4
    800029b2:	02c48613          	addi	a2,s1,44
    800029b6:	85da                	mv	a1,s6
    800029b8:	05093503          	ld	a0,80(s2)
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	cb6080e7          	jalr	-842(ra) # 80001672 <copyout>
    800029c4:	02054563          	bltz	a0,800029ee <waitx+0xbc>
          freeproc(np);
    800029c8:	8526                	mv	a0,s1
    800029ca:	fffff097          	auipc	ra,0xfffff
    800029ce:	1bc080e7          	jalr	444(ra) # 80001b86 <freeproc>
          release(&np->lock);
    800029d2:	8526                	mv	a0,s1
    800029d4:	ffffe097          	auipc	ra,0xffffe
    800029d8:	2c4080e7          	jalr	708(ra) # 80000c98 <release>
          release(&wait_lock);
    800029dc:	0000f517          	auipc	a0,0xf
    800029e0:	8dc50513          	addi	a0,a0,-1828 # 800112b8 <wait_lock>
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	2b4080e7          	jalr	692(ra) # 80000c98 <release>
          return pid;
    800029ec:	a09d                	j	80002a52 <waitx+0x120>
            release(&np->lock);
    800029ee:	8526                	mv	a0,s1
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	2a8080e7          	jalr	680(ra) # 80000c98 <release>
            release(&wait_lock);
    800029f8:	0000f517          	auipc	a0,0xf
    800029fc:	8c050513          	addi	a0,a0,-1856 # 800112b8 <wait_lock>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	298080e7          	jalr	664(ra) # 80000c98 <release>
            return -1;
    80002a08:	59fd                	li	s3,-1
    80002a0a:	a0a1                	j	80002a52 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002a0c:	1b048493          	addi	s1,s1,432
    80002a10:	03348463          	beq	s1,s3,80002a38 <waitx+0x106>
      if (np->parent == p)
    80002a14:	7c9c                	ld	a5,56(s1)
    80002a16:	ff279be3          	bne	a5,s2,80002a0c <waitx+0xda>
        acquire(&np->lock);
    80002a1a:	8526                	mv	a0,s1
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	1c8080e7          	jalr	456(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    80002a24:	4c9c                	lw	a5,24(s1)
    80002a26:	f74785e3          	beq	a5,s4,80002990 <waitx+0x5e>
        release(&np->lock);
    80002a2a:	8526                	mv	a0,s1
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	26c080e7          	jalr	620(ra) # 80000c98 <release>
        havekids = 1;
    80002a34:	8756                	mv	a4,s5
    80002a36:	bfd9                	j	80002a0c <waitx+0xda>
    if (!havekids || p->killed)
    80002a38:	c701                	beqz	a4,80002a40 <waitx+0x10e>
    80002a3a:	02892783          	lw	a5,40(s2)
    80002a3e:	cb8d                	beqz	a5,80002a70 <waitx+0x13e>
      release(&wait_lock);
    80002a40:	0000f517          	auipc	a0,0xf
    80002a44:	87850513          	addi	a0,a0,-1928 # 800112b8 <wait_lock>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	250080e7          	jalr	592(ra) # 80000c98 <release>
      return -1;
    80002a50:	59fd                	li	s3,-1
  }
}
    80002a52:	854e                	mv	a0,s3
    80002a54:	60e6                	ld	ra,88(sp)
    80002a56:	6446                	ld	s0,80(sp)
    80002a58:	64a6                	ld	s1,72(sp)
    80002a5a:	6906                	ld	s2,64(sp)
    80002a5c:	79e2                	ld	s3,56(sp)
    80002a5e:	7a42                	ld	s4,48(sp)
    80002a60:	7aa2                	ld	s5,40(sp)
    80002a62:	7b02                	ld	s6,32(sp)
    80002a64:	6be2                	ld	s7,24(sp)
    80002a66:	6c42                	ld	s8,16(sp)
    80002a68:	6ca2                	ld	s9,8(sp)
    80002a6a:	6d02                	ld	s10,0(sp)
    80002a6c:	6125                	addi	sp,sp,96
    80002a6e:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002a70:	85ea                	mv	a1,s10
    80002a72:	854a                	mv	a0,s2
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	640080e7          	jalr	1600(ra) # 800020b4 <sleep>
    havekids = 0;
    80002a7c:	b721                	j	80002984 <waitx+0x52>

0000000080002a7e <update_time>:

void update_time()
{
    80002a7e:	7179                	addi	sp,sp,-48
    80002a80:	f406                	sd	ra,40(sp)
    80002a82:	f022                	sd	s0,32(sp)
    80002a84:	ec26                	sd	s1,24(sp)
    80002a86:	e84a                	sd	s2,16(sp)
    80002a88:	e44e                	sd	s3,8(sp)
    80002a8a:	e052                	sd	s4,0(sp)
    80002a8c:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002a8e:	0000f497          	auipc	s1,0xf
    80002a92:	c4248493          	addi	s1,s1,-958 # 800116d0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002a96:	4991                	li	s3,4
    {
      p->runtime++;
      p->run_time_pbs++;
    }
    if (p->state == SLEEPING)
    80002a98:	4a09                	li	s4,2
  for (p = proc; p < &proc[NPROC]; p++)
    80002a9a:	00016917          	auipc	s2,0x16
    80002a9e:	83690913          	addi	s2,s2,-1994 # 800182d0 <mlfq>
    80002aa2:	a025                	j	80002aca <update_time+0x4c>
      p->runtime++;
    80002aa4:	1704a783          	lw	a5,368(s1)
    80002aa8:	2785                	addiw	a5,a5,1
    80002aaa:	16f4a823          	sw	a5,368(s1)
      p->run_time_pbs++;
    80002aae:	1744a783          	lw	a5,372(s1)
    80002ab2:	2785                	addiw	a5,a5,1
    80002ab4:	16f4aa23          	sw	a5,372(s1)
    {
      p->sleep_time++;
    }
    release(&p->lock);
    80002ab8:	8526                	mv	a0,s1
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	1de080e7          	jalr	478(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ac2:	1b048493          	addi	s1,s1,432
    80002ac6:	03248263          	beq	s1,s2,80002aea <update_time+0x6c>
    acquire(&p->lock);
    80002aca:	8526                	mv	a0,s1
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	118080e7          	jalr	280(ra) # 80000be4 <acquire>
    if (p->state == RUNNING)
    80002ad4:	4c9c                	lw	a5,24(s1)
    80002ad6:	fd3787e3          	beq	a5,s3,80002aa4 <update_time+0x26>
    if (p->state == SLEEPING)
    80002ada:	fd479fe3          	bne	a5,s4,80002ab8 <update_time+0x3a>
      p->sleep_time++;
    80002ade:	1944a783          	lw	a5,404(s1)
    80002ae2:	2785                	addiw	a5,a5,1
    80002ae4:	18f4aa23          	sw	a5,404(s1)
    80002ae8:	bfc1                	j	80002ab8 <update_time+0x3a>
  }
}
    80002aea:	70a2                	ld	ra,40(sp)
    80002aec:	7402                	ld	s0,32(sp)
    80002aee:	64e2                	ld	s1,24(sp)
    80002af0:	6942                	ld	s2,16(sp)
    80002af2:	69a2                	ld	s3,8(sp)
    80002af4:	6a02                	ld	s4,0(sp)
    80002af6:	6145                	addi	sp,sp,48
    80002af8:	8082                	ret

0000000080002afa <set_priority>:

int set_priority(int new_priority, int pid)
{
    80002afa:	7179                	addi	sp,sp,-48
    80002afc:	f406                	sd	ra,40(sp)
    80002afe:	f022                	sd	s0,32(sp)
    80002b00:	ec26                	sd	s1,24(sp)
    80002b02:	e84a                	sd	s2,16(sp)
    80002b04:	e44e                	sd	s3,8(sp)
    80002b06:	e052                	sd	s4,0(sp)
    80002b08:	1800                	addi	s0,sp,48
    80002b0a:	8a2a                	mv	s4,a0
    80002b0c:	892e                	mv	s2,a1
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002b0e:	0000f497          	auipc	s1,0xf
    80002b12:	bc248493          	addi	s1,s1,-1086 # 800116d0 <proc>
    80002b16:	00015997          	auipc	s3,0x15
    80002b1a:	7ba98993          	addi	s3,s3,1978 # 800182d0 <mlfq>
  {
    acquire(&p->lock);
    80002b1e:	8526                	mv	a0,s1
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	0c4080e7          	jalr	196(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    80002b28:	589c                	lw	a5,48(s1)
    80002b2a:	01278d63          	beq	a5,s2,80002b44 <set_priority+0x4a>
      int old_spriority = p->static_priority;
      p->static_priority = new_priority;
      release(&p->lock);
      return old_spriority;
    }
    release(&p->lock);
    80002b2e:	8526                	mv	a0,s1
    80002b30:	ffffe097          	auipc	ra,0xffffe
    80002b34:	168080e7          	jalr	360(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b38:	1b048493          	addi	s1,s1,432
    80002b3c:	ff3491e3          	bne	s1,s3,80002b1e <set_priority+0x24>
  }
  return -1;
    80002b40:	597d                	li	s2,-1
    80002b42:	a811                	j	80002b56 <set_priority+0x5c>
      int old_spriority = p->static_priority;
    80002b44:	17c4a903          	lw	s2,380(s1)
      p->static_priority = new_priority;
    80002b48:	1744ae23          	sw	s4,380(s1)
      release(&p->lock);
    80002b4c:	8526                	mv	a0,s1
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	14a080e7          	jalr	330(ra) # 80000c98 <release>
}
    80002b56:	854a                	mv	a0,s2
    80002b58:	70a2                	ld	ra,40(sp)
    80002b5a:	7402                	ld	s0,32(sp)
    80002b5c:	64e2                	ld	s1,24(sp)
    80002b5e:	6942                	ld	s2,16(sp)
    80002b60:	69a2                	ld	s3,8(sp)
    80002b62:	6a02                	ld	s4,0(sp)
    80002b64:	6145                	addi	sp,sp,48
    80002b66:	8082                	ret

0000000080002b68 <swtch>:
    80002b68:	00153023          	sd	ra,0(a0)
    80002b6c:	00253423          	sd	sp,8(a0)
    80002b70:	e900                	sd	s0,16(a0)
    80002b72:	ed04                	sd	s1,24(a0)
    80002b74:	03253023          	sd	s2,32(a0)
    80002b78:	03353423          	sd	s3,40(a0)
    80002b7c:	03453823          	sd	s4,48(a0)
    80002b80:	03553c23          	sd	s5,56(a0)
    80002b84:	05653023          	sd	s6,64(a0)
    80002b88:	05753423          	sd	s7,72(a0)
    80002b8c:	05853823          	sd	s8,80(a0)
    80002b90:	05953c23          	sd	s9,88(a0)
    80002b94:	07a53023          	sd	s10,96(a0)
    80002b98:	07b53423          	sd	s11,104(a0)
    80002b9c:	0005b083          	ld	ra,0(a1)
    80002ba0:	0085b103          	ld	sp,8(a1)
    80002ba4:	6980                	ld	s0,16(a1)
    80002ba6:	6d84                	ld	s1,24(a1)
    80002ba8:	0205b903          	ld	s2,32(a1)
    80002bac:	0285b983          	ld	s3,40(a1)
    80002bb0:	0305ba03          	ld	s4,48(a1)
    80002bb4:	0385ba83          	ld	s5,56(a1)
    80002bb8:	0405bb03          	ld	s6,64(a1)
    80002bbc:	0485bb83          	ld	s7,72(a1)
    80002bc0:	0505bc03          	ld	s8,80(a1)
    80002bc4:	0585bc83          	ld	s9,88(a1)
    80002bc8:	0605bd03          	ld	s10,96(a1)
    80002bcc:	0685bd83          	ld	s11,104(a1)
    80002bd0:	8082                	ret

0000000080002bd2 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002bd2:	1141                	addi	sp,sp,-16
    80002bd4:	e406                	sd	ra,8(sp)
    80002bd6:	e022                	sd	s0,0(sp)
    80002bd8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002bda:	00005597          	auipc	a1,0x5
    80002bde:	73e58593          	addi	a1,a1,1854 # 80008318 <all_states.1776+0x30>
    80002be2:	00016517          	auipc	a0,0x16
    80002be6:	16650513          	addi	a0,a0,358 # 80018d48 <tickslock>
    80002bea:	ffffe097          	auipc	ra,0xffffe
    80002bee:	f6a080e7          	jalr	-150(ra) # 80000b54 <initlock>
}
    80002bf2:	60a2                	ld	ra,8(sp)
    80002bf4:	6402                	ld	s0,0(sp)
    80002bf6:	0141                	addi	sp,sp,16
    80002bf8:	8082                	ret

0000000080002bfa <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002bfa:	1141                	addi	sp,sp,-16
    80002bfc:	e422                	sd	s0,8(sp)
    80002bfe:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c00:	00003797          	auipc	a5,0x3
    80002c04:	6a078793          	addi	a5,a5,1696 # 800062a0 <kernelvec>
    80002c08:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c0c:	6422                	ld	s0,8(sp)
    80002c0e:	0141                	addi	sp,sp,16
    80002c10:	8082                	ret

0000000080002c12 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002c12:	1141                	addi	sp,sp,-16
    80002c14:	e406                	sd	ra,8(sp)
    80002c16:	e022                	sd	s0,0(sp)
    80002c18:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	dba080e7          	jalr	-582(ra) # 800019d4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c22:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c26:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c28:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c2c:	00004617          	auipc	a2,0x4
    80002c30:	3d460613          	addi	a2,a2,980 # 80007000 <_trampoline>
    80002c34:	00004697          	auipc	a3,0x4
    80002c38:	3cc68693          	addi	a3,a3,972 # 80007000 <_trampoline>
    80002c3c:	8e91                	sub	a3,a3,a2
    80002c3e:	040007b7          	lui	a5,0x4000
    80002c42:	17fd                	addi	a5,a5,-1
    80002c44:	07b2                	slli	a5,a5,0xc
    80002c46:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c48:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c4c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c4e:	180026f3          	csrr	a3,satp
    80002c52:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c54:	6d38                	ld	a4,88(a0)
    80002c56:	6134                	ld	a3,64(a0)
    80002c58:	6585                	lui	a1,0x1
    80002c5a:	96ae                	add	a3,a3,a1
    80002c5c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c5e:	6d38                	ld	a4,88(a0)
    80002c60:	00000697          	auipc	a3,0x0
    80002c64:	14668693          	addi	a3,a3,326 # 80002da6 <usertrap>
    80002c68:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002c6a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c6c:	8692                	mv	a3,tp
    80002c6e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c70:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c74:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c78:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c7c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c80:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c82:	6f18                	ld	a4,24(a4)
    80002c84:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c88:	692c                	ld	a1,80(a0)
    80002c8a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c8c:	00004717          	auipc	a4,0x4
    80002c90:	40470713          	addi	a4,a4,1028 # 80007090 <userret>
    80002c94:	8f11                	sub	a4,a4,a2
    80002c96:	97ba                	add	a5,a5,a4
  ((void (*)(uint64, uint64))fn)(TRAPFRAME, satp);
    80002c98:	577d                	li	a4,-1
    80002c9a:	177e                	slli	a4,a4,0x3f
    80002c9c:	8dd9                	or	a1,a1,a4
    80002c9e:	02000537          	lui	a0,0x2000
    80002ca2:	157d                	addi	a0,a0,-1
    80002ca4:	0536                	slli	a0,a0,0xd
    80002ca6:	9782                	jalr	a5
}
    80002ca8:	60a2                	ld	ra,8(sp)
    80002caa:	6402                	ld	s0,0(sp)
    80002cac:	0141                	addi	sp,sp,16
    80002cae:	8082                	ret

0000000080002cb0 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002cb0:	1101                	addi	sp,sp,-32
    80002cb2:	ec06                	sd	ra,24(sp)
    80002cb4:	e822                	sd	s0,16(sp)
    80002cb6:	e426                	sd	s1,8(sp)
    80002cb8:	e04a                	sd	s2,0(sp)
    80002cba:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002cbc:	00016917          	auipc	s2,0x16
    80002cc0:	08c90913          	addi	s2,s2,140 # 80018d48 <tickslock>
    80002cc4:	854a                	mv	a0,s2
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	f1e080e7          	jalr	-226(ra) # 80000be4 <acquire>
  ticks++;
    80002cce:	00006497          	auipc	s1,0x6
    80002cd2:	36248493          	addi	s1,s1,866 # 80009030 <ticks>
    80002cd6:	409c                	lw	a5,0(s1)
    80002cd8:	2785                	addiw	a5,a5,1
    80002cda:	c09c                	sw	a5,0(s1)
  update_time();
    80002cdc:	00000097          	auipc	ra,0x0
    80002ce0:	da2080e7          	jalr	-606(ra) # 80002a7e <update_time>
  wakeup(&ticks);
    80002ce4:	8526                	mv	a0,s1
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	55a080e7          	jalr	1370(ra) # 80002240 <wakeup>
  release(&tickslock);
    80002cee:	854a                	mv	a0,s2
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	fa8080e7          	jalr	-88(ra) # 80000c98 <release>
}
    80002cf8:	60e2                	ld	ra,24(sp)
    80002cfa:	6442                	ld	s0,16(sp)
    80002cfc:	64a2                	ld	s1,8(sp)
    80002cfe:	6902                	ld	s2,0(sp)
    80002d00:	6105                	addi	sp,sp,32
    80002d02:	8082                	ret

0000000080002d04 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002d04:	1101                	addi	sp,sp,-32
    80002d06:	ec06                	sd	ra,24(sp)
    80002d08:	e822                	sd	s0,16(sp)
    80002d0a:	e426                	sd	s1,8(sp)
    80002d0c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d0e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002d12:	00074d63          	bltz	a4,80002d2c <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002d16:	57fd                	li	a5,-1
    80002d18:	17fe                	slli	a5,a5,0x3f
    80002d1a:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002d1c:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002d1e:	06f70363          	beq	a4,a5,80002d84 <devintr+0x80>
  }
}
    80002d22:	60e2                	ld	ra,24(sp)
    80002d24:	6442                	ld	s0,16(sp)
    80002d26:	64a2                	ld	s1,8(sp)
    80002d28:	6105                	addi	sp,sp,32
    80002d2a:	8082                	ret
      (scause & 0xff) == 9)
    80002d2c:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002d30:	46a5                	li	a3,9
    80002d32:	fed792e3          	bne	a5,a3,80002d16 <devintr+0x12>
    int irq = plic_claim();
    80002d36:	00003097          	auipc	ra,0x3
    80002d3a:	672080e7          	jalr	1650(ra) # 800063a8 <plic_claim>
    80002d3e:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002d40:	47a9                	li	a5,10
    80002d42:	02f50763          	beq	a0,a5,80002d70 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002d46:	4785                	li	a5,1
    80002d48:	02f50963          	beq	a0,a5,80002d7a <devintr+0x76>
    return 1;
    80002d4c:	4505                	li	a0,1
    else if (irq)
    80002d4e:	d8f1                	beqz	s1,80002d22 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d50:	85a6                	mv	a1,s1
    80002d52:	00005517          	auipc	a0,0x5
    80002d56:	5ce50513          	addi	a0,a0,1486 # 80008320 <all_states.1776+0x38>
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	82e080e7          	jalr	-2002(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d62:	8526                	mv	a0,s1
    80002d64:	00003097          	auipc	ra,0x3
    80002d68:	668080e7          	jalr	1640(ra) # 800063cc <plic_complete>
    return 1;
    80002d6c:	4505                	li	a0,1
    80002d6e:	bf55                	j	80002d22 <devintr+0x1e>
      uartintr();
    80002d70:	ffffe097          	auipc	ra,0xffffe
    80002d74:	c38080e7          	jalr	-968(ra) # 800009a8 <uartintr>
    80002d78:	b7ed                	j	80002d62 <devintr+0x5e>
      virtio_disk_intr();
    80002d7a:	00004097          	auipc	ra,0x4
    80002d7e:	b32080e7          	jalr	-1230(ra) # 800068ac <virtio_disk_intr>
    80002d82:	b7c5                	j	80002d62 <devintr+0x5e>
    if (cpuid() == 0)
    80002d84:	fffff097          	auipc	ra,0xfffff
    80002d88:	c24080e7          	jalr	-988(ra) # 800019a8 <cpuid>
    80002d8c:	c901                	beqz	a0,80002d9c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d8e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d92:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d94:	14479073          	csrw	sip,a5
    return 2;
    80002d98:	4509                	li	a0,2
    80002d9a:	b761                	j	80002d22 <devintr+0x1e>
      clockintr();
    80002d9c:	00000097          	auipc	ra,0x0
    80002da0:	f14080e7          	jalr	-236(ra) # 80002cb0 <clockintr>
    80002da4:	b7ed                	j	80002d8e <devintr+0x8a>

0000000080002da6 <usertrap>:
{
    80002da6:	1101                	addi	sp,sp,-32
    80002da8:	ec06                	sd	ra,24(sp)
    80002daa:	e822                	sd	s0,16(sp)
    80002dac:	e426                	sd	s1,8(sp)
    80002dae:	e04a                	sd	s2,0(sp)
    80002db0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002db2:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002db6:	1007f793          	andi	a5,a5,256
    80002dba:	e3ad                	bnez	a5,80002e1c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dbc:	00003797          	auipc	a5,0x3
    80002dc0:	4e478793          	addi	a5,a5,1252 # 800062a0 <kernelvec>
    80002dc4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002dc8:	fffff097          	auipc	ra,0xfffff
    80002dcc:	c0c080e7          	jalr	-1012(ra) # 800019d4 <myproc>
    80002dd0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002dd2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dd4:	14102773          	csrr	a4,sepc
    80002dd8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dda:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002dde:	47a1                	li	a5,8
    80002de0:	04f71c63          	bne	a4,a5,80002e38 <usertrap+0x92>
    if (p->killed)
    80002de4:	551c                	lw	a5,40(a0)
    80002de6:	e3b9                	bnez	a5,80002e2c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002de8:	6cb8                	ld	a4,88(s1)
    80002dea:	6f1c                	ld	a5,24(a4)
    80002dec:	0791                	addi	a5,a5,4
    80002dee:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002df0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002df4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002df8:	10079073          	csrw	sstatus,a5
    syscall();
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	2e0080e7          	jalr	736(ra) # 800030dc <syscall>
  if (p->killed)
    80002e04:	549c                	lw	a5,40(s1)
    80002e06:	ebc1                	bnez	a5,80002e96 <usertrap+0xf0>
  usertrapret();
    80002e08:	00000097          	auipc	ra,0x0
    80002e0c:	e0a080e7          	jalr	-502(ra) # 80002c12 <usertrapret>
}
    80002e10:	60e2                	ld	ra,24(sp)
    80002e12:	6442                	ld	s0,16(sp)
    80002e14:	64a2                	ld	s1,8(sp)
    80002e16:	6902                	ld	s2,0(sp)
    80002e18:	6105                	addi	sp,sp,32
    80002e1a:	8082                	ret
    panic("usertrap: not from user mode");
    80002e1c:	00005517          	auipc	a0,0x5
    80002e20:	52450513          	addi	a0,a0,1316 # 80008340 <all_states.1776+0x58>
    80002e24:	ffffd097          	auipc	ra,0xffffd
    80002e28:	71a080e7          	jalr	1818(ra) # 8000053e <panic>
      exit(-1);
    80002e2c:	557d                	li	a0,-1
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	4e2080e7          	jalr	1250(ra) # 80002310 <exit>
    80002e36:	bf4d                	j	80002de8 <usertrap+0x42>
  else if ((which_dev = devintr()) != 0)
    80002e38:	00000097          	auipc	ra,0x0
    80002e3c:	ecc080e7          	jalr	-308(ra) # 80002d04 <devintr>
    80002e40:	892a                	mv	s2,a0
    80002e42:	c501                	beqz	a0,80002e4a <usertrap+0xa4>
  if (p->killed)
    80002e44:	549c                	lw	a5,40(s1)
    80002e46:	c3a1                	beqz	a5,80002e86 <usertrap+0xe0>
    80002e48:	a815                	j	80002e7c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e4a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e4e:	5890                	lw	a2,48(s1)
    80002e50:	00005517          	auipc	a0,0x5
    80002e54:	51050513          	addi	a0,a0,1296 # 80008360 <all_states.1776+0x78>
    80002e58:	ffffd097          	auipc	ra,0xffffd
    80002e5c:	730080e7          	jalr	1840(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e60:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e64:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e68:	00005517          	auipc	a0,0x5
    80002e6c:	52850513          	addi	a0,a0,1320 # 80008390 <all_states.1776+0xa8>
    80002e70:	ffffd097          	auipc	ra,0xffffd
    80002e74:	718080e7          	jalr	1816(ra) # 80000588 <printf>
    p->killed = 1;
    80002e78:	4785                	li	a5,1
    80002e7a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e7c:	557d                	li	a0,-1
    80002e7e:	fffff097          	auipc	ra,0xfffff
    80002e82:	492080e7          	jalr	1170(ra) # 80002310 <exit>
    if (which_dev == 2)
    80002e86:	4789                	li	a5,2
    80002e88:	f8f910e3          	bne	s2,a5,80002e08 <usertrap+0x62>
      yield();
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	1ec080e7          	jalr	492(ra) # 80002078 <yield>
    80002e94:	bf95                	j	80002e08 <usertrap+0x62>
  int which_dev = 0;
    80002e96:	4901                	li	s2,0
    80002e98:	b7d5                	j	80002e7c <usertrap+0xd6>

0000000080002e9a <kerneltrap>:
{
    80002e9a:	7179                	addi	sp,sp,-48
    80002e9c:	f406                	sd	ra,40(sp)
    80002e9e:	f022                	sd	s0,32(sp)
    80002ea0:	ec26                	sd	s1,24(sp)
    80002ea2:	e84a                	sd	s2,16(sp)
    80002ea4:	e44e                	sd	s3,8(sp)
    80002ea6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ea8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eac:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eb0:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002eb4:	1004f793          	andi	a5,s1,256
    80002eb8:	cb85                	beqz	a5,80002ee8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ebe:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002ec0:	ef85                	bnez	a5,80002ef8 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002ec2:	00000097          	auipc	ra,0x0
    80002ec6:	e42080e7          	jalr	-446(ra) # 80002d04 <devintr>
    80002eca:	cd1d                	beqz	a0,80002f08 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ecc:	4789                	li	a5,2
    80002ece:	06f50a63          	beq	a0,a5,80002f42 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ed2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ed6:	10049073          	csrw	sstatus,s1
}
    80002eda:	70a2                	ld	ra,40(sp)
    80002edc:	7402                	ld	s0,32(sp)
    80002ede:	64e2                	ld	s1,24(sp)
    80002ee0:	6942                	ld	s2,16(sp)
    80002ee2:	69a2                	ld	s3,8(sp)
    80002ee4:	6145                	addi	sp,sp,48
    80002ee6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ee8:	00005517          	auipc	a0,0x5
    80002eec:	4c850513          	addi	a0,a0,1224 # 800083b0 <all_states.1776+0xc8>
    80002ef0:	ffffd097          	auipc	ra,0xffffd
    80002ef4:	64e080e7          	jalr	1614(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ef8:	00005517          	auipc	a0,0x5
    80002efc:	4e050513          	addi	a0,a0,1248 # 800083d8 <all_states.1776+0xf0>
    80002f00:	ffffd097          	auipc	ra,0xffffd
    80002f04:	63e080e7          	jalr	1598(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f08:	85ce                	mv	a1,s3
    80002f0a:	00005517          	auipc	a0,0x5
    80002f0e:	4ee50513          	addi	a0,a0,1262 # 800083f8 <all_states.1776+0x110>
    80002f12:	ffffd097          	auipc	ra,0xffffd
    80002f16:	676080e7          	jalr	1654(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f1a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f1e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f22:	00005517          	auipc	a0,0x5
    80002f26:	4e650513          	addi	a0,a0,1254 # 80008408 <all_states.1776+0x120>
    80002f2a:	ffffd097          	auipc	ra,0xffffd
    80002f2e:	65e080e7          	jalr	1630(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f32:	00005517          	auipc	a0,0x5
    80002f36:	4ee50513          	addi	a0,a0,1262 # 80008420 <all_states.1776+0x138>
    80002f3a:	ffffd097          	auipc	ra,0xffffd
    80002f3e:	604080e7          	jalr	1540(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	a92080e7          	jalr	-1390(ra) # 800019d4 <myproc>
    80002f4a:	d541                	beqz	a0,80002ed2 <kerneltrap+0x38>
    80002f4c:	fffff097          	auipc	ra,0xfffff
    80002f50:	a88080e7          	jalr	-1400(ra) # 800019d4 <myproc>
    80002f54:	4d18                	lw	a4,24(a0)
    80002f56:	4791                	li	a5,4
    80002f58:	f6f71de3          	bne	a4,a5,80002ed2 <kerneltrap+0x38>
    yield();
    80002f5c:	fffff097          	auipc	ra,0xfffff
    80002f60:	11c080e7          	jalr	284(ra) # 80002078 <yield>
    80002f64:	b7bd                	j	80002ed2 <kerneltrap+0x38>

0000000080002f66 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f66:	1101                	addi	sp,sp,-32
    80002f68:	ec06                	sd	ra,24(sp)
    80002f6a:	e822                	sd	s0,16(sp)
    80002f6c:	e426                	sd	s1,8(sp)
    80002f6e:	1000                	addi	s0,sp,32
    80002f70:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	a62080e7          	jalr	-1438(ra) # 800019d4 <myproc>
  switch (n)
    80002f7a:	4795                	li	a5,5
    80002f7c:	0497e163          	bltu	a5,s1,80002fbe <argraw+0x58>
    80002f80:	048a                	slli	s1,s1,0x2
    80002f82:	00005717          	auipc	a4,0x5
    80002f86:	5ce70713          	addi	a4,a4,1486 # 80008550 <all_states.1776+0x268>
    80002f8a:	94ba                	add	s1,s1,a4
    80002f8c:	409c                	lw	a5,0(s1)
    80002f8e:	97ba                	add	a5,a5,a4
    80002f90:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002f92:	6d3c                	ld	a5,88(a0)
    80002f94:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f96:	60e2                	ld	ra,24(sp)
    80002f98:	6442                	ld	s0,16(sp)
    80002f9a:	64a2                	ld	s1,8(sp)
    80002f9c:	6105                	addi	sp,sp,32
    80002f9e:	8082                	ret
    return p->trapframe->a1;
    80002fa0:	6d3c                	ld	a5,88(a0)
    80002fa2:	7fa8                	ld	a0,120(a5)
    80002fa4:	bfcd                	j	80002f96 <argraw+0x30>
    return p->trapframe->a2;
    80002fa6:	6d3c                	ld	a5,88(a0)
    80002fa8:	63c8                	ld	a0,128(a5)
    80002faa:	b7f5                	j	80002f96 <argraw+0x30>
    return p->trapframe->a3;
    80002fac:	6d3c                	ld	a5,88(a0)
    80002fae:	67c8                	ld	a0,136(a5)
    80002fb0:	b7dd                	j	80002f96 <argraw+0x30>
    return p->trapframe->a4;
    80002fb2:	6d3c                	ld	a5,88(a0)
    80002fb4:	6bc8                	ld	a0,144(a5)
    80002fb6:	b7c5                	j	80002f96 <argraw+0x30>
    return p->trapframe->a5;
    80002fb8:	6d3c                	ld	a5,88(a0)
    80002fba:	6fc8                	ld	a0,152(a5)
    80002fbc:	bfe9                	j	80002f96 <argraw+0x30>
  panic("argraw");
    80002fbe:	00005517          	auipc	a0,0x5
    80002fc2:	47250513          	addi	a0,a0,1138 # 80008430 <all_states.1776+0x148>
    80002fc6:	ffffd097          	auipc	ra,0xffffd
    80002fca:	578080e7          	jalr	1400(ra) # 8000053e <panic>

0000000080002fce <fetchaddr>:
{
    80002fce:	1101                	addi	sp,sp,-32
    80002fd0:	ec06                	sd	ra,24(sp)
    80002fd2:	e822                	sd	s0,16(sp)
    80002fd4:	e426                	sd	s1,8(sp)
    80002fd6:	e04a                	sd	s2,0(sp)
    80002fd8:	1000                	addi	s0,sp,32
    80002fda:	84aa                	mv	s1,a0
    80002fdc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002fde:	fffff097          	auipc	ra,0xfffff
    80002fe2:	9f6080e7          	jalr	-1546(ra) # 800019d4 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002fe6:	653c                	ld	a5,72(a0)
    80002fe8:	02f4f863          	bgeu	s1,a5,80003018 <fetchaddr+0x4a>
    80002fec:	00848713          	addi	a4,s1,8
    80002ff0:	02e7e663          	bltu	a5,a4,8000301c <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ff4:	46a1                	li	a3,8
    80002ff6:	8626                	mv	a2,s1
    80002ff8:	85ca                	mv	a1,s2
    80002ffa:	6928                	ld	a0,80(a0)
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	702080e7          	jalr	1794(ra) # 800016fe <copyin>
    80003004:	00a03533          	snez	a0,a0
    80003008:	40a00533          	neg	a0,a0
}
    8000300c:	60e2                	ld	ra,24(sp)
    8000300e:	6442                	ld	s0,16(sp)
    80003010:	64a2                	ld	s1,8(sp)
    80003012:	6902                	ld	s2,0(sp)
    80003014:	6105                	addi	sp,sp,32
    80003016:	8082                	ret
    return -1;
    80003018:	557d                	li	a0,-1
    8000301a:	bfcd                	j	8000300c <fetchaddr+0x3e>
    8000301c:	557d                	li	a0,-1
    8000301e:	b7fd                	j	8000300c <fetchaddr+0x3e>

0000000080003020 <fetchstr>:
{
    80003020:	7179                	addi	sp,sp,-48
    80003022:	f406                	sd	ra,40(sp)
    80003024:	f022                	sd	s0,32(sp)
    80003026:	ec26                	sd	s1,24(sp)
    80003028:	e84a                	sd	s2,16(sp)
    8000302a:	e44e                	sd	s3,8(sp)
    8000302c:	1800                	addi	s0,sp,48
    8000302e:	892a                	mv	s2,a0
    80003030:	84ae                	mv	s1,a1
    80003032:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003034:	fffff097          	auipc	ra,0xfffff
    80003038:	9a0080e7          	jalr	-1632(ra) # 800019d4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000303c:	86ce                	mv	a3,s3
    8000303e:	864a                	mv	a2,s2
    80003040:	85a6                	mv	a1,s1
    80003042:	6928                	ld	a0,80(a0)
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	746080e7          	jalr	1862(ra) # 8000178a <copyinstr>
  if (err < 0)
    8000304c:	00054763          	bltz	a0,8000305a <fetchstr+0x3a>
  return strlen(buf);
    80003050:	8526                	mv	a0,s1
    80003052:	ffffe097          	auipc	ra,0xffffe
    80003056:	e12080e7          	jalr	-494(ra) # 80000e64 <strlen>
}
    8000305a:	70a2                	ld	ra,40(sp)
    8000305c:	7402                	ld	s0,32(sp)
    8000305e:	64e2                	ld	s1,24(sp)
    80003060:	6942                	ld	s2,16(sp)
    80003062:	69a2                	ld	s3,8(sp)
    80003064:	6145                	addi	sp,sp,48
    80003066:	8082                	ret

0000000080003068 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80003068:	1101                	addi	sp,sp,-32
    8000306a:	ec06                	sd	ra,24(sp)
    8000306c:	e822                	sd	s0,16(sp)
    8000306e:	e426                	sd	s1,8(sp)
    80003070:	1000                	addi	s0,sp,32
    80003072:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003074:	00000097          	auipc	ra,0x0
    80003078:	ef2080e7          	jalr	-270(ra) # 80002f66 <argraw>
    8000307c:	c088                	sw	a0,0(s1)
  return 0;
}
    8000307e:	4501                	li	a0,0
    80003080:	60e2                	ld	ra,24(sp)
    80003082:	6442                	ld	s0,16(sp)
    80003084:	64a2                	ld	s1,8(sp)
    80003086:	6105                	addi	sp,sp,32
    80003088:	8082                	ret

000000008000308a <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    8000308a:	1101                	addi	sp,sp,-32
    8000308c:	ec06                	sd	ra,24(sp)
    8000308e:	e822                	sd	s0,16(sp)
    80003090:	e426                	sd	s1,8(sp)
    80003092:	1000                	addi	s0,sp,32
    80003094:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003096:	00000097          	auipc	ra,0x0
    8000309a:	ed0080e7          	jalr	-304(ra) # 80002f66 <argraw>
    8000309e:	e088                	sd	a0,0(s1)
  return 0;
}
    800030a0:	4501                	li	a0,0
    800030a2:	60e2                	ld	ra,24(sp)
    800030a4:	6442                	ld	s0,16(sp)
    800030a6:	64a2                	ld	s1,8(sp)
    800030a8:	6105                	addi	sp,sp,32
    800030aa:	8082                	ret

00000000800030ac <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    800030ac:	1101                	addi	sp,sp,-32
    800030ae:	ec06                	sd	ra,24(sp)
    800030b0:	e822                	sd	s0,16(sp)
    800030b2:	e426                	sd	s1,8(sp)
    800030b4:	e04a                	sd	s2,0(sp)
    800030b6:	1000                	addi	s0,sp,32
    800030b8:	84ae                	mv	s1,a1
    800030ba:	8932                	mv	s2,a2
  *ip = argraw(n);
    800030bc:	00000097          	auipc	ra,0x0
    800030c0:	eaa080e7          	jalr	-342(ra) # 80002f66 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800030c4:	864a                	mv	a2,s2
    800030c6:	85a6                	mv	a1,s1
    800030c8:	00000097          	auipc	ra,0x0
    800030cc:	f58080e7          	jalr	-168(ra) # 80003020 <fetchstr>
}
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6902                	ld	s2,0(sp)
    800030d8:	6105                	addi	sp,sp,32
    800030da:	8082                	ret

00000000800030dc <syscall>:
    [SYS_trace] 1,
    [SYS_set_priority] 2,
    };

void syscall(void)
{
    800030dc:	715d                	addi	sp,sp,-80
    800030de:	e486                	sd	ra,72(sp)
    800030e0:	e0a2                	sd	s0,64(sp)
    800030e2:	fc26                	sd	s1,56(sp)
    800030e4:	f84a                	sd	s2,48(sp)
    800030e6:	f44e                	sd	s3,40(sp)
    800030e8:	f052                	sd	s4,32(sp)
    800030ea:	ec56                	sd	s5,24(sp)
    800030ec:	e85a                	sd	s6,16(sp)
    800030ee:	e45e                	sd	s7,8(sp)
    800030f0:	0880                	addi	s0,sp,80
  int num;
  struct proc *p = myproc();
    800030f2:	fffff097          	auipc	ra,0xfffff
    800030f6:	8e2080e7          	jalr	-1822(ra) # 800019d4 <myproc>
    800030fa:	84aa                	mv	s1,a0
  int arg1 = 0, arg2 = 0, arg3 = 0;
  num = p->trapframe->a7;
    800030fc:	05853983          	ld	s3,88(a0)
    80003100:	0a89b783          	ld	a5,168(s3)
    80003104:	00078a1b          	sext.w	s4,a5
  int count_args = syscallnum[num];
    80003108:	002a1693          	slli	a3,s4,0x2
    8000310c:	00005717          	auipc	a4,0x5
    80003110:	45c70713          	addi	a4,a4,1116 # 80008568 <syscallnum>
    80003114:	9736                	add	a4,a4,a3
    80003116:	00072903          	lw	s2,0(a4)
  int arg1 = 0, arg2 = 0, arg3 = 0;
    8000311a:	4a81                	li	s5,0

  if (count_args > 0)
    8000311c:	01205463          	blez	s2,80003124 <syscall+0x48>
    arg1 = p->trapframe->a0;
    80003120:	0709aa83          	lw	s5,112(s3)
  if (count_args > 1)
    80003124:	4705                	li	a4,1
  int arg1 = 0, arg2 = 0, arg3 = 0;
    80003126:	4b01                	li	s6,0
  if (count_args > 1)
    80003128:	01275463          	bge	a4,s2,80003130 <syscall+0x54>
    arg2 = p->trapframe->a1;
    8000312c:	0789ab03          	lw	s6,120(s3)
  if (count_args > 2)
    80003130:	4709                	li	a4,2
  int arg1 = 0, arg2 = 0, arg3 = 0;
    80003132:	4b81                	li	s7,0
  if (count_args > 2)
    80003134:	01275463          	bge	a4,s2,8000313c <syscall+0x60>
    arg3 = p->trapframe->a2;
    80003138:	0809ab83          	lw	s7,128(s3)

  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    8000313c:	37fd                	addiw	a5,a5,-1
    8000313e:	475d                	li	a4,23
    80003140:	0af76863          	bltu	a4,a5,800031f0 <syscall+0x114>
    80003144:	003a1713          	slli	a4,s4,0x3
    80003148:	00005797          	auipc	a5,0x5
    8000314c:	42078793          	addi	a5,a5,1056 # 80008568 <syscallnum>
    80003150:	97ba                	add	a5,a5,a4
    80003152:	77bc                	ld	a5,104(a5)
    80003154:	cfd1                	beqz	a5,800031f0 <syscall+0x114>
  {
    p->trapframe->a0 = syscalls[num]();
    80003156:	9782                	jalr	a5
    80003158:	06a9b823          	sd	a0,112(s3)
    if (p->mask >> num)
    8000315c:	58dc                	lw	a5,52(s1)
    8000315e:	4147d7bb          	sraw	a5,a5,s4
    80003162:	c7d5                	beqz	a5,8000320e <syscall+0x132>
    {
      printf("%d: syscall %s ", p->pid, system_call_name[num]);
    80003164:	0a0e                	slli	s4,s4,0x3
    80003166:	00006797          	auipc	a5,0x6
    8000316a:	89278793          	addi	a5,a5,-1902 # 800089f8 <system_call_name>
    8000316e:	9a3e                	add	s4,s4,a5
    80003170:	000a3603          	ld	a2,0(s4)
    80003174:	588c                	lw	a1,48(s1)
    80003176:	00005517          	auipc	a0,0x5
    8000317a:	2c250513          	addi	a0,a0,706 # 80008438 <all_states.1776+0x150>
    8000317e:	ffffd097          	auipc	ra,0xffffd
    80003182:	40a080e7          	jalr	1034(ra) # 80000588 <printf>
      if (count_args == 1)
    80003186:	4785                	li	a5,1
    80003188:	02f90363          	beq	s2,a5,800031ae <syscall+0xd2>
        printf("( %d )", arg1);
      if (count_args == 2)
    8000318c:	4789                	li	a5,2
    8000318e:	02f90a63          	beq	s2,a5,800031c2 <syscall+0xe6>
        printf("( %d %d )", arg1, arg2);
      if (count_args == 3)
    80003192:	478d                	li	a5,3
    80003194:	04f90263          	beq	s2,a5,800031d8 <syscall+0xfc>
        printf("( %d %d %d )", arg1, arg2, arg3);
      printf(" -> %d\n", p->trapframe->a0);
    80003198:	6cbc                	ld	a5,88(s1)
    8000319a:	7bac                	ld	a1,112(a5)
    8000319c:	00005517          	auipc	a0,0x5
    800031a0:	2d450513          	addi	a0,a0,724 # 80008470 <all_states.1776+0x188>
    800031a4:	ffffd097          	auipc	ra,0xffffd
    800031a8:	3e4080e7          	jalr	996(ra) # 80000588 <printf>
    800031ac:	a08d                	j	8000320e <syscall+0x132>
        printf("( %d )", arg1);
    800031ae:	85d6                	mv	a1,s5
    800031b0:	00005517          	auipc	a0,0x5
    800031b4:	29850513          	addi	a0,a0,664 # 80008448 <all_states.1776+0x160>
    800031b8:	ffffd097          	auipc	ra,0xffffd
    800031bc:	3d0080e7          	jalr	976(ra) # 80000588 <printf>
      if (count_args == 3)
    800031c0:	bfe1                	j	80003198 <syscall+0xbc>
        printf("( %d %d )", arg1, arg2);
    800031c2:	865a                	mv	a2,s6
    800031c4:	85d6                	mv	a1,s5
    800031c6:	00005517          	auipc	a0,0x5
    800031ca:	28a50513          	addi	a0,a0,650 # 80008450 <all_states.1776+0x168>
    800031ce:	ffffd097          	auipc	ra,0xffffd
    800031d2:	3ba080e7          	jalr	954(ra) # 80000588 <printf>
      if (count_args == 3)
    800031d6:	b7c9                	j	80003198 <syscall+0xbc>
        printf("( %d %d %d )", arg1, arg2, arg3);
    800031d8:	86de                	mv	a3,s7
    800031da:	865a                	mv	a2,s6
    800031dc:	85d6                	mv	a1,s5
    800031de:	00005517          	auipc	a0,0x5
    800031e2:	28250513          	addi	a0,a0,642 # 80008460 <all_states.1776+0x178>
    800031e6:	ffffd097          	auipc	ra,0xffffd
    800031ea:	3a2080e7          	jalr	930(ra) # 80000588 <printf>
    800031ee:	b76d                	j	80003198 <syscall+0xbc>
    }
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    800031f0:	86d2                	mv	a3,s4
    800031f2:	15848613          	addi	a2,s1,344
    800031f6:	588c                	lw	a1,48(s1)
    800031f8:	00005517          	auipc	a0,0x5
    800031fc:	28050513          	addi	a0,a0,640 # 80008478 <all_states.1776+0x190>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	388080e7          	jalr	904(ra) # 80000588 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003208:	6cbc                	ld	a5,88(s1)
    8000320a:	577d                	li	a4,-1
    8000320c:	fbb8                	sd	a4,112(a5)
  }
}
    8000320e:	60a6                	ld	ra,72(sp)
    80003210:	6406                	ld	s0,64(sp)
    80003212:	74e2                	ld	s1,56(sp)
    80003214:	7942                	ld	s2,48(sp)
    80003216:	79a2                	ld	s3,40(sp)
    80003218:	7a02                	ld	s4,32(sp)
    8000321a:	6ae2                	ld	s5,24(sp)
    8000321c:	6b42                	ld	s6,16(sp)
    8000321e:	6ba2                	ld	s7,8(sp)
    80003220:	6161                	addi	sp,sp,80
    80003222:	8082                	ret

0000000080003224 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003224:	1101                	addi	sp,sp,-32
    80003226:	ec06                	sd	ra,24(sp)
    80003228:	e822                	sd	s0,16(sp)
    8000322a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000322c:	fec40593          	addi	a1,s0,-20
    80003230:	4501                	li	a0,0
    80003232:	00000097          	auipc	ra,0x0
    80003236:	e36080e7          	jalr	-458(ra) # 80003068 <argint>
    return -1;
    8000323a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000323c:	00054963          	bltz	a0,8000324e <sys_exit+0x2a>
  exit(n);
    80003240:	fec42503          	lw	a0,-20(s0)
    80003244:	fffff097          	auipc	ra,0xfffff
    80003248:	0cc080e7          	jalr	204(ra) # 80002310 <exit>
  return 0;  // not reached
    8000324c:	4781                	li	a5,0
}
    8000324e:	853e                	mv	a0,a5
    80003250:	60e2                	ld	ra,24(sp)
    80003252:	6442                	ld	s0,16(sp)
    80003254:	6105                	addi	sp,sp,32
    80003256:	8082                	ret

0000000080003258 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003258:	1141                	addi	sp,sp,-16
    8000325a:	e406                	sd	ra,8(sp)
    8000325c:	e022                	sd	s0,0(sp)
    8000325e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003260:	ffffe097          	auipc	ra,0xffffe
    80003264:	774080e7          	jalr	1908(ra) # 800019d4 <myproc>
}
    80003268:	5908                	lw	a0,48(a0)
    8000326a:	60a2                	ld	ra,8(sp)
    8000326c:	6402                	ld	s0,0(sp)
    8000326e:	0141                	addi	sp,sp,16
    80003270:	8082                	ret

0000000080003272 <sys_fork>:

uint64
sys_fork(void)
{
    80003272:	1141                	addi	sp,sp,-16
    80003274:	e406                	sd	ra,8(sp)
    80003276:	e022                	sd	s0,0(sp)
    80003278:	0800                	addi	s0,sp,16
  return fork();
    8000327a:	fffff097          	auipc	ra,0xfffff
    8000327e:	be4080e7          	jalr	-1052(ra) # 80001e5e <fork>
}
    80003282:	60a2                	ld	ra,8(sp)
    80003284:	6402                	ld	s0,0(sp)
    80003286:	0141                	addi	sp,sp,16
    80003288:	8082                	ret

000000008000328a <sys_wait>:

uint64
sys_wait(void)
{
    8000328a:	1101                	addi	sp,sp,-32
    8000328c:	ec06                	sd	ra,24(sp)
    8000328e:	e822                	sd	s0,16(sp)
    80003290:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003292:	fe840593          	addi	a1,s0,-24
    80003296:	4501                	li	a0,0
    80003298:	00000097          	auipc	ra,0x0
    8000329c:	df2080e7          	jalr	-526(ra) # 8000308a <argaddr>
    800032a0:	87aa                	mv	a5,a0
    return -1;
    800032a2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800032a4:	0007c863          	bltz	a5,800032b4 <sys_wait+0x2a>
  return wait(p);
    800032a8:	fe843503          	ld	a0,-24(s0)
    800032ac:	fffff097          	auipc	ra,0xfffff
    800032b0:	e6c080e7          	jalr	-404(ra) # 80002118 <wait>
}
    800032b4:	60e2                	ld	ra,24(sp)
    800032b6:	6442                	ld	s0,16(sp)
    800032b8:	6105                	addi	sp,sp,32
    800032ba:	8082                	ret

00000000800032bc <sys_waitx>:

uint64
sys_waitx(void)
{
    800032bc:	7139                	addi	sp,sp,-64
    800032be:	fc06                	sd	ra,56(sp)
    800032c0:	f822                	sd	s0,48(sp)
    800032c2:	f426                	sd	s1,40(sp)
    800032c4:	f04a                	sd	s2,32(sp)
    800032c6:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime;
  uint rtime;
  if (argaddr(0, &addr) < 0)
    800032c8:	fd840593          	addi	a1,s0,-40
    800032cc:	4501                	li	a0,0
    800032ce:	00000097          	auipc	ra,0x0
    800032d2:	dbc080e7          	jalr	-580(ra) # 8000308a <argaddr>
    return -1;
    800032d6:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0)
    800032d8:	08054063          	bltz	a0,80003358 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0)
    800032dc:	fd040593          	addi	a1,s0,-48
    800032e0:	4505                	li	a0,1
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	da8080e7          	jalr	-600(ra) # 8000308a <argaddr>
    return -1;
    800032ea:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0)
    800032ec:	06054663          	bltz	a0,80003358 <sys_waitx+0x9c>
  if (argaddr(2, &addr2) < 0)
    800032f0:	fc840593          	addi	a1,s0,-56
    800032f4:	4509                	li	a0,2
    800032f6:	00000097          	auipc	ra,0x0
    800032fa:	d94080e7          	jalr	-620(ra) # 8000308a <argaddr>
    return -1;
    800032fe:	57fd                	li	a5,-1
  if (argaddr(2, &addr2) < 0)
    80003300:	04054c63          	bltz	a0,80003358 <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    80003304:	fc040613          	addi	a2,s0,-64
    80003308:	fc440593          	addi	a1,s0,-60
    8000330c:	fd843503          	ld	a0,-40(s0)
    80003310:	fffff097          	auipc	ra,0xfffff
    80003314:	622080e7          	jalr	1570(ra) # 80002932 <waitx>
    80003318:	892a                	mv	s2,a0
  struct proc* p = myproc();
    8000331a:	ffffe097          	auipc	ra,0xffffe
    8000331e:	6ba080e7          	jalr	1722(ra) # 800019d4 <myproc>
    80003322:	84aa                	mv	s1,a0
  if(copyout(p->pagetable, addr1, (char *)&wtime, sizeof(uint)) < 0)
    80003324:	4691                	li	a3,4
    80003326:	fc440613          	addi	a2,s0,-60
    8000332a:	fd043583          	ld	a1,-48(s0)
    8000332e:	6928                	ld	a0,80(a0)
    80003330:	ffffe097          	auipc	ra,0xffffe
    80003334:	342080e7          	jalr	834(ra) # 80001672 <copyout>
    return -1;
    80003338:	57fd                	li	a5,-1
  if(copyout(p->pagetable, addr1, (char *)&wtime, sizeof(uint)) < 0)
    8000333a:	00054f63          	bltz	a0,80003358 <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000333e:	4691                	li	a3,4
    80003340:	fc040613          	addi	a2,s0,-64
    80003344:	fc843583          	ld	a1,-56(s0)
    80003348:	68a8                	ld	a0,80(s1)
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	328080e7          	jalr	808(ra) # 80001672 <copyout>
    80003352:	00054a63          	bltz	a0,80003366 <sys_waitx+0xaa>
    return -1;
  return ret;
    80003356:	87ca                	mv	a5,s2
}
    80003358:	853e                	mv	a0,a5
    8000335a:	70e2                	ld	ra,56(sp)
    8000335c:	7442                	ld	s0,48(sp)
    8000335e:	74a2                	ld	s1,40(sp)
    80003360:	7902                	ld	s2,32(sp)
    80003362:	6121                	addi	sp,sp,64
    80003364:	8082                	ret
    return -1;
    80003366:	57fd                	li	a5,-1
    80003368:	bfc5                	j	80003358 <sys_waitx+0x9c>

000000008000336a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000336a:	7179                	addi	sp,sp,-48
    8000336c:	f406                	sd	ra,40(sp)
    8000336e:	f022                	sd	s0,32(sp)
    80003370:	ec26                	sd	s1,24(sp)
    80003372:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003374:	fdc40593          	addi	a1,s0,-36
    80003378:	4501                	li	a0,0
    8000337a:	00000097          	auipc	ra,0x0
    8000337e:	cee080e7          	jalr	-786(ra) # 80003068 <argint>
    80003382:	87aa                	mv	a5,a0
    return -1;
    80003384:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003386:	0207c063          	bltz	a5,800033a6 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	64a080e7          	jalr	1610(ra) # 800019d4 <myproc>
    80003392:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003394:	fdc42503          	lw	a0,-36(s0)
    80003398:	fffff097          	auipc	ra,0xfffff
    8000339c:	a24080e7          	jalr	-1500(ra) # 80001dbc <growproc>
    800033a0:	00054863          	bltz	a0,800033b0 <sys_sbrk+0x46>
    return -1;
  return addr;
    800033a4:	8526                	mv	a0,s1
}
    800033a6:	70a2                	ld	ra,40(sp)
    800033a8:	7402                	ld	s0,32(sp)
    800033aa:	64e2                	ld	s1,24(sp)
    800033ac:	6145                	addi	sp,sp,48
    800033ae:	8082                	ret
    return -1;
    800033b0:	557d                	li	a0,-1
    800033b2:	bfd5                	j	800033a6 <sys_sbrk+0x3c>

00000000800033b4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800033b4:	7139                	addi	sp,sp,-64
    800033b6:	fc06                	sd	ra,56(sp)
    800033b8:	f822                	sd	s0,48(sp)
    800033ba:	f426                	sd	s1,40(sp)
    800033bc:	f04a                	sd	s2,32(sp)
    800033be:	ec4e                	sd	s3,24(sp)
    800033c0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800033c2:	fcc40593          	addi	a1,s0,-52
    800033c6:	4501                	li	a0,0
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	ca0080e7          	jalr	-864(ra) # 80003068 <argint>
    return -1;
    800033d0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033d2:	06054563          	bltz	a0,8000343c <sys_sleep+0x88>
  acquire(&tickslock);
    800033d6:	00016517          	auipc	a0,0x16
    800033da:	97250513          	addi	a0,a0,-1678 # 80018d48 <tickslock>
    800033de:	ffffe097          	auipc	ra,0xffffe
    800033e2:	806080e7          	jalr	-2042(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800033e6:	00006917          	auipc	s2,0x6
    800033ea:	c4a92903          	lw	s2,-950(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800033ee:	fcc42783          	lw	a5,-52(s0)
    800033f2:	cf85                	beqz	a5,8000342a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033f4:	00016997          	auipc	s3,0x16
    800033f8:	95498993          	addi	s3,s3,-1708 # 80018d48 <tickslock>
    800033fc:	00006497          	auipc	s1,0x6
    80003400:	c3448493          	addi	s1,s1,-972 # 80009030 <ticks>
    if(myproc()->killed){
    80003404:	ffffe097          	auipc	ra,0xffffe
    80003408:	5d0080e7          	jalr	1488(ra) # 800019d4 <myproc>
    8000340c:	551c                	lw	a5,40(a0)
    8000340e:	ef9d                	bnez	a5,8000344c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003410:	85ce                	mv	a1,s3
    80003412:	8526                	mv	a0,s1
    80003414:	fffff097          	auipc	ra,0xfffff
    80003418:	ca0080e7          	jalr	-864(ra) # 800020b4 <sleep>
  while(ticks - ticks0 < n){
    8000341c:	409c                	lw	a5,0(s1)
    8000341e:	412787bb          	subw	a5,a5,s2
    80003422:	fcc42703          	lw	a4,-52(s0)
    80003426:	fce7efe3          	bltu	a5,a4,80003404 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000342a:	00016517          	auipc	a0,0x16
    8000342e:	91e50513          	addi	a0,a0,-1762 # 80018d48 <tickslock>
    80003432:	ffffe097          	auipc	ra,0xffffe
    80003436:	866080e7          	jalr	-1946(ra) # 80000c98 <release>
  return 0;
    8000343a:	4781                	li	a5,0
}
    8000343c:	853e                	mv	a0,a5
    8000343e:	70e2                	ld	ra,56(sp)
    80003440:	7442                	ld	s0,48(sp)
    80003442:	74a2                	ld	s1,40(sp)
    80003444:	7902                	ld	s2,32(sp)
    80003446:	69e2                	ld	s3,24(sp)
    80003448:	6121                	addi	sp,sp,64
    8000344a:	8082                	ret
      release(&tickslock);
    8000344c:	00016517          	auipc	a0,0x16
    80003450:	8fc50513          	addi	a0,a0,-1796 # 80018d48 <tickslock>
    80003454:	ffffe097          	auipc	ra,0xffffe
    80003458:	844080e7          	jalr	-1980(ra) # 80000c98 <release>
      return -1;
    8000345c:	57fd                	li	a5,-1
    8000345e:	bff9                	j	8000343c <sys_sleep+0x88>

0000000080003460 <sys_kill>:

uint64
sys_kill(void)
{
    80003460:	1101                	addi	sp,sp,-32
    80003462:	ec06                	sd	ra,24(sp)
    80003464:	e822                	sd	s0,16(sp)
    80003466:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003468:	fec40593          	addi	a1,s0,-20
    8000346c:	4501                	li	a0,0
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	bfa080e7          	jalr	-1030(ra) # 80003068 <argint>
    80003476:	87aa                	mv	a5,a0
    return -1;
    80003478:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000347a:	0007c863          	bltz	a5,8000348a <sys_kill+0x2a>
  return kill(pid);
    8000347e:	fec42503          	lw	a0,-20(s0)
    80003482:	fffff097          	auipc	ra,0xfffff
    80003486:	f70080e7          	jalr	-144(ra) # 800023f2 <kill>
}
    8000348a:	60e2                	ld	ra,24(sp)
    8000348c:	6442                	ld	s0,16(sp)
    8000348e:	6105                	addi	sp,sp,32
    80003490:	8082                	ret

0000000080003492 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003492:	1101                	addi	sp,sp,-32
    80003494:	ec06                	sd	ra,24(sp)
    80003496:	e822                	sd	s0,16(sp)
    80003498:	e426                	sd	s1,8(sp)
    8000349a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000349c:	00016517          	auipc	a0,0x16
    800034a0:	8ac50513          	addi	a0,a0,-1876 # 80018d48 <tickslock>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	740080e7          	jalr	1856(ra) # 80000be4 <acquire>
  xticks = ticks;
    800034ac:	00006497          	auipc	s1,0x6
    800034b0:	b844a483          	lw	s1,-1148(s1) # 80009030 <ticks>
  release(&tickslock);
    800034b4:	00016517          	auipc	a0,0x16
    800034b8:	89450513          	addi	a0,a0,-1900 # 80018d48 <tickslock>
    800034bc:	ffffd097          	auipc	ra,0xffffd
    800034c0:	7dc080e7          	jalr	2012(ra) # 80000c98 <release>
  return xticks;
}
    800034c4:	02049513          	slli	a0,s1,0x20
    800034c8:	9101                	srli	a0,a0,0x20
    800034ca:	60e2                	ld	ra,24(sp)
    800034cc:	6442                	ld	s0,16(sp)
    800034ce:	64a2                	ld	s1,8(sp)
    800034d0:	6105                	addi	sp,sp,32
    800034d2:	8082                	ret

00000000800034d4 <sys_trace>:

uint64 sys_trace(void)
{
    800034d4:	1101                	addi	sp,sp,-32
    800034d6:	ec06                	sd	ra,24(sp)
    800034d8:	e822                	sd	s0,16(sp)
    800034da:	1000                	addi	s0,sp,32
  int mask = 0;
    800034dc:	fe042623          	sw	zero,-20(s0)
  if (argint(0, &mask) < 0)
    800034e0:	fec40593          	addi	a1,s0,-20
    800034e4:	4501                	li	a0,0
    800034e6:	00000097          	auipc	ra,0x0
    800034ea:	b82080e7          	jalr	-1150(ra) # 80003068 <argint>
    return -1;
    800034ee:	57fd                	li	a5,-1
  if (argint(0, &mask) < 0)
    800034f0:	00054a63          	bltz	a0,80003504 <sys_trace+0x30>
  myproc()->mask = mask;
    800034f4:	ffffe097          	auipc	ra,0xffffe
    800034f8:	4e0080e7          	jalr	1248(ra) # 800019d4 <myproc>
    800034fc:	fec42783          	lw	a5,-20(s0)
    80003500:	d95c                	sw	a5,52(a0)
  return 0;
    80003502:	4781                	li	a5,0
}
    80003504:	853e                	mv	a0,a5
    80003506:	60e2                	ld	ra,24(sp)
    80003508:	6442                	ld	s0,16(sp)
    8000350a:	6105                	addi	sp,sp,32
    8000350c:	8082                	ret

000000008000350e <sys_set_priority>:

uint64 sys_set_priority(void)
{
    8000350e:	1101                	addi	sp,sp,-32
    80003510:	ec06                	sd	ra,24(sp)
    80003512:	e822                	sd	s0,16(sp)
    80003514:	1000                	addi	s0,sp,32
  int priority, pid;
  if (argint(0, &priority) < 0)
    80003516:	fec40593          	addi	a1,s0,-20
    8000351a:	4501                	li	a0,0
    8000351c:	00000097          	auipc	ra,0x0
    80003520:	b4c080e7          	jalr	-1204(ra) # 80003068 <argint>
    return -1;
    80003524:	57fd                	li	a5,-1
  if (argint(0, &priority) < 0)
    80003526:	02054563          	bltz	a0,80003550 <sys_set_priority+0x42>
  if (argint(0, &pid) < 0)
    8000352a:	fe840593          	addi	a1,s0,-24
    8000352e:	4501                	li	a0,0
    80003530:	00000097          	auipc	ra,0x0
    80003534:	b38080e7          	jalr	-1224(ra) # 80003068 <argint>
    return -1;
    80003538:	57fd                	li	a5,-1
  if (argint(0, &pid) < 0)
    8000353a:	00054b63          	bltz	a0,80003550 <sys_set_priority+0x42>
  return set_priority(priority, pid);
    8000353e:	fe842583          	lw	a1,-24(s0)
    80003542:	fec42503          	lw	a0,-20(s0)
    80003546:	fffff097          	auipc	ra,0xfffff
    8000354a:	5b4080e7          	jalr	1460(ra) # 80002afa <set_priority>
    8000354e:	87aa                	mv	a5,a0
    80003550:	853e                	mv	a0,a5
    80003552:	60e2                	ld	ra,24(sp)
    80003554:	6442                	ld	s0,16(sp)
    80003556:	6105                	addi	sp,sp,32
    80003558:	8082                	ret

000000008000355a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000355a:	7179                	addi	sp,sp,-48
    8000355c:	f406                	sd	ra,40(sp)
    8000355e:	f022                	sd	s0,32(sp)
    80003560:	ec26                	sd	s1,24(sp)
    80003562:	e84a                	sd	s2,16(sp)
    80003564:	e44e                	sd	s3,8(sp)
    80003566:	e052                	sd	s4,0(sp)
    80003568:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000356a:	00005597          	auipc	a1,0x5
    8000356e:	12e58593          	addi	a1,a1,302 # 80008698 <syscalls+0xc8>
    80003572:	00015517          	auipc	a0,0x15
    80003576:	7ee50513          	addi	a0,a0,2030 # 80018d60 <bcache>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	5da080e7          	jalr	1498(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003582:	0001d797          	auipc	a5,0x1d
    80003586:	7de78793          	addi	a5,a5,2014 # 80020d60 <bcache+0x8000>
    8000358a:	0001e717          	auipc	a4,0x1e
    8000358e:	a3e70713          	addi	a4,a4,-1474 # 80020fc8 <bcache+0x8268>
    80003592:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003596:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000359a:	00015497          	auipc	s1,0x15
    8000359e:	7de48493          	addi	s1,s1,2014 # 80018d78 <bcache+0x18>
    b->next = bcache.head.next;
    800035a2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035a4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035a6:	00005a17          	auipc	s4,0x5
    800035aa:	0faa0a13          	addi	s4,s4,250 # 800086a0 <syscalls+0xd0>
    b->next = bcache.head.next;
    800035ae:	2b893783          	ld	a5,696(s2)
    800035b2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035b4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035b8:	85d2                	mv	a1,s4
    800035ba:	01048513          	addi	a0,s1,16
    800035be:	00001097          	auipc	ra,0x1
    800035c2:	4bc080e7          	jalr	1212(ra) # 80004a7a <initsleeplock>
    bcache.head.next->prev = b;
    800035c6:	2b893783          	ld	a5,696(s2)
    800035ca:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035cc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035d0:	45848493          	addi	s1,s1,1112
    800035d4:	fd349de3          	bne	s1,s3,800035ae <binit+0x54>
  }
}
    800035d8:	70a2                	ld	ra,40(sp)
    800035da:	7402                	ld	s0,32(sp)
    800035dc:	64e2                	ld	s1,24(sp)
    800035de:	6942                	ld	s2,16(sp)
    800035e0:	69a2                	ld	s3,8(sp)
    800035e2:	6a02                	ld	s4,0(sp)
    800035e4:	6145                	addi	sp,sp,48
    800035e6:	8082                	ret

00000000800035e8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035e8:	7179                	addi	sp,sp,-48
    800035ea:	f406                	sd	ra,40(sp)
    800035ec:	f022                	sd	s0,32(sp)
    800035ee:	ec26                	sd	s1,24(sp)
    800035f0:	e84a                	sd	s2,16(sp)
    800035f2:	e44e                	sd	s3,8(sp)
    800035f4:	1800                	addi	s0,sp,48
    800035f6:	89aa                	mv	s3,a0
    800035f8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800035fa:	00015517          	auipc	a0,0x15
    800035fe:	76650513          	addi	a0,a0,1894 # 80018d60 <bcache>
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	5e2080e7          	jalr	1506(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000360a:	0001e497          	auipc	s1,0x1e
    8000360e:	a0e4b483          	ld	s1,-1522(s1) # 80021018 <bcache+0x82b8>
    80003612:	0001e797          	auipc	a5,0x1e
    80003616:	9b678793          	addi	a5,a5,-1610 # 80020fc8 <bcache+0x8268>
    8000361a:	02f48f63          	beq	s1,a5,80003658 <bread+0x70>
    8000361e:	873e                	mv	a4,a5
    80003620:	a021                	j	80003628 <bread+0x40>
    80003622:	68a4                	ld	s1,80(s1)
    80003624:	02e48a63          	beq	s1,a4,80003658 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003628:	449c                	lw	a5,8(s1)
    8000362a:	ff379ce3          	bne	a5,s3,80003622 <bread+0x3a>
    8000362e:	44dc                	lw	a5,12(s1)
    80003630:	ff2799e3          	bne	a5,s2,80003622 <bread+0x3a>
      b->refcnt++;
    80003634:	40bc                	lw	a5,64(s1)
    80003636:	2785                	addiw	a5,a5,1
    80003638:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000363a:	00015517          	auipc	a0,0x15
    8000363e:	72650513          	addi	a0,a0,1830 # 80018d60 <bcache>
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	656080e7          	jalr	1622(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000364a:	01048513          	addi	a0,s1,16
    8000364e:	00001097          	auipc	ra,0x1
    80003652:	466080e7          	jalr	1126(ra) # 80004ab4 <acquiresleep>
      return b;
    80003656:	a8b9                	j	800036b4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003658:	0001e497          	auipc	s1,0x1e
    8000365c:	9b84b483          	ld	s1,-1608(s1) # 80021010 <bcache+0x82b0>
    80003660:	0001e797          	auipc	a5,0x1e
    80003664:	96878793          	addi	a5,a5,-1688 # 80020fc8 <bcache+0x8268>
    80003668:	00f48863          	beq	s1,a5,80003678 <bread+0x90>
    8000366c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000366e:	40bc                	lw	a5,64(s1)
    80003670:	cf81                	beqz	a5,80003688 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003672:	64a4                	ld	s1,72(s1)
    80003674:	fee49de3          	bne	s1,a4,8000366e <bread+0x86>
  panic("bget: no buffers");
    80003678:	00005517          	auipc	a0,0x5
    8000367c:	03050513          	addi	a0,a0,48 # 800086a8 <syscalls+0xd8>
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	ebe080e7          	jalr	-322(ra) # 8000053e <panic>
      b->dev = dev;
    80003688:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000368c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003690:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003694:	4785                	li	a5,1
    80003696:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003698:	00015517          	auipc	a0,0x15
    8000369c:	6c850513          	addi	a0,a0,1736 # 80018d60 <bcache>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	5f8080e7          	jalr	1528(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800036a8:	01048513          	addi	a0,s1,16
    800036ac:	00001097          	auipc	ra,0x1
    800036b0:	408080e7          	jalr	1032(ra) # 80004ab4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036b4:	409c                	lw	a5,0(s1)
    800036b6:	cb89                	beqz	a5,800036c8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036b8:	8526                	mv	a0,s1
    800036ba:	70a2                	ld	ra,40(sp)
    800036bc:	7402                	ld	s0,32(sp)
    800036be:	64e2                	ld	s1,24(sp)
    800036c0:	6942                	ld	s2,16(sp)
    800036c2:	69a2                	ld	s3,8(sp)
    800036c4:	6145                	addi	sp,sp,48
    800036c6:	8082                	ret
    virtio_disk_rw(b, 0);
    800036c8:	4581                	li	a1,0
    800036ca:	8526                	mv	a0,s1
    800036cc:	00003097          	auipc	ra,0x3
    800036d0:	f0a080e7          	jalr	-246(ra) # 800065d6 <virtio_disk_rw>
    b->valid = 1;
    800036d4:	4785                	li	a5,1
    800036d6:	c09c                	sw	a5,0(s1)
  return b;
    800036d8:	b7c5                	j	800036b8 <bread+0xd0>

00000000800036da <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036da:	1101                	addi	sp,sp,-32
    800036dc:	ec06                	sd	ra,24(sp)
    800036de:	e822                	sd	s0,16(sp)
    800036e0:	e426                	sd	s1,8(sp)
    800036e2:	1000                	addi	s0,sp,32
    800036e4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036e6:	0541                	addi	a0,a0,16
    800036e8:	00001097          	auipc	ra,0x1
    800036ec:	466080e7          	jalr	1126(ra) # 80004b4e <holdingsleep>
    800036f0:	cd01                	beqz	a0,80003708 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036f2:	4585                	li	a1,1
    800036f4:	8526                	mv	a0,s1
    800036f6:	00003097          	auipc	ra,0x3
    800036fa:	ee0080e7          	jalr	-288(ra) # 800065d6 <virtio_disk_rw>
}
    800036fe:	60e2                	ld	ra,24(sp)
    80003700:	6442                	ld	s0,16(sp)
    80003702:	64a2                	ld	s1,8(sp)
    80003704:	6105                	addi	sp,sp,32
    80003706:	8082                	ret
    panic("bwrite");
    80003708:	00005517          	auipc	a0,0x5
    8000370c:	fb850513          	addi	a0,a0,-72 # 800086c0 <syscalls+0xf0>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	e2e080e7          	jalr	-466(ra) # 8000053e <panic>

0000000080003718 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003718:	1101                	addi	sp,sp,-32
    8000371a:	ec06                	sd	ra,24(sp)
    8000371c:	e822                	sd	s0,16(sp)
    8000371e:	e426                	sd	s1,8(sp)
    80003720:	e04a                	sd	s2,0(sp)
    80003722:	1000                	addi	s0,sp,32
    80003724:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003726:	01050913          	addi	s2,a0,16
    8000372a:	854a                	mv	a0,s2
    8000372c:	00001097          	auipc	ra,0x1
    80003730:	422080e7          	jalr	1058(ra) # 80004b4e <holdingsleep>
    80003734:	c92d                	beqz	a0,800037a6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003736:	854a                	mv	a0,s2
    80003738:	00001097          	auipc	ra,0x1
    8000373c:	3d2080e7          	jalr	978(ra) # 80004b0a <releasesleep>

  acquire(&bcache.lock);
    80003740:	00015517          	auipc	a0,0x15
    80003744:	62050513          	addi	a0,a0,1568 # 80018d60 <bcache>
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	49c080e7          	jalr	1180(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003750:	40bc                	lw	a5,64(s1)
    80003752:	37fd                	addiw	a5,a5,-1
    80003754:	0007871b          	sext.w	a4,a5
    80003758:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000375a:	eb05                	bnez	a4,8000378a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000375c:	68bc                	ld	a5,80(s1)
    8000375e:	64b8                	ld	a4,72(s1)
    80003760:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003762:	64bc                	ld	a5,72(s1)
    80003764:	68b8                	ld	a4,80(s1)
    80003766:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003768:	0001d797          	auipc	a5,0x1d
    8000376c:	5f878793          	addi	a5,a5,1528 # 80020d60 <bcache+0x8000>
    80003770:	2b87b703          	ld	a4,696(a5)
    80003774:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003776:	0001e717          	auipc	a4,0x1e
    8000377a:	85270713          	addi	a4,a4,-1966 # 80020fc8 <bcache+0x8268>
    8000377e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003780:	2b87b703          	ld	a4,696(a5)
    80003784:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003786:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000378a:	00015517          	auipc	a0,0x15
    8000378e:	5d650513          	addi	a0,a0,1494 # 80018d60 <bcache>
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	506080e7          	jalr	1286(ra) # 80000c98 <release>
}
    8000379a:	60e2                	ld	ra,24(sp)
    8000379c:	6442                	ld	s0,16(sp)
    8000379e:	64a2                	ld	s1,8(sp)
    800037a0:	6902                	ld	s2,0(sp)
    800037a2:	6105                	addi	sp,sp,32
    800037a4:	8082                	ret
    panic("brelse");
    800037a6:	00005517          	auipc	a0,0x5
    800037aa:	f2250513          	addi	a0,a0,-222 # 800086c8 <syscalls+0xf8>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	d90080e7          	jalr	-624(ra) # 8000053e <panic>

00000000800037b6 <bpin>:

void
bpin(struct buf *b) {
    800037b6:	1101                	addi	sp,sp,-32
    800037b8:	ec06                	sd	ra,24(sp)
    800037ba:	e822                	sd	s0,16(sp)
    800037bc:	e426                	sd	s1,8(sp)
    800037be:	1000                	addi	s0,sp,32
    800037c0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037c2:	00015517          	auipc	a0,0x15
    800037c6:	59e50513          	addi	a0,a0,1438 # 80018d60 <bcache>
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	41a080e7          	jalr	1050(ra) # 80000be4 <acquire>
  b->refcnt++;
    800037d2:	40bc                	lw	a5,64(s1)
    800037d4:	2785                	addiw	a5,a5,1
    800037d6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037d8:	00015517          	auipc	a0,0x15
    800037dc:	58850513          	addi	a0,a0,1416 # 80018d60 <bcache>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	4b8080e7          	jalr	1208(ra) # 80000c98 <release>
}
    800037e8:	60e2                	ld	ra,24(sp)
    800037ea:	6442                	ld	s0,16(sp)
    800037ec:	64a2                	ld	s1,8(sp)
    800037ee:	6105                	addi	sp,sp,32
    800037f0:	8082                	ret

00000000800037f2 <bunpin>:

void
bunpin(struct buf *b) {
    800037f2:	1101                	addi	sp,sp,-32
    800037f4:	ec06                	sd	ra,24(sp)
    800037f6:	e822                	sd	s0,16(sp)
    800037f8:	e426                	sd	s1,8(sp)
    800037fa:	1000                	addi	s0,sp,32
    800037fc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037fe:	00015517          	auipc	a0,0x15
    80003802:	56250513          	addi	a0,a0,1378 # 80018d60 <bcache>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	3de080e7          	jalr	990(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000380e:	40bc                	lw	a5,64(s1)
    80003810:	37fd                	addiw	a5,a5,-1
    80003812:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003814:	00015517          	auipc	a0,0x15
    80003818:	54c50513          	addi	a0,a0,1356 # 80018d60 <bcache>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	47c080e7          	jalr	1148(ra) # 80000c98 <release>
}
    80003824:	60e2                	ld	ra,24(sp)
    80003826:	6442                	ld	s0,16(sp)
    80003828:	64a2                	ld	s1,8(sp)
    8000382a:	6105                	addi	sp,sp,32
    8000382c:	8082                	ret

000000008000382e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000382e:	1101                	addi	sp,sp,-32
    80003830:	ec06                	sd	ra,24(sp)
    80003832:	e822                	sd	s0,16(sp)
    80003834:	e426                	sd	s1,8(sp)
    80003836:	e04a                	sd	s2,0(sp)
    80003838:	1000                	addi	s0,sp,32
    8000383a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000383c:	00d5d59b          	srliw	a1,a1,0xd
    80003840:	0001e797          	auipc	a5,0x1e
    80003844:	bfc7a783          	lw	a5,-1028(a5) # 8002143c <sb+0x1c>
    80003848:	9dbd                	addw	a1,a1,a5
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	d9e080e7          	jalr	-610(ra) # 800035e8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003852:	0074f713          	andi	a4,s1,7
    80003856:	4785                	li	a5,1
    80003858:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000385c:	14ce                	slli	s1,s1,0x33
    8000385e:	90d9                	srli	s1,s1,0x36
    80003860:	00950733          	add	a4,a0,s1
    80003864:	05874703          	lbu	a4,88(a4)
    80003868:	00e7f6b3          	and	a3,a5,a4
    8000386c:	c69d                	beqz	a3,8000389a <bfree+0x6c>
    8000386e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003870:	94aa                	add	s1,s1,a0
    80003872:	fff7c793          	not	a5,a5
    80003876:	8ff9                	and	a5,a5,a4
    80003878:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000387c:	00001097          	auipc	ra,0x1
    80003880:	118080e7          	jalr	280(ra) # 80004994 <log_write>
  brelse(bp);
    80003884:	854a                	mv	a0,s2
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	e92080e7          	jalr	-366(ra) # 80003718 <brelse>
}
    8000388e:	60e2                	ld	ra,24(sp)
    80003890:	6442                	ld	s0,16(sp)
    80003892:	64a2                	ld	s1,8(sp)
    80003894:	6902                	ld	s2,0(sp)
    80003896:	6105                	addi	sp,sp,32
    80003898:	8082                	ret
    panic("freeing free block");
    8000389a:	00005517          	auipc	a0,0x5
    8000389e:	e3650513          	addi	a0,a0,-458 # 800086d0 <syscalls+0x100>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	c9c080e7          	jalr	-868(ra) # 8000053e <panic>

00000000800038aa <balloc>:
{
    800038aa:	711d                	addi	sp,sp,-96
    800038ac:	ec86                	sd	ra,88(sp)
    800038ae:	e8a2                	sd	s0,80(sp)
    800038b0:	e4a6                	sd	s1,72(sp)
    800038b2:	e0ca                	sd	s2,64(sp)
    800038b4:	fc4e                	sd	s3,56(sp)
    800038b6:	f852                	sd	s4,48(sp)
    800038b8:	f456                	sd	s5,40(sp)
    800038ba:	f05a                	sd	s6,32(sp)
    800038bc:	ec5e                	sd	s7,24(sp)
    800038be:	e862                	sd	s8,16(sp)
    800038c0:	e466                	sd	s9,8(sp)
    800038c2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038c4:	0001e797          	auipc	a5,0x1e
    800038c8:	b607a783          	lw	a5,-1184(a5) # 80021424 <sb+0x4>
    800038cc:	cbd1                	beqz	a5,80003960 <balloc+0xb6>
    800038ce:	8baa                	mv	s7,a0
    800038d0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038d2:	0001eb17          	auipc	s6,0x1e
    800038d6:	b4eb0b13          	addi	s6,s6,-1202 # 80021420 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038da:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038dc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038de:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038e0:	6c89                	lui	s9,0x2
    800038e2:	a831                	j	800038fe <balloc+0x54>
    brelse(bp);
    800038e4:	854a                	mv	a0,s2
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	e32080e7          	jalr	-462(ra) # 80003718 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038ee:	015c87bb          	addw	a5,s9,s5
    800038f2:	00078a9b          	sext.w	s5,a5
    800038f6:	004b2703          	lw	a4,4(s6)
    800038fa:	06eaf363          	bgeu	s5,a4,80003960 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800038fe:	41fad79b          	sraiw	a5,s5,0x1f
    80003902:	0137d79b          	srliw	a5,a5,0x13
    80003906:	015787bb          	addw	a5,a5,s5
    8000390a:	40d7d79b          	sraiw	a5,a5,0xd
    8000390e:	01cb2583          	lw	a1,28(s6)
    80003912:	9dbd                	addw	a1,a1,a5
    80003914:	855e                	mv	a0,s7
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	cd2080e7          	jalr	-814(ra) # 800035e8 <bread>
    8000391e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003920:	004b2503          	lw	a0,4(s6)
    80003924:	000a849b          	sext.w	s1,s5
    80003928:	8662                	mv	a2,s8
    8000392a:	faa4fde3          	bgeu	s1,a0,800038e4 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000392e:	41f6579b          	sraiw	a5,a2,0x1f
    80003932:	01d7d69b          	srliw	a3,a5,0x1d
    80003936:	00c6873b          	addw	a4,a3,a2
    8000393a:	00777793          	andi	a5,a4,7
    8000393e:	9f95                	subw	a5,a5,a3
    80003940:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003944:	4037571b          	sraiw	a4,a4,0x3
    80003948:	00e906b3          	add	a3,s2,a4
    8000394c:	0586c683          	lbu	a3,88(a3)
    80003950:	00d7f5b3          	and	a1,a5,a3
    80003954:	cd91                	beqz	a1,80003970 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003956:	2605                	addiw	a2,a2,1
    80003958:	2485                	addiw	s1,s1,1
    8000395a:	fd4618e3          	bne	a2,s4,8000392a <balloc+0x80>
    8000395e:	b759                	j	800038e4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003960:	00005517          	auipc	a0,0x5
    80003964:	d8850513          	addi	a0,a0,-632 # 800086e8 <syscalls+0x118>
    80003968:	ffffd097          	auipc	ra,0xffffd
    8000396c:	bd6080e7          	jalr	-1066(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003970:	974a                	add	a4,a4,s2
    80003972:	8fd5                	or	a5,a5,a3
    80003974:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003978:	854a                	mv	a0,s2
    8000397a:	00001097          	auipc	ra,0x1
    8000397e:	01a080e7          	jalr	26(ra) # 80004994 <log_write>
        brelse(bp);
    80003982:	854a                	mv	a0,s2
    80003984:	00000097          	auipc	ra,0x0
    80003988:	d94080e7          	jalr	-620(ra) # 80003718 <brelse>
  bp = bread(dev, bno);
    8000398c:	85a6                	mv	a1,s1
    8000398e:	855e                	mv	a0,s7
    80003990:	00000097          	auipc	ra,0x0
    80003994:	c58080e7          	jalr	-936(ra) # 800035e8 <bread>
    80003998:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000399a:	40000613          	li	a2,1024
    8000399e:	4581                	li	a1,0
    800039a0:	05850513          	addi	a0,a0,88
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	33c080e7          	jalr	828(ra) # 80000ce0 <memset>
  log_write(bp);
    800039ac:	854a                	mv	a0,s2
    800039ae:	00001097          	auipc	ra,0x1
    800039b2:	fe6080e7          	jalr	-26(ra) # 80004994 <log_write>
  brelse(bp);
    800039b6:	854a                	mv	a0,s2
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	d60080e7          	jalr	-672(ra) # 80003718 <brelse>
}
    800039c0:	8526                	mv	a0,s1
    800039c2:	60e6                	ld	ra,88(sp)
    800039c4:	6446                	ld	s0,80(sp)
    800039c6:	64a6                	ld	s1,72(sp)
    800039c8:	6906                	ld	s2,64(sp)
    800039ca:	79e2                	ld	s3,56(sp)
    800039cc:	7a42                	ld	s4,48(sp)
    800039ce:	7aa2                	ld	s5,40(sp)
    800039d0:	7b02                	ld	s6,32(sp)
    800039d2:	6be2                	ld	s7,24(sp)
    800039d4:	6c42                	ld	s8,16(sp)
    800039d6:	6ca2                	ld	s9,8(sp)
    800039d8:	6125                	addi	sp,sp,96
    800039da:	8082                	ret

00000000800039dc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800039dc:	7179                	addi	sp,sp,-48
    800039de:	f406                	sd	ra,40(sp)
    800039e0:	f022                	sd	s0,32(sp)
    800039e2:	ec26                	sd	s1,24(sp)
    800039e4:	e84a                	sd	s2,16(sp)
    800039e6:	e44e                	sd	s3,8(sp)
    800039e8:	e052                	sd	s4,0(sp)
    800039ea:	1800                	addi	s0,sp,48
    800039ec:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039ee:	47ad                	li	a5,11
    800039f0:	04b7fe63          	bgeu	a5,a1,80003a4c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800039f4:	ff45849b          	addiw	s1,a1,-12
    800039f8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039fc:	0ff00793          	li	a5,255
    80003a00:	0ae7e363          	bltu	a5,a4,80003aa6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a04:	08052583          	lw	a1,128(a0)
    80003a08:	c5ad                	beqz	a1,80003a72 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a0a:	00092503          	lw	a0,0(s2)
    80003a0e:	00000097          	auipc	ra,0x0
    80003a12:	bda080e7          	jalr	-1062(ra) # 800035e8 <bread>
    80003a16:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a18:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a1c:	02049593          	slli	a1,s1,0x20
    80003a20:	9181                	srli	a1,a1,0x20
    80003a22:	058a                	slli	a1,a1,0x2
    80003a24:	00b784b3          	add	s1,a5,a1
    80003a28:	0004a983          	lw	s3,0(s1)
    80003a2c:	04098d63          	beqz	s3,80003a86 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a30:	8552                	mv	a0,s4
    80003a32:	00000097          	auipc	ra,0x0
    80003a36:	ce6080e7          	jalr	-794(ra) # 80003718 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a3a:	854e                	mv	a0,s3
    80003a3c:	70a2                	ld	ra,40(sp)
    80003a3e:	7402                	ld	s0,32(sp)
    80003a40:	64e2                	ld	s1,24(sp)
    80003a42:	6942                	ld	s2,16(sp)
    80003a44:	69a2                	ld	s3,8(sp)
    80003a46:	6a02                	ld	s4,0(sp)
    80003a48:	6145                	addi	sp,sp,48
    80003a4a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a4c:	02059493          	slli	s1,a1,0x20
    80003a50:	9081                	srli	s1,s1,0x20
    80003a52:	048a                	slli	s1,s1,0x2
    80003a54:	94aa                	add	s1,s1,a0
    80003a56:	0504a983          	lw	s3,80(s1)
    80003a5a:	fe0990e3          	bnez	s3,80003a3a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a5e:	4108                	lw	a0,0(a0)
    80003a60:	00000097          	auipc	ra,0x0
    80003a64:	e4a080e7          	jalr	-438(ra) # 800038aa <balloc>
    80003a68:	0005099b          	sext.w	s3,a0
    80003a6c:	0534a823          	sw	s3,80(s1)
    80003a70:	b7e9                	j	80003a3a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003a72:	4108                	lw	a0,0(a0)
    80003a74:	00000097          	auipc	ra,0x0
    80003a78:	e36080e7          	jalr	-458(ra) # 800038aa <balloc>
    80003a7c:	0005059b          	sext.w	a1,a0
    80003a80:	08b92023          	sw	a1,128(s2)
    80003a84:	b759                	j	80003a0a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003a86:	00092503          	lw	a0,0(s2)
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	e20080e7          	jalr	-480(ra) # 800038aa <balloc>
    80003a92:	0005099b          	sext.w	s3,a0
    80003a96:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003a9a:	8552                	mv	a0,s4
    80003a9c:	00001097          	auipc	ra,0x1
    80003aa0:	ef8080e7          	jalr	-264(ra) # 80004994 <log_write>
    80003aa4:	b771                	j	80003a30 <bmap+0x54>
  panic("bmap: out of range");
    80003aa6:	00005517          	auipc	a0,0x5
    80003aaa:	c5a50513          	addi	a0,a0,-934 # 80008700 <syscalls+0x130>
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	a90080e7          	jalr	-1392(ra) # 8000053e <panic>

0000000080003ab6 <iget>:
{
    80003ab6:	7179                	addi	sp,sp,-48
    80003ab8:	f406                	sd	ra,40(sp)
    80003aba:	f022                	sd	s0,32(sp)
    80003abc:	ec26                	sd	s1,24(sp)
    80003abe:	e84a                	sd	s2,16(sp)
    80003ac0:	e44e                	sd	s3,8(sp)
    80003ac2:	e052                	sd	s4,0(sp)
    80003ac4:	1800                	addi	s0,sp,48
    80003ac6:	89aa                	mv	s3,a0
    80003ac8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003aca:	0001e517          	auipc	a0,0x1e
    80003ace:	97650513          	addi	a0,a0,-1674 # 80021440 <itable>
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	112080e7          	jalr	274(ra) # 80000be4 <acquire>
  empty = 0;
    80003ada:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003adc:	0001e497          	auipc	s1,0x1e
    80003ae0:	97c48493          	addi	s1,s1,-1668 # 80021458 <itable+0x18>
    80003ae4:	0001f697          	auipc	a3,0x1f
    80003ae8:	40468693          	addi	a3,a3,1028 # 80022ee8 <log>
    80003aec:	a039                	j	80003afa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003aee:	02090b63          	beqz	s2,80003b24 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003af2:	08848493          	addi	s1,s1,136
    80003af6:	02d48a63          	beq	s1,a3,80003b2a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003afa:	449c                	lw	a5,8(s1)
    80003afc:	fef059e3          	blez	a5,80003aee <iget+0x38>
    80003b00:	4098                	lw	a4,0(s1)
    80003b02:	ff3716e3          	bne	a4,s3,80003aee <iget+0x38>
    80003b06:	40d8                	lw	a4,4(s1)
    80003b08:	ff4713e3          	bne	a4,s4,80003aee <iget+0x38>
      ip->ref++;
    80003b0c:	2785                	addiw	a5,a5,1
    80003b0e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b10:	0001e517          	auipc	a0,0x1e
    80003b14:	93050513          	addi	a0,a0,-1744 # 80021440 <itable>
    80003b18:	ffffd097          	auipc	ra,0xffffd
    80003b1c:	180080e7          	jalr	384(ra) # 80000c98 <release>
      return ip;
    80003b20:	8926                	mv	s2,s1
    80003b22:	a03d                	j	80003b50 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b24:	f7f9                	bnez	a5,80003af2 <iget+0x3c>
    80003b26:	8926                	mv	s2,s1
    80003b28:	b7e9                	j	80003af2 <iget+0x3c>
  if(empty == 0)
    80003b2a:	02090c63          	beqz	s2,80003b62 <iget+0xac>
  ip->dev = dev;
    80003b2e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b32:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b36:	4785                	li	a5,1
    80003b38:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b3c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b40:	0001e517          	auipc	a0,0x1e
    80003b44:	90050513          	addi	a0,a0,-1792 # 80021440 <itable>
    80003b48:	ffffd097          	auipc	ra,0xffffd
    80003b4c:	150080e7          	jalr	336(ra) # 80000c98 <release>
}
    80003b50:	854a                	mv	a0,s2
    80003b52:	70a2                	ld	ra,40(sp)
    80003b54:	7402                	ld	s0,32(sp)
    80003b56:	64e2                	ld	s1,24(sp)
    80003b58:	6942                	ld	s2,16(sp)
    80003b5a:	69a2                	ld	s3,8(sp)
    80003b5c:	6a02                	ld	s4,0(sp)
    80003b5e:	6145                	addi	sp,sp,48
    80003b60:	8082                	ret
    panic("iget: no inodes");
    80003b62:	00005517          	auipc	a0,0x5
    80003b66:	bb650513          	addi	a0,a0,-1098 # 80008718 <syscalls+0x148>
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	9d4080e7          	jalr	-1580(ra) # 8000053e <panic>

0000000080003b72 <fsinit>:
fsinit(int dev) {
    80003b72:	7179                	addi	sp,sp,-48
    80003b74:	f406                	sd	ra,40(sp)
    80003b76:	f022                	sd	s0,32(sp)
    80003b78:	ec26                	sd	s1,24(sp)
    80003b7a:	e84a                	sd	s2,16(sp)
    80003b7c:	e44e                	sd	s3,8(sp)
    80003b7e:	1800                	addi	s0,sp,48
    80003b80:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b82:	4585                	li	a1,1
    80003b84:	00000097          	auipc	ra,0x0
    80003b88:	a64080e7          	jalr	-1436(ra) # 800035e8 <bread>
    80003b8c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b8e:	0001e997          	auipc	s3,0x1e
    80003b92:	89298993          	addi	s3,s3,-1902 # 80021420 <sb>
    80003b96:	02000613          	li	a2,32
    80003b9a:	05850593          	addi	a1,a0,88
    80003b9e:	854e                	mv	a0,s3
    80003ba0:	ffffd097          	auipc	ra,0xffffd
    80003ba4:	1a0080e7          	jalr	416(ra) # 80000d40 <memmove>
  brelse(bp);
    80003ba8:	8526                	mv	a0,s1
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	b6e080e7          	jalr	-1170(ra) # 80003718 <brelse>
  if(sb.magic != FSMAGIC)
    80003bb2:	0009a703          	lw	a4,0(s3)
    80003bb6:	102037b7          	lui	a5,0x10203
    80003bba:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003bbe:	02f71263          	bne	a4,a5,80003be2 <fsinit+0x70>
  initlog(dev, &sb);
    80003bc2:	0001e597          	auipc	a1,0x1e
    80003bc6:	85e58593          	addi	a1,a1,-1954 # 80021420 <sb>
    80003bca:	854a                	mv	a0,s2
    80003bcc:	00001097          	auipc	ra,0x1
    80003bd0:	b4c080e7          	jalr	-1204(ra) # 80004718 <initlog>
}
    80003bd4:	70a2                	ld	ra,40(sp)
    80003bd6:	7402                	ld	s0,32(sp)
    80003bd8:	64e2                	ld	s1,24(sp)
    80003bda:	6942                	ld	s2,16(sp)
    80003bdc:	69a2                	ld	s3,8(sp)
    80003bde:	6145                	addi	sp,sp,48
    80003be0:	8082                	ret
    panic("invalid file system");
    80003be2:	00005517          	auipc	a0,0x5
    80003be6:	b4650513          	addi	a0,a0,-1210 # 80008728 <syscalls+0x158>
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	954080e7          	jalr	-1708(ra) # 8000053e <panic>

0000000080003bf2 <iinit>:
{
    80003bf2:	7179                	addi	sp,sp,-48
    80003bf4:	f406                	sd	ra,40(sp)
    80003bf6:	f022                	sd	s0,32(sp)
    80003bf8:	ec26                	sd	s1,24(sp)
    80003bfa:	e84a                	sd	s2,16(sp)
    80003bfc:	e44e                	sd	s3,8(sp)
    80003bfe:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c00:	00005597          	auipc	a1,0x5
    80003c04:	b4058593          	addi	a1,a1,-1216 # 80008740 <syscalls+0x170>
    80003c08:	0001e517          	auipc	a0,0x1e
    80003c0c:	83850513          	addi	a0,a0,-1992 # 80021440 <itable>
    80003c10:	ffffd097          	auipc	ra,0xffffd
    80003c14:	f44080e7          	jalr	-188(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c18:	0001e497          	auipc	s1,0x1e
    80003c1c:	85048493          	addi	s1,s1,-1968 # 80021468 <itable+0x28>
    80003c20:	0001f997          	auipc	s3,0x1f
    80003c24:	2d898993          	addi	s3,s3,728 # 80022ef8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c28:	00005917          	auipc	s2,0x5
    80003c2c:	b2090913          	addi	s2,s2,-1248 # 80008748 <syscalls+0x178>
    80003c30:	85ca                	mv	a1,s2
    80003c32:	8526                	mv	a0,s1
    80003c34:	00001097          	auipc	ra,0x1
    80003c38:	e46080e7          	jalr	-442(ra) # 80004a7a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c3c:	08848493          	addi	s1,s1,136
    80003c40:	ff3498e3          	bne	s1,s3,80003c30 <iinit+0x3e>
}
    80003c44:	70a2                	ld	ra,40(sp)
    80003c46:	7402                	ld	s0,32(sp)
    80003c48:	64e2                	ld	s1,24(sp)
    80003c4a:	6942                	ld	s2,16(sp)
    80003c4c:	69a2                	ld	s3,8(sp)
    80003c4e:	6145                	addi	sp,sp,48
    80003c50:	8082                	ret

0000000080003c52 <ialloc>:
{
    80003c52:	715d                	addi	sp,sp,-80
    80003c54:	e486                	sd	ra,72(sp)
    80003c56:	e0a2                	sd	s0,64(sp)
    80003c58:	fc26                	sd	s1,56(sp)
    80003c5a:	f84a                	sd	s2,48(sp)
    80003c5c:	f44e                	sd	s3,40(sp)
    80003c5e:	f052                	sd	s4,32(sp)
    80003c60:	ec56                	sd	s5,24(sp)
    80003c62:	e85a                	sd	s6,16(sp)
    80003c64:	e45e                	sd	s7,8(sp)
    80003c66:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c68:	0001d717          	auipc	a4,0x1d
    80003c6c:	7c472703          	lw	a4,1988(a4) # 8002142c <sb+0xc>
    80003c70:	4785                	li	a5,1
    80003c72:	04e7fa63          	bgeu	a5,a4,80003cc6 <ialloc+0x74>
    80003c76:	8aaa                	mv	s5,a0
    80003c78:	8bae                	mv	s7,a1
    80003c7a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c7c:	0001da17          	auipc	s4,0x1d
    80003c80:	7a4a0a13          	addi	s4,s4,1956 # 80021420 <sb>
    80003c84:	00048b1b          	sext.w	s6,s1
    80003c88:	0044d593          	srli	a1,s1,0x4
    80003c8c:	018a2783          	lw	a5,24(s4)
    80003c90:	9dbd                	addw	a1,a1,a5
    80003c92:	8556                	mv	a0,s5
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	954080e7          	jalr	-1708(ra) # 800035e8 <bread>
    80003c9c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c9e:	05850993          	addi	s3,a0,88
    80003ca2:	00f4f793          	andi	a5,s1,15
    80003ca6:	079a                	slli	a5,a5,0x6
    80003ca8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003caa:	00099783          	lh	a5,0(s3)
    80003cae:	c785                	beqz	a5,80003cd6 <ialloc+0x84>
    brelse(bp);
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	a68080e7          	jalr	-1432(ra) # 80003718 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cb8:	0485                	addi	s1,s1,1
    80003cba:	00ca2703          	lw	a4,12(s4)
    80003cbe:	0004879b          	sext.w	a5,s1
    80003cc2:	fce7e1e3          	bltu	a5,a4,80003c84 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003cc6:	00005517          	auipc	a0,0x5
    80003cca:	a8a50513          	addi	a0,a0,-1398 # 80008750 <syscalls+0x180>
    80003cce:	ffffd097          	auipc	ra,0xffffd
    80003cd2:	870080e7          	jalr	-1936(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003cd6:	04000613          	li	a2,64
    80003cda:	4581                	li	a1,0
    80003cdc:	854e                	mv	a0,s3
    80003cde:	ffffd097          	auipc	ra,0xffffd
    80003ce2:	002080e7          	jalr	2(ra) # 80000ce0 <memset>
      dip->type = type;
    80003ce6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003cea:	854a                	mv	a0,s2
    80003cec:	00001097          	auipc	ra,0x1
    80003cf0:	ca8080e7          	jalr	-856(ra) # 80004994 <log_write>
      brelse(bp);
    80003cf4:	854a                	mv	a0,s2
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	a22080e7          	jalr	-1502(ra) # 80003718 <brelse>
      return iget(dev, inum);
    80003cfe:	85da                	mv	a1,s6
    80003d00:	8556                	mv	a0,s5
    80003d02:	00000097          	auipc	ra,0x0
    80003d06:	db4080e7          	jalr	-588(ra) # 80003ab6 <iget>
}
    80003d0a:	60a6                	ld	ra,72(sp)
    80003d0c:	6406                	ld	s0,64(sp)
    80003d0e:	74e2                	ld	s1,56(sp)
    80003d10:	7942                	ld	s2,48(sp)
    80003d12:	79a2                	ld	s3,40(sp)
    80003d14:	7a02                	ld	s4,32(sp)
    80003d16:	6ae2                	ld	s5,24(sp)
    80003d18:	6b42                	ld	s6,16(sp)
    80003d1a:	6ba2                	ld	s7,8(sp)
    80003d1c:	6161                	addi	sp,sp,80
    80003d1e:	8082                	ret

0000000080003d20 <iupdate>:
{
    80003d20:	1101                	addi	sp,sp,-32
    80003d22:	ec06                	sd	ra,24(sp)
    80003d24:	e822                	sd	s0,16(sp)
    80003d26:	e426                	sd	s1,8(sp)
    80003d28:	e04a                	sd	s2,0(sp)
    80003d2a:	1000                	addi	s0,sp,32
    80003d2c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d2e:	415c                	lw	a5,4(a0)
    80003d30:	0047d79b          	srliw	a5,a5,0x4
    80003d34:	0001d597          	auipc	a1,0x1d
    80003d38:	7045a583          	lw	a1,1796(a1) # 80021438 <sb+0x18>
    80003d3c:	9dbd                	addw	a1,a1,a5
    80003d3e:	4108                	lw	a0,0(a0)
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	8a8080e7          	jalr	-1880(ra) # 800035e8 <bread>
    80003d48:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d4a:	05850793          	addi	a5,a0,88
    80003d4e:	40c8                	lw	a0,4(s1)
    80003d50:	893d                	andi	a0,a0,15
    80003d52:	051a                	slli	a0,a0,0x6
    80003d54:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d56:	04449703          	lh	a4,68(s1)
    80003d5a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d5e:	04649703          	lh	a4,70(s1)
    80003d62:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d66:	04849703          	lh	a4,72(s1)
    80003d6a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d6e:	04a49703          	lh	a4,74(s1)
    80003d72:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d76:	44f8                	lw	a4,76(s1)
    80003d78:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d7a:	03400613          	li	a2,52
    80003d7e:	05048593          	addi	a1,s1,80
    80003d82:	0531                	addi	a0,a0,12
    80003d84:	ffffd097          	auipc	ra,0xffffd
    80003d88:	fbc080e7          	jalr	-68(ra) # 80000d40 <memmove>
  log_write(bp);
    80003d8c:	854a                	mv	a0,s2
    80003d8e:	00001097          	auipc	ra,0x1
    80003d92:	c06080e7          	jalr	-1018(ra) # 80004994 <log_write>
  brelse(bp);
    80003d96:	854a                	mv	a0,s2
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	980080e7          	jalr	-1664(ra) # 80003718 <brelse>
}
    80003da0:	60e2                	ld	ra,24(sp)
    80003da2:	6442                	ld	s0,16(sp)
    80003da4:	64a2                	ld	s1,8(sp)
    80003da6:	6902                	ld	s2,0(sp)
    80003da8:	6105                	addi	sp,sp,32
    80003daa:	8082                	ret

0000000080003dac <idup>:
{
    80003dac:	1101                	addi	sp,sp,-32
    80003dae:	ec06                	sd	ra,24(sp)
    80003db0:	e822                	sd	s0,16(sp)
    80003db2:	e426                	sd	s1,8(sp)
    80003db4:	1000                	addi	s0,sp,32
    80003db6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003db8:	0001d517          	auipc	a0,0x1d
    80003dbc:	68850513          	addi	a0,a0,1672 # 80021440 <itable>
    80003dc0:	ffffd097          	auipc	ra,0xffffd
    80003dc4:	e24080e7          	jalr	-476(ra) # 80000be4 <acquire>
  ip->ref++;
    80003dc8:	449c                	lw	a5,8(s1)
    80003dca:	2785                	addiw	a5,a5,1
    80003dcc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dce:	0001d517          	auipc	a0,0x1d
    80003dd2:	67250513          	addi	a0,a0,1650 # 80021440 <itable>
    80003dd6:	ffffd097          	auipc	ra,0xffffd
    80003dda:	ec2080e7          	jalr	-318(ra) # 80000c98 <release>
}
    80003dde:	8526                	mv	a0,s1
    80003de0:	60e2                	ld	ra,24(sp)
    80003de2:	6442                	ld	s0,16(sp)
    80003de4:	64a2                	ld	s1,8(sp)
    80003de6:	6105                	addi	sp,sp,32
    80003de8:	8082                	ret

0000000080003dea <ilock>:
{
    80003dea:	1101                	addi	sp,sp,-32
    80003dec:	ec06                	sd	ra,24(sp)
    80003dee:	e822                	sd	s0,16(sp)
    80003df0:	e426                	sd	s1,8(sp)
    80003df2:	e04a                	sd	s2,0(sp)
    80003df4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003df6:	c115                	beqz	a0,80003e1a <ilock+0x30>
    80003df8:	84aa                	mv	s1,a0
    80003dfa:	451c                	lw	a5,8(a0)
    80003dfc:	00f05f63          	blez	a5,80003e1a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e00:	0541                	addi	a0,a0,16
    80003e02:	00001097          	auipc	ra,0x1
    80003e06:	cb2080e7          	jalr	-846(ra) # 80004ab4 <acquiresleep>
  if(ip->valid == 0){
    80003e0a:	40bc                	lw	a5,64(s1)
    80003e0c:	cf99                	beqz	a5,80003e2a <ilock+0x40>
}
    80003e0e:	60e2                	ld	ra,24(sp)
    80003e10:	6442                	ld	s0,16(sp)
    80003e12:	64a2                	ld	s1,8(sp)
    80003e14:	6902                	ld	s2,0(sp)
    80003e16:	6105                	addi	sp,sp,32
    80003e18:	8082                	ret
    panic("ilock");
    80003e1a:	00005517          	auipc	a0,0x5
    80003e1e:	94e50513          	addi	a0,a0,-1714 # 80008768 <syscalls+0x198>
    80003e22:	ffffc097          	auipc	ra,0xffffc
    80003e26:	71c080e7          	jalr	1820(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e2a:	40dc                	lw	a5,4(s1)
    80003e2c:	0047d79b          	srliw	a5,a5,0x4
    80003e30:	0001d597          	auipc	a1,0x1d
    80003e34:	6085a583          	lw	a1,1544(a1) # 80021438 <sb+0x18>
    80003e38:	9dbd                	addw	a1,a1,a5
    80003e3a:	4088                	lw	a0,0(s1)
    80003e3c:	fffff097          	auipc	ra,0xfffff
    80003e40:	7ac080e7          	jalr	1964(ra) # 800035e8 <bread>
    80003e44:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e46:	05850593          	addi	a1,a0,88
    80003e4a:	40dc                	lw	a5,4(s1)
    80003e4c:	8bbd                	andi	a5,a5,15
    80003e4e:	079a                	slli	a5,a5,0x6
    80003e50:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e52:	00059783          	lh	a5,0(a1)
    80003e56:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e5a:	00259783          	lh	a5,2(a1)
    80003e5e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e62:	00459783          	lh	a5,4(a1)
    80003e66:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e6a:	00659783          	lh	a5,6(a1)
    80003e6e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e72:	459c                	lw	a5,8(a1)
    80003e74:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e76:	03400613          	li	a2,52
    80003e7a:	05b1                	addi	a1,a1,12
    80003e7c:	05048513          	addi	a0,s1,80
    80003e80:	ffffd097          	auipc	ra,0xffffd
    80003e84:	ec0080e7          	jalr	-320(ra) # 80000d40 <memmove>
    brelse(bp);
    80003e88:	854a                	mv	a0,s2
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	88e080e7          	jalr	-1906(ra) # 80003718 <brelse>
    ip->valid = 1;
    80003e92:	4785                	li	a5,1
    80003e94:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e96:	04449783          	lh	a5,68(s1)
    80003e9a:	fbb5                	bnez	a5,80003e0e <ilock+0x24>
      panic("ilock: no type");
    80003e9c:	00005517          	auipc	a0,0x5
    80003ea0:	8d450513          	addi	a0,a0,-1836 # 80008770 <syscalls+0x1a0>
    80003ea4:	ffffc097          	auipc	ra,0xffffc
    80003ea8:	69a080e7          	jalr	1690(ra) # 8000053e <panic>

0000000080003eac <iunlock>:
{
    80003eac:	1101                	addi	sp,sp,-32
    80003eae:	ec06                	sd	ra,24(sp)
    80003eb0:	e822                	sd	s0,16(sp)
    80003eb2:	e426                	sd	s1,8(sp)
    80003eb4:	e04a                	sd	s2,0(sp)
    80003eb6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003eb8:	c905                	beqz	a0,80003ee8 <iunlock+0x3c>
    80003eba:	84aa                	mv	s1,a0
    80003ebc:	01050913          	addi	s2,a0,16
    80003ec0:	854a                	mv	a0,s2
    80003ec2:	00001097          	auipc	ra,0x1
    80003ec6:	c8c080e7          	jalr	-884(ra) # 80004b4e <holdingsleep>
    80003eca:	cd19                	beqz	a0,80003ee8 <iunlock+0x3c>
    80003ecc:	449c                	lw	a5,8(s1)
    80003ece:	00f05d63          	blez	a5,80003ee8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ed2:	854a                	mv	a0,s2
    80003ed4:	00001097          	auipc	ra,0x1
    80003ed8:	c36080e7          	jalr	-970(ra) # 80004b0a <releasesleep>
}
    80003edc:	60e2                	ld	ra,24(sp)
    80003ede:	6442                	ld	s0,16(sp)
    80003ee0:	64a2                	ld	s1,8(sp)
    80003ee2:	6902                	ld	s2,0(sp)
    80003ee4:	6105                	addi	sp,sp,32
    80003ee6:	8082                	ret
    panic("iunlock");
    80003ee8:	00005517          	auipc	a0,0x5
    80003eec:	89850513          	addi	a0,a0,-1896 # 80008780 <syscalls+0x1b0>
    80003ef0:	ffffc097          	auipc	ra,0xffffc
    80003ef4:	64e080e7          	jalr	1614(ra) # 8000053e <panic>

0000000080003ef8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ef8:	7179                	addi	sp,sp,-48
    80003efa:	f406                	sd	ra,40(sp)
    80003efc:	f022                	sd	s0,32(sp)
    80003efe:	ec26                	sd	s1,24(sp)
    80003f00:	e84a                	sd	s2,16(sp)
    80003f02:	e44e                	sd	s3,8(sp)
    80003f04:	e052                	sd	s4,0(sp)
    80003f06:	1800                	addi	s0,sp,48
    80003f08:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f0a:	05050493          	addi	s1,a0,80
    80003f0e:	08050913          	addi	s2,a0,128
    80003f12:	a021                	j	80003f1a <itrunc+0x22>
    80003f14:	0491                	addi	s1,s1,4
    80003f16:	01248d63          	beq	s1,s2,80003f30 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f1a:	408c                	lw	a1,0(s1)
    80003f1c:	dde5                	beqz	a1,80003f14 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f1e:	0009a503          	lw	a0,0(s3)
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	90c080e7          	jalr	-1780(ra) # 8000382e <bfree>
      ip->addrs[i] = 0;
    80003f2a:	0004a023          	sw	zero,0(s1)
    80003f2e:	b7dd                	j	80003f14 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f30:	0809a583          	lw	a1,128(s3)
    80003f34:	e185                	bnez	a1,80003f54 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f36:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f3a:	854e                	mv	a0,s3
    80003f3c:	00000097          	auipc	ra,0x0
    80003f40:	de4080e7          	jalr	-540(ra) # 80003d20 <iupdate>
}
    80003f44:	70a2                	ld	ra,40(sp)
    80003f46:	7402                	ld	s0,32(sp)
    80003f48:	64e2                	ld	s1,24(sp)
    80003f4a:	6942                	ld	s2,16(sp)
    80003f4c:	69a2                	ld	s3,8(sp)
    80003f4e:	6a02                	ld	s4,0(sp)
    80003f50:	6145                	addi	sp,sp,48
    80003f52:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f54:	0009a503          	lw	a0,0(s3)
    80003f58:	fffff097          	auipc	ra,0xfffff
    80003f5c:	690080e7          	jalr	1680(ra) # 800035e8 <bread>
    80003f60:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f62:	05850493          	addi	s1,a0,88
    80003f66:	45850913          	addi	s2,a0,1112
    80003f6a:	a811                	j	80003f7e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003f6c:	0009a503          	lw	a0,0(s3)
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	8be080e7          	jalr	-1858(ra) # 8000382e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003f78:	0491                	addi	s1,s1,4
    80003f7a:	01248563          	beq	s1,s2,80003f84 <itrunc+0x8c>
      if(a[j])
    80003f7e:	408c                	lw	a1,0(s1)
    80003f80:	dde5                	beqz	a1,80003f78 <itrunc+0x80>
    80003f82:	b7ed                	j	80003f6c <itrunc+0x74>
    brelse(bp);
    80003f84:	8552                	mv	a0,s4
    80003f86:	fffff097          	auipc	ra,0xfffff
    80003f8a:	792080e7          	jalr	1938(ra) # 80003718 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f8e:	0809a583          	lw	a1,128(s3)
    80003f92:	0009a503          	lw	a0,0(s3)
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	898080e7          	jalr	-1896(ra) # 8000382e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f9e:	0809a023          	sw	zero,128(s3)
    80003fa2:	bf51                	j	80003f36 <itrunc+0x3e>

0000000080003fa4 <iput>:
{
    80003fa4:	1101                	addi	sp,sp,-32
    80003fa6:	ec06                	sd	ra,24(sp)
    80003fa8:	e822                	sd	s0,16(sp)
    80003faa:	e426                	sd	s1,8(sp)
    80003fac:	e04a                	sd	s2,0(sp)
    80003fae:	1000                	addi	s0,sp,32
    80003fb0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fb2:	0001d517          	auipc	a0,0x1d
    80003fb6:	48e50513          	addi	a0,a0,1166 # 80021440 <itable>
    80003fba:	ffffd097          	auipc	ra,0xffffd
    80003fbe:	c2a080e7          	jalr	-982(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fc2:	4498                	lw	a4,8(s1)
    80003fc4:	4785                	li	a5,1
    80003fc6:	02f70363          	beq	a4,a5,80003fec <iput+0x48>
  ip->ref--;
    80003fca:	449c                	lw	a5,8(s1)
    80003fcc:	37fd                	addiw	a5,a5,-1
    80003fce:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fd0:	0001d517          	auipc	a0,0x1d
    80003fd4:	47050513          	addi	a0,a0,1136 # 80021440 <itable>
    80003fd8:	ffffd097          	auipc	ra,0xffffd
    80003fdc:	cc0080e7          	jalr	-832(ra) # 80000c98 <release>
}
    80003fe0:	60e2                	ld	ra,24(sp)
    80003fe2:	6442                	ld	s0,16(sp)
    80003fe4:	64a2                	ld	s1,8(sp)
    80003fe6:	6902                	ld	s2,0(sp)
    80003fe8:	6105                	addi	sp,sp,32
    80003fea:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fec:	40bc                	lw	a5,64(s1)
    80003fee:	dff1                	beqz	a5,80003fca <iput+0x26>
    80003ff0:	04a49783          	lh	a5,74(s1)
    80003ff4:	fbf9                	bnez	a5,80003fca <iput+0x26>
    acquiresleep(&ip->lock);
    80003ff6:	01048913          	addi	s2,s1,16
    80003ffa:	854a                	mv	a0,s2
    80003ffc:	00001097          	auipc	ra,0x1
    80004000:	ab8080e7          	jalr	-1352(ra) # 80004ab4 <acquiresleep>
    release(&itable.lock);
    80004004:	0001d517          	auipc	a0,0x1d
    80004008:	43c50513          	addi	a0,a0,1084 # 80021440 <itable>
    8000400c:	ffffd097          	auipc	ra,0xffffd
    80004010:	c8c080e7          	jalr	-884(ra) # 80000c98 <release>
    itrunc(ip);
    80004014:	8526                	mv	a0,s1
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	ee2080e7          	jalr	-286(ra) # 80003ef8 <itrunc>
    ip->type = 0;
    8000401e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004022:	8526                	mv	a0,s1
    80004024:	00000097          	auipc	ra,0x0
    80004028:	cfc080e7          	jalr	-772(ra) # 80003d20 <iupdate>
    ip->valid = 0;
    8000402c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004030:	854a                	mv	a0,s2
    80004032:	00001097          	auipc	ra,0x1
    80004036:	ad8080e7          	jalr	-1320(ra) # 80004b0a <releasesleep>
    acquire(&itable.lock);
    8000403a:	0001d517          	auipc	a0,0x1d
    8000403e:	40650513          	addi	a0,a0,1030 # 80021440 <itable>
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	ba2080e7          	jalr	-1118(ra) # 80000be4 <acquire>
    8000404a:	b741                	j	80003fca <iput+0x26>

000000008000404c <iunlockput>:
{
    8000404c:	1101                	addi	sp,sp,-32
    8000404e:	ec06                	sd	ra,24(sp)
    80004050:	e822                	sd	s0,16(sp)
    80004052:	e426                	sd	s1,8(sp)
    80004054:	1000                	addi	s0,sp,32
    80004056:	84aa                	mv	s1,a0
  iunlock(ip);
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	e54080e7          	jalr	-428(ra) # 80003eac <iunlock>
  iput(ip);
    80004060:	8526                	mv	a0,s1
    80004062:	00000097          	auipc	ra,0x0
    80004066:	f42080e7          	jalr	-190(ra) # 80003fa4 <iput>
}
    8000406a:	60e2                	ld	ra,24(sp)
    8000406c:	6442                	ld	s0,16(sp)
    8000406e:	64a2                	ld	s1,8(sp)
    80004070:	6105                	addi	sp,sp,32
    80004072:	8082                	ret

0000000080004074 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004074:	1141                	addi	sp,sp,-16
    80004076:	e422                	sd	s0,8(sp)
    80004078:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000407a:	411c                	lw	a5,0(a0)
    8000407c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000407e:	415c                	lw	a5,4(a0)
    80004080:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004082:	04451783          	lh	a5,68(a0)
    80004086:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000408a:	04a51783          	lh	a5,74(a0)
    8000408e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004092:	04c56783          	lwu	a5,76(a0)
    80004096:	e99c                	sd	a5,16(a1)
}
    80004098:	6422                	ld	s0,8(sp)
    8000409a:	0141                	addi	sp,sp,16
    8000409c:	8082                	ret

000000008000409e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000409e:	457c                	lw	a5,76(a0)
    800040a0:	0ed7e963          	bltu	a5,a3,80004192 <readi+0xf4>
{
    800040a4:	7159                	addi	sp,sp,-112
    800040a6:	f486                	sd	ra,104(sp)
    800040a8:	f0a2                	sd	s0,96(sp)
    800040aa:	eca6                	sd	s1,88(sp)
    800040ac:	e8ca                	sd	s2,80(sp)
    800040ae:	e4ce                	sd	s3,72(sp)
    800040b0:	e0d2                	sd	s4,64(sp)
    800040b2:	fc56                	sd	s5,56(sp)
    800040b4:	f85a                	sd	s6,48(sp)
    800040b6:	f45e                	sd	s7,40(sp)
    800040b8:	f062                	sd	s8,32(sp)
    800040ba:	ec66                	sd	s9,24(sp)
    800040bc:	e86a                	sd	s10,16(sp)
    800040be:	e46e                	sd	s11,8(sp)
    800040c0:	1880                	addi	s0,sp,112
    800040c2:	8baa                	mv	s7,a0
    800040c4:	8c2e                	mv	s8,a1
    800040c6:	8ab2                	mv	s5,a2
    800040c8:	84b6                	mv	s1,a3
    800040ca:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040cc:	9f35                	addw	a4,a4,a3
    return 0;
    800040ce:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040d0:	0ad76063          	bltu	a4,a3,80004170 <readi+0xd2>
  if(off + n > ip->size)
    800040d4:	00e7f463          	bgeu	a5,a4,800040dc <readi+0x3e>
    n = ip->size - off;
    800040d8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040dc:	0a0b0963          	beqz	s6,8000418e <readi+0xf0>
    800040e0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040e2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040e6:	5cfd                	li	s9,-1
    800040e8:	a82d                	j	80004122 <readi+0x84>
    800040ea:	020a1d93          	slli	s11,s4,0x20
    800040ee:	020ddd93          	srli	s11,s11,0x20
    800040f2:	05890613          	addi	a2,s2,88
    800040f6:	86ee                	mv	a3,s11
    800040f8:	963a                	add	a2,a2,a4
    800040fa:	85d6                	mv	a1,s5
    800040fc:	8562                	mv	a0,s8
    800040fe:	ffffe097          	auipc	ra,0xffffe
    80004102:	366080e7          	jalr	870(ra) # 80002464 <either_copyout>
    80004106:	05950d63          	beq	a0,s9,80004160 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000410a:	854a                	mv	a0,s2
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	60c080e7          	jalr	1548(ra) # 80003718 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004114:	013a09bb          	addw	s3,s4,s3
    80004118:	009a04bb          	addw	s1,s4,s1
    8000411c:	9aee                	add	s5,s5,s11
    8000411e:	0569f763          	bgeu	s3,s6,8000416c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004122:	000ba903          	lw	s2,0(s7)
    80004126:	00a4d59b          	srliw	a1,s1,0xa
    8000412a:	855e                	mv	a0,s7
    8000412c:	00000097          	auipc	ra,0x0
    80004130:	8b0080e7          	jalr	-1872(ra) # 800039dc <bmap>
    80004134:	0005059b          	sext.w	a1,a0
    80004138:	854a                	mv	a0,s2
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	4ae080e7          	jalr	1198(ra) # 800035e8 <bread>
    80004142:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004144:	3ff4f713          	andi	a4,s1,1023
    80004148:	40ed07bb          	subw	a5,s10,a4
    8000414c:	413b06bb          	subw	a3,s6,s3
    80004150:	8a3e                	mv	s4,a5
    80004152:	2781                	sext.w	a5,a5
    80004154:	0006861b          	sext.w	a2,a3
    80004158:	f8f679e3          	bgeu	a2,a5,800040ea <readi+0x4c>
    8000415c:	8a36                	mv	s4,a3
    8000415e:	b771                	j	800040ea <readi+0x4c>
      brelse(bp);
    80004160:	854a                	mv	a0,s2
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	5b6080e7          	jalr	1462(ra) # 80003718 <brelse>
      tot = -1;
    8000416a:	59fd                	li	s3,-1
  }
  return tot;
    8000416c:	0009851b          	sext.w	a0,s3
}
    80004170:	70a6                	ld	ra,104(sp)
    80004172:	7406                	ld	s0,96(sp)
    80004174:	64e6                	ld	s1,88(sp)
    80004176:	6946                	ld	s2,80(sp)
    80004178:	69a6                	ld	s3,72(sp)
    8000417a:	6a06                	ld	s4,64(sp)
    8000417c:	7ae2                	ld	s5,56(sp)
    8000417e:	7b42                	ld	s6,48(sp)
    80004180:	7ba2                	ld	s7,40(sp)
    80004182:	7c02                	ld	s8,32(sp)
    80004184:	6ce2                	ld	s9,24(sp)
    80004186:	6d42                	ld	s10,16(sp)
    80004188:	6da2                	ld	s11,8(sp)
    8000418a:	6165                	addi	sp,sp,112
    8000418c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000418e:	89da                	mv	s3,s6
    80004190:	bff1                	j	8000416c <readi+0xce>
    return 0;
    80004192:	4501                	li	a0,0
}
    80004194:	8082                	ret

0000000080004196 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004196:	457c                	lw	a5,76(a0)
    80004198:	10d7e863          	bltu	a5,a3,800042a8 <writei+0x112>
{
    8000419c:	7159                	addi	sp,sp,-112
    8000419e:	f486                	sd	ra,104(sp)
    800041a0:	f0a2                	sd	s0,96(sp)
    800041a2:	eca6                	sd	s1,88(sp)
    800041a4:	e8ca                	sd	s2,80(sp)
    800041a6:	e4ce                	sd	s3,72(sp)
    800041a8:	e0d2                	sd	s4,64(sp)
    800041aa:	fc56                	sd	s5,56(sp)
    800041ac:	f85a                	sd	s6,48(sp)
    800041ae:	f45e                	sd	s7,40(sp)
    800041b0:	f062                	sd	s8,32(sp)
    800041b2:	ec66                	sd	s9,24(sp)
    800041b4:	e86a                	sd	s10,16(sp)
    800041b6:	e46e                	sd	s11,8(sp)
    800041b8:	1880                	addi	s0,sp,112
    800041ba:	8b2a                	mv	s6,a0
    800041bc:	8c2e                	mv	s8,a1
    800041be:	8ab2                	mv	s5,a2
    800041c0:	8936                	mv	s2,a3
    800041c2:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800041c4:	00e687bb          	addw	a5,a3,a4
    800041c8:	0ed7e263          	bltu	a5,a3,800042ac <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041cc:	00043737          	lui	a4,0x43
    800041d0:	0ef76063          	bltu	a4,a5,800042b0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041d4:	0c0b8863          	beqz	s7,800042a4 <writei+0x10e>
    800041d8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041da:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041de:	5cfd                	li	s9,-1
    800041e0:	a091                	j	80004224 <writei+0x8e>
    800041e2:	02099d93          	slli	s11,s3,0x20
    800041e6:	020ddd93          	srli	s11,s11,0x20
    800041ea:	05848513          	addi	a0,s1,88
    800041ee:	86ee                	mv	a3,s11
    800041f0:	8656                	mv	a2,s5
    800041f2:	85e2                	mv	a1,s8
    800041f4:	953a                	add	a0,a0,a4
    800041f6:	ffffe097          	auipc	ra,0xffffe
    800041fa:	2c4080e7          	jalr	708(ra) # 800024ba <either_copyin>
    800041fe:	07950263          	beq	a0,s9,80004262 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004202:	8526                	mv	a0,s1
    80004204:	00000097          	auipc	ra,0x0
    80004208:	790080e7          	jalr	1936(ra) # 80004994 <log_write>
    brelse(bp);
    8000420c:	8526                	mv	a0,s1
    8000420e:	fffff097          	auipc	ra,0xfffff
    80004212:	50a080e7          	jalr	1290(ra) # 80003718 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004216:	01498a3b          	addw	s4,s3,s4
    8000421a:	0129893b          	addw	s2,s3,s2
    8000421e:	9aee                	add	s5,s5,s11
    80004220:	057a7663          	bgeu	s4,s7,8000426c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004224:	000b2483          	lw	s1,0(s6)
    80004228:	00a9559b          	srliw	a1,s2,0xa
    8000422c:	855a                	mv	a0,s6
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	7ae080e7          	jalr	1966(ra) # 800039dc <bmap>
    80004236:	0005059b          	sext.w	a1,a0
    8000423a:	8526                	mv	a0,s1
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	3ac080e7          	jalr	940(ra) # 800035e8 <bread>
    80004244:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004246:	3ff97713          	andi	a4,s2,1023
    8000424a:	40ed07bb          	subw	a5,s10,a4
    8000424e:	414b86bb          	subw	a3,s7,s4
    80004252:	89be                	mv	s3,a5
    80004254:	2781                	sext.w	a5,a5
    80004256:	0006861b          	sext.w	a2,a3
    8000425a:	f8f674e3          	bgeu	a2,a5,800041e2 <writei+0x4c>
    8000425e:	89b6                	mv	s3,a3
    80004260:	b749                	j	800041e2 <writei+0x4c>
      brelse(bp);
    80004262:	8526                	mv	a0,s1
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	4b4080e7          	jalr	1204(ra) # 80003718 <brelse>
  }

  if(off > ip->size)
    8000426c:	04cb2783          	lw	a5,76(s6)
    80004270:	0127f463          	bgeu	a5,s2,80004278 <writei+0xe2>
    ip->size = off;
    80004274:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004278:	855a                	mv	a0,s6
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	aa6080e7          	jalr	-1370(ra) # 80003d20 <iupdate>

  return tot;
    80004282:	000a051b          	sext.w	a0,s4
}
    80004286:	70a6                	ld	ra,104(sp)
    80004288:	7406                	ld	s0,96(sp)
    8000428a:	64e6                	ld	s1,88(sp)
    8000428c:	6946                	ld	s2,80(sp)
    8000428e:	69a6                	ld	s3,72(sp)
    80004290:	6a06                	ld	s4,64(sp)
    80004292:	7ae2                	ld	s5,56(sp)
    80004294:	7b42                	ld	s6,48(sp)
    80004296:	7ba2                	ld	s7,40(sp)
    80004298:	7c02                	ld	s8,32(sp)
    8000429a:	6ce2                	ld	s9,24(sp)
    8000429c:	6d42                	ld	s10,16(sp)
    8000429e:	6da2                	ld	s11,8(sp)
    800042a0:	6165                	addi	sp,sp,112
    800042a2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042a4:	8a5e                	mv	s4,s7
    800042a6:	bfc9                	j	80004278 <writei+0xe2>
    return -1;
    800042a8:	557d                	li	a0,-1
}
    800042aa:	8082                	ret
    return -1;
    800042ac:	557d                	li	a0,-1
    800042ae:	bfe1                	j	80004286 <writei+0xf0>
    return -1;
    800042b0:	557d                	li	a0,-1
    800042b2:	bfd1                	j	80004286 <writei+0xf0>

00000000800042b4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042b4:	1141                	addi	sp,sp,-16
    800042b6:	e406                	sd	ra,8(sp)
    800042b8:	e022                	sd	s0,0(sp)
    800042ba:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042bc:	4639                	li	a2,14
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	afa080e7          	jalr	-1286(ra) # 80000db8 <strncmp>
}
    800042c6:	60a2                	ld	ra,8(sp)
    800042c8:	6402                	ld	s0,0(sp)
    800042ca:	0141                	addi	sp,sp,16
    800042cc:	8082                	ret

00000000800042ce <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042ce:	7139                	addi	sp,sp,-64
    800042d0:	fc06                	sd	ra,56(sp)
    800042d2:	f822                	sd	s0,48(sp)
    800042d4:	f426                	sd	s1,40(sp)
    800042d6:	f04a                	sd	s2,32(sp)
    800042d8:	ec4e                	sd	s3,24(sp)
    800042da:	e852                	sd	s4,16(sp)
    800042dc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042de:	04451703          	lh	a4,68(a0)
    800042e2:	4785                	li	a5,1
    800042e4:	00f71a63          	bne	a4,a5,800042f8 <dirlookup+0x2a>
    800042e8:	892a                	mv	s2,a0
    800042ea:	89ae                	mv	s3,a1
    800042ec:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ee:	457c                	lw	a5,76(a0)
    800042f0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042f2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042f4:	e79d                	bnez	a5,80004322 <dirlookup+0x54>
    800042f6:	a8a5                	j	8000436e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042f8:	00004517          	auipc	a0,0x4
    800042fc:	49050513          	addi	a0,a0,1168 # 80008788 <syscalls+0x1b8>
    80004300:	ffffc097          	auipc	ra,0xffffc
    80004304:	23e080e7          	jalr	574(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004308:	00004517          	auipc	a0,0x4
    8000430c:	49850513          	addi	a0,a0,1176 # 800087a0 <syscalls+0x1d0>
    80004310:	ffffc097          	auipc	ra,0xffffc
    80004314:	22e080e7          	jalr	558(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004318:	24c1                	addiw	s1,s1,16
    8000431a:	04c92783          	lw	a5,76(s2)
    8000431e:	04f4f763          	bgeu	s1,a5,8000436c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004322:	4741                	li	a4,16
    80004324:	86a6                	mv	a3,s1
    80004326:	fc040613          	addi	a2,s0,-64
    8000432a:	4581                	li	a1,0
    8000432c:	854a                	mv	a0,s2
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	d70080e7          	jalr	-656(ra) # 8000409e <readi>
    80004336:	47c1                	li	a5,16
    80004338:	fcf518e3          	bne	a0,a5,80004308 <dirlookup+0x3a>
    if(de.inum == 0)
    8000433c:	fc045783          	lhu	a5,-64(s0)
    80004340:	dfe1                	beqz	a5,80004318 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004342:	fc240593          	addi	a1,s0,-62
    80004346:	854e                	mv	a0,s3
    80004348:	00000097          	auipc	ra,0x0
    8000434c:	f6c080e7          	jalr	-148(ra) # 800042b4 <namecmp>
    80004350:	f561                	bnez	a0,80004318 <dirlookup+0x4a>
      if(poff)
    80004352:	000a0463          	beqz	s4,8000435a <dirlookup+0x8c>
        *poff = off;
    80004356:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000435a:	fc045583          	lhu	a1,-64(s0)
    8000435e:	00092503          	lw	a0,0(s2)
    80004362:	fffff097          	auipc	ra,0xfffff
    80004366:	754080e7          	jalr	1876(ra) # 80003ab6 <iget>
    8000436a:	a011                	j	8000436e <dirlookup+0xa0>
  return 0;
    8000436c:	4501                	li	a0,0
}
    8000436e:	70e2                	ld	ra,56(sp)
    80004370:	7442                	ld	s0,48(sp)
    80004372:	74a2                	ld	s1,40(sp)
    80004374:	7902                	ld	s2,32(sp)
    80004376:	69e2                	ld	s3,24(sp)
    80004378:	6a42                	ld	s4,16(sp)
    8000437a:	6121                	addi	sp,sp,64
    8000437c:	8082                	ret

000000008000437e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000437e:	711d                	addi	sp,sp,-96
    80004380:	ec86                	sd	ra,88(sp)
    80004382:	e8a2                	sd	s0,80(sp)
    80004384:	e4a6                	sd	s1,72(sp)
    80004386:	e0ca                	sd	s2,64(sp)
    80004388:	fc4e                	sd	s3,56(sp)
    8000438a:	f852                	sd	s4,48(sp)
    8000438c:	f456                	sd	s5,40(sp)
    8000438e:	f05a                	sd	s6,32(sp)
    80004390:	ec5e                	sd	s7,24(sp)
    80004392:	e862                	sd	s8,16(sp)
    80004394:	e466                	sd	s9,8(sp)
    80004396:	1080                	addi	s0,sp,96
    80004398:	84aa                	mv	s1,a0
    8000439a:	8b2e                	mv	s6,a1
    8000439c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000439e:	00054703          	lbu	a4,0(a0)
    800043a2:	02f00793          	li	a5,47
    800043a6:	02f70363          	beq	a4,a5,800043cc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	62a080e7          	jalr	1578(ra) # 800019d4 <myproc>
    800043b2:	15053503          	ld	a0,336(a0)
    800043b6:	00000097          	auipc	ra,0x0
    800043ba:	9f6080e7          	jalr	-1546(ra) # 80003dac <idup>
    800043be:	89aa                	mv	s3,a0
  while(*path == '/')
    800043c0:	02f00913          	li	s2,47
  len = path - s;
    800043c4:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800043c6:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043c8:	4c05                	li	s8,1
    800043ca:	a865                	j	80004482 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800043cc:	4585                	li	a1,1
    800043ce:	4505                	li	a0,1
    800043d0:	fffff097          	auipc	ra,0xfffff
    800043d4:	6e6080e7          	jalr	1766(ra) # 80003ab6 <iget>
    800043d8:	89aa                	mv	s3,a0
    800043da:	b7dd                	j	800043c0 <namex+0x42>
      iunlockput(ip);
    800043dc:	854e                	mv	a0,s3
    800043de:	00000097          	auipc	ra,0x0
    800043e2:	c6e080e7          	jalr	-914(ra) # 8000404c <iunlockput>
      return 0;
    800043e6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043e8:	854e                	mv	a0,s3
    800043ea:	60e6                	ld	ra,88(sp)
    800043ec:	6446                	ld	s0,80(sp)
    800043ee:	64a6                	ld	s1,72(sp)
    800043f0:	6906                	ld	s2,64(sp)
    800043f2:	79e2                	ld	s3,56(sp)
    800043f4:	7a42                	ld	s4,48(sp)
    800043f6:	7aa2                	ld	s5,40(sp)
    800043f8:	7b02                	ld	s6,32(sp)
    800043fa:	6be2                	ld	s7,24(sp)
    800043fc:	6c42                	ld	s8,16(sp)
    800043fe:	6ca2                	ld	s9,8(sp)
    80004400:	6125                	addi	sp,sp,96
    80004402:	8082                	ret
      iunlock(ip);
    80004404:	854e                	mv	a0,s3
    80004406:	00000097          	auipc	ra,0x0
    8000440a:	aa6080e7          	jalr	-1370(ra) # 80003eac <iunlock>
      return ip;
    8000440e:	bfe9                	j	800043e8 <namex+0x6a>
      iunlockput(ip);
    80004410:	854e                	mv	a0,s3
    80004412:	00000097          	auipc	ra,0x0
    80004416:	c3a080e7          	jalr	-966(ra) # 8000404c <iunlockput>
      return 0;
    8000441a:	89d2                	mv	s3,s4
    8000441c:	b7f1                	j	800043e8 <namex+0x6a>
  len = path - s;
    8000441e:	40b48633          	sub	a2,s1,a1
    80004422:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004426:	094cd463          	bge	s9,s4,800044ae <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000442a:	4639                	li	a2,14
    8000442c:	8556                	mv	a0,s5
    8000442e:	ffffd097          	auipc	ra,0xffffd
    80004432:	912080e7          	jalr	-1774(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004436:	0004c783          	lbu	a5,0(s1)
    8000443a:	01279763          	bne	a5,s2,80004448 <namex+0xca>
    path++;
    8000443e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004440:	0004c783          	lbu	a5,0(s1)
    80004444:	ff278de3          	beq	a5,s2,8000443e <namex+0xc0>
    ilock(ip);
    80004448:	854e                	mv	a0,s3
    8000444a:	00000097          	auipc	ra,0x0
    8000444e:	9a0080e7          	jalr	-1632(ra) # 80003dea <ilock>
    if(ip->type != T_DIR){
    80004452:	04499783          	lh	a5,68(s3)
    80004456:	f98793e3          	bne	a5,s8,800043dc <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000445a:	000b0563          	beqz	s6,80004464 <namex+0xe6>
    8000445e:	0004c783          	lbu	a5,0(s1)
    80004462:	d3cd                	beqz	a5,80004404 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004464:	865e                	mv	a2,s7
    80004466:	85d6                	mv	a1,s5
    80004468:	854e                	mv	a0,s3
    8000446a:	00000097          	auipc	ra,0x0
    8000446e:	e64080e7          	jalr	-412(ra) # 800042ce <dirlookup>
    80004472:	8a2a                	mv	s4,a0
    80004474:	dd51                	beqz	a0,80004410 <namex+0x92>
    iunlockput(ip);
    80004476:	854e                	mv	a0,s3
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	bd4080e7          	jalr	-1068(ra) # 8000404c <iunlockput>
    ip = next;
    80004480:	89d2                	mv	s3,s4
  while(*path == '/')
    80004482:	0004c783          	lbu	a5,0(s1)
    80004486:	05279763          	bne	a5,s2,800044d4 <namex+0x156>
    path++;
    8000448a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000448c:	0004c783          	lbu	a5,0(s1)
    80004490:	ff278de3          	beq	a5,s2,8000448a <namex+0x10c>
  if(*path == 0)
    80004494:	c79d                	beqz	a5,800044c2 <namex+0x144>
    path++;
    80004496:	85a6                	mv	a1,s1
  len = path - s;
    80004498:	8a5e                	mv	s4,s7
    8000449a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000449c:	01278963          	beq	a5,s2,800044ae <namex+0x130>
    800044a0:	dfbd                	beqz	a5,8000441e <namex+0xa0>
    path++;
    800044a2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800044a4:	0004c783          	lbu	a5,0(s1)
    800044a8:	ff279ce3          	bne	a5,s2,800044a0 <namex+0x122>
    800044ac:	bf8d                	j	8000441e <namex+0xa0>
    memmove(name, s, len);
    800044ae:	2601                	sext.w	a2,a2
    800044b0:	8556                	mv	a0,s5
    800044b2:	ffffd097          	auipc	ra,0xffffd
    800044b6:	88e080e7          	jalr	-1906(ra) # 80000d40 <memmove>
    name[len] = 0;
    800044ba:	9a56                	add	s4,s4,s5
    800044bc:	000a0023          	sb	zero,0(s4)
    800044c0:	bf9d                	j	80004436 <namex+0xb8>
  if(nameiparent){
    800044c2:	f20b03e3          	beqz	s6,800043e8 <namex+0x6a>
    iput(ip);
    800044c6:	854e                	mv	a0,s3
    800044c8:	00000097          	auipc	ra,0x0
    800044cc:	adc080e7          	jalr	-1316(ra) # 80003fa4 <iput>
    return 0;
    800044d0:	4981                	li	s3,0
    800044d2:	bf19                	j	800043e8 <namex+0x6a>
  if(*path == 0)
    800044d4:	d7fd                	beqz	a5,800044c2 <namex+0x144>
  while(*path != '/' && *path != 0)
    800044d6:	0004c783          	lbu	a5,0(s1)
    800044da:	85a6                	mv	a1,s1
    800044dc:	b7d1                	j	800044a0 <namex+0x122>

00000000800044de <dirlink>:
{
    800044de:	7139                	addi	sp,sp,-64
    800044e0:	fc06                	sd	ra,56(sp)
    800044e2:	f822                	sd	s0,48(sp)
    800044e4:	f426                	sd	s1,40(sp)
    800044e6:	f04a                	sd	s2,32(sp)
    800044e8:	ec4e                	sd	s3,24(sp)
    800044ea:	e852                	sd	s4,16(sp)
    800044ec:	0080                	addi	s0,sp,64
    800044ee:	892a                	mv	s2,a0
    800044f0:	8a2e                	mv	s4,a1
    800044f2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044f4:	4601                	li	a2,0
    800044f6:	00000097          	auipc	ra,0x0
    800044fa:	dd8080e7          	jalr	-552(ra) # 800042ce <dirlookup>
    800044fe:	e93d                	bnez	a0,80004574 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004500:	04c92483          	lw	s1,76(s2)
    80004504:	c49d                	beqz	s1,80004532 <dirlink+0x54>
    80004506:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004508:	4741                	li	a4,16
    8000450a:	86a6                	mv	a3,s1
    8000450c:	fc040613          	addi	a2,s0,-64
    80004510:	4581                	li	a1,0
    80004512:	854a                	mv	a0,s2
    80004514:	00000097          	auipc	ra,0x0
    80004518:	b8a080e7          	jalr	-1142(ra) # 8000409e <readi>
    8000451c:	47c1                	li	a5,16
    8000451e:	06f51163          	bne	a0,a5,80004580 <dirlink+0xa2>
    if(de.inum == 0)
    80004522:	fc045783          	lhu	a5,-64(s0)
    80004526:	c791                	beqz	a5,80004532 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004528:	24c1                	addiw	s1,s1,16
    8000452a:	04c92783          	lw	a5,76(s2)
    8000452e:	fcf4ede3          	bltu	s1,a5,80004508 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004532:	4639                	li	a2,14
    80004534:	85d2                	mv	a1,s4
    80004536:	fc240513          	addi	a0,s0,-62
    8000453a:	ffffd097          	auipc	ra,0xffffd
    8000453e:	8ba080e7          	jalr	-1862(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004542:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004546:	4741                	li	a4,16
    80004548:	86a6                	mv	a3,s1
    8000454a:	fc040613          	addi	a2,s0,-64
    8000454e:	4581                	li	a1,0
    80004550:	854a                	mv	a0,s2
    80004552:	00000097          	auipc	ra,0x0
    80004556:	c44080e7          	jalr	-956(ra) # 80004196 <writei>
    8000455a:	872a                	mv	a4,a0
    8000455c:	47c1                	li	a5,16
  return 0;
    8000455e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004560:	02f71863          	bne	a4,a5,80004590 <dirlink+0xb2>
}
    80004564:	70e2                	ld	ra,56(sp)
    80004566:	7442                	ld	s0,48(sp)
    80004568:	74a2                	ld	s1,40(sp)
    8000456a:	7902                	ld	s2,32(sp)
    8000456c:	69e2                	ld	s3,24(sp)
    8000456e:	6a42                	ld	s4,16(sp)
    80004570:	6121                	addi	sp,sp,64
    80004572:	8082                	ret
    iput(ip);
    80004574:	00000097          	auipc	ra,0x0
    80004578:	a30080e7          	jalr	-1488(ra) # 80003fa4 <iput>
    return -1;
    8000457c:	557d                	li	a0,-1
    8000457e:	b7dd                	j	80004564 <dirlink+0x86>
      panic("dirlink read");
    80004580:	00004517          	auipc	a0,0x4
    80004584:	23050513          	addi	a0,a0,560 # 800087b0 <syscalls+0x1e0>
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	fb6080e7          	jalr	-74(ra) # 8000053e <panic>
    panic("dirlink");
    80004590:	00004517          	auipc	a0,0x4
    80004594:	32850513          	addi	a0,a0,808 # 800088b8 <syscalls+0x2e8>
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	fa6080e7          	jalr	-90(ra) # 8000053e <panic>

00000000800045a0 <namei>:

struct inode*
namei(char *path)
{
    800045a0:	1101                	addi	sp,sp,-32
    800045a2:	ec06                	sd	ra,24(sp)
    800045a4:	e822                	sd	s0,16(sp)
    800045a6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045a8:	fe040613          	addi	a2,s0,-32
    800045ac:	4581                	li	a1,0
    800045ae:	00000097          	auipc	ra,0x0
    800045b2:	dd0080e7          	jalr	-560(ra) # 8000437e <namex>
}
    800045b6:	60e2                	ld	ra,24(sp)
    800045b8:	6442                	ld	s0,16(sp)
    800045ba:	6105                	addi	sp,sp,32
    800045bc:	8082                	ret

00000000800045be <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045be:	1141                	addi	sp,sp,-16
    800045c0:	e406                	sd	ra,8(sp)
    800045c2:	e022                	sd	s0,0(sp)
    800045c4:	0800                	addi	s0,sp,16
    800045c6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045c8:	4585                	li	a1,1
    800045ca:	00000097          	auipc	ra,0x0
    800045ce:	db4080e7          	jalr	-588(ra) # 8000437e <namex>
}
    800045d2:	60a2                	ld	ra,8(sp)
    800045d4:	6402                	ld	s0,0(sp)
    800045d6:	0141                	addi	sp,sp,16
    800045d8:	8082                	ret

00000000800045da <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045da:	1101                	addi	sp,sp,-32
    800045dc:	ec06                	sd	ra,24(sp)
    800045de:	e822                	sd	s0,16(sp)
    800045e0:	e426                	sd	s1,8(sp)
    800045e2:	e04a                	sd	s2,0(sp)
    800045e4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045e6:	0001f917          	auipc	s2,0x1f
    800045ea:	90290913          	addi	s2,s2,-1790 # 80022ee8 <log>
    800045ee:	01892583          	lw	a1,24(s2)
    800045f2:	02892503          	lw	a0,40(s2)
    800045f6:	fffff097          	auipc	ra,0xfffff
    800045fa:	ff2080e7          	jalr	-14(ra) # 800035e8 <bread>
    800045fe:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004600:	02c92683          	lw	a3,44(s2)
    80004604:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004606:	02d05763          	blez	a3,80004634 <write_head+0x5a>
    8000460a:	0001f797          	auipc	a5,0x1f
    8000460e:	90e78793          	addi	a5,a5,-1778 # 80022f18 <log+0x30>
    80004612:	05c50713          	addi	a4,a0,92
    80004616:	36fd                	addiw	a3,a3,-1
    80004618:	1682                	slli	a3,a3,0x20
    8000461a:	9281                	srli	a3,a3,0x20
    8000461c:	068a                	slli	a3,a3,0x2
    8000461e:	0001f617          	auipc	a2,0x1f
    80004622:	8fe60613          	addi	a2,a2,-1794 # 80022f1c <log+0x34>
    80004626:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004628:	4390                	lw	a2,0(a5)
    8000462a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000462c:	0791                	addi	a5,a5,4
    8000462e:	0711                	addi	a4,a4,4
    80004630:	fed79ce3          	bne	a5,a3,80004628 <write_head+0x4e>
  }
  bwrite(buf);
    80004634:	8526                	mv	a0,s1
    80004636:	fffff097          	auipc	ra,0xfffff
    8000463a:	0a4080e7          	jalr	164(ra) # 800036da <bwrite>
  brelse(buf);
    8000463e:	8526                	mv	a0,s1
    80004640:	fffff097          	auipc	ra,0xfffff
    80004644:	0d8080e7          	jalr	216(ra) # 80003718 <brelse>
}
    80004648:	60e2                	ld	ra,24(sp)
    8000464a:	6442                	ld	s0,16(sp)
    8000464c:	64a2                	ld	s1,8(sp)
    8000464e:	6902                	ld	s2,0(sp)
    80004650:	6105                	addi	sp,sp,32
    80004652:	8082                	ret

0000000080004654 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004654:	0001f797          	auipc	a5,0x1f
    80004658:	8c07a783          	lw	a5,-1856(a5) # 80022f14 <log+0x2c>
    8000465c:	0af05d63          	blez	a5,80004716 <install_trans+0xc2>
{
    80004660:	7139                	addi	sp,sp,-64
    80004662:	fc06                	sd	ra,56(sp)
    80004664:	f822                	sd	s0,48(sp)
    80004666:	f426                	sd	s1,40(sp)
    80004668:	f04a                	sd	s2,32(sp)
    8000466a:	ec4e                	sd	s3,24(sp)
    8000466c:	e852                	sd	s4,16(sp)
    8000466e:	e456                	sd	s5,8(sp)
    80004670:	e05a                	sd	s6,0(sp)
    80004672:	0080                	addi	s0,sp,64
    80004674:	8b2a                	mv	s6,a0
    80004676:	0001fa97          	auipc	s5,0x1f
    8000467a:	8a2a8a93          	addi	s5,s5,-1886 # 80022f18 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000467e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004680:	0001f997          	auipc	s3,0x1f
    80004684:	86898993          	addi	s3,s3,-1944 # 80022ee8 <log>
    80004688:	a035                	j	800046b4 <install_trans+0x60>
      bunpin(dbuf);
    8000468a:	8526                	mv	a0,s1
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	166080e7          	jalr	358(ra) # 800037f2 <bunpin>
    brelse(lbuf);
    80004694:	854a                	mv	a0,s2
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	082080e7          	jalr	130(ra) # 80003718 <brelse>
    brelse(dbuf);
    8000469e:	8526                	mv	a0,s1
    800046a0:	fffff097          	auipc	ra,0xfffff
    800046a4:	078080e7          	jalr	120(ra) # 80003718 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046a8:	2a05                	addiw	s4,s4,1
    800046aa:	0a91                	addi	s5,s5,4
    800046ac:	02c9a783          	lw	a5,44(s3)
    800046b0:	04fa5963          	bge	s4,a5,80004702 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046b4:	0189a583          	lw	a1,24(s3)
    800046b8:	014585bb          	addw	a1,a1,s4
    800046bc:	2585                	addiw	a1,a1,1
    800046be:	0289a503          	lw	a0,40(s3)
    800046c2:	fffff097          	auipc	ra,0xfffff
    800046c6:	f26080e7          	jalr	-218(ra) # 800035e8 <bread>
    800046ca:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046cc:	000aa583          	lw	a1,0(s5)
    800046d0:	0289a503          	lw	a0,40(s3)
    800046d4:	fffff097          	auipc	ra,0xfffff
    800046d8:	f14080e7          	jalr	-236(ra) # 800035e8 <bread>
    800046dc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046de:	40000613          	li	a2,1024
    800046e2:	05890593          	addi	a1,s2,88
    800046e6:	05850513          	addi	a0,a0,88
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	656080e7          	jalr	1622(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800046f2:	8526                	mv	a0,s1
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	fe6080e7          	jalr	-26(ra) # 800036da <bwrite>
    if(recovering == 0)
    800046fc:	f80b1ce3          	bnez	s6,80004694 <install_trans+0x40>
    80004700:	b769                	j	8000468a <install_trans+0x36>
}
    80004702:	70e2                	ld	ra,56(sp)
    80004704:	7442                	ld	s0,48(sp)
    80004706:	74a2                	ld	s1,40(sp)
    80004708:	7902                	ld	s2,32(sp)
    8000470a:	69e2                	ld	s3,24(sp)
    8000470c:	6a42                	ld	s4,16(sp)
    8000470e:	6aa2                	ld	s5,8(sp)
    80004710:	6b02                	ld	s6,0(sp)
    80004712:	6121                	addi	sp,sp,64
    80004714:	8082                	ret
    80004716:	8082                	ret

0000000080004718 <initlog>:
{
    80004718:	7179                	addi	sp,sp,-48
    8000471a:	f406                	sd	ra,40(sp)
    8000471c:	f022                	sd	s0,32(sp)
    8000471e:	ec26                	sd	s1,24(sp)
    80004720:	e84a                	sd	s2,16(sp)
    80004722:	e44e                	sd	s3,8(sp)
    80004724:	1800                	addi	s0,sp,48
    80004726:	892a                	mv	s2,a0
    80004728:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000472a:	0001e497          	auipc	s1,0x1e
    8000472e:	7be48493          	addi	s1,s1,1982 # 80022ee8 <log>
    80004732:	00004597          	auipc	a1,0x4
    80004736:	08e58593          	addi	a1,a1,142 # 800087c0 <syscalls+0x1f0>
    8000473a:	8526                	mv	a0,s1
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	418080e7          	jalr	1048(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004744:	0149a583          	lw	a1,20(s3)
    80004748:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000474a:	0109a783          	lw	a5,16(s3)
    8000474e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004750:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004754:	854a                	mv	a0,s2
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	e92080e7          	jalr	-366(ra) # 800035e8 <bread>
  log.lh.n = lh->n;
    8000475e:	4d3c                	lw	a5,88(a0)
    80004760:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004762:	02f05563          	blez	a5,8000478c <initlog+0x74>
    80004766:	05c50713          	addi	a4,a0,92
    8000476a:	0001e697          	auipc	a3,0x1e
    8000476e:	7ae68693          	addi	a3,a3,1966 # 80022f18 <log+0x30>
    80004772:	37fd                	addiw	a5,a5,-1
    80004774:	1782                	slli	a5,a5,0x20
    80004776:	9381                	srli	a5,a5,0x20
    80004778:	078a                	slli	a5,a5,0x2
    8000477a:	06050613          	addi	a2,a0,96
    8000477e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004780:	4310                	lw	a2,0(a4)
    80004782:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004784:	0711                	addi	a4,a4,4
    80004786:	0691                	addi	a3,a3,4
    80004788:	fef71ce3          	bne	a4,a5,80004780 <initlog+0x68>
  brelse(buf);
    8000478c:	fffff097          	auipc	ra,0xfffff
    80004790:	f8c080e7          	jalr	-116(ra) # 80003718 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004794:	4505                	li	a0,1
    80004796:	00000097          	auipc	ra,0x0
    8000479a:	ebe080e7          	jalr	-322(ra) # 80004654 <install_trans>
  log.lh.n = 0;
    8000479e:	0001e797          	auipc	a5,0x1e
    800047a2:	7607ab23          	sw	zero,1910(a5) # 80022f14 <log+0x2c>
  write_head(); // clear the log
    800047a6:	00000097          	auipc	ra,0x0
    800047aa:	e34080e7          	jalr	-460(ra) # 800045da <write_head>
}
    800047ae:	70a2                	ld	ra,40(sp)
    800047b0:	7402                	ld	s0,32(sp)
    800047b2:	64e2                	ld	s1,24(sp)
    800047b4:	6942                	ld	s2,16(sp)
    800047b6:	69a2                	ld	s3,8(sp)
    800047b8:	6145                	addi	sp,sp,48
    800047ba:	8082                	ret

00000000800047bc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047bc:	1101                	addi	sp,sp,-32
    800047be:	ec06                	sd	ra,24(sp)
    800047c0:	e822                	sd	s0,16(sp)
    800047c2:	e426                	sd	s1,8(sp)
    800047c4:	e04a                	sd	s2,0(sp)
    800047c6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047c8:	0001e517          	auipc	a0,0x1e
    800047cc:	72050513          	addi	a0,a0,1824 # 80022ee8 <log>
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	414080e7          	jalr	1044(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800047d8:	0001e497          	auipc	s1,0x1e
    800047dc:	71048493          	addi	s1,s1,1808 # 80022ee8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047e0:	4979                	li	s2,30
    800047e2:	a039                	j	800047f0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800047e4:	85a6                	mv	a1,s1
    800047e6:	8526                	mv	a0,s1
    800047e8:	ffffe097          	auipc	ra,0xffffe
    800047ec:	8cc080e7          	jalr	-1844(ra) # 800020b4 <sleep>
    if(log.committing){
    800047f0:	50dc                	lw	a5,36(s1)
    800047f2:	fbed                	bnez	a5,800047e4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047f4:	509c                	lw	a5,32(s1)
    800047f6:	0017871b          	addiw	a4,a5,1
    800047fa:	0007069b          	sext.w	a3,a4
    800047fe:	0027179b          	slliw	a5,a4,0x2
    80004802:	9fb9                	addw	a5,a5,a4
    80004804:	0017979b          	slliw	a5,a5,0x1
    80004808:	54d8                	lw	a4,44(s1)
    8000480a:	9fb9                	addw	a5,a5,a4
    8000480c:	00f95963          	bge	s2,a5,8000481e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004810:	85a6                	mv	a1,s1
    80004812:	8526                	mv	a0,s1
    80004814:	ffffe097          	auipc	ra,0xffffe
    80004818:	8a0080e7          	jalr	-1888(ra) # 800020b4 <sleep>
    8000481c:	bfd1                	j	800047f0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000481e:	0001e517          	auipc	a0,0x1e
    80004822:	6ca50513          	addi	a0,a0,1738 # 80022ee8 <log>
    80004826:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	470080e7          	jalr	1136(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004830:	60e2                	ld	ra,24(sp)
    80004832:	6442                	ld	s0,16(sp)
    80004834:	64a2                	ld	s1,8(sp)
    80004836:	6902                	ld	s2,0(sp)
    80004838:	6105                	addi	sp,sp,32
    8000483a:	8082                	ret

000000008000483c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000483c:	7139                	addi	sp,sp,-64
    8000483e:	fc06                	sd	ra,56(sp)
    80004840:	f822                	sd	s0,48(sp)
    80004842:	f426                	sd	s1,40(sp)
    80004844:	f04a                	sd	s2,32(sp)
    80004846:	ec4e                	sd	s3,24(sp)
    80004848:	e852                	sd	s4,16(sp)
    8000484a:	e456                	sd	s5,8(sp)
    8000484c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000484e:	0001e497          	auipc	s1,0x1e
    80004852:	69a48493          	addi	s1,s1,1690 # 80022ee8 <log>
    80004856:	8526                	mv	a0,s1
    80004858:	ffffc097          	auipc	ra,0xffffc
    8000485c:	38c080e7          	jalr	908(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004860:	509c                	lw	a5,32(s1)
    80004862:	37fd                	addiw	a5,a5,-1
    80004864:	0007891b          	sext.w	s2,a5
    80004868:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000486a:	50dc                	lw	a5,36(s1)
    8000486c:	efb9                	bnez	a5,800048ca <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000486e:	06091663          	bnez	s2,800048da <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004872:	0001e497          	auipc	s1,0x1e
    80004876:	67648493          	addi	s1,s1,1654 # 80022ee8 <log>
    8000487a:	4785                	li	a5,1
    8000487c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000487e:	8526                	mv	a0,s1
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	418080e7          	jalr	1048(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004888:	54dc                	lw	a5,44(s1)
    8000488a:	06f04763          	bgtz	a5,800048f8 <end_op+0xbc>
    acquire(&log.lock);
    8000488e:	0001e497          	auipc	s1,0x1e
    80004892:	65a48493          	addi	s1,s1,1626 # 80022ee8 <log>
    80004896:	8526                	mv	a0,s1
    80004898:	ffffc097          	auipc	ra,0xffffc
    8000489c:	34c080e7          	jalr	844(ra) # 80000be4 <acquire>
    log.committing = 0;
    800048a0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048a4:	8526                	mv	a0,s1
    800048a6:	ffffe097          	auipc	ra,0xffffe
    800048aa:	99a080e7          	jalr	-1638(ra) # 80002240 <wakeup>
    release(&log.lock);
    800048ae:	8526                	mv	a0,s1
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	3e8080e7          	jalr	1000(ra) # 80000c98 <release>
}
    800048b8:	70e2                	ld	ra,56(sp)
    800048ba:	7442                	ld	s0,48(sp)
    800048bc:	74a2                	ld	s1,40(sp)
    800048be:	7902                	ld	s2,32(sp)
    800048c0:	69e2                	ld	s3,24(sp)
    800048c2:	6a42                	ld	s4,16(sp)
    800048c4:	6aa2                	ld	s5,8(sp)
    800048c6:	6121                	addi	sp,sp,64
    800048c8:	8082                	ret
    panic("log.committing");
    800048ca:	00004517          	auipc	a0,0x4
    800048ce:	efe50513          	addi	a0,a0,-258 # 800087c8 <syscalls+0x1f8>
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	c6c080e7          	jalr	-916(ra) # 8000053e <panic>
    wakeup(&log);
    800048da:	0001e497          	auipc	s1,0x1e
    800048de:	60e48493          	addi	s1,s1,1550 # 80022ee8 <log>
    800048e2:	8526                	mv	a0,s1
    800048e4:	ffffe097          	auipc	ra,0xffffe
    800048e8:	95c080e7          	jalr	-1700(ra) # 80002240 <wakeup>
  release(&log.lock);
    800048ec:	8526                	mv	a0,s1
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	3aa080e7          	jalr	938(ra) # 80000c98 <release>
  if(do_commit){
    800048f6:	b7c9                	j	800048b8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048f8:	0001ea97          	auipc	s5,0x1e
    800048fc:	620a8a93          	addi	s5,s5,1568 # 80022f18 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004900:	0001ea17          	auipc	s4,0x1e
    80004904:	5e8a0a13          	addi	s4,s4,1512 # 80022ee8 <log>
    80004908:	018a2583          	lw	a1,24(s4)
    8000490c:	012585bb          	addw	a1,a1,s2
    80004910:	2585                	addiw	a1,a1,1
    80004912:	028a2503          	lw	a0,40(s4)
    80004916:	fffff097          	auipc	ra,0xfffff
    8000491a:	cd2080e7          	jalr	-814(ra) # 800035e8 <bread>
    8000491e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004920:	000aa583          	lw	a1,0(s5)
    80004924:	028a2503          	lw	a0,40(s4)
    80004928:	fffff097          	auipc	ra,0xfffff
    8000492c:	cc0080e7          	jalr	-832(ra) # 800035e8 <bread>
    80004930:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004932:	40000613          	li	a2,1024
    80004936:	05850593          	addi	a1,a0,88
    8000493a:	05848513          	addi	a0,s1,88
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	402080e7          	jalr	1026(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004946:	8526                	mv	a0,s1
    80004948:	fffff097          	auipc	ra,0xfffff
    8000494c:	d92080e7          	jalr	-622(ra) # 800036da <bwrite>
    brelse(from);
    80004950:	854e                	mv	a0,s3
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	dc6080e7          	jalr	-570(ra) # 80003718 <brelse>
    brelse(to);
    8000495a:	8526                	mv	a0,s1
    8000495c:	fffff097          	auipc	ra,0xfffff
    80004960:	dbc080e7          	jalr	-580(ra) # 80003718 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004964:	2905                	addiw	s2,s2,1
    80004966:	0a91                	addi	s5,s5,4
    80004968:	02ca2783          	lw	a5,44(s4)
    8000496c:	f8f94ee3          	blt	s2,a5,80004908 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004970:	00000097          	auipc	ra,0x0
    80004974:	c6a080e7          	jalr	-918(ra) # 800045da <write_head>
    install_trans(0); // Now install writes to home locations
    80004978:	4501                	li	a0,0
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	cda080e7          	jalr	-806(ra) # 80004654 <install_trans>
    log.lh.n = 0;
    80004982:	0001e797          	auipc	a5,0x1e
    80004986:	5807a923          	sw	zero,1426(a5) # 80022f14 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000498a:	00000097          	auipc	ra,0x0
    8000498e:	c50080e7          	jalr	-944(ra) # 800045da <write_head>
    80004992:	bdf5                	j	8000488e <end_op+0x52>

0000000080004994 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004994:	1101                	addi	sp,sp,-32
    80004996:	ec06                	sd	ra,24(sp)
    80004998:	e822                	sd	s0,16(sp)
    8000499a:	e426                	sd	s1,8(sp)
    8000499c:	e04a                	sd	s2,0(sp)
    8000499e:	1000                	addi	s0,sp,32
    800049a0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049a2:	0001e917          	auipc	s2,0x1e
    800049a6:	54690913          	addi	s2,s2,1350 # 80022ee8 <log>
    800049aa:	854a                	mv	a0,s2
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	238080e7          	jalr	568(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049b4:	02c92603          	lw	a2,44(s2)
    800049b8:	47f5                	li	a5,29
    800049ba:	06c7c563          	blt	a5,a2,80004a24 <log_write+0x90>
    800049be:	0001e797          	auipc	a5,0x1e
    800049c2:	5467a783          	lw	a5,1350(a5) # 80022f04 <log+0x1c>
    800049c6:	37fd                	addiw	a5,a5,-1
    800049c8:	04f65e63          	bge	a2,a5,80004a24 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049cc:	0001e797          	auipc	a5,0x1e
    800049d0:	53c7a783          	lw	a5,1340(a5) # 80022f08 <log+0x20>
    800049d4:	06f05063          	blez	a5,80004a34 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049d8:	4781                	li	a5,0
    800049da:	06c05563          	blez	a2,80004a44 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049de:	44cc                	lw	a1,12(s1)
    800049e0:	0001e717          	auipc	a4,0x1e
    800049e4:	53870713          	addi	a4,a4,1336 # 80022f18 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049e8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049ea:	4314                	lw	a3,0(a4)
    800049ec:	04b68c63          	beq	a3,a1,80004a44 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049f0:	2785                	addiw	a5,a5,1
    800049f2:	0711                	addi	a4,a4,4
    800049f4:	fef61be3          	bne	a2,a5,800049ea <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049f8:	0621                	addi	a2,a2,8
    800049fa:	060a                	slli	a2,a2,0x2
    800049fc:	0001e797          	auipc	a5,0x1e
    80004a00:	4ec78793          	addi	a5,a5,1260 # 80022ee8 <log>
    80004a04:	963e                	add	a2,a2,a5
    80004a06:	44dc                	lw	a5,12(s1)
    80004a08:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a0a:	8526                	mv	a0,s1
    80004a0c:	fffff097          	auipc	ra,0xfffff
    80004a10:	daa080e7          	jalr	-598(ra) # 800037b6 <bpin>
    log.lh.n++;
    80004a14:	0001e717          	auipc	a4,0x1e
    80004a18:	4d470713          	addi	a4,a4,1236 # 80022ee8 <log>
    80004a1c:	575c                	lw	a5,44(a4)
    80004a1e:	2785                	addiw	a5,a5,1
    80004a20:	d75c                	sw	a5,44(a4)
    80004a22:	a835                	j	80004a5e <log_write+0xca>
    panic("too big a transaction");
    80004a24:	00004517          	auipc	a0,0x4
    80004a28:	db450513          	addi	a0,a0,-588 # 800087d8 <syscalls+0x208>
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	b12080e7          	jalr	-1262(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a34:	00004517          	auipc	a0,0x4
    80004a38:	dbc50513          	addi	a0,a0,-580 # 800087f0 <syscalls+0x220>
    80004a3c:	ffffc097          	auipc	ra,0xffffc
    80004a40:	b02080e7          	jalr	-1278(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a44:	00878713          	addi	a4,a5,8
    80004a48:	00271693          	slli	a3,a4,0x2
    80004a4c:	0001e717          	auipc	a4,0x1e
    80004a50:	49c70713          	addi	a4,a4,1180 # 80022ee8 <log>
    80004a54:	9736                	add	a4,a4,a3
    80004a56:	44d4                	lw	a3,12(s1)
    80004a58:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a5a:	faf608e3          	beq	a2,a5,80004a0a <log_write+0x76>
  }
  release(&log.lock);
    80004a5e:	0001e517          	auipc	a0,0x1e
    80004a62:	48a50513          	addi	a0,a0,1162 # 80022ee8 <log>
    80004a66:	ffffc097          	auipc	ra,0xffffc
    80004a6a:	232080e7          	jalr	562(ra) # 80000c98 <release>
}
    80004a6e:	60e2                	ld	ra,24(sp)
    80004a70:	6442                	ld	s0,16(sp)
    80004a72:	64a2                	ld	s1,8(sp)
    80004a74:	6902                	ld	s2,0(sp)
    80004a76:	6105                	addi	sp,sp,32
    80004a78:	8082                	ret

0000000080004a7a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a7a:	1101                	addi	sp,sp,-32
    80004a7c:	ec06                	sd	ra,24(sp)
    80004a7e:	e822                	sd	s0,16(sp)
    80004a80:	e426                	sd	s1,8(sp)
    80004a82:	e04a                	sd	s2,0(sp)
    80004a84:	1000                	addi	s0,sp,32
    80004a86:	84aa                	mv	s1,a0
    80004a88:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a8a:	00004597          	auipc	a1,0x4
    80004a8e:	d8658593          	addi	a1,a1,-634 # 80008810 <syscalls+0x240>
    80004a92:	0521                	addi	a0,a0,8
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	0c0080e7          	jalr	192(ra) # 80000b54 <initlock>
  lk->name = name;
    80004a9c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004aa0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004aa4:	0204a423          	sw	zero,40(s1)
}
    80004aa8:	60e2                	ld	ra,24(sp)
    80004aaa:	6442                	ld	s0,16(sp)
    80004aac:	64a2                	ld	s1,8(sp)
    80004aae:	6902                	ld	s2,0(sp)
    80004ab0:	6105                	addi	sp,sp,32
    80004ab2:	8082                	ret

0000000080004ab4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ab4:	1101                	addi	sp,sp,-32
    80004ab6:	ec06                	sd	ra,24(sp)
    80004ab8:	e822                	sd	s0,16(sp)
    80004aba:	e426                	sd	s1,8(sp)
    80004abc:	e04a                	sd	s2,0(sp)
    80004abe:	1000                	addi	s0,sp,32
    80004ac0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ac2:	00850913          	addi	s2,a0,8
    80004ac6:	854a                	mv	a0,s2
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	11c080e7          	jalr	284(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004ad0:	409c                	lw	a5,0(s1)
    80004ad2:	cb89                	beqz	a5,80004ae4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004ad4:	85ca                	mv	a1,s2
    80004ad6:	8526                	mv	a0,s1
    80004ad8:	ffffd097          	auipc	ra,0xffffd
    80004adc:	5dc080e7          	jalr	1500(ra) # 800020b4 <sleep>
  while (lk->locked) {
    80004ae0:	409c                	lw	a5,0(s1)
    80004ae2:	fbed                	bnez	a5,80004ad4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ae4:	4785                	li	a5,1
    80004ae6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ae8:	ffffd097          	auipc	ra,0xffffd
    80004aec:	eec080e7          	jalr	-276(ra) # 800019d4 <myproc>
    80004af0:	591c                	lw	a5,48(a0)
    80004af2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004af4:	854a                	mv	a0,s2
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	1a2080e7          	jalr	418(ra) # 80000c98 <release>
}
    80004afe:	60e2                	ld	ra,24(sp)
    80004b00:	6442                	ld	s0,16(sp)
    80004b02:	64a2                	ld	s1,8(sp)
    80004b04:	6902                	ld	s2,0(sp)
    80004b06:	6105                	addi	sp,sp,32
    80004b08:	8082                	ret

0000000080004b0a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b0a:	1101                	addi	sp,sp,-32
    80004b0c:	ec06                	sd	ra,24(sp)
    80004b0e:	e822                	sd	s0,16(sp)
    80004b10:	e426                	sd	s1,8(sp)
    80004b12:	e04a                	sd	s2,0(sp)
    80004b14:	1000                	addi	s0,sp,32
    80004b16:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b18:	00850913          	addi	s2,a0,8
    80004b1c:	854a                	mv	a0,s2
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	0c6080e7          	jalr	198(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b26:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b2a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b2e:	8526                	mv	a0,s1
    80004b30:	ffffd097          	auipc	ra,0xffffd
    80004b34:	710080e7          	jalr	1808(ra) # 80002240 <wakeup>
  release(&lk->lk);
    80004b38:	854a                	mv	a0,s2
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	15e080e7          	jalr	350(ra) # 80000c98 <release>
}
    80004b42:	60e2                	ld	ra,24(sp)
    80004b44:	6442                	ld	s0,16(sp)
    80004b46:	64a2                	ld	s1,8(sp)
    80004b48:	6902                	ld	s2,0(sp)
    80004b4a:	6105                	addi	sp,sp,32
    80004b4c:	8082                	ret

0000000080004b4e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b4e:	7179                	addi	sp,sp,-48
    80004b50:	f406                	sd	ra,40(sp)
    80004b52:	f022                	sd	s0,32(sp)
    80004b54:	ec26                	sd	s1,24(sp)
    80004b56:	e84a                	sd	s2,16(sp)
    80004b58:	e44e                	sd	s3,8(sp)
    80004b5a:	1800                	addi	s0,sp,48
    80004b5c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b5e:	00850913          	addi	s2,a0,8
    80004b62:	854a                	mv	a0,s2
    80004b64:	ffffc097          	auipc	ra,0xffffc
    80004b68:	080080e7          	jalr	128(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b6c:	409c                	lw	a5,0(s1)
    80004b6e:	ef99                	bnez	a5,80004b8c <holdingsleep+0x3e>
    80004b70:	4481                	li	s1,0
  release(&lk->lk);
    80004b72:	854a                	mv	a0,s2
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	124080e7          	jalr	292(ra) # 80000c98 <release>
  return r;
}
    80004b7c:	8526                	mv	a0,s1
    80004b7e:	70a2                	ld	ra,40(sp)
    80004b80:	7402                	ld	s0,32(sp)
    80004b82:	64e2                	ld	s1,24(sp)
    80004b84:	6942                	ld	s2,16(sp)
    80004b86:	69a2                	ld	s3,8(sp)
    80004b88:	6145                	addi	sp,sp,48
    80004b8a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b8c:	0284a983          	lw	s3,40(s1)
    80004b90:	ffffd097          	auipc	ra,0xffffd
    80004b94:	e44080e7          	jalr	-444(ra) # 800019d4 <myproc>
    80004b98:	5904                	lw	s1,48(a0)
    80004b9a:	413484b3          	sub	s1,s1,s3
    80004b9e:	0014b493          	seqz	s1,s1
    80004ba2:	bfc1                	j	80004b72 <holdingsleep+0x24>

0000000080004ba4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ba4:	1141                	addi	sp,sp,-16
    80004ba6:	e406                	sd	ra,8(sp)
    80004ba8:	e022                	sd	s0,0(sp)
    80004baa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004bac:	00004597          	auipc	a1,0x4
    80004bb0:	c7458593          	addi	a1,a1,-908 # 80008820 <syscalls+0x250>
    80004bb4:	0001e517          	auipc	a0,0x1e
    80004bb8:	47c50513          	addi	a0,a0,1148 # 80023030 <ftable>
    80004bbc:	ffffc097          	auipc	ra,0xffffc
    80004bc0:	f98080e7          	jalr	-104(ra) # 80000b54 <initlock>
}
    80004bc4:	60a2                	ld	ra,8(sp)
    80004bc6:	6402                	ld	s0,0(sp)
    80004bc8:	0141                	addi	sp,sp,16
    80004bca:	8082                	ret

0000000080004bcc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bcc:	1101                	addi	sp,sp,-32
    80004bce:	ec06                	sd	ra,24(sp)
    80004bd0:	e822                	sd	s0,16(sp)
    80004bd2:	e426                	sd	s1,8(sp)
    80004bd4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bd6:	0001e517          	auipc	a0,0x1e
    80004bda:	45a50513          	addi	a0,a0,1114 # 80023030 <ftable>
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	006080e7          	jalr	6(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004be6:	0001e497          	auipc	s1,0x1e
    80004bea:	46248493          	addi	s1,s1,1122 # 80023048 <ftable+0x18>
    80004bee:	0001f717          	auipc	a4,0x1f
    80004bf2:	3fa70713          	addi	a4,a4,1018 # 80023fe8 <ftable+0xfb8>
    if(f->ref == 0){
    80004bf6:	40dc                	lw	a5,4(s1)
    80004bf8:	cf99                	beqz	a5,80004c16 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bfa:	02848493          	addi	s1,s1,40
    80004bfe:	fee49ce3          	bne	s1,a4,80004bf6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c02:	0001e517          	auipc	a0,0x1e
    80004c06:	42e50513          	addi	a0,a0,1070 # 80023030 <ftable>
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	08e080e7          	jalr	142(ra) # 80000c98 <release>
  return 0;
    80004c12:	4481                	li	s1,0
    80004c14:	a819                	j	80004c2a <filealloc+0x5e>
      f->ref = 1;
    80004c16:	4785                	li	a5,1
    80004c18:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c1a:	0001e517          	auipc	a0,0x1e
    80004c1e:	41650513          	addi	a0,a0,1046 # 80023030 <ftable>
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	076080e7          	jalr	118(ra) # 80000c98 <release>
}
    80004c2a:	8526                	mv	a0,s1
    80004c2c:	60e2                	ld	ra,24(sp)
    80004c2e:	6442                	ld	s0,16(sp)
    80004c30:	64a2                	ld	s1,8(sp)
    80004c32:	6105                	addi	sp,sp,32
    80004c34:	8082                	ret

0000000080004c36 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c36:	1101                	addi	sp,sp,-32
    80004c38:	ec06                	sd	ra,24(sp)
    80004c3a:	e822                	sd	s0,16(sp)
    80004c3c:	e426                	sd	s1,8(sp)
    80004c3e:	1000                	addi	s0,sp,32
    80004c40:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c42:	0001e517          	auipc	a0,0x1e
    80004c46:	3ee50513          	addi	a0,a0,1006 # 80023030 <ftable>
    80004c4a:	ffffc097          	auipc	ra,0xffffc
    80004c4e:	f9a080e7          	jalr	-102(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c52:	40dc                	lw	a5,4(s1)
    80004c54:	02f05263          	blez	a5,80004c78 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c58:	2785                	addiw	a5,a5,1
    80004c5a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c5c:	0001e517          	auipc	a0,0x1e
    80004c60:	3d450513          	addi	a0,a0,980 # 80023030 <ftable>
    80004c64:	ffffc097          	auipc	ra,0xffffc
    80004c68:	034080e7          	jalr	52(ra) # 80000c98 <release>
  return f;
}
    80004c6c:	8526                	mv	a0,s1
    80004c6e:	60e2                	ld	ra,24(sp)
    80004c70:	6442                	ld	s0,16(sp)
    80004c72:	64a2                	ld	s1,8(sp)
    80004c74:	6105                	addi	sp,sp,32
    80004c76:	8082                	ret
    panic("filedup");
    80004c78:	00004517          	auipc	a0,0x4
    80004c7c:	bb050513          	addi	a0,a0,-1104 # 80008828 <syscalls+0x258>
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>

0000000080004c88 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c88:	7139                	addi	sp,sp,-64
    80004c8a:	fc06                	sd	ra,56(sp)
    80004c8c:	f822                	sd	s0,48(sp)
    80004c8e:	f426                	sd	s1,40(sp)
    80004c90:	f04a                	sd	s2,32(sp)
    80004c92:	ec4e                	sd	s3,24(sp)
    80004c94:	e852                	sd	s4,16(sp)
    80004c96:	e456                	sd	s5,8(sp)
    80004c98:	0080                	addi	s0,sp,64
    80004c9a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c9c:	0001e517          	auipc	a0,0x1e
    80004ca0:	39450513          	addi	a0,a0,916 # 80023030 <ftable>
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	f40080e7          	jalr	-192(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004cac:	40dc                	lw	a5,4(s1)
    80004cae:	06f05163          	blez	a5,80004d10 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004cb2:	37fd                	addiw	a5,a5,-1
    80004cb4:	0007871b          	sext.w	a4,a5
    80004cb8:	c0dc                	sw	a5,4(s1)
    80004cba:	06e04363          	bgtz	a4,80004d20 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004cbe:	0004a903          	lw	s2,0(s1)
    80004cc2:	0094ca83          	lbu	s5,9(s1)
    80004cc6:	0104ba03          	ld	s4,16(s1)
    80004cca:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cce:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cd2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cd6:	0001e517          	auipc	a0,0x1e
    80004cda:	35a50513          	addi	a0,a0,858 # 80023030 <ftable>
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	fba080e7          	jalr	-70(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004ce6:	4785                	li	a5,1
    80004ce8:	04f90d63          	beq	s2,a5,80004d42 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004cec:	3979                	addiw	s2,s2,-2
    80004cee:	4785                	li	a5,1
    80004cf0:	0527e063          	bltu	a5,s2,80004d30 <fileclose+0xa8>
    begin_op();
    80004cf4:	00000097          	auipc	ra,0x0
    80004cf8:	ac8080e7          	jalr	-1336(ra) # 800047bc <begin_op>
    iput(ff.ip);
    80004cfc:	854e                	mv	a0,s3
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	2a6080e7          	jalr	678(ra) # 80003fa4 <iput>
    end_op();
    80004d06:	00000097          	auipc	ra,0x0
    80004d0a:	b36080e7          	jalr	-1226(ra) # 8000483c <end_op>
    80004d0e:	a00d                	j	80004d30 <fileclose+0xa8>
    panic("fileclose");
    80004d10:	00004517          	auipc	a0,0x4
    80004d14:	b2050513          	addi	a0,a0,-1248 # 80008830 <syscalls+0x260>
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	826080e7          	jalr	-2010(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d20:	0001e517          	auipc	a0,0x1e
    80004d24:	31050513          	addi	a0,a0,784 # 80023030 <ftable>
    80004d28:	ffffc097          	auipc	ra,0xffffc
    80004d2c:	f70080e7          	jalr	-144(ra) # 80000c98 <release>
  }
}
    80004d30:	70e2                	ld	ra,56(sp)
    80004d32:	7442                	ld	s0,48(sp)
    80004d34:	74a2                	ld	s1,40(sp)
    80004d36:	7902                	ld	s2,32(sp)
    80004d38:	69e2                	ld	s3,24(sp)
    80004d3a:	6a42                	ld	s4,16(sp)
    80004d3c:	6aa2                	ld	s5,8(sp)
    80004d3e:	6121                	addi	sp,sp,64
    80004d40:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d42:	85d6                	mv	a1,s5
    80004d44:	8552                	mv	a0,s4
    80004d46:	00000097          	auipc	ra,0x0
    80004d4a:	34c080e7          	jalr	844(ra) # 80005092 <pipeclose>
    80004d4e:	b7cd                	j	80004d30 <fileclose+0xa8>

0000000080004d50 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d50:	715d                	addi	sp,sp,-80
    80004d52:	e486                	sd	ra,72(sp)
    80004d54:	e0a2                	sd	s0,64(sp)
    80004d56:	fc26                	sd	s1,56(sp)
    80004d58:	f84a                	sd	s2,48(sp)
    80004d5a:	f44e                	sd	s3,40(sp)
    80004d5c:	0880                	addi	s0,sp,80
    80004d5e:	84aa                	mv	s1,a0
    80004d60:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d62:	ffffd097          	auipc	ra,0xffffd
    80004d66:	c72080e7          	jalr	-910(ra) # 800019d4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d6a:	409c                	lw	a5,0(s1)
    80004d6c:	37f9                	addiw	a5,a5,-2
    80004d6e:	4705                	li	a4,1
    80004d70:	04f76763          	bltu	a4,a5,80004dbe <filestat+0x6e>
    80004d74:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d76:	6c88                	ld	a0,24(s1)
    80004d78:	fffff097          	auipc	ra,0xfffff
    80004d7c:	072080e7          	jalr	114(ra) # 80003dea <ilock>
    stati(f->ip, &st);
    80004d80:	fb840593          	addi	a1,s0,-72
    80004d84:	6c88                	ld	a0,24(s1)
    80004d86:	fffff097          	auipc	ra,0xfffff
    80004d8a:	2ee080e7          	jalr	750(ra) # 80004074 <stati>
    iunlock(f->ip);
    80004d8e:	6c88                	ld	a0,24(s1)
    80004d90:	fffff097          	auipc	ra,0xfffff
    80004d94:	11c080e7          	jalr	284(ra) # 80003eac <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d98:	46e1                	li	a3,24
    80004d9a:	fb840613          	addi	a2,s0,-72
    80004d9e:	85ce                	mv	a1,s3
    80004da0:	05093503          	ld	a0,80(s2)
    80004da4:	ffffd097          	auipc	ra,0xffffd
    80004da8:	8ce080e7          	jalr	-1842(ra) # 80001672 <copyout>
    80004dac:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004db0:	60a6                	ld	ra,72(sp)
    80004db2:	6406                	ld	s0,64(sp)
    80004db4:	74e2                	ld	s1,56(sp)
    80004db6:	7942                	ld	s2,48(sp)
    80004db8:	79a2                	ld	s3,40(sp)
    80004dba:	6161                	addi	sp,sp,80
    80004dbc:	8082                	ret
  return -1;
    80004dbe:	557d                	li	a0,-1
    80004dc0:	bfc5                	j	80004db0 <filestat+0x60>

0000000080004dc2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004dc2:	7179                	addi	sp,sp,-48
    80004dc4:	f406                	sd	ra,40(sp)
    80004dc6:	f022                	sd	s0,32(sp)
    80004dc8:	ec26                	sd	s1,24(sp)
    80004dca:	e84a                	sd	s2,16(sp)
    80004dcc:	e44e                	sd	s3,8(sp)
    80004dce:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004dd0:	00854783          	lbu	a5,8(a0)
    80004dd4:	c3d5                	beqz	a5,80004e78 <fileread+0xb6>
    80004dd6:	84aa                	mv	s1,a0
    80004dd8:	89ae                	mv	s3,a1
    80004dda:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ddc:	411c                	lw	a5,0(a0)
    80004dde:	4705                	li	a4,1
    80004de0:	04e78963          	beq	a5,a4,80004e32 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004de4:	470d                	li	a4,3
    80004de6:	04e78d63          	beq	a5,a4,80004e40 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dea:	4709                	li	a4,2
    80004dec:	06e79e63          	bne	a5,a4,80004e68 <fileread+0xa6>
    ilock(f->ip);
    80004df0:	6d08                	ld	a0,24(a0)
    80004df2:	fffff097          	auipc	ra,0xfffff
    80004df6:	ff8080e7          	jalr	-8(ra) # 80003dea <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004dfa:	874a                	mv	a4,s2
    80004dfc:	5094                	lw	a3,32(s1)
    80004dfe:	864e                	mv	a2,s3
    80004e00:	4585                	li	a1,1
    80004e02:	6c88                	ld	a0,24(s1)
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	29a080e7          	jalr	666(ra) # 8000409e <readi>
    80004e0c:	892a                	mv	s2,a0
    80004e0e:	00a05563          	blez	a0,80004e18 <fileread+0x56>
      f->off += r;
    80004e12:	509c                	lw	a5,32(s1)
    80004e14:	9fa9                	addw	a5,a5,a0
    80004e16:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e18:	6c88                	ld	a0,24(s1)
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	092080e7          	jalr	146(ra) # 80003eac <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e22:	854a                	mv	a0,s2
    80004e24:	70a2                	ld	ra,40(sp)
    80004e26:	7402                	ld	s0,32(sp)
    80004e28:	64e2                	ld	s1,24(sp)
    80004e2a:	6942                	ld	s2,16(sp)
    80004e2c:	69a2                	ld	s3,8(sp)
    80004e2e:	6145                	addi	sp,sp,48
    80004e30:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e32:	6908                	ld	a0,16(a0)
    80004e34:	00000097          	auipc	ra,0x0
    80004e38:	3c8080e7          	jalr	968(ra) # 800051fc <piperead>
    80004e3c:	892a                	mv	s2,a0
    80004e3e:	b7d5                	j	80004e22 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e40:	02451783          	lh	a5,36(a0)
    80004e44:	03079693          	slli	a3,a5,0x30
    80004e48:	92c1                	srli	a3,a3,0x30
    80004e4a:	4725                	li	a4,9
    80004e4c:	02d76863          	bltu	a4,a3,80004e7c <fileread+0xba>
    80004e50:	0792                	slli	a5,a5,0x4
    80004e52:	0001e717          	auipc	a4,0x1e
    80004e56:	13e70713          	addi	a4,a4,318 # 80022f90 <devsw>
    80004e5a:	97ba                	add	a5,a5,a4
    80004e5c:	639c                	ld	a5,0(a5)
    80004e5e:	c38d                	beqz	a5,80004e80 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e60:	4505                	li	a0,1
    80004e62:	9782                	jalr	a5
    80004e64:	892a                	mv	s2,a0
    80004e66:	bf75                	j	80004e22 <fileread+0x60>
    panic("fileread");
    80004e68:	00004517          	auipc	a0,0x4
    80004e6c:	9d850513          	addi	a0,a0,-1576 # 80008840 <syscalls+0x270>
    80004e70:	ffffb097          	auipc	ra,0xffffb
    80004e74:	6ce080e7          	jalr	1742(ra) # 8000053e <panic>
    return -1;
    80004e78:	597d                	li	s2,-1
    80004e7a:	b765                	j	80004e22 <fileread+0x60>
      return -1;
    80004e7c:	597d                	li	s2,-1
    80004e7e:	b755                	j	80004e22 <fileread+0x60>
    80004e80:	597d                	li	s2,-1
    80004e82:	b745                	j	80004e22 <fileread+0x60>

0000000080004e84 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e84:	715d                	addi	sp,sp,-80
    80004e86:	e486                	sd	ra,72(sp)
    80004e88:	e0a2                	sd	s0,64(sp)
    80004e8a:	fc26                	sd	s1,56(sp)
    80004e8c:	f84a                	sd	s2,48(sp)
    80004e8e:	f44e                	sd	s3,40(sp)
    80004e90:	f052                	sd	s4,32(sp)
    80004e92:	ec56                	sd	s5,24(sp)
    80004e94:	e85a                	sd	s6,16(sp)
    80004e96:	e45e                	sd	s7,8(sp)
    80004e98:	e062                	sd	s8,0(sp)
    80004e9a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e9c:	00954783          	lbu	a5,9(a0)
    80004ea0:	10078663          	beqz	a5,80004fac <filewrite+0x128>
    80004ea4:	892a                	mv	s2,a0
    80004ea6:	8aae                	mv	s5,a1
    80004ea8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004eaa:	411c                	lw	a5,0(a0)
    80004eac:	4705                	li	a4,1
    80004eae:	02e78263          	beq	a5,a4,80004ed2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004eb2:	470d                	li	a4,3
    80004eb4:	02e78663          	beq	a5,a4,80004ee0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004eb8:	4709                	li	a4,2
    80004eba:	0ee79163          	bne	a5,a4,80004f9c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ebe:	0ac05d63          	blez	a2,80004f78 <filewrite+0xf4>
    int i = 0;
    80004ec2:	4981                	li	s3,0
    80004ec4:	6b05                	lui	s6,0x1
    80004ec6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004eca:	6b85                	lui	s7,0x1
    80004ecc:	c00b8b9b          	addiw	s7,s7,-1024
    80004ed0:	a861                	j	80004f68 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ed2:	6908                	ld	a0,16(a0)
    80004ed4:	00000097          	auipc	ra,0x0
    80004ed8:	22e080e7          	jalr	558(ra) # 80005102 <pipewrite>
    80004edc:	8a2a                	mv	s4,a0
    80004ede:	a045                	j	80004f7e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ee0:	02451783          	lh	a5,36(a0)
    80004ee4:	03079693          	slli	a3,a5,0x30
    80004ee8:	92c1                	srli	a3,a3,0x30
    80004eea:	4725                	li	a4,9
    80004eec:	0cd76263          	bltu	a4,a3,80004fb0 <filewrite+0x12c>
    80004ef0:	0792                	slli	a5,a5,0x4
    80004ef2:	0001e717          	auipc	a4,0x1e
    80004ef6:	09e70713          	addi	a4,a4,158 # 80022f90 <devsw>
    80004efa:	97ba                	add	a5,a5,a4
    80004efc:	679c                	ld	a5,8(a5)
    80004efe:	cbdd                	beqz	a5,80004fb4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f00:	4505                	li	a0,1
    80004f02:	9782                	jalr	a5
    80004f04:	8a2a                	mv	s4,a0
    80004f06:	a8a5                	j	80004f7e <filewrite+0xfa>
    80004f08:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f0c:	00000097          	auipc	ra,0x0
    80004f10:	8b0080e7          	jalr	-1872(ra) # 800047bc <begin_op>
      ilock(f->ip);
    80004f14:	01893503          	ld	a0,24(s2)
    80004f18:	fffff097          	auipc	ra,0xfffff
    80004f1c:	ed2080e7          	jalr	-302(ra) # 80003dea <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f20:	8762                	mv	a4,s8
    80004f22:	02092683          	lw	a3,32(s2)
    80004f26:	01598633          	add	a2,s3,s5
    80004f2a:	4585                	li	a1,1
    80004f2c:	01893503          	ld	a0,24(s2)
    80004f30:	fffff097          	auipc	ra,0xfffff
    80004f34:	266080e7          	jalr	614(ra) # 80004196 <writei>
    80004f38:	84aa                	mv	s1,a0
    80004f3a:	00a05763          	blez	a0,80004f48 <filewrite+0xc4>
        f->off += r;
    80004f3e:	02092783          	lw	a5,32(s2)
    80004f42:	9fa9                	addw	a5,a5,a0
    80004f44:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f48:	01893503          	ld	a0,24(s2)
    80004f4c:	fffff097          	auipc	ra,0xfffff
    80004f50:	f60080e7          	jalr	-160(ra) # 80003eac <iunlock>
      end_op();
    80004f54:	00000097          	auipc	ra,0x0
    80004f58:	8e8080e7          	jalr	-1816(ra) # 8000483c <end_op>

      if(r != n1){
    80004f5c:	009c1f63          	bne	s8,s1,80004f7a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f60:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f64:	0149db63          	bge	s3,s4,80004f7a <filewrite+0xf6>
      int n1 = n - i;
    80004f68:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f6c:	84be                	mv	s1,a5
    80004f6e:	2781                	sext.w	a5,a5
    80004f70:	f8fb5ce3          	bge	s6,a5,80004f08 <filewrite+0x84>
    80004f74:	84de                	mv	s1,s7
    80004f76:	bf49                	j	80004f08 <filewrite+0x84>
    int i = 0;
    80004f78:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f7a:	013a1f63          	bne	s4,s3,80004f98 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f7e:	8552                	mv	a0,s4
    80004f80:	60a6                	ld	ra,72(sp)
    80004f82:	6406                	ld	s0,64(sp)
    80004f84:	74e2                	ld	s1,56(sp)
    80004f86:	7942                	ld	s2,48(sp)
    80004f88:	79a2                	ld	s3,40(sp)
    80004f8a:	7a02                	ld	s4,32(sp)
    80004f8c:	6ae2                	ld	s5,24(sp)
    80004f8e:	6b42                	ld	s6,16(sp)
    80004f90:	6ba2                	ld	s7,8(sp)
    80004f92:	6c02                	ld	s8,0(sp)
    80004f94:	6161                	addi	sp,sp,80
    80004f96:	8082                	ret
    ret = (i == n ? n : -1);
    80004f98:	5a7d                	li	s4,-1
    80004f9a:	b7d5                	j	80004f7e <filewrite+0xfa>
    panic("filewrite");
    80004f9c:	00004517          	auipc	a0,0x4
    80004fa0:	8b450513          	addi	a0,a0,-1868 # 80008850 <syscalls+0x280>
    80004fa4:	ffffb097          	auipc	ra,0xffffb
    80004fa8:	59a080e7          	jalr	1434(ra) # 8000053e <panic>
    return -1;
    80004fac:	5a7d                	li	s4,-1
    80004fae:	bfc1                	j	80004f7e <filewrite+0xfa>
      return -1;
    80004fb0:	5a7d                	li	s4,-1
    80004fb2:	b7f1                	j	80004f7e <filewrite+0xfa>
    80004fb4:	5a7d                	li	s4,-1
    80004fb6:	b7e1                	j	80004f7e <filewrite+0xfa>

0000000080004fb8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004fb8:	7179                	addi	sp,sp,-48
    80004fba:	f406                	sd	ra,40(sp)
    80004fbc:	f022                	sd	s0,32(sp)
    80004fbe:	ec26                	sd	s1,24(sp)
    80004fc0:	e84a                	sd	s2,16(sp)
    80004fc2:	e44e                	sd	s3,8(sp)
    80004fc4:	e052                	sd	s4,0(sp)
    80004fc6:	1800                	addi	s0,sp,48
    80004fc8:	84aa                	mv	s1,a0
    80004fca:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fcc:	0005b023          	sd	zero,0(a1)
    80004fd0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004fd4:	00000097          	auipc	ra,0x0
    80004fd8:	bf8080e7          	jalr	-1032(ra) # 80004bcc <filealloc>
    80004fdc:	e088                	sd	a0,0(s1)
    80004fde:	c551                	beqz	a0,8000506a <pipealloc+0xb2>
    80004fe0:	00000097          	auipc	ra,0x0
    80004fe4:	bec080e7          	jalr	-1044(ra) # 80004bcc <filealloc>
    80004fe8:	00aa3023          	sd	a0,0(s4)
    80004fec:	c92d                	beqz	a0,8000505e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fee:	ffffc097          	auipc	ra,0xffffc
    80004ff2:	b06080e7          	jalr	-1274(ra) # 80000af4 <kalloc>
    80004ff6:	892a                	mv	s2,a0
    80004ff8:	c125                	beqz	a0,80005058 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ffa:	4985                	li	s3,1
    80004ffc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005000:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005004:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005008:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000500c:	00003597          	auipc	a1,0x3
    80005010:	4a458593          	addi	a1,a1,1188 # 800084b0 <all_states.1776+0x1c8>
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	b40080e7          	jalr	-1216(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000501c:	609c                	ld	a5,0(s1)
    8000501e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005022:	609c                	ld	a5,0(s1)
    80005024:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005028:	609c                	ld	a5,0(s1)
    8000502a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000502e:	609c                	ld	a5,0(s1)
    80005030:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005034:	000a3783          	ld	a5,0(s4)
    80005038:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000503c:	000a3783          	ld	a5,0(s4)
    80005040:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005044:	000a3783          	ld	a5,0(s4)
    80005048:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000504c:	000a3783          	ld	a5,0(s4)
    80005050:	0127b823          	sd	s2,16(a5)
  return 0;
    80005054:	4501                	li	a0,0
    80005056:	a025                	j	8000507e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005058:	6088                	ld	a0,0(s1)
    8000505a:	e501                	bnez	a0,80005062 <pipealloc+0xaa>
    8000505c:	a039                	j	8000506a <pipealloc+0xb2>
    8000505e:	6088                	ld	a0,0(s1)
    80005060:	c51d                	beqz	a0,8000508e <pipealloc+0xd6>
    fileclose(*f0);
    80005062:	00000097          	auipc	ra,0x0
    80005066:	c26080e7          	jalr	-986(ra) # 80004c88 <fileclose>
  if(*f1)
    8000506a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000506e:	557d                	li	a0,-1
  if(*f1)
    80005070:	c799                	beqz	a5,8000507e <pipealloc+0xc6>
    fileclose(*f1);
    80005072:	853e                	mv	a0,a5
    80005074:	00000097          	auipc	ra,0x0
    80005078:	c14080e7          	jalr	-1004(ra) # 80004c88 <fileclose>
  return -1;
    8000507c:	557d                	li	a0,-1
}
    8000507e:	70a2                	ld	ra,40(sp)
    80005080:	7402                	ld	s0,32(sp)
    80005082:	64e2                	ld	s1,24(sp)
    80005084:	6942                	ld	s2,16(sp)
    80005086:	69a2                	ld	s3,8(sp)
    80005088:	6a02                	ld	s4,0(sp)
    8000508a:	6145                	addi	sp,sp,48
    8000508c:	8082                	ret
  return -1;
    8000508e:	557d                	li	a0,-1
    80005090:	b7fd                	j	8000507e <pipealloc+0xc6>

0000000080005092 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005092:	1101                	addi	sp,sp,-32
    80005094:	ec06                	sd	ra,24(sp)
    80005096:	e822                	sd	s0,16(sp)
    80005098:	e426                	sd	s1,8(sp)
    8000509a:	e04a                	sd	s2,0(sp)
    8000509c:	1000                	addi	s0,sp,32
    8000509e:	84aa                	mv	s1,a0
    800050a0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050a2:	ffffc097          	auipc	ra,0xffffc
    800050a6:	b42080e7          	jalr	-1214(ra) # 80000be4 <acquire>
  if(writable){
    800050aa:	02090d63          	beqz	s2,800050e4 <pipeclose+0x52>
    pi->writeopen = 0;
    800050ae:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050b2:	21848513          	addi	a0,s1,536
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	18a080e7          	jalr	394(ra) # 80002240 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050be:	2204b783          	ld	a5,544(s1)
    800050c2:	eb95                	bnez	a5,800050f6 <pipeclose+0x64>
    release(&pi->lock);
    800050c4:	8526                	mv	a0,s1
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	bd2080e7          	jalr	-1070(ra) # 80000c98 <release>
    kfree((char*)pi);
    800050ce:	8526                	mv	a0,s1
    800050d0:	ffffc097          	auipc	ra,0xffffc
    800050d4:	928080e7          	jalr	-1752(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800050d8:	60e2                	ld	ra,24(sp)
    800050da:	6442                	ld	s0,16(sp)
    800050dc:	64a2                	ld	s1,8(sp)
    800050de:	6902                	ld	s2,0(sp)
    800050e0:	6105                	addi	sp,sp,32
    800050e2:	8082                	ret
    pi->readopen = 0;
    800050e4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050e8:	21c48513          	addi	a0,s1,540
    800050ec:	ffffd097          	auipc	ra,0xffffd
    800050f0:	154080e7          	jalr	340(ra) # 80002240 <wakeup>
    800050f4:	b7e9                	j	800050be <pipeclose+0x2c>
    release(&pi->lock);
    800050f6:	8526                	mv	a0,s1
    800050f8:	ffffc097          	auipc	ra,0xffffc
    800050fc:	ba0080e7          	jalr	-1120(ra) # 80000c98 <release>
}
    80005100:	bfe1                	j	800050d8 <pipeclose+0x46>

0000000080005102 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005102:	7159                	addi	sp,sp,-112
    80005104:	f486                	sd	ra,104(sp)
    80005106:	f0a2                	sd	s0,96(sp)
    80005108:	eca6                	sd	s1,88(sp)
    8000510a:	e8ca                	sd	s2,80(sp)
    8000510c:	e4ce                	sd	s3,72(sp)
    8000510e:	e0d2                	sd	s4,64(sp)
    80005110:	fc56                	sd	s5,56(sp)
    80005112:	f85a                	sd	s6,48(sp)
    80005114:	f45e                	sd	s7,40(sp)
    80005116:	f062                	sd	s8,32(sp)
    80005118:	ec66                	sd	s9,24(sp)
    8000511a:	1880                	addi	s0,sp,112
    8000511c:	84aa                	mv	s1,a0
    8000511e:	8aae                	mv	s5,a1
    80005120:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005122:	ffffd097          	auipc	ra,0xffffd
    80005126:	8b2080e7          	jalr	-1870(ra) # 800019d4 <myproc>
    8000512a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000512c:	8526                	mv	a0,s1
    8000512e:	ffffc097          	auipc	ra,0xffffc
    80005132:	ab6080e7          	jalr	-1354(ra) # 80000be4 <acquire>
  while(i < n){
    80005136:	0d405163          	blez	s4,800051f8 <pipewrite+0xf6>
    8000513a:	8ba6                	mv	s7,s1
  int i = 0;
    8000513c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000513e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005140:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005144:	21c48c13          	addi	s8,s1,540
    80005148:	a08d                	j	800051aa <pipewrite+0xa8>
      release(&pi->lock);
    8000514a:	8526                	mv	a0,s1
    8000514c:	ffffc097          	auipc	ra,0xffffc
    80005150:	b4c080e7          	jalr	-1204(ra) # 80000c98 <release>
      return -1;
    80005154:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005156:	854a                	mv	a0,s2
    80005158:	70a6                	ld	ra,104(sp)
    8000515a:	7406                	ld	s0,96(sp)
    8000515c:	64e6                	ld	s1,88(sp)
    8000515e:	6946                	ld	s2,80(sp)
    80005160:	69a6                	ld	s3,72(sp)
    80005162:	6a06                	ld	s4,64(sp)
    80005164:	7ae2                	ld	s5,56(sp)
    80005166:	7b42                	ld	s6,48(sp)
    80005168:	7ba2                	ld	s7,40(sp)
    8000516a:	7c02                	ld	s8,32(sp)
    8000516c:	6ce2                	ld	s9,24(sp)
    8000516e:	6165                	addi	sp,sp,112
    80005170:	8082                	ret
      wakeup(&pi->nread);
    80005172:	8566                	mv	a0,s9
    80005174:	ffffd097          	auipc	ra,0xffffd
    80005178:	0cc080e7          	jalr	204(ra) # 80002240 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000517c:	85de                	mv	a1,s7
    8000517e:	8562                	mv	a0,s8
    80005180:	ffffd097          	auipc	ra,0xffffd
    80005184:	f34080e7          	jalr	-204(ra) # 800020b4 <sleep>
    80005188:	a839                	j	800051a6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000518a:	21c4a783          	lw	a5,540(s1)
    8000518e:	0017871b          	addiw	a4,a5,1
    80005192:	20e4ae23          	sw	a4,540(s1)
    80005196:	1ff7f793          	andi	a5,a5,511
    8000519a:	97a6                	add	a5,a5,s1
    8000519c:	f9f44703          	lbu	a4,-97(s0)
    800051a0:	00e78c23          	sb	a4,24(a5)
      i++;
    800051a4:	2905                	addiw	s2,s2,1
  while(i < n){
    800051a6:	03495d63          	bge	s2,s4,800051e0 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800051aa:	2204a783          	lw	a5,544(s1)
    800051ae:	dfd1                	beqz	a5,8000514a <pipewrite+0x48>
    800051b0:	0289a783          	lw	a5,40(s3)
    800051b4:	fbd9                	bnez	a5,8000514a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051b6:	2184a783          	lw	a5,536(s1)
    800051ba:	21c4a703          	lw	a4,540(s1)
    800051be:	2007879b          	addiw	a5,a5,512
    800051c2:	faf708e3          	beq	a4,a5,80005172 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051c6:	4685                	li	a3,1
    800051c8:	01590633          	add	a2,s2,s5
    800051cc:	f9f40593          	addi	a1,s0,-97
    800051d0:	0509b503          	ld	a0,80(s3)
    800051d4:	ffffc097          	auipc	ra,0xffffc
    800051d8:	52a080e7          	jalr	1322(ra) # 800016fe <copyin>
    800051dc:	fb6517e3          	bne	a0,s6,8000518a <pipewrite+0x88>
  wakeup(&pi->nread);
    800051e0:	21848513          	addi	a0,s1,536
    800051e4:	ffffd097          	auipc	ra,0xffffd
    800051e8:	05c080e7          	jalr	92(ra) # 80002240 <wakeup>
  release(&pi->lock);
    800051ec:	8526                	mv	a0,s1
    800051ee:	ffffc097          	auipc	ra,0xffffc
    800051f2:	aaa080e7          	jalr	-1366(ra) # 80000c98 <release>
  return i;
    800051f6:	b785                	j	80005156 <pipewrite+0x54>
  int i = 0;
    800051f8:	4901                	li	s2,0
    800051fa:	b7dd                	j	800051e0 <pipewrite+0xde>

00000000800051fc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051fc:	715d                	addi	sp,sp,-80
    800051fe:	e486                	sd	ra,72(sp)
    80005200:	e0a2                	sd	s0,64(sp)
    80005202:	fc26                	sd	s1,56(sp)
    80005204:	f84a                	sd	s2,48(sp)
    80005206:	f44e                	sd	s3,40(sp)
    80005208:	f052                	sd	s4,32(sp)
    8000520a:	ec56                	sd	s5,24(sp)
    8000520c:	e85a                	sd	s6,16(sp)
    8000520e:	0880                	addi	s0,sp,80
    80005210:	84aa                	mv	s1,a0
    80005212:	892e                	mv	s2,a1
    80005214:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	7be080e7          	jalr	1982(ra) # 800019d4 <myproc>
    8000521e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005220:	8b26                	mv	s6,s1
    80005222:	8526                	mv	a0,s1
    80005224:	ffffc097          	auipc	ra,0xffffc
    80005228:	9c0080e7          	jalr	-1600(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000522c:	2184a703          	lw	a4,536(s1)
    80005230:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005234:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005238:	02f71463          	bne	a4,a5,80005260 <piperead+0x64>
    8000523c:	2244a783          	lw	a5,548(s1)
    80005240:	c385                	beqz	a5,80005260 <piperead+0x64>
    if(pr->killed){
    80005242:	028a2783          	lw	a5,40(s4)
    80005246:	ebc1                	bnez	a5,800052d6 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005248:	85da                	mv	a1,s6
    8000524a:	854e                	mv	a0,s3
    8000524c:	ffffd097          	auipc	ra,0xffffd
    80005250:	e68080e7          	jalr	-408(ra) # 800020b4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005254:	2184a703          	lw	a4,536(s1)
    80005258:	21c4a783          	lw	a5,540(s1)
    8000525c:	fef700e3          	beq	a4,a5,8000523c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005260:	09505263          	blez	s5,800052e4 <piperead+0xe8>
    80005264:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005266:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005268:	2184a783          	lw	a5,536(s1)
    8000526c:	21c4a703          	lw	a4,540(s1)
    80005270:	02f70d63          	beq	a4,a5,800052aa <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005274:	0017871b          	addiw	a4,a5,1
    80005278:	20e4ac23          	sw	a4,536(s1)
    8000527c:	1ff7f793          	andi	a5,a5,511
    80005280:	97a6                	add	a5,a5,s1
    80005282:	0187c783          	lbu	a5,24(a5)
    80005286:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000528a:	4685                	li	a3,1
    8000528c:	fbf40613          	addi	a2,s0,-65
    80005290:	85ca                	mv	a1,s2
    80005292:	050a3503          	ld	a0,80(s4)
    80005296:	ffffc097          	auipc	ra,0xffffc
    8000529a:	3dc080e7          	jalr	988(ra) # 80001672 <copyout>
    8000529e:	01650663          	beq	a0,s6,800052aa <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052a2:	2985                	addiw	s3,s3,1
    800052a4:	0905                	addi	s2,s2,1
    800052a6:	fd3a91e3          	bne	s5,s3,80005268 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052aa:	21c48513          	addi	a0,s1,540
    800052ae:	ffffd097          	auipc	ra,0xffffd
    800052b2:	f92080e7          	jalr	-110(ra) # 80002240 <wakeup>
  release(&pi->lock);
    800052b6:	8526                	mv	a0,s1
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	9e0080e7          	jalr	-1568(ra) # 80000c98 <release>
  return i;
}
    800052c0:	854e                	mv	a0,s3
    800052c2:	60a6                	ld	ra,72(sp)
    800052c4:	6406                	ld	s0,64(sp)
    800052c6:	74e2                	ld	s1,56(sp)
    800052c8:	7942                	ld	s2,48(sp)
    800052ca:	79a2                	ld	s3,40(sp)
    800052cc:	7a02                	ld	s4,32(sp)
    800052ce:	6ae2                	ld	s5,24(sp)
    800052d0:	6b42                	ld	s6,16(sp)
    800052d2:	6161                	addi	sp,sp,80
    800052d4:	8082                	ret
      release(&pi->lock);
    800052d6:	8526                	mv	a0,s1
    800052d8:	ffffc097          	auipc	ra,0xffffc
    800052dc:	9c0080e7          	jalr	-1600(ra) # 80000c98 <release>
      return -1;
    800052e0:	59fd                	li	s3,-1
    800052e2:	bff9                	j	800052c0 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052e4:	4981                	li	s3,0
    800052e6:	b7d1                	j	800052aa <piperead+0xae>

00000000800052e8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800052e8:	df010113          	addi	sp,sp,-528
    800052ec:	20113423          	sd	ra,520(sp)
    800052f0:	20813023          	sd	s0,512(sp)
    800052f4:	ffa6                	sd	s1,504(sp)
    800052f6:	fbca                	sd	s2,496(sp)
    800052f8:	f7ce                	sd	s3,488(sp)
    800052fa:	f3d2                	sd	s4,480(sp)
    800052fc:	efd6                	sd	s5,472(sp)
    800052fe:	ebda                	sd	s6,464(sp)
    80005300:	e7de                	sd	s7,456(sp)
    80005302:	e3e2                	sd	s8,448(sp)
    80005304:	ff66                	sd	s9,440(sp)
    80005306:	fb6a                	sd	s10,432(sp)
    80005308:	f76e                	sd	s11,424(sp)
    8000530a:	0c00                	addi	s0,sp,528
    8000530c:	84aa                	mv	s1,a0
    8000530e:	dea43c23          	sd	a0,-520(s0)
    80005312:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005316:	ffffc097          	auipc	ra,0xffffc
    8000531a:	6be080e7          	jalr	1726(ra) # 800019d4 <myproc>
    8000531e:	892a                	mv	s2,a0

  begin_op();
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	49c080e7          	jalr	1180(ra) # 800047bc <begin_op>

  if((ip = namei(path)) == 0){
    80005328:	8526                	mv	a0,s1
    8000532a:	fffff097          	auipc	ra,0xfffff
    8000532e:	276080e7          	jalr	630(ra) # 800045a0 <namei>
    80005332:	c92d                	beqz	a0,800053a4 <exec+0xbc>
    80005334:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	ab4080e7          	jalr	-1356(ra) # 80003dea <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000533e:	04000713          	li	a4,64
    80005342:	4681                	li	a3,0
    80005344:	e5040613          	addi	a2,s0,-432
    80005348:	4581                	li	a1,0
    8000534a:	8526                	mv	a0,s1
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	d52080e7          	jalr	-686(ra) # 8000409e <readi>
    80005354:	04000793          	li	a5,64
    80005358:	00f51a63          	bne	a0,a5,8000536c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000535c:	e5042703          	lw	a4,-432(s0)
    80005360:	464c47b7          	lui	a5,0x464c4
    80005364:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005368:	04f70463          	beq	a4,a5,800053b0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000536c:	8526                	mv	a0,s1
    8000536e:	fffff097          	auipc	ra,0xfffff
    80005372:	cde080e7          	jalr	-802(ra) # 8000404c <iunlockput>
    end_op();
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	4c6080e7          	jalr	1222(ra) # 8000483c <end_op>
  }
  return -1;
    8000537e:	557d                	li	a0,-1
}
    80005380:	20813083          	ld	ra,520(sp)
    80005384:	20013403          	ld	s0,512(sp)
    80005388:	74fe                	ld	s1,504(sp)
    8000538a:	795e                	ld	s2,496(sp)
    8000538c:	79be                	ld	s3,488(sp)
    8000538e:	7a1e                	ld	s4,480(sp)
    80005390:	6afe                	ld	s5,472(sp)
    80005392:	6b5e                	ld	s6,464(sp)
    80005394:	6bbe                	ld	s7,456(sp)
    80005396:	6c1e                	ld	s8,448(sp)
    80005398:	7cfa                	ld	s9,440(sp)
    8000539a:	7d5a                	ld	s10,432(sp)
    8000539c:	7dba                	ld	s11,424(sp)
    8000539e:	21010113          	addi	sp,sp,528
    800053a2:	8082                	ret
    end_op();
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	498080e7          	jalr	1176(ra) # 8000483c <end_op>
    return -1;
    800053ac:	557d                	li	a0,-1
    800053ae:	bfc9                	j	80005380 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053b0:	854a                	mv	a0,s2
    800053b2:	ffffc097          	auipc	ra,0xffffc
    800053b6:	6e6080e7          	jalr	1766(ra) # 80001a98 <proc_pagetable>
    800053ba:	8baa                	mv	s7,a0
    800053bc:	d945                	beqz	a0,8000536c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053be:	e7042983          	lw	s3,-400(s0)
    800053c2:	e8845783          	lhu	a5,-376(s0)
    800053c6:	c7ad                	beqz	a5,80005430 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053c8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053ca:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800053cc:	6c85                	lui	s9,0x1
    800053ce:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800053d2:	def43823          	sd	a5,-528(s0)
    800053d6:	a42d                	j	80005600 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053d8:	00003517          	auipc	a0,0x3
    800053dc:	48850513          	addi	a0,a0,1160 # 80008860 <syscalls+0x290>
    800053e0:	ffffb097          	auipc	ra,0xffffb
    800053e4:	15e080e7          	jalr	350(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053e8:	8756                	mv	a4,s5
    800053ea:	012d86bb          	addw	a3,s11,s2
    800053ee:	4581                	li	a1,0
    800053f0:	8526                	mv	a0,s1
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	cac080e7          	jalr	-852(ra) # 8000409e <readi>
    800053fa:	2501                	sext.w	a0,a0
    800053fc:	1aaa9963          	bne	s5,a0,800055ae <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005400:	6785                	lui	a5,0x1
    80005402:	0127893b          	addw	s2,a5,s2
    80005406:	77fd                	lui	a5,0xfffff
    80005408:	01478a3b          	addw	s4,a5,s4
    8000540c:	1f897163          	bgeu	s2,s8,800055ee <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005410:	02091593          	slli	a1,s2,0x20
    80005414:	9181                	srli	a1,a1,0x20
    80005416:	95ea                	add	a1,a1,s10
    80005418:	855e                	mv	a0,s7
    8000541a:	ffffc097          	auipc	ra,0xffffc
    8000541e:	c54080e7          	jalr	-940(ra) # 8000106e <walkaddr>
    80005422:	862a                	mv	a2,a0
    if(pa == 0)
    80005424:	d955                	beqz	a0,800053d8 <exec+0xf0>
      n = PGSIZE;
    80005426:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005428:	fd9a70e3          	bgeu	s4,s9,800053e8 <exec+0x100>
      n = sz - i;
    8000542c:	8ad2                	mv	s5,s4
    8000542e:	bf6d                	j	800053e8 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005430:	4901                	li	s2,0
  iunlockput(ip);
    80005432:	8526                	mv	a0,s1
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	c18080e7          	jalr	-1000(ra) # 8000404c <iunlockput>
  end_op();
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	400080e7          	jalr	1024(ra) # 8000483c <end_op>
  p = myproc();
    80005444:	ffffc097          	auipc	ra,0xffffc
    80005448:	590080e7          	jalr	1424(ra) # 800019d4 <myproc>
    8000544c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000544e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005452:	6785                	lui	a5,0x1
    80005454:	17fd                	addi	a5,a5,-1
    80005456:	993e                	add	s2,s2,a5
    80005458:	757d                	lui	a0,0xfffff
    8000545a:	00a977b3          	and	a5,s2,a0
    8000545e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005462:	6609                	lui	a2,0x2
    80005464:	963e                	add	a2,a2,a5
    80005466:	85be                	mv	a1,a5
    80005468:	855e                	mv	a0,s7
    8000546a:	ffffc097          	auipc	ra,0xffffc
    8000546e:	fb8080e7          	jalr	-72(ra) # 80001422 <uvmalloc>
    80005472:	8b2a                	mv	s6,a0
  ip = 0;
    80005474:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005476:	12050c63          	beqz	a0,800055ae <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000547a:	75f9                	lui	a1,0xffffe
    8000547c:	95aa                	add	a1,a1,a0
    8000547e:	855e                	mv	a0,s7
    80005480:	ffffc097          	auipc	ra,0xffffc
    80005484:	1c0080e7          	jalr	448(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005488:	7c7d                	lui	s8,0xfffff
    8000548a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000548c:	e0043783          	ld	a5,-512(s0)
    80005490:	6388                	ld	a0,0(a5)
    80005492:	c535                	beqz	a0,800054fe <exec+0x216>
    80005494:	e9040993          	addi	s3,s0,-368
    80005498:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000549c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000549e:	ffffc097          	auipc	ra,0xffffc
    800054a2:	9c6080e7          	jalr	-1594(ra) # 80000e64 <strlen>
    800054a6:	2505                	addiw	a0,a0,1
    800054a8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054ac:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800054b0:	13896363          	bltu	s2,s8,800055d6 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054b4:	e0043d83          	ld	s11,-512(s0)
    800054b8:	000dba03          	ld	s4,0(s11)
    800054bc:	8552                	mv	a0,s4
    800054be:	ffffc097          	auipc	ra,0xffffc
    800054c2:	9a6080e7          	jalr	-1626(ra) # 80000e64 <strlen>
    800054c6:	0015069b          	addiw	a3,a0,1
    800054ca:	8652                	mv	a2,s4
    800054cc:	85ca                	mv	a1,s2
    800054ce:	855e                	mv	a0,s7
    800054d0:	ffffc097          	auipc	ra,0xffffc
    800054d4:	1a2080e7          	jalr	418(ra) # 80001672 <copyout>
    800054d8:	10054363          	bltz	a0,800055de <exec+0x2f6>
    ustack[argc] = sp;
    800054dc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054e0:	0485                	addi	s1,s1,1
    800054e2:	008d8793          	addi	a5,s11,8
    800054e6:	e0f43023          	sd	a5,-512(s0)
    800054ea:	008db503          	ld	a0,8(s11)
    800054ee:	c911                	beqz	a0,80005502 <exec+0x21a>
    if(argc >= MAXARG)
    800054f0:	09a1                	addi	s3,s3,8
    800054f2:	fb3c96e3          	bne	s9,s3,8000549e <exec+0x1b6>
  sz = sz1;
    800054f6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054fa:	4481                	li	s1,0
    800054fc:	a84d                	j	800055ae <exec+0x2c6>
  sp = sz;
    800054fe:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005500:	4481                	li	s1,0
  ustack[argc] = 0;
    80005502:	00349793          	slli	a5,s1,0x3
    80005506:	f9040713          	addi	a4,s0,-112
    8000550a:	97ba                	add	a5,a5,a4
    8000550c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005510:	00148693          	addi	a3,s1,1
    80005514:	068e                	slli	a3,a3,0x3
    80005516:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000551a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000551e:	01897663          	bgeu	s2,s8,8000552a <exec+0x242>
  sz = sz1;
    80005522:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005526:	4481                	li	s1,0
    80005528:	a059                	j	800055ae <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000552a:	e9040613          	addi	a2,s0,-368
    8000552e:	85ca                	mv	a1,s2
    80005530:	855e                	mv	a0,s7
    80005532:	ffffc097          	auipc	ra,0xffffc
    80005536:	140080e7          	jalr	320(ra) # 80001672 <copyout>
    8000553a:	0a054663          	bltz	a0,800055e6 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000553e:	058ab783          	ld	a5,88(s5)
    80005542:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005546:	df843783          	ld	a5,-520(s0)
    8000554a:	0007c703          	lbu	a4,0(a5)
    8000554e:	cf11                	beqz	a4,8000556a <exec+0x282>
    80005550:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005552:	02f00693          	li	a3,47
    80005556:	a039                	j	80005564 <exec+0x27c>
      last = s+1;
    80005558:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000555c:	0785                	addi	a5,a5,1
    8000555e:	fff7c703          	lbu	a4,-1(a5)
    80005562:	c701                	beqz	a4,8000556a <exec+0x282>
    if(*s == '/')
    80005564:	fed71ce3          	bne	a4,a3,8000555c <exec+0x274>
    80005568:	bfc5                	j	80005558 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000556a:	4641                	li	a2,16
    8000556c:	df843583          	ld	a1,-520(s0)
    80005570:	158a8513          	addi	a0,s5,344
    80005574:	ffffc097          	auipc	ra,0xffffc
    80005578:	8be080e7          	jalr	-1858(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000557c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005580:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005584:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005588:	058ab783          	ld	a5,88(s5)
    8000558c:	e6843703          	ld	a4,-408(s0)
    80005590:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005592:	058ab783          	ld	a5,88(s5)
    80005596:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000559a:	85ea                	mv	a1,s10
    8000559c:	ffffc097          	auipc	ra,0xffffc
    800055a0:	598080e7          	jalr	1432(ra) # 80001b34 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055a4:	0004851b          	sext.w	a0,s1
    800055a8:	bbe1                	j	80005380 <exec+0x98>
    800055aa:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055ae:	e0843583          	ld	a1,-504(s0)
    800055b2:	855e                	mv	a0,s7
    800055b4:	ffffc097          	auipc	ra,0xffffc
    800055b8:	580080e7          	jalr	1408(ra) # 80001b34 <proc_freepagetable>
  if(ip){
    800055bc:	da0498e3          	bnez	s1,8000536c <exec+0x84>
  return -1;
    800055c0:	557d                	li	a0,-1
    800055c2:	bb7d                	j	80005380 <exec+0x98>
    800055c4:	e1243423          	sd	s2,-504(s0)
    800055c8:	b7dd                	j	800055ae <exec+0x2c6>
    800055ca:	e1243423          	sd	s2,-504(s0)
    800055ce:	b7c5                	j	800055ae <exec+0x2c6>
    800055d0:	e1243423          	sd	s2,-504(s0)
    800055d4:	bfe9                	j	800055ae <exec+0x2c6>
  sz = sz1;
    800055d6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055da:	4481                	li	s1,0
    800055dc:	bfc9                	j	800055ae <exec+0x2c6>
  sz = sz1;
    800055de:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055e2:	4481                	li	s1,0
    800055e4:	b7e9                	j	800055ae <exec+0x2c6>
  sz = sz1;
    800055e6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055ea:	4481                	li	s1,0
    800055ec:	b7c9                	j	800055ae <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800055ee:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055f2:	2b05                	addiw	s6,s6,1
    800055f4:	0389899b          	addiw	s3,s3,56
    800055f8:	e8845783          	lhu	a5,-376(s0)
    800055fc:	e2fb5be3          	bge	s6,a5,80005432 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005600:	2981                	sext.w	s3,s3
    80005602:	03800713          	li	a4,56
    80005606:	86ce                	mv	a3,s3
    80005608:	e1840613          	addi	a2,s0,-488
    8000560c:	4581                	li	a1,0
    8000560e:	8526                	mv	a0,s1
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	a8e080e7          	jalr	-1394(ra) # 8000409e <readi>
    80005618:	03800793          	li	a5,56
    8000561c:	f8f517e3          	bne	a0,a5,800055aa <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005620:	e1842783          	lw	a5,-488(s0)
    80005624:	4705                	li	a4,1
    80005626:	fce796e3          	bne	a5,a4,800055f2 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000562a:	e4043603          	ld	a2,-448(s0)
    8000562e:	e3843783          	ld	a5,-456(s0)
    80005632:	f8f669e3          	bltu	a2,a5,800055c4 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005636:	e2843783          	ld	a5,-472(s0)
    8000563a:	963e                	add	a2,a2,a5
    8000563c:	f8f667e3          	bltu	a2,a5,800055ca <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005640:	85ca                	mv	a1,s2
    80005642:	855e                	mv	a0,s7
    80005644:	ffffc097          	auipc	ra,0xffffc
    80005648:	dde080e7          	jalr	-546(ra) # 80001422 <uvmalloc>
    8000564c:	e0a43423          	sd	a0,-504(s0)
    80005650:	d141                	beqz	a0,800055d0 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005652:	e2843d03          	ld	s10,-472(s0)
    80005656:	df043783          	ld	a5,-528(s0)
    8000565a:	00fd77b3          	and	a5,s10,a5
    8000565e:	fba1                	bnez	a5,800055ae <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005660:	e2042d83          	lw	s11,-480(s0)
    80005664:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005668:	f80c03e3          	beqz	s8,800055ee <exec+0x306>
    8000566c:	8a62                	mv	s4,s8
    8000566e:	4901                	li	s2,0
    80005670:	b345                	j	80005410 <exec+0x128>

0000000080005672 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005672:	7179                	addi	sp,sp,-48
    80005674:	f406                	sd	ra,40(sp)
    80005676:	f022                	sd	s0,32(sp)
    80005678:	ec26                	sd	s1,24(sp)
    8000567a:	e84a                	sd	s2,16(sp)
    8000567c:	1800                	addi	s0,sp,48
    8000567e:	892e                	mv	s2,a1
    80005680:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005682:	fdc40593          	addi	a1,s0,-36
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	9e2080e7          	jalr	-1566(ra) # 80003068 <argint>
    8000568e:	04054063          	bltz	a0,800056ce <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005692:	fdc42703          	lw	a4,-36(s0)
    80005696:	47bd                	li	a5,15
    80005698:	02e7ed63          	bltu	a5,a4,800056d2 <argfd+0x60>
    8000569c:	ffffc097          	auipc	ra,0xffffc
    800056a0:	338080e7          	jalr	824(ra) # 800019d4 <myproc>
    800056a4:	fdc42703          	lw	a4,-36(s0)
    800056a8:	01a70793          	addi	a5,a4,26
    800056ac:	078e                	slli	a5,a5,0x3
    800056ae:	953e                	add	a0,a0,a5
    800056b0:	611c                	ld	a5,0(a0)
    800056b2:	c395                	beqz	a5,800056d6 <argfd+0x64>
    return -1;
  if(pfd)
    800056b4:	00090463          	beqz	s2,800056bc <argfd+0x4a>
    *pfd = fd;
    800056b8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056bc:	4501                	li	a0,0
  if(pf)
    800056be:	c091                	beqz	s1,800056c2 <argfd+0x50>
    *pf = f;
    800056c0:	e09c                	sd	a5,0(s1)
}
    800056c2:	70a2                	ld	ra,40(sp)
    800056c4:	7402                	ld	s0,32(sp)
    800056c6:	64e2                	ld	s1,24(sp)
    800056c8:	6942                	ld	s2,16(sp)
    800056ca:	6145                	addi	sp,sp,48
    800056cc:	8082                	ret
    return -1;
    800056ce:	557d                	li	a0,-1
    800056d0:	bfcd                	j	800056c2 <argfd+0x50>
    return -1;
    800056d2:	557d                	li	a0,-1
    800056d4:	b7fd                	j	800056c2 <argfd+0x50>
    800056d6:	557d                	li	a0,-1
    800056d8:	b7ed                	j	800056c2 <argfd+0x50>

00000000800056da <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056da:	1101                	addi	sp,sp,-32
    800056dc:	ec06                	sd	ra,24(sp)
    800056de:	e822                	sd	s0,16(sp)
    800056e0:	e426                	sd	s1,8(sp)
    800056e2:	1000                	addi	s0,sp,32
    800056e4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056e6:	ffffc097          	auipc	ra,0xffffc
    800056ea:	2ee080e7          	jalr	750(ra) # 800019d4 <myproc>
    800056ee:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056f0:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80d0>
    800056f4:	4501                	li	a0,0
    800056f6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056f8:	6398                	ld	a4,0(a5)
    800056fa:	cb19                	beqz	a4,80005710 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056fc:	2505                	addiw	a0,a0,1
    800056fe:	07a1                	addi	a5,a5,8
    80005700:	fed51ce3          	bne	a0,a3,800056f8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005704:	557d                	li	a0,-1
}
    80005706:	60e2                	ld	ra,24(sp)
    80005708:	6442                	ld	s0,16(sp)
    8000570a:	64a2                	ld	s1,8(sp)
    8000570c:	6105                	addi	sp,sp,32
    8000570e:	8082                	ret
      p->ofile[fd] = f;
    80005710:	01a50793          	addi	a5,a0,26
    80005714:	078e                	slli	a5,a5,0x3
    80005716:	963e                	add	a2,a2,a5
    80005718:	e204                	sd	s1,0(a2)
      return fd;
    8000571a:	b7f5                	j	80005706 <fdalloc+0x2c>

000000008000571c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000571c:	715d                	addi	sp,sp,-80
    8000571e:	e486                	sd	ra,72(sp)
    80005720:	e0a2                	sd	s0,64(sp)
    80005722:	fc26                	sd	s1,56(sp)
    80005724:	f84a                	sd	s2,48(sp)
    80005726:	f44e                	sd	s3,40(sp)
    80005728:	f052                	sd	s4,32(sp)
    8000572a:	ec56                	sd	s5,24(sp)
    8000572c:	0880                	addi	s0,sp,80
    8000572e:	89ae                	mv	s3,a1
    80005730:	8ab2                	mv	s5,a2
    80005732:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005734:	fb040593          	addi	a1,s0,-80
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	e86080e7          	jalr	-378(ra) # 800045be <nameiparent>
    80005740:	892a                	mv	s2,a0
    80005742:	12050f63          	beqz	a0,80005880 <create+0x164>
    return 0;

  ilock(dp);
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	6a4080e7          	jalr	1700(ra) # 80003dea <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000574e:	4601                	li	a2,0
    80005750:	fb040593          	addi	a1,s0,-80
    80005754:	854a                	mv	a0,s2
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	b78080e7          	jalr	-1160(ra) # 800042ce <dirlookup>
    8000575e:	84aa                	mv	s1,a0
    80005760:	c921                	beqz	a0,800057b0 <create+0x94>
    iunlockput(dp);
    80005762:	854a                	mv	a0,s2
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	8e8080e7          	jalr	-1816(ra) # 8000404c <iunlockput>
    ilock(ip);
    8000576c:	8526                	mv	a0,s1
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	67c080e7          	jalr	1660(ra) # 80003dea <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005776:	2981                	sext.w	s3,s3
    80005778:	4789                	li	a5,2
    8000577a:	02f99463          	bne	s3,a5,800057a2 <create+0x86>
    8000577e:	0444d783          	lhu	a5,68(s1)
    80005782:	37f9                	addiw	a5,a5,-2
    80005784:	17c2                	slli	a5,a5,0x30
    80005786:	93c1                	srli	a5,a5,0x30
    80005788:	4705                	li	a4,1
    8000578a:	00f76c63          	bltu	a4,a5,800057a2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000578e:	8526                	mv	a0,s1
    80005790:	60a6                	ld	ra,72(sp)
    80005792:	6406                	ld	s0,64(sp)
    80005794:	74e2                	ld	s1,56(sp)
    80005796:	7942                	ld	s2,48(sp)
    80005798:	79a2                	ld	s3,40(sp)
    8000579a:	7a02                	ld	s4,32(sp)
    8000579c:	6ae2                	ld	s5,24(sp)
    8000579e:	6161                	addi	sp,sp,80
    800057a0:	8082                	ret
    iunlockput(ip);
    800057a2:	8526                	mv	a0,s1
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	8a8080e7          	jalr	-1880(ra) # 8000404c <iunlockput>
    return 0;
    800057ac:	4481                	li	s1,0
    800057ae:	b7c5                	j	8000578e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800057b0:	85ce                	mv	a1,s3
    800057b2:	00092503          	lw	a0,0(s2)
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	49c080e7          	jalr	1180(ra) # 80003c52 <ialloc>
    800057be:	84aa                	mv	s1,a0
    800057c0:	c529                	beqz	a0,8000580a <create+0xee>
  ilock(ip);
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	628080e7          	jalr	1576(ra) # 80003dea <ilock>
  ip->major = major;
    800057ca:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800057ce:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800057d2:	4785                	li	a5,1
    800057d4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	546080e7          	jalr	1350(ra) # 80003d20 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057e2:	2981                	sext.w	s3,s3
    800057e4:	4785                	li	a5,1
    800057e6:	02f98a63          	beq	s3,a5,8000581a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800057ea:	40d0                	lw	a2,4(s1)
    800057ec:	fb040593          	addi	a1,s0,-80
    800057f0:	854a                	mv	a0,s2
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	cec080e7          	jalr	-788(ra) # 800044de <dirlink>
    800057fa:	06054b63          	bltz	a0,80005870 <create+0x154>
  iunlockput(dp);
    800057fe:	854a                	mv	a0,s2
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	84c080e7          	jalr	-1972(ra) # 8000404c <iunlockput>
  return ip;
    80005808:	b759                	j	8000578e <create+0x72>
    panic("create: ialloc");
    8000580a:	00003517          	auipc	a0,0x3
    8000580e:	07650513          	addi	a0,a0,118 # 80008880 <syscalls+0x2b0>
    80005812:	ffffb097          	auipc	ra,0xffffb
    80005816:	d2c080e7          	jalr	-724(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000581a:	04a95783          	lhu	a5,74(s2)
    8000581e:	2785                	addiw	a5,a5,1
    80005820:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005824:	854a                	mv	a0,s2
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	4fa080e7          	jalr	1274(ra) # 80003d20 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000582e:	40d0                	lw	a2,4(s1)
    80005830:	00003597          	auipc	a1,0x3
    80005834:	06058593          	addi	a1,a1,96 # 80008890 <syscalls+0x2c0>
    80005838:	8526                	mv	a0,s1
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	ca4080e7          	jalr	-860(ra) # 800044de <dirlink>
    80005842:	00054f63          	bltz	a0,80005860 <create+0x144>
    80005846:	00492603          	lw	a2,4(s2)
    8000584a:	00003597          	auipc	a1,0x3
    8000584e:	04e58593          	addi	a1,a1,78 # 80008898 <syscalls+0x2c8>
    80005852:	8526                	mv	a0,s1
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	c8a080e7          	jalr	-886(ra) # 800044de <dirlink>
    8000585c:	f80557e3          	bgez	a0,800057ea <create+0xce>
      panic("create dots");
    80005860:	00003517          	auipc	a0,0x3
    80005864:	04050513          	addi	a0,a0,64 # 800088a0 <syscalls+0x2d0>
    80005868:	ffffb097          	auipc	ra,0xffffb
    8000586c:	cd6080e7          	jalr	-810(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005870:	00003517          	auipc	a0,0x3
    80005874:	04050513          	addi	a0,a0,64 # 800088b0 <syscalls+0x2e0>
    80005878:	ffffb097          	auipc	ra,0xffffb
    8000587c:	cc6080e7          	jalr	-826(ra) # 8000053e <panic>
    return 0;
    80005880:	84aa                	mv	s1,a0
    80005882:	b731                	j	8000578e <create+0x72>

0000000080005884 <sys_dup>:
{
    80005884:	7179                	addi	sp,sp,-48
    80005886:	f406                	sd	ra,40(sp)
    80005888:	f022                	sd	s0,32(sp)
    8000588a:	ec26                	sd	s1,24(sp)
    8000588c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000588e:	fd840613          	addi	a2,s0,-40
    80005892:	4581                	li	a1,0
    80005894:	4501                	li	a0,0
    80005896:	00000097          	auipc	ra,0x0
    8000589a:	ddc080e7          	jalr	-548(ra) # 80005672 <argfd>
    return -1;
    8000589e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058a0:	02054363          	bltz	a0,800058c6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800058a4:	fd843503          	ld	a0,-40(s0)
    800058a8:	00000097          	auipc	ra,0x0
    800058ac:	e32080e7          	jalr	-462(ra) # 800056da <fdalloc>
    800058b0:	84aa                	mv	s1,a0
    return -1;
    800058b2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058b4:	00054963          	bltz	a0,800058c6 <sys_dup+0x42>
  filedup(f);
    800058b8:	fd843503          	ld	a0,-40(s0)
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	37a080e7          	jalr	890(ra) # 80004c36 <filedup>
  return fd;
    800058c4:	87a6                	mv	a5,s1
}
    800058c6:	853e                	mv	a0,a5
    800058c8:	70a2                	ld	ra,40(sp)
    800058ca:	7402                	ld	s0,32(sp)
    800058cc:	64e2                	ld	s1,24(sp)
    800058ce:	6145                	addi	sp,sp,48
    800058d0:	8082                	ret

00000000800058d2 <sys_read>:
{
    800058d2:	7179                	addi	sp,sp,-48
    800058d4:	f406                	sd	ra,40(sp)
    800058d6:	f022                	sd	s0,32(sp)
    800058d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058da:	fe840613          	addi	a2,s0,-24
    800058de:	4581                	li	a1,0
    800058e0:	4501                	li	a0,0
    800058e2:	00000097          	auipc	ra,0x0
    800058e6:	d90080e7          	jalr	-624(ra) # 80005672 <argfd>
    return -1;
    800058ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058ec:	04054163          	bltz	a0,8000592e <sys_read+0x5c>
    800058f0:	fe440593          	addi	a1,s0,-28
    800058f4:	4509                	li	a0,2
    800058f6:	ffffd097          	auipc	ra,0xffffd
    800058fa:	772080e7          	jalr	1906(ra) # 80003068 <argint>
    return -1;
    800058fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005900:	02054763          	bltz	a0,8000592e <sys_read+0x5c>
    80005904:	fd840593          	addi	a1,s0,-40
    80005908:	4505                	li	a0,1
    8000590a:	ffffd097          	auipc	ra,0xffffd
    8000590e:	780080e7          	jalr	1920(ra) # 8000308a <argaddr>
    return -1;
    80005912:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005914:	00054d63          	bltz	a0,8000592e <sys_read+0x5c>
  return fileread(f, p, n);
    80005918:	fe442603          	lw	a2,-28(s0)
    8000591c:	fd843583          	ld	a1,-40(s0)
    80005920:	fe843503          	ld	a0,-24(s0)
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	49e080e7          	jalr	1182(ra) # 80004dc2 <fileread>
    8000592c:	87aa                	mv	a5,a0
}
    8000592e:	853e                	mv	a0,a5
    80005930:	70a2                	ld	ra,40(sp)
    80005932:	7402                	ld	s0,32(sp)
    80005934:	6145                	addi	sp,sp,48
    80005936:	8082                	ret

0000000080005938 <sys_write>:
{
    80005938:	7179                	addi	sp,sp,-48
    8000593a:	f406                	sd	ra,40(sp)
    8000593c:	f022                	sd	s0,32(sp)
    8000593e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005940:	fe840613          	addi	a2,s0,-24
    80005944:	4581                	li	a1,0
    80005946:	4501                	li	a0,0
    80005948:	00000097          	auipc	ra,0x0
    8000594c:	d2a080e7          	jalr	-726(ra) # 80005672 <argfd>
    return -1;
    80005950:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005952:	04054163          	bltz	a0,80005994 <sys_write+0x5c>
    80005956:	fe440593          	addi	a1,s0,-28
    8000595a:	4509                	li	a0,2
    8000595c:	ffffd097          	auipc	ra,0xffffd
    80005960:	70c080e7          	jalr	1804(ra) # 80003068 <argint>
    return -1;
    80005964:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005966:	02054763          	bltz	a0,80005994 <sys_write+0x5c>
    8000596a:	fd840593          	addi	a1,s0,-40
    8000596e:	4505                	li	a0,1
    80005970:	ffffd097          	auipc	ra,0xffffd
    80005974:	71a080e7          	jalr	1818(ra) # 8000308a <argaddr>
    return -1;
    80005978:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000597a:	00054d63          	bltz	a0,80005994 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000597e:	fe442603          	lw	a2,-28(s0)
    80005982:	fd843583          	ld	a1,-40(s0)
    80005986:	fe843503          	ld	a0,-24(s0)
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	4fa080e7          	jalr	1274(ra) # 80004e84 <filewrite>
    80005992:	87aa                	mv	a5,a0
}
    80005994:	853e                	mv	a0,a5
    80005996:	70a2                	ld	ra,40(sp)
    80005998:	7402                	ld	s0,32(sp)
    8000599a:	6145                	addi	sp,sp,48
    8000599c:	8082                	ret

000000008000599e <sys_close>:
{
    8000599e:	1101                	addi	sp,sp,-32
    800059a0:	ec06                	sd	ra,24(sp)
    800059a2:	e822                	sd	s0,16(sp)
    800059a4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059a6:	fe040613          	addi	a2,s0,-32
    800059aa:	fec40593          	addi	a1,s0,-20
    800059ae:	4501                	li	a0,0
    800059b0:	00000097          	auipc	ra,0x0
    800059b4:	cc2080e7          	jalr	-830(ra) # 80005672 <argfd>
    return -1;
    800059b8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059ba:	02054463          	bltz	a0,800059e2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059be:	ffffc097          	auipc	ra,0xffffc
    800059c2:	016080e7          	jalr	22(ra) # 800019d4 <myproc>
    800059c6:	fec42783          	lw	a5,-20(s0)
    800059ca:	07e9                	addi	a5,a5,26
    800059cc:	078e                	slli	a5,a5,0x3
    800059ce:	97aa                	add	a5,a5,a0
    800059d0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800059d4:	fe043503          	ld	a0,-32(s0)
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	2b0080e7          	jalr	688(ra) # 80004c88 <fileclose>
  return 0;
    800059e0:	4781                	li	a5,0
}
    800059e2:	853e                	mv	a0,a5
    800059e4:	60e2                	ld	ra,24(sp)
    800059e6:	6442                	ld	s0,16(sp)
    800059e8:	6105                	addi	sp,sp,32
    800059ea:	8082                	ret

00000000800059ec <sys_fstat>:
{
    800059ec:	1101                	addi	sp,sp,-32
    800059ee:	ec06                	sd	ra,24(sp)
    800059f0:	e822                	sd	s0,16(sp)
    800059f2:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059f4:	fe840613          	addi	a2,s0,-24
    800059f8:	4581                	li	a1,0
    800059fa:	4501                	li	a0,0
    800059fc:	00000097          	auipc	ra,0x0
    80005a00:	c76080e7          	jalr	-906(ra) # 80005672 <argfd>
    return -1;
    80005a04:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a06:	02054563          	bltz	a0,80005a30 <sys_fstat+0x44>
    80005a0a:	fe040593          	addi	a1,s0,-32
    80005a0e:	4505                	li	a0,1
    80005a10:	ffffd097          	auipc	ra,0xffffd
    80005a14:	67a080e7          	jalr	1658(ra) # 8000308a <argaddr>
    return -1;
    80005a18:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a1a:	00054b63          	bltz	a0,80005a30 <sys_fstat+0x44>
  return filestat(f, st);
    80005a1e:	fe043583          	ld	a1,-32(s0)
    80005a22:	fe843503          	ld	a0,-24(s0)
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	32a080e7          	jalr	810(ra) # 80004d50 <filestat>
    80005a2e:	87aa                	mv	a5,a0
}
    80005a30:	853e                	mv	a0,a5
    80005a32:	60e2                	ld	ra,24(sp)
    80005a34:	6442                	ld	s0,16(sp)
    80005a36:	6105                	addi	sp,sp,32
    80005a38:	8082                	ret

0000000080005a3a <sys_link>:
{
    80005a3a:	7169                	addi	sp,sp,-304
    80005a3c:	f606                	sd	ra,296(sp)
    80005a3e:	f222                	sd	s0,288(sp)
    80005a40:	ee26                	sd	s1,280(sp)
    80005a42:	ea4a                	sd	s2,272(sp)
    80005a44:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a46:	08000613          	li	a2,128
    80005a4a:	ed040593          	addi	a1,s0,-304
    80005a4e:	4501                	li	a0,0
    80005a50:	ffffd097          	auipc	ra,0xffffd
    80005a54:	65c080e7          	jalr	1628(ra) # 800030ac <argstr>
    return -1;
    80005a58:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a5a:	10054e63          	bltz	a0,80005b76 <sys_link+0x13c>
    80005a5e:	08000613          	li	a2,128
    80005a62:	f5040593          	addi	a1,s0,-176
    80005a66:	4505                	li	a0,1
    80005a68:	ffffd097          	auipc	ra,0xffffd
    80005a6c:	644080e7          	jalr	1604(ra) # 800030ac <argstr>
    return -1;
    80005a70:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a72:	10054263          	bltz	a0,80005b76 <sys_link+0x13c>
  begin_op();
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	d46080e7          	jalr	-698(ra) # 800047bc <begin_op>
  if((ip = namei(old)) == 0){
    80005a7e:	ed040513          	addi	a0,s0,-304
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	b1e080e7          	jalr	-1250(ra) # 800045a0 <namei>
    80005a8a:	84aa                	mv	s1,a0
    80005a8c:	c551                	beqz	a0,80005b18 <sys_link+0xde>
  ilock(ip);
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	35c080e7          	jalr	860(ra) # 80003dea <ilock>
  if(ip->type == T_DIR){
    80005a96:	04449703          	lh	a4,68(s1)
    80005a9a:	4785                	li	a5,1
    80005a9c:	08f70463          	beq	a4,a5,80005b24 <sys_link+0xea>
  ip->nlink++;
    80005aa0:	04a4d783          	lhu	a5,74(s1)
    80005aa4:	2785                	addiw	a5,a5,1
    80005aa6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005aaa:	8526                	mv	a0,s1
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	274080e7          	jalr	628(ra) # 80003d20 <iupdate>
  iunlock(ip);
    80005ab4:	8526                	mv	a0,s1
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	3f6080e7          	jalr	1014(ra) # 80003eac <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005abe:	fd040593          	addi	a1,s0,-48
    80005ac2:	f5040513          	addi	a0,s0,-176
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	af8080e7          	jalr	-1288(ra) # 800045be <nameiparent>
    80005ace:	892a                	mv	s2,a0
    80005ad0:	c935                	beqz	a0,80005b44 <sys_link+0x10a>
  ilock(dp);
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	318080e7          	jalr	792(ra) # 80003dea <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ada:	00092703          	lw	a4,0(s2)
    80005ade:	409c                	lw	a5,0(s1)
    80005ae0:	04f71d63          	bne	a4,a5,80005b3a <sys_link+0x100>
    80005ae4:	40d0                	lw	a2,4(s1)
    80005ae6:	fd040593          	addi	a1,s0,-48
    80005aea:	854a                	mv	a0,s2
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	9f2080e7          	jalr	-1550(ra) # 800044de <dirlink>
    80005af4:	04054363          	bltz	a0,80005b3a <sys_link+0x100>
  iunlockput(dp);
    80005af8:	854a                	mv	a0,s2
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	552080e7          	jalr	1362(ra) # 8000404c <iunlockput>
  iput(ip);
    80005b02:	8526                	mv	a0,s1
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	4a0080e7          	jalr	1184(ra) # 80003fa4 <iput>
  end_op();
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	d30080e7          	jalr	-720(ra) # 8000483c <end_op>
  return 0;
    80005b14:	4781                	li	a5,0
    80005b16:	a085                	j	80005b76 <sys_link+0x13c>
    end_op();
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	d24080e7          	jalr	-732(ra) # 8000483c <end_op>
    return -1;
    80005b20:	57fd                	li	a5,-1
    80005b22:	a891                	j	80005b76 <sys_link+0x13c>
    iunlockput(ip);
    80005b24:	8526                	mv	a0,s1
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	526080e7          	jalr	1318(ra) # 8000404c <iunlockput>
    end_op();
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	d0e080e7          	jalr	-754(ra) # 8000483c <end_op>
    return -1;
    80005b36:	57fd                	li	a5,-1
    80005b38:	a83d                	j	80005b76 <sys_link+0x13c>
    iunlockput(dp);
    80005b3a:	854a                	mv	a0,s2
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	510080e7          	jalr	1296(ra) # 8000404c <iunlockput>
  ilock(ip);
    80005b44:	8526                	mv	a0,s1
    80005b46:	ffffe097          	auipc	ra,0xffffe
    80005b4a:	2a4080e7          	jalr	676(ra) # 80003dea <ilock>
  ip->nlink--;
    80005b4e:	04a4d783          	lhu	a5,74(s1)
    80005b52:	37fd                	addiw	a5,a5,-1
    80005b54:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b58:	8526                	mv	a0,s1
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	1c6080e7          	jalr	454(ra) # 80003d20 <iupdate>
  iunlockput(ip);
    80005b62:	8526                	mv	a0,s1
    80005b64:	ffffe097          	auipc	ra,0xffffe
    80005b68:	4e8080e7          	jalr	1256(ra) # 8000404c <iunlockput>
  end_op();
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	cd0080e7          	jalr	-816(ra) # 8000483c <end_op>
  return -1;
    80005b74:	57fd                	li	a5,-1
}
    80005b76:	853e                	mv	a0,a5
    80005b78:	70b2                	ld	ra,296(sp)
    80005b7a:	7412                	ld	s0,288(sp)
    80005b7c:	64f2                	ld	s1,280(sp)
    80005b7e:	6952                	ld	s2,272(sp)
    80005b80:	6155                	addi	sp,sp,304
    80005b82:	8082                	ret

0000000080005b84 <sys_unlink>:
{
    80005b84:	7151                	addi	sp,sp,-240
    80005b86:	f586                	sd	ra,232(sp)
    80005b88:	f1a2                	sd	s0,224(sp)
    80005b8a:	eda6                	sd	s1,216(sp)
    80005b8c:	e9ca                	sd	s2,208(sp)
    80005b8e:	e5ce                	sd	s3,200(sp)
    80005b90:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b92:	08000613          	li	a2,128
    80005b96:	f3040593          	addi	a1,s0,-208
    80005b9a:	4501                	li	a0,0
    80005b9c:	ffffd097          	auipc	ra,0xffffd
    80005ba0:	510080e7          	jalr	1296(ra) # 800030ac <argstr>
    80005ba4:	18054163          	bltz	a0,80005d26 <sys_unlink+0x1a2>
  begin_op();
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	c14080e7          	jalr	-1004(ra) # 800047bc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bb0:	fb040593          	addi	a1,s0,-80
    80005bb4:	f3040513          	addi	a0,s0,-208
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	a06080e7          	jalr	-1530(ra) # 800045be <nameiparent>
    80005bc0:	84aa                	mv	s1,a0
    80005bc2:	c979                	beqz	a0,80005c98 <sys_unlink+0x114>
  ilock(dp);
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	226080e7          	jalr	550(ra) # 80003dea <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bcc:	00003597          	auipc	a1,0x3
    80005bd0:	cc458593          	addi	a1,a1,-828 # 80008890 <syscalls+0x2c0>
    80005bd4:	fb040513          	addi	a0,s0,-80
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	6dc080e7          	jalr	1756(ra) # 800042b4 <namecmp>
    80005be0:	14050a63          	beqz	a0,80005d34 <sys_unlink+0x1b0>
    80005be4:	00003597          	auipc	a1,0x3
    80005be8:	cb458593          	addi	a1,a1,-844 # 80008898 <syscalls+0x2c8>
    80005bec:	fb040513          	addi	a0,s0,-80
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	6c4080e7          	jalr	1732(ra) # 800042b4 <namecmp>
    80005bf8:	12050e63          	beqz	a0,80005d34 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bfc:	f2c40613          	addi	a2,s0,-212
    80005c00:	fb040593          	addi	a1,s0,-80
    80005c04:	8526                	mv	a0,s1
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	6c8080e7          	jalr	1736(ra) # 800042ce <dirlookup>
    80005c0e:	892a                	mv	s2,a0
    80005c10:	12050263          	beqz	a0,80005d34 <sys_unlink+0x1b0>
  ilock(ip);
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	1d6080e7          	jalr	470(ra) # 80003dea <ilock>
  if(ip->nlink < 1)
    80005c1c:	04a91783          	lh	a5,74(s2)
    80005c20:	08f05263          	blez	a5,80005ca4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c24:	04491703          	lh	a4,68(s2)
    80005c28:	4785                	li	a5,1
    80005c2a:	08f70563          	beq	a4,a5,80005cb4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c2e:	4641                	li	a2,16
    80005c30:	4581                	li	a1,0
    80005c32:	fc040513          	addi	a0,s0,-64
    80005c36:	ffffb097          	auipc	ra,0xffffb
    80005c3a:	0aa080e7          	jalr	170(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c3e:	4741                	li	a4,16
    80005c40:	f2c42683          	lw	a3,-212(s0)
    80005c44:	fc040613          	addi	a2,s0,-64
    80005c48:	4581                	li	a1,0
    80005c4a:	8526                	mv	a0,s1
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	54a080e7          	jalr	1354(ra) # 80004196 <writei>
    80005c54:	47c1                	li	a5,16
    80005c56:	0af51563          	bne	a0,a5,80005d00 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c5a:	04491703          	lh	a4,68(s2)
    80005c5e:	4785                	li	a5,1
    80005c60:	0af70863          	beq	a4,a5,80005d10 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c64:	8526                	mv	a0,s1
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	3e6080e7          	jalr	998(ra) # 8000404c <iunlockput>
  ip->nlink--;
    80005c6e:	04a95783          	lhu	a5,74(s2)
    80005c72:	37fd                	addiw	a5,a5,-1
    80005c74:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c78:	854a                	mv	a0,s2
    80005c7a:	ffffe097          	auipc	ra,0xffffe
    80005c7e:	0a6080e7          	jalr	166(ra) # 80003d20 <iupdate>
  iunlockput(ip);
    80005c82:	854a                	mv	a0,s2
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	3c8080e7          	jalr	968(ra) # 8000404c <iunlockput>
  end_op();
    80005c8c:	fffff097          	auipc	ra,0xfffff
    80005c90:	bb0080e7          	jalr	-1104(ra) # 8000483c <end_op>
  return 0;
    80005c94:	4501                	li	a0,0
    80005c96:	a84d                	j	80005d48 <sys_unlink+0x1c4>
    end_op();
    80005c98:	fffff097          	auipc	ra,0xfffff
    80005c9c:	ba4080e7          	jalr	-1116(ra) # 8000483c <end_op>
    return -1;
    80005ca0:	557d                	li	a0,-1
    80005ca2:	a05d                	j	80005d48 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ca4:	00003517          	auipc	a0,0x3
    80005ca8:	c1c50513          	addi	a0,a0,-996 # 800088c0 <syscalls+0x2f0>
    80005cac:	ffffb097          	auipc	ra,0xffffb
    80005cb0:	892080e7          	jalr	-1902(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cb4:	04c92703          	lw	a4,76(s2)
    80005cb8:	02000793          	li	a5,32
    80005cbc:	f6e7f9e3          	bgeu	a5,a4,80005c2e <sys_unlink+0xaa>
    80005cc0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cc4:	4741                	li	a4,16
    80005cc6:	86ce                	mv	a3,s3
    80005cc8:	f1840613          	addi	a2,s0,-232
    80005ccc:	4581                	li	a1,0
    80005cce:	854a                	mv	a0,s2
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	3ce080e7          	jalr	974(ra) # 8000409e <readi>
    80005cd8:	47c1                	li	a5,16
    80005cda:	00f51b63          	bne	a0,a5,80005cf0 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005cde:	f1845783          	lhu	a5,-232(s0)
    80005ce2:	e7a1                	bnez	a5,80005d2a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ce4:	29c1                	addiw	s3,s3,16
    80005ce6:	04c92783          	lw	a5,76(s2)
    80005cea:	fcf9ede3          	bltu	s3,a5,80005cc4 <sys_unlink+0x140>
    80005cee:	b781                	j	80005c2e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005cf0:	00003517          	auipc	a0,0x3
    80005cf4:	be850513          	addi	a0,a0,-1048 # 800088d8 <syscalls+0x308>
    80005cf8:	ffffb097          	auipc	ra,0xffffb
    80005cfc:	846080e7          	jalr	-1978(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005d00:	00003517          	auipc	a0,0x3
    80005d04:	bf050513          	addi	a0,a0,-1040 # 800088f0 <syscalls+0x320>
    80005d08:	ffffb097          	auipc	ra,0xffffb
    80005d0c:	836080e7          	jalr	-1994(ra) # 8000053e <panic>
    dp->nlink--;
    80005d10:	04a4d783          	lhu	a5,74(s1)
    80005d14:	37fd                	addiw	a5,a5,-1
    80005d16:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d1a:	8526                	mv	a0,s1
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	004080e7          	jalr	4(ra) # 80003d20 <iupdate>
    80005d24:	b781                	j	80005c64 <sys_unlink+0xe0>
    return -1;
    80005d26:	557d                	li	a0,-1
    80005d28:	a005                	j	80005d48 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d2a:	854a                	mv	a0,s2
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	320080e7          	jalr	800(ra) # 8000404c <iunlockput>
  iunlockput(dp);
    80005d34:	8526                	mv	a0,s1
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	316080e7          	jalr	790(ra) # 8000404c <iunlockput>
  end_op();
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	afe080e7          	jalr	-1282(ra) # 8000483c <end_op>
  return -1;
    80005d46:	557d                	li	a0,-1
}
    80005d48:	70ae                	ld	ra,232(sp)
    80005d4a:	740e                	ld	s0,224(sp)
    80005d4c:	64ee                	ld	s1,216(sp)
    80005d4e:	694e                	ld	s2,208(sp)
    80005d50:	69ae                	ld	s3,200(sp)
    80005d52:	616d                	addi	sp,sp,240
    80005d54:	8082                	ret

0000000080005d56 <sys_open>:

uint64
sys_open(void)
{
    80005d56:	7131                	addi	sp,sp,-192
    80005d58:	fd06                	sd	ra,184(sp)
    80005d5a:	f922                	sd	s0,176(sp)
    80005d5c:	f526                	sd	s1,168(sp)
    80005d5e:	f14a                	sd	s2,160(sp)
    80005d60:	ed4e                	sd	s3,152(sp)
    80005d62:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d64:	08000613          	li	a2,128
    80005d68:	f5040593          	addi	a1,s0,-176
    80005d6c:	4501                	li	a0,0
    80005d6e:	ffffd097          	auipc	ra,0xffffd
    80005d72:	33e080e7          	jalr	830(ra) # 800030ac <argstr>
    return -1;
    80005d76:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d78:	0c054163          	bltz	a0,80005e3a <sys_open+0xe4>
    80005d7c:	f4c40593          	addi	a1,s0,-180
    80005d80:	4505                	li	a0,1
    80005d82:	ffffd097          	auipc	ra,0xffffd
    80005d86:	2e6080e7          	jalr	742(ra) # 80003068 <argint>
    80005d8a:	0a054863          	bltz	a0,80005e3a <sys_open+0xe4>

  begin_op();
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	a2e080e7          	jalr	-1490(ra) # 800047bc <begin_op>

  if(omode & O_CREATE){
    80005d96:	f4c42783          	lw	a5,-180(s0)
    80005d9a:	2007f793          	andi	a5,a5,512
    80005d9e:	cbdd                	beqz	a5,80005e54 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005da0:	4681                	li	a3,0
    80005da2:	4601                	li	a2,0
    80005da4:	4589                	li	a1,2
    80005da6:	f5040513          	addi	a0,s0,-176
    80005daa:	00000097          	auipc	ra,0x0
    80005dae:	972080e7          	jalr	-1678(ra) # 8000571c <create>
    80005db2:	892a                	mv	s2,a0
    if(ip == 0){
    80005db4:	c959                	beqz	a0,80005e4a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005db6:	04491703          	lh	a4,68(s2)
    80005dba:	478d                	li	a5,3
    80005dbc:	00f71763          	bne	a4,a5,80005dca <sys_open+0x74>
    80005dc0:	04695703          	lhu	a4,70(s2)
    80005dc4:	47a5                	li	a5,9
    80005dc6:	0ce7ec63          	bltu	a5,a4,80005e9e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	e02080e7          	jalr	-510(ra) # 80004bcc <filealloc>
    80005dd2:	89aa                	mv	s3,a0
    80005dd4:	10050263          	beqz	a0,80005ed8 <sys_open+0x182>
    80005dd8:	00000097          	auipc	ra,0x0
    80005ddc:	902080e7          	jalr	-1790(ra) # 800056da <fdalloc>
    80005de0:	84aa                	mv	s1,a0
    80005de2:	0e054663          	bltz	a0,80005ece <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005de6:	04491703          	lh	a4,68(s2)
    80005dea:	478d                	li	a5,3
    80005dec:	0cf70463          	beq	a4,a5,80005eb4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005df0:	4789                	li	a5,2
    80005df2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005df6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005dfa:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005dfe:	f4c42783          	lw	a5,-180(s0)
    80005e02:	0017c713          	xori	a4,a5,1
    80005e06:	8b05                	andi	a4,a4,1
    80005e08:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e0c:	0037f713          	andi	a4,a5,3
    80005e10:	00e03733          	snez	a4,a4
    80005e14:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e18:	4007f793          	andi	a5,a5,1024
    80005e1c:	c791                	beqz	a5,80005e28 <sys_open+0xd2>
    80005e1e:	04491703          	lh	a4,68(s2)
    80005e22:	4789                	li	a5,2
    80005e24:	08f70f63          	beq	a4,a5,80005ec2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e28:	854a                	mv	a0,s2
    80005e2a:	ffffe097          	auipc	ra,0xffffe
    80005e2e:	082080e7          	jalr	130(ra) # 80003eac <iunlock>
  end_op();
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	a0a080e7          	jalr	-1526(ra) # 8000483c <end_op>

  return fd;
}
    80005e3a:	8526                	mv	a0,s1
    80005e3c:	70ea                	ld	ra,184(sp)
    80005e3e:	744a                	ld	s0,176(sp)
    80005e40:	74aa                	ld	s1,168(sp)
    80005e42:	790a                	ld	s2,160(sp)
    80005e44:	69ea                	ld	s3,152(sp)
    80005e46:	6129                	addi	sp,sp,192
    80005e48:	8082                	ret
      end_op();
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	9f2080e7          	jalr	-1550(ra) # 8000483c <end_op>
      return -1;
    80005e52:	b7e5                	j	80005e3a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e54:	f5040513          	addi	a0,s0,-176
    80005e58:	ffffe097          	auipc	ra,0xffffe
    80005e5c:	748080e7          	jalr	1864(ra) # 800045a0 <namei>
    80005e60:	892a                	mv	s2,a0
    80005e62:	c905                	beqz	a0,80005e92 <sys_open+0x13c>
    ilock(ip);
    80005e64:	ffffe097          	auipc	ra,0xffffe
    80005e68:	f86080e7          	jalr	-122(ra) # 80003dea <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e6c:	04491703          	lh	a4,68(s2)
    80005e70:	4785                	li	a5,1
    80005e72:	f4f712e3          	bne	a4,a5,80005db6 <sys_open+0x60>
    80005e76:	f4c42783          	lw	a5,-180(s0)
    80005e7a:	dba1                	beqz	a5,80005dca <sys_open+0x74>
      iunlockput(ip);
    80005e7c:	854a                	mv	a0,s2
    80005e7e:	ffffe097          	auipc	ra,0xffffe
    80005e82:	1ce080e7          	jalr	462(ra) # 8000404c <iunlockput>
      end_op();
    80005e86:	fffff097          	auipc	ra,0xfffff
    80005e8a:	9b6080e7          	jalr	-1610(ra) # 8000483c <end_op>
      return -1;
    80005e8e:	54fd                	li	s1,-1
    80005e90:	b76d                	j	80005e3a <sys_open+0xe4>
      end_op();
    80005e92:	fffff097          	auipc	ra,0xfffff
    80005e96:	9aa080e7          	jalr	-1622(ra) # 8000483c <end_op>
      return -1;
    80005e9a:	54fd                	li	s1,-1
    80005e9c:	bf79                	j	80005e3a <sys_open+0xe4>
    iunlockput(ip);
    80005e9e:	854a                	mv	a0,s2
    80005ea0:	ffffe097          	auipc	ra,0xffffe
    80005ea4:	1ac080e7          	jalr	428(ra) # 8000404c <iunlockput>
    end_op();
    80005ea8:	fffff097          	auipc	ra,0xfffff
    80005eac:	994080e7          	jalr	-1644(ra) # 8000483c <end_op>
    return -1;
    80005eb0:	54fd                	li	s1,-1
    80005eb2:	b761                	j	80005e3a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005eb4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005eb8:	04691783          	lh	a5,70(s2)
    80005ebc:	02f99223          	sh	a5,36(s3)
    80005ec0:	bf2d                	j	80005dfa <sys_open+0xa4>
    itrunc(ip);
    80005ec2:	854a                	mv	a0,s2
    80005ec4:	ffffe097          	auipc	ra,0xffffe
    80005ec8:	034080e7          	jalr	52(ra) # 80003ef8 <itrunc>
    80005ecc:	bfb1                	j	80005e28 <sys_open+0xd2>
      fileclose(f);
    80005ece:	854e                	mv	a0,s3
    80005ed0:	fffff097          	auipc	ra,0xfffff
    80005ed4:	db8080e7          	jalr	-584(ra) # 80004c88 <fileclose>
    iunlockput(ip);
    80005ed8:	854a                	mv	a0,s2
    80005eda:	ffffe097          	auipc	ra,0xffffe
    80005ede:	172080e7          	jalr	370(ra) # 8000404c <iunlockput>
    end_op();
    80005ee2:	fffff097          	auipc	ra,0xfffff
    80005ee6:	95a080e7          	jalr	-1702(ra) # 8000483c <end_op>
    return -1;
    80005eea:	54fd                	li	s1,-1
    80005eec:	b7b9                	j	80005e3a <sys_open+0xe4>

0000000080005eee <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005eee:	7175                	addi	sp,sp,-144
    80005ef0:	e506                	sd	ra,136(sp)
    80005ef2:	e122                	sd	s0,128(sp)
    80005ef4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ef6:	fffff097          	auipc	ra,0xfffff
    80005efa:	8c6080e7          	jalr	-1850(ra) # 800047bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005efe:	08000613          	li	a2,128
    80005f02:	f7040593          	addi	a1,s0,-144
    80005f06:	4501                	li	a0,0
    80005f08:	ffffd097          	auipc	ra,0xffffd
    80005f0c:	1a4080e7          	jalr	420(ra) # 800030ac <argstr>
    80005f10:	02054963          	bltz	a0,80005f42 <sys_mkdir+0x54>
    80005f14:	4681                	li	a3,0
    80005f16:	4601                	li	a2,0
    80005f18:	4585                	li	a1,1
    80005f1a:	f7040513          	addi	a0,s0,-144
    80005f1e:	fffff097          	auipc	ra,0xfffff
    80005f22:	7fe080e7          	jalr	2046(ra) # 8000571c <create>
    80005f26:	cd11                	beqz	a0,80005f42 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f28:	ffffe097          	auipc	ra,0xffffe
    80005f2c:	124080e7          	jalr	292(ra) # 8000404c <iunlockput>
  end_op();
    80005f30:	fffff097          	auipc	ra,0xfffff
    80005f34:	90c080e7          	jalr	-1780(ra) # 8000483c <end_op>
  return 0;
    80005f38:	4501                	li	a0,0
}
    80005f3a:	60aa                	ld	ra,136(sp)
    80005f3c:	640a                	ld	s0,128(sp)
    80005f3e:	6149                	addi	sp,sp,144
    80005f40:	8082                	ret
    end_op();
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	8fa080e7          	jalr	-1798(ra) # 8000483c <end_op>
    return -1;
    80005f4a:	557d                	li	a0,-1
    80005f4c:	b7fd                	j	80005f3a <sys_mkdir+0x4c>

0000000080005f4e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f4e:	7135                	addi	sp,sp,-160
    80005f50:	ed06                	sd	ra,152(sp)
    80005f52:	e922                	sd	s0,144(sp)
    80005f54:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f56:	fffff097          	auipc	ra,0xfffff
    80005f5a:	866080e7          	jalr	-1946(ra) # 800047bc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f5e:	08000613          	li	a2,128
    80005f62:	f7040593          	addi	a1,s0,-144
    80005f66:	4501                	li	a0,0
    80005f68:	ffffd097          	auipc	ra,0xffffd
    80005f6c:	144080e7          	jalr	324(ra) # 800030ac <argstr>
    80005f70:	04054a63          	bltz	a0,80005fc4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005f74:	f6c40593          	addi	a1,s0,-148
    80005f78:	4505                	li	a0,1
    80005f7a:	ffffd097          	auipc	ra,0xffffd
    80005f7e:	0ee080e7          	jalr	238(ra) # 80003068 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f82:	04054163          	bltz	a0,80005fc4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005f86:	f6840593          	addi	a1,s0,-152
    80005f8a:	4509                	li	a0,2
    80005f8c:	ffffd097          	auipc	ra,0xffffd
    80005f90:	0dc080e7          	jalr	220(ra) # 80003068 <argint>
     argint(1, &major) < 0 ||
    80005f94:	02054863          	bltz	a0,80005fc4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f98:	f6841683          	lh	a3,-152(s0)
    80005f9c:	f6c41603          	lh	a2,-148(s0)
    80005fa0:	458d                	li	a1,3
    80005fa2:	f7040513          	addi	a0,s0,-144
    80005fa6:	fffff097          	auipc	ra,0xfffff
    80005faa:	776080e7          	jalr	1910(ra) # 8000571c <create>
     argint(2, &minor) < 0 ||
    80005fae:	c919                	beqz	a0,80005fc4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fb0:	ffffe097          	auipc	ra,0xffffe
    80005fb4:	09c080e7          	jalr	156(ra) # 8000404c <iunlockput>
  end_op();
    80005fb8:	fffff097          	auipc	ra,0xfffff
    80005fbc:	884080e7          	jalr	-1916(ra) # 8000483c <end_op>
  return 0;
    80005fc0:	4501                	li	a0,0
    80005fc2:	a031                	j	80005fce <sys_mknod+0x80>
    end_op();
    80005fc4:	fffff097          	auipc	ra,0xfffff
    80005fc8:	878080e7          	jalr	-1928(ra) # 8000483c <end_op>
    return -1;
    80005fcc:	557d                	li	a0,-1
}
    80005fce:	60ea                	ld	ra,152(sp)
    80005fd0:	644a                	ld	s0,144(sp)
    80005fd2:	610d                	addi	sp,sp,160
    80005fd4:	8082                	ret

0000000080005fd6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fd6:	7135                	addi	sp,sp,-160
    80005fd8:	ed06                	sd	ra,152(sp)
    80005fda:	e922                	sd	s0,144(sp)
    80005fdc:	e526                	sd	s1,136(sp)
    80005fde:	e14a                	sd	s2,128(sp)
    80005fe0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fe2:	ffffc097          	auipc	ra,0xffffc
    80005fe6:	9f2080e7          	jalr	-1550(ra) # 800019d4 <myproc>
    80005fea:	892a                	mv	s2,a0
  
  begin_op();
    80005fec:	ffffe097          	auipc	ra,0xffffe
    80005ff0:	7d0080e7          	jalr	2000(ra) # 800047bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ff4:	08000613          	li	a2,128
    80005ff8:	f6040593          	addi	a1,s0,-160
    80005ffc:	4501                	li	a0,0
    80005ffe:	ffffd097          	auipc	ra,0xffffd
    80006002:	0ae080e7          	jalr	174(ra) # 800030ac <argstr>
    80006006:	04054b63          	bltz	a0,8000605c <sys_chdir+0x86>
    8000600a:	f6040513          	addi	a0,s0,-160
    8000600e:	ffffe097          	auipc	ra,0xffffe
    80006012:	592080e7          	jalr	1426(ra) # 800045a0 <namei>
    80006016:	84aa                	mv	s1,a0
    80006018:	c131                	beqz	a0,8000605c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000601a:	ffffe097          	auipc	ra,0xffffe
    8000601e:	dd0080e7          	jalr	-560(ra) # 80003dea <ilock>
  if(ip->type != T_DIR){
    80006022:	04449703          	lh	a4,68(s1)
    80006026:	4785                	li	a5,1
    80006028:	04f71063          	bne	a4,a5,80006068 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000602c:	8526                	mv	a0,s1
    8000602e:	ffffe097          	auipc	ra,0xffffe
    80006032:	e7e080e7          	jalr	-386(ra) # 80003eac <iunlock>
  iput(p->cwd);
    80006036:	15093503          	ld	a0,336(s2)
    8000603a:	ffffe097          	auipc	ra,0xffffe
    8000603e:	f6a080e7          	jalr	-150(ra) # 80003fa4 <iput>
  end_op();
    80006042:	ffffe097          	auipc	ra,0xffffe
    80006046:	7fa080e7          	jalr	2042(ra) # 8000483c <end_op>
  p->cwd = ip;
    8000604a:	14993823          	sd	s1,336(s2)
  return 0;
    8000604e:	4501                	li	a0,0
}
    80006050:	60ea                	ld	ra,152(sp)
    80006052:	644a                	ld	s0,144(sp)
    80006054:	64aa                	ld	s1,136(sp)
    80006056:	690a                	ld	s2,128(sp)
    80006058:	610d                	addi	sp,sp,160
    8000605a:	8082                	ret
    end_op();
    8000605c:	ffffe097          	auipc	ra,0xffffe
    80006060:	7e0080e7          	jalr	2016(ra) # 8000483c <end_op>
    return -1;
    80006064:	557d                	li	a0,-1
    80006066:	b7ed                	j	80006050 <sys_chdir+0x7a>
    iunlockput(ip);
    80006068:	8526                	mv	a0,s1
    8000606a:	ffffe097          	auipc	ra,0xffffe
    8000606e:	fe2080e7          	jalr	-30(ra) # 8000404c <iunlockput>
    end_op();
    80006072:	ffffe097          	auipc	ra,0xffffe
    80006076:	7ca080e7          	jalr	1994(ra) # 8000483c <end_op>
    return -1;
    8000607a:	557d                	li	a0,-1
    8000607c:	bfd1                	j	80006050 <sys_chdir+0x7a>

000000008000607e <sys_exec>:

uint64
sys_exec(void)
{
    8000607e:	7145                	addi	sp,sp,-464
    80006080:	e786                	sd	ra,456(sp)
    80006082:	e3a2                	sd	s0,448(sp)
    80006084:	ff26                	sd	s1,440(sp)
    80006086:	fb4a                	sd	s2,432(sp)
    80006088:	f74e                	sd	s3,424(sp)
    8000608a:	f352                	sd	s4,416(sp)
    8000608c:	ef56                	sd	s5,408(sp)
    8000608e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006090:	08000613          	li	a2,128
    80006094:	f4040593          	addi	a1,s0,-192
    80006098:	4501                	li	a0,0
    8000609a:	ffffd097          	auipc	ra,0xffffd
    8000609e:	012080e7          	jalr	18(ra) # 800030ac <argstr>
    return -1;
    800060a2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060a4:	0c054a63          	bltz	a0,80006178 <sys_exec+0xfa>
    800060a8:	e3840593          	addi	a1,s0,-456
    800060ac:	4505                	li	a0,1
    800060ae:	ffffd097          	auipc	ra,0xffffd
    800060b2:	fdc080e7          	jalr	-36(ra) # 8000308a <argaddr>
    800060b6:	0c054163          	bltz	a0,80006178 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800060ba:	10000613          	li	a2,256
    800060be:	4581                	li	a1,0
    800060c0:	e4040513          	addi	a0,s0,-448
    800060c4:	ffffb097          	auipc	ra,0xffffb
    800060c8:	c1c080e7          	jalr	-996(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060cc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060d0:	89a6                	mv	s3,s1
    800060d2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060d4:	02000a13          	li	s4,32
    800060d8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060dc:	00391513          	slli	a0,s2,0x3
    800060e0:	e3040593          	addi	a1,s0,-464
    800060e4:	e3843783          	ld	a5,-456(s0)
    800060e8:	953e                	add	a0,a0,a5
    800060ea:	ffffd097          	auipc	ra,0xffffd
    800060ee:	ee4080e7          	jalr	-284(ra) # 80002fce <fetchaddr>
    800060f2:	02054a63          	bltz	a0,80006126 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800060f6:	e3043783          	ld	a5,-464(s0)
    800060fa:	c3b9                	beqz	a5,80006140 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060fc:	ffffb097          	auipc	ra,0xffffb
    80006100:	9f8080e7          	jalr	-1544(ra) # 80000af4 <kalloc>
    80006104:	85aa                	mv	a1,a0
    80006106:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000610a:	cd11                	beqz	a0,80006126 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000610c:	6605                	lui	a2,0x1
    8000610e:	e3043503          	ld	a0,-464(s0)
    80006112:	ffffd097          	auipc	ra,0xffffd
    80006116:	f0e080e7          	jalr	-242(ra) # 80003020 <fetchstr>
    8000611a:	00054663          	bltz	a0,80006126 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000611e:	0905                	addi	s2,s2,1
    80006120:	09a1                	addi	s3,s3,8
    80006122:	fb491be3          	bne	s2,s4,800060d8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006126:	10048913          	addi	s2,s1,256
    8000612a:	6088                	ld	a0,0(s1)
    8000612c:	c529                	beqz	a0,80006176 <sys_exec+0xf8>
    kfree(argv[i]);
    8000612e:	ffffb097          	auipc	ra,0xffffb
    80006132:	8ca080e7          	jalr	-1846(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006136:	04a1                	addi	s1,s1,8
    80006138:	ff2499e3          	bne	s1,s2,8000612a <sys_exec+0xac>
  return -1;
    8000613c:	597d                	li	s2,-1
    8000613e:	a82d                	j	80006178 <sys_exec+0xfa>
      argv[i] = 0;
    80006140:	0a8e                	slli	s5,s5,0x3
    80006142:	fc040793          	addi	a5,s0,-64
    80006146:	9abe                	add	s5,s5,a5
    80006148:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000614c:	e4040593          	addi	a1,s0,-448
    80006150:	f4040513          	addi	a0,s0,-192
    80006154:	fffff097          	auipc	ra,0xfffff
    80006158:	194080e7          	jalr	404(ra) # 800052e8 <exec>
    8000615c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000615e:	10048993          	addi	s3,s1,256
    80006162:	6088                	ld	a0,0(s1)
    80006164:	c911                	beqz	a0,80006178 <sys_exec+0xfa>
    kfree(argv[i]);
    80006166:	ffffb097          	auipc	ra,0xffffb
    8000616a:	892080e7          	jalr	-1902(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000616e:	04a1                	addi	s1,s1,8
    80006170:	ff3499e3          	bne	s1,s3,80006162 <sys_exec+0xe4>
    80006174:	a011                	j	80006178 <sys_exec+0xfa>
  return -1;
    80006176:	597d                	li	s2,-1
}
    80006178:	854a                	mv	a0,s2
    8000617a:	60be                	ld	ra,456(sp)
    8000617c:	641e                	ld	s0,448(sp)
    8000617e:	74fa                	ld	s1,440(sp)
    80006180:	795a                	ld	s2,432(sp)
    80006182:	79ba                	ld	s3,424(sp)
    80006184:	7a1a                	ld	s4,416(sp)
    80006186:	6afa                	ld	s5,408(sp)
    80006188:	6179                	addi	sp,sp,464
    8000618a:	8082                	ret

000000008000618c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000618c:	7139                	addi	sp,sp,-64
    8000618e:	fc06                	sd	ra,56(sp)
    80006190:	f822                	sd	s0,48(sp)
    80006192:	f426                	sd	s1,40(sp)
    80006194:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006196:	ffffc097          	auipc	ra,0xffffc
    8000619a:	83e080e7          	jalr	-1986(ra) # 800019d4 <myproc>
    8000619e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800061a0:	fd840593          	addi	a1,s0,-40
    800061a4:	4501                	li	a0,0
    800061a6:	ffffd097          	auipc	ra,0xffffd
    800061aa:	ee4080e7          	jalr	-284(ra) # 8000308a <argaddr>
    return -1;
    800061ae:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800061b0:	0e054063          	bltz	a0,80006290 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800061b4:	fc840593          	addi	a1,s0,-56
    800061b8:	fd040513          	addi	a0,s0,-48
    800061bc:	fffff097          	auipc	ra,0xfffff
    800061c0:	dfc080e7          	jalr	-516(ra) # 80004fb8 <pipealloc>
    return -1;
    800061c4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061c6:	0c054563          	bltz	a0,80006290 <sys_pipe+0x104>
  fd0 = -1;
    800061ca:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061ce:	fd043503          	ld	a0,-48(s0)
    800061d2:	fffff097          	auipc	ra,0xfffff
    800061d6:	508080e7          	jalr	1288(ra) # 800056da <fdalloc>
    800061da:	fca42223          	sw	a0,-60(s0)
    800061de:	08054c63          	bltz	a0,80006276 <sys_pipe+0xea>
    800061e2:	fc843503          	ld	a0,-56(s0)
    800061e6:	fffff097          	auipc	ra,0xfffff
    800061ea:	4f4080e7          	jalr	1268(ra) # 800056da <fdalloc>
    800061ee:	fca42023          	sw	a0,-64(s0)
    800061f2:	06054863          	bltz	a0,80006262 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061f6:	4691                	li	a3,4
    800061f8:	fc440613          	addi	a2,s0,-60
    800061fc:	fd843583          	ld	a1,-40(s0)
    80006200:	68a8                	ld	a0,80(s1)
    80006202:	ffffb097          	auipc	ra,0xffffb
    80006206:	470080e7          	jalr	1136(ra) # 80001672 <copyout>
    8000620a:	02054063          	bltz	a0,8000622a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000620e:	4691                	li	a3,4
    80006210:	fc040613          	addi	a2,s0,-64
    80006214:	fd843583          	ld	a1,-40(s0)
    80006218:	0591                	addi	a1,a1,4
    8000621a:	68a8                	ld	a0,80(s1)
    8000621c:	ffffb097          	auipc	ra,0xffffb
    80006220:	456080e7          	jalr	1110(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006224:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006226:	06055563          	bgez	a0,80006290 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000622a:	fc442783          	lw	a5,-60(s0)
    8000622e:	07e9                	addi	a5,a5,26
    80006230:	078e                	slli	a5,a5,0x3
    80006232:	97a6                	add	a5,a5,s1
    80006234:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006238:	fc042503          	lw	a0,-64(s0)
    8000623c:	0569                	addi	a0,a0,26
    8000623e:	050e                	slli	a0,a0,0x3
    80006240:	9526                	add	a0,a0,s1
    80006242:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006246:	fd043503          	ld	a0,-48(s0)
    8000624a:	fffff097          	auipc	ra,0xfffff
    8000624e:	a3e080e7          	jalr	-1474(ra) # 80004c88 <fileclose>
    fileclose(wf);
    80006252:	fc843503          	ld	a0,-56(s0)
    80006256:	fffff097          	auipc	ra,0xfffff
    8000625a:	a32080e7          	jalr	-1486(ra) # 80004c88 <fileclose>
    return -1;
    8000625e:	57fd                	li	a5,-1
    80006260:	a805                	j	80006290 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006262:	fc442783          	lw	a5,-60(s0)
    80006266:	0007c863          	bltz	a5,80006276 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000626a:	01a78513          	addi	a0,a5,26
    8000626e:	050e                	slli	a0,a0,0x3
    80006270:	9526                	add	a0,a0,s1
    80006272:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006276:	fd043503          	ld	a0,-48(s0)
    8000627a:	fffff097          	auipc	ra,0xfffff
    8000627e:	a0e080e7          	jalr	-1522(ra) # 80004c88 <fileclose>
    fileclose(wf);
    80006282:	fc843503          	ld	a0,-56(s0)
    80006286:	fffff097          	auipc	ra,0xfffff
    8000628a:	a02080e7          	jalr	-1534(ra) # 80004c88 <fileclose>
    return -1;
    8000628e:	57fd                	li	a5,-1
}
    80006290:	853e                	mv	a0,a5
    80006292:	70e2                	ld	ra,56(sp)
    80006294:	7442                	ld	s0,48(sp)
    80006296:	74a2                	ld	s1,40(sp)
    80006298:	6121                	addi	sp,sp,64
    8000629a:	8082                	ret
    8000629c:	0000                	unimp
	...

00000000800062a0 <kernelvec>:
    800062a0:	7111                	addi	sp,sp,-256
    800062a2:	e006                	sd	ra,0(sp)
    800062a4:	e40a                	sd	sp,8(sp)
    800062a6:	e80e                	sd	gp,16(sp)
    800062a8:	ec12                	sd	tp,24(sp)
    800062aa:	f016                	sd	t0,32(sp)
    800062ac:	f41a                	sd	t1,40(sp)
    800062ae:	f81e                	sd	t2,48(sp)
    800062b0:	fc22                	sd	s0,56(sp)
    800062b2:	e0a6                	sd	s1,64(sp)
    800062b4:	e4aa                	sd	a0,72(sp)
    800062b6:	e8ae                	sd	a1,80(sp)
    800062b8:	ecb2                	sd	a2,88(sp)
    800062ba:	f0b6                	sd	a3,96(sp)
    800062bc:	f4ba                	sd	a4,104(sp)
    800062be:	f8be                	sd	a5,112(sp)
    800062c0:	fcc2                	sd	a6,120(sp)
    800062c2:	e146                	sd	a7,128(sp)
    800062c4:	e54a                	sd	s2,136(sp)
    800062c6:	e94e                	sd	s3,144(sp)
    800062c8:	ed52                	sd	s4,152(sp)
    800062ca:	f156                	sd	s5,160(sp)
    800062cc:	f55a                	sd	s6,168(sp)
    800062ce:	f95e                	sd	s7,176(sp)
    800062d0:	fd62                	sd	s8,184(sp)
    800062d2:	e1e6                	sd	s9,192(sp)
    800062d4:	e5ea                	sd	s10,200(sp)
    800062d6:	e9ee                	sd	s11,208(sp)
    800062d8:	edf2                	sd	t3,216(sp)
    800062da:	f1f6                	sd	t4,224(sp)
    800062dc:	f5fa                	sd	t5,232(sp)
    800062de:	f9fe                	sd	t6,240(sp)
    800062e0:	bbbfc0ef          	jal	ra,80002e9a <kerneltrap>
    800062e4:	6082                	ld	ra,0(sp)
    800062e6:	6122                	ld	sp,8(sp)
    800062e8:	61c2                	ld	gp,16(sp)
    800062ea:	7282                	ld	t0,32(sp)
    800062ec:	7322                	ld	t1,40(sp)
    800062ee:	73c2                	ld	t2,48(sp)
    800062f0:	7462                	ld	s0,56(sp)
    800062f2:	6486                	ld	s1,64(sp)
    800062f4:	6526                	ld	a0,72(sp)
    800062f6:	65c6                	ld	a1,80(sp)
    800062f8:	6666                	ld	a2,88(sp)
    800062fa:	7686                	ld	a3,96(sp)
    800062fc:	7726                	ld	a4,104(sp)
    800062fe:	77c6                	ld	a5,112(sp)
    80006300:	7866                	ld	a6,120(sp)
    80006302:	688a                	ld	a7,128(sp)
    80006304:	692a                	ld	s2,136(sp)
    80006306:	69ca                	ld	s3,144(sp)
    80006308:	6a6a                	ld	s4,152(sp)
    8000630a:	7a8a                	ld	s5,160(sp)
    8000630c:	7b2a                	ld	s6,168(sp)
    8000630e:	7bca                	ld	s7,176(sp)
    80006310:	7c6a                	ld	s8,184(sp)
    80006312:	6c8e                	ld	s9,192(sp)
    80006314:	6d2e                	ld	s10,200(sp)
    80006316:	6dce                	ld	s11,208(sp)
    80006318:	6e6e                	ld	t3,216(sp)
    8000631a:	7e8e                	ld	t4,224(sp)
    8000631c:	7f2e                	ld	t5,232(sp)
    8000631e:	7fce                	ld	t6,240(sp)
    80006320:	6111                	addi	sp,sp,256
    80006322:	10200073          	sret
    80006326:	00000013          	nop
    8000632a:	00000013          	nop
    8000632e:	0001                	nop

0000000080006330 <timervec>:
    80006330:	34051573          	csrrw	a0,mscratch,a0
    80006334:	e10c                	sd	a1,0(a0)
    80006336:	e510                	sd	a2,8(a0)
    80006338:	e914                	sd	a3,16(a0)
    8000633a:	6d0c                	ld	a1,24(a0)
    8000633c:	7110                	ld	a2,32(a0)
    8000633e:	6194                	ld	a3,0(a1)
    80006340:	96b2                	add	a3,a3,a2
    80006342:	e194                	sd	a3,0(a1)
    80006344:	4589                	li	a1,2
    80006346:	14459073          	csrw	sip,a1
    8000634a:	6914                	ld	a3,16(a0)
    8000634c:	6510                	ld	a2,8(a0)
    8000634e:	610c                	ld	a1,0(a0)
    80006350:	34051573          	csrrw	a0,mscratch,a0
    80006354:	30200073          	mret
	...

000000008000635a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000635a:	1141                	addi	sp,sp,-16
    8000635c:	e422                	sd	s0,8(sp)
    8000635e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006360:	0c0007b7          	lui	a5,0xc000
    80006364:	4705                	li	a4,1
    80006366:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006368:	c3d8                	sw	a4,4(a5)
}
    8000636a:	6422                	ld	s0,8(sp)
    8000636c:	0141                	addi	sp,sp,16
    8000636e:	8082                	ret

0000000080006370 <plicinithart>:

void
plicinithart(void)
{
    80006370:	1141                	addi	sp,sp,-16
    80006372:	e406                	sd	ra,8(sp)
    80006374:	e022                	sd	s0,0(sp)
    80006376:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006378:	ffffb097          	auipc	ra,0xffffb
    8000637c:	630080e7          	jalr	1584(ra) # 800019a8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006380:	0085171b          	slliw	a4,a0,0x8
    80006384:	0c0027b7          	lui	a5,0xc002
    80006388:	97ba                	add	a5,a5,a4
    8000638a:	40200713          	li	a4,1026
    8000638e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006392:	00d5151b          	slliw	a0,a0,0xd
    80006396:	0c2017b7          	lui	a5,0xc201
    8000639a:	953e                	add	a0,a0,a5
    8000639c:	00052023          	sw	zero,0(a0)
}
    800063a0:	60a2                	ld	ra,8(sp)
    800063a2:	6402                	ld	s0,0(sp)
    800063a4:	0141                	addi	sp,sp,16
    800063a6:	8082                	ret

00000000800063a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063a8:	1141                	addi	sp,sp,-16
    800063aa:	e406                	sd	ra,8(sp)
    800063ac:	e022                	sd	s0,0(sp)
    800063ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	5f8080e7          	jalr	1528(ra) # 800019a8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063b8:	00d5179b          	slliw	a5,a0,0xd
    800063bc:	0c201537          	lui	a0,0xc201
    800063c0:	953e                	add	a0,a0,a5
  return irq;
}
    800063c2:	4148                	lw	a0,4(a0)
    800063c4:	60a2                	ld	ra,8(sp)
    800063c6:	6402                	ld	s0,0(sp)
    800063c8:	0141                	addi	sp,sp,16
    800063ca:	8082                	ret

00000000800063cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063cc:	1101                	addi	sp,sp,-32
    800063ce:	ec06                	sd	ra,24(sp)
    800063d0:	e822                	sd	s0,16(sp)
    800063d2:	e426                	sd	s1,8(sp)
    800063d4:	1000                	addi	s0,sp,32
    800063d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063d8:	ffffb097          	auipc	ra,0xffffb
    800063dc:	5d0080e7          	jalr	1488(ra) # 800019a8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063e0:	00d5151b          	slliw	a0,a0,0xd
    800063e4:	0c2017b7          	lui	a5,0xc201
    800063e8:	97aa                	add	a5,a5,a0
    800063ea:	c3c4                	sw	s1,4(a5)
}
    800063ec:	60e2                	ld	ra,24(sp)
    800063ee:	6442                	ld	s0,16(sp)
    800063f0:	64a2                	ld	s1,8(sp)
    800063f2:	6105                	addi	sp,sp,32
    800063f4:	8082                	ret

00000000800063f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063f6:	1141                	addi	sp,sp,-16
    800063f8:	e406                	sd	ra,8(sp)
    800063fa:	e022                	sd	s0,0(sp)
    800063fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063fe:	479d                	li	a5,7
    80006400:	06a7c963          	blt	a5,a0,80006472 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006404:	0001e797          	auipc	a5,0x1e
    80006408:	bfc78793          	addi	a5,a5,-1028 # 80024000 <disk>
    8000640c:	00a78733          	add	a4,a5,a0
    80006410:	6789                	lui	a5,0x2
    80006412:	97ba                	add	a5,a5,a4
    80006414:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006418:	e7ad                	bnez	a5,80006482 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000641a:	00451793          	slli	a5,a0,0x4
    8000641e:	00020717          	auipc	a4,0x20
    80006422:	be270713          	addi	a4,a4,-1054 # 80026000 <disk+0x2000>
    80006426:	6314                	ld	a3,0(a4)
    80006428:	96be                	add	a3,a3,a5
    8000642a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000642e:	6314                	ld	a3,0(a4)
    80006430:	96be                	add	a3,a3,a5
    80006432:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006436:	6314                	ld	a3,0(a4)
    80006438:	96be                	add	a3,a3,a5
    8000643a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000643e:	6318                	ld	a4,0(a4)
    80006440:	97ba                	add	a5,a5,a4
    80006442:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006446:	0001e797          	auipc	a5,0x1e
    8000644a:	bba78793          	addi	a5,a5,-1094 # 80024000 <disk>
    8000644e:	97aa                	add	a5,a5,a0
    80006450:	6509                	lui	a0,0x2
    80006452:	953e                	add	a0,a0,a5
    80006454:	4785                	li	a5,1
    80006456:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000645a:	00020517          	auipc	a0,0x20
    8000645e:	bbe50513          	addi	a0,a0,-1090 # 80026018 <disk+0x2018>
    80006462:	ffffc097          	auipc	ra,0xffffc
    80006466:	dde080e7          	jalr	-546(ra) # 80002240 <wakeup>
}
    8000646a:	60a2                	ld	ra,8(sp)
    8000646c:	6402                	ld	s0,0(sp)
    8000646e:	0141                	addi	sp,sp,16
    80006470:	8082                	ret
    panic("free_desc 1");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	48e50513          	addi	a0,a0,1166 # 80008900 <syscalls+0x330>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0c4080e7          	jalr	196(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006482:	00002517          	auipc	a0,0x2
    80006486:	48e50513          	addi	a0,a0,1166 # 80008910 <syscalls+0x340>
    8000648a:	ffffa097          	auipc	ra,0xffffa
    8000648e:	0b4080e7          	jalr	180(ra) # 8000053e <panic>

0000000080006492 <virtio_disk_init>:
{
    80006492:	1101                	addi	sp,sp,-32
    80006494:	ec06                	sd	ra,24(sp)
    80006496:	e822                	sd	s0,16(sp)
    80006498:	e426                	sd	s1,8(sp)
    8000649a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000649c:	00002597          	auipc	a1,0x2
    800064a0:	48458593          	addi	a1,a1,1156 # 80008920 <syscalls+0x350>
    800064a4:	00020517          	auipc	a0,0x20
    800064a8:	c8450513          	addi	a0,a0,-892 # 80026128 <disk+0x2128>
    800064ac:	ffffa097          	auipc	ra,0xffffa
    800064b0:	6a8080e7          	jalr	1704(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064b4:	100017b7          	lui	a5,0x10001
    800064b8:	4398                	lw	a4,0(a5)
    800064ba:	2701                	sext.w	a4,a4
    800064bc:	747277b7          	lui	a5,0x74727
    800064c0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064c4:	0ef71163          	bne	a4,a5,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064c8:	100017b7          	lui	a5,0x10001
    800064cc:	43dc                	lw	a5,4(a5)
    800064ce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064d0:	4705                	li	a4,1
    800064d2:	0ce79a63          	bne	a5,a4,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064d6:	100017b7          	lui	a5,0x10001
    800064da:	479c                	lw	a5,8(a5)
    800064dc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064de:	4709                	li	a4,2
    800064e0:	0ce79363          	bne	a5,a4,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064e4:	100017b7          	lui	a5,0x10001
    800064e8:	47d8                	lw	a4,12(a5)
    800064ea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064ec:	554d47b7          	lui	a5,0x554d4
    800064f0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064f4:	0af71963          	bne	a4,a5,800065a6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064f8:	100017b7          	lui	a5,0x10001
    800064fc:	4705                	li	a4,1
    800064fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006500:	470d                	li	a4,3
    80006502:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006504:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006506:	c7ffe737          	lui	a4,0xc7ffe
    8000650a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    8000650e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006510:	2701                	sext.w	a4,a4
    80006512:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006514:	472d                	li	a4,11
    80006516:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006518:	473d                	li	a4,15
    8000651a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000651c:	6705                	lui	a4,0x1
    8000651e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006520:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006524:	5bdc                	lw	a5,52(a5)
    80006526:	2781                	sext.w	a5,a5
  if(max == 0)
    80006528:	c7d9                	beqz	a5,800065b6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000652a:	471d                	li	a4,7
    8000652c:	08f77d63          	bgeu	a4,a5,800065c6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006530:	100014b7          	lui	s1,0x10001
    80006534:	47a1                	li	a5,8
    80006536:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006538:	6609                	lui	a2,0x2
    8000653a:	4581                	li	a1,0
    8000653c:	0001e517          	auipc	a0,0x1e
    80006540:	ac450513          	addi	a0,a0,-1340 # 80024000 <disk>
    80006544:	ffffa097          	auipc	ra,0xffffa
    80006548:	79c080e7          	jalr	1948(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000654c:	0001e717          	auipc	a4,0x1e
    80006550:	ab470713          	addi	a4,a4,-1356 # 80024000 <disk>
    80006554:	00c75793          	srli	a5,a4,0xc
    80006558:	2781                	sext.w	a5,a5
    8000655a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000655c:	00020797          	auipc	a5,0x20
    80006560:	aa478793          	addi	a5,a5,-1372 # 80026000 <disk+0x2000>
    80006564:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006566:	0001e717          	auipc	a4,0x1e
    8000656a:	b1a70713          	addi	a4,a4,-1254 # 80024080 <disk+0x80>
    8000656e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006570:	0001f717          	auipc	a4,0x1f
    80006574:	a9070713          	addi	a4,a4,-1392 # 80025000 <disk+0x1000>
    80006578:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000657a:	4705                	li	a4,1
    8000657c:	00e78c23          	sb	a4,24(a5)
    80006580:	00e78ca3          	sb	a4,25(a5)
    80006584:	00e78d23          	sb	a4,26(a5)
    80006588:	00e78da3          	sb	a4,27(a5)
    8000658c:	00e78e23          	sb	a4,28(a5)
    80006590:	00e78ea3          	sb	a4,29(a5)
    80006594:	00e78f23          	sb	a4,30(a5)
    80006598:	00e78fa3          	sb	a4,31(a5)
}
    8000659c:	60e2                	ld	ra,24(sp)
    8000659e:	6442                	ld	s0,16(sp)
    800065a0:	64a2                	ld	s1,8(sp)
    800065a2:	6105                	addi	sp,sp,32
    800065a4:	8082                	ret
    panic("could not find virtio disk");
    800065a6:	00002517          	auipc	a0,0x2
    800065aa:	38a50513          	addi	a0,a0,906 # 80008930 <syscalls+0x360>
    800065ae:	ffffa097          	auipc	ra,0xffffa
    800065b2:	f90080e7          	jalr	-112(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800065b6:	00002517          	auipc	a0,0x2
    800065ba:	39a50513          	addi	a0,a0,922 # 80008950 <syscalls+0x380>
    800065be:	ffffa097          	auipc	ra,0xffffa
    800065c2:	f80080e7          	jalr	-128(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800065c6:	00002517          	auipc	a0,0x2
    800065ca:	3aa50513          	addi	a0,a0,938 # 80008970 <syscalls+0x3a0>
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	f70080e7          	jalr	-144(ra) # 8000053e <panic>

00000000800065d6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065d6:	7159                	addi	sp,sp,-112
    800065d8:	f486                	sd	ra,104(sp)
    800065da:	f0a2                	sd	s0,96(sp)
    800065dc:	eca6                	sd	s1,88(sp)
    800065de:	e8ca                	sd	s2,80(sp)
    800065e0:	e4ce                	sd	s3,72(sp)
    800065e2:	e0d2                	sd	s4,64(sp)
    800065e4:	fc56                	sd	s5,56(sp)
    800065e6:	f85a                	sd	s6,48(sp)
    800065e8:	f45e                	sd	s7,40(sp)
    800065ea:	f062                	sd	s8,32(sp)
    800065ec:	ec66                	sd	s9,24(sp)
    800065ee:	e86a                	sd	s10,16(sp)
    800065f0:	1880                	addi	s0,sp,112
    800065f2:	892a                	mv	s2,a0
    800065f4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065f6:	00c52c83          	lw	s9,12(a0)
    800065fa:	001c9c9b          	slliw	s9,s9,0x1
    800065fe:	1c82                	slli	s9,s9,0x20
    80006600:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006604:	00020517          	auipc	a0,0x20
    80006608:	b2450513          	addi	a0,a0,-1244 # 80026128 <disk+0x2128>
    8000660c:	ffffa097          	auipc	ra,0xffffa
    80006610:	5d8080e7          	jalr	1496(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006614:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006616:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006618:	0001eb97          	auipc	s7,0x1e
    8000661c:	9e8b8b93          	addi	s7,s7,-1560 # 80024000 <disk>
    80006620:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006622:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006624:	8a4e                	mv	s4,s3
    80006626:	a051                	j	800066aa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006628:	00fb86b3          	add	a3,s7,a5
    8000662c:	96da                	add	a3,a3,s6
    8000662e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006632:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006634:	0207c563          	bltz	a5,8000665e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006638:	2485                	addiw	s1,s1,1
    8000663a:	0711                	addi	a4,a4,4
    8000663c:	25548063          	beq	s1,s5,8000687c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006640:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006642:	00020697          	auipc	a3,0x20
    80006646:	9d668693          	addi	a3,a3,-1578 # 80026018 <disk+0x2018>
    8000664a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000664c:	0006c583          	lbu	a1,0(a3)
    80006650:	fde1                	bnez	a1,80006628 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006652:	2785                	addiw	a5,a5,1
    80006654:	0685                	addi	a3,a3,1
    80006656:	ff879be3          	bne	a5,s8,8000664c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000665a:	57fd                	li	a5,-1
    8000665c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000665e:	02905a63          	blez	s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006662:	f9042503          	lw	a0,-112(s0)
    80006666:	00000097          	auipc	ra,0x0
    8000666a:	d90080e7          	jalr	-624(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    8000666e:	4785                	li	a5,1
    80006670:	0297d163          	bge	a5,s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006674:	f9442503          	lw	a0,-108(s0)
    80006678:	00000097          	auipc	ra,0x0
    8000667c:	d7e080e7          	jalr	-642(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006680:	4789                	li	a5,2
    80006682:	0097d863          	bge	a5,s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006686:	f9842503          	lw	a0,-104(s0)
    8000668a:	00000097          	auipc	ra,0x0
    8000668e:	d6c080e7          	jalr	-660(ra) # 800063f6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006692:	00020597          	auipc	a1,0x20
    80006696:	a9658593          	addi	a1,a1,-1386 # 80026128 <disk+0x2128>
    8000669a:	00020517          	auipc	a0,0x20
    8000669e:	97e50513          	addi	a0,a0,-1666 # 80026018 <disk+0x2018>
    800066a2:	ffffc097          	auipc	ra,0xffffc
    800066a6:	a12080e7          	jalr	-1518(ra) # 800020b4 <sleep>
  for(int i = 0; i < 3; i++){
    800066aa:	f9040713          	addi	a4,s0,-112
    800066ae:	84ce                	mv	s1,s3
    800066b0:	bf41                	j	80006640 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800066b2:	20058713          	addi	a4,a1,512
    800066b6:	00471693          	slli	a3,a4,0x4
    800066ba:	0001e717          	auipc	a4,0x1e
    800066be:	94670713          	addi	a4,a4,-1722 # 80024000 <disk>
    800066c2:	9736                	add	a4,a4,a3
    800066c4:	4685                	li	a3,1
    800066c6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066ca:	20058713          	addi	a4,a1,512
    800066ce:	00471693          	slli	a3,a4,0x4
    800066d2:	0001e717          	auipc	a4,0x1e
    800066d6:	92e70713          	addi	a4,a4,-1746 # 80024000 <disk>
    800066da:	9736                	add	a4,a4,a3
    800066dc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800066e0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066e4:	7679                	lui	a2,0xffffe
    800066e6:	963e                	add	a2,a2,a5
    800066e8:	00020697          	auipc	a3,0x20
    800066ec:	91868693          	addi	a3,a3,-1768 # 80026000 <disk+0x2000>
    800066f0:	6298                	ld	a4,0(a3)
    800066f2:	9732                	add	a4,a4,a2
    800066f4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066f6:	6298                	ld	a4,0(a3)
    800066f8:	9732                	add	a4,a4,a2
    800066fa:	4541                	li	a0,16
    800066fc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066fe:	6298                	ld	a4,0(a3)
    80006700:	9732                	add	a4,a4,a2
    80006702:	4505                	li	a0,1
    80006704:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006708:	f9442703          	lw	a4,-108(s0)
    8000670c:	6288                	ld	a0,0(a3)
    8000670e:	962a                	add	a2,a2,a0
    80006710:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd700e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006714:	0712                	slli	a4,a4,0x4
    80006716:	6290                	ld	a2,0(a3)
    80006718:	963a                	add	a2,a2,a4
    8000671a:	05890513          	addi	a0,s2,88
    8000671e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006720:	6294                	ld	a3,0(a3)
    80006722:	96ba                	add	a3,a3,a4
    80006724:	40000613          	li	a2,1024
    80006728:	c690                	sw	a2,8(a3)
  if(write)
    8000672a:	140d0063          	beqz	s10,8000686a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000672e:	00020697          	auipc	a3,0x20
    80006732:	8d26b683          	ld	a3,-1838(a3) # 80026000 <disk+0x2000>
    80006736:	96ba                	add	a3,a3,a4
    80006738:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000673c:	0001e817          	auipc	a6,0x1e
    80006740:	8c480813          	addi	a6,a6,-1852 # 80024000 <disk>
    80006744:	00020517          	auipc	a0,0x20
    80006748:	8bc50513          	addi	a0,a0,-1860 # 80026000 <disk+0x2000>
    8000674c:	6114                	ld	a3,0(a0)
    8000674e:	96ba                	add	a3,a3,a4
    80006750:	00c6d603          	lhu	a2,12(a3)
    80006754:	00166613          	ori	a2,a2,1
    80006758:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000675c:	f9842683          	lw	a3,-104(s0)
    80006760:	6110                	ld	a2,0(a0)
    80006762:	9732                	add	a4,a4,a2
    80006764:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006768:	20058613          	addi	a2,a1,512
    8000676c:	0612                	slli	a2,a2,0x4
    8000676e:	9642                	add	a2,a2,a6
    80006770:	577d                	li	a4,-1
    80006772:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006776:	00469713          	slli	a4,a3,0x4
    8000677a:	6114                	ld	a3,0(a0)
    8000677c:	96ba                	add	a3,a3,a4
    8000677e:	03078793          	addi	a5,a5,48
    80006782:	97c2                	add	a5,a5,a6
    80006784:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006786:	611c                	ld	a5,0(a0)
    80006788:	97ba                	add	a5,a5,a4
    8000678a:	4685                	li	a3,1
    8000678c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000678e:	611c                	ld	a5,0(a0)
    80006790:	97ba                	add	a5,a5,a4
    80006792:	4809                	li	a6,2
    80006794:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006798:	611c                	ld	a5,0(a0)
    8000679a:	973e                	add	a4,a4,a5
    8000679c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067a0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800067a4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067a8:	6518                	ld	a4,8(a0)
    800067aa:	00275783          	lhu	a5,2(a4)
    800067ae:	8b9d                	andi	a5,a5,7
    800067b0:	0786                	slli	a5,a5,0x1
    800067b2:	97ba                	add	a5,a5,a4
    800067b4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800067b8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067bc:	6518                	ld	a4,8(a0)
    800067be:	00275783          	lhu	a5,2(a4)
    800067c2:	2785                	addiw	a5,a5,1
    800067c4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067c8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067cc:	100017b7          	lui	a5,0x10001
    800067d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067d4:	00492703          	lw	a4,4(s2)
    800067d8:	4785                	li	a5,1
    800067da:	02f71163          	bne	a4,a5,800067fc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800067de:	00020997          	auipc	s3,0x20
    800067e2:	94a98993          	addi	s3,s3,-1718 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    800067e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067e8:	85ce                	mv	a1,s3
    800067ea:	854a                	mv	a0,s2
    800067ec:	ffffc097          	auipc	ra,0xffffc
    800067f0:	8c8080e7          	jalr	-1848(ra) # 800020b4 <sleep>
  while(b->disk == 1) {
    800067f4:	00492783          	lw	a5,4(s2)
    800067f8:	fe9788e3          	beq	a5,s1,800067e8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800067fc:	f9042903          	lw	s2,-112(s0)
    80006800:	20090793          	addi	a5,s2,512
    80006804:	00479713          	slli	a4,a5,0x4
    80006808:	0001d797          	auipc	a5,0x1d
    8000680c:	7f878793          	addi	a5,a5,2040 # 80024000 <disk>
    80006810:	97ba                	add	a5,a5,a4
    80006812:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006816:	0001f997          	auipc	s3,0x1f
    8000681a:	7ea98993          	addi	s3,s3,2026 # 80026000 <disk+0x2000>
    8000681e:	00491713          	slli	a4,s2,0x4
    80006822:	0009b783          	ld	a5,0(s3)
    80006826:	97ba                	add	a5,a5,a4
    80006828:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000682c:	854a                	mv	a0,s2
    8000682e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006832:	00000097          	auipc	ra,0x0
    80006836:	bc4080e7          	jalr	-1084(ra) # 800063f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000683a:	8885                	andi	s1,s1,1
    8000683c:	f0ed                	bnez	s1,8000681e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000683e:	00020517          	auipc	a0,0x20
    80006842:	8ea50513          	addi	a0,a0,-1814 # 80026128 <disk+0x2128>
    80006846:	ffffa097          	auipc	ra,0xffffa
    8000684a:	452080e7          	jalr	1106(ra) # 80000c98 <release>
}
    8000684e:	70a6                	ld	ra,104(sp)
    80006850:	7406                	ld	s0,96(sp)
    80006852:	64e6                	ld	s1,88(sp)
    80006854:	6946                	ld	s2,80(sp)
    80006856:	69a6                	ld	s3,72(sp)
    80006858:	6a06                	ld	s4,64(sp)
    8000685a:	7ae2                	ld	s5,56(sp)
    8000685c:	7b42                	ld	s6,48(sp)
    8000685e:	7ba2                	ld	s7,40(sp)
    80006860:	7c02                	ld	s8,32(sp)
    80006862:	6ce2                	ld	s9,24(sp)
    80006864:	6d42                	ld	s10,16(sp)
    80006866:	6165                	addi	sp,sp,112
    80006868:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000686a:	0001f697          	auipc	a3,0x1f
    8000686e:	7966b683          	ld	a3,1942(a3) # 80026000 <disk+0x2000>
    80006872:	96ba                	add	a3,a3,a4
    80006874:	4609                	li	a2,2
    80006876:	00c69623          	sh	a2,12(a3)
    8000687a:	b5c9                	j	8000673c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000687c:	f9042583          	lw	a1,-112(s0)
    80006880:	20058793          	addi	a5,a1,512
    80006884:	0792                	slli	a5,a5,0x4
    80006886:	0001e517          	auipc	a0,0x1e
    8000688a:	82250513          	addi	a0,a0,-2014 # 800240a8 <disk+0xa8>
    8000688e:	953e                	add	a0,a0,a5
  if(write)
    80006890:	e20d11e3          	bnez	s10,800066b2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006894:	20058713          	addi	a4,a1,512
    80006898:	00471693          	slli	a3,a4,0x4
    8000689c:	0001d717          	auipc	a4,0x1d
    800068a0:	76470713          	addi	a4,a4,1892 # 80024000 <disk>
    800068a4:	9736                	add	a4,a4,a3
    800068a6:	0a072423          	sw	zero,168(a4)
    800068aa:	b505                	j	800066ca <virtio_disk_rw+0xf4>

00000000800068ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068ac:	1101                	addi	sp,sp,-32
    800068ae:	ec06                	sd	ra,24(sp)
    800068b0:	e822                	sd	s0,16(sp)
    800068b2:	e426                	sd	s1,8(sp)
    800068b4:	e04a                	sd	s2,0(sp)
    800068b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068b8:	00020517          	auipc	a0,0x20
    800068bc:	87050513          	addi	a0,a0,-1936 # 80026128 <disk+0x2128>
    800068c0:	ffffa097          	auipc	ra,0xffffa
    800068c4:	324080e7          	jalr	804(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068c8:	10001737          	lui	a4,0x10001
    800068cc:	533c                	lw	a5,96(a4)
    800068ce:	8b8d                	andi	a5,a5,3
    800068d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068d6:	0001f797          	auipc	a5,0x1f
    800068da:	72a78793          	addi	a5,a5,1834 # 80026000 <disk+0x2000>
    800068de:	6b94                	ld	a3,16(a5)
    800068e0:	0207d703          	lhu	a4,32(a5)
    800068e4:	0026d783          	lhu	a5,2(a3)
    800068e8:	06f70163          	beq	a4,a5,8000694a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068ec:	0001d917          	auipc	s2,0x1d
    800068f0:	71490913          	addi	s2,s2,1812 # 80024000 <disk>
    800068f4:	0001f497          	auipc	s1,0x1f
    800068f8:	70c48493          	addi	s1,s1,1804 # 80026000 <disk+0x2000>
    __sync_synchronize();
    800068fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006900:	6898                	ld	a4,16(s1)
    80006902:	0204d783          	lhu	a5,32(s1)
    80006906:	8b9d                	andi	a5,a5,7
    80006908:	078e                	slli	a5,a5,0x3
    8000690a:	97ba                	add	a5,a5,a4
    8000690c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000690e:	20078713          	addi	a4,a5,512
    80006912:	0712                	slli	a4,a4,0x4
    80006914:	974a                	add	a4,a4,s2
    80006916:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000691a:	e731                	bnez	a4,80006966 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000691c:	20078793          	addi	a5,a5,512
    80006920:	0792                	slli	a5,a5,0x4
    80006922:	97ca                	add	a5,a5,s2
    80006924:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006926:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000692a:	ffffc097          	auipc	ra,0xffffc
    8000692e:	916080e7          	jalr	-1770(ra) # 80002240 <wakeup>

    disk.used_idx += 1;
    80006932:	0204d783          	lhu	a5,32(s1)
    80006936:	2785                	addiw	a5,a5,1
    80006938:	17c2                	slli	a5,a5,0x30
    8000693a:	93c1                	srli	a5,a5,0x30
    8000693c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006940:	6898                	ld	a4,16(s1)
    80006942:	00275703          	lhu	a4,2(a4)
    80006946:	faf71be3          	bne	a4,a5,800068fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000694a:	0001f517          	auipc	a0,0x1f
    8000694e:	7de50513          	addi	a0,a0,2014 # 80026128 <disk+0x2128>
    80006952:	ffffa097          	auipc	ra,0xffffa
    80006956:	346080e7          	jalr	838(ra) # 80000c98 <release>
}
    8000695a:	60e2                	ld	ra,24(sp)
    8000695c:	6442                	ld	s0,16(sp)
    8000695e:	64a2                	ld	s1,8(sp)
    80006960:	6902                	ld	s2,0(sp)
    80006962:	6105                	addi	sp,sp,32
    80006964:	8082                	ret
      panic("virtio_disk_intr status");
    80006966:	00002517          	auipc	a0,0x2
    8000696a:	02a50513          	addi	a0,a0,42 # 80008990 <syscalls+0x3c0>
    8000696e:	ffffa097          	auipc	ra,0xffffa
    80006972:	bd0080e7          	jalr	-1072(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
