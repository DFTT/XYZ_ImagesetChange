//
//  Test_oc_hardString.m
//  imagesetChange
//
//  Created by 大大东 on 2021/8/5.
//

#import "Test_oc_hardString.h"

@implementation Test_oc_hardString
- (void)test__ {
    @"正常的";
    @"'单引号'";
    @"\"双引号\"";
    @"@\"@双引号\"";
    @"包含数字的111";
    @"包含数字在中间222的";
    @"包含格式化的_%d";
    @"\
    多行汉字的\
    多行汉字的";
    @"\
    多行汉字有引号的\"\
    多行汉字的";
}
@end
