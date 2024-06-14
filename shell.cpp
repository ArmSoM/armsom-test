#include "shell.h"
#include <QProcess>
#include "QDebug"
#include "QDateTime"
#include "QDir"

execshell::execshell()
{

}


//执行su命令 execute 无返回
void execshell::setExecute(QString execute){
    qDebug()<<execute;//打印出读取的信息
    QProcess::execute(execute);
}

void execshell::setStartExecute(QString execute){
    qDebug()<<execute;//打印出读取的信息
    QProcess *openProcess = new QProcess();    //新建一个process进程
    //设置process输出的输出模式 setReadChannel
    openProcess->setReadChannelMode(QProcess::MergedChannels);
    //开始执行
    openProcess->start(execute);
    //等待系统调度
    openProcess->waitForStarted();
}

//执行su命令并返回内容
QString execshell::getExecute(QString execute){
    qDebug()<<execute;//打印出读取的信息
    //源文件
    QProcess process;
    process.start(execute);//输入命令
    process.waitForFinished();//执行命令
    QString output = process.readAllStandardOutput();//读取返回
    qDebug()<<"output======"<<output;//打印出读取的信息
    process.close();
    return output;
}
