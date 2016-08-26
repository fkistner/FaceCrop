//
//  OpenCV.m
//  FaceCrop
//
//  Created by Florian Kistner on 12/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FaceCrop-swift.h"
#import <cmath>
#import "MagickImage.h"
#import <Magick++.h>

@implementation MagickImage
{
    Magick::Image image;
}

static Magick::Blob sRGBProfile;
static Magick::Blob labProfile;

+ (void)initialize
{
    Magick::InitializeMagick("");
    auto sRGBProfileData =
        [[NSData alloc] initWithContentsOfFile:@"/System/Library/ColorSync/Profiles/sRGB Profile.icc"];
    auto labProfileData =
        [[NSData alloc] initWithContentsOfFile:@"/System/Library/ColorSync/Profiles/Generic Lab Profile.icc"];
    sRGBProfile = Magick::Blob([sRGBProfileData bytes], [sRGBProfileData length]);
    labProfile = Magick::Blob([labProfileData bytes], [labProfileData length]);
}

BOOL errorFromException(Magick::Exception &e, NSError **error)
{
    if (error != nil)
    {
        auto info = @{ NSLocalizedFailureReasonErrorKey: [NSString stringWithCString:e.what()
                                                                            encoding:NSUTF8StringEncoding] };
        *error = [[ExceptionError alloc] initWithInfo:info];
    }
    return NO;
}

- (instancetype)initFromFile:(NSString *)path error:(NSError**)error
{
    self = [super init];
    if (self != nil)
    {
        try {
            auto p = std::string([path UTF8String]);
            image = Magick::Image(p);
            return self;
        } catch (Magick::Exception e) {
            errorFromException(e, error);
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithData:(NSData*)data cols:(NSUInteger)cols rows:(NSUInteger)rows
{
    self = [super init];
    if (self != nil)
    {
        image.read(cols, rows, "RGB", Magick::FloatPixel, data.bytes);
        image.colorspaceType(Magick::LabColorspace);
        image.iccColorProfile(labProfile);
    }
    return self;
}

- (void)dealloc
{
    image = Magick::Image();
}

- (BOOL)writeToFile:(NSString*)path error:(NSError**)error
{
    return [self writeToFile:path withQuality:.95 error:error];
}

- (BOOL)writeToFile:(NSString*)path withQuality:(float)quality error:(NSError**)error
{
    try
    {
        image.quality((int)std::lround(quality * 100));
        image.type(Magick::OptimizeType);
        image.write(std::string([path UTF8String]));
        return YES;
    } catch (Magick::Exception e) {
        return errorFromException(e, error);
    }
}

- (void)withData:(void (^)(NSMutableData* data, NSUInteger cols, NSUInteger rows))action
{
    auto cols = image.columns(); auto rows = image.rows();
    auto data = [NSMutableData dataWithLength:cols * rows * 3 * sizeof(float)];
    image.write(0, 0, cols, rows, "RGB", Magick::FloatPixel, data.mutableBytes);
    action(data, cols, rows);
}


- (void)setDepth:(size_t)depth
{
    image.depth(depth);
}

- (void)convertToColorspace:(Colorspace)colorspace
{
    [self convertToColorspace:colorspace ignoreMissingProfile:NO];
}

- (void)convertToColorspace:(Colorspace)colorspace ignoreMissingProfile:(BOOL)ignoreMissingProfile
{
//    auto info = image.imageInfo();
//    if (info->profile == nullptr)
//        image.iccColorProfile(sRGBBlob);
    auto prevColorSpace = image.colorSpace();
    image.iccColorProfile(colorspace == Colorspace_sRGB
                              ? sRGBProfile
                              : labProfile);
    auto afterColorSpace = image.colorSpace();
    assert(ignoreMissingProfile || prevColorSpace != afterColorSpace);
    
    auto setColorspace = colorspace == Colorspace_sRGB
                              ? Magick::sRGBColorspace
                              : Magick::LabColorspace;
    
    if (afterColorSpace != setColorspace)
    {
        if (colorspace == Colorspace_sRGB)
            NSLog(@"No profile conversion");

        try
        {
            image.colorSpace(setColorspace);
        }
        catch (Magick::Warning e)
        {
            NSLog(@"%s", e.what());
        }
    }
}

- (void)resize:(CGSize)size
{
    Magick::Geometry geometry(std::lround(size.width), std::lround(size.height));
    image.filterType(Magick::MitchellFilter);
    image.resize(geometry);
}

- (void)autoLevel
{
    image.autoLevel();
}

- (void)autoGamma
{
    image.autoGamma();
}

- (void)crop:(CGRect)rect
{
    Magick::Geometry g(std::lround(rect.size.width), std::lround(rect.size.height), std::lround(rect.origin.x), std::lround(rect.origin.y));
    image.crop(g);
}

- (CGSize)size
{
    return CGSizeMake(image.columns(), image.rows());
}

@end