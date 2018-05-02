//
//  ViewController.m
//  CLKVOBlockDemo
//
//  Created by dengchenglin on 2016/4/12.
//  Copyright © 2016年 Property. All rights reserved.
//

#import "ViewController.h"

#import "Test.h"

#import "NSObject+CL_KVO.h"

@interface ViewController ()



@end

@implementation ViewController
{
    Test *test1;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    test1 = [Test new];
  
//    [test1 cl_addObserver:self forKey:@"name" callBack:^(id observer, NSString *key, id oldValue, id newValue) {
//        NSLog(@"observer is --%@\n key is --%@\n oldValue is --%@\n newValue is --%@",observer,key,oldValue,newValue);
//    }];
    
    [test1 addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    
    

    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    test1.name = [NSString stringWithFormat:@"%d",arc4random()];
}


- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [test1 cl_removeAllObserver:self];
}

@end
