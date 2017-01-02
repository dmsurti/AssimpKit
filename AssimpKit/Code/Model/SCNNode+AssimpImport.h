
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
#import <SceneKit/SceneKit.h>
#import "SCNAssimpAnimSettings.h"

/**
 A scenekit SCNNode category which imitates the SCNAnimatable protocol.
 */
@interface SCNNode (AssimpImport)

#pragma mark - SCNAnimatable Clone

/**
 @name SCNAnimatable Clone
 */

/**
 Adds an animation object for the specified key..

 @param animScene The scene object representing the animation.
 @param animKey An string identifying the animation for later retrieval. You may
 pass nil if you don’t need to reference the animation later.
 @param settings The animation settings object.
 */
- (void)addAnimationScene:(SCNScene *)animScene
                   forKey:(NSString *)animKey
             withSettings:(SCNAssimpAnimSettings *)settings;

/**
 Removes the animation attached to the object with the specified key.

 @param animKey A string identifying an attached animation to remove.
 */
- (void)removeAnimationSceneForKey:(NSString *)animKey;

/**
 Removes the animation attached to the object with the specified key, smoothly
 transitioning out of the animation’s effect.

 @param animKey A string identifying an attached animation to remove.
 @param fadeOutDuration The duration for transitioning out of the animation’s
 effect before it is removed
 */
- (void)removeAnimationSceneForKey:(NSString *)animKey
                   fadeOutDuration:(CGFloat)fadeOutDuration;

/**
 Pauses the animation attached to the object with the specified key.

 @param animKey A string identifying an attached animation.
 */
- (void)pauseAnimationSceneForKey:(NSString *)animKey;

/**
 Resumes a previously paused animation attached to the object with the specified
 key.

 @param animKey A string identifying an attached animation.
 */
- (void)resumeAnimationSceneForKey:(NSString *)animKey;

/**
 Returns a Boolean value indicating whether the animation attached to the object
 with the specified key is paused.

 @param animKey A string identifying an attached animation.
 @return YES if the specified animation is paused. NO if the animation is
 running or no animation is attached to the object with that key.
 */
- (BOOL)isAnimationSceneForKeyPaused:(NSString *)animKey;

#pragma mark - Skeleton

/**
 @name Skeleton
 */

/**
 Finds the root node of the skeleton in the scene.

 @return Retuns the root node of the skeleton in the scene.
 */
- (SCNNode *)findSkeletonRootNode;

@end
