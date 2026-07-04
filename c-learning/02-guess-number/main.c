/**
 * 项目 2：猜数字游戏
 * =====================
 * 学习目标：
 *   - if / else if / else 分支判断
 *   - while 循环（重复执行直到条件不满足）
 *   - rand() 生成随机数
 *   - 比较运算符：> < == != >= <=
 *   - 变量自增：count++
 *
 * 运行方法：
 *   gcc main.c -o main.exe
 *   main.exe
 */

#include <stdio.h>   // printf, scanf
#include <stdlib.h>  // rand, srand
#include <time.h>    // time（用于随机数种子）

int main()
{
    // ===== 第1部分：生成随机数 =====
    // srand(time(NULL)) 用当前时间作为"种子"来初始化随机数生成器
    // 这样每次运行程序，生成的随机数都不一样
    srand(time(NULL));

    // rand() % 100 生成 0~99 的随机数，+1 变成 1~100
    int answer = rand() % 100 + 1;
    int guess;          // 存放玩家的猜测
    int count = 0;      // 记录猜了多少次

    printf("========================================\n");
    printf("         猜数字游戏 (1~100)\n");
    printf("========================================\n\n");
    printf("我已经想好了一个 1 到 100 之间的数字\n");
    printf("来猜猜看吧！\n\n");

    // ===== 第2部分：游戏循环 =====
    // while (1) 表示"永远循环"，只有遇到 break 才会跳出
    while (1)
    {
        printf("请输入你的猜测：");
        scanf("%d", &guess);  // %d 读取整数
        count++;              // 猜测次数 +1

        // ===== 第3部分：判断大小 =====
        if (guess > answer)
        {
            printf("  ↓ 太大了！再小一点~\n\n");
        }
        else if (guess < answer)
        {
            printf("  ↑ 太小了！再大一点~\n\n");
        }
        else
        {
            // 猜中了！
            printf("\n========================================\n");
            printf("  恭喜你猜中了！答案就是 %d！\n", answer);
            printf("  你一共猜了 %d 次\n", count);
            printf("========================================\n");

            // 根据猜测次数给出评价
            if (count <= 3)
            {
                printf("  评价：运气爆棚！你是天才！🌟\n");
            }
            else if (count <= 7)
            {
                printf("  评价：不错哦！思路很清晰 👍\n");
            }
            else if (count <= 10)
            {
                printf("  评价：还行，下次可以更快 💪\n");
            }
            else
            {
                printf("  评价：终于找到了！继续加油 😊\n");
            }
            break;  // 跳出循环，游戏结束
        }
    }

    printf("\n按回车键退出...");
    getchar();
    getchar();
    return 0;
}
