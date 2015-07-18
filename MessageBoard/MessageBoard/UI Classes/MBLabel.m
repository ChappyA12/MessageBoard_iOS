//
//  MBLabel.m
//  MessageBoard
//
//  Created by Chappy Asel on 7/17/15.
//  Copyright © 2015 CD. All rights reserved.
//

#import "MBLabel.h"
#import "TextObject.h"

@implementation MBLabel

- (id)initWithTextObject: (TextObject *) textObject andCanvas: (UIView *) canvas {
    if (self = [super init]) {
        _textObject = textObject;
        _canvasSize = canvas.frame.size;
        UIFont *font = [UIFont fontWithName:_textObject.font size:[_textObject.fontSize floatValue]];
        CGSize textSize = [_textObject.text sizeWithAttributes:@{NSFontAttributeName:font}];
        CGPoint loc = [self canvasLocation];
        self.frame = CGRectMake(loc.x-textSize.width/2, loc.y, textSize.width, textSize.height);
        self.text = _textObject.text;
        self.font = font;
        self.textColor = [UIColor colorWithRed:[_textObject.color_r floatValue] green:[_textObject.color_g floatValue] blue:[_textObject.color_b floatValue] alpha:1.0];
        self.textAlignment = NSTextAlignmentCenter;
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor redColor]; //TEMPORARY
        self.numberOfLines = 0;
        CGSize maximumLabelSize = CGSizeMake(350, 2000);
        CGSize expectedSize = [self sizeThatFits:maximumLabelSize];
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, expectedSize.width, expectedSize.height);
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedUILabel:)];
        [self addGestureRecognizer:tapRecognizer];
        UIPanGestureRecognizer *dragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(userDraggedUILabel:)];
        [self addGestureRecognizer:dragRecognizer];
        UIPinchGestureRecognizer *scaleRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(userScaledUILabel:)];
        [self addGestureRecognizer:scaleRecognizer];
        UIRotationGestureRecognizer *rotateRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(userRotatedUILabel:)];
        [self addGestureRecognizer:rotateRecognizer];
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userLongPressedUILabel:)];
        [self addGestureRecognizer:longPressRecognizer];
        [self updateTranslations];
    }
    return self;
}

#pragma mark - public methods

- (void)updateText {
    UIFont *font = [UIFont fontWithName:_textObject.font size:[_textObject.fontSize floatValue]*[_textObject.scale floatValue]];
    CGSize textSize = [_textObject.text sizeWithAttributes:@{NSFontAttributeName:font}];
    self.text = _textObject.text;
    self.font = font;
    self.textColor = [UIColor colorWithRed:[_textObject.color_r floatValue] green:[_textObject.color_g floatValue] blue:[_textObject.color_b floatValue] alpha:1.0];
    CGPoint loc = [self canvasLocation];
    self.frame = CGRectMake(loc.x-textSize.width/2, loc.y, textSize.width, textSize.height);
    self.numberOfLines = 0;
    CGSize maximumLabelSize = CGSizeMake(350, 2000);
    CGSize expectedSize = [self sizeThatFits:maximumLabelSize];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, expectedSize.width, expectedSize.height);
}

- (void)updateTranslations {
    UIFont *font = [UIFont fontWithName:_textObject.font size:[_textObject.fontSize floatValue]*[_textObject.scale floatValue]];
    CGSize textSize = [_textObject.text sizeWithAttributes:@{NSFontAttributeName:font}];
    self.font = font;
    CGPoint loc = [self canvasLocation];
    self.frame = CGRectMake(loc.x, loc.y, textSize.width, textSize.height);
    //label.bounds = CGRectMake([textObject.location_x floatValue], [textObject.location_y floatValue], textSize.width, textSize.height);
    //label.center = CGPointMake(label.bounds.origin.x+label.bounds.size.width/2, label.bounds.origin.y+label.bounds.size.height/2);
    self.transform = CGAffineTransformMakeRotation([_textObject.rotation floatValue]);
    self.numberOfLines = 0;
    CGSize maximumLabelSize = CGSizeMake(500, 2000);
    CGSize expectedSize = [self sizeThatFits:maximumLabelSize];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, expectedSize.width, expectedSize.height);
}

#pragma mark - point conversion

- (CGPoint)canvasLocation {
    return CGPointMake([_textObject.location_x floatValue]*_canvasSize.width, [_textObject.location_y floatValue]*_canvasSize.height);
}

- (CGPoint)textObjectLocationForPoint: (CGPoint) point {
    return CGPointMake(point.x/_canvasSize.width, point.y/_canvasSize.height);
}

#pragma mark - gesture recognition

CGPoint dragLocationInsideUILabel;

- (IBAction)userTappedUILabel:(UITapGestureRecognizer *)sender {
    [_delegate shouldBeginEditingMBLabel:self];
}

- (IBAction)userLongPressedUILabel:(UILongPressGestureRecognizer *)sender {
    [_delegate shouldRemoveMBLabel:self];
}

- (IBAction)userDraggedUILabel:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) dragLocationInsideUILabel = [sender locationInView:self];
    CGPoint loc = [self textObjectLocationForPoint: [sender locationInView:[self superview]]];
    CGPoint adjLoc = [self textObjectLocationForPoint:dragLocationInsideUILabel];
    _textObject.location_x = [NSNumber numberWithFloat: loc.x - adjLoc.x];
    _textObject.location_y = [NSNumber numberWithFloat: loc.y - adjLoc.y];
    [self updateTranslations];
    if (sender.state == UIGestureRecognizerStateEnded) [self endTranslation];
}

- (IBAction)userScaledUILabel:(UIPinchGestureRecognizer *)sender {
    _textObject.scale = [NSNumber numberWithFloat:sender.scale];
    [self updateTranslations];
    //[self updateTextObject:textEdited withLocation:[sender locationInView:_canvas]];
    if (sender.state == UIGestureRecognizerStateEnded) [self endTranslation];
}

- (IBAction)userRotatedUILabel:(UIRotationGestureRecognizer *)sender {
    _textObject.rotation = [NSNumber numberWithFloat:sender.rotation];
    [self updateTranslations];
    //[self updateTextObject:textEdited withLocation:[sender locationInView:_canvas]];
    if (sender.state == UIGestureRecognizerStateEnded) [self endTranslation];
}

- (void)endTranslation {
    [_delegate translationEndedForTextObject:_textObject];
}

#pragma mark - overridden methods

- (NSUInteger)hash {
    return [_textObject hash]+1;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
