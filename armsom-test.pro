QT       += core gui multimedia multimediawidgets


greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

CONFIG += c++11

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
    camerathread.cpp \
    camerawindow.cpp \
    main.cpp \
    mainwindow.cpp \
    shell.cpp \
    testthread.cpp

HEADERS += \
    camerathread.h \
    camerawindow.h \
    mainwindow.h \
    shell.h \
    testthread.h

FORMS += \
    camerawindow.ui \
    mainwindow.ui

CONFIG += link_pkgconfig
PKGCONFIG += opencv4

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /usr/bin
!isEmpty(target.path): INSTALLS += target

desktop.path  = /usr/share/applications
desktop.files = resources/armsom-test.desktop
icons.path = /usr/share/icons/hicolor/512x512/apps
icons.files   = resources/ArmSoM.png
audio.path = /opt/armsomtest
audio.files   = resources/audio.wav
testscripts.path = /opt/armsomtest
testscripts.files = resources/shell
INSTALLS     += desktop icons audio testscripts

RESOURCES += \
    QtResources.qrc
