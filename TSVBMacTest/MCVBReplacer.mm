//
//  TSVBReplacer.m
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-23.
//

#import "MCVBReplacer.h"

#include <dlfcn.h>
#include <CoreFoundation/CoreFoundation.h>

#include "sdk_factory.h"

using namespace manycam;

@interface MCVBReplacer () {
    pfnCreateSDKFactory _createFactory;
    ISDKFactory * _sdkFactory;
    IPipeline * _pipeline;
    IFrameFactory * _frameFactory;
    
}

@end

@implementation MCVBReplacer

- (instancetype)init {
    self = [super init];
    if (self) {
        BOOL setupOK = [self initSetup];
        if (!setupOK) {
            return nil;
        }
    }
    return self;
}

- (BOOL)initSetup {
    
    NSString * mcvbNSPath = [self getMCVBNSPath];
    
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:mcvbNSPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:mcvbNSPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
        NSLog(@"Library is not exist!");
        return NO;
    }
    
    const char * path = NULL;
    //path = "libmcvb.dylib";
    //path = [mcvbNSPath UTF8String];
    //path = [mcvbNSPath cStringUsingEncoding:NSASCIIStringEncoding];
    path = [mcvbNSPath cStringUsingEncoding:NSUTF8StringEncoding];
    
    if (!path) {
        NSLog(@"Can not get library char path.");
        return NO;
    }
    
    void * handle = dlopen(path, RTLD_NOW);
    if (!handle) {
        char * error = dlerror();
        NSLog(@"dlopen error: %s", error);
        return NO;
    }
   
    _createFactory = reinterpret_cast<manycam::pfnCreateSDKFactory>(dlsym(handle, "createSDKFactory"));
    if (!_createFactory) {
        NSLog(@"Fail to get function pointer of createSDKFactory");
        return NO;
    }
    
    _sdkFactory = _createFactory();
    if (!_sdkFactory) {
        NSLog(@"Fail to createFactory!");
        return NO;
    }
    
    _pipeline = _sdkFactory->createPipeline();
    if (!_pipeline) {
        NSLog(@"Fail to create pipeline!");
        return NO;
    }
    
    _frameFactory = _sdkFactory->createFrameFactory();
    if (!_frameFactory) {
        NSLog(@"Fail to createFrameFactory!");
        return NO;
    }
    
    return YES;
}

- (NSString *)getMCVBNSPath {
    //return [self getMCVBNSPathFromFrameWork];
    return [self getMCVBNSPathFromResource];
}

- (NSString *)getMCVBNSPathFromFrameWork {
    NSString *dataPath;
    
#if 0
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    dataPath = [documentsDirectory stringByAppendingPathComponent:@"libmcvb.dylib"];
#endif
    
    NSBundle* bundle = [NSBundle mainBundle];
#if 0
    NSArray<NSBundle *> *allFrameworks = [NSBundle allFrameworks];
    NSArray<NSBundle *> *allBundles = [NSBundle allBundles];
    NSURL * sharedFrameWorkUrl = bundle.sharedFrameworksURL;
    NSString * sharedFrameworkPath = bundle.sharedFrameworksPath;
    NSString * execPath = bundle.executablePath;
#endif
    NSString * privateFrameworkPath = bundle.privateFrameworksPath;
    dataPath = [privateFrameworkPath stringByAppendingPathComponent:@"libmcvb.dylib"];
    return dataPath;
}

- (NSString *)getMCVBNSPathFromResource {
    NSString * dataPath;
    NSBundle* bundle = [NSBundle mainBundle];
    dataPath = [bundle pathForResource:@"libmcvb" ofType:@"dylib"];
    return dataPath;
}

- (CFStringRef)getMCVBCFPath {
    CFStringRef ret = nullptr;
    CFBundleRef appBundle = CFBundleGetMainBundle();

    CFURLRef appUrlRef = CFBundleCopyBundleURL(appBundle);
    CFURLRef fmwkUrlRef = CFBundleCopyPrivateFrameworksURL(appBundle);
    CFStringRef appPathRef = CFURLCopyPath(appUrlRef);
    CFStringRef fmwkPathRef = CFURLCopyPath(fmwkUrlRef);
    return ret;
}

- (char*)MYCFStringCopyUTF8String:(CFStringRef)aString {
  if (aString == NULL) {
    return NULL;
  }

  CFIndex length = CFStringGetLength(aString);
  CFIndex maxSize =
  CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8) + 1;
  char *buffer = (char *)malloc(maxSize);
  if (CFStringGetCString(aString, buffer, maxSize,
                         kCFStringEncodingUTF8)) {
    return buffer;
  }
  free(buffer); // If we failed
  return NULL;
}
@end
