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

#import "ReplaceLayerAction.h"


@implementation ReplaceLayerAction


@synthesize reverse;

-(id) initWithScene:(Scene*)_scene layer:(Layer<ReplaceLayerActionDelegate>*)_layer replaceLayer:(Layer*)_replaceLayer
{
	[super initWithDuration:0.8f];
	
	scene = _scene;
	layer = _layer;
	replaceLayer = _replaceLayer;
	
	layer.anchorPoint = cpvzero;
	layer.position = cpv(480, 0);
	[scene addChild:layer z:1];	
	[layer visit];
	
	reverse = false;
	
	return self;
}



- (void) setReverse: (bool)_reverse {
	reverse = _reverse;
	if (reverse) {
		layer.position = cpv(-480, 0);
	} else {
		layer.position = cpv(480, 0);		
	}
}



-(void)stop
{
	if (replaceLayer) {
		[scene removeChild:replaceLayer cleanup:false];
	}
	
	layer.position = cpvzero;
	[layer layerReplaced];
	
	[super stop];
}



-(void) update: (ccTime) t
{
	float tt = t;
	float rate = 2.0f;
	int sign =1;
	int r = (int) rate;
	
	if (r % 2 == 0)
		sign = -1;	
	
	if ((t*=2) < 1)
		tt = 0.5f * powf (t, rate);
	else
		tt = sign*0.5f * (powf (t-2, rate) + sign*2);	
	
	if (replaceLayer) {
		if (reverse) {
			replaceLayer.position = cpv(480.0f * tt, 0);
		} else {
			replaceLayer.position = cpv(- (480.0f * tt), 0);
		}
	}
	
	if (reverse) {
		layer.position = cpv(-480 + (480.0f * tt), 0);
	} else {
		layer.position = cpv(480 - (480.0f * tt), 0);
	}
}

@end
