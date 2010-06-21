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

#import "PunchAction.h"
#import "Player.h"

@implementation PunchAction

@synthesize dir, isHit, power;

-(id) initWithPlayer:(Player*)_player space:(cpSpace*)_space
{
	[super init];
	
	player = _player;
	space = _space;

	isRetreating = false;
	elapsed = 0;
	duration = 0;

	return self;
}



- (void) reset {
	isRetreating = false;	
	isHit = false;
	elapsed = 0;
	punchTime = MAX_PUNCH_TIME - (MAX_PUNCH_TIME - MIN_PUNCH_TIME) * power;
	duration = punchTime * 2;
}



-(void) start
{
	[self reset];
	
	cpSpaceRemoveJoint(space, player.headGloveJoint1);
	cpSpaceRemoveJoint(space, player.headGloveJoint2);
	cpSpaceRemoveJoint(space, player.headGloveJoint3);
	
	cpBodyResetForces(player.gloveBody);
	cpVect normDir = cpvnormalize(dir);
	cpVect relAim = cpvmult(normDir, GLOVE_DIST_MAX);
	cpVect aim = cpvadd(player.headBody->p, relAim);
	cpBodySlew(player.gloveBody, aim, punchTime);
	
	[super start];
}



-(BOOL) isDone {
	return elapsed >= duration;
}



-(void) stop
{
	[super stop];
	
	elapsed = duration;
	
	cpBodyResetForces(player.headBody);
	cpBodyResetForces(player.gloveBody);
	
	player.gloveBody->v = cpvzero;

	cpSpaceAddJoint(space, player.headGloveJoint1);
	cpSpaceAddJoint(space, player.headGloveJoint2);
	cpSpaceAddJoint(space, player.headGloveJoint3);	
}



-(void) step: (ccTime) dt {
	elapsed += dt;
	if (!isRetreating && elapsed >= punchTime) {
		[self retreat];
	}
}



-(void)retreat
{
	[player updatePosition];
	
	isRetreating = true;		
	
	duration = elapsed * 2;
	
	cpVect returnTo = cpvadd(player.headBody->p, cpvmult(cpvnormalize(cpvsub(player.gloveBody->p, player.headBody->p)), GLOVE_DIST_MIN));
	
	cpBodySlew(player.gloveBody, returnTo, elapsed);
}

@end