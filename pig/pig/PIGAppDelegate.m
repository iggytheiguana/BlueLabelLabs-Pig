//
//  PIGAppDelegate.m
//  pig
//
//  Created by Jordan Gurrieri on 8/26/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "PIGAppDelegate.h"
#import "PIGIAPHelper.h"
#import "PIGGCHelper.h"
#import "Flurry+PIGFlurry.h"
#import "PIGGameConstants.h"
#import <Crashlytics/Crashlytics.h>
#import <RevMobAds/RevMobAds.h>

@implementation PIGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // Start Crashlytics
    [Crashlytics startWithAPIKey:@"b53fcf08df9b183b382153735d57a10862fc5348"];
    
    // Update the app version in the User Defaults
    [self updateAppVersionUserDefaultSetting];
    
    // Start Flurry
    [Flurry setCrashReportingEnabled:NO];
    [Flurry startSession:@"F8KVX5H9N2RCP6RD6VXH"];
    
    // Start RevMobAds Session
    [RevMobAds startSessionWithAppID:@"52d5a5f85d1d553d6d000066"];
    [RevMobAds session].parallaxMode = RevMobParallaxModeDefault;
//    [RevMobAds session].testingMode = RevMobAdsTestingModeWithAds;
    
    // Check for IAP transactions
    [PIGIAPHelper sharedInstance];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Instance Methods
- (void)updateAppVersionUserDefaultSetting {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* appVersionCurrent = [infoDict objectForKey:@"CFBundleShortVersionString"];
    
    // Save the current app version
    [userDefaults setObject:appVersionCurrent forKey:kAppVersion];
    
    [userDefaults synchronize];
}

@end
