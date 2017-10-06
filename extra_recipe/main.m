//
//  main.m
//  extra_recipe
//
//  Created by xerub on 13/06/2017.
//  Copyright © 2017 xerub. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    if (argc > 2 && !strcmp(argv[1], "derp")) {
        printf("wait...\n");
        sleep(3);
        int launchctl_load_cmd(const char *filename, int do_load, int opt_force, int opt_write);
        int rv = launchctl_load_cmd(argv[2], 1, 0, 0);
        printf("subrv = %d\n", rv);
        return rv;
    }
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
