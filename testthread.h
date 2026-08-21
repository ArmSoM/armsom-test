#ifndef TESTTHREAD_H
#define TESTTHREAD_H

#include <QThread>
#include <QString>

class TestThread : public QThread
{
    Q_OBJECT

public:
    // 使用 QString 传值，避免 C 风格指针生命周期导致的野指针问题
    // 移除 UI 指针传参，线程无需了解 UI 结构
    explicit TestThread(int itemNum, const QString &command, QObject *parent = nullptr);

signals:
    // 定义信号：执行完毕后，通知主线程刷新结果 (行号, 是否通过)
    void testFinished(int itemNum, bool isSuccess);

protected:
    void run() override;

private:
    int m_itemNum;
    QString m_command;
};

#endif // TESTTHREAD_H