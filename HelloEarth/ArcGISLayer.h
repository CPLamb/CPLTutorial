//
//  ArcGISLayer.h
//  HelloEarth
//
//  Created by Chris Lamb on 7/8/15.
//  Copyright (c) 2015 com.SantaCruzNewspaperTaxi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WhirlyGlobeComponent.h>

@interface ArcGISLayer : NSObject <MaplyPagingDelegate>
{
    NSString *search;
    NSOperationQueue *opQueue;
    NSInteger zoneNumber;
}

@property (nonatomic, assign) int minZoom, maxZoom;

- (id)initWithSearch:(NSString *)search;

@end
