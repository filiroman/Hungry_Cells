//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//

#import "CCNode.h"
#import "cocos2d.h"
#import "Box2D.h"

#define kPerfectTakeOffVelocityY 2.0f

@class Game;
class FatContactListener;

@interface Fat : CCNode
{
    Game *_game;
    CCSprite *_sprite;
    b2Body *_body;
    float _radius;
    BOOL _awake;
    BOOL _flying;
    BOOL _diving;
    FatContactListener *_contactListener;
    int _nPerfectSlides;
}
@property (nonatomic, retain) Game *game;
@property (nonatomic, retain) CCSprite *sprite;
@property (nonatomic, readwrite) b2Body *body;
@property (readonly) BOOL awake;
@property (nonatomic) BOOL diving;

+ (id) fatWithGame:(Game*)game;
- (id) initWithGame:(Game*)game;

- (void) updatePhysics;
- (void) updateNode;

@end
