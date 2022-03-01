//
//  SharedShadersType.h
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-28.
//

#ifndef SharedShadersType_h
#define SharedShadersType_h

#include <simd/simd.h>

struct VertexIO
{
    float4 position [[position]];
    float2 textureCoord [[user(texturecoord)]];
};

#endif /* SharedShadersType_h */
