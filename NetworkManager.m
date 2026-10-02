#import "NetworkManager.h"
#import <dlfcn.h>

// MobileWiFi function signatures
typedef struct __WiFiManagerClient *WiFiManagerRef;
typedef struct __WiFiDeviceClient *WiFiDeviceClientRef;

typedef WiFiManagerRef (*WiFiManagerClientCreateFunc)(CFAllocatorRef allocator, int flags);
typedef CFArrayRef (*WiFiManagerClientCopyDevicesFunc)(WiFiManagerRef manager);
typedef int (*WiFiDeviceClientGetPowerFunc)(WiFiDeviceClientRef device);
typedef void (*WiFiDeviceClientSetPowerFunc)(WiFiDeviceClientRef device, int power);
typedef void (*WiFiManagerClientSetPropertyFunc)(WiFiManagerRef manager, CFStringRef property, CFPropertyListRef value);

// CoreTelephony function signatures
typedef struct __CTServerConnection CTServerConnection;
typedef CTServerConnection *(*CTServerConnectionCreateFunc)(CFAllocatorRef allocator, void *callback, void *context);
typedef int (*CTServerConnectionGetCellularDataIsEnabledFunc)(CTServerConnection *connection, bool *enabled);
typedef int (*CTServerConnectionSetCellularDataIsEnabledFunc)(CTServerConnection *connection, bool enabled);

@interface NetworkManager () {
    void *_mobileWiFiHandle;
    void *_coreTelephonyHandle;
    
    WiFiManagerClientCreateFunc _WiFiManagerClientCreate;
    WiFiManagerClientCopyDevicesFunc _WiFiManagerClientCopyDevices;
    WiFiDeviceClientGetPowerFunc _WiFiDeviceClientGetPower;
    WiFiDeviceClientSetPowerFunc _WiFiDeviceClientSetPower;
    WiFiManagerClientSetPropertyFunc _WiFiManagerClientSetProperty;
    
    CTServerConnectionCreateFunc _CTServerConnectionCreate;
    CTServerConnectionGetCellularDataIsEnabledFunc _CTServerConnectionGetCellularDataIsEnabled;
    CTServerConnectionSetCellularDataIsEnabledFunc _CTServerConnectionSetCellularDataIsEnabled;
}
@end

@implementation NetworkManager

+ (instancetype)sharedManager {
    static NetworkManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NetworkManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadSymbols];
    }
    return self;
}

- (void)loadSymbols {
    // 1. MobileWiFi
    self->_mobileWiFiHandle = dlopen("/System/Library/PrivateFrameworks/MobileWiFi.framework/MobileWiFi", RTLD_LAZY | RTLD_GLOBAL);
    if (self->_mobileWiFiHandle) {
        self->_WiFiManagerClientCreate = (WiFiManagerClientCreateFunc)dlsym(self->_mobileWiFiHandle, "WiFiManagerClientCreate");
        self->_WiFiManagerClientCopyDevices = (WiFiManagerClientCopyDevicesFunc)dlsym(self->_mobileWiFiHandle, "WiFiManagerClientCopyDevices");
        self->_WiFiDeviceClientGetPower = (WiFiDeviceClientGetPowerFunc)dlsym(self->_mobileWiFiHandle, "WiFiDeviceClientGetPower");
        self->_WiFiDeviceClientSetPower = (WiFiDeviceClientSetPowerFunc)dlsym(self->_mobileWiFiHandle, "WiFiDeviceClientSetPower");
        self->_WiFiManagerClientSetProperty = (WiFiManagerClientSetPropertyFunc)dlsym(self->_mobileWiFiHandle, "WiFiManagerClientSetProperty");
    }
    
    // 2. CoreTelephony
    self->_coreTelephonyHandle = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY | RTLD_GLOBAL);
    if (self->_coreTelephonyHandle) {
        self->_CTServerConnectionCreate = (CTServerConnectionCreateFunc)dlsym(self->_coreTelephonyHandle, "_CTServerConnectionCreate");
        self->_CTServerConnectionGetCellularDataIsEnabled = (CTServerConnectionGetCellularDataIsEnabledFunc)dlsym(self->_coreTelephonyHandle, "_CTServerConnectionGetCellularDataIsEnabled");
        self->_CTServerConnectionSetCellularDataIsEnabled = (CTServerConnectionSetCellularDataIsEnabledFunc)dlsym(self->_coreTelephonyHandle, "_CTServerConnectionSetCellularDataIsEnabled");
    }
}

#pragma mark - WiFi

- (BOOL)isWiFiEnabled {
    if (self->_WiFiManagerClientCreate && self->_WiFiManagerClientCopyDevices && self->_WiFiDeviceClientGetPower) {
        WiFiManagerRef mgr = self->_WiFiManagerClientCreate(kCFAllocatorDefault, 0);
        if (mgr) {
            CFArrayRef devices = self->_WiFiManagerClientCopyDevices(mgr);
            if (devices && CFArrayGetCount(devices) > 0) {
                WiFiDeviceClientRef client = (WiFiDeviceClientRef)CFArrayGetValueAtIndex(devices, 0);
                int power = self->_WiFiDeviceClientGetPower(client);
                CFRelease(devices);
                CFRelease(mgr);
                return (power != 0);
            }
            if (devices) CFRelease(devices);
            CFRelease(mgr);
        }
    }
    return NO;
}

- (BOOL)setWiFiEnabled:(BOOL)enabled {
    BOOL success = NO;
    if (self->_WiFiManagerClientCreate) {
        WiFiManagerRef mgr = self->_WiFiManagerClientCreate(kCFAllocatorDefault, 0);
        if (mgr) {
            if (self->_WiFiManagerClientCopyDevices && self->_WiFiDeviceClientSetPower) {
                CFArrayRef devices = self->_WiFiManagerClientCopyDevices(mgr);
                if (devices && CFArrayGetCount(devices) > 0) {
                    WiFiDeviceClientRef client = (WiFiDeviceClientRef)CFArrayGetValueAtIndex(devices, 0);
                    self->_WiFiDeviceClientSetPower(client, enabled ? 1 : 0);
                    success = YES;
                }
                if (devices) CFRelease(devices);
            }
            if (!success && self->_WiFiManagerClientSetProperty) {
                CFBooleanRef val = enabled ? kCFBooleanTrue : kCFBooleanFalse;
                self->_WiFiManagerClientSetProperty(mgr, CFSTR("AllowEnable"), val);
                success = YES;
            }
            CFRelease(mgr);
        }
    }
    return success;
}

#pragma mark - Cellular

- (BOOL)isCellularEnabled {
    if (self->_CTServerConnectionCreate && self->_CTServerConnectionGetCellularDataIsEnabled) {
        CTServerConnection *conn = self->_CTServerConnectionCreate(kCFAllocatorDefault, NULL, NULL);
        if (conn) {
            bool enabled = false;
            self->_CTServerConnectionGetCellularDataIsEnabled(conn, &enabled);
            CFRelease((CFTypeRef)conn);
            return enabled;
        }
    }
    return NO;
}

- (BOOL)setCellularEnabled:(BOOL)enabled {
    if (self->_CTServerConnectionCreate && self->_CTServerConnectionSetCellularDataIsEnabled) {
        CTServerConnection *conn = self->_CTServerConnectionCreate(kCFAllocatorDefault, NULL, NULL);
        if (conn) {
            self->_CTServerConnectionSetCellularDataIsEnabled(conn, enabled);
            CFRelease((CFTypeRef)conn);
            return YES;
        }
    }
    return NO;
}

#pragma mark - Open Settings Fallbacks

- (void)openURLString:(NSString *)str {
    NSURL *url = [NSURL URLWithString:str];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    } else {
        // Fallback with prefs:
        NSString *prefs = [str stringByReplacingOccurrencesOfString:@"App-Prefs:" withString:@"prefs:"];
        NSURL *pUrl = [NSURL URLWithString:prefs];
        [[UIApplication sharedApplication] openURL:pUrl options:@{} completionHandler:nil];
    }
}

- (void)openWiFiSettings {
    [self openURLString:@"App-Prefs:root=WIFI"];
}

- (void)openCellularSettings {
    [self openURLString:@"App-Prefs:root=MOBILE_DATA_SETTINGS_ID"];
}

- (void)openHotspotSettings {
    [self openURLString:@"App-Prefs:root=INTERNET_TETHERING"];
}

@end
