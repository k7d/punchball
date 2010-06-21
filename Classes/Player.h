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

#import "GameObject.h"
#import "PunchAction.h"
#import "RotateAction.h"
#import "HitEffect.h"
#import "PASoundSource.h"
#import "HeadParticle.h"
#import "Config.h"

typedef struct {
	cpVect headP;
	cpVect headV;
	float headA;
	cpVect gloveV;
	float opponentHealth;
} PlayerInfo;



@class Game;

@interface Player : GameObject {
	AtlasSpriteManager *headSM;
	AtlasSprite *headSprite;
	AtlasSprite *eyesSprite;
	AtlasSpriteManager *gloveSM;
	AtlasSprite *gloveSprite;
	AtlasSpriteManager *springSM;
	AtlasSpriteManager *bonusSM;
	AtlasSprite *springSprite;
	
	float hits;
	float health;
	int score;
	int hitStreak;
	
	cpSpace	*space;
	
	cpBody	*headBody;
	cpShape* headShape;
	
	cpBody	*gloveBody;
	cpShape* gloveShape;
	
	GameObjectWrapper *gloveWrapper;
	float gloveAngle;
	
	cpJoint *headGloveJoint1;
	cpJoint *headGloveJoint2;
	cpJoint *headGloveJoint3;		
	cpJoint *headGlovePunchJoint;		
	
	RotateAction *rotateAction;
	PunchAction *punchAction;	
	
	float time;
	
	float hitImpactTime;
	float punchImpactTime;
	float hitEffectTime;
	float updateAnimTime;
	
	HitEffect *hitEffect;

    PASoundSource *punchSound;
    PASoundSource *hitSound;
	
	NSArray *headParticles;
	
	bool isLocal;
	bool calcHits;
	int state;
	int animIndex;
	
	bool isSliding;
	bool isFinalSlide;
	cpVect slideTarget;
	
	bool holdAngle;
	bool holdPosition;
	bool correctPosition;
	
	int color;
	
	int slideSpeed;
	
	bool headWasHit;
	cpVect headVBeforeHit;
	bool gloveWasHit;
	cpVect gloveVBeforeHit;
	
	float turnStart;
}



@property (readonly) AtlasSprite	*gloveSprite;

@property (readwrite) float health;
@property (readwrite) int score;
@property (readwrite) bool isLocal;
@property (readwrite) bool calcHits;
@property (readwrite) bool isSliding;

@property (readonly) cpBody	*headBody;
@property (readonly) cpBody	*gloveBody;
@property (readwrite) float gloveAngle;

@property (readonly) cpJoint *headGloveJoint1;
@property (readonly) cpJoint *headGloveJoint2;
@property (readonly) cpJoint *headGloveJoint3;		

@property (readonly) PunchAction *punchAction;

@property (readonly) PASoundSource *punchSound;
@property (readonly) PASoundSource *hitSound;

@property (readonly) int color;

@property (readonly) int state;

@property (readonly) float time;

-(id) initWithPos:(cpVect)pos 
			 left:(bool)left
			color:(int)_color 
			 game:(Game*)game 
		   headSM:(AtlasSpriteManager*)_headSM 
		  gloveSM:(AtlasSpriteManager*)_gloveSM 
		 springSM:(AtlasSpriteManager*)_springSM 
		 bonusSM:(AtlasSpriteManager*)_bonusSM 
   headParticleSM:(AtlasSpriteManager*)_headParticleSM 
			space:(cpSpace*)_space;

-(void) slideTo:(cpVect*)pos final:(bool)final;

-(bool) turn:(CGPoint)aim;

-(bool) punch:(CGPoint)aim;

-(float)calcHitForce:(cpBody*)from to:(cpBody*)to power:(float)power;

-(void)calcPunchImpact:(float)force;

-(void) hitHead: (Player*)byPlayer contact:(cpContact*)contact;
-(void) hitGlove: (Player*)byPlayer contact:(cpContact*)contact;

-(void) updateState;

-(void) calcHeadVelocity:(ccTime) delta damping:(float)damping;
-(void) calcGloveVelocity:(ccTime) delta damping:(float)damping;

-(bool)isHit;

-(void)correctPos:(PlayerInfo*)playerInfo;

-(int)getTotalScore;

- (float) getPower;

@end
