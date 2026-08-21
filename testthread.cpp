#include "testthread.h"

TestThread::TestThread(int itemNum, const QString &command, QObject *parent)
    : QThread(parent)
    , m_itemNum(itemNum)
    , m_command(command)
{
}

TestThread::~TestThread()
{
}

void TestThread::run()
{
    if (m_itemNum == 99) {
        qDebug() << "[Manual Thread] Executing:" << m_command;
        if (!m_command.isEmpty()) {
            QProcess::execute(m_command);
        }
        return;
    }

    if (m_command.isEmpty()) {
        emit testFinished(m_itemNum, false);
        return;
    }

    qDebug() << "[Auto Thread Start] Row:" << m_itemNum << "Cmd:" << m_command;

    QProcess process;
    process.start("bash", QStringList() << "-c" << m_command);
    process.waitForFinished(-1);

    int exitCode = process.exitCode();
    QProcess::ExitStatus exitStatus = process.exitStatus();

    bool isSuccess = (exitStatus == QProcess::NormalExit && exitCode == 0);

    qDebug() << "[Auto Thread Done] Row:" << m_itemNum 
             << "ExitCode:" << exitCode 
             << "Result:" << (isSuccess ? "PASS" : "FAIL");

    emit testFinished(m_itemNum, isSuccess);
}