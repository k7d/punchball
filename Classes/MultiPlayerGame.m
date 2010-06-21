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

#import "MultiPlayerGame.h"

@implementation MultiPlayerGame

@synthesize link;



-(id) initWithDelegate: (id<GameDelegate>)_delegate link:(Link*)_link left:(bool)left
{
	[super initWithDelegate:_delegate];
	
	rightPlayer = [[[Player alloc] initWithPos:cpv(360, 160)  
										  left:false
										 color:1 
										  game:self 
										headSM:headSM 
									   gloveSM:gloveSM 
									  springSM:springSM
									   bonusSM:bonusSM					
								headParticleSM:headParticleSM 
										 space:space] autorelease];
	
	[gameObjects addObject:rightPlayer];

	self.link = _link;
	
	link.dataReceiver = self;

	if (left) {
		localPlayer = leftPlayer;
		remotePlayer = rightPlayer;
		[leftLabel setString:@"You"];
		[rightLabel setString:link.peerName];
	} else {
		localPlayer = rightPlayer;
		remotePlayer = leftPlayer;
		[rightLabel setString:@"You"];
		[leftLabel setString:link.peerName];
	}
	
	opponentName = [link.peerName copy];

	localPlayer.isLocal = true;
	localPlayer.calcHits = false;
	
	[self updateScores];		
	
	nextSlideTime = 0;

	return self;
}




- (void)dealloc
{
	if (pausePopup) {
		[pausePopup	dismissWithClickedButtonIndex:-1 animated:NO];
	}
	
	self.link = nil;
	[super dealloc];
}



- (void)layerReplaced
{
	[super layerReplaced];
	if (localPlayer == leftPlayer) {
		// fire up syncing
		[self syncState];
	}
}



- (void)receivePacket:(int)packetID objectIndex:(int)objectIndex data:(void*)data {
	switch (packetID) {
		case NETWORK_UPDATE_DIR: {
			break;
		}
		case NETWORK_PUNCH: {
			CGPoint *aim = (CGPoint*)data;
			[remotePlayer punch:*aim];
			break;
		}
		case NETWORK_TURN: {
			CGPoint *aim = (CGPoint*)data;
			[remotePlayer turn:*aim];
			break;
		}
		case NETWORK_POS: {
			PlayerInfo *pi = (PlayerInfo*)data;
			[remotePlayer correctPos:pi];
			localPlayer.health = pi->opponentHealth;
			[self updateScores];

			[NSTimer scheduledTimerWithTimeInterval:NETWORK_SYNC_DELAY target:self selector:@selector(syncState) userInfo:nil repeats:NO];
			break;
		}
			
		case NETWORK_SLIDE: {
			SlideInfo *slideInfo = (SlideInfo*)data;
			[remotePlayer slideTo: &slideInfo->slideTo final:slideInfo->finalSlide];
			break;
		}
			
		case NETWORK_PAUSE: {
			[super pause];
			break;
		}
			
		case NETWORK_RESUME: {
			NSLog(@"NETWORK_RESUME received");
			
			if (pausePopup) {
				[pausePopup dismissWithClickedButtonIndex:0 animated:YES];
			}
			
			[super resume];
			
			break;
		}
			
		default: {
			NSLog(@" >>> receivePacket: invalid packeID %d", packetID);
			break;
		}
	}
}



-(void) syncState {
	static PlayerInfo playerInfo;
	playerInfo.headP = localPlayer.headBody->p;
	playerInfo.gloveV = localPlayer.gloveBody->v;
	playerInfo.headV = localPlayer.headBody->v;
	playerInfo.headA = localPlayer.headBody->a;
	
	playerInfo.opponentHealth = remotePlayer.health;
	[link sendPacket:NETWORK_POS objectIndex:0 data:&playerInfo length:sizeof(playerInfo) reliable:YES];
}




-(void)touchBegan:(CGPoint)pos {
	if (pos.x >= localPlayer.headBody->p.x - SLIDE_TOUCH_APROX &&
		pos.x <= localPlayer.headBody->p.x + SLIDE_TOUCH_APROX &&
		pos.y >= localPlayer.headBody->p.y - SLIDE_TOUCH_APROX &&
		pos.y <= localPlayer.headBody->p.y + SLIDE_TOUCH_APROX) {
		isSliding = true;

		[localPlayer slideTo:&pos final:false];
		
		static SlideInfo slideInfo;
		slideInfo.slideTo = pos;
		slideInfo.finalSlide = false;
		[link sendPacket:NETWORK_SLIDE objectIndex:0 data:&slideInfo length:sizeof(slideInfo) reliable:YES];
		nextSlideTime = localPlayer.time + NETWORK_SLIDE_INTERVAL;
		
	} else {
		isSliding = false;
		if ([localPlayer turn:pos]) {
			[link sendPacket:NETWORK_TURN objectIndex:0 data:&pos length:sizeof(pos) reliable:YES];
		}
	}	
}


-(void)touchMove:(CGPoint)pos final:(bool)final {
	if (isSliding) {
		[localPlayer slideTo:&pos final: final];
		if (localPlayer.time > nextSlideTime || final) {
			static SlideInfo slideInfo;
			slideInfo.slideTo = pos;
			slideInfo.finalSlide = final;
			[link sendPacket:NETWORK_SLIDE objectIndex:0 data:&slideInfo length:sizeof(slideInfo) reliable:YES];
			nextSlideTime = localPlayer.time + NETWORK_SLIDE_INTERVAL;
		}
	} else {
		if (final) {
			if ([localPlayer punch:pos]) {
				[link sendPacket:NETWORK_PUNCH objectIndex:0 data:&pos length:sizeof(pos) reliable:YES];
			}
		} else {
			if ([localPlayer turn:pos] && localPlayer.time > nextSlideTime) {
				[link sendPacket:NETWORK_TURN objectIndex:0 data:&pos length:sizeof(pos) reliable:YES];
				nextSlideTime = localPlayer.time + NETWORK_SLIDE_INTERVAL;
			}
		}
	}
}



-(void) pause {
	[link sendPacket:NETWORK_PAUSE objectIndex:0 data:nil length:0 reliable:YES];
	[super pause];
}



-(void) resume {
	[link sendPacket:NETWORK_RESUME objectIndex:0 data:nil length:0 reliable:YES];
	[super resume];
}



-(void) menu {
	[link sendPacket:NETWORK_RESUME objectIndex:0 data:nil length:0 reliable:YES];
	[link invalidateSession];
	[super menu];
}


@end
