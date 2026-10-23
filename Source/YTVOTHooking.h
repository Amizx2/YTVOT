#pragma once

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT BOOL YTVOTInstallInstanceHook(NSString *className, NSString *selectorName, IMP hookIMP, IMP _Nullable * _Nullable originalIMP);
FOUNDATION_EXPORT BOOL YTVOTInstallClassHook(NSString *className, NSString *selectorName, IMP hookIMP, IMP _Nullable * _Nullable originalIMP);
FOUNDATION_EXPORT Class _Nullable YTVOTResolveClass(NSString *className);

NS_ASSUME_NONNULL_END
