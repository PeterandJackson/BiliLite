/**
 * 项目 4：成绩管理器
 * =====================
 * 学习目标：
 *   - 数组（int scores[]、char names[][]）：存放多个同类型数据
 *   - for 循环：已知次数地重复执行
 *   - 冒泡排序算法：把数组从小到大排列
 *   - 数组遍历：用循环访问每个元素
 *   - 基本统计：找最大值、最小值、算平均数
 *
 * 运行方法：
 *   gcc main.c -o main.exe
 *   main.exe
 */

#include <stdio.h>
#include <string.h>  // strcpy 复制字符串

// 常量定义：最多几个学生，名字最长几个字符
// #define 是预处理指令，编译前做文本替换
#define MAX_STUDENTS 50
#define NAME_LEN 30

int main()
{
    // ===== 第1部分：声明变量 =====
    // 二维字符数组：存储多个学生的名字
    // 可以理解为 "50 行 × 30 列" 的表格，每行是一个名字
    char names[MAX_STUDENTS][NAME_LEN];
    int scores[MAX_STUDENTS];  // 一维整数数组：存储每个学生的成绩
    int n;                     // 实际学生人数

    printf("========================================\n");
    printf("         学 生 成 绩 管 理 器\n");
    printf("========================================\n\n");

    // ===== 第2部分：输入学生信息 =====
    printf("请输入学生人数（最多 %d 人）：", MAX_STUDENTS);
    scanf("%d", &n);

    // 输入验证：防止超过数组大小
    if (n <= 0 || n > MAX_STUDENTS)
    {
        printf("人数不合法！请输入 1 ~ %d\n", MAX_STUDENTS);
        printf("按回车键退出...");
        getchar();
        getchar();
        return 1;
    }

    // for 循环的 3 个部分：(初始化; 条件; 每次迭代后执行的)
    // i++ 表示"i 自增 1"，等价于 i = i + 1
    printf("\n请依次输入每个学生的名字和成绩：\n");
    for (int i = 0; i < n; i++)
    {
        printf("  学生 %d - 名字：", i + 1);
        scanf("%s", names[i]);  // %s 读取字符串（注意：数组名本身就是地址，不用 &）
        printf("        - 成绩：");
        scanf("%d", &scores[i]);
    }

    // ===== 第3部分：排序（冒泡排序） =====
    // 冒泡排序的思想：每一轮"冒"出当前最大的元素放到末尾
    // 相邻两两比较，大的往后移，像气泡浮出水面
    for (int round = 0; round < n - 1; round++)
    {
        for (int j = 0; j < n - 1 - round; j++)
        {
            if (scores[j] < scores[j + 1])  // 降序排列（成绩高的在前）
            {
                // 交换成绩
                int temp_score = scores[j];
                scores[j] = scores[j + 1];
                scores[j + 1] = temp_score;

                // 名字也要跟着交换（保持名字和成绩对应）
                char temp_name[NAME_LEN];
                strcpy(temp_name, names[j]);        // 把 names[j] 复制到 temp_name
                strcpy(names[j], names[j + 1]);
                strcpy(names[j + 1], temp_name);
            }
        }
    }

    // ===== 第4部分：计算统计信息 =====
    int total = 0;          // 总分
    int highest = scores[0];  // 最高分（初始化为第一个元素）
    int lowest = scores[0];   // 最低分

    for (int i = 0; i < n; i++)
    {
        total += scores[i];  // 累加（等价于 total = total + scores[i]）

        if (scores[i] > highest) highest = scores[i];
        if (scores[i] < lowest) lowest = scores[i];
    }
    float average = (float)total / n;  // (float) 是类型转换，确保小数除法

    // ===== 第5部分：输出结果 =====
    printf("\n");
    printf("========================================\n");
    printf("         成 绩 排 行 榜\n");
    printf("========================================\n");
    printf("  名次  姓名           成绩\n");
    printf("  ----  ------------  ----\n");

    for (int i = 0; i < n; i++)
    {
        printf("  %-4d  %-12s  %3d 分\n", i + 1, names[i], scores[i]);
    }

    printf("========================================\n");
    printf("  总人数：%d 人\n", n);
    printf("  最高分：%d 分\n", highest);
    printf("  最低分：%d 分\n", lowest);
    printf("  平均分：%.1f 分\n", average);
    printf("========================================\n");

    printf("\n按回车键退出...");
    getchar();
    getchar();
    return 0;
}
