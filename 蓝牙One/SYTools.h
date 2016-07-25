//
//  SYTools.h
//  蓝牙One
//
//  Created by qianfeng on 16/7/23.
//  Copyright © 2016年 qianfeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^myBlock)();

@interface SYTools : NSObject

+(UIButton *)createButton:(NSString *)title type:(UIButtonType)type frame:(CGRect)frame titleColor:(UIColor*)titleColor hightTitleColor:(UIColor *)hightColor backgroundColor:(UIColor *)color target:(id)target action:(SEL)action tintFont:(CGFloat)font;

+(UILabel *)createLabel:(CGRect)frame tintColor:(UIColor *)color backgroundColor:(UIColor *)groundColor numberOFLines:(NSInteger)lines textAlignment:(NSTextAlignment)textAlignment tintFont:(CGFloat)font;

+(void)alertWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttonTitles inController:(UIViewController *)controller finish:(myBlock)finish cancel:(myBlock)cancel;

@end
