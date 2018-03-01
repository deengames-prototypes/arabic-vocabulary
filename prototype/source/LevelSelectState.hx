package;

import helix.core.HelixState;
import helix.data.Config;
using haxesharp.collections.Linq;
import flixel.util.FlxSave;

import GameMode;
import WordsParser;

class LevelSelectState extends HelixState
{   
    private var SAVE_SLOT:String = "DebugSave";
    private var levels:Array<Level>;

	override public function create():Void
	{
		super.create();

        this.levels = new LevelMaker().createLevels();
        var levelReached = this.getMaxLevelReached();
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
            trace("New: old was " + save.data.maxLevelReached);
            save.data.maxLevelReached = 1;
            save.flush();
        }

        trace('returning ${save.data.maxLevelReached}');
        return save.data.maxLevelReached;
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