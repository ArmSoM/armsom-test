## 构建步骤
1, 安装依赖包
```
sudo apt install debhelper qtchooser libopencv-dev build-essential qtmultimedia5-dev
```
2, 构建deb
```
dpkg-buildpackage -us -uc
```

