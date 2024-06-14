#include "camerathread.h"
#include <iostream>
#include <QDebug>

#include <QTimer>

#include <QCamera>
#include <QCameraInfo>
#include <QCameraViewfinder>
#include <QCameraImageCapture>
#include <QFileDialog>
#include <QList>

using namespace std;


CameraThread::CameraThread(int itemnum,const char *command,Ui::CameraWindow *ui,QCameraViewfinder *camera_viewfinder,QCameraViewfinder *hdmiin_viewfinder,QWidget *parent):m_ItemNum(itemnum),m_command(command),ui(ui),Camera_viewfinder(camera_viewfinder),Hdmiin_viewfinder(hdmiin_viewfinder)
{
    cameras = QCameraInfo::availableCameras();   //获取所有相机的列表
    //qDebug() << "this is camera: ";
    if (cameras.count() > 0) {
        for(const QCameraInfo &cameraInfo:cameras) {
            qDebug() << cameraInfo.description();
        }
        camera = new QCamera(cameras.at(0));     //初始化实例化一个相机对象
       // hdmiin = new QCamera(cameras.at(9));     //初始化实例化一个hdmiin对象
    }

    //设置取景器
    //viewfinder = new QCameraViewfinder(this);
    camera->setViewfinder(Camera_viewfinder);
    //hdmiin->setViewfinder(Hdmiin_viewfinder);
    Camera_viewfinder->resize(576, 324);                 //设置取景器显示大小
    //viewfinder->resize(384,216);                 //设置取景器显示大小
    //Camera_viewfinder->move(660,350);
    Camera_viewfinder->move(120,440);
    //Hdmiin_viewfinder->resize(462, 260);                 //设置取景器显示大小
    //viewfinder->resize(384,216);                 //设置取景器显示大小
    //Hdmiin_viewfinder->move(660,80);
    //Hdmiin_viewfinder->move(200,50);
    //viewfinder->show();

    Camera_imageCapture = new QCameraImageCapture(camera);
    camera->start();                             //开启相机

   // Hdmiin_imageCapture = new QCameraImageCapture(hdmiin);
    //hdmiin->start();                             //开启hdmiin


    //设置默认摄像头参数s
    QCameraViewfinderSettings set;
    set.setResolution(1920, 1080);                 //设置显示分辨率
    set.setMaximumFrameRate(60);                 //设置帧率
    //set.setPixelFormat(QVideoFrame::Format_YUYV);  //xiangsugeshi
    camera->setViewfinderSettings(set);
    //hdmiin->setViewfinderSettings(set);



    //添加初始化相机的分辨率选项
    mResSize = camera->supportedViewfinderResolutions();
    //qDebug() << "mResSize = " << mResSize;
    for (const QSize &msize:mResSize) {
        qDebug() << msize; //摄像头支持分辨率打印
    }

}

CameraThread::~CameraThread()
{
    camera->stop();
    //hdmiin->stop();
    Camera_viewfinder->close();
   // Hdmiin_viewfinder->close();
    delete camera;
    //delete hdmiin;
    //HdmiinVideocapture->release();
    //CameraVideocapture->release();
}

void CameraThread::run()
{
    //    imageCapture = new QCameraImageCapture(camera);
    //    camera->start();                             //开启相机

    //    //设置默认摄像头参数
    //    QCameraViewfinderSettings set;
    //    set.setResolution(640, 480);                 //设置显示分辨率
    //    set.setMaximumFrameRate(60);                 //设置帧率
    //    camera->setViewfinderSettings(set);



    //    //添加初始化相机的分辨率选项
    //    mResSize = camera->supportedViewfinderResolutions();
    //    //qDebug() << "mResSize = " << mResSize;
    //    for (const QSize &msize:mResSize) {
    //        qDebug() << msize; //摄像头支持分辨率打印
    //    }
}



//事件驱动///
//打开摄像头
void CameraThread::on_pushButton_clicked()
{
    // 开始计时，超时则发出timeout()信号
    if(ok)timer->start(33);
    else timer->stop();
    ok = !ok;
}


//exit
void CameraThread::bnClose()
{
    timer->stop();         // 停止读取数据。
    // HdmiinVideocapture->release();
    //CameraVideocapture->release();
    //exit
    //    QApplication* app;
    //    app->exit(0);
}


