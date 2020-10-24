&emsp;&emsp;Windows是市场占有率最高的桌面操作系统，很多开发人员还是习惯于在Windows系统中进行开发工作，但服务器领域多采用Linux操作系统，因此开发人员在开发过程中，经常会遇到windows系统开发的软件难以部署到Linux系统的问题。  
&emsp;&emsp;WSL（Windows Subsystem for Linux），顾名思义就是在Windows中使用Linux系统，尤其是支持docker的WSL2发布后，完美的解决了开发人员的难题，在Windows系统中能毫无障碍的Linux系统。     

&emsp;&emsp;下面我们开始在Windows10 环境中搭建WSL2。  

1.系统安装  
&emsp;&emsp;WSL2只能运行于Windows 10系统之上，并且要求Windows 10版本为2004版本，内部版本号为19041版本或者更高版本。   
&emsp;&emsp;Windows 10的版本可以这样看到： 鼠标右键单击"开始"-->"设置"-->"关于"-->"Windows规格"中的版本号。  
&emsp;&emsp;如果Windows 10的版本号低于2004，需要先升级Windows版本。  
&emsp;&emsp;1）下载windows 10 2004版本的iso文件；  
&emsp;&emsp;2）鼠标右键单击iso文件，选择"装载"；  
&emsp;&emsp;3）在打开的目录中，双击"setup.exe"进行升级安装。   

2.安装WSL2   
2.1 启用"虚拟机平台"   
&emsp;&emsp;安装 WSL2之前，必须启用"虚拟机平台"功能。打开"控制面板"-->"程序"-->"程序和功能"-->"启用或关闭Windows功能"-->勾选"虚拟机平台"，"确定"后重启系统。    
2.2 安装WSL  
&emsp;&emsp;打开"控制面板"-->"程序"-->"程序和功能"-->"启用或关闭Windows功能"-->勾选"适用于Linux的Windows子系统"，"确定"后重启系统。   

&emsp;&emsp;系统重启后，鼠标右键点击"开始"，打开"Windows PowerShell(管理员)"，输入"wsl"，验证成功，WSL已经正常安装。   

      PS C:\WINDOWS\system32> wsl
      适用于 Linux 的 Windows 子系统没有已安装的分发版。
      可以通过访问 Microsoft Store 来安装分发版:
      https://aka.ms/wslstore  

2.3 升级WSL 2   
&emsp;&emsp;WSL安装好之后，默认是WSL 1，需要把默认版本设为WSL 2。   

      PS C:\WINDOWS\system32> wsl --set-default-version 2
      WSL 2 需要更新其内核组件。有关信息，请访问 https://aka.ms/wsl2kernel
      有关与 WSL 2 的主要区别的信息，请访问 https://aka.ms/wsl2

&emsp;&emsp;提示需要更新WSL 2内核组件，访问https://aka.ms/wsl2kernel，并下载安装WSL2 Linux内核更新包。安装完成后，重新设置WSL默认版本为2。   

      PS C:\WINDOWS\system32> wsl --set-default-version 2
      有关与 WSL 2 的主要区别的信息，请访问 https://aka.ms/wsl2   

2.4 下载Linux分发版  
&emsp;&emsp; 打开"Microsoft Store"微软商城，搜索"ubuntu"，即可搜索到多个ubuntu的发行版，选择免费的"Ubuntu 18.04 LTS"下载，下载时需要登录微软账号。   
&emsp;&emsp; 下载完成后，在"Microsoft Store"微软商城直接启动Ubuntu 18.04。   
&emsp;&emsp; 在"Windows PowerShell(管理员)"中查看WSL的运行情况。   

      PS C:\WINDOWS\system32> wsl -l -v
        NAME            STATE           VERSION
      * Ubuntu-18.04    Running         2

&emsp;&emsp; 可以看到Ubuntu-18.04已经正常运行。   


3.参考资料        
&emsp;&emsp; https://docs.microsoft.com/zh-cn/windows/wsl/wsl2-kernel

----
&emsp;&emsp;安微云是国内领先的基于Arm架构的云技术团队，提供虚拟化、数据分析、数据存储、文本处理、语义分析、自动化脚本等企业级云技术及服务。  
&emsp;&emsp;更多信息，请关注"安微云"公众号。