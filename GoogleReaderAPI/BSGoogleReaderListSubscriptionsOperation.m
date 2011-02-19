//
//  BSGoogleReaderListSubscriptionsOperation.m
//  GoogleReaderAPITest
//
//  Created by Sasmito Adibowo on 08-02-11.
//  Copyright 2011 Basil Salad Software. All rights reserved.
//  http://basil-salad.com

#import "BSGoogleReaderListSubscriptionsOperation.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "CJSONDeserializer.h"
#import "BSErrors.h"

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
    NSString* const USER_AGENT_KEY = @"User-Agent";
    NSString* const USER_AGENT_VALUE = @"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_4; en-us) AppleWebKit/533.19.4 (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4";
    //
    // Step 1 - login
    NSURL* loginURL = [NSURL URLWithString:@"https://www.google.com/accounts/ClientLogin"];
    ASIFormDataRequest* loginRequest = [ASIFormDataRequest requestWithURL:loginURL];
    loginRequest.useCookiePersistence = NO;
    
    [loginRequest addRequestHeader:USER_AGENT_KEY value:USER_AGENT_VALUE];
    
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
    NSString* clientSID = nil;
    NSString* errorMessage = nil;
    NSString* clientAuth = nil;
    for(NSString* entry in loginResponseVariables) {
        NSArray* entryComponents = [entry componentsSeparatedByString:@"="];
        if (entryComponents.count == 2) {
            NSString* key = [entryComponents objectAtIndex:0];
            if ([@"SID" caseInsensitiveCompare:key] == NSOrderedSame) {
                clientSID = [entryComponents objectAtIndex:1];
            } else if ([@"Auth" caseInsensitiveCompare:key] == NSOrderedSame) {
                clientAuth = [entryComponents objectAtIndex:1];
            } else if ([@"Error" caseInsensitiveCompare:key] == NSOrderedSame) {
                errorMessage = [entryComponents objectAtIndex:1];
            }
        }
    }
    
    
    if (!clientSID || !clientAuth) {
        // return error
        NSMutableDictionary* errorInfo = [NSMutableDictionary dictionaryWithCapacity:3];
        ErrorLog(@"Error logging in. Response body:\n-----\n%@\n-----\n",loginResponse);

        [errorInfo setObject:NSLocalizedString(@"Could not log you in to Google.",@"Google Reader service") forKey:NSLocalizedDescriptionKey];

        if (errorMessage) {
            [errorInfo setObject:[NSString localizedStringWithFormat:@"Google returned error: \"%@\".",errorMessage] forKey:NSLocalizedFailureReasonErrorKey];
        }
        [errorInfo setObject:NSLocalizedString(@"Please re-check your Google ID and password.",@"Google Reader service") forKey:NSLocalizedRecoverySuggestionErrorKey];

        self.operationError = [NSError errorWithDomain:BSCommonsErrorDomain code:BSInvalidCredentialsError userInfo:errorInfo];
        return;
    }
    
    NSDate* expiryDate = [NSDate dateWithTimeIntervalSinceNow:3600 * 24 * 7];
    
    NSDictionary* clientSidCookieProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"0",NSHTTPCookieVersion,
                                            @"/",NSHTTPCookiePath,
                                            @".google.com",NSHTTPCookieDomain,
                                            expiryDate,NSHTTPCookieExpires,
                                            @"SID",NSHTTPCookieName,
                                            clientSID,NSHTTPCookieValue,
                                      nil];
    
    NSHTTPCookie* sidCookie = [NSHTTPCookie cookieWithProperties:clientSidCookieProps];
    
    //
    // Step 2 - retrieve feed list.
    u_int64_t now = abs(round([[NSDate date] timeIntervalSince1970] * 1000));
    NSURL* listURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.google.com/reader/api/0/subscription/list?output=json&client=scroll&ck=%qu",now]];
    
    NSString* authString = [NSString stringWithFormat:@"GoogleLogin auth=%@",clientAuth];
    
    ASIHTTPRequest* listRequest = [ASIHTTPRequest requestWithURL:listURL];
    listRequest.useCookiePersistence = NO;
    [loginRequest addRequestHeader:USER_AGENT_KEY value:USER_AGENT_VALUE];
    [listRequest addRequestHeader:@"Authorization" value:authString];
    
    [listRequest.requestCookies addObject:sidCookie];
    
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

        if (jsonError) {
            self.operationError = jsonError;
        } else {
            NSString* localizedFailureReason = [NSString localizedStringWithFormat:@"Google Reader doesn't return a dictionary for its root object but instead returned %@",[listData class]];
            ErrorLog(@"%@",localizedFailureReason);
            NSMutableDictionary* errorInfo = [NSMutableDictionary dictionaryWithCapacity:3];
            
            [errorInfo setObject:NSLocalizedString(@"Unknown data returned from Google Reader",@"Google Reader service") forKey:NSLocalizedDescriptionKey];
            [errorInfo setObject:localizedFailureReason forKey:NSLocalizedFailureReasonErrorKey];
            [errorInfo setObject:NSLocalizedString(@"Please retry at a later time.",@"Google Reader service") forKey:NSLocalizedRecoverySuggestionErrorKey];
            
            self.operationError = [NSError errorWithDomain:BSCommonsErrorDomain code:BSOperationError userInfo:errorInfo];
        }
        return;
    }
    
    NSArray* subscriptions = [listData objectForKey:@"subscriptions"];
    if (![subscriptions isKindOfClass:ARRAY_CLASS]) {
        // JSON parse error.
        NSString* localizedFailureReason = [NSString localizedStringWithFormat:@"Google Reader doesn't return an array for its \"subscriptions\" value but instead returned %@",[subscriptions class]];
        ErrorLog(@"%@",localizedFailureReason);
        NSMutableDictionary* errorInfo = [NSMutableDictionary dictionaryWithCapacity:3];
        
        [errorInfo setObject:NSLocalizedString(@"Unknown data returned from Google Reader",@"Google Reader service") forKey:NSLocalizedDescriptionKey];
        [errorInfo setObject:localizedFailureReason forKey:NSLocalizedFailureReasonErrorKey];
        [errorInfo setObject:NSLocalizedString(@"Please retry at a later time.",@"Google Reader service") forKey:NSLocalizedRecoverySuggestionErrorKey];

        self.operationError = [NSError errorWithDomain:BSCommonsErrorDomain code:BSOperationError userInfo:errorInfo];
        
        return;
    }
    
    const NSUInteger subscriptionsCount = subscriptions.count;
    if (subscriptionsCount == 0) {
        NSMutableDictionary* errorInfo = [NSMutableDictionary dictionaryWithCapacity:3];
        
        [errorInfo setObject:NSLocalizedString(@"No data returned from Google Reader",@"Google Reader service") forKey:NSLocalizedDescriptionKey];
        [errorInfo setObject:NSLocalizedString(@"You probably do not have any feed configured in Google Reader",@"Google Reader service") forKey:NSLocalizedFailureReasonErrorKey];
        [errorInfo setObject:NSLocalizedString(@"You do not need to import any feeds at this time.",@"Google Reader service") forKey:NSLocalizedRecoverySuggestionErrorKey];
        self.operationError = [NSError errorWithDomain:BSCommonsErrorDomain code:BSOperationError userInfo:errorInfo];
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
