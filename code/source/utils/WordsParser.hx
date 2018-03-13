package utils;

import haxe.Json;
import openfl.Assets;
import model.Word;

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
