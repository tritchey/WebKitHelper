//
//  WebKitHelperController.h
//  Vigil
//
//  Created by Timothy Ritchey on 6/10/08.
//  Copyright 2008 Red Rome Logic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WebSiteManagedObject.h"

@interface WebKitHelperController : NSObject {
    NSString *url;
    WebSiteManagedObject *webSite;
    NSTask *thumbnailTask;
    NSPipe *thumbnailPipe;
    NSUInteger currentKey;
    NSUInteger currentLength;
    NSMutableData *currentData;
}
- (void)initWithURL:(NSString *)aString forWebSiteObject:(id)anObject;
- (void)gatherURLInfo;
- (void)webKitHelperReady:(NSNotification *)note;
- (void)webKitHelperTerminated:(NSNotification *)note;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end
