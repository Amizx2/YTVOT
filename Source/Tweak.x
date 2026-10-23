#import "YTVOTHooks.h"
#import "YTVOTLog.h"

%ctor {
    @autoreleasepool {
        YTVOTLogAlways(@"Loader", @"Loading YTVOT standalone tweak...");
        YTVOTInstallHooks();
    }
}
