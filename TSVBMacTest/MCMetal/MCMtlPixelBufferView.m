//
//  VBMtlPixelBufferView.m
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-28.
//

#import "MCMtlPixelBufferView.h"
#import "MCMtlRendering.h"

#import "MCAppResolution.h"

#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>
@import Metal;
@import CoreMedia;

@interface MCMtlPixelBufferView () {
    dispatch_semaphore_t _semaphore;
    CVMetalTextureCacheRef _textureCache;
    dispatch_queue_t _queue;
    
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;
    id <MTLLibrary> _library;
    
    id <MTLBuffer>  _vertexBuffer;
    id <MTLBuffer>  _texCoordBuffer;
    id <MTLRenderPipelineState> _renderPipelineState;
    id <MTLSamplerState> _defaultSampleState;
    
    id <CAMetalDrawable> _currentDrawable;
    CAMetalLayer * _metalLayer;
    
    CVMetalTextureRef _textureSrcRef;
    
    CMVideoDimensions _outputRes;
}
// the current drawable created within the view's CAMetalLayer
@property (nonatomic) id <CAMetalDrawable> currentDrawable;
// The current framebuffer can be read by delegate during -[MetalViewDelegate render:]
// This call may block until the framebuffer is available.
@property (nonatomic) MTLRenderPassDescriptor *renderPassDescriptor;
@end

@implementation MCMtlPixelBufferView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)setIsTransparentView:(BOOL)isTransparentView {
    @synchronized (self) {
        _isTransparentView = isTransparentView;
        if (!_metalLayer) {
            _metalLayer = (CAMetalLayer *)self.layer;
        }
        if (_isTransparentView) {
            _metalLayer.opaque = NO;
        } else {
            _metalLayer.opaque = YES;
        }
    }
}

+ (Class)layerClass {
    return [CAMetalLayer class];
}

- (void)setupRenderPassDescriptorForTexture:(id <MTLTexture>) texture
{
    // create lazily
    if(_renderPassDescriptor == nil)
    {
        _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        if (!_renderPassDescriptor) {
            NSLog(@">> ERROR: Failed to create renderPassDescriptor!");
            return;
        }
    }
    
    // create a color attachment every frame since we have to recreate the texture every frame
    MTLRenderPassColorAttachmentDescriptor *colorAttachment = _renderPassDescriptor.colorAttachments[0];
    colorAttachment.texture = texture;
    
    // make sure to clear every frame for best performance
    colorAttachment.loadAction = MTLLoadActionClear;
    colorAttachment.storeAction = MTLStoreActionStore;
    if (_isTransparentView) {
        colorAttachment.clearColor = MTLClearColorMake(0.0f, 0.0f, 0.0f, 0.0f);
    } else {
        colorAttachment.clearColor = MTLClearColorMake(0.0f, 0.0f, 0.0f, 1.0f);
    }
}

- (MTLRenderPassDescriptor *)renderPassDescriptor
{
    id <CAMetalDrawable> drawable = self.currentDrawable;
    if(!drawable) {
        NSLog(@">> ERROR: Failed to get a drawable!");
        _renderPassDescriptor = nil;
    } else {
        [self setupRenderPassDescriptorForTexture: drawable.texture];
    }
    
    return _renderPassDescriptor;
}

- (id <CAMetalDrawable>)currentDrawable
{
    if (_currentDrawable == nil) {
        _currentDrawable = [_metalLayer nextDrawable];
    }
    
    return _currentDrawable;
}

- (BOOL)preparePipelineState {
    // get the fragment function from the library
    id <MTLFunction> fragmentProgram = [_library newFunctionWithName:@"fragmentPassThrough"];
    
    // get the vertex function from the library
    id <MTLFunction> vertexProgram = [_library newFunctionWithName:@"vertexPassThrough"];
    
    //  create a pipeline state for the quad
    MTLRenderPipelineDescriptor *passthroughtStateDescriptor = [MTLRenderPipelineDescriptor new];
    passthroughtStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    passthroughtStateDescriptor.sampleCount      = 1;
    passthroughtStateDescriptor.vertexFunction   = vertexProgram;
    passthroughtStateDescriptor.fragmentFunction = fragmentProgram;
    
    NSError *pError = nil;
    _renderPipelineState = [_device newRenderPipelineStateWithDescriptor:passthroughtStateDescriptor error:&pError];
    if(!_renderPipelineState)
    {
        NSLog(@">> ERROR: Failed acquiring pipeline state descriptor: %@", pError);
        return NO;
    } // if
    
    return YES;
}

- (BOOL)prepareSamplerState {
    MTLSamplerDescriptor * samplerDescriptor = [self buildMtlLinearSamplerDescriptor];
    if (!samplerDescriptor) {
        NSLog(@">> %@ ERROR: Failed to buildMtlNearestSamplerDescriptor", self.description);
        return NO;
    }
    _defaultSampleState = [_device newSamplerStateWithDescriptor:samplerDescriptor];
    if (!_defaultSampleState) {
        NSLog(@">> %@ ERROR: Failed to prepareSamplerState", self.description);
        return NO;
    }
    return YES;
}

- (BOOL)prepareDataBuffers {
    const uint32_t kVertexCount = 4 * 4;
    const uint32_t kVertexSize = kVertexCount * sizeof(float);
    
    float squareVertices[kVertexSize] = {
                                                     -1.0, -1.0, 0.0, 1.0, // bottom left
                                                     1.0, -1.0,  0.0, 1.0, // bottom right
                                                     -1.0,  1.0,  0.0, 1.0, // top left
                                                     1.0,  1.0,  0.0, 1.0 // top right
    };
    MTLResourceOptions bufferOption = MTLResourceOptionCPUCacheModeDefault;
    if (@available(iOS 9.0, *)) {
        bufferOption = MTLResourceStorageModeShared;
    }
    _vertexBuffer = [_device newBufferWithBytes:squareVertices length:kVertexSize options:bufferOption];
    if (!_vertexBuffer) {
        NSLog(@">>%@ ERROR: Failed creating a vertex buffer!", self.description);
        return NO;
    }
    _vertexBuffer.label = @"MetalView vertices";
    
    const uint32_t kTexCoordCount = 2 * 4;
    const uint32_t kTexCoordSize = kTexCoordCount * sizeof(float);
    
    float passThroughTextureVertices[kTexCoordSize] = { //It is a metal texture coordinate, it does not need flip.
                                               0.0, 1.0, // bottom left
                                               1.0, 1.0, // bottom right
                                               0.0, 0.0, // top left
                                               1.0, 0.0 // top right
    };
    _texCoordBuffer = [_device newBufferWithBytes:passThroughTextureVertices length:kTexCoordSize options:bufferOption];
    if (!_texCoordBuffer) {
        NSLog(@">>%@ ERROR: Failed creating a texCoord buffer!", self.description);
        return NO;
    }
    _vertexBuffer.label = @"MetalView texCoord";
    return YES;
}

- (BOOL)configMetal {
    _device = [MCMtlRendering sharedInstance].sharedDevice;
    _commandQueue = [MCMtlRendering sharedInstance].sharedCommandQueue;
    _library = [MCMtlRendering sharedInstance].sharedLibrary;
    
    if (!(_device && _commandQueue && _library)) {
        return NO;
    }
    
    return YES;
}

- (BOOL)createTextureCache {
    CVReturn textureCacheError = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, _device, NULL, &_textureCache);
    if (textureCacheError) {
        NSLog(@">> %@ ERROR: Could not create a texture cache", self.description);
        assert(0);
        return NO;
    }
    return YES;
}

- (BOOL)setupMetal {
    
    _outputRes = [MCAppResolution sizeForType:MCAppResolutionType_720p];
    
    if (![self configMetal]) {
        return NO;
    }
    if (![self createTextureCache]) {
        return NO;
    }
    if (![self prepareDataBuffers]) {
        return NO;
    }
    if (![self preparePipelineState]) {
        return NO;
    }
    if (![self prepareSamplerState]) {
        return NO;
    }
    //self.contentScaleFactor = [UIScreen mainScreen].nativeScale;
    _isCrop = NO;
    _metalLayer = (CAMetalLayer *)self.layer;
    //AVSampleBufferDisplayLayer * eaglLayer = (AVSampleBufferDisplayLayer *)self.layer;
    if (_isTransparentView) {
        _metalLayer.opaque = NO;
    } else {
        _metalLayer.opaque = YES;
    }
    //_metalLayer.device = self.
    _metalLayer.contentsScale = [NSScreen mainScreen].backingScaleFactor;
    _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    _metalLayer.frame = self.bounds;
    _metalLayer.framebufferOnly = false; //To support sampling.
    
    _queue = dispatch_queue_create( "net.vmn.metalview.video", DISPATCH_QUEUE_SERIAL );
    dispatch_set_target_queue( _queue, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0 ) );
    
    _semaphore = dispatch_semaphore_create(1);
    
    return YES;
}

- (instancetype)initWithFrame:(CGRect)frame withTransparent:(BOOL)isTransparent {
    _isTransparentView = isTransparent;
    return [self initWithFrame:frame];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if ( self )
    {
        if (![self setupMetal]) {
            return nil;
        }
    }
    return self;
}

- (void)doFlushPixelBufferCache {
    if ( _textureCache ) {
        CVMetalTextureCacheFlush(_textureCache, 0);
    }
}

- (void)flushPixelBufferCache {
    //[self lock];
    [self doFlushPixelBufferCache];
    //[self unlock];
}

- (void)reset {
    BOOL notTimeout = [self lock];
    if (notTimeout) {
        [self doResetForRenderPass];
        [self doResetForInit];
        [self unlock];
    } else {
        [self unCleanReset];
    }
}

- (void)unCleanReset { //Temp workround for SPRINGBOARD, Code 0x8badf00d
    
    if ( _textureCache ) {
        CVMetalTextureCacheFlush(_textureCache, 0);
    }
    
    if (_textureSrcRef) {
        //CFRelease(_textureSrcRef);
        _textureSrcRef = NULL;
    }
    
    if (_textureCache) {
        //CFRelease(_textureCache);
        _textureCache = NULL;
    }
}

- (void)doResetForRenderPass {
    [self doFlushPixelBufferCache];
    if (_textureSrcRef) {
        CFRelease(_textureSrcRef);
        _textureSrcRef = NULL;
    }
}

- (void)doResetForInit {
    if (_textureCache) {
        CFRelease(_textureCache);
        _textureCache = NULL;
    }
}

- (BOOL)lock {
    BOOL ret = NO;
    if (_semaphore) {
#if DEBUG
        dispatch_time_t timeWaitForLock = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);//DISPATCH_TIME_FOREVER;
#else
        dispatch_time_t timeWaitForLock = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);//DISPATCH_TIME_FOREVER;
#endif
        long wait = dispatch_semaphore_wait(_semaphore, timeWaitForLock);
        if (wait) {
            ret = NO;
        } else {
            ret = YES;
        }
    }
    return ret;
}

- (BOOL)tryLock {
    return (dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_NOW) == 0);
}

- (void)unlock {
    if (_semaphore) {
        dispatch_semaphore_signal(_semaphore);
    }
}

- (void)dealloc {
    [self reset];
}

- (void)displayVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    // use non blocking semaphore to drop frame if we have another in queue to draw
    if (![self tryLock]) {
        return;
    }
    
    dispatch_async(_queue, ^{
        
        if (!_semaphore) { // just in case it is destroyed in another thread
            return;
        }
        
        [self displayVideoFrameInternal:pixelBuffer];
        _currentDrawable = nil;
        [self unlock];
    });
}

- (void)displayVideoFrameInternal:(CVPixelBufferRef)pixelBuffer {
    
    if ( pixelBuffer == NULL ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL pixel buffer" userInfo:nil];
        return;
    }
    
    size_t frameWidth, frameHeight;
    
    frameWidth = CVPixelBufferGetWidth( pixelBuffer );
    frameHeight = CVPixelBufferGetHeight( pixelBuffer );
    
    
    // avoid blinkage for late frame with wrong rotation
    BOOL isFramePortrait = NO;
    BOOL isDrawInPortrait = NO;
    
    if (isFramePortrait != isDrawInPortrait) {
        // TODO still draw the frame
        //NSLog(@"Drop drawing late frame during rotation");
        return;
    }
    
    if (!_textureCache) {
        [self createTextureCache];
    }
    
    CVReturn error;
    
    error = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, frameWidth, frameHeight, 0, &_textureSrcRef);
    if (error) {
        NSLog(@">> ERROR: Couldnt create texture from image");
        assert(0);
        [self doResetForRenderPass];
        return;
    }
    
    id <MTLTexture> textureSrc = CVMetalTextureGetTexture(_textureSrcRef);
    if (nil == textureSrc) {
        NSLog(@">> ERROR: Couldn't get texture from texture ref");
        assert(0);
        NSLog(@">> ERROR: Couldn't get texture from texture ref");
        assert(0);
    }

    [self setupDataBuffers];
    
    //[self startCaptureScope];
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    if (commandBuffer == nil) {
        NSLog(@">> ERROR: Failed to create Metal command buffer");
        assert(0);
        [self doResetForRenderPass];
        return;
    }
    
    if (!self.renderPassDescriptor) { //For bug 7127, fix for "[CAMetalLayer nextDrawable] returning nil because device is nil", to make sure currentDrawable is valid.
        NSLog(@">> ERROR: Failed to setup Metal render pass descriptor");
        return;
    }
    commandBuffer.label = self.description;
    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:self.renderPassDescriptor];
    if (renderEncoder == nil) {
        NSLog(@">> ERROR: Failed to create Metal command render enconder");
        assert(0);
        [self doResetForRenderPass];
        return;
    }
    
    renderEncoder.label = @"MCMtlPixelBufferView Display";
    [renderEncoder pushDebugGroup:@"MCMtlPixelBufferView Display"];
    [renderEncoder setRenderPipelineState:_renderPipelineState];
    [renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:_texCoordBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentTexture:textureSrc atIndex:0];
    [renderEncoder setFragmentSamplerState:_defaultSampleState atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [renderEncoder endEncoding];
    
    [commandBuffer presentDrawable:self.currentDrawable];
    [commandBuffer commit];
    //[self endCaptureScope];
    
    [self doResetForRenderPass];
    
}

- (void)resetPassThroughTextureVertices {
    if (_texCoordBuffer != nil) {
        float * pTexCoord = (float *)[_texCoordBuffer contents];
        if (pTexCoord != NULL) {
            pTexCoord[0] = 0.0; pTexCoord[1] = 1.0;
            pTexCoord[2] = 1.0; pTexCoord[3] = 1.0;
            pTexCoord[4] = 0.0; pTexCoord[5] = 0.0;
            pTexCoord[6] = 1.0; pTexCoord[7] = 0.0;
        }
    }
}

- (void)setupDataBuffers {
    [self resetPassThroughTextureVertices];
    float * passThroughTextureVertices = NULL;
    if (_texCoordBuffer) {
        passThroughTextureVertices = (float *)[_texCoordBuffer contents];
        if (!passThroughTextureVertices) {
            return;
        }
    }
    
    if (self.isCrop) {
        // position of texture preview on frame
        float textureHeightRatio = 1.0f;
        float textureWidthRatio = 1.0f;
        
        CMVideoDimensions outputRes = _outputRes;
        CMVideoDimensions outputPortraitRes = {.width = outputRes.height, .height = outputRes.width}; // we always draw in portrait
        CGFloat viewWidth =  _metalLayer.drawableSize.width;
        CGFloat viewHeight = _metalLayer.drawableSize.height;
        CMVideoDimensions viewRes = {.width = viewWidth, .height = viewHeight};
        
        BOOL sameRatio = [MCAppResolution sameRatioForResolution:outputPortraitRes andResolution:viewRes];
        
        float lessSideRatio = 1.0f;
        
        if (!sameRatio) { // make crop if ratio is different
            lessSideRatio = (viewWidth / (float)viewHeight); // now: 3.0 / 4.0
        }
        //Perform a vertical flip by swapping the top left and the bottom left coordinate.
        // CVPixelBuffers have a top left origin and OpenGL has a bottom left origin.
        if (1)
        {
            textureHeightRatio = lessSideRatio;
            CGSize textureSamplingSize = CGSizeMake(textureWidthRatio, textureHeightRatio);
            
            // top left
            passThroughTextureVertices[0] =     ( 1.0 - textureSamplingSize.width ) / 2.0;
            passThroughTextureVertices[1] =     ( 1.0 + textureSamplingSize.height ) / 2.0;
            // top right
            passThroughTextureVertices[2] =     ( 1.0 + textureSamplingSize.width ) / 2.0;
            passThroughTextureVertices[3] =     ( 1.0 + textureSamplingSize.height ) / 2.0;
            // bottom left
            passThroughTextureVertices[4] =     ( 1.0 - textureSamplingSize.width ) / 2.0;
            passThroughTextureVertices[5] =     ( 1.0 - textureSamplingSize.height ) / 2.0;
            // bottom right
            passThroughTextureVertices[6] =     ( 1.0 + textureSamplingSize.width ) / 2.0;
            passThroughTextureVertices[7] =     ( 1.0 - textureSamplingSize.height ) / 2.0;
            
        }
    }
}

- (void)setOutputVideoResolution:(CMVideoDimensions)outputRes {
    _outputRes = outputRes;
}

#pragma mark Helper functions
- (MTLSamplerDescriptor *)buildMtlLinearSamplerDescriptor {
    MTLSamplerDescriptor * samplerDescriptor = [MTLSamplerDescriptor new];
    if (!samplerDescriptor) {
        NSLog(@">> ERROR: Failed to new MTLRenderPipelineDescriptor");
        return nil;
    }
    samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    
    return samplerDescriptor;
}
@end
