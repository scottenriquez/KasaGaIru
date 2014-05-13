//
//  KGIOpenWeatherClient.h
//  傘が要る？
//
//  Created by Hunter Kyle Gearhart on 11/05/2014.
//  Copyright (c) 2014 Hunter Kyle Gearhart. All rights reserved.
//
//  Serves as the object utilized to make calls to, and receive data from the
//  Open Weather API

@import CoreLocation;

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa/ReactiveCocoa.h>

#import "KGIWeatherData.h"
#import "KGIDailyForecast.h"

@interface KGIOpenWeatherClient : NSObject

- (RACSignal *)fetchJSONFromURL:(NSURL *)url;
- (RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate usingUnits:(BOOL)isMetric;
- (RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate usingUnits:(BOOL)isMetric;
- (RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate usingUnits:(BOOL)isMetric;

@end
