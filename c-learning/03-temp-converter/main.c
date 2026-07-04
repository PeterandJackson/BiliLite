/**
 * 项目 3：温度转换器
 * =====================
 * 学习目标：
 *   - 自定义函数（定义、调用、参数、返回值）
 *   - switch 语句（多路分支）
 *   - 函数的重用（写一次，多次调用）
 *   - do-while 循环（至少执行一次，再判断是否继续）
 *
 * 运行方法：
 *   gcc main.c -o main.exe
 *   main.exe
 */

#include <stdio.h>

// ===== 函数声明 =====
// 把函数定义写在 main 前面，main 才能"认识"它们
// 每个函数做一件事，让代码清晰易读

/**
 * 摄氏度 → 华氏度
 * 公式：°F = °C × 9/5 + 32
 *
 * 参数 celsius：摄氏温度
 * 返回值：对应的华氏温度
 */
float celsius_to_fahrenheit(float celsius)
{
    return celsius * 9.0 / 5.0 + 32.0;
}

/**
 * 华氏度 → 摄氏度
 * 公式：°C = (°F - 32) × 5/9
 *
 * 参数 fahrenheit：华氏温度
 * 返回值：对应的摄氏温度
 */
float fahrenheit_to_celsius(float fahrenheit)
{
    return (fahrenheit - 32.0) * 5.0 / 9.0;
}

/**
 * 显示菜单
 * void 表示这个函数不返回任何值
 */
void show_menu()
{
    printf("\n");
    printf("========================================\n");
    printf("         温 度 转 换 器\n");
    printf("========================================\n");
    printf("  1. 摄氏度 → 华氏度  (°C → °F)\n");
    printf("  2. 华氏度 → 摄氏度  (°F → °C)\n");
    printf("  0. 退出程序\n");
    printf("========================================\n");
    printf("请选择 (0-2)：");
}

int main()
{
    int choice;   // 存放用户的选择
    float temp;   // 存放输入的温度

    // do-while 循环：先执行一次，再判断是否继续
    // 适合"至少显示一次菜单"的场景
    do
    {
        show_menu();
        scanf("%d", &choice);

        // switch 语句：根据 choice 的值跳转到不同的分支
        // 比一长串 if-else if 更清晰
        switch (choice)
        {
            case 1:
                // 摄氏度 → 华氏度
                printf("请输入摄氏温度：");
                scanf("%f", &temp);
                // 调用我们写的函数，传入 temp，得到转换结果
                printf("\n  %.1f °C = %.1f °F\n", temp, celsius_to_fahrenheit(temp));
                break;  // 跳出 switch，不要"穿透"到下一个 case

            case 2:
                // 华氏度 → 摄氏度
                printf("请输入华氏温度：");
                scanf("%f", &temp);
                printf("\n  %.1f °F = %.1f °C\n", temp, fahrenheit_to_celsius(temp));
                break;

            case 0:
                printf("再见！\n");
                break;

            default:
                // 输入了 0/1/2 以外的数字
                printf("无效选择，请重新输入！\n");
                break;
        }
    }
    while (choice != 0);  // 只要不是 0，就继续循环

    return 0;
}
