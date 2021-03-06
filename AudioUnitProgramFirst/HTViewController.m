//
//  HTViewController.m
//  AudioUnitProgram
//
//  Created by wb-shangguanhaitao on 14-3-12.
//  Copyright (c) 2014年 shangguan. All rights reserved.
//

#import "HTViewController.h"
#import "HTAudioPlayer.h"

@interface HTViewController ()

@end

@implementation HTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 60.0f, 40.0f)];
    button.backgroundColor = [UIColor blueColor];
    button.center = self.view.center;
    [self.view addSubview:button];
    [button addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)play:(id)sender
{
    NSString *path=[[NSBundle mainBundle] pathForResource:@"loop" ofType:@"wav"];
    [[HTAudioPlayer shareAudioPlayer] playWithLocationFilePath:path];
}

@end
