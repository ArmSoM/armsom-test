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
    // 使用 bash -c 显式包裹执行命令
    process.start("bash", QStringList() << "-c" << m_command);
    process.waitForFinished(-1); // 等待脚本彻底执行完毕

    int exitCode = process.exitCode();
    QProcess::ExitStatus exitStatus = process.exitStatus();

    bool isSuccess = (exitStatus == QProcess::NormalExit && exitCode == 0);

    qDebug() << "[Auto Thread Done] Row:" << m_itemNum 
             << "ExitCode:" << exitCode 
             << "Result:" << (isSuccess ? "PASS" : "FAIL");

    emit testFinished(m_itemNum, isSuccess);
}