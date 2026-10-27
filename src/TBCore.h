#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Touch Bar brightness via the ambient light sensor.
//
// macOS drives the Touch Bar backlight from the ambient light sensor, but has
// no public API to set the backlight directly. CoreBrightness exposes an
// engineering hook: writing the "AABSensorOverride" property on
// BrightnessSystemClient fakes the ALS lux value, and the backlight follows.
// The override is removed again by passing nil for the same key.

@interface TBCore : NSObject
@property (class, nonatomic, readonly) TBCore *shared;

@property (nonatomic, readonly) BOOL available;

// Ambient light as CoreBrightness currently reports it (-1 if unavailable).
@property (nonatomic, readonly) double currentLux;

// The value we injected, or -1 when the real sensor is in charge.
@property (nonatomic, readonly) double overrideLux;

// overrideLux when injecting, otherwise currentLux.
@property (nonatomic, readonly) double effectiveLux;

// Faked lux range. Values above maxLux are clamped by the daemon (~5000).
@property (nonatomic) double maxLux;
@property (nonatomic) double minLux;

- (BOOL)setLux:(double)lux;           // also remembers the value
- (BOOL)setPercent:(double)percent;   // 0 = darkest, 100 = brightest
- (BOOL)clearOverride;                // hand control back to the real sensor

// Remembered setpoint, used by the LaunchAgent to restore after login or a
// corebrightnessd restart.
- (double)rememberedLux;              // -1 if nothing remembered
- (BOOL)restoreRemembered;

- (double)luxForPercent:(double)percent;
- (double)percentForLux:(double)lux;
@end

NS_ASSUME_NONNULL_END
