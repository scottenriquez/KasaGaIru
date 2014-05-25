//
//  KGIOpenWeatherDataManager.h
//  傘が要る？
//
//  Created by Hunter Kyle Gearhart on 11/05/2014.
//  Copyright (c) 2014 Hunter Kyle Gearhart. All rights reserved.
//
//  Serves to locate the user's device and to make the necessary calls to the
//  Open Weather API using the available client object

@import Foundation;
@import CoreLocation;
#import <ReactiveCocoa/ReactiveCocoa/ReactiveCocoa.h>

#import "KGIWeatherData.h"

@interface KGIOpenWeatherDataManager : NSObject <CLLocationManagerDelegate>

// Returns the application's singleton instance which fetches and manages all weather data
+ (instancetype)sharedManager;

// Read-only properties for user location as well as the weather data retrieved for that location
@property (nonatomic, strong, readonly) CLLocation *currentLocation;
@property (nonatomic, strong, readonly) KGIWeatherData *currentCondition;
@property (nonatomic, strong, readonly) NSArray *hourlyForecast;
@property (nonatomic, strong, readonly) NSArray *dailyForecast;

// Read-only properties which declare the formatting to date data
@property (nonatomic, strong, readonly) NSDateFormatter *hourlyFormatter;
@property (nonatomic, strong, readonly) NSDateFormatter *dailyFormatter;


// Locates the user to kick-off or refresh the weather information fetching process
- (void)findCurrentLocationAndRetrieveWeatherData;

// Retrieves weather data for the current user location
- (RACSignal *)updateWeatherInformation;

// Specifies the units of measure in use
@property (nonatomic) BOOL usingMetric;

@end
