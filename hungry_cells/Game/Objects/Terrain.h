//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//
//

#import "cocos2d.h"
#import "Box2D.h"

#define kMaxHillKeyPoints 51
#define kMaxHillVertices 2000
#define kMaxBorderVertices 5000
#define kHillSegmentWidth 20

@class Game;

@interface Terrain : CCNode {
	ccVertex2F hillKeyPoints[kMaxHillKeyPoints];
	int nHillKeyPoints;
	int fromKeyPointI;
	int toKeyPointI;
	ccVertex2F hillVertices[kMaxHillVertices];
    ccVertex2F topHillVertices[kMaxHillVertices];
	ccVertex2F hillTexCoords[kMaxHillVertices];
	int nHillVertices;
	ccVertex2F borderVertices[kMaxBorderVertices];
    ccVertex2F topBorderVertices[kMaxBorderVertices];
	int nBorderVertices;
	CCSprite *_stripes;
	float _offsetX;
	b2World *world;
	b2Body *body;
	int screenW;
	int screenH;
	int textureSize;
}
@property (nonatomic, retain) CCSprite *stripes;
@property (nonatomic, assign) float offsetX;
@property (nonatomic, assign) Game *game;
@property (nonatomic, assign) BOOL education;

+ (id) terrainWithWorld:(b2World*)w game:(Game*)g;
- (id) initWithWorld:(b2World*)w game:(Game*)g;

- (void)updateBodies;

- (float)lastXPosition;

- (void) reset;

- (void)showHelp;
- (void)showOxygen;

@end
