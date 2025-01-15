---
title: 'EasyShader——线框与三角形'
date: '2025-1-15'
description: 苹果线框绘制与三角形绘制
top_img: https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%9B%BE%E5%BD%A2%E5%AD%A6%E5%88%86%E4%BA%AB%E8%AF%BE%E5%A4%B4%E5%9B%BE.png
cover: https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20241031191729.png
categories: EasyShader
---
# 前言

* 本节分享需要一个obj格式的模型文件，我的库里提供了这个文件，当然，如果你具备建模能力也可以自己建一个模型使用，重要的是思路，不是素材！当然素材一样会提供，并且这节分享需要更多的资源我们一一来看。
---
* model.h
	* 这个头文件是用来导入模型的，它能够导入后缀为obj的模型类型。
* Vector
	* 这是c++为我们提供的库文件，它叫做容器，内部维护着一个动态数组，我们通过它来讲模型数据导入并输出成为像素点。
---
## 2.1 重构mainc.cpp

## 2.1.1 头文件项更改

* 首先我们必须加入以上提到的头文件，依次获取其中的变量与方法。
```c++
#include <vector>
#include <cmath>
#include "tgaimage.h"
#include "model.h"
#include "geometry.h"
```
## 2.1.2 全局变量与main函数修改

* 我们需要创建一个Model * 类型的变量，它本身是个Model类型的指针，对应着一片Model长度的内存地址，我们用其来存储我们读取到的模型。
```c++
Model *model = NULL;
```
* 我们现将其设置为空，请注意，在此提醒一个编程小技巧，我们能够申请到的空间叫做堆，我们需要谨慎小心地操作内存空间，所以一定要对每一个声明的指针变量对应一个确定的内存区域，NULL区域在不同的系统中对应空间不一样，但是它是安全的，所以我们一开始将其赋于我们的模型变量，让它安全的申请下来。
---
* 接下来是main函数部分
* 首先我们需要让main函数具有两个参数，你可能觉得这不符合你的习惯，确实，我们一般不在main函数中声明参数，但main函数实际上是程序运行的入口函数，它是被系统调用的函数之一，因此我们一样完全可以为其添加参数
---
* 这两个参数是为了防止读取模型失败导致内存泄漏而存在的，如果模型正常加载则写入我们存放在对应路径下的文件（注意是相对路径），否则交给model内的方法处理。
```c++
int main(int argc, char** argv) {
    if (2==argc) {
        model = new Model(argv[1]);
    } else {
        model = new Model("obj/.obj");
    }
}
```
---
* 接下来，我们需要对.obj文件进行读取，如果你打开.obj文件，其实可以发现，它就是一大堆的点坐标，我们需要的就是依次读入点坐标所形成的面，并调用我们之前的line算法，将其连接并画在画布上。
```c++
for (int i=0; i<model->nfaces(); i++) {
        std::vector<int> face = model->face(i);
        for (int j=0; j<3; j++) {
            Vec3f v0 = model->vert(face[j]);
            Vec3f v1 = model->vert(face[(j+1)%3]);
            int x0 = (v0.x+1.)*width/2.;
            int y0 = (v0.y+1.)*height/2.;
            int x1 = (v1.x+1.)*width/2.;
            int y1 = (v1.y+1.)*height/2.;
            line(x0, y0, x1, y1, image, white);
        }
    }
```
---
* 我们遍历模型中所有的面，并将其全部装到一个int类型的数组中，而后我们以3为一个单位，去遍历这个数组，并将其中的点取出作为v0和v1，而后我们将这些点缩放到屏幕空间（希望你还记得这个概念），最后调用绘制算法，将图像用白色绘制到画布上！
* 不过在这里你得到的可能是反着的，这和坐标系不同有关（希望你同样记得这个概念），接下来我们利用TGAIMAGE内置的方法，将这个图像统统翻转！然后绘制就好了，但最后别忘记释放你申请的内存！这跟申请一样同样需要你小心翼翼！
```c++
 image.flip_vertically(); 
    image.write_tga_file("output.tga");
    delete model;
    return 0;
```
---
## 2.1.3 物体线框渲染

* 现在，你就可以得到你的大苹果了！
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241113112119.png)
	`2.1.2 线框大苹果`
* 很有成就感是不是？但这远远没有结束，我们将做的更酷！最后我们完成时，这将是个有材质的苹果。
---
## 2.2 三角形

## 2.2.1 三角形线框绘制

* 首先，三角形是由基本的三个点组成的，因此我们如果要定义一个绘制三角形点的函数，这并不困难，我们只需要让其包含三个最基本的点坐标，并用合适的颜色绘制它就好了，这和我们绘制苹果线框的逻辑是一样的，所以在这里我们可以利用line方法写出一个初步的方案
```c++
void triangle(Vec2i t0, Vec2i t1, Vec2i t2, TGAImage &image, TGAColor color) { 
    line(t0, t1, image, color); 
    line(t1, t2, image, color); 
    line(t2, t0, image, color); 
}
```
---
* 让我们测试一下这个函数，我们绘制三个三角形
```c++
Vec2i t0[3] = {Vec2i(0, 70),   Vec2i(10, 160),  Vec2i(10, 80)}; 
Vec2i t1[3] = {Vec2i(120, 50),  Vec2i(160, 1),   Vec2i(70, 180)}; 
Vec2i t2[3] = {Vec2i(184, 150), Vec2i(122, 160), Vec2i(130, 120)}; 
triangle(t0[0], t0[1], t0[2], image, red); 
triangle(t1[0], t1[1], t1[2], image, white); 
triangle(t2[0], t2[1], t2[2], image, green);
```
---
* 最后你应该会得到这张图像
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241113120108.png)
	`2.2.1 简单的三角形线框 `
---
## 2.2.2 三角形填充原理

* 实际上，这个问题的解决方法有很多，我们可以尝试很多不同的方法，在此我们先根据最简单的思路，那就是扫描线绘制，我们可以一条一条的填充我们的三角形，这条线的y值是固定的，x值由左端到右端变化，我们只需要依次调用我们之前写好了的DrawLine方法，绘制就可以了，伪代码如下
```
For each horizontal line y between the triangle‘s top and Bottom
comput x_left and x_right for this y
drawline(x_left,y,x_right,y)
```
---
* 接着，我们可以将y值进行排序，选出三个点之中的最小值和最大值，并将其分别命名为y0，y2，所以y的取值就是在y0——y2区间内。
* 随后我们关注我们的x_left与x_right，我们希望他们包含整个三角形的全部取值范围，因此我们需要关注不同形态的三角形，并计算其边的x值。
---
* 对于三角形我们可以通过y值分出长边和短边，在这里我们统一定义P0——P2为高边。x_right的值要么来自高边，要么来自短边
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241118094225.png)
	`2.2.2 分离三角形的高边与短边`
---
* 因此我们可以使用插值计算这些边中y值对应的x值，其实就是之前我们绘制直线方法的变体。我们将这些数据记录在三个数组之中，并且合并x01 和 x12 数组为x012 也就是整个三角形的x变量数组。
* 随后我们就可以判断谁是x_left中的数谁是x_right中的数了，只需要选择任何一条水平线，比较其在x02与x012中的值，如果x02 小于x012，那么就说明x02中的值为x_left否则为x_right。至此我们完成了绘制方法，接着调用DrawLine方法绘制即可。
* 接下来我们来看代码实现
---
## 2.3 代码实践

## 2.3.1 三角形长短边分类

* 首先来按我们的思路，给三角形长短边分分类吧，这在代码实现中很简单，我们只需要判断谁大谁小，然后给他们排序就好了。
```c++
void triangleLine(Vec2i t0, Vec2i t1, Vec2i t2, TGAImage& image, TGAColor color)
{
	//在这段代码中我们主要区分长边与短边,我们需要将其按从小到大排序
	if (t0.y > t1.y) std::swap(t0, t1);
	if (t0.y > t2.y) std::swap(t0, t2);
	if (t1.y > t2.y) std::swap(t1, t2);
	//排序好了，我们将其分别绘制
	line(t0, t1, image, green);
	line(t1, t2, image, green);
	line(t2, t0, image, red);
	//最后我们将得到长边与短边的区分，最长的也就是y差别最大的就是长边，红色。
}
```
---
## 2.3.2 上下区域分离

* 现在我们已经可以区分长边和短边了，下一步我们就将对三角形进行分解，因为短边始终会有两个，因此我们会将这两个边按其交点处分解，分别绘制！
```c++
void ApartOfTriangle(Vec2i t0, Vec2i t1, Vec2i t2, TGAImage& image, TGAColor color)
{
	if (t0.y > t1.y) std::swap(t0, t1);
	if (t0.y > t2.y) std::swap(t0, t2);
	if (t1.y > t2.y) std::swap(t1, t2);
	//首先我们计算总高度，这也就是最长边的y值变化范围
	int total_height = t2.y - t0.y;
	//随后我们绘制其中下方的短边所形成的部分
	for (int y = t0.y; y <= t1.y; y++)
	{
		int segment_height = t1.y - to.y + 1;
		//我们设置我们需要绘制的直线范围，这里+1是为了避免重复绘制
		float alpha = (float)(y - t0.y) / total_height;
		float beta = (float)(y - t0.y) / segment_height;
		//这里是设置占比范围，通过乘上不同的占比来设置最后绘制的图像的真实距离
		//实际上做的就是线性插值！
		Vec2i A = t0 + (t2 - t0) * alpha;
		Vec2i B = t0 + (t1 - t0) * beta;
		image.set(A.x, y, red);
		image.set(B.x, y, green);
	}	
}
```
---
* 现在我们已经可以描绘三角形下半部分的线框了，但这样的线性插值难免会有问题，因为步长的缘故所以会出现断线！
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241119113726.png)
`2.3.2 断线问题`
* 这个问题其实我们可以忽略，因为最后绘制时我们用对应的水平线连接这些点，间隙就会消失。
---
## 2.3.2 填充三角形并绘制上半部分

* 我们可以直接简单的使用一个for循环去绘制这些连接两段的直线，为了避免出现问题，我们在设置直线时先判断大小，若大小相反则将其翻转并绘制
```c++
void FilledTriangle(Vec2i t0, Vec2i t1, Vec2i t2, TGAImage image, TGAColor color)
{
		if (A.x < B.x)
			std::swap(A, B);
		for (int j = A.x; j <= B.x; j++)//通过内层嵌套的循环绘制每一层的线条
		{
			image.set(j, y, color);
		}
			
	}
	for (int y = t1.y; y <= t2.y; y++) {
		int segment_height = t2.y - t1.y + 1;
		float alpha = (float)(y - t0.y) / total_height;
		float beta = (float)(y - t1.y) / segment_height; // be careful with divisions by zero 
		Vec2i A = t0 + (t2 - t0) * alpha;
		Vec2i B = t1 + (t2 - t1) * beta;
		if (A.x > B.x) std::swap(A, B);
		for (int j = A.x; j <= B.x; j++) {
			image.set(j, y, color); // attention, due to int casts t0.y+i != A.y 
		}
	}
}
```
* 恭喜你，你现在已经可以绘制一个实心三角形了，但是我们可以做的更好
---
* 首先被考虑到的就是，我们可以对代码层面进行优化，因为现在存在四个for循环，总共的时间复杂度就是2n^2，我们可以将其缩减。合并为一个for循环。
```c++
void FilledTriangleLv2(Vec2i t0, Vec2i t1, Vec2i t2, TGAImage image, TGAColor color)
{
	if (t0.y > t1.y) std::swap(t0, t1);
	if (t0.y > t2.y) std::swap(t0, t2);
	if (t1.y > t2.y) std::swap(t1, t2);
	//首先我们计算总高度，这也就是最长边的y值变化范围
	int total_height = t2.y - t0.y;
	//随后我们绘制其中下方的短边所形成的部分
	for (int i =0;i<total_height; i++)
	{
		//首先我们先判断绘制的是上部分还是下部分
		bool secound_half = i > t1.y - t0.y || t1.y == t0.y;
		//这两个条件分别对应了锐角三角形以及直角三角形的情况
		int segment_height = secound_half ? t2.y - t1.y : t1.y - t0.y;
		//我们根据上面的判断结果来设置我们绘制的是那一部分的高度
		float alpha = (float)i / total_height;
		float beta = (float)(i - (secound_half ? t1.y - t0.y : 0)) / segment_height;
		//这部分我们通过处理绘制哪一部分来排除我们已经绘制的部分保证参数正确。
		Vec2i A = t0 + (t2 - t0) * alpha;
		Vec2i B = secound_half ? t1 + (t2 - t1) * beta : t0 + (t1 - t0) * beta;
		//这里我们判断绘制的是哪个部分，要是上半部分就从t1开始
		if (A.x > B.x) std::swap(A, B);
		for (int j = A.x; j < B.x; j++)
		{
			image.set(j, t0.y + i, color);//这里我们保证绘制是从最低点开始的。
		}
	}
}
```
---
* 大功告成了！。。。吗？不知道你是否还记得。在光栅化篇我们提到过的，包围盒以及后续提到的重心坐标的概念，我们如果按现在这种扫描线的方法设置，确实很简单，但效率很低，我们希望优化我们的算法，跟上时代，接下来我们将利用包围盒以及重心坐标，重新绘制三角形！
---
# 参考资料

* 计算机图形学入门——3D渲染指南
* https://github.com/ssloy/tinyrenderer
* 我的项目地址：
* https://github.com/Pleasant233/EasyRender