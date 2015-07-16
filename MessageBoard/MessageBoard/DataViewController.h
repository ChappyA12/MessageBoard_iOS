//
//  DataViewController.h
//  MessageBoard
//
//  Created by Chappy Asel on 7/15/15.
//  Copyright © 2015 CD. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *dataLabel;
@property (weak, nonatomic) IBOutlet UIView *canvas;
@property (strong, nonatomic) IBOutlet UITextField *textField;

@property (strong, nonatomic) NSNumber *pageNumber;

@end

