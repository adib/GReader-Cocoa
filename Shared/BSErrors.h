//
//  BSErrors.h
//  News Anchor
//
//  Created by Sasmito Adibowo on 01/02/10.
//  Copyright 2010 Basil Salad Software. All rights reserved.
//  http://basil-salad.com

#import <Cocoa/Cocoa.h>

extern NSString* const BSCommonsErrorDomain;
extern NSString* const BSUnderlyingExceptionErrorKey;
extern NSString* const BSCallstackSymbolsErrorKey;
extern NSString* const BSProcessTerminationStatusErrorKey;


enum  {
	// error while loading feed from network.
	
	// Foundation addition errors start at 0x100
	BSMalformedURLStringError = 0x101,
	
	// AppKit & UIKit Addition errors start at 0x200
	BSAppSupportFolderError = 0x201,
	
	BSUnhandledExceptionError = 0x102,

	// Core Data Addition errors start at 0x300
	BSNoPersistentStoreCoordinatorError	=	0x301,
	
	// Own errors start at 0x1000
	BSOperationError	= 0x1001,
	BSProcessLaunchError = 0x1002,
	BSProcessReturnError = 0x1003,
    BSInvalidCredentialsError = 0x1004,

	// I/O errors start at 0x1100
	
	BSFileExistsError = 0x1101,
	BSFileWriteError = 0x1102,
	BSFileMissingError = 0x1103,
	
	
	
	// Application level errors start at 0x2000
	BSBetaVersionExpiredError = 0x2001
	
};

