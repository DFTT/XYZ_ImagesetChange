//
//  HashModify.h
//  imagesetChange
//
//  Created by zhazhenwang on 2021/8/5.
//

#import <Foundation/Foundation.h>

@interface HashModify : NSObject

// 修改资源文件的md5
+ (void)modifyHashWithDirPath:(NSString *)dirPath;

// 修改资源文件的XMP元数据 (要求电脑安装工具:exiftool  https://exiftool.org/)
+ (void)modifyFileXMPWithDirPath:(NSString *)dirPath;

@end
