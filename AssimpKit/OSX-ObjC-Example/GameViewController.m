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
  SCNScene* scene = [SCNScene assimpSceneNamed:@"spider.obj"];
  // set the scene to the view
  self.gameView.scene = scene;

  // allows the user to manipulate the camera
  self.gameView.allowsCameraControl = YES;

  // show statistics such as fps and timing information
  self.gameView.showsStatistics = YES;

  // configure the view
  self.gameView.backgroundColor = [NSColor blackColor];
}

@end
