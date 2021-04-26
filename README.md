#  "动态马甲包安装文档"：

##  已验证环境 centos7,8

### 1. 安装环境步骤

-  git安装
    - 查看git是否已安装
      - 执行 **git**
       - 如未安装
         - 执行 **yum -y install git**
    - 执行 **git clone https://github.com/YangChengTeam/vestbag.git Scripts**
    - 执行 **cd  Scripts**
    - 执行 **sh install.sh**
    - 命名结束后  再次执行**sh install.sh**检测环境是否安装成功
- zip安装
    - 查看unzip是否已安装
       - 执行 **unzip**
       - 如未安装
         - 执行 **yum -y install unzip**
    - 执行 **unzip -d Scripts vestbag.zip**
    - 执行 **cd  Scripts**
    - 命令完成后  再次执行**sh install.sh**检测环境是否安装成功

### 2. 打包
- 上传所需文件
    - 拿到需要打包的马甲类型id (比例：48 )
        - 将需要打包apk命名为48.apk 以及签名文件redguess.jks  上传到Scripts
        - 如需角标 
            - 文件名角标jb48.png 
            - 文件大小格式按![jb.png](jb.png)
- 执行预打包脚本
    - 执行 **sh squick.sh -a 48.apk -t 48 -d 1 -g 1**
    - 会生成一个48.config 在其中配置签名信息
        - 在其后追加签名信息 比如
           - jks_path="redguess.jks"<br/>
             jks_ali="redguess"<br/>
             jks_pass="123456"<br/>

- 观察日志是否测试包已打成功
   - 未成功
      - 分析原因解决
- 测试test48.apk
   - 下载test48.apk到本地
   - 查看版本号 签名等信息
   - 安装测试是否正常
- 运行打包进程
    - 未执行过
      - 执行 **sh squick pm start 44**
    - 已执行过
      - 执行 **sh squick pm restart**
    - 查看日志观察打包情况
      - 执行 **sh squick pm log**    
### 3. Q&A

- 1.q&a. $'\r':command not found
    - windows文件传到linux问题
      - 执行 **yum -y install dos2unix**
         - 执行 **dos2unix \*.sh**
         - 执行 **dos2unix \*.js**

- 2.q&a. squick.sh 有哪些功能
   - 执行 **sh squick.sh -h** 获取帮助
   - 执行 **sh squick.sh -a 48.apk -t 48 -d 1 -g 1** 预处理资源 更新母包 删除所有马甲包文件 并打一个测试包
   - 执行 **sh squick.sh -t 48 -g 1**  仅打一个测试包
   - 执行 **sh squick.sh -a 48.apk -t 48 -c 0 -g 1** 预处理资源 不更新母包并打一个测试包

   - 执行 **sh squick pm start**    启动打包进程并开机启动
   - 执行 **sh squick pm restart**  重启进程
   - 执行 **sh squick pm stop**  停止进程
   - 执行 **sh squick pm log**  进程日志

   - 执行 **sh squick fs check**  检测包的有效性
   - 执行 **sh squick fs clean**  清理临时文件





        
  


