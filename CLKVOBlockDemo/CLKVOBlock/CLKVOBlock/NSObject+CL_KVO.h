//
//  NSObject+CL_KVO.h
//  CLKVOBlockDemo
//
//  Created by dengchenglin on 2016/4/12.
//  Copyright © 2016年 Property. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CLKVOCallBack)(id observer, NSString *key,id oldValue,id newValue);

@interface NSObject (CL_KVO)

- (void)cl_addObserver:(NSObject *)observer forKey:(NSString *)key callBack:(CLKVOCallBack)callBack;

- (void)cl_removeObserver:(id)observer key:(NSString *)key;

- (void)cl_removeAllObserver:(id)observer;

@end
