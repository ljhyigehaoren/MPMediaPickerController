//
//  ViewController.m
//  MUsicViewController
//
//  Created by LJH on 2017/11/9.
//  Copyright © 2017年 LJH. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#define kMusicKey @"kMusicKey"
#import "SharePlayView.h"
@interface ViewController ()<MPMediaPickerControllerDelegate>{
    MPMediaPickerController *musicVC;  //获取本地音频列表
    MPMusicPlayerController *musicPlayVC;
    SharePlayView *_playView; //地步播放器View
}

@end

@implementation ViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
//    接受远程控制
    [self becomeFirstResponder];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

// 获取音频文件、播放音频文件
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor yellowColor];
    //添加后台通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    //添加后台通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    // Do any additional setup after loading the view, typically from a nib.
//    取
//    注意使用MPMediaPickerController由于涉及到访问多媒体权限需要在info中添加Privacy - Media Library Usage Description设置
    musicVC = [[MPMediaPickerController alloc]initWithMediaTypes:MPMediaTypeAnyAudio];
    musicVC.delegate = self;
    musicVC.prompt = @"请选择您要播放的节目";
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if(_playView) _playView.hidden = YES;
    [self presentViewController:musicVC animated:YES completion:nil];
}

-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker{
    NSLog(@"取消选择");
    if(_playView) _playView.hidden = NO;
    [mediaPicker dismissViewControllerAnimated:true completion:nil];
}

/*
 网上大部分使用的是这种直接播放的方法，但是我实验后感觉播放无效
 */
//-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection{
////    播放选择的音乐
////    初始化播放控制类
//    musicPlayVC = [[MPMusicPlayerController alloc]init];
////    绑定
//    [musicPlayVC setQueueWithItemCollection:mediaItemCollection];
////    播放
//    [musicPlayVC play];
//}

//注释第二种方法，来自简书http://www.jianshu.com/p/4fa2a9658a4a
//该方法可以实现播放音频的效果
- (void)mediaPicker:(nonnull MPMediaPickerController *)mediaPicker didPickMediaItems:(nonnull MPMediaItemCollection *)mediaItemCollection {
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController systemMusicPlayer];
    [musicPlayer setQueueWithItemCollection:mediaItemCollection];
    MPMediaItem *item = [mediaItemCollection.items firstObject];
    // 重点:编码对象(item)为NSData
    NSData *date = [NSKeyedArchiver archivedDataWithRootObject:item];
    // 存储编码后的NSData到plist文件
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:kMusicKey];
    [self dismissViewControllerAnimated:YES completion:nil];
    // 取出data并播放
    [self playerMusic];
}
//2.取出音乐播放
- (void)playerMusic {
    _titleHeader1.text = @"交流是一种快乐";
    _titleHeader2.text = @"学习更是一种乐趣";
    // 在任何其他文件都可以取出data进行音乐播放
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kMusicKey];
    // 解档还原item对象
    MPMediaItem *item = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    // 取出音乐.注意:MPMediaItemPropertyAssetURL属性可能为空. 这是因为iPhone自带软件Music对音乐版权的保护,对于所有进行过 DRM Protection(数字版权加密保护)的音乐都不能被第三方APP获取并播放.即使这些音乐已经下载到本地.但是还是可以播放本地未进行过数字版权加密的音乐.也就是您自己手动导入的音乐.
    NSURL *assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
    _playView = [SharePlayView sharedInstance];
    _playView.hidden = NO;
    [_playView createPlayerToolWith:assetURL];
}

#pragma mark ---定制锁屏界面---
//App进入后台
-(void)appEnterBackground{
    if (_playView) {
        [_playView appEnterBackgroundWithBool:YES];
    }
}
//App进入前台
-(void)appEnterForeground{
    if (_playView) {
        [_playView appEnterBackgroundWithBool:NO];
    }
}

#pragma mark ---设置远程控制接收方法---
/*
 // 不包含任何子事件类型
 UIEventSubtypeNone                              = 0,
 // 摇晃事件（从iOS3.0开始支持此事件）
 UIEventSubtypeMotionShake                       = 1,
 //远程控制子事件类型（从iOS4.0开始支持远程控制事件）
 //播放事件【操作：停止状态下，按耳机线控中间按钮一下】
 UIEventSubtypeRemoteControlPlay                 = 100,
 //暂停事件
 UIEventSubtypeRemoteControlPause                = 101,
 //停止事件
 UIEventSubtypeRemoteControlStop                 = 102,
 //播放或暂停切换【操作：播放或暂停状态下，按耳机线控中间按钮一下】
 UIEventSubtypeRemoteControlTogglePlayPause      = 103,
 //下一曲【操作：按耳机线控中间按钮两下】
 UIEventSubtypeRemoteControlNextTrack            = 104,
 //上一曲【操作：按耳机线控中间按钮三下】
 UIEventSubtypeRemoteControlPreviousTrack        = 105,
 //快退开始【操作：按耳机线控中间按钮三下不要松开】
 UIEventSubtypeRemoteControlBeginSeekingBackward = 106,
 //快退停止【操作：按耳机线控中间按钮三下到了快退的位置松开】
 UIEventSubtypeRemoteControlEndSeekingBackward   = 107,
 //快进开始【操作：按耳机线控中间按钮两下不要松开】
 UIEventSubtypeRemoteControlBeginSeekingForward  = 108,
 //快进停止【操作：按耳机线控中间按钮两下到了快进的位置松开】
 UIEventSubtypeRemoteControlEndSeekingForward    = 109,
 */
-(void)remoteControlReceivedWithEvent:(UIEvent *)event{
    if (event.type == UIEventTypeRemoteControl) {
//        判断是否为远程控制，如果不是则不执行
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlPlay:
//               播放
                [_playView playOrPause];
                break;
            case UIEventSubtypeRemoteControlPause:
//               暂停
                [_playView playOrPause];
                break;
            case UIEventSubtypeRemoteControlStop:
//               停止
                break;
            case UIEventSubtypeRemoteControlNextTrack:
//               下一首
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
//               上一首
                break;
            default:
                break;
        }
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    //    取消远程控制
    [self resignFirstResponder];
    [[UIApplication sharedApplication]endReceivingRemoteControlEvents];
    
}

-(void)dealloc{
//    移除通知
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
