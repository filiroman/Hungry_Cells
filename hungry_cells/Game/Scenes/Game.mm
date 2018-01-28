//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//

#import "Game.h"
#import "Menu.h"
#import "Sky.h"
#import "Terrain.h"
#import "Hero.h"
#import "Constants.h"
#import "Box2DHelper.h"
#import "box2d.h"
#import "SimpleAudioEngine.h"

#define START_LIVES 6
#define FORCE_MAGNITUDE 1.0f

@interface Game()
{
    int lives;
    float magnitude;
    CCSprite *oxygenSpr;
    CCSprite *gameOverSpr;
    
    CCSprite *winSpr;
    CCMenu *finishMenu;
    
    CCMenu *starMenu;
    CCSprite *restartSpr;
    CCSprite *toMenuSpr;
    
    CCSprite *upSpr;
    CCSprite *downSpr;
    
    BOOL crashed;
    
    BOOL gameOver;
    BOOL gameWin;
    
    BOOL education;
    BOOL education_2;
    BOOL education_3;
}

@property (nonatomic, retain) NSMutableArray *lifes;
@property (nonatomic, retain) NSMutableArray *stars;

- (void) createBox2DWorld;
- (BOOL) touchBeganAt:(CGPoint)location;
- (BOOL) touchEndedAt:(CGPoint)location;
- (void) reset;
@end

@implementation Game

@synthesize screenW = _screenW;
@synthesize screenH = _screenH;
@synthesize world = _world;
@synthesize sky = _sky;
@synthesize terrain = _terrain;
@synthesize hero = _hero;
@synthesize resetButton = _resetButton;

+ (CCScene*) scene {
	CCScene *scene = [CCScene node];
	[scene addChild:[Game node]];
	return scene;
}

- (id) init {
	
	if ((self = [super init])) {

		CGSize screenSize = [[CCDirector sharedDirector] winSize];
		_screenW = screenSize.width;
		_screenH = screenSize.height;
        
        gameOver = NO;
        gameWin = NO;
        
        NSNumber *yep = [[NSUserDefaults standardUserDefaults] valueForKey:UD_IDENTIFIER];
        if (yep == nil)
        {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:UD_IDENTIFIER];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            education = YES;
            education_2 = YES;
            education_3 = YES;
        } else
        {
            education = [yep boolValue];
            education_2 = education;
            education_3 = education;
        }
        
        

        magnitude = FORCE_MAGNITUDE;
        lives = START_LIVES;
        crashed = NO;
        self.lifes = [NSMutableArray arrayWithCapacity:lives];
        self.stars = [NSMutableArray arrayWithCapacity:3];
        
        [self prepareAudio];
        
		[self createBox2DWorld];

#ifndef DRAW_BOX2D_WORLD

		self.sky = [Sky skyWithTextureSize:1024];
		[self addChild:_sky];
		
#endif

		self.terrain = [Terrain terrainWithWorld:_world game:self];
		[self addChild:_terrain];
		
		self.hero = [Hero heroWithGame:self];
		[_terrain addChild:_hero];

//		self.resetButton = [CCSprite spriteWithFile:@"resetButton.png"];
//		[self addChild:_resetButton];
//		CGSize size = _resetButton.contentSize;
//		float padding = 8;
//		_resetButton.position = ccp(_screenW-size.width/2-padding, _screenH-size.height/2-padding);
		
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
		self.isTouchEnabled = YES;
#else
		self.isMouseEnabled = YES;
#endif
        
        [self createOxygen];
        
        [self createControls];
        
        [self createGameOver];
        
		[self scheduleUpdate];
	}
	return self;
}

- (void)createGameOver
{
    gameOverSpr = [CCSprite spriteWithFile:@"gameover.png"];
    [self addChild:gameOverSpr z:3];
    gameOverSpr.position = ccp(-gameOverSpr.boundingBox.size.width, _screenH/2);
    
    // Standard method to create a button
    CCMenuItem *restartMenuItem = [CCMenuItemImage
                                   itemFromNormalImage:@"restart.png" selectedImage:@"restart.png"
                                   target:self selector:@selector(restartButtonTapped)];
    //restartMenuItem.position = ccp(50, 50);
    
    CCMenuItem *menuMenuItem = [CCMenuItemImage
                                itemFromNormalImage:@"to_menu.png" selectedImage:@"to_menu.png"
                                target:self selector:@selector(menuButtonTapped)];
    //menuMenuItem.position = ccp(100, 100);
    starMenu = [CCMenu menuWithItems:restartMenuItem, menuMenuItem, nil];
    [starMenu alignItemsHorizontallyWithPadding:30];
    [gameOverSpr addChild:starMenu];
    starMenu.position = ccp(_screenW/2+110,_screenH/2+130);
    //        starMenu.opacity = 0;
    
    winSpr = [CCSprite spriteWithFile:@"completed.png"];
    [self addChild:winSpr];
    winSpr.position = ccp(-winSpr.boundingBox.size.width, _screenH/2);
    
    for (int i=-1; i<2; ++i) {
        CCSprite *star = [CCSprite spriteWithFile:@"star_empty.png"];
        [winSpr addChild:star];
        
        star.position = ccp(_screenW/2+i*120-30, _screenH/2+80);
        
        [self.stars addObject:star];
    }
    
    // Standard method to create a button
    CCMenuItem *restartMenuItem2 = [CCMenuItemImage
                                   itemFromNormalImage:@"restart.png" selectedImage:@"restart.png"
                                   target:self selector:@selector(restartButtonTapped)];
    //restartMenuItem.position = ccp(50, 50);
    
    CCMenuItem *menuMenuItem2 = [CCMenuItemImage
                                itemFromNormalImage:@"to_menu.png" selectedImage:@"to_menu.png"
                                target:self selector:@selector(menuButtonTapped)];
    //menuMenuItem.position = ccp(100, 100);
    finishMenu = [CCMenu menuWithItems:restartMenuItem2, menuMenuItem2, nil];
    [finishMenu alignItemsHorizontallyWithPadding:30];
    [winSpr addChild:finishMenu];
    finishMenu.position = ccp(_screenW/2-30,_screenH/2-100);
}

- (void)createControls
{
    upSpr = [CCSprite spriteWithFile:@"control_down.png"];
    upSpr.rotation = 180;
    [self addChild:upSpr];
    upSpr.position = ccp(_screenW - 200, 100);
    upSpr.opacity = education ? 0 : 255;
    
    downSpr = [CCSprite spriteWithFile:@"control_down.png"];
    [self addChild:downSpr];
    downSpr.position = ccp(200, 100);
    downSpr.opacity = education ? 0 : 255;
}

- (void)createOxygen
{
    oxygenSpr = [CCSprite spriteWithFile:@"oxygen.png"];
    [self addChild:oxygenSpr];
    oxygenSpr.position = ccp(80, _screenH - 80);
    oxygenSpr.opacity = education ? 0 : 255;
    
    for (int i=0; i<lives; ++i) {
        CCSprite *spr = [CCSprite spriteWithFile:@"oxygen_filled.png"];
        [self addChild:spr];
        spr.position = ccp(i*60 + 170, _screenH - 90);
        
        spr.opacity = education ? 0 : 255;
        
        [self.lifes addObject:spr];
    }
}

- (void)menuButtonTapped
{
    [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInT transitionWithDuration:1.0 scene:[Menu scene]]];
}

- (void)restartButtonTapped
{
    [self unscheduleUpdate];
    
    magnitude = FORCE_MAGNITUDE;
    lives = START_LIVES;
    crashed = NO;
    
    [self endCrashing];
    
    if (gameOver)
        [gameOverSpr runAction:[CCMoveTo actionWithDuration:1.0f position:ccp(-_screenW,_screenH/2)]];
    else if (gameWin)
        [winSpr runAction:[CCMoveTo actionWithDuration:1.0f position:ccp(-_screenW,_screenH/2)]];
    
    gameOver = NO;
    gameWin = NO;
    
    for (int i=0; i<3; ++i) {
        CCSprite *spr = [self.stars objectAtIndex:i];
        CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:@"star_empty.png"];
        [spr setTexture:tex];
    }
    
    for (CCSprite *spr in self.lifes) {
        [spr removeFromParentAndCleanup:YES];
    }
    
    [self.lifes removeAllObjects];
    [self reset];
    [self createOxygen];
    
    [self scheduleUpdate];
}

- (void)prepareAudio
{
    //[[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"hip_hop_bg.mp3"];
}

- (void) dealloc {
	
	self.sky = nil;
	self.terrain = nil;
	self.hero = nil;
//	self.resetButton = nil;

#ifdef DRAW_BOX2D_WORLD

	delete _render;
	_render = NULL;
	
#endif
	
	delete _world;
	_world = NULL;
	
	[super dealloc];
}

#pragma mark touches

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED

- (void) registerWithTouchDispatcher {
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint location = [touch locationInView:[touch view]];
	location = [[CCDirector sharedDirector] convertToGL:location];
	return [self touchBeganAt:location];;
}

- (void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint location = [touch locationInView:[touch view]];
	location = [[CCDirector sharedDirector] convertToGL:location];
	[self touchEndedAt:location];;
}

#else

- (void) registerWithTouchDispatcher {
	[[CCEventDispatcher sharedDispatcher] addMouseDelegate:self priority:0];
}

- (BOOL)ccMouseDown:(NSEvent *)event {
	CGPoint location = [[CCDirector sharedDirector] convertEventToGL:event];
	return [self touchBeganAt:location];
}

- (BOOL)ccMouseUp:(NSEvent *)event {
	CGPoint location = [[CCDirector sharedDirector] convertEventToGL:event];
	return [self touchEndedAt:location];
}

#endif

- (void)onEnter
{
    [super onEnter];
    
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"hip_hop_bg.mp3" loop:YES];
}

- (void)onEnterTransitionDidFinish
{
    [super onEnterTransitionDidFinish];
    
    [_terrain showHelp];
}

-(void)moveSpriteUp:(ccTime) dt {
    
    b2Body *body = self.hero.body;
    
    body->SetActive(true);
    
    b2Vec2 force = b2Vec2((cos(body->GetAngle()-4.7) * magnitude) , (sin(body->GetAngle()-4.7) * magnitude));
    body->ApplyLinearImpulse(force, body->GetPosition());
}

-(void)moveSpriteDown:(ccTime) dt {
    
    b2Body *body = self.hero.body;
    
    body->SetActive(true);

    b2Vec2 force = b2Vec2((cos(body->GetAngle()+4.7) * magnitude) , (sin(body->GetAngle()+4.7) * magnitude));
    body->ApplyLinearImpulse(force, body->GetPosition());
}

- (void)showOxygen
{
    [oxygenSpr runAction:[CCSequence actionOne:[CCFadeIn actionWithDuration:0.25f] two:[CCBlink actionWithDuration:2.0f blinks:10]]];
    
    for (CCSprite *spr in self.lifes) {
        [spr runAction:[CCSequence actionOne:[CCFadeIn actionWithDuration:0.25f] two:[CCBlink actionWithDuration:2.0f blinks:10]]];
    }
}

- (void)showControls
{
    [upSpr runAction:[CCFadeIn actionWithDuration:0.7f]];
    [downSpr runAction:[CCFadeIn actionWithDuration:0.7f]];
}

- (BOOL) touchBeganAt:(CGPoint)location {
//	CGPoint pos = _resetButton.position;
//	CGSize size = _resetButton.contentSize;
//	float padding = 8;
//	float w = size.width+padding*2;
//	float h = size.height+padding*2;
//	CGRect rect = CGRectMake(pos.x-w/2, pos.y-h/2, w, h);
//	if (CGRectContainsPoint(rect, location)) {
//		[self reset];
//	} else {
//		_hero.diving = YES;
//	}
    
    if (education == YES)
    {
        [self showOxygen];
        [_terrain showOxygen];
        
        education = NO;
    }
    else if (education_2 == YES)
    {
        [self showControls];
        [self moveSpriteUp:nil];
        education_2 = NO;
    }
    else
    {
        if (CGRectContainsPoint(downSpr.boundingBox, location))
        {
    //        [self moveSpriteDown:nil];
            //CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:@"star_filled.png"];
            
            downSpr.color = ccc3(224, 102, 54);
            
            [self schedule:@selector(moveSpriteDown:)];
            
            //        NSLog(@"DOWN");
        }
        else if (CGRectContainsPoint(upSpr.boundingBox, location))
        {
            upSpr.color = ccc3(224, 102, 54);
            
            [self schedule:@selector(moveSpriteUp:)];
    //        [self moveSpriteUp:nil];
            //        NSLog(@"UP");
        }
    }
	return YES;
}

- (BOOL) touchEndedAt:(CGPoint)location {
    
    downSpr.color = ccc3(255, 255, 255);
    upSpr.color = ccc3(255, 255, 255);
    
    [self unschedule:@selector(moveSpriteDown:)];
    [self unschedule:@selector(moveSpriteUp:)];
	_hero.diving = NO;
	return YES;
}

#pragma mark methods

- (void) reset {
    [_terrain reset];
    [_hero resetForPos:ccp(5000, _screenH/2)];
}

//- (void)update:(ccTime)dt {
//    
//    float PIXELS_PER_SECOND = 100;
//    static float offset = 0;
//    offset += PIXELS_PER_SECOND * dt;
//    
////    CGSize textureSize = _background.textureRect.size;
////    [_background setTextureRect:CGRectMake(offset, 0, textureSize.width, textureSize.height)];
//    
//    // Add at bottom of update
//    [_terrain setOffsetX:offset];
//    
//}

- (void) update:(ccTime)dt {

	[_hero updatePhysics];
	
	int32 velocityIterations = 8;
	int32 positionIterations = 3;
	_world->Step(dt, velocityIterations, positionIterations);
//	_world->ClearForces();
    
//    for ( b2Body* b = _world->GetBodyList(); b; b = b->GetNext())
//    {
//        if (b->GetUserData() != NULL) {
//            CCSprite *sprite = (CCSprite *)b->GetUserData();
//            
//            CGPoint p;
//            p.x = b->GetPosition().x * [Box2DHelper pointsPerMeter];
//            p.y = b->GetPosition().y * [Box2DHelper pointsPerMeter];
//            
//            sprite.position = p;
//        }
//    }
//
	[_hero updateNode];
    

	// terrain scale and offset
	float height = _hero.position.y;
	const float minHeight = _screenH*4/5;
	if (height < minHeight) {
		height = minHeight;
	}
	float scale = minHeight / height;
	_terrain.scale = scale;
    
    CGFloat dist = [_terrain lastXPosition] - _hero.position.x;
    
    if (dist > _screenW)
        _terrain.offsetX = _hero.position.x;
    else if (dist < 350)
    {
        if (!gameOver && !gameWin)
        {
            [self win];
            NSLog(@"WIN!");
        }
        else if (dist < 100)
        {
            NSLog(@"UNSCHEDULE UPDATE!");
            [self unscheduleUpdate];
        }
    }
    
    if (!education_3)
        magnitude+=0.01;
    
//    NSLog(@"POSITION: %f",_hero.position.x);
    
    if (education_3 && _hero.position.x > 5000)
        education_3 = NO;
    
    //[_terrain updateBodies];

#ifndef DRAW_BOX2D_WORLD
	[_sky setOffsetX:_terrain.offsetX*0.2f];
	[_sky setScale:1.0f-(1.0f-scale)*0.75f];
#endif
}

- (void) createBox2DWorld {
	
	b2Vec2 gravity;
	gravity.Set(3.0f, 0);
	
	_world = new b2World(gravity, false);

//#ifdef DRAW_BOX2D_WORLD
	
//	_render = new GLESDebugDraw([Box2DHelper pointsPerMeter]);
//	_world->SetDebugDraw(_render);
//	
//	uint32 flags = 0;
//	flags += b2Draw::e_shapeBit;
//	flags += b2Draw::e_jointBit;
//	flags += b2Draw::e_aabbBit;
//	flags += b2Draw::e_pairBit;
//	flags += b2Draw::e_centerOfMassBit;
//	_render->SetFlags(flags);
	
//#endif
}

- (void)endCrashing
{
    crashed = NO;
    
    CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:@"bloodcell.png"];
    [_hero.sprite setTexture:tex];
}

- (void)gameOver
{
    gameOver = YES;
    //[self unscheduleUpdate];
    
    [gameOverSpr runAction:[CCMoveTo actionWithDuration:1.0f position:ccp(_screenW/2,_screenH/2)]];
}

- (void)win
{
    gameWin = YES;
    
    [self unscheduleUpdate];
    [winSpr runAction:[CCSequence actionOne:[CCMoveTo actionWithDuration:1.0f position:ccp(_screenW/2,_screenH/2)] two:[CCSequence actions:[CCCallBlock actionWithBlock:^{
            CCSprite *spr = [self.stars objectAtIndex:0];
            CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:@"star_filled.png"];
            [spr setTexture:tex];
    }], [CCDelayTime actionWithDuration:0.3f], [CCCallBlock actionWithBlock:^{
        if (lives > 2)
        {
            CCSprite *spr = [self.stars objectAtIndex:1];
            CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:@"star_filled.png"];
            [spr setTexture:tex];
        }
    }], [CCDelayTime actionWithDuration:0.3f], [CCCallBlock actionWithBlock:^{
        if (lives > 4)
        {
            CCSprite *spr = [self.stars objectAtIndex:2];
            CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:@"star_filled.png"];
            [spr setTexture:tex];
        }
    }], nil]]];
                       
//                       [CCCallBlock actionWithBlock:^{
//        for (int i=0; i<3; ++i) {
//            CCSprite *spr = [self.stars objectAtIndex:i];
//            CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:@"star_filled.png"];
//            [spr setTexture:tex];
//        }
//    }]]];
}

- (void)decreaseLife
{
    if (crashed)
        return;
    
    if (education_3)
        return;
    
    if (gameWin || gameOver)
        return;
    
    crashed = YES;
    
    int a = arc4random()%3 + 1;
    
    [[SimpleAudioEngine sharedEngine] playEffect:[NSString stringWithFormat:@"fish_%d.mp3",a]];
    
    CCTexture2D* tex2 = [[CCTextureCache sharedTextureCache] addImage:@"bloodcell_sad.png"];
    [_hero.sprite setTexture:tex2];
    [[self.hero sprite] runAction:[CCBlink actionWithDuration:2.0f blinks:10]];
    
    lives--;
    if (lives<1)
    {
        if (lives == 0)
        {
            CCSprite *life = [self.lifes objectAtIndex:lives];
            CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:@"oxygen_empty.png"];
            [life setTexture:tex];
        }
        
        if (!gameWin)
        {
            [self gameOver];
            return;
        }
    }
    
    CCSprite *life = [self.lifes objectAtIndex:lives];
    CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:@"oxygen_empty.png"];
    [life setTexture:tex];
    
    [self performSelector:@selector(endCrashing) withObject:nil afterDelay:3.0f];
    //NSLog(@"LIFE -1!");
}

- (void)increaseLife
{
    NSLog(@"LIFE +1!");
}

- (void) showPerfectSlide {
	NSString *str = @"perfect slide";
	CCLabelBMFont *label = [CCLabelBMFont labelWithString:str fntFile:@"good_dog_plain_32.fnt"];
	label.position = ccp(_screenW/2, _screenH/16);
	[label runAction:[CCScaleTo actionWithDuration:1.0f scale:1.2f]];
	[label runAction:[CCSequence actions:
					  [CCFadeOut actionWithDuration:1.0f],
					  [CCCallFuncND actionWithTarget:label selector:@selector(removeFromParentAndCleanup:) data:(void*)YES],
					  nil]];
	[self addChild:label];
}

- (void) showFrenzy {
	NSString *str = @"FRENZY!";
	CCLabelBMFont *label = [CCLabelBMFont labelWithString:str fntFile:@"good_dog_plain_32.fnt"];
	label.position = ccp(_screenW/2, _screenH/16);
	[label runAction:[CCScaleTo actionWithDuration:2.0f scale:1.4f]];
	[label runAction:[CCSequence actions:
					  [CCFadeOut actionWithDuration:2.0f],
					  [CCCallFuncND actionWithTarget:label selector:@selector(removeFromParentAndCleanup:) data:(void*)YES],
					  nil]];
	[self addChild:label];
}

- (void) showHit {
	NSString *str = @"hit";
	CCLabelBMFont *label = [CCLabelBMFont labelWithString:str fntFile:@"good_dog_plain_32.fnt"];
	label.position = ccp(_screenW/2, _screenH/16);
	[label runAction:[CCScaleTo actionWithDuration:1.0f scale:1.2f]];
	[label runAction:[CCSequence actions:
					  [CCFadeOut actionWithDuration:1.0f],
					  [CCCallFuncND actionWithTarget:label selector:@selector(removeFromParentAndCleanup:) data:(void*)YES],
					  nil]];
	[self addChild:label];
}

- (void)fatTouched
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"fish_well.mp3"];
}

@end
