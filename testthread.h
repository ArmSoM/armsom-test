#ifndef TESTTHREAD_H
#define TESTTHREAD_H

#include <QThread>
#include <QString>
#include <QProcess>
#include <QDebug>

class TestThread : public QThread
{
    Q_OBJECT

public:
    explicit TestThread(int itemNum, const QString &command, QObject *parent = nullptr);
    ~TestThread();

protected:
    void run() override;

signals:
    void testFinished(int itemNum, bool isSuccess);

private:
    int m_itemNum;
    QString m_command;
};

#endif // TESTTHREAD_H