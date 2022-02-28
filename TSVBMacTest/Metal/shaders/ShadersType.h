//
//  ShadersType.h
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-28.
//

#ifndef ShadersType_h
#define ShadersType_h

#include <simd/simd.h>

// Vertex input/output structure for passing results from vertex shader to fragment shader

typedef struct
{
    //vector_float4 _u_inner_leftbottom;
    //vector_float4 _u_inner_righttop;
    vector_float2 _u_t_inner_leftbottom;
    vector_float2 _u_t_inner_righttop;
} PipUniform;

typedef struct
{
    vector_float4 _u_inner_lefttop;
    vector_float4 _u_inner_rightbottom;
} PipMtlUniform;


typedef struct
{
    float _progress;
    float _u_is_forward_direction;
    int _u_split_coord;
} TransitionUniform;
//typedef struct
//{
//    vector_float4 _u_inner_leftbottom;
//    vector_float4 _u_inner_righttop;
//} PipVertexUniform;

typedef struct
{
    float _u_x_resolution;
    float _u_y_resolution;
    float _u_time;
    float _u_pixel_scale;
} McEffectsUniform;

typedef struct {
    //vector_float2 _u_object_position;
    //vector_float2 _u_object_rect;
    vector_float2 _u_object_inner_leftbottom;
    vector_float2 _u_object_inner_righttop;
} McEffectObjectsDataUniform;

typedef struct
{
    McEffectObjectsDataUniform uniform;
    size_t pItem;
} McEffectObjectsUniform;

typedef struct
{
    float alpha;
} SegmentUniform;

#endif /* ShadersType_h */
