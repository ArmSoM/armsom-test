#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QTableWidget>
#include <QThread>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

enum TestType {
    AUTO_TEST,  // 自动测试
    MANUAL_TEST // 人工测试
};

struct TestItem {
    QString name;            // 测试项名称
    TestType type;           // 测试类型
    QString scriptPath;      // 自动化测试脚本路径 (若为 MANUAL_TEST 可留空)
    const char* passSlot;    // 通过按钮绑定的槽函数
    const char* failSlot;    // 失败按钮绑定的槽函数
};

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void on_TestButton_clicked();
    
    // 自定义槽：线程完成自动化测试后回传结果更新 UI (改变文字及背景变绿/变红)
    void onTestThreadFinished(int row, bool isSuccess);

    // 手动测试触发槽
    void on_typec_Button_clicked();
    void on_usb_Button_clicked();
    void on_tfcard_Button_clicked();
    void on_hdmiin_Button_clicked();
    void on_Audio_Button_clicked();

    // 手动判定结果槽
    void on_hdmiinfaild_clicked();
    void on_audiopass_clicked();
    void on_hdmiinpass_clicked();
    void on_audiofaild_clicked();
    void on_mipipass_clicked();
    void on_mipifaild_clicked();
    void on_gpiopass_clicked();
    void on_gpiofaild_clicked();

private:
    void initUI();
    void initTestTable(int condition);

    Ui::MainWindow *ui;
    int condition = -1;              // 当前板卡 Condition
    int m_runningThreadsCount = 0;    // 运行中的自动化测试线程计数器
};

#endif // MAINWINDOW_H