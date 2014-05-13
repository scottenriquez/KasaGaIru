//
//  KGIWeatherForecastViewController.m
//  傘が要る？
//
//  Created by Hunter Kyle Gearhart on 09/05/2014.
//  Copyright (c) 2014 Hunter Kyle Gearhart. All rights reserved.
//

#import "KGIWeatherForecastViewController.h"

#import <LBBlurredImage/UIImageView+LBBlurredImage.h>
#import "KGIOpenWeatherDataManager.h"

@interface KGIWeatherForecastViewController ()

// IBOutlets for each dynamic element of the UI
@property (nonatomic, strong) IBOutlet UIImageView *blurredBackgroundImageView;
@property (strong, nonatomic) IBOutlet UILabel *cityNameLabel;
@property (strong, nonatomic) IBOutlet UICollectionView *eightDayForecast;
@property (strong, nonatomic) IBOutlet UIImageView *currentWeatherImage;
@property (strong, nonatomic) IBOutlet UILabel *currentWeatherCondition;
@property (strong, nonatomic) IBOutlet UILabel *currentTempLabel;
@property (strong, nonatomic) IBOutlet UILabel *todayLowTempLabel;
@property (strong, nonatomic) IBOutlet UILabel *todayHighTempLabel;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *displayedUIText;
@property (strong, nonatomic) IBOutlet UICollectionView *hourlyForecastCollectionView;
@property (strong, nonatomic) IBOutlet UICollectionView *dailyForecastCollectionView;
@property (strong, nonatomic) IBOutlet UIView *overlaySettingsView;
@property (strong, nonatomic) IBOutlet UIButton *settingsDoneButton;
@property (strong, nonatomic) IBOutlet UISegmentedControl *unitToggle;
@property (strong, nonatomic) IBOutlet UILabel *unitsOfMeasureLabel;

@end

// Tags to tell the collection views apart with
#define DAILY_COLLECTION_VIEW_TAG 100
#define HOURLY_COLLECTION_VIEW_TAG 200

// Daily forecast collection view UI element tags
#define DAY_LABEL_TAG 101
#define DAY_WEATHER_IMAGE_TAG 102
#define TEMPERATURE_RANGE_LABEL_TAG 103

// Hourly forecast colletion view UI element tags
#define HOUR_LABEL_TAG 201
#define HOUR_WEATHER_IMAGE_TAG 202
#define TEMPERATURE_LABEL_TAG 203

// Used to differentiate between which units of measure are in use
#define METRIC 0
#define IMPERIAL 1

@implementation KGIWeatherForecastViewController

- (id)init {
    if (self = [super init]) {
        // Use the init method to ensure that these are only initialized once, as they're expensive
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Blur, and set the current background image
    UIImage *background = [UIImage imageNamed:@"bg"];
    [self.blurredBackgroundImageView setImageToBlur:background blurRadius:10 completionBlock:nil];
    
    // Set default UI values before loading in weather data
    [self.cityNameLabel setText:@"Loading Location Data..."];
    [self.currentTempLabel setText:@"0°"];
    [self.todayLowTempLabel setText:@"L: 0°"];
    [self.todayHighTempLabel setText:@"H: 0°"];
    [self.currentWeatherCondition setText:@"Loading Current Weather Data..."];
    
    // Subscribe to recieve updates when weather data has been received from the Open Weather API
    [[RACObserve([KGIOpenWeatherDataManager sharedManager], currentCondition)
      // Perform changes on the main thread as we'll be updating the UI
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(KGIWeatherData *newWeatherData) {
         // Update the location and weather data
         self.currentTempLabel.text = [NSString stringWithFormat:@"%.0f°",newWeatherData.temperature.floatValue];
         self.currentWeatherCondition.text = [newWeatherData.condition capitalizedString];
         self.cityNameLabel.text = [newWeatherData.locationName capitalizedString];
         self.todayLowTempLabel.text = [NSString stringWithFormat:@"L: %.0f°", [newWeatherData.tempLow floatValue]];
         self.todayHighTempLabel.text = [NSString stringWithFormat:@"H: %.0f°", [newWeatherData.tempHigh floatValue]];
         
         // Update the current weather's icon to an image corresponding to the current conditions
         NSString *imageName = [NSString stringWithFormat:@"%@", [newWeatherData imageName]];
         self.currentWeatherImage.image = [UIImage imageNamed:imageName];
     }];
    
    [[RACObserve([KGIOpenWeatherDataManager sharedManager], hourlyForecast)
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(NSArray *newForecast) {
         [self.hourlyForecastCollectionView reloadData];
     }];
    
    [[RACObserve([KGIOpenWeatherDataManager sharedManager], dailyForecast)
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(NSArray *newForecast) {
         [self.dailyForecastCollectionView reloadData];
     }];
    
    // Create and instruct the application's Open Weather data manager to get the user's
    // location and the appropriate necessary weather data
    [[KGIOpenWeatherDataManager sharedManager] findCurrentLocationAndRetrieveWeatherData];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    // Set for a light status bar style to match with the dark background
    return UIStatusBarStyleLightContent;
}

- (IBAction)toggleSettingsView:(UIButton *)sender
{
    BOOL wasShowing = self.overlaySettingsView.alpha == 1.0;
    [UIView animateWithDuration:0.25 animations: ^ {
        if (wasShowing) {
            // Clear away the settings UI elements
            self.unitsOfMeasureLabel.hidden = YES;
            self.unitToggle.hidden = YES;
            self.settingsDoneButton.hidden = YES;
            self.overlaySettingsView.alpha = 0.0;
            
            // Reload the weather data, as settings may have been changed
            // TODO: Have this occur only when the user changes the setting
            [[KGIOpenWeatherDataManager sharedManager]findCurrentLocationAndRetrieveWeatherData];
        } else {
            // Bring the settings UI on-screen
            self.settingsDoneButton.hidden  = NO;
            self.unitToggle.hidden = NO;
            self.unitsOfMeasureLabel.hidden = NO;
            self.overlaySettingsView.alpha = 1.0;
        }
        // Bring the overlay in or out as appropriate
        self.overlaySettingsView.alpha = (wasShowing)? 0.0 : 1.0;;
    }];
}


- (IBAction)toggleUnitsOfMeasure:(id)sender {
    // Change the content of the API call based on the new setting
    if (self.unitToggle.selectedSegmentIndex == METRIC) {
        [KGIOpenWeatherDataManager sharedManager].usingMetric = YES;
    } else if(self.unitToggle.selectedSegmentIndex == IMPERIAL) {
        [KGIOpenWeatherDataManager sharedManager].usingMetric = NO;
    }
}

#pragma UICollectionViewDelegate



#pragma UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView.tag == DAILY_COLLECTION_VIEW_TAG) {
        return 3;
    } else if (collectionView.tag == HOURLY_COLLECTION_VIEW_TAG) {
        return MIN([[KGIOpenWeatherDataManager sharedManager].hourlyForecast count], 6);
    } else {
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell;
    
    // Determine which forecast collection view is being populated with data
    if (collectionView.tag == DAILY_COLLECTION_VIEW_TAG) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"dailyForecastCell" forIndexPath:indexPath];
        
        // Snag the appropriate UI elements using the tags defined above
        UILabel *dayLabel = (UILabel *)[cell viewWithTag:DAY_LABEL_TAG];
        UIImageView *weatherImage = (UIImageView *)[cell viewWithTag:DAY_WEATHER_IMAGE_TAG];
        UILabel *temperatureLabel = (UILabel *)[cell viewWithTag:TEMPERATURE_RANGE_LABEL_TAG];
        
        // Insert the appropriate day's data into the pointed-to UI elements
        KGIWeatherData *weather = [KGIOpenWeatherDataManager sharedManager].dailyForecast[indexPath.row];
        dayLabel.text = [[KGIOpenWeatherDataManager sharedManager].dailyFormatter stringFromDate:weather.date];
        NSString *imageName = [NSString stringWithFormat:@"%@", [weather imageName]];
        weatherImage.image = [UIImage imageNamed:imageName];
        temperatureLabel.text = [NSString stringWithFormat:@"%d° / %d°", weather.tempHigh.intValue, weather.tempLow.intValue];
    } else if (collectionView.tag == HOURLY_COLLECTION_VIEW_TAG) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"hourlyForecastCell" forIndexPath:indexPath];

        //cell.backgroundColor = [UIColor redColor];
        
        // Snag the appropriate UI elements using the tags defined above
        UIImageView *weatherImage = (UIImageView *)[cell viewWithTag:HOUR_WEATHER_IMAGE_TAG];
        UILabel *hourLabel = (UILabel *)[cell viewWithTag:HOUR_LABEL_TAG];
        UILabel *temperatureLabel = (UILabel *)[cell viewWithTag:TEMPERATURE_LABEL_TAG];
        
        // Insert the appropriate hour's data into the pointed-to UI elements
        KGIWeatherData *weather = [KGIOpenWeatherDataManager sharedManager].hourlyForecast[indexPath.row+1];
        hourLabel.text = [[KGIOpenWeatherDataManager sharedManager].hourlyFormatter stringFromDate:weather.date];
        NSString *imageName = [NSString stringWithFormat:@"%@", [weather imageName]];
        weatherImage.image = [UIImage imageNamed:imageName];
        temperatureLabel.text = [NSString stringWithFormat:@"%.0f°",weather.temperature.floatValue];
    }
    
    return cell;
}

@end
