#import <Foundation/Foundation.h>
#include <dlfcn.h>
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;
typedef CFTypeRef (*cp_t)(IOHIDServiceClientRef,CFStringRef);
extern IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef);
extern CFArrayRef IOHIDEventSystemClientCopyServices(IOHIDEventSystemClientRef);
extern CFDictionaryRef IOHIDServiceClientCopyProperties(IOHIDServiceClientRef);
int main(void){ @autoreleasepool{
  setvbuf(stdout,NULL,_IONBF,0);
  cp_t cp=(cp_t)dlsym(RTLD_DEFAULT,"IOHIDServiceClientCopyProperty");
  IOHIDEventSystemClientRef sys=IOHIDEventSystemClientCreate(kCFAllocatorDefault);
  CFArrayRef svcs=IOHIDEventSystemClientCopyServices(sys);
  IOHIDServiceClientRef als=NULL;
  for(CFIndex i=0;i<CFArrayGetCount(svcs);i++){
    IOHIDServiceClientRef s=(IOHIDServiceClientRef)CFArrayGetValueAtIndex(svcs,i);
    CFTypeRef p=cp(s,CFSTR("Product"));
    if(p && [(__bridge_transfer NSString*)p isEqualToString:@"als"]){ als=s; break; }
  }
  printf("als=%p\n",als);
  if(!als) return 1;
  const char *keys[]={"Lux","Illuminance","CurrentLux","ReportInterval","Calibration","SensorProperty","Brightness","IntegrationTime","SampleInterval"};
  for(int i=0;i<9;i++){ CFTypeRef v=cp(als,CFStringCreateWithCString(NULL,keys[i],kCFStringEncodingUTF8)); printf("  %-16s -> %s\n",keys[i], v?[(__bridge_transfer id)v description].UTF8String:"nil"); }
  printf("=== full props ===\n");
  CFDictionaryRef props=IOHIDServiceClientCopyProperties(als);
  printf("%s\n", props?[(__bridge_transfer NSDictionary*)props description].UTF8String:"nil");
  return 0;
} }
