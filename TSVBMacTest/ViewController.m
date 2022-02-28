//
//  ViewController.m
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-21.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "BaseVBReplacer.h"
#import "MCVBReplacer.h"

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    BaseVBReplacer * _cvReplacer;
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
    [self setupReplacer];
    [self setupCaptureSession];
}

- (void)setupReplacer {
    if (!_cvReplacer) {
        _cvReplacer = [[MCVBReplacer alloc] init];
    }
}

- (BOOL)setupCaptureSession {
    
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
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription( sampleBuffer );
    CVPixelBufferRef sourceBuffer = CMSampleBufferGetImageBuffer( sampleBuffer );
    CVPixelBufferRef pixelBufferBeforeRunOn = nil;
    if (_cvReplacer) {
        pixelBufferBeforeRunOn = [_cvReplacer processPixelBuffer:sourceBuffer];
    } else {
        
    }
}
@end
