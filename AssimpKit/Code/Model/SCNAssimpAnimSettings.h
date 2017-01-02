
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

/**
 SCNAssimpAnimSettings provides support for CAMediaTiming protocol, animation
 attributes and animating scenekit content.
 */
@interface SCNAssimpAnimSettings : NSObject

#pragma mark - CAMediaTiming

/**
 @name CAMediaTiming
 */

/**
 Specifies the begin time of the receiver in relation to its parent object, if
 applicable.
 */
@property CFTimeInterval beginTime;

/**
  Specifies an additional time offset in active local time.
 */
@property CFTimeInterval timeOffset;

/**
 Determines the number of times the animation will repeat.
 */
@property float repeatCount;

/**
 Determines how many seconds the animation will repeat for.
 */
@property CFTimeInterval repeatDuration;

/**
 Specifies the basic duration of the animation, in seconds.
 */
@property CFTimeInterval duration;

/**
 Specifies how time is mapped to receiver’s time space from the parent time
 space.
 */
@property float speed;

/**
 Determines if the receiver plays in the reverse upon completion.
 */
@property BOOL autoreverses;

/**
 Determines if the receiver’s presentation is frozen or removed once its active
 duration has completed.
 */
@property (copy) NSString *fillMode;

#pragma mark - Animation attributes

/**
 @name Animation attributes
 */
/**
 Determines if the animation is removed from the target layer’s animations upon
 completion.
 */
@property (getter=isRemovedOnCompletion) BOOL removedOnCompletion;

/**
 An optional timing function defining the pacing of the animation.
 */
@property (strong) CAMediaTimingFunction *timingFunction;

#pragma mark - Getting and setting the delegate

/**
 @name Getting and setting the delegate
*/

/**
 Specifies the receiver’s delegate object.
 */
@property (strong) id<CAAnimationDelegate> delegate;

#pragma mark - Controlling SceneKit Animation Timing

/**
 Controlling SceneKit Animation Timing
 */

/**
 For animations attached to SceneKit objects, a Boolean value that determines
 whether the animation is evaluated using the scene time or the system time.
 */
@property BOOL usesSceneTimeBase;

#pragma mark - Fading Between SceneKit Animations

/**
 Fading Between SceneKit Animations
 */

/**
 For animations attached to SceneKit objects, the duration for transitioning
 into the animation’s effect as it begins.
 */
@property CGFloat fadeInDuration;

/**
 For animations attached to SceneKit objects, the duration for transitioning out
 of the animation’s effect as it ends.
 */
@property CGFloat fadeOutDuration;

#pragma mark - Attaching SceneKit Animation Events

/**
 Attaching SceneKit Animation Events
 */

/**
 For animations attached to SceneKit objects, a list of events attached to an
 animation.
 */
@property (nonatomic, copy) NSArray<SCNAnimationEvent *> *animationEvents;

@end
