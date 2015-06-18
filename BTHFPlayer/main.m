//
//  Example: BTHFPlayer
//
//  Created by Adam Solesby on 6/18/15.
//  Copyright (c) 2015 Adam Solesby. All rights reserved.
//

// Experiment with handsfree bluetooth audio


#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController
@property (nonatomic, retain) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) IBOutlet UIButton *playButton;
@property (nonatomic, strong) IBOutlet UISwitch *modeSwitch;
@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
    self.view.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    CGFloat width = self.view.frame.size.width;
    UIColor* tintColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    
    self.modeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(width/2-25, width, 0, 0)];
    self.modeSwitch.tintColor = self.modeSwitch.onTintColor = tintColor;
    [self.modeSwitch addTarget:self action:@selector(toggleMode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.modeSwitch];
    
    self.playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.playButton.frame = CGRectMake(0, 0, width, width);
    self.playButton.titleLabel.font = [UIFont systemFontOfSize:42];
    [self.playButton setTitle:@"Play" forState:UIControlStateNormal]; // &#10073; &#10074;
    [self.playButton setTitleColor:tintColor forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(togglePlayback) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playButton];
}

- (void) toggleMode
{
    if (self.audioPlayer.playing) [self togglePlayback];
    self.audioPlayer = nil;
}

- (void) togglePlayback
{
    if (!self.audioPlayer)
    {
        NSError* error;
        
        AVAudioSession* audioSession = [AVAudioSession sharedInstance];
        
        if (self.modeSwitch.on)
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                          withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:&error];
        else
            [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];

        NSURL* url = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"mp3"];
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    }
    
    if (self.audioPlayer.playing)
    {
        [self.audioPlayer pause];
        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    }
    else
    {
        [self.audioPlayer play];
        [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];
    }
}



@end

/********************************************************************************************************************************/

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIViewController *viewController;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    self.viewController = [[ViewController alloc] init];
    self.window.rootViewController = self.viewController;
    [self.window addSubview: self.viewController.view];
    [self.window makeKeyAndVisible];
    return YES;
}
@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
