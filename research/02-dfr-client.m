#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <objc/runtime.h>

@interface DFRBrightnessClient : NSObject
- (instancetype)init;
- (BOOL)initializeHID;
- (int)getDFRDisplayID;
- (BOOL)dimToStep:(long)step;
- (BOOL)dimToStep:(long)step withPeriod:(float)p andCoefficient:(float)c;
- (long)getDimmingStep;
- (long)displayState;
- (long)harmonyState;
- (BOOL)turnOn;
- (BOOL)turnOff;
- (id)copyPropertyForKey:(NSString *)k;
- (BOOL)setProperty:(id)v forKey:(NSString *)k;
@end

int main(int argc, char **argv){
  @autoreleasepool {
    void *h = dlopen("/System/Library/PrivateFrameworks/DFRBrightness.framework/DFRBrightness", RTLD_NOW|RTLD_GLOBAL);
    printf("dlopen=%p err=%s\n", h, h?NULL:dlerror());
    Class c = NSClassFromString(@"DFRBrightnessClient");
    printf("class=%s\n", c?class_getName(c):"nil");
    if(!c) return 1;
    DFRBrightnessClient *cl = [[c alloc] init];
    printf("init -> %s\n", cl?"OK":"nil");
    if(!cl) return 2;
    BOOL ok = [cl initializeHID];
    printf("initializeHID -> %d\n", ok);
    printf("displayID -> 0x%x (%d)\n", [cl getDFRDisplayID], [cl getDFRDisplayID]);
    printf("displayState -> %ld\n", (long)[cl displayState]);
    printf("harmonyState -> %ld\n", (long)[cl harmonyState]);
    printf("dimmingStep -> %ld\n", (long)[cl getDimmingStep]);
    for(NSString *k in @[@"BrightnessStep",@"DimmingStep",@"Brightness",@"Step",@"DFRBrightness",@"MaxDimmingStep"]){
      @try { id v=[cl copyPropertyForKey:k]; printf("prop %-18s -> %s\n", k.UTF8String, v?[[v description] UTF8String]:"nil"); }
      @catch(NSException *e){ printf("prop %-18s -> EXC %s\n", k.UTF8String, e.reason.UTF8String); }
    }
    unsigned long cnt=0; unsigned long *burn=NULL;
    // skip burnin
    (void)cnt;(void)burn;
    return 0;
  }
}
