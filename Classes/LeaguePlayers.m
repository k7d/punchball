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

#import "LeaguePlayers.h"
#import "Common.h"

@implementation LeaguePlayers

-(id)init:(id<LeaguePlayersDelegate>)_delegate league:(TwiztLeague*)_league window:(UIWindow*)_window {
	self = [super init];
	
	delegate = _delegate;
	league = _league;
	window = _window;

	Sprite *bg = [Sprite spriteWithFile:@"league.png"];
	bg.anchorPoint = cpvzero;	
	[self addChild:bg z:0];			
	
	MenuItemImage *mn = [MenuItemImage itemFromNormalImage:@"b_menu.png" selectedImage:@"b_menu_s.png" target:self selector:@selector(menu:)];	
	Menu *mnm = [Menu menuWithItems: mn, nil];
	mnm.position = cpv(70, 278);
	[self addChild:mnm z:3];	
	
	playerIDs = [[[league getGames] allKeys] retain];
	
	table = [[UITableView alloc] initWithFrame:CGRectMake(0,0,480.0f,320.0f)];
	table.backgroundColor = [UIColor clearColor];
	table.separatorStyle = UITableViewCellSeparatorStyleNone;
	table.transform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(H_PI), +80, +80);
	table.frame = CGRectMake(12, 495, 228, 450);
	table.rowHeight = 30.0f;
	table.delegate = self;
	table.dataSource = self;
	[window addSubview:table];
	
	return self;
}



-(void)dealloc {
	[table removeFromSuperview];	
	[table release];
	[playerIDs release];
	[super dealloc];
}



-(void)setPosition:(CGPoint)p {
	table.frame = CGRectMake(12, p.x + 15, 228, 450);
	[super setPosition:p];
}



- (void)layerReplaced {
}



-(void)menu: (id) sender {
	[delegate onLeagueMenu];
}



- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	int c =  [playerIDs count];
	if (c == 0) {
		return 2; 
	} else {
		return c;
	}
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *PlayerCellID = @"PlayerCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PlayerCellID];

	if (cell == nil) {
		// Use the default cell style.
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PlayerCellID] autorelease];
	}
	
	if ([playerIDs count] == 0) {
		if (indexPath.row == 0) {
			cell.textLabel.text = @"You haven't played with";
		} else {
			cell.textLabel.text = @"anybody yet.";
		}
	} else {
		NSDictionary *playerGames = [[league getGames] objectForKey:[playerIDs objectAtIndex:indexPath.row]];
		cell.textLabel.text = [NSString stringWithFormat:@"vs. %@", [playerGames objectForKey:@"Name"]];
	}

	cell.textLabel.font = [UIFont fontWithName:@"Courier" size:22];
	cell.textLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
	
	return cell;
}



- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[delegate onLeaguePlayer:[playerIDs objectAtIndex:indexPath.row]];
	return indexPath;
}


@end
