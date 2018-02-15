package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;

import helix.core.HelixState;
import helix.core.HelixText;

import GameMode;

class SelectModeState extends HelixState
{
	private static inline var FONT_SIZE:Int = 32;
	private static inline var PADDING:Int = 16;

	override public function create():Void
	{
		super.create();

		var askArabicText = new HelixText(PADDING, PADDING, "Ask me Arabic", FONT_SIZE);
		askArabicText.onClick(function() {
			FlxG.switchState(new PlayState(GameMode.AskInArabic));
		});

		var askEnglishText = new HelixText(Std.int(FlxG.width - askArabicText.width - PADDING), PADDING,  "Ask me English", FONT_SIZE);
		askEnglishText.onClick(function() {
			FlxG.switchState(new PlayState(GameMode.AskInEnglish));
		});


	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}
