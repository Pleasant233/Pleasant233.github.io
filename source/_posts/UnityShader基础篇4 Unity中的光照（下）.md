---
title: 'UnityShader基础篇4——Untiy中的光照（下）'
date: '2025-4-12'
description: 增加对于阴影与光照的支持
top_img: https://pleasant233.oss-cn-beijing.aliyuncs.com/SnowMountainWithCloud.png
cover: https://pleasant233.oss-cn-beijing.aliyuncs.com/SnowMountainWithCloud.png
categories: UntiyShader基础篇
---
# 4.0 引子
* 在之前的学习中，我们了解了UntiyShader中材质与光线作用的基本方式与原理，并且实现了一系列基本的主流模型。最后完成了经典的**布林冯模型**。但是先前的学习中，我们只能处理简单的场景（也就是只有一个灯光的场景）。
* 那么接下来，我们将继续学习光照相关的内容，实现一个真正可用的模型，它能够处理所有灯光对其的交互。
---
# 4.1 Untiy的渲染路径
## 4.1.1 何为 渲染路径（RenderPath）
* 在这学期的分享中，我们接触了大量的专业词汇，可能会随时搞混，不过只要记住他们的特征，我们就可以理解他们的作用。
* 渲染路径实际上就是指光照**是如何应用到UntiyShader**中的。因此每个Pass都需要我们为其设置渲染路径，我们才能正确的处理光照。
* 渲染路径如果不能被显卡支持，则其会选择更低一级的渲染路径。例如如果不支持延迟渲染路径（Deferred Path）那么Untiy就会为我们使用前向渲染路径（ForwardPath）。
## 4.1.2 延迟渲染路径（Deferred Path）
* 延迟渲染路径顾名思义，是将着色阶段推迟的渲染路径，即使场景中有成百上千个灯光，也可以保持流程的渲染帧率，但是需要依赖硬件支持。
* 其本质就是对于灯光Pass基于G-Buffer（屏幕空间缓存）和深度信息计算光照，因为是基于屏幕空间，因此并不会因为场景复杂度而增加渲染时间。可以避免计算未通过深度测试的片元，并且每盏灯光都可以进行**逐像素级别的计算**，效果更加逼真。因为可以与法线贴图等进行逐像素的计算。
* 但延迟渲染也有其问题，因为着色的推迟，因此延迟渲染无法支持真正的MSAA抗锯齿，但是依然有相关方法可以支持（进阶篇会详细讲到），并且延迟着色无法处理半透明物体，会自动选择**前向渲染进行渲染**。
---
* 延迟渲染对于灯光数量上的消耗并不明暗，主要还是针对灯光照射范围，和是否投射阴影。范围越大，阴影投射都会增加消耗。
* 延迟渲染只能在具备多重渲染目标，支持深度渲染贴图的显卡上进行。顾名思义就是可以通过一个DrawCall渲染多张纹理。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250313171255.png)
	`4.1.2 多重渲染目标的实际应用`
---
* 并且延迟着色并不支持正交投影，因此二维游戏很多只能使用前向渲染路径进行渲染。下面我们就会介绍前向渲染路径，这也是目前我们最常用的渲染路径。
* 默认会生成数个渲染纹理（RenderTexture）：

| 渲染图RT     | RGB通道  | A通道  |
| --------- | ------ | ---- |
| RT0       | 漫射     | 无    |
| RT1       | 高光     | 高光指数 |
| RT2       | 法线     | 无    |
| RT3       | 自发光+探针 | 同左   |
| 深度缓冲和模版缓冲 | ……     | ……   |

---
## 4.1.3前向渲染路径（Forward Rendering）
* 前向渲染路径是传统的渲染路径，支持所有的图形功能。
* 前向渲染的目标是渲染该对象的**渲染图元**，并计算两个缓冲区的深度信息，来判断片元是否可见，如果可见则更新颜色缓冲区中的值
* 因此其渲染一个物体，往往使用一个或多个Pass，这取决于灯光的数量。因灯光的重要性不同，渲染方式也不同。
* 最亮的灯光往往会被用作逐像素的渲染方式，而四个点光源以逐顶点为渲染方式，剩下的灯光则以几乎不消耗性能的SH（Spherical Harmonics）球协函数的方式渲染。
* 起决定性作用的设置在于，渲染模式是否为Important，若为important则为逐像素渲染，**最亮的平行光**总是以逐像素方式渲染。
* 若设置为Auto，则Untiy会根据灯光的亮度以及距离物体的远近自动选择渲染方式。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250313172733.png)
	`4.1.3 Untiy中的灯光重要性设置`
---
* 基础的Pass会包含一个逐像素的平行光，以及所有逐顶点，SH的光源，并且会包含来自Shader的光照贴图，环境光等，单只有平行光能够投射阴影，光照贴图不会接受SH的照明。
* 其余的逐像素光源会逐个增加Pass渲染，但默认不会投射阴影，要想让灯光投射阴影，就需要添加内置的编译指令：multi_compile_fwdadd_fullshadows编译出不同的Shader变体（Variant）。
---
* 下面是前向渲染与延迟渲染的特性对比
 ![dc2d6138cec8c5d22b906a574528522.jpg](https://pleasant233.oss-cn-beijing.aliyuncs.com/dc2d6138cec8c5d22b906a574528522.jpg)
	`4.1.3.1 前向渲染以及延迟渲染对比`

---
# 4.2 前向渲染下的光照处理
## 4.2.1 LightMode
* 先前我们提到过。LightMode标签是用作定义Pass在光照流水线中的作用，我们可以为不同的Pass设置不同的渲染标签来规定每个Pass的作用。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250313174440.png)
* `4.2.1 不同的LightMode设置`
* 正确的设置渲染标签，可以让引擎为我们提供相应的变量，我们只需要使用内置的光照变量来访问这些值即可，如果我们没有指定任何的渲染路径则可能会出现错误赋值。
* 我们可以在Pass的开头处声明该Pass的LightMode标签如下
```Shaderlab
Tags{“LightMode” = “ForwardBase”}
```
* 这样我们就声明了一个在前向渲染路径下的Pass了。
## 4.2.2 多光源实现
* 现在，我们有了对前向渲染的基本概念，就可以进入到如何实现多光源场景的部分了，首先，我们需要正确的获取光源变量的信息
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202025-03-24%20161807.png)
	`4.2.2 多光源效果图`
---
* 对于光照而言，我们需要做的事情实际上就是根据光源的数个特点来对光进行描述和采样。最终作用到我们的渲染结果上。
* 光所具备的几个特点分别是：**位置，半径，强度，衰减，方向**
* 因此我们也将以这几个特点为基础来进行光照的渲染。
* 首先，我们借用上节课最后的成果——布林冯模型，来对光照进行加工，先完成一个能够有多光源Pass的Shader，再在之后加入阴影，形成一个完整的标准的Standard Shader！
---
* 首先，对于BasePass我们需要设置它的**光照标签**为Forwardbase,这样Untiy就可以为我们识别并在该Pass渲染最主要的平行光源，接着，我们需要添加**Lighting包含文件以及UntiyCG包含文件，以此来获取正确的变量。**
* 最关键的部分就是我们需要添加编译指令，让Untiy为我们正确添加诸如_LightColor等值。
* 其余代码与上节课所写并无差异，最关键的部分就是，在最后我们需要添加一个atten变量，该变量即为**光源衰减值**，而该Pass所对应的平行光是主光源，无衰减，则值为1
```CG
fixed3 color = unity_AmbientSky + (diffuse + specular) * 1.0;
```
---
* 接下来就到了最关键的部分，我们需要为其余的光源添加另一个Pass，该Pass的光照标签为**ForwardAdd**表明它是附加的Pass，而因此我们就需要为该Pass设置混合模式，我们知道最后渲染的目标实际上是帧缓冲，因此如何对帧缓冲的值进行替换就是我们需要考虑的问题，在这里，我们就需要在最后的**混合部分，设置混合模式，比如`Blend One One`的意思就是1:1混合也就是叠加上去。**
```Shaderlab
Tags{"LightMode" = "ForwardAdd"} //设置光照标签  
Blend One One //设置混合模式
```
* 随后我们需要为该Pass添加编译指令，该Pass的编译指令与上一个Pass实际上就只差了最后的一串字符
```CG
#pragma multi_compile_fwdadd
```
* 其余的代码只需要全部复制过来即可，我们在最后的片元着色器中添加条件语句分支，来对不同类型的光源进行不同的设置。
---
* 首先是对于光源类型，若不是平行光，那其就有位置远近的关系，以及光源向量，那么我们就需要来进行判别，获取正确的光源向量信息。
```CG
#ifdef USING_DIRECTIONAL_LIGHT  
    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);  
#else  
    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - mul(unity_ObjectToWorld,i.vertex).xyz);  
    #endif
```
* 对于平行光，我们单纯获取其方向即可，而点光源以及聚光灯都有位置信息，因此，我们就需要去利用向量运算，获得指向物体方向向量的空间位置信息。
---
## 4.2.3 光照衰减
* 接下来，我们需要处理光照衰减，光照衰减，是根据灯光与物体距离计算得出的，光源距离物体越远，光照越不明显。
* 在Untiy中，有两种方式可以计算光源光照衰减值，一种是对灯光贴图进行采样，另一种是利用数学公式计算采样。
* 纹理采样的缺点是，需要预处理该纹理，并且一旦存储数据就无法使用其他公式计算衰减，但是可以提升性能，并且效果良好。
* 数学公式的缺点是，无法很好的解决聚光灯等光源形状问题，会在离开瞬间发生突变。因此本章我们主要使用的是灯光贴图采样法。
---
* 灯光衰减是Untiy在内部使用一张贴图
`_LightTexture0`来记录的。其中（0,0）点对应了与光源重合位置的衰减值，而（1,1）点则对应了光源空间中能受影响的最远一点的值。
* 为了采样该纹理，我们需要首先得到点在光源中的空间位置，这一般是通过_LightMatrix0 变换矩阵来将该点变换到光源空间的位置，然后使用这个坐标的模的平方（也就是距离）来对光照贴图进行采样，最后使用UNITY_ATTEN_CHANNEL来获取衰减纹理中衰减值所在分量，最终获得衰减值。
```CG
#ifdef USING_DIRECTIONAL_LIGHT  
   fixed atten = 1.0;  
#else  
  
   fixed3 lightCoord = mul(unity_WorldToLight,float4(mul(mul(unity_ObjectToWorld,i.vertex),1)).xyz);
   fixed atten = tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
```
![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202025-03-25%20114024.png)
	`4.2.3 对于光源贴图的采样方式理解`

---
* 对于聚光灯，我们还可以进一步的进行细分，通过添加条件分支，完善对聚光灯的衰减和光照处理
```CG
#elif defined (SPOT)  
    float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));  
    fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
```
* 实际上我们干的事情分为三部分，首先是进行空间有效性检测，对应
`(lightCoord.z >0)` 排除聚光灯背面的像素，因为聚光灯只对正方向的物体有贡献。
* 接下来是按形状处理衰减，首先使用光源纹理，通过将光源纹理由3D转化为2D并从【-1，1】映射到【0,1】坐标。用其w分量作为光源形状上的衰减数值与后续距离衰减相乘。
* 距离衰减与点光源距离衰减采样模式相同，同样是用点积代替复杂的开方运算节省性能。
---
* 另一种添加多光源的方法：内置的Shade4PointLights()函数，该函数能够为我们添加四个点光源光照相加的结果。
* 并且其默认所有输入光源均为点光源，因此判断的结果并不完美。
* 但只限于点光源，而且衰减计算可能会出现问题，因为其内部是使用了数学方式运算而不是贴图纹理采样，并且开销也会更大。
* 使用该函数的方法：
```CG
fixed3 color = diffuse;  
  
color.rgb += Shade4PointLights(unity_4LightPosX0,unity_4LightPosY0,unity_4LightPosZ0,unity_LightColor[0].rgb,unity_LightColor[1].rgb,unity_LightColor[2].rgb,  
    unity_LightColor[3].rgb,unity_4LightAtten0,mul(unity_ObjectToWorld,i.vertex).rgb,worldNormal) * _DiffuseColor;  
color += specular + unity_AmbientSky;  
return fixed4(color,1);
```
---
* 综合而言还是使用光源贴图采样的方式效果更好，性能开销也相对更低。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202025-03-25%20123454.png)
`4.2.3 左图为采样光源贴图，右侧为点光源函数`
---
# 4.3 Untiy中的阴影实现
## 4.3.1 ShadowMap与ScreenShadowMap
* ShadowMap 即阴影图，是在实时渲染中处理阴影映射的方式，其技术原理十分简单，就是将摄像机放在**与光源重合的位置**上，并记录一张纹理，这张纹理实际上是一张**深度纹理**。记录了从光源位置出发的能看到场景中最近的**表面深度值**。
* 在Untiy中，会使用一个额外的，LightMode为ShadowCaster的Pass用于专门更新光源的阴影映射纹理。其渲染目标是名为阴影映射纹理或深度纹理的RT。
* 如果开启了光源阴影，则渲染引擎会在当前渲染的物体中，寻找ShadowCaster Pass，若没有则回退到FallBack中，直到找到为止。当找到后，则就会用其来更新光源阴影映射纹理。
* 传统映射中，我们会在非ShadowCasterPass中将顶点变化到光源空间下，并用xy分量对阴影映射纹理采样。得到其位置的深度信息（阴影纹理中）随后，我们就会比较顶点深度（位于光源空间下的z坐标值）若纹理深度小于顶点深度，则说明该点位于阴影中。这样就完成了阴影的投射过程。
---
* 而基于屏幕空间的处理方式，则是在后续显卡支持MRT即多重渲染目标后才得以支持的。其原本是延迟渲染下的一种阴影投射方式。
* 对于屏幕阴影映射而言，其会先调用ShadowCaster的Pass来得到投射阴影光源的阴影映射纹理，以及摄像机深度纹理，而后根据映射纹理和深度纹理来得到屏幕空间的阴影图。
* 若相机深度图大于阴影纹理中的深度值则说明可见但在阴影中。通过这样的采样，我们就可以得到包含在屏幕空间下的所有阴影区域，若有物体想要接受阴影，则采样阴影图，通过将该物体的定带你变换到屏幕空间中并采样即可。
---
* 总结：若一个物体想要接受其余物体的投影，就必须在Shader中对阴影映射纹理采样，并将其与光照效果相乘产生阴影效果。
* 若一个物体想要投射阴影，则必须将其加入到光源阴影映射纹理中，从而让其余物体能够采样到它。
* 下面我们就结合已知进行实践完成阴影的处理。
---
## 4.3.2 阴影投射
* 如果要让某个光源投射阴影，首先需要将其允许投射阴影的选项打开，并且确保接受阴影的物体开启了ShadowCaster，如果取消，即使Shader内有相应的Pass也会忽略从而不执行。
* 如果我们现在对物体进行投射，我们会发现物体能够正常的显示阴影，这是因为Shader的FallBack中存在ShadowCaster。
* 但如果我们将光源原点置于物体之中，会发现阴影出现了残缺
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202025-03-26%20150153.png)
	`残缺的阴影`
* 这是因为球体本身是单面的，因此如果从光源处检测的话，则会认为光线在球体内，因此则不会投射出阴影。这时如果将Double-Sides打开的话，则会正常投射，因为这时球体则会是双面的。
* 接下来，我们来学习如何让物体接受阴影。
---
## 4.3.3 接受阴影
* 首先，接受阴影，意味着该物体需要对阴影图进行采样，所以我们需要准备采样的坐标，随后若支持屏幕空间阴影则变换其到屏幕空间下，与深度图进行采样比较，否则就将其变换到光源空间，使用传统的采样方式。
* 最后我们就将使用得到的阴影坐标对阴影纹理进行采样。接下来我们就来实现这个过程。
* 首先我们需要不包含一个新的内置文件`AutoLight.cginc`我们将用其中定义的宏来计算阴影。首先，我们添加了一个内置宏变量SHADOW_COORS()，该变量用于声明一个纹理坐标。其输入就是下一个可用的插值寄存器值，也就是TEXCOORDX中X+1的值。
```CG
struct v2f {  
    float4 pos : SV_POSITION;  
    float3 worldNormal : TEXCOORD0;  
    float3 worldPos : TEXCOORD1;  
    SHADOW_COORDS(2)  
};  
  
v2f vert(a2v v) {  
    v2f o;  
    o.pos = UnityObjectToClipPos(v.vertex);  
        o.worldNormal = UnityObjectToWorldNormal(v.normal);  
        o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
    TRANSFER_SHADOW(o);  
    return o;  
}
```
---

* 随后在顶点着色器中，我们就将变换顶点的坐标。使用TRANSFORM_SHADOW(o)宏定义，来对阴影坐标进行转换。这里的内部处理方式可以给大家参考一下。
*  ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202025-03-30%20124619.png)
* 本质上就是通过一系列宏定义去判断何时需要怎样计算阴影，如何映射。
* 当能够运用屏幕坐标下的阴影计算时则执行对应指令。否则按照传统方式解决。
---
* 最后来到片元着色器部分，我们利用之前的阴影纹理对其进行采样，计算阴影衰减，并将所得到的数值与最终的渲染结果颜色相乘，即可得到被其他物体投射阴影的物体。
```CG
fixed Shadow = SHADOW_ATTENUATION(i);  
return fixed4(ambient + (diffuse + specular) * Shadow * atten, 1.0);
```
---
* 当你的主光源开启阴影投射时，我们就可以注意到，物体上已经可以产生阴影了
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202025-03-30%20134912.png)
	`4.3.3接受阴影的效果`
* 但值得注意的是，这些宏变量的计算需要使用上下文信息，我们需要确保变量名匹配，a2v 中的顶点坐标变量必须是vertex，v2f中的顶点位置变量必须为pos。
* 目前该Shader只能处理平行光，后续我们将使其能够成为一个完整可用的Shader代码框架。
---
## 4.3.4 光源与阴影衰减
* 先前我们提到了光源如何进行衰减采样，以及阴影的实现，而阴影同样具备衰减特性，因此，我们就可以针对光源和阴影来实现一个统一的管理效果。
* 为此，我们使用Untiy为我们提供的宏来统一管理计算。该宏便是——UNITY_LIGHT_ATTENUATION。
* 这个宏定义是定义在AutoLight.cginc之中的，它实际上就是整合了Light的衰减与Shadow的衰减，并输出一个统一的衰减值。
* 其接受三个参数，其中，第一个参数atten是Untiy为我们自动创建的，因此我们只需要输入atten即可。而第二个以及第三个参数，则分别为v2f结构体以及其中的世界空间坐标，我们只需传入即可。
* 随后，如果我们希望额外的光源也产生衰减和阴影效果，则需要将编译指令 multi_compile_fwdadd 替换为multi_compile_fwdadd_fullshadows
* 这样Untiy就会为我们自动添加相关的数值到我们的参数中了。
* 最后我们就得到了本节课的最终目标，一个完整可用的布林冯Shader。目前，这个Shader已经可以用在任何场景之中了。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202025-03-31%20143235.png)
	`4.3.4 一个最终可用的完整的支持基本光照的布林冯模型`
---
# 4.4 结语与参考资料
* 本节我们完成了全部的基础光照内容，最终实现了一个可以与任何光源交互的可用的Shader模型。接下来我们将从不透明进阶到透明效果阶段，这也是问题最多的一个阶段，我们将编写各类透明效果。
* UnityShader入门精要 冯乐乐著
* UntiyShaderlab 新手宝典 唐福幸著