---
title: 'Ue材质入门——4'
date: '2024-10-17'
description: 虚幻引擎中的数据纬度控制以及运算节点
top_img: https://pleasant233.oss-cn-beijing.aliyuncs.com/ring-7218706_1920.png
cover: https://pleasant233.oss-cn-beijing.aliyuncs.com/ring-7218706_1920.png
categories: Ue材质入门
--- 
# 数据维度的控制

* 在UE中，我们可以利用一些节点来进行数据的拆分与提升，例如在UV方向上，我们就可以利用掩码节点Mask来进行通道的拆分，如下图所示，我们将原本的UV节点拆分为R(U)通道以及G(V)通道：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241001184403.png)
* 同样，我们也可以利用节点将他们合并起来，对于合并输出节点Ue提供了基础的Append节点以及封装多个Append节点从而实现多个输入的MakeFloat系列节点，他们都可以接受两个以上的参数并将他们合并输出：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241001184606.png)

# 色彩维度的控制

* UE中图片的色彩控制有以下几种：
	* Add节点的加法调节
	* Multiply节点的乘法调节
	* Power节点的乘方调节
	* CheapContrast与CheapContrastRGB的灰度和对比度调节
	* 以及1-x节点的取反调节
	我们逐一进行介绍
---
## ADD节点

* 首先是Add节点，这一节点主要功能就是为原图像加上一个常量，因为图像输入的是RGBA通道值，就会为这些值加上一个量，如果大于1，则会为白色，这与我们之前了解的相同
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241001194813.png)
 ---
## Multiply节点
 
 * 随后是Multiple节点，这一节点可以在原有通道的基础上，乘上一个常量，如果常量小于1，则会让整体变暗，大于一则变亮
 * ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241001203147.png)
---

 ## Power结点
 
 * 再之后是Power节点，POW节点是指数节点，可以让原来的值乘以n次方，会让暗的地方更暗，亮的地方更亮
 * ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241001203430.png)
---
# CheapContrast以及RGB

* 这两个节点分别是针对单通道的灰度调节节点以及针对三通道的对比度节点，实际区别就是接受的数据不一样，本身都是调节黑白灰关系的节点，为了让图片对比度更加明显：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241001203647.png)
---
## 1-x节点

* 这个节点是为了取反操作而诞生的，本质上就是统一进行一个偏移，也就是减去1，这样图片的整体输出就截然相反了：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241001204112.png)
---
# 一些额外的注意点

* 在上文提到POWER节点与CheapContrast节点都能让暗部更暗亮部更亮，而它们之间有什么区别呢？
* 答案是，他们的作用区间不一样，前者是在0-1之间，而后者则是以0.5为中间值进行变换，我们实践就会发现，结果就是：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241001204718.png)
---
# UV的运算

* UV节点可以控制一个纹理的缩放，本质是调整一个纹理的坐标位置，而模型的UV则与之无关，就好比UV是皮肤而纹理坐标是衣服，UV节点调整的是怎么穿这件衣服。
* UV节点有几个重要参数：
	* U方向偏移量
	* V方向偏移量
	* 解除镜像U
	* 解除镜像V
## U，V方向偏移量

* 这两个参数控制的实际上是UV数值的大小，视觉上的效果就是UV相较于模型坐标的缩放大小，比如若增大UV的坐标，那么多出来的部分（因为UV本是0-1）就会平铺填充同样的图像：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241001214316.png)
* 我们可以用ADD节点或Multiply节点来控制这个过程：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241001214413.png)
## U,V方向镜像解除

* 本质上，我们通过UV节点调节的纹理，是以0.5为中心调节的，若解除这一镜像，我们就会得到从0.5开始的纹理图像：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241001214651.png)
* 上面的图像就是画面的下四分之一，也就是上端为0.5，左端为0.5的方式，这可以帮助我们进行一些的运算
---
