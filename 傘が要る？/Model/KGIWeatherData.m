//
//  KGIWeatherData.m
//  傘が要る？
//
//  Created by Hunter Kyle Gearhart on 10/05/2014.
//  Copyright (c) 2014 Hunter Kyle Gearhart. All rights reserved.
//

#import "KGIWeatherData.h"

@interface KGIWeatherData ()
@property (nonatomic, strong) NSDictionary *imageMap;
@property (nonatomic, strong) NSArray *rainyConditions;
@end

@implementation KGIWeatherData {

}


- (NSString *)imageName {
    // Dictionary mapping from image codes to actual image file names
    if (!self.imageMap) {
        self.imageMap = @{
          @"01d" : @"weather-clear",
          @"02d" : @"weather-few",
          @"03d" : @"weather-few",
          @"04d" : @"weather-broken",
          @"09d" : @"weather-shower",
          @"10d" : @"weather-rain",
          @"11d" : @"weather-tstorm",
          @"13d" : @"weather-snow",
          @"50d" : @"weather-mist",
          @"01n" : @"weather-moon",
          @"02n" : @"weather-few-night",
          @"03n" : @"weather-few-night",
          @"04n" : @"weather-broken",
          @"09n" : @"weather-shower",
          @"10n" : @"weather-rain-night",
          @"11n" : @"weather-tstorm",
          @"13n" : @"weather-snow",
          @"50n" : @"weather-mist",
        };
    }
    return _imageMap[self.icon];
}

- (BOOL)needUmbrella {
    // Array of all the wet conditions calling for an umbrella
    if (!self.rainyConditions) {
        self.rainyConditions = @[
          @"09d", // weather-shower
          @"10d", // weather-rain
          @"11d", // weather-tstorm
          @"13d", // weather-snow
          @"50d", // weather-mist
          @"09n", // weather-shower
          @"10n", // weather-rain-night
          @"11n", // weather-tstorm
          @"13n", // weather-snow
          @"50n"  // weather-mist
        ];
    }
    return [_rainyConditions containsObject:self.icon];
}

- (BOOL)needJacket:(NSNumber *)jacketThreshold {
    return [self.temperature floatValue] < [jacketThreshold floatValue];
}

- (BOOL)needSunUmbrella:(NSNumber *)sunUmbrellaThreshold {
    return [self.temperature floatValue] > [sunUmbrellaThreshold floatValue];
}

#pragma mark MTLValueTransformer

+ (NSValueTransformer *)dateJSONTransformer {
    // Transforms between an NSDate object and a Unix-style floating point time interval
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
        return [NSDate dateWithTimeIntervalSince1970:str.floatValue];
    } reverseBlock:^(NSDate *date) {
        return [NSString stringWithFormat:@"%f",[date timeIntervalSince1970]];
    }];
}

+ (NSValueTransformer *)sunriseJSONTransformer {
    // Utilize the date transformer to translate to the appropriate NSDate object
    return [self dateJSONTransformer];
}

+ (NSValueTransformer *)sunsetJSONTransformer {
    // Utilize the date transformer to translate to the appropriate NSDate object
    return [self dateJSONTransformer];
}

+ (NSValueTransformer *)conditionDescriptionJSONTransformer {
    // Snags the first group of weather data properties from the JSON Objects weather array
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSArray *values) {
        return [values firstObject];
    } reverseBlock:^(NSString *str) {
        return @[str];
    }];
}

+ (NSValueTransformer *)conditionJSONTransformer {
    // Snags the first group of weather data properties from the JSON Objects weather array
    return [self conditionDescriptionJSONTransformer];
}

+ (NSValueTransformer *)iconJSONTransformer {
    // Snags the first group of weather data properties from the JSON Objects weather array
    return [self conditionDescriptionJSONTransformer];
}

#define MPS_TO_MPH 2.23694f

+ (NSValueTransformer *)windSpeedJSONTransformer {
    // Allows for the tranformation to/from metric from imperial units
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSNumber *num) {
        return @(num.floatValue*MPS_TO_MPH);
    } reverseBlock:^(NSNumber *speed) {
        return @(speed.floatValue/MPS_TO_MPH);
    }];
}

#pragma mark MTLJSONSerializing

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    // Return a mapping of the classes properties to the JSON keypaths in the JSON object
    // retreived from the OpenWeather API
    return @{
             @"date": @"dt",
             @"locationName": @"name",
             @"humidity": @"main.humidity",
             @"temperature": @"main.temp",
             @"tempHigh": @"main.temp_max",
             @"tempLow": @"main.temp_min",
             @"sunrise": @"sys.sunrise",
             @"sunset": @"sys.sunset",
             @"conditionDescription": @"weather.description",
             @"condition": @"weather.main",
             @"icon": @"weather.icon",
             @"windBearing": @"wind.deg",
             @"windSpeed": @"wind.speed"
             };
}

@end
