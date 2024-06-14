#ifndef TESTTHREAD_H
#define TESTTHREAD_H

#include <QThread>
#include "mainwindow.h"
#include "ui_mainwindow.h"
class MainWindow;

#define SHELL       0
#define COMMAM      1

class TestThread : public QThread
{
public:
    TestThread(int itemnum,const char *command,Ui::MainWindow *ui,QWidget *parent = nullptr);

    int m_ItemNum;
    const char * m_command;
    Ui::MainWindow * ui;

private:

protected:
    void run();
private slots:

};


#endif // TESTTHREAD_H
