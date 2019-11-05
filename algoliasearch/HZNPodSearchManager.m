//
//  HZNPodSearchManager.m
//  algoliasearch
//
//  Created by pillar on 2019/11/5.
//  Copyright © 2019 pillar. All rights reserved.
//

#import "HZNPodSearchManager.h"
#import <CommonCrypto/CommonDigest.h>

@import InstantSearchClient;
@interface HZNPodSearchManager()
@property (nonatomic, strong) Index *i;
@property (nonatomic, strong) NSURLSession *s;
@property (nonatomic, copy) NSString *cachePath;
@end

@implementation HZNPodSearchManager
+ (instancetype)sharedInstanced {
    static HZNPodSearchManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}
+ (void)setCachePath:(NSString *)cachePath {
    [HZNPodSearchManager sharedInstanced].cachePath = cachePath;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        Client *c = [[Client alloc] initWithAppID:@"WBHHAMHYNM" apiKey:@"4f7544ca8701f9bf2a4e55daff1b09e9"];
        _i = [c indexWithName:@"cocoapods"];
        _s = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _cachePath = NSTemporaryDirectory();
    }
    return self;
}

+ (void)search:(NSString *)pod completion:(void(^)( NSDictionary * _Nullable dic,  NSError * _Nullable err))completion {
    pod = [pod stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (pod.length == 0) {
        if (completion) {
            completion(@{},nil);
        }
        return;
    }
    
    Query *q = [[Query alloc] initWithQuery:pod];
    [[HZNPodSearchManager sharedInstanced].i search:q completionHandler:^(NSDictionary<NSString *,id> * _Nullable content, NSError * _Nullable err) {
        NSDictionary *ret = nil;
        if (err == nil) {
            NSArray *hits = content[@"hits"];
            for (NSDictionary *podInfo in hits) {
                if ([podInfo[@"name"] isEqualToString:pod]) {
                    ret = podInfo;
                    break;
                }
            }
            
        }
        if (completion) {
            completion(ret,err);
        }
    }];
}

+ (void)searchVersions:(NSString *)pod completion:(void(^)( NSDictionary * _Nullable dic,  NSError * _Nullable err))completion {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://trunk.cocoapods.org/api/v1/pods/%@",pod]];
    [[[HZNPodSearchManager sharedInstanced].s dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable err) {
        if (completion) {
            if (data) {
                id objc = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if (objc) {
                    NSArray *versions = objc[@"versions"];
                    NSMutableArray *res = [NSMutableArray arrayWithCapacity:versions.count];
                    for (NSDictionary *info in versions) {
                        [res addObject:info[@"name"]];
                    }
                    if (res.count) {
                        completion(@{@"versions":[[[res reverseObjectEnumerator] allObjects] copy]},nil);
                        return ;
                    }
                }
            }
            completion(nil,nil);
        }
    }] resume];
}

// 具体参考： https://cdn.cocoapods.org/CocoaPods-version.yml prefix_lengths字段
static int prefix_lengths = 3;

+ (void)searchVersions1:(NSString *)pod completion:(void(^)( NSDictionary * _Nullable dic,  NSError * _Nullable err))completion {
    
    NSString *md5 = MD5(pod);
    NSMutableArray *segment = [NSMutableArray arrayWithCapacity:3];
    for (int i = 0; i<prefix_lengths; i++) {
        [segment addObject:[md5 substringWithRange:NSMakeRange(i, 1)]];
    }
    // https://cdn.cocoapods.org/all_pods_versions_1_1_7.txt
    assert(segment.count == 3);
    
    NSString *file = [NSString stringWithFormat:@"all_pods_versions_%@_%@_%@.txt",segment[0],segment[1],segment[2]];
    NSString *eTag;
    
    NSString *absPath = [[HZNPodSearchManager sharedInstanced].cachePath stringByAppendingPathComponent:file];
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:absPath];
    // 检查文件是否存在
    if (fileExist) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:absPath error:NULL];
        NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];
        // 缓存时长1小时
        if ([[NSDate date] timeIntervalSince1970] - [fileModDate timeIntervalSince1970] < 3600) {
            NSArray *ret = [self versionsWithPodName:pod inFile:absPath];
            if (completion) {
                completion(ret ? @{@"versions":ret} : nil , nil);
            }
            return;
        }
        
        eTag = [self etag:absPath];
    }
    
    // 那么下载
    // https://cdn.cocoapods.org/all_pods_versions_1_1_7.txt
    NSString *url = [NSString stringWithFormat:@"https://cdn.cocoapods.org/%@",file];
    [self requestURL:url filePath:absPath tag:eTag completion:^(NSData * _Nullable data, NSError * _Nullable err) {
        if (err == nil) {
            NSArray *ret = [self versionsWithPodName:pod inFile:absPath];
            if (completion) {
                completion(ret ? @{@"versions":ret} : nil , nil);
            }
        } else {
            if (completion) {
                completion(nil , err);
            }
        }
    }];
}


+ (void)requestURL:(NSString *)path filePath:(NSString *)filePath tag:(NSString * _Nullable)tag completion:(void(^)( NSData * _Nullable data,  NSError * _Nullable err))completion {
    NSURL *url = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    if (tag) {
        [request setValue:tag forHTTPHeaderField:@"If-None-Match"];
    }
    [[[HZNPodSearchManager sharedInstanced].s dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {
            NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
            NSInteger code = httpRes.statusCode;
            switch (code) {
                case 301:   // 重定向
                {
                    NSString *location = nil;
                    id value = httpRes.allHeaderFields[@"location"];
                    if ([value isKindOfClass:[NSArray class]]) {
                        location = [value firstObject];
                    } else {
                        location = value;
                    }
                    [self requestURL:location filePath:filePath tag:tag completion:completion];
                    return ;
                }
                    break;
                case 304:{
                    NSFileManager *fm = [NSFileManager defaultManager];
                    //更改文件属性
                    NSDictionary *attrDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSDate date],NSFileModificationDate, nil];
                    [fm setAttributes:attrDict ofItemAtPath:filePath error:nil];
                }
                    break;
                case 200:{
                    [data writeToFile:filePath atomically:YES];
                    NSString *etag = [httpRes.allHeaderFields objectForKey:@"etag"];
                    if (etag) {
                        NSData *data = [etag dataUsingEncoding:NSUTF8StringEncoding];
                        [data writeToFile:[NSString stringWithFormat:@"%@.etag",filePath] atomically:YES];
                    }
                }
                    break;
                default:
                    break;
            }
        }
        if (completion) {
            completion(data,error);
        }
    }] resume];
}




+ (nullable NSArray *)versionsWithPodName:(NSString *)name inFile:(NSString *)path{
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) {
        return nil;
    }
    NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        NSArray *array = [line componentsSeparatedByString:@"/"];
        if ([[array firstObject] isEqualToString:name]) {
            return [[[array subarrayWithRange:NSMakeRange(1, array.count - 1)] reverseObjectEnumerator] allObjects];
        }
    }
    return nil;
}

+ (nullable NSString *)etag:(NSString *)path {
    NSString *filePath = [NSString stringWithFormat:@"%@.etag",path];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (data) {
            return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    return nil;
}


static NSString* MD5(NSString *str)
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    
    NSNumber *num = [NSNumber numberWithUnsignedLong:strlen(cStr)];
    CC_MD5( cStr,[num intValue], result );
    
    return [[NSString stringWithFormat:
             @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
             result[0], result[1], result[2], result[3],
             result[4], result[5], result[6], result[7],
             result[8], result[9], result[10], result[11],
             result[12], result[13], result[14], result[15]
             ] lowercaseString];
}
@end
