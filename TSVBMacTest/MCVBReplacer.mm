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
    IReplacementController * _backgroundController;
    CFDictionaryRef _pixelBufferAttributes;
    
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
    
//    if (_sdkFactory) {
//        _sdkFactory->release();
//        _sdkFactory = nullptr;
//    }
    _pipeline->enableBlurBackground(0.8);
    
    return YES;
}

- (void)releaseFactoryResource {
    if (_frameFactory) {
        _frameFactory->release();
        _frameFactory = nullptr;
    }
    if (_backgroundController) {
        _backgroundController->release();
        _backgroundController = nullptr;
    }
    if (_pipeline) {
        _pipeline->release();
        _pipeline = nullptr;
    }
    if (_sdkFactory) {
        _sdkFactory->release();
        _sdkFactory = nullptr;
    }
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
#if 0
    CFBundleRef appBundle = CFBundleGetMainBundle();

    CFURLRef appUrlRef = CFBundleCopyBundleURL(appBundle);
    CFURLRef fmwkUrlRef = CFBundleCopyPrivateFrameworksURL(appBundle);
    CFStringRef appPathRef = CFURLCopyPath(appUrlRef);
    CFStringRef fmwkPathRef = CFURLCopyPath(fmwkUrlRef);
#endif
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

- (CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)srcPixelBuffer {
    if (!srcPixelBuffer) {
        return nil;
    }
    
    CVPixelBufferLockBaseAddress(srcPixelBuffer, 0);
    
    unsigned int width = (unsigned int)CVPixelBufferGetWidth(srcPixelBuffer);
    unsigned int height = (unsigned int)CVPixelBufferGetHeight(srcPixelBuffer);
    unsigned int bytesPerPixel = 4;
    unsigned int bytesPerLine = width * bytesPerPixel;
    //size_t bytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer);
    
    const uint8_t * srcAddress = (uint8_t *)(CVPixelBufferGetBaseAddress(srcPixelBuffer));
    if (!srcAddress) {
        CVPixelBufferUnlockBaseAddress(srcPixelBuffer, 0);
        return nil;
    }
    
    void * data = (void *)(srcAddress);
    IFrame * input = _frameFactory->createBGRA(data, bytesPerLine, width, height, true);
    
    if (!input) {
        CVPixelBufferUnlockBaseAddress(srcPixelBuffer, 0);
        return nil;
    }
    CVPixelBufferUnlockBaseAddress(srcPixelBuffer, 0);
    
    PipelineError err;
    //id<MCVBFrame> processed = [_pipeline process:input error:&err];
    IFrame * processed = _pipeline->process(input, &err);
    if (!processed) {
        return nullptr;
    }
    
    BOOL copy = YES;
    CVPixelBufferRef ret = nil;
    ret = [self getPixelBufferFromFrame:processed byCopy:copy];
    
    return ret;
}

- (CVPixelBufferRef)getPixelBufferFromFrame:(IFrame *)frame byCopy:(BOOL)copy {
    //@autoreleasepool {

        if (!frame) {
            return nil;
        }
        
        ILockedFrameData * frameData;
        if (copy) {
            frameData = frame->lock(FrameLock::read);
        } else {
            frameData = frame->lock(FrameLock::readWrite);
        }
        if (!frameData) {
            return nil;
        }
        
        void * dataPointer = frameData->dataPointer(0);
        if (!dataPointer) {
            return nil;
        }
        uint8_t * rawDataBaseAddress = (uint8_t *)(dataPointer);
        if (!rawDataBaseAddress) {
            return nil;
        }
    
        CVPixelBufferRef ret = nil;
        CVReturn err = 0;
        size_t width = frame->width();
        size_t height = frame->height();
        size_t bytePerline = frameData->bytesPerLine(0);
        size_t bytePerPixel = bytePerline / width;
    
        if (copy) {
            err = CVPixelBufferCreate(kCFAllocatorSystemDefault,
                                      width,
                                      height,
                                      kCVPixelFormatType_32BGRA,
                                      _pixelBufferAttributes,
                                      &ret);
            if (err) {
                NSLog(@"Error CVPixelBufferCreate creating pixel buffer: %d", err);
                return nil;
            }
            CVPixelBufferLockBaseAddress(ret,0);
            void * dst_buff = CVPixelBufferGetBaseAddress(ret);
            size_t dataSize = width * height * bytePerPixel;
            memcpy(dst_buff, rawDataBaseAddress, dataSize);
            CVPixelBufferUnlockBaseAddress(ret, 0);
            //frameData = nil;

        } else {
            //TODO: xc: the pixel from no copy not work for metal texture.
            err = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                                width,
                                                height,
                                                kCVPixelFormatType_32BGRA,
                                                dataPointer,
                                                bytePerline,
                                                nil,
                                                nil,
                                                _pixelBufferAttributes,
                                                &ret);
            if (err) {
                NSLog(@"Error CVPixelBufferCreateWithBytes creating pixel buffer: %d", err);
                return nil;
            }
        }
        
        return ret;
    //}
}

- (CFDictionaryRef)createVirtualBackgroundPixelBufferAttributes {
    
    NSDictionary * myAttr = @{ (NSString*)kCVPixelBufferIOSurfacePropertiesKey : @{},
                              (NSString*)kCVPixelBufferMetalCompatibilityKey: @YES,
                              (NSString*)kCVPixelBufferOpenGLTextureCacheCompatibilityKey: @YES
                              
    };
    return (__bridge_retained CFDictionaryRef)myAttr;
}

-(void)setBackgroundWithContentOfFile:(nullable NSString*)filePath
{
    if (!filePath) {
        return;
    }
    const char * path = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
    IFrame * background = _frameFactory->loadImage(path);
    if (background) {
        _backgroundController->setBackgroundImage(background);
    }
}

-(void)resetBackgroundImage
{
    _backgroundController->clearBackgroundImage();
}

@end
