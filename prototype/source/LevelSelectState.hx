package;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRandom;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import haxe.Json;
using haxesharp.collections.Linq;
import helix.core.HelixState;
import helix.core.HelixSprite;
using helix.core.HelixSpriteFluentApi;
import helix.core.HelixText;
import helix.data.Config;
import openfl.Assets;

import WordsParser;
using haxesharp.collections.Linq;

class LevelSelectState extends HelixState
{   
    private var levels:Array<Level>;

	override public function create():Void
	{
		super.create();

        this.levels = new LevelMaker().createLevels();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}

class LevelMaker
{
    private var LEVEL_TYPES:Array<String>; // ask Arabic, ask English, both

    private var words:Array<Word>;

    public function new() { }

    public function createLevels():Array<Level>
    {
        this.LEVEL_TYPES = Config.get("levelTypes");
        
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
    public var levelType(default, null):String; // TODO: enum

    public function new(words:Array<Word>, levelType:String)
    {
        this.words = words;
        this.levelType = levelType;
    }
}