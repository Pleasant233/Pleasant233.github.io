---
title: 'UnityShader基础篇5——透明效果'
date: '2025-4-20'
description: 一系列的透明效果原理及其实现
top_img: https://pleasant233.oss-cn-beijing.aliyuncs.com/SnowMountainWithCloud.png
cover: https://pleasant233.oss-cn-beijing.aliyuncs.com/SnowMountainWithCloud.png
categories: UntiyShader基础篇
---
# 5.1 透明测试与透明混合
* 我们之前在Untiy中实现的效果，都是不透明的，所以他们的渲染逻辑就是，启用深度缓冲（z-Buffer）以及深度测试（depthTest），如果片元深度比上一个片元在帧缓冲中的深度更近，则覆盖帧缓冲，呈现在我们眼前的永远是距离摄像机最近的片元。
* 想要实现透明效果，我们需要修改这个过程。而要想修改这个过程，我们就需要认识一个新的测试方式，那就是透明度测试（Alpha-test）以及真正实现半透明效果的透明度混合（Alpha-Blend）。
---
## 5.1.1 透明度测试
* 透明度测试简单而直接，如果一个片元的透明度不满足设定条件（比如一个具体的数值）那么久直接舍弃
* 这一步通常发生在vertex2Fragment之间
* 否则就会按照**不透明**的方式来处理。就会使用不透明流程中的深度测试，写入等。
* 因此透明度测试是不需要关闭深度写入的。
* 而这也决定了它只能做到剔除效果，比如一个透明背景的美术素材，用其处理就可以保留主体。
* 但如果想实现半透明效果，就需要进行更为复杂的透明度混合操作。
---
## 5.1.2 透明度混合
* 透明度混合实际上就是将透明物体与不透明物体按照一定比例进行颜色混合，最后得到半透明效果的过程。这个过程我们可以分为几个步骤来进行。
* 首先，我们需要正确处理不透明物体与透明物体的前后关系。
* 为了正确渲染场景，Untiy会先渲染所有不透明物体，在渲染队列中的标识为`Opaque`
* 然后再渲染半透明物体`Transparent`
* 如果物体属于半透明范畴，我们需要在标签中进行声明。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20250401110657.png)
`5.1.2 半透明物体渲染流程`
---
* 如果半透明物体在透明物体前，并且我们遵循从进到远绘制的不透明流程，我们首先需要**关闭深度写入**，但开启深度测试，这样透明物体就可以在一定范围内被选中，并且还可以不影响后方不透明物体的渲染。
* 而且对于多个半透明物体叠加的情况，在半透明队列中，渲染的方式也是从后向前进行的，这样就可以保证前面的半透明物体是叠加在后面的半透明物体上的。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20250401104738.png)
	`5.1.2.1 透明度混合示意`
---
## 5.1.3 渲染顺序
* 那么我们该如何设置对应物体的渲染顺序呢，我们可以参考下表，这个表中标明了所有队列的用途和渲染顺序。
* 数字越大越靠后渲染。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202025-04-01%20110929.png)
`5.1.3 渲染队列`
* 因此，对于透明度测试物体，我们就需要将其渲染队列设置为`AlphaTest`
* 对于透明度混合物体，我们就要将其设置为`Transparent`
---
## 5.1.4 混合操作（Blend）
* 最后，通过测试的片元会和帧缓冲之内的颜色进行**混合**操作。这一操作本质上就是将颜色按照预先设置的比例进行混合。
* 我们可以使用Untiy为我们提供的Blend命令，来对颜色进行混合。
* 这一阶段我们之前介绍过，是高度可配置的，因此，我们可以使用Untiy为我们提供的各类指令选定混合的函数，混合模式可以在SubShader与Pass中设置。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202025-04-01%20111643.png)
	`5.1.4 混合模式设置语法`
* Blend模式有四种，我们一般使用的是第二种，即Blend SrcFactor DstFactor
* 我们希望混合的方式是透明度混合，因此我们实际上就是用两个片元的透明度进行插值。插值后的数值作为混合因子混合颜色。
* 所以我们使用的语句为
`Blend SrcAlpha OneMinusSrcAlpha`
对应的公式为
`DstColor（new） = SrcAlpha * SrcColor + （1- SrcAlpha）* DstColor（old）`

---
* 一些常用的混合操作的写法：
* ![cccecdeeeb8389a74ae4f4e1cceae0a](https://pleasant233.oss-cn-beijing.aliyuncs.com/cccecdeeeb8389a74ae4f4e1cceae0a.jpg)
	`5.1.4.1 诸多混合操作`	
* 下面，我们就来实现一个透明度混合的基本效果。
---
# 5.2 半透明混合
## 5.2.1 基本的半透明混合
* 前文提到了半透明混合的思路，所以我们按图索骥，来实现基本的半透混合效果。
* 首先，我们需要保证渲染顺序的正确性，所以我们需要正确设置渲染的Tag，将队列设置为半透明，并开启忽略半透明的阴影（当然后面我们会启用）。
```ShaderLab
Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
```
* 现在我们就可以来正式写我们的代码了，首先我们需要关闭深度写入，这样才能让后面的物体正常渲染，并且我们设置了混合模式，使用了Alpha混合。
```Shaderlab
ZWrite Off  
Blend SrcAlpha OneMinusSrcAlpha
```
* 接着，我们按照传统流程实现到片元着色器前的内容。
```CG
CGPROGRAM  
  
#pragma vertex vert  
#pragma fragment frag  
  
#include "UnityLightingCommon.cginc"  
#include"UnityCG.cginc"  
fixed4 _Color;  
sampler2D _MainTex;  
float4 _MainTex_ST;  
fixed _AlphaScale;  
  
struct a2v {  
    float4 vertex : POSITION;  
    float3 normal : NORMAL;  
    float4 texcoord : TEXCOORD0;  
};  
  
struct v2f {  
    float4 pos : SV_POSITION;  
    float3 worldNormal : TEXCOORD0;  
    float3 worldPos : TEXCOORD1;  
    float2 uv : TEXCOORD2;  
};  
  
v2f vert(a2v v) {  
    v2f o;  
    o.pos = UnityObjectToClipPos(v.vertex);  
        o.worldNormal = UnityObjectToWorldNormal(v.normal);  
        o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
        o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);  
    return o;  
}
```
---
* 接着就是最关键的片元着色器部分，我们正常的计算法线和光照，按照Lambert模型的计算方式，最后在返回颜色值时，将颜色的a通道与我们的参数中的_AlphaScale相乘，这样就可以完成不透明度的控制了。
```CG
fixed4 frag(v2f i) : SV_Target {  
fixed3 worldNormal = normalize(i.worldNormal);  
    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));  
    fixed4 texColor = tex2D(_MainTex, i.uv);  
    fixed3 albedo = texColor.rgb * _Color.rgb;  
    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;  
    fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));  
    return fixed4(ambient + diffuse, texColor.a * _AlphaScale);  
}
```
* ![Pasted image 20250407094635](https://pleasant233.oss-cn-beijing.aliyuncs.com/Pasted%20image%2020250407094635.png)
	`5.2.1 透明度混合效果`
---
## 5.2.2 双面半透效果
* 现在，透明效果只有一面，我们无法实现拥有体积的半透明效果。所以接下来让我们来看看怎样实现拥有体积的半透，实际上也很简单。
* 目前我们讨论的效果，都是基于关闭深度写入从而实现的效果。为何无法实现体积效果呢？其本质实际上就是因为半透明物体自身无法实现混合效果，因此在混合阶段时直接被替换了颜色。因此，我们就需要对前后进行两次混合，这样就可以得到正确的双层半透效果了。
---
* 要想实现两次混合也很简单，我们只需要从后向前渲染目标物体的两个面就好了，因此就要使用一个新的功能，那就是剔除。
* 剔除是渲染管线中的一个部分，发生在顶点与片元着色之间。（请注意，这里的剔除与裁剪并不是一个概念）。
* 其是可配置的部分，主要包含三种状态：FRONT，BACK，OFF
* 我们使用的方式就是，前后分Pass渲染，第一个Pass先剔除前部，让后方片元与物体后半部分进行混合，第二个Pass剔除后半部分，让前半部分与已经在帧缓冲中的后半部分混合结果再次混合，就可以得到双层效果了。
---
* 代码非常简单，这里就不全部复制了，关键部分，就是两个Pass的剔除配置操作。
```ShaderLab
Pass1
Pass{
	Cull Front
	……
}
Pass 2
Pass{
	Cull Back
}
```
* ![Pasted image 20250407100512](https://pleasant233.oss-cn-beijing.aliyuncs.com/Pasted%20image%2020250407100512.png)
`5.2.2 双层半透明渲染`
---
## 5.2.3 复杂前后遮挡的半透渲染
* 有一些少数情况，部分模型可能存在自身的前后遮挡关系，这时候再使用之前的渲染方式，就会导致深度信息错误（本质就是认为该物体的各位置深度处在同一个值）这就导致会出现这样的错误效果：
* ![Pasted image 20250407100829](https://pleasant233.oss-cn-beijing.aliyuncs.com/Pasted%20image%2020250407100829.png)
`5.2.3 错误的半透效果`
* 解决方式其实很简单，我们只需要额外增加一个Pass，该Pass不向帧缓冲写入任何颜色信息，这样就可以避免干扰之前的渲染，而只是写入深度信息，这样在接下来的混合Pass中，深度信息就正常了，我们就可以正常进行混合了。
---
```Shaderlab
Pass  
{  
    ZWrite On  
    ColorMask 0  
}
```
* ColorMask是一个掩码标记，0的意思是全部过滤，也就是不写入任何信息。也可以指定RGBA通道进行过滤。
* 这样，我们就能得到一个正确显示的物体模型了。
* ![Pasted image 20250407101223](https://pleasant233.oss-cn-beijing.aliyuncs.com/Pasted%20image%2020250407101223.png)
`5.2.4 深度正确的复杂半透效果`
---
# 5.3 透明度测试
## AlphaTest
* 透明度测试的本质就是，只要一个片元的透明度不满足条件（阈值），那么它对应的片元就会被舍弃。被舍弃的片元不会再进行任何处理，也不会影响颜色缓冲。
* 否则就按不透明物体来处理。
* 通常我们会使用clip函数来进行测试。
```CG
void clip(float1-4 x)
```
* 如果给定参数的任何一个分量为负，则舍弃当前像素的输出，等同于
```
void clip(float4 x)
{
	if(any(x<0))
		discard;
}
```
* 原理十分简单，接下来我们就来尝试编写一个透明度测试的Shader。
---
* 首先，在参数栏内，我们需要声明一个用于裁剪的float变量，其作为阈值，若图像纹理的Alpha值与之相减小于0，则省略这个片元。
```
Properties {  
       _Color ("Color Tint", Color) = (1, 1, 1, 1)  
       _MainTex ("Main Tex", 2D) = "white" {}  
       _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5  
    }
```
---
* 接下来，在SubShader的Tag部分，我们需要设定Queue为'AlphaTest"，这样才能正确的使用透明度测试。
* 并且我们将渲染类型设置为“TransparentCutout”。同样是为了正常进行裁剪。
```ShaderLab
Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
```
---
* 随后就是一系列常规操作，这里不多赘述，主要来看片元着色器部分。
* 我们在此处使用纹理自身的Alpha值减去之前在属性栏声明的数值然后传入到clip函数中，这样就能够完成透明度测试了。
* 剩下的代码与之前Lambert模型中的一致，这里就不多赘述了。
```CG
// Alpha test  
             clip (texColor.a - _Cutoff);  
             // Equal to //           if ((texColor.a - _Cutoff) < 0.0) {  
//              discard;  
//           }
```
---
* 我们在使用透明度测试时，可以在Pass中添加 AlphaToMaskOn 这样才进行抗锯齿采样时，引擎会为我们增加边缘的采样次数，以达到抗锯齿的效果。
* ![Pasted image 20250408141828](https://pleasant233.oss-cn-beijing.aliyuncs.com/Pasted%20image%2020250408141828.png)
`5.3.1 AlphaTest`
---
## 5.3.2 模版测试
* 模板测试同样可以实现类似于透明的效果，当然模版测试可以实现的效果还有很多，比如传送门等。
* 其原理便是，每一个片元所对的像素分配一个模版值，用于控制显示哪个片元。
* 之前提到过，模版测试所在的管线位置是逐片元操作阶段，在这一阶段，我们就可以对片元的模版值进行测试，从而过滤掉我们不希望输出到帧缓冲的片元。
* ![Pasted image 20250409102628](https://pleasant233.oss-cn-beijing.aliyuncs.com/Pasted%20image%2020250409102628.png)
`5.3.2 模版测试所处阶段`
---
* 模版测试的逻辑：
```
if（referenceValue comparisonFunction stencil BufferValue）
pass
or
not
```
* 实际上类似于帧缓冲区，渲染管线也会为每个片元提供模版缓冲区，模版缓冲中记录的就是当前帧中所有片元的模版值。
* 对于Shader中对应的模版语法大致如下图所示。
* ![Pasted image 20250409103232](https://pleasant233.oss-cn-beijing.aliyuncs.com/Pasted%20image%2020250409103232.png)
`5.3.3 模版缓冲语法结构`
---
* 对于比较的操作而言也有一系列的操作内容，比如Greater大于，GEqual大于等于等。可参考下图
* ![Pasted image 20250409103423](https://pleasant233.oss-cn-beijing.aliyuncs.com/Pasted%20image%2020250409103423.png)
`5.3.4 比较函数概览`
---
* 对于像素的处理我们也有一系列的方法可供选择，比如Keep保持缓冲中的值不变，Zero将0写入缓冲。
* ![Pasted image 20250409103559](https://pleasant233.oss-cn-beijing.aliyuncs.com/Pasted%20image%2020250409103559.png)
`比较后操作`
---
## 5.3.3 模版测试实践
* 我们来实现一个类似于笼中窥梦中的不同方向不同场景的效果。
* 我们先来分析如何实现这个效果，首先，我们需要具备两个材质，第一个材质是用于检测的材质我们可以叫它StencilTestMask，也就是作为一个遮罩去检测对应的模版值。另一个则是对应的物体，这种物体上的材质需要具备一个对应的模版缓冲值，如果相同则绘制，否则跳过不绘制。这就是我们的原理。
* 现在我们来实现Mask材质。
---
* Mask材质非常简单，实际上它不需要向帧缓冲输出任何值，这个在之前的半透明渲染中我们也使用过，当时是作为写入深度缓冲Pass的一部分而使用的，在此处则是为了检验模版值而使用的。
* 首先我们需要输入一个模版标准值，这个标准值是用来与对应物体模版缓冲中的值做检测用的。
```Shaderlab
Properties  
{  
    _ID("Mask ID", Int) = 1 //设置掩码数值  
}
```
* 接着，我们需要正确的渲染该物体，我们需要声明其在渲染队列中的位置，我们希望它在所有不透明物体前渲染，因此我们需要将其声明在Geometry（几何）队列之后一项，我们可以简单的如此声明：
```Shaderlab
Tags {"RenderType" = "Opaque" "Queue" = "Geometry+1"} //设置渲染标签
```
---
* 随后我们不希望其向帧缓冲中写入任何值，因此我们用掩码过滤掉。同时为了显示后方物体，我们同样不写入深度缓冲值，这样后续物体就能正常经过深度测试。
```Shaderlab
ColorMask 0  
ZWrite Off //这个材质只作为蒙版值使用因此不向帧缓冲与深度缓冲区输入任何值
```
* 接下来我们需要在SubShader中声明模版值和判断函数以及操作方法。
* 我们希望用ID作为参考值，并且默认开启比较，如果通过，则替换帧缓冲的角色。
```Shaderlab
Stencil  
{  
    Ref[_ID] //ID值作为参考值  
    Comp Always //默认开启比较  
    Pass Replace //通过则替换该像素颜色  
}
```
---
* 接下来的代码就很简单了，由于我们不需要显示这一层材质我们只需要正常传递参数实现材质就可以了，这里直接粘出来供大家参考。
```CG
Pass  
        {  
            CGPROGRAM  
            #pragma vertex vert  
            #pragma fragment frag  
            #include "UnityCG.cginc"  
  
            struct v2f  
            {  
                float4 pos : POSITION;     
            };  
            v2f vert(appdata_base v)  
            {                v2f o;  
                o.pos = UnityObjectToClipPos(v.vertex);  
                return o;  
            }            fixed4 frag(v2f i):SV_Target{  
                return fixed4(1,1,1,1);  
            }            ENDCG  
        }  
    }    FallBack "Diffuse"  
}
```
---
* 接下来就是需要检测的部分了，需要检测的目标我们也需要设置其模版值。
* 为了让其渲染正确，我们需要将其固定在检测器后一个队列位置中渲染，所以我们可以这样声明
```Shaderlab
Tags { "RenderType"="Opaque" "Queue" = "Geometry+2"}
```
* 我们可以简单的创建一个默认的表面着色器。然后在参数中同样声明一个ID值，该值作为传入模版缓冲中的值使用，随后，我们写入判断的方法，只有当检测值与模版值相等时才通过，渲染该片元。
```Shaderlab
Stencil  
{  
    Ref[_ID]  
    Comp Equal //如果相等则渲染该片元  
}
```
* 后续代码都不需要更改，这样就完成了笼中窥梦同款效果，十分简单，但也是对于渲染队列以及管线理解的基础检测。
* ![Pasted image 20250410150707](https://pleasant233.oss-cn-beijing.aliyuncs.com/Pasted%20image%2020250410150707.png)
`5.3.3 笼中窥梦效果`
---
# 结语与参考资料
* 本节我们完成了所有基本的透明半透明渲染方式，当然还有很多进阶的内容，比如多层半透明渲染的效率以及前后遮挡的解决方案，基于插孔的半透渲染，以及基于Alpha剔除的半透渲染等，我们会在进阶分享中实现。
* 技术美术百人计划——【【技术美术百人计划】图形 3.1 深度与模板测试  传送门效果示例】 https://www.bilibili.com/video/BV1Tb4y1C7Qa/?p=2&share_source=copy_web&vd_source=18d60239a339ad21d3b3f050742622f4
* UnityShader入门精要 冯乐乐著
* UntiyShaderlab 新手宝典 唐福幸著