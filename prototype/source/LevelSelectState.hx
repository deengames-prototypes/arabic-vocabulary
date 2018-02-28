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

class LevelSelectState extends HelixState
{   
    private var levels:Array<Level>;

	override public function create():Void
	{
		super.create();

        this.levels = new LevelMaker().createLevels();
        
        trace('LEVELS: ${this.levels.length}');
        for (level in this.levels) {
            var english = "[";
            for (word in level.words) {
                english += word.english + ", ";
            }            
            trace('    ${level.levelType}: ${english}]');
        }
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
    private var wordsPerBucket:Int;
    private var numBuckets:Int;

    public function new() { }

    public function createLevels():Array<Level>
    {
        this.LEVEL_TYPES = Config.get("levelTypes");
        
		this.words = WordsParser.getAllWords();
        this.numBuckets = this.countWordBuckets();        
        var numLevels = numBuckets; // Pair of two buckets per level
        var numLevelsPerType = Std.int(numBuckets / LEVEL_TYPES.length); // Round down.

        var levels = new Array<Level>();
        var numBucketsPerLevel = 2;
        var nextBucket:Int = 0;

        for (type in LEVEL_TYPES)
        {
            for (i in 0 ... numLevelsPerType)
            {
                var levelWords = new Array<Word>();
                for (j in 0 ... numBucketsPerLevel)
                {
                    levelWords = levelWords.concat(this.getBucket(nextBucket));
                    nextBucket += 1;
                }

                var level = new Level(levelWords, type);
                levels.push(level);
            }
        }

        return levels;
    }
    
    private function countWordBuckets():Int
    {
        this.wordsPerBucket = Config.get("wordsPerBucket");
        return Math.round(this.words.length / wordsPerBucket);
    }

    private function getBucket(n:Int):Array<Word>
    {
        n = n % this.numBuckets;
        var start = (n * wordsPerBucket) % this.words.length;
        var stop = ((n + 1) * wordsPerBucket) % this.words.length;

        if (start < stop)
        {
            return this.words.slice(start, stop);
        }
        else
        {
            // Wrap
            return this.words.slice(start, this.words.length).concat(this.words.slice(0, stop));
        }
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