package utils;

using haxesharp.collections.Linq;

import helix.data.Config;

import model.GameMode;
import model.Level;
import model.Word;

class LevelMaker
{
    private var LEVEL_TYPES:Array<GameMode> = [GameMode.AskInArabic, GameMode.AskInEnglish, GameMode.Mixed];

    public var words(default, null):Array<Word>;

    public function new() { }

    public function createLevels():Array<Level>
    {
		this.words = WordsParser.getAllWords();
        var newWordsPerLevel = Config.get("newWordsPerLevel");
        var repeatWordsPerLevel = Config.get("repeatWordsPerLevel");
        var wordsPerLevel = newWordsPerLevel + repeatWordsPerLevel;
        
        var numLevels = Std.int(Math.ceil(this.words.length / newWordsPerLevel));
        trace('${this.words.length} words, ${newWordsPerLevel} per level, ${numLevels} levels');

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
            levels.push(new Level(levelWords, levelType, i));
        }

        return levels;
    }    
}