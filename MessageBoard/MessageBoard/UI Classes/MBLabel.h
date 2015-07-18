//
//  MBLabel.h
//  MessageBoard
//
//  Created by Chappy Asel on 7/17/15.
//  Copyright © 2015 CD. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TextObject;
@class MBLabel;

@protocol MBLabelDelegate <NSObject>
@required

- (void)shouldBeginEditingMBLabel: (MBLabel *) label;
- (void)shouldRemoveMBLabel: (MBLabel *) label;
- (void)translationEndedForTextObject: (TextObject *) textObject;

@end

@interface MBLabel : UILabel

@property (nonatomic) TextObject *textObject;
@property (nonatomic) CGSize canvasSize;
@property (nonatomic, assign) id <MBLabelDelegate> delegate;

- (id)initWithTextObject: (TextObject *) textObject andCanvas: (UIView *) canvas;

- (void)updateText;

- (void)updateTranslations;

@end
