//
//  NSPlayerView.m
//  NSVideoPlayer
//
//  Created by Steve JobsOne on 10/24/17.
//  Copyright © 2017 Steve JobsOne. All rights reserved.
//
@import AVFoundation;
#import "NSPlayerView.h"

@implementation NSPlayerView

+ (Class)layerClass {
    
    return [AVPlayerLayer class];
    
}

- (AVPlayer *)player {
    
    return [(AVPlayerLayer *)[self layer] player];
    
}

- (void)setPlayer:(AVPlayer *)player {
    
    ((AVPlayerLayer *)[self layer]).videoGravity = AVLayerVideoGravityResizeAspectFill;
    [(AVPlayerLayer *)[self layer] setPlayer:player];
    
}

@end
