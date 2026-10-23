#pragma once

#import <Foundation/Foundation.h>
#import "YTVOTDefines.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const YTVOTPreferencesDidChangeNotification;

@interface YTVOTPreferences : NSObject

+ (instancetype)sharedPreferences;

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL autoTranslate;
@property (nonatomic, assign) BOOL adaptiveDucking;
@property (nonatomic, assign) float translationVolume; // 0.0 - 1.0 (default 1.0)
@property (nonatomic, assign) float backgroundVolume;  // 0.0 - 1.0 (default 0.25)
@property (nonatomic, copy) NSString *voice;           // @"any", @"female", @"male"
@property (nonatomic, copy) NSString *targetLanguage;  // @"ru", @"en", @"kk"
@property (nonatomic, copy, nullable) NSString *yandexToken;
@property (nonatomic, assign) YTVOTButtonPlacement buttonPlacement;

- (void)resetToDefaults;

@end

NS_ASSUME_NONNULL_END
