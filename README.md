## 构建步骤
1, 安装依赖包
```
sudo apt install debhelper qtchooser libopencv-dev build-essential qtmultimedia5-dev
```

2, 编译
```
mkdir build && cd build && qmake ../armsom-test.pro && make
cd build && rm -rf * && qmake ../armsom-test.pro && make -j4
```

3, 构建deb
```
dpkg-buildpackage -us -uc


sige运行内存不足不能多线程运行构建命令
DEB_BUILD_OPTIONS=parallel=1 dpkg-buildpackage -us -uc

```

4, 卸载deb
```
apt remove armsom-test
```

要是QT应用打不开的话是因为找不到X11环境，需要更新应用libqt5gui5_5.15.8+dfsg-11+gles_arm64.deb
https://cdn.haguro.top/share/qt-gles-debs.tar

下列软件包有未满足的依赖关系:指定版本号
apt-get install libqt5gui5=5.15.8+dfsg-11+deb12u2

ArmSoM-CM5-IO 测试

工具: 

usb测试：2*usb3.0 ，2* 键盘/鼠标 (遇到爱国者品牌usb3.0 插着上电偶尔识别不到3.0 降级为2.0)
M.2 测试： NVME 硬盘
摄像头：1个ov13850,1个imx219
mipi dis: 10.1 寸屏幕
hdmi：hdmi显示器