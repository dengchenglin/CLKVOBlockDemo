//
//  NSObject+CL_KVO.m
//  CLKVOBlockDemo
//
//  Created by dengchenglin on 2016/4/12.
//  Copyright © 2016年 Property. All rights reserved.
//

#import "NSObject+CL_KVO.h"

#import <objc/message.h>

#define CLKVOClassPrefix @"CLKVO_"
#define CLKVOkeyArrayKey @"CLKVOkeyArrayKey"

@interface CLObserverInfo :NSObject

@property (nonatomic, weak) id observer;

@property (nonatomic, copy) NSString *key;

@property (nonatomic, copy) NSString *setterName;

@property (nonatomic, copy) CLKVOCallBack callBack;

- (instancetype)initWithObserver:(id)observer key:(NSString *)key setterName:(NSString *)setterName callBack:(CLKVOCallBack)callBack;

@end


@implementation CLObserverInfo

- (instancetype)initWithObserver:(id)observer key:(NSString *)key setterName:(NSString *)setterName callBack:(CLKVOCallBack)callBack
{
    if (self = [super init]) {
        _observer = observer;
        _key = key;
        _setterName = setterName;
        _callBack = callBack;
    }
    
    return self;
}


@end


@implementation NSObject (CL_KVO)

- (void)cl_addObserver:(NSObject *)observer forKey:(NSString *)key callBack:(CLKVOCallBack)callBack{
    //1、检测成员变量是否存在对应的key
    
    NSString *keySetterName = [self setterNameForKey:key];
    
    Method keySetterMethod = class_getInstanceMethod(self.class, NSSelectorFromString(keySetterName));
    
    if(!keySetterMethod){
        NSLog(@"没有与key对应的成员变量");
        return;
    }
    
    //2、新建一个子类，将isa指向这个子类
    Class cls = object_getClass(self);
    NSString *clsName = NSStringFromClass(cls);
    //是否是第一次添加通知
    if(![clsName hasPrefix:CLKVOClassPrefix]){
        
        NSString *kvoClassName = [CLKVOClassPrefix stringByAppendingString:clsName];
        Class kvoClass = NSClassFromString(kvoClassName);
        
        if(!kvoClass){
            kvoClass = objc_allocateClassPair(self.class, kvoClassName.UTF8String, 0);
            //修改kvo class方法的实现,否则外部调用class获取的是子类class
            //原类class方法
            Method originSetterMethod = class_getInstanceMethod(self.class, @selector(class));
            const char *types = method_getTypeEncoding(originSetterMethod);
            //新建子类class方法的实现
            IMP newImp = (IMP)cl_class;
            
            //为kvoClass添加class方法 并将实现指向原类的class方法的实现
            class_addMethod(kvoClass, @selector(class), newImp, types);
            
            objc_registerClassPair(kvoClass);
            
            object_setClass(self, kvoClass);
            
            cls = kvoClass;
        }
        
    }
    //3、为kvoClass添加setter方法
    class_addMethod(cls, NSSelectorFromString(keySetterName), (IMP)cl_setter, method_getTypeEncoding(keySetterMethod));
    
    //4、数组保存要监听的key
    CLObserverInfo *info = [[CLObserverInfo alloc] initWithObserver:observer key:key setterName:keySetterName callBack:callBack];

    NSMutableArray *observers = objc_getAssociatedObject(self, CLKVOkeyArrayKey);
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, CLKVOkeyArrayKey, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [observers addObject:info];
    
}

- (void)cl_removeObserver:(id)observer key:(NSString *)key{
    NSMutableArray *observers = objc_getAssociatedObject(self, CLKVOkeyArrayKey);
    if (!observers) return;
    for (CLObserverInfo *info in observers) {
        if([info.key isEqualToString:key] && (info.observer == observer)) {
            [observers removeObject:info];
            break;
        }
    }
}

- (void)cl_removeAllObserver:(id)observer{
    NSMutableArray *observers = objc_getAssociatedObject(self, CLKVOkeyArrayKey);
    if (!observers) return;
    for (CLObserverInfo *info in observers) {
        if(info.observer == observer) {
            [observers removeObject:info];
        }
    }
}

Class cl_class(id self, SEL cmd)
{
    Class cls = object_getClass(self);
    Class superCls = class_getSuperclass(cls);
    return superCls;
}

static void cl_setter(id self, SEL _cmd, id newValue)
{
    id oldValue;
    CLObserverInfo *currentInfo;
    NSString *setterName = NSStringFromSelector(_cmd);
    NSMutableArray *observers = objc_getAssociatedObject(self, CLKVOkeyArrayKey);
   
    for (CLObserverInfo *info in observers) {
        if ([info.setterName isEqualToString:setterName]) {
            oldValue = [self valueForKey:info.key];
            currentInfo = info;
        }
    }
    //调用原类setter方法
    struct objc_super superClazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    ((void (*)(void *, SEL, id))objc_msgSendSuper)(&superClazz, _cmd, newValue);
    
    if(currentInfo.callBack){
        currentInfo.callBack(currentInfo.observer, currentInfo.key, oldValue, newValue);
    }
    
}


- (NSString *)setterNameForKey:(NSString *)key
{
    // 1. 首字母转换成大写
    unichar c = [key characterAtIndex:0];
    NSString *str = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[NSString stringWithFormat:@"%c", c-32]];
    // 2. 最前增加set, 最后增加:
    NSString *setter = [NSString stringWithFormat:@"set%@:", str];
    return setter;
    
}

@end
