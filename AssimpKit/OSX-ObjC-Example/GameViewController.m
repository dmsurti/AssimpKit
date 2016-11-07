//
//  GameViewController.m
//  OSX-ObjC-Example
//
//  Created by Deepak Surti on 10/24/16.
//  Copyright (c) 2016 __MyCompanyName__. All rights reserved.
//

#import "GameViewController.h"
#import "SCNScene+AssimpImport.h"

@implementation GameViewController

- (void)awakeFromNib {
  //  NSString* filePath = @"/Users/deepaksurti/ios-osx/assimp/demo/assets/"
  // @"models-nonbsd/3DS/jeep1.3ds";
  NSString* filePath =
      @"/Users/deepaksurti/ios-osx/assimp/demo/assets/astroBoy_walk.dae";
  SCNAssimpScene* scene =
      [SCNScene assimpSceneWithURL:[NSURL URLWithString:filePath]];
  // SCNScene* scene = [SCNScene assimpSceneNamed:@"spider.obj"];
  SCNAssimpAnimation* walkAnim = [scene animationForKey:@"astroBoy_walk-1"];
  [scene addAnimation:walkAnim];

  self.gameView.scene = scene;

  // allows the user to manipulate the camera
  self.gameView.allowsCameraControl = YES;

  // show statistics such as fps and timing information
  self.gameView.showsStatistics = YES;

  // configure the view
  self.gameView.backgroundColor = [NSColor whiteColor];
  
  self.gameView.playing = YES;
}

@end
