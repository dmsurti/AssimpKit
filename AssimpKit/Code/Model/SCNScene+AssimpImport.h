
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

#include <GLKit/GLKit.h>
#import <SceneKit/SceneKit.h>
#import "SCNAssimpScene.h"
#import "PostProcessingFlags.h"

/**
 A scenekit SCNScene category to import scenes using the assimp library.
 */
@interface SCNScene (AssimpImport)

#pragma mark - Loading scenes using assimp

/**
 @name Loading scenes using assimp
 */

/**
  Returns the array of file extensions for all the supported formats.

  @return The array of supported file extensions
*/
+ (NSArray<NSString *> *)allowedFileExtensions;
/**
 Returns a Boolean value that indicates whether the SCNAssimpScene class can
 read asset data from files with the specified extension.

 @param extension The filename extension identifying an asset file format.
 @return YES if the SCNAssimpScene class can read asset data from files with
 the specified extension; otherwise, NO.
 */
+ (BOOL)canImportFileExtension:(NSString *)extension;

/**
 Loads a scene from a file with the specified name in the app’s main bundle.

 @param name The name of a scene file in the app bundle’s resources directory.
 @param postProcessFlags The flags for all possible post processing steps.
 @return A new scene object, or nil if no scene could be loaded.
 */
+ (SCNAssimpScene *)assimpSceneNamed:(NSString *)name
                    postProcessFlags:
                        (AssimpKitPostProcessSteps)postProcessFlags;

/**
 Loads a scene from the specified NSString URL.

 @param url The NSString URL to the scene file to load.
 @param postProcessFlags The flags for all possible post processing steps.
 @return A new scene object, or nil if no scene could be loaded.
 */
+ (SCNAssimpScene *)assimpSceneWithURL:(NSURL *)url
                      postProcessFlags:
                          (AssimpKitPostProcessSteps)postProcessFlags;

@end
