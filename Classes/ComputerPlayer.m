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

#import "ComputerPlayer.h"


@implementation ComputerPlayer

-(id) initWithPos:(cpVect)pos 
			 left:(bool)left
			color:(int)_color 
			 game:(Game*)_game 
		   headSM:(AtlasSpriteManager*)_headSM 
		  gloveSM:(AtlasSpriteManager*)_gloveSM 
		 springSM:(AtlasSpriteManager*)_springSM 
		  bonusSM:(AtlasSpriteManager*)_bonusSM
   headParticleSM:(AtlasSpriteManager*)_headParticleSM 
			space:(cpSpace*)_space
	  otherPlayer:(Player*)_otherPlayer 
{
	[super initWithPos:pos 
				  left:left 
				 color:_color 
				  game:_game
				headSM:_headSM 
			   gloveSM:_gloveSM 
			  springSM:_springSM 
			   bonusSM:_bonusSM	 
		headParticleSM:_headParticleSM 
				 space:_space];
	
	holdPosition = false;
	
	otherPlayer = _otherPlayer;
	maxSweep = MAX_SWEEP;
	
	firstCycle = true;
		
	return self;
}



-(void) step:(ccTime) dt {
	[super step:dt];

	if (firstCycle) {
		slideTime = time + fabs(fmod(arc4random(), 100)) * maxSlideDelay / 100.0f;
		turnTime = time + fabs(fmod(arc4random(), 100)) * maxPunchDelay / 100.0f;
		punchTime = turnTime + fabs(fmod(arc4random(), 100)) * maxSweep / 100.0f;
		firstCycle = false;
	}
	
	if (punchTime < time) {
		cpVect aim;
		aim.x = otherPlayer.headBody->p.x + fabs(fmod(arc4random(), hitPrecision * 2)) - hitPrecision;
		aim.y = otherPlayer.headBody->p.y + fabs(fmod(arc4random(), hitPrecision * 2)) - hitPrecision;
		
		[self punch:aim];
		
		turnTime = time + fabs(fmod((float)arc4random(), 100.0f)) * maxPunchDelay / 100.0f;
		punchTime = turnTime + fabs(fmod(arc4random(), 100)) * maxSweep / 100.0f;
		
	} else if (turnTime < time) {
		cpVect aim;
		aim.x = otherPlayer.headBody->p.x + fabs(fmod(arc4random(), hitPrecision * 2)) - hitPrecision;
		aim.y = otherPlayer.headBody->p.y + fabs(fmod(arc4random(), hitPrecision * 2)) - hitPrecision;
		
		[self turn:aim];		
		
	} else if (slideTime < time) {
		cpVect slideTo;
		slideTo.x = fmod(arc4random(), (slideMax * 2)) - slideMax;
		slideTo.y = fmod(arc4random(), (slideMax * 2)) - slideMax;
		
		if (slideTo.x > 0) {
			slideTo.x += SLIDE_TARGET_APROX;
		} else {
			slideTo.x -= SLIDE_TARGET_APROX;
		}
		
		if (slideTo.y > 0) {
			slideTo.y += SLIDE_TARGET_APROX;
		} else {
			slideTo.y -= SLIDE_TARGET_APROX;
		}
		
		slideTo.x += headBody->p.y;
		slideTo.y += headBody->p.x;
		
		if (slideTo.x < 40) {
			slideTo.x = 40;
		} else if (slideTo.x > 440) {
			slideTo.x = 440;
		}		
		
		if (slideTo.y < 40) {
			slideTo.y = 40;
		} else if (slideTo.y > 280) {
			slideTo.y = 280;
		}
		
		[self slideTo: &slideTo final:true];
		
		slideTime = time +fmod((float)arc4random(), 100.0f) * maxSlideDelay / 100.0f;		
	}

}

@end
