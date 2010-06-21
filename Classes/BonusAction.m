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

#import "BonusAction.h"
#import "Config.h"
#import "Common.h"

@implementation BonusAction

+(id) actionWithType:(int)type pos:(cpVect)pos sm:(AtlasSpriteManager*)_sm;
{	
	return [[[self alloc] initWithType:type pos:pos sm:_sm] autorelease];
}

-(id) initWithType:(int)type pos:(cpVect)pos sm:(AtlasSpriteManager*)_sm {
	if (type > 10) {
		[super initWithDuration:BONUS_LONG_TIP_TIME];
	} else {
		[super initWithDuration:BONUS_TIP_TIME];
	}
	
	startPosition = pos;
	
	float a = fmod(arc4random(), D_PI);
	delta = cpvmult(cpvforangle(a), BONUS_TIP_DIST);
	
	sm = _sm;

	if (type < 0) {		
		sprite = [AtlasSprite spriteWithRect:CGRectMake((-type - 1) * 40, 64, 40, 32) spriteManager:sm];
		
	} else if (type < 9) {		
		sprite = [AtlasSprite spriteWithRect:CGRectMake((type - 1) * 40, 0, 40, 32) spriteManager:sm];
		
	} else if (type == 10) {
		// perfect hit
		sprite = [AtlasSprite spriteWithRect:CGRectMake(0, 32, 120, 32) spriteManager:sm];
		
	} else if (type == 11) {
		// x2
		sprite = [AtlasSprite spriteWithRect:CGRectMake(280, 32, 120, 32) spriteManager:sm];
		
	} else if (type == 12) {
		// x3
		sprite = [AtlasSprite spriteWithRect:CGRectMake(400, 32, 120, 32) spriteManager:sm];
		
	} else if (type == 20) {
		sprite = [AtlasSprite spriteWithRect:CGRectMake(120, 32, 40, 32) spriteManager:sm];
		
	} else if (type == 21) {
		sprite = [AtlasSprite spriteWithRect:CGRectMake(160, 32, 40, 32) spriteManager:sm];
		
	} else if (type == 22) {
		sprite = [AtlasSprite spriteWithRect:CGRectMake(200, 32, 80, 32) spriteManager:sm];
		
	} else {
		return nil;
	}
	
	sprite.position = pos;
	
	return self;
}



-(void)start {
	[sm addChild:sprite z:1];	
	[super start];
}



-(void)stop {
	[super stop];
	[sm removeChild:sprite cleanup:YES];	
}



-(void) update: (ccTime) t
{	
	if (t <= 0.1) {
		[sprite setOpacity: 255.0f * t * 10.0f];	
	} else if (t > 0.5) {
		[sprite setOpacity:255 - (255.0f * (t - 0.5f) * 2.0f)];	
	}
	
	[sprite setPosition: ccp( (startPosition.x + delta.x * t ), (startPosition.y + delta.y * t ) )];
}



@end
