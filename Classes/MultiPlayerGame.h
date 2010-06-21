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
#import "Link.h"
#import <GameKit/GameKit.h>




typedef enum {	
	NETWORK_UPDATE_DIR, 
	NETWORK_PUNCH,		
	NETWORK_SLIDE,		
	NETWORK_TURN,		
	NETWORK_POS,
	NETWORK_PAUSE,
	NETWORK_RESUME
} PacketCodes;


typedef struct {
	cpVect slideTo;
	bool finalSlide;
} SlideInfo;


@interface MultiPlayerGame : Game<DataReceiver> {
	Link *link;
	int gamePacketNumber;
	Player *remotePlayer;
	float nextSlideTime;
}

@property (nonatomic, retain) Link *link;

-(id) initWithDelegate: (id<GameDelegate>)_delegate link:(Link*)_link left:(bool)left;

- (void)receivePacket:(int)packetID objectIndex:(int)objectIndex data:(void*)data;

- (void)syncState;

@end
