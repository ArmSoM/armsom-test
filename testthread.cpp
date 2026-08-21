#include "testthread.h"
#include <QProcess>
#include <QDebug>

TestThread::TestThread(int itemNum, const QString &command, QObject *parent)
    : QThread(parent)
    , m_itemNum(itemNum)
    , m_command(command)
{
}

void TestThread::run()
{
    // 如果是人工测试项（例如约定 99 或 MANUAL_TESTING），仅执行命令拉起窗口/测试，无需刷新自动表格
    if (m_itemNum == 99) {
        qDebug() << "Executing manual test command:" << m_command;
        if (!m_command.isEmpty()) {
            QProcess::execute(m_command);
        }
        return;
    }

    // 自动化测试项
    if (m_command.isEmpty()) {
        emit testFinished(m_itemNum, false);
        return;
    }

    // 使用 QProcess::execute 同步执行系统命令，获取 exitCode (0 为 Success/Pass)
    int exitCode = QProcess::execute(m_command);
    bool isSuccess = (exitCode == 0);

    // 发射信号告知主线程测试结果，由主线程在 UI 层面刷新文字与颜色
    emit testFinished(m_itemNum, isSuccess);
}