package;

import flixel.FlxG;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import haxe.Json;
import helix.core.HelixState;
import helix.core.HelixSprite;
import helix.core.HelixText;
import helix.data.Config;
import openfl.Assets;

class PlayState extends HelixState
{
	private var allWords = new Array<Word>();

	override public function create():Void
	{
		super.create();
		var words:Array<Dynamic> = Json.parse(Assets.getText("assets/data/words.json"));
		for (word in words) {
			var w = new Word(word.arabic, word.english);
			this.allWords.push(w);
			trace(w.english);
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
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
