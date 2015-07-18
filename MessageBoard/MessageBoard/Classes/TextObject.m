//
//  TextObject.m
//  MessageBoard
//
//  Created by Chappy Asel on 7/15/15.
//  Copyright © 2015 CD. All rights reserved.
//

#import "TextObject.h"

@implementation TextObject

@dynamic text;
@dynamic font;
@dynamic fontSize;
@dynamic scale;
@dynamic location_x;
@dynamic location_y;
@dynamic rotation;
@dynamic color_r;
@dynamic color_g;
@dynamic color_b;
@dynamic parentPageObjectID;

+ (void)load { [self registerSubclass]; }

+ (NSString *)parseClassName { return @"TextObject"; }

- (NSString *)description {
    return [NSString stringWithFormat:@"TextObject: \n{text} %@ \n{position} %@,%@",self.text,self.location_x,self.location_y];
}

- (NSUInteger)hash {
    return [self.objectId hash]; //object ID is always enique
}

@end
