//
//  DemoViewController.m
//  algoliasearch
//
//  Created by pillar on 2019/11/5.
//  Copyright © 2019 pillar. All rights reserved.
//

#import "DemoViewController.h"
#import "HZNPodSearchManager.h"
@import InstantSearchClient;

@interface DemoViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong) Index *index;

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Client *c = [[Client alloc] initWithAppID:@"WBHHAMHYNM" apiKey:@"4f7544ca8701f9bf2a4e55daff1b09e9"];
    self.index = [c indexWithName:@"cocoapods"];
    // Do any additional setup after loading the view.
}
- (IBAction)search:(id)sender {
    NSDate *start = [NSDate date];
    //    NSArray *pods = @[@"FMDB",@"Texture",@"ReactiveCocoa",@"MJRefresh"];
    //    for (NSString *item in pods) {
    //        [HZNPodSearchManager search:item completion:^(NSDictionary * _Nullable dic, NSError * _Nullable err) {
    //            NSDate *end = [NSDate date];
    //            NSLog(@"%@（ %@ ） == >耗时 %d",dic[@"name"],dic[@"summary"],(int)[end timeIntervalSince1970] - (int)[start timeIntervalSince1970]);
    //        }];
    //    }
    [HZNPodSearchManager search:self.textField.text completion:^(NSDictionary * _Nullable dic, NSError * _Nullable err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDate *end = [NSDate date];
            NSLog(@"1 ==  %@（ %@ ） == >耗时 %d",dic[@"name"],dic[@"summary"],(int)[end timeIntervalSince1970] - (int)[start timeIntervalSince1970]);
        });
    }];
    
    [HZNPodSearchManager searchVersions:self.textField.text completion:^(NSDictionary * _Nullable dic, NSError * _Nullable err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDate *end = [NSDate date];
            NSLog(@"2 == %@（ %@ ） == >耗时 %d",self.textField.text,dic[@"versions"],(int)[end timeIntervalSince1970] - (int)[start timeIntervalSince1970]);
        });
    }];
    
    [HZNPodSearchManager searchVersions1:self.textField.text completion:^(NSDictionary * _Nullable dic, NSError * _Nullable err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDate *end = [NSDate date];
            NSLog(@"3 ==%@（ %@ ） == >耗时 %d",self.textField.text,dic[@"versions"],(int)[end timeIntervalSince1970] - (int)[start timeIntervalSince1970]);
        });
    }];
    
    
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
