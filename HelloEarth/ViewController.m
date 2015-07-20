//
//  ViewController.m
//  HelloEarth
//
//  Created by Steve Gifford on 11/11/14.
//  Copyright (c) 2014 mousebird consulting. All rights reserved.
//

#import "ViewController.h"
#import "WhirlyGlobeComponent.h"

@interface ViewController ()

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
const bool DoOverlay = true;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create an empty globe or map and add it to the view
    theViewC = [[WhirlyGlobeViewController alloc] init];
    [self.view addSubview:theViewC.view];
    theViewC.view.frame = self.view.bounds;
    [self addChildViewController:theViewC];
    
// Create your location on the map
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
    {
        [locationManager requestWhenInUseAuthorization];
    }

    [locationManager startUpdatingLocation];
 
    // Display a MaplyScreenObject with your location
    [self addStuff];            // It more about random stuff now
    
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
    theViewC.frameInterval = 2;
    
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
        int maxZoom = 18;
        
// A set of various base layers to select from. Remember to adjust the maxZoom factor appropriately
        // http://otile1.mqcdn.com/tiles/1.0.0/sat/
        // http://map1.vis.earthdata.nasa.gov/wmts-webmerc/VIIRS_CityLights_2012/default/2015-05-07/GoogleMapsCompatible_Level8/ - jpg
        // http://map1.vis.earthdata.nasa.gov/wmts-webmerc/MODIS_Terra_CorrectedReflectance_TrueColor/default/2015-06-07/GoogleMapsCompatible_Level9/{z}/{y}/{x}  - jpg
        // http://services.arcgisonline.com/arcgis/rest/services/World_Terrain_Base/MapServer/tile/{z}/{y}/{x}
        // http://services.arcgisonline.com/arcgis/rest/services/NatGeo_World_Map/MapServer/tile/{z}/{y}/{x}
        
        // MapQuest Open Aerial Tiles, Courtesy Of Mapquest
        // Portions Courtesy NASA/JPL­Caltech and U.S. Depart. of Agriculture, Farm Service Agency
        MaplyRemoteTileSource *tileSource =
        [[MaplyRemoteTileSource alloc]
         initWithBaseURL:@"http://services.arcgisonline.com/arcgis/rest/services/NatGeo_World_Map/MapServer/tile/{z}/{y}/{x}"
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
        globeViewC.height = 1.35;
        globeViewC.heading = -0.20;
        globeViewC.tilt = 0.35;         // PI/2 radians = horizon??
        [globeViewC animateToPosition:MaplyCoordinateMakeWithDegrees(-121.85,37.0)
                                 time:1.0];
    } else {
        mapViewC.height = 0.05;
        [mapViewC animateToPosition:MaplyCoordinateMakeWithDegrees(-122.4192,37.7793)
                               time:1.0];
    }
    
    
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
    [self addCountries];
    
    //add the pics from Journey
    [self addPics];
}

- (void)addPics
{
    NSLog(@"Adding the geolocated pics");
    
    //First we unstuff the pList
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *plistURL = [mainBundle URLForResource:@"UniqueStoriesPart13" withExtension:@"plist"];
    picsArray = [NSArray arrayWithContentsOfURL:plistURL];
    
    //Next we display the pics on the globe
    NSMutableArray *theMarkers = [[NSMutableArray alloc] initWithCapacity:1000];
    
    int picCount = 0;
    int picKBytes = 0;
    
    // Just looping along
    for (int i=0;i<75;i++) {
        NSURL *thePicThumbnailUrl = [NSURL URLWithString:[picsArray[i] objectForKey:@"thumbUrl"]];
        
        MaplyScreenMarker *theScreenMarker = [[MaplyScreenMarker alloc] init];
        
        thePicData = [NSData dataWithContentsOfURL:thePicThumbnailUrl];
        theScreenMarker.image = [UIImage imageWithData:thePicData];
        NSString *latitude = [picsArray[i] objectForKey:@"latitude"];
        NSString *longitude = [picsArray[i] objectForKey:@"longitude"];
        MaplyCoordinate theLocation = MaplyCoordinateMakeWithDegrees([longitude floatValue], [latitude floatValue]);
        MaplyCoordinate3d theSpaceLocation = MaplyCoordinate3dMake([longitude floatValue]/57.3, [latitude floatValue]/57.3, 200000);
        
        theScreenMarker.loc = theLocation;
        
        theScreenMarker.size = CGSizeMake(60.0, 60.0);
        theScreenMarker.offset = CGPointMake(-30.0, 10.0);
        theScreenMarker.layoutImportance = MAXFLOAT;
        
        // Adds the pic to the list
        if ([thePicData length] < 45000) {      // if it's less than 60k
            [theMarkers addObject:theScreenMarker];
            picCount = picCount + 1;
            picKBytes = picKBytes + [thePicData length];
        }
        MaplyMarker *theMarkerPic = [[MaplyMarker alloc] init];
        //[[MaplyBillboard alloc] initWithImage:[UIImage imageWithData:thePicData] color:[UIColor whiteColor] size:CGSizeMake(0.08, 0.08)];
        theMarkerPic.loc = theLocation;
        theMarkerPic.image = [UIImage imageWithData:thePicData];
        theMarkerPic.size = CGSizeMake(0.00075, 0.00075);
        //     [theMarkers addObject:theMarkerPic];
        
        NSLog(@"Pic #%d looks like %@ and is %d long", i, [picsArray[i] objectForKey:@"storyCoverText"], [thePicData length]);
    }
    
    //Add the screenMarker array to the layer
    [theViewC addScreenMarkers:theMarkers desc:nil];
    
    NSLog(@"Added %lu geolocated pics total kB = %d", (unsigned long)picCount, picKBytes);
    
}

- (void) addStuff        //Adds a variety of objects to see what may
{
    MaplyCoordinate theLocation = MaplyCoordinateMakeWithDegrees(-124.00, 36.98);
    
// screenMarkers
    MaplyScreenMarker *yourLocation = [[MaplyScreenMarker alloc] init];
    yourLocation.image = [UIImage imageNamed:@"OtterPraying.png"];
    yourLocation.loc = theLocation;
    yourLocation.size = CGSizeMake(60.0, 100.0);
    NSMutableArray *theMarkers = [NSMutableArray arrayWithObject:yourLocation];
    [theViewC addScreenMarkers:theMarkers desc:nil];

//screenBillboards
    MaplyBillboard *yourBillboard = [[MaplyBillboard alloc] initWithImage:[UIImage imageNamed:@"GodParticle120.png"] color:[UIColor whiteColor] size:CGSizeMake(0.08, 0.08)];
    yourBillboard.center = MaplyCoordinate3dMake(-2.05, 0.63, 220000.0);
    NSMutableArray *theBillboards = [NSMutableArray arrayWithObject:yourBillboard];
//    [theViewC addBillboards:theBillboards desc:nil mode:nil];

  }

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
//- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"Updating my location to the map/globe %f %f", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude);
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
