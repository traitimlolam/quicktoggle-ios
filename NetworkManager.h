#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NetworkManager : NSObject

+ (instancetype)sharedManager;

- (BOOL)isWiFiEnabled;
- (BOOL)setWiFiEnabled:(BOOL)enabled;

- (BOOL)isCellularEnabled;
- (BOOL)setCellularEnabled:(BOOL)enabled;

- (void)openWiFiSettings;
- (void)openCellularSettings;
- (void)openHotspotSettings;

@end

NS_ASSUME_NONNULL_END
