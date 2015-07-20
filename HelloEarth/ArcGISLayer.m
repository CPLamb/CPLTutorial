//
//  ArcGISLayer.m
//  HelloEarth
//
//  Created by Chris Lamb on 7/8/15.
//  Copyright (c) 2015 com.SantaCruzNewspaperTaxi. All rights reserved.
//

#import "ArcGISLayer.h"

@implementation ArcGISLayer


- (id)initWithSearch:(NSString *)inSearch
{
    self = [super init];
    search = inSearch;
    opQueue = [[NSOperationQueue alloc] init];
    
    return self;
}

- (void)startFetchForTile:(MaplyTileID)tileID forLayer:(MaplyQuadPagingLayer *)layer
{
    // bounding box for tile
    MaplyBoundingBox bbox;
    [layer geoBoundsforTile:tileID ll:&bbox.ll ur:&bbox.ur];
    NSURLRequest *urlReq = [self constructRequest:bbox];
    
    // kick off the query asychronously
    [NSURLConnection
     sendAsynchronousRequest:urlReq
     queue:opQueue
     completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         NSLog(@"Returned data is %d", data.length);
         // parse the resulting GeoJSON
         MaplyVectorObject *vecObj = [MaplyVectorObject VectorObjectFromGeoJSON:data];
         
         if (vecObj)
         {
             // display a transparent filled polygon
             MaplyComponentObject *filledObj =
             [layer.viewC
              addVectors:@[vecObj]
              desc:@{kMaplyColor: [UIColor colorWithRed:0.0
                                                  green:0.25 blue:0.0 alpha:0.15],
                     kMaplyFilled: @(YES),
                     kMaplyEnable: @(NO)
                     }
              mode:MaplyThreadCurrent];
             
             // display a line around the lot
             MaplyComponentObject *outlineObj =
             [layer.viewC
              addVectors:@[vecObj]
              desc:@{kMaplyColor: [UIColor redColor],
                     kMaplyVecWidth: @(4),
                     kMaplyFilled: @(NO),
                     kMaplyEnable: @(NO)
                     }
              mode:MaplyThreadCurrent];
             
             // keep track of it in the layer
             [layer addData:@[filledObj,outlineObj] forTile:tileID];
         }
         
         // let the layer know the tile is done
         [layer tileDidLoad:tileID];
     }];
}

- (NSURLRequest *)constructRequest:(MaplyBoundingBox)bbox
{
    double toDeg = 180/M_PI;
    NSString *query = [NSString stringWithFormat:search,bbox.ll.x*toDeg,bbox.ll.y*toDeg,bbox.ur.x*toDeg,bbox.ur.y*toDeg];
    NSString *encodeQuery = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
 //   encodeQuery = [encodeQuery stringByReplacingOccurrencesOfString:@"&" withString:@"&26"];  //%26
    
// STEP 4 - Enable the proper fullUrl string, included ar a couple of ESRI URLs for the overlay tiles
    // http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Demographics/ESRI_Census_USA/MapServer/5
    // http://services.arcgis.com/OfH668nDRN7tbJh0/ArcGIS/rest/services/NYCEvacZones2013/FeatureServer
    // http://services.arcgis.com/OfH668nDRN7tbJh0/arcgis/rest/services/SandyNYCEvacMap/FeatureServer/0/query?
    
    NSString *fullUrl = [NSString stringWithFormat:@"http://services.arcgis.com/OfH668nDRN7tbJh0/ArcGIS/rest/services/NYCEvacZones2013/FeatureServer/0/query?%@",encodeQuery];
  //  NSString *fullUrl = [NSString stringWithFormat:@"https://pluto.cartodb.com/api/v2/sql?format=GeoJSON&q=%@",encodeQuery];
    NSLog(@"%@", fullUrl);
    
    NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL URLWithString:fullUrl]];
    
    return urlReq;
}

@end
