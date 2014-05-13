//
//  KGIDailyForecast.m
//  傘が要る？
//
//  Created by Hunter Kyle Gearhart on 10/05/2014.
//  Copyright (c) 2014 Hunter Kyle Gearhart. All rights reserved.
//

#import "KGIDailyForecast.h"

@implementation KGIDailyForecast

#pragma mark MTLJSONSerializing

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    NSMutableDictionary *paths = [[super JSONKeyPathsByPropertyKey] mutableCopy];
    // Edit the normal JSON key paths to match the different ones returned for daily forecasts
    paths[@"tempHigh"] = @"temp.max";
    paths[@"tempLow"] = @"temp.min";
    return paths;
}

@end
