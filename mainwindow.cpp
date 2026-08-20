#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "testthread.h"
#include "camerawindow.h"

#include <iostream>
#include <QtWidgets/QHBoxLayout>
#include <QTableWidget>
#include <QTableWidgetItem>
#include <QProcess>
#include <QTimer>
#include <QFile>
#include <QTextStream>
#include <QDebug>
#include <QPixmap>

// --- 数据结构定义 ---
enum TestType {
    AUTO_TEST,  // 自动测试
    MANUAL_TEST // 人工测试
};

struct TestItem {
    QString name;            // 测试项名称
    TestType type;           // 测试类型
    const char* passSlot;    // 通过按钮绑定的槽函数
    const char* failSlot;    // 失败按钮绑定的槽函数
};

// 预声明辅助函数
int getBoardCondition();
QList<TestItem> getTestListByBoard(int condition);

// --- MainWindow 实现 ---
MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    initUI();

    timer = new QTimer(this);
    timer->stop();
    connect(timer, SIGNAL(timeout()), this, SLOT(cameraCapture()));
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
    delete UsbThread;
    delete TfcardThread;
    delete RtcThread;
    delete CameraThread;
    delete AudioThread;
    delete PinThread;
    delete ui;
}

void MainWindow::initUI()
{
    // 1. 获取当前板卡的 condition 值
    int condition = getBoardCondition();

    // 2. 根据 condition 显示对应的板卡图片
    switch (condition) {
        case 1:
            ui->label_2->setPixmap(QPixmap(":/images/armsom-cm5-io.png"));
            break;
        case 2:
        case 3:
        default:
            ui->label_2->setPixmap(QPixmap(":/images/armsom-sige7.png"));
            break;
    }

    // 3. 设置表格样式与属性
    ui->tableWidget->setGeometry(650, 67, 450, 560);
    ui->tableWidget->setColumnCount(4);
    ui->tableWidget->horizontalHeader()->setFixedHeight(40);
    ui->tableWidget->horizontalHeader()->setStretchLastSection(true);
    ui->tableWidget->horizontalHeader()->setSectionsClickable(false);

    // 设置表头内容
    QStringList header = {"序号", "测试项", "测试类别", "测试状态"};
    ui->tableWidget->setHorizontalHeaderLabels(header);

    // 设置表头字体和背景色
    QFont font = ui->tableWidget->horizontalHeader()->font();
    font.setBold(true);
    ui->tableWidget->horizontalHeader()->setFont(font);
    ui->tableWidget->horizontalHeader()->setStyleSheet("QHeaderView::section{background:skyblue;}");

    // 设置列宽策略
    ui->tableWidget->setColumnWidth(0, 60);
    ui->tableWidget->horizontalHeader()->setSectionResizeMode(1, QHeaderView::Stretch);
    ui->tableWidget->horizontalHeader()->setSectionResizeMode(2, QHeaderView::Stretch);
    ui->tableWidget->horizontalHeader()->setSectionResizeMode(3, QHeaderView::Stretch);

    ui->tableWidget->verticalHeader()->setDefaultSectionSize(37);
    ui->tableWidget->verticalHeader()->setVisible(false);
    ui->tableWidget->setEditTriggers(QAbstractItemView::NoEditTriggers);

    // 4. 动态生成测试表格数据与按钮
    initTestTable(condition);
}

void MainWindow::initTestTable(int condition)
{
    QList<TestItem> testList = getTestListByBoard(condition);
    ui->tableWidget->setRowCount(testList.size());

    for (int i = 0; i < testList.size(); ++i) {
        const TestItem &item = testList[i];

        // 1. 第 0 列：序号 (自动居中)
        QTableWidgetItem *itemNum = new QTableWidgetItem(QString::number(i + 1));
        itemNum->setTextAlignment(Qt::AlignCenter);
        ui->tableWidget->setItem(i, 0, itemNum);

        // 2. 第 1 列：测试项目名称
        ui->tableWidget->setItem(i, 1, new QTableWidgetItem(item.name));

        // 3. 根据类型填充第 2 列和第 3 列
        if (item.type == AUTO_TEST) {
            ui->tableWidget->setItem(i, 2, new QTableWidgetItem("自动测试"));
            ui->tableWidget->setItem(i, 3, new QTableWidgetItem(""));
        } 
        else if (item.type == MANUAL_TEST) {
            // “通过”按钮
            QPushButton *passBtn = new QPushButton("通过", this);
            passBtn->setEnabled(false);
            if (item.passSlot) {
                connect(passBtn, SIGNAL(clicked()), this, item.passSlot);
            }
            ui->tableWidget->setCellWidget(i, 2, passBtn);

            // “不通过”按钮
            QPushButton *failBtn = new QPushButton("不通过", this);
            failBtn->setEnabled(false);
            if (item.failSlot) {
                connect(failBtn, SIGNAL(clicked()), this, item.failSlot);
            }
            ui->tableWidget->setCellWidget(i, 3, failBtn);
        }
    }
}

void MainWindow::on_pass_clicked(int item, QString string)
{
    QColor bgColor = (string == "通过") ? Qt::green : Qt::red;

    ui->tableWidget->setItem(item, 3, new QTableWidgetItem(string));
    for (int col = 0; col < 4; ++col) {
        if (ui->tableWidget->item(item, col)) {
            ui->tableWidget->item(item, col)->setBackgroundColor(bgColor);
        }
    }
}

void MainWindow::on_TestButton_clicked()
{
    ui->TestButton->setEnabled(false);

    // 触发各类自动化脚本测试
    const char *command = "sudo sh /opt/armsomtest/shell/wifi.sh";
    WifiThread = new TestThread(4, command, ui, this);
    WifiThread->start();

    command = "sudo sh /opt/armsomtest/shell/bt.sh";
    BtThread = new TestThread(5, command, ui, this);
    BtThread->start();

    command = "sudo sh /opt/armsomtest/shell/eth.sh";
    Ethhread = new TestThread(3, command, ui, this);
    Ethhread->start();

    command = "sudo sh /opt/armsomtest/shell/M2.sh";
    M2Thread = new TestThread(8, command, ui, this);
    M2Thread->start();

    command = "sudo sh /opt/armsomtest/shell/typec.sh";
    TypecThread = new TestThread(1, command, ui, this);
    TypecThread->start();

    command = "sudo sh /opt/armsomtest/shell/usb.sh";
    UsbThread = new TestThread(0, command, ui, this);
    UsbThread->start();

    command = "sudo sh /opt/armsomtest/shell/tfcard.sh";
    TfcardThread = new TestThread(7, command, ui, this);
    TfcardThread->start();

    command = "sudo sh /opt/armsomtest/shell/rtc.sh";
    RtcThread = new TestThread(6, command, ui, this);
    RtcThread->start();

    command = "sudo sh /opt/armsomtest/shell/camera.sh";
    CameraThread = new TestThread(9, command, ui, this);
    CameraThread->start();

    if (ok) timer->start(33);
    else timer->stop();
    ok = !ok;

    command = "sudo sh /opt/armsomtest/shell/audio.sh";
    AudioThread = new TestThread(MANUAL_TESTING, command, ui, this);
    AudioThread->start();

    command = "sudo sh /opt/armsomtest/shell/gpio40.sh";
    PinThread = new TestThread(MANUAL_TESTING, command, ui, this);
    PinThread->start();
}

// 单项手动测试按钮触发槽函数
void MainWindow::on_TYPEC_Button_clicked()
{
    const char *command = "sudo sh /opt/armsomtest/shell/typec.sh";
    TestThread * TypecThread = new TestThread(4, command, ui);
    TypecThread->start();
}

void MainWindow::on_usbButton_clicked()
{
    const char *command = "sudo sh /opt/armsomtest/shell/usb.sh";
    TestThread * UsbThread = new TestThread(6, command, ui);
    UsbThread->start();
}

void MainWindow::on_tfcard_Button_clicked()
{
    const char *command = "sudo sh /opt/armsomtest/shell/tfcard.sh";
    TestThread * TfcardThread = new TestThread(7, command, ui);
    TfcardThread->start();
}

void MainWindow::on_hdmiin_Button_clicked()
{
    const char *command = "sudo sh /opt/armsomtest/shell/hdmiin.sh";
    TestThread * HdmiinThread = new TestThread(MANUAL_TESTING, command, ui);
    HdmiinThread->start();
}

void MainWindow::on_Audio_Button_clicked()
{
    const char *command = "sudo sh /opt/armsomtest/shell/audio.sh";
    TestThread * AudioThread = new TestThread(MANUAL_TESTING, command, ui);
    AudioThread->start();
}

void MainWindow::on_PIN_Button_clicked()
{
    const char *command = "sudo sh /opt/armsomtest/shell/armsom-w3-gpio40.sh";
    TestThread * PinThread = new TestThread(MANUAL_TESTING, command, ui);
    PinThread->start();
}

// --- 板卡型号获取与配置 ---
int getBoardCondition()
{
    QFile file("/proc/device-tree/compatible");
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "无法读取设备树文件，使用默认条件";
        return -1;
    }

    QByteArray data = file.readAll();
    file.close();

    QString firstCompatible = QString::fromUtf8(data.split('\0').first());
    QString boardId;

    if (firstCompatible.contains(',')) {
        QString afterComma = firstCompatible.section(',', 1);
        boardId = afterComma.section('-', 1);
    } else {
        boardId = firstCompatible;
    }

    qDebug() << "解析得到的 BOARD_ID:" << boardId;

    if (boardId == "armsom-cm5-io") {
        return 1;
    } else if (boardId == "armsom-sige7") {
        return 2;
    } else if (boardId == "armsom-p2pro") {
        return 3;
    } else {
        return 0;
    }
}

QList<TestItem> getTestListByBoard(int condition)
{
    QList<TestItem> items;

    switch (condition) {
        case 1: // armsom-cm5-io
            items = {
                {"USB测试",    AUTO_TEST,   nullptr, nullptr},
                {"网口测试",      AUTO_TEST,   nullptr, nullptr},
                {"WIFI测试",      AUTO_TEST,   nullptr, nullptr},
                {"BT测试",        AUTO_TEST,   nullptr, nullptr},
                {"RTC测试",       AUTO_TEST,   nullptr, nullptr},
                {"TFCARD测试",    AUTO_TEST,   nullptr, nullptr},
                {"M.2接口测试",   AUTO_TEST,   nullptr, nullptr},
                {"Camera测试",    AUTO_TEST,   nullptr, nullptr},
                {"音频测试",      MANUAL_TEST, SLOT(on_audiopass_clicked()),   SLOT(on_audiofaild_clicked())},
                {"MIPI屏测试",    MANUAL_TEST, SLOT(on_mipipass_clicked()),    SLOT(on_mipifaild_clicked())},
                {"HDMIIN测试",    MANUAL_TEST, SLOT(on_hdmiinpass_clicked()),  SLOT(on_hdmiinfaild_clicked())},
                {"40PIN测试",     MANUAL_TEST, SLOT(on_pinpass_clicked()),     SLOT(on_pinfaild_clicked())}
            };
            break;

        case 2: // armsom-sige7
            items = {
                {"USB测试",    AUTO_TEST,   nullptr, nullptr},
                {"网口测试",      AUTO_TEST,   nullptr, nullptr},
                {"WIFI测试",      AUTO_TEST,   nullptr, nullptr},
                {"BT测试",        AUTO_TEST,   nullptr, nullptr},
                {"RTC测试",       AUTO_TEST,   nullptr, nullptr},
                {"TFCARD测试",    AUTO_TEST,   nullptr, nullptr},
                {"音频测试",      MANUAL_TEST, SLOT(on_audiopass_clicked()),   SLOT(on_audiofaild_clicked())},
                {"40PIN测试",     MANUAL_TEST, SLOT(on_pinpass_clicked()),     SLOT(on_pinfaild_clicked())}
            };
            break;

        default: // 默认未知板卡配置
            items = {
                {"USB3测试",    AUTO_TEST,   nullptr, nullptr},
                {"网口测试",      AUTO_TEST,   nullptr, nullptr},
                {"RTC测试",       AUTO_TEST,   nullptr, nullptr}
            };
            break;
    }

    return items;
}