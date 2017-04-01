
# xcpack.sh
一条命令行实现smba连接，版本号加1，打包，上传，生成固定格式通知功能。当然你也可以通过简单的配置进行功能的删选。

使用:
```
    sh xcpack.sh
    sh xcpack.sh -p
```
---
功能:
- 1.使用配置smba账号自动连接到共享服务器
- 2.多个target(targetName & targetNameToday)的版本号同步自动升级,build号加1
- 3.打包，上传smba服务端，如果带 “-p” 参数将上传fir
- 4.生成发包信息文本格式(格式如下)并拷贝到剪切板，显示器右上角出现上传smba服务端成功之后，就可以直接粘贴(Command+V)
```
        iOS Sprint13 Preview
        bundleVersion:1.6.1.466
        WebInstall: http://fir.im/xxx
        SmbaInstall: /Volumes/互联网产品中心/项目/WeChat/iOS/V1.6/1.6.1正式环境/WeChat1.6.1.466.ipa
```
---
运行步骤:
- 1.自动连接smba服务
- 2.版本号自动升级是通过访问smba全局变量来实现，第一次没有读取到会提示输入一个默认的(现有的)版本号;若没有连接smba则读取本地build号进行升级。
- 3.清除缓存，编译，打包生成ipa文件到本地 xcrunBuild路径下
- 4.按照之前的ipa文件在smba上的路径放置方式，拷贝到对应路径下如下，如果没有对应路径会自动创建，成功则会自动打开文件夹
    - Path: /Volumes/互联网产品中心/项目/WeChat/iOS/V1.6/1.6.1正式环境/WeChat1.6.1.466.ipa
- 5.提示发包文本信息已拷贝，若"-p"，上传fir。

---
配置: 
   > 只需配置你需要的功能部分，例如需要用到smba服务就需要配置smba用户名，密码和分享目录；用到fir功能就要配置fir的token
   > 依赖: xcpretty (sudo gem install xcpretty), xcodebuild

基本配置:
    
```
    注意exportOptions.plist的teamID和method设置对应的值
    TARGET_NAME=xxxx 
    BUILD_CONFIGURATION=Debug # the build configuration of current scheme
```
    
smba配置：
```
    smbaUserName="username" 
    smbaPassword="password" 
    smbaDirectory="192.168.23.15/xxx/xxxx" 
    mountedDirectory="/Volumes/$TARGET_NAME" 
```
fir.im 配置：
```
    FIR_TOKEN=xxxxxxxxxxxxxxxxxx 
    FIR_SHORT_LINK=http://fir.im/xxx
```
