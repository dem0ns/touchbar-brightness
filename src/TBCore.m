#import "TBCore.h"
#import <dlfcn.h>
#import <math.h>

// Private class from CoreBrightness.framework. Talks XPC to corebrightnessd.
@interface BrightnessSystemClient : NSObject
- (id)copyPropertyForKey:(NSString *)key;
- (BOOL)setProperty:(id)value forKey:(NSString *)key;
@end

static NSString *const kSuite = @"com.dem0ns.TouchBarBrightness";
static NSString *const kMaxLuxKey = @"maxLux";
static NSString *const kMinLuxKey = @"minLux";
static NSString *const kOverrideKey = @"AABSensorOverride";
static NSString *const kSavedLuxKey = @"savedLux";

@implementation TBCore {
    BrightnessSystemClient *_client;
    double _maxLux;
    double _minLux;
}

+ (instancetype)shared {
    static TBCore *shared = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared = [[TBCore alloc] init]; });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness",
           RTLD_NOW | RTLD_GLOBAL);
    Class cls = NSClassFromString(@"BrightnessSystemClient");
    if (cls) {
        _client = [[cls alloc] init];
    }

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    double storedMax = [defaults doubleForKey:kMaxLuxKey];
    double storedMin = [defaults doubleForKey:kMinLuxKey];
    _maxLux = storedMax > 0 ? storedMax : 5000.0;
    _minLux = storedMin > 0 ? storedMin : 1.0;
    return self;
}

- (BOOL)available { return _client != nil; }

- (double)currentLux {
    if (!_client) return -1;
    id value = [_client copyPropertyForKey:@"Lux"];
    if (!value || ![value respondsToSelector:@selector(doubleValue)]) return -1;
    return [value doubleValue];
}

- (double)overrideLux {
    if (!_client) return -1;
    id value = [_client copyPropertyForKey:kOverrideKey];
    if (!value || ![value respondsToSelector:@selector(doubleValue)]) return -1;
    double lux = [value doubleValue];
    return lux < 0 ? -1 : lux;   // -1 disables the override
}

- (double)effectiveLux {
    double injected = self.overrideLux;
    return injected >= 0 ? injected : self.currentLux;
}

- (BOOL)setLux:(double)lux {
    if (!_client) return NO;
    if (lux < 0) lux = 0;
    BOOL ok = [_client setProperty:@(lux) forKey:kOverrideKey];
    if (ok) {
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
        [defaults setDouble:lux forKey:kSavedLuxKey];
        [defaults synchronize];
    }
    return ok;
}

- (BOOL)clearOverride {
    if (!_client) return NO;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    [defaults removeObjectForKey:kSavedLuxKey];
    [defaults synchronize];
    // Never pass nil here: CBColorModuleShared's setPropertyInternal:forKey:
    // does [_dict setObject:forKey:] and throws on nil, aborting corebrightnessd.
    // -1 is the documented-by-behaviour "disabled" value.
    return [_client setProperty:@(-1) forKey:kOverrideKey];
}

- (double)rememberedLux {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    if (![defaults objectForKey:kSavedLuxKey]) return -1;
    double lux = [defaults doubleForKey:kSavedLuxKey];
    return lux > 0 ? lux : -1;
}

- (BOOL)restoreRemembered {
    double lux = self.rememberedLux;
    if (lux < 0) {
        // No setpoint stored yet: adopt an override that another build or tool
        // already applied, so it survives the next reboot.
        lux = self.overrideLux;
        if (lux < 0) return NO;
    }
    return [self setLux:lux];
}

- (BOOL)setPercent:(double)percent {
    return [self setLux:[self luxForPercent:percent]];
}

- (double)maxLux { return _maxLux; }
- (double)minLux { return _minLux; }

- (void)setMaxLux:(double)maxLux {
    if (maxLux < 1) maxLux = 1;
    if (maxLux > 20000) maxLux = 20000;
    _maxLux = maxLux;
    if (_minLux > _maxLux) _minLux = _maxLux;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    [defaults setDouble:maxLux forKey:kMaxLuxKey];
    [defaults synchronize];
}

- (void)setMinLux:(double)minLux {
    if (minLux < 0) minLux = 0;
    if (minLux > _maxLux) minLux = _maxLux;
    _minLux = minLux;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kSuite];
    [defaults setDouble:minLux forKey:kMinLuxKey];
    [defaults synchronize];
}

// Perceptual: equal slider steps should feel roughly equal.
- (double)luxForPercent:(double)percent {
    if (percent <= 0) return _minLux;
    if (percent >= 100) return _maxLux;
    double lo = log(_minLux > 0 ? _minLux : 0.01);
    double hi = log(_maxLux);
    return exp(lo + (percent / 100.0) * (hi - lo));
}

- (double)percentForLux:(double)lux {
    if (lux <= 0) return 0;
    double lo = log(_minLux > 0 ? _minLux : 0.01);
    double hi = log(_maxLux);
    if (hi <= lo) return 100;
    double pct = 100.0 * (log(lux) - lo) / (hi - lo);
    if (pct < 0) return 0;
    if (pct > 100) return 100;
    return pct;
}

@end
