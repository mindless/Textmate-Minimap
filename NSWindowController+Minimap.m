//
//  NSWindowController+Minimap.m
//  TextmateMinimap
//
//  Created by Julian Eberius on 09.02.10.
//  Copyright 2010 Julian Eberius. All rights reserved.
//

#import "NSWindowController+Minimap.h"
#import "MinimapView.h"
#import "TextMate.h"
#import "TextMateMinimap.h"
#import "objc/runtime.h"

// stuff that the textmate-windowcontrollers (OakProjectController, OakDocumentControler) implement 
@interface NSWindowController (TextMate_WindowControllers_Only)
- (id)textView;
- (void)goToLineNumber:(id)newLine;
- (unsigned int)getLineHeight;
@end

@implementation NSWindowController (MM_NSWindowController)

- (void)refreshMinimap 
{
	NSWindow* window = [self window];
	for (NSDrawer *drawer in [window drawers])
		if ([[drawer contentView] isKindOfClass:[MinimapView class]] )  {
			MinimapView* textShapeView = (MinimapView*)[drawer contentView];
			[textShapeView refreshDisplay];	
		}
}

- (int)getCurrentLine:(id)textView
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	[textView bind:@"lineNumber" toObject:dict  
	   withKeyPath:@"line"   options:nil];
	int line = [(NSNumber*)[dict objectForKey:@"line"] intValue];
	//[textView unbind:@"lineNumber"];
	return line;
}

- (void)toggleMinimap
{
	NSWindow* window = [self window];
	for (NSDrawer *drawer in [window drawers])
		if ([[drawer contentView] isKindOfClass:[MinimapView class]] )  {
			int state = [drawer state];
			if (state == NSDrawerClosedState || state == NSDrawerClosingState)
				[drawer open];
			else 
				[drawer close];
		}
			
}

- (void)scrollToLine:(unsigned int)newLine
{
	NSWindow* window = [self window];
	for (NSDrawer *drawer in [window drawers])
		if ([[drawer contentView] isKindOfClass:[MinimapView class]] )  {
			id textView = [self textView];
			MinimapView* textShapeView = (MinimapView*)[drawer contentView];
			
			[textView goToLineNumber: [NSNumber numberWithInt:newLine]];
			
			[textShapeView refreshDisplay];
		}
}

- (BOOL) isSoftWrapEnabled
{
	NSMenu* viewMenu = [[[NSApp mainMenu] itemWithTitle:@"View"] submenu];
	for (NSMenuItem* item in [viewMenu itemArray])
	{
		if ([[item title] isEqualToString:@"Soft Wrap"])
		{
			return [item state];
		}
	}
	return NO;
}

#pragma mark swizzled_methods

- (void)MM_windowWillClose:(id)aNotification
{
	for (NSDrawer *drawer in [[self window] drawers])
		if ([[drawer contentView] isKindOfClass:[MinimapView class]] )  {
			[drawer setContentView:nil];
			[drawer setParentWindow:nil];
		}

	// call original
    [self MM_windowWillClose:aNotification];
}

- (void)MM_windowDidLoad
{
    // call original
    [self MM_windowDidLoad];
	
    NSWindow* window=[self window];
	NSSize contentSize = NSMakeSize(160, [window frame].size.height);
	id minimapDrawer = [[NSDrawer alloc] initWithContentSize:contentSize preferredEdge:NSMaxXEdge];
	[minimapDrawer setParentWindow:window];
	
	// init textshapeview
    MinimapView* textshapeView=  [[MinimapView alloc] initWithTextView:[self textView]];
	[textshapeView setWindowController:self];
	
	if ([[self className] isEqualToString:@"OakProjectController"]) {
		[minimapDrawer setTrailingOffset:56];
		[minimapDrawer setLeadingOffset:24];
	}
	else if ([[self className] isEqualToString:@"OakDocumentController"]) {
		[minimapDrawer setTrailingOffset:56];
		[minimapDrawer setLeadingOffset:0];
	}
	
	[minimapDrawer setContentView:textshapeView];
	[minimapDrawer openOnEdge:NSMaxXEdge];

	[minimapDrawer release];
	[textshapeView release];
}


@end