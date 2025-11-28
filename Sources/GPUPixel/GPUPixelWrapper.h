#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface GPUPixelWrapper : NSObject

/// Initialize with the view where the video should be rendered
- (instancetype)initWithView:(UIView *)view;

/// Process a video frame
- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/// Toggle beauty filter
- (void)setBeautyEnabled:(BOOL)enabled;

/// Set beauty parameters with custom values
- (void)setBeautyParameters:(float)smoothing 
                  whitening:(float)whitening 
                 sharpening:(float)sharpening
                   faceSlim:(float)faceSlim
                 eyeEnlarge:(float)eyeEnlarge;

@end

NS_ASSUME_NONNULL_END
