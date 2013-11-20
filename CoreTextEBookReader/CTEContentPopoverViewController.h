//
//  CTEContentPopoverViewController.h
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/18/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CTEContentPopoverViewController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) IBOutlet UIButton *fontSmallerButton;
@property (nonatomic, strong) IBOutlet UIButton *fontLargerButton;
@property (nonatomic, strong) IBOutlet UIButton *singleColumnButton;
@property (nonatomic, strong) IBOutlet UIButton *doubleColumnButton;
@property (nonatomic, strong) IBOutlet UIPickerView *fontPicker;

@property (nonatomic, strong) NSArray *fonts;

@end
