//
//  Renderer.metal
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-28.
//

#include <metal_stdlib>
using namespace metal;

#import "SharedShadersType.h"
#import "ShadersType.h"

// Vertex shader for a textured quad
vertex VertexIO vertexDefaultRenderer(const device packed_float4 *pPosition  [[ buffer(0) ]],
                                      const device packed_float2 *pTexCoords [[ buffer(1) ]],
                                      uint                  vid        [[ vertex_id ]])
{
    VertexIO outVertex;
    
    outVertex.position = pPosition[vid];
    outVertex.textureCoord = pTexCoords[vid];
//    float2 oldTextureCoord = pTexCoords[vid];
//    outVertex.textureCoord.x = oldTextureCoord.x;
//    outVertex.textureCoord.y = 1.0 - oldTextureCoord.y;
    
    return outVertex;
}

// Fragment shader for a textured quad
fragment half4 fragmentDefaultRenderer(VertexIO         inputFragment [[ stage_in ]],
                                       texture2d<half> inputTexture  [[ texture(0) ]],
                                       constant        McEffectsUniform &uniforms [[ buffer(2) ]],
                                       sampler         samplr        [[ sampler(0) ]]
                                       )
{
//    constexpr sampler samplr(s_address::clamp_to_edge,
//                             t_address::clamp_to_edge,
//                             min_filter::linear,
//                             mag_filter::linear
//                             );
    return inputTexture.sample(samplr, inputFragment.textureCoord);
    
//    float2 position = inputFragment.textureCoord;
//    //position.y = 1.0 - position.y;
//    return inputTexture.sample(samplr, position);
}

