package view;

import flixel.group.FlxSpriteGroup;
import helix.core.HelixSprite;
using helix.core.HelixSpriteFluentApi;
import helix.core.HelixText;
import helix.data.Config;
import model.GameMode;
import model.Word;

class Card extends FlxSpriteGroup
{
	private static inline var CARD_WIDTH_TO_FIT:Float = 200;
	private static inline var PADDING:Int = 8;
	private static inline var DEFAULT_FONT_SIZE:Int = 32;
	
	public var cardBase:HelixSprite;
	public var cover:HelixSprite;
	public var image:HelixSprite;
	public var englishText:HelixText;
	public var arabicText:Dynamic;
	public var word:Word;
	private var clickable:Bool = true;

	public function new(imageFile:String, word:Word, mode:GameMode)
	{
		super();

		this.word = word;
		this.cardBase = new HelixSprite("assets/images/ui/card-base.png");		
		this.add(cardBase);

		if (Config.get("arabicTextIsImages") == true) {
			this.arabicText = new HelixSprite('assets/images/text/${word.transliteration}.png');
			this.arabicText.setGraphicSize(this.arabicText.width / 2, 0); // scale down to 50%
		} else {
			this.arabicText = new HelixText(PADDING, PADDING, word.arabic, DEFAULT_FONT_SIZE);
		}

		arabicText.x += (cardBase.width - arabicText.width)  / 2;
		this.arabicText.alpha = mode == GameMode.AskInArabic ? 0 : 1;
		this.add(arabicText);		

		this.image = new HelixSprite(imageFile);
		image.move((cardBase.width - image.width) / 2, (cardBase.height - image.height) / 2);
		this.add(image);

		this.englishText = new HelixText(Std.int(PADDING), Std.int(cardBase.height - PADDING), word.english, DEFAULT_FONT_SIZE);
		englishText.x += (cardBase.width - englishText.width)  / 2;
		englishText.y -= englishText.height;
		this.englishText.alpha = mode == GameMode.AskInArabic ? 1 : 0;
		this.add(englishText);
	}

	public function onClick(callback:Void->Void):Void
	{
		this.cardBase.onClick(function() {
			if (this.clickable) {
				this.clickable = false;
				callback();
			}
		});
	}

	public function disable() {
		this.cardBase.onClick(function() { });
	}
}