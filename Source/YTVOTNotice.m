#import "YTVOTNotice.h"

static const NSInteger kYTVOTNoticeTag = 0x59564F54; // 'YVOT'

void YTVOTShowNotice(NSString *message) {
    if (message.length == 0) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = nil;
        for (UIWindow *w in UIApplication.sharedApplication.windows) {
            if (w.isKeyWindow) {
                keyWindow = w;
                break;
            }
        }
        if (!keyWindow) {
            keyWindow = UIApplication.sharedApplication.windows.firstObject;
        }
        if (!keyWindow) return;

        UIView *oldNotice = [keyWindow viewWithTag:kYTVOTNoticeTag];
        if (oldNotice) {
            [oldNotice removeFromSuperview];
        }

        UIView *pill = [[UIView alloc] init];
        pill.tag = kYTVOTNoticeTag;
        pill.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.92];
        pill.layer.cornerRadius = 16.0;
        pill.layer.masksToBounds = YES;
        pill.layer.borderWidth = 0.5;
        pill.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
        pill.translatesAutoresizingMaskIntoConstraints = NO;
        pill.alpha = 0.0;

        UILabel *label = [[UILabel alloc] init];
        label.text = message;
        label.textColor = UIColor.whiteColor;
        label.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [pill addSubview:label];

        [keyWindow addSubview:pill];

        UILayoutGuide *safe = keyWindow.safeAreaLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
            [pill.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
            [pill.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-60.0],
            [pill.widthAnchor greaterThanOrEqualToConstant:140.0],
            [pill.widthAnchor lessThanOrEqualToAnchor:safe.widthAnchor constant:-40.0],
            [label.topAnchor constraintEqualToAnchor:pill.topAnchor constant:10.0],
            [label.bottomAnchor constraintEqualToAnchor:pill.bottomAnchor constant:-10.0],
            [label.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:16.0],
            [label.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-16.0]
        ]];

        [UIView animateWithDuration:0.25 animations:^{
            pill.alpha = 1.0;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3 animations:^{
                    pill.alpha = 0.0;
                } completion:^(BOOL finished) {
                    [pill removeFromSuperview];
                }];
            });
        }];
    });
}
