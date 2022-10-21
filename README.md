# XYZ_ImagesetChange

一个Mac工具，用来处理项目马甲包的.xcassets/.bundle

继续迭代 还可以做很多事情

### 目前支持:
1. 修改所有```xxx.imageset```文件夹中的图片文件名, 使文件名和imageset名称相同
2. 移动/反向移动 所有 xxx.imageset 文件夹中的图片文件 到一个指定的文件夹 （便于提供给美术 批量修改图片文件）
3. 批量修改```xxx.imageset```名，同时修改代码中取图片的硬编码（为了防止错误修改导致代码取图失败, 名称中包含数字的未修改）
4. 对Bundle/imageset中的png/jpeg图片添加0.03透明度(可配置)的滤镜 并 重新生成图片 (只会混色非透明通道区域, 确保了有透明区域的图片)
5. 修改其他类型资源文件的hash (仅修改hash, ['webp', 'svga', 'mp3', 'png', 'jpg'])
