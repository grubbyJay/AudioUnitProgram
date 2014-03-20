//
//  HTAudioPlayer.m
//  AudioUnitProgram
//
//  Created by wb-shangguanhaitao on 14-3-12.
//  Copyright (c) 2014年 shangguan. All rights reserved.
//

#import "HTAudioPlayer.h"

OSStatus PlayCallback(void                            *inRefCon,
                      AudioUnitRenderActionFlags      *ioActionFlags,
                      const AudioTimeStamp            *inTimeStamp,
                      UInt32                          inBusNumber,
                      UInt32					      inNumberFrames,
                      AudioBufferList                 *ioData){
    printf("play::%ld,",inNumberFrames);
    printf("play::%p,",ioData);
    printf("play::%ld,",ioData->mNumberBuffers);
    printf("inBusNumber::%ld,",inBusNumber);
    HTAudioPlayer* this = (HTAudioPlayer *)CFBridgingRelease(inRefCon);
    
    for (int i=0; i < ioData->mNumberBuffers; i++)
    {
        AudioBuffer buffer = ioData->mBuffers[i];
        UInt32 *frameBuffer = buffer.mData;
        for (int index = 0; index < inNumberFrames; index++)
        {
            frameBuffer[index] = [this getNextPacket];
        }
    }
    
    /*
    UInt32 sizeIn = sizeof(AudioStreamBasicDescription);
    AudioStreamBasicDescription audioFormatIn;
    AudioUnitGetProperty(this -> _audioUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input,
                         0,
                         &audioFormatIn,
                         &sizeIn);
    UInt32 sizeOut = sizeof(AudioStreamBasicDescription);
    AudioStreamBasicDescription audioFormatOut;
    AudioUnitGetProperty(this -> _audioUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         0,
                         &audioFormatOut,
                         &sizeOut);
     */
    
    return noErr;
}

/*
static void AudioFileStreamPropertyListenerProc(void* clientData, AudioFileStreamID audioFileStream, AudioFileStreamPropertyID	propertyId, UInt32* flags)
{
	HTAudioPlayer* player = (HTAudioPlayer*)CFBridgingRelease(clientData);
    
//	[player handlePropertyChangeForFileStream:audioFileStream fileStreamPropertyID:propertyId ioFlags:flags];
}

static void AudioFileStreamPacketsProc(void* clientData, UInt32 numberBytes, UInt32 numberPackets, const void* inputData, AudioStreamPacketDescription* packetDescriptions)
{
	HTAudioPlayer* player = (HTAudioPlayer*)CFBridgingRelease(clientData);
    
//	[player handleAudioPackets:inputData numberBytes:numberBytes numberPackets:numberPackets packetDescriptions:packetDescriptions];
}
*/

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
        
        /*
        UInt32 enable = 1;
        AudioUnitSetProperty(_audioUnit,
                             kAudioOutputUnitProperty_EnableIO,
                             kAudioUnitScope_Input,
                             0,
                             &enable,
                             sizeof(enable));
        */
        
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
    const UInt8 *buffer = (const UInt8 *)[filePath cStringUsingEncoding:[NSString defaultCStringEncoding]];
    CFIndex bufLen = strlen([filePath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    CFURLRef audioFileUrl = CFURLCreateFromFileSystemRepresentation(NULL, buffer, bufLen, false);
    
    OSStatus result = AudioFileOpenURL(audioFileUrl, 0x01, 0, &_audioFile);
    
    UInt32 dataSize = sizeof(_packetCount);
    result = AudioFileGetProperty(_audioFile, kAudioFilePropertyAudioDataPacketCount, &dataSize, &_packetCount);
    if (result != noErr)
    {
        _packetCount = -1;
    }
    if (_packetCount > 0)
    {
        UInt32 packetRead = (UInt32)_packetCount;
        _audioData=(UInt32 *)malloc(sizeof(UInt32)*packetRead);
        
        UInt32 numBytesRead=-1;
        result = AudioFileReadPackets(_audioFile, false, &numBytesRead, NULL, 0, &packetRead, _audioData);

    }
    //...
    AudioOutputUnitStart(_audioUnit);

    return YES;
}

#pragma mark ======== 获取下一个packet API ========

-(UInt32)getNextPacket
{
    UInt32 returnValue = 0;
    if (_packetIndex >= _packetCount)
    {
        _packetIndex = 0;
    }
    returnValue = _audioData[_packetIndex++];
    
    return returnValue;
}

@end
