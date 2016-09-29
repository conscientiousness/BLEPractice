//
//  FirstViewController.m
//  BLEPractice
//
//  Created by Jesselin on 28/09/2016.
//  Copyright © 2016 JesseLin. All rights reserved.
//

#import "TalkingViewController.h"

@interface TalkingViewController () <UITextFieldDelegate, UITextViewDelegate,CBPeripheralDelegate>
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@end

@implementation TalkingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // MARK: - Step 19
    _talkingPeripheral.delegate = self;
    // 開啟Characteristic的NotifyValue, Central將可以收到通知, 觸發didUpdateValueForDescriptor
    [_talkingPeripheral setNotifyValue:YES forCharacteristic:_talkingCharacteristic];
    // End Step 19
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
    // MARK: - Step 20
    NSString *content = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"Receive from Peripheral: %@",content);
    
    if(content.length>0)
    {
        _logTextView.text = [NSString stringWithFormat:@"%@%@",content,_logTextView.text];
    }
    // End Step 20
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    // MARK: - Step 22
    if(error != nil) {
        NSLog(@"didWriteValueForCharacteristic error: %@",error.description);
    }
    // End Step 22
}

#pragma mark - UITextViewDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    
    // MARK: - Step 21
    [textField resignFirstResponder];
    
    if(textField.text.length > 0) {
        NSString *context = [NSString stringWithFormat:@"[%@] %@\n",[[UIDevice currentDevice] model],textField.text];
        NSData *data = [context dataUsingEncoding:NSUTF8StringEncoding];
        
        [_talkingPeripheral writeValue:data forCharacteristic:_talkingCharacteristic type:CBCharacteristicWriteWithResponse];
    }
    return NO;
    // End Step 21
}

@end
