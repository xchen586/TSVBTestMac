//
//  MCAppResolution.m
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-28.
//

#import "MCAppResolution.h"

@implementation MCAppResolution

+ (CMVideoDimensions)sizeForType:(MCAppResolutionType)type {
    switch (type) {
        case MCAppResolutionType_288p: {
            CMVideoDimensions videoSize = {512, 288};
            return videoSize;
        }
        case MCAppResolutionType_360p: {
            CMVideoDimensions videoSize = {640, 360};
            return videoSize;
        }
        case MCAppResolutionType_432p: {
            CMVideoDimensions videoSize = {768, 432};
            return videoSize;
        }
        case MCAppResolutionType_480p: {
            CMVideoDimensions videoSize = {640, 480};
            return videoSize;
        }
        case MCAppResolutionType_540p: {
            CMVideoDimensions videoSize = {960, 540};
            return videoSize;
        }
        case MCAppResolutionType_576p: {
            CMVideoDimensions videoSize = {1024, 576};
            return videoSize;
        }
        case MCAppResolutionType_720p: {
            CMVideoDimensions videoSize = {1280, 720};
            return videoSize;
        }
        case MCAppResolutionType_1080p: {
            CMVideoDimensions videoSize = {1920, 1080};
            return videoSize;
        }
        case MCAppResolutionType_2160p: {
            CMVideoDimensions videoSize = {3840, 2160};
            return videoSize;
        }
            
        case MCAppResolutionType_1to1_192: {
            CMVideoDimensions videoSize = {192, 192};
            return videoSize;
        }
            
        default: {
            CMVideoDimensions videoSize = {0, 0};
            return videoSize;
        }
    }
}
+ (NSString *)stringForType:(MCAppResolutionType)type {
    switch (type) {
        case MCAppResolutionType_288p: {
            return @"512×288";
        }
        case MCAppResolutionType_360p: {
            return @"640×360";
        }
        case MCAppResolutionType_432p: {
            return @"768×432";
        }
        case MCAppResolutionType_480p: {
            return @"640×480";
        }
        case MCAppResolutionType_576p: {
            return @"1024×576";
        }
        case MCAppResolutionType_720p: {
            return @"1280×720";
        }
        case MCAppResolutionType_1080p: {
            return @"1920×1080";
        }
        case MCAppResolutionType_2160p: {
            return @"3840x2160";
        }
        case MCAppResolutionType_1to1_192: {
            return @"192×192";
        }
        
        default: {
            return @"Unknown";
        }
    }
}
+ (NSArray *)getAllLabels {
    return @[
             [MCAppResolution stringForType:MCAppResolutionType_288p],
             [MCAppResolution stringForType:MCAppResolutionType_432p],
             [MCAppResolution stringForType:MCAppResolutionType_480p],
             [MCAppResolution stringForType:MCAppResolutionType_576p],
             [MCAppResolution stringForType:MCAppResolutionType_720p],
             [MCAppResolution stringForType:MCAppResolutionType_1080p],
#if MC_ENABLE_VIDEO_4K
             [MCAppResolution stringForType:MCAppResolutionType_2160p],
#endif
             //[MCAppResolution stringForType:MCAppResolutionType_1to1_192],
    ];
}

+ (MCAppResolutionType)typeByIndex:(NSInteger)index {
    switch (index) {
        case 0:
            return MCAppResolutionType_432p;
        case 1:
            return MCAppResolutionType_480p;
        case 2:
            return MCAppResolutionType_576p;
        case 3:
            return MCAppResolutionType_720p;
        case 4:
            return MCAppResolutionType_1080p;
#if MC_ENABLE_VIDEO_4K
        case 5:
            return MCAppResolutionType_2160p;
#endif
        default:
            return MCAppResolutionType_None;
    }
}

+ (BOOL)isRecommendedType:(MCAppResolutionType)type {
    return type == [MCAppResolution defaultType];
}

+ (MCAppResolutionType)defaultType {
    return MCAppResolutionType_576p;
}

+ (BOOL)isHDResolution:(MCAppResolutionType)type {
    switch (type) {
        case MCAppResolutionType_720p:
            return YES;
        case MCAppResolutionType_1080p:
            return YES;
        case MCAppResolutionType_2160p:
            return YES;
        default:
            return NO;
    }
}

+ (BOOL)is4to3Resolution:(MCAppResolutionType)type {
    switch (type) {
        case MCAppResolutionType_480p:
            return YES;
        default:
            return NO;
    }
}

+ (BOOL)is16to9Resolution:(MCAppResolutionType)type {
    switch (type) {
        case MCAppResolutionType_480p:
            return NO;
        default:
            return YES;
    }
}

+ (BOOL)is4to3ByResolution:(CMVideoDimensions)res {
    
    CMVideoDimensions res4x3 = { .width = 4, .height = 3};
    
    return [self sameRatioForResolution:res andResolution:res4x3];
}

+ (BOOL)is3to4ByResolution:(CMVideoDimensions)res {
    
    CMVideoDimensions res3x4 = { .width = 3, .height = 4};
    
    return [self sameRatioForResolution:res andResolution:res3x4];
}

+ (BOOL)is4With3ByResolution:(CMVideoDimensions)res {
    return [self is4to3ByResolution:res] || [self is3to4ByResolution:res];
}

+ (BOOL)is16to9ByResolution:(CMVideoDimensions)res {
    
    CMVideoDimensions res16x9 = { .width = 16, .height = 9};
    
    return [self sameRatioForResolution:res andResolution:res16x9];
}

+ (BOOL)is9to16ByResolution:(CMVideoDimensions)res {
    
    CMVideoDimensions res9x16 = { .width = 9, .height = 16};
    
    return [self sameRatioForResolution:res andResolution:res9x16];
}

+ (BOOL)is16With9ByResolution:(CMVideoDimensions)res {
    return [self is16to9ByResolution:res] || [self is9to16ByResolution:res];
}

+ (BOOL)sameRatioForResolution:(CMVideoDimensions)one andResolution:(CMVideoDimensions)two {
    
    if (one.height == 0 || two.height == 0) {
        return NO;
    }
    
    double ratioOne = one.width / (double)one.height;
    double ratioTwo = two.width / (double)two.height;
    
    return fabs(ratioOne - ratioTwo) < 0.01;
}

@end
