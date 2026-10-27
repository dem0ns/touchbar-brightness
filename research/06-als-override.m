#import <Foundation/Foundation.h>
#import <dlfcn.h>
@interface BrightnessSystemClient : NSObject
- (id)copyPropertyForKey:(NSString*)k;
- (BOOL)setProperty:(id)v forKey:(NSString*)k;
@end
int main(void){ @autoreleasepool{
  setvbuf(stdout,NULL,_IONBF,0);
  dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_NOW|RTLD_GLOBAL);
  Class c=NSClassFromString(@"BrightnessSystemClient");
  BrightnessSystemClient *cb=[[c alloc] init];
  double vals[]={0.5, 50, 500, 5000, 50000};
  for(int i=0;i<5;i++){
    BOOL ok=[cb setProperty:@(vals[i]) forKey:@"AABSensorOverride"];
    usleep(800000);
    id lux=[cb copyPropertyForKey:@"Lux"];
    printf("AABSensorOverride=%.1f (ok=%d) -> Lux=%s\n", vals[i], ok, lux?[[lux description] UTF8String]:"nil");
  }
  return 0;
} }
