---
title: 'EasyShader——重心坐标检测以及深度缓冲'
date: '2025-1-17'
description: 绘制前后遮挡关系正常的苹果
top_img: https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%9B%BE%E5%BD%A2%E5%AD%A6%E5%88%86%E4%BA%AB%E8%AF%BE%E5%A4%B4%E5%9B%BE.png
cover: https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20241031191729.png
categories: EasyShader
---
# 3.1 重心坐标

* 先前在光栅化部分的理论讲解中，我们大致知道了重心坐标的概念，在此我们再次回顾一下。重心坐标是一种用三个顶点来描述三角形中任意顶点属性值的方法，其三个系数和为1，而我们可以用这样的方法来优化我们对于三角形的描述。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241025120903.png)
---
* 我们通过计算三角形顶点与任意一点P的关系来计算其是否在三角形内，这用到了我们先前提到的判断方法，也就是判断其叉积是否符号一致，而转化到重心坐标中我们就可以用叉积的第三个结果是否小于1来判断。
* 如果第三个值小于1，则说明其为0，这是因为我们的数值都是以整数值作为坐标的。于是这个三角形就是不正确的，此时我们直接返回一个错误值即可。若正确我们就返回其在重心坐标下的值即可。
```c++
Vec3f barycentric(Vec2i *pts, Vec2i P) { 
    Vec3f u = Vec3f(pts[2][0]-pts[0][0], pts[1][0]-pts[0][0], pts[0][0]-P[0])^Vec3f(pts[2][1]-pts[0][1], pts[1][1]-pts[0][1], pts[0][1]-P[1]);
    if (std::abs(u.z)<1) return Vec3f(-1,1,1);
    return Vec3f(1.f-(u.x+u.y)/u.z, u.y/u.z, u.x/u.z); 
}
```
---
# 3.2 包围盒判断

* 先前我们曾在光栅化中介绍了包围盒判断法，现在我们来看它的实现。
* 首先，包围盒需要我们确定这个图元的边界，而事先，我们需要设定这个边界值。最大值我们设定为画布大小-1，最小值我们设定为（0,0）。
```c++
void TriangleWithBox(Vec2i pts* , TGAImage image,TGAColor color)
{
	Vec2i bboxmin(0,0);
	Vec2i   bboxmax(image.get_width()-1,
	image.get_height()-1);
}
```
---
* 随后，我们需要限定包围盒的最大范围为画布的最大范围。然后，根据传入的顶点值，来更新包围盒的范围。
* 包围盒的最小范围我们取的是传入顶点与包围盒最大范围的最小值，并将其更新到包围盒的坐标中。
```c++
···
Veci clamp(image.get_width()-1,
image.get_height()-1);
for(int i =0;i<3;i++)
{
	bboxmin.x = std::max(0,std::max(bboxmin.x,pts[i].x));
	bboxmin.y = 
std::max(0,std::max(bboxmin.y,pts[i].y));
}
```
---
包围盒的最大范围设置也是如此，我们取包围盒现有得最小值与顶点值的最大值。同时不超过画布范围。
```c++
{
	···
	bboxmax.x = 
std::min(clamp,std::min(bboxmax.x,pts[i].x));
	bboxmax.y = 
std::min(clamp,std::min(bboxmax.y,pts[i].y));
}
```
---
* 随后，我们创建一个点P，遍历在包围盒内的P点，并判断其是否在三角形内，如果其任意值不小于0，则证明其在三角形内，便设置这个点。
```c++
Vec2i P;
for(P.x = bboxmin.x;P.x <= bboxmax.x;P.x++)
{
	for(P.y = bboxmin.y;P.y<=bboxmax,y;P.y++)
	{
		 Vec3f bc_screen  = barycentric(pts, P); 
		 if(bc_screen.x<0 || bc_screen.y<0 || bc_screen.z<0) continue;
	        image.set(P.x, P.y, color);
	}
}
```
* 这样，我们便完成了最基本的包围盒检测与设置，后续我们会改进算法，让它们更规范。
---
* 接下来我们来看一个叫做深度缓冲的东西，这个技术在我们的渲染器中的应用就是用来防止被遮挡的面渲染到其他面前面。
* 深度缓冲有一些基本的特性，之前在理论部分我们了解到了，深度缓冲存储着该像素点的最小深度，并实时更新。在实际实现部分，深度缓冲是窗口自动创建的，会以16,24,32 位浮点形式存储深度值。
* 在后续我们还会优化深度缓冲的算法，目前它只作为判断前后顺序的一个标准。
---
# 3.3 更新深度缓冲算法

## 3.3.1 对重心坐标判断法的重构

* 首先，更新后最大的重构就是，我们需要引入深度缓冲，当然这并不困难，对于我们的玩具渲染器而言，我们实践是为了更好的理解原理，后续工业化的实践你可以借助图形API来完成，当然我们没有兴趣也没有必要自己写API。
* 在我们的包围盒判断函数中，我们将使用一个更为直观简便的矩阵写法，代替我们之前所写的一大长串的点积公式。
---
* 首先，我们定义了一个Vec3f 变量的数组，在计算之前，请确保你更新了你的geometry头文件，我们将会依赖其中定义的运算符。
* 之后，我们使用一个for循环，计算出用来判断的三个向量值，并填充这个空的矩阵。
```c++
 Vec3f s[2];
 for (int i = 2; i--; ) {
     s[i][0] = C[i] - A[i];
     s[i][1] = B[i] - A[i];
     s[i][2] = A[i] - P[i];
 }
```
* 就像上面这样。
---
* 随后，就到了我们最重要的求重心坐标的阶段了，首先我们计算了叉积得到了该平面的法向量，其中z分量代表了面向观察者的三角形面积，如果这个值非常小，说明该三角形是退化的（三点共线），也就是说可以忽略，所以我们就返回一个无效值即可。如果通过，则计算P的重心坐标
```c++
Vec3f u = cross(s[0], s[1]);
if (std::abs(u[2]) > 1e-2) // dont forget that u[2] is integer. If it is zero then triangle ABC is degenerate
    return Vec3f(1.f - (u.x + u.y) / u.z, u.y / u.z, u.x / u.z);
return Vec3f(-1, 1, 1); // in this case generate negative coordinates, it will be thrown away by the rasterizator
```
---
* 这样，我们就更新了我们的判断函数，接下来，我们利用这个新的判断函数作为检测依据，与包围盒算法一起更新，最后加入深度缓冲判断。
---
## 3.3.2 对于包围盒三角形绘制法的重构

* 接下来，让我们关注三角形，先前我们使用了包围盒作为三角形绘制的方法，效果不错，现在我们需要在其中加入深度缓冲作为优化方法，其实这并不困难，我们只需要写入对应的深度值就好了。利用我们已经做好的算法，只需要改进一下就好了。
* 首先，让我们先关注对包围盒的优化~
```c++
 Vec2f bboxmin(std::numeric_limits<float>::max(), std::numeric_limits<float>::max());
 Vec2f bboxmax(-std::numeric_limits<float>::max(), -std::numeric_limits<float>::max());
```
* 首先，我们先将包围盒扩展为c++能够得到的上下限，这个做法是为了后续我们进行大规模渲染做准备，我们需要足够的空间。
---
* 接着，我们需要限定画布的范围，我们只希望渲染画布上的内容，因此依然限定为画布大小。
```c++
 Vec2f clamp(image.get_width() - 1, image.get_height() - 1);
```
* 随后，我们利用嵌套循环，实现了对包围盒的更新。
```c++
for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 2; j++) {
        bboxmin[j] = std::max(0.f, std::min(bboxmin[j], pts[i][j]));
        bboxmax[j] = std::min(clamp[j], std::max(bboxmax[j], pts[i][j]));
    }
}
```
---
* 接着，我们利用包围盒算法进行绘制，首先我们判断屏幕上任意一点是否在对应的三角形内，并利用我们之前完成的中心坐标算法进行计算。
```c++
Vec3f P;
for (P.x = bboxmin.x; P.x <= bboxmax.x; P.x++) {
    for (P.y = bboxmin.y; P.y <= bboxmax.y; P.y++) {
        Vec3f bc_screen = barycentric(pts[0], pts[1], pts[2], P);
```
* 如果任意一个值小于0则直接跳过，说明不在该点内，接着我们先初始化P的z值为0，这与一般的方法不一样，不过无伤大雅，因为我们想做的只是逐层绘制而已。
---
```c++
if (bc_screen.x < 0 || bc_screen.y < 0 || bc_screen.z < 0) continue;
P.z = 0;
```
* 接着，就到了最重量级的环节，我们需要获得这个三角形所在像素的深度值，通过对应顶点的z值与对应权重相乘来得到P的近似权重值，以此更新深度缓冲值。
* 接着，我们对于深度缓冲的每一个像素进行判断，如果P点的深度值比它大，就将其更新为P的权重值，并设置该点颜色。
```c++
 if (zbuffer[int(P.x + P.y * width)] < P.z) {
     zbuffer[int(P.x + P.y * width)] = P.z;
     image.set(P.x, P.y, color);
 }
```
---
* 大功告成，不过现在，我们还需要更新一下屏幕呈现的算法，因为我们需要将世界坐标变化为屏幕坐标，希望你还记得这一步视口变换~。
```c++
Vec3f world2screen(Vec3f v) {
    return Vec3f(int((v.x + 1.) * width / 2. + .5), int((v.y + 1.) * height / 2. + .5), v.z);
}
```
* 随后我们将创建一个深度缓冲数组，并将窗口大小传给它，随后我们将其初始化为c++数值上限，代表无限远。
```c++
 float* zbuffer = new float[width * height];
 for (int i = width * height; i--; zbuffer[i] = -std::numeric_limits<float>::max());
```
* 接着就是一如既往的操作，我们从模型中取出顶点，通过变换将其变换为视口坐标，然后绘制它。
```c++
 TGAImage image(width, height, TGAImage::RGB);
 for (int i = 0; i < model->nfaces(); i++) {
     std::vector<int> face = model->face(i);
     Vec3f pts[3];
     for (int i = 0; i < 3; i++) pts[i] = world2screen(model->vert(face[i]));
     triangle(pts, zbuffer, image, TGAColor(rand() % 255, rand() % 255, rand() % 255, 255));
 }
```
---
* 这样我们就得到了最终渲染的新苹果。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241210111025.png)
	`3.3.2 深度缓冲更新后前后遮挡关系正确的苹果`
---
# 参考资料

* 计算机图形学入门——3D渲染指南
* https://github.com/ssloy/tinyrenderer
* 我的项目地址：
* https://github.com/Pleasant233/EasyRender