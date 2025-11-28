#import "GPUPixelWrapper.h"
#include <gpupixel/gpupixel.h>

using namespace gpupixel;

@interface GPUPixelWrapper () {
    std::shared_ptr<SourceRawData> _sourceRawData;
    std::shared_ptr<SinkView> _gpuPixelView;
    std::shared_ptr<BeautyFaceFilter> _beautyFaceFilter;
    std::shared_ptr<FaceReshapeFilter> _faceReshapeFilter;
    std::shared_ptr<FaceDetector> _faceDetector;
}
@end

@implementation GPUPixelWrapper

- (instancetype)initWithView:(UIView *)view {
    self = [super init];
    if (self) {
        @try {
            // Initialize GPUPixel Pipeline
            // 1. Create Source
            _sourceRawData = SourceRawData::Create();
            
            // 2. Create View Sink (Render to the UIView)
            _gpuPixelView = SinkView::Create((__bridge void*)view);
            
            // 3. Create Filters
            _beautyFaceFilter = BeautyFaceFilter::Create();
            _faceReshapeFilter = FaceReshapeFilter::Create();
            _faceDetector = FaceDetector::Create();
            
            // 4. Construct Pipeline: Source -> FaceReshape -> Beauty -> View
            _sourceRawData->AddSink(_faceReshapeFilter)->AddSink(_beautyFaceFilter)->AddSink(_gpuPixelView);
            
            // Default: Disable beauty
            [self setBeautyEnabled:NO];
            
            NSLog(@"GPUPixelWrapper initialized successfully");
        } @catch (NSException *exception) {
            NSLog(@"GPUPixelWrapper init failed: %@", exception);
        }
    }
    return self;
}

- (void)processPixelBuffer:(CVPixelBufferRef)imageBuffer {
    if (!_sourceRawData || !imageBuffer) return;
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    int width = (int)CVPixelBufferGetWidth(imageBuffer);
    int height = (int)CVPixelBufferGetHeight(imageBuffer);
    int stride = (int)CVPixelBufferGetBytesPerRow(imageBuffer);
    const uint8_t* pixels = (const uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Detect face landmarks
    std::vector<float> landmarks = _faceDetector->Detect(
        pixels, width, height, stride,
        GPUPIXEL_MODE_FMT_VIDEO, GPUPIXEL_FRAME_TYPE_BGRA
    );
    
    // Apply landmarks to face reshape filter
    if (!landmarks.empty()) {
        _faceReshapeFilter->SetFaceLandmarks(landmarks);
    }
    
    // Feed data to GPUPixel pipeline
    _sourceRawData->ProcessData(pixels, width, height, stride, GPUPIXEL_FRAME_TYPE_BGRA);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

- (void)setBeautyEnabled:(BOOL)enabled {
    @try {
        if (enabled) {
            // Enable full beauty effects
            _beautyFaceFilter->SetBlurAlpha(0.5); // Skin smoothing
            _beautyFaceFilter->SetWhite(0.2);     // Whitening
            _beautyFaceFilter->SetSharpen(0.2);   // Sharpening
            NSLog(@"Beauty enabled");
        } else {
            // Disable effects
            _beautyFaceFilter->SetBlurAlpha(0.0);
            _beautyFaceFilter->SetWhite(0.0);
            _beautyFaceFilter->SetSharpen(0.0);
            NSLog(@"Beauty disabled");
        }
    } @catch (NSException *exception) {
        NSLog(@"setBeautyEnabled failed: %@", exception);
    }
}

- (void)setBeautyParameters:(float)smoothing 
                  whitening:(float)whitening 
                 sharpening:(float)sharpening
                   faceSlim:(float)faceSlim
                 eyeEnlarge:(float)eyeEnlarge {
    @try {
        // 应用美颜参数
        _beautyFaceFilter->SetBlurAlpha(smoothing);
        _beautyFaceFilter->SetWhite(whitening);
        _beautyFaceFilter->SetSharpen(sharpening);
        
        // 应用人脸变形参数
        _faceReshapeFilter->SetFaceSlimLevel(faceSlim);
        _faceReshapeFilter->SetEyeZoomLevel(eyeEnlarge);
        
        NSLog(@"Beauty parameters updated: smoothing=%.2f, whitening=%.2f, sharpening=%.2f, faceSlim=%.2f, eyeEnlarge=%.2f", 
              smoothing, whitening, sharpening, faceSlim, eyeEnlarge);
    } @catch (NSException *exception) {
        NSLog(@"setBeautyParameters failed: %@", exception);
    }
}

- (void)dealloc {
    _sourceRawData = nullptr;
    _beautyFaceFilter = nullptr;
    _faceReshapeFilter = nullptr;
    _faceDetector = nullptr;
    _gpuPixelView = nullptr;
}

@end
