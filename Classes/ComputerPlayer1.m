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

#import "ComputerPlayer1.h"


@implementation ComputerPlayer1

-(id) initWithPos:(cpVect)pos 
			 left:(bool)left
			 game:(Game*)_game 
		   headSM:(AtlasSpriteManager*)_headSM 
		  gloveSM:(AtlasSpriteManager*)_gloveSM 
		 springSM:(AtlasSpriteManager*)_springSM 
		  bonusSM:(AtlasSpriteManager*)_bonusSM 
   headParticleSM:(AtlasSpriteManager*)_headParticleSM 
			space:(cpSpace*)_space
	  otherPlayer:(Player*)_otherPlayer{
	[super initWithPos:pos 
				  left:left 
				 color:1
				  game:_game
				headSM:_headSM 
			   gloveSM:_gloveSM 
			  springSM:_springSM
			   bonusSM:_bonusSM
		headParticleSM:_headParticleSM 
				 space:_space
		   otherPlayer:_otherPlayer];

	maxSlideDelay = 3.5f;
	maxPunchDelay = 1.5f;
	slideMax = 10;
	slideSpeed = 150;
	hitPrecision = 100;

	return self;
}

@end
