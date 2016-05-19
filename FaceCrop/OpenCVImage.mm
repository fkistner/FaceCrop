//
//  OpenCVImage.m
//  FaceCrop
//
//  Created by Florian Kistner on 14/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

#import "OpenCVImage.h"
#import <array>
#import <opencv2/opencv.hpp>

@implementation OpenCVImage
{
    cv::Mat im;
}

- (instancetype)initWithData:(NSData*)data cols:(int)cols rows:(int)rows
{
    self = [super init];
    if (self != nil)
    {
        im = cv::Mat(rows, cols, CV_32FC3);
        memcpy(im.data, data.bytes, data.length);
    }
    return self;
}

- (void)dealloc
{
    im = cv::Mat();
}

- (void)claheWithClipLimit:(double)clipLimit tileGridSize:(CGSize)tileGridSize
{
    auto clahe = cv::createCLAHE();
    clahe->setClipLimit(clipLimit);
    clahe->setTilesGridSize(cv::Size((int)std::lround(tileGridSize.width), (int)std::lround(tileGridSize.height)));
    
    cv::Mat l(im.rows, im.cols, CV_32FC1);
    std::array<int, 2> from_to_split { 0,0 };
    cv::mixChannels(&im, 1, &l, 1, from_to_split.data(), from_to_split.size()>>1);
    
    l.convertTo(l, CV_8UC1, (1<<8)-1);
    clahe->apply(l, l);
    l.convertTo(l, CV_32FC1, 1./((1<<8)-1));
    
    std::array<int, 6> from_to_merge { 0,0, 2,1, 3,2 };
    std::array<cv::Mat,2> in_merge { l, im };
    cv::mixChannels(in_merge.data(), in_merge.size(), &im, 1, from_to_merge.data(), from_to_merge.size()>>1);
}

- (void)withData:(void (^)(NSData* data, int cols, int rows))action
{
    auto data = [[NSData alloc] initWithBytesNoCopy:im.data length:im.total() * im.elemSize() freeWhenDone:NO];
    action(data, im.cols, im.rows);
}

const std::string cascadePath = "/usr/local/opt/opencv3/share/OpenCV/haarcascades/";
const std::array<std::string, 3> cascadeFiles
{
    cascadePath + "haarcascade_frontalface_default.xml",
    cascadePath + "haarcascade_frontalface_alt.xml",
    cascadePath + "haarcascade_frontalface_alt2.xml"
};

- (CGRect)faceDetect
{
    // get luminance
    cv::Mat l(im.rows, im.cols, CV_32FC1);
    std::array<int, 2> from_to_split { 0,0 };
    cv::mixChannels(&im, 1, &l, 1, from_to_split.data(), from_to_split.size()>>1);
    l.convertTo(l, CV_8UC1, (1<<8)-1);
    
    /*cv::Mat rgb;
    cv::cvtColor(im, rgb, CV_Lab2BGR);
    cv::Mat l;
    cv::cvtColor(rgb, l, CV_BGR2GRAY);*/
    /*cv::imshow("", l);
    cv::waitKey();*/
    
    cv::Size minSize = im.size() / 4;
    
    for(auto &cascadeFile : cascadeFiles)
    {
        cv::CascadeClassifier cascade(cascadeFile);
        
        std::vector<cv::Rect> faces;
        cascade.detectMultiScale(l, faces, 1.05, 5, 0, minSize);
        
        if (faces.size() == 0)
        {
            auto m = cv::getRotationMatrix2D(cv::Point2f(im.rows / 2., im.cols / 2.), -20, 1);
            cv::Mat rot(im.rows, im.cols, CV_32FC1);
            cv::warpAffine(l, rot, m, im.size());
            
            cascade.detectMultiScale(rot, faces, 1.05, 5, 0, minSize);
            
            cv::invertAffineTransform(m, m);
            for(auto &face : faces)
            {
                cv::Point2f mid((face.tl() + face.br()) / 2.);
                std::vector<cv::Point2f> facePoints { mid, mid };
                cv::transform(facePoints, facePoints, m);
                auto midRot = facePoints[0] - cv::Point2f(face.size().width / 2., face.size().height / 2.);
                face = cv::Rect2i(midRot, face.size());
            }
        }
        
        if (faces.size() == 1)
        {
            auto face = faces[0];
            //cv::rectangle(im, face, cv::Scalar(0,0,0,1));
            return CGRectMake(face.x, face.y, face.width, face.height);
        }
    }
    return CGRectNull;
}

/*- (void)show 
{
    cv::Mat sim(im.rows, im.cols, CV_8UC3);
    im.convertTo(sim, CV_8UC3, (1<<8)-1);
    cv::cvtColor(sim, sim, cv::COLOR_Lab2BGR);
    
    cv::imshow("", sim);
    cv::waitKey();
}*/

- (void)crop:(CGRect)rect
{
    cv::Rect r((int)std::lround(rect.origin.x),   (int)std::lround(rect.origin.y),
               (int)std::lround(rect.size.width), (int)std::lround(rect.size.height));
    im(r).copyTo(im);
}

@end