//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//

#import "Level.h"
#import "Menu.h"
#import "Sublevel.h"
#import "SimpleAudioEngine.h"

@implementation Level

+ (CCScene*) scene {
    CCScene *scene = [CCScene node];
    [scene addChild:[Level node]];
    return scene;
}

- (id) init {
    
    if ((self = [super init])) {
        
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        
        CCSprite *bg = [CCSprite spriteWithFile:@"levelBG.png"];
        [self addChild:bg];
        bg.position = ccp(screenSize.width/2, screenSize.height/2);
        
        // Standard method to create a button
        CCMenuItem *starMenuItem = [CCMenuItemImage
                                    itemFromNormalImage:@"hamburger.png" selectedImage:@"hamburger.png"
                                    target:self selector:@selector(starButtonTapped)];
        starMenuItem.position = ccp(screenSize.width/2-1, screenSize.height/2+328);
        
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
    [[CCDirector sharedDirector] replaceScene:[Menu scene]];
}

- (void)starButtonTapped
{
    [[CCDirector sharedDirector] replaceScene:[Sublevel scene]];
}

@end
