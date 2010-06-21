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

#import "Game.h"


static void eachShape(void *ptr, void* unused)
{
	cpShape *shape = (cpShape*) ptr;
	GameObject* gameObject = shape->data;
	if (gameObject) {
		[gameObject updatePosition];
	}
}



static int
gloveHeadCollision(cpShape *a, cpShape *b, cpContact *contacts, int numContacts, cpFloat normal_coef, void *data)
{
	GameObjectWrapper *glovePlayerWrapper = a->data;
	Player *glovePlayer = (Player*)glovePlayerWrapper.target;
	Player *headPlayer = b->data;
	Game *game = data;
	
	if (glovePlayer != headPlayer) {
		[headPlayer hitHead:glovePlayer contact:contacts];
		[game updateScores];
		return 1;
	} else {
		return 0;
	}
}



static int
gloveGloveCollision(cpShape *a, cpShape *b, cpContact *contacts, int numContacts, cpFloat normal_coef, void *data)
{
	GameObjectWrapper *w1 = a->data;
	Player *p1 = (Player*)w1.target;
	GameObjectWrapper *w2 = b->data;
	Player *p2 = (Player*)w2.target;
	
	if (!p1.punchAction.isDone) {
		[p2 hitGlove:p1 contact: contacts];
	}

	if (!p2.punchAction.isDone) {
		[p1 hitGlove:p2 contact: contacts];
	}
	
	return 1;
}



void drawCollisions(void *ptr, void *data)
{
	cpArbiter *arb = (cpArbiter *)ptr;
	for(int i=0; i<arb->numContacts; i++){
		cpVect v = arb->contacts[i].p;
		drawPoint( ccp(v.x, v.y) );
	}
}



@implementation Game



@synthesize gameObjects, rightPlayer, showHint;



-(id) initWithDelegate: (id)_delegate
{
	[super init];
	
	gameInProgress = true;
	isSliding = false;
	
	delegate = _delegate;
	
	isTouchEnabled = YES;
	isAccelerometerEnabled = YES;
	
	leftLabel = [Label labelWithString:@"" fontName:@"Courier" fontSize:22];
	leftLabel.position = cpv(30, 10);
	leftLabel.anchorPoint = cpv(0.0, 0.0);
	[leftLabel setColor: ccc3(229, 229, 229)];
	[self addChild:leftLabel z:1];
	
	rightLabel = [Label labelWithString:@"" fontName:@"Courier" fontSize:22];
	rightLabel.position = cpv(450, 10);
	rightLabel.anchorPoint = cpv(1.0, 0.0);
	[rightLabel setColor: ccc3(229, 229, 229)];
	[self addChild:rightLabel z:1];
	
	CGSize wins = [[Director sharedDirector] winSize];
	
	cpInitChipmunk();
	
	cpBody *staticBody = cpBodyNew(INFINITY, INFINITY);
	space = cpSpaceNew();
	space->damping = DAMPING;
	cpSpaceResizeStaticHash(space, 400.0f, 40);
	cpSpaceResizeActiveHash(space, 100, 600);
	
	space->gravity = ccp(0, 0);
	space->elasticIterations = space->iterations;
	
	cpShape *shape;
	
	// bottom
	shape = cpSegmentShapeNew(staticBody, ccp(-BORDER_WITDH + INNER_BORDER,-BORDER_WITDH + INNER_BORDER), ccp(wins.width + BORDER_WITDH - INNER_BORDER * 2, -BORDER_WITDH + INNER_BORDER), BORDER_WITDH);
	shape->e = 1.0; shape->u = 0.0; shape->collision_type = COLLISION_TYPE_BORDER;
	cpSpaceAddStaticShape(space, shape);
	
	// top
	shape = cpSegmentShapeNew(staticBody, ccp(-BORDER_WITDH + INNER_BORDER,wins.height + BORDER_WITDH - INNER_BORDER * 2), ccp(wins.width + BORDER_WITDH - INNER_BORDER * 2, wins.height + BORDER_WITDH - INNER_BORDER * 2), BORDER_WITDH);
	shape->e = 1.0; shape->u = 0.0; shape->collision_type = COLLISION_TYPE_BORDER;
	cpSpaceAddStaticShape(space, shape);
	
	// left
	shape = cpSegmentShapeNew(staticBody, ccp(-BORDER_WITDH + INNER_BORDER,-BORDER_WITDH + INNER_BORDER), ccp(-BORDER_WITDH + INNER_BORDER,wins.height + BORDER_WITDH - INNER_BORDER * 2), BORDER_WITDH);
	shape->e = 1.0; shape->u = 0.0; shape->collision_type = COLLISION_TYPE_BORDER;
	cpSpaceAddStaticShape(space, shape);
	
	// right
	shape = cpSegmentShapeNew(staticBody, ccp(wins.width + BORDER_WITDH - INNER_BORDER * 2, -BORDER_WITDH + INNER_BORDER), ccp(wins.width + BORDER_WITDH - INNER_BORDER * 2,wins.height + BORDER_WITDH - INNER_BORDER * 2), BORDER_WITDH);
	shape->e = 1.0; shape->u = 0.0; shape->collision_type = COLLISION_TYPE_BORDER;
	cpSpaceAddStaticShape(space, shape);

	springSM = [AtlasSpriteManager spriteManagerWithFile:@"spring.png" capacity:10];
	[self addChild:springSM z:4];

	gloveSM = [AtlasSpriteManager spriteManagerWithFile:@"glove.png" capacity:10];
	[self addChild:gloveSM z:5];

	headSM = [AtlasSpriteManager spriteManagerWithFile:@"head.png" capacity:10];
	[self addChild:headSM z:6];
	
	headParticleSM = [AtlasSpriteManager spriteManagerWithFile:@"head_p.png" capacity:10];
	[self addChild:headParticleSM z:7];
	
	scoreSM = [AtlasSpriteManager spriteManagerWithFile:@"energy.png" capacity:10];
	[self addChild:scoreSM z:1];

	bonusSM = [AtlasSpriteManager spriteManagerWithFile:@"bonuses.png" capacity:20];
	[self addChild:bonusSM z:2];
	
	leftScore = [AtlasSprite spriteWithRect:CGRectMake(0, 0, 15, 300) spriteManager:scoreSM];
	leftScore.anchorPoint = cpvzero;
	leftScore.position = cpv(10, 10);
	[scoreSM addChild:leftScore z:1];
	

	rightScore = [AtlasSprite spriteWithRect:CGRectMake(15, 0, 15, 300) spriteManager:scoreSM];
	rightScore.anchorPoint = cpvzero;
	rightScore.position = cpv(455, 10);
	[scoreSM addChild:rightScore z:1];	
	
	scoreLabel = [Label labelWithString:@"0" fontName:@"Courier" fontSize:22];	
	scoreLabel.position = cpv(240, 300);
	[self addChild:scoreLabel z:1];

	cpSpaceAddCollisionPairFunc(space, COLLISION_TYPE_GLOVE, COLLISION_TYPE_HEAD, &gloveHeadCollision, self);
	cpSpaceAddCollisionPairFunc(space, COLLISION_TYPE_GLOVE, COLLISION_TYPE_GLOVE, &gloveGloveCollision, self);
	
	gameObjects = [[NSMutableArray alloc] init];
	
	leftPlayer = [[[Player alloc] initWithPos:cpv(120, 160)  
										 left:true 
										color:0 
										 game:self 
									   headSM:headSM 
									  gloveSM:gloveSM 
									 springSM:springSM 
									  bonusSM:bonusSM
							   headParticleSM:headParticleSM 
										space:space] autorelease];
	
	[gameObjects addObject:leftPlayer];

	gestures = [[Gestures alloc] initWithDelegate:self];

	pausePopup = nil;
	
	showHint = true;
	
	return self;
}



- (void) dealloc
{
	[gestures release];
	[gameObjects release];
	cpSpaceFree(space);
	[super dealloc];
}



- (void)layerReplaced
{
	[self schedule: @selector(step:)];
	if (showHint) {
		[self runAction:[GameHintAction hintWithText:@"Swipe two fingers downwards to pause" layer:self]];
	}
}



-(void) step: (ccTime) delta
{
	cpSpaceStep(space, delta);
	
	cpSpaceHashEach(space->activeShapes, &eachShape, nil);
	cpSpaceHashEach(space->staticShapes, &eachShape, nil);

	[leftPlayer step:delta];
	[rightPlayer step:delta];	
}



-(void) updateScores 
{
	if (gameInProgress) {
		if (leftPlayer.health <= 0.0f || rightPlayer.health <= 0.0f) {
			gameInProgress = false;
			[NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(gameOver) userInfo:nil repeats:NO];
		}
				
		leftScore.textureRect = CGRectMake(leftPlayer.color * 15, 0, 15, (leftPlayer.health / MAX_HEALTH) * 300.0f);
		rightScore.textureRect = CGRectMake(rightPlayer.color * 15, 0, 15, (rightPlayer.health / MAX_HEALTH) * 300.0f);		
	}
	
	[scoreLabel setString: [NSString stringWithFormat:@"%d", [localPlayer getTotalScore]]];
}



- (void)gameOver {
	if (leftPlayer.health <= 0.0f) {
		[delegate gameOver:leftPlayer != localPlayer score:[localPlayer getTotalScore] opponentName:opponentName];
	} else if (rightPlayer.health <= 0.0f) {
		[delegate gameOver:rightPlayer != localPlayer score:[localPlayer getTotalScore] opponentName:opponentName];
	}	
}



- (BOOL)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSSet *allTouches = [event allTouches];
	if ([allTouches count] > 1) {
		[gestures touchesBegan:allTouches];
		return kEventHandled;
	}	
	
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];		
		location = [[Director sharedDirector] convertCoordinate: location];
		[self touchBegan:location];
		break;
	}
	return kEventHandled;
}



- (BOOL)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSSet *allTouches = [event allTouches];
	if ([allTouches count] > 1) {
		[gestures touchesMoved:allTouches];
		return kEventHandled;
	}
	

	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];		
		location = [[Director sharedDirector] convertCoordinate: location];
		[self touchMove:location final:false];
		break;
	}
	
	return kEventHandled;
}



- (BOOL)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSSet *allTouches = [event allTouches];
	if ([allTouches count] > 1) {
		[gestures touchesEnded:allTouches];
		return kEventHandled;
	}
	
	
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];		
		location = [[Director sharedDirector] convertCoordinate: location];

		[self touchMove:location final:true];

		break;
	}
	
	return kEventHandled;
}



-(void)touchBegan:(CGPoint)pos {
	if (pos.x >= localPlayer.headBody->p.x - SLIDE_TOUCH_APROX &&
		pos.x <= localPlayer.headBody->p.x + SLIDE_TOUCH_APROX &&
		pos.y >= localPlayer.headBody->p.y - SLIDE_TOUCH_APROX &&
		pos.y <= localPlayer.headBody->p.y + SLIDE_TOUCH_APROX) {
		isSliding = true;
		[localPlayer slideTo:&pos final:false];
	} else {
		isSliding = false;
		[localPlayer turn:pos];			
	}	
}



-(void)touchMove:(CGPoint)pos final:(bool)final {
	if (isSliding) {
		[localPlayer slideTo:&pos final:final];
	} else {
		if (final) {
			[localPlayer punch:pos];			
		} else {
			[localPlayer turn:pos];			
		}
	}
}



-(void) onGesture: (GestureType)gestureType {
	if (gestureType == TWO_LEFT) {
		[self pause];		
	}
}



-(void) pause {
	[[Director sharedDirector] pause];

	pausePopup = [[[UIAlertView alloc] init] autorelease];
	[pausePopup setDelegate:self];
	[pausePopup setTitle:@"Game paused"];
	[pausePopup addButtonWithTitle:@"Resume"];
	[pausePopup addButtonWithTitle:@"Menu"];
	[pausePopup show];	
}



- (void) alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex
{	
	pausePopup = nil;
	
	if (buttonIndex == 0) {
		[self resume];
	} else {
		[self menu];
	}
}	



-(void) resume {
	[[Director sharedDirector] resume];
}



-(void) menu {
	[[Director sharedDirector] resume];
	[delegate mainMenu];
}

@end




@implementation GameHintAction

+(id) hintWithText:(NSString*)t layer:(Layer*)_layer {	
	return [[[self alloc] initWithText:t layer:_layer] autorelease];
}

-(id) initWithText:(NSString*)text layer:(Layer*)_layer  {
	self = [super initWithDuration:GAME_HINT_TIME];
	
	layer = _layer;
	label = [Label labelWithString:text fontName:@"Courier" fontSize:16];
	label.position = cpv(240, 50);
	[layer addChild:label];
	
	return self;
}



-(void)stop {
	[super stop];
	[layer removeChild:label cleanup:YES];	
}



-(void) update: (ccTime) t
{	
	if (t <= 0.1) {
		[label setOpacity: 255.0f * t * 10.0f];	
	} else if (t > 0.7) {
		[label setOpacity:255 - (255.0f * (t - 0.3f) * 1.43f)];	
	}
}



@end
