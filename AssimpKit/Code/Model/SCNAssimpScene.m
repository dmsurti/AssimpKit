
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
#import "SCNAssimpScene.h"

@interface SCNAssimpScene ()

#pragma mark - SCNScene objects

/**
 @name SCNScene objects
 */

/**
 The scene representing the mdoel and the optional skeleton.
 */
@property (readwrite, nonatomic) SCNScene *modelScene;

/**
 The array of scenes where each scene is a skeletal animation.
 */

@property (readwrite, nonatomic) NSDictionary *animationScenes;

#pragma mark - Add, fetch SCNAssimpAnimation animations

/**
 @name Add, fetch SCNAssimpAnimation animations
 */

/**
 The dictionary of SCNAssimpAnimation objects, for each animation in the scene.
 */
@property (readwrite, nonatomic) NSMutableDictionary *animations;

/**
 Adds an SCNAssimpAnimation object.

 @param assimpAnimation The scene animation object created from animation data.
 */
- (void)addAnimation:(SCNAssimpAnimation *)assimpAnimation
             toScene:(SCNScene *)animScene;

/**
 Return the SCNAssimpAnimation object for the specified animation key.

 @param key The unique scene animation key.
 @return The scene animation object.
 */
- (SCNAssimpAnimation *)animationForKey:(NSString *)key;

@end

@implementation SCNAssimpScene

#pragma mark - Creating a new scene animation
/**
 @name Creating a new scene animation
 */

/**
 Creates a new scene animation, without any animation data.

 @return A new scene animation object.
 */
- (id)init
{
    self = [super init];
    if (self)
    {
        self.animations = [[NSMutableDictionary alloc] init];
        self.animationScenes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Add, fetch SCNAssimpAnimation animations

/**
 @name Add, fetch SCNAssimpAnimation animations
 */

/**
 Adds an SCNAssimpAnimation object to the given scene.

 @param assimpAnimation The scene animation object created from the animation
 data.
 @param animScene The scene to which the animation object is added.
 */
- (void)addAnimation:(SCNAssimpAnimation *)assimpAnimation
             toScene:(SCNScene *)animScene
{
    NSDictionary *frameAnims = assimpAnimation.frameAnims;
    for (NSString *nodeName in frameAnims.allKeys)
    {
        SCNNode *boneNode =
            [animScene.rootNode childNodeWithName:nodeName recursively:YES];
        NSDictionary *channelKeys = [frameAnims valueForKey:nodeName];
        CAKeyframeAnimation *posAnim = [channelKeys valueForKey:@"position"];
        CAKeyframeAnimation *quatAnim =
            [channelKeys valueForKey:@"orientation"];
        CAKeyframeAnimation *scaleAnim = [channelKeys valueForKey:@"scale"];
        DLog(@" for node %@ pos anim is %@ quat anim is %@", boneNode, posAnim,
             quatAnim);
        NSString *nodeKey = [@"/node-" stringByAppendingString:nodeName];
        if (posAnim)
        {
            NSString *posKey =
                [nodeKey stringByAppendingString:@".transform.translation"];
            [boneNode addAnimation:posAnim forKey:posKey];
        }
        if (quatAnim)
        {
            NSString *quatKey =
                [nodeKey stringByAppendingString:@".transform.quaternion"];
            [boneNode addAnimation:quatAnim forKey:quatKey];
        }
        if (scaleAnim)
        {
            NSString *scaleKey =
                [nodeKey stringByAppendingString:@".transform.scale"];
            [boneNode addAnimation:scaleAnim forKey:scaleKey];
        }
    }
}

/**
 Return the SCNAssimpAnimation object for the specified animation key.
 
 @param key The unique scene animation key.
 @return The scene animation object.
 */
- (SCNAssimpAnimation *)animationForKey:(NSString *)key
{
    return [self.animations valueForKey:key];
}

#pragma mark - Add, fetch scene animations

/**
 @name Add, fetch scene animations
 */

/**
 Return the keys for all the animations in this file.

 @return The array of animation keys.
 */
- (NSArray *)animationKeys
{
    return self.animationScenes.allKeys;
}

/**
Return the SCNScene object for the specified animation key.

@param key The unique scene animation key.
@return The scene animation object.
*/
- (SCNScene *)animationSceneForKey:(NSString *)key
{
    return [self.animationScenes valueForKey:key];
}

#pragma mark - Make SCNScene objects

/**
 @name Make SCNScene objects
 */

/**
 Makes the SCNScene representing the model and the optional skeleton.

 This transformation to SCNScene allows the client to use the existing SCNScene
 API. This also makes it trivial to support serialization using the existing
 SCNScene export API, thereby allowing easy integration in the XCode Scene
 editor and the asset pipeline.
 */
- (void)makeModelScene
{
    self.modelScene = [[SCNScene alloc] init];
    for (SCNNode *childNode in self.rootNode.childNodes)
    {
        [self.modelScene.rootNode addChildNode:childNode];
    }
}

/**
 Makes an array of SCNScene objects, each SCNScene representing a skeletal
 animation.

 This transformation to SCNScene allows the client to use the existing SCNScene
 API. This also makes it trivial to support serialization using the existing
 SCNScene export API, thereby allowing easy integration in the XCode Scene
 editor and the asset pipeline.
 */
- (void)makeAnimationScenes
{
    for (NSString *animSceneKey in self.animations.allKeys)
    {
        SCNAssimpAnimation *assimpAnim =
            [self.animations valueForKey:animSceneKey];
        SCNScene *animScene = [[SCNScene alloc] init];
        [animScene.rootNode addChildNode:[self.skeletonNode clone]];
        [self addAnimation:assimpAnim toScene:animScene];
        [self.animationScenes setValue:animScene forKey:animSceneKey];
    }
}

@end
