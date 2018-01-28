//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//

#import "Box2DHelper.h"
#import "cocos2d.h"

@implementation Box2DHelper

+ (float) pointsPerMeter {
	return 32.0f;
}

+ (float) metersPerPoint {
	return 1.0f / [self pointsPerMeter];
}

+ (float) pixelsPerMeter {
	return [self pointsPerMeter] * CC_CONTENT_SCALE_FACTOR();
}

+ (float) metersPerPixel {
	return 1.0f / [self pixelsPerMeter];
}

@end
