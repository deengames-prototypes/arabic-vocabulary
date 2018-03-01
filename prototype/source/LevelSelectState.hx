package;

import helix.core.HelixSprite;
using helix.core.HelixSpriteFluentApi;
import helix.core.HelixState;
import helix.core.HelixText;
import helix.data.Config;
using haxesharp.collections.Linq;
import flixel.FlxG;
import flixel.util.FlxSave;

import GameMode;
import WordsParser;
import Map;

class LevelSelectState extends HelixState
{   
    private static inline var SAVE_SLOT:String = "DebugSave";
    private static inline var PADDING:Int = 16;

    private var levels:Array<Level>;

	override public function create():Void
	{
		super.create();

        this.levels = new LevelMaker().createLevels();
        var levelReached = this.getMaxLevelReached();
        this.createButtons(this.levels, levelReached);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

    private function getMaxLevelReached():Int
    {
        var save = new FlxSave();
        save.bind(SAVE_SLOT);
        if (save.data.maxLevelReached == null)
        {
            save.data.maxLevelReached = 0;
            save.flush();
        }

        return save.data.maxLevelReached;
    }

    private function createButtons(levels:Array<Level>, maxLevelReached:Int):Void
    {
        for (levelNum in 0 ... levels.length)
        {
            var level = levels[levelNum];
            var isEnabled = maxLevelReached >= levelNum;

            var button = new LevelButton(levelNum, level, isEnabled);
            button.move(
                PADDING + (levelNum % 3) * (PADDING + button.width),
                PADDING + Std.int(levelNum / 3) * (PADDING + button.height));
        }
    }
}

class LevelButton extends HelixSprite
{
    private static inline var FONT_SIZE:Int = 32;

    private static var LEVEL_MODE_IMAGES:Map<GameMode, String> = [
        GameMode.AskInArabic => "words-button-1",
        GameMode.AskInEnglish => "words-button-2",
        GameMode.Mixed => "words-button-3",
    ];

    private var text:HelixText;

    public function new(levelNum:Int, level:Level, isEnabled:Bool)
    {
        var suffix = isEnabled ? "" : "-disabled";
        super('assets/images/${LEVEL_MODE_IMAGES[level.levelType]}${suffix}.png');
        this.text = new HelixText(0, 0, '${levelNum + 1}', FONT_SIZE);
        this.onClick(function() {
            FlxG.switchState(new PlayState(level.levelType, level.words));
        });
    }

    public function move(x, y):Void
    {
        this.x = x; 
        this.y = y;
        this.text.x = Std.int(this.x + (this.width / 2));
        this.text.y = Std.int(this.y + (this.height / 2));
    }
}

class LevelMaker
{
    private var LEVEL_TYPES:Array<GameMode> = [GameMode.AskInArabic, GameMode.AskInEnglish, GameMode.Mixed];

    private var words:Array<Word>;

    public function new() { }

    public function createLevels():Array<Level>
    {
		this.words = WordsParser.getAllWords();
        var newWordsPerLevel = Config.get("newWordsPerLevel");
        var repeatWordsPerLevel = Config.get("repeatWordsPerLevel");
        var wordsPerLevel = newWordsPerLevel + repeatWordsPerLevel;
        var numLevels = Std.int(Math.ceil(this.words.length / newWordsPerLevel));

        var levels = new Array<Level>();

        for (i in 0 ... numLevels)
        {
            var start = i * newWordsPerLevel;
            var stop = (i + 1) * newWordsPerLevel;
            
            var levelWords = this.words.slice(start, stop);
            var oldWords = new Array<Word>();

            if (i == 0)
            {
                // First level. Just pick the words with index > start sequentially.
                oldWords = this.words.slice(stop, stop + repeatWordsPerLevel);
            }
            else
            {
                // If it's the last level, maybe we didn't get enough words. Take more.
                if (levelWords.length < stop - start)
                {
                    var delta = (stop - start - levelWords.length);
                    repeatWordsPerLevel += delta;
                }

                // Not the first level
                // Randomly pick from words with index < start
                oldWords = this.words.slice(0, start).shuffle().take(repeatWordsPerLevel);
            }

            levelWords = levelWords.concat(oldWords);
            // map [0..10] to [0..3]
            var index = Std.int(i * this.LEVEL_TYPES.length / numLevels);
            var levelType = this.LEVEL_TYPES[index];
            levels.push(new Level(levelWords, levelType));
        }

        return levels;
    }    
}

class Level
{
    public var words(default, null):Array<Word>;
    public var levelType(default, null):GameMode; // TODO: enum

    public function new(words:Array<Word>, levelType:GameMode)
    {
        this.words = words;
        this.levelType = levelType;
    }
}