//
//  WKHController.h
//  Vigil
//
//  Created by Timothy Ritchey on 6/8/08.
//  Copyright 2008 Red Rome Logic. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

// This is the main object that grabs the url passed into the command-line
// downloads all the stuff we need, and passes it back to the application
// that called us

@interface WebKitHelper : NSObject {
    WebView *webView;
    NSSize viewSize;
}
- (void)returnData:(NSData *)data forKey:(NSUInteger)key;
- (void)errorOut:(NSString *)errorMessage;
- (void)exit;
- (void)logFrame:(WebFrame *)frame delegate:(NSString *)name;
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame;

@end
