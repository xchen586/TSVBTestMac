//
//  MCMtlRendering.h
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@import Metal;

@interface MCMtlRendering : NSObject

@property(nonatomic, readonly) id <MTLDevice> sharedDevice;
@property(nonatomic, readonly) id <MTLCommandQueue> sharedCommandQueue;
@property(nonatomic, readonly) id <MTLLibrary> sharedLibrary;

@property(nonatomic, readonly) id <MTLFunction> sharedVertexRendererFunc;
@property(nonatomic, readonly) id <MTLFunction> sharedFragmentRendererFunc;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
