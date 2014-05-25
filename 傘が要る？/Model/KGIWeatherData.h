//
//  KGIWeatherData.h
//  傘が要る？
//
//  Created by Hunter Kyle Gearhart on 10/05/2014.
//  Copyright (c) 2014 Hunter Kyle Gearhart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface KGIWeatherData : MTLModel <MTLJSONSerializing>

// Weather data grabbed using the OpenWeatherMapAPI
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSNumber *humidity;
@property (nonatomic, strong) NSNumber *temperature;
@property (nonatomic, strong) NSNumber *tempHigh;
@property (nonatomic, strong) NSNumber *tempLow;
@property (nonatomic, strong) NSString *locationName;
@property (nonatomic, strong) NSDate *sunrise;
@property (nonatomic, strong) NSDate *sunset;
@property (nonatomic, strong) NSString *conditionDescription;
@property (nonatomic, strong) NSString *condition;
@property (nonatomic, strong) NSNumber *windBearing;
@property (nonatomic, strong) NSNumber *windSpeed;
@property (nonatomic, strong) NSString *icon;

// Delivers the appropriate image name for the current instance's weather condition
- (NSString *)imageName;

// Returns weather or not the weather object indicates conditions which necessitate an umbrella
- (BOOL)needUmbrella;

// Returns whether or not the weather object indicates conditions which the user indicates as when they need a jacket
- (BOOL)needJacket:(NSNumber *)jacketThreshold;

// Given a user's sun umbrella threshold value, return whether or not they'll need a sun umbrella
- (BOOL)needSunUmbrella:(NSNumber *)sunUmbrellaThreshold;

@end
