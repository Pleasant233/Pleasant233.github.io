---
title: 'EasyShader小结——完成材质添加'
date: '2025-1-24'
description: 添加UV映射与材质读取输入
top_img: https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%9B%BE%E5%BD%A2%E5%AD%A6%E5%88%86%E4%BA%AB%E8%AF%BE%E5%A4%B4%E5%9B%BE.png
cover: https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20241031191729.png
categories: EasyShader
---
* 接下来，在让我们的渲染器以三维形式工作前，我们需要先完成前面遗留的一点小问题，我们目前还无法渲染一张纹理。
* 这在原教程中为一个家庭作业，因为我们的目的是了解渲染器如何工作而不是成为一个图形程序。
* 因此，我们之后的代码以实现效果的学习为主而不是重构和追求代码的封装架构，当然后续会尽可能地将方法封装为类。
---
* 如果想要有一个如下图类似的苹果材质，我们需要怎么做呢？
* ![屏幕截图 2024-05-30 095357.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202024-05-30%20095357.png)
	`4.1 技术部正式群的头像苹果图片`
---
* 大致分为以下几个步骤
	* 首先，我们需要获取并导入纹理
	* 接着，我们需要正确的读取并映射纹理（还记得UV坐标吗）
	* 最后我们需要输出带有纹理信息的图片
* 接下来，我们通过阅读源码逐一进行学习。感谢开源的大佬为我们提供了学习的平台，我们在理解的基础上运用代码学习，本身也算是一种实践。
---
## 4.1.1 修改Model类以适应更新

* 首先，为了加载材质，我们需要进行一些准备工作，其中之一就是，先要保证我们能够获取并导入纹理，在model中，我们增加了面法线，面uv，这些都可以在obj文件中获取，接着，我们增加了一个TGAIMAGE对象作为存储漫反射纹理的目标，并增加了对应的uv映射，以及漫反射贴图映射计算的函数，为我们第二步工作做好准备。
```c++
std::vector<Vec3f> norms_;//面法线
std::vector<Vec2f> uv_;//面uv
TGAImage diffusemap_;//漫反射贴图
void load_texture(std::string filname, const char* suffix, TGAImage& img);//加载贴图

Vec2i uv(int iface, int nvert);//加载uv函数
TGAColor diffuse(Vec2i uv);//漫反射贴图映射计算。
```
* 详细的内容我们在Model.cpp中定义，这也是应用了声明与定义分离的思想。
---
* 在上一节中我们最后将代码重构为加入矩阵的版本，我们重构了geometry类，这也为我们本讲对于Modle类的重构提供了便利。
* 接下来我们进入对于主函数的修改。我们将重新编写之前的深度缓冲，三角形绘制方法，让其能够支持绘制纹理
* 首先我们抽象出了一个int指针类型的变量用于记录深度信息，其为zbuffer将其初始化为NULL
---
```c++
int* zbuffer = NULL;
```

* 接下来，我们在主函数中初始化它，这与我们先前做的一样。
```c++
zbuffer = new int[width * height];
for (int i = 0; i < width * height; i++) {
    zbuffer[i] = std::numeric_limits<int>::min();
}
```
* 与申请模型空间一直，在运行结束后我们需要释放我们申请的空间，因此在主循环结尾，我们需要释放zbuffer
```c++
delete[] zbuffer;
```
---
# 4.4 更新三角形绘制方法

* 这里为了便于大家理解，我们回归最开始的扫描线绘制方法，当然包围盒同样也可以绘制纹理，可以单独为包围盒算法计算uv纹理坐标，这一点大家可以自行开发。
* 这里只为各位提供思路。先前我们了解到，实际上uv坐标就是一个对应查找的坐标映射，大家可以理解为一个函数，所以其查找方法与我们绘制直线的方法应当是相同的。也就是都需要进行插值
```c++
Vec2i uvA = uv0 + (uv2 - uv0) * alpha;
Vec2i uvB = second_half ? uv1 + (uv2 - uv1) * beta : uv0 + (uv1 - uv0) * beta;
```
---
* 我们需要修改传入参数的部分，将其修改为传入uv0，uv1，uv2的部分，这些参数本身来源于我们的obj模型数据。
```c++
void triangle(Vec3i t0, Vec3i t1, Vec3i t2, Vec2i uv0, Vec2i uv1, Vec2i uv2, TGAImage& image, float intensity, int* zbuffer)
```
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250123150501.png)
	`4.4 obj中的uv坐标信息`
---
* 随后，我们在A和B之间进行插值计算，得到逐个点的坐标以及uv坐标信息，并且以该点坐标为索引设置其深度值，这时，我们会从模型的漫反射贴图中取得该点对应的颜色信息，并依照该点强度值进行设置。
```c++
for (int j = A.x; j <= B.x; j++) {
    float phi = B.x == A.x ? 1. : (float)(j - A.x) / (float)(B.x - A.x);
    Vec3i   P = Vec3f(A) + Vec3f(B - A) * phi;
    Vec2i uvP = uvA + (uvB - uvA) * phi;
    int idx = P.x + P.y * width;
    if (zbuffer[idx] < P.z) {
        zbuffer[idx] = P.z;
        TGAColor color = model->diffuse(uvP);
        image.set(P.x, P.y, TGAColor(color.r * intensity, color.g * intensity, color.b * intensity));
    }
}
```
---
# 4.5 采样并设置uv

* 最后我们只需要对uv进行采样并设置就好了，这一点实际上跟采样顶点很类似，我们实例化一个二维向量数组，随后将模型对应的uv点坐标设置在上面就可以了。
```c++
Vec2i uv[3];
for (int k = 0; k < 3; k++) {
    uv[k] = model->uv(i, k);
}
```
* 最后，我们只需要将所有数据传入triangle函数中，就可以得到一个有diffuse贴图的苹果了。
---
![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20250123151930.png)	`4.5  最后结课成品`

---
# 4.6 结语

* 不知不觉，我们的图形学分享课就要跟大家说再见了，但是学习图形学的路程依旧漫长，我们只不过是瞥见了冰山一角。EasyShader渲染器为我们提供了很多便利，大家可以跟随原作者的路线继续学习，同样的进阶版渲染器也可以在我的github上找到。下学期会继续给大家分享进阶的光线追踪以及渲染器实践~，还有正式的Shader内容，敬请期待，新的一年，我们一起进步！
---
*  计算机图形学入门——3D渲染指南
* https://github.com/ssloy/tinyrenderer
* 我的项目地址：
* https://github.com/Pleasant233/EasyRender