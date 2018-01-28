//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//

@interface Box2DHelper : NSObject

// ignore CC_CONTENT_SCALE_FACTOR
+ (float) pointsPerMeter;
+ (float) metersPerPoint;

// consider CC_CONTENT_SCALE_FACTOR
+ (float) pixelsPerMeter;
+ (float) metersPerPixel;

@end
