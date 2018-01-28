//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//

#import "Game.h"
#import "Fat.h"
#import "FatContactListener.h"
#import "Box2D.h"
#import "Constants.h"
#import "Box2DHelper.h"

@interface Fat()
{
    BOOL initial;
}
- (void) createBox2DBody;

@end

@implementation Fat

@synthesize game = _game;
@synthesize sprite = _sprite;
@synthesize awake = _awake;
@synthesize diving = _diving;
@synthesize body = _body;

+ (id) fatWithGame:(Game*)game {
    return [[[self alloc] initWithGame:game] autorelease];
}

- (id) initWithGame:(Game*)game {
    
    if ((self = [super init])) {
        
        self.game = game;
        
//#ifndef DRAW_BOX2D_WORLD
        
        int num = arc4random()%3 + 1;
        
        self.sprite = [CCSprite spriteWithFile:[NSString stringWithFormat:@"fatcell_%d.png",num]];
        [self addChild:_sprite];
//#endif
        _body = NULL;
        _radius = 50.0f;
        
        initial = YES;
        
        _contactListener = new FatContactListener(self);
        _game.world->SetContactListener(_contactListener);
        
        [self reset];
    }
    return self;
}

- (void) dealloc {
    
    self.game = nil;
    
#ifndef DRAW_BOX2D_WORLD
    self.sprite = nil;
#endif
    
    delete _contactListener;
    [super dealloc];
}

- (void) reset {
    _flying = NO;
    _diving = NO;
    _nPerfectSlides = 0;
    if (_body) {
        _game.world->DestroyBody(_body);
    }
    //[self createBox2DBody];
    //[self updateNode];
//    [self sleep];
}

- (void)setPosition:(CGPoint)position
{
    [super setPosition:position];
    
    if (initial)
    {
        initial = NO;
        //[self createBox2DBody];
    }
//    [self updateNode];
}

- (void) createBox2DBody {
    
    b2BodyDef bd;
    bd.type = b2_dynamicBody;
    bd.linearDamping = 0.05f;
    bd.fixedRotation = true;
    
    // start position
    CGPoint p = position_;
//    CCLOG(@"start position = %f, %f", p.x, p.y);
    
    bd.position.Set(p.x * [Box2DHelper metersPerPoint], p.y * [Box2DHelper metersPerPoint]);
    _body = _game.world->CreateBody(&bd);
    _body->SetUserData(self.sprite);
    
    b2CircleShape shape;
    shape.m_radius = _radius * [Box2DHelper metersPerPoint];
    
    b2FixtureDef fd;
    fd.shape = &shape;
    fd.density = 1.0f;
    fd.restitution = 0; // bounce
    fd.friction = 0;
    
    _body->CreateFixture(&fd);
}

- (void) sleep {
    _awake = NO;
    _body->SetActive(false);
}

- (void) wake {
    _awake = YES;
    _body->SetActive(true);
    _body->ApplyLinearImpulse(b2Vec2(1,2), _body->GetPosition());
}

- (void) updatePhysics {
    
    // apply force if diving
    if (_diving) {
        if (!_awake) {
            [self wake];
            _diving = NO;
        } else {
            _body->ApplyForce(b2Vec2(0,-40),_body->GetPosition());
        }
    }
    
    // limit velocity
    const float minVelocityX = 3;
    const float minVelocityY = -40;
    b2Vec2 vel = _body->GetLinearVelocity();
    if (vel.x < minVelocityX) {
        vel.x = minVelocityX;
    }
    if (vel.y < minVelocityY) {
        vel.y = minVelocityY;
    }
    _body->SetLinearVelocity(vel);
}

- (void) updateNode {
    
    CGPoint p;
    p.x = _body->GetPosition().x * [Box2DHelper pointsPerMeter];
    p.y = _body->GetPosition().y * [Box2DHelper pointsPerMeter];
    
    // CCNode position and rotation
    position_ = p;
    b2Vec2 vel = _body->GetLinearVelocity();
    float angle = atan2f(vel.y, vel.x);
    
#ifdef DRAW_BOX2D_WORLD
    _body->SetTransform(_body->GetPosition(), angle);
#else
    self.rotation = -1 * CC_RADIANS_TO_DEGREES(angle);
#endif
    
    // collision detection
    b2Contact *c = _game.world->GetContactList();
    if (c) {
        if (_flying) {
            [self landed];
        }
    } else {
        if (!_flying) {
            [self tookOff];
        }
    }
    
    // TEMP: sleep if below the screen
    if (p.y < -_radius && _awake) {
        [self sleep];
    }
}

- (void) landed {
    //	CCLOG(@"landed");
    _flying = NO;
}

- (void) tookOff {
    //	CCLOG(@"tookOff");
    _flying = YES;
    b2Vec2 vel = _body->GetLinearVelocity();
    //	CCLOG(@"vel.y = %f",vel.y);
    if (vel.y > kPerfectTakeOffVelocityY) {
        //		CCLOG(@"perfect slide");
        _nPerfectSlides++;
        if (_nPerfectSlides > 1) {
            if (_nPerfectSlides == 4) {
                //[_game showFrenzy];
            } else {
                //[_game showPerfectSlide];
            }
        }
    }
}

@end