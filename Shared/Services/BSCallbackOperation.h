//
//  BSSCallbackOperation.h
//  Basil Salad Commons
//
//  Created by Sasmito Adibowo on 31/07/10.
//  Copyright 2010 Basil Salad Software. All rights reserved.
//  http://basil-salad.com

#import <Cocoa/Cocoa.h>
#import "BSOperation.h"

/**
 An operation object that will return itself to a specified selector within the thread.
 */
@interface BSCallbackOperation : BSOperation {
@private
	id callbackTarget;
	SEL callbackSelector;
	NSThread* callbackThread;
}

/**
 Creates the operation object.  At the end of the operation this will call the specified target
 in the specified thread.  when the threadOrNil parameter is nil, the current thread is assumed to 
 be the target thread.
 */

-(id) initWithTarget:(id) target selector:(SEL) selector thread:(NSThread*) threadOrNil;




/**
 Override this method to perform processing.
 */
-(void) performOperation;

@end
