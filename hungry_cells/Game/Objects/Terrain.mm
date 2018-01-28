//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//

#import "Terrain.h"
#import "Constants.h"
#import "Box2DHelper.h"
#import "Game.h"
#import "Fat.h"

#define TUBE_HEIGHT 350

@interface Terrain()
{
    
    CCSprite *first;
    CCSprite *second;
}

@property (nonatomic, retain) NSMutableArray *fats;

- (CCSprite*) generateStripesSprite;
- (CCTexture2D*) generateStripesTexture;
- (void) renderStripes;
- (void) renderGradient;
- (void) renderHighlight;
- (void) renderTopBorder;
- (void) renderNoise;
- (void) generateHillKeyPoints;
- (void) generateBorderVertices;
- (void) createBox2DBody;
- (void) resetHillVertices;
- (ccColor4F) randomColor;


@end

@implementation Terrain

@synthesize stripes = _stripes;
@synthesize offsetX = _offsetX;

+ (id) terrainWithWorld:(b2World*)w game:(Game*)g {
	return [[[self alloc] initWithWorld:w game:g] autorelease];
}

- (id) initWithWorld:(b2World*)w game:(Game*)g {
	
	if ((self = [super init])) {
		
		world = w;
        
        _education = [[[NSUserDefaults standardUserDefaults] valueForKey:UD_IDENTIFIER] boolValue];
        
        self.fats = [NSMutableArray arrayWithCapacity:5];
        
        self.game = g;

		CGSize size = [[CCDirector sharedDirector] winSize];
		screenW = size.width;
		screenH = size.height;
		
#ifndef DRAW_BOX2D_WORLD
		textureSize = 1024;
//		self.stripes = [self generateStripesSprite];
#endif
		
		[self generateHillKeyPoints];
		[self generateBorderVertices];
		[self createBox2DBody];
//        [self createBox2DTopBody];

		self.offsetX = 0;
	}
	return self;
}

- (void) dealloc {

#ifndef DRAW_BOX2D_WORLD
	
	self.stripes = nil;
	
#endif
    
    self.fats = nil;
    [first release];
    [second release];

	[super dealloc];
}

- (CCSprite*) generateStripesSprite {
	
	CCTexture2D *texture = [self generateStripesTexture];
	CCSprite *sprite = [CCSprite spriteWithTexture:texture];
	ccTexParams tp = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_CLAMP_TO_EDGE};
	[sprite.texture setTexParameters:&tp];
	
	return sprite;
}

- (CCTexture2D*) generateStripesTexture {
	
	CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
	[rt begin];
	[self renderStripes];
	[self renderGradient];
	[self renderHighlight];
	[self renderTopBorder];
	[self renderNoise];
	[rt end];
	
	return rt.sprite.texture;
}

- (void) renderStripes {
	
	const int minStripes = 4;
	const int maxStripes = 30;
	
	// random even number of stripes
	int nStripes = arc4random_uniform(maxStripes-minStripes)+minStripes;
	if (nStripes%2) {
		nStripes++;
	}
//	CCLOG(@"nStripes = %d", nStripes);
	
	ccVertex2F *vertices = (ccVertex2F*)malloc(sizeof(ccVertex2F)*nStripes*6);
	ccColor4F *colors = (ccColor4F*)malloc(sizeof(ccColor4F)*nStripes*6);
	int nVertices = 0;
	
	float x1, x2, y1, y2, dx, dy;
	ccColor4F c;
	
	if (arc4random_uniform(2)) {
		
		// diagonal stripes
		
		dx = (float)textureSize*2 / (float)nStripes;
		dy = 0;
		
		x1 = -textureSize;
		y1 = 0;
		
		x2 = 0;
		y2 = textureSize;
		
		for (int i=0; i<nStripes/2; i++) {
			c = [self randomColor];
			for (int j=0; j<2; j++) {
				for (int k=0; k<6; k++) {
					colors[nVertices+k] = c;
				}
				vertices[nVertices++] = (ccVertex2F){x1+j*textureSize, y1};
				vertices[nVertices++] = (ccVertex2F){x1+j*textureSize+dx, y1};
				vertices[nVertices++] = (ccVertex2F){x2+j*textureSize, y2};
				vertices[nVertices++] = vertices[nVertices-3];
				vertices[nVertices++] = vertices[nVertices-3];
				vertices[nVertices++] = (ccVertex2F){x2+j*textureSize+dx, y2};
			}
			x1 += dx;
			x2 += dx;
		}
		
	} else {
		
		// horizontal stripes
		
		dx = 0;
		dy = (float)textureSize / (float)nStripes;
		
		x1 = 0;
		y1 = 0;
		
		x2 = textureSize;
		y2 = 0;
		
		for (int i=0; i<nStripes; i++) {
			c = [self randomColor];
			for (int k=0; k<6; k++) {
				colors[nVertices+k] = c;
			}
			vertices[nVertices++] = (ccVertex2F){x1, y1};
			vertices[nVertices++] = (ccVertex2F){x2, y2};
			vertices[nVertices++] = (ccVertex2F){x1, y1+dy};
			vertices[nVertices++] = vertices[nVertices-3];
			vertices[nVertices++] = vertices[nVertices-3];
			vertices[nVertices++] = (ccVertex2F){x2, y2+dy};
			y1 += dy;
			y2 += dy;
		}
		
	}
	
	// adjust vertices for retina
	for (int i=0; i<nVertices; i++) {
		vertices[i].x *= CC_CONTENT_SCALE_FACTOR();
		vertices[i].y *= CC_CONTENT_SCALE_FACTOR();
	}
	
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glColor4f(1, 1, 1, 1);
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glDrawArrays(GL_TRIANGLES, 0, (GLsizei)nVertices);
	
	free(vertices);
	free(colors);
}

- (void) renderGradient {
	
	float gradientAlpha = 0.5f;
	float gradientWidth = textureSize;
	
	ccVertex2F vertices[6];
	ccColor4F colors[6];
	int nVertices = 0;
	
	vertices[nVertices] = (ccVertex2F){0, 0};
	colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
	vertices[nVertices] = (ccVertex2F){textureSize, 0};
	colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
	
	vertices[nVertices] = (ccVertex2F){0, gradientWidth};
	colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
	vertices[nVertices] = (ccVertex2F){textureSize, gradientWidth};
	colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
	
	if (gradientWidth < textureSize) {
		vertices[nVertices] = (ccVertex2F){0, textureSize};
		colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
		vertices[nVertices] = (ccVertex2F){textureSize, textureSize};
		colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
	}
	
	// adjust vertices for retina
	for (int i=0; i<nVertices; i++) {
		vertices[i].x *= CC_CONTENT_SCALE_FACTOR();
		vertices[i].y *= CC_CONTENT_SCALE_FACTOR();
	}
	
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
}

- (void) renderHighlight {
	
	float highlightAlpha = 0.5f;
	float highlightWidth = textureSize/4;
	
	ccVertex2F vertices[4];
	ccColor4F colors[4];
	int nVertices = 0;
	
	vertices[nVertices] = (ccVertex2F){0, 0};
	colors[nVertices++] = (ccColor4F){1, 1, 0.5f, highlightAlpha}; // yellow
	vertices[nVertices] = (ccVertex2F){textureSize, 0};
	colors[nVertices++] = (ccColor4F){1, 1, 0.5f, highlightAlpha};
	
	vertices[nVertices] = (ccVertex2F){0, highlightWidth};
	colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
	vertices[nVertices] = (ccVertex2F){textureSize, highlightWidth};
	colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
	
	// adjust vertices for retina
	for (int i=0; i<nVertices; i++) {
		vertices[i].x *= CC_CONTENT_SCALE_FACTOR();
		vertices[i].y *= CC_CONTENT_SCALE_FACTOR();
	}
	
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
}

- (void) renderTopBorder {
	
	float borderAlpha = 0.5f;
	float borderWidth = 2.0f;
	
	ccVertex2F vertices[2];
	int nVertices = 0;
	
	vertices[nVertices++] = (ccVertex2F){0, borderWidth/2};
	vertices[nVertices++] = (ccVertex2F){textureSize, borderWidth/2};
	
	// adjust vertices for retina
	for (int i=0; i<nVertices; i++) {
		vertices[i].x *= CC_CONTENT_SCALE_FACTOR();
		vertices[i].y *= CC_CONTENT_SCALE_FACTOR();
	}
	
	glDisableClientState(GL_COLOR_ARRAY);
	
	glLineWidth(borderWidth*CC_CONTENT_SCALE_FACTOR());
	glColor4f(0, 0, 0, borderAlpha);
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glDrawArrays(GL_LINE_STRIP, 0, (GLsizei)nVertices);
}

- (void) renderNoise {
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
	
	CCSprite *s = [CCSprite spriteWithFile:@"noise.png"];
	[s setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
	s.position = ccp(textureSize/2, textureSize/2);
	float imageSize = s.textureRect.size.width;
	s.scale = (float)textureSize/imageSize*CC_CONTENT_SCALE_FACTOR();
	glColor4f(1, 1, 1, 1);
	[s visit];
	[s visit]; // more contrast
}

- (CCLabelTTF*)generateTitleWithString:(NSString*)title position:(CGPoint)position opacity:(int)opacity
{
//    CCLabelTTF *subtitle = [CCLabelTTF labelWithString:title fontName:@"LaoMN" fontSize:50.0f];
    CCLabelTTF *subtitle = [CCLabelTTF labelWithString:title dimensions:CGSizeMake(screenW, screenH/2) alignment:NSTextAlignmentCenter fontName:@"LaoMN-Bold" fontSize:40.0f];
    [self addChild:subtitle];
    
    subtitle.opacity = opacity;
    subtitle.position = position;
    
    return [subtitle autorelease];
}

- (void)makeTitleWithString:(NSString*)title position:(CGPoint)position opacity:(int)opacity
{
    [self makeTitleWithString:title position:position opacity:opacity fontSize:40.0f];
}

- (void)makeTitleWithString:(NSString*)title position:(CGPoint)position opacity:(int)opacity fontSize:(CGFloat)fontSize
{
    //    CCLabelTTF *subtitle = [CCLabelTTF labelWithString:title fontName:@"LaoMN" fontSize:50.0f];
    CCLabelTTF *subtitle = [CCLabelTTF labelWithString:title dimensions:CGSizeMake(screenW, screenH/2) alignment:NSTextAlignmentCenter fontName:@"LaoMN-Bold" fontSize:fontSize];
    [self addChild:subtitle];
    
    subtitle.opacity = opacity;
    subtitle.position = position;
    
}

- (void)showOxygen
{
    [first runAction:[CCSequence actions:[CCFadeOut actionWithDuration:0.5f], [CCCallBlock actionWithBlock:^{
        [second runAction:[CCFadeIn actionWithDuration:0.7f]];
    }], nil]];
}

- (void)showHelp
{
    
    
//    CCLabelTTF *second = [self generateTitleWithString:@"you are the red blood cell\ntraveling through the veins" position:CGPointMake(hillKeyPoints[2].x-100,screenH - 300) opacity:0];
    
    [first runAction:[CCFadeIn actionWithDuration:0.7f]];
    
}

- (void) generateHillKeyPoints {

	nHillKeyPoints = 0;
	
	float x, y, dx, dy, ny;
	
	x = -screenW/4;
	y = screenH*3/4;
	hillKeyPoints[nHillKeyPoints++] = (ccVertex2F){x, y};

	// starting point
	x = 0;
	y = screenH*1.9f/4;
	hillKeyPoints[nHillKeyPoints++] = (ccVertex2F){x, y};
    
    int minDX = 350, rangeDX = 50;
    int minDY = 10,  rangeDY = 10;
    float sign = -1; // +1 - going up, -1 - going  down
    float maxHeight = screenH;
    float minHeight = 20;
    
    if (_education)
    {
        while (nHillKeyPoints < 15) {
            dx = arc4random_uniform(rangeDX)+minDX;
            x += dx;
            dy = arc4random_uniform(rangeDY)+minDY;
            ny = y + dy*sign;
            if(ny > maxHeight) ny = maxHeight;
            if(ny < minHeight) ny = minHeight;
            y = ny;
            sign *= -1;
            hillKeyPoints[nHillKeyPoints++] = (ccVertex2F){x, y};
        }
        
        first = [[self generateTitleWithString:@"you are the red blood cell\ntraveling through the veins\n(tap to continue)" position:CGPointMake(hillKeyPoints[2].x-91,80) opacity:0] retain];
        second = [[self generateTitleWithString:@"your goal is to save\nas much oxygen as you can\n(tap to continue)" position:CGPointMake(hillKeyPoints[2].x-91,80) opacity:0] retain];
        
        [self makeTitleWithString:@"move up and down\nusing buttons" position:CGPointMake(hillKeyPoints[4].x-90,80) opacity:255];
        [self makeTitleWithString:@"avoid walls\nand fats on them" position:CGPointMake(hillKeyPoints[8].x-90,80) opacity:255];
        [self makeTitleWithString:@"GO!!!" position:CGPointMake(hillKeyPoints[14].x-90,80) opacity:255 fontSize:80.0f];
        
        Fat *fatCell = [Fat fatWithGame:self.game];
        [self addChild:fatCell];
        fatCell.position = ccp(hillKeyPoints[9].x-30,hillKeyPoints[9].y);

        [self.fats addObject:fatCell];
        
        fatCell = [Fat fatWithGame:self.game];
        [self addChild:fatCell];
        fatCell.position = ccp(hillKeyPoints[9].x,hillKeyPoints[9].y+5);
        
        [self.fats addObject:fatCell];
        
        fatCell = [Fat fatWithGame:self.game];
        [self addChild:fatCell];
        fatCell.position = ccp(hillKeyPoints[9].x+25,hillKeyPoints[9].y-3);
        
        [self.fats addObject:fatCell];
        
        _education = NO;
    }
	
    minDX = 360, rangeDX = 80;
	minDY = 40,  rangeDY = 150;
	sign = -1; // +1 - going up, -1 - going  down
	maxHeight = 3*screenH/4;
	minHeight = 20;
	while (nHillKeyPoints < kMaxHillKeyPoints-1) {
		dx = arc4random_uniform(rangeDX)+minDX;
		x += dx;
		dy = arc4random_uniform(rangeDY)+minDY;
		ny = y + dy*sign;
		if(ny > maxHeight) ny = maxHeight;
		if(ny < minHeight) ny = minHeight;
		y = ny;
		sign *= -1;
		hillKeyPoints[nHillKeyPoints++] = (ccVertex2F){x, y};
        
        
        if (arc4random()%2 == 1)
        {
            
            Fat *fatCell = [Fat fatWithGame:self.game];
            [self addChild:fatCell];
            fatCell.position = ccp(x-30,y);
            
            [self.fats addObject:fatCell];
            
            if (arc4random()%2 == 1)
            {
                fatCell = [Fat fatWithGame:self.game];
                [self addChild:fatCell];
                fatCell.position = ccp(x+30,y-5);
                
                [self.fats addObject:fatCell];
            }
        
            if (arc4random()%2 == 0)
            {
                fatCell = [Fat fatWithGame:self.game];
                [self addChild:fatCell];
                fatCell.position = ccp(x,y-2);
                
                [self.fats addObject:fatCell];
            }
            
            if (arc4random()%2 == 0)
            {
                fatCell = [Fat fatWithGame:self.game];
                [self addChild:fatCell];
                fatCell.position = ccp(x+60,y+2);
                
                [self.fats addObject:fatCell];
            }
            
            if (arc4random()%2 == 1)
            {
                fatCell = [Fat fatWithGame:self.game];
                [self addChild:fatCell];
                fatCell.position = ccp(x-55,y-3);
                
                [self.fats addObject:fatCell];
            }
        }
	}

	// cliff
	x += minDX+rangeDX;
	y = 0;
	hillKeyPoints[nHillKeyPoints++] = (ccVertex2F){x, y};
    
    x = hillKeyPoints[nHillKeyPoints-2].x;
    y = hillKeyPoints[nHillKeyPoints-2].y;
    
    CCSprite *spr = [CCSprite spriteWithFile:@"finish.png"];
    [self addChild:spr z:-1];
    spr.position = ccp(x+20,y+TUBE_HEIGHT/2);

	// adjust vertices for retina
	for (int i=0; i<nHillKeyPoints; i++) {
		hillKeyPoints[i].x *= CC_CONTENT_SCALE_FACTOR();
		hillKeyPoints[i].y *= CC_CONTENT_SCALE_FACTOR();
	}
	
	fromKeyPointI = 0;
	toKeyPointI = 0;
}

- (void) generateBorderVertices {

	nBorderVertices = 0;
	ccVertex2F p0, p1, pt0, pt1, pt10;
	p0 = hillKeyPoints[0];
	for (int i=1; i<nHillKeyPoints; i++) {
		p1 = hillKeyPoints[i];
		
		int hSegments = floorf((p1.x-p0.x)/kHillSegmentWidth);
		float dx = (p1.x - p0.x) / hSegments;
		float da = M_PI / hSegments;
		float ymid = (p0.y + p1.y) / 2;
		float ampl = (p0.y - p1.y) / 2;
		pt0 = p0;
		borderVertices[nBorderVertices] = pt0;
        pt0.y += TUBE_HEIGHT;
        topBorderVertices[nBorderVertices++] = pt0;
        
		for (int j=1; j<hSegments+1; j++) {
			pt1.x = p0.x + j*dx;
			pt1.y = ymid + ampl * cosf(da*j);
			borderVertices[nBorderVertices] = pt1;
            pt10 = pt1;
            pt10.y += TUBE_HEIGHT;
            topBorderVertices[nBorderVertices++] = pt10;
			pt0 = pt1;
		}
		
		p0 = p1;
	}
//	CCLOG(@"nBorderVertices = %d", nBorderVertices);
}

- (void)createBox2DTopBody {
    
//    b2BodyDef bd;
//    bd.position.Set(0, screenH);
//    
//    body = world->CreateBody(&bd);
//    
//    b2Vec2 b2vertices[kMaxBorderVertices];
//    int nVertices = 0;
//    for (int i=0; i<nBorderVertices; i++) {
//        b2vertices[nVertices++].Set(topBorderVertices[i].x * [Box2DHelper metersPerPixel],
//                                    topBorderVertices[i].y * [Box2DHelper metersPerPixel]);
//    }
//    b2vertices[nVertices++].Set(topBorderVertices[nBorderVertices-1].x * [Box2DHelper metersPerPixel], screenH);
//    b2vertices[nVertices++].Set(topBorderVertices[0].x * [Box2DHelper metersPerPixel], screenH);
//    
//    b2LoopShape shape;
//    shape.Create(b2vertices, nVertices);
//    body->CreateFixture(&shape, 0);
}

- (void) createBox2DBody {
	
	b2BodyDef bd;
	bd.position.Set(0, 0);
	
	body = world->CreateBody(&bd);
	
	b2Vec2 b2vertices[kMaxBorderVertices];
	int nVertices = 0;
	for (int i=0; i<nBorderVertices; i++) {
		b2vertices[nVertices++].Set(borderVertices[i].x * [Box2DHelper metersPerPixel],
									borderVertices[i].y * [Box2DHelper metersPerPixel]);
	}
//	b2vertices[nVertices++].Set(borderVertices[nBorderVertices-1].x * [Box2DHelper metersPerPixel], 20);
//	b2vertices[nVertices++].Set(borderVertices[0].x * [Box2DHelper metersPerPixel], 20);
    for (int i=nBorderVertices-1; i>-1; i--) {
        b2vertices[nVertices++].Set(topBorderVertices[i].x * [Box2DHelper metersPerPixel],
                                    topBorderVertices[i].y * [Box2DHelper metersPerPixel]);
    }
	
	b2LoopShape shape;
	shape.Create(b2vertices, nVertices);
	body->CreateFixture(&shape, 0);
    
}

- (void) resetHillVertices {
    
    //#ifdef DRAW_BOX2D_WORLD
    //	return;
    //#endif
    
    static int prevFromKeyPointI = -1;
    static int prevToKeyPointI = -1;
    
    // key points interval for drawing
    
    float leftSideX = _offsetX-screenW/8/self.scale;
    float rightSideX = _offsetX+screenW*7/8/self.scale;
    
    // adjust position for retina
    leftSideX *= CC_CONTENT_SCALE_FACTOR();
    rightSideX *= CC_CONTENT_SCALE_FACTOR();
    
    while (hillKeyPoints[fromKeyPointI+1].x < leftSideX) {
        fromKeyPointI++;
        if (fromKeyPointI > nHillKeyPoints-1) {
            fromKeyPointI = nHillKeyPoints-1;
            break;
        }
    }
    while (hillKeyPoints[toKeyPointI].x < rightSideX) {
        toKeyPointI++;
        if (toKeyPointI > nHillKeyPoints-1) {
            toKeyPointI = nHillKeyPoints-1;
            break;
        }
    }
    
    if (prevFromKeyPointI != fromKeyPointI || prevToKeyPointI != toKeyPointI) {
        
        //		CCLOG(@"building hillVertices array for the visible area");
        
        //		CCLOG(@"leftSideX = %f", leftSideX);
        //		CCLOG(@"rightSideX = %f", rightSideX);
        
        //		CCLOG(@"fromKeyPointI = %d (x = %f)",fromKeyPointI,hillKeyPoints[fromKeyPointI].x);
        //		CCLOG(@"toKeyPointI = %d (x = %f)",toKeyPointI,hillKeyPoints[toKeyPointI].x);
        
        // vertices for visible area
        nHillVertices = 0;
        ccVertex2F p0, p1, pt0, pt1;
        p0 = hillKeyPoints[fromKeyPointI];
        for (int i=fromKeyPointI+1; i<toKeyPointI+1; i++) {
            p1 = hillKeyPoints[i];
            
            // triangle strip between p0 and p1
            int hSegments = floorf((p1.x-p0.x)/kHillSegmentWidth);
            int vSegments = 1;
            float dx = (p1.x - p0.x) / hSegments;
            float da = M_PI / hSegments;
            float ymid = (p0.y + p1.y) / 2;
            float ampl = (p0.y - p1.y) / 2;
            pt0 = p0;
            for (int j=1; j<hSegments+1; j++) {
                pt1.x = p0.x + j*dx;
                pt1.y = ymid + ampl * cosf(da*j);
                for (int k=0; k<vSegments+1; k++) {
                    hillVertices[nHillVertices] = (ccVertex2F){pt0.x, pt0.y-(float)textureSize/vSegments*k};
                    topHillVertices[nHillVertices++] = (ccVertex2F){pt0.x, TUBE_HEIGHT + pt0.y+(float)textureSize/vSegments*k};
                    
                    //                    topHillTexCoords[nHillVertices] = (ccVertex2F){pt0.x/(float)textureSize, (float)(k)/vSegments};
                    //					hillTexCoords[nHillVertices++] = (ccVertex2F){pt0.x/(float)textureSize, (float)(k)/vSegments};
                    
                    hillVertices[nHillVertices] = (ccVertex2F){pt1.x, pt1.y-(float)textureSize/vSegments*k};
                    topHillVertices[nHillVertices++] = (ccVertex2F){pt1.x, TUBE_HEIGHT + pt1.y+(float)textureSize/vSegments*k};
                    
                    //                    topHillTexCoords[nHillVertices] = (ccVertex2F){pt1.x/(float)textureSize, (float)(k)/vSegments};
                    //					hillTexCoords[nHillVertices++] = (ccVertex2F){pt1.x/(float)textureSize, (float)(k)/vSegments};
                    
                }
                pt0 = pt1;
            }
            
            p0 = p1;
        }
        
        //		CCLOG(@"nHillVertices = %d", nHillVertices);
        
        prevFromKeyPointI = fromKeyPointI;
        prevToKeyPointI = toKeyPointI;
    }
}

//- (void) resetHillVertices {
//
//#ifdef DRAW_BOX2D_WORLD
//	return;
//#endif
//	
//	static int prevFromKeyPointI = -1;
//	static int prevToKeyPointI = -1;
//	
//	// key points interval for drawing
//	
//	float leftSideX = _offsetX-screenW/8/self.scale;
//	float rightSideX = _offsetX+screenW*7/8/self.scale;
//	
//	// adjust position for retina
//	leftSideX *= CC_CONTENT_SCALE_FACTOR();
//	rightSideX *= CC_CONTENT_SCALE_FACTOR();
//	
//	while (hillKeyPoints[fromKeyPointI+1].x < leftSideX) {
//		fromKeyPointI++;
//		if (fromKeyPointI > nHillKeyPoints-1) {
//			fromKeyPointI = nHillKeyPoints-1;
//			break;
//		}
//	}
//	while (hillKeyPoints[toKeyPointI].x < rightSideX) {
//		toKeyPointI++;
//		if (toKeyPointI > nHillKeyPoints-1) {
//			toKeyPointI = nHillKeyPoints-1;
//			break;
//		}
//	}
//	
//	if (prevFromKeyPointI != fromKeyPointI || prevToKeyPointI != toKeyPointI) {
//		
////		CCLOG(@"building hillVertices array for the visible area");
//
////		CCLOG(@"leftSideX = %f", leftSideX);
////		CCLOG(@"rightSideX = %f", rightSideX);
//		
////		CCLOG(@"fromKeyPointI = %d (x = %f)",fromKeyPointI,hillKeyPoints[fromKeyPointI].x);
////		CCLOG(@"toKeyPointI = %d (x = %f)",toKeyPointI,hillKeyPoints[toKeyPointI].x);
//		
//		// vertices for visible area
//		nHillVertices = 0;
//		ccVertex2F p0, p1, pt0, pt1;
//		p0 = hillKeyPoints[fromKeyPointI];
//		for (int i=fromKeyPointI+1; i<toKeyPointI+1; i++) {
//			p1 = hillKeyPoints[i];
//			
//			// triangle strip between p0 and p1
//			int hSegments = floorf((p1.x-p0.x)/kHillSegmentWidth);
//			int vSegments = 1;
//			float dx = (p1.x - p0.x) / hSegments;
//			float da = M_PI / hSegments;
//			float ymid = (p0.y + p1.y) / 2;
//			float ampl = (p0.y - p1.y) / 2;
//			pt0 = p0;
//			for (int j=1; j<hSegments+1; j++) {
//				pt1.x = p0.x + j*dx;
//				pt1.y = ymid + ampl * cosf(da*j);
//				for (int k=0; k<vSegments+1; k++) {
//					hillVertices[nHillVertices] = (ccVertex2F){pt0.x, pt0.y-(float)textureSize/vSegments*k};
//					hillTexCoords[nHillVertices++] = (ccVertex2F){pt0.x/(float)textureSize, (float)(k)/vSegments};
//					hillVertices[nHillVertices] = (ccVertex2F){pt1.x, pt1.y-(float)textureSize/vSegments*k};
//					hillTexCoords[nHillVertices++] = (ccVertex2F){pt1.x/(float)textureSize, (float)(k)/vSegments};
//				}
//				pt0 = pt1;
//			}
//			
//			p0 = p1;
//		}
//		
////		CCLOG(@"nHillVertices = %d", nHillVertices);
//		
//		prevFromKeyPointI = fromKeyPointI;
//		prevToKeyPointI = toKeyPointI;
//	}
//}

- (ccColor4F) randomColor {
	const int minSum = 450;
	const int minDelta = 150;
	int r, g, b, min, max;
	while (true) {
		r = arc4random_uniform(256);
		g = arc4random_uniform(256);
		b = arc4random_uniform(256);
		min = MIN(MIN(r, g), b);
		max = MAX(MAX(r, g), b);
		if (max-min < minDelta) continue;
		if (r+g+b < minSum) continue;
		break;
	}
	return ccc4FFromccc3B(ccc3(r, g, b));
}

- (void) draw {
	
////#ifdef DRAW_BOX2D_WORLD
//	
//	glDisable(GL_TEXTURE_2D);
//	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
//	glDisableClientState(GL_COLOR_ARRAY);
//	
//	glPushMatrix();
//	glScalef(CC_CONTENT_SCALE_FACTOR(), CC_CONTENT_SCALE_FACTOR(), 1.0f);
//	world->DrawDebugData();
//	glPopMatrix();
//	
//	glEnableClientState(GL_COLOR_ARRAY);
//	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
//	glEnable(GL_TEXTURE_2D);	
//
////#else
//
//	glBindTexture(GL_TEXTURE_2D, _stripes.texture.name);
//	
//	glDisableClientState(GL_COLOR_ARRAY);
//	
//	glColor4f(0.5, 0.5, 0.5, 1);
//	glVertexPointer(2, GL_FLOAT, 0, hillVertices);
//	glTexCoordPointer(2, GL_FLOAT, 0, hillTexCoords);
//	glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nHillVertices);
//	
//	glEnableClientState(GL_COLOR_ARRAY);
    
    
    
    
    glBindTexture(GL_TEXTURE_2D, _stripes.texture.name);
    
    glDisableClientState(GL_COLOR_ARRAY);
    
    glColor4f(178.0/255.0, 44.0/255.0, 69.0/255.0, 1);
    glVertexPointer(2, GL_FLOAT, 0, hillVertices);
    //	glTexCoordPointer(2, GL_FLOAT, 0, hillTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nHillVertices);
    
    glVertexPointer(2, GL_FLOAT, 0, topHillVertices);
    //    glTexCoordPointer(2, GL_FLOAT, 0, topHillTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nHillVertices);
    
    glEnableClientState(GL_COLOR_ARRAY);
//
//#endif
}

- (void)updateBodies
{
    for (Hero *fat in self.fats) {
        [fat updateNode];
    }
}

- (void) setOffsetX:(float)offsetX {
	static BOOL firstTime = YES;
	if (_offsetX != offsetX || firstTime) {
		firstTime = NO;
		_offsetX = offsetX;
		self.position = ccp(screenW/8-_offsetX*self.scale, 0);
		[self resetHillVertices];
	}
}

- (void) reset {
	
#ifndef DRAW_BOX2D_WORLD
//	self.stripes = [self generateStripesSprite];
#endif
	
	fromKeyPointI = 13;
	toKeyPointI = 17;
}

- (float)lastXPosition
{
    return hillKeyPoints[nHillKeyPoints-1].x;
}

@end
