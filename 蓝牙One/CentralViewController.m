//
//  CentralViewController.m
//  蓝牙One
//
//  Created by qianfeng on 16/7/23.
//  Copyright © 2016年 qianfeng. All rights reserved.
//

#import "CentralViewController.h"
#import "SYHeader.h"
#import "SYTools.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface CentralViewController () <CBCentralManagerDelegate,CBPeripheralDelegate>
{
    CBCentralManager *_manager;
    
    UILabel *_label;
}

@property(nonatomic,strong) CBPeripheral *discoveredPeripheral;

@property(nonatomic,strong) NSMutableData *mutData;

@end

@implementation CentralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor cyanColor]];
    
    _label = [SYTools createLabel:CGRectMake(50, 100, 300, 25) tintColor:[UIColor blackColor] backgroundColor:[UIColor lightTextColor] numberOFLines:0 textAlignment:NSTextAlignmentLeft tintFont:12.0];
    [self.view addSubview:_label];
    
    //创建中央设备管理器
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    
    self.mutData = [NSMutableData data];
}

//判断蓝牙开关状态
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        
        [SYTools alertWithTitle:@"蓝牙反馈" message:@"蓝牙开关未开启" buttons:@[@"确定"] inController:self finish:nil cancel:nil];
        return;
    }
    
    [self scan];
}

//扫描外设
-(void)scan
{
    [_manager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVER_UUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
}

//peripheral为扫描到的外设
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    //最好信号强度为 -22左右
    if (RSSI.integerValue > -15) {
        return;
    }
    if (RSSI.integerValue < -35) {
        return;
    }
    
    NSLog(@"peripheral-->%@,identifier-->%@,advertisementData-->%@,RSSI-->%@",peripheral,peripheral.identifier,advertisementData,RSSI);
    
    //判断是新设备，则保存并且连接
    if (self.discoveredPeripheral != peripheral) {
        self.discoveredPeripheral = peripheral;
        
        NSLog(@"已经发现peripheral-->%@",peripheral);
        //开启连接
        [_manager connectPeripheral:peripheral options:nil];
    }
}

//连接失败时会走这个方法
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"连接失败%@,%@",error,error.localizedDescription);
    //清楚所有
    [self clearUp];
}

//连接成功时会走
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //停止扫描
    [_manager stopScan];
    
    //清空之前收到的数据
    [self.mutData setLength:0];
    
    peripheral.delegate = self;
    
    //搜索外设服务
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVER_UUID]]];
}

//扫描到服务后
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"扫描到服务后%@",error.localizedDescription);
        [self clearUp];
        return;
    }
    
    //扫描服务中与我们所匹配的特征
    for (CBService *server in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_UUID]] forService:server];
    }
}

//发现到特征后
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"发现到特征后%@",error.localizedDescription);
        [self clearUp];
        return;
    }
    
    //再次寻找我们需要的特征
    for (CBCharacteristic *character in service.characteristics) {
        if ([character.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]]) {
            //订阅这个特征
            [peripheral setNotifyValue:YES forCharacteristic:character];
        }
    }
}

//为特征添加通知（订阅）
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error){
        NSLog(@"特征添加通知%@",error.localizedDescription);
    }
    
    //判断是否是我们所匹配的特征
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]]) {
        return;
    }
    
    //开启通知
    if (characteristic.isNotifying) {
        NSLog(@"开启通知（订阅成功）%@",characteristic);
    }
    //通知停止
    else
    {
        NSLog(@"通知停止%@",characteristic);
        //断开连接
        [_manager cancelPeripheralConnection:peripheral];
    }
}

//接受数据
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"接受数据%@",error.localizedDescription);
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    //是否是结束标志
    if ([stringFromData isEqualToString:END_SYMBOL]) {
        //显示所有数据
        _label.text = [[NSString alloc] initWithData:self.mutData encoding:NSUTF8StringEncoding];
        [self.mutData setLength:0];
        
        //取消订阅
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        //断开连接
        [_manager cancelPeripheralConnection:peripheral];
    }
    else
    {
        //没有接受完所有数据
        [self.mutData appendData:characteristic.value];
    }
}

//断开连接后会走
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"已经断开连接");
}

//清空连接
-(void)clearUp
{
    //没有连接，不用往下执行
    if (self.discoveredPeripheral.state != CBPeripheralStateConnected) {
        return;
    }
    
    /**
     外设包含服务，服务包含特征，（匹配我们设置的特征）特征包含数据等属性
     特征是与外界交互的最小单位
     */
    //判断外设是否有服务
    if (self.discoveredPeripheral.services != nil) {
        for (CBService *server in self.discoveredPeripheral.services) {
            //判断服务中是否包含特征
            if (server.characteristics != nil) {
                for (CBCharacteristic *character in server.characteristics) {
                    //判断特征是否是我们所匹配的特征
                    if ([character.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]]) {
                        //如果特征在通知(是否订阅)
                        if (character.isNotifying) {
                            //取消订阅
                            [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:character];
                            
                            return;
                        }
                    }
                }
            }
        }
    }
    
    //断开连接
    [_manager cancelPeripheralConnection:self.discoveredPeripheral];
}





@end
