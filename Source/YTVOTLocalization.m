#import "YTVOTLocalization.h"

NSString *YTVOTLocalized(NSString *key) {
    if (key.length == 0) return @"";
    static NSDictionary *ruDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ruDict = @{
            @"No active video": @"Нет активного видео",
            @"Translating...": @"Перевод запрашивается...",
            @"Translation ready": @"Перевод готов",
            @"Voice-over active": @"Голосовой перевод включен",
            @"Translation failed": @"Ошибка перевода",
            @"Invalid audio link": @"Некорректная ссылка на аудио",
            @"Wait %ld sec...": @"Ожидание: %ld сек...",
            @"Yandex account required for this video": @"Требуется авторизация в Яндекс",
            @"Translation unavailable": @"Перевод недоступен для этого видео",
            @"Voice-Over Translation": @"Голосовой перевод",
            @"Disable Translation": @"Отключить перевод",
            @"YTVOT Settings": @"Настройки перевода (YTVOT)",
            @"Enable Voice-Over": @"Включить голосовой перевод",
            @"Auto-translate on play": @"Автоперевод при запуске видео",
            @"Adaptive ducking": @"Умное приглушение оригинала",
            @"Adaptive ducking subtitle": @"Приглушает оригинальное видео только во время речи перевода",
            @"Translation volume": @"Громкость перевода",
            @"Original video volume": @"Громкость оригинала",
            @"Target Language": @"Язык перевода",
            @"Voice Type": @"Голос озвучки",
            @"Any voice": @"Автоматически",
            @"Female voice": @"Женский",
            @"Male voice": @"Мужской",
            @"Yandex Account": @"Аккаунт Яндекс",
            @"Authorized": @"Авторизован",
            @"Not authorized": @"Не авторизован",
            @"Log Out": @"Выйти",
            @"Log In with Yandex": @"Войти через Яндекс",
            @"Clear Cache": @"Очистить кэш переводов",
            @"Cache cleared": @"Кэш очищен",
            @"Close": @"Закрыть",
            @"Done": @"Готово"
        };
    });

    NSString *preferred = NSLocale.preferredLanguages.firstObject.lowercaseString;
    if ([preferred hasPrefix:@"ru"] || [preferred hasPrefix:@"be"] || [preferred hasPrefix:@"uk"] || [preferred hasPrefix:@"kk"]) {
        NSString *translated = ruDict[key];
        if (translated) return translated;
    }
    return key;
}
