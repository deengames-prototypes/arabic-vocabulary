package;

import haxe.Json;
import openfl.Assets;

class WordsParser
{
    public static function getAllWords():Array<Word>
    {
        var words:Array<Dynamic> = Json.parse(Assets.getText("assets/data/words.json"));
        var toReturn = new Array<Word>();

		for (word in words)
        {
			var w = new Word(word.arabic, word.english);
			toReturn.push(w);
		}

        return toReturn;
    }
}

class Word
{
	public var arabic(default, default):String;
	public var english(default, default):String;

	public function new(arabic:String, english:String)
	{
		this.arabic = arabic;
		this.english = english;
	}
}