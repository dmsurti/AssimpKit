//
//  GameViewController.m
//  iOS-ObjC-Example
//
//  Created by Deepak Surti on 10/24/16.
//  Copyright (c) 2016 __MyCompanyName__. All rights reserved.
//

#import "GameViewController.h"
#import "SCNScene+AssimpImport.h"
#import "AssimpImporter.h"

@implementation GameViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString* docsDir = [paths objectAtIndex:0];
  NSString* explorer = [docsDir stringByAppendingString:@"/explorer_skinned.dae"];
  NSString* bob = [docsDir stringByAppendingString:@"/Bob.md5mesh"];
  SCNAssimpScene* scene = [SCNScene assimpSceneWithURL:[NSURL URLWithString:bob]];
  
  // Now we can access the file's contents
  NSString* runAnim = [docsDir stringByAppendingString:@"/explorer/jump_start.dae"];
  NSString* bobAnim = [docsDir stringByAppendingString:@"/Bob.md5anim"];
  AssimpImporter* assimpImporter = [[AssimpImporter alloc] init];
  SCNAssimpScene* jumpStartScene = [assimpImporter importScene:bobAnim];
  NSString* bobId = @"Bob-1";
  NSString* jumpId = @"jump_start-1";
  SCNAssimpAnimation* jumpStartAnim = [jumpStartScene animationForKey:bobId];
  [scene addAnimation:jumpStartAnim];
  
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
  
  scnView.playing = YES;
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
