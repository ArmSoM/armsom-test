#ifndef CAMERATHREAD_H
#define CAMERATHREAD_H



//#include <QMainWindow>

//#include "ui_QtGuiApplication1.h"
#include "mainwindow.h"
#include "camerawindow.h"
//#include "ui_mainwindow.h"
#include "ui_camerawindow.h"
#include <QThread>

#include "qimage.h"

#include <QFileDialog>
#include <QLabel>
#include <QTimer>
#include <QPushButton>

class QCamera;
class QCameraViewfinder;
class QCameraImageCapture;
class QCameraInfo;
class QCameraViewfinderSettings;
//#include <QCamera>
//#include <QCameraImageCapture>
class CameraWindow;


class CameraThread: public QThread
{
    Q_OBJECT

public:
    CameraThread(int itemnum,const char *command,Ui::CameraWindow *ui,QCameraViewfinder *viewfinder,QCameraViewfinder *viewfinder2,QWidget *parent = nullptr);
    ~CameraThread();

    int m_ItemNum;
    const char * m_command;
   // Ui::MainWindow * ui;
    Ui::CameraWindow *ui;

private:


    QTimer *timer;
    bool ok;

    QLabel *clickLabel;
    QPushButton *pushButton;

//    QScopedPointer<QCamera> camera;
//    QScopedPointer<QCamera> hdmiin;

    QCamera *camera;                   //相机
    QCamera *hdmiin;                   //hdmiin
    QCameraViewfinder *Camera_viewfinder;     //相机取景器
    QCameraViewfinder *Hdmiin_viewfinder;     //hdmiin取景器
    QCameraImageCapture *Camera_imageCapture; //图像捕获
    QCameraImageCapture *Hdmiin_imageCapture; //图像捕获
    QList<QCameraInfo> cameras;        //相机列表
    QList<QSize> mResSize = {};        //分辨率列表
private slots:
    void on_pushButton_clicked();
    // void readFarme();
    void bnClose();

protected:
    void run();

};

#endif // CAMERATHREAD_H
