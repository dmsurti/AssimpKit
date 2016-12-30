
/*
---------------------------------------------------------------------------
Assimp to Scene Kit Library (AssimpKit)
---------------------------------------------------------------------------
Copyright (c) 2016, Deepak Surti, Ison Apps, AssimpKit team
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
* Neither the name of the AssimpKit team, nor the names of its
  contributors may be used to endorse or promote products
  derived from this software without specific prior
  written permission of the AssimpKit team.
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
#import <AssimpKit/PostProcessingFlags.h>
#import <AssimpKit/SCNScene+AssimpImport.h>

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Load the scene
    SCNAssimpScene *scene =
        [SCNScene assimpSceneWithURL:[NSURL URLWithString:self.modelFilePath]
                    postProcessFlags:AssimpKit_Process_FlipUVs |
                                     AssimpKit_Process_Triangulate];

    // Load the animation scene
    if (self.animFilePath)
    {
        SCNAssimpScene *animScene =
            [SCNScene assimpSceneWithURL:[NSURL URLWithString:self.animFilePath]
                        postProcessFlags:AssimpKit_Process_FlipUVs |
                                         AssimpKit_Process_Triangulate];
        NSArray *animationKeys = animScene.animationKeys;
        // If multiple animations exist, load the first animation
        if (animationKeys.count > 0)
        {
            SCNScene* animation = [animScene animationSceneForKey:[animationKeys objectAtIndex:0]];
            [scene.modelScene addAnimationScene:animation];
        }
    }

    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;

    // set the scene to the view
    scnView.scene = scene.modelScene;

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
