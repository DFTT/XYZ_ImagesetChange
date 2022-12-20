//
//  XYZUIImageUtil.m
//  imagesetChange
//
//  Created by 大大东 on 2022/12/20.
//

#import "XYZUIImageUtil.h"

#import <objc/runtime.h>

// md5/sha1 加密
#import <CommonCrypto/CommonDigest.h>
static NSString * k_MD5_32(NSString *originString) {
    
    const char* str = [originString UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];//
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}


@interface XYZUIImageUtil ()
@property (nonatomic, strong) NSCache *imgResCache; // name : UIImage
@property (nonatomic, readonly, strong) NSBundle *bundleOfXCImageSet; // 存储 转换成bin的xcimageSet中的图片
@property (nonatomic, readonly, strong) NSBundle *bundleOfMain; // 存储main bundle 中的图片
@end

@implementation XYZUIImageUtil

@synthesize bundleOfXCImageSet = _bundleOfXCImageSet, bundleOfMain = _bundleOfMain;


+ (instancetype)sharedInstance {
    static XYZUIImageUtil *util = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        util = [[XYZUIImageUtil alloc] init];
        util.imgResCache = [[NSCache alloc] init];
        util.imgResCache.totalCostLimit = 30 * 1024 * 1024;
    });
    return util;
}

- (NSBundle *)bundleOfMain {
    if (!_bundleOfMain) {
        NSString *path = [[NSBundle bundleForClass:XYZUIImageUtil.class] pathForResource:@"TTTMainRes" ofType:@"bundle"];
        _bundleOfMain = [NSBundle bundleWithPath:path];
    }
    return  _bundleOfMain;
}
- (NSBundle *)bundleOfXCImageSet {
    if (!_bundleOfXCImageSet) {
        NSString *path = [[NSBundle bundleForClass:XYZUIImageUtil.class] pathForResource:@"TTTSetRes" ofType:@"bundle"];
        _bundleOfXCImageSet = [NSBundle bundleWithPath:path];
    }
    return  _bundleOfXCImageSet;
}
@end


#if TARGET_OS_IPHONE

@implementation UIImage (XXMM)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(imageNamed:);
        SEL swizzledSelector = @selector(xxmm_imageNamed:);
        
        Class aClass = NSClassFromString(@"UIImage");
        Method originalMethod = class_getClassMethod(aClass, originalSelector);
        Method swizzledMethod = class_getClassMethod(aClass, swizzledSelector);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

+ (UIImage *)xxmm_imageNamed:(NSString *)name {
    if (name == nil || name.length == 0) {return nil;}
    UIImage *image = [self xxmm_imageNamed:name];
    if (image != nil) {
        return image;
    }
    
    // 缓存
    image = [[XYZUIImageUtil sharedInstance].imgResCache objectForKey:name];
    if (image != nil) {
        return image;
    }
    
    static NSArray<NSString *> *prefixArr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([UIScreen mainScreen].scale == 3) {
            prefixArr = @[@"3x", @"2x", @"1x", @""];
        }else {
            prefixArr = @[@"2x", @"3x", @"1x", @""];
        }
    });
    
    // 读取 解密
    NSString *enpytName = k_MD5_32(name);
    NSInteger cost = 0;
    for (NSString *pre in prefixArr) {
        @autoreleasepool {
            NSString *newName = [pre stringByAppendingString:enpytName];
            NSString *path = [[XYZUIImageUtil sharedInstance].bundleOfXCImageSet pathForResource:newName ofType:@""];
            if (path) {
                NSData *data = [[NSData alloc] initWithBase64EncodedData:[NSData dataWithContentsOfFile:path] options:0];
                image = [UIImage imageWithData:data];
                cost = data.length;
                break;
            }
        }
    }
    // 缓存
    if (image != nil) {
        [[XYZUIImageUtil sharedInstance].imgResCache setObject:image forKey:name cost:cost];
    }
    
#if DEBUG
    [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"确实图片资源：%@", name] message:nil delegate:nil cancelButtonTitle:@"反馈给RD" otherButtonTitles: nil] show];
#endif
    
    return nil;
}

@end

#endif
