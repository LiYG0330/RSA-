#define _CRT_SECURE_NO_WARNINGS
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

/*func1：素数检测*/
short check_num(short p)
{
    srand((unsigned)time(NULL));
    for (int i = 0; i < 100; i++) {
        short num = rand() % (p - 2) + 2;
        long long result = 1;
        for (int j = 0; j < p - 1; j++) {
            result = (result * num) % p;
        }
        if (result != 1)
            return 0;
    }
    return p;
}

/*func2：Euclid算法*/
int Euclid(int a, int b)
{
    int r;
    while (b != 0) {
        r = a % b;
        a = b;
        b = r;
    }
    return a; // 需要判断a与1的关系
}

/*func3：奇数遍历*/
int odd_traversal(int fai)
{
    for (int i = fai; i > 0; i--) {
        if (i % 2 != 0) {
            int g = Euclid(i, fai);
            if (g != 1)
                continue;
            else
                return i;
        }
        else {
            continue;
        }
    }
    return -1;
}

/*func4：扩展Euclid算法*/
int exgcd(int a, int b, int *x, int *y)
{
    if (b == 0) {
        *x = 1;
        *y = 0;
        return a;
    }
    int x1, y1;
    int g = exgcd(b, a % b, &x1, &y1);
    *x = y1;
    *y = x1 - (a / b) * y1;
    return g;
}

/* 返回 e 关于 fai 的模逆 d，若不存在则返回 -1；同时通过 x,y 返回 exgcd 的系数 */
int extended_euclid(int e, int fai, int *x, int *y)
{
    int x0, y0;
    int g = exgcd(e, fai, &x0, &y0);
    if (g != 1) {
        return -1; /* 不存在逆元 */
    }
    *x = x0;
    *y = y0;
    int d = (x0 % fai + fai) % fai;
    return d;
}

/* 快速幂取模：计算 base^exp % mod */
long long mod_pow(long long base, long long exp, long long mod)
{
    long long sum = 1;
    base %= mod;
    while (exp) {
        if (exp & 1) {
            sum = (sum * base) % mod;
        }
        exp /= 2;
        base = base * base % mod;
    }
    return sum;
}

/*func5：加密模块*/
long long encrypt(int m, int e, int n)
{
    return mod_pow(m, e, n);
}

/*func6：解密模块*/
long long decrypt(int c, int d, int n)
{
    return mod_pow(c, d, n);
}

int main()
{
    short p, q;
    int n, fai, e, d, m, c, a;
    int x, y;
    printf("请输入两个素数p和q：");
    scanf("%hd %hd", &p, &q);
    if (check_num(p) && check_num(q)) {
        printf("输入的两个数都是素数\n");
        n = p * q;
        fai = (p - 1) * (q - 1);
        printf("n=%d,fai=%d\n", n, fai);
        e = odd_traversal(fai);
        printf("e=%d\n", e);
        a = Euclid(e, fai);
        if (a == 1) {
            d = extended_euclid(e, fai, &x, &y);
            if (d == -1) {
                printf("e 与 fai 不互质，无法计算d\n");
                return 0;
            }
            printf("d=%d\n", d);
            printf("请输入明文m：");
            scanf("%d", &m);
            c = (int)encrypt(m, e, n);
            printf("加密后的密文c=%d\n", c);
            m = (int)decrypt(c, d, n);
            printf("解密后的明文m=%d\n", m);
        }
        else {
            printf("e与fai不互质，无法计算d\n");
        }
    }
    else {
        printf("输入的两个数中至少有一个不是素数，请重新输入！\n");
    }
    return 0;
}