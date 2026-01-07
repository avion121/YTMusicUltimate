#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static BOOL YTMU(NSString *key) {
    NSDictionary *YTMUltimateDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"YTMUltimate"];
    return [YTMUltimateDict[key] boolValue];
}

static void clearCacheSync() {
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    if (cachePath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirectory = NO;
        BOOL exists = [fileManager fileExistsAtPath:cachePath isDirectory:&isDirectory];
        
        if (exists && isDirectory) {
            // Try to remove the entire cache directory first (like the settings do)
            NSError *error = nil;
            [fileManager removeItemAtPath:cachePath error:&error];
            
            // If that didn't work, delete contents individually
            if (error && [fileManager fileExistsAtPath:cachePath]) {
                NSArray *contents = [fileManager contentsOfDirectoryAtPath:cachePath error:nil];
                for (NSString *item in contents) {
                    NSString *itemPath = [cachePath stringByAppendingPathComponent:item];
                    [fileManager removeItemAtPath:itemPath error:nil];
                }
            }
        }
    }
}

static void clearCache() {
    if (!YTMU(@"YTMUltimateIsEnabled")) {
        return;
    }
    
    // Use background task to ensure cache clearing completes even when app is exiting
    UIApplication *app = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        // If we're running out of time, do it synchronously
        clearCacheSync();
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        clearCacheSync();
        
        if (bgTask != UIBackgroundTaskInvalid) {
            [app endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }
    });
}

// Hook using UIApplication notifications (more reliable)
static void setupNotifications() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
        // Clear cache immediately when entering background (most reliable)
        if (YTMU(@"YTMUltimateIsEnabled")) {
            clearCacheSync();
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
        // On termination, do it synchronously to ensure it completes
        if (YTMU(@"YTMUltimateIsEnabled")) {
            clearCacheSync();
        }
    }];
}

// Also try hooking YTMAppDelegate if it exists
%hook YTMAppDelegate

- (void)applicationDidEnterBackground:(UIApplication *)application {
    %orig;
    // Clear cache immediately when entering background (most reliable)
    if (YTMU(@"YTMUltimateIsEnabled")) {
        clearCacheSync();
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    %orig;
    // On termination, do it synchronously to ensure it completes
    if (YTMU(@"YTMUltimateIsEnabled")) {
        clearCacheSync();
    }
}

%end

%ctor {
    %init;
    setupNotifications();
}

