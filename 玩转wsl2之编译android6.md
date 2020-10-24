&emsp;&emsp;WSL2极大的方便了Windows 10系统和Linux系统的互访，非常适用于需要双系统频繁互访的开发场景。

&emsp;&emsp;Android系统的编译和调试，就是这样的一个例子。下面我们使用WSL2来编译Android 6。  

1.安装Ubuntu 16.04分发版 
1.1 下载安装Ubuntu 16.04     
&emsp;&emsp;目前"Microsoft Store"微软商城中搜索Ubuntu，已经找不到Ubuntu 16.04版本，可以用浏览器访问https://www.microsoft.com/zh-cn/p/ubuntu-1604-lts/9pjn388hp8c9?rtc=1&activetab=pivot:overviewtab跳转安装。      
&emsp;&emsp;下载启动后，查看运行状态。   

      PS C:\WINDOWS\system32> wsl -l -v
        NAME            STATE           VERSION
      * Ubuntu-16.04    Running         2

&emsp;&emsp;由于Android 6的代码量比较大，也为了后续代码维护方便，我们把Ubuntu 16.04环境迁移到空间比较大的非系统盘。打开管理员"Windows PowerShell"：   

      PS C:\WINDOWS\system32> wsl -t Ubuntu-16.04
      PS C:\WINDOWS\system32> wsl -l -v
        NAME            STATE           VERSION
      * Ubuntu-16.04    Stopped         2  
      PS C:\WINDOWS\system32> wsl --export Ubuntu-16.04 d:\wsl-ubuntu1604.tar
      PS C:\WINDOWS\system32> wsl --unregister Ubuntu-16.04
      正在注销...
      PS C:\WINDOWS\system32> wsl --import Ubuntu-16.04 d:\wsl-ubuntu1604 D:\wsl-ubuntu1604.tar --version 2
      PS C:\WINDOWS\system32> wsl -l -v
        NAME            STATE           VERSION
      * Ubuntu-16.04    Stopped         2
      PS C:\WINDOWS\system32> ubuntu1604 config --default-user YOURNAME
      PS C:\WINDOWS\system32> del D:\wsl-ubuntu1604.tar

1.2 扩展虚拟磁盘空间     
&emsp;&emsp;WSL2系统的虚拟磁盘空间，默认是250G，通过AOSP下载Android 6代码，并编译，所需空间较大，我们把虚拟磁盘空间扩大为400G。    

      PS C:\WINDOWS\system32> diskpart
      Microsoft DiskPart 版本 10.0.19041.1
      Copyright (C) Microsoft Corporation.
      在计算机上: DESKTOP-2HD952A   
      DISKPART> select vdisk file="D:\wsl-ubuntu1604\ext4.vhdx"
      DiskPart 已成功选择虚拟磁盘文件。
      DISKPART> expand vdisk maximum="400000"
        100 百分比已完成
      DiskPart 已成功扩展虚拟磁盘文件。

&emsp;&emsp;用diskpart完成虚拟磁盘扩展后，进入Ubuntu 16.04系统。  

      ubuntu@DESKTOP-2HD952A:~$ df -h
      Filesystem      Size  Used Avail Use% Mounted on
      /dev/sdb        251G  1.2G  237G   1% /
      tmpfs           6.2G     0  6.2G   0% /mnt/wsl
      ......
      tmpfs           6.2G     0  6.2G   0% /sys/fs/cgroup
      C:\             238G   51G  187G  22% /mnt/c
      D:\             932G  202G  730G  22% /mnt/d

&emsp;&emsp;可以看到Ubuntu 16.04使用的磁盘设备为/dev/sdb。   

      sudo mount -t devtmpfs none /dev
      mount | grep ext4
      sudo resize2fs /dev/sdb 
  
2 下载Android 6源码   
2.1 下载repo工具    

      mkdir ~/bin
      PATH=~/bin:$PATH
      curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
      chmod a+x ~/bin/repo

2.2 下载Android 6代码    
&emsp;&emsp;下载Android 6代码，需要先下载AOSP镜像，然后在checkout出来。有两种方法。
2.2.1 传统下载方法    
&emsp;&emsp;AOSP首次同步需要下载约30GB数据，并且有很多小文件，因此要求有较高的网速，且容易下载失败，耗时较长。   

      mkdir WORKING_DIRECTORY
      cd WORKING_DIRECTORY
      repo init -u https://mirrors.tuna.tsinghua.edu.cn/git/AOSP/platform/manifest
      repo init -u https://mirrors.tuna.tsinghua.edu.cn/git/AOSP/platform/manifest -b android-6.0.1_r81
      repo sync

2.2.2 使用每月更新的初始化包

      wget -c https://mirrors.tuna.tsinghua.edu.cn/aosp-monthly/aosp-latest.tar #下载初始化包
      tar xf aosp-latest.tar
      cd AOSP   # 解压得到的 AOSP 工程目录
      # 这时 ls 的话什么也看不到，因为只有一个隐藏的 .repo 目录
      repo sync # 正常同步一遍即可得到完整目录 

&emsp;&emsp;如果wget下载较慢，还可以在Windows 10环境中，用迅雷下载后，拷贝到WSL2 Ubuntu 16.04环境中。Windows 10环境中的逻辑盘在Ubuntu 16.04中都有挂载，参看1.2章节。       

3.编译Android 6    
3.1 更改国内软件源    

      cd /etc/apt/
      sudo cp sources.list sources.list_bk 
      
      sudo vim sources.list      
        deb http://mirrors.aliyun.com/ubuntu/ xenial main
        deb-src http://mirrors.aliyun.com/ubuntu/ xenial main
        deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main
        deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main
        deb http://mirrors.aliyun.com/ubuntu/ xenial universe
        deb-src http://mirrors.aliyun.com/ubuntu/ xenial universe
        deb http://mirrors.aliyun.com/ubuntu/ xenial-updates universe
        deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates universe

        deb http://mirrors.aliyun.com/ubuntu/ xenial-security main
        deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main
        deb http://mirrors.aliyun.com/ubuntu/ xenial-security universe
        deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security universe
      
      sudo apt-get update

3.2 安装openJDK7
&emsp;&emsp;Android 6源码的编译只能使用OpenJDK7，Ubuntu 16.04没有OpenJDK7的源，需要添加OpenJDK的源，并安装。 

      sudo add-apt-repository ppa:openjdk-r/ppa 
      sudo apt-get update
      sudo apt-get install openjdk-7-jdk 

3.3 安装依赖库  

      sudo apt install make python bison zip
      sudo apt install g++-multilib gcc-multilib lib32ncurses5-dev lib32z1-dev
      sudo apt install libxml2-utils

3.4 编译android 6
&emsp;&emsp;进入Android 6目录，编译代码。   

      source build/envsetup.sh
      lunch
          选择1. aosp_arm-eng
      make -j16

&emsp;&emsp;make -j参数跟CPU核数有关，设置为CPU核数 X 2。

4.参考资料        
&emsp;&emsp; https://mirrors.tuna.tsinghua.edu.cn/help/AOSP/

----
&emsp;&emsp;安微云是国内领先的基于Arm架构的云技术团队，提供虚拟化、数据分析、数据存储、文本处理、语义分析、自动化脚本等企业级云技术及服务。  
&emsp;&emsp;更多信息，请关注"安微云"公众号。