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
    /**
     *  Audio unit 实例
     */
    AudioComponentInstance _audioUnit;
    
    /**
     *  读文件流
     */
    CFReadStreamRef _readStreamRef;

    /**
     *  文件读入的buffer
     */
    UInt8* _readBuffer;
    
    /**
     * readBuffer的大小
     */
    int _readBufferSize;
    
    /**
     *  Audio File Stream 解析文件
     */
    AudioFileStreamID _audioFile;
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
 *  @param filePath 本地音频文件路径
 *
 */
-(void) openWithFilePath:(NSString *)filePath;

/**
 *  _readStreamRef读的数据可以用了
 */
- (void)dataAvailable;

@end
