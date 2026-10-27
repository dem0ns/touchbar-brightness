#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>

static const char *fws[] = {
  "/System/Library/PrivateFrameworks/DFRBrightness.framework/DFRBrightness",
  "/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation",
  "/System/Library/PrivateFrameworks/DFRDisplay.framework/DFRDisplay",
  "/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness",
  "/System/Library/PrivateFrameworks/BrightnessControl.framework/BrightnessControl",
  "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices",
  NULL
};

static void dumpClass(Class c, const char *tag){
  printf("\n### [%s] %s\n", tag, class_getName(c));
  Class meta = object_getClass(c);
  unsigned int n=0;
  Method *ms = class_copyMethodList(meta, &n);
  for(unsigned i=0;i<n;i++) printf("  + %s  -> %s\n", sel_getName(method_getName(ms[i])), method_getTypeEncoding(ms[i]));
  free(ms);
  ms = class_copyMethodList(c, &n);
  for(unsigned i=0;i<n;i++) printf("  - %s  -> %s\n", sel_getName(method_getName(ms[i])), method_getTypeEncoding(ms[i]));
  free(ms);
}

int main(void){
  for(int i=0; fws[i]; i++){
    void *h = dlopen(fws[i], RTLD_NOW|RTLD_LOCAL);
    printf("\n===== %s => %s\n", fws[i], h ? "OK" : dlerror());
  }
  int count = objc_getClassList(NULL,0);
  Class *classes = (Class *)malloc(sizeof(Class)*count);
  count = objc_getClassList(classes,count);
  for(int i=0;i<count;i++){
    const char *n = class_getName(classes[i]);
    if(!n) continue;
    if(strstr(n,"DFR")||strstr(n,"Bright")||strstr(n,"TouchBar")||strstr(n,"DisplayServices"))
      dumpClass(classes[i], "runtime");
  }
  free(classes);
  return 0;
}
