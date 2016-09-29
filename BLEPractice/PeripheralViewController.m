//
//  SecondViewController.m
//  BLEPractice
//
//  Created by Jesselin on 28/09/2016.
//  Copyright © 2016 JesseLin. All rights reserved.
//

#import "PeripheralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

NSString * const kServiceUUID = @"9999";
NSString * const kCharacteristicUUID = @"AAAA";
NSString * const kPeripheralName = @"Happy Chat Room";

@interface PeripheralViewController ()<CBPeripheralManagerDelegate, UITextFieldDelegate>
{
    CBPeripheralManager *peripheralManager;
    CBMutableCharacteristic *chatCharacteristic;
}
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet UITextField *inputTextfield;
@end

@implementation PeripheralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // MARK: - Step 23
    peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    // End Step 23
}

- (IBAction)switchValueChanged:(id)sender {
    
     // MARK: - Step 24
    if([sender isOn]) {
        CBUUID *uuid = [CBUUID UUIDWithString:kServiceUUID];
        NSArray *uuids = @[uuid];
        
        // CBAdvertisementDataServiceDataKey的value必須要用array
        NSDictionary *info = @{CBAdvertisementDataServiceDataKey: uuids,
                               CBAdvertisementDataLocalNameKey: kPeripheralName};
        [peripheralManager startAdvertising:info];
        
    } else {
        [peripheralManager stopAdvertising];
    }
    // End Step 24
}

- (void)sendText:(NSString *)text central:(CBCentral *)central {
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    
    // MARK: - Step 27
    if(central == nil) {
        [peripheralManager updateValue:data forCharacteristic:chatCharacteristic onSubscribedCentrals:nil];
    } else {
        [peripheralManager updateValue:data forCharacteristic:chatCharacteristic onSubscribedCentrals:@[central]];
    }
    // End Step 27
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    // MARK: - Step 28
    [textField resignFirstResponder];
    
    if(textField.text.length > 0) {
        NSString *content = [NSString stringWithFormat:@"[%@] %@\n",kPeripheralName,textField.text];
        [self sendText:content central:nil];
        
        _logTextView.text = [NSString stringWithFormat:@"%@%@",content,_logTextView.text];
    }
    
    return NO;
    // end Stwp 28
}

#pragma mark - CBPeripheralDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    // MARK: - Step 25
    CBManagerState state = peripheral.state;
    
    if(state != CBManagerStatePoweredOn) {
        NSLog(@"peripheralManagerDidUpdateState error = %ld",state);
    } else {
        CBUUID *uuidService = [CBUUID UUIDWithString:kServiceUUID];
        CBUUID *uuidCharacteristic = [CBUUID UUIDWithString:kCharacteristicUUID];
        
        CBCharacteristicProperties porperties = CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify;
        CBAttributePermissions permissions = CBAttributePermissionsReadable | CBAttributePermissionsWriteable;
        
        chatCharacteristic = [[CBMutableCharacteristic alloc] initWithType:uuidCharacteristic properties:porperties value:nil permissions:permissions];
        
        CBMutableService *chatService = [[CBMutableService alloc] initWithType:uuidService primary:YES];
        chatService.characteristics = @[chatCharacteristic];
        
        [peripheralManager addService:chatService];
    }
    // End Step 25
}

// 當Central notify該Characteristic, 此方法會觸發, 這裡設計, 當有central連入, 發送歡迎訊息
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    
    // MARK: - Step 26
    NSString *hello = [NSString stringWithFormat:@"[%@] Welcome ! Here is %@, (Total:%ld, Max Length:%ld)",kPeripheralName,kPeripheralName,chatCharacteristic.subscribedCentrals.count,central.maximumUpdateValueLength];
    
    [self sendText:hello central:central];
    
    _logTextView.text = [NSString stringWithFormat:@"%@%@",hello,_logTextView.text];
    // End Step 26
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(nonnull CBCharacteristic *)characteristic {
    
}

// [_talkingPeripheral writeValue:data forCharacteristic:_talkingCharacteristic type:CBCharacteristicWriteWithResponse];
- (void) peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(nonnull NSArray<CBATTRequest *> *)requests {
    
    // MARK: - Step 29
    for(CBATTRequest *tmp in requests) {
        
        // Tell Central it is received.
        [peripheralManager respondToRequest:tmp withResult:CBATTErrorSuccess];
        
        // Show on UI and forward to all Centrals
        NSString *content = [[NSString alloc] initWithData:tmp.value encoding:NSUTF8StringEncoding];
        
        if(content != nil) {
            
            // 發給其他user
            [self sendText:content central:nil];
            _logTextView.text = [NSString stringWithFormat:@"%@%@",content,_logTextView];
        }
    }
    // End Step 29
}
@end
