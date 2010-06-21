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

@protocol EnterNameDelegate

- (void) nameEntered: (NSString*)name;

@end

@interface EnterNameView : UIView<UITextFieldDelegate>{
	UITextField *nameField;
	id<EnterNameDelegate> delegate;
}

- (id) initWithDelegate: (id<EnterNameDelegate>)_delegate;

@end

@interface EnterName : Layer<ReplaceLayerActionDelegate, EnterNameDelegate> {
	id<EnterNameDelegate> delegate;
	UIWindow *window;
	EnterNameView *view;
}

- (id) initWithDelegate: (id<EnterNameDelegate>)_delegate window:(UIWindow*)_window;

@end


