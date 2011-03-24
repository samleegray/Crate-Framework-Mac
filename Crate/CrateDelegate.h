//
//  TinyGrabDelegate.h
//  CloudieApp
//
//  Created by Sam Gray on 3/12/11.
//  Copyright 2011 Sam Gray. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol CrateDelegate

-(void)uploadProgress:(int)percent;
-(void)downloadProgress:(int)percent;

@end
