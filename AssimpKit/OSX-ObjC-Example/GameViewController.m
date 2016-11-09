
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
#import "SCNScene+AssimpImport.h"

@implementation GameViewController

- (void)awakeFromNib
{
  //  NSString* filePath = @"/Users/deepaksurti/ios-osx/assimp/demo/assets/"
  // @"models-nonbsd/3DS/jeep1.3ds";
  NSString *filePath =
      @"/Users/deepaksurti/ios-osx/assimp/demo/assets/astroBoy_walk.dae";
  SCNAssimpScene *scene =
      [SCNScene assimpSceneWithURL:[NSURL URLWithString:filePath]];
  // SCNScene* scene = [SCNScene assimpSceneNamed:@"spider.obj"];
  SCNAssimpAnimation *walkAnim = [scene animationForKey:@"astroBoy_walk-1"];
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
