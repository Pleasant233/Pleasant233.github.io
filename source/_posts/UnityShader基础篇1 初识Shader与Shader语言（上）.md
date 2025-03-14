---
title: 'UnityShader基础篇初始Shader与Shader语言（上）'
date: '2025-3-14'
description: 简单介绍UntiyShader的基本概念与着色语言
top_img: https://pleasant233.oss-cn-beijing.aliyuncs.com/SnowMountainWithCloud.png
cover: https://pleasant233.oss-cn-beijing.aliyuncs.com/SnowMountainWithCloud.png
categories: UntiyShader基础篇
---
# 1.0 概要
* 这是一个全新的篇章，经过一学期的图形学基础学习，相信我们已经对画面如何呈现在屏幕上的过程有了一个大概的认识，接下来，我们将对UnityShader进行系统性的学习，我们将实践之前提到的一系列理论知识，并了解其在实际引擎中使用。
* 根据上一学期的课程经验，我们将尽可能使用理论化的语言和规范的流程进行讲解，便于大家的学习理解。每节课都将会从理论→实践→思考的形式呈现。
---
# 1.1 初识UntiyShdaer
* 在之前的渲染管线学习中，我们了解到，对于目前引擎中的可编程渲染管线（SRP），我们可以编辑的部分主要是顶点着色器（VertexShader），片元着色器（FragmentShader）。
* 详情： [[入门图形学6——渲染管线综述]] 
* [入门图形学6——渲染管线综述](https://pleasant233.github.io/2024/12/21/%E5%85%A5%E9%97%A8%E5%9B%BE%E5%BD%A2%E5%AD%A66%E2%80%94%E2%80%94%E6%B8%B2%E6%9F%93%E7%AE%A1%E7%BA%BF%E7%BB%BC%E8%BF%B0/)
* 为了便于学习，我们在这里再回顾一下什么是渲染管线而由此推出什么是Shader的定义。
---
# 1.2 渲染流水线

* 渲染流水线就是电脑内存中的几何数据经过一系列处理，呈现在屏幕上被我们观察到的过程，大概可以分为三个阶段，分别是：应用阶段，几何阶段，光栅化阶段。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250216101745.png)
	`2.1. 渲染流水线`
---
## 1.2.1 应用阶段
* 应用阶段主要是CPU负责的，我们在软件中处理数据时主要发生在这部分，详细的内容我们已经在之前的教程提到过了，欢迎回顾[[入门图形学6——渲染管线综述]]
* 我们将需要处理的数据模型准备好，以及将一系列的渲染所需数据，如贴图，灯光，uv等传入显存，便于进入下一个阶段处理，这里的数据便成为渲染图元（rendering primitives）
* 渲染状态同样是重要的参数之一，渲染状态就是如何渲染该物体，包括最基本的Color，纹理tex，着色器Shader等。
---
## 1.2.2 几何阶段
* 从此处开始，我们便进入了GPU接管的阶段，也是我们编程面向的阶段。在这里我们将应用阶段传入的**几何图元**进行相对应的操作，它可以是逐顶点，逐多边形等等，我们会在后面介绍，这部分所对应的就是我们的VertexShader（顶点着色器）。
* 我们在入门图形学中详细介绍了*坐标变换*的相关知识，这是为了让我们更好的理解顶点着色器所做的事，那就是将顶点坐标变换至屏幕空间，最后输出到屏幕上。
* 最后传出到光栅化阶段的是二维坐标，深度值，着色信息等。
---
## 1.2.3 光栅化阶段
* 光栅化阶段所进行的操作就是针对每个像素进行插值运算，最后生成屏幕上的图像，这一部分对应的着色器便是FragmentShader（片元着色器）。
* 因此我们所做的操作是逐像素的，相对开销比较大，但效果会更好。
* 这一阶段往往合并了各类测试，比如**深度测试，模版测试，透明度测试**等，我们会在后续认识这些部分。
* 最后是对于呈现本身，我们会将每一次渲染的图像存储在Color-buffer里，这也是所谓的帧缓冲，我们将对其进行混合操作，如覆写，或更复杂的计算。
* 在这里我们会应用一种叫做双重缓冲（Double-Buffer），渲染永远发生在后一个Buffer中，等渲染完则会调换两个缓冲的前后顺序保证呈现最连续的画面。
---
# 1.3 图形API与Shader
## 1.3.1 图形API
* 对于我们而言实际上了解这些知识就是为了编写着色器，所以对于UnityShader而言，我们只需要在Shader文件中设置一些输入和着色器片段内容，就可以呈现大部分效果。
* 但实际上Shader本身就是一个文本文件，最后的一切操作，都交给Unity以及图形API来完成。
* 我们在之前已经简要了解了诸如OPenGL，DX等API，它们的作用就是更加方便的与GPU沟通，通过调用API，我们可以控制图形驱动调用GPU硬件，从而完成实际的计算。
* CPU到GPU的过程则是从CPU内存中传入GPU显存中的过程。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250216105921.png)
	`1.3 API在渲染管线所处的位置`
---
## 1.3.2 Shader语言
* 对于可编程的着色器阶段，我们需要用一系列语言来编写程序，就比如我们在对CPU编程使用的C语言等。
* 而对于GPU，不同的API对应了不同的着色语言，最常用的为OPenGL对应的GLSL，DX对应的HLSL，以及NV的CG
* 上述语言中，HLSL对于游戏编程更为常用，最值得学习，而Unity使用的则是NV的CG语言，已经很久未更新，但由于其语言风格更类似于C语言，并且针对不同平台可以生成对应的底层代码，因此跨平台性更佳，再加其与HLSL语法几乎一样，因此我们将主要学习CG语言，而在后续进阶内容中我们将利用HLSL实现更加复杂的效果。
---
## 1.3.3 什么是Shader
* 现在，我们就可以来总结何为Shader了，Shader就是GPU流水线上一段高度可编程的部分，由GPU执行，本质上就是告诉GPU该如何处理数据。
* 主要分为顶点与片元着色器，当然还有特殊的诸如路径追踪着色器，计算着色器等。
* 如果将Shader比作加工方式，那贴图数据就是素材，成品就是材质。
* 我们主要学习的Shader语言为CG之上封装的Unity的Shaderlab语言，实际上就是有很多宏定义以及函数可供我们调用，便于实现效果。接下来我们就将正式进入着色器实际编写环节，本次以及下次课，我们将完成一个简单的着色器，随后我们就可以正式进入Shader的世界，编写多种多样的效果。
---
# 1.4 ShaderLab语法与概念
* 在这一部分，我们将介绍Unity中的着色器相关内容与Shaderlab语法基础，各位可以跟随实践，代码都将附加在文内，方便各位尝试。
## 1.4.1 创建Shader文件
* Unity版本：2022.3
* 在Unity中，每一个材质都会至少对应一个着色器文件，如果我们创建一个材质，那么它会自动添加一个默认的Shader，它具备基本的光照，颜色等信息。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250216113441.png)
	`1.4.1 Material的属性面板`
---
* 我们可以发现这个材质有一系列的参数可以供我们调节，其中由上自下大致可以分为三个区域，Shader选择框，数据参数面板，以及预览面板。
* 我们先来关注Shader选择框，在这里，右侧编辑栏内，我们可以选择特定的Shader，进行处理，点击Editer我们就可以打开Shader面板，最终呈现在我们面前的便是一个Shader文件了。
* 当然我们也可以单独创建Shader文件，在主界面下方文件面板中右键创建一个Standard Surface Shader（标准表面着色器并且右键打开它，这时会吊起Vs编辑器，最后呈现在我们眼前的便是实际的Shader文件了。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250217105653.png)
	`1.4.1.1 Shader文件面板`
---
* 其中我们会注意到一系列参数，后面我们会详细讲解最关键的我们可以注意到最下面一组*Properties* 参数，这就是我们可以从引擎传入的部分。 
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250216115552.png)
`1.4.1.2 Shader文件`
* 表面着色器实际上就是由*顶点着色器与片元着色器组合而成的*，因此我们仍然可以通过顶点和片元着色器去解构理解。
* 如果我们在图1.4.1.1中点击show Code generate我们就可以看到Untiy引擎为我们编译的顶点与片元着色器代码 
* 对于compile and show code，在后期，我们可以查看对应不同平台编译出的汇编代码，并对其进行调节和优化
---
## 1.4.2 ShaderLab
* ShaderLab实际上是Unity对着色语言的一层上层抽象，它为我们保留了着色语言的基本语法，并封装了许多计算，效果宏函数供我们调用。
* Shaderlab是一种说明性语言，不论我们写何种语言，Shaderlab都会对其进行包装。它使用了一些嵌套在花括号内的语义来描述一个UntiyShader文件的结构，包括了所需数据，着色器属性，渲染状态设置等。所以其**不仅包含着色器代码**并且还包含了显示一个材质所需的所有东西。
![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250217095033.png)

	`1.4.2 UnityShader与Shaderlab的作用`
---
* 通过观察图1.4.1.2我们可以发现，任意一个Shaderlab代码都包含以下内容
```shaderlab
Shader"Name"//Shader名称与路径
{
	Properties{//Shader对应的属性值
	}
	SubShader{//顶点，片元着色器等
	}
}
FallBack "Name"

```
* 我们可以总结出大概分为四个部分，分别是名称，Properties，SubShader，FallBack。接下来我们一一介绍。
---
## 1.4.3 Shaderlab结构
* Shader所对应的名称就是其路径，比如图1.4.1.2中，该Shader为
```Shaderlab
Shader "Custom/TestShader"
```
* 那么它就是Custom下的TestShader，每一个Shader都有一个独属于自己的路径。
---
* Properties是Shaderlab所必备的属性框对应了引擎界面中的属性面板，至少有一个，属性的格式要包含名称，显示名称，类型，和默认值，如果没有指定默认值，Untiy会自动默认一个值，对于数据来说通常为0，其余如字符串则有特定默认值。
```shaderlab
_Name("displayName",PropertyType) = DefaultValue;
```
* 以下是常用的数据类型
![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250217103917.png)
`1.4.3 Properties常用属性值`
* 如果在着色器中编写就是这样的，随后在面板中我们就可以设置数值。
```ShaderLab
 Properties
 {
     _Color ("Color", Color) = (1,1,1,1)
     _MainTex ("Albedo (RGB)", 2D) = "white" {}
     _Glossiness ("Smoothness", Range(0,1)) = 0.5
     _Metallic ("Metallic", Range(0,1)) = 0.0
 }
```
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250217104613.png)
`1.4.3.1 Shader对应着色器面板中的数值效果`
---
* Shader代码通常包括至少一个**SubShader**，GPU会顺序检测SubShader是否能执行，假如均无法执行则可以回退到一个能够执行的基本着色器。
* 每个SubShader中有若干个Pass，每个Pass都是一次完整的渲染流程，而Pass之间会按照指定的顺序进行混合。最终输出。而每个Pass中就会包含诸如顶点，片元着色器等模块。
* SubShader的大概结构是这样的
```Shaderlab
SubShader{
[Tags]//标签
[RenderSetup]//渲染状态
Pass{
}
……
}
```
---
* 其中Pass是必须的，而RenderSetup是可选的，我们可以设置显卡的各种状态，如剔除，测试选项等，对应渲染管线的不同阶段，这也被成为可配置的。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250217110356.png)
`1.4.3.2 渲染设置`
* 如果在SubShader开头设置则默认作用于所有Pass，而若想单独设置，则可以在特定Pass上单独定义。
---
* 而对于标签而言，标签Tags实际上是一个键值对，它的键值均为字符串类型，这些是其与Unity沟通的方式，它们主要定义如何，以及何时渲染这个对象。
```
Tags{“TagName1” = “Value1”}
```
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250217111202.png)
	`1.4.3.2 渲染标签类型`
* 最常用的设置有：渲染队列Queue，渲染类型RenderType等。
* 渲染队列主要可分为：Background，Geometry，AlphaTest，Transparent等，它们对应了不同的渲染顺序，我们也可以自行设置物体在渲染队列中的位置比如
```Shaderlab
Tags{“Queue” = "Geometry+1"}
```
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250217115544.png)
`1.4.3.3 渲染队列前后顺序`
---
* 而对于渲染类型RenderType而言，我们可以指定该物体渲染作什么物体用于后期的渲染替换以及使用相机深度纹理。
* 常用的渲染类型有：Opaque用于普通Shader，比如不透明，自发光等，Transparent用于半透明Shader。以下是渲染类型的大致表格。
	![89160f4a8d94f8ecc6f8398c8621604.jpg](https://pleasant233.oss-cn-beijing.aliyuncs.com/89160f4a8d94f8ecc6f8398c8621604.jpg)
	`1.4.3.4 渲染类型概览`
---
* 此外我们还可以针对是否开启批处理DIsableBatching，是否接受阴影投射IgnoreProjector进行控制，这些都属于Tags的范围，可见Tag标签非常强大。
---
## 1.4.4 Pass部分
* Pass部分就是我们实际编写Shader最主要代码的部分，UnityShader为我们提供了一个很好的框架，在非引擎情境下，我们要编写Shader代码，往往各个着色器需要分开编写，由于Shaderlab是标记性语言的特点，我们实际上只是在**编辑文本**，而Unity在编译时会将制定代码块内的内容，复制编译到对应的着色器部分，这大大减轻了我们的工作量，可以只在一个文档内完成。
* 先前提到，Pass是一个渲染流程单位，它代表一个渲染流程循环，结合之前我们所学的知识，渲染管线分为应用（A），几何（G），光栅化（R）三个阶段。
* 而自然而然，Pass也可简单看做由三部分组成：
	* 应用参数，数据
	* 几何阶段（顶点着色器）
	* 光栅化阶段（片元着色器）
* 因此，我们也将这样来学习最重要的Shader代码核心区域。
---
* Pass区域的代码大致可以看做是如下的形式
```shaderlab
Pass{
	Name “” //该Pass的名称
	Tags //标签
	RenderSetup//渲染设置
	other
}
```
* 首先是名称部分，我们可以给任意Pass命名如：
```shaderlab
Name "myFirstPass"
```
* 这样我们在外部任意一个Shader文件中，只需要使用UsePass制定就可使用，但注意一点，UnityShader引用Pass**只支持全部大写**！
```shaderlab
UsePass “MyShader/MyPass”
```
* 此外，Pass同样可以设置标签和渲染设置，只不过与SubShader有所不同的是，标签的作用不同。
*  ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250218092802.png)
	`1.4.4 Pass的标签设置`
---
* 此外，还有一种特殊的Pass，叫做GrabPass，这个Pass可以抓取屏幕结果并将其储存到一张纹理中，用于后续处理。
## 1.4.5 FallBack
* FallBack的主要用途是如果所有的SubShader都在此显卡无法运行，则回退到FallBack所指定的Shader文件中去。语法大概是这样的
```shaderlab
{}
……
FallBack “Name”
or Fallback Off
```
* 当然Fallback不有这个用途，FallBack还可以影响阴影投射，正在渲染一张阴影图也就是ShadowMap时，Unity会在每个UnityShader中寻找一个投射阴影的Pass，而我们通常不需要自己实现，只需要利用FallBack指定一个内置Shader即可。后续会详细介绍。
* Shaderlab还有其他语义，我们会在后续自定义材质面板的过程中讲解到。
---
# 1.5 结语 与参考资料
* 恭喜你，我们已经完整认识了UnityShader的几乎所有基础内容，下一步，我们将深入细节，真正完成一个可以正常渲染的Shader。现在我们可以将整个Shader的架构写出来了！
```Shaderlab
Shader“MyShader”{ //Shader名称
	Properties{
		Name（DisplayName，PropertyTYpe） = defaultValue;
		……
	}
	SubShader{
		Tags[]
		RenderSetup[]
	Pass
	{
		Name
		Tags[] *
		RenderSetup[]
		ShaderPrograms{}
	}
	……
	}
	FallBack“”
}
```
* 现在想必你应该能看懂先前我们创建的Shader文件了！
---
* UnityShader入门精要 冯乐乐著
* UntiyShaderlab 新手宝典 唐福幸著