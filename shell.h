#ifndef SHELL_H
#define SHELL_H

#include "QString"

class execshell
{
public:
    execshell();

    //执行su命令 execute 无返回
    void setExecute(QString execute);
    //执行su命令并返回内容
    QString getExecute(QString execute);
    //纯异步调用
    void setStartExecute(QString execute);
};

#endif // SHELL_H
