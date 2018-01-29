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

class Card extends FlxGroup
{
	private static inline var PADDING:Int = 8;
	
	public function new(imageFile:String, arabic:String, english:String, x:Int, y:Int)
	{
		var image = new HelixSprite(imageFile).move(x, y);
		this.add(image);

		var arabicText = new HelixText(x + PADDING, y + PADDING, arabic);
		this.add(arabicText);
		var englishText = new HelixText(x + PADDING, y + image.height - PADDING, english);
		this.add(englishText);
	}
}
