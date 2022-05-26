# XYZ_ImagesetChange
一个Mac工具，用来处理项目马甲包的.xcassets/.bundle
其实继续修改 还可以做很多事情

目前支持
1. 扫描出全项目中的.h/.m/.swift/.xib/.storeboard文件
2. 扫描出全项目中的 xxx.imageset 文件夹名称/路径
3. 修改所有 xxx.imageset 文件夹中的图片文件名, 使文件名等同于imageset的名称
4. 移动/反向移动 所有 xxx.imageset 文件夹中的图片文件 到一个指定的文件夹 （便于提供给美术 批量修改图片文件）
5. 扫描出全项目中所有硬编码的字符串（这种OC->@“xx” / swift->"xx"）
6. 修改大部分 xxx.imageset 文件夹名，同时修改代码中的硬编码（目前逻辑其实可以修改绝大部分 主要为了防止错误修改导致代码取图失败 **xib/storeboard文件未修改**）
7. 对png/jpeg图片添加0.03透明度的滤镜, 从而达到视觉效果基本不变的同时重新生成图片文件 (此条目的是为了替换 第4条中 需要美术重新批量修改图片 )
8. 修改指定目录下图片的hash (仅修改hash)

TODO:
1. 可以修改 .xib/.storeboard文件中的 图片名
