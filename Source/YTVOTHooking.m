#import "YTVOTHooking.h"
#import "YTVOTLog.h"

Class _Nullable YTVOTResolveClass(NSString *className) {
    if (className.length == 0) return Nil;
    return NSClassFromString(className);
}

BOOL YTVOTInstallInstanceHook(NSString *className, NSString *selectorName, IMP hookIMP, IMP _Nullable * _Nullable originalIMP) {
    Class targetClass = YTVOTResolveClass(className);
    if (!targetClass || !hookIMP) {
        YTVOTLog(@"Hook", @"Class '%@' not found, hook skipped.", className);
        return NO;
    }

    SEL selector = NSSelectorFromString(selectorName);
    Method method = class_getInstanceMethod(targetClass, selector);
    if (!method) {
        YTVOTLog(@"Hook", @"Method -[%@ %@] not found, hook skipped.", className, selectorName);
        return NO;
    }

    const char *types = method_getTypeEncoding(method);
    IMP previousIMP = class_replaceMethod(targetClass, selector, hookIMP, types);
    if (!previousIMP) {
        previousIMP = method_getImplementation(method);
    }

    if (originalIMP) {
        *originalIMP = previousIMP;
    }
    YTVOTLog(@"Hook", @"Installed hook on -[%@ %@]", className, selectorName);
    return YES;
}

BOOL YTVOTInstallClassHook(NSString *className, NSString *selectorName, IMP hookIMP, IMP _Nullable * _Nullable originalIMP) {
    Class targetClass = YTVOTResolveClass(className);
    if (!targetClass || !hookIMP) {
        return NO;
    }

    Class metaClass = object_getClass((id)targetClass);
    if (!metaClass) return NO;

    SEL selector = NSSelectorFromString(selectorName);
    Method method = class_getClassMethod(targetClass, selector);
    if (!method) return NO;

    const char *types = method_getTypeEncoding(method);
    IMP previousIMP = class_replaceMethod(metaClass, selector, hookIMP, types);
    if (!previousIMP) {
        previousIMP = method_getImplementation(method);
    }

    if (originalIMP) {
        *originalIMP = previousIMP;
    }
    return YES;
}
