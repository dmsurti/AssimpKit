//
//  SCNAssimpAnimation.h
//  AssimpKit
//
//  Created by Deepak Surti on 11/7/16.
//
//

#import <SceneKit/SceneKit.h>

@interface SCNAssimpAnimation : SCNScene

@property (readonly, nonatomic) NSString *key;
@property (readonly, nonatomic) NSDictionary *frameAnims;

- (id)initWithKey:(NSString *)key frameAnims:(NSDictionary *)anims;

@end
