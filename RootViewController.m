#import "RootViewController.h"
#import "NetworkManager.h"
#import <AudioToolbox/AudioToolbox.h>

@interface RootViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;

// Wi-Fi Card
@property (nonatomic, strong) UIView *wifiCard;
@property (nonatomic, strong) UILabel *wifiStatusLabel;
@property (nonatomic, strong) UISwitch *wifiSwitch;

// Cellular Card
@property (nonatomic, strong) UIView *cellCard;
@property (nonatomic, strong) UILabel *cellStatusLabel;
@property (nonatomic, strong) UISwitch *cellSwitch;

// Preset Card
@property (nonatomic, strong) UIView *presetCard;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.title = @"Bật Tắt Mạng VN";
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];
    
    [self setupUI];
    [self refreshStates];
    
    // Auto-refresh when app becomes active
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshStates)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)triggerFeedback {
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [gen prepare];
        [gen impactOccurred];
    }
}

- (void)setupUI {
    CGFloat w = self.view.bounds.size.width - 32;
    CGFloat y = 20;
    
    // 1. Header Banner
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(16, y, w, 70)];
    header.backgroundColor = [UIColor colorWithRed:0.06 green:0.09 blue:0.16 alpha:1.0];
    header.layer.cornerRadius = 16;
    [self.scrollView addSubview:header];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, w - 32, 24)];
    titleLabel.text = @"⚡ ĐIỀU KHIỂN MẠNG 1 CHẠM";
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textColor = [UIColor whiteColor];
    [header addSubview:titleLabel];
    
    UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 36, w - 32, 20)];
    subLabel.text = @"Bật/Tắt trực tiếp Wi-Fi & 3G/4G không cần vào Cài Đặt";
    subLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    subLabel.textColor = [UIColor colorWithRed:0.58 green:0.64 blue:0.72 alpha:1.0];
    [header addSubview:subLabel];
    
    y += 82;
    
    // 2. Wi-Fi Card
    self.wifiCard = [[UIView alloc] initWithFrame:CGRectMake(16, y, w, 110)];
    self.wifiCard.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    self.wifiCard.layer.cornerRadius = 18;
    self.wifiCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.wifiCard.layer.shadowOpacity = 0.06;
    self.wifiCard.layer.shadowOffset = CGSizeMake(0, 3);
    self.wifiCard.layer.shadowRadius = 8;
    [self.scrollView addSubview:self.wifiCard];
    
    UILabel *wifiIcon = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, 36, 36)];
    wifiIcon.text = @"📶";
    wifiIcon.font = [UIFont systemFontOfSize:26];
    [self.wifiCard addSubview:wifiIcon];
    
    UILabel *wifiTitle = [[UILabel alloc] initWithFrame:CGRectMake(60, 16, 180, 22)];
    wifiTitle.text = @"Mạng Wi-Fi";
    wifiTitle.font = [UIFont boldSystemFontOfSize:16];
    [self.wifiCard addSubview:wifiTitle];
    
    self.wifiStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 38, 180, 18)];
    self.wifiStatusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [self.wifiCard addSubview:self.wifiStatusLabel];
    
    self.wifiSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(w - 68, 22, 51, 31)];
    [self.wifiSwitch addTarget:self action:@selector(wifiSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.wifiCard addSubview:self.wifiSwitch];
    
    UIButton *wifiSetBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    wifiSetBtn.frame = CGRectMake(16, 68, w - 32, 32);
    [wifiSetBtn setTitle:@"⚙️ Mở Cài Đặt Wi-Fi Chi Tiết" forState:UIControlStateNormal];
    wifiSetBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    wifiSetBtn.backgroundColor = [UIColor tertiarySystemFillColor];
    wifiSetBtn.layer.cornerRadius = 8;
    [wifiSetBtn addTarget:self action:@selector(openWiFiSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.wifiCard addSubview:wifiSetBtn];
    
    y += 122;
    
    // 3. Cellular Card
    self.cellCard = [[UIView alloc] initWithFrame:CGRectMake(16, y, w, 110)];
    self.cellCard.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    self.cellCard.layer.cornerRadius = 18;
    self.cellCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cellCard.layer.shadowOpacity = 0.06;
    self.cellCard.layer.shadowOffset = CGSizeMake(0, 3);
    self.cellCard.layer.shadowRadius = 8;
    [self.scrollView addSubview:self.cellCard];
    
    UILabel *cellIcon = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, 36, 36)];
    cellIcon.text = @"📡";
    cellIcon.font = [UIFont systemFontOfSize:26];
    [self.cellCard addSubview:cellIcon];
    
    UILabel *cellTitle = [[UILabel alloc] initWithFrame:CGRectMake(60, 16, 180, 22)];
    cellTitle.text = @"Dữ Liệu Di Động (3G/4G)";
    cellTitle.font = [UIFont boldSystemFontOfSize:16];
    [self.cellCard addSubview:cellTitle];
    
    self.cellStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 38, 180, 18)];
    self.cellStatusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [self.cellCard addSubview:self.cellStatusLabel];
    
    self.cellSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(w - 68, 22, 51, 31)];
    [self.cellSwitch addTarget:self action:@selector(cellSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.cellCard addSubview:self.cellSwitch];
    
    UIButton *cellSetBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    cellSetBtn.frame = CGRectMake(16, 68, w - 32, 32);
    [cellSetBtn setTitle:@"⚙️ Mở Cài Đặt Di Động Chi Tiết" forState:UIControlStateNormal];
    cellSetBtn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    cellSetBtn.backgroundColor = [UIColor tertiarySystemFillColor];
    cellSetBtn.layer.cornerRadius = 8;
    [cellSetBtn addTarget:self action:@selector(openCellularSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.cellCard addSubview:cellSetBtn];
    
    y += 122;
    
    // 4. Quick Actions / Presets Card
    self.presetCard = [[UIView alloc] initWithFrame:CGRectMake(16, y, w, 175)];
    self.presetCard.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    self.presetCard.layer.cornerRadius = 18;
    self.presetCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.presetCard.layer.shadowOpacity = 0.06;
    self.presetCard.layer.shadowOffset = CGSizeMake(0, 3);
    self.presetCard.layer.shadowRadius = 8;
    [self.scrollView addSubview:self.presetCard];
    
    UILabel *pTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, w - 32, 22)];
    pTitle.text = @"⚡ Chế Độ Chuyển Đổi Nhanh";
    pTitle.font = [UIFont boldSystemFontOfSize:15];
    [self.presetCard addSubview:pTitle];
    
    UIButton *b1 = [self createActionButtonWithTitle:@"📶 Chỉ Dùng Wi-Fi (Tắt 4G Tiết Kiệm)" action:@selector(modeOnlyWiFi) color:[UIColor systemTealColor] frame:CGRectMake(16, 42, w - 32, 36)];
    [self.presetCard addSubview:b1];
    
    UIButton *b2 = [self createActionButtonWithTitle:@"📡 Chỉ Dùng 4G (Tắt Wi-Fi Ra Ngoài)" action:@selector(modeOnlyCellular) color:[UIColor systemGreenColor] frame:CGRectMake(16, 84, w - 32, 36)];
    [self.presetCard addSubview:b2];
    
    UIButton *b3 = [self createActionButtonWithTitle:@"🌐 Mở Điểm Phát Sóng Cá Nhân (Hotspot)" action:@selector(openHotspot) color:[UIColor systemOrangeColor] frame:CGRectMake(16, 126, w - 32, 36)];
    [self.presetCard addSubview:b3];
    
    y += 190;
    
    // Footer
    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(16, y, w, 40)];
    footer.numberOfLines = 2;
    footer.textAlignment = NSTextAlignmentCenter;
    footer.text = @"Dành riêng cho iPhone Sếp Hiếu • iOS 16\nNhấn để điều khiển Wi-Fi & 3G/4G tức thì";
    footer.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    footer.textColor = [UIColor secondaryLabelColor];
    [self.scrollView addSubview:footer];
    
    y += 60;
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, y);
}

- (UIButton *)createActionButtonWithTitle:(NSString *)title action:(SEL)sel color:(UIColor *)col frame:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    btn.layer.cornerRadius = 10;
    btn.backgroundColor = [col colorWithAlphaComponent:0.15];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:col forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [btn addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)refreshStates {
    BOOL wifi = [[NetworkManager sharedManager] isWiFiEnabled];
    self.wifiSwitch.on = wifi;
    if (wifi) {
        self.wifiStatusLabel.text = @"🟢 Đang BẬT";
        self.wifiStatusLabel.textColor = [UIColor systemGreenColor];
    } else {
        self.wifiStatusLabel.text = @"⚪ Đang TẮT";
        self.wifiStatusLabel.textColor = [UIColor secondaryLabelColor];
    }
    
    BOOL cell = [[NetworkManager sharedManager] isCellularEnabled];
    self.cellSwitch.on = cell;
    if (cell) {
        self.cellStatusLabel.text = @"🟢 Đang BẬT";
        self.cellStatusLabel.textColor = [UIColor systemGreenColor];
    } else {
        self.cellStatusLabel.text = @"⚪ Đang TẮT";
        self.cellStatusLabel.textColor = [UIColor secondaryLabelColor];
    }
}

- (void)wifiSwitchChanged:(UISwitch *)sender {
    [self triggerFeedback];
    BOOL res = [[NetworkManager sharedManager] setWiFiEnabled:sender.on];
    if (!res) {
        // Fallback open settings
        [[NetworkManager sharedManager] openWiFiSettings];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshStates];
    });
}

- (void)cellSwitchChanged:(UISwitch *)sender {
    [self triggerFeedback];
    BOOL res = [[NetworkManager sharedManager] setCellularEnabled:sender.on];
    if (!res) {
        // Fallback open settings
        [[NetworkManager sharedManager] openCellularSettings];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshStates];
    });
}

- (void)modeOnlyWiFi {
    [self triggerFeedback];
    [[NetworkManager sharedManager] setWiFiEnabled:YES];
    [[NetworkManager sharedManager] setCellularEnabled:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshStates];
    });
}

- (void)modeOnlyCellular {
    [self triggerFeedback];
    [[NetworkManager sharedManager] setWiFiEnabled:NO];
    [[NetworkManager sharedManager] setCellularEnabled:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshStates];
    });
}

- (void)openWiFiSettings {
    [self triggerFeedback];
    [[NetworkManager sharedManager] openWiFiSettings];
}

- (void)openCellularSettings {
    [self triggerFeedback];
    [[NetworkManager sharedManager] openCellularSettings];
}

- (void)openHotspot {
    [self triggerFeedback];
    [[NetworkManager sharedManager] openHotspotSettings];
}

@end
