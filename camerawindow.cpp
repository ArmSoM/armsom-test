//#include "camerawindow.h"
//#include "ui_camerawindow.h"

//CameraWindow::CameraWindow(QWidget *parent) :
//    QMainWindow(parent),
//    ui(new Ui::CameraWindow)
//{
//    ui->setupUi(this);
//    const char * string;
//    Camera_viewfinder = new QCameraViewfinder(this);
//    Hdmiin_viewfinder = new QCameraViewfinder(this);
//    camerathread = new CameraThread(0,string,ui,Camera_viewfinder,Hdmiin_viewfinder,this);
//    camerathread->start();
//}

//CameraWindow::~CameraWindow()
//{
//    Camera_viewfinder->close();
//    Hdmiin_viewfinder->close();
//    delete Camera_viewfinder;
//    delete Hdmiin_viewfinder;
//    delete camerathread;
//    delete ui;
//}



#include "camerawindow.h"
#include "ui_camerawindow.h"

#include <iostream>
#include <opencv2/opencv.hpp>
#include <QDebug>

using namespace std;
using namespace cv;


CameraWindow::CameraWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::CameraWindow)
{
    ui->setupUi(this);
    const char * string;
        Camera_viewfinder = new QCameraViewfinder(this);
        Hdmiin_viewfinder = new QCameraViewfinder(this);
        camerathread = new CameraThread(0,string,ui,Camera_viewfinder,Hdmiin_viewfinder,this);
        camerathread->start();

    //this->setFixedSize(300, 400);
    //setWindowState(Qt::WindowMaximized);//max
    timer = new QTimer(this);
    timer->stop();
    connect(timer, SIGNAL(timeout()), this, SLOT(readFarme()));  // 时间到，读取当前摄像头信息
    ok = true;

    //    pushButton = new QPushButton(tr("开始/暂停"),this);
    //    pushButton->setGeometry(QRect(0, 0, 100, 100));
    //    pushButton->setFont(QFont("Times", 32, QFont::Bold));
    //    connect(pushButton, SIGNAL(clicked()),this, SLOT(on_pushButton_clicked()));

    // clickLabel = new QLabel(this);
    ui->hdmiin_label->setGeometry(120, 50, 576, 324);
    //ui->camera_label->setGeometry(120, 440, 576, 324);
    //打开摄像头，从摄像头中获取视频
    HdmiinVideocapture = new VideoCapture(20);
    //CameraVideocapture = new VideoCapture(11);



    //默认分辨率
        //double frame_width = CameraVideocapture->get(cv::CAP_PROP_FRAME_WIDTH);
        //double frame_height = CameraVideocapture->get(cv::CAP_PROP_FRAME_HEIGHT);
        //double frame_rate = CameraVideocapture->get(cv::CAP_PROP_FPS);

        //cout << "default : " << "( " << frame_width << ", " << frame_height << " )" << ", " << frame_rate << endl;


    //设置分辨率，编码格式
//    CameraVideocapture->set(cv::CAP_PROP_FPS, 0);
//        CameraVideocapture->set(cv::CAP_PROP_FRAME_WIDTH, 1280);
//        CameraVideocapture->set(cv::CAP_PROP_FRAME_HEIGHT, 720);
//        CameraVideocapture->set(cv::CAP_PROP_FOURCC, cv::VideoWriter::fourcc('M', 'J', 'P', 'G'));

//        double frame_set_width = CameraVideocapture->get(cv::CAP_PROP_FRAME_WIDTH);
//        double frame_set_height = CameraVideocapture->get(cv::CAP_PROP_FRAME_HEIGHT);
//        double frame_set_rate = CameraVideocapture->get(cv::CAP_PROP_FPS);

//        cout << "after Change : " << "( " << frame_set_width << ", " << frame_set_height << " )" << ", " << frame_set_rate << endl;



    //    VideoCapture captrue;
    //    Mat img;
    //    captrue.open(11);
    //    if(captrue.isOpened()){
    //        qDebug() <<"camera is opened";
    //    }
    //    while (1) {
    //        captrue.read(img);
    //        imshow("Video test",img);
    //        waitKey(1);

    //    }
    //    waitKey(0);

    if(ok)timer->start(33);
    else timer->stop();
    ok = !ok;
}

CameraWindow::~CameraWindow()
{
    delete ui;
}

QImage CameraWindow::cvMat2QImage(const Mat& mat)    // Mat 改成 QImage
{
    if (mat.type() == CV_8UC1)					// 单通道
    {
        QImage image(mat.cols, mat.rows, QImage::Format_Indexed8);
        image.setColorCount(256);				// 灰度级数256
        for (int i = 0; i < 256; i++)
        {
            image.setColor(i, qRgb(i, i, i));
        }
        uchar *pSrc = mat.data;					// 复制mat数据
        for (int row = 0; row < mat.rows; row++)
        {
            uchar *pDest = image.scanLine(row);
            memcpy(pDest, pSrc, mat.cols);
            pSrc += mat.step;
        }
        return image;
    }

    else if (mat.type() == CV_8UC3)				// 3通道
    {
        const uchar *pSrc = (const uchar*)mat.data;			// 复制像素
        QImage image(pSrc, mat.cols, mat.rows, mat.step, QImage::Format_RGB888);	// R, G, B 对应 0,1,2
        return image.rgbSwapped();				// rgbSwapped是为了显示效果色彩好一些。
    }
    else if (mat.type() == CV_8UC4)
    {
        const uchar *pSrc = (const uchar*)mat.data;			// 复制像素
        // Create QImage with same dimensions as input Mat
        QImage image(pSrc, mat.cols, mat.rows, mat.step, QImage::Format_ARGB32);		// B,G,R,A 对应 0,1,2,3
        return image.copy();
    }
    else
    {
        return QImage();
    }
}

Mat CameraWindow::QImage2cvMat(QImage image)			// QImage改成Mat
{
    Mat mat;
    switch (image.format())
    {
    case QImage::Format_ARGB32:
    case QImage::Format_RGB32:
    case QImage::Format_ARGB32_Premultiplied:
        mat = Mat(image.height(), image.width(), CV_8UC4, (void*)image.constBits(), image.bytesPerLine());
        break;
    case QImage::Format_RGB888:
        mat = Mat(image.height(), image.width(), CV_8UC3, (void*)image.constBits(), image.bytesPerLine());
        cv::cvtColor(mat, mat, CV_BGR2RGB);
        break;
    case QImage::Format_Indexed8:
        mat = Mat(image.height(), image.width(), CV_8UC1, (void*)image.constBits(), image.bytesPerLine());
        break;
    }
    return mat;
}

//事件驱动///
//打开摄像头
void CameraWindow::on_pushButton_clicked()
{
    // 开始计时，超时则发出timeout()信号
    //    if(ok)timer->start(33);
    //    else timer->stop();
    //    ok = !ok;
}
//读取Frame图像 when timeout()
void CameraWindow::readFarme()
{
    HdmiinVideocapture->read(matFrame);
    QImage imgg = cvMat2QImage(matFrame);
    QPixmap qpixmap = QPixmap::fromImage(imgg);

    int with = ui->hdmiin_label->width();
    int height = ui->hdmiin_label->height();
    QPixmap fitpixmap = qpixmap.scaled(with,height,Qt::KeepAspectRatio,Qt::SmoothTransformation);
    // QPixmap fitpixmap = qpixmap.scaled(with,height,Qt::IgnoreAspectRatio,Qt::SmoothTransformation);
    // 将图片显示到label上
    ui->hdmiin_label->setPixmap(fitpixmap);


    //CameraVideocapture->read(cameramatFrame);
    //QImage cameraimgg = cvMat2QImage(cameramatFrame);
    //QPixmap camerapixmap = QPixmap::fromImage(cameraimgg);

    //int camerawith = ui->camera_label->width();
    //int cameraheight = ui->camera_label->height();
   // QPixmap camerafitpixmap = camerapixmap.scaled(with,height,Qt::KeepAspectRatio,Qt::SmoothTransformation);
    // QPixmap fitpixmap = qpixmap.scaled(with,height,Qt::IgnoreAspectRatio,Qt::SmoothTransformation);
    // 将图片显示到label上
   // ui->camera_label->setPixmap(camerafitpixmap);

}

//exit
void CameraWindow::bnClose()
{
    timer->stop();         // 停止读取数据。
    HdmiinVideocapture->release();
   // CameraVideocapture->release();
    //exit
    QApplication* app;
    app->exit(0);
}

