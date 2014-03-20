//
//  HTAudioPlayer.m
//  AudioUnitProgram
//
//  Created by wb-shangguanhaitao on 14-3-12.
//  Copyright (c) 2014年 shangguan. All rights reserved.
//

#import "HTAudioPlayer.h"

static void ReadStreamCallbackProc(
                                   CFReadStreamRef stream,
                                   CFStreamEventType eventType,
                                   void* inClientInfo
                                   )
{
    HTAudioPlayer *audioPlayer = (__bridge HTAudioPlayer *)inClientInfo;
    switch (eventType)
    {
        case kCFStreamEventErrorOccurred:
//            [datasource errorOccured];
            break;
        case kCFStreamEventEndEncountered:
//            [datasource eof];
            break;
        case kCFStreamEventHasBytesAvailable:
            [audioPlayer dataAvailable];
            break;
        default:
            break;
    }
}

static OSStatus PlayCallback(
                             void                            *inRefCon,
                             AudioUnitRenderActionFlags      *ioActionFlags,
                             const AudioTimeStamp            *inTimeStamp,
                             UInt32                          inBusNumber,
                             UInt32					      inNumberFrames,
                             AudioBufferList                 *ioData
                             )
{
    printf("play::%ld,",inNumberFrames);
    printf("play::%p,",ioData);
    printf("play::%ld,",ioData->mNumberBuffers);
    printf("inBusNumber::%ld,",inBusNumber);
    
    return noErr;
}

/**
 *  文件流中的属性改变时调用的回调
 *
 *  @param clientData      外接传入的参数
 *  @param audioFileStream 文件流解析器
 *  @param propertyId      变化的属性Id
 *  @param flags           标志位
 *
 *  @return void
 */
static void AudioFileStreamPropertyListenerProc(
                                                void* clientData,
                                                AudioFileStreamID audioFileStream,
                                                AudioFileStreamPropertyID	propertyId,
                                                UInt32* flags
                                                )
{
    HTAudioPlayer *audioPlayer = (__bridge HTAudioPlayer *)clientData;
    
//	[player handlePropertyChangeForFileStream:audioFileStream fileStreamPropertyID:propertyId ioFlags:flags];
}

/**
 *  数据流解析成音频数据之后的回调
 *
 *  @param clientData         外界传入的参数
 *  @param numberBytes        音频数据流的字节数
 *  @param numberPackets      音频数据包的个数
 *  @param inputData          音频数据
 *  @param packetDescriptions 音频流的数据包的描述
 *
 *  @return void
 */
static void AudioFileStreamPacketsProc(
                                       void* clientData,
                                       UInt32 numberBytes,
                                       UInt32 numberPackets,
                                       const void* inputData,
                                       AudioStreamPacketDescription* packetDescriptions
                                       )
{
    HTAudioPlayer *audioPlayer = (__bridge HTAudioPlayer *)clientData;
    
//	[player handleAudioPackets:inputData numberBytes:numberBytes numberPackets:numberPackets packetDescriptions:packetDescriptions];
}


@interface HTAudioPlayer ()


@end

@implementation HTAudioPlayer

#pragma mark ======== Init API ========

- (void) dealloc
{
	AudioUnitUninitialize(_audioUnit);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        NSError *audioSessionError = nil;
        AVAudioSession *mySession = [AVAudioSession sharedInstance];     // 1
        [mySession setCategory: AVAudioSessionCategoryPlayAndRecord      // 3
                         error: &audioSessionError];
        [mySession setActive: YES                                        // 4
                       error: &audioSessionError];
        
        //Obtain a RemoteIO unit instance
        AudioComponentDescription acd;
        acd.componentType = kAudioUnitType_Output;
        acd.componentSubType = kAudioUnitSubType_RemoteIO;
        acd.componentFlags = 0;
        acd.componentFlagsMask = 0;
        acd.componentManufacturer = kAudioUnitManufacturer_Apple;
        
        AudioComponent inputComponent = AudioComponentFindNext(NULL, &acd);
        
        AudioComponentInstanceNew(inputComponent, &_audioUnit);
        
        AudioStreamBasicDescription audioFormat;
        
        audioFormat.mSampleRate         = 44100.00;
        audioFormat.mFormatID           = kAudioFormatLinearPCM;
        audioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        audioFormat.mFramesPerPacket    = 1;
        audioFormat.mChannelsPerFrame   = 2;
        audioFormat.mBitsPerChannel     = 16;
        audioFormat.mBytesPerFrame      = audioFormat.mBitsPerChannel*audioFormat.mChannelsPerFrame/8;
        audioFormat.mBytesPerPacket     = audioFormat.mBytesPerFrame*audioFormat.mFramesPerPacket;
        audioFormat.mReserved           = 0;
        
        AudioUnitSetProperty(_audioUnit,
                             kAudioUnitProperty_StreamFormat,
                             kAudioUnitScope_Input,
                             0,
                             &audioFormat,
                             sizeof(AudioStreamBasicDescription));
        
        //Add a callback for playing
        AURenderCallbackStruct playStruct;
        playStruct.inputProc= PlayCallback;
        playStruct.inputProcRefCon = (void*) CFBridgingRetain(self);
        
        AudioUnitSetProperty(_audioUnit,
                             kAudioUnitProperty_SetRenderCallback,
                             kAudioUnitScope_Input,
                             0,
                             &playStruct,
                             sizeof(playStruct));
        
        AudioUnitInitialize(_audioUnit);
        
        /**
         *  读文件的流buffer和size
         */
        _readBufferSize = 64 * 1024;
        _readBuffer = calloc(sizeof(UInt8), _readBufferSize);
    }
    return self;
}

+ (instancetype)shareAudioPlayer
{
    static HTAudioPlayer *audioPlayer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        audioPlayer = [[HTAudioPlayer alloc] init];
    });
    return audioPlayer;
}

#pragma mark ======== Play API ========

- (BOOL)playWithLocationFilePath:(NSString *)filePath
{
    //...
    [self openWithFilePath:filePath];
    AudioOutputUnitStart(_audioUnit);

    return YES;
}

#pragma mark ======== CFReadStreamRef API ========

-(void) openWithFilePath:(NSString *)filePath
{
    if (_readStreamRef)
    {
        CFReadStreamSetClient(_readStreamRef, kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(_readStreamRef, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopCommonModes);

        CFReadStreamClose(_readStreamRef);
        CFRelease(_readStreamRef);
        
        _readStreamRef = 0;
    }
    
    NSURL* url = [[NSURL alloc] initFileURLWithPath:filePath];
    
    _readStreamRef = CFReadStreamCreateWithFile(NULL, (__bridge CFURLRef)url);
    
    NSError* fileError;
    
    if (fileError)
    {
        CFReadStreamClose(_readStreamRef);
        CFRelease(_readStreamRef);
        _readStreamRef = 0;
        return;
    }
    
    if (_readStreamRef)
    {
        CFStreamClientContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
        CFReadStreamSetClient(_readStreamRef, kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered, ReadStreamCallbackProc, &context);
        CFReadStreamScheduleWithRunLoop(_readStreamRef, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopCommonModes);
    }
    
    CFReadStreamOpen(_readStreamRef);
}

- (void)dataAvailable
{
    [self readIntoBuffer:_readBuffer withSize:_readBufferSize];
    [self parseAudioPacketFromeBuffer:_readBuffer withSize:_readBufferSize];
}

/**
 *  从文件流取出文件
 *
 *  @param buffer audio 数据
 *  @param size   buffer的大小
 *
 *  @return 读文件返回的结果
 */
-(int) readIntoBuffer:(UInt8 *)buffer withSize:(int)size
{
    int retval = (int)CFReadStreamRead(_readStreamRef, buffer, size);
    return retval;
}

#pragma mark ======== Audio File Stream Server API ========

/**
 *  将流文件的数据转化成音频数据
 *
 *  @param buffer 将要被转换的的数据
 *  @param size   buffer的大小
 */
- (void)parseAudioPacketFromeBuffer:(UInt8 *)buffer withSize:(int)size
{
    OSStatus error;
    if (!_audioFile)
    {
        error = AudioFileStreamOpen(
                                    (__bridge void*)self,
                                    AudioFileStreamPropertyListenerProc,
                                    AudioFileStreamPacketsProc,
                                    kAudioFileWAVEType,
                                    &_audioFile
                                    );
    }
    error = AudioFileStreamParseBytes(
                                      _audioFile,
                                      size,
                                      buffer,
                                      kAudioFileStreamParseFlag_Discontinuity
                                      );
}

@end
