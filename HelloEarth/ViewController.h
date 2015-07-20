//
//  ViewController.h
//  HelloEarth
//
//  Created by Chris Lamb on 7/14/15.
//  Copyright (c) 2015 com.SantaCruzNewspaperTaxi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WhirlyGlobeComponent.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate>
{
    NSOperationQueue *opQueue;
}

@end

