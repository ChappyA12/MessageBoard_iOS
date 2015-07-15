//
//  MessageBoardPage.h
//  MessageBoard
//
//  Created by Chappy Asel on 7/15/15.
//  Copyright © 2015 CD. All rights reserved.
//

#import <Parse/Parse.h>
@class TextObject;

@interface MessageBoardPage : PFObject<PFSubclassing>
+ (NSString *)parseClassName;

@property NSNumber *pageNumber;

@property NSArray<TextObject *> *textObjects;

@end
