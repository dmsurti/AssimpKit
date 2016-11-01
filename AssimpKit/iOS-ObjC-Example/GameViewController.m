//
//  GameViewController.m
//  iOS-ObjC-Example
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

- (void)viewDidLoad {
  [super viewDidLoad];

  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString* docsDir = [paths objectAtIndex:0];
  NSString* boy = [docsDir stringByAppendingString:@"/astroBoy_walk.dae"];
  // SCNScene* scene = [SCNScene assimpSceneNamed:@"explorer_skinned.dae"];
  // SCNScene* scene = [SCNScene sceneNamed:@"explorer_skinned.dae"];
  SCNScene* scene = [SCNScene assimpSceneWithURL:[NSURL URLWithString:boy]];
  //  NSError* error;
  //  SCNScene* scene = [SCNScene sceneWithURL:[NSURL fileURLWithPath:boy]
  //                                   options:nil
  //                                     error:&error];
  //  if (error) {
  //    NSLog(@" Could not read file from URL: %@", error.description);
  //  }

  // create a new scene
  // SCNScene* scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];

  // retrieve the SCNView
  SCNView* scnView = (SCNView*)self.view;

  // set the scene to the view
  scnView.scene = scene;

  // allows the user to manipulate the camera
  scnView.allowsCameraControl = YES;

  // show statistics such as fps and timing information
  scnView.showsStatistics = YES;

  // configure the view
  scnView.backgroundColor = [UIColor whiteColor];

  self.animTime = 0.0;
  self.prevTime = 0.0;
  scnView.delegate = self;

  // let us add an animation
  SCNAssimpScene* animScene = (SCNAssimpScene*)scnView.scene;
  [animScene addAnimationForKey:@"astroBoy_walk-1"];
}

- (BOOL)shouldAutorotate {
  return YES;
}

- (BOOL)prefersStatusBarHidden {
  return YES;
}

- (void)renderer:(id<SCNSceneRenderer>)renderer
    updateAtTime:(NSTimeInterval)time {
  NSLog(@"  Updating animation at %f with prev %f anim time %f ", time,
        self.prevTime, self.animTime);
  // retrieve the SCNView
  SCNView* scnView = (SCNView*)self.view;

  SCNAssimpScene* scene = (SCNAssimpScene*)scnView.scene;
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  if ([[UIDevice currentDevice] userInterfaceIdiom] ==
      UIUserInterfaceIdiomPhone) {
    return UIInterfaceOrientationMaskAllButUpsideDown;
  } else {
    return UIInterfaceOrientationMaskAll;
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

@end
