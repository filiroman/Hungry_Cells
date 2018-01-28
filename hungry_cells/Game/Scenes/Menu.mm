//  Hungry_Cells
//
//  Created by Roman Filippov on 26/09/15.
//
//

#import "Menu.h"
#import "Level.h"
#import "SimpleAudioEngine.h"

@implementation Menu

+ (CCScene*) scene {
    CCScene *scene = [CCScene node];
    [scene addChild:[Menu node]];
    return scene;
}

- (id) init {
    
    if ((self = [super initWithColor:ccc4(178, 44, 69, 255)])) {
        
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        
        CCLabelTTF *title = [CCLabelTTF labelWithString:@"Hungry Cells" fontName:@"LaoMN-Bold" fontSize:75.0f];
        [self addChild:title];
        title.position = ccp(screenSize.width/2, screenSize.height*3/4-50);
        
        CCLabelTTF *subtitle = [CCLabelTTF labelWithString:@"help red cells to deliver all oxygen" fontName:@"LaoMN" fontSize:35.0f];
        [self addChild:subtitle];
        subtitle.position = ccp(screenSize.width/2, screenSize.height/2+120);
        
        // Standard method to create a button
        CCMenuItem *starMenuItem = [CCMenuItemImage
                                    itemFromNormalImage:@"play_button.png" selectedImage:@"play_button.png"
                                    target:self selector:@selector(starButtonTapped)];
        starMenuItem.position = ccp(screenSize.width/2, screenSize.height/2-120);
        CCMenu *starMenu = [CCMenu menuWithItems:starMenuItem, nil];
        starMenu.position = CGPointZero;
        [self addChild:starMenu];
        
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"fish_1.mp3"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"fish_2.mp3"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"fish_3.mp3"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"fish_well.mp3"];
        
        [[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"main_theme.mp3"];
    }
    
    return self;
}

- (void)onEnter
{
    [super onEnter];
    
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"main_theme.mp3"];
}

//- (void)onExit
//{
//    
//}

- (void)starButtonTapped
{
    [[CCDirector sharedDirector] replaceScene:[Level scene]];
}

@end
