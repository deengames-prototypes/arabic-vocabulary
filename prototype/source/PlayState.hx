package;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRandom;
import flixel.ui.FlxButton;
import haxe.Json;
import helix.core.HelixState;
import helix.core.HelixSprite;
using helix.core.HelixSpriteFluentApi;
import helix.core.HelixText;
import helix.data.Config;
import openfl.Assets;

class PlayState extends HelixState
{
	private var allWords = new Array<Word>();
	private var random = new FlxRandom();
	
	override public function create():Void
	{
		super.create();
		var words:Array<Dynamic> = Json.parse(Assets.getText("assets/data/words.json"));

		for (word in words) {
			var w = new Word(word.arabic, word.english);
			this.allWords.push(w);
		}

		var card = random.getObject(this.allWords);
		this.add(new Card('assets/images/${card.english}.png', card.arabic, card.english, 100, 50));
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
	private static inline var DEFAULT_FONT_SIZE:Int = 32;

	public function new(imageFile:String, arabic:String, english:String, x:Int, y:Int)
	{
		super();
		
		var cardBase = new HelixSprite("assets/images/card-base.png");
		cardBase.move(x, y);
		this.add(cardBase);

		var arabicText = new HelixText(x + PADDING, y + PADDING, arabic, DEFAULT_FONT_SIZE);
		arabicText.x += (cardBase.width - arabicText.width)  / 2;
		this.add(arabicText);

		var image = new HelixSprite(imageFile);
		image.move(x + (cardBase.width - image.width) / 2, y + (cardBase.height - image.height) / 2);
		this.add(image);

		var englishText = new HelixText(Std.int(x + PADDING), Std.int(y + cardBase.height - PADDING), english, DEFAULT_FONT_SIZE);
		englishText.x += (cardBase.width - englishText.width)  / 2;
		englishText.y -= englishText.height;
		this.add(englishText);
	}
}
