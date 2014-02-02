//
//  Constants.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 10/27/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import "CTEConstants.h"

@implementation CTEConstants

//events
NSString * const ShowSideMenu = @"ShowSideMenu";
NSString * const HideSideMenu = @"HideSideMenu";
NSString * const ContentViewLoaded = @"ContentViewLoaded";
NSString * const ChangeFont = @"ChangeFont";
NSString * const ChangeFontSize = @"ChangeFontSize";
NSString * const ChangeColumnCount = @"ChangeColumnCount";
NSString * const ChangeFormat = @"ChangeFormat";
NSString * const PageForward = @"PageForward";
NSString * const PageBackward = @"PageBackward";

//settings
CGFloat const PageTurnBoundaryPhone = 50.0;
CGFloat const PageTurnBoundaryPad = 100.0;
CGFloat const MaxImageColumnHeightRatio = 0.6;
NSString * const SettingsFileName = @"EBookReaderSettings";

//labels
NSString * const NavigationBarTitle = @"CoreTextEBookReader";

//fonts
NSString * const BodyFontKey = @"BODY_FONT";
NSString * const BodyItalicFontKey = @"BODY_FONT_ITALIC";
NSString * const BodyFontSizeKey = @"BODY_FONT_SIZE";
NSString * const PageNumKey = @"PAGE_NUM";
NSString * const ColumnCountKey = @"COL_COUNT";
NSString * const BaskervilleFontKey = @"Baskerville";
NSString * const GeorgiaFontKey = @"Georgia";
NSString * const PalatinoFontKey = @"Palatino";
NSString * const TimesNewRomanFontKey = @"Times New Roman";
NSString * const BaskervilleFont = @"Baskerville";
NSString * const GeorgiaFont = @"Georgia";
NSString * const PalatinoFont = @"Palatino-Roman";
NSString * const TimesNewRomanFont = @"TimesNewRomanPSMT";
NSString * const BaskervilleFontItalic = @"Baskerville-Italic";
NSString * const GeorgiaFontItalic = @"Georgia-Italic";
NSString * const PalatinoFontItalic = @"Palatino-Italic";
NSString * const TimesNewRomanFontItalic = @"TimesNewRomanPS-ItalicMT";

//others
NSString *const HttpPrefix = @"http://";

@end
