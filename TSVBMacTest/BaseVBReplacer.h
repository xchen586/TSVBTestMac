//
//  BaseVBReplacer.h
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-25.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseVBReplacer : NSObject

-(nullable CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)srcPixelBuffer;

-(void)setBackgroundWithContentOfFile:(nullable NSString*)filePath;
-(void)resetBackgroundImage;

-(void)releaseFactoryResource;

@end

NS_ASSUME_NONNULL_END
