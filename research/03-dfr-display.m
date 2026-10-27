#import <Foundation/Foundation.h>
#import <dlfcn.h>
int main(void){ @autoreleasepool{
  setvbuf(stdout,NULL,_IONBF,0);
  void *hD = dlopen("/System/Library/PrivateFrameworks/DFRDisplay.framework/DFRDisplay", RTLD_NOW|RTLD_GLOBAL);
  void *(*create)(void) = dlsym(hD, "DFRDisplayCreate");
  int (*getb)(void*, float*) = dlsym(hD, "DFRDisplayGetBrightness");
  int (*setb)(void*, float) = dlsym(hD, "DFRDisplaySetBrightness");
  int (*ready)(void*) = dlsym(hD, "DFRDisplayIsReady");
  int (*present)(void*) = dlsym(hD, "DFRDisplayIsInterfacePresent");
  void *d = create();
  printf("create=%p\n", d);
  for(int i=0;i<10;i++){
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    int rdy = ready?ready(d):-1, prs = present?present(d):-1;
    float b=-999; int g = getb?getb(d,&b):-1;
    printf("t=%.1fs ready=%d present=%d get=0x%x b=%.3f\n",(i+1)*0.5,rdy,prs,g,b);
    if(prs>0) break;
  }
  printf("SetBrightness(0.5) -> 0x%x\n", setb?setb(d,0.5f):-1);
  usleep(500000);
  float b=-999; int g=getb?getb(d,&b):-1;
  printf("after set: get=0x%x b=%.3f\n", g, b);
  return 0;
} }
