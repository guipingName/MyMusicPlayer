//
//  ViewController.m
//  MyMusicPlayer
//
//  Created by pingui on 15/12/25.
//  Copyright (c) 2015年 pingui. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"

@interface ViewController ()<AVAudioPlayerDelegate,UITableViewDataSource,UITableViewDelegate>
{
    AVAudioPlayer *myPlayer;
    NSTimer *timer;
    NSArray *musics;
    NSInteger index;
    UITableView *myTableView;
}

@property (weak, nonatomic) IBOutlet UIImageView *backImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *fastForwardButton;
@property (weak, nonatomic) IBOutlet UIButton *fastBackButton;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    index = 0;
    if (!musics) {
        musics = @[@"Seasons In The Sun", @"月半小夜曲", @"Marry You"];
    }
    
    _coverImageView.layer.borderWidth = 1;
    _coverImageView.layer.borderColor = [UIColor clearColor].CGColor;
    _coverImageView.layer.cornerRadius = 130;
    _coverImageView.layer.masksToBounds = YES;
    
    [_progressSlider setThumbImage:[UIImage imageNamed:@"slider_L"] forState:UIControlStateNormal];
    [_progressSlider setThumbImage:[UIImage imageNamed:@"slider_H"] forState:UIControlStateHighlighted];
    
    _backImageView.image = [UIImage imageNamed:@"background.jpeg"];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    [self playMusic];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.8 target:self selector:@selector(changeRefresh:) userInfo:nil repeats:YES];
}


- (IBAction)progressValueChanged:(UISlider *)sender {
    myPlayer.currentTime = sender.value * myPlayer.duration;
}

- (void) changeRefresh:(NSTimer *)sender{
    _currentTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld",(NSInteger)myPlayer.currentTime / 60,(NSInteger)myPlayer.currentTime % 60];
    
    _progressSlider.value = myPlayer.currentTime / myPlayer.duration;
    
    [UIView animateWithDuration:1.5 animations:^{
        _coverImageView.transform = CGAffineTransformRotate(_coverImageView.transform, M_PI_4);
    }];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    index++;
    if (index== musics.count) {
        index = 0;
    }
    [self playMusic];
}

- (IBAction)pauseOrStart:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (myPlayer.isPlaying) {
        [myPlayer pause];
        timer.fireDate = [NSDate distantFuture];
    }
    else{
        [myPlayer play];
        timer.fireDate = [NSDate distantPast];
    }
}


- (void) playMusic{
    NSString *filename = [[NSBundle mainBundle] pathForResource:musics[index] ofType:@"mp3"];
    NSURL *fileurl = [NSURL fileURLWithPath:filename];
    [self updateUI:fileurl];
    myPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileurl error:nil];
    myPlayer.delegate = self;
    [self showDuration];
    [myPlayer prepareToPlay];
    [myPlayer play];
}

- (IBAction)lastSong:(UIButton *)sender {
    index--;
    if (index < 0) {
        index = musics.count - 1;
    }
    [self playMusic];
}

- (IBAction)nextSong:(UIButton *)sender {
    index++;
    if (index== musics.count) {
        index = 0;
    }
    [self playMusic];
}

- (IBAction)listButton:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        if (!myTableView) {
            myTableView = [[UITableView alloc] initWithFrame:CGRectMake(10, 430, 300, 120) style:UITableViewStylePlain];
        }
        myTableView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:myTableView];
        myTableView.rowHeight = 30;
        myTableView.dataSource = self;
        myTableView.delegate = self;
    }
    else{
        [myTableView removeFromSuperview];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return musics.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CELL"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CELL"];
    }
    cell.textLabel.text = musics[indexPath.row];
    cell.textLabel.font = [UIFont systemFontOfSize:13];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [myTableView removeFromSuperview];
    index = indexPath.row;
    [self playMusic];
}

- (void) updateUI:(NSURL *) fileUrl{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileUrl options:nil];
    NSArray *metaDataItems = [asset metadataForFormat:[[asset availableMetadataFormats] firstObject]];
    for (AVMetadataItem *item in metaDataItems) {
        if ([item.commonKey isEqualToString:@"artist"]) {
            _artistLabel.text = [item.value description];
        }
        else if ([item.commonKey isEqualToString:@"title"]){
            _titleLabel.text = [item.value description];
        }
        else if ([item.commonKey isEqualToString:@"artwork"]){
            _coverImageView.image = [UIImage imageWithData:(id)item.value];
        }
    }
}

- (void) showDuration{
    _durationLabel.text = [NSString stringWithFormat:@"%02ld:%02ld",(NSInteger)myPlayer.duration / 60,(NSInteger)myPlayer.duration % 60];
}

- (IBAction)downLoadButtonClicked:(UIButton *)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"盗版不提供下载";
    hud.yOffset = 140.0f;
    hud.alpha = 0.2;
    hud.mode = MBProgressHUDModeText;
    [hud hide:YES afterDelay:1];
}

- (IBAction)myFavoriteButtonClicked:(UIButton *)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"VIP特权";
    hud.yOffset = 140.0f;
    hud.alpha = 0.2;
    hud.mode = MBProgressHUDModeText;
    [hud hide:YES afterDelay:1];
}

- (void) dealloc{
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
}

@end
