//
//  GameView.m
//  OSX-ObjC-Example
//
//  Created by Deepak Surti on 10/24/16.
//  Copyright (c) 2016 __MyCompanyName__. All rights reserved.
//

#import "GameView.h"

@implementation GameView

-(void)mouseDown:(NSEvent *)theEvent
{
    /* Called when a mouse click occurs */
    
    // check what nodes are clicked
    NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSArray *hitResults = [self hitTest:NSPointToCGPoint(p) options:nil];
    
    // check that we clicked on at least one object
    if([hitResults count] > 0){
        // retrieved the first clicked object
        SCNHitTestResult *result = [hitResults objectAtIndex:0];
        
        // get its material
        SCNMaterial *material = result.node.geometry.firstMaterial;
        
        // highlight it
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.5];

        // on completion - unhighlight
        [SCNTransaction setCompletionBlock:^{
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.5];

            material.emission.contents = [NSColor blackColor];
            
            [SCNTransaction commit];
        }];
        
        material.emission.contents = [NSColor redColor];
        
        [SCNTransaction commit];
    }
    
    
    [super mouseDown:theEvent];
}

@end
