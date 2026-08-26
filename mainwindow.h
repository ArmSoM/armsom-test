#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QTableWidget>
#include <QPushButton>
#include <QHeaderView>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

enum TestType {
    AUTO_TEST,
    MANUAL_TEST
};

struct TestItem {
    QString name;
    TestType type;
    QString scriptPath;
    const char* passSlot;
    const char* failSlot;
};

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void on_TestButton_clicked();
    
    // 对应接收 TestThread 信号的槽函数
    void onTestThreadFinished(int row, bool isSuccess);

    // 手动测试触发槽
    void on_typec_Button_clicked();
    void on_usb_Button_clicked();
    void on_tfcard_Button_clicked();
    void on_hdmiin_Button_clicked();
    void on_Audio_Button_clicked();

    // 手动判定结果槽
    void on_audiopass_clicked();
    void on_hdmiinpass_clicked();
    void on_mipipass_clicked();
    void on_gpiopass_clicked();

private:
    void initUI();
    void initTestTable(int condition);
    void setRowTestResult(int row, bool isSuccess);

    Ui::MainWindow *ui;
    int condition = -1;
    int m_runningThreadsCount = 0;
};

#endif // MAINWINDOW_H