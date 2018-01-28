//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//

#import "Sublevel.h"
#import "SimpleAudioEngine.h"
#import "Game.h"
#import "Level.h"

@implementation Sublevel

+ (CCScene*) scene {
    CCScene *scene = [CCScene node];
    [scene addChild:[Sublevel node]];
    return scene;
}

- (id) init {
    
    if ((self = [super init])) {
        
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        
        CCSprite *bg = [CCSprite spriteWithFile:@"sublevel.png"];
        [self addChild:bg];
        bg.position = ccp(screenSize.width/2, screenSize.height/2);
        
        // Standard method to create a button
        CCMenuItem *starMenuItem = [CCMenuItemImage
                                    itemFromNormalImage:@"level_1.png" selectedImage:@"level_1.png"
                                    target:self selector:@selector(starButtonTapped)];
        starMenuItem.position = ccp(screenSize.width/3 - 50, screenSize.height/2-37);
        
        CCMenuItem *backMenuItem = [CCMenuItemImage
                                    itemFromNormalImage:@"back_arrow.png" selectedImage:@"back_arrow.png"
                                    target:self selector:@selector(backButtonTapped)];
        backMenuItem.position = ccp(100, 100);
        
        CCMenu *starMenu = [CCMenu menuWithItems:starMenuItem, backMenuItem, nil];
        starMenu.position = CGPointZero;
        [self addChild:starMenu];
        
    }
    return self;
    
}

- (void)backButtonTapped
{
    [[CCDirector sharedDirector] replaceScene:[Level scene]];
}

- (void)starButtonTapped
{
    [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionMoveInB transitionWithDuration:0.7f scene:[Game scene]]];
}

@end
