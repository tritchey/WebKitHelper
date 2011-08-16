//
//  WebKitHelperController.m
//  Vigil
//
//  Created by Timothy Ritchey on 6/10/08.
//  Copyright 2008 Red Rome Logic. All rights reserved.
//

#import "WebKitHelperController.h"
#import "WebKitHelperKeys.h"

@implementation WebKitHelperController

- (void)initWithURL:(NSString *)aString forWebSiteObject:(id)anObject
{
    self = [super init];
    if(self) {
        url = [aString copy];
        webSite = [anObject retain];
        currentData = nil;
        currentKey = RRNoKey;
        currentLength = 0;
        [self gatherURLInfo];
    }
}

- (void)dealloc
{
    [url release];
    [webSite release];
    [thumbnailPipe release];
    [super dealloc];
}

- (void)gatherURLInfo
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *webKitHelperPath = [bundle pathForResource:@"WebKitHelper" ofType:@"app"];
    NSString *webKitHelperExecutablePath = [NSString stringWithFormat:@"%@%@", webKitHelperPath, @"/Contents/MacOS/WebKitHelper"];
    if(webKitHelperExecutablePath) {
        thumbnailTask = [[NSTask alloc] init];
        [thumbnailTask setLaunchPath:webKitHelperExecutablePath];
        NSArray *args = [NSArray arrayWithObjects: @"-url", url, nil];
        [thumbnailTask setArguments:args];
        thumbnailPipe = [[NSPipe alloc] init];
        [thumbnailTask setStandardOutput:thumbnailPipe];
        
        NSFileHandle *fh = [thumbnailPipe fileHandleForReading];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(webKitHelperReady:) name:NSFileHandleReadCompletionNotification object:fh];
        [nc addObserver:self selector:@selector(webKitHelperTerminated:) name:NSTaskDidTerminateNotification object:thumbnailTask];
        [thumbnailTask launch];
        [fh readInBackgroundAndNotify];
    } else {
        [thumbnailTask release];
    }
}    

- (void)webKitHelperReady:(NSNotification *)note
{
    NSData *d = [[note userInfo] valueForKey:NSFileHandleNotificationDataItem];

    if([d length] > 0) {
        // if there is no key yet set, the data we got back
        // should be the key
        if(currentKey == RRNoKey) {
            // the first block back is the key
            [d getBytes:&currentKey length:sizeof(NSUInteger)];
            d = [d subdataWithRange:NSMakeRange(sizeof(NSUInteger), [d length] - sizeof(NSUInteger))];            
        }
        
        // if there is still data left, and we don't have a length yet
        // then what we have is the length
        if(currentLength == 0 && [d length] > 0) {
            [d getBytes:&currentLength length:sizeof(NSUInteger)];
            d = [d subdataWithRange:NSMakeRange(sizeof(NSUInteger), [d length] - sizeof(NSUInteger))];
        }
        
        // otherwise, everything left is data
        if([d length] > 0) {
            if(currentData == nil) {
                currentData = [[NSMutableData alloc] initWithCapacity:currentLength];
            }
            [currentData appendData:d];
        }
        
        // check to see if we have everything
        if(currentLength > 0 && currentLength == [currentData length]) {
            
            if(currentKey == RRTitleKey) {
                NSString *s = [[[NSString alloc] initWithData:currentData encoding:NSUTF8StringEncoding] autorelease];
                [webSite setValue:s forKey:@"title"];
            } else if(currentKey == RRIconKey) {
                [webSite setValue:currentData forKey:@"favicon"];
            } else if(currentKey == RRThumbnailKey) {
                [webSite setValue:currentData forKey:@"thumbnail"];
            } else if(currentKey == RRErrorKey) {
                NSString *s = [[[NSString alloc] initWithData:currentData encoding:NSUTF8StringEncoding] autorelease];
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                [alert addButtonWithTitle:@"OK"];
                [alert setMessageText:@"Error Retrieving Information for URL"];
                [alert setInformativeText:s];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
                [self retain]; // make sure we don't go away before the user closes the alert box
            }
            [currentData release];
            currentData = nil;
            currentKey = RRNoKey;
            currentLength = 0;
        }
        
        [[thumbnailPipe fileHandleForReading] readInBackgroundAndNotify];
    }
}

- (void)webKitHelperTerminated:(NSNotification *)note
{
//    NSLog(@"helper terminated");
    [thumbnailTask release];
    thumbnailTask = nil;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    [self autorelease];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [[alert window] orderOut:nil];
    [self autorelease]; // we are ready to let ourselves go
}

@end
