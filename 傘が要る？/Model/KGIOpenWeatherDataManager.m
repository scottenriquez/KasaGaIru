//
//  KGIOpenWeatherDataManager.m
//  傘が要る？
//
//  Created by Hunter Kyle Gearhart on 11/05/2014.
//  Copyright (c) 2014 Hunter Kyle Gearhart. All rights reserved.
//
//  Serves to locate the user's device and to make the necessary calls to the
//  Open Weather API using the available client object

#import "KGIOpenWeatherDataManager.h"

#import "KGIOpenWeatherClient.h"
//#import <TSMessages/TSMessage.h>

@interface KGIOpenWeatherDataManager ()

// Redeclare some external properties so that they're editable by this class internally
@property (nonatomic, strong, readwrite) KGIWeatherData *currentCondition;
@property (nonatomic, strong, readwrite) CLLocation *currentLocation;
@property (nonatomic, strong, readwrite) NSArray *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray *dailyForecast;
@property (nonatomic, strong, readwrite) NSDateFormatter *hourlyFormatter;
@property (nonatomic, strong, readwrite) NSDateFormatter *dailyFormatter;

// Declare some new properties needed for the internal implementation
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) KGIOpenWeatherClient *client;

@end

@implementation KGIOpenWeatherDataManager

// ** Designated Constructor **
+ (instancetype)sharedManager {
    static id _sharedManager = nil;
    // Utilize a one-time dispatch thread to initialize the data manager
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

- (id)init {
    if (self = [super init]) {
        // Specify the formatting to be used on hourly and daily weather forecast data
        _hourlyFormatter = [[NSDateFormatter alloc] init];
        _hourlyFormatter.dateFormat = @"h a";
        
        _dailyFormatter = [[NSDateFormatter alloc] init];
        _dailyFormatter.dateFormat = @"EEEE";
        
        // Declare self as the delegate to recieve all new user location data
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        // Instantiate the client to be used to fetch weather data
        _client = [[KGIOpenWeatherClient alloc] init];
        
        // Instantiate the weather data manager to initially use metric units
        _usingMetric = YES;
        
        // Create an observer so that a Reactive Cocoa call is made when the user's location changes
        [[[[RACObserve(self, currentLocation)
            // Only attempt to grab weather data when the user's location isn't nil
            ignore:nil]
           
           // Return a signal which is the result fo the call to three different update functions
           flattenMap:^(CLLocation *newLocation) {
               return [RACSignal merge:@[
                                         [self updateCurrentConditions],
                                         [self updateDailyForecast],
                                         [self updateHourlyForecast]
                                         ]];
               // Notify all subscribers on the main thread that weather information has been updated
           }] deliverOn:RACScheduler.mainThreadScheduler]
         // Display an error notification in the event of retrieval failure
         subscribeError:^(NSError *error) {
             // TODO: Consider removing this, or changing it to display an UIAlertView
             /*[TSMessage showNotificationWithTitle:@"Error"
                                         subtitle:@"There was a problem fetching the latest weather."
                                             type:TSMessageNotificationTypeError];*/
         }];
    }
    return self;
}

- (void)findCurrentLocationAndRetrieveWeatherData {
    self.isFirstUpdate = YES;
    [self.locationManager startUpdatingLocation];
}

- (RACSignal *)updateCurrentConditions {
    return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate usingUnits:self.usingMetric] doNext:^(KGIWeatherData *condition) {
        self.currentCondition = condition;
    }];
}

- (RACSignal *)updateHourlyForecast {
    return [[self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate usingUnits:self.usingMetric] doNext:^(NSArray *conditions) {
        self.hourlyForecast = conditions;
    }];
}

- (RACSignal *)updateDailyForecast {
    return [[self.client fetchDailyForecastForLocation:self.currentLocation.coordinate usingUnits:self.usingMetric] doNext:^(NSArray *conditions) {
        self.dailyForecast = conditions;
    }];
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    // Utilize the already-cached location of the user's device
    if (self.isFirstUpdate) {
        self.isFirstUpdate = NO;
        return;
    }
    
    CLLocation *location = [locations lastObject];
    
    // TODO: Play around with this accuracy
    // Only utilize the given location if its deemed to be accurate enough
    if (location.horizontalAccuracy > 0) {
        // Update the users location and quit cease recieving further location updates
        self.currentLocation = location;
        [self.locationManager stopUpdatingLocation];
    }
}

@end
