//
//  CTEContentPopoverViewController.h
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/18/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CTEViewOptionsViewController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) IBOutlet UIPickerView *pickerView;

@property (nonatomic, strong) NSArray *fonts;
@property (nonatomic, strong) NSArray *fontSizes;
@property (nonatomic, strong) NSArray *columns;
@property (nonatomic, strong) NSString *selectedFont;
@property (nonatomic, strong) NSNumber *selectedFontSize;
@property (nonatomic, strong) NSNumber *selectedColumnsInView;
@property (nonatomic, strong) UIColor *barColor;

@property (nonatomic, strong) IBOutlet UIView *backgroundHeader;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
         selectedFont:(NSString *)fontKey
     selectedFontSize:(NSNumber *)selectedFontSize
selectedColumnsInView:(NSNumber *)selectedColumnsInView
             barColor:(UIColor *)color;
@end
