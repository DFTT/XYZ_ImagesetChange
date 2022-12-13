//
//  HashModify.m
//  imagesetChange
//
//  Created by zhazhenwang on 2021/8/5.
//

#import "HashModify.h"

@implementation HashModify

+ (void)modifyHashWithDirPath:(NSString *)dirPath {
    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"modify_hash" ofType:@"py"];
    NSString *cmd = [NSString stringWithFormat:@"python3 %@ %@", scriptPath, dirPath];
    system(cmd.UTF8String);
}

@end
