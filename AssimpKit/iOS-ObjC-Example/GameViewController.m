//
//  GameViewController.m
//  iOS-ObjC-Example
//
//  Created by Deepak Surti on 10/24/16.
//  Copyright (c) 2016 __MyCompanyName__. All rights reserved.
//

#import "GameViewController.h"
#import "SCNScene+AssimpImport.h"

@implementation GameViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  SCNScene* scene = [SCNScene assimpSceneNamed:@"spider.obj"];

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
  scnView.backgroundColor = [UIColor blackColor];
}

- (BOOL)shouldAutorotate {
  return YES;
}

- (BOOL)prefersStatusBarHidden {
  return YES;
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
