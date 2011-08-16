//
//  WKHController.m
//  Vigil
//
//  Created by Timothy Ritchey on 6/8/08.
//  Copyright 2008 Red Rome Logic. All rights reserved.
//

#import "WebKitHelper.h"
#import "WebKitHelperKeys.h"
#import <QuartzCore/QuartzCore.h>

@implementation WebKitHelper

- (void)awakeFromNib
{

    viewSize = NSMakeSize(800, 1100);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *urlArg = [userDefaults stringForKey:@"url"];
    
    if (urlArg == nil || [urlArg length] == 0) {
        [self errorOut:@"no URL provided"];
    }

    NSMutableString *url = [NSMutableString stringWithString:urlArg];

    // check url for beginning http://
    if(![url hasPrefix:@"http://"]) {
        [url insertString:@"http://" atIndex:0];
    }
    
	
    NSURL *valid = [NSURL URLWithString:url];
    if (valid == nil)
    {
        [self errorOut:@"invalid URL format"];
    }
    
    // now we are going to do our fun stuff here
    webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, viewSize.width, viewSize.height) frameName:@"MyFrame" groupName:@"MyGroup"];
    [webView setMaintainsBackForwardList:NO];
    [webView setFrameLoadDelegate:self];
    
    // set preferences so that we limit what gets loaded
    // for creating the thumbnail
    WebPreferences *prefs = [webView preferences];
    [prefs setPlugInsEnabled:NO];
    [prefs setJavaEnabled:NO];
    [prefs setJavaScriptCanOpenWindowsAutomatically:NO];
    [prefs setJavaScriptEnabled:NO];
    [prefs setAllowsAnimatedImages:NO];
    
    // most memory-efficient setting; remote resources are still cached to disk
    if ([prefs respondsToSelector:@selector(setCacheModel:)]) {
        [prefs setCacheModel:WebCacheModelDocumentViewer];
    }
    
    [webView setMainFrameURL:url];  
}

- (void)returnData:(NSData *)data forKey:(NSUInteger)key
{
    NSUInteger length = [data length];
    if(length > 0) {
        NSData *keyData = [NSData dataWithBytes:&key length:sizeof(NSUInteger)];
        NSData *lengthData = [NSData dataWithBytes:&length length:sizeof(NSUInteger)];
        NSFileHandle *out = [NSFileHandle fileHandleWithStandardOutput];
        [out writeData:keyData];
        [out writeData:lengthData];
        [out writeData:data];
    }
}

- (void)errorOut:(NSString *)errorMessage
{
    [self returnData:[errorMessage dataUsingEncoding:NSUTF8StringEncoding] forKey:RRErrorKey];
    [self exit];
}

- (void)exit
{
    [webView stopLoading:nil];
    [webView setFrameLoadDelegate:nil];
    [webView autorelease];
    webView = nil;    
    exit(0);
}


- (void)logFrame:(WebFrame *)frame delegate:(NSString *)name
{
    WebDataSource *ds = [frame provisionalDataSource];
    if(ds == nil) {
        ds = [frame dataSource];
    }
    if(ds != nil) {
        NSLog(@"%@: name: \"%@\" url: %@", name, [frame name], [[ds request] URL]);
    } else {
        NSLog(@"%@: name: \"%@\"", name, [frame name]);
    }    
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    if(frame == [sender mainFrame]) {
        [self errorOut:@"Unable to load URL"];
    }
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    [self errorOut:@"Unable to load URL"];
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if(frame == [sender mainFrame]) {
        // pull out an image for the frame
        WebFrameView *view = [[sender mainFrame] frameView];
        [view setAllowsScrolling:NO];
        
        NSBitmapImageRep *bitmap = [view bitmapImageRepForCachingDisplayInRect:NSMakeRect(0,0,viewSize.width, viewSize.height)];
        [sender cacheDisplayInRect:[sender bounds] toBitmapImageRep:bitmap];
        
        CIImage *original = [[[CIImage alloc] initWithBitmapImageRep:bitmap] autorelease];
        
        // extend the edges of the image
        CIFilter *filter = [CIFilter filterWithName:@"CIAffineClamp"];
        [filter setValue:[NSAffineTransform transform] forKey:@"inputTransform"];
        [filter setValue:original forKey:@"inputImage"];
        original = [filter valueForKey:@"outputImage"];
        
        // scale down the image
        filter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
        [filter setDefaults];
        
        float scaleH = 0.125;
        float aspect = 1.0f;
        
        [filter setValue:[NSNumber numberWithFloat:scaleH] forKey:@"inputScale"];
        [filter setValue:[NSNumber numberWithFloat:aspect] forKey:@"inputAspectRatio"];
        
        [filter setValue:original forKey:@"inputImage"];
        original = [filter valueForKey:@"outputImage"];
        
        CIVector *cropRect = [CIVector vectorWithX:0.0 Y:0.0 Z:100.0 W: 136.0];
        filter = [CIFilter filterWithName:@"CICrop"];
        [filter setValue:original forKey:@"inputImage"];
        [filter setValue:cropRect forKey:@"inputRectangle"];
        original = [filter valueForKey:@"outputImage"];
        
        NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize([original extent].size.width, [original extent].size.height)] autorelease];
        [image addRepresentation:[NSCIImageRep imageRepWithCIImage:original]];
        
        [self returnData:[image TIFFRepresentation] forKey:RRThumbnailKey];
        
        [self exit];
    }
}

- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame
{
    if(frame == [sender mainFrame]) {
        [self returnData:[image TIFFRepresentation] forKey:RRIconKey];
    }
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
    if(frame == [sender mainFrame]) {
        [self returnData:[title dataUsingEncoding:NSUTF8StringEncoding] forKey:RRTitleKey];
    }
}

@end
