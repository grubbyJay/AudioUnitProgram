//
//  HTAudioPlayer.h
//  AudioUnitProgram
//
//  Created by wb-shangguanhaitao on 14-3-12.
//  Copyright (c) 2014年 shangguan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

/**
 *  利用Audio Unit 和 Audio File Stream来播放
 */
@interface HTAudioPlayer : NSObject
{
@public
    AudioComponentInstance _audioUnit;
    AudioFileID _audioFile;
    SInt64 _packetCount;
    SInt64 _packetIndex;
    UInt32 *_audioData;
}


/**
 *  @brief 返回共享的音频播放器
 *
 *  @return 返回共享的音频播放器
 */
+ (instancetype)shareAudioPlayer;

/**
 *  播放本地音频
 *
 *  @param fileName 本地音频文件名
 *
 *  @return 是否能够播放
 */
- (BOOL)playWithLocationFilePath:(NSString *)fileName;

/**
 *  获取下一个packet
 *
 *  @return 返回下一个Packet
 */
-(UInt32)getNextPacket;

@end
