//
//  BSSOperation.h
//  Basil Salad Commons
//
//  Created by Sasmito Adibowo on 31/07/10.
//  Copyright 2010 Basil Salad Software. All rights reserved.
//  http://basil-salad.com

#import <Cocoa/Cocoa.h>


@interface BSOperation : NSOperation {
@private
	NSMutableDictionary * userInfo;
	NSError* operationError;
}

/**
 Arbitrary tag -- not used by the operation object but simply retained
 */
@property (nonatomic,retain) NSMutableDictionary* userInfo;


/**
 Set whenever the operation encountered an error.
 */
@property (nonatomic,retain) NSError* operationError;


-(void) handleException:(NSException*) e;

@end
