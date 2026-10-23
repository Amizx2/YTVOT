#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YTVOTStatus) {
    YTVOTStatusFailed = 0,
    YTVOTStatusFinished = 1,
    YTVOTStatusWaiting = 2,
    YTVOTStatusLongWaiting = 3,
    YTVOTStatusPartContent = 5,
    YTVOTStatusAudioRequested = 6,
    YTVOTStatusSessionRequired = 7
};

@interface YTVOTResponse : NSObject
@property (nonatomic, copy, nullable) NSString *audioURL;
@property (nonatomic, assign) YTVOTStatus status;
@property (nonatomic, assign) NSInteger remainingTime;
@property (nonatomic, copy, nullable) NSString *translationID;
@property (nonatomic, copy, nullable) NSString *detectedLanguage;
@property (nonatomic, copy, nullable) NSString *message;
@end

typedef void (^YTVOTCompletion)(YTVOTResponse * _Nullable response, NSError * _Nullable error);
typedef YTVOTCompletion YTVOTClientCompletion;

@interface YTVOTClient : NSObject

+ (instancetype)sharedClient;

+ (nullable NSString *)currentYandexToken;
+ (nullable NSString *)currentYandexLogin;
+ (BOOL)isYandexAuthorized;
+ (void)logoutYandex;
+ (nullable NSString *)cleanOAuthToken:(NSString *)rawInput;
+ (void)validateAndSaveToken:(NSString *)rawToken
                  completion:(void (^)(BOOL success, NSString * _Nullable login, NSString * _Nullable errorMessage))completion;

- (void)requestTranslationForVideoID:(NSString *)videoID
                            duration:(double)duration
                          sourceLang:(NSString * _Nullable)sourceLang
                          targetLang:(NSString * _Nullable)targetLang
                           voiceType:(NSString * _Nullable)voiceType
                          completion:(YTVOTClientCompletion)completion;

- (void)clearCache;

@end

NS_ASSUME_NONNULL_END
