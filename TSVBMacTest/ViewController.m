//
//  ViewController.m
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-21.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

#import "BaseVBReplacer.h"
#import "MCVBReplacer.h"
#import "MCMtlPixelBufferView.h"
#import "AAPLRenderer.h"

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    BaseVBReplacer * _cvReplacer;
    MCMtlPixelBufferView * _mtlView;
    
    MTKView * _mtkView;
    AAPLRenderer *_renderer;
    
    CALayer * _outputLayer;
}

@property (nonatomic, weak) IBOutlet NSView *videoPreviewView;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
   
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void) awakeFromNib {
    [super awakeFromNib];
    
    [self initSetup];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(switchSpace)
                                                               name:NSWorkspaceActiveSpaceDidChangeNotification
                                                             object:[NSWorkspace sharedWorkspace]];
}

- (void)initSetup {
    //[self createMtlView];
    [self setupReplacer];
    [self setupCaptureSession];
    [self setupOutputLayer];
}

- (void)viewWillLayout {
    [super viewWillLayout];
    [self layoutMtlView];
}

- (void)viewDidLayout {
    [super viewDidLayout];
    [self layoutMtlView];
    
}

- (void)layoutMtlView {
    if (_mtlView) {
        _mtlView.frame = [self getMetalViewRect];
    }
}

- (void)layoutMtkView {
    if (_mtkView) {
        _mtkView.frame = [self getMetalViewRect];
    }
}

- (CGRect)getMetalViewRect {
    CGRect frame = _videoPreviewView.frame;
    CGRect ret = CGRectMake(frame.origin.x, frame.origin.y / 2.0, frame.size.width / 2.0, frame.size.height / 2.0);
    return ret;
    
}
- (void)createMtlView {
    if (!_mtlView) {
        _mtlView = [[MCMtlPixelBufferView alloc] initWithFrame:CGRectZero];
        [self.view addSubview:_mtlView];
        NSWindowOrderingMode mode = NSWindowAbove;
        [self.view addSubview:_mtlView positioned:mode relativeTo:_videoPreviewView];
    }
}

- (void)createMtkView {
    if (_mtkView) {
        _mtkView = [[MTKView alloc] initWithFrame:CGRectZero];
    }
}

- (void)setupOutputLayer
{
    if (!_outputLayer) {
        _outputLayer = [CALayer layer];
        _outputLayer.bounds = CGRectMake(0, 0, 640, 360);
        _outputLayer.position = CGPointMake(0, 0);
        _outputLayer.anchorPoint = CGPointMake(0, 0);
        _outputLayer.borderWidth = 1.0;
        _outputLayer.borderColor = [NSColor whiteColor].CGColor;
        _outputLayer.backgroundColor = [NSColor blackColor].CGColor;

        [_videoPreviewView.layer addSublayer:_outputLayer];
    }
}

- (void)setupReplacer {
    if (!_cvReplacer) {
        _cvReplacer = [[MCVBReplacer alloc] init];
    }
}

- (BOOL)setupCaptureSession {
    
    if (_session) {
        return YES;
    }
    
    NSError *error = nil;
    _session = [[AVCaptureSession alloc] init];
    if (!_session) {
        NSLog(@"Cannot add video capture session.");
        return NO;
    }
    _session.sessionPreset = AVCaptureSessionPresetMedium;
    
    // Find a suitable AVCaptureDevice
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if(!device) {
        NSLog(@"Cannot create video device.");
        return NO;
    }
    
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        NSLog(@"Cannot create video input.");
        return NO;
    }
    [_session addInput:input];
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    if (!output) {
        NSLog(@"Cannot create video output.");
        return NO;
    }
    output.videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : @( kCVPixelFormatType_32BGRA ) };
    if ([_session canAddOutput:output]) {
        dispatch_queue_t queue = dispatch_queue_create("videoCaptureQueue", NULL);
        [output setSampleBufferDelegate:self queue:queue];
        [_session addOutput:output];
    } else {
        NSLog(@"Cannot add video output.");
        return NO;
    }
    
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _previewLayer.name = @"videoPreview";
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame = CGRectMake (0, 0, _videoPreviewView.frame.size.width, _videoPreviewView.frame.size.height);
    
    _previewLayer.affineTransform = CGAffineTransformMakeScale (-1,1);
    
    [_videoPreviewView setWantsLayer:YES];
    [_videoPreviewView.layer addSublayer:_previewLayer];
#if 0
    _outputLayer = [[CALayer alloc] init];
    _outputLayer.name = @"vbOutput";
    _outputLayer.frame = CGRectMake (0, 0, _videoPreviewView.frame.size.width, _videoPreviewView.frame.size.height);
    _outputLayer.affineTransform = CGAffineTransformMakeScale (-1,1);
    [_videoPreviewView.layer addSublayer:_outputLayer];
#endif
    
    [_session setSessionPreset:AVCaptureSessionPresetMedium];
    
    if ([_session canSetSessionPreset:AVCaptureSessionPresetLow])  {
        //Check size based configs are supported before setting them
        [_session setSessionPreset:AVCaptureSessionPresetLow];
    }
    
    [_session startRunning];
    
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification {
    [_session stopRunning];
    if (_cvReplacer) {
        [_cvReplacer releaseFactoryResource];
    }
}

- (void) switchSpace {
    [[self.view window] orderFront:self];
}

/*!
    Callback method to be called when the video data is updated.
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    dispatch_sync(dispatch_get_main_queue(), ^(void) {
        // Get an image from the sample buffer.
        [self captureFrameForVB:sampleBuffer];

        // Set the interval for image acquisition.
        //[NSThread sleepForTimeInterval:0.5];
    });
}

- (void)captureFrameForVB:(CMSampleBufferRef _Nonnull)sampleBuffer {
    //CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription( sampleBuffer );
    CVPixelBufferRef sourceBuffer = CMSampleBufferGetImageBuffer( sampleBuffer );

    CVPixelBufferRef pixelBufferBeforeRunOn = nil;
    if (_cvReplacer) {
        pixelBufferBeforeRunOn = [_cvReplacer processPixelBuffer:sourceBuffer];
        if (pixelBufferBeforeRunOn) {
            //dispatch_async(dispatch_get_main_queue(), ^{
                //[_mtlView displayVideoPixelBuffer:pixelBufferBeforeRunOn];
                //[_mtlView flushPixelBufferCache];

                if (self->_outputLayer) {

                    CGImageRef cgOutput = [self getCGImageFromCVPixelBuffer:pixelBufferBeforeRunOn];
                    if (cgOutput) {
                        self->_outputLayer.contents = (__bridge id)(cgOutput);
                        CGImageRelease(cgOutput);
                        cgOutput = nil;
                    }

                    CFRelease(pixelBufferBeforeRunOn);
                }
                
            //});
            
        }
    } else {
        
    }


}

- (CGImageRef)getCGImageFromCVPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer) {
        return NULL;
    }
    CGImageRef ret;
    
    OSStatus err = VTCreateCGImageFromCVPixelBuffer(pixelBuffer, nil, &ret);
    return ret;
}

@end
