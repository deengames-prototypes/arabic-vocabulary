package states;

import flixel.FlxG;
import flixel.tweens.FlxTween;

import helix.core.HelixSprite;
using helix.core.HelixSpriteFluentApi;
import helix.core.HelixState;
import helix.core.HelixText;
using haxesharp.collections.Linq;

import model.Level;
import model.GameMode;
import utils.SaveManager;
import utils.LevelMaker;
import view.Gem;
import view.LevelButton;
import view.TutorialWindow;

class LevelSelectState extends HelixState
{   
    private static inline var Y_PADDING = 50;
    private static inline var PADDING:Int = 16;
    private static inline var NUM_COLUMNS:Int = 3;
    private static inline var FONT_SIZE:Int = 32;
    private static inline var GEM_SPEED:Int = 300;
    private static inline var FADE_IN_TIME:Int = 1;
    
    private var showAnimation:Bool = false;
    private var gemsText:HelixText;
    private var levelSelectText:HelixText;
    private var levels:Array<Level>;
    private var buttons:Array<LevelButton>;
    private var masjid:HelixSprite;

    private var currentGems:Int = 0;
    private var totalGems:Int = 0;

    public function new(showAnimation:Bool = false) {
        super();
        this.showAnimation = showAnimation;
    }

	override public function create():Void
	{
		super.create();

        var levelMaker = new LevelMaker();
        this.levels = levelMaker.createLevels();
        var levelReached = SaveManager.getMaxLevelReached();
        levelReached = 11;
        
        this.buttons = this.createButtons(this.levels, levelReached);
        this.addMasjidAndGauge(buttons);

        var gemsPerLevel = PlayState.NUM_GEMS_TO_WIN;
        this.currentGems = levelReached * gemsPerLevel;
        this.totalGems = this.levels.length * gemsPerLevel;
        this.gemsText = new HelixText(0, Std.int(PADDING / 2), "50/100 gems", FONT_SIZE);
        this.gemsText.x = Std.int(this.masjid.x + (this.masjid.width - this.gemsText.width) / 2);

        this.levelSelectText = new HelixText(PADDING, Std.int(this.gemsText.y), "Select a Level", FONT_SIZE);

        if (this.showAnimation) {
            this.hideUi();
            // Pretend we have one level less in gems because the animation will
            // show and increment/update this value.
            this.currentGems -= gemsPerLevel; 
            this.showGemAnimation();
        }

        this.updateGemsText();

        if (!SaveManager.getShownStoryPanel()) {
            SaveManager.showedStoryPanel();
            var tutorial = new TutorialWindow("Monsters took the last mushaf from the masjid, plunging it into darkness!
                Go and recover gems from the Qur'an and recover them to bring the masjid back to light!",
                "assets/images/tutorials/monster-with-gem.png");
            tutorial.x = (FlxG.width - tutorial.width) / 2;
            tutorial.y = (FlxG.height - tutorial.height) / 2;
        }

        if (levelReached > this.levels.length) {
            
            var allInOneData = new Level(levelMaker.words, GameMode.Mixed, this.levels.length + 1);

            if (!SaveManager.getShownGameCompletionPanel()) {
                SaveManager.showedGameCompletionPanel();
                var tutorial = new TutorialWindow("You found all the gems and saved the day! The masjid is back to normal! Alhamdulillah!\n\nAs a special reward, you've unlocked the All-in-One level, which combines the challenge of all the previous levels, combined.",
                    "assets/images/ui/gems-completion.png");

                tutorial.x = (FlxG.width - tutorial.width) / 2;
                tutorial.y = (FlxG.height - tutorial.height) / 2;
            }
        }
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

    private function createButtons(levels:Array<Level>, maxLevelReached:Int):Array<LevelButton>
    {
        var levelsPerRow = Std.int(Math.ceil(levels.length / NUM_COLUMNS)); // three types of levels
        var buttons = new Array<LevelButton>();

        for (levelNum in 0 ... levels.length)
        {
            var level = levels[levelNum];
            var isEnabled = maxLevelReached >= levelNum;

            var button = new LevelButton(levelNum, level, isEnabled);
            button.move(
                PADDING + (levelNum % levelsPerRow) * (PADDING + button.width),
                Y_PADDING + PADDING + Std.int(levelNum / levelsPerRow) * (PADDING + button.height));
            buttons.add(button);
        }

        return buttons;
    }

    private function addMasjidAndGauge(buttons:Array<LevelButton>):Void
    {
        var maxX:Float = 0;
        for (button in buttons) {
            if (button.x + button.width > maxX) {
                maxX = button.x + button.width;
            }
        }
        
        // Center horizontally in available space
        this.masjid = new HelixSprite("assets/images/masjid-large.png");
        var freeSpace = FlxG.width - maxX - masjid.width - (2 * PADDING);
        masjid.move(maxX + PADDING + (freeSpace / 2), Y_PADDING + PADDING);
    }

    private function showGemAnimation():Void
    {
        for (i in 0 ... PlayState.NUM_GEMS_TO_WIN) {
            var gem = new Gem(i + 1);
            gem.showAsGem();

            // Off-screen bottom-left
            gem.x = -(gem.width + PADDING) * (i + 1);
            gem.y = (FlxG.height - gem.height) / 2;
            // Stop here (centered under the masjid)
            var stopX = masjid.x + ((masjid.width - gem.width) / 2);
            // Move up here (centered in the masjid)
            var absorbtionY = 3/4 * (masjid.height - gem.height) + masjid.y;
            
            FlxTween.linearMotion(gem, gem.x, gem.y, stopX, gem.y, GEM_SPEED, false, {
                onComplete: function(tween:FlxTween):Void {                        
                    gem.destroy();
                    this.currentGems += 1;
                    this.updateGemsText();

                    if (this.currentGems == SaveManager.getMaxLevelReached() * PlayState.NUM_GEMS_TO_WIN) {
                        // Final gem is down
                        this.fadeInUi();
                    }
                }
            });
        }
    }

    private function updateGemsText():Void
    {
        this.gemsText.text = '${currentGems}/${totalGems} gems';
    }

    private function hideUi():Void
    {
        for (button in this.buttons) {
            button.alpha = 0;
        }
        
        this.levelSelectText.alpha = 0;
    }

    private function fadeInUi():Void
    {
        for (button in this.buttons) {
            FlxTween.tween(button, { alpha: 1 }, FADE_IN_TIME);
        }
        
        FlxTween.tween(this.levelSelectText, { alpha: 1 }, FADE_IN_TIME);
    }
}