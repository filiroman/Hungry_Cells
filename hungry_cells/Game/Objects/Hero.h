//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"

#define kPerfectTakeOffVelocityY 2.0f

@class Game;
class HeroContactListener;

@interface Hero : CCNode {
	Game *_game;
	CCSprite *_sprite;
	b2Body *_body;
	float _radius;
	BOOL _awake;
	BOOL _flying;
	BOOL _diving;
	HeroContactListener *_contactListener;
	int _nPerfectSlides;
}
@property (nonatomic, retain) Game *game;
@property (nonatomic, retain) CCSprite *sprite;
@property (nonatomic, readwrite) b2Body *body;
@property (readonly) BOOL awake;
@property (nonatomic) BOOL diving;

+ (id) heroWithGame:(Game*)game;
- (id) initWithGame:(Game*)game;

- (void) reset;
- (void) resetForPos:(CGPoint)pos;
- (void) sleep;
- (void) wake;
- (void) updatePhysics;
- (void) updateNode;

- (void) landed;
- (void) tookOff;
- (void) hit;

@end
