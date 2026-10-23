#import "YTVOTPreferences.h"

NSString * const YTVOTPreferencesDidChangeNotification = @"YTVOTPreferencesDidChangeNotification";

static NSString * const kPrefEnabled = @"YTVOT.Enabled";
static NSString * const kPrefAutoTranslate = @"YTVOT.AutoTranslate";
static NSString * const kPrefAdaptiveDucking = @"YTVOT.AdaptiveDucking";
static NSString * const kPrefTranslationVolume = @"YTVOT.TranslationVolume";
static NSString * const kPrefBackgroundVolume = @"YTVOT.BackgroundVolume";
static NSString * const kPrefVoice = @"YTVOT.Voice";
static NSString * const kPrefTargetLanguage = @"YTVOT.TargetLanguage";
static NSString * const kPrefYandexToken = @"YTVOT.YandexToken";
static NSString * const kPrefButtonPlacement = @"YTVOT.ButtonPlacement";

@interface YTVOTPreferences ()
@property (nonatomic, strong) NSUserDefaults *defaults;
@end

@implementation YTVOTPreferences

+ (instancetype)sharedPreferences {
    static YTVOTPreferences *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[YTVOTPreferences alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _defaults = [[NSUserDefaults alloc] initWithSuiteName:YTVOT_BUNDLE_ID] ?: [NSUserDefaults standardUserDefaults];
        [self registerDefaults];
    }
    return self;
}

- (void)registerDefaults {
    NSDictionary *defaultsDict = @{
        kPrefEnabled: @YES,
        kPrefAutoTranslate: @NO,
        kPrefAdaptiveDucking: @YES,
        kPrefTranslationVolume: @(1.0f),
        kPrefBackgroundVolume: @(0.25f),
        kPrefVoice: @"any",
        kPrefTargetLanguage: @"ru",
        kPrefButtonPlacement: @(YTVOTButtonPlacementOverlay)
    };
    [self.defaults registerDefaults:defaultsDict];
}

- (void)postChangeNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:YTVOTPreferencesDidChangeNotification object:self];
    });
}

#pragma mark - Getters / Setters

- (BOOL)enabled {
    return [self.defaults boolForKey:kPrefEnabled];
}

- (void)setEnabled:(BOOL)enabled {
    [self.defaults setBool:enabled forKey:kPrefEnabled];
    [self postChangeNotification];
}

- (BOOL)autoTranslate {
    return [self.defaults boolForKey:kPrefAutoTranslate];
}

- (void)setAutoTranslate:(BOOL)autoTranslate {
    [self.defaults setBool:autoTranslate forKey:kPrefAutoTranslate];
    [self postChangeNotification];
}

- (BOOL)adaptiveDucking {
    return [self.defaults boolForKey:kPrefAdaptiveDucking];
}

- (void)setAdaptiveDucking:(BOOL)adaptiveDucking {
    [self.defaults setBool:adaptiveDucking forKey:kPrefAdaptiveDucking];
    [self postChangeNotification];
}

- (float)translationVolume {
    float val = [self.defaults floatForKey:kPrefTranslationVolume];
    return (val <= 0.0f) ? 1.0f : val;
}

- (void)setTranslationVolume:(float)translationVolume {
    [self.defaults setFloat:translationVolume forKey:kPrefTranslationVolume];
    [self postChangeNotification];
}

- (float)backgroundVolume {
    float val = [self.defaults floatForKey:kPrefBackgroundVolume];
    return (val <= 0.0f) ? 0.25f : val;
}

- (void)setBackgroundVolume:(float)backgroundVolume {
    [self.defaults setFloat:backgroundVolume forKey:kPrefBackgroundVolume];
    [self postChangeNotification];
}

- (NSString *)voice {
    return [self.defaults stringForKey:kPrefVoice] ?: @"any";
}

- (void)setVoice:(NSString *)voice {
    [self.defaults setObject:voice ?: @"any" forKey:kPrefVoice];
    [self postChangeNotification];
}

- (NSString *)targetLanguage {
    return [self.defaults stringForKey:kPrefTargetLanguage] ?: @"ru";
}

- (void)setTargetLanguage:(NSString *)targetLanguage {
    [self.defaults setObject:targetLanguage ?: @"ru" forKey:kPrefTargetLanguage];
    [self postChangeNotification];
}

- (NSString *)yandexToken {
    return [self.defaults stringForKey:kPrefYandexToken];
}

- (void)setYandexToken:(NSString *)yandexToken {
    if (yandexToken.length > 0) {
        [self.defaults setObject:yandexToken forKey:kPrefYandexToken];
    } else {
        [self.defaults removeObjectForKey:kPrefYandexToken];
    }
    [self postChangeNotification];
}

- (YTVOTButtonPlacement)buttonPlacement {
    return (YTVOTButtonPlacement)[self.defaults integerForKey:kPrefButtonPlacement];
}

- (void)setButtonPlacement:(YTVOTButtonPlacement)buttonPlacement {
    [self.defaults setInteger:buttonPlacement forKey:kPrefButtonPlacement];
    [self postChangeNotification];
}

- (void)resetToDefaults {
    [self.defaults removeObjectForKey:kPrefEnabled];
    [self.defaults removeObjectForKey:kPrefAutoTranslate];
    [self.defaults removeObjectForKey:kPrefAdaptiveDucking];
    [self.defaults removeObjectForKey:kPrefTranslationVolume];
    [self.defaults removeObjectForKey:kPrefBackgroundVolume];
    [self.defaults removeObjectForKey:kPrefVoice];
    [self.defaults removeObjectForKey:kPrefTargetLanguage];
    [self.defaults removeObjectForKey:kPrefButtonPlacement];
    [self registerDefaults];
    [self postChangeNotification];
}

@end
