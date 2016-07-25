//
//  PeripheralViewController.m
//  蓝牙One
//
//  Created by qianfeng on 16/7/23.
//  Copyright © 2016年 qianfeng. All rights reserved.
//

#import "PeripheralViewController.h"
#import "SYTools.h"
#import "SYHeader.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface PeripheralViewController () <CBPeripheralManagerDelegate>
{
    BOOL _isFinish;
    unsigned long _sendBytes;
}

@property(nonatomic,strong) CBPeripheralManager *peripheralManager;
@property(nonatomic,strong) CBMutableCharacteristic *transferCharacteristic;
@property(nonatomic,strong) UITextField *textView;
@property(nonatomic,strong) NSData *dataToSend;

@end

@implementation PeripheralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.textView = [[UITextField alloc] initWithFrame:CGRectMake(50, 100, 270, 50)];
    self.textView.placeholder = @"需要发送的信息";
    [self.view addSubview:self.textView];
    
    UIButton *button = [SYTools createButton:@"发送" type:UIButtonTypeCustom frame:CGRectMake(50, 200, 50, 50) titleColor:[UIColor grayColor] hightTitleColor:[UIColor redColor] backgroundColor:[UIColor lightGrayColor] target:self action:@selector(sendData) tintFont:15.0];
    [self.view addSubview:button];
    
    //创建周边设备管理器
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

//判断蓝牙的开启状态
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        [SYTools alertWithTitle:@"蓝牙反馈" message:@"蓝牙没有打开" buttons:@[@"确定"] inController:self finish:nil cancel:nil];
        return;
    }
    
    //创建特征
    CBUUID *cUUID = [CBUUID UUIDWithString:CHARACTERISTIC_UUID];
    self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:cUUID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    //创建服务
    CBUUID *sUUID = [CBUUID UUIDWithString:SERVER_UUID];
    CBMutableService *transferServer = [[CBMutableService alloc] initWithType:sUUID primary:YES];
    
    //将特征添加到服务中
    transferServer.characteristics = @[self.transferCharacteristic];
    
    //把服务添加到周边管理器中
    [self.peripheralManager addService:transferServer];
    
    //发送广播，广播一个指定的服务
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[[CBUUID UUIDWithString:SERVER_UUID]]}];
}

//当订阅成功时，则发送数据
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"已经订阅");
}

//结束订阅是调用
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"已经结束订阅，断开连接");
}

-(void)sendData
{
    if (_isFinish) {
        //发送结束标记
        BOOL didSend = [self.peripheralManager updateValue:[END_SYMBOL dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        if (didSend) {
            _isFinish = NO;
            //发送标记至0
            _sendBytes = 0;
            NSLog(@"发送完成");
        }
        //没有成功发送结束标记，则返回并等待
        return;
    }
    
    //不发送结束标记，就发送数据
    //发送文字
    self.dataToSend = [self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
    
    //发送图片
    //self.dataToSend = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"" ofType:@""]];
    
    if (_sendBytes >= self.dataToSend.length) {
        //没有数据则返回
        return;
    }
    
    //如果还有数据，就一直发送，直到失败为止
    BOOL didSend = YES;
    while (didSend) {
        
        NSInteger amountToSend = self.dataToSend.length - _sendBytes;
        //每次传输的字节数为20字节
        if (amountToSend > MAX_BYTES) {
            amountToSend = MAX_BYTES;
        }
        
        //复制我们想要的数据
        NSData *chunkData = [NSData dataWithBytes:self.dataToSend.bytes + _sendBytes length:amountToSend];
        //发送数据
        didSend = [self.peripheralManager updateValue:chunkData forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        //发送失败。返回
        if (!didSend) {
            return;
        }
        else
        {
            //更新已发送长度
            _sendBytes += amountToSend;
            //判断是否发送结束
            if (_sendBytes >= self.dataToSend.length) {
                _isFinish = YES;
                [self performSelector:@selector(sendData) withObject:nil afterDelay:0.1];
            }
        }
    }
    //退出编辑
    [self.view endEditing:YES];
}

/**
 *当周边设备准备好发送下次数据的时候就被调用
 *可以确保数据传递的及时性
 *队列满时也可以调用
 **/
-(void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    //发送数据
    [self sendData];
}


















@end
