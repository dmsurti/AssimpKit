
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

#import <SceneKit/SceneKit.h>
#import "SCNNode+AssimpImport.h"

@implementation SCNNode (AssimpImport)

#pragma mark - SCNAnimatable Clone

/**
 @name SCNAnimatable Clone
 */

/**
 Adds the animation at the given node subtree to the corresponding node subtree
 in the scene.

 @param animNode The node and it's subtree which has a CAAnimation.
 */
- (void)addAnimationFromNode:(SCNNode *)animNode
                      forKey:(NSString *)animKey
                withSettings:(SCNAssimpAnimSettings *)settings
                   hasEvents:(BOOL)hasEvents
                 hasDelegate:(BOOL)hasDelegate
{
    for (NSString *nodeAnimKey in animNode.animationKeys)
    {
        CAAnimation *animation = [animNode animationForKey:nodeAnimKey];

        // CAMediaTiming
        animation.beginTime = settings.beginTime;
        animation.timeOffset = settings.timeOffset;
        animation.repeatCount = settings.repeatCount;
        animation.repeatDuration = settings.repeatDuration;
        if (animation.duration == 0)
        {
            animation.duration = settings.duration;
        }
        animation.speed = settings.speed;
        animation.autoreverses = settings.autoreverses;
        animation.fillMode = settings.fillMode;

        // Animation attributes
        animation.removedOnCompletion = settings.removedOnCompletion;
        animation.timingFunction = settings.timingFunction;

        // Controlling SceneKit Animation Timing
        animation.usesSceneTimeBase = settings.usesSceneTimeBase;

        // Fading Between SceneKit Animations
        animation.fadeInDuration = settings.fadeInDuration;
        animation.fadeOutDuration = settings.fadeOutDuration;

        if (hasEvents)
        {
            animation.animationEvents = settings.animationEvents;
            hasEvents = NO;
        }
        if (hasDelegate)
        {
            animation.delegate = settings.delegate;
            hasDelegate = NO;
        }

        NSString *boneName = animNode.name;
        SCNNode *sceneBoneNode =
            [self childNodeWithName:boneName recursively:YES];
        NSString *key = [[nodeAnimKey stringByAppendingString:@"-"]
            stringByAppendingString:animKey];
        [sceneBoneNode addAnimation:animation forKey:key];
    }
    for (SCNNode *childNode in animNode.childNodes)
    {
        [self addAnimationFromNode:childNode
                            forKey:animKey
                      withSettings:settings
                         hasEvents:hasEvents
                       hasDelegate:hasDelegate];
    }
}

/**
 Adds a skeletal animation scene to the scene.

 @param animScene The scene object representing the animation.
 */
- (void)addAnimationScene:(SCNScene *)animScene
                   forKey:(NSString *)animKey
             withSettings:(SCNAssimpAnimSettings *)settings
{
    SCNNode *rootAnimNode = [animScene.rootNode findSkeletonRootNode];

    SCNAssimpAnimSettings *defaultSettings =
        [[SCNAssimpAnimSettings alloc] init];

    if (settings == nil)
    {
        settings = defaultSettings;
    }

    BOOL hasEvents = settings.animationEvents.count > 0;
    BOOL hasDelegate = (settings.delegate != nil);

    if (rootAnimNode.childNodes.count > 0)
    {
        [self addAnimationFromNode:rootAnimNode
                            forKey:animKey
                      withSettings:settings
                         hasEvents:hasEvents
                       hasDelegate:hasDelegate];
    }
    else
    {
        // no root exists, so add animation data to all bones
        DLog(@" no root: %@ %d", rootAnimNode.parentNode,
             rootAnimNode.parentNode.childNodes.count);
        [self addAnimationFromNode:rootAnimNode.parentNode
                            forKey:animKey
                      withSettings:settings
                         hasEvents:hasEvents
                       hasDelegate:hasDelegate];
    }
}

- (void)removeAnimationAtNode:(SCNNode *)animNode
                       forKey:(NSString *)animKey
              fadeOutDuration:(CGFloat)fadeOutDuration
                 withSuffixes:(NSArray *)suffixes
{
    if (animNode.name != nil)
    {
        NSString *keyPrefix = [@"/node-" stringByAppendingString:animNode.name];
        for (NSString *suffix in suffixes)
        {
            NSString *key = [[keyPrefix stringByAppendingString:suffix]
                stringByAppendingString:animKey];
            [animNode removeAnimationForKey:key];
        }
    }
    for (SCNNode *child in animNode.childNodes)
    {
        [self removeAnimationAtNode:child
                             forKey:animKey
                    fadeOutDuration:0.0
                       withSuffixes:suffixes];
    }
}

- (void)removeAnimationSceneForKey:(NSString *)animKey
{
    NSArray *suffixes = [[NSArray alloc]
        initWithObjects:@".transform.translation-", @".transform.quaternion-",
                        @".transform.scale-", nil];
    [self removeAnimationAtNode:self
                         forKey:animKey
                fadeOutDuration:0.0
                   withSuffixes:suffixes];
}

- (void)removeAnimationSceneForKey:(NSString *)animKey
                   fadeOutDuration:(CGFloat)fadeOutDuration
{
    NSArray *suffixes = [[NSArray alloc]
        initWithObjects:@".transform.translation-", @".transform.quaternion-",
                        @".transform.scale-", nil];
    [self removeAnimationAtNode:self
                         forKey:animKey
                fadeOutDuration:fadeOutDuration
                   withSuffixes:suffixes];
}

- (void)pauseAnimationAtNode:(SCNNode *)animNode
                      forKey:(NSString *)animKey
                withSuffixes:(NSArray *)suffixes
{
    if (animNode.name != nil)
    {
        NSString *keyPrefix = [@"/node-" stringByAppendingString:animNode.name];
        for (NSString *suffix in suffixes)
        {
            NSString *key = [[keyPrefix stringByAppendingString:suffix]
                stringByAppendingString:animKey];
            NSLog(@" pausing animation with key: %@", key);
            [animNode pauseAnimationForKey:key];
        }
    }
    for (SCNNode *child in animNode.childNodes)
    {
        [self pauseAnimationAtNode:child forKey:animKey withSuffixes:suffixes];
    }
}

- (void)pauseAnimationSceneForKey:(NSString *)animKey
{
    NSArray *suffixes = [[NSArray alloc]
        initWithObjects:@".transform.translation-", @".transform.quaternion-",
                        @".transform.scale-", nil];
    [self pauseAnimationAtNode:self forKey:animKey withSuffixes:suffixes];
}

- (void)resumeAnimationAtNode:(SCNNode *)animNode
                       forKey:(NSString *)animKey
                 withSuffixes:(NSArray *)suffixes
{
    if (animNode.name != nil)
    {
        NSString *keyPrefix = [@"/node-" stringByAppendingString:animNode.name];
        for (NSString *suffix in suffixes)
        {
            NSString *key = [[keyPrefix stringByAppendingString:suffix]
                stringByAppendingString:animKey];
            NSLog(@" resuming animation with key: %@", key);
            [animNode resumeAnimationForKey:key];
        }
    }
    for (SCNNode *child in animNode.childNodes)
    {
        [self resumeAnimationAtNode:child forKey:animKey withSuffixes:suffixes];
    }
}

- (void)resumeAnimationSceneForKey:(NSString *)animKey
{
    NSArray *suffixes = [[NSArray alloc]
        initWithObjects:@".transform.translation-", @".transform.quaternion-",
                        @".transform.scale-", nil];
    [self resumeAnimationAtNode:self forKey:animKey withSuffixes:suffixes];
}

- (BOOL)isAnimationForScenePausedAtNode:(SCNNode *)animNode
                                 forKey:(NSString *)animKey
                           withSuffixes:(NSArray *)suffixes
{
    BOOL paused = NO;
    if (animNode.name != nil)
    {
        NSString *keyPrefix = [@"/node-" stringByAppendingString:animNode.name];
        for (NSString *suffix in suffixes)
        {
            NSString *key = [[keyPrefix stringByAppendingString:suffix]
                stringByAppendingString:animKey];
            NSLog(@" resuming animation with key: %@", key);
            paused = [animNode isAnimationForKeyPaused:key];
        }
    }
    if(paused)
    {
        return paused;
    } else
    {
        for (SCNNode *child in animNode.childNodes)
        {
            paused = [self isAnimationForScenePausedAtNode:child
                                                    forKey:animKey
                                              withSuffixes:suffixes];
        }
    }
    return paused;
}

- (BOOL)isAnimationSceneForKeyPaused:(NSString *)animKey
{
    NSArray *suffixes = [[NSArray alloc]
                         initWithObjects:@".transform.translation-", @".transform.quaternion-",
                         @".transform.scale-", nil];
    return [self isAnimationForScenePausedAtNode:self
                                          forKey:animKey
                                    withSuffixes:suffixes];
}

#pragma mark - Skeleton

/**
 @name Skeleton
 */

/**
 Finds the root node of the skeleton in the scene.

 @return Retuns the root node of the skeleton in the scene.
 */
- (SCNNode *)findSkeletonRootNode
{
    __block SCNNode *rootAnimNode = nil;
    // find root of skeleton
    [self enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
      if (child.animationKeys.count > 0)
      {
          DLog(@" found anim: %@ at node %@", child.animationKeys, child);
          rootAnimNode = child;
          *stop = YES;
      }
    }];
    return rootAnimNode;
}

@end
