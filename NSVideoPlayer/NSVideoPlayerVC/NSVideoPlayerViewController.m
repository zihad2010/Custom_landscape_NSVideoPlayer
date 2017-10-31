//
//  NSVideoPlayerViewController.m
//  NSVideoPlayer
//
//  Created by Steve JobsOne on 10/24/17.
//  Copyright © 2017 Steve JobsOne. All rights reserved.
//

#import "NSVideoPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "NSPlayerView.h"
#import "Reachability.h"

@interface NSVideoPlayerViewController (){
    
    Float64 totalTimeInMls;
    
}
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;

@property (strong, nonatomic) IBOutlet UILabel *totalVideoTmineLabel;
@property (strong, nonatomic) IBOutlet UIView *cancleButtonView;
@property (strong, nonatomic) IBOutlet UISlider *sliderWaitingBuffer;

@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet UIButton *videoPlayPauseButton;
@property (strong, nonatomic) IBOutlet UIView *sliderControllerView;
@property (strong, nonatomic) IBOutlet NSPlayerView *playerView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *playerViewWidthConstant;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *playerViewHeightConstant;
//@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) AVPlayer *player;
@property BOOL isPlaying;
@property BOOL isHidden;
@property BOOL isVideoStarting;


@end

@implementation NSVideoPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    
    self.playerViewHeightConstant.constant = self.view.frame.size.width;
    self.playerViewWidthConstant.constant = self.view.frame.size.height;
    self.playerView.transform = CGAffineTransformMakeRotation(M_PI_2);
    [self.slider setValue:0];
    [self.sliderWaitingBuffer setValue:0];
    self.sliderControllerView.layer.cornerRadius = 5;
    self.cancleButtonView.layer.cornerRadius = 5;
    [self.sliderWaitingBuffer setThumbImage:[UIImage imageNamed:@"SliderThumbWatingBufferImage"] forState:UIControlStateNormal];
    [self.sliderWaitingBuffer setThumbImage:[UIImage imageNamed:@"SliderThumbWatingBufferImage"] forState:UIControlStateHighlighted];
    [self.slider setThumbImage:[UIImage imageNamed:@"SliderThumbImage"] forState:UIControlStateNormal];
    [self.slider setThumbImage:[UIImage imageNamed:@"SliderThumbImage"] forState:UIControlStateHighlighted];
    
    NSURL *fileURL = [NSURL URLWithString:@"url"];
    [self playVideoWithUrl:fileURL];
    
    [self addSpinnerView];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:YES];
    [self playOrPuseButtonAction:self];
    
    
    
}

- (void) handleNetworkChange:(NSNotification *)notice {
    
    NetworkStatus remoteHostStatus = [self.internetReachability currentReachabilityStatus];
    
    if(remoteHostStatus == NotReachable) {
        
        NSLog(@"No internet connection");
        
    } else if (remoteHostStatus == ReachableViaWiFi) {
        
        NSLog(@"Connected with wifi");
        
    } else if (remoteHostStatus == ReachableViaWWAN) {
        
        NSLog(@"Connected with cell");
    }
}

-(void)addSpinnerView{
    
    [_spinner setHidden:NO];
    [_spinner startAnimating];
}

-(void)playVideoWithUrl:(NSURL *)url{
    
    self.playerItem = [AVPlayerItem playerItemWithURL:url];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    [self.playerView setPlayer:self.player];
    
    [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    self.slider.maximumValue = CMTimeGetSeconds(self.playerItem.asset.duration);
    self.sliderWaitingBuffer.maximumValue = CMTimeGetSeconds(self.playerItem.asset.duration);
    totalTimeInMls = 1000 * CMTimeGetSeconds(self.playerItem.asset.duration);
    self.timeLabel.text = [self formatInterval:totalTimeInMls];
    self.totalVideoTmineLabel.text = @"00:00";
    
    self.isHidden = NO;
    if (!self.isHidden) {
        
        [self performSelector:@selector(callAfterSomeSecond) withObject:nil afterDelay:5];
    }
}

- (IBAction)playOrPuseButtonAction:(id)sender {
    
    if (self.isPlaying) {
        
        [self.player pause];
        [self.videoPlayPauseButton setImage:[UIImage imageNamed:@"PlayImage"] forState:UIControlStateNormal];
        [self.timer invalidate];
        
    } else {
        
        [self.videoPlayPauseButton setImage:[UIImage imageNamed:@"PauseImage"] forState:UIControlStateNormal];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
        [self.player play];
    }
    self.isPlaying = !self.isPlaying;
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
    
    [self.player seekToTime:CMTimeMakeWithSeconds(sender.value, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self updateTimeLabel];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if([self.playerItem status] == AVPlayerStatusReadyToPlay) {
        
        if(object == _player.currentItem && [keyPath isEqualToString:@"loadedTimeRanges"]){
            
            NSArray *timeRanges = (NSArray*)[change objectForKey:NSKeyValueChangeNewKey];
            
            if (timeRanges && [timeRanges count]) {
                
                CMTimeRange timerange=[[timeRanges objectAtIndex:0]CMTimeRangeValue];
                double startTime = CMTimeGetSeconds(timerange.start);
                double loadedDuration = CMTimeGetSeconds(timerange.duration);
                [self.sliderWaitingBuffer setValue:loadedDuration+startTime];
                NSLog(@"get time range, its start is %f seconds, its duration is %f seconds.", startTime, loadedDuration);
            }
        }
        
        if (object == _playerItem && [keyPath isEqualToString:@"playbackBufferEmpty"]) {
            
            if (_playerItem.playbackBufferEmpty) {
                
                Float64 dur = CMTimeGetSeconds([self.player currentTime]);
                
                [self.spinner setHidden:NO];
                [self.spinner startAnimating];
                self.isVideoStarting = NO;
                NSLog(@"is buffering,......%f",dur);
            }
        } else if (object == _playerItem && [keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            
            if (_playerItem.playbackLikelyToKeepUp) {
                self.isVideoStarting = YES;
                
                NSLog(@"stop buffering,......");
                [self.spinner setHidden:YES];
                [self.spinner stopAnimating];
                
            }
        }
    } else {
        
        NSLog(@"Not ready to play, still loading.......");
    }
    
}


- (void)updateSlider {
   
    if (self.playerItem.isPlaybackLikelyToKeepUp) {
        self.isVideoStarting = YES;
        [self.spinner setHidden:YES];
        [self.spinner stopAnimating];
    }
    
    if (self.isVideoStarting) {
        [self updateTimeLabel];
        CGFloat val = self.slider.value + 0.1f;
        [self.slider setValue:val];
    }
}

- (void)updateTimeLabel {
    
    Float64 dur = CMTimeGetSeconds([self.player currentTime]);
    Float64 durInMiliSec = 1000*dur;
    self.totalVideoTmineLabel.text = [self formatInterval:durInMiliSec];
    self.timeLabel.text = [NSString stringWithFormat:@"-%@",[self formatInterval:totalTimeInMls - durInMiliSec]];
}

- (NSString *)formatInterval:(Float64)totalMilliseconds {
    
    unsigned long milliseconds = totalMilliseconds;
    unsigned long seconds = milliseconds / 1000;
    milliseconds %= 1000;
    unsigned long minutes = seconds / 60;
    seconds %= 60;
    return [NSString stringWithFormat:@"%02lu:%02lu",minutes,seconds];
}

- (void)dealloc {
    
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    NSSet* touchesForTargetView = [event touchesForView:self.playerView];
    if (touchesForTargetView.allObjects.count != 0) {
        
        if (!self.isHidden) {
            
            self.cancleButtonView.alpha = 1;
            self.sliderControllerView.alpha = 1;
            [UIView animateWithDuration:0.3 animations:^{
                self.cancleButtonView.alpha = 0;
                self.sliderControllerView.alpha = 0;
            } completion: ^(BOOL finished) {
                
                if (finished) {
                    self.isHidden = YES;
                }
            }];
            
        } else {
            
            self.cancleButtonView.alpha = 0;
            self.sliderControllerView.alpha = 0;
            [UIView animateWithDuration:0.3 animations:^{
                self.cancleButtonView.alpha = 1;
                self.sliderControllerView.alpha = 1;
            } completion: ^(BOOL finished) {
                
                if (finished) {
                    self.isHidden = NO;
                    [self performSelector:@selector(callAfterSomeSecond) withObject:nil afterDelay:5];
                }
            }];
        }
    }
}

- (void)itemDidFinishPlaying:(NSNotification *)notification {
    
    [self.player seekToTime:kCMTimeZero];
    self.isPlaying = NO;
    [self.videoPlayPauseButton setImage:[UIImage imageNamed:@"PlayImage"] forState:UIControlStateNormal];
    [self.timer invalidate];
    [self.slider setValue:0];
    
    if (!self.isHidden) {
        self.cancleButtonView.alpha = 1;
        self.sliderControllerView.alpha = 1;
        [UIView animateWithDuration:0.3 animations:^{
            self.cancleButtonView.alpha = 0;
            self.sliderControllerView.alpha = 0;
        } completion: ^(BOOL finished) {
            self.isHidden = YES;
        }];
    }
}

-(void)callAfterSomeSecond{
    
    if (!self.isHidden) {
        
        self.cancleButtonView.alpha = 1;
        self.sliderControllerView.alpha = 1;
        [UIView animateWithDuration:3.0 animations:^{
            self.cancleButtonView.alpha = 0;
            self.sliderControllerView.alpha = 0;
        } completion: ^(BOOL finished) {
            self.isHidden = YES;
        }];
    }
}

-(BOOL)prefersStatusBarHidden {
    
    return YES;
}

- (IBAction)dismissVideoViewController:(id)sender {
    
    [self.player pause];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
