//
//  MCMtlRendering.m
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-28.
//

#import "MCMtlRendering.h"

@import Metal;

@interface MCMtlRendering () {
    
}

@property(nonatomic, readwrite) id <MTLDevice> sharedDevice;
@property(nonatomic, readwrite) id <MTLCommandQueue> sharedCommandQueue;
@property(nonatomic, readwrite) id <MTLLibrary> sharedLibrary;

@end

@implementation MCMtlRendering

+ (instancetype)sharedInstance {
    
    static MCMtlRendering * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MCMtlRendering alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        _sharedDevice = MTLCreateSystemDefaultDevice();
        if (!_sharedDevice) {
            NSLog(@"Fail to create shared Metal Device");
            return nil;
        }
    
        _sharedCommandQueue = [_sharedDevice newCommandQueue];
        if (!_sharedCommandQueue) {
            NSLog(@"Fail to create shared Metal Command Queue");
            return nil;
        }
        
        _sharedLibrary = [_sharedDevice newDefaultLibrary];
        if (!_sharedLibrary) {
            NSLog(@"Fail to create shared Metal Library");
            return nil;
        }
        
        _sharedVertexRendererFunc =[_sharedLibrary newFunctionWithName:@"vertexDefaultRenderer"];
        if (!_sharedVertexRendererFunc) {
            NSLog(@"Fail to create shared vertex renderfunc");
            return nil;
        }
        
        _sharedFragmentRendererFunc =[_sharedLibrary newFunctionWithName:@"fragmentDefaultRenderer"];
        if (!_sharedFragmentRendererFunc) {
            NSLog(@"Fail to create shared vertex renderfunc");
            return nil;
        }
        
    }

    return self;
}

@end

