/**
 * 项目 6：通讯录
 * =====================
 * 学习目标：
 *   - 指针（*）：存储另一个变量的地址
 *   - 取地址符（&）：获取变量的地址
 *   - 动态内存分配 malloc()：在程序运行时申请内存
 *   - free()：释放不再使用的内存（防止内存泄漏）
 *   - sizeof：获取类型或变量占用的字节数
 *   - -> 箭头操作符：通过指针访问结构体成员
 *
 * 运行方法：
 *   gcc main.c -o main.exe
 *   main.exe
 */

#include <stdio.h>
#include <stdlib.h>  // malloc, free
#include <string.h>  // strcpy, strcmp, strstr

// 电话号码最大长度
#define PHONE_LEN 20

// ===== 联系人结构体 =====
typedef struct
{
    char name[50];          // 姓名
    char phone[PHONE_LEN];  // 电话
    int age;                // 年龄
} Contact;

// ===== 链表节点 =====
// 这是一个"自引用结构体"——节点里存了指向下一个节点的指针
// 就像火车车厢，每节车厢连着下一节
typedef struct Node
{
    Contact contact;        // 这节车厢装的"货物"（联系人数据）
    struct Node* next;      // 指向下一节车厢的指针
} Node;

// 链表头指针：指向第一节车厢
// NULL 表示"空地址"，链表为空
Node* head = NULL;

// ===== 函数声明 =====

/** 向链表末尾添加联系人 */
void add_contact()
{
    // malloc 在"堆"上申请一块内存，返回这块内存的地址
    // sizeof(Node) 告诉 malloc "我需要 Node 这么大的空间"
    Node* new_node = (Node*)malloc(sizeof(Node));
    if (new_node == NULL)
    {
        printf("  错误：内存不足！\n");
        return;
    }

    // 填充数据
    printf("  姓名：");
    getchar();
    fgets(new_node->contact.name, 50, stdin);
    int len = strlen(new_node->contact.name);
    if (len > 0 && new_node->contact.name[len - 1] == '\n')
        new_node->contact.name[len - 1] = '\0';

    printf("  电话：");
    fgets(new_node->contact.phone, PHONE_LEN, stdin);
    len = strlen(new_node->contact.phone);
    if (len > 0 && new_node->contact.phone[len - 1] == '\n')
        new_node->contact.phone[len - 1] = '\0';

    printf("  年龄：");
    scanf("%d", &new_node->contact.age);

    new_node->next = NULL;  // 新节点是最后一节车厢，后面没有车了

    // 把新节点连接到链表末尾
    if (head == NULL)
    {
        // 链表为空，新节点就是第一节车厢
        head = new_node;
    }
    else
    {
        // 遍历到链表末尾，然后把新节点接上去
        Node* current = head;
        while (current->next != NULL)
        {
            current = current->next;  // 移动到下一节车厢
        }
        current->next = new_node;  // 在末尾挂上新节点
    }
    printf("  ✓ 联系人已添加！\n");
}

/** 列出所有联系人 */
void list_contacts()
{
    printf("\n");
    if (head == NULL)
    {
        printf("  通讯录为空。\n");
        return;
    }

    printf("  %-4s %-12s %-15s %s\n", "序号", "姓名", "电话", "年龄");
    printf("  ---- ------------ --------------- ----\n");

    Node* current = head;
    int index = 1;
    while (current != NULL)
    {
        // -> 操作符：通过指针访问结构体成员
        // current->contact.name 等价于 (*current).contact.name
        printf("  %-4d %-12s %-15s %d 岁\n",
               index++,
               current->contact.name,
               current->contact.phone,
               current->contact.age);
        current = current->next;
    }
}

/** 按姓名搜索联系人 */
void search_contact()
{
    if (head == NULL)
    {
        printf("  通讯录为空。\n");
        return;
    }

    char keyword[50];
    printf("  请输入要搜索的姓名：");
    getchar();
    fgets(keyword, 50, stdin);
    int len = strlen(keyword);
    if (len > 0 && keyword[len - 1] == '\n')
        keyword[len - 1] = '\0';

    // 遍历链表，逐个比较
    int found = 0;
    Node* current = head;
    while (current != NULL)
    {
        // strstr 在字符串中查找子串，返回子串首次出现的位置
        // 返回 NULL 表示没找到
        if (strstr(current->contact.name, keyword) != NULL)
        {
            printf("  找到：%s | %s | %d 岁\n",
                   current->contact.name,
                   current->contact.phone,
                   current->contact.age);
            found = 1;
        }
        current = current->next;
    }
    if (!found)
    {
        printf("  没有找到匹配的联系人。\n");
    }
}

/** 删除联系人 */
void delete_contact()
{
    list_contacts();
    if (head == NULL) return;

    printf("\n  请输入要删除的序号：");
    int index;
    scanf("%d", &index);

    if (index < 1)
    {
        printf("  序号无效！\n");
        return;
    }

    Node* target = NULL;

    if (index == 1)
    {
        // 删除头节点（第一节车厢）
        target = head;
        head = head->next;  // 第二节变成第一节
    }
    else
    {
        // 找到要删除节点的前一个节点
        Node* prev = head;
        for (int i = 1; i < index - 1 && prev != NULL; i++)
        {
            prev = prev->next;
        }
        if (prev == NULL || prev->next == NULL)
        {
            printf("  序号无效！\n");
            return;
        }
        target = prev->next;
        prev->next = target->next;  // 跳过目标节点，重新连接
    }

    printf("  ✓ 已删除：%s\n", target->contact.name);
    free(target);  // 释放内存！忘记 free 会导致内存泄漏
}

/** 释放整个链表（退出时调用） */
void free_all()
{
    Node* current = head;
    while (current != NULL)
    {
        Node* next = current->next;  // 先记住下一节车厢
        free(current);               // 释放当前车厢
        current = next;              // 处理下一节
    }
    head = NULL;
}

// ===== 主函数 =====
int main()
{
    int choice;

    printf("========================================\n");
    printf("         通  讯  录\n");
    printf("========================================\n");
    printf("  用 指针 + 链表 管理联系人\n\n");

    do
    {
        printf("\n----------------------------------------\n");
        printf("  1. 查看所有联系人\n");
        printf("  2. 添加联系人\n");
        printf("  3. 搜索联系人\n");
        printf("  4. 删除联系人\n");
        printf("  0. 退出\n");
        printf("----------------------------------------\n");
        printf("请选择 (0-4)：");
        scanf("%d", &choice);

        switch (choice)
        {
            case 1: list_contacts();   break;
            case 2: add_contact();     break;
            case 3: search_contact();  break;
            case 4: delete_contact();  break;
            case 0:
                free_all();  // 退出前释放所有内存
                printf("再见！\n");
                break;
            default: printf("无效选择！\n"); break;
        }
    }
    while (choice != 0);

    return 0;
}
