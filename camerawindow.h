#ifndef CAMERAWINDOW_H
#define CAMERAWINDOW_H

#include <QMainWindow>
#include "camerathread.h"
#include <QCameraViewfinder>

class CameraThread;

namespace Ui {
class CameraWindow;
}

//class CameraWindow : public QMainWindow
//{
//    Q_OBJECT

//public:
//    explicit CameraWindow(QWidget *parent = nullptr);
//    ~CameraWindow();

//private:
//    Ui::CameraWindow *ui;
//    CameraThread *camerathread;


//    QCameraViewfinder *Camera_viewfinder;     //取景器
//    QCameraViewfinder *Hdmiin_viewfinder;     //取景器
//};

//#endif // CAMERAWINDOW_H



#include <QMainWindow>

//#include "ui_QtGuiApplication1.h"
#include "camerathread.h"
#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/imgproc/types_c.h>
#include "qimage.h"

#include <QFileDialog>
#include <QLabel>
#include <QTimer>
#include <QPushButton>
//#include <QCamera>
//#include <QCameraImageCapture>

class CameraThread;

using namespace cv;          //OpenCV命名空间


QT_BEGIN_NAMESPACE
namespace Ui { class CameraWindow; }
QT_END_NAMESPACE

class CameraWindow : public QMainWindow
{
    Q_OBJECT

public:
    CameraWindow(QWidget *parent = nullptr);
    ~CameraWindow();

private:
    Ui::CameraWindow *ui;
        CameraThread *camerathread;


        QCameraViewfinder *Camera_viewfinder;     //取景器
        QCameraViewfinder *Hdmiin_viewfinder;     //取景器

    QImage cvMat2QImage(const Mat & mat);
        Mat QImage2cvMat(QImage image);

        QTimer *timer;
        bool ok;
        VideoCapture *HdmiinVideocapture;
        VideoCapture *CameraVideocapture;
        Mat matFrame;
        Mat cameramatFrame;
        QLabel *clickLabel;
        QPushButton *pushButton;
private slots:
    void on_pushButton_clicked();
    void readFarme();
    void bnClose();


};
#endif // MAINWINDOW_H

