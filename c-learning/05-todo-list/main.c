/**
 * 项目 5：待办事项
 * =====================
 * 学习目标：
 *   - struct 结构体：把多个相关数据"打包"成一个新类型
 *   - 结构体数组：存储多个同类结构体
 *   - 字符串操作：strcpy（复制）、strcmp（比较）
 *   - 函数模块化：每个功能独立成函数
 *   - 命令行菜单 + 增删查改 (CRUD)
 *
 * 运行方法：
 *   gcc main.c -o main.exe
 *   main.exe
 */

#include <stdio.h>
#include <string.h>  // strcpy, strcmp, strlen

#define MAX_TODOS 100       // 最多存储的待办事项数
#define TITLE_LEN 100       // 标题最大长度

// ===== 定义结构体 =====
// struct 让我们创建一个"复合数据类型"
// 一个 Todo 包含两个字段：标题（字符串）和是否完成（整数）
typedef struct
{
    char title[TITLE_LEN];  // 标题
    int done;               // 0=未完成, 1=已完成
} Todo;

// 全局变量（在这个文件里所有函数都能用）
Todo todos[MAX_TODOS];  // 结构体数组：存储所有待办事项
int todo_count = 0;     // 当前待办事项数量

// ===== 函数声明 =====

/** 显示主菜单 */
void show_menu()
{
    printf("\n");
    printf("========================================\n");
    printf("         待 办 事 项 列 表\n");
    printf("========================================\n");
    printf("  1. 查看所有事项\n");
    printf("  2. 添加新事项\n");
    printf("  3. 标记事项为完成\n");
    printf("  4. 删除事项\n");
    printf("  0. 退出\n");
    printf("========================================\n");
    printf("请选择 (0-4)：");
}

/** 查看所有待办事项 */
void list_todos()
{
    printf("\n");
    if (todo_count == 0)
    {
        printf("  （空）还没有待办事项，去添加一个吧！\n");
        return;
    }

    printf("  序号  状态    事项\n");
    printf("  ----  ------  ------------------------\n");
    for (int i = 0; i < todo_count; i++)
    {
        // strcmp 比较两个字符串，相等返回 0
        printf("  %-4d  %-6s  %s\n",
               i + 1,
               todos[i].done ? "[✓]" : "[ ]",  // 三元运算符：条件 ? 真值 : 假值
               todos[i].title);
    }
}

/** 添加新待办事项 */
void add_todo()
{
    if (todo_count >= MAX_TODOS)
    {
        printf("  待办事项已满！请先删除一些。\n");
        return;
    }

    printf("  请输入新事项：");
    getchar();  // 消耗缓冲区残留换行符
    // fgets 比 scanf 安全，可以读取带空格的字符串
    // stdin 表示从标准输入（键盘）读取
    fgets(todos[todo_count].title, TITLE_LEN, stdin);
    // fgets 会保留末尾的换行符 \n，把它去掉
    int len = strlen(todos[todo_count].title);
    if (len > 0 && todos[todo_count].title[len - 1] == '\n')
    {
        todos[todo_count].title[len - 1] = '\0';  // '\0' 是字符串结束符
    }

    todos[todo_count].done = 0;  // 新事项默认为"未完成"
    todo_count++;
    printf("  ✓ 已添加！\n");
}

/** 标记事项为完成 */
void complete_todo()
{
    list_todos();
    if (todo_count == 0) return;

    printf("\n  请输入要完成的序号：");
    int index;
    scanf("%d", &index);

    // 检查序号是否合法
    if (index < 1 || index > todo_count)
    {
        printf("  序号无效！\n");
        return;
    }

    todos[index - 1].done = 1;  // 数组从 0 开始，用户看到的序号从 1 开始
    printf("  ✓ 已标记为完成！\n");
}

/** 删除待办事项 */
void delete_todo()
{
    list_todos();
    if (todo_count == 0) return;

    printf("\n  请输入要删除的序号：");
    int index;
    scanf("%d", &index);

    if (index < 1 || index > todo_count)
    {
        printf("  序号无效！\n");
        return;
    }

    // 删除：把后面的元素依次往前移一位
    for (int i = index - 1; i < todo_count - 1; i++)
    {
        todos[i] = todos[i + 1];  // 结构体之间可以直接赋值！
    }
    todo_count--;
    printf("  ✓ 已删除！\n");
}

// ===== 主函数 =====
int main()
{
    int choice;

    printf("========================================\n");
    printf("         待 办 事 项 应 用\n");
    printf("========================================\n");
    printf("  用 struct 结构体来管理你的每日任务\n");

    do
    {
        show_menu();
        scanf("%d", &choice);

        switch (choice)
        {
            case 1: list_todos();    break;
            case 2: add_todo();      break;
            case 3: complete_todo(); break;
            case 4: delete_todo();   break;
            case 0: printf("再见！记得完成今天的事项哦~\n"); break;
            default: printf("无效选择！\n"); break;
        }
    }
    while (choice != 0);

    return 0;
}
