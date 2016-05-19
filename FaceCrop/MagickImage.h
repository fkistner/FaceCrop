//
//  FKMagickImage.h
//  FaceCrop
//
//  Created by Florian Kistner on 13/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger)
{
    Colorspace_sRGB,
    Colorspace_LAB
} Colorspace;

@interface MagickImage : NSObject

@property (nonatomic,readonly) CGSize size;

- (instancetype)initFromFile:(NSString*)path error:(NSError**)error;
- (instancetype)initWithData:(NSData*)data cols:(NSUInteger)cols rows:(NSUInteger)rows;
- (BOOL)writeToFile:(NSString*)path error:(NSError**)error;
- (BOOL)writeToFile:(NSString*)path withQuality:(float)quality error:(NSError**)error;
- (void)withData:(void (^)(NSMutableData* data, NSUInteger cols, NSUInteger rows))action;

- (void)setDepth:(size_t)depth;
- (void)convertToColorspace:(Colorspace)colorspace;
- (void)convertToColorspace:(Colorspace)colorspace ignoreMissingProfile:(BOOL)ignoreMissingProfile;
- (void)resize:(CGSize)size;
- (void)autoLevel;
- (void)autoGamma;
- (void)crop:(CGRect)rect;

@end
