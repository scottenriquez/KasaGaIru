//
//  KGIOpenWeatherClient.m
//  傘が要る？
//
//  Created by Hunter Kyle Gearhart on 11/05/2014.
//  Copyright (c) 2014 Hunter Kyle Gearhart. All rights reserved.
//
//  Serves as the object utilized to make calls to, and receive data from the
//  Open Weather API

#import "KGIOpenWeatherClient.h"

@interface KGIOpenWeatherClient ()

// Session to be used to communicate using the Open Weather API
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation KGIOpenWeatherClient

- (id)init {
    if (self = [super init]) {
        // Initialize the API session to be used by this instance of the client
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config];
        
        // Initially use metric units
    }
    return self;
}

- (RACSignal *)fetchJSONFromURL:(NSURL *)url {
    
    // Creates and returns a signal used to grab the JSON formatted weather information
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // Data task which parses and stores the received weather data to memory
        NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // Handle the JSON data once it's received from the given URL
            if (! error) {
                NSError *jsonError = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
                if (! jsonError) {
                    // Send the subscriber the JSON data
                    [subscriber sendNext:json];
                } else {
                    // Inform the subscriber that an error occurred during JSON serialization
                    [subscriber sendError:jsonError];
                }
            } else {
                // Inform the subscriber that an error occurred during the retrieval phase
                [subscriber sendError:error];
            }
            // Regardless of its successfulness, inform the subscriber that the request is complete
            [subscriber sendCompleted];
        }];
        
        // Initates the URL session when the signal is subscribed to
        [dataTask resume];
        
        // Serves to do any clean-up once the signal is disposed of
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
    }] doError:^(NSError *error) {
        // A side effect logging any errors which may have occurred during the creation
        // of the signal
        NSLog(@"%@",error);
    }];
}

- (RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate usingUnits:(BOOL)isMetric {
    // Build the URL string which serves as a request to the Open Weather API
    NSString *units = (isMetric) ? @"metric" : @"imperial";
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&units=%@",coordinate.latitude, coordinate.longitude, units];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Create a signal which will allow subsequent Reactive Cocoa calls to be made on it
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // Map the JSON data to an instance of the KGIWeatherData class
        return [MTLJSONAdapter modelOfClass:[KGIWeatherData class] fromJSONDictionary:json error:nil];
    }];
}

- (RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate usingUnits:(BOOL)isMetric {
    // Build the URL string which serves as a request to the Open Weather API
    NSString *units = (isMetric) ? @"metric" : @"imperial";
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast?lat=%f&lon=%f&units=%@&cnt=15",coordinate.latitude, coordinate.longitude, units];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Create a signal which will allow subsequent Reactive Cocoa calls to be made on it
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // Allows for Reactive Cocoa calls to be made on lists of data
        RACSequence *list = [json[@"list"] rac_sequence];
        
        // Return a list of signals which all allow Reactive Cocoa calls to be made on them
        return [[list map:^(NSDictionary *item) {
            // For each JSON object, map its values to a KGIWeatherData object
            return [MTLJSONAdapter modelOfClass:[KGIWeatherData class] fromJSONDictionary:item error:nil];
            // Transform the data into an NSArray using the convenience method
        }] array];
    }];
}

- (RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate usingUnits:(BOOL)isMetric {
    NSString *units = (isMetric) ? @"metric" : @"imperial";
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast/daily?lat=%f&lon=%f&units=%@&cnt=3",coordinate.latitude, coordinate.longitude, units];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Create a signal which will allow subsequent Reactive Cocoa calls to be made on it
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // Allows for Reactive Cocoa calls to be made on lists of data
        RACSequence *list = [json[@"list"] rac_sequence];
        
        // Return a list of signals which all allow Reactive Cocoa calls to be made on them
        return [[list map:^(NSDictionary *item) {
            // For each JSON object, map its values to a KGIWeatherData object
            return [MTLJSONAdapter modelOfClass:[KGIDailyForecast class] fromJSONDictionary:item error:nil];
        }] array];
    }];
}

@end
