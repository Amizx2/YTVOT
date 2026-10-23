#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define YTVOT_BUNDLE_ID @"com.amizx2.ytvot"
#define YTVOT_VERSION @"1.0.0"

typedef NS_ENUM(NSInteger, YTVOTState) {
    YTVOTStateDisabled = 0,
    YTVOTStateIdle = 1,
    YTVOTStateLoading = 2,
    YTVOTStatePlaying = 3,
    YTVOTStatePaused = 4,
    YTVOTStateError = 5
};

typedef NS_ENUM(NSInteger, YTVOTButtonPlacement) {
    YTVOTButtonPlacementOverlay = 0,
    YTVOTButtonPlacementMenu = 1,
    YTVOTButtonPlacementBoth = 2
};

NS_ASSUME_NONNULL_END
