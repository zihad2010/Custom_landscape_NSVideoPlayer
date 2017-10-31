//
//  NSPlayerView.h
//  NSVideoPlayer
//
//  Created by Steve JobsOne on 10/24/17.
//  Copyright © 2017 Steve JobsOne. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVPlayer;

@interface NSPlayerView : UIView

@property (nonatomic, strong) AVPlayer *player;

@end
