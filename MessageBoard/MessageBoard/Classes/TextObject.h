//
//  TextObject.h
//  MessageBoard
//
//  Created by Chappy Asel on 7/15/15.
//  Copyright © 2015 CD. All rights reserved.
//

#import <Parse/Parse.h>

@interface TextObject : PFObject <PFSubclassing>

@property NSString *text;

@property NSString *font;
@property NSNumber *fontSize;

@property NSNumber *location_x;
@property NSNumber *location_y;

@property NSNumber *rotation; //0.0 - 2.0 (radians)

@property NSNumber *color_r;
@property NSNumber *color_g;
@property NSNumber *color_b;

@property NSString *parentPageObjectID;

+ (NSString *)parseClassName;

@end
