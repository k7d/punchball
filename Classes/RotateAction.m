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

#import "RotateAction.h"

#import "Player.h"
#import "Common.h"

@implementation RotateAction

@synthesize isRunning;

-(id) initWithPlayer: (Player*)_player
{
	player = _player;
	isRunning = false;
	return [super initWithDuration:0];
}



-(void)setAngle: (float) _angle {
	player.gloveAngle = normAngle(_angle);	
	
	float angleDelta = normAngle(player.gloveAngle - normAngle(player.headBody->a));
	if (angleDelta > M_PI) {
		angleDelta = D_PI - angleDelta;
	}		

	duration = angleDelta / ROTATE_SPEED; // how long will rotation take in seconds
}



-(void) start
{
	isRunning = true;
	
	[super start];
}



-(void) stop
{	
	[super stop];
	
	isRunning = false;
	
	[player.gloveSprite runAction:player.punchAction];
}


-(void) update: (ccTime) t
{	
}

@end
