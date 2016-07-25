//
//  HomeViewController.m
//  蓝牙One
//
//  Created by qianfeng on 16/7/23.
//  Copyright © 2016年 qianfeng. All rights reserved.
//

#import "HomeViewController.h"
#import "SYTools.h"
#import "CentralViewController.h"
#import "PeripheralViewController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSArray *titles = @[@"中央扫描",@"发起连接"];
    
    for (int i = 0; i < 2; i++) {
        UIButton *button = [SYTools createButton:titles[i] type:UIButtonTypeCustom frame:CGRectMake(100, 100 + 50*i, 200, 40) titleColor:[UIColor whiteColor] hightTitleColor:[UIColor redColor]backgroundColor:[UIColor lightGrayColor] target:self action:@selector(click:) tintFont:15.0];
        button.tag = 100 + i;
        [self.view addSubview:button];
    }
}

-(void)click:(UIButton *)btn
{
    if (btn.tag == 100) {
        CentralViewController *vc = [[CentralViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else
    {
        PeripheralViewController *vc = [[PeripheralViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
