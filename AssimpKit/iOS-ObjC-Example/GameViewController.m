
/*
---------------------------------------------------------------------------
Assimp to Scene Kit Library (AssimpKit)
---------------------------------------------------------------------------
Copyright (c) 2016, AssimpKit team
All rights reserved.
Redistribution and use of this software in source and binary forms,
with or without modification, are permitted provided that the following
conditions are met:
* Redistributions of source code must retain the above
  copyright notice, this list of conditions and the
  following disclaimer.
* Redistributions in binary form must reproduce the above
  copyright notice, this list of conditions and the
  following disclaimer in the documentation and/or other
  materials provided with the distribution.
* Neither the name of the assimp team, nor the names of its
  contributors may be used to endorse or promote products
  derived from this software without specific prior
  written permission of the assimp team.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
---------------------------------------------------------------------------
*/

#import "GameViewController.h"
#import "AssimpImporter.h"
#import "SCNScene+AssimpImport.h"

@implementation GameViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString *docsDir = [paths objectAtIndex:0];
  NSString *explorer =
      [docsDir stringByAppendingString:@"/explorer_skinned.dae"];
  NSString *bob = [docsDir stringByAppendingString:@"/Bob.md5mesh"];
  SCNAssimpScene *scene =
      [SCNScene assimpSceneWithURL:[NSURL URLWithString:bob]];

  // Now we can access the file's contents
  NSString *runAnim =
      [docsDir stringByAppendingString:@"/explorer/jump_start.dae"];
  NSString *bobAnim = [docsDir stringByAppendingString:@"/Bob.md5anim"];
  AssimpImporter *assimpImporter = [[AssimpImporter alloc] init];
  SCNAssimpScene *jumpStartScene = [assimpImporter importScene:bobAnim];
  NSString *bobId = @"Bob-1";
  NSString *jumpId = @"jump_start-1";
  SCNAssimpAnimation *jumpStartAnim = [jumpStartScene animationForKey:bobId];
  [scene addAnimation:jumpStartAnim];

  // retrieve the SCNView
  SCNView *scnView = (SCNView *)self.view;

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

- (BOOL)shouldAutorotate
{
  return YES;
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] ==
      UIUserInterfaceIdiomPhone)
  {
    return UIInterfaceOrientationMaskAllButUpsideDown;
  }
  else
  {
    return UIInterfaceOrientationMaskAll;
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

@end
