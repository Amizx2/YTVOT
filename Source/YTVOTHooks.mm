#import "YTVOTHooks.h"
#import "YTVOTHooking.h"
#import "YTVOTCoordinator.h"
#import "YTVOTPreferences.h"
#import "YTVOTLocalization.h"
#import "YTVOTOverlayButton.h"
#import "YTVOTSettingsViewController.h"
#import "YTVOTLog.h"

#import <objc/message.h>

#pragma mark - Helper Functions

static id YTVOTObjectMessage(id receiver, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (receiver == nil || ![receiver respondsToSelector:selector]) {
        return nil;
    }
    return ((id (*)(id, SEL))objc_msgSend)(receiver, selector);
}

static NSString *YTVOTVideoIDFromObject(id object) {
    if ([object isKindOfClass:NSString.class]) {
        return object;
    }
    for (NSString *selector in @[@"videoID", @"videoId", @"currentVideoID", @"identifier"]) {
        id value = YTVOTObjectMessage(object, selector);
        if ([value isKindOfClass:NSString.class] && [value length] != 0) {
            return value;
        }
    }
    id details = YTVOTObjectMessage(object, @"videoDetails");
    if (details != nil && details != object) {
        return YTVOTVideoIDFromObject(details);
    }
    return nil;
}

static double YTVOTDurationFromObject(id object) {
    for (NSString *selector in @[@"totalMediaTime", @"duration", @"videoDuration", @"mediaTime"]) {
        SEL sel = NSSelectorFromString(selector);
        if ([object respondsToSelector:sel]) {
            return ((double (*)(id, SEL))objc_msgSend)(object, sel);
        }
    }
    return 0.0;
}

static void YTVOTNotifyDidActivateVideo(id receiver, id playbackController, id video, id playbackData) {
    NSString *videoID = YTVOTVideoIDFromObject(receiver) ?:
                        YTVOTVideoIDFromObject(video) ?:
                        YTVOTVideoIDFromObject(playbackData);
    
    double duration = YTVOTDurationFromObject(video) ?:
                      YTVOTDurationFromObject(playbackData) ?:
                      YTVOTDurationFromObject(receiver);

    if (videoID.length > 0) {
        [YTVOTCoordinator.sharedCoordinator videoDidActivateWithID:videoID
                                                          duration:duration
                                                            player:receiver
                                                playbackController:playbackController
                                                       singleVideo:video];
    }
}

#pragma mark - Playback Hooks

static IMP OriginalSingleVideoMediaState;
static void YTVOTSingleVideoMediaState(id receiver, SEL selector, id singleVideo, NSInteger fromState, NSInteger toState, int reason) {
    if (OriginalSingleVideoMediaState != NULL) {
        ((void (*)(id, SEL, id, NSInteger, NSInteger, int))OriginalSingleVideoMediaState)(
            receiver, selector, singleVideo, fromState, toState, reason
        );
    }
    [YTVOTCoordinator.sharedCoordinator videoMediaStateDidChangeFromState:fromState toState:toState stoppageReason:reason];
}

static IMP OriginalMutatedSingleVideoMediaState;
static void YTVOTMutatedSingleVideoMediaState(id receiver, SEL selector, id singleVideo, NSInteger fromState, NSInteger toState, int reason) {
    if (OriginalMutatedSingleVideoMediaState != NULL) {
        ((void (*)(id, SEL, id, NSInteger, NSInteger, int))OriginalMutatedSingleVideoMediaState)(
            receiver, selector, singleVideo, fromState, toState, reason
        );
    }
    [YTVOTCoordinator.sharedCoordinator videoMediaStateDidChangeFromState:fromState toState:toState stoppageReason:reason];
}

static IMP OriginalSingleVideoPlaybackRate;
static void YTVOTSingleVideoPlaybackRate(id receiver, SEL selector, id singleVideo, float rate) {
    if (OriginalSingleVideoPlaybackRate != NULL) {
        ((void (*)(id, SEL, id, float))OriginalSingleVideoPlaybackRate)(
            receiver, selector, singleVideo, rate
        );
    }
    [YTVOTCoordinator.sharedCoordinator videoPlaybackRateDidChange:rate];
}

static IMP OriginalDidDeactivateVideo;
static void YTVOTDidDeactivateVideo(id receiver, SEL selector, id playbackController, id video) {
    if (OriginalDidDeactivateVideo != NULL) {
        ((void (*)(id, SEL, id, id))OriginalDidDeactivateVideo)(receiver, selector, playbackController, video);
    }
    [YTVOTCoordinator.sharedCoordinator videoDidDeactivate];
}

static IMP OriginalDidStopPlayback;
static void YTVOTDidStopPlayback(id receiver, SEL selector, id playbackController, int reason) {
    if (OriginalDidStopPlayback != NULL) {
        ((void (*)(id, SEL, id, int))OriginalDidStopPlayback)(receiver, selector, playbackController, reason);
    }
    [YTVOTCoordinator.sharedCoordinator videoDidDeactivate];
}

#pragma mark - Miniplayer Dismiss Hooks

static IMP OriginalMiniplayerDidTapClose;
static void YTVOTMiniplayerDidTapClose(id receiver, SEL selector) {
    if (OriginalMiniplayerDidTapClose != NULL) {
        ((void (*)(id, SEL))OriginalMiniplayerDidTapClose)(receiver, selector);
    }
    [YTVOTCoordinator.sharedCoordinator videoDidDeactivate];
}

static IMP OriginalMiniplayerDidPressClose;
static void YTVOTMiniplayerDidPressClose(id receiver, SEL selector) {
    if (OriginalMiniplayerDidPressClose != NULL) {
        ((void (*)(id, SEL))OriginalMiniplayerDidPressClose)(receiver, selector);
    }
    [YTVOTCoordinator.sharedCoordinator videoDidDeactivate];
}

static IMP OriginalMiniBarDidTapClose;
static void YTVOTMiniBarDidTapClose(id receiver, SEL selector) {
    if (OriginalMiniBarDidTapClose != NULL) {
        ((void (*)(id, SEL))OriginalMiniBarDidTapClose)(receiver, selector);
    }
    [YTVOTCoordinator.sharedCoordinator videoDidDeactivate];
}

#pragma mark - Video Activation Hook on Player Controller

static IMP OriginalPlayerLoadVideo;
static void YTVOTPlayerLoadVideo(id receiver, SEL selector, id playbackData) {
    if (OriginalPlayerLoadVideo != NULL) {
        ((void (*)(id, SEL, id))OriginalPlayerLoadVideo)(receiver, selector, playbackData);
    }
    YTVOTNotifyDidActivateVideo(receiver, nil, nil, playbackData);
}

static IMP OriginalPlayerDidActivateVideo;
static void YTVOTPlayerDidActivateVideo(id receiver, SEL selector, id controller, id video) {
    if (OriginalPlayerDidActivateVideo != NULL) {
        ((void (*)(id, SEL, id, id))OriginalPlayerDidActivateVideo)(receiver, selector, controller, video);
    }
    YTVOTNotifyDidActivateVideo(receiver, controller, video, nil);
}

#pragma mark - Action Sheet Menu Hook

static IMP OriginalActionsForRenderers;
static id YTVOTActionsForRenderers(id receiver, SEL selector, id renderers, id fromView, id entry, BOOL shouldLog, id firstResponder) {
    id actions = nil;
    if (OriginalActionsForRenderers != NULL) {
        actions = ((id (*)(id, SEL, id, id, id, BOOL, id))OriginalActionsForRenderers)(
            receiver, selector, renderers, fromView, entry, shouldLog, firstResponder
        );
    }

    YTVOTPreferences *prefs = [YTVOTPreferences sharedPreferences];
    if (!prefs.enabled || prefs.buttonPlacement == YTVOTButtonPlacementOverlay) {
        return actions;
    }

    if (![actions isKindOfClass:NSMutableArray.class]) {
        return actions;
    }

    NSMutableArray *actionList = (NSMutableArray *)actions;
    Class actionClass = NSClassFromString(@"YTActionSheetAction");
    SEL makeSimple = NSSelectorFromString(@"actionWithTitle:iconImage:style:handler:");
    if (!actionClass || ![actionClass respondsToSelector:makeSimple]) {
        return actions;
    }

    // Check for duplicate
    for (id act in actionList) {
        NSString *title = nil;
        if ([act respondsToSelector:NSSelectorFromString(@"title")]) {
            title = ((NSString * (*)(id, SEL))objc_msgSend)(act, NSSelectorFromString(@"title"));
        }
        if ([title containsString:YTVOTLocalized(@"Voice-Over Translation")] ||
            [title containsString:YTVOTLocalized(@"Disable Translation")]) {
            return actions;
        }
    }

    UIImage *icon = nil;
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:17.0 weight:UIImageSymbolWeightRegular];
        icon = [UIImage systemImageNamed:@"waveform.badge.magnifyingglass" withConfiguration:config];
        if (!icon) icon = [UIImage systemImageNamed:@"globe" withConfiguration:config];
    }

    YTVOTCoordinator *coord = YTVOTCoordinator.sharedCoordinator;
    NSString *title;
    if (coord.currentState == YTVOTStatePlaying || coord.currentState == YTVOTStatePaused) {
        title = YTVOTLocalized(@"Disable Translation");
    } else {
        NSString *target = prefs.targetLanguage ?: @"ru";
        if ([target isEqualToString:@"en"]) {
            title = [NSString stringWithFormat:@"%@ (ENG)", YTVOTLocalized(@"Voice-Over Translation")];
        } else if ([target isEqualToString:@"kk"]) {
            title = [NSString stringWithFormat:@"%@ (ҚАЗ)", YTVOTLocalized(@"Voice-Over Translation")];
        } else {
            title = [NSString stringWithFormat:@"%@ (РУС)", YTVOTLocalized(@"Voice-Over Translation")];
        }
    }

    id votAction = ((id (*)(id, SEL, id, id, NSInteger, id))objc_msgSend)(
        actionClass, makeSimple, title, icon, 0, ^{
            [coord toggleTranslation];
        }
    );

    if (votAction) {
        [actionList addObject:votAction];
    }

    return actions;
}

#pragma mark - Overlay Button Injection on YTMainAppControlsOverlayView

static const NSInteger kYTVOTOverlayButtonTag = 0x59564F55; // 'YVOU'

static IMP OriginalOverlayLayoutSubviews;
static void YTVOTOverlayLayoutSubviews(UIView *receiver, SEL selector) {
    if (OriginalOverlayLayoutSubviews != NULL) {
        ((void (*)(id, SEL))OriginalOverlayLayoutSubviews)(receiver, selector);
    }

    YTVOTPreferences *prefs = [YTVOTPreferences sharedPreferences];
    if (!prefs.enabled || prefs.buttonPlacement == YTVOTButtonPlacementMenu) {
        UIView *existing = [receiver viewWithTag:kYTVOTOverlayButtonTag];
        if (existing) existing.hidden = YES;
        return;
    }

    YTVOTOverlayButton *btn = (YTVOTOverlayButton *)[receiver viewWithTag:kYTVOTOverlayButtonTag];
    if (!btn) {
        btn = [YTVOTOverlayButton overlayButton];
        btn.tag = kYTVOTOverlayButtonTag;
        [receiver addSubview:btn];
        YTVOTCoordinator.sharedCoordinator.overlayButton = btn;
    }

    btn.hidden = NO;
    [btn updateForState:YTVOTCoordinator.sharedCoordinator.currentState];

    // Find gear / settings button in overlay to position next to it
    UIView *referenceView = nil;
    for (UIView *sub in receiver.subviews) {
        NSString *ident = sub.accessibilityIdentifier.lowercaseString ?: @"";
        if ([ident containsString:@"gear"] ||
            [ident containsString:@"settings"] ||
            [ident containsString:@"overflow"]) {
            if (sub.frame.size.width > 10.0 && sub.frame.size.height > 10.0) {
                referenceView = sub;
                break;
            }
        }
    }

    CGFloat btnSize = 40.0;
    if (referenceView != nil && referenceView.window != nil) {
        CGRect refFrame = referenceView.frame;
        btn.frame = CGRectMake(CGRectGetMinX(refFrame) - btnSize - 6.0,
                               CGRectGetMidY(refFrame) - (btnSize / 2.0),
                               btnSize, btnSize);
    } else {
        // Fallback: top right corner with safe insets
        CGFloat topInset = 16.0;
        if (@available(iOS 11.0, *)) {
            topInset = MAX(receiver.safeAreaInsets.top, 16.0);
        }
        btn.frame = CGRectMake(receiver.bounds.size.width - btnSize - 54.0, topInset, btnSize, btnSize);
    }
}

static IMP OriginalOverlaySetOverlayVisible;
static void YTVOTOverlaySetOverlayVisible(UIView *receiver, SEL selector, BOOL visible, BOOL animated) {
    if (OriginalOverlaySetOverlayVisible != NULL) {
        ((void (*)(id, SEL, BOOL, BOOL))OriginalOverlaySetOverlayVisible)(receiver, selector, visible, animated);
    }
    UIView *btn = [receiver viewWithTag:kYTVOTOverlayButtonTag];
    if (btn) {
        if (animated) {
            [UIView animateWithDuration:0.2 animations:^{
                btn.alpha = visible ? 1.0 : 0.0;
            }];
        } else {
            btn.alpha = visible ? 1.0 : 0.0;
        }
    }
}

#pragma mark - YouTube Settings Injection Hook

static IMP OriginalSettingsSetSectionItems;
static void YTVOTSettingsSetSectionItems(UIViewController *receiver, SEL selector, NSMutableArray *items, NSUInteger category, NSString *title, NSString *titleDescription, BOOL headerHidden) {
    if ([items isKindOfClass:NSMutableArray.class]) {
        Class itemClass = NSClassFromString(@"YTSettingsSectionItem");
        if (itemClass != Nil) {
            // Check duplicate
            BOOL alreadyHasVOT = NO;
            for (id item in items) {
                if ([[item description] containsString:@"YTVOT"] || [[item description] containsString:@"Voice-Over"]) {
                    alreadyHasVOT = YES;
                    break;
                }
            }

            if (!alreadyHasVOT) {
                SEL itemMaker = NSSelectorFromString(@"itemWithTitle:accessibilityIdentifier:detailTextBlock:selectBlock:");
                if ([itemClass respondsToSelector:itemMaker]) {
                    id votItem = ((id (*)(id, SEL, id, id, id, id))objc_msgSend)(
                        itemClass, itemMaker,
                        YTVOTLocalized(@"Voice-Over Translation"),
                        @"id.amizx2.ytvot.settings",
                        ^NSString *{
                            return YTVOT_VERSION;
                        },
                        ^BOOL(id cell, NSUInteger status) {
                            (void)cell; (void)status;
                            [YTVOTSettingsViewController presentFromViewController:receiver];
                            return YES;
                        }
                    );
                    if (votItem) {
                        [items addObject:votItem];
                    }
                }
            }
        }
    }

    if (OriginalSettingsSetSectionItems != NULL) {
        ((void (*)(id, SEL, id, NSUInteger, id, id, BOOL))OriginalSettingsSetSectionItems)(
            receiver, selector, items, category, title, titleDescription, headerHidden
        );
    }
}

#pragma mark - Hook Registration Entrypoint

void YTVOTInstallHooks(void) {
    YTVOTLogAlways(@"Core", @"Installing YTVOT hooks (v%@)...", YTVOT_VERSION);

    // 1. Playback lifecycle hooks on YTPlayerViewController
    YTVOTInstallInstanceHook(@"YTPlayerViewController",
                            @"singleVideo:mediaStateDidChangeFromState:toState:stoppageReason:",
                            (IMP)YTVOTSingleVideoMediaState,
                            &OriginalSingleVideoMediaState);
    YTVOTInstallInstanceHook(@"YTPlayerViewController",
                            @"potentiallyMutatedSingleVideo:mediaStateDidChangeFromState:toState:stoppageReason:",
                            (IMP)YTVOTMutatedSingleVideoMediaState,
                            &OriginalMutatedSingleVideoMediaState);
    YTVOTInstallInstanceHook(@"YTPlayerViewController",
                            @"singleVideo:playbackRateDidChange:",
                            (IMP)YTVOTSingleVideoPlaybackRate,
                            &OriginalSingleVideoPlaybackRate);
    YTVOTInstallInstanceHook(@"YTPlayerViewController",
                            @"playbackController:didDeactivateVideo:",
                            (IMP)YTVOTDidDeactivateVideo,
                            &OriginalDidDeactivateVideo);
    YTVOTInstallInstanceHook(@"YTPlayerViewController",
                            @"playbackController:didStopPlaybackWithReason:",
                            (IMP)YTVOTDidStopPlayback,
                            &OriginalDidStopPlayback);
    YTVOTInstallInstanceHook(@"YTPlayerViewController",
                            @"loadVideoWithPlaybackData:",
                            (IMP)YTVOTPlayerLoadVideo,
                            &OriginalPlayerLoadVideo);
    YTVOTInstallInstanceHook(@"YTPlayerViewController",
                            @"playbackController:didActivateVideo:",
                            (IMP)YTVOTPlayerDidActivateVideo,
                            &OriginalPlayerDidActivateVideo);

    // 2. Miniplayer / Watch dismiss hooks
    YTVOTInstallInstanceHook(@"YTWatchFloatingMiniplayerViewController",
                            @"didTapClose",
                            (IMP)YTVOTMiniplayerDidTapClose,
                            &OriginalMiniplayerDidTapClose);
    YTVOTInstallInstanceHook(@"YTWatchFloatingMiniplayerViewController",
                            @"didPressClose",
                            (IMP)YTVOTMiniplayerDidPressClose,
                            &OriginalMiniplayerDidPressClose);
    YTVOTInstallInstanceHook(@"YTWatchMiniBarViewController",
                            @"didTapClose",
                            (IMP)YTVOTMiniBarDidTapClose,
                            &OriginalMiniBarDidTapClose);

    // 3. Action Sheet Menu Hook
    YTVOTInstallInstanceHook(@"YTMenuController",
                            @"actionsForRenderers:fromView:entry:shouldLogItems:firstResponder:",
                            (IMP)YTVOTActionsForRenderers,
                            &OriginalActionsForRenderers);

    // 4. Overlay Controls Hook on YTMainAppControlsOverlayView
    YTVOTInstallInstanceHook(@"YTMainAppControlsOverlayView",
                            @"layoutSubviews",
                            (IMP)YTVOTOverlayLayoutSubviews,
                            &OriginalOverlayLayoutSubviews);
    YTVOTInstallInstanceHook(@"YTMainAppControlsOverlayView",
                            @"setOverlayVisible:animated:",
                            (IMP)YTVOTOverlaySetOverlayVisible,
                            &OriginalOverlaySetOverlayVisible);

    // 5. YouTube Settings Hook
    YTVOTInstallInstanceHook(@"YTSettingsViewController",
                            @"setSectionItems:forCategory:title:titleDescription:headerHidden:",
                            (IMP)YTVOTSettingsSetSectionItems,
                            &OriginalSettingsSetSectionItems);

    YTVOTLogAlways(@"Core", @"YTVOT hooks successfully initialized.");
}
