---
title: 'Ue材质入门——7'
date: '2024-10-26'
description: 虚幻引擎中的法线与其运算
top_img: https://pleasant233.oss-cn-beijing.aliyuncs.com/ring-7218706_1920.png
cover: https://pleasant233.oss-cn-beijing.aliyuncs.com/ring-7218706_1920.png
categories: Ue材质入门
---
# 法线底层原理

* 法线是赋予模型材质凹凸感的工具，其本身实际上是一组组的向量数据，通过光线与这些向量数据做矩阵运算，来得到凹凸效果
* Bump贴图和Normal贴图：
	* 两者都可以用于实现法线所能够实现的凹凸效果，但Bump只有单一的凹陷凸起变化，而法线则是可以向四面八方进行变化，因此它们视觉上的颜色也是不一样的
	* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241015153242.png)
	* 不同的颜色代表不同的方向，这一点前文我们已经了解过了，其本质是对颜色通道的映射，因为颜色通道RGB本身也可以视作一种向量（颜色向量）
* 面法线与顶点法线：
	* 每个顶点自然都有自己的法线方向，而面法线是通过对一个面片上的顶点法线（通常为3个）进行插值得到的。
---
# 法线与光照运算

* 在图形学的学习过程中我们了解到，很多光照模型都加入了法线来进行不同着色程度的运算，这里我们可以简单抽象为：
	* 若法线方向与光照方向相反则为-1(注意计算中光线方向是由物体指向光源)
	* 若法线方向与光照方向垂直则为0
	* 若法线方向与光照方向相同则为1
* 以上，我们可以简单得出一个拥有明暗交界面的材质：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241015154216.png)
---
## Ue中的实现

* 我们通过调取光源方向节点SkyAtomsphereLightDirection，用Dot节将其与VertexNormal节点做点积运算，最后得到一个上述效果的材质：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241015154449.png)
---
# 法线贴图的数据原理

* 法线贴图是在切线空间的，而切线空间中的x，y轴分别为tan与bitan也就是切线与副切线，而与他们垂直的就是法线：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241015154804.png)
* 根据这个原理，我们就可以进行一定的数据运算，来实现法线凸起的效果，因此我们可以分析出一张法线贴图实际上是分别具有三个颜色通道的值，分别代表tan，bitan方向上凸起程度，加在一起便成为了一张法线贴图，因此使用法线时需要使用RGB通道：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241015155058.png)
* 根据上面的原理，我们可以自行验证一下，三个方向是不是具备相互垂直的关系，我们利用dot节点和Append节点来用GB两个通道的值来代替R通道的值：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241015160239.png)

  * R点积G得到的是除B通道外的值，因为这两个方向是互相垂直的，点积为0，取反之后得到的就是B通道的值了。不要想复杂哦！
  # 不同的法线贴图
---
* OpenGL法线与DirectX法线：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241015165216.png)
* 他们的最大区别是轴向不同，导致的结果就是代表的方向不同，会导致模型表面突出方向倒置，区别方法就是看符合左手坐标系还是右手坐标系，OpenGl右手DirectX左手，分别对应逆时针和顺时针
* 我们可以对其进行简单的取反操作来让轴向改变，由此来转换不同的贴图。
---
