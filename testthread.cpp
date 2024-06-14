#include "testthread.h"
#include <QProcess>
#include <QFileInfo>
#include "QDebug"
#include "string.h"

TestThread::TestThread(int itemnum,const char *command,Ui::MainWindow *ui,QWidget *parent):m_ItemNum(itemnum),m_command(command),ui(ui)
{

}

void TestThread::run()
{
        int status =0;
        const char *hdmiincommand = "sudo sh /opt/armsomtest/shell/hdmiin.sh";
        if (strcmp(m_command,hdmiincommand))
        {
            status = system(m_command);
        }

        if(m_ItemNum == 99) //99表示人工测试
        {
            qDebug()<<"HDMIIN TEST======";//打印出读取的信息
        }
        else
        {
            if(status)
            {
               ui->tableWidget->setItem(m_ItemNum,3,new QTableWidgetItem("不通过"));
               ui->tableWidget->item(m_ItemNum, 0)->setBackgroundColor(Qt::red);//faild red
               ui->tableWidget->item(m_ItemNum, 1)->setBackgroundColor(Qt::red);
               ui->tableWidget->item(m_ItemNum, 2)->setBackgroundColor(Qt::red);
               ui->tableWidget->item(m_ItemNum, 3)->setBackgroundColor(Qt::red);
            }
            else   //0 is sucess
            {
               ui->tableWidget->setItem(m_ItemNum,3,new QTableWidgetItem("通过"));
               ui->tableWidget->item(m_ItemNum, 0)->setBackgroundColor(Qt::green);//faild red;//sucess green
               ui->tableWidget->item(m_ItemNum, 1)->setBackgroundColor(Qt::green);
               ui->tableWidget->item(m_ItemNum, 2)->setBackgroundColor(Qt::green);
               ui->tableWidget->item(m_ItemNum, 3)->setBackgroundColor(Qt::green);
            }
        }
}





