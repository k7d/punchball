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

#import "PASoundMgr.h"
#import "Common.h"
#import "HeadGloveJoint.h"
#import "BonusAction.h"

void headUpdateVelocity(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt) {
	Player* player = body->data;
	[player calcHeadVelocity:dt damping:damping];
}



void gloveUpdateVelocity(cpBody *body, cpVect gravity, cpFloat damping, cpFloat dt) {
	Player* player = body->data;
	[player calcGloveVelocity:dt damping:damping];
}




@implementation Player

@synthesize gloveSprite, health, score, isLocal, color, isSliding, state;
@synthesize gloveBody, gloveAngle, headBody, headGloveJoint1, headGloveJoint2, headGloveJoint3, punchAction;
@synthesize punchSound, hitSound, calcHits, time;


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
{
	[super init];
	
	color = _color;
	
	hits = 0;
	health = MAX_HEALTH;
	score = 0;
	hitStreak = 1;
	state = 0;	
	animIndex = 0;
	isLocal = false;
	calcHits = true;
	isSliding = false;
	holdPosition = true;
	holdAngle = false;
	correctPosition = false;
	
	time = 0;
	punchImpactTime = 0;
	hitImpactTime = 0;
	hitEffectTime = 0;
	
	bonusSM = _bonusSM;
	
	headSM = _headSM;
	headSprite = [AtlasSprite spriteWithRect:CGRectMake(0, 0, 60, 60) spriteManager:_headSM];
	[_headSM addChild: headSprite];	
	headSprite.position = pos;

	eyesSprite = [AtlasSprite spriteWithRect:CGRectMake(0, 180, 60, 60) spriteManager:_headSM];
	[_headSM addChild: eyesSprite];	
	eyesSprite.position = pos;	
	
	gloveSM = _gloveSM;
	gloveSprite = [AtlasSprite spriteWithRect:CGRectMake(0, 0 + color * 40, 40, 40) spriteManager:_gloveSM];
	[_gloveSM addChild: gloveSprite];	
	if (left) {
		gloveSprite.position = ccp(pos.x + GLOVE_DIST_MIN, pos.y);
	} else {
		gloveSprite.position = ccp(pos.x - GLOVE_DIST_MIN, pos.y);
		gloveSprite.rotation = 180;
	}
	
	springSM = _springSM;
	springSprite = [AtlasSprite spriteWithRect:CGRectMake(0, 0, 216, 21) spriteManager:_springSM];
	springSprite.anchorPoint = cpv(0, 0.5);
	[_springSM addChild: springSprite];
	springSprite.position = ccp(pos.x, pos.y);
	if (!left) {
		springSprite.rotation = 180;
	}
	
	space = _space;
	
	headBody = cpBodyNew(10.0f, cpMomentForCircle(10.0f, 30, 0, CGPointZero));
	headBody->data = self;
	headBody->velocity_func = &headUpdateVelocity;	
	headBody->p = pos;
	if (!left) {
		cpBodySetAngle(headBody, 3.0f);
	}
	cpSpaceAddBody(space, headBody);
	
	headShape = cpCircleShapeNew(headBody, 30, CGPointZero);
	headShape->collision_type = COLLISION_TYPE_HEAD;
	headShape->e = 0.7f; 
	headShape->u = 0.0f;
	headShape->data = self;
	cpSpaceAddShape(space, headShape);
	
	gloveBody = cpBodyNew(10.0f, cpMomentForCircle(10.0f, 20, 0, CGPointZero));
	gloveBody->data = self;
	gloveBody->velocity_func = &gloveUpdateVelocity;
	if (left) {
		gloveBody->p = ccp(pos.x + GLOVE_DIST_MIN, pos.y);
		gloveAngle = 0;
	} else {
		gloveBody->p = ccp(pos.x - GLOVE_DIST_MIN, pos.y);
		gloveAngle = 3.0f;
		cpBodySetAngle(gloveBody, 3.0f);
	}
	cpSpaceAddBody(space, gloveBody);
	
	headGloveJoint1 = cpPinJointNew(headBody, gloveBody, cpv(0, 30), cpv(0, 20));
	cpSpaceAddJoint(space, headGloveJoint1);
	
	headGloveJoint2 = cpPinJointNew(headBody, gloveBody, cpv(0, -30), cpv(0, -20));
	cpSpaceAddJoint(space, headGloveJoint2);
	
	headGloveJoint3 = cpPinJointNew(headBody, gloveBody, cpv(30, 0), cpv(-20, 0));
	cpSpaceAddJoint(space, headGloveJoint3);

	gloveWrapper = [[GameObjectWrapper alloc] initWithTarget:self];
	
	gloveShape = cpCircleShapeNew(gloveBody, 20, cpv(0, 0));
	gloveShape->collision_type = COLLISION_TYPE_GLOVE;
	gloveShape->e = 0.7; 
	gloveShape->u = 0.0;
	gloveShape->data = gloveWrapper;
	cpSpaceAddShape(space, gloveShape);
	
	punchAction = [[PunchAction alloc] initWithPlayer:self space:space];
	rotateAction = [[RotateAction alloc] initWithPlayer:self];
	
	hitEffect = [[[HitEffect alloc] initWithPlayerColor:color] autorelease];
	[game addChild: hitEffect z:2];
	hitEffect.texture = [[TextureMgr sharedTextureMgr] addImage: @"flake.png"];

	punchSound = [[PASoundSource alloc] initWithFile:@"punch" looped:NO];
	if (isLocal) {
		[punchSound setGain:0.1];
	} else {
		[punchSound setGain:0.05];
	}
	hitSound = [[PASoundSource alloc] initWithFile:@"hit" looped:NO];
	
	headParticles = [[NSArray alloc] initWithObjects:
					 [HeadParticle particleWithSpace:space manager:_headParticleSM index:0],
					 [HeadParticle particleWithSpace:space manager:_headParticleSM index:1],
					 [HeadParticle particleWithSpace:space manager:_headParticleSM index:2],
					 [HeadParticle particleWithSpace:space manager:_headParticleSM index:3],
					 [HeadParticle particleWithSpace:space manager:_headParticleSM index:4],
					 [HeadParticle particleWithSpace:space manager:_headParticleSM index:5],
					 [HeadParticle particleWithSpace:space manager:_headParticleSM index:6],
					 [HeadParticle particleWithSpace:space manager:_headParticleSM index:7],
					 [HeadParticle particleWithSpace:space manager:_headParticleSM index:8],
					 nil];
		
	slideSpeed = DEFAULT_SLIDE_SPEED;
	
	headWasHit = false;
	gloveWasHit = false;
	
	turnStart = -1;
	
	return self;
}



- (void) dealloc
{	
	[headParticles release];
	
	[hitSound stop];
	[hitSound release];
	
	[punchSound stop];
	[punchSound release];

	[rotateAction release];
	[punchAction release];

	// GLOVE
	
	cpSpaceRemoveShape(space, gloveShape);
	cpShapeFree(gloveShape);
	
	[gloveWrapper release];
	
	cpSpaceRemoveJoint(space, headGloveJoint1);
	cpJointFree(headGloveJoint1);
	
	cpSpaceRemoveJoint(space, headGloveJoint1);
	cpJointFree(headGloveJoint2);
	
	cpSpaceRemoveJoint(space, headGloveJoint1);
	cpJointFree(headGloveJoint3);

	cpSpaceRemoveBody(space, gloveBody);
	cpBodyFree(gloveBody);
	
	// HEAD
	
	cpSpaceRemoveShape(space, headShape);
	cpShapeFree(headShape);

	cpSpaceRemoveBody(space, headBody);
	cpBodyFree(headBody);
	
	[springSM removeChild:springSprite cleanup:YES];
	
	[gloveSM removeChild:gloveSprite cleanup:YES];
	
	[headSM removeChild:eyesSprite cleanup:YES];	
	[headSM removeChild:headSprite cleanup:YES];	
	
	[super dealloc];
}



- (void)updatePosition {
	eyesSprite.position = headBody->p;	
	
	if (state < 14) {
		headSprite.position = headBody->p;	
	}
	
	gloveSprite.position = gloveBody->p;	

	if (state < 11) {
		float ad = CC_RADIANS_TO_DEGREES( -cpvtoangle(cpvsub(gloveBody->p, headBody->p)));
		gloveSprite.rotation = ad;	
		
		float gloveDist = cpvlength(cpvsub(gloveBody->p, headBody->p));
		int si = (gloveDist - 40) / 10;
		if (si < 0) si = 0;
		else if (si > 18) si = 18;
		
		springSprite.textureRect = CGRectMake(0, si * 21, 216, 21);
		springSprite.position =  headBody->p;
		springSprite.rotation = ad;
		
		hitEffect.position = headBody->p;
	}
}



-(bool) turn:(CGPoint)aim {
	if (state < 11) {
		self.gloveAngle = normAngle(cpvtoangle(cpvsub(aim, headBody->p)));	

		holdAngle = true;
		
		if (turnStart < 0) {
			turnStart = time;
		}
		
		return true;
		
	} else {
		return false;
	}	
}



- (float) getPower {
	float power = ((time - turnStart) + PUNCH_POWER_BASE) * PUNCH_POWER_COEF;
	if (power > 1.0f) {
		power = 1.0f;
	}
	return power;
}



-(bool) punch:(CGPoint)aim
{
	if (state < 11) {
		float power = [self getPower];
		
		if ([rotateAction isRunning]) {
			[gloveSprite stopAction:rotateAction];
			[rotateAction stop];
		}
		
		if (![punchAction isDone]) {
			[gloveSprite stopAction:punchAction];
			[punchAction stop];
		}		
	
		[punchSound stop];						
		[punchSound playAtListenerPosition];		
		
		punchAction.dir = cpvsub(aim, headBody->p);		
		punchAction.power = power;
		[rotateAction setAngle: cpvtoangle(punchAction.dir)];
		[gloveSprite runAction: rotateAction];
		
		holdAngle = true;
		
		turnStart = -1.0f;
		
		return true;
	} else {
		return false;
	}
}



-(void)setHealth:(float)_health {
	health = _health;
	
	if (health < 0.0f) {
		health = 0.0f;
	}
	
	int newState;
	if (health <= 0.0f) {
		if (state > 10) {
			return;
		}
		
		newState = 11;
	}
	else {
		newState = 10 - (health / MAX_HEALTH * 10.0f);
	}
	
	if (newState != state) {
		state = newState;
		[self updateState];
	}
	
}


-(void)updateState {
	if (state < 11 && hitImpactTime > time) {
		[eyesSprite setTextureRect:CGRectMake(360, 180, 60, 60)]; // hide
		[headSprite setTextureRect:CGRectMake(900, 0, 60, 60)];
		
	} else if (state < 14) {
		if (state == 11) {
			cpSpaceRemoveJoint(space, headGloveJoint1);
			cpSpaceRemoveJoint(space, headGloveJoint2);
			cpSpaceRemoveJoint(space, headGloveJoint3);
			[eyesSprite setTextureRect:CGRectMake(360, 180, 60, 60)]; // hide
			[springSM removeChild:springSprite cleanup:YES];			
		}
		
		[headSprite setTextureRect:CGRectMake(state * 60, 0, 60, 60)];
	}
	
	animIndex = 0;
}



-(void)updateAnim {
	animIndex++;
	animIndex = animIndex % 3;
	
	updateAnimTime = time + 0.1f;
	
	if (state < 11 && hitImpactTime > time) {	
		[eyesSprite setTextureRect:CGRectMake(360, 180, 60, 60)]; // hide
		[headSprite setTextureRect:CGRectMake(900, animIndex * 60, 60, 60)];
	} else {
		if (state < 14) {
			[headSprite setTextureRect:CGRectMake(state * 60, animIndex * 60, 60, 60)];
			
			if (state < 11) {
				if (turnStart < 0) {
					[eyesSprite setTextureRect:CGRectMake(0, 180, 60, 60)];
				} else {
					int i = [self getPower] * 5;
					[eyesSprite setTextureRect:CGRectMake(i * 60, 180, 60, 60)]; 
				}
			}
		}
	}
}



-(void) slideTo:(cpVect*)pos final:(bool)final {
	
	cpVect sv = cpvsub(*pos, headBody->p);

	slideTarget = *pos;
	
	if (fabs(sv.x) < SLIDE_TARGET_APROX && fabs(sv.y) < SLIDE_TARGET_APROX) {
		// do not slide
		headBody->v = cpvzero;		
		headBody->p = *pos;
		isSliding = false;
		
	} else {
		isSliding = true;
	}

	isFinalSlide = final;
}



-(float)calcHitForce:(cpBody*)from to:(cpBody*)to power:(float)power {
	float fromToA = halfAngle(cpvtoangle(cpvsub(to->p, from->p)));
	float fromA = halfAngle(cpvtoangle(from->v));
	float deltaA = fabs(fromA - fromToA);		
	if (deltaA > H_PI) {
		deltaA = M_PI - deltaA;
	}		
	
	float force = (H_PI - deltaA) / H_PI * (power / 2 + 0.5);	
	
	return force;
}


-(void)calcPunchImpact:(float)force {
	float newImpactTime = time + force * MAX_PUNCH_IMPACT_TIME;
	if (newImpactTime > punchImpactTime) {
		punchImpactTime = newImpactTime;
	} 	
}


-(void) hitHead: (Player*)byPlayer contact:(cpContact*)contact
{
	if (!byPlayer.punchAction.isDone && !byPlayer.punchAction.isHit) {
		float force = [self calcHitForce:byPlayer->gloveBody to:headBody power:byPlayer.punchAction.power];
		byPlayer.punchAction.isHit = true;
		
		if (state > 10 && byPlayer.isLocal) {
			if (state == 11) {
				byPlayer.score += 10;
				[bonusSM runAction: [BonusAction actionWithType:20 pos:headBody->p sm:bonusSM]];
			} else if (state == 12) {
				byPlayer.score += 15;
				[bonusSM runAction: [BonusAction actionWithType:21 pos:headBody->p sm:bonusSM]];
			} else if (state == 13) {
				byPlayer.score += 20;
				[bonusSM runAction: [BonusAction actionWithType:22 pos:headBody->p sm:bonusSM]];
			}
		}
		
		
		if (state < 11) {
			
			if (byPlayer.isLocal) {
				int points;
				if (force >= PERFECT_HIT_THRESHOLD) {
					points = PERFECT_HIT_SCORE;
					[bonusSM runAction: [BonusAction actionWithType:10 pos:headBody->p sm:bonusSM]];
					
				} else {
					points = (force * HIT_SCORE);			
					if (points < 1) {
						points = 1;
					}
					[bonusSM runAction: [BonusAction actionWithType:points pos:headBody->p sm:bonusSM]];				
				}
				
				if (hitImpactTime >= time) {
					hitStreak++;
					if (hitStreak > 3) {
						hitStreak = 3;
					}
					if (hitStreak == 2) {
						points += STREAK_2_SCORE;
					} else if (hitStreak == 3) {
						points += STREAK_3_SCORE;
					}
					[bonusSM runAction: [BonusAction actionWithType: 9 + hitStreak pos:headBody->p sm:bonusSM]];				
				} else {
					hitStreak = 1;
				}
			
				byPlayer.score += points;
			}
			
			if (self.isLocal) {
				int points = -(force * HIT_SCORE);			
				if (points > -1) {
					points = -1;
				} else if (points < -10) {
					points = -10;
				}
				
				[bonusSM runAction: [BonusAction actionWithType:points pos:headBody->p sm:bonusSM]];
			}
			
			// PUNCH IMPACT
			[self calcPunchImpact:force];
			
			// HIT IMPACT		
			float newImpactTime = time + force * MAX_HIT_IMPACT_TIME;
			if (newImpactTime > hitImpactTime) {
				hitImpactTime = newImpactTime;
			} 	
						
			// HIT EFFECT
			hitEffectTime = time + HIT_EFFECT_TIME;
			hitEffect.speed = force * MAX_HIT_EFFECT_SPEED + 50.0f;
			[hitEffect activate];					
			
			if (calcHits) {
				self.health -= force;
			}
			
			holdAngle = false;
			
		} else if (state == 13) {
			cpVect p = headBody->p;
			headBody->p = cpv(-10000, -10000);
			[headSM removeChild:headSprite cleanup:YES];
			for (HeadParticle *headParticle in headParticles) {
				[headParticle activate:p v:cpvzero];
			}
			
			state = 14;
			
		} else if (state > 10) {
			state++;
		}
				
		[byPlayer.punchSound stop];						
		[byPlayer.hitSound stop];								
		[hitSound setGain: force];				
		[hitSound playAtListenerPosition];		
		
		[self updateState];		
	}
}





-(void) hitGlove: (Player*)byPlayer contact:(cpContact*)contact
{
	if (!byPlayer.punchAction.isDone) {
		float force = [self calcHitForce:byPlayer->gloveBody to:gloveBody power:byPlayer.punchAction.power];
		
		// PUNCH IMPACT
		[self calcPunchImpact:force];
		
		[byPlayer.punchSound stop];						
		[byPlayer.hitSound stop];								
		[hitSound setGain: force];				
		[hitSound playAtListenerPosition];				
	}
}



-(void) calcGloveVelocity:(ccTime)delta damping: (float)damping {
	if (state < 11) {		
		// update velocity without damping
		gloveBody->v = cpvadd(gloveBody->v, cpvmult(cpvmult(gloveBody->f, gloveBody->m_inv), delta));
		gloveBody->w = 0; 
		
		// align glove direction with head
		gloveBody->a = headBody->a;

	} else {
		// glove is detached - let it float freely
		gloveBody->v = cpvadd(cpvmult(gloveBody->v, damping), cpvmult(cpvmult(gloveBody->f,gloveBody->m_inv), delta));
		gloveBody->w = gloveBody->w + gloveBody->t * gloveBody->i_inv * delta;		
	}
}



-(void) calcHeadVelocity:(ccTime)delta damping: (float)damping {
	if (state < 11) {
		
		if (isSliding && (holdPosition || (!holdPosition && !self.isHit) ) ) { // !self.isHit && 
			cpVect sv = cpvsub(slideTarget, headBody->p);
			
			if (fabs(sv.x) < SLIDE_TARGET_APROX && fabs(sv.y) < SLIDE_TARGET_APROX) {
				// we have reached target - stop sliding
				//isSliding = false;
				
				if (!isFinalSlide) {
					headBody->v = cpvzero;
					headBody->p = slideTarget;
				} else {					
					isSliding = false;
				}
				
			} else {				
				headBody->v = cpvmult(cpvnormalize(sv), slideSpeed);
			}
			
			holdAngle = true;			
			
		} else {
			// float freely
			headBody->v = cpvadd(cpvmult(headBody->v, damping), cpvmult(cpvmult(headBody->f, headBody->m_inv), delta));
		}
		
		// adjust angle
		if (holdAngle || correctPosition) {
			float angleDelta = normAngle(gloveAngle - normAngle(headBody->a));
			
			if (angleDelta > M_PI) {
				angleDelta = - D_PI + angleDelta;
			}		
			
			if (fabsf(angleDelta) < ROTATE_APROX) {
				headBody->w = angleDelta;
			} else if (angleDelta > 0) {
				headBody->w = ROTATE_SPEED;
			} else {
				headBody->w = -ROTATE_SPEED;
			}
			
		} else {
						
			headBody->w = headBody->w*damping + headBody->t * headBody->i_inv * delta;			
			gloveAngle = headBody->a;
		}
		
	} else {
		// FAIL - float freely
		headBody->v = cpvadd(cpvmult(headBody->v, damping), cpvmult(cpvmult(headBody->f, headBody->m_inv), delta));
		headBody->w = headBody->w*damping + headBody->t * headBody->i_inv * delta;			
	}	
}



-(void) step: (ccTime) delta {
	time += delta;
		
	if (updateAnimTime <= time) {
		[self updateAnim];
	}	
	
	if (hitEffectTime <= time && hitEffect.active) {
		[hitEffect stopSystem];
		[self updateState];
	} 
}



-(bool)isHit {
	return punchImpactTime > time;
}



-(void)correctPos:(PlayerInfo*)pi {
	cpVect headPD = cpvsub(pi->headP, headBody->p);
	
	if (fabs(headPD.x) >= SLIDE_TARGET_APROX || fabs(headPD.y) >= SLIDE_TARGET_APROX) {
		cpVect headPC = cpvmult(headPD, 1/NETWORK_SYNC_CORRECTION_INTERVAL);
		headBody->v = cpvadd(pi->headV, headPC);
		
		gloveBody->v = cpvadd(pi->gloveV, headPC);
	} else {
		headBody->v = pi->headV;
	}	
	
	correctPosition = true;
	gloveAngle = pi->headA;	
}



-(int)getTotalScore {
	return health * HIT_SCORE + score;
}

@end


