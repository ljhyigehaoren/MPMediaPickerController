//
//  SharePlayView.m
//  MUsicViewController
//
//  Created by LJH on 2017/11/9.
//  Copyright © 2017年 LJH. All rights reserved.
//

#import "SharePlayView.h"
#import "AppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>
#define HIGHT_SCREEN [UIScreen mainScreen].bounds.size.height
#define WIDTH_SCREEN [UIScreen mainScreen].bounds.size.width

@implementation SharePlayView
{
    NSDictionary *_soundInfo;
    BOOL _enterBackground;
}
/*
  _playerTool.volume 控制是否静音
  _playerTool.numberOfLoops 控制是否单曲循环
 */

- (void)awakeFromNib {
    [super awakeFromNib];
    _playGroundImage.layer.cornerRadius = 25;//切图圆角
    _playGroundImage.layer.masksToBounds = YES;
    [_playerSlider setThumbImage:[UIImage imageNamed:@"icon_video_point"] forState:UIControlStateNormal];
    [_playerSlider setThumbImage:[UIImage imageNamed:@"icon_video_point"] forState:UIControlStateSelected];
    _playerSlider.userInteractionEnabled = NO;
}

//单例模式初始化
+ (SharePlayView *)sharedInstance{
    static dispatch_once_t once;
    static SharePlayView *sharedInstance;
    dispatch_once(&once, ^{
        NSArray* nibView =  [[NSBundle mainBundle] loadNibNamed:@"SharePlayView" owner:self options:nil];
        sharedInstance = [nibView objectAtIndex:0];
        sharedInstance.frame = CGRectMake(0,HIGHT_SCREEN -70, WIDTH_SCREEN, 70);
        [[UIApplication sharedApplication].keyWindow addSubview:sharedInstance];
        sharedInstance.backgroundColor = [UIColor yellowColor];
        //添加通知，拔出耳机后暂停播放
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    });
    return sharedInstance;
}

//创建播放器
-(void)createPlayerToolWith:(NSURL *)assUrl{
    //设置外放和后台播放(同时需要在info中设置Required background modes)
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error: nil];
    _playerTool = [[AVAudioPlayer alloc]initWithContentsOfURL:assUrl error:nil];
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(monitor) userInfo:nil repeats:YES];
    }
    _timer.fireDate = [NSDate distantPast];
    _playerTool.delegate = self;
    _playerTool.meteringEnabled = YES;
    _playButton.selected = YES;
    [_playerTool play];
    [self getSoundInfoWithUrl:assUrl];
}

/**
 *  一旦输出改变则执行此方法
 *
 *  @param notification 输出改变通知对象
 */
-(void)routeChange:(NSNotification *)notification{
    NSDictionary *dic=notification.userInfo;
    int changeReason= [dic[AVAudioSessionRouteChangeReasonKey] intValue];
    //等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
    if (changeReason==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioSessionRouteDescription *routeDescription=dic[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescription= [routeDescription.outputs firstObject];
        //原设备为耳机则暂停
        if ([portDescription.portType isEqualToString:@"Headphones"]) {
            if ([_playerTool isPlaying]) {
                [_playerTool pause];
                _playButton.selected = NO;
                _timer.fireDate = [NSDate distantFuture];
            }
        }
    }
}

//获取音频信息流
-(void)getSoundInfoWithUrl:(NSURL *)url{
    
    AudioFileID audioFile;
    //    获取文件
    //  AudioFilePermissions:（可读）权限 0:表示文件只可读
    AudioFileOpenURL((__bridge CFURLRef)url, kAudioFileReadPermission, 0, &audioFile);
    
    //  读取  获取音频文件的Info信息
    UInt32 dictionarySize = 0;
    AudioFileGetPropertyInfo(audioFile, kAudioFilePropertyInfoDictionary, &dictionarySize, 0);
    
    CFDictionaryRef dictionary;
    AudioFileGetProperty(audioFile, kAudioFilePropertyInfoDictionary, &dictionarySize, &dictionary);
    NSDictionary *audioDic = (__bridge NSDictionary *)dictionary;
    _soundInfo = audioDic;
    for (int i = 0; i < [audioDic allKeys].count; i++){
        NSString *key = [[audioDic allKeys]objectAtIndex:i];
        NSString *value = [audioDic valueForKey:key];
        NSLog(@"%@=%@",key,value);
    }
    NSString *title = [NSString stringWithFormat:@"歌曲：%@   作曲：%@",audioDic[@"title"],audioDic[@"artist"]];
    _itemTitle.text = title;
    CFRelease(dictionary); //释放内存
    AudioFileClose(audioFile); //关掉音频文件
}

//定时器
-(void)monitor{
    [self updateProgressInfo];
    [_playerSlider setValue:_playerTool.currentTime/_playerTool.duration animated:YES];
    _playTimeLabel.text = [self transfromTimeWithTime:_playerTool.currentTime];
    _totalTimeLabel.text = [self transfromTimeWithTime:_playerTool.duration];
    if (_enterBackground == YES) {
        [self setPlayingInfo];
    }
}

//-(void)sliderValueChanged:(UISlider *)slider{
//    [_playerTool pause];
////    NSInteger playTime = slider.value*_playerTool.duration;
//    [_playerTool playAtTime: 60];
//    [_playerTool play];
//}

#pragma mark -- 播放时长
-(NSString *)transfromTimeWithTime:(int)intTime{
    //计算天数、时、分、秒
    int minutes = ((int)intTime)%(3600*24)%3600/60;
    int seconds = ((int)intTime)%(3600*24)%3600%60;
    
    NSString *minute = minutes < 10? [NSString stringWithFormat:@"0%d",minutes]:[NSString stringWithFormat:@"%d",minutes];
    NSString *second = seconds < 10? [NSString stringWithFormat:@"0%d",seconds]:[NSString stringWithFormat:@"%d",seconds];
 
    NSString *dateContent = [[NSString alloc] initWithFormat:@"%@:%@",minute,second];
    return dateContent;
}

//音频封面旋转
- (void)updateProgressInfo {
    [UIView animateWithDuration:1.0 animations:^{
        //图片旋转
        _playGroundImage.transform = CGAffineTransformRotate(_playGroundImage.transform,M_PI_4 * .2);
    }];
}

//播放暂停事件
- (IBAction)playSoundBtuuonAction:(id)sender {
    if ([_playerTool isPlaying]) {
        [_playerTool pause];
        _playButton.selected = NO;
        _timer.fireDate = [NSDate distantFuture];
    }
    else{
        [_playerTool play];
        _playButton.selected = YES;
        _timer.fireDate = [NSDate distantPast];
    }
}

-(void)playOrPause{
    [self playSoundBtuuonAction:nil];
}

#pragma mark AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"播放已完成");
    [self playSoundBtuuonAction:nil];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error{
    NSLog(@"音频发生错误");
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player NS_DEPRECATED_IOS(2_2, 8_0){
    
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags NS_DEPRECATED_IOS(6_0, 8_0){
    
}

#pragma mark ---定制锁屏界面---
-(void)setPlayingInfo{
    // BASE_INFO_FUN(@"配置NowPlayingCenter");
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    //音乐的标题
    [info setObject:_soundInfo[@"title"] forKey:MPMediaItemPropertyTitle];
    //音乐的艺术家
    [info setObject:_soundInfo[@"artist"] forKey:MPMediaItemPropertyArtist];
    //音乐信息
    [info setObject:_soundInfo[@"album"] forKey:MPMediaItemPropertyAlbumTitle];
    //音乐的播放时间
    [info setObject:@(_playerTool.currentTime) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    //音乐的播放速度
    [info setObject:@(1) forKey:MPNowPlayingInfoPropertyPlaybackRate];
    //音乐的总时间
    [info setObject:@(_playerTool.duration) forKey:MPMediaItemPropertyPlaybackDuration];
    //音乐的封面
    MPMediaItemArtwork * artwork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"fengmian"]];
    [info setObject:artwork forKey:MPMediaItemPropertyArtwork];
    //完成设置
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
}

- (void)appEnterBackgroundWithBool:(BOOL)isBackground{
    _enterBackground = isBackground;
}

//移除通知，释放播放器资源
-(void)dealloc{
    _playerTool.delegate = nil;
    _playerTool = nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
}

@end
