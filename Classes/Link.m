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

#import "Link.h"



typedef enum {
	StateDisconnected,
	StatePicker,
	StateReset,
	StateCointoss,
	StateConnected,
	StateReconnect
} LinkStates;



@implementation Link

@synthesize state, role, session, name, sessionID, peerID, peerName, connectionAlert, dataReceiver, uniqueID, peerUniqueID;



- (id)initWithID:(NSString*)_sessionID name:(NSString*)_name delegate:(id<LinkDelegate>)_delegate {
	[super init];
	
	self.sessionID = _sessionID;
	self.name = _name;
	
	delegate = _delegate;
	
	role = RoleServer;
	packetNumber = 0;
	session = nil;
	peerID = nil;
	
	NSString *uid = [[UIDevice currentDevice] uniqueIdentifier];
	uniqueID = [uid hash];
	
	self.state = StateDisconnected;
	
	return self;
}



- (void)dealloc {
	if(self.connectionAlert && self.connectionAlert.visible) {
		[self.connectionAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}
	self.connectionAlert = nil;
	
	[self invalidateSession];
	
	self.peerName = nil;	
	self.peerID = nil;
	self.name = nil;
	self.sessionID = nil;
	
	[super dealloc];
}



- (void)invalidateSession {
	if(session != nil) {
		self.dataReceiver = nil;
		[session disconnectFromAllPeers]; 
		session.available = NO; 
		[session setDataReceiveHandler: nil withContext: NULL]; 
		session.delegate = nil; 
		self.session = nil;
	}
}



- (void)setGameState:(NSInteger)newState {
	if(newState == StateDisconnected) {
		if(self.session) {
			// invalidate session and release it.
			[self invalidateSession];
		}
	}
	
	state = newState;
}



-(void)startPicker {
	GKPeerPickerController*		picker;
	
	self.state = StatePicker;
	
	picker = [[GKPeerPickerController alloc] init]; // note: picker is released in various picker delegate methods when picker use is done.
	picker.delegate = self;
	[picker show]; // show the Peer Picker
}



- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker { 
	NSLog(@" >>> peerPickerControllerDidCancel");

	// Peer Picker automatically dismisses on user cancel. No need to programmatically dismiss.
    
	// autorelease the picker. 
	picker.delegate = nil;
    [picker autorelease]; 
	
	// invalidate and release game session if one is around.
	if(self.session != nil)	{
		[self invalidateSession];
	}

	state = StateDisconnected;
	[delegate linkDisconnected];
} 



- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type { 
	NSLog(@" >>> sessionForConnectionType");
	
	GKSession *_session = [[GKSession alloc] initWithSessionID:sessionID displayName:name sessionMode:GKSessionModePeer]; 
	return [_session autorelease]; // peer picker retains a reference, so autorelease ours so we don't leak.
}



- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)_peerID toSession:(GKSession *)_session { 
	NSLog(@" >>> didConnectPeer");
	
	// Remember the current peer.
	self.peerID = _peerID; 
	
	// Make sure we have a reference to the game session and it is set up
	self.session = _session; // retain
	self.session.delegate = self; 

	self.peerName = [session displayNameForPeer:peerID];

	[self.session setDataReceiveHandler:self withContext:nil];
	
	// Done with the Peer Picker so dismiss it.
	[picker dismiss];
	picker.delegate = nil;
	[picker autorelease];
	
	// Start Multiplayer game by entering a cointoss state to determine who is server/client.
	self.state = StateCointoss;
	[NSTimer scheduledTimerWithTimeInterval:0.033 target:self selector:@selector(cointoss) userInfo:nil repeats:NO];
} 



- (void)cointoss {
	NSLog(@" >>> cointoss");
	
	[self sendPacket:PACKET_COINTOSS objectIndex:0 data:&uniqueID length:sizeof(int) reliable:YES];
}



- (void)reset {
	self.dataReceiver = nil;
	self.state = StateReset;
}



- (void)resync {
	[self cointoss];
	
	if (self.state == StateReset) {
		NSString *message = [NSString stringWithFormat:@"Waiting for %@.", [session displayNameForPeer:peerID]];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Replay" message:message delegate:self cancelButtonTitle:@"End Game" otherButtonTitles:nil];
		
		self.connectionAlert = alert;
		[alert show];
		[alert release];
		state = StateCointoss;	
	} else {
		// cointoss packet already received
		[delegate linkConnected:role];
	}
	
}



/*
 * Getting a data packet. This is the data receive handler method expected by the GKSession. 
 * We set ourselves as the receive data handler in the -peerPickerController:didConnectPeer:toSession: method.
 */
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context { 	
	//NSLog(@" >>> receiveData");
	
	const unsigned int packetHeaderSize = 3 * sizeof(int); // we have two "ints" for our header	
	
	static int lastPacketTime = -1;
	unsigned char *incomingPacket = (unsigned char *)[data bytes];
	int *pIntData = (int *)&incomingPacket[0];
	
	// check the network time and make sure packers are in order
	int packetTime = pIntData[0];
	int packetID = pIntData[1];
	int objectIndex = pIntData[2];
	
	lastPacketTime = packetTime;
	
	switch( packetID ) {
		case PACKET_COINTOSS:
			{
				// coin toss to determine roles of the two players
				peerUniqueID = pIntData[3];
				
				// if other player's coin is higher than ours then that player is the server
				if(peerUniqueID > uniqueID) {
					self.role = RoleClient;
				}
				
				if (self.state == StateCointoss) {
					if(self.connectionAlert && self.connectionAlert.visible) {
						[self.connectionAlert dismissWithClickedButtonIndex:-1 animated:NO];
					}
					
					[delegate linkConnected: self.role];
				}
				
				self.state = StateConnected;
			}
			break;	
		default:
			if (dataReceiver) {
				[dataReceiver receivePacket:packetID objectIndex:objectIndex data:&incomingPacket[packetHeaderSize]];
			} else {
				NSLog(@" !!! receiveData PACKET BEFORE COINTOSS: %d", packetID);
			}
	}
}



- (void)sendPacket:(int)packetID objectIndex:(int)objectIndex data:(void *)data length:(int)length reliable:(bool)howtosend {
	
	// the packet we'll send is resued
	static unsigned char networkPacket[MAX_PACKET_SIZE];
	const unsigned int packetHeaderSize = 3 * sizeof(int); // we have two "ints" for our header	
	
	if(length < (MAX_PACKET_SIZE - packetHeaderSize)) { // our networkPacket buffer size minus the size of the header info
		int *pIntData = (int *)&networkPacket[0];
		// header info
		pIntData[0] = packetNumber++;
		pIntData[1] = packetID;
		pIntData[2] = objectIndex;
		
		// copy data in after the header
		memcpy( &networkPacket[packetHeaderSize], data, length ); 
		
		NSData *packet = [NSData dataWithBytes: networkPacket length: (length+packetHeaderSize)];
		if(howtosend == YES) { 
			[session sendDataToAllPeers:packet withDataMode:GKSendDataReliable error:nil];			
		} else {
			[session sendDataToAllPeers:packet withDataMode:GKSendDataUnreliable error:nil];
		}
	}
}



// we've gotten a state change in the session
- (void)session:(GKSession *)_session peer:(NSString *)_peerID didChangeState:(GKPeerConnectionState)_state { 
	
	NSLog(@" >>> didChangeState");
	
	if(self.state == StatePicker) {
		return;				// only do stuff if we're in multiplayer, otherwise it is probably for Picker
	}
	
	if(_state == GKPeerStateDisconnected) {
		// We've been disconnected from the other peer.
		
		// Update user alert or throw alert if it isn't already up
		
		NSString *message = [NSString stringWithFormat:@"%@ has disconnected.", [_session displayNameForPeer:_peerID]];
		if ((self.state == StateCointoss) && self.connectionAlert && self.connectionAlert.visible) {
			self.connectionAlert.message = message;
		}
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lost Connection" message:message delegate:self cancelButtonTitle:@"End Game" otherButtonTitles:nil];
			self.connectionAlert = alert;
			[alert show];
			[alert release];
		}
		
		self.state = StateDisconnected;
		
		[delegate linkDisconnected];
	} 
} 



// Called when an alert button is tapped.
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	// 0 index is "End Game" button
	if(buttonIndex == 0) {
		if (self.state == StateCointoss) {
			[delegate linkDisconnected];
		}
		self.state = StateDisconnected;
	}
}


@end
