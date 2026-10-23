#pragma once

#import <UIKit/UIKit.h>
#import "YTVOTDefines.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const YTVOTStateDidChangeNotification;

@interface YTVOTCoordinator : NSObject

+ (instancetype)sharedCoordinator;

@property (nonatomic, readonly) YTVOTState currentState;
@property (nonatomic, copy, readonly, nullable) NSString *currentVideoID;
@property (nonatomic, assign, readonly) double currentVideoDuration;
@property (nonatomic, copy, readonly, nullable) NSString *statusMessage;

@property (nonatomic, weak, nullable) UIButton *overlayButton;
@property (nonatomic, assign) BOOL lastVideoWasPlaying;
@property (nonatomic, assign) float lastPlaybackRate;
@property (nonatomic, assign) NSTimeInterval lastPlaybackTime;

- (void)videoDidActivateWithID:(NSString *)videoID duration:(double)duration player:(id _Nullable)player;
- (void)videoDidActivateWithID:(NSString *)videoID duration:(double)duration player:(id _Nullable)player playbackController:(id _Nullable)playbackController singleVideo:(id _Nullable)singleVideo;
- (void)videoPlaybackStateDidChangeIsPlaying:(BOOL)isPlaying rate:(float)rate time:(NSTimeInterval)time;
- (void)videoMediaStateDidChangeFromState:(NSInteger)fromState toState:(NSInteger)toState stoppageReason:(int)reason;
- (void)videoPlaybackRateDidChange:(float)rate;
- (void)videoDidSeekToTime:(NSTimeInterval)time;
- (void)videoDidDeactivate;

- (void)toggleTranslation;
- (void)startTranslation;
- (void)stopTranslation;
- (void)updateOverlayButton;

@end

NS_ASSUME_NONNULL_END
