package;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRandom;
import flixel.ui.FlxButton;
import haxe.Json;
using haxesharp.collections.Linq;
import helix.core.HelixState;
import helix.core.HelixSprite;
using helix.core.HelixSpriteFluentApi;
import helix.core.HelixText;
import helix.data.Config;
import openfl.Assets;

class PlayState extends HelixState
{
	private static inline var TARGET_FONT_SIZE = 64;
	private static inline var PADDING:Int = 16;

	private var allWords = new Array<Word>();
	private var targetWord:Word;
	private var random = new FlxRandom();
	private var targetText:HelixText;
	
	override public function create():Void
	{
		super.create();

		new HelixSprite("assets/images/background.png");
		
		var words:Array<Dynamic> = Json.parse(Assets.getText("assets/data/words.json"));

		for (word in words) {
			var w = new Word(word.arabic, word.english);
			this.allWords.push(w);
		}

		this.generateAndShowRound();
		this.targetText = new HelixText(400, PADDING, this.targetWord.arabic, TARGET_FONT_SIZE);				
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	private function generateAndShowRound():Void
	{
		var numWords:Int = Std.int(Config.get("wordsPerRound"));
		var words = this.allWords.shuffle().take(numWords);
		var i:Int = 0;

		this.targetWord = words[0];
		if (this.targetText != null)
		{
			this.targetText.text = targetWord.arabic;
		}

		for (word in words)
		{
			var card = new Card('assets/images/${word.english}.png', 
				word.arabic, word.english, function() {
				if (word == targetWord)
				{
					trace("WIN!");
				}
				else
				{
					trace('NO! You clicked ${word.arabic}, should have clicked ${targetWord.english}!');
				}
			});
			this.add(card);
			card.x = PADDING + (i * card.width) + (i * PADDING);
			card.y = 2 * TARGET_FONT_SIZE;
			i += 1;
		}
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

class Card extends FlxSpriteGroup
{
	private static inline var CARD_WIDTH_TO_FIT:Float = 200;
	private static inline var PADDING:Int = 8;
	public static inline var DEFAULT_FONT_SIZE:Int = 32;
	
	public var cardBase:HelixSprite;
	public var cover:HelixSprite;
	public var image:HelixSprite;
	public var englishText:HelixText;
	public var arabicText:HelixText;

	public function new(imageFile:String, arabic:String, english:String, clickHandler:Void->Void)
	{
		super();

		this.cardBase = new HelixSprite("assets/images/card-base.png");
		this.cardBase.onClick(clickHandler);
		this.add(cardBase);

		this.arabicText = new HelixText(PADDING, PADDING, arabic, DEFAULT_FONT_SIZE);
		arabicText.x += (cardBase.width - arabicText.width)  / 2;
		this.arabicText.alpha = 0;
		this.add(arabicText);		

		this.image = new HelixSprite(imageFile);
		image.move((cardBase.width - image.width) / 2, (cardBase.height - image.height) / 2);
		this.add(image);

		this.englishText = new HelixText(Std.int(PADDING), Std.int(cardBase.height - PADDING), english, DEFAULT_FONT_SIZE);
		englishText.x += (cardBase.width - englishText.width)  / 2;
		englishText.y -= englishText.height;
		this.add(englishText);

		// Last so it goes on top
		this.cover = new HelixSprite("assets/images/card-cover.png");
		cover.alpha = 0;		
		this.add(cover);
	}
}
