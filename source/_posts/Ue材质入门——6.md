---
title: 'Ue材质入门——6'
date: '2024-10-25'
description: 三角函数节点以及棋盘格实现
top_img: https://pleasant233.oss-cn-beijing.aliyuncs.com/ring-7218706_1920.png
cover: https://pleasant233.oss-cn-beijing.aliyuncs.com/ring-7218706_1920.png
categories: Ue材质入门
---
# 棋盘格

* 我们来看一个有趣的效果，顺便介绍UE中常用的三角函数节点。
* 上一节我们已经初步认识了三角函数的威力，学习并分析了arctan节点
* 今天，我们从最基本的sine和cosine节点来认识Ue中的三角函数节点以及作用。

* 效果分析：我们需要实现黑白相间的棋盘格，本质上就是黑白的重复，我们可以用PS简单实现一下，供我们分析！
## PS中的实现

* ![imag.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/%E6%A3%8B%E7%9B%98%E6%A0%BC.png)
* 我们可以观察到，这个图形是由黑色（0）以及白色（1）区域构成的，那么我们需要考虑如何实现这个排序，黑色可以通过乘法得出，我们可以利用Mask节点，将这张图横竖分开，并进行操作，让它变为横竖都是黑白相间的纹理，这就要隆重介绍我们今天的主角——sine节点。
## SIne节点

* SIne节点作为一个三角函数节点，它模拟的就是三角函数的数值，它有一个周期参数，并且拥有三角函数的最大值最小值，它接受一个标量并将其进行三角函数运算，会出现波峰和波谷，波峰为正值而波谷为负值
* 在Ue中就会显示为黑白相间的条纹颜色！
*  ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241014094712.png)
* 如上图所示，这样我们就可以利用它来创建网格了！
# 网格的实现

* 网格需要横向和竖向的排列，因此我们需要将原有的纹理坐标节点使用mask节点拆分为R通道与G通道，分别对其进行计算

* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241015150346.png)


* 随后，为了控制纹理细分数量，我们为两个拆分后的节点分别添加Multipl乘法节点，并且新建一个常量数值接入他们，我们通过控制常量的大小来控制网格的数量，实际上是控制uv的缩放
* 随后我们分别为这两个节点添加SINE节点，这样，我们就可以在SINE节点的预览窗口中观察到条纹状的纹理了

* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241015150409.png)


* 而后，我们需要考虑如何混合这两个结果，我们需要让黑的部分叠加白的部分，并保留下来，因此我们使用Multipl节点将两个结果值相乘，这样黑色（<0）的部分就会被保留，因为0乘以任何数仍为0，于是我们就得到了一张有些模糊的网格图。

* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241015150436.png)

* 这看起来还有些不对，因为sine得出的有很多非整数结果，它们导致我们的边缘值比较模糊（再次记忆我们的颜色值始终置于0,1之间）
* 因此我们需要将它们取整，我们使用Ceil节点，将其取整，这个函数我们高中就学习过，大于0的值会变为1,1-2则变为2，因此他们会取整为1，这样我们的边缘值就正常了！
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241015150455.png)
---
