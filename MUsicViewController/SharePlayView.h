//
//  SharePlayView.h
//  MUsicViewController
//
//  Created by LJH on 2017/11/9.
//  Copyright © 2017年 LJH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
@interface SharePlayView : UIView <AVAudioPlayerDelegate>
{
    AVAudioPlayer *_playerTool;
    NSTimer *_timer;
}
@property (weak, nonatomic) IBOutlet UILabel *itemTitle;
@property (weak, nonatomic) IBOutlet UIImageView *playGroundImage;
@property (weak, nonatomic) IBOutlet UISlider *playerSlider;
@property (weak, nonatomic) IBOutlet UILabel *playTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIImageView *playViewBgImage;

+ (SharePlayView *)sharedInstance;
- (void)createPlayerToolWith:(NSURL *)assUrl;
- (void)playOrPause;
- (void)appEnterBackgroundWithBool:(BOOL)isBackground;
@end
