#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "testthread.h"

#include <QFile>
#include <QDebug>
#include <QTableWidgetItem>
#include <QBrush>
#include <QColor>

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
                {"USB测试",      AUTO_TEST,   "sudo sh /opt/armsomtest/shell/usb.sh",    nullptr, nullptr},
                {"网口测试",     AUTO_TEST,   "sudo sh /opt/armsomtest/shell/eth.sh",    nullptr, nullptr},
                {"WIFI测试",     AUTO_TEST,   "sudo sh /opt/armsomtest/shell/wifi.sh",   nullptr, nullptr},
                {"BT测试",       AUTO_TEST,   "sudo sh /opt/armsomtest/shell/bt.sh",     nullptr, nullptr},
                {"RTC测试",      AUTO_TEST,   "sudo sh /opt/armsomtest/shell/rtc.sh",    nullptr, nullptr},
                {"TFCARD测试",   AUTO_TEST,   "sudo sh /opt/armsomtest/shell/tfcard.sh",  nullptr, nullptr},
                {"M.2接口测试",  AUTO_TEST,   "sudo sh /opt/armsomtest/shell/m2.sh",      nullptr, nullptr},
                {"Camera测试",   AUTO_TEST,   "sudo sh /opt/armsomtest/shell/camera.sh",  nullptr, nullptr},
                {"音频测试",     AUTO_TEST, "sudo sh /opt/armsomtest/shell/audio.sh",nullptr, nullptr},
                {"MIPI屏测试",   MANUAL_TEST, "", SLOT(on_mipipass_clicked()),   nullptr},
                // {"40PIN测试",    MANUAL_TEST, "", SLOT(on_gpiopass_clicked()),    nullptr}
            };
            break;

        case 2: // armsom-sige7
            items = {
                {"USB测试",      AUTO_TEST,   "sudo sh /opt/armsomtest/shell/usb.sh",    nullptr, nullptr},
                {"网口测试",     AUTO_TEST,   "sudo sh /opt/armsomtest/shell/eth.sh",    nullptr, nullptr},
                {"WIFI测试",     AUTO_TEST,   "sudo sh /opt/armsomtest/shell/wifi.sh",   nullptr, nullptr},
                {"BT测试",       AUTO_TEST,   "sudo sh /opt/armsomtest/shell/bt.sh",     nullptr, nullptr},
                {"RTC测试",      AUTO_TEST,   "sudo sh /opt/armsomtest/shell/rtc.sh",    nullptr, nullptr},
                {"TFCARD测试",   AUTO_TEST,   "sudo sh /opt/armsomtest/shell/tfcard.sh",  nullptr, nullptr},
                {"音频测试",     AUTO_TEST, "", nullptr,  nullptr},
                {"40PIN测试",    MANUAL_TEST, "", SLOT(on_gpiopass_clicked()),    nullptr}
            };
            break;

        default: // 默认未知板卡配置
            items = {
                {"USB测试",     AUTO_TEST,   "sudo sh /opt/armsomtest/shell/usb.sh",    nullptr, nullptr},
                {"网口测试",     AUTO_TEST,   "sudo sh /opt/armsomtest/shell/eth.sh",    nullptr, nullptr},
                {"RTC测试",      AUTO_TEST,   "sudo sh /opt/armsomtest/shell/rtc.sh",    nullptr, nullptr}
            };
            break;
    }

    return items;
}

// --- MainWindow 实现 ---
MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    initUI();
}

MainWindow::~MainWindow()
{   
    ui->tableWidget->clearContents();
    delete ui;
}

void MainWindow::initUI()
{
    // 1. 获取并存储 condition
    this->condition = getBoardCondition();

    // 2. 根据 condition 显示对应的板卡图片
    switch (this->condition) {
        case 1:
            ui->label_2->setPixmap(QPixmap(":/images/armsom-cm5-io.png"));
            break;
        case 2:
        case 3:
        default:
            ui->label_2->setPixmap(QPixmap(":/images/armsom-sige7.png"));
            break;
    }

    // 3. 设置表格属性
    ui->tableWidget->setGeometry(650, 67, 450, 560);
    ui->tableWidget->setColumnCount(4);
    ui->tableWidget->horizontalHeader()->setFixedHeight(40);
    ui->tableWidget->horizontalHeader()->setStretchLastSection(true);
    ui->tableWidget->horizontalHeader()->setSectionsClickable(false);

    QStringList header = {"序号", "测试项", "测试类别", "测试状态"};
    ui->tableWidget->setHorizontalHeaderLabels(header);

    QFont font = ui->tableWidget->horizontalHeader()->font();
    font.setBold(true);
    ui->tableWidget->horizontalHeader()->setFont(font);
    ui->tableWidget->horizontalHeader()->setStyleSheet("QHeaderView::section{background:skyblue;}");

    ui->tableWidget->setColumnWidth(0, 60);
    ui->tableWidget->horizontalHeader()->setSectionResizeMode(1, QHeaderView::Stretch);
    ui->tableWidget->horizontalHeader()->setSectionResizeMode(2, QHeaderView::Stretch);
    ui->tableWidget->horizontalHeader()->setSectionResizeMode(3, QHeaderView::Stretch);

    ui->tableWidget->verticalHeader()->setDefaultSectionSize(37);
    ui->tableWidget->verticalHeader()->setVisible(false);
    ui->tableWidget->setEditTriggers(QAbstractItemView::NoEditTriggers);

    // 4. 填充表格内容
    initTestTable(this->condition);
}

void MainWindow::initTestTable(int condition)
{
    QList<TestItem> testList = getTestListByBoard(condition);
    ui->tableWidget->setRowCount(testList.size());

    for (int i = 0; i < testList.size(); ++i) {
        const TestItem &item = testList[i];

        // 第 0 列：序号
        QTableWidgetItem *itemNum = new QTableWidgetItem(QString::number(i + 1));
        itemNum->setTextAlignment(Qt::AlignCenter);
        ui->tableWidget->setItem(i, 0, itemNum);

        // 第 1 列：测试项目名称
        QTableWidgetItem *itemName = new QTableWidgetItem(item.name);
        // 将脚本路径存入 UserRole 绑定的 UserData 中，防止重跑
        itemName->setData(Qt::UserRole, item.scriptPath);
        itemName->setData(Qt::UserRole + 1, static_cast<int>(item.type));
        ui->tableWidget->setItem(i, 1, itemName);

        // 第 2 列 & 第 3 列
        if (item.type == AUTO_TEST) {
            ui->tableWidget->setItem(i, 2, new QTableWidgetItem("自动测试"));
            ui->tableWidget->setItem(i, 3, new QTableWidgetItem("等待测试"));
        } 
        else if (item.type == MANUAL_TEST) {
            QPushButton *passBtn = new QPushButton("通过", this);
            if (item.passSlot) connect(passBtn, SIGNAL(clicked()), this, item.passSlot);
            ui->tableWidget->setCellWidget(i, 2, passBtn);

            QPushButton *failBtn = new QPushButton("不通过", this);
            if (item.failSlot) connect(failBtn, SIGNAL(clicked()), this, item.failSlot);
            ui->tableWidget->setCellWidget(i, 3, failBtn);
        }
    }
}

// 一键测试按钮逻辑
void MainWindow::on_TestButton_clicked()
{
    ui->TestButton->setEnabled(false);
    m_runningThreadsCount = 0;

    int rowCount = ui->tableWidget->rowCount();

    // 1. 先扫描需要跑的 AUTO_TEST 项
    for (int i = 0; i < rowCount; ++i) {
        QTableWidgetItem *nameItem = ui->tableWidget->item(i, 1);
        if (!nameItem) continue;

        TestType type = static_cast<TestType>(nameItem->data(Qt::UserRole + 1).toInt());
        QString scriptPath = nameItem->data(Qt::UserRole).toString();

        if (type == AUTO_TEST && !scriptPath.isEmpty()) {
            m_runningThreadsCount++;
        }
    }

    if (m_runningThreadsCount == 0) {
        ui->TestButton->setEnabled(true);
        return;
    }

    // 2. 依次按表格行号精准启动线程
    for (int i = 0; i < rowCount; ++i) {
        QTableWidgetItem *nameItem = ui->tableWidget->item(i, 1);
        if (!nameItem) continue;

        TestType type = static_cast<TestType>(nameItem->data(Qt::UserRole + 1).toInt());
        QString scriptPath = nameItem->data(Qt::UserRole).toString();

        if (type != AUTO_TEST || scriptPath.isEmpty()) {
            continue;
        }

        // 设置当前行状态为“测试中...”
        QTableWidgetItem *statusItem = new QTableWidgetItem("测试中...");
        statusItem->setTextAlignment(Qt::AlignCenter);
        ui->tableWidget->setItem(i, 3, statusItem);

        // 绑定准确的行号 i 与对应脚本路径
        TestThread *thread = new TestThread(i, scriptPath, this);

        connect(thread, &TestThread::testFinished, this, &MainWindow::onTestThreadFinished);

        connect(thread, &TestThread::finished, this, [this, thread]() {
            m_runningThreadsCount--;
            if (m_runningThreadsCount <= 0) {
                ui->TestButton->setEnabled(true);
            }
            thread->deleteLater();
        });

        thread->start();
    }
}

// 接收后台线程测试结果，刷新整行颜色和文本
void MainWindow::onTestThreadFinished(int row, bool isSuccess)
{
    QString resultText = isSuccess ? "通过" : "不通过";
    QColor bgColor = isSuccess ? Qt::green : Qt::red;

    // 更新第 3 列文本
    QTableWidgetItem *statusItem = new QTableWidgetItem(resultText);
    statusItem->setTextAlignment(Qt::AlignCenter);
    ui->tableWidget->setItem(row, 3, statusItem);

    // 设置整行的背景颜色
    for (int col = 0; col < 4; ++col) {
        QTableWidgetItem *item = ui->tableWidget->item(row, col);
        if (item) {
            item->setBackground(QBrush(bgColor));
        }
    }
}

// 单项手动拉起脚本槽函数示例（用于支持调起测试但不在主列表上自动刷颜色的任务）
void MainWindow::on_typec_Button_clicked()
{
    TestThread *typecThread = new TestThread(99, "sudo sh /opt/armsomtest/shell/typec.sh", this);
    connect(typecThread, &TestThread::finished, typecThread, &QObject::deleteLater);
    typecThread->start();
}

void MainWindow::on_usb_Button_clicked()
{
    TestThread *usbThread = new TestThread(99, "sudo sh /opt/armsomtest/shell/usb.sh", this);
    connect(usbThread, &TestThread::finished, usbThread, &QObject::deleteLater);
    usbThread->start();
}

void MainWindow::on_tfcard_Button_clicked()
{
    TestThread *tfcardThread = new TestThread(99, "sudo sh /opt/armsomtest/shell/tfcard.sh", this);
    connect(tfcardThread, &TestThread::finished, tfcardThread, &QObject::deleteLater);
    tfcardThread->start();
}

void MainWindow::on_hdmiin_Button_clicked()
{
    TestThread *hdmiinThread = new TestThread(99, "sudo sh /opt/armsomtest/shell/hdmiin.sh", this);
    connect(hdmiinThread, &TestThread::finished, hdmiinThread, &QObject::deleteLater);
    hdmiinThread->start();
}

void MainWindow::on_Audio_Button_clicked()
{
    TestThread *audioThread = new TestThread(99, "sudo sh /opt/armsomtest/shell/audio.sh", this);
    connect(audioThread, &TestThread::finished, audioThread, &QObject::deleteLater);
    audioThread->start();
}

// 手动测试结果按钮绑定的空槽函数（根据实际需求扩充）
void MainWindow::on_audiopass_clicked() {}
void MainWindow::on_hdmiinpass_clicked() {}
void MainWindow::on_mipipass_clicked() {}
void MainWindow::on_gpiopass_clicked() {}