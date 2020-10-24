&emsp;&emsp;WSL2极大的方便了Windows 10系统和Linux系统的互访，非常适用于需要双系统频繁互访的开发场景。

&emsp;&emsp;Android系统的编译和调试，就是这样的一个例子。下面我们在Windows 10上搭建android-sdk调试Android 6 image的环境。  

1.安装android studio    
1.1 下载安装Ubuntu 16.04     
&emsp;&emsp;浏览器访问www.android-studio.org，下载安装android studio。    
&emsp;&emsp;安装完成后，启动android studio，按照默认配置执行，并由android studio自动安装android-sdk。  
&emsp;&emsp;如果安装过程中出现如下错误，先略过。    

      Running Intel® HAXM installer
      Failed to install Intel HAXM. 
      ......
      Installer log is located at C:\Users\youname\AppData\Local\Temp\haxm_log.txt

1.2 配置Android SDK    
&emsp;&emsp;打开android studio的Tools-->SDK manager，在"SDK Platforms"页上勾选"Android 6.0"，确定安装。  

1.3 配置虚拟设备     
&emsp;&emsp;打开android studio的Tools-->AVD manager。    
&emsp;&emsp;点击"Create Virtual Device"，选择"phone"->"Nexus 5"，在"System Image"页面选择"x86 Images"页，选择下载Android 6.0 Marshmallow 的x86_64平台images，定义一个简单的avd name，生成Android虚拟设备。     
&emsp;&emsp;在Windows 10环境中arm架构的虚拟设备运行较慢，最好不要配置arm架构的images。    
&emsp;&emsp;虚拟设备配置好之后，即可在"虚拟设备"页面上运行虚拟手机。    

2.运行编译生成的Android images    
2.1 映射目录    
&emsp;&emsp;Windows 10中的调试，需要访问Ubuntu 16.04中编译生成的Android
 images，因此需要把Ubuntu 16.04的目录映射到Windows 10中。目录映射有两种方法：一种是使用wsl$目录，另一种是使用samba服务。    
2.1.1 使用wsl$目录    
&emsp;&emsp;鼠标右键点击"开始"，在"运行"中输入"\ \wsl$"，即可访问到Ubuntu 16.04系统的根目录，并可以逐级找到Android 6的目录。   
&emsp;&emsp;wsl$目录的映射，只能到"\ \wsl$\Ubuntu-16.04"，无法直接映射到Android 6的目录，对于有洁癖的开发人员来说，如果无法忍受，可以采用samba服务。   
&emsp;&emsp;点击"此电脑"，在顶部菜单中选择"映射网络驱动器"，把"\ \wsl$\Ubuntu-16.04"映射Windows 10系统的目录。    
2.1.2 使用samba服务    
&emsp;&emsp;在Ubuntu 16.04中安装配置samba服务。由于是本机访问，配置相对简单。        

      sudo apt install samba
      
      sudo vim /etc/samba/smb.conf
          #找到 ===Share Definitions====章节，打开相关配置项
          ......
          [homes]
              comment = Home Directories
              browseable = yes
              read only = no
              create mask = 0755
              directory mask = 0755
              valid users = %S
          
          #在文件尾部增加共享项
          [share]
              comment = share
              path = /home/yourpath
              wretable = yes
              valid users = yourname
      
      sudo service smbd restart      

&emsp;&emsp;WSL2每次启动Ubuntu系统，Ubuntu系统的ip地址都会变化，用samba服务需要固定Ubuntu 16.04系统的IP地址。    
&emsp;&emsp;打开"Windows PowerShell(管理员)"，执行设置IP的命令。该命令每次启动Ubuntu 16.04后，都需要执行。       

      wsl -d Ubuntu-16.04 -u root ip addr add 172.19.110.237/24 broadcast 172.19.110.255 dev eth0 label eth0:1
      netsh interface ip add address "vEthernet (WSL)" 172.19.110.1  255.255.255.0

&emsp;&emsp;命令中的IP地址，可根据需求修改。    
&emsp;&emsp;鼠标右键点击"开始"，在"运行"中输入"\ \ip"，即可访问到Ubuntu 16.04系统的根目录，并可以逐级找到Android 6的目录。   
&emsp;&emsp;点击"此电脑"，在顶部菜单中选择"映射网络驱动器"，把Android 6 的编译目录映射Windows 10系统的目录。  

2.2 运行编译生成的android image    
&emsp;&emsp;可以使用emulator.exe来加载编译好的android image，我们配置avd的时候选择的是"x86 Images"，因此要注意，必须编译对应的x86_64 android image。

      #擦除已有的avd数据
      your_android_sdk_path\emulator\emulator.exe -avd your_avd_name  -wipe-data
      #模拟器重新加载android image
      your_android_sdk_path\emulator\emulator.exe -avd your_avd_name  -system "your_android_path\out\target\product\generic_x86_64\system.img" -data "your_android_path\out\target\product\generic_x86_64\userdata.img"

&emsp;&emsp;自己编译的Android image被加载起来了，可以很方便的看修改的效果。    


3.参考资料        
&emsp;&emsp; http://www.android-studio.org

----
&emsp;&emsp;安微云是国内领先的基于Arm架构的云技术团队，提供虚拟化、数据分析、数据存储、文本处理、语义分析、自动化脚本等企业级云技术及服务。  
&emsp;&emsp;更多信息，请关注"安微云"公众号。