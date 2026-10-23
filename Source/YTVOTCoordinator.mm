#import <objc/message.h>
#import "YTVOTCoordinator.h"
#import "YTVOTClient.h"
#import "YTVOTAudioPlayer.h"
#import "YTVOTPreferences.h"
#import "YTVOTLocalization.h"
#import "YTVOTNotice.h"
#import "YTVOTLog.h"

NSString * const YTVOTStateDidChangeNotification = @"YTVOTStateDidChangeNotification";


@interface YTVOTCoordinator () <YTVOTAudioPlayerDelegate>
@property (nonatomic, assign) YTVOTState currentState;
@property (nonatomic, copy, nullable) NSString *currentVideoID;
@property (nonatomic, assign) double currentVideoDuration;
@property (nonatomic, copy, nullable) NSString *statusMessage;
@property (nonatomic, strong, nullable) NSTimer *retryTimer;
@end

@implementation YTVOTCoordinator

+ (instancetype)sharedCoordinator {
    static YTVOTCoordinator *coordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coordinator = [[YTVOTCoordinator alloc] init];
    });
    return coordinator;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentState = YTVOTStateIdle;
        _lastPlaybackRate = 1.0f;
        YTVOTAudioPlayer.sharedPlayer.delegate = self;
        [self reloadPreferences];

        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(handlePreferencesChanged)
                                                   name:YTVOTPreferencesDidChangeNotification
                                                 object:nil];
    }
    return self;
}

- (void)handlePreferencesChanged {
    [self reloadPreferences];
    [self updateOverlayButton];
}

- (void)reloadPreferences {
    YTVOTPreferences *prefs = [YTVOTPreferences sharedPreferences];
    if (!prefs.enabled && self.currentState != YTVOTStateIdle) {
        [self stopTranslation];
    }
    YTVOTAudioPlayer.sharedPlayer.backgroundVolume = prefs.backgroundVolume;
    YTVOTAudioPlayer.sharedPlayer.translationVolume = prefs.translationVolume;
    YTVOTAudioPlayer.sharedPlayer.adaptiveDuckingEnabled = prefs.adaptiveDucking;
}

- (void)setState:(YTVOTState)state {
    _currentState = state;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateOverlayButton];
        [NSNotificationCenter.defaultCenter postNotificationName:YTVOTStateDidChangeNotification object:self];
    });
}

#pragma mark - Video Lifecycle Events

- (void)videoDidActivateWithID:(NSString *)videoID duration:(double)duration player:(id _Nullable)player {
    [self videoDidActivateWithID:videoID duration:duration player:player playbackController:nil singleVideo:nil];
}

- (void)videoDidActivateWithID:(NSString *)videoID duration:(double)duration player:(id _Nullable)player playbackController:(id _Nullable)playbackController singleVideo:(id _Nullable)singleVideo {
    [self stopTranslation];
    [self.retryTimer invalidate];
    self.retryTimer = nil;

    YTVOTLog(@"Coordinator", @"videoDidActivateWithID: %@, duration=%.1fs, player=%@", videoID, duration, player ? NSStringFromClass([player class]) : @"nil");

    self.currentVideoID = videoID;
    self.currentVideoDuration = duration;

    double detectedTime = 0.0;
    NSArray *timeSources = @[player ?: [NSNull null], singleVideo ?: [NSNull null], playbackController ?: [NSNull null]];
    for (id obj in timeSources) {
        if (!obj || obj == [NSNull null]) continue;
        for (NSString *selName in @[@"currentVideoMediaTime", @"currentTime", @"mediaTime"]) {
            SEL sel = NSSelectorFromString(selName);
            if ([obj respondsToSelector:sel]) {
                double t = ((double (*)(id, SEL))objc_msgSend)(obj, sel);
                if (isfinite(t) && t > 0.0) {
                    detectedTime = t;
                    break;
                }
            }
        }
        if (detectedTime > 0.0) break;
    }
    self.lastPlaybackTime = detectedTime;

    float detectedRate = 0.0f;
    if (singleVideo && [singleVideo respondsToSelector:NSSelectorFromString(@"playbackRate")]) {
        detectedRate = ((float (*)(id, SEL))objc_msgSend)(singleVideo, NSSelectorFromString(@"playbackRate"));
    } else if (playbackController && [playbackController respondsToSelector:NSSelectorFromString(@"currentPlaybackRate")]) {
        detectedRate = ((float (*)(id, SEL))objc_msgSend)(playbackController, NSSelectorFromString(@"currentPlaybackRate"));
    }
    if (detectedRate < 0.25f || detectedRate > 5.0f) {
        float saved = [NSUserDefaults.standardUserDefaults floatForKey:@"YTVOT.Preference.Player.SavedRate"];
        if (saved >= 0.25f && saved <= 5.0f) {
            detectedRate = saved;
        }
    }
    if (detectedRate >= 0.25f && detectedRate <= 5.0f) {
        self.lastPlaybackRate = detectedRate;
    } else if (self.lastPlaybackRate < 0.25f || self.lastPlaybackRate > 5.0f) {
        self.lastPlaybackRate = 1.0f;
    }

    [YTVOTAudioPlayer.sharedPlayer attachYouTubePlayer:player playbackController:playbackController singleVideo:singleVideo];

    YTVOTPreferences *prefs = [YTVOTPreferences sharedPreferences];
    BOOL enabled = prefs.enabled;
    if (!enabled) {
        self.state = YTVOTStateDisabled;
        return;
    }

    self.state = YTVOTStateIdle;
    self.statusMessage = nil;

    BOOL autoTranslate = prefs.autoTranslate;
    if (autoTranslate && videoID.length > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([self.currentVideoID isEqualToString:videoID] && self.currentState == YTVOTStateIdle) {
                [self startTranslation];
            }
        });
    }
}

- (void)videoPlaybackStateDidChangeIsPlaying:(BOOL)isPlaying rate:(float)rate time:(NSTimeInterval)time {
    self.lastVideoWasPlaying = isPlaying;
    self.lastPlaybackRate = rate > 0.0f ? rate : 1.0f;
    self.lastPlaybackTime = time;

    if (self.currentState == YTVOTStatePlaying || self.currentState == YTVOTStatePaused) {
        [YTVOTAudioPlayer.sharedPlayer synchronizeWithVideoTime:time rate:self.lastPlaybackRate isPlaying:isPlaying];
        self.state = isPlaying ? YTVOTStatePlaying : YTVOTStatePaused;
    }
}

- (void)videoMediaStateDidChangeFromState:(NSInteger)fromState toState:(NSInteger)toState stoppageReason:(int)reason {
    YTVOTLog(@"Coordinator", @"mediaStateDidChange: %ld -> %ld (reason: %d)", (long)fromState, (long)toState, reason);

    // YouTube YTSingleVideoMediaState: 3 = Playing
    if (toState == 3) {
        self.lastVideoWasPlaying = YES;
        if (self.currentState == YTVOTStatePaused) {
            self.state = YTVOTStatePlaying;
            [YTVOTAudioPlayer.sharedPlayer playAtRate:self.lastPlaybackRate];
        }
    }
    // YouTube YTSingleVideoMediaState: 2 = Paused, 4 = Buffering, 5 = Seeking, 6 = Suspended
    else if (toState == 2 || toState == 4 || toState == 5 || toState == 6) {
        self.lastVideoWasPlaying = NO;
        if (self.currentState == YTVOTStatePlaying) {
            self.state = YTVOTStatePaused;
            [YTVOTAudioPlayer.sharedPlayer pause];
        }
    }
    // YouTube YTSingleVideoMediaState: 1 = Ended / Unstarted
    else if (toState == 1) {
        self.lastVideoWasPlaying = NO;
        if (self.currentState == YTVOTStatePlaying || self.currentState == YTVOTStatePaused) {
            [self stopTranslation];
        }
    }
}

- (void)videoPlaybackRateDidChange:(float)rate {
    float safeRate = rate > 0.0f ? rate : 1.0f;
    YTVOTLog(@"Coordinator", @"videoPlaybackRateDidChange: %.2f", safeRate);
    self.lastPlaybackRate = safeRate;
    [YTVOTAudioPlayer.sharedPlayer setTargetPlaybackRate:safeRate];
}

- (void)videoDidSeekToTime:(NSTimeInterval)time {
    self.lastPlaybackTime = time;
    YTVOTLog(@"Coordinator", @"videoDidSeekToTime: %.2fs", time);
    if (self.currentState == YTVOTStatePlaying || self.currentState == YTVOTStatePaused) {
        [YTVOTAudioPlayer.sharedPlayer seekToTime:time];
    }
}

- (void)videoDidDeactivate {
    YTVOTLog(@"Coordinator", @"videoDidDeactivate (was %@)", self.currentVideoID);
    [self.retryTimer invalidate];
    self.retryTimer = nil;
    [self stopTranslation];
    [YTVOTAudioPlayer.sharedPlayer detachYouTubePlayer];
    self.currentVideoID = nil;
    self.state = YTVOTStateIdle;
}

#pragma mark - Translation Actions

- (void)toggleTranslation {
    if (self.currentState == YTVOTStatePlaying || self.currentState == YTVOTStatePaused || self.currentState == YTVOTStateLoading) {
        [self stopTranslation];
    } else {
        [self startTranslation];
    }
}

- (void)startTranslation {
    if (self.currentVideoID.length == 0) {
        self.currentVideoID = self.currentVideoID;
    }
    if (self.currentVideoID.length == 0) {
        YTVOTLog(@"Coordinator", @"startTranslation called with no active video ID");
        YTVOTShowNotice(YTVOTLocalized(@"No active video"));
        return;
    }

    [self.retryTimer invalidate];
    self.retryTimer = nil;

    self.state = YTVOTStateLoading;
    self.statusMessage = YTVOTLocalized(@"Translating...");
    YTVOTShowNotice(YTVOTLocalized(@"Translating..."));

    NSString *videoID = self.currentVideoID;
    double duration = self.currentVideoDuration;

    YTVOTPreferences *prefs = [YTVOTPreferences sharedPreferences];
    NSString *targetLang = prefs.targetLanguage ?: @"ru";
    NSString *voiceType = prefs.voice ?: @"any";

    YTVOTLog(@"Coordinator", @"startTranslation: videoID=%@, duration=%.1fs, targetLang=%@, voiceType=%@", videoID, duration, targetLang, voiceType);

    [YTVOTClient.sharedClient requestTranslationForVideoID:videoID
                                                      duration:duration
                                                    sourceLang:nil
                                                    targetLang:targetLang
                                                     voiceType:voiceType
                                                    completion:^(YTVOTResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self.currentVideoID isEqualToString:videoID]) {
                YTVOTLog(@"Coordinator", @"Video changed during translation request (was %@, now %@)", videoID, self.currentVideoID);
                return; // Video changed
            }

            if (error != nil || response == nil) {
                self.state = YTVOTStateError;
                self.statusMessage = error.localizedDescription ?: YTVOTLocalized(@"Translation failed");
                YTVOTLog(@"Coordinator", @"Translation request error: %@", self.statusMessage);
                YTVOTShowNotice(self.statusMessage);
                return;
            }

            YTVOTLog(@"Coordinator", @"Translation status result: status=%ld, audioURL=%@, remTime=%ld, msg=%@", (long)response.status, response.audioURL ?: @"-", (long)response.remainingTime, response.message ?: @"-");

            if ((response.status == YTVOTStatusFinished || response.status == YTVOTStatusPartContent) && response.audioURL.length > 0) {
                NSURL *url = [NSURL URLWithString:response.audioURL];
                if (url != nil) {
                    self.statusMessage = YTVOTLocalized(@"Translation ready");
                    YTVOTLog(@"Coordinator", @"Loading audio URL (autoPlay=%d): %@", self.lastVideoWasPlaying, response.audioURL);
                    [YTVOTAudioPlayer.sharedPlayer loadURL:url initialTime:self.lastPlaybackTime rate:self.lastPlaybackRate autoPlay:self.lastVideoWasPlaying];
                    self.state = self.lastVideoWasPlaying ? YTVOTStatePlaying : YTVOTStatePaused;
                    YTVOTShowNotice(YTVOTLocalized(@"Voice-over active"));
                } else {
                    self.state = YTVOTStateError;
                    self.statusMessage = YTVOTLocalized(@"Invalid audio link");
                    YTVOTLog(@"Coordinator", @"Invalid audio URL string: %@", response.audioURL);
                    YTVOTShowNotice(self.statusMessage);
                }
            } else if (response.status == YTVOTStatusWaiting ||
                       response.status == YTVOTStatusLongWaiting ||
                       response.status == YTVOTStatusPartContent ||
                       response.status == YTVOTStatusAudioRequested) {
                NSInteger waitSeconds = response.remainingTime > 0 ? response.remainingTime : 10;
                NSInteger pollInterval = MIN(MAX(waitSeconds, 3), 6);
                self.statusMessage = [NSString stringWithFormat:YTVOTLocalized(@"Wait %ld sec..."), (long)waitSeconds];
                YTVOTLog(@"Coordinator", @"Translation in progress (%ld sec remaining, next poll in %ld sec). Scheduling retry timer...", (long)waitSeconds, (long)pollInterval);
                YTVOTShowNotice(self.statusMessage);

                self.retryTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)pollInterval
                                                                   repeats:NO
                                                                     block:^(NSTimer * _Nonnull timer) {
                    (void)timer;
                    if ([self.currentVideoID isEqualToString:videoID]) {
                        YTVOTLog(@"Coordinator", @"Retry timer fired for videoID=%@. Re-querying translation...", videoID);
                        [self startTranslation];
                    }
                }];
            } else if (response.status == YTVOTStatusSessionRequired) {
                self.state = YTVOTStateError;
                self.statusMessage = YTVOTLocalized(@"Yandex account required for this video");
                YTVOTLog(@"Coordinator", @"Translation requires Yandex session (status 7)");
                YTVOTShowNotice(self.statusMessage);
            } else {
                self.state = YTVOTStateError;
                self.statusMessage = response.message.length > 0 ? response.message : YTVOTLocalized(@"Translation unavailable");
                YTVOTLog(@"Coordinator", @"Translation unavailable or failed: %@", self.statusMessage);
                YTVOTShowNotice(self.statusMessage);
            }
        });
    }];
}

- (void)stopTranslation {
    YTVOTLog(@"Coordinator", @"stopTranslation called");
    [self.retryTimer invalidate];
    self.retryTimer = nil;
    [YTVOTAudioPlayer.sharedPlayer stop];
    self.state = YTVOTStateIdle;
    self.statusMessage = nil;
}

#pragma mark - YTVOTAudioPlayerDelegate

- (void)votAudioPlayerDidReachEnd {
    self.state = YTVOTStateIdle;
}

#pragma mark - UI Update

- (void)updateOverlayButton {
    UIButton *btn = self.overlayButton;
    if (btn == nil) return;

    YTVOTPreferences *prefs = [YTVOTPreferences sharedPreferences];
    if (!prefs.enabled || prefs.buttonPlacement == YTVOTButtonPlacementMenu) {
        btn.hidden = YES;
        return;
    }

    btn.hidden = NO;

    if (@available(iOS 13.0, *)) {
        switch (self.currentState) {
            case YTVOTStateLoading:
                [btn setImage:[UIImage systemImageNamed:@"hourglass"] forState:UIControlStateNormal];
                [btn setTitle:nil forState:UIControlStateNormal];
                [btn setTintColor:UIColor.systemYellowColor];
                break;
            case YTVOTStatePlaying:
            case YTVOTStatePaused:
                [btn setImage:[UIImage systemImageNamed:@"waveform"] forState:UIControlStateNormal];
                [btn setTitle:nil forState:UIControlStateNormal];
                [btn setTintColor:UIColor.systemGreenColor];
                break;
            default:
                [btn setImage:[UIImage systemImageNamed:@"waveform.badge.magnifyingglass"] forState:UIControlStateNormal];
                [btn setTitle:nil forState:UIControlStateNormal];
                [btn setTintColor:UIColor.whiteColor];
                break;
        }
    }
}

@end
