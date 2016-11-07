//
//  SCNAssimpAnimation.m
//  AssimpKit
//
//  Created by Deepak Surti on 11/7/16.
//
//

#import "SCNAssimpAnimation.h"

@interface SCNAssimpAnimation ()

@property(readwrite, nonatomic) NSString* key;
@property(readwrite, nonatomic) NSDictionary* frameAnims;

@end

@implementation SCNAssimpAnimation

-(id)initWithKey:(NSString*)key frameAnims:(NSDictionary*)anims {
  self = [super init];
  if (self) {
    self.key = key;
    self.frameAnims = anims;
  }
  return self;
}

@end
