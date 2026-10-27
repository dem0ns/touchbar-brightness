#import <Foundation/Foundation.h>
#import <dlfcn.h>
@interface BrightnessSystemClient : NSObject
- (id)copyPropertyForKey:(NSString*)k;
@end
int main(void){ @autoreleasepool{
  setvbuf(stdout,NULL,_IONBF,0);
  dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_NOW|RTLD_GLOBAL);
  Class c=NSClassFromString(@"BrightnessSystemClient");
  BrightnessSystemClient *cb=[[c alloc] init];
  for(int i=0;i<15;i++){
    id lux=[cb copyPropertyForKey:@"Lux"];
    id ov=[cb copyPropertyForKey:@"AABSensorOverride"];
    id ovv=[cb copyPropertyForKey:@"AABSensorOverrideValue"];
    printf("t=%2ds  Lux=%-12s  AABSensorOverride=%-12s  Value=%s\n", i,
      lux?[[lux description] UTF8String]:"nil",
      ov?[[ov description] UTF8String]:"nil",
      ovv?[[ovv description] UTF8String]:"nil");
    sleep(1);
  }
  return 0;
} }
