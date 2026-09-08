DATA SEGMENT
    ;-------------------- C 程序中的变量 --------------------
    p    DW 0                 ; short p
    q    DW 0                 ; short q
    n    DD 0                 ; int n
    fai  DD 0                 ; int fai
    e    DD 0                 ; int e
    d    DD 0                 ; int d
    m    DD 0                 ; int m (明文)
    vc   DD 0                 ; int c (密文)
    a    DD 0                 ; int a
    x    DD 0                 ; int x (exgcd 系数)
    y    DD 0                 ; int y (exgcd 系数)

    ;-------------------- 随机数生成器 --------------------
    seed    DW 0              ; rand 的种子
    num_tmp DW 0              ; check_num 中的随机底数 num

    ;-------------------- read_int 的工作区 --------------------
    rd_acc_lo DW 0            ; 累加器低位
    rd_acc_hi DW 0            ; 累加器高位
    rd_sign   DW 0            ; 符号标志 (1=负)
    rd_digit  DW 0            ; 当前数字

    ;-------------------- 多精度运算工作区 --------------------
    A_lo DW 0                 ; 32 位被乘数/被除数 A
    A_hi DW 0
    B_lo DW 0                 ; 32 位乘数/除数 B
    B_hi DW 0
    M_lo DW 0                 ; 32 位模数 M
    M_hi DW 0
    P0  DW 0                  ; 64 位乘积 P = P3:P2:P1:P0
    P1  DW 0
    P2  DW 0
    P3  DW 0
    Q_lo DW 0                 ; 32 位商
    Q_hi DW 0
    R_lo DW 0                 ; 32 位余数
    R_hi DW 0

    ;-------------------- mod_pow 的参数与局部量 --------------------
    base_lo DW 0
    base_hi DW 0
    exp_lo  DW 0
    exp_hi  DW 0
    mod_lo  DW 0
    mod_hi  DW 0
    sum_lo  DW 0
    sum_hi  DW 0

    ;-------------------- 提示字符串 (以 '$' 结尾) --------------------
    sInputPrompt DB "Please enter two prime numbers p&q:$"
    sPrimeOk     DB "They are both prime numbers.",13,10,"$"
    sN           DB "n=$"
    sCommaFai    DB ",fai=$"
    sE           DB "e=$"
    sD           DB "d=$"
    sInputM      DB "Please enter the plaintext m:$"
    sC           DB "Encrypted plaintext c=$"
    sMdec        DB "Decrypted plaintext m=$"
    sNoD1        DB "e and fai are not coprime,so d cannot be calculated.",13,10,"$"
    sNotPrime    DB "At least one of the two numbers you entered isn't prime, please try again!",13,10,"$"
DATA ENDS

STACK SEGMENT STACK
    DW 1024 DUP(?)           ; 2KB 栈空间 (exgcd 递归需要)
STACK ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK

;============================================================================
;  主程序
;============================================================================
START:
    MOV  AX, DATA
    MOV  DS, AX

    ;---- printf("请输入两个素数p和q：") ----
    MOV  DX, OFFSET sInputPrompt
    CALL print_str

    ;---- scanf("%hd %hd", &p, &q) ----
    CALL read_int              ; 读入 p (32 位存于 DX:AX)
    MOV  p, AX                 ; 截取低 16 位, 对应 %hd
    CALL read_int              ; 读入 q
    MOV  q, AX

    ;---- if (check_num(p) && check_num(q)) ----
    PUSH p
    CALL check_num             ; AX = check_num(p)
    OR   AX, AX
    JNZ  main_prime_p
    JMP  main_notprime
main_prime_p:
    PUSH q
    CALL check_num             ; AX = check_num(q)
    OR   AX, AX
    JNZ  main_prime_q
    JMP  main_notprime
main_prime_q:
    ;---- printf("输入的两个数都是素数\n") ----
    MOV  DX, OFFSET sPrimeOk
    CALL print_str

    ;---- n = p * q  (16x16 -> 32 位) ----
    MOV  AX, p
    MOV  BX, q
    MUL  BX                   ; DX:AX = p*q
    MOV  WORD PTR n, AX
    MOV  WORD PTR n+2, DX

    ;---- fai = (p-1) * (q-1) ----
    MOV  AX, p
    DEC  AX                   ; AX = p-1
    MOV  CX, AX
    MOV  AX, q
    DEC  AX                   ; AX = q-1
    MOV  BX, AX
    MOV  AX, CX               ; AX = p-1
    MUL  BX                   ; DX:AX = (p-1)*(q-1)
    MOV  WORD PTR fai, AX
    MOV  WORD PTR fai+2, DX

    ;---- printf("n=%d,fai=%d\n", n, fai) ----
    MOV  DX, OFFSET sN
    CALL print_str
    MOV  AX, WORD PTR n
    MOV  DX, WORD PTR n+2
    CALL print_int
    MOV  DX, OFFSET sCommaFai
    CALL print_str
    MOV  AX, WORD PTR fai
    MOV  DX, WORD PTR fai+2
    CALL print_int
    CALL print_crlf

    ;---- e = odd_traversal(fai) ----
    PUSH WORD PTR fai+2
    PUSH WORD PTR fai
    CALL odd_traversal        ; DX:AX = e
    MOV  WORD PTR e, AX
    MOV  WORD PTR e+2, DX

    ;---- printf("e=%d\n", e) ----
    MOV  DX, OFFSET sE
    CALL print_str
    MOV  AX, WORD PTR e
    MOV  DX, WORD PTR e+2
    CALL print_int
    CALL print_crlf

    ;---- a = Euclid(e, fai) ----
    PUSH WORD PTR fai+2
    PUSH WORD PTR fai
    PUSH WORD PTR e+2
    PUSH WORD PTR e
    CALL Euclid               ; DX:AX = a
    MOV  WORD PTR a, AX
    MOV  WORD PTR a+2, DX

    ;---- if (a == 1) ----
    CMP  AX, 1
    JE   main_a_lo
    JMP  main_a_not1
main_a_lo:
    CMP  DX, 0
    JE   main_a_hi
    JMP  main_a_not1
main_a_hi:

    ;---- d = extended_euclid(e, fai, &x, &y) ----
    MOV  AX, OFFSET y
    PUSH AX
    MOV  AX, OFFSET x
    PUSH AX
    PUSH WORD PTR fai+2
    PUSH WORD PTR fai
    PUSH WORD PTR e+2
    PUSH WORD PTR e
    CALL extended_euclid      ; DX:AX = d

    ;---- if (d == -1) ----
    CMP  AX, 0FFFFH
    JNE  main_d_ok
    CMP  DX, 0FFFFH
    JNE  main_d_ok
    MOV  DX, OFFSET sNoD1
    CALL print_str
    JMP  main_exit

main_d_ok:
    MOV  WORD PTR d, AX
    MOV  WORD PTR d+2, DX

    ;---- printf("d=%d\n", d) ----
    MOV  DX, OFFSET sD
    CALL print_str
    MOV  AX, WORD PTR d
    MOV  DX, WORD PTR d+2
    CALL print_int
    CALL print_crlf

    ;---- printf("请输入明文m：") + scanf("%d", &m) ----
    MOV  DX, OFFSET sInputM
    CALL print_str
    CALL read_int
    MOV  WORD PTR m, AX
    MOV  WORD PTR m+2, DX

    ;---- c = (int)encrypt(m, e, n) ----
    CALL encrypt               ; DX:AX = c
    MOV  WORD PTR vc, AX
    MOV  WORD PTR vc+2, DX

    ;---- printf("加密后的密文c=%d\n", c) ----
    MOV  DX, OFFSET sC
    CALL print_str
    MOV  AX, WORD PTR vc
    MOV  DX, WORD PTR vc+2
    CALL print_int
    CALL print_crlf

    ;---- m = (int)decrypt(c, d, n) ----
    CALL decrypt               ; DX:AX = m
    MOV  WORD PTR m, AX
    MOV  WORD PTR m+2, DX

    ;---- printf("解密后的明文m=%d\n", m) ----
    MOV  DX, OFFSET sMdec
    CALL print_str
    MOV  AX, WORD PTR m
    MOV  DX, WORD PTR m+2
    CALL print_int
    CALL print_crlf

    JMP  main_exit

main_a_not1:
    ;---- printf("e与fai不互质，无法计算d\n") ----
    MOV  DX, OFFSET sNoD1
    CALL print_str
    JMP  main_exit

main_notprime:
    ;---- printf("输入的两个数中至少有一个不是素数，请重新输入！\n") ----
    MOV  DX, OFFSET sNotPrime
    CALL print_str

main_exit:
    MOV  AX, 4C00H
    INT  21H

;============================================================================
;  print_str: 输出以 '$' 结尾的字符串 (DX = 字符串偏移)
;============================================================================
print_str PROC NEAR
    PUSH AX
    MOV  AH, 09H
    INT  21H
    POP  AX
    RET
print_str ENDP

;============================================================================
;  print_crlf: 输出回车换行
;============================================================================
print_crlf PROC NEAR
    PUSH AX
    PUSH DX
    MOV  AH, 02H
    MOV  DL, 0DH
    INT  21H
    MOV  DL, 0AH
    INT  21H
    POP  DX
    POP  AX
    RET
print_crlf ENDP

;============================================================================
;  print_int: 以十进制输出 32 位有符号整数 (DX:AX = 值)
;============================================================================
print_int PROC NEAR
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    OR   DX, DX
    JNS  pp_pos              ; 非负则跳过符号处理
    ; 先取绝对值, 再输出负号 (避免 INT 21H 破坏 AX/DX)
    NOT  AX
    NOT  DX
    ADD  AX, 1
    ADC  DX, 0
    PUSH DX
    PUSH AX
    MOV  AH, 02H
    MOV  DL, '-'
    INT  21H
    POP  AX
    POP  DX
pp_pos:
    XOR  SI, SI              ; SI = 数字个数
pp_div:
    ; 用 32 位除法逐次除以 10
    MOV  A_lo, AX
    MOV  A_hi, DX
    MOV  B_lo, 10
    MOV  B_hi, 0
    CALL divmod32
    MOV  AX, Q_lo            ; 商
    MOV  DX, Q_hi
    MOV  CX, R_lo            ; 余数(个位)
    ADD  CX, '0'
    PUSH CX
    INC  SI
    MOV  BX, AX
    OR   BX, DX
    JNZ  pp_div              ; 商不为 0 则继续
pp_print:
    POP  DX
    MOV  AH, 02H
    INT  21H
    DEC  SI
    JNZ  pp_print
    POP  DI
    POP  SI
    POP  CX
    POP  BX
    RET
print_int ENDP

;============================================================================
;  read_int: 从键盘读入 32 位有符号十进制整数, 返回 DX:AX
;            (跳过前导空白与回车换行, 支持前导 +/- 号)
;============================================================================
read_int PROC NEAR
    PUSH BX
    PUSH CX
    MOV  rd_acc_lo, 0
    MOV  rd_acc_hi, 0
    MOV  rd_sign, 0
rd_skip:
    MOV  AH, 01H
    INT  21H
    CMP  AL, ' '
    JE   rd_skip
    CMP  AL, 09H
    JE   rd_skip
    CMP  AL, 0DH
    JE   rd_skip
    CMP  AL, 0AH
    JE   rd_skip
    CMP  AL, '-'
    JNE  rd_plus
    MOV  rd_sign, 1
    MOV  AH, 01H
    INT  21H
    JMP  rd_first
rd_plus:
    CMP  AL, '+'
    JNE  rd_first
    MOV  AH, 01H
    INT  21H
rd_first:
    ; AL 中为当前字符
rd_dig:
    CMP  AL, '0'
    JB   rd_done
    CMP  AL, '9'
    JA   rd_done
    SUB  AL, '0'
    XOR  AH, AH
    MOV  rd_digit, AX         ; 数字 0..9
    ; acc = acc*10 + digit = acc*8 + acc*2 + digit
    MOV  AX, rd_acc_lo
    MOV  DX, rd_acc_hi
    SHL  AX, 1
    RCL  DX, 1
    SHL  AX, 1
    RCL  DX, 1
    SHL  AX, 1
    RCL  DX, 1                ; DX:AX = acc*8
    MOV  BX, rd_acc_lo
    MOV  CX, rd_acc_hi
    SHL  BX, 1
    RCL  CX, 1                ; CX:BX = acc*2
    ADD  AX, BX
    ADC  DX, CX               ; DX:AX = acc*10
    ADD  AX, rd_digit
    ADC  DX, 0                ; DX:AX = acc*10 + digit
    MOV  rd_acc_lo, AX
    MOV  rd_acc_hi, DX
    MOV  AH, 01H
    INT  21H                  ; 读下一个字符
    JMP  rd_dig
rd_done:
    MOV  AX, rd_acc_lo
    MOV  DX, rd_acc_hi
    CMP  rd_sign, 1
    JNE  rd_ret
    NOT  AX
    NOT  DX
    ADD  AX, 1
    ADC  DX, 0                ; 取相反数
rd_ret:
    POP  CX
    POP  BX
    RET
read_int ENDP

;============================================================================
;  srand_now: 用系统时间初始化随机数种子 (对应 srand(time(NULL)))
;============================================================================
srand_now PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV  AH, 2CH              ; DOS 取时间: CH=时 CL=分 DH=秒 DL=1/100秒
    INT  21H
    MOV  AX, DX               ; 秒:1/100秒
    XOR  AX, CX               ; 与 分:时 混合
    JNZ  sn_done
    MOV  AX, 0A5A5H           ; 避免种子为 0
sn_done:
    MOV  seed, AX
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
srand_now ENDP

;============================================================================
;  rand16: 线性同余伪随机数发生器, 返回 AX (0..65535), 对应 rand()
;============================================================================
rand16 PROC NEAR
    PUSH BX
    PUSH DX
    MOV  AX, seed
    MOV  BX, 25173
    MUL  BX                   ; DX:AX = seed*25173
    ADD  AX, 13849
    ADC  DX, 0
    MOV  seed, AX             ; 取低 16 位 (模 2^16)
    POP  DX
    POP  BX
    RET
rand16 ENDP

;============================================================================
;  div32_core: 32 位无符号恢复余数法除法的核心循环 (32 次)
;    输入:  A = 待移位的被除数(32位), B = 除数(32位), R = 初始余数(32位)
;    输出:  Q = 商(32位), R = 余数(32位), A 被破坏
;============================================================================
div32_core PROC NEAR
    PUSH CX
    MOV  Q_lo, 0
    MOV  Q_hi, 0
    MOV  CX, 32
dloop:
    ; 被除数左移 1 位, 最高位 -> CF
    SHL  A_lo, 1
    RCL  A_hi, 1
    ; 余数左移 1 位, 最低位 <- CF
    RCL  R_lo, 1
    RCL  R_hi, 1
    ; 比较 R >= B (无符号)
    MOV  AX, R_hi
    CMP  AX, B_hi
    JA   dosub
    JB   nosub
    MOV  AX, R_lo
    CMP  AX, B_lo
    JB   nosub
dosub:
    MOV  AX, R_lo
    SUB  AX, B_lo
    MOV  R_lo, AX
    MOV  AX, R_hi
    SBB  AX, B_hi
    MOV  R_hi, AX
    STC                        ; 商位 = 1
    JMP  shiftq
nosub:
    CLC                        ; 商位 = 0
shiftq:
    RCL  Q_lo, 1
    RCL  Q_hi, 1
    LOOP dloop
    POP  CX
    RET
div32_core ENDP

;============================================================================
;  divmod32: 32位 / 32位 无符号除法, A/B -> Q(商), R(余数)
;============================================================================
divmod32 PROC NEAR
    MOV  R_lo, 0
    MOV  R_hi, 0
    CALL div32_core
    RET
divmod32 ENDP

;============================================================================
;  divmod64: 64位 / 32位 无符号除法, P(64位)/B(32位) -> Q(商), R(余数)
;            商必须能放入 32 位 (调用方保证)
;============================================================================
divmod64 PROC NEAR
    ; 初始余数 = P 的高 32 位
    MOV  AX, P2
    MOV  R_lo, AX
    MOV  AX, P3
    MOV  R_hi, AX
    ; 待移位被除数 = P 的低 32 位
    MOV  AX, P0
    MOV  A_lo, AX
    MOV  AX, P1
    MOV  A_hi, AX
    CALL div32_core
    RET
divmod64 ENDP

;============================================================================
;  mul32x32: 32位 * 32位 -> 64位 无符号乘法, A*B -> P (P3:P2:P1:P0)
;============================================================================
mul32x32 PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    ; 部分积 t0 = A_lo * B_lo
    MOV  AX, A_lo
    MOV  BX, B_lo
    MUL  BX                   ; DX:AX = A_lo*B_lo
    MOV  P0, AX
    MOV  SI, DX               ; SI = 进位 c1
    ; 部分积 t1 = A_hi * B_lo
    MOV  AX, A_hi
    MOV  BX, B_lo
    MUL  BX                   ; DX:AX = A_hi*B_lo
    MOV  CX, DX
    ADD  AX, SI               ; AX = A_hi*B_lo低 + c1
    ADC  CX, 0                ; CX = A_hi*B_lo高 + 进位
    MOV  SI, CX               ; SI = P2 部分
    MOV  DI, AX               ; DI = P1 部分
    ; 部分积 t2 = A_lo * B_hi
    MOV  AX, A_lo
    MOV  BX, B_hi
    MUL  BX                   ; DX:AX = A_lo*B_hi
    ADD  DI, AX               ; P1 += 低
    ADC  SI, DX               ; P2 += 高 + 进位
    MOV  CX, 0
    ADC  CX, 0                ; CX = P3 部分(进位)
    ; 部分积 t3 = A_hi * B_hi
    MOV  AX, A_hi
    MOV  BX, B_hi
    MUL  BX                   ; DX:AX = A_hi*B_hi
    ADD  SI, AX               ; P2 += 低
    ADC  CX, DX               ; P3 += 高 + 进位
    MOV  P1, DI
    MOV  P2, SI
    MOV  P3, CX
    POP  DI
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
mul32x32 ENDP

;============================================================================
;  mulmod: (A * B) mod M -> R (32位), 用于模幂运算中的模乘
;============================================================================
mulmod PROC NEAR
    CALL mul32x32             ; P = A*B (64位)
    MOV  AX, M_lo
    MOV  B_lo, AX
    MOV  AX, M_hi
    MOV  B_hi, AX
    CALL divmod64             ; R = P mod M
    RET
mulmod ENDP

;============================================================================
;  mod_pow: 快速幂取模, 计算 base^exp mod mod, 返回 DX:AX
;    对应 C 函数: long long mod_pow(base, exp, mod)
;    使用全局变量 base_*, exp_*, mod_* 作为参数
;============================================================================
mod_pow PROC NEAR
    ; sum = 1
    MOV  sum_lo, 1
    MOV  sum_hi, 0
    ; base %= mod
    MOV  AX, base_lo
    MOV  A_lo, AX
    MOV  AX, base_hi
    MOV  A_hi, AX
    MOV  AX, mod_lo
    MOV  B_lo, AX
    MOV  AX, mod_hi
    MOV  B_hi, AX
    CALL divmod32
    MOV  AX, R_lo
    MOV  base_lo, AX
    MOV  AX, R_hi
    MOV  base_hi, AX
mploop:
    ; while (exp != 0)
    MOV  AX, exp_lo
    OR   AX, exp_hi
    JZ   mpdone
    ; if (exp & 1) sum = (sum * base) % mod
    TEST exp_lo, 1
    JZ   nosum
    MOV  AX, sum_lo
    MOV  A_lo, AX
    MOV  AX, sum_hi
    MOV  A_hi, AX
    MOV  AX, base_lo
    MOV  B_lo, AX
    MOV  AX, base_hi
    MOV  B_hi, AX
    MOV  AX, mod_lo
    MOV  M_lo, AX
    MOV  AX, mod_hi
    MOV  M_hi, AX
    CALL mulmod
    MOV  AX, R_lo
    MOV  sum_lo, AX
    MOV  AX, R_hi
    MOV  sum_hi, AX
nosum:
    ; exp /= 2
    SHR  exp_hi, 1
    RCR  exp_lo, 1
    ; base = (base * base) % mod
    MOV  AX, base_lo
    MOV  A_lo, AX
    MOV  AX, base_hi
    MOV  A_hi, AX
    MOV  AX, base_lo
    MOV  B_lo, AX
    MOV  AX, base_hi
    MOV  B_hi, AX
    MOV  AX, mod_lo
    MOV  M_lo, AX
    MOV  AX, mod_hi
    MOV  M_hi, AX
    CALL mulmod
    MOV  AX, R_lo
    MOV  base_lo, AX
    MOV  AX, R_hi
    MOV  base_hi, AX
    JMP  mploop
mpdone:
    MOV  AX, sum_lo
    MOV  DX, sum_hi
    RET
mod_pow ENDP

;============================================================================
;  encrypt: 加密模块, c = mod_pow(m, e, n), 返回 DX:AX
;============================================================================
encrypt PROC NEAR
    MOV  AX, WORD PTR m
    MOV  base_lo, AX
    MOV  AX, WORD PTR m+2
    MOV  base_hi, AX
    MOV  AX, WORD PTR e
    MOV  exp_lo, AX
    MOV  AX, WORD PTR e+2
    MOV  exp_hi, AX
    MOV  AX, WORD PTR n
    MOV  mod_lo, AX
    MOV  AX, WORD PTR n+2
    MOV  mod_hi, AX
    CALL mod_pow
    RET
encrypt ENDP

;============================================================================
;  decrypt: 解密模块, m = mod_pow(c, d, n), 返回 DX:AX
;============================================================================
decrypt PROC NEAR
    MOV  AX, WORD PTR vc
    MOV  base_lo, AX
    MOV  AX, WORD PTR vc+2
    MOV  base_hi, AX
    MOV  AX, WORD PTR d
    MOV  exp_lo, AX
    MOV  AX, WORD PTR d+2
    MOV  exp_hi, AX
    MOV  AX, WORD PTR n
    MOV  mod_lo, AX
    MOV  AX, WORD PTR n+2
    MOV  mod_hi, AX
    CALL mod_pow
    RET
decrypt ENDP

;============================================================================
;  Euclid: 求最大公约数, 对应 C 的 int Euclid(int a, int b)
;    参数通过栈传递: a=[BP+4..6], b=[BP+8..10], 返回 DX:AX
;============================================================================
Euclid PROC NEAR
    PUSH BP
    MOV  BP, SP
eucloop:
    ; while (b != 0)
    MOV  AX, [BP+8]
    OR   AX, [BP+10]
    JZ   euret_a
    ; r = a % b
    MOV  AX, [BP+4]
    MOV  A_lo, AX
    MOV  AX, [BP+6]
    MOV  A_hi, AX
    MOV  AX, [BP+8]
    MOV  B_lo, AX
    MOV  AX, [BP+10]
    MOV  B_hi, AX
    CALL divmod32
    ; a = b
    MOV  AX, [BP+8]
    MOV  [BP+4], AX
    MOV  AX, [BP+10]
    MOV  [BP+6], AX
    ; b = r
    MOV  AX, R_lo
    MOV  [BP+8], AX
    MOV  AX, R_hi
    MOV  [BP+10], AX
    JMP  eucloop
euret_a:
    MOV  AX, [BP+4]
    MOV  DX, [BP+6]
    POP  BP
    RET  8
Euclid ENDP

;============================================================================
;  odd_traversal: 奇数遍历, 对应 C 的 int odd_traversal(int fai)
;    从 fai 向下找最大的与 fai 互素的奇数, 找不到返回 -1
;============================================================================
odd_traversal PROC NEAR
    PUSH BP
    MOV  BP, SP
    SUB  SP, 4                ; 局部变量 i: [BP-4]=低, [BP-2]=高
    MOV  AX, [BP+4]
    MOV  [BP-4], AX
    MOV  AX, [BP+6]
    MOV  [BP-2], AX           ; i = fai
otloop:
    MOV  AX, [BP-4]
    OR   AX, [BP-2]
    JZ   ot_notfound          ; i == 0
    TEST WORD PTR [BP-4], 1
    JZ   ot_next              ; i 为偶数, 跳过
    ; g = Euclid(i, fai)
    PUSH WORD PTR [BP+6]      ; fai 高位
    PUSH WORD PTR [BP+4]      ; fai 低位
    PUSH WORD PTR [BP-2]      ; i 高位
    PUSH WORD PTR [BP-4]      ; i 低位
    CALL Euclid               ; DX:AX = g
    CMP  AX, 1
    JNE  ot_next
    OR   DX, DX
    JNZ  ot_next
    ; g == 1: 返回 i
    MOV  AX, [BP-4]
    MOV  DX, [BP-2]
    MOV  SP, BP
    POP  BP
    RET  4
ot_next:
    ; i--
    SUB  WORD PTR [BP-4], 1
    SBB  WORD PTR [BP-2], 0
    JMP  otloop
ot_notfound:
    MOV  AX, 0FFFFH
    MOV  DX, 0FFFFH
    MOV  SP, BP
    POP  BP
    RET  4
odd_traversal ENDP

;============================================================================
;  exgcd: 扩展 Euclid 算法 (递归), 对应 C 的
;     int exgcd(int a, int b, int *x, int *y)
;    参数: a=[BP+4..6] b=[BP+8..10] x=[BP+12] y=[BP+14], 返回 DX:AX
;    局部: x1, y1, q, g (各 32 位)
;============================================================================
exgcd PROC NEAR
    PUSH BP
    MOV  BP, SP
    SUB  SP, 16
    ; 局部: x1=[BP-4..2] y1=[BP-8..6] q=[BP-12..10] g=[BP-16..14]
    PUSH SI
    ; if (b == 0)
    MOV  AX, [BP+8]
    OR   AX, [BP+10]
    JNZ  ex_recurse
    ; *x = 1; *y = 0; return a
    MOV  SI, [BP+12]
    MOV  WORD PTR SS:[SI], 1
    MOV  WORD PTR SS:[SI+2], 0
    MOV  SI, [BP+14]
    MOV  WORD PTR SS:[SI], 0
    MOV  WORD PTR SS:[SI+2], 0
    MOV  AX, [BP+4]
    MOV  DX, [BP+6]
    JMP  ex_ret
ex_recurse:
    ; q = a / b; r = a % b
    MOV  AX, [BP+4]
    MOV  A_lo, AX
    MOV  AX, [BP+6]
    MOV  A_hi, AX
    MOV  AX, [BP+8]
    MOV  B_lo, AX
    MOV  AX, [BP+10]
    MOV  B_hi, AX
    CALL divmod32
    MOV  AX, Q_lo
    MOV  [BP-12], AX          ; 保存 q
    MOV  AX, Q_hi
    MOV  [BP-10], AX
    ; g = exgcd(b, r, &x1, &y1)
    LEA  AX, [BP-8]           ; &y1
    PUSH AX
    LEA  AX, [BP-4]           ; &x1
    PUSH AX
    PUSH R_hi                 ; r 高位
    PUSH R_lo                 ; r 低位
    PUSH WORD PTR [BP+10]     ; b 高位
    PUSH WORD PTR [BP+8]      ; b 低位
    CALL exgcd
    MOV  [BP-16], AX          ; 保存 g
    MOV  [BP-14], DX
    ; *x = y1
    MOV  SI, [BP+12]
    MOV  AX, [BP-8]
    MOV  SS:[SI], AX
    MOV  AX, [BP-6]
    MOV  SS:[SI+2], AX
    ; *y = x1 - (a/b)*y1  (取乘积低 32 位, 与 C 的 int 回绕一致)
    MOV  AX, [BP-12]
    MOV  A_lo, AX
    MOV  AX, [BP-10]
    MOV  A_hi, AX
    MOV  AX, [BP-8]
    MOV  B_lo, AX
    MOV  AX, [BP-6]
    MOV  B_hi, AX
    CALL mul32x32             ; P = q*y1 (64位)
    MOV  AX, [BP-4]           ; x1 低位
    SUB  AX, P0
    MOV  [BP-8], AX           ; 暂存结果
    MOV  AX, [BP-2]           ; x1 高位
    SBB  AX, P1
    MOV  [BP-6], AX
    MOV  SI, [BP+14]
    MOV  AX, [BP-8]
    MOV  SS:[SI], AX
    MOV  AX, [BP-6]
    MOV  SS:[SI+2], AX
    ; return g
    MOV  AX, [BP-16]
    MOV  DX, [BP-14]
ex_ret:
    POP  SI
    MOV  SP, BP
    POP  BP
    RET  12
exgcd ENDP

;============================================================================
;  extended_euclid: 求 e 关于 fai 的模逆 d, 对应 C 的
;     int extended_euclid(int e, int fai, int *x, int *y)
;============================================================================
extended_euclid PROC NEAR
    PUSH BP
    MOV  BP, SP
    SUB  SP, 8
    ; 局部: x0=[BP-4..2] y0=[BP-8..6]
    PUSH SI
    ; g = exgcd(e, fai, &x0, &y0)
    LEA  AX, [BP-8]           ; &y0
    PUSH AX
    LEA  AX, [BP-4]           ; &x0
    PUSH AX
    PUSH WORD PTR [BP+10]     ; fai 高位
    PUSH WORD PTR [BP+8]      ; fai 低位
    PUSH WORD PTR [BP+6]      ; e 高位
    PUSH WORD PTR [BP+4]      ; e 低位
    CALL exgcd                ; DX:AX = g
    ; if (g != 1) return -1
    CMP  AX, 1
    JNE  ee_neg
    OR   DX, DX
    JNZ  ee_neg
    ; *x = x0; *y = y0
    MOV  SI, [BP+12]
    MOV  AX, [BP-4]
    MOV  [SI], AX
    MOV  AX, [BP-2]
    MOV  [SI+2], AX
    MOV  SI, [BP+14]
    MOV  AX, [BP-8]
    MOV  [SI], AX
    MOV  AX, [BP-6]
    MOV  [SI+2], AX
    ; d = (x0 % fai + fai) % fai
    ; 由于 |x0| < fai, 等价于: x0<0 时 d = x0 + fai, 否则 d = x0
    MOV  AX, [BP-4]           ; x0 低位
    MOV  DX, [BP-2]           ; x0 高位
    OR   DX, DX
    JNS  ee_ret               ; x0 >= 0
    ADD  AX, [BP+8]           ; + fai 低位
    ADC  DX, [BP+10]          ; + fai 高位
    JMP  ee_ret
ee_neg:
    MOV  AX, 0FFFFH
    MOV  DX, 0FFFFH
ee_ret:
    POP  SI
    MOV  SP, BP
    POP  BP
    RET  12
extended_euclid ENDP

;============================================================================
;  check_num: 素数检测 (费马素性检验), 对应 C 的 short check_num(short p)
;    参数 p=[BP+4], 返回 AX (素数返回 p, 否则返回 0)
;============================================================================
check_num PROC NEAR
    PUSH BP
    MOV  BP, SP
    PUSH SI
    PUSH DI
    ; srand(time(NULL))
    CALL srand_now
    ; p < 3 时直接返回 p (避免 p=2 时出现除零)
    MOV  AX, [BP+4]
    CMP  AX, 3
    JB   cn_prime
    MOV  SI, 0                ; 外层循环 i = 0
cn_outer:
    CMP  SI, 100
    JAE  cn_prime             ; 100 轮全部通过 -> 素数
    ; num = rand() % (p-2) + 2
    MOV  AX, [BP+4]
    SUB  AX, 2
    MOV  DI, AX               ; DI = p-2
    CALL rand16               ; AX = 随机数
    MOV  DX, 0
    DIV  DI                   ; DX = rand % (p-2)
    ADD  DX, 2
    MOV  num_tmp, DX          ; num = 2..p-1
    ; result = 1
    MOV  BX, 1
    ; 内层循环: (p-1) 次
    MOV  CX, [BP+4]
    DEC  CX
    MOV  DI, [BP+4]           ; DI = p (除数)
cn_inner:
    ; result = (result * num) % p
    MOV  AX, BX               ; AX = result
    MOV  DX, num_tmp          ; DX = num
    MUL  DX                   ; DX:AX = result * num
    DIV  DI                   ; DX = 余数
    MOV  BX, DX               ; result = 余数
    LOOP cn_inner
    ; if (result != 1) return 0
    CMP  BX, 1
    JNE  cn_notprime
    INC  SI
    JMP  cn_outer
cn_notprime:
    XOR  AX, AX
    JMP  cn_ret
cn_prime:
    MOV  AX, [BP+4]
cn_ret:
    POP  DI
    POP  SI
    POP  BP
    RET  2
check_num ENDP

CODE ENDS
END START
