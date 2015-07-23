//
//  ViewController.m
//  HelloEarth
//
//  Created by Steve Gifford on 11/11/14.
//  Copyright (c) 2014 mousebird consulting. All rights reserved.
//

#import "ViewController.h"
#import "WhirlyGlobeComponent.h"
#import "ArcGISLayer.h"

@interface ViewController ()
{
    NSMutableDictionary *ovlLayers;
}

- (void) addCountries;

@end

@implementation ViewController
{
    WhirlyGlobeViewController *theViewC;
    NSDictionary *vectorDict;
    CLLocationManager *locationManager;
    NSArray *picsArray;
    NSData *thePicData;
}

// Set these for different view options
const bool DoOverlay = false;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create an empty globe or map and add it to the view
    theViewC = [[WhirlyGlobeViewController alloc] init];
    [self.view addSubview:theViewC.view];
    theViewC.view.frame = self.view.bounds;
    [self addChildViewController:theViewC];
    
    
    // this logic makes it work for either globe or map
    WhirlyGlobeViewController *globeViewC = nil;
    MaplyViewController *mapViewC = nil;
    if ([theViewC isKindOfClass:[WhirlyGlobeViewController class]])
        globeViewC = (WhirlyGlobeViewController *)theViewC;
    else
        mapViewC = (MaplyViewController *)theViewC;
    
    // we want a black background for a globe, a white background for a map.
    theViewC.clearColor = (globeViewC != nil) ? [UIColor lightGrayColor] : [UIColor whiteColor];
    
    // and thirty fps if we can get it ­ change this to 3 if you find your app is struggling
    theViewC.frameInterval = 2;     //2
    
// Varies the tilt per height
 //   [theViewC setTiltMinHeight:0.005 maxHeight:0.10 minTilt:1.10 maxTilt:0.02];
    
    // add the capability to use the local tiles or remote tiles
    bool useLocalTiles = false;
    
    // we'll need this layer in a second
    MaplyQuadImageTilesLayer *layer;
    
    if (useLocalTiles)
    {
        MaplyMBTileSource *tileSource =
        [[MaplyMBTileSource alloc] initWithMBTiles:@"geography­-class_medres"];
        layer = [[MaplyQuadImageTilesLayer alloc]
                 initWithCoordSystem:tileSource.coordSys tileSource:tileSource];
    } else {
        // Because this is a remote tile set, we'll want a cache directory
        NSString *baseCacheDir =
        [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
         objectAtIndex:0];
        NSString *aerialTilesCacheDir = [NSString stringWithFormat:@"%@/osmtiles/",
                                         baseCacheDir];
        int maxZoom = 20;
        
// A set of various base layers to select from. Remember to adjust the maxZoom factor appropriately
        // http://otile1.mqcdn.com/tiles/1.0.0/sat/
        // http://services.arcgisonline.com/arcgis/rest/services/World_Terrain_Base/MapServer/tile/{z}/{y}/{x}
        // http://services.arcgisonline.com/arcgis/rest/services/NatGeo_World_Map/MapServer/tile/{z}/{y}/{x}
        // http://services.arcgisonline.com/arcgis/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}
        // http://services.arcgisonline.com/arcgis/rest/services/Ocean_Basemap/MapServer/tile/{z}/{y}/{x}
        
        MaplyRemoteTileSource *tileSource =
        [[MaplyRemoteTileSource alloc]
         initWithBaseURL:@"http://services.arcgisonline.com/arcgis/rest/services/Ocean_Basemap/MapServer/tile/{z}/{y}/{x}"
         ext:@"png" minZoom:0 maxZoom:maxZoom];
        tileSource.cacheDir = aerialTilesCacheDir;
        layer = [[MaplyQuadImageTilesLayer alloc]
                 initWithCoordSystem:tileSource.coordSys tileSource:tileSource];
    }
    
    layer.handleEdges = (globeViewC != nil);
    layer.coverPoles = (globeViewC != nil);
    layer.requireElev = false;
    layer.waitLoad = false;
    layer.drawPriority = 0;
    layer.singleLevelLoading = false;
    [theViewC addLayer:layer];
    
    // start up over Santa Cruz, center of the universe's beach
    if (globeViewC != nil)
    {
        globeViewC.height = 0.016;
        globeViewC.heading = 0.15;
        globeViewC.tilt = 0.25;         // PI/2 radians = horizon??
        [globeViewC animateToPosition:MaplyCoordinateMakeWithDegrees(-73.9, 40.90)
                                 time:1.0];
    } else {
        mapViewC.height = 0.05;
        [mapViewC animateToPosition:MaplyCoordinateMakeWithDegrees(-122.4192,37.7793)
                               time:1.0];
    }
    
// Adding a little sauce - AutoTilt
    [globeViewC setTiltMinHeight:0.01 maxHeight:0.1 minTilt:0.4 maxTilt:0.0];
    
    
    // Setup a remote overlay from NASA GIBS
    if (DoOverlay)
    {
        // For network paging layers, where we'll store temp files
        NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)  objectAtIndex:0];
        
        MaplyRemoteTileSource *tileSource = [[MaplyRemoteTileSource alloc] initWithBaseURL:@"http://map1.vis.earthdata.nasa.gov/wmts-webmerc/Sea_Surface_Temp_Blended/default/2015-06-25/GoogleMapsCompatible_Level7/{z}/{y}/{x}" ext:@"png" minZoom:0 maxZoom:9];
        
   //     MaplyRemoteTileSource *tileSource = [[MaplyRemoteTileSource alloc] initWithBaseURL:@"http://tile.openweathermap.org/map/precipitation/" ext:@"png" minZoom:0 maxZoom:6];
        
        tileSource.cacheDir = [NSString stringWithFormat:@"%@/sea_temperature/",cacheDir];
        
        tileSource.tileInfo.cachedFileLifetime = 3; // invalidate OWM data after three secs
        MaplyQuadImageTilesLayer *temperatureLayer = [[MaplyQuadImageTilesLayer alloc] initWithCoordSystem:tileSource.coordSys tileSource:tileSource];
        
        //       NSLog(@"The coordSystem is %@", tileSource.coordSys);
        
        temperatureLayer.coverPoles = false;
        temperatureLayer.handleEdges = false;
        [globeViewC addLayer:temperatureLayer];
        
    }
    
    // set the vector characteristics to be pretty and selectable
    vectorDict = @{
                   kMaplyColor: [UIColor whiteColor],
                   kMaplySelectable: @(true),
                   kMaplyVecWidth: @(4.0)};
    
    // add the countries
//    [self addCountries];
    
// add the ArcGIS vector layer
    [self addVectorLayer];
    
}

- (void)addVectorLayer
{
    NSString *search = @"WHERE=Zone=1&f=pgeojson&outSR=4326";
  //     NSString *search = @"SELECT the_geom,address,ownername,numfloors FROM mn_mappluto_13v1 WHERE the_geom && ST_SetSRID(ST_MakeBox2D(ST_Point(%f, %f), ST_Point(%f, %f)), 4326) LIMIT 2000;";
    
    ArcGISLayer *vectorLayer = [[ArcGISLayer alloc] initWithSearch:search];
    vectorLayer.minZoom = 10;   //15
    vectorLayer.maxZoom = 10;
    MaplySphericalMercator *coordSys = [[MaplySphericalMercator alloc] initWebStandard];
    MaplyQuadPagingLayer *quadLayer =
    [[MaplyQuadPagingLayer alloc] initWithCoordSystem:coordSys delegate:vectorLayer];
    [theViewC addLayer:quadLayer];
}

- (void)addCountries
{
    // handle this in another thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),
                   ^{
                       NSArray *allOutlines = [[NSBundle mainBundle] pathsForResourcesOfType:@"geojson" inDirectory:nil];
                       
                       for (NSString *outlineFile in allOutlines)
                       {
                           NSData *jsonData = [NSData dataWithContentsOfFile:outlineFile];
                           if (jsonData)
                           {
                               MaplyVectorObject *wgVecObj = [MaplyVectorObject VectorObjectFromGeoJSON:jsonData];
                               
                               // the admin tag from the country outline geojson has the country name ­ save
                               NSString *vecName = [[wgVecObj attributes] objectForKey:@"ADMIN"];
                               wgVecObj.userObject = vecName;
                               
                               // add the outline to our view
                               MaplyComponentObject *compObj = [theViewC addVectors:[NSArray arrayWithObject:wgVecObj] desc:vectorDict];
                               // If you ever intend to remove these, keep track of the MaplyComponentObjects above.
             /*                  // Add a screen label per country
                               if ([vecName length] > 0)
                               {
                                   MaplyScreenLabel *label = [[MaplyScreenLabel alloc] init];
                                   label.text = vecName;
                                   label.loc = [wgVecObj center];
                                   label.selectable = true;
                                   [theViewC addScreenLabels:@[label] desc:
                                    @{
                                      kMaplyFont: [UIFont boldSystemFontOfSize:12.0],
                                      kMaplyTextOutlineColor: [UIColor blackColor],
                                      kMaplyTextOutlineSize: @(1.0),
                                      kMaplyColor: [UIColor whiteColor]
                                      }];
              
                               }
                           */
                           }
                       }
                   });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
