/*
 * Copyright Red Hat, Inc., and individual contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <CommonCrypto/CommonDigest.h>

#import "../FeedHenry-Sw.h"
#import "FHSyncClient.h"
#import "FHSyncUtils.h"
#import "FHSyncPendingDataRecord.h"
#import "FHSyncDataRecord.h"
#import "FHSyncDataset.h"
#import "FHDefines.h"

@implementation FHSyncClient {
    NSMutableDictionary *_dataSets;
    FHSyncConfig *_syncConfig;
    BOOL _initialized;
    FHSyncDataset* _dataSetInjected;
}

/*
 Unit test DI constructor.
 */
- (instancetype)initWithConfig:(FHSyncConfig *)config AndDataSet:(FHSyncDataset*)dataSet {
    self = [super init];
    if (self) {
        _syncConfig = config;
        _dataSets = [NSMutableDictionary dictionary];
        _dataSetInjected = dataSet;
        _initialized = YES;
        [self datasetMonitor:nil];
    }

    return self;
}

- (instancetype)initWithConfig:(FHSyncConfig *)config {
    self = [super init];
    if (self) {
        _syncConfig = config;
        _dataSets = [NSMutableDictionary dictionary];
        _initialized = YES;
        [self datasetMonitor:nil];
    }
    
    return self;
}

+ (FHSyncClient *)getInstance {
    static FHSyncClient *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[FHSyncClient alloc] init];
    });

    return _shared;
}

- (void)doManage:(NSString *)dataId
       AndConfig:(FHSyncConfig *)config
        AndQuery:(NSDictionary *)queryParams
     AndMetaData:(NSMutableDictionary *)metaData {
    if (!_initialized) {
        [NSException
         raise:@"FHSyncClient isn't initialized"
         format:@"FHSyncClient hasn't been initialized. Have you " @"called the init function?"];
    }
    
    // first, check if the dataset for dataId is already loaded
    FHSyncDataset *dataSet = _dataSets[dataId];
    // allow to set sync config options for each dataset
    FHSyncConfig *dataSyncConfig = _syncConfig;
    if (nil != config) {
        dataSyncConfig = config;
    }
    if (nil == dataSet) {
        // not loaded yet, try to read it from a local file
        NSError *error = nil;
        if (_dataSetInjected == nil) {
            dataSet = [[FHSyncDataset alloc] initFromFileWithDataId:dataId error:error];
            if (nil == error) {
                // data loaded successfully
                [FHSyncUtils doNotifyWithDataId:dataId
                                         config:dataSyncConfig
                                            uid:NULL
                                           code:LOCAL_UPDATE_APPLIED_MESSAGE
                                        message:@"load"];
            } else {
                // cat not load data, create a new map for it
                dataSet = [[FHSyncDataset alloc] initWithDataId:dataId];
            }
        } else {
            dataSet = _dataSetInjected;
        }

        _dataSets[dataId] = dataSet;
    }
    
    dataSet.syncConfig = dataSyncConfig;
    
    // if the dataset is not initialised yet, do the init
    dataSet.queryParams = queryParams;
    dataSet.syncRunning = NO;
    dataSet.syncLoopPending = YES;
    dataSet.stopSync = NO;
    // custom metadata are used to select a subset of data set
    dataSet.customMetaData = metaData;
    
    dataSet.initialised = YES;
    
    NSError *saveError = nil;
    [dataSet saveToFile:saveError];
    if (saveError) {
        DLog(@"Failed to save dataset with dataId %@", dataId);
    }
}

- (void)datasetMonitor:(NSDictionary *)info {
    DLog(@"start to run checkDatasets");
    [self checkDatasets];
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(datasetMonitor:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)checkDatasets {
    if (nil != _dataSets) {
        [_dataSets enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            @autoreleasepool {
                FHSyncDataset *dataset = (FHSyncDataset *)obj;
                BOOL syncRunning = dataset.syncRunning;
                if (!syncRunning && !dataset.stopSync) {
                    // sync isn't running for dataId at the moment, check if
                    // needs to start it
                    NSDate *lastSyncStart = dataset.syncLoopStart;
                    NSDate *lastSyncCmp = dataset.syncLoopEnd;
                    if (nil == lastSyncStart) {
                        // sync never started
                        dataset.syncLoopPending = YES;
                    } else if (nil != lastSyncCmp) {
                        // otherwise check how long since the last sync has
                        // finished
                        NSTimeInterval timeSinceLastSync =
                        [[NSDate date] timeIntervalSinceDate:lastSyncCmp];
                        FHSyncConfig *dataSyncConfig = dataset.syncConfig;
                        if (timeSinceLastSync > dataSyncConfig.syncFrequency) {
                            dataset.syncLoopPending = YES;
                        }
                    }
                    if (dataset.syncLoopPending) {
                        DLog(@"start to run syncLoopWithDataId %@", key);
                        [dataset startSyncLoop];
                    }
                }
            }
        }];
    }
}

- (void)manageWithDataId:(NSString *)dataId
               AndConfig:(FHSyncConfig *)config
                AndQuery:(NSDictionary *)queryParams {
    [self doManage:dataId AndConfig:config AndQuery:queryParams AndMetaData:nil];
}

- (void)manageWithDataId:(NSString *)dataId AndConfig:(FHSyncConfig *)config AndQuery:(NSDictionary *)queryParams AndMetaData:(NSMutableDictionary *)metaData {
    [self doManage:dataId AndConfig:config AndQuery:queryParams AndMetaData:metaData];
}

- (void)stopWithDataId:(NSString *)dataId {
    FHSyncDataset *dataset = (_dataSets)[dataId];
    if (dataset) {
        dataset.stopSync = YES;
    }
}

- (void)destroy {
    if (_initialized) {
        [_dataSets enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            FHSyncDataset *dataset = (FHSyncDataset *)obj;
            dataset.stopSync = YES;
        }];
        _dataSets = nil;
        _syncConfig = nil;
        _initialized = NO;
    }
}

- (NSDictionary *)listWithDataId:(NSString *)dataId {
    FHSyncDataset *dataSet = _dataSets[dataId];
    if (dataSet) {
        return [dataSet listData];
    }

    return nil;
}

- (NSDictionary *)readWithDataId:(NSString *)dataId AndUID:(NSString *)uid {
    FHSyncDataset *dataSet = _dataSets[dataId];
    if (dataSet) {
        return [dataSet readDataWithUID:uid];
    }

    return nil;
}

- (NSDictionary *)createWithDataId:(NSString *)dataId AndData:(NSDictionary *)data {
    FHSyncDataset *dataSet = _dataSets[dataId];
    if (dataSet) {
        return [dataSet createWithData:data];
    }

    return nil;
}

- (NSDictionary *)updateWithDataId:(NSString *)dataId
                            AndUID:(NSString *)uid
                           AndData:(NSDictionary *)data {
    FHSyncDataset *dataSet = _dataSets[dataId];
    if (dataSet) {
        return [dataSet updateWithUID:uid data:data];
    }

    return nil;
}

- (NSDictionary *)deleteWithDataId:(NSString *)dataId AndUID:(NSString *)uid {
    FHSyncDataset *dataSet = _dataSets[dataId];
    if (dataSet) {
        return [dataSet deleteWithUID:uid];
    }

    return nil;
}

- (void)listCollisionWithCallbacksForDataId:(NSString *)dataId
                                 AndSuccess:(void (^)(FHResponse *success))sucornil
                                 AndFailure:(void (^)(FHResponse *failed))failornil {
    NSString *path = [NSString stringWithFormat:@"/mbaas/sync/%@", dataId];
    NSDictionary* params = @{ @"fn" : @"listCollisions"};
    [FH performCloudRequest:path method:@"POST" headers:nil args:params completionHandler:^(FHResponse* response, NSError* error) {
        if (error != nil) { // response contains error
            failornil(response);
            return;
        }
        sucornil(response);
    }];
}

- (void)removeCollisionWithCallbacksForDataId:(NSString *)dataId
                                         hash:(NSString *)collisionHash
                                   AndSuccess:(void (^)(FHResponse *success))sucornil
                                   AndFailure:(void (^)(FHResponse *failed))failornil {
    NSString *path = [NSString stringWithFormat:@"/mbaas/sync/%@", dataId];
    NSDictionary* params = @{
                             @"fn" : @"removeCollisions",
                             @"hash" : collisionHash
                             };
    [FH performCloudRequest:path method:@"POST" headers:nil args:params completionHandler:^(FHResponse* response, NSError* error) {
        if (error != nil) { // response contains error
            failornil(response);
            return;
        }
        sucornil(response);
    }];
}

- (void)forceSync:(NSString*)dataSetId {
    FHSyncDataset *dataSet = _dataSets[dataSetId];
    if (dataSet) {
        dataSet.syncLoopPending = YES;
    }
}

@end
