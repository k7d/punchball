/*
 Copyright 2009 Kaspars Dancis
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "EnterName.h"
#import "Common.h"

@implementation EnterName

- (id) initWithDelegate: (id<EnterNameDelegate>)_delegate window:(UIWindow*)_window {
	[super init];
	
	delegate = _delegate;
	window = _window;
	
	Sprite *bg = [Sprite spriteWithFile:@"name.png"];
	bg.anchorPoint = cpvzero;	
	[self addChild:bg z:1];			
	
	view = [[EnterNameView alloc] initWithDelegate:self];
	
	return self;
}


- (void) dealloc {
	[view release];
	[super dealloc];
}

	
- (void)layerReplaced
{
	[window addSubview:view];
}

- (void) nameEntered: (NSString*)name 
{
	Label *l = [Label labelWithString:name fontName:@"Courier" fontSize:30];
	l.anchorPoint = cpvzero;
	l.position = cpv(30, 225);
	[self addChild:l];
	
	[view removeFromSuperview];	
	[delegate nameEntered:name];	
}

@end


@implementation EnterNameView

- (id) initWithDelegate: (id)_delegate {
	if (self = [super initWithFrame:CGRectMake(0,0,480,320)]) {
		self.userInteractionEnabled = true;
		
		self.transform = CGAffineTransformMakeRotation(H_PI);		
		self.bounds = CGRectMake(-80, -80, 480, 320);		
		
		delegate = _delegate;
		
        nameField = [[[UITextField alloc] initWithFrame:CGRectMake(30, 60, 420, 40)] autorelease];
		nameField.font = [UIFont fontWithName:@"Courier" size:30];
		nameField.returnKeyType = UIReturnKeyDone;
		nameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
		nameField.autocorrectionType = UITextAutocorrectionTypeNo;
		nameField.keyboardType = UIKeyboardTypeAlphabet;
		nameField.textColor = [UIColor whiteColor];
		nameField.delegate = self;
		[self addSubview:nameField];

		[nameField becomeFirstResponder];		
    }
	
    return self;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	NSString *name = [[nameField text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([name length] == 0) {
		UIAlertView *popup = [[UIAlertView alloc] initWithTitle:@"Please enter a name" message:@"It will be used to record your highscores as well as identify you in a multiplayer game." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[popup show];
	} else {
		[nameField resignFirstResponder];
		[delegate nameEntered:[nameField text]];
	}
	return YES;
}

@end
