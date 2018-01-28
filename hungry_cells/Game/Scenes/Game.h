//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//

#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

#define UD_IDENTIFIER @"hungry-cells.education"

@class Sky;
@class Terrain;
@class Hero;

@interface Game : CCLayer {
	int _screenW;
	int _screenH;
	b2World *_world;
	Sky *_sky;
	Terrain *_terrain;
	Hero *_hero;
	GLESDebugDraw *_render;
	CCSprite *_resetButton;
}
@property (readonly) int screenW;
@property (readonly) int screenH;
@property (nonatomic, readonly) b2World *world;
@property (nonatomic, retain) Sky *sky;
@property (nonatomic, retain) Terrain *terrain;
@property (nonatomic, retain) Hero *hero;
@property (nonatomic, retain) CCSprite *resetButton;

+ (CCScene*) scene;

- (void) showPerfectSlide;
- (void) showFrenzy;
- (void) showHit;

- (void)decreaseLife;
- (void)increaseLife;

- (void)fatTouched;

@end
