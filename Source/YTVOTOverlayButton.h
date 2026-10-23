#pragma once

#import <UIKit/UIKit.h>
#import "YTVOTDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface YTVOTOverlayButton : UIButton

+ (instancetype)overlayButton;

- (void)updateForState:(YTVOTState)state;

@end

NS_ASSUME_NONNULL_END
