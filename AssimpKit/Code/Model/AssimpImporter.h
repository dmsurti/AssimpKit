
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

#import <Foundation/Foundation.h>
#include <GLKit/GLKit.h>
#import <SceneKit/SceneKit.h>
#import "SCNAssimpScene.h"
#import "PostProcessingFlags.h"

/**
 An importer that imports the files with formats supported by Assimp and
 converts the assimp scene graph into a scenekit scene graph.
 */
@interface AssimpImporter : NSObject

#pragma mark - Creating an importer

/**
 @name Creating an importer
 */

/**
 Creates an importer to import files supported by AssimpKit.

 @return A new importer.
 */
- (id)init;

#pragma mark - Loading a scene
/**
 Loads a scene from the specified file path.

 @param filePath The path to the scene file to load.
 @param postProcessFlags The flags for all possible post processing steps.
 @return A new scene object, or nil if no scene could be loaded.
 */
- (SCNAssimpScene *)importScene:(NSString *)filePath
               postProcessFlags:(AssimpKitPostProcessSteps)postProcessFlags;

@end
