#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void YTVOTLog(NSString *category, NSString *format, ...) NS_FORMAT_FUNCTION(2, 3);
FOUNDATION_EXPORT void YTVOTLogAlways(NSString *category, NSString *format, ...) NS_FORMAT_FUNCTION(2, 3);

NS_ASSUME_NONNULL_END
