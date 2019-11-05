//
//  HZNPodSearchManager.h
//  algoliasearch
//
//  Created by pillar on 2019/11/5.
//  Copyright © 2019 pillar. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HZNPodSearchManager : NSObject
+ (void)setCachePath:(NSString *)cachePath;
+ (void)search:(NSString *)pod completion:(void(^)( NSDictionary * _Nullable dic,  NSError * _Nullable err))completion;
+ (void)searchVersions:(NSString *)pod completion:(void(^)( NSDictionary * _Nullable dic,  NSError * _Nullable err))completion;
+ (void)searchVersions1:(NSString *)pod completion:(void(^)( NSDictionary * _Nullable dic,  NSError * _Nullable err))completion;
@end

NS_ASSUME_NONNULL_END
