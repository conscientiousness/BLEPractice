//
//  DiscoveredPeripheral.h
//  BLEPractice
//
//  Created by Jesselin on 28/09/2016.
//  Copyright © 2016 JesseLin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface DiscoveredPeripheral : NSObject
// MARK: - Step 5
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, assign) NSInteger lastRSSI;
@property (nonatomic, strong) NSDate *lastSeenDateTime;
// ======== End Step 5
@end
