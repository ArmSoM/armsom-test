## 构建步骤
1, 安装依赖包
```
sudo apt install debhelper qtchooser libopencv-dev build-essential qtmultimedia5-dev
```
2, 构建deb
```
dpkg-buildpackage -us -uc


sige运行内存不足不能多线程运行构建命令
DEB_BUILD_OPTIONS=parallel=1 dpkg-buildpackage -us -uc

```

