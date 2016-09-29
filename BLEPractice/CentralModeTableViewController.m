//
//  CentralModeTableViewController.m
//  BLEPractice
//
//  Created by Jesselin on 28/09/2016.
//  Copyright © 2016 JesseLin. All rights reserved.
//

#import "CentralModeTableViewController.h"
#import "DiscoveredPeripheral.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "TalkingViewController.h"

float const kTableViewReloadMaxTimeInterval = 1.0;
NSString * const kTargetService = @"1A2B";
NSString * const kTargetCharacteristic = @"3C4D";

@interface CentralModeTableViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    CBCentralManager *centerManger;
    NSMutableDictionary *allDiscovered;
    NSDate *lastTableViewReloadTime;
    NSMutableString *detailInfoString;
    NSMutableArray *restServices;
    
    BOOL shouldStartTalking;
    CBPeripheral *talkingPeripheral;
    CBCharacteristic *talkingCharacteristic;
}
@end

@implementation CentralModeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // MARK: - Step 1
    centerManger = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    allDiscovered = [NSMutableDictionary new];
    restServices = [NSMutableArray new];
    // End Step 1
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // MARK: - Step 18
    if(shouldStartTalking) {
        shouldStartTalking = NO;
        
        [centerManger cancelPeripheralConnection:talkingPeripheral];
        talkingPeripheral = nil;
        talkingCharacteristic = nil;
        
        [self startToScan];
    }
    // End Step 17
}

- (IBAction)switchValueChanged:(id)sender {
    
    // MARK: - Step 3
    if([sender isOn]) {
        [self startToScan];
    } else {
        [self stopScanning];
    }
    // End Step 3
}

- (void) startToScan {
    
    // MARK: - Step 4
    // 指定特定Service UUID, 沒有也可傳nil
    NSArray *servies = @[];
    
    // Scan時, 是否允許相同UUID裝置同時出現
    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    [centerManger scanForPeripheralsWithServices:servies options:options];
    // End Step 4
}

- (void) stopScanning {
    [centerManger stopScan];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    // MARK: - Step 2
    CBManagerState state = central.state;
    
    if (state != CBManagerStatePoweredOn) {
        NSString *message = [NSString stringWithFormat:@"BLE is not available.(error: %ld)",(long)state];
        NSLog(@"%@",message);
    }
    // End Step 2
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    // MARK: - Step 6
    NSString *uuid = peripheral.identifier.UUIDString;
    BOOL isExist = allDiscovered[uuid] != nil;
    
    if(isExist == NO) {
        NSLog(@"Found: %@(%@), RSSI: %ld",peripheral.identifier,peripheral.name, (long)[RSSI integerValue]);
    }
    
    DiscoveredPeripheral *item = [DiscoveredPeripheral new];
    item.peripheral = peripheral;
    item.lastRSSI = [RSSI integerValue];
    item.lastSeenDateTime = [NSDate date];
    [allDiscovered setObject:item forKey:uuid];
    
    // 降低UI更新頻率, 每秒更新一次, 避免CPU負載過高
    NSDate *now = [NSDate date];
    if(isExist == NO || [now timeIntervalSinceDate:lastTableViewReloadTime] > kTableViewReloadMaxTimeInterval) {
        lastTableViewReloadTime = now;
        [self.tableView reloadData];
    }
    // End Step 6
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    // MARK: - Step 9
    NSLog(@"Peripheral Connect: %@",peripheral.name);
    
    [self stopScanning];
    
    peripheral.delegate = self;
    [restServices removeAllObjects];
    
    // MARK: - Step 14
    if(shouldStartTalking == NO) { // accessoryButtonTapped
        // 如連線成功discoverServices觸發didDiscoverServices
        [peripheral discoverServices:nil];
    } else {
        CBUUID *targetService = [CBUUID UUIDWithString:kTargetService];
        [peripheral discoverServices:@[targetService]];
    }
    // End Step 14
    
    //[peripheral discoverServices:nil];
    // End Step 9
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    
    NSLog(@"Fail to Connect Peripheral: %@",error.description);
    shouldStartTalking = NO;
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error {
    
    // MARK: - Step 10
    NSLog(@"Disconnected: %@",peripheral.name);
    [self startToScan];
    // End Step 10
    shouldStartTalking = NO;
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    
    // MARK: - Step 11
    if(error) {
        NSLog(@"didDiscoverServices error: %@",error.description);
        [centerManger cancelPeripheralConnection:peripheral];
        [self startToScan];
        shouldStartTalking = NO;
        return;
    }
    
    NSLog(@"===didDiscoverServices===");
    
    NSArray *allServices = peripheral.services;
    [restServices addObjectsFromArray:allServices];
    
    // MARK: - Step 15
    if(shouldStartTalking == NO) {
        [peripheral discoverCharacteristics:nil forService:[restServices firstObject]];
    } else if (restServices.count > 0) {
        CBUUID *targetCharacteristics = [CBUUID UUIDWithString:kTargetCharacteristic];
        
        [peripheral discoverCharacteristics:@[targetCharacteristics] forService:[restServices firstObject]];
    } else {
        [centerManger cancelPeripheralConnection:peripheral];
        [self startToScan];
        shouldStartTalking = NO;
    }
    // End Step 15
    
    // Pick the first one to discover characteristic
    // discoverCharacteristics 觸發 didDiscoverCharacteristicsForService
    //[peripheral discoverCharacteristics:nil forService:[resetServices firstObject]];
    if (restServices.count > 0) [restServices removeObjectAtIndex:0];
    // End Step 11
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    
    // MARK: - Step 12
    if(error) {
        NSLog(@"didDiscoverCharacteristics error: %@",error.description);
        [centerManger cancelPeripheralConnection:peripheral];
        [self startToScan];
        return;
    }
    
    NSLog(@"===didDiscoverCharacteristics===");
    
    // MARK: - Step 16
    if(shouldStartTalking) {
        talkingPeripheral = peripheral;
        talkingCharacteristic = service.characteristics[0];
        
        [self performSegueWithIdentifier:@"startTalking" sender:nil];
        return;
    }
    // End Step 16
    
    [detailInfoString appendFormat:@"*** Peripheral: %@ (%ld services)\n",peripheral.name,peripheral.services.count];
    [detailInfoString appendFormat:@"** Service: %@ (%ld characteristic)\n",service.UUID.UUIDString,service.characteristics.count];
    
    for(CBCharacteristic *cbc in service.characteristics) {
        [detailInfoString appendFormat:@"* Characteristic: %@\n",cbc.UUID.UUIDString];
    }
    
    if(restServices.count == 0) {
        // show result
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Result" message:detailInfoString preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [centerManger cancelPeripheralConnection:peripheral];
            [self startToScan];
            detailInfoString = nil;
        }];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        
    } else {
        [detailInfoString appendString:@"\n"];
        [peripheral discoverCharacteristics:nil forService:[restServices firstObject]];
        [restServices removeObjectAtIndex:0];
    }
    // End Step 12
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return allDiscovered.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // MARK: - Step 7
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    NSArray *allKeys = allDiscovered.allKeys;
    DiscoveredPeripheral *target = allDiscovered[allKeys[indexPath.row]];
    
    NSString *desc = [NSString stringWithFormat:@"%@, RSSI: %ld",target.peripheral.name, target.lastRSSI];
    NSString *timeAgo = [NSString stringWithFormat:@"Last seen: %1.f seconds ago",[[NSDate date] timeIntervalSinceDate:target.lastSeenDateTime]];
    
    cell.textLabel.text = desc;
    cell.detailTextLabel.text = timeAgo;
    
    return cell;
    // End Step 7
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    shouldStartTalking = NO;
    // MARK: - Step 8
    [self connectWithIndexPath:indexPath];
    // End Step 8
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    // MARK: - Step 13
    shouldStartTalking = YES;
    [self connectWithIndexPath:indexPath];
    // End Step 13
}

- (void) connectWithIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *allkeys = allDiscovered.allKeys;
    DiscoveredPeripheral *target = allDiscovered[allkeys[indexPath.row]];
    [centerManger connectPeripheral:target.peripheral options:nil];
    detailInfoString = [NSMutableString new];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    // MARK: - Step 17
    TalkingViewController *vc = segue.destinationViewController;
    vc.talkingPeripheral = talkingPeripheral;
    vc.talkingCharacteristic = talkingCharacteristic;
    // End Step 17
}


@end
