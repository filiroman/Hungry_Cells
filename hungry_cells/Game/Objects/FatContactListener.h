//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//

#import "Box2D.h"

#define kMaxAngleDiff 2.4f // in radians

@class Fat;

class FatContactListener : public b2ContactListener {
public:
    Fat *_hero;
    
    FatContactListener(Fat* hero);
    ~FatContactListener();
    
    void BeginContact(b2Contact* contact);
    void EndContact(b2Contact* contact);
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold);
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse);
};