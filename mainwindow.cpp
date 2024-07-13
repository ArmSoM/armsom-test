#include "mainwindow.h"
#include "ui_mainwindow.h"
#include"testthread.h"

#include "camerawindow.h"

#include <iostream>

#include <QtWidgets/QHBoxLayout>
#include<QTableWidget>>
#include<QTableWidgetItem>

#include <QProcess>
#include <QTimer>
#include <QFile>


MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    const char * string;
    initUI();

    timer = new QTimer(this);
    timer->stop();
    connect(timer, SIGNAL(timeout()), this, SLOT(cameraCapture()));  // 时间到，读取当前摄像头信息
    ok = true;
}

MainWindow::~MainWindow()
{  
    ui->tableWidget->clearContents();
    delete WifiThread;
    delete BtThread;
    delete Ethhread;
    delete M2Thread;
    delete TypecThread;
    delete Usb20Thread;
    delete Usb30Thread;
    delete TfcardThread;
    delete RtcThread;
    delete CameraThread;
    delete AudioThread;
    delete PinThread;
    //camerathread->requestInterruption();
    //camerathread->wait();
    delete ui;
}

void  MainWindow::initUI()
{
        //QPixmap armsommap(":///images/armsom.png");
        //ui->pushButton->setIcon(QIcon(armsommap));
       // 设置表格的位置和尺寸大小
       //ui->tableWidget->setGeometry(180, 80, 450, 532);
       ui->tableWidget->setGeometry(650, 67, 450, 560);
       ui->tableWidget->setRowCount(14);     //15行
       ui->tableWidget->setColumnCount(4);   //3列

       //设置等宽
       //ui->tableWidget->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);

       //设列的宽度
       //ui->tableWidget->horizontalHeader()->setDefaultSectionSize(300);

        //设置表头的高度
       ui->tableWidget->horizontalHeader()->setFixedHeight(40);

       //设置每一行最后一个单元格不留空格
       ui->tableWidget->horizontalHeader()->setStretchLastSection(true);

       //设置表头不可点击（默认点击后进行排序）
       ui->tableWidget->horizontalHeader()-> setSectionsClickable(false);


       //设置表头内容
       QStringList header;
       header.append("序号");
       header.append("测试项");
       header.append("测试类别");
       header.append("测试状态");
       ui->tableWidget->setHorizontalHeaderLabels(header);

       //设置字体
       QFont font = ui->tableWidget->horizontalHeader()->font(); //获取表头原来的字体
       font.setBold(true);//字体设置粗体
       ui->tableWidget->horizontalHeader()->setFont(font);

       //通过样式表，设置表头背景色
       ui->tableWidget->horizontalHeader()->setStyleSheet("QHeaderView::section{background:skyblue;}");

       //设置列宽策略，使列自适应宽度，所有列平均分来填充空白部分
       ui->tableWidget->setColumnWidth(0,60);
        ui->tableWidget->horizontalHeader()->setSectionResizeMode(1, QHeaderView::Stretch);
        ui->tableWidget->horizontalHeader()->setSectionResizeMode(2, QHeaderView::Stretch);
        ui->tableWidget->horizontalHeader()->setSectionResizeMode(3, QHeaderView::Stretch);

       ui->tableWidget->verticalHeader()->setDefaultSectionSize(37); //设置处垂直方向高度
       //ui->tableWidget->setFrameShape(QFrame::NoFrame); //设置无边框
       //ui->tableWidget->setShowGrid(false); //设置不显示格子线

       //设置表格中每一行的表头
       //ui->tableWidget->setHorizontalHeaderLabels(QStringList()<<"测试项"<<"测试类别"<<"测试状态");//水平
       //ui->tableWidget->setVerticalHeaderLabels(QStringList()<<"1"<<"2"); //垂直
       //ui->tableWidget->horizontalHeader()->setVisible(false);//是否显示水平表头
       ui->tableWidget->verticalHeader()->setVisible(false);//是否显示垂直表头

       //设置表格数据区内的所有单元格都不允许编辑
       ui->tableWidget->setEditTriggers(QAbstractItemView::NoEditTriggers);

       //设置表格中每一行的内容
       ui->tableWidget->setItem(0,0,new QTableWidgetItem("1"));
       //ui->tableWidget->item(0,0)->setTextAlignment(Qt::AlignHCenter|Qt::AlignVCenter);
       ui->tableWidget->setItem(0,1,new QTableWidgetItem("USB3.0测试"));
       ui->tableWidget->setItem(0,2,new QTableWidgetItem("自动测试"));
       ui->tableWidget->setItem(0,3,new QTableWidgetItem(""));
       ui->tableWidget->setItem(1,0,new QTableWidgetItem("2"));
       //ui->tableWidget->setItem(1,1,new QTableWidgetItem("Type-C测试"));
       ui->tableWidget->setItem(1,2,new QTableWidgetItem("自动测试"));
       ui->tableWidget->setItem(1,3,new QTableWidgetItem(""));
       ui->tableWidget->setItem(2,0,new QTableWidgetItem("3"));
       ui->tableWidget->setItem(2,1,new QTableWidgetItem("USB2.0测试"));
       ui->tableWidget->setItem(2,2,new QTableWidgetItem("自动测试"));
       ui->tableWidget->setItem(2,3,new QTableWidgetItem(""));
       ui->tableWidget->setItem(3,0,new QTableWidgetItem("4"));
       ui->tableWidget->setItem(3,1,new QTableWidgetItem("网口测试"));
       ui->tableWidget->setItem(3,2,new QTableWidgetItem("自动测试"));
       ui->tableWidget->setItem(3,3,new QTableWidgetItem(""));
       ui->tableWidget->setItem(4,0,new QTableWidgetItem("5"));
       ui->tableWidget->setItem(4,1,new QTableWidgetItem("WIFI测试"));
       ui->tableWidget->setItem(4,2,new QTableWidgetItem("自动测试"));
       ui->tableWidget->setItem(4,3,new QTableWidgetItem(""));
       ui->tableWidget->setItem(5,0,new QTableWidgetItem("5"));
       ui->tableWidget->setItem(5,1,new QTableWidgetItem("BT测试"));
       ui->tableWidget->setItem(5,2,new QTableWidgetItem("自动测试"));
       ui->tableWidget->setItem(5,3,new QTableWidgetItem(""));
       ui->tableWidget->setItem(6,0,new QTableWidgetItem("6"));
       ui->tableWidget->setItem(6,1,new QTableWidgetItem("RTC测试"));
       ui->tableWidget->setItem(6,2,new QTableWidgetItem("自动测试"));
       ui->tableWidget->setItem(6,3,new QTableWidgetItem(""));
       ui->tableWidget->setItem(7,0,new QTableWidgetItem("7"));
       ui->tableWidget->setItem(7,1,new QTableWidgetItem("TFCARD测试"));
       ui->tableWidget->setItem(7,2,new QTableWidgetItem("自动测试"));
       ui->tableWidget->setItem(7,3,new QTableWidgetItem(""));
       ui->tableWidget->setItem(8,0,new QTableWidgetItem("8"));
       ui->tableWidget->setItem(8,1,new QTableWidgetItem("ap6275测试"));
       ui->tableWidget->setItem(8,2,new QTableWidgetItem("自动测试"));
       ui->tableWidget->setItem(8,3,new QTableWidgetItem(""));
       ui->tableWidget->setItem(9,0,new QTableWidgetItem("9"));
       //ui->tableWidget->setItem(9,1,new QTableWidgetItem("Camera测试"));
       ui->tableWidget->setItem(9,2,new QTableWidgetItem("自动测试"));
       ui->tableWidget->setItem(9,3,new QTableWidgetItem(""));
       ui->tableWidget->setItem(10,0,new QTableWidgetItem("10"));
       ui->tableWidget->setItem(10,1,new QTableWidgetItem("音频测试"));
       ui->tableWidget->setItem(10,2,new QTableWidgetItem("人工测试"));
       ui->tableWidget->setItem(10,3,new QTableWidgetItem(""));
       ui->tableWidget->setItem(11,0,new QTableWidgetItem("11"));
       ui->tableWidget->setItem(11,1,new QTableWidgetItem("MIPI屏测试"));
       ui->tableWidget->setItem(11,2,new QTableWidgetItem("人工测试"));
       ui->tableWidget->setItem(11,3,new QTableWidgetItem(""));
       ui->tableWidget->setItem(12,0,new QTableWidgetItem("12"));
       ui->tableWidget->setItem(12,1,new QTableWidgetItem("HDMIIN测试"));
       ui->tableWidget->setItem(12,2,new QTableWidgetItem("人工测试"));
       ui->tableWidget->setItem(12,3,new QTableWidgetItem(""));
       ui->tableWidget->setItem(13,0,new QTableWidgetItem("13"));
       ui->tableWidget->setItem(13,1,new QTableWidgetItem("40PIN测试"));
       ui->tableWidget->setItem(13,2,new QTableWidgetItem("人工测试"));
       ui->tableWidget->setItem(13,3,new QTableWidgetItem(""));

       for (int i =0;i<14;i++)
       {
           ui->tableWidget->item(i,0)->setTextAlignment(Qt::AlignHCenter|Qt::AlignVCenter);
       }

       // 人工测试添加按钮
       //Audio
       Audio_pass_bt = new QPushButton(this);
       Audio_pass_bt->setText("通过");
       Audio_pass_bt->setEnabled(false);
       connect(Audio_pass_bt,SIGNAL(clicked()),this,SLOT(on_audiopass_clicked()));  // 添加  按钮 点击处理
       ui->tableWidget->setCellWidget(10,2,Audio_pass_bt);


       Audio_faild_bt = new QPushButton(this);
       Audio_faild_bt->setText("不通过");
       Audio_faild_bt->setEnabled(false);
       connect(Audio_faild_bt,SIGNAL(clicked()),this,SLOT(on_audiofaild_clicked()));  // 添加  按钮 点击处理
       ui->tableWidget->setCellWidget(10,3,Audio_faild_bt);

       //MIPI-DSI
       Mipi_pass_bt = new QPushButton(this);
       Mipi_pass_bt->setText("通过");
       Mipi_pass_bt->setEnabled(false);
       connect(Mipi_pass_bt,SIGNAL(clicked()),this,SLOT(on_mipipass_clicked()));  // 添加  按钮 点击处理
       ui->tableWidget->setCellWidget(11,2,Mipi_pass_bt);


       Mipi_faild_bt = new QPushButton(this);
       Mipi_faild_bt->setText("不通过");
       Mipi_faild_bt->setEnabled(false);
       connect(Mipi_faild_bt,SIGNAL(clicked()),this,SLOT(on_mipifaild_clicked()));  // 添加  按钮 点击处理
       ui->tableWidget->setCellWidget(11,3,Mipi_faild_bt);

       //Hdmiin
       Hdmiin_pass_bt = new QPushButton(this);
       Hdmiin_pass_bt->setText("通过");
       Hdmiin_pass_bt->setEnabled(false);
       connect(Hdmiin_pass_bt,SIGNAL(clicked()),this,SLOT(on_hdmiinpass_clicked()));  // 添加  按钮 点击处理
       ui->tableWidget->setCellWidget(12,2,Hdmiin_pass_bt);


       Hdmiin_faild_bt = new QPushButton(this);
       Hdmiin_faild_bt->setText("不通过");
       Hdmiin_faild_bt->setEnabled(false);
       connect(Hdmiin_faild_bt,SIGNAL(clicked()),this,SLOT(on_hdmiinfaild_clicked()));  // 添加  按钮 点击处理
       ui->tableWidget->setCellWidget(12,3,Hdmiin_faild_bt);

       //40PIN
       Pin_pass_bt = new QPushButton(this);
       Pin_pass_bt->setText("通过");
       Pin_pass_bt->setEnabled(false);
       connect(Pin_pass_bt,SIGNAL(clicked()),this,SLOT(on_pinpass_clicked()));  // 添加  按钮 点击处理
       ui->tableWidget->setCellWidget(13,2,Pin_pass_bt);


       Pin_faild_bt = new QPushButton(this);
       Pin_faild_bt->setText("不通过");
       Pin_faild_bt->setEnabled(false);
       connect(Pin_faild_bt,SIGNAL(clicked()),this,SLOT(on_pinfaild_clicked()));  // 添加  按钮 点击处理
       ui->tableWidget->setCellWidget(13,3,Pin_faild_bt);

}

void MainWindow::on_pass_clicked(int item,QString string)
{
    if(string == QString::fromLocal8Bit("通过"))
    {
        ui->tableWidget->setItem(item,3,new QTableWidgetItem(string));
        ui->tableWidget->item(item, 0)->setBackgroundColor(Qt::green);
        ui->tableWidget->item(item, 1)->setBackgroundColor(Qt::green);//faild red;//sucess green
        ui->tableWidget->item(item, 2)->setBackgroundColor(Qt::green);
        ui->tableWidget->item(item, 3)->setBackgroundColor(Qt::green);
    }
    else if(string == QString::fromLocal8Bit("不通过"))
    {
        ui->tableWidget->setItem(item,3,new QTableWidgetItem(string));
        ui->tableWidget->item(item, 0)->setBackgroundColor(Qt::red);
        ui->tableWidget->item(item, 1)->setBackgroundColor(Qt::red);//faild red;//sucess green
        ui->tableWidget->item(item, 2)->setBackgroundColor(Qt::red);
        ui->tableWidget->item(item, 3)->setBackgroundColor(Qt::red);
    }
    else
    {
        ;
    }

}

void MainWindow::on_audiopass_clicked()
{
    Audio_pass_bt->setVisible(false);
    Audio_pass_bt->setEnabled(false);
    Audio_faild_bt->setVisible(false);
    Audio_faild_bt->setEnabled(false);
    QString string = "通过";
    on_pass_clicked(10,string);
}

void MainWindow::on_audiofaild_clicked()
{
    Audio_pass_bt->setVisible(false);
    Audio_pass_bt->setEnabled(false);
    Audio_faild_bt->setVisible(false);
    Audio_faild_bt->setEnabled(false);
    QString string = "不通过";
    on_pass_clicked(10,string);
}

void MainWindow::on_mipipass_clicked()
{
    Mipi_pass_bt->setVisible(false);
    Mipi_pass_bt->setEnabled(false);
    Mipi_faild_bt->setVisible(false);
    Mipi_faild_bt->setEnabled(false);
    QString string = "通过";
    on_pass_clicked(11,string);
}

void MainWindow::on_mipifaild_clicked()
{
    Mipi_pass_bt->setVisible(false);
    Mipi_pass_bt->setEnabled(false);
    Mipi_faild_bt->setVisible(false);
    Mipi_faild_bt->setEnabled(false);
    QString string = "不通过";
    on_pass_clicked(11,string);
}

void MainWindow::on_hdmiinpass_clicked()
{
    //Hdmiin_pass_bt->setStyleSheet("background-color:rgb(0,255,0)");  //button set color
    Hdmiin_pass_bt->setVisible(false);
    Hdmiin_pass_bt->setEnabled(false);
    Hdmiin_faild_bt->setVisible(false);
    Hdmiin_faild_bt->setEnabled(false);
    QString string = "通过";
    on_pass_clicked(12,string);
}

void MainWindow::on_hdmiinfaild_clicked()
{
    Hdmiin_pass_bt->setVisible(false);
    Hdmiin_pass_bt->setEnabled(false);
    Hdmiin_faild_bt->setVisible(false);
    Hdmiin_faild_bt->setEnabled(false);
    QString string = "不通过";
    on_pass_clicked(12,string);
}

void MainWindow::on_pinpass_clicked()
{
    Pin_pass_bt->setVisible(false);
    Pin_pass_bt->setEnabled(false);
    Pin_faild_bt->setVisible(false);
    Pin_faild_bt->setEnabled(false);
    QString string = "通过";
    on_pass_clicked(13,string);
}

void MainWindow::on_pinfaild_clicked()
{
    Pin_pass_bt->setVisible(false);
    Pin_pass_bt->setEnabled(false);
    Pin_faild_bt->setVisible(false);
    Pin_faild_bt->setEnabled(false);
    QString string = "不通过";
    on_pass_clicked(13,string);
}


void MainWindow::on_TestButton_clicked()
{
    ui->TestButton->setEnabled(false);
    // 设置表格的位置和尺寸大小
    //ui->tableWidget->setGeometry(180, 80, 450, 532);
    //const char * string;
    //camerathread = new CameraThread(0,string,ui,this);


    Audio_pass_bt->setEnabled(true);
    Audio_faild_bt->setEnabled(true);
    Mipi_pass_bt->setEnabled(true);
    Mipi_faild_bt->setEnabled(true);
    Hdmiin_pass_bt->setEnabled(true);
    Hdmiin_faild_bt->setEnabled(true);
    Pin_pass_bt->setEnabled(true);
    Pin_faild_bt->setEnabled(true);

    const char *command = "sudo sh /opt/armsomtest/shell/wifi.sh";
    WifiThread = new TestThread(4,command,ui,this);
    WifiThread->start();

    command = "sudo sh /opt/armsomtest/shell/bt.sh";
    BtThread = new TestThread(5,command,ui,this);
    BtThread->start();

    command = "sudo sh /opt/armsomtest/shell/eth.sh";
    Ethhread = new TestThread(3,command,ui,this);
    Ethhread->start();

    command = "sudo sh /opt/armsomtest/shell/M2.sh";
    M2Thread = new TestThread(8,command,ui,this);
    M2Thread->start();

    command = "sudo sh /opt/armsomtest/shell/typec.sh";
    TypecThread = new TestThread(1,command,ui,this);
    TypecThread->start();

    command = "sudo sh /opt/armsomtest/shell/usb2.sh";
    Usb20Thread = new TestThread(2,command,ui,this);
    Usb20Thread->start();

    command = "sudo sh /opt/armsomtest/shell/usb3.sh";
    Usb30Thread = new TestThread(0,command,ui,this);
    Usb30Thread->start();

    command = "sudo sh /opt/armsomtest/shell/tfcard.sh";
    TfcardThread = new TestThread(7,command,ui,this);
    TfcardThread->start();

    command = "sudo sh /opt/armsomtest/shell/rtc.sh";
    RtcThread = new TestThread(6,command,ui,this);
    RtcThread->start();

    command = "sudo sh /opt/armsomtest/shell/camera.sh";
    CameraThread = new TestThread(9,command,ui,this);
    CameraThread->start();

    if(ok)timer->start(33);
    else timer->stop();
    ok = !ok;

    command = "sudo sh /opt/armsomtest/shell/audio.sh";
    AudioThread = new TestThread(MANUAL_TESTING,command,ui,this);
    AudioThread->start();

    command = "sudo sh /opt/armsomtest/shell/armsom-w3-gpio40.sh";
    PinThread = new TestThread(MANUAL_TESTING,command,ui,this);
    PinThread->start();

}



void MainWindow::on_pass_Button_clicked()
{
    QString str = Qshell.getExecute("sudo ifconfig");
}


void MainWindow::on_WIFI_Button_clicked()
{
    const char *command = "sudo sh /opt/armsomtest/shell/wifi.sh";
    TestThread * WifiThread = new TestThread(0,command,ui);
    WifiThread->start();
}

void MainWindow::on_BT_Button_clicked()
{
    const char *command = "sudo sh /opt/armsomtest/shell/bt.sh";
    TestThread * BtThread = new TestThread(1,command,ui);
    BtThread->start();
}

void MainWindow::on_eth_Button_clicked()
{
    const char *command = "sudo sh /opt/armsomtest/shell/eth.sh";
    TestThread * Ethhread = new TestThread(2,command,ui);
    Ethhread->start();
}


void MainWindow::on_M2_Button_clicked()
{
    const char *command = "sudo sh /opt/armsomtest/shell/M2.sh";
    TestThread * M2Thread = new TestThread(3,command,ui);
    M2Thread->start();
}

void MainWindow::on_TYPEC_Button_clicked()
{
    const char *command = "sudo sh /opt/armsomtest/shell/typec.sh";
    TestThread * TypecThread = new TestThread(4,command,ui);
    TypecThread->start();
}


void MainWindow::on_usb20_Button_clicked()
{
      const char *command = "sudo sh /opt/armsomtest/shell/usb2.sh";
      TestThread * Usb20Thread = new TestThread(5,command,ui);
      Usb20Thread->start();
}

void MainWindow::on_usb30Button_clicked()
{
      const char *command = "sudo sh /opt/armsomtest/shell/usb3.sh";
      TestThread * Usb30Thread = new TestThread(6,command,ui);
      Usb30Thread->start();
}

void MainWindow::on_tfcard_Button_clicked()
{
      const char *command = "sudo sh /opt/armsomtest/shell/tfcard.sh";
      TestThread * TfcardThread = new TestThread(7,command,ui);
      TfcardThread->start();
}

void MainWindow::on_hdmiin_Button_clicked()
{
      const char *command = "sudo sh /opt/armsomtest/shell/hdmiin.sh";
      TestThread * HdmiinThread = new TestThread(MANUAL_TESTING,command,ui);
      HdmiinThread->start();

      Hdmiin_pass_bt->setEnabled(true);
      Hdmiin_faild_bt->setEnabled(true);
}

void MainWindow::on_Audio_Button_clicked()
{
    const char *command = "sudo sh /opt/armsomtest/shell/audio.sh";
    TestThread * AudioThread = new TestThread(MANUAL_TESTING,command,ui);
    AudioThread->start();

    Audio_pass_bt->setEnabled(true);
    Audio_faild_bt->setEnabled(true);
}

void MainWindow::on_PIN_Button_clicked()
{
   const char *command = "sudo sh /opt/armsomtest/shell/armsom-w3-gpio40.sh";
   TestThread * PinThread = new TestThread(MANUAL_TESTING,command,ui);
   PinThread->start();

   Pin_pass_bt->setEnabled(true);
   Pin_faild_bt->setEnabled(true);
}
