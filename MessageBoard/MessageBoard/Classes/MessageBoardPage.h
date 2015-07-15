//
//  MessageBoardPage.h
//  MessageBoard
//
//  Created by Chappy Asel on 7/15/15.
//  Copyright © 2015 CD. All rights reserved.
//

#import <Parse/Parse.h>

@interface MessageBoardPage : PFObject<PFSubclassing>
+ (NSString *)parseClassName;

- (id) initWithPageNumber: (NSNumber *) number;

@property NSNumber *pageNumber;

@end
