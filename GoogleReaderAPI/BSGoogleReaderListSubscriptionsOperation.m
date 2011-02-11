//
//  BSGoogleReaderListSubscriptionsOperation.m
//  GoogleReaderAPITest
//
//  Created by Sasmito Adibowo on 08-02-11.
//  Copyright 2011 Basil Salad Software. All rights reserved.
//  http://basil-salad.com

#import "BSGoogleReaderListSubscriptionsOperation.h"
#import <math.h>
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "CJSONDeserializer.h"

#import "FoundationAdditionsMacros.h"

NSString* const BSGoogleReaderTitleKey = @"com.basilsalad.BSGoogleReaderTitleKey";

NSString* const BSGoogleReaderCategoriesKey = @"com.basilsalad.BSGoogleReaderCategoriesKey";

NSString* const BSGoogleReaderFeedURLKey = @"com.basilsalad.BSGoogleReaderFeedURLKey";

NSString* const BSGoogleReaderItemIDKey = @"com.basilsalad.BSGoogleReaderItemIDKey";

NSString* const BSGoogleReaderFeedKey = @"com.basilsalad.BSGoogleReaderFeedKey";



@implementation BSGoogleReaderListSubscriptionsOperation

@synthesize resultFeeds;
@synthesize login;
@synthesize password;

-(void) performOperation {
    // login
    NSURL* loginURL = [NSURL URLWithString:@"https://www.google.com/accounts/ClientLogin"];
    ASIFormDataRequest* loginRequest = [ASIFormDataRequest requestWithURL:loginURL];
    
    [loginRequest setPostValue:@"reader" forKey:@"service"];
    [loginRequest setPostValue:@"scroll" forKey:@"source"];
    [loginRequest setPostValue:@"http://www.google.com/" forKey:@"continue"];

    [loginRequest setPostValue:self.login forKey:@"Email"];
    [loginRequest setPostValue:self.password forKey:@"Passwd"];
    [loginRequest startSynchronous];
   
    NSError* loginError = [loginRequest error];
    if (loginError) {
        self.operationError = loginError;
        return;
    }
    
    NSString* loginResponse = [loginRequest responseString];
    NSArray* loginResponseVariables = [loginResponse componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSString* clientToken = nil;
    NSString* errorMessage = nil;
    for(NSString* entry in loginResponseVariables) {
        NSArray* entryComponents = [entry componentsSeparatedByString:@"="];
        if (entryComponents.count == 2) {
            NSString* key = [entryComponents objectAtIndex:0];
            if ([@"SID" caseInsensitiveCompare:key] == NSOrderedSame) {
                clientToken = [entryComponents objectAtIndex:1];
                break;
            } else if ([@"Error" caseInsensitiveCompare:key] == NSOrderedSame) {
                errorMessage = [entryComponents objectAtIndex:1];
                break;
            }
        }
    }
    
    if (!clientToken) {
        // return error
        ErrorLog(@"Token not found - incorrect password? ErrorMessage: %@",errorMessage);
        return;
    }
    /*
    NSDictionary* clientTokenCookieProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 //@"1",NSHTTPCookieVersion,
                                                 @".google.com",NSHTTPCookieDomain,
                                                 @"1600000000",NSHTTPCookieMaximumAge,
                                                 @"/",NSHTTPCookiePath,
                                                 @"SID",NSHTTPCookieName,
                                                 clientToken,NSHTTPCookieValue,
                                                 nil];
    NSHTTPCookie* clientTokenCookie = [NSHTTPCookie cookieWithProperties:clientTokenCookieProperties];
     */
    u_int64_t now = abs(round([[NSDate date] timeIntervalSince1970] * 1000));
    
    NSURL* listURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.google.com/reader/api/0/subscription/list?output=json&client=scroll&ck=%qu",now]];
    
    
    ASIHTTPRequest* listRequest = [ASIHTTPRequest requestWithURL:listURL];
    //listRequest.requestCookies = [NSMutableArray arrayWithObject:clientTokenCookie];
    [listRequest startSynchronous];
    
    NSError* listError = [listRequest error];
    if (listError) {
        ErrorLog(@"Error listing feed: %@",listError);
        self.operationError = listError;
        return;
    }
    
    const Class DICTIONARY_CLASS = [NSDictionary class];
    const Class ARRAY_CLASS = [NSArray class];
    
    CJSONDeserializer* json = [CJSONDeserializer deserializer];
    NSError* jsonError = nil;    
    NSDictionary* listData = [json deserializeAsDictionary:[listRequest responseData] error:&jsonError];
    if (![listData isKindOfClass:DICTIONARY_CLASS]) {
        self.operationError = jsonError;
        return;
    }
    
    // TODO: parse JSON data and package into the result dictionaries
    NSArray* subscriptions = [listData objectForKey:@"subscriptions"];
    if (![subscriptions isKindOfClass:ARRAY_CLASS]) {
        // JSON parse error.
        return;
    }
    
    const NSUInteger subscriptionsCount = subscriptions.count;
    if (subscriptionsCount == 0) {
        // no data
        return;
    }
    
    NSMutableArray* feeds = [NSMutableArray arrayWithCapacity:subscriptionsCount];
    NSMutableDictionary* categories = [NSMutableDictionary dictionaryWithCapacity:subscriptionsCount];
    
    for(NSDictionary* subscriptionEntry in subscriptions) {
        if (![subscriptionEntry isKindOfClass:DICTIONARY_CLASS]) {
            continue;
        }
        NSString* subscriptionID = [subscriptionEntry objectForKey:@"id"];
        if (!subscriptionID) {
            continue;
        }
        
        NSString* subscriptionURLString = [subscriptionID stringByReplacingOccurrencesOfString:@"feed/" withString:@""];
        NSURL* subscriptionURL = [NSURL URLWithString:subscriptionURLString];
        if (!subscriptionURL) {
            continue;
        }
        
        NSMutableDictionary* feed = [NSMutableDictionary dictionaryWithCapacity:4];
        [feed setObject:subscriptionID forKey:BSGoogleReaderItemIDKey];
        [feed setObject:subscriptionURL forKey:BSGoogleReaderFeedURLKey];
        [feed setObject:BSNotNilString([subscriptionEntry objectForKey:@"title"]) forKey:BSGoogleReaderTitleKey];
        
        
        NSArray* feedCategories = [subscriptionEntry objectForKey:@"categories"];
        NSUInteger feedCategoriesCount = feedCategories.count;
        if (feedCategoriesCount > 0) {
            NSMutableArray* categoryAssignments = [NSMutableArray arrayWithCapacity:feedCategoriesCount];
            [feed setObject:categoryAssignments forKey:BSGoogleReaderCategoriesKey];
            
            for(NSDictionary* feedCategory in feedCategories) {
                NSString* categoryID = [feedCategory objectForKey:@"id"];
                if (!categoryID) {
                    continue;
                }
                NSMutableDictionary* category = [categories objectForKey:categoryID];
                if (!category) {
                    category = [NSMutableDictionary dictionaryWithCapacity:2];
                    [category setObject:categoryID forKey:BSGoogleReaderItemIDKey];
                    
                    [categories setObject:category forKey:categoryID];
                }
                NSString* categoryTitle = [feedCategory objectForKey:@"label"];
                if (categoryTitle.length > 0) {
                    [category setObject:categoryTitle forKey:BSGoogleReaderTitleKey];
                }
                [categoryAssignments addObject:category];
            }
        }
        
        [feeds addObject:feed];
    }
    
    [resultFeeds release];
    resultFeeds = [feeds retain];
}

-(void) dealloc {
	[login release];
	[password release];
    [resultFeeds release];
    [super dealloc];
}
@end
