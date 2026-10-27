#import <Foundation/Foundation.h>
#include <dlfcn.h>
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;
typedef CFTypeRef (*copyprop_t)(IOHIDServiceClientRef, CFStringRef);
extern IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef);
extern CFArrayRef IOHIDEventSystemClientCopyServices(IOHIDEventSystemClientRef);
int main(void){ @autoreleasepool{
  setvbuf(stdout,NULL,_IONBF,0);
  copyprop_t cp=(copyprop_t)dlsym(RTLD_DEFAULT,"IOHIDServiceClientCopyProperty");
  IOHIDEventSystemClientRef sys=IOHIDEventSystemClientCreate(kCFAllocatorDefault);
  CFArrayRef svcs=IOHIDEventSystemClientCopyServices(sys);
  for(CFIndex i=0;i<CFArrayGetCount(svcs);i++){
    IOHIDServiceClientRef s=(IOHIDServiceClientRef)CFArrayGetValueAtIndex(svcs,i);
    NSMutableArray *b=[NSMutableArray array];
    for(NSString *k in @[@"Product",@"Transport",@"PrimaryUsagePage",@"PrimaryUsage",@"VendorID",@"ProductID"]){
      CFTypeRef v=cp(s,(__bridge CFStringRef)k);
      if(v) [b addObject:[NSString stringWithFormat:@"%@=%@",k,(__bridge_transfer id)v]];
    }
    printf("[%3ld] %s\n",(long)i,[b componentsJoinedByString:@" "].UTF8String);
  }
  return 0;
} }
