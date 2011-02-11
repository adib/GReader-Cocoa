//
//  BSGoogleReaderListSubscriptionsOperation.h
//  GoogleReaderAPITest
//
//  Created by Sasmito Adibowo on 08-02-11.
//  Copyright 2011 Basil Salad Software. All rights reserved.
//  http://basil-salad.com

#import <Cocoa/Cocoa.h>
#import "BSCallbackOperation.h"

@interface BSGoogleReaderListSubscriptionsOperation : BSCallbackOperation {
    NSArray* resultFeeds;
    NSString* login;
    NSString* password;
}

@property (nonatomic,retain) NSString* login;
@property (nonatomic,retain) NSString* password;

@property (nonatomic,readonly) NSArray* resultFeeds;

@end



extern NSString* const BSGoogleReaderTitleKey;

extern NSString* const BSGoogleReaderCategoriesKey;

extern NSString* const BSGoogleReaderFeedKey;

extern NSString* const BSGoogleReaderFeedURLKey;

extern NSString* const BSGoogleReaderItemIDKey;