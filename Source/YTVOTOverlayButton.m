#import "YTVOTOverlayButton.h"
#import "YTVOTCoordinator.h"
#import "YTVOTPreferences.h"
#import "YTVOTSettingsViewController.h"

@interface YTVOTOverlayButton ()
@property (nonatomic, strong, nullable) UIActivityIndicatorView *spinner;
@end

@implementation YTVOTOverlayButton

+ (instancetype)overlayButton {
    YTVOTOverlayButton *button = [YTVOTOverlayButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 40, 40);
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    button.accessibilityLabel = @"Voice-Over Translation";

    [button addTarget:button action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:button action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.5;
    [button addGestureRecognizer:longPress];

    [button updateForState:YTVOTCoordinator.sharedCoordinator.currentState];
    return button;
}

- (void)handleTap {
    [YTVOTCoordinator.sharedCoordinator toggleTranslation];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [feedback impactOccurred];

        UIViewController *presenter = [self topViewController];
        if (presenter) {
            YTVOTSettingsViewController *settingsVC = [[YTVOTSettingsViewController alloc] init];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
            nav.modalPresentationStyle = UIModalPresentationFormSheet;
            [presenter presentViewController:nav animated:YES completion:nil];
        }
    }
}

- (UIViewController * _Nullable)topViewController {
    UIWindow *window = self.window;
    if (!window) {
        if (@available(iOS 13.0, *)) {
            for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
                if ([s isKindOfClass:[UIWindowScene class]] && s.activationState == UISceneActivationStateForegroundActive) {
                    UIWindowScene *scene = (UIWindowScene *)s;
                    for (UIWindow *w in scene.windows) {
                        if (w.isKeyWindow) { window = w; break; }
                    }
                    if (window) break;
                }
            }
        }
    }
    if (!window) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        window = UIApplication.sharedApplication.keyWindow ?: UIApplication.sharedApplication.windows.firstObject;
#pragma clang diagnostic pop
    }
    UIViewController *top = window.rootViewController;
    while (top.presentedViewController) {
        top = top.presentedViewController;
    }
    return top;
}

- (void)updateForState:(YTVOTState)state {
    if (self.spinner) {
        [self.spinner stopAnimating];
        [self.spinner removeFromSuperview];
        self.spinner = nil;
    }

    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18.0 weight:UIImageSymbolWeightRegular];
        UIImage *img = nil;
        UIColor *tint = UIColor.whiteColor;

        switch (state) {
            case YTVOTStateRequesting:
            case YTVOTStateWaiting: {
                img = [UIImage systemImageNamed:@"waveform" withConfiguration:config];
                tint = [UIColor colorWithRed:1.0 green:0.8 blue:0.2 alpha:1.0]; // Yellow

                UIActivityIndicatorView *spin = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
                spin.center = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
                spin.color = tint;
                [spin startAnimating];
                [self addSubview:spin];
                self.spinner = spin;
                break;
            }
            case YTVOTStatePlaying:
            case YTVOTStatePaused:
                img = [UIImage systemImageNamed:@"waveform" withConfiguration:config];
                tint = [UIColor colorWithRed:0.25 green:0.85 blue:0.45 alpha:1.0]; // Vibrant green
                break;
            case YTVOTStateError:
                img = [UIImage systemImageNamed:@"waveform.badge.exclamationmark" withConfiguration:config];
                if (!img) img = [UIImage systemImageNamed:@"exclamationmark.circle" withConfiguration:config];
                tint = [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0]; // Red
                break;
            case YTVOTStateIdle:
            default:
                img = [UIImage systemImageNamed:@"waveform.badge.magnifyingglass" withConfiguration:config];
                if (!img) img = [UIImage systemImageNamed:@"globe" withConfiguration:config];
                tint = [UIColor colorWithWhite:1.0 alpha:0.85];
                break;
        }

        [self setImage:[img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.tintColor = tint;
    } else {
        [self setTitle:@"VOT" forState:UIControlStateNormal];
        self.tintColor = UIColor.whiteColor;
    }
}

@end
