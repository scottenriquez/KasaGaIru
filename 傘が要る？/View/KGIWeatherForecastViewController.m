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
@property (strong, nonatomic) IBOutlet UIImageView *umbrellaIndicator;
@property (strong, nonatomic) IBOutlet UIImageView *umbrellaInventoryIndicator;
@property (strong, nonatomic) IBOutlet UIImageView *jacketIndicator;
@property (strong, nonatomic) IBOutlet UIImageView *jacketInventoryIndicator;
@property (strong, nonatomic) IBOutlet UIImageView *sunUmbrellaIndicator;
@property (strong, nonatomic) IBOutlet UIImageView *sunUmbrellaInventoryIndicator;
@property (strong, nonatomic) IBOutlet UILabel *jacketThresholdTitleLabel;
@property (strong, nonatomic) IBOutlet UISlider *jacketThresholdSlider;
@property (strong, nonatomic) IBOutlet UILabel *jacketThresholdLabel;
@property (strong, nonatomic) IBOutlet UILabel *sunUmbrellaThresholdTitleLabel;
@property (strong, nonatomic) IBOutlet UISlider *sunUmbrellaThresholdSlider;
@property (strong, nonatomic) IBOutlet UILabel *sunUmbrellaThresholdLabel;


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
    
    // Set up the hidden settings view UI
    [self.jacketThresholdLabel setText:[NSString stringWithFormat:@"%.0f°", self.jacketThresholdSlider.value]];
    [self.sunUmbrellaThresholdLabel setText:[NSString stringWithFormat:@"%.0f°", self.sunUmbrellaThresholdSlider.value]];
    
    // Subscribe to recieve updates when weather data has been received from the Open Weather API
    [[RACObserve([KGIOpenWeatherDataManager sharedManager], currentCondition)
      // Perform changes on the main thread as we'll be updating the UI
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(KGIWeatherData *newWeatherData) {
         // Update the location and weather data
         self.currentTempLabel.text = [NSString stringWithFormat:@"%.0f°",newWeatherData.temperature.floatValue];
         self.currentWeatherCondition.text = newWeatherData.condition;
         self.cityNameLabel.text = newWeatherData.locationName;
         self.todayLowTempLabel.text = [NSString stringWithFormat:@"L: %.0f°", [newWeatherData.tempLow floatValue]];
         self.todayHighTempLabel.text = [NSString stringWithFormat:@"H: %.0f°", [newWeatherData.tempHigh floatValue]];
         
         // Update the current weather's icon to an image corresponding to the current conditions
         NSString *imageName = [NSString stringWithFormat:@"%@", [newWeatherData imageName]];
         self.currentWeatherImage.image = [UIImage imageNamed:imageName];
         
         // Reflect the necessity of any items in the UI
         [self updateItemsList];
         [self updateInventory];
     }];
    
    [[RACObserve([KGIOpenWeatherDataManager sharedManager], hourlyForecast)
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(NSArray *newForecast) {
         [self.hourlyForecastCollectionView reloadData];
         [self updateItemsList];
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

- (void)updateItemsList {
    // Grab the current conditions outside
    KGIWeatherData *currentConditions = [KGIOpenWeatherDataManager sharedManager].currentCondition;
    
    // Indicate that an umbrella is needed if it is currently raining
    if ([currentConditions needUmbrella]) {
        self.umbrellaIndicator.image = [UIImage imageNamed:@"umbrella"];
    } else {
        self.umbrellaIndicator.image = nil;
    }
    
    // Indicate that a jacket is needed if it is currently colder than the user's threshold
    if ([currentConditions needJacket:[NSNumber numberWithFloat:[self.jacketThresholdLabel.text floatValue]]]) {
        self.jacketIndicator.image = [UIImage imageNamed:@"jacket"];
    } else {
        self.jacketIndicator.image = nil;
    }
    
    // If the user has indicated a sun umbrella temperature threshold, check against it and show the appropriate picture
    if ([currentConditions needSunUmbrella:[NSNumber numberWithFloat:[self.sunUmbrellaThresholdLabel.text floatValue]]]) {
        self.sunUmbrellaIndicator.image = [UIImage imageNamed:@"umbrella"];
    } else {
        self.sunUmbrellaIndicator.image = nil;
    }
}

- (void)updateInventory {
    // Grab the day's forecasted weather to be scanned
    NSArray *hourlyForecast = [KGIOpenWeatherDataManager sharedManager].hourlyForecast;
    
    // Truth values to be ticked if an item is needed somewhere in the forecast
    BOOL needUmbrellaInInventory = NO;
    BOOL needSunUmbrellaInInventory = NO;
    BOOL needJacketInInventory = NO;
    
    // We shall naively set an end date/time for the scan by adding 24 hours to the current time
    NSTimeInterval secondsInADay = 86400;
    NSDate *scanEndDate = [NSDate dateWithTimeIntervalSinceNow:secondsInADay];
    
    // Scan through the rest of the day's forecast and indicate the necessity of any items
    for (KGIWeatherData *hourlyWeatherData in hourlyForecast) {
        // If all items are in the inventory, no more checks need to be made
        if (needJacketInInventory && needUmbrellaInInventory && needSunUmbrellaInInventory) {
            break;
        }
        
        // If we're looking at a date/time which is over 24 hours past the current time, break
        if ([hourlyWeatherData.date laterDate:scanEndDate] == hourlyWeatherData.date) {
            break;
        }
        
        // Check if an umbrella is needed for rain
        if ([hourlyWeatherData needUmbrella]) {
            needUmbrellaInInventory = YES;
        }
        // Check if a jacket is needed for colder temperatures
        if ([hourlyWeatherData needJacket:[NSNumber numberWithFloat:[self.jacketThresholdLabel.text floatValue]]]) {
            needJacketInInventory = YES;
        }
        // Check if a sun umbrella will be needed in the event of high temperatures above the user's threshold
        if ([hourlyWeatherData needSunUmbrella:[NSNumber numberWithFloat:[self.sunUmbrellaThresholdLabel.text floatValue]]]) {
            needSunUmbrellaInInventory = YES;
        }
    }
    
    // Update what inventory items will appear lit up
    self.jacketInventoryIndicator.image = (needJacketInInventory) ? [UIImage imageNamed:@"jacket"] : nil;
    self.umbrellaInventoryIndicator.image = (needUmbrellaInInventory) ? [UIImage imageNamed:@"umbrella"] : nil;
    self.sunUmbrellaInventoryIndicator.image = (needSunUmbrellaInInventory) ? [UIImage imageNamed:@"umbrella"] : nil;
    
    // Ensure that the inventory will also factor in the current conditions, as the hourly forecast doesn't always contain them
    if (self.umbrellaIndicator.image == [UIImage imageNamed:@"umbrella"]) {
        self.umbrellaInventoryIndicator.image = [UIImage imageNamed:@"umbrella"];
    }
    if (self.jacketIndicator.image == [UIImage imageNamed:@"jacket"]) {
        self.jacketInventoryIndicator.image = [UIImage imageNamed:@"jacket"];
    }
    if (self.sunUmbrellaIndicator.image == [UIImage imageNamed:@"umbrella"]) {
        self.sunUmbrellaInventoryIndicator.image = [UIImage imageNamed:@"umbrella"];
    }
}

- (IBAction)jacketThresholdChanged:(UISlider *)sender {
    // Update the label below the slider to show its value
    self.jacketThresholdLabel.text = [NSString stringWithFormat:@"%.0f°", sender.value];
}

- (IBAction)sunUmbrellaThresholdChanged:(UISlider *)sender {
    // Update the label below the slider to show its value
    self.sunUmbrellaThresholdLabel.text = [NSString stringWithFormat:@"%.0f°", sender.value];
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
            self.jacketThresholdTitleLabel.hidden = YES;
            self.jacketThresholdLabel.hidden = YES;
            self.jacketThresholdSlider.hidden = YES;
            self.sunUmbrellaThresholdTitleLabel.hidden = YES;
            self.sunUmbrellaThresholdSlider.hidden = YES;
            self.sunUmbrellaThresholdLabel.hidden = YES;
            self.settingsDoneButton.hidden = YES;
            self.overlaySettingsView.alpha = 0.0;
            
            // Reload the weather data, as settings may have been changed
            // TODO: Have this occur only when the user changes to a different city
            // any change to the units or thresholds can be handled by a simple UI update and
            // no network call
            [[KGIOpenWeatherDataManager sharedManager]findCurrentLocationAndRetrieveWeatherData];
        } else {
            // Bring the settings UI on-screen
            self.settingsDoneButton.hidden  = NO;
            self.unitToggle.hidden = NO;
            self.jacketThresholdTitleLabel.hidden = NO;
            self.jacketThresholdSlider.hidden = NO;
            self.jacketThresholdLabel.hidden = NO;
            self.sunUmbrellaThresholdTitleLabel.hidden = NO;
            self.sunUmbrellaThresholdSlider.hidden = NO;
            self.sunUmbrellaThresholdLabel.hidden = NO;
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
        // The min and max values for the jacket threshold depend on the current units being used
        self.jacketThresholdSlider.minimumValue = -15;
        self.jacketThresholdSlider.maximumValue = 23;
        
        // Convert the value to the new units of measure
        float convertedTemp = ([self.jacketThresholdLabel.text floatValue] - 32) * 5/9;
        self.jacketThresholdSlider.value = convertedTemp;
        self.jacketThresholdLabel.text = [NSString stringWithFormat:@"%.0f°", convertedTemp];
        
        // The min and max values for the sum umbrella threshold depend on the current units as well
        self.sunUmbrellaThresholdSlider.minimumValue = 0;
        self.sunUmbrellaThresholdSlider.maximumValue = 40;
        
        // Convert the value to the new units of measure
        convertedTemp = ([self.sunUmbrellaThresholdLabel.text floatValue] - 32) * 5/9;
        self.sunUmbrellaThresholdSlider.value = convertedTemp;
        self.sunUmbrellaThresholdLabel.text = [NSString stringWithFormat:@"%.0f°", convertedTemp];
        
        
    } else if(self.unitToggle.selectedSegmentIndex == IMPERIAL) {
        [KGIOpenWeatherDataManager sharedManager].usingMetric = NO;
        // The min and max values for the jacket threshold depend on the current units being used
        self.jacketThresholdSlider.minimumValue = 5;
        self.jacketThresholdSlider.maximumValue = 73;
        // Convert the value to the new units of measure
        float convertedTemp = ([self.jacketThresholdLabel.text floatValue] * 9/5) + 32;
        self.jacketThresholdSlider.value = convertedTemp;
        self.jacketThresholdLabel.text = [NSString stringWithFormat:@"%.0f°", convertedTemp];
        
        // The min and max values for the sum umbrella threshold depend on the current units as well
        self.sunUmbrellaThresholdSlider.minimumValue = 32;
        self.sunUmbrellaThresholdSlider.maximumValue = 110;
        
        // Convert the value to the new units of measure
        convertedTemp = ([self.sunUmbrellaThresholdLabel.text floatValue] * 9/5) + 32;
        self.sunUmbrellaThresholdSlider.value = convertedTemp;
        self.sunUmbrellaThresholdLabel.text = [NSString stringWithFormat:@"%.0f°", convertedTemp];
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
    } else if (collectionView.tag ==  HOURLY_COLLECTION_VIEW_TAG) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"hourlyForecastCell" forIndexPath:indexPath];
        
        // Snag the appropriate UI elements using the tags defined above
        UILabel *hourLabel = (UILabel *)[cell viewWithTag:HOUR_LABEL_TAG];
        UIImageView *weatherImage = (UIImageView *)[cell viewWithTag:HOUR_WEATHER_IMAGE_TAG];
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
