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

#define BORDER_WITDH 10000 // border width - increases this if player or glove get stuck of out bounds
#define INNER_BORDER 0
#define DAMPING 0.6 // how much resistance space will have. 1.0 = no resistance
#define SLIDE_TOUCH_APROX 40 // radius in pixels when sliding touch is registered
#define COLLISION_TYPE_BORDER 4

#define GLOVE_DIST_MIN 50.0f
#define GLOVE_DIST_MAX 250.0f

#define COLLISION_TYPE_HEAD 1
#define COLLISION_TYPE_GLOVE 2

#define MIN_PUNCH_TIME 0.10f
#define MAX_PUNCH_TIME 0.15f

#define MAX_PUNCH_IMPACT_TIME 0.5f // in seconds 
#define MAX_HIT_IMPACT_TIME 1.0f // in seconds

#define HIT_EFFECT_TIME 0.3f
#define MAX_HIT_EFFECT_SPEED 150.0f

#define MAX_HEALTH 20.0f

#define DEFAULT_SLIDE_SPEED 1200 // max pixels per second 

#define SLIDE_TARGET_APROX 10.0f // by how much pixels head should be from slide target to stop sliding

#define ROTATE_SPEED 12.56  // radians per second 2*pi = 360 degrees 

#define ROTATE_APROX 0.17

#define NETWORK_SYNC_DELAY 0.05f // in seconds
#define NETWORK_SYNC_CORRECTION_INTERVAL 0.5f
#define NETWORK_SLIDE_INTERVAL 0.1f // how frequently send slide updates in seconds 

#define HIT_SCORE 10.0f
#define PERFECT_HIT_THRESHOLD 0.9f
#define PERFECT_HIT_SCORE 20
#define STREAK_2_SCORE 3
#define STREAK_3_SCORE 5

#define BONUS_TIP_TIME 3.0f
#define BONUS_LONG_TIP_TIME 3.0f
#define BONUS_TIP_DIST 600.0f // in pixels

#define GAME_HINT_TIME 3.0f // in seconds

#define MAX_SWEEP 0.5f
 
#define PUNCH_POWER_COEF 1.25f // max power = after 1 / PUNCH_POWER_COEF - PUNCH_POWER_BASE seconds = 0.7
#define PUNCH_POWER_BASE 0.1f

#define APP_ID "Punchball"
#define SECRET "leaderboard_secret_key"

