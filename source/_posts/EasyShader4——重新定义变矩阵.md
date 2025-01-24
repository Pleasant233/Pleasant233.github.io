---
title: 'EasyShader——重新定义变换矩阵'
date: '2025-1-24'
description: 添加Matrix类定义矩阵变换
top_img: https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%9B%BE%E5%BD%A2%E5%AD%A6%E5%88%86%E4%BA%AB%E8%AF%BE%E5%A4%B4%E5%9B%BE.png
cover: https://pleasant233.oss-cn-beijing.aliyuncs.com/%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20241031191729.png
categories: EasyShader
---
# 4.0 前言

* 本篇是在重心坐标与深度检测成功绘制了前后关系正常的苹果图像，和后一节也就是本次图形学基础课实践部分的最终章节——漫反射材质导入的起承转合章节。本章我们将重构我们的变换代码，主要涉及一下几个部分
	* geometry 类
	* main.cpp
* 我们将实际将矩阵应用在我们的光栅化渲染器中，最后实现效果，为后续进阶的可变换视角的渲染器版本做铺垫。
---
# 4.1 Geometry类

* 首先是geometry类，我们对其进行了简单的重构，增加了Matrix类的定义，以及方法实现。相关的代码你可以在我们的库中找到，记住要找到矩阵分支~。
* 我们来看矩阵类的实现。
* 首先我们定义了一个数组，和两个int类型的值分别代表行和列。接着我们定义了基本的初始化方法以及一些基本的运算，如矩阵的乘法，矩阵的转置，逆阵等。
```c++
class Matrix {
    std::vector<std::vector<float> > m;
    int rows, cols;
public:
    Matrix(int r = DEFAULT_ALLOC, int c = DEFAULT_ALLOC);
    inline int nrows();
    inline int ncols();

    static Matrix identity(int dimensions);
    std::vector<float>& operator[](const int i);
    Matrix operator*(const Matrix& a);
    Matrix transpose();
    Matrix inverse();

    friend std::ostream& operator<<(std::ostream& s, Matrix& m);
};
```
---
* 我们在cpp中实现它们。
* 首先是最基本的两个内联函数，这两个函数只返回其本身的值。
```c++
int Matrix::nrows() {
    return rows;
}

int Matrix::ncols() {
    return cols;
}
```
* 接着，是一个初始化单位阵的函数identity,返回一个单位阵
```c++
Matrix Matrix::identity(int dimensions) {
    Matrix E(dimensions, dimensions);
    for (int i = 0; i < dimensions; i++) {
        for (int j = 0; j < dimensions; j++) {
            E[i][j] = (i == j ? 1.f : 0.f);
        }
    }
    return E;
}
```
---
* 随后，是一个计算符【】，返回矩阵第i 列的值。
```c++
std::vector<float>& Matrix::operator[](const int i) {
    assert(i >= 0 && i < rows);
    return m[i];
}
```
---
* 接着是乘法，我们只需要取每一行每一列数乘即可
```c++
Matrix Matrix::operator*(const Matrix& a) {
    assert(cols == a.rows);
    Matrix result(rows, a.cols);
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < a.cols; j++) {
            result.m[i][j] = 0.f;
            for (int k = 0; k < cols; k++) {
                result.m[i][j] += m[i][k] * a.m[k][j];
            }
        }
    }
    return result;
}
```
---
* 然后是转置，我们只需要新实例化出一个矩阵，并反向填入目标矩阵的值即可
``` c++
Matrix Matrix::transpose() {
    Matrix result(cols, rows);
    for (int i = 0; i < rows; i++)
        for (int j = 0; j < cols; j++)
            result[j][i] = m[i][j];
    return result;
}
```
---
* 最后是最为麻烦的逆阵，在这里，我们应用了教科书上的求逆阵方式，也就是所谓的高斯消元法，通过增加一个单位阵并将原矩阵化为最简阶梯形矩阵的方式，得到逆阵。
* 详细代码你可以在我的库里找到~。
---
# 4.2 Main

* 现在，我们需要根据我们处理好的矩阵，来对我们的主函数文件进行重构。
* 但首先，我们需要先回顾一下之前是如何处理相关内容的。回顾先前的代码，我们法线，之前我们定义了一个直接将世界空间坐标映射到视口坐标的Worldtoscreen方法。
```c++
Vec3f world2screen(Vec3f v) {
    return Vec3f(int((v.x + 1.) * width / 2. + .5), int((v.y + 1.) * height / 2. + .5), v.z);
}
```
---
* 并没有中间的裁剪和投影阶段。这很类似正交投影的方法，不过我们希望其能够移动，也就是能有透视
* 因此我们需要实现一系列新方法。
* 首先是两个基础的转换函数。其作用在于将矩阵形式和向量形式相互转换，在后续进行矩阵和向量混合运算时起到关键作用。
* 在这里，我们强调一点，实际上矩阵也就是一个二维数组，向量则是一个一维数组，计算机中存储二维数组的形式同样是线性排布的。
* ![image.png](https://pleasant233.oss-cn-beijing.aliyuncs.com/20241226122411.png)
	`4.2.1`
---
* 以下是两个方法的代码
```c++
Vec3f m2v(Matrix m) {//转换函数，将矩阵形式转换为向量形式。
    return Vec3f(m[0][0] / m[3][0], m[1][0] / m[3][0], m[2][0] / m[3][0]);
}

Matrix v2m(Vec3f v) {//转换函数，将向量转换为矩阵形式。
    Matrix m(4, 1);
    m[0][0] = v.x;
    m[1][0] = v.y;
    m[2][0] = v.z;
    m[3][0] = 1.f;
    return m;
}
```
* 定义完这两个基础方法后，下一步，我们就需要定义两个重要的转换操作，一个是视图变换矩阵一个是透视投影矩阵。
---
# 4.3 视图变换与透视投影变换

* 首先是外部的视图变换，教程中将这一步与下一步合并，形成了新的视图变换矩阵。
```c++
Matrix viewport(int x, int y, int w, int h) {//视口+正交变换
    Matrix m = Matrix::identity(4);
    m[0][3] = x + w / 2.f;
    m[1][3] = y + h / 2.f;
    m[2][3] = depth / 2.f;

    m[0][0] = w / 2.f;
    m[1][1] = h / 2.f;
    m[2][2] = depth / 2.f;
    return m;
}
```
---
# 4.4 main函数中的变化

* 在main函数中，我们首先初始化了一个透视矩阵，随后调用了先前写好的视图变化矩阵方法，得到了一个视图变化矩阵，随后，我们余弦设定了相机的位置朝向，并以此初始化了透视矩阵中第四行第三列的值。
```c++
Vec3f camera(0,0,-1);
...
int main(...)
{
...
Matrix Projection = Matrix::identity(4);
//初始化一个透视矩阵
Matrix ViewPort = viewport(width / 8,height /8,width * 3/4 ,height * 3 / 4)
//初始化一个视图+正交矩阵
 Projection[3][2] = -1.f / camera.z;//设置矩阵中第四行第三列的值为-z
}
```
---
* 接着，我们需要在绘制模型时做一些改动，回归我们最开始绘制的方法，我们需要两个坐标，分别是屏幕以及世界坐标，之后，我们就可以用矩阵的方式得到屏幕坐标，相比之前更加方便了。
```c++
 Vec3i screen_coords[3];
 Vec3f world_coords[3];
 for (int j = 0; j < 3; j++) {
     Vec3f v = model->vert(face[j]);
     screen_coords[j] = m2v(ViewPort * Projection * v2m(v));
     world_coords[j] = v;
 }
```
* 关于矩阵部分的设置，基本上就到此结束了，接下来我们就可以正式进入对于模型加载贴图并绘制的部分了。我们需要修改Model头文件，添加uv坐标以及导入图片纹理的方法。
---
# 参考资料

*  计算机图形学入门——3D渲染指南
* https://github.com/ssloy/tinyrenderer
* 我的项目地址：
* https://github.com/Pleasant233/EasyRender