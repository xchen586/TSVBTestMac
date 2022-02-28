//
//  MCAppResolution.h
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-28.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreMedia/CMFormatDescription.h>

NS_ASSUME_NONNULL_BEGIN
// In theory we should have resolutions divisable by 8 (for RGB -> YUV),
// but by some reason webrtc can't handle res not divisable by 16, so use only those (TODO: check why?)

typedef enum {
    MCAppResolutionType_None = 0,
    
    // 1:1 (test)
    MCAppResolutionType_1to1_192 = '192p',
    
    // 4:3
    MCAppResolutionType_480p = '480p',
    // TODO: add 800x600, 1024x768
    
    // 16:9
    MCAppResolutionType_288p = '288p', // not used - too bad quality
    MCAppResolutionType_360p = '360p', // deprecated, height is not divisable by 16
    MCAppResolutionType_432p = '432p', // 768 x 432
    MCAppResolutionType_540p = '540p', // deprecated as not divisable by 8
    MCAppResolutionType_576p = '576p', // 1024 x 576
    MCAppResolutionType_720p = '720p',
    MCAppResolutionType_1080p = '1080p',
    MCAppResolutionType_2160p = '2160p',
#if MC_ENABLE_VIDEO_4K
    MCAppResolutionType_Count = 6 // of valid resolutions
#else
    MCAppResolutionType_Count = 5 // of valid resolutions
#endif
} MCAppResolutionType;

@interface MCAppResolution : NSObject

+ (CMVideoDimensions)sizeForType:(MCAppResolutionType)type;
+ (NSString *)stringForType:(MCAppResolutionType)type;
+ (NSArray *)getAllLabels;
+ (MCAppResolutionType)typeByIndex:(NSInteger)index;
+ (BOOL)isRecommendedType:(MCAppResolutionType)type;
+ (MCAppResolutionType)defaultType;
+ (BOOL)isHDResolution:(MCAppResolutionType)type;
+ (BOOL)is16to9Resolution:(MCAppResolutionType)type;
+ (BOOL)is4to3ByResolution:(CMVideoDimensions)res;
+ (BOOL)is3to4ByResolution:(CMVideoDimensions)res;
+ (BOOL)is4With3ByResolution:(CMVideoDimensions)res;
+ (BOOL)is16to9ByResolution:(CMVideoDimensions)res;
+ (BOOL)is9to16ByResolution:(CMVideoDimensions)res;
+ (BOOL)is16With9ByResolution:(CMVideoDimensions)res;
+ (BOOL)sameRatioForResolution:(CMVideoDimensions)one andResolution:(CMVideoDimensions)two;

@end

NS_ASSUME_NONNULL_END
