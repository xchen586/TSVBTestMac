//
//  VBMtlPixelBufferView.h
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-28.
//

#import <Cocoa/Cocoa.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface MCMtlPixelBufferView : NSControl

@property BOOL isCrop;
@property BOOL skipDraw;
@property (nonatomic) BOOL isTransparentView;

- (instancetype)initWithFrame:(CGRect)frame withTransparent:(BOOL)isTransparent;

- (void)displayVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)flushPixelBufferCache;
- (void)reset;

- (void)setOutputVideoResolution:(CMVideoDimensions)outputRes;
@end

NS_ASSUME_NONNULL_END
