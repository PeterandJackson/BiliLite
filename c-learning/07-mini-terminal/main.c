/**
 * 项目 7：迷你终端
 * =====================
 * 学习目标：
 *   - 文件读写：fopen / fprintf / fscanf / fclose
 *   - 命令行参数：argc（参数个数）、argv（参数数组）
 *   - system() 执行系统命令
 *   - 综合运用之前学过的所有知识
 *
 * 两种运行方式：
 *   (1) 交互模式：gcc main.c -o mycli.exe && mycli.exe
 *       进入后输入命令（help/list/mynote/cls/退出）
 *
 *   (2) 快捷调用：gcc main.c -o mycli.exe
 *       mycli.exe add "今天去超市购物"
 *       mycli.exe list
 *
 * 运行方法：
 *   gcc main.c -o main.exe
 *   main.exe
 */

#include <stdio.h>
#include <stdlib.h>  // system
#include <string.h>  // strcpy, strcmp, strlen

#define MAX_NOTES 100
#define NOTE_LEN 200
#define NOTE_FILE "notes.txt"  // 存储笔记的文件名

// ===== 函数声明 =====

/** 显示帮助信息 */
void show_help()
{
    printf("\n");
    printf("  可用命令：\n");
    printf("  ┌────────────────┬──────────────────────┐\n");
    printf("  │ 命令           │ 说明                  │\n");
    printf("  ├────────────────┼──────────────────────┤\n");
    printf("  │ list  (ls)     │ 列出当前目录的文件     │\n");
    printf("  │ mynote         │ 查看所有笔记          │\n");
    printf("  │ mynote add     │ 添加一条笔记          │\n");
    printf("  │ mynote clear   │ 清空所有笔记          │\n");
    printf("  │ cls (clear)    │ 清屏                  │\n");
    printf("  │ time           │ 显示当前日期时间      │\n");
    printf("  │ help           │ 显示本帮助            │\n");
    printf("  │ exit (quit)    │ 退出程序              │\n");
    printf("  └────────────────┴──────────────────────┘\n\n");
    printf("  提示：也可以用命令行参数直接调用：\n");
    printf("    mycli.exe mynote add \"去买牛奶\"\n");
    printf("    mycli.exe mynote\n\n");
}

/** 列出文件（调用系统 dir 命令） */
void list_files()
{
    printf("\n");
    system("dir /b");  // /b 表示简洁输出
    printf("\n");
}

/** 查看所有笔记（从文件读取） */
void view_notes()
{
    FILE* file = fopen(NOTE_FILE, "r");  // "r" = 只读模式
    if (file == NULL)
    {
        printf("  还没有笔记，用 'mynote add' 来添加！\n");
        return;
    }

    printf("\n  ====== 我的笔记 ======\n");
    char line[NOTE_LEN];
    int count = 0;
    // fgets 从文件读取一行，返回 NULL 表示读到文件末尾
    while (fgets(line, NOTE_LEN, file) != NULL)
    {
        printf("  [%d] %s", ++count, line);
    }
    fclose(file);  // 用完记得关闭文件！

    if (count == 0)
    {
        printf("  （空）\n");
    }
    printf("  ======================\n");
}

/** 添加笔记（追加写入文件） */
void add_note(char* text)
{
    FILE* file = fopen(NOTE_FILE, "a");  // "a" = 追加模式（append）
    if (file == NULL)
    {
        printf("  无法创建笔记文件！\n");
        return;
    }

    // fprintf 像 printf，但把内容写入文件而不是屏幕
    fprintf(file, "%s\n", text);
    fclose(file);
    printf("  ✓ 笔记已保存：%s\n", text);
}

/** 交互式添加笔记 */
void add_note_interactive()
{
    char text[NOTE_LEN];
    printf("  请输入笔记内容：");
    getchar();
    fgets(text, NOTE_LEN, stdin);
    int len = strlen(text);
    if (len > 0 && text[len - 1] == '\n')
        text[len - 1] = '\0';
    add_note(text);
}

/** 清空笔记 */
void clear_notes()
{
    printf("  确认清空所有笔记？(y/n)：");
    getchar();
    char ch = getchar();
    if (ch == 'y' || ch == 'Y')
    {
        FILE* file = fopen(NOTE_FILE, "w");  // "w" = 写入模式（会清空已有内容）
        if (file != NULL) fclose(file);
        printf("  ✓ 笔记已清空！\n");
    }
    else
    {
        printf("  已取消。\n");
    }
}

// ===== 主函数 =====
// argc: 命令行参数的个数
// argv: 命令行参数的数组，argv[0] 是程序名，argv[1] 是第一个参数...
int main(int argc, char* argv[])
{
    // ===== 模式1：命令行参数模式 =====
    // 如果用户给了一个以上参数（argc > 1），快速执行然后退出
    if (argc > 1)
    {
        // strcmp 比较字符串，值为 0 表示相等
        if (strcmp(argv[1], "mynote") == 0)
        {
            if (argc > 2 && strcmp(argv[2], "add") == 0)
            {
                // mycli.exe mynote add "内容"
                if (argc > 3)
                {
                    add_note(argv[3]);
                }
                else
                {
                    printf("用法：mycli mynote add \"笔记内容\"\n");
                }
            }
            else if (argc > 2 && strcmp(argv[2], "clear") == 0)
            {
                clear_notes();
            }
            else
            {
                view_notes();
            }
        }
        else if (strcmp(argv[1], "list") == 0 || strcmp(argv[1], "ls") == 0)
        {
            list_files();
        }
        else if (strcmp(argv[1], "help") == 0)
        {
            show_help();
        }
        else
        {
            printf("未知命令：%s\n输入 'help' 查看帮助\n", argv[1]);
        }
        return 0;  // 参数模式下执行完就直接退出
    }

    // ===== 模式2：交互模式 =====
    // 没有命令行参数时，进入交互式命令循环
    printf("========================================\n");
    printf("         迷 你 终 端\n");
    printf("========================================\n");
    printf("输入 'help' 查看可用命令，'exit' 退出\n\n");

    char command[100];

    while (1)
    {
        printf("mycli> ");
        // scanf 返回成功读取的项目数。返回 EOF（-1）表示输入结束
        if (scanf("%s", command) != 1)
        {
            printf("\n");
            break;  // 输入结束，退出循环
        }

        if (strcmp(command, "help") == 0)
        {
            show_help();
        }
        else if (strcmp(command, "list") == 0 || strcmp(command, "ls") == 0)
        {
            list_files();
        }
        else if (strcmp(command, "mynote") == 0)
        {
            // 读取子命令
            char sub[10];
            char peek = getchar();
            if (peek == ' ')
            {
                scanf("%s", sub);
                if (strcmp(sub, "add") == 0)
                {
                    add_note_interactive();
                }
                else if (strcmp(sub, "clear") == 0)
                {
                    clear_notes();
                }
                else
                {
                    printf("  未知子命令：%s\n", sub);
                }
            }
            else
            {
                ungetc(peek, stdin);  // 把读到的字符放回去
                view_notes();
            }
        }
        else if (strcmp(command, "cls") == 0 || strcmp(command, "clear") == 0)
        {
            system("cls");  // Windows 清屏命令
        }
        else if (strcmp(command, "time") == 0)
        {
            system("date /t && time /t");  // 显示日期和时间
        }
        else if (strcmp(command, "exit") == 0 || strcmp(command, "quit") == 0)
        {
            printf("再见！\n");
            break;
        }
        else
        {
            printf("  未知命令：%s（输入 'help' 查看帮助）\n", command);
        }
    }

    return 0;
}
