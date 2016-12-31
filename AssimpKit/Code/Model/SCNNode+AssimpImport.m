
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

#import "SCNNode+AssimpImport.h"
#import <SceneKit/SceneKit.h>

@implementation SCNNode (AssimpImport)
#pragma mark - Adding animation

/**
 @name Adding animation
 */

/**
 Adds the animation at the given node subtree to the corresponding node subtree
 in the scene.
 
 @param animNode The node and it's subtree which has a CAAnimation.
 */
- (void)addAnimationFromNode:(SCNNode *)animNode
{
    for (NSString *animKey in animNode.animationKeys)
    {
        CAAnimation *animation = [animNode animationForKey:animKey];
        NSString *boneName = animNode.name;
        SCNNode *sceneBoneNode =
        [self childNodeWithName:boneName recursively:YES];
        [sceneBoneNode addAnimation:animation forKey:animKey];
    }
    for (SCNNode *childNode in animNode.childNodes)
    {
        [self addAnimationFromNode:childNode];
    }
}

/**
 Adds a skeletal animation scene to the scene.
 
 @param animScene The scene object representing the animation.
 */
- (void)addAnimationScene:(SCNScene *)animScene
{
    __block SCNNode *rootAnimNode = nil;
        // find root of skeleton
    [animScene.rootNode
     enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
         if (child.animationKeys.count > 0)
         {
             DLog(@" found anim: %@ at node %@", child.animationKeys, child);
             rootAnimNode = child;
             *stop = YES;
         }
         
     }];
    
    if (rootAnimNode.childNodes.count > 0)
    {
        [self addAnimationFromNode:rootAnimNode];
    }
    else
    {
            // no root exists, so add animation data to all bones
        DLog(@" no root: %@ %d", rootAnimNode.parentNode,
             rootAnimNode.parentNode.childNodes.count);
        [self addAnimationFromNode:rootAnimNode.parentNode];
    }
}

@end
