//
//  OpenCVImage.h
//  FaceCrop
//
//  Created by Florian Kistner on 14/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OpenCVImage : NSObject

- (instancetype)initWithData:(NSMutableData*)data cols:(int)cols rows:(int)rows;
- (void)withData:(void (^)(NSData* data, int cols, int rows))action;

- (void)claheWithClipLimit:(double)clipLimit tileGridSize:(CGSize)tileGridSize;
- (CGRect)faceDetect;
- (void)crop:(CGRect)rect;
//- (void)show;

@end
