#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^YTVOTYandexAuthCompletion)(BOOL success, NSString * _Nullable login, NSString * _Nullable errorMessage);

@interface YTVOTYandexAuthViewController : UIViewController

@property (nonatomic, copy, nullable) YTVOTYandexAuthCompletion completion;

+ (void)presentFromViewController:(UIViewController *)viewController
                       completion:(nullable YTVOTYandexAuthCompletion)completion;

+ (void)openSafariAuth;

@end

NS_ASSUME_NONNULL_END
