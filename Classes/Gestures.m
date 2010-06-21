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

#import "Gestures.h"

#define THRESHOLD 15.0f


typedef enum {
	UP,
	UP_RIGHT,
	RIGHT,
	DOWN_RIGHT,
	DOWN,
	DOWN_LEFT,
	LEFT,
	UP_LEFT
} Direction;

@implementation Gestures

-(id)initWithDelegate:(id<GesturesDelegate>)_delegate {
	self = [super init];
	
	delegate = _delegate;
	
	return self;
}



- (void)dealloc {
	[super dealloc];
}



- (void) touchesBegan:(NSSet *)touches {
}



- (void) touchesMoved:(NSSet *)touches {
}



- (void) touchesEnded:(NSSet *)touches {
	NSMutableArray *directions = [NSMutableArray arrayWithCapacity:[touches count]];
	
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];		
		CGPoint prevLocation = [touch previousLocationInView: [touch view]];				
		CGPoint delta = cpvsub(location, prevLocation);

		if (delta.x > THRESHOLD) {
			if (delta.y > THRESHOLD) {
				[directions addObject:[NSNumber numberWithInt:DOWN_RIGHT]];
			} else if (delta.y < -THRESHOLD) {
				[directions addObject:[NSNumber numberWithInt:UP_RIGHT]];
			} else {
				[directions addObject:[NSNumber numberWithInt:RIGHT]];
			}

		} else if (delta.x < -THRESHOLD) {
			if (delta.y > THRESHOLD) {
				[directions addObject:[NSNumber numberWithInt:DOWN_LEFT]];
			} else if (delta.y < -THRESHOLD) {
				[directions addObject:[NSNumber numberWithInt:UP_LEFT]];
			} else {
				[directions addObject:[NSNumber numberWithInt:LEFT]];
			}
			
		} else {
			if (delta.y > THRESHOLD) {
				[directions addObject:[NSNumber numberWithInt:DOWN]];
			} else if (delta.y < -THRESHOLD) {
				[directions addObject:[NSNumber numberWithInt:UP]];
			} 			
		}		
	}	
	
	if ([directions count] == 2) {
		if ([(NSNumber*)[directions objectAtIndex:0] intValue] == DOWN &&
			[(NSNumber*)[directions objectAtIndex:1] intValue] == DOWN) 
		{
			[delegate onGesture:TWO_DOWN];
			
		} else if ([(NSNumber*)[directions objectAtIndex:0] intValue] == LEFT &&
				   [(NSNumber*)[directions objectAtIndex:1] intValue] == LEFT) 
		{
			[delegate onGesture:TWO_LEFT];
		}
	}	
}


@end
