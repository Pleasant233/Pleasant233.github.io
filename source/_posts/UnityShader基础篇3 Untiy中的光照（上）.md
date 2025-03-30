---
title: 'UnityShader基础篇3——Untiy中的光照（上）'
date: '2025-3-30'
description: 简单介绍Untiy中的光照与基本的光照模型
top_img: https://pleasant233.oss-cn-beijing.aliyuncs.com/SnowMountainWithCloud.png
cover: https://pleasant233.oss-cn-beijing.aliyuncs.com/SnowMountainWithCloud.png
categories: UntiyShader基础篇
---
# 3.0 前言
* 在进入光照篇之前，我们还需要再了解一些关于Shader编程的零碎知识，这些知识对于我们解决Shader的Bug，增进Shader编程能力有很大帮助。
## 3.0.1 帧调试器
* 对于解决Shader出错的最好方式，就是Untiy为我们提供的辅助工具，帧调试器（FrameDebugger），我们可以在运行游戏后，点击Game视窗上方的小虫子图案启动它。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250224103705.png)
	`3.0.1 帧调试器`
* 它实际上就是将渲染中的各个事件（Event）为我们汇总到了一起，形成了树状结构，我们可以去查看每一次提交（DrawCall）的实际结果，帮助我们优化流程。
* 我们还可以查看其详细信息，比如该GameObject所应用的Shader信息，如是否开启了各类检测，剔除，ShaderTags or RenderSetup等。
---
## 3.0.2 简化Shader
* 对于Shader而言，高效的实现效果使我们需要考虑的前提，因此我们需要了解对于Shader而言的开销分布。
* 因为片元着色器的作用是处理插值后的逐像素操作，因此处理的消耗很大，实际上我们是通过GPU的寄存器等进行的数据处理和操作。
* 因此不要在片元着色器中进行过量计算。
* ShaderTarget对应了我们能够使用多高级的ShaderModel，在我们先前的基础篇提到过。[[UnityShader基础篇2 初识Shader与Shader语言（下）#^8a5c23]]
* 我们可以在编译阶段指定更高的Target等级，运用更多的寄存器来解决这些问题。但请注意，在移动设备上的开销。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250224104617.png)
	`3.0.2 指定对应的渲染目标等级`
---
* 减少使用分支与循环语句。
* 分支与循环语句在GPU中的实现与CPU不同，因此如果使用会降低GPU的并行处理操作，尽管现代GPU有所改善，但依然推荐各位慎用！
* 如果非要使用，可以借助以下方式优化
	* 1. 循环条件变量最好为常数
	* 2. 每个循环代码块指令尽可能少
	* 3. 分支嵌套层数尽可能少
---
* 不要除0，对于这一点而言，数学上我们都能理解，在一般情况下，这是一个无意义的操作。
* 对于计算机而言亦然，因此我们可以强制将其截取为非0范围。也可以判断（当然开销略大）。
---
# 3.1 光线基础回顾
## 3.1.1 光线的基本定义
* 就像我们之前的图形学学习一样，我们知道光是从**光源**发出的，在后期的PBR流程中，我们会更加科学严谨的定义光线。
* **辐照度**是指垂直于光线l的单位面积上单位时间内所穿过的能量也就是所谓的IR（可见同期光追分享） [[入门光线追踪2——辐射度量学#^b620d6|什么是IR]]
* 而IR与光线与平面法线夹角的**余弦成正比**，因此我们就可以用光线向量l与表面法线n点积来得到cos值。
---
* 光线与物体交互，会产生不同的结果，大致可以分为两种
	* 1. 散射
	* 2. 吸收
* 前者又分为两种方向，一种会散射到物体内部，称为**折射or透射**。
* 而另一种则称为*反射
* 不透明的物体，内部的物质会继续与光线作用，一部分被物体吸收，另一部分重新发射出物体表面，这样物体就会发射出了**不同的光线**
* 我们利用高光反射来表示物体如何发射光线，而漫反射则表示有多少光线会被折射，吸收，散射出表面。
* 我们可以计算光线的**出射度**（[[入门光线追踪2——辐射度量学#^8b3c27|ER的定义]]）,他们之间的比值就是漫射与高光反射属性值。
---
## 3.1.2 光照模型
* 我们再次定义何为**着色**，这与光线追踪分享中相同，详细的可以参考光线追踪的分享。我们使用材质属性，光源信息，的等式来计算某个观察方向的出射度的过程，就被称为**着色**。
* 而不同的**光照模型**。对应了不同的等式。也是我们处理光线的方式。
* 我们可以通过一个函数模型去解决如果光线从一个方向照射到一个表面时，多少光线被反射，以及其方向，这就是所谓得到BRDF（双向反射函数），定义依然参考光线追踪部分的分享[[入门光线追踪2——辐射度量学#^525b6a| 何为BRDF]]。
* 关于更高级的PBR及其实现我们将在后续提升章节再介绍，我们现在介绍的是一种广泛用于游戏渲染中的经验模型——Blinn-Phong模型。
* 实际上我们之前已经在图形学入门中介绍了基本的Blinn-Phong模型概念。如有需要，请回顾[[入门图形学10——着色2#^daa208|BlinnPhong模型]], [入门图形学10着色2](https://pleasant233.github.io/2025/01/17/%E5%85%A5%E9%97%A8%E5%9B%BE%E5%BD%A2%E5%AD%A69%E2%80%94%E2%80%94%E7%9D%80%E8%89%B21/)
* 这里我们只需要回顾模型所包含的四个重要组成项——
	 * 漫射（diffuse）
	 * 高光（Specular）
	 * 环境光（Ambient）
---
* 特别的，一些物理效果无法使用布林冯模型实现，例如菲涅尔反射等，我们会使用特定的着色模型实现。
* 并且布林冯模型是各向同性的，意味着反射不会因为我们视角的转变有任何变化，因此对于如金属，毛发等，我们需要学习基于物理的材质PBR。
* 接下来我们将正式进入Untiy，实现一系列简单的经验模型，在下一节课的最后给出一个完整可用的模型。
---
# 3.2 Untiy光照与CG函数
## 3.2.1 Unity的Lighting面板与渲染路径
* 我们可以在Untiy主界面上段选择windows选项框，现在Lighting面板被合并到了Rendering面板内，我们需要打开Rendering面板选择Lighting复选框，就可以看到Lighting面板了。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250225094726.png)
	`3.2.1 Lighting面板`
* 在这里，我们可以修改天空盒材质，修改环境光照选项，我们可以选择环境光来源，其可以来源于**skybox，gradient，color**三个来源，我们可以设置后两者的颜色，这会对应我们在Shader文件中获取的**Ambient（环境光）的颜色。**
* 我们一般会使用UNITY_LIGHTMODEL_AMBIENT这个宏来返回环境光照的颜色。
---
* 关于渲染路径，我们将在后续详细提到，现在，我们只需要了解，修改不同的渲染路径，会影响Unity中的光照。我们可以在ProjectSetting中，修改Graphic选项卡中的RenderPath选项来修改渲染路径。一般我们会选择Forward（前向渲染）路径。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250225095535.png)
	`3.2.1.1 对于不同的渲染平台我们可以配置不同的渲染策略`
* 还有两种选择，一个是延迟渲染，另一个是顶点光照，前者拥有最高保真的灯光数量，后者则是最低保真的灯光数量，是Forward的子集。
* 关于RenderingPath的详细介绍，我们会在实现功能后进行。现在我们只需要了解如何修改它即可。
---
## 3.2.2 Lambert模型
* Lambert模型就是一种最简单的经验模型，其原理就是我们一开始对光线的定义中提到的，**反射光线强度与表面法线和光线向量夹角成正比**，这也是一种只有漫射的经验模型。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250225100329.png)
	`3.2.2 Lambert模型公式`
* 其只需要四个参数，即光线颜色，物体颜色，以及法线向量n和光线向量l。
* 对于max函数，我们在CG中有一个更加方便的实现。那就是saturate()函数，这个函数可以将输入限制到【0,1】区间内。
* 接下来，我们来进入正式的Shader编写，来一起完成一个兰伯特模型。
---
* 首先，我们接着上一节的思路，我们可以迅速新建一个Shader文件，并对其进行改造，保留最关键的部分。
```shaderlab
Shader "Custom/LambertShader"
{
    Properties
    {
        
    }
    SubShader
    {

        CGPROGRAM

        ENDCG
    }
    FallBack "Diffuse"
}
```
* 对于Lambert模型，我们需要一个最基本的漫射颜色，在Properties中输入即可，
```shaderlab
_DiffuseColor("Diffuse Color",Color) = (1,1,1,1)
```
* 随后，我们在SubShader中需要添加Pass代码块，这次，我们需要设置Pass的标签。
* 这一行指明了该Pass在光照管线中的角色，只有正确设置了Lightmode，我们才能正确得到一些内置变量。
```shaderlab
 Tags{"LightMode" = "ForwardBase"} //设置光照标签
```
---
* 同时我们需要添加光照包含文件“Lighting.cginc”，这样我们才能获取一系列的光照变量供我们使用。
* 接下来的声明内容就不再赘述，我们主要关注顶点着色器部分。这里放出代码。
```CG
Tags{"LightMode" = "ForwardBase"} //设置光照标签
CGPROGRAM
#include "Lighting.cginc"//包含光照包含文件
#include "UnityCG.cginc"
#pragma vertex vert
#pragma fragment frag

fixed4 _DiffuseColor;//声明材质颜色
struct a2v{ // 声明参数结构体，当然可以使用内置的appdata_base进行传递
    float4 vertex : POSITION;
    float3 normal : NORMAL;
};
struct v2f{
    float4 pos : SV_POSITION;
    fixed3 color : COLOR;//传递颜色便于对颜色进行操作你也可以使用COLOR0 or TEXCOORD0
};
```
---
* 接下来我们关注顶点着色器部分，在这里，我们主要进行的计算就是将顶点信息进行相对应的变换，并利用兰伯特计算法，计算出漫射信息。
* 首先，我们需要变换**顶点坐标**，将顶点坐标变换到裁剪空间。
* 接着，我们需要变换法线，将法线从模型空间变换到**世界空间**，这样才能保证能够与光线运算。
* 在这里，我们也可以使用右乘逆阵的形式来变换法线，这样就可以避免因为不均缩放而导致的法线方向偏移。但在这里不多做赘述。
* 我们使用Unity内置的法线变换函数。随后我们将其归一化。
```CG
v2f vert(a2v v){
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);//将顶点变换到裁剪空间
       
    float3 n = UnityObjectToWorldNormal(v.normal);//将法线变化到世界空间
    //另一种写法：normalize(mul(v.normal,(float3x3)_Word2Object))已不常使用
    n = normalize(n);//归一化法线向量
```
---
* 接着，我们利用Unity为我们内置的变量_WorldSpaceLightPos0来获取灯光的位置，这个灯光是具备优先级限制的，我们会在下一节进阶篇中详细介绍，目前你可以理解为它会获取场景中自动添加的平行光位置
* 随后，利用兰伯特模型计算漫反射，我们就可以得到diffuse项了。
* 最后我们利用Unity内置的宏UNITY_LIGHTMODEL_AMBIENT来获取环境光变量，最后赋予v2f结构体中的Color变量，输出即可。
```CG
fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);//获取灯光方向

fixed ndotL = dot(n,worldLight);//计算辐射度
fixed3 diffuse = _LightColor0.rgb * _DiffuseColor.rgb * saturate(ndotL);//利用兰伯特公式完成兰伯特光照计算

fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz; //获取环境光变量
o.color = ambient + diffuse;//输出一个具有漫射和环境光的颜色值
return o;
```
---
* 最后，我们就可以得到一个具有基本的漫射的基于兰伯特模型的材质了。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250225113936.png)
	`3.2.2 兰伯特模型`
* 我们发现虽然效果不错，但是在过渡阶段会有明显的锯齿，在我们之前的图形学分享中，我们了解到，这主要是因为着色频率较低[[入门图形学10——着色2#^e2c8d3| 着色频率回顾]]
* [网页着色频率回顾](https://pleasant233.github.io/2025/01/22/%E5%85%A5%E9%97%A8%E5%9B%BE%E5%BD%A2%E5%AD%A610%E2%80%94%E2%80%94%E7%9D%80%E8%89%B22/)
* 于是我们自然想到可以进行更高级的着色，也就是逐像素的着色，发生在片元着色器阶段，这也被称为Phong着色（记住这是着色方式而不是光照模型）。
* 接下来我们来看看如何在片元着色器中实现Phong着色。
---
## 3.2.3 Phong着色（逐像素Lambert）
* 我们之前提到过，尽量不要在片元着色器中进行大量计算，但为了让我们的效果更好，有时我们可以对不同的硬件平台选择不同的着色模式。
* Phong着色与Lambert着色的其他设置我们可以保留，我们只需要关注顶点与片元着色器中的变化即可。
* 在定点着色器中，我们只需要进行顶点着色器所必备的顶点坐标系转换的工作即可，所以，我们的着色器代码就是只保留变换坐标系的功能即可
```CG
 struct v2f{
     float4 pos : SV_POSITION;
    // fixed3 color : COLOR;//我们不需要在vert中处理颜色所以不用管
     float3 worldNormal: TEXCOORD0; //在这里我们可以用Tex作为数据类型传递
 };
```
* 因此我们需要修改顶点着色器传递给片元着色器的信息，我们传递变换后的法线信息即可。
* 所有着色计算我们都将在片元着色器中进行，片元着色器是**逐像素计算**的，因此我们会得到更加细腻平滑的颜色变化。在片元着色器中，我们需要获取顶点着色器传递过来的法线信息，随后经过与逐顶点相同的计算就可以得到最后的效果了。
```CG
fixed4 frag(v2f i):SV_Target{
    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
    fixed3 worldNormal = normalize(i.worldNormal);
    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
    fixed ndotl = saturate(dot(worldNormal,worldLightDir));
    fixed3 diffuse = _LightColor0.rgb * _DiffuseColor.rgb * ndotl;
    fixed3 color = ambient + diffuse;
    return fixed4(color,1);//返回颜色值
}
```
* 现在的Pc平台基本上不会因为逐像素而牺牲过多性能，手机平台也迭代更新十分迅速，因此可以放心将计算放在片元着色器中。
---
## 3.2.4 半兰伯特模型（HalfLambert）
* 半兰伯特模型是由半条命开发时Valve公司提出的。主要的目的就是修改在环境光照下，模型背面的阴影变化一样，僵硬的问题。
* 我们之前的做法是将值阶段在0-1区间，这会导致一些映射在0以下的值失去意义。导致背面数值均为0因此一片漆黑。
* 所以半兰伯特模型实际上做了一件十分简单的变化，那就是将数值的变化保留，只不过映射到0-1区间，这是一个很简单的数学思想。我们在编写Shader时时常会做这个操作也叫做clamp。
* 于是我们就可以简单的修改Phong着色的代码，将saturate部分更改为
	* 0.5 * （dot（worldNormal，worldLightDir））+0.5
* 这样相当于将数值映射在了0-1区间。
```CG
fixed4 frag(v2f i):SV_Target{
    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
    fixed3 worldNormal = normalize(i.worldNormal);
    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
    fixed ndotl = 0.5*(dot(worldNormal,worldLightDir)) + 0.5;
    fixed3 diffuse = _LightColor0.rgb * _DiffuseColor.rgb * ndotl;
    fixed3 color = ambient + diffuse;
    return fixed4(color,1);//返回颜色值
}
```

![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250311151142.png)
	`3.2.4 半兰伯特模型效果（右3）`

---
## 3.2.5 高光反射
* 有了之前的学习检验，这里我们就直截了当的介绍基于下面这个公式的高光反射计算方法。
	*  ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250311151812.png)
* 我们可以观察到该公式实际上是一个非线性的公式（因为有指数运算），因此在计算的过程中，我们就需要在插值后再进行该运算，这样就能避免破坏其非线性的性质。所以我们会在片元着色器中对其进行计算。
* 在之前的理论部分，我们提到过反射向量的计算方法，但在这里我们可以通过reflect()函数直接获取该值，其原理本质上还是我们之前的向量运算法则。
* 该函数需要两个参数，一个是光线入射方向，另一个是法线方向。
* 那么我们就直接来实现这个效果。
* 首先，我们需要计算每个着色点的情况，因为是光线是世界空间，因此，我们需要在世界空间下完成计算。
* 我们在顶点着色器的参数结构体中增加一项vertex，我们可以利用之前提到的使用TEXCOORD类型来进行声明。
```CG
struct v2f{
    float4 pos : SV_POSITION;
   // fixed3 color : COLOR;//我们不需要在vert中处理颜色所以不用管
    float3 worldNormal: TEXCOORD0; //在这里我们可以用Tex作为数据类型传递
    float4 vertex:TEXCOORD1;//顶点世界空间位置
};
```
---
* 接着，我们就可以在片元着色器中进行计算了。在片元着色器中，我们按照公式计算即可。首先便是镜面反射向量，这个向量需要我们传入从该着色点到光线的向量因此传入的便是worldLightDir的相反数。接着，我们计算视角向量，直接使用Untiy为我们提供的函数即可，传入我们之前新声明的参数就好了。
* 最后就是按照公式将所有参数组合起来，就可以得到我们的镜面反射了。
```CG
···
//计算镜面反射
fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));//计算反射射线，但这里注意需要获取从着色点到灯光的向量因此取反
fixed3 viewDir = normalize(WorldSpaceViewDir(i.vertex));
fixed3 specular = _LightColor0 * _SpecularColor * pow(saturate(dot(reflectDir,viewDir)),_Glossy);
//计算高光反射项。

fixed3 color = unity_AmbientSky + diffuse + specular;
···
```
---
![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250312111158.png)
	`3.2.5 镜面反射效果`

---
## 3.2.6 BlinnPhong模型
* 布林冯模型实际上是两个人的杰作，之前我们已经完成了冯模型，接下来我们来看布林冯模型。
* 布林冯模型的关键实际上就是在Phong模型的镜面反射部分做了一定的修改，可以使我们不用再计算较为复杂的反射向量而是使用半程向量的形式来进行模拟计算。 ^07e1f1
* 这部分原理在基础篇详细介绍过欢迎回顾
![[#^07e1f1| 布林冯模型回顾]]
* [布林冯模型回顾](https://pleasant233.github.io/2025/01/17/%E5%85%A5%E9%97%A8%E5%9B%BE%E5%BD%A2%E5%AD%A69%E2%80%94%E2%80%94%E7%9D%80%E8%89%B21/#9-2-6-%E5%B8%83%E6%9E%97%E5%86%AF%E6%A8%A1%E5%9E%8B%E4%B8%AD%E7%9A%84%E5%8F%8D%E5%B0%84%E8%AE%A1%E7%AE%97)
* 于是我们只需要对反射向量部分进行修改即可。我们将反射向量修改为半程向量的计算方式。在远距离上，半程向量可以被看做一个恒定不变的值，因此大大减少了计算量。
```CG
……
fixed3 viewDir = normalize(WorldSpaceViewDir(i.vertex));
fixed3 halfDir = normalize(worldLightDir + viewDir);
fixed3 specular = _LightColor0 * _SpecularColor * pow(saturate(dot(worldNormal,halfDir)),_Glossy);
……
```
---
* 这种方法计算的光线光圈会更大一些，看起来效果更好一些，BlinnPhong模型并没有正确与否的区别，只需根据需求选择效果即可。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250312114249.png)
	`3.2.6 布林冯模型（右）与冯模型（左）对比`
---
# 结语与参考资料
* 本篇我们介绍了Unity中基本的光照模型以及其实现方法，接下来，我们将深入光照部分，开始实现多光源光照以及阴影部分。
* UnityShader入门精要 冯乐乐著
* UntiyShaderlab 新手宝典 唐福幸著