---
title: 博客搭建感想
sticky: 1
---
# 主要流程
 * 本地化部署流程
 * 线上发布流程
---
## 本地化部署
 * 前期准备
   * 首先，本地化部署需要提前安装好两个东西，
     可参考hexo框架官网：https://hexo.io/zh-cn/
   * 需要下载node.js，同时下载npm，也就是版本管理器，这些可以帮助我们管理博客版本内容。
     * node.js 官网：https://nodejs.org/zh-cn
     * 你可以直接在官网复制它的代码并且打开本地自带的Windows命令窗口：powershell，粘贴你复制的代码
     * 等待安装完成就可以了 
   * 下载git，git主要作用是建立起云端和本地之间的桥梁，让我们能够从云端拉取数据。
     * 同样可以在官网下载：https://git-scm.com/ 
     * git安装相对简单，你可以直接全部选择next就自动安装完成了，很无脑！
   * 在安装完成后，本地的环境就基本上搭建完成了。 
## 线上发布：
   * 首先访问：https://github.com/mmdjiji/hexo-template 获取该库的代码，并且由此新建一个库，
     详细教程可参考：https://www.bilibili.com/video/BV1Bu4y1d7YF/?spm_id_from=333.999.0.0&vd_source=a506bd54314456e886d3818e488bb1c8
   * 断点发生在使用spacecode编辑处，因为该方法是完全基于云端的部署，所以完全依赖虚拟机的网速
     然而经过多方验证，虚拟机网速堪忧，因此在此我们选择在本地部署！
## 独家揭秘！
   * 本地化部署就是本教程独一无二之处，大部分教程都会将两者割裂，但本教程才是最无脑的过程，
     前文我们已经提到，云端部署十分缓慢，那有没有办法加快这个速度呢？
   * 答案当然是有的！我们可以利用githubdesktop更快捷的进行上传与下载，避免云端网速的问题！
  ### github的使用
   * 首先，下载githubdesktop，这个在你的库里local选项就能下载，为了方便起见，本文还是给大家配图
   * 配图使用PicGo，同样也会给大家介绍，并且介绍obsidian中的PicGo联动小功能！
  <img src ="https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202024-09-12%20111142.png">
   * 下载安装完成后，我们就可以将线上的库克隆到本地了，这里各位自行摸索即可，很简单，就不再赘述
  ### 在bush窗口中完成部署 
   * 克隆完成后，我们需要再本地进行编辑，首先，找到克隆库所在本地文件夹，在文件夹中右键
   * 打开选项栏，选择open git bush here
   * 然后我们就嫩得到一个这样的窗口，很好，你已经几乎要完成它了！
  <img src="https://pleasant233.oss-cn-beijing.aliyuncs.com/20240912111820.png">
   * 随后，我们需要先安装hexo框架，在对话框中输入：
   `$ npm install -g hexo-cli `
   * 等待安装完成，在这里你可以加速这个过程，可将上述代码替换为：
   `$ cnpm install -g hexo-cli`
   * 这是一个国内镜像，但前提是你需要下载它，你可以通过powershell输入：
   `npm install -g cnpm --registry=https://registry.npmmirror.com `
   下载完成后，之后的所有需要npm的代码就都可以用cnpm替换了
   * 之后我们继续键入`cnpm install`来安装依赖，请确保你进行了上一步！
   * 在此之后，我们就完成了全部部署，你可以输入`hexo g`来检测部署结果
   * 注意！按此方式部署的hexo是局部的，所以需要输入`npx+hexo...`命令！注意区分
   * 若如图所示，则说明部署完成：
  <img src ="https://pleasant233.oss-cn-beijing.aliyuncs.com/20240912112800.png">
   * 请注意，上图中，butterfly字样是主题，若未安装是不会显示的，这无伤大雅。
  ### 配合github上传
   * 第一阶段我们的githubdesktop就排上用场了，你只需要在面板中点击commit，
   * 随后点击push origin 上传到云端即可了，返回到github库主页面，点击setting，查看page页面更新消息，你可以按F5刷新页面，不过多久，一个网站就搭建好了，并且你可以在本地完全控制它！
---
# 结尾
   * 这是我的第一篇真正的博客，讲解了如何优雅而简便的搭建一个你的博客，接下来我会更新后续的内容，包括技术美术全部相关学习心得，笔记，随笔，图形学系列课程，希望能共同学习交流，那么最后一步！
   * push to origin！
---
# 参考链接与项目
 * 1.hexo官网：https://hexo.io/zh-cn/
 * 2.b站up主：方欲遣兵北逐胡的视频：【基于Hexo搭建本地博客并部署到云服务器教程】 https://www.bilibili.com/video/BV1qU4y1K7Hk/?share_source=copy_web&vd_source=18d60239a339ad21d3b3f050742622f4
 * 3.b站up主：吉吉学长的视频：【【Hexo | 03】创建属于你的追番列表】 https://www.bilibili.com/video/BV1Bu4y1d7YF/?share_source=copy_web&vd_source=18d60239a339ad21d3b3f050742622f4
 * 全部为开源项目，不承担任何责任！！