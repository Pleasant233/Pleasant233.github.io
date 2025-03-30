---
title: 'UnityShader基础篇2——初识Shader与Shader语言（下）'
date: '2025-3-22'
description: 简单介绍UntiyShader的基本概念与着色语言
top_img: https://pleasant233.oss-cn-beijing.aliyuncs.com/SnowMountainWithCloud.png
cover: https://pleasant233.oss-cn-beijing.aliyuncs.com/SnowMountainWithCloud.png
categories: UntiyShader基础篇
---
# 2.1 UntiyShader类型
* 上一节，我们大致了解了UnityShader的*基本概念与Shaderlab的基本语法，* 接下来我们将深入UnityShader内部，了解UntiyShader的着色器类型，以及其详细信息。
## 2.1.1 表面着色器

* 如果我们在Untiy中新建一个着色器文件，那么默认的着色器应该是一个**表面着色器**，它是Unity自己创造的一种着色器类型，代码量少，但是**渲染代价大**，它其实是Untiy对于顶点着色器与片元着色器之上的一层更高的抽象，其为我们处理了很多**光照细节（后续光照篇会详细讲到）** 使我们可以更方便的编辑效果。
* 表面着色器的代码在SubShader中间，而没有Pass的概念，这是因为表面着色器*不需要我们去定义*使用多少个Pass我们只需要将数据传入到我们希望的地方，并告知其如何渲染，剩下的事情Unity都会帮我们完成，实际上最终也是翻译为顶点着色器与片元着色器代码。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250218111519.png)
	`2.1.1 表面着色器代码片段`
---
* 我们可以发现，实际上被封装在代码块中的是CGPROGRAM与ENDCG中的代码片段，这些片段中的代码遵循的语言规范是CG/HLSL，我们实际上是将真正的着色语言**嵌套**在Shaderlab语言中，其虽然是Untiy封装过后的，但语法几乎与标准的CG/HLSL一样。但有些函数Unity没有提供支持。
---
## 2.1.2 顶点，片元着色器
* 对于顶点片元着色器而言，我们同样可以用CG/HLSL来编写，其灵活性比表面着色器**更高**，我们可以控制更多的渲染细节，定义每一个**Pass**，虽然这意味着我们需要编写更多的代码。
* 以下是一个简单的顶点片元着色器实例
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250218112246.png)
	`2.1.2 一个最简单的顶点片元着色器实例`
* 本节最后我们也将完成这个Shader，并理解其每一行代码的逻辑与用途。
* 此外，还有一种Shader类型是固定函数Shader，这是在老式的可配置渲染管线中遗留的Shader类型，目前已经不再使用了。
---
## 2.1.3 补充知识

* 那么我们该如何选择Shader类型呢？
	* 如果是与**多种光源**有关的Shader类型，我们可以直接选择表面着色器，它将为我们省去很多麻烦
	* 如果是希望控制单Pass细节，自定义效果多，光线效果少，那么请直接选择顶点，片元着色器！
* UnityShader并不是真正的Shader文件
	* 传统的Shader我们只能分开编写各类着色器，并且无法直接设置一些渲染设置如混合，深度测试等，我们也需要很小心的处理Shader的输入与输出。
	* Unity为我们提供了不需要关注底层实现细节而主要关注开发过程的方式，让我们更加方便的处理呈现内容。
	* 但其也有弊端，它的封装性很高，所以类型语法都被限制了，对于一些特殊的着色器如**几何着色器（GeometryShader）**，**曲面细分着色器**则支持的并不是很好。
* UnityShader与HLSL/CG
	* UntiyShader实际上与HLSL和CG的关系是独立的，真正的Shader片段均为HLSL/CG语法。
	* Untiy会为我们智能针对平台编译所需要的中层代码，并提交给GPU，因此我们不需要针对每个平台再去编写对应API的代码，大大减轻了负担。
---
# 2.2 CG语法基础

* 接下来，我们将正式开始编写着色器，我们将使用Vs作为IDE编辑我们的Shader文件。在编写前，我们需要先来了解一下CG语法的基础。
## 2.2.1 基本结构
* 前文提到，在每一个Pass中（除表面着色器外），就是我们的CG语言所在的位置，我们需要在Pass代码框中编写CG语言。
* Shaderlab只是起到组织代码结构的作用，真正发挥作用的是Pass框架内的CG语言而我们在编写CG语言时，还需要在头部和尾部添加CGPROGRAM以及ENDCG作为标识，告诉Untiy这一段是我们的CG代码。
* 另外我们需要使用对应的编译指令，来编译对应的顶点，片元着色器，以及Shader要编译的目标级别。
```shaderlab
Pass{
	CGPROGRAM
	#pragma vertex vert  //定义顶点着色器
	#pragma fragment frag //定义片元着色器
	#pragma target name //定义要编译的目标级别
	ENDCG
}
```
* 编译指令用于告诉Untiy哪一个是顶点着色器片段，而哪一个是片元着色器片段。而**编译目标等级**则是因为Unity会将CG代码编译到不同的**ShaderModle**中，往往高级的功能需要在更高的GPU上运行，因此需要小心这个数值，通常默认值为2.5
* 另外还可以使用`#pragma require feature`来指定需要何种功能，比如
```shaderlab
#pragma require Geometry tessellation //需要几何体细分功能
```
* 针对不同平台，还可以使用编译指令，只编译或不编译成特定平台的代码。
```shaderlab
#pragma only_renderers d3d11 //只编译 DX3D 11/12平台的底层代码
#pragma exclude_renderers glcore //不编译 OPenGL 3.x / 4.x
```
---
## 2.2.2 顶点着色器

* 这是我们编写Shader所需要的最关键的部分，我们需要利用函数的模式来编写顶点与片元着色器，我们先从渲染管线的思路来认识，从最开始的顶点着色器来逐步认识这段最关键的处理部分。
* 这样的着色器有两种编写方式，一种是有**返回值**的模式，另一种是无返回值模式
```shaderlab
//有返回值
float4 vert(float4 v : POSITION) :SV_POSITION
{
	return mul(UNITY_MATRIX_MVP ,v); // 返回一个经过MVP矩阵变换后的顶点值
}
//无返回值
void vert(in float4 v : POSITION,out float4 position : SV_POSITION)
{
	position = UnityObjectToClipPos(v); // 使用Unity模型到裁剪空间函数进行变换
}
```
* 顶点着色器计算的对象是顶点，精度较低。
* 我们可以观察到，无论是有返回值还是没有，他们的大体结构都类似，首先需要输入和输出，输入v包含了这个顶点的位置，由POSITION语义指定，返回一个float4类型的变量，这就是裁剪空间中的位置。
---
* UntiyShader的数值类型，主要有fixed1-4，half1-4，float1-4（精度依次提高）以及struct类型。
* 对于优化而言。我们需要使用尽可能低的精度来提升Shader性能，我们可以用fixed类型存储**颜色和单位矢量**，更大范围则是half，最差再使用float。
---
* 这些数据从哪里来呢？如果我们需要更多的数据该如何表示呢？学过编程的同学可能会想到**结构体**，没错，我们将用结构体来表示这些从**应用阶段**传来的数据，并将其传入到顶点着色器中。
```shaderlab
……
struct a2v{ //代表从应用阶段传递到顶点阶段
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 texcoord : TEXCOORD0;
}
float4 vert(a2v v):SV_POSITION{
	return mul(UNITY_MATRIX_MVP,v.vertex);
}
```
---

* 我们需要通过**语义**来告诉系统我们输入输出的是何值。
* 什么是语义呢？**语义**就是一个赋给Shader输入输出的字符串，定义了数据的类型，至于数据本身Untiy并不关心，它只要将数据合理的进行传输即可。
* Unity支持的常用语义如下：
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250219093810.png)
	`2.2.2 Untiy支持的a2v语义`
* 其中TEXCOORD n 的数量是与之前所提到的ShaderModle有关，一般在ShaderModle2，3中，n为8，一般所需不超过2，因此绝大多数情况下是够用的。 ^8a5c23
* 通常TEXCOORD也就是uv纹理坐标只有两个维度的值，因此若声明为float4变量，后两位会被自动填充，其中w维度变量默认为1，而z维度变量默认为0，代表一个点坐标。
---
## 2.2.3 片元着色器
* 片元着色器结构与顶点着色器略有不同，因为往往片元着色器面向的都是最后输出颜色的部分，因此输出的语义标识与数值类型都有限制。
```shaderlab
//无返回值版本
void frag(in v2f i, out fixed4 color :SV_Target){
	color = (i.color,1.0);
}
//有返回值版本
fixed4 frag(v2f i):SV_Target{
	return fixed4 (i.color , 1.0)；
}
```
* 对于顶点着色器与片元着色器的通信，我们就需要使用一个新的结构体用于定义顶点着色器的输出
```shaderlab
struct v2f{
	float4 pos : SV_POSITION;
	fixed3 color: COLOR0;
}
```
* 顶点着色器的输出必须包含**一个语义为SV_POSITION**的变量，这样片元着色器才能得知插值后的顶点位置，Color变量往往存储颜色，但也可以自行定义。
* 片元着色器的输入实际上就是顶点着色器输出的**插值**，而对于TEXCOORD语义，其不再特指为uv坐标，实际上可以传递任何值，因此需要依据条件而定。
* 片元着色器的输出值是往往需要指定一个渲染目标（RenderTarget）,它是由HLSL中的一个系统语义SV_Target指定的，它的作用是将这张图像渲染到帧缓冲中。
* 片元着色器的输出值是一个颜色值，一般为fixed4类型。
---
* 现在，我们可以结合所学大致写出目前我们已知的Shader代码了。
```shaderlab
Shader “YOURShader”{
SubShader{
	Pass{
		CGPROGRAM
		#pragma vertex vert；
		#pragma fragment frag；
		struct a2v{
			float4 vertex : POSITION;
			float3 normal :NORMAL;
			float4 texcoord : TEXCOORD0;
		} ;
		v2f vert(a2v v):SV_POSITION{
			v2f o;//实例化一个v2f对象，并修改其中的值传递给片元着色器
			o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
			o.color = v.normal * 0.5 + fixed3(0.5,0.5,0,5)；
			return o;
		}
		struct v2f{
			float4 pos: SV_POSITION;
			fixed3 color:COLOR0;
		};
		fixed4 frag(v2f i):SV_Target{
			return fixed4(i.color,1.0);
		}
		ENDCG
	}
	//FALLBACK Off
}
}
```
---
## 2.2.4 CG属性
* 在完成了以上的内容之后，我们现在再来看之前一直没有特别关注的**属性**Properties部分，现在如果我们想改变Shader内部的属性值，我们只能修改Shader代码。
* 于是我们有了**属性**代码块，它可以让我们能够从软件界面中可视化修改对应的属性变量，只需要我们在代码内部声明该变量即可，其语法为
```shaderlab
type name;
```
* 比如，如果我们要声明一个外部的Float变量，我们需要在代码块中首先添加之前提到过的变量声明
```shaderlab
Properties
{
	_MyFloat("Float Properties",Float) = 1
}
```
* 随后，在CG代码内部，**再次声明该变量**。
```shaderlab
CGPROGRAM
……
float _MyFloat;
……
ENDCG
```
* 这样，我们在外部视图面板中的参数条件就能直接传递到代码内部了。
---
![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250221093919.png)
`2.2.4 常用的CG属性`
* 以上是一些比较常用的属性值与其对应的变量类型，包括后续使用纹理时所添加的2D以及Cub等属性，在后续的章节也会进一步介绍。
---
# 2.3 Unity包含文件
## 2.3.1 什么是包含文件
* 包含文件可以理解为是Untiy为了方便我们进行开发，预先将**一系列函数，变量封装起来**，供我们调用的文件。类似于c++的**头文件**。
* 大家可以去Untiy官网选择下载内置着色器来下载这些文件
* 我们需要在CG代码框内使用类似于添加c++头文件的方式，添加这些包含文件。
```shaderlab
CGPROGRAM
……
#include “UnityCG.cginc”
……
ENDCG
```
* UnityCG.cginc是最常用的包含文件，其中包括了很多内置的辅助函数以及结构体，便于我们简化我们的Shader。
* 以下是一系列常用的包含文件夹以及其描述。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250221113506.png)
	`2.3.1 常用的包含文件`
---
## 2.3.2 UnityCG.cginc
* 该包含文件中包含了很多结构体，我们可以直接使用其作为之前所提到的顶点着色器，以及片元着色器之间的传递数据的结构体。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250221113822.png)
	`2.3.2 UnityCG.cginc所包含的常用结构体`
* 另外其也提供了一系列常用的**函数**，比如将顶点进行变换的函数，获取光照和视角变换的函数等，这些我们也完全可以自己实现，但随着代码推进，越来越复杂时，我们就需要通过这些函数来优化我们的代码。
* ![8b9118bfc35ca2f51b6eed51c3d5a75.jpg](https://pleasant233.oss-cn-beijing.aliyuncs.com/8b9118bfc35ca2f51b6eed51c3d5a75.jpg)
	`UntiyCG.cginc中包含的顶点转换函数`
---
## 2.3.3 关于宏
* 上图中我们可以发现说明里有等同于mul（UNITY_MATRIX_MVP）的字样，实际上括号内的函数是包含在另一个包含文件中的宏定义，其对应了Unity为我们实现的MVP变化矩阵。
* 宏定义在编译是会**自动替换为字符串**，因此我们只需要输入名称即可使用。但这样的效率依旧不高，而且函数对于我们来说认知更为直观，因此我们可以现在搞清楚Shader原理的过程中，随着学习的深入，一步一步用函数替换掉宏定义，使得代码更整洁。
---
# 2.4 让我们来写一个真正的Shader
* 说了那么多，百闻不如一见，只有真正实践，我们才会发现问题，以更好的掌握。
* 现在，我们将用我们学过的知识，来编写一个简单的Shader，我们可以通过界面上的**一个参数来调整图片与材质颜色的混合程度**。
* 首先，我们需要具备三个参数，一个是图像纹理，另一个是一个颜色值，一个是一个Float值用于控制混合程度。
```shaderlab
Properties
{
   _MainTex("MainTex",2D) = "white"{} //贴图默认值为“white”{}
   _MainColor("MainColor",Color) = (1,1,1,1) //颜色默认值为 （1,1,1,1）为白色
   _LerpV("LerpValue",Range(0,1)) = 1 //这里是一种可视化进度条的写法，一个范围值可以拖拽限定最大最小值以及默认值
   //当然你还可以使用_LerpV("LerpValue",Float) = 1 的写法。效果是一样的
}
```
---
* 接下来我们开始正式编写CG代码片段，我们需要先进行一系列的编译设置
```shaderlab
 SubShader
 {
     Pass{
     CGPROGRAM
     
     #pragma vertex vert
     #pragma fragment frag

     #include "UnityCG.cginc" //包含包含文件（到此处为止都不需要添加分号）
     
     fixed4 _MainColor;
     float _LerpV;
     sampler2D _MainTex;//注意此处需要与之前的属性声明值一致，此处开始需要添加分号，分段执行
     float4 _MainTex_ST;//此处是后续会讲到的，每个贴图所对应的缩放与平移值，用于对纹理进行采样。
……
```
---
* 接下来，我们分别用基础版本和高级版本来实现。实际上的不同点，就是高级部分非常简略，适合后期进阶使用。普通版本更适合新手入门搞懂Shader代码细节使用。大家各取所需即可
* 基础思路，我们在顶点着色器中转换顶点坐标并计算纹理坐标，在片元着色器中利用lerp函数对两个值进行插值，最后输出即可。
```Shaderlab
//这里提供两种解决思路，一个是用基础宏定义的基础思路，另一个是用函数解决的进阶思路，在后期可以使用进阶思路

//基础思路

//首先声明两个结构体用于传递信息
/*
struct a2v{
    float4 vertex:POSITION; //最基本的顶点位置信息
    float2 texcoord:TEXCOORD0;//最基本的纹理坐标信息
};
struct v2f{
    float4 pos:SV_POSITION;//裁剪空间下的顶点位置信息
    float2 uv:TEXCOORD0;
};
v2f vert(a2v v){
    v2f o;
    o.pos = mul(UNITY_MATRIX_MVP,v.vertex)//将顶点变换到裁剪空间下现在编译时会自动替换，这里只是强调概念
    o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);//利用包含文件中的宏计算纹理坐标
    return o;
}
fixed4 frag(v2f i):SV_Target{
    fixed4 color = tex2D(_MainTex,i.uv);//使用tex2D函数用uv坐标采样主纹理
    return lerp(color,_MainColor,_LerpV);
}
```
---
* 另外一种就是进阶思路，进阶思路其实就是使用**函数以及包含文件内的结构体**代替我们自己编写的结构体以及宏定义，更简单的完成目的。
```shaderlab
 //进阶思路，使用UnityCG.cginc中为我们提供的结构体以及函数
 v2f_img vert(appdata_base v){
     v2f_img o;
     o.pos = UnityObjectToClipPos(v.vertex);//利用函数将顶点变换到裁剪空间下
     o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);//利用包含文件中的宏计算纹理坐标
     return o;
 }
 fixed4 frag(v2f_img i):SV_Target{
     fixed4 color = tex2D(_MainTex,i.uv);//使用tex2D函数用uv坐标采样主纹理
     return lerp(color,_MainColor,_LerpV);
 }
```
---
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250223144642.png)
	`2.4 效果展示`
---
# 2.5 结语与参考资料
* 本节我们完成了真正可以使用的第一个Shader文件，我们了解了Shader的基本概念与基本语法，了解了两个最基本的着色器的作用与写法。
* 接下来，我们将进入光照部分，实现一系列光照算法模型，了解Unity中的光照系统。
* 所有代码我都将上传到**Github社区进行维护**，欢迎大家一起交流。
---
* UnityShader入门精要 冯乐乐著
* UntiyShaderlab 新手宝典 唐福幸著