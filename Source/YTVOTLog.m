#import "YTVOTLog.h"
#import <os/log.h>

void YTVOTLog(NSString *category, NSString *format, ...) {
#if DEBUG
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    if (@available(iOS 10.0, *)) {
        static os_log_t logSubsystem;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            logSubsystem = os_log_create("com.amizx2.ytvot", "General");
        });
        os_log(logSubsystem, "[YTVOT][%{public}@] %{public}@", category ?: @"Core", message);
    } else {
        NSLog(@"[YTVOT][%@] %@", category ?: @"Core", message);
    }
#else
    (void)category;
    (void)format;
#endif
}

void YTVOTLogAlways(NSString *category, NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    if (@available(iOS 10.0, *)) {
        static os_log_t logSubsystem;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            logSubsystem = os_log_create("com.amizx2.ytvot", "General");
        });
        os_log(logSubsystem, "[YTVOT][%{public}@] %{public}@", category ?: @"Core", message);
    } else {
        NSLog(@"[YTVOT][%@] %@", category ?: @"Core", message);
    }
}
