//
//  GameViewController.m
//  OSX-ObjC-Example
//
//  Created by Deepak Surti on 10/24/16.
//  Copyright (c) 2016 __MyCompanyName__. All rights reserved.
//

#import "GameViewController.h"
#import "SCNScene+AssimpImport.h"

@interface GameViewController ()

@property NSTimeInterval animTime;
@property NSTimeInterval prevTime;
@property NSInteger index;

@end

@implementation GameViewController

- (void)awakeFromNib {
  //  NSString* filePath = @"/Users/deepaksurti/ios-osx/assimp/demo/assets/"
  // @"models-nonbsd/3DS/jeep1.3ds";
  NSString* filePath =
      @"/Users/deepaksurti/ios-osx/assimp/demo/assets/explorer_skinned.dae";
  NSString* astroBoy =
      @"/Users/deepaksurti/ios-osx/assimp/demo/assets/astroBoy_walk.dae";
  NSString* soldier =
      @"/Users/deepaksurti/ios-osx/assimp/demo/assets/attack.dae";
  NSString* bob = @"/Users/deepaksurti/ios-osx/assimp/demo/assets/"
                  @"models-nonbsd/MD5/BOB.md5mesh";
  SCNScene* scene =
      [SCNScene assimpSceneWithURL:[NSURL URLWithString:astroBoy]];
  // SCNScene* scene = [SCNScene assimpSceneNamed:@"spider.obj"];

  self.gameView.scene = scene;

  // allows the user to manipulate the camera
  self.gameView.allowsCameraControl = YES;

  // show statistics such as fps and timing information
  self.gameView.showsStatistics = YES;

  // configure the view
  self.gameView.backgroundColor = [NSColor lightGrayColor];

  self.animTime = 0.0;
  self.prevTime = 0.0;
  self.gameView.delegate = self;

  // let us add an animation
  SCNAssimpScene* animScene = (SCNAssimpScene*)self.gameView.scene;
  [animScene addAnimationForKey:@"astroBoy_walk-1"];
  // [animScene addAnimationForKey:@"attack"];
  //  NSString* walkFilePath =
  //      @"/Users/deepaksurti/ios-osx/assimp/demo/assets/explorer/hit.dae";
  //  NSString* bobAnim = @"/Users/deepaksurti/ios-osx/assimp/demo/assets/"
  //                      @"models-nonbsd/MD5/Bob.md5anim";
  //  SCNAssimpScene* walkScene = [SCNScene assimpSceneWithURL:bobAnim];
  //  self.index = 1;
}

#pragma mark - SCNSceneRendererDelegate

- (void)renderer:(id<SCNSceneRenderer>)renderer
    updateAtTime:(NSTimeInterval)time {
  NSLog(@"  Updating animation at %f with prev %f anim time %f ", time,
        self.prevTime, self.animTime);
  SCNAssimpScene* scene = (SCNAssimpScene*)self.gameView.scene;
  if (self.prevTime == 0) {
    self.prevTime = time;
  } else {
    NSTimeInterval delta = (time - self.prevTime);
    self.animTime += delta;
    NSLog(@" anim time elapsed: %f after delta %f", self.animTime, delta);
    self.prevTime = time;
    if (self.animTime > 1.08) {
      NSLog(@" Will now reset animation ");
      self.animTime = 0.0;
    } else {
      NSLog(@" Will now apply animation ");
      [scene applyAnimationAtTime:self.animTime];
    }
  }
}

@end
