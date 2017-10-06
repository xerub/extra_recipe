//
//  ViewController.m
//  extra_recipe
//
//  Created by xerub on 13/06/2017.
//  Copyright © 2017 xerub. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)bang:(UIButton *)sender
{
    NSString *status;
    extern int jb_go(void);
    switch (jb_go()) {
        case 0:
            status = @"jailbroken";
            break;
        case 1:
            status = @"internal error";
            break;
        case 2:
            status = @"unsupported";
            break;
        case 3:
            status = @"unsupported yet";
            break;
        case 42:
            status = @"hmm... ok";
            break;
        default:
            status = @"failed, reboot";
            break;
    }
    [sender setEnabled:NO];
    [sender setTitle:status forState:UIControlStateDisabled];
}


@end
