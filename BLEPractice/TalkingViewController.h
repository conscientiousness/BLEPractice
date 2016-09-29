//
//  FirstViewController.h
//  BLEPractice
//
//  Created by Jesselin on 28/09/2016.
//  Copyright © 2016 JesseLin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface TalkingViewController : UIViewController

@property (nonatomic, strong) CBPeripheral *talkingPeripheral;
@property (nonatomic, strong) CBCharacteristic *talkingCharacteristic;

@end

