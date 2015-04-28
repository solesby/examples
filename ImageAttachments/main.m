//
//  Example: ImageAttachments
//
//  Created by Adam Solesby on 4/21/15.
//  Copyright (c) 2015 Adam Solesby. All rights reserved.
//

// I'm trying to get image attachments working to replace system glyphs that I don't like
// Here is the most basic example for replacing the system 🔒 padlock icon with an
// image (drawing in code). This works fine until I try to add paragraph styles to the
// attributed string. Once those are added, the images disappear (although they still
// take up some space.


#import <UIKit/UIKit.h>


@interface ViewController : UIViewController
@end

@implementation ViewController

- (UIImage *)imageOfPadlock
{
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(15, 14), NO, 0.0f);
    
    //// Color Declarations
    UIColor* color9 = [UIColor colorWithRed: 0.502 green: 0.502 blue: 0.502 alpha: 1];
    UIColor* color10 = [UIColor colorWithRed: 0.502 green: 0.502 blue: 0.502 alpha: 1];
    
    //// Oval Drawing
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(4, 2.5, 7, 8)];
    [color10 setStroke];
    ovalPath.lineWidth = 2;
    [ovalPath stroke];
    
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(2, 7, 11, 7)];
    [color9 setFill];
    [rectanglePath fill];
    
    UIImage *imageOfPadlock = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOfPadlock;
}

- (NSMutableAttributedString*) stringWithPadlock:(NSString*)text
{
    NSArray *parts = [text componentsSeparatedByString:@"🔒"];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:parts[0]];
    NSLog(@"padlock parts: %@", parts);
    
    if (parts.count==1) return attributedString; // did not contain padlock
    
    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
    textAttachment.image = [self imageOfPadlock];
    
    NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
    
    for( NSUInteger i=1; i < parts.count; i++)
    {
        [attributedString appendAttributedString:attrStringWithImage];
        [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:parts[i]]];
    }
    
    return [attributedString mutableCopy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray* strings = @[
                         @"🔒 This has padlock \U0001F512\uFE0E", // http://mts.io/2015/04/21/unicode-symbol-render-text-emoji/
                         @"This has padlock at the end 🔒",
                         @"🔒 This 🔒 has 🔒 several 🔒 padlocks 🔒",
                         @"🔒 This is a multi-line\n🔒 string with padlocks 🔒",
                         @"🔒 This is a multi-line\n🔒 string with padlocks 🔒 that will not display them 🔒",
                         ];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.headIndent = 20.0;
    paragraphStyle.firstLineHeadIndent = 20.0;
    paragraphStyle.tailIndent = -20.0;
    paragraphStyle.paragraphSpacing = 8.0;
    paragraphStyle.minimumLineHeight = 20;
    
    
    
    NSUInteger i = 0;
    for (NSString* s in strings)
    {
        CGFloat height = 100;
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, i * (height+10), self.view.frame.size.width-20, height)];
        label.text = s;
        label.numberOfLines = 0;
        label.layer.borderWidth = 1.0;
        label.layer.borderColor = [UIColor blueColor].CGColor;
        [self.view addSubview:label];
        
        NSMutableAttributedString *attrString = [self stringWithPadlock:s];
        
        // if (NO)
        if (i==4)
            
        /**** HERE IS THE PROBLEM ****/
            [attrString setAttributes:@{NSParagraphStyleAttributeName:paragraphStyle} range:NSMakeRange(0, attrString.length)];
        
        label.attributedText = attrString;
        
        i++;
    }
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
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
