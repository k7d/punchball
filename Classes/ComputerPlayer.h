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

#import "Player.h"

@interface ComputerPlayer : Player {
	Player *otherPlayer;	
	
	float maxSlideDelay; // max delay between slides in seconds
	float maxPunchDelay; // max delay between punches in seconds
	float maxSweep;
	
	int slideMax; 
	int hitPrecision; // closer to 0 is better
	
	float turnTime;
	float punchTime;
	float slideTime;
	
	bool firstCycle;
}


-(id) initWithPos:(cpVect)pos 
			 left:(bool)left
			color:(int)_color
			 game:(Game*)game 
		   headSM:(AtlasSpriteManager*)_headSM 
		  gloveSM:(AtlasSpriteManager*)_gloveSM 
		 springSM:(AtlasSpriteManager*)_springSM
		  bonusSM:(AtlasSpriteManager*)_bonusSM
   headParticleSM:(AtlasSpriteManager*)_headParticleSM 
			space:(cpSpace*)_space
	  otherPlayer:(Player*)_otherPlayer;


@end
