#import "YTVOTSettingsViewController.h"
#import "YTVOTPreferences.h"
#import "YTVOTLocalization.h"
#import "YTVOTClient.h"
#import "YTVOTNotice.h"
#import "YTVOTYandexAuthViewController.h"

@interface YTVOTSettingsViewController ()
@property (nonatomic, strong) YTVOTPreferences *prefs;
@end

@implementation YTVOTSettingsViewController

+ (void)presentFromViewController:(UIViewController *)presentingVC {
    YTVOTSettingsViewController *settingsVC = [[YTVOTSettingsViewController alloc] initWithStyle:UITableViewStyleInsetGrouped];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [presentingVC presentViewController:nav animated:YES completion:nil];
}

- (instancetype)init {
    return [self initWithStyle:UITableViewStyleInsetGrouped];
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        _prefs = [YTVOTPreferences sharedPreferences];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = YTVOTLocalized(@"YTVOT Settings");

    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDone)];
    self.navigationItem.rightBarButtonItem = doneBtn;
}

- (void)handleDone {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 2; // Enable, Auto-translate
        case 1: return 3; // Adaptive ducking, Translation volume, Original volume
        case 2: return 2; // Target language, Voice type
        case 3: return 2; // Account status, Login/Logout
        case 4: return 1; // Clear cache
        case 5: return 2; // Version, Author
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return YTVOTLocalized(@"General");
        case 1: return YTVOTLocalized(@"Audio Controls");
        case 2: return YTVOTLocalized(@"Language & Voice");
        case 3: return YTVOTLocalized(@"Yandex Account");
        case 4: return YTVOTLocalized(@"Storage");
        case 5: return YTVOTLocalized(@"About");
        default: return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return YTVOTLocalized(@"Adaptive ducking subtitle");
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseID = [NSString stringWithFormat:@"YTVOTCell_%ld_%ld", (long)indexPath.section, (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseID];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;

    if (indexPath.section == 0) {
        UISwitch *toggle = [[UISwitch alloc] init];
        cell.accessoryView = toggle;
        if (indexPath.row == 0) {
            cell.textLabel.text = YTVOTLocalized(@"Enable Voice-Over");
            toggle.on = self.prefs.enabled;
            [toggle addTarget:self action:@selector(handleEnableToggled:) forControlEvents:UIControlEventValueChanged];
        } else {
            cell.textLabel.text = YTVOTLocalized(@"Auto-translate on play");
            toggle.on = self.prefs.autoTranslate;
            [toggle addTarget:self action:@selector(handleAutoTranslateToggled:) forControlEvents:UIControlEventValueChanged];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = YTVOTLocalized(@"Adaptive ducking");
            UISwitch *toggle = [[UISwitch alloc] init];
            toggle.on = self.prefs.adaptiveDucking;
            [toggle addTarget:self action:@selector(handleAdaptiveDuckingToggled:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = toggle;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d%%)", YTVOTLocalized(@"Translation volume"), (int)(self.prefs.translationVolume * 100)];
            UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 140, 30)];
            slider.minimumValue = 0.05f;
            slider.maximumValue = 1.0f;
            slider.value = self.prefs.translationVolume;
            slider.tag = 101;
            [slider addTarget:self action:@selector(handleTransVolumeChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = slider;
        } else if (indexPath.row == 2) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d%%)", YTVOTLocalized(@"Original video volume"), (int)(self.prefs.backgroundVolume * 100)];
            UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 140, 30)];
            slider.minimumValue = 0.0f;
            slider.maximumValue = 1.0f;
            slider.value = self.prefs.backgroundVolume;
            slider.tag = 102;
            [slider addTarget:self action:@selector(handleBgVolumeChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = slider;
        }
    } else if (indexPath.section == 2) {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (indexPath.row == 0) {
            cell.textLabel.text = YTVOTLocalized(@"Target Language");
            NSString *target = self.prefs.targetLanguage;
            if ([target isEqualToString:@"en"]) cell.detailTextLabel.text = @"English";
            else if ([target isEqualToString:@"kk"]) cell.detailTextLabel.text = @"Қазақша";
            else cell.detailTextLabel.text = @"Русский";
        } else {
            cell.textLabel.text = YTVOTLocalized(@"Voice Type");
            NSString *v = self.prefs.voice;
            if ([v isEqualToString:@"female"]) cell.detailTextLabel.text = YTVOTLocalized(@"Female voice");
            else if ([v isEqualToString:@"male"]) cell.detailTextLabel.text = YTVOTLocalized(@"Male voice");
            else cell.detailTextLabel.text = YTVOTLocalized(@"Any voice");
        }
    } else if (indexPath.section == 3) {
        if (indexPath.row == 0) {
            cell.textLabel.text = YTVOTLocalized(@"Status");
            BOOL auth = [YTVOTClient isYandexAuthorized];
            cell.detailTextLabel.text = auth ? ([NSString stringWithFormat:@"%@ (%@)", YTVOTLocalized(@"Authorized"), [YTVOTClient currentYandexLogin] ?: @""]) : YTVOTLocalized(@"Not authorized");
            cell.detailTextLabel.textColor = auth ? [UIColor colorWithRed:0.2 green:0.7 blue:0.3 alpha:1.0] : UIColor.secondaryLabelColor;
        } else {
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            BOOL auth = [YTVOTClient isYandexAuthorized];
            cell.textLabel.text = auth ? YTVOTLocalized(@"Log Out") : YTVOTLocalized(@"Log In with Yandex");
            cell.textLabel.textColor = auth ? UIColor.systemRedColor : UIColor.systemBlueColor;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else if (indexPath.section == 4) {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.textLabel.text = YTVOTLocalized(@"Clear Cache");
        cell.textLabel.textColor = UIColor.systemRedColor;
    } else if (indexPath.section == 5) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"YTVOT";
            cell.detailTextLabel.text = YTVOT_VERSION;
        } else {
            cell.textLabel.text = @"Developer";
            cell.detailTextLabel.text = @"Amizx2";
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            [self showLanguagePicker];
        } else {
            [self showVoicePicker];
        }
    } else if (indexPath.section == 3 && indexPath.row == 1) {
        if ([YTVOTClient isYandexAuthorized]) {
            [YTVOTClient logoutYandex];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationAutomatic];
            YTVOTShowNotice(YTVOTLocalized(@"Logged Out"));
        } else {
            [YTVOTYandexAuthViewController presentFromViewController:self completion:^(BOOL success, NSString * _Nullable login, NSString * _Nullable errorMessage) {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationAutomatic];
                if (success) {
                    YTVOTShowNotice([NSString stringWithFormat:@"%@: %@", YTVOTLocalized(@"Authorized"), login ?: @""]);
                } else if (errorMessage) {
                    YTVOTShowNotice(errorMessage);
                }
            }];
        }
    } else if (indexPath.section == 4 && indexPath.row == 0) {
        [[YTVOTClient sharedClient] clearCache];
        YTVOTShowNotice(YTVOTLocalized(@"Cache cleared"));
    }
}

#pragma mark - Actions

- (void)handleEnableToggled:(UISwitch *)sender {
    self.prefs.enabled = sender.isOn;
}

- (void)handleAutoTranslateToggled:(UISwitch *)sender {
    self.prefs.autoTranslate = sender.isOn;
}

- (void)handleAdaptiveDuckingToggled:(UISwitch *)sender {
    self.prefs.adaptiveDucking = sender.isOn;
}

- (void)handleTransVolumeChanged:(UISlider *)sender {
    self.prefs.translationVolume = sender.value;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d%%)", YTVOTLocalized(@"Translation volume"), (int)(sender.value * 100)];
}

- (void)handleBgVolumeChanged:(UISlider *)sender {
    self.prefs.backgroundVolume = sender.value;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d%%)", YTVOTLocalized(@"Original video volume"), (int)(sender.value * 100)];
}

- (void)showLanguagePicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:YTVOTLocalized(@"Target Language") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Русский (RU)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.prefs.targetLanguage = @"ru";
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"English (EN)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.prefs.targetLanguage = @"en";
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Қазақша (KK)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.prefs.targetLanguage = @"kk";
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:YTVOTLocalized(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showVoicePicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:YTVOTLocalized(@"Voice Type") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:YTVOTLocalized(@"Any voice") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.prefs.voice = @"any";
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:YTVOTLocalized(@"Female voice") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.prefs.voice = @"female";
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:YTVOTLocalized(@"Male voice") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.prefs.voice = @"male";
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:YTVOTLocalized(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
