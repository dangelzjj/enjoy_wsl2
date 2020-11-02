
&emsp;&emsp;Androidd源码非常庞大，由好几百个git仓库组成，是由repo工具来进行管理的。为了和AOSP的仓库兼容，我们也搭建使用repo工具管理的私有源码仓库。   

&emsp;&emsp;在WSL2的Ubuntu 16.04环境中我们完成了Android 6.0源码的编译，在这个基础上，我们来搭建基于WSL2的Android代码仓库，和每日迭代编译的环境。     


1.环境搭建       
&emsp;&emsp; Android源码仓库的搭建，需要两台设备，一台作为Android源码仓库，一台作为客户端上传Android源码。我们把完成Android 6.0源码编译的Ubuntu 16.04作为客户端，另外重新创建一台Ubuntu 20.04作为Android源码仓库服务器。   
&emsp;&emsp; 打开"Microsoft Store"微软商城，搜索"ubuntu"，即可搜索到多个ubuntu的发行版，选择免费的"Ubuntu 20.04 LTS"下载，下载完成后，在"Microsoft Store"微软商城直接启动Ubuntu 20.04。   
&emsp;&emsp; 在"Windows PowerShell(管理员)"中查看WSL的运行情况。   

      PS C:\WINDOWS\system32> wsl -l -v
        NAME            STATE        VERSION
      * Ubuntu-16.04    Running      2        #客户端，上传代码
        Ubuntu-20.04    Running      2        #服务器，Android源码仓库

&emsp;&emsp; 可以看到Ubuntu 20.04已经正常运行。  
&emsp;&emsp; 通过管理员Windows PowerShell给Ubuntu 20.04设置IP地址，把两个系统设置到同一个网段。    

      wsl -d Ubuntu-16.04 -u root ip addr add 172.19.110.237/24 broadcast 172.19.110.255 dev eth0 label eth0:1
      wsl -d Ubuntu-20.04 -u root ip addr add 172.19.110.236/24 broadcast 172.19.110.255 dev eth0 label eth0:2
      netsh interface ip add address "vEthernet (WSL)" 172.19.110.1  255.255.255.0



2.配置服务器   
2.1 配置客户端repo   
&emsp;&emsp;Android源码仓库搭建好之后，需要用repo工具验证，先配置repo。   

      curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo -o repo
      chmod +x repo

&emsp;&emsp;repo工具初始化时，需要下载git-repo仓库，配置清华的源，可以加速下载。    

      vim ~/.bashrc
        #在文件末尾添加REPO_URL
        export REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo'
      source ~/.bashrc

&emsp;&emsp;尝试运行一下repo命令，有python环境缺失的错误。Ubuntu 20.04中默认安装python3，没有python命令，做个软链接。    

      sudo ln -s /usr/bin/python3 /usr/bin/python

2.2 服务端启动git服务    
&emsp;&emsp;WSL2的Ubuntu系统跟直接安装的Ubuntu系统在底层系统服务上有些差别，gitlab等开源系统运行有问题。简单起见，我们直接用git daemon启动git服务。    

      /usr/bin/git daemon  --export-all --enable=receive-pack --reuseaddr --base-path=/home/yourname/repositories &

&emsp;&emsp;命令参数含义：    
&emsp;&emsp;--export-all：使用该选项后，在git仓库中就不必创建git-daemon-export-ok文件。   
&emsp;&emsp;--enable=receive-pack：配置git服务器可读写，默认git配置为只读服务器。    
&emsp;&emsp;--reuseaddr：允许服务器在无需等待旧连接超时的情况下重启。   
&emsp;&emsp;--base-path：配置git服务器路径，选项允许用户在未完全指定路径的条件下克隆项目。   

2.3 配置源码仓库   
&emsp;&emsp;我们编译的是Android 6.0 r81 tag，因此代码仓库用and6r81目录统一管理。   
2.3.1 服务端创建manifest仓库   
&emsp;&emsp;manifest仓库是配置文件仓库，repo是通过manifest仓库来管理所有的代码仓库，是最核心的一个仓库。    

     cd ~/
     mkdir repositories
     cd repositories
     git init --bare and6r81/manifest.git

2.3.2 客户端上传manifest仓库文件     
&emsp;&emsp;manifest仓库中的文件只有一个，就是default.xml，可以基于android 6.0代码中.repo目录中的修改。    

      cd ~/
      mkdir and6r81
      cd and6r81
      git clone git://172.19.110.236/and6r81/manifest.git
      cd manifest
      cp youu_android_code_path/.repo/manifests/default.xml ./
      vim default.xml  
          <?xml version="1.0" encoding="UTF-8"?>
          <manifest>
          
            <remote  name="origin"
                     fetch="git://172.19.110.236/and6r81" />
            <default revision="master"
                     remote="origin"
                     sync-j="4" />
                   
            <project path="build" name="platform/build" groups="pdk" >
            ..........
          </manifest>
        
        git add .
        git commit -m "init manifest"
        git push

&emsp;&emsp;这样就完成了manifest仓库的初始化。    

2.3.3 服务端初始化所有代码仓库   
&emsp;&emsp;manifest仓库初始化好之后，使用default.xml文件，在服务端创建文件中定义的所有git仓库。    
&emsp;&emsp;把default.xml通过/mnt/c中转拷贝到服务端，编写脚本，批量创建git仓库。   
&emsp;&emsp;首先，从default.xml中获取所有的git仓库。    

      cat default.xml | cut -d '"' -f 4 > repos.txt

&emsp;&emsp;把default.xml文件中的每一行，用引号分割后，取第4列，存入repos.txt文件，参看文件中的project行，就可以取到git仓库的名字。命令执行完成后，编辑repos.txt，把无效的行手动删除掉。   
&emsp;&emsp;编写批量创建git仓库的脚本，create_repos.sh。    

      #/bin/bash
      set -x
      set -e
      pwd=${PWD}
       
      cd /home/yourname/repositories/and6r81
      while read line; do
          if [ -z "$line" ]; then
              echo $git_dir not exist !!!!!!!!!! 1>&2
              continue
          fi
          git init --bare $line.git
          echo ==== $line =====
          pwd
      done

&emsp;&emsp;把两个文件放在同一个目录中，执行命令，批量创建git仓库。   

      cat repos.txt | . create_repos.sh

2.3.4 客户端上传代码到服务端仓库      
&emsp;&emsp;拷贝Android 6代码到客户端clone manifest仓库的目录，并清除代码中的.git目录。    

      cp -r your_android_path/android_code   ~/and681/
      cd ~/and681/
      find -name .git | xargs rm -rf 

&emsp;&emsp;用du命令看看所有Android代码的容量。    

      du -h --max-depth=0
&emsp;&emsp;Android 6的代码量在22G左右。     

&emsp;&emsp;从default.xml中获取需要上传的仓库目录，并保存到src.txt。   

      cat your_path/default.xml | cut -d '"' -f 2 > src.txt

&emsp;&emsp;仓库目录获取的是project列表的第2列。文件生成后，也需要编辑文件，把无关的行删除。          

&emsp;&emsp;编写批量上传git仓库代码的脚本push_src.sh。

      #/bin/bash
       
      set -x
      set -e
       
      para1=
      work_dir=$1
      count=0
      
      isempty=
       
      pwd=${PWD}
       
      while read line; do
          echo $line
          isempty="notemtpy"
          count=$((count+1))
          line1=${line%%/*}
          if [ -z "$line" ]; then
              echo $work_dir not exist !!!!!!!!!!!! 1>&2
              continue
          fi
          if [ $(ls -A $pwd/$line | wc -l) -eq 0 ]; then
              echo $work_dir empty !!!!!!!!!!!! 1>&2
              isempty="empty"
          fi
          workdir=$pwd/$line
          echo ==== $workdir
          cd $workdir
              rm -rf .git
              git init .  1>&2
              git add . -f 1>&2
      
              if [ "$isempty" = "notempty" ]; then
                  git commit -m "init"
                  if [ "$line1" = "device" ]; then
                      git push --set-upstream git://172.19.110.236/and6r81/$line.git master
                  else
                      git push --set-upstream git://172.19.110.236/and6r81/platform/$line.git master
                  fi
              else
                  echo "add empyt_file"
                  touch empty_file
                  git add .
                  git commit -m "add empty_file"
                  
                  if [ "$line1" = "device" ]; then
                    git push --set-upstream git://172.19.110.236/and6r81/$line.git master
                  else
                    git push --set-upstream git://172.19.110.236/and6r81/platform/$line.git master
                  fi
      
                  echo number:$count should be empty $line >> $HOME/log_$(date +%Y_%m_%d)
               fi
          echo -e "number:$count \n"
      done

&emsp;&emsp;上传脚本中要注意Android代码中的空仓库的处理，否则repo下载的时候会出错。    
&emsp;&emsp;上传代码时，还会出现default.xml代码中有定义，但Android代码中不存在的目录，上传出错时，需要从src.txt文件删除掉，有以下这些。   

      /external/jline
      /prebuilts/eclipse-build-deps
      /prebuilts/eclipse-build-deps-sources
      tools/adt/eclipse
      tools/adt/idea
      tools/base
      tools/build
      tools/emulatortools/base
      tools/emulator
      tools/idea
      tools/loganalysis
      tools/motodev
      tools/studio/cloud
      tools/studio/translation
      tools/swt
      tools/tradefederation      

&emsp;&emsp;上传结束后，需要重新调整代码仓库。   
&emsp;&emsp;1）从manifest.git中default.xml文件中删除以上的仓库，并更新仓库。   
&emsp;&emsp;2）删除掉服务端批量创建的仓库；从服务器用于批量创建git仓库的default.xml中删除掉以上的仓库，重新批量创建仓库。   
&emsp;&emsp;3）客户端用更新过的default.xml重新上传代码到服务端。    

2.3.5 验证代码仓库   
&emsp;&emsp;代码上传结束后，在客户端验证repo下载代码。   

      repo init -u git://172.19.110.236/and6r81/manifest.git
      repo sync

&emsp;&emsp;代码下载成功后，可以在用du命令看看整体代码的大小。    

3.代码仓库设置局域网可访问    
&emsp;&emsp;WSL2的网络模式是NAT模式，在管理员Windows PowerShell中用ipconfig命令可以看到vEthernet（WSL）的以太网适配器，这是所有WSL2 Linux系统的网关。其它电脑无法直接访问WSL2 Linux系统上架设的服务，需要做以下配置。   
3.1 在服务端的防火墙中开放端口    

      sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
      sudo iptables -A INPUT -p tcp --dport 9418  -j ACCEPT
      sudo iptables-save

3.2 配置端口映射    
&emsp;&emsp;在主机的管理员Windows PowerShell中配置端口映射。    

      netsh interface portproxy add v4tov4 listenport=9418 listenaddress=0.0.0.0 connectport=9418 connectaddress=172.19.110.236
      netsh interface portproxy add v4tov4 listenport=22 listenaddress=0.0.0.0 connectport=22 connectaddress=172.19.110.236

3.3 关闭主机防火墙      
&emsp;&emsp;Windows 10默认开启防火墙，会导致其它机器无法访问git服务，可以调整防火墙中的端口。简单操作，可以直接关闭防火墙。    
&emsp;&emsp;打开"控制面板"-->"防火墙"-->"启动或关闭防火墙"，关闭防火墙。    

3.4 修改manifest仓库定义    
&emsp;&emsp;git仓库开放给其它主机访问，需要把manifest仓库中default.xml的仓库地址改为主机ip。      

      <?xml version="1.0" encoding="UTF-8"?>
      <manifest>
         <remote  name="origin"
                  fetch="git://your_ip/and6r81" />
         <default revision="master"
                  remote="origin"
                  sync-j="4" />
                   
         <project path="build" name="platform/build" groups="pdk" >
         ..........
      </manifest>      

3.5 验证代码仓库   
&emsp;&emsp;修改完成后，在其它主机上验证repo下载代码。   

      repo init -u git://your_ip/and6r81/manifest.git
      repo sync

4.每日迭代编译环境      
&emsp;&emsp;Android代码一般编译时间比较长，我们可以用jenkins工具在晚上时间自动完成每日迭代编译。    
4.1 安装jenkins工具    
&emsp;&emsp;我们在客户端安装jenkins，可以直接编译代码。    

      wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
      echo deb http://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list
      sudo apt-get update
      
      #如果出现以下错误
      ......
      Reading package lists... Done
      W: GPG error: https://pkg.jenkins.io/debian-stable binary/ Release: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY FCEF32E745F2C3D5
      E: The repository 'http://pkg.jenkins.io/debian-stable binary/ Release' is not signed.
      N: Updating from such a repository can't be done securely, and is therefore disabled by default.
      N: See apt-secure(8) manpage for repository creation and user configuration details.
      
      sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FCEF32E745F2C3D5
      sudo apt install jenkins

&emsp;&emsp;jenkins安装源在国外，下载速度比较慢，也可以下载deb安装包安装。    

      wget  https://mirrors.tuna.tsinghua.edu.cn/jenkins/debian-stable/jenkins_2.249.2_all.deb
      sudo dpkg -i jenkins_2.249.2_all.deb

&emsp;&emsp;安装过程中出现daemon包缺失的错误时，

      sudo apt -f -y install

&emsp;&emsp;安装完成后，启动jenkins服务。    

      service jenkins start

&emsp;&emsp;服务器启动后，在本机用浏览器登录jenkins后台。     

      http://localhost:8080

&emsp;&emsp;按照提示解锁Jenkins，安装推荐插件后，就可定义任务。     


5.参考资料        
&emsp;&emsp; https://docs.microsoft.com/en-us/windows/wsl/compare-versions#accessing-linux-applications-from-windows  

----
&emsp;&emsp;安微云是国内领先的基于Arm架构的云技术团队，提供虚拟化、数据分析、数据存储、文本处理、语义分析、自动化脚本等企业级云技术及服务。  
&emsp;&emsp;更多信息，请关注"安微云"公众号。