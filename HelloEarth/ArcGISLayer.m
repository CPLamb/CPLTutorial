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
    zoneNumber = 0;
    
    return self;
}

- (void)startFetchForTile:(MaplyTileID)tileID forLayer:(MaplyQuadPagingLayer *)layer
{
    // Building a search that increments the zone number
 //   zoneNumber = zoneNumber+1;
 //   if (zoneNumber == 7) zoneNumber = 1;
    
 //   search = @"WHERE=Zone= ";
 //   NSString *number = [NSString stringWithFormat:@"%ld", (long)zoneNumber];
 //   search = [[search stringByAppendingString:number] stringByAppendingString:@" &f=pgeojson&outSR=4326"];
    // @"WHERE=Zone="%lu"&f=pgeojson&outSR=4326", i
    
    // bounding box for tile
    MaplyBoundingBox bbox;
    [layer geoBoundsforTile:tileID ll:&bbox.ll ur:&bbox.ur];
    NSURLRequest *urlReq = [self constructRequest:bbox];
//    NSLog(@"The PagingLayer is %@", layer);
    
//    NSLog(@"The %ldth search query is %@", (long)zoneNumber, search);
    
    // kick off the query asychronously
    [NSURLConnection
     sendAsynchronousRequest:urlReq
     queue:opQueue
     completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         NSLog(@"returned data length is %lu", (unsigned long)data.length);
         // parse the resulting GeoJSON
         MaplyVectorObject *vecObj = [MaplyVectorObject VectorObjectFromGeoJSON:data];
         int vectorCount = [vecObj.splitVectors count];
         
         NSLog(@"Data from ESRI is %@ with %d vectors", vecObj.attributes, vectorCount);
         
         // Attempting to perform a draw on each individual splitVector
         int i = 0;
         for (i; i<=vectorCount; i++) {
      //       NSString *vectAttrib = [NSString stringWithFormat:[vecObj.attributes objectForKey:@"Zone"]];
             MaplyVectorObject *splitVector = [vecObj.splitVectors objectAtIndex:i];
             NSString *splitVectorZone = [splitVector.attributes objectForKey:@"Zone"];
             NSString *vectAttrib = splitVectorZone;
     //        NSString *vectAttrib = [NSString stringWithFormat:[[vecObj.splitVectors objectAtIndex:i] objectForKey:@"Zone"]];
   //          NSLog(@"splitVector %d Zone = %@", i, splitVectorZone);
             // Attempting to give different colors to the Zones
             UIColor *vectObjectColor = [UIColor colorWithRed:0.0
                                                        green:0.25 blue:0.0 alpha:0.25];
             
             if ([vectAttrib isEqualToString:@"5"]) {
                 NSLog(@"Say YEAH! it's 5!");
                 vectObjectColor = [UIColor colorWithRed:0.30
                                                   green:0.0 blue:0.0 alpha:0.25];
             } else if ([vectAttrib isEqualToString:@"6"]) {
                 vectObjectColor = [UIColor colorWithRed:1.0
                                                   green:0.0 blue:0.0 alpha:0.25];
             } else if ([vectAttrib isEqualToString:@"1"]) {
                 vectObjectColor = [UIColor colorWithRed:0.0
                                                   green:0.20 blue:0.0 alpha:0.25];
             } else if ([vectAttrib isEqualToString:@"2"]) {
                 vectObjectColor = [UIColor colorWithRed:0.0
                                                   green:0.80 blue:0.0 alpha:0.25];
             } else if ([vectAttrib isEqualToString:@"3"]) {
                 vectObjectColor = [UIColor colorWithRed:0.70
                                                   green:0.0 blue:7.0 alpha:0.25];
             } else if ([vectAttrib isEqualToString:@"4"]) {
                 vectObjectColor = [UIColor colorWithRed:0.30
                                                   green:0.0 blue:3.0 alpha:0.25];
             }
             
             if (vecObj)
             {
                 // display a transparent filled polygon
                 MaplyComponentObject *filledObj =
                 [layer.viewC
                  addVectors:@[vecObj]
                  desc:@{kMaplyColor: vectObjectColor,
                         kMaplyFilled: @(YES),
                         kMaplyEnable: @(NO)
                         }
                  mode:MaplyThreadCurrent];
                 
                 // display a line around the lot
                 MaplyComponentObject *outlineObj =
                 [layer.viewC
                  addVectors:@[vecObj]
                  desc:@{kMaplyColor: [UIColor blackColor],
                         kMaplyVecWidth: @(2),
                         kMaplyFilled: @(NO),
                         kMaplyEnable: @(NO)
                         }
                  mode:MaplyThreadCurrent];
                 
                 // keep track of it in the layer
                 [layer addData:@[filledObj,outlineObj] forTile:tileID];
             }
             // let the layer know the tile is done
             [layer tileDidLoad:tileID];
         }
     }];
}

- (NSURLRequest *)constructRequest:(MaplyBoundingBox)bbox
{
    double toDeg = 180/M_PI;
    NSString *query = [NSString stringWithFormat:search,bbox.ll.x*toDeg,bbox.ll.y*toDeg,bbox.ur.x*toDeg,bbox.ur.y*toDeg];
    NSString *encodeQuery = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  //  encodeQuery = [encodeQuery stringByReplacingOccurrencesOfString:@"&" withString:@"&"];  //%26
    
// A couple of ESRI URLs
    // http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Demographics/ESRI_Census_USA/MapServer/5
    // http://services.arcgis.com/OfH668nDRN7tbJh0/ArcGIS/rest/services/NYCEvacZones2013/FeatureServer
    // http://services.arcgis.com/OfH668nDRN7tbJh0/arcgis/rest/services/SandyNYCEvacMap/FeatureServer/0/query?
        
  //    NSString *fullUrl = [NSString stringWithFormat:@"http://services.arcgis.com/OfH668nDRN7tbJh0/arcgis/rest/services/SandyNYCEvacMap/FeatureServer/0/query?%@",encodeQuery];
    NSString *fullUrl = [NSString stringWithFormat:@"http://services.arcgis.com/OfH668nDRN7tbJh0/ArcGIS/rest/services/NYCEvacZones2013/FeatureServer/0/query?%@",encodeQuery];
    
  //  NSString *fullUrl = [NSString stringWithFormat:@"https://pluto.cartodb.com/api/v2/sql?format=GeoJSON&q=%@",encodeQuery];
    
    NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL URLWithString:fullUrl]];
    
    return urlReq;
}

@end
