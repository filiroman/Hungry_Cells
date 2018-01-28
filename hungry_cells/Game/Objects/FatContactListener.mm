//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//

#import "FatContactListener.h"
#import "Fat.h"
#import "Game.h"

FatContactListener::FatContactListener(Fat* hero) {
    _hero = [hero retain];
}

FatContactListener::~FatContactListener() {
    [_hero release];
}

void FatContactListener::BeginContact(b2Contact* contact) {
    NSLog(@"FAT!");
}

void FatContactListener::EndContact(b2Contact* contact) {
    
    [_hero.game fatTouched];
}

void FatContactListener::PreSolve(b2Contact* contact, const b2Manifold* oldManifold) {
//    b2WorldManifold wm;
//    contact->GetWorldManifold(&wm);
//    b2PointState state1[2], state2[2];
//    b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());
//    if (state2[0] == b2_addState) {
//        const b2Body *b = contact->GetFixtureB()->GetBody();
//        b2Vec2 vel = b->GetLinearVelocity();
//        float va = atan2f(vel.y, vel.x);
//        float na = atan2f(wm.normal.y, wm.normal.x);
//        //		CCLOG(@"na = %.3f",na);
//        if (na - va > kMaxAngleDiff) {
////            [_hero hit];
//        }
//    }
}

void FatContactListener::PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {}
