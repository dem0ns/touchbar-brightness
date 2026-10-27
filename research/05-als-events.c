#include <stdio.h>
#include <dlfcn.h>
#include <unistd.h>
#include <mach/mach_time.h>
#include <CoreFoundation/CoreFoundation.h>
typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;
int main(void){
  setvbuf(stdout,NULL,_IONBF,0);
  IOHIDEventRef (*create)(void*, unsigned long long, int, unsigned) = dlsym(RTLD_DEFAULT,"IOHIDEventCreateAmbientLightSensorEvent");
  void (*setf)(IOHIDEventRef, unsigned, double) = dlsym(RTLD_DEFAULT,"IOHIDEventSetFloatValue");
  double (*getf)(IOHIDEventRef, unsigned) = dlsym(RTLD_DEFAULT,"IOHIDEventGetFloatValue");
  IOHIDEventSystemClientRef (*ccreate)(void*) = dlsym(RTLD_DEFAULT,"IOHIDEventSystemClientCreate");
  void (*dispatch)(IOHIDEventSystemClientRef, IOHIDEventRef) = dlsym(RTLD_DEFAULT,"IOHIDEventSystemClientDispatchEvent");
  void (*setm)(IOHIDEventSystemClientRef, CFDictionaryRef) = dlsym(RTLD_DEFAULT,"IOHIDEventSystemClientSetMatching");
  dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW|RTLD_GLOBAL);
  int (*getb)(int, float*) = dlsym(RTLD_DEFAULT,"DisplayServicesGetBrightness");
  printf("create=%p setf=%p getf=%p ccreate=%p dispatch=%p setm=%p getb=%p\n",create,setf,getf,ccreate,dispatch,setm,getb);
  if(!create||!setf||!dispatch) return 1;

  unsigned long long ts = mach_absolute_time();
  IOHIDEventRef e = create(NULL, ts, 0, 1);
  setf(e, 0x000C0006, 500.0);
  printf("roundtrip: %f\n", getf?getf(e,0x000C0006):-1);

  IOHIDEventSystemClientRef c = ccreate ? ccreate(NULL) : NULL;
  printf("client=%p\n", c);
  if(c && setm){
    const void *keys[] = { CFSTR("PrimaryUsagePage"), CFSTR("PrimaryUsage") };
    int page=0xff00, usage=4;
    CFNumberRef p = CFNumberCreate(NULL,kCFNumberIntType,&page);
    CFNumberRef u = CFNumberCreate(NULL,kCFNumberIntType,&usage);
    const void *vals[] = { p, u };
    CFDictionaryRef d = CFDictionaryCreate(NULL,keys,vals,2,&kCFTypeDictionaryKeyCallBacks,&kCFTypeDictionaryValueCallBacks);
    setm(c,d);
    printf("matching set\n");
  }
  float b=-1; if(getb) { getb(1,&b); printf("display1 brightness before=%.4f\n", b); }
  double luxes[] = {0.5, 10000, 0.5, 10000};
  for(int i=0;i<4;i++){
    unsigned long long t2 = mach_absolute_time();
    IOHIDEventRef ev = create(NULL, t2, 0, 1);
    setf(ev, 0x000C0006, luxes[i]);
    dispatch(c, ev);
    usleep(1500000);
    b=-1; if(getb) getb(1,&b);
    printf("dispatched lux=%.1f -> display1 brightness=%.4f\n", luxes[i], b);
  }
  return 0;
}
