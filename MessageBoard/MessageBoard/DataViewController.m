//
//  DataViewController.m
//  MessageBoard
//
//  Created by Chappy Asel on 7/15/15.
//  Copyright © 2015 CD. All rights reserved.
//

#import "DataViewController.h"
#import <Parse/Parse.h>
#import "MessageBoardPage.h"

@interface DataViewController ()

@property (nonatomic) MessageBoardPage *page;

@end

@implementation DataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.dataLabel.text = [NSString stringWithFormat:@"Page: %@", self.pageNumber];
    _page = [[MessageBoardPage alloc] initWithPageNumber:self.pageNumber];
    [_page saveInBackgroundWithBlock:^(BOOL succeeded, NSError * __nullable error) {
        if (succeeded) {
            
        }
        else NSLog(@"%@",error.description);
    }];
}

@end
