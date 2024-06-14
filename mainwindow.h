#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

#include "testthread.h"
#include "camerathread.h"
#include <QtWidgets/QPushButton>
#include "shell.h"

#include <QCameraViewfinder>

#define MANUAL_TESTING 99

class TestThread; //
class CameraThread;

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

    execshell Qshell;

    QPushButton *Hdmiin_pass_bt;

    QPushButton *Hdmiin_faild_bt;

    QPushButton *Camera_pass_bt;

    QPushButton *Camera_faild_bt;

    QPushButton *Audio_pass_bt;

    QPushButton *Audio_faild_bt;

    QPushButton *Mipi_pass_bt;

    QPushButton *Mipi_faild_bt;

    QPushButton *Pin_pass_bt;

    QPushButton *Pin_faild_bt;

private slots:


    void initUI();

    void on_pass_clicked(int item,QString string);

    void on_hdmiinpass_clicked();

    void on_hdmiinfaild_clicked();

    void on_camerapass_clicked();

    void on_camerafaild_clicked();

    void on_audiopass_clicked();

    void on_audiofaild_clicked();

    void on_mipipass_clicked();

    void on_mipifaild_clicked();

    void on_pinpass_clicked();

    void on_pinfaild_clicked();

    void on_TestButton_clicked();

    void on_pass_Button_clicked();

    void on_PIN_Button_clicked();

    void on_WIFI_Button_clicked();

    void on_BT_Button_clicked();


    void on_M2_Button_clicked();

    void on_TYPEC_Button_clicked();

    void on_eth_Button_clicked();

    void on_usb20_Button_clicked();

    void on_usb30Button_clicked();

    void on_tfcard_Button_clicked();

    void on_hdmiin_Button_clicked();

    void on_Audio_Button_clicked();

    void on_Camera_Button_clicked();

    void cameraCapture();

     void on_camera_stop_clicked();


     void on_CameraButton_clicked();

private:
    Ui::MainWindow *ui;
    TestThread *testthread;
    TestThread * WifiThread;
    TestThread * BtThread;
    TestThread * Ethhread;
    TestThread * M2Thread;
    TestThread * TypecThread;
    TestThread * Usb20Thread;
    TestThread * Usb30Thread;
    TestThread * TfcardThread;
    TestThread * RtcThread;
    TestThread * AudioThread;
    TestThread * PinThread;

    CameraThread *camerathread;

    QTimer *timer;
    bool ok;
    QCameraViewfinder *Camera_viewfinder;     //取景器
    QCameraViewfinder *Hdmiin_viewfinder;     //取景器
signals:
    void import(Ui::MainWindow *);
};
#endif // MAINWINDOW_H
