#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define YTVOT_BUNDLE_ID @"com.amizx2.ytvot"
#define YTVOT_VERSION @"1.0.0"

typedef NS_ENUM(NSInteger, YTVOTState) {
    YTVOTStateIdle = 0,
    YTVOTStateRequesting,
    YTVOTStateWaiting,
    YTVOTStatePlaying,
    YTVOTStatePaused,
    YTVOTStateError
};

typedef NS_ENUM(NSInteger, YTVOTButtonPlacement) {
    YTVOTButtonPlacementOverlay = 0,
    YTVOTButtonPlacementMenu = 1,
    YTVOTButtonPlacementBoth = 2
};

NS_ASSUME_NONNULL_END
