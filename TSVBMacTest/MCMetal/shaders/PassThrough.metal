//
//  PassThrough.metal
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-28.
//

#include <metal_stdlib>
// Include header shared between this Metal shader code and C code executing Metal API commands
#import "SharedShadersType.h"
//#import "ShadersType.h"

using namespace metal;

// Vertex shader for a textured quad
vertex VertexIO vertexPassThrough(const device packed_float4 *pPosition  [[ buffer(0) ]],
                                  const device packed_float2 *pTexCoords [[ buffer(1) ]],
                                  uint                  vid        [[ vertex_id ]])
{
    VertexIO outVertex;
    
    outVertex.position = pPosition[vid];
    outVertex.textureCoord = pTexCoords[vid];
    
    return outVertex;
}

// Fragment shader for a textured quad
fragment half4 fragmentPassThrough(VertexIO         inputFragment [[ stage_in ]],
                                   texture2d<half> inputTexture  [[ texture(0) ]]
                                   , sampler         samplr        [[ sampler(0) ]]
                                   )
{
//    constexpr sampler samplr(s_address::clamp_to_edge,
//                             t_address::clamp_to_edge,
//                             min_filter::linear,
//                             mag_filter::linear
//                             );
    return inputTexture.sample(samplr, inputFragment.textureCoord);
}

// Receiving YCrCb textures.
fragment half4 fragmentNV12Conversion(VertexIO in[[stage_in]],
                                       texture2d<float, access::sample> textureY[[texture(0)]],
                                       texture2d<float, access::sample> textureCbCr[[texture(1)]]
                                      , sampler         samplr        [[ sampler(0) ]]
                                    ) {
    //constexpr sampler s(address::clamp_to_edge, filter::linear);
    float y;
    float2 uv;
    y = textureY.sample(samplr, in.textureCoord).r;
    uv = textureCbCr.sample(samplr, in.textureCoord).rg - float2(0.5, 0.5);
    
    // Conversion for YUV to rgb from http://www.fourcc.org/fccyvrgb.php
    float4 out = float4(y + 1.403 * uv.y, y - 0.344 * uv.x - 0.714 * uv.y, y + 1.770 * uv.x, 1.0);
    
    return half4(out);
};

// Receiving YCrCb textures.
fragment half4 fragmentNV12ConversionABGR(VertexIO in[[stage_in]],
                                       texture2d<float, access::sample> textureY[[texture(0)]],
                                          texture2d<float, access::sample> textureCbCr[[texture(1)]] ,
                                          sampler         samplr        [[ sampler(0) ]]
                                          )  {
    //constexpr sampler samplr(address::clamp_to_edge, filter::linear);
    float y;
    float2 uv;
    y = textureY.sample(samplr, in.textureCoord).r;
    uv = textureCbCr.sample(samplr, in.textureCoord).rg - float2(0.5, 0.5);
    
    // Conversion for YUV to rgb from http://www.fourcc.org/fccyvrgb.php
    float4 out = float4(y + 1.770 * uv.x, y - 0.344 * uv.x - 0.714 * uv.y, y + 1.403 * uv.y, 1.0);
    //float4 out = float4(y + 1.403 * uv.y, y - 0.344 * uv.x - 0.714 * uv.y,  y + 1.770 * uv.x, 1.0); For frame comes from webrtc browser;
    
    return half4(out);
};

// I420 -> ARGB converter
fragment half4 fragmentI420Conversion(VertexIO in[[stage_in]],
                                      texture2d<float, access::sample> textureY[[texture(0)]],
                                      texture2d<float, access::sample> textureU[[texture(1)]],
                                      texture2d<float, access::sample> textureV[[texture(2)]],
                                      sampler         samplr        [[ sampler(0) ]]
                                      )
{

    float y, u, v, r, g, b;
    
    y = textureY.sample(samplr, in.textureCoord).r;
    u = textureU.sample(samplr, in.textureCoord).r;
    v = textureV.sample(samplr, in.textureCoord).r;
    u = u - 0.5;
    v = v - 0.5;
    r = y + 1.403 * v;
    g = y - 0.344 * u - 0.714 * v;
    b = y + 1.770 * u;
    
    return half4(r, g, b, 1.0);
};

// I420 -> ABGR converter
fragment half4 fragmentI420ConversionABGR(VertexIO in[[stage_in]],
                                      texture2d<float, access::sample> textureY[[texture(0)]],
                                      texture2d<float, access::sample> textureU[[texture(1)]],
                                      texture2d<float, access::sample> textureV[[texture(2)]],
                                      sampler         samplr        [[ sampler(0) ]]
                                      )
{
    
    float y, u, v, r, g, b;
    
    y = textureY.sample(samplr, in.textureCoord).r;
    u = textureU.sample(samplr, in.textureCoord).r;
    v = textureV.sample(samplr, in.textureCoord).r;
    u = u - 0.5;
    v = v - 0.5;
    r = y + 1.403 * v;
    g = y - 0.344 * u - 0.714 * v;
    b = y + 1.770 * u;
    
    // B <-> R inverted for old android versions
    return half4(b, g, r, 1.0);
};



