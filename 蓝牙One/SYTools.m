//
//  SYTools.m
//  蓝牙One
//
//  Created by qianfeng on 16/7/23.
//  Copyright © 2016年 qianfeng. All rights reserved.
//

#import "SYTools.h"

@implementation SYTools

+(UIButton *)createButton:(NSString *)title type:(UIButtonType)type frame:(CGRect)frame titleColor:(UIColor*)titleColor hightTitleColor:(UIColor *)hightColor backgroundColor:(UIColor *)color target:(id)target action:(SEL)action tintFont:(CGFloat)font
{
    UIButton *button = [UIButton buttonWithType:type];
    button.frame = frame;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    [button setTitleColor:hightColor forState:UIControlStateHighlighted];
    [button setBackgroundColor:color];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.font = [UIFont systemFontOfSize:font];
    
    return button;
}

+(UILabel *)createLabel:(CGRect)frame tintColor:(UIColor *)color backgroundColor:(UIColor *)groundColor numberOFLines:(NSInteger)lines textAlignment:(NSTextAlignment)textAlignment tintFont:(CGFloat)font
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.tintColor = color;
    label.backgroundColor = groundColor;
    label.numberOfLines = lines;
    label.textAlignment = textAlignment;
    label.font = [UIFont systemFontOfSize:font];
    
    return label;
}

+(void)alertWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttonTitles inController:(UIViewController *)controller finish:(myBlock)finish cancel:(myBlock)cancel
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    int index = 0;
    
    for (NSString *title in buttonTitles) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
           
            if (index == 0) {
                if (finish) {
                    finish();
                }
            }
            else if (index == 1)
            {
                if (cancel) {
                    cancel();
                }
            }
        }];
        [alertController addAction:action];
        index++;
    }
    [controller presentViewController:alertController animated:YES completion:nil];
}

@end
