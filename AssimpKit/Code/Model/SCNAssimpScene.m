
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
#import "SCNAssimpScene.h"

@interface SCNAssimpScene ()

@property (readwrite, nonatomic) NSMutableDictionary *animations;

@end

@implementation SCNAssimpScene

- (id)init
{
    self = [super init];
    if (self)
    {
        self.animations = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addAnimation:(SCNAssimpAnimation *)assimpAnimation
{
    NSDictionary *frameAnims = assimpAnimation.frameAnims;
    for (NSString *nodeName in frameAnims.allKeys)
    {
        SCNNode *boneNode =
            [self.rootNode childNodeWithName:nodeName
                                 recursively:YES];
        NSDictionary *channelKeys = [frameAnims valueForKey:nodeName];
        CAKeyframeAnimation *posAnim = [channelKeys valueForKey:@"position"];
        CAKeyframeAnimation *quatAnim = [channelKeys valueForKey:@"orientation"];
        CAKeyframeAnimation *scaleAnim = [channelKeys valueForKey:@"scale"];
        NSLog(@" for node %@ pos anim is %@ quat anim is %@", boneNode, posAnim,
                  quatAnim);
        if (posAnim)
        {
            [boneNode addAnimation:posAnim
                            forKey:[nodeName stringByAppendingString:@"-pos"]];
        }
        if (quatAnim)
        {
            [boneNode addAnimation:quatAnim
                            forKey:[nodeName stringByAppendingString:@"-quat"]];
        }
        if (scaleAnim)
        {
            [boneNode addAnimation:scaleAnim
                            forKey:[nodeName stringByAppendingString:@"-scale"]];
        }
    }
}

- (SCNAssimpAnimation *)animationForKey:(NSString *)key
{
    return [self.animations valueForKey:key];
}

@end
