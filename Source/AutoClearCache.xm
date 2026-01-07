#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static BOOL YTMU(NSString *key) {
    NSDictionary *YTMUltimateDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"YTMUltimate"];
    return [YTMUltimateDict[key] boolValue];
}

static void clearCache() {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        if (cachePath) {
            [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
        }
    });
}

%hook YTMAppDelegate

- (void)applicationDidEnterBackground:(UIApplication *)application {
    %orig;
    
    // Clear cache automatically when app enters background (exits)
    if (YTMU(@"YTMUltimateIsEnabled")) {
        clearCache();
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    %orig;
    
    // Also clear cache when app is about to terminate
    if (YTMU(@"YTMUltimateIsEnabled")) {
        clearCache();
    }
}

%end

%ctor {
    %init;
}

