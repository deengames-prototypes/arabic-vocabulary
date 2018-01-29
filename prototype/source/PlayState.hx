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
	override public function create():Void
	{
		super.create();
		var words:Array<Dynamic> = Json.parse(Assets.getText("assets/data/json.txt"));
		for (word in words) {
			//trace("Word=" + word);
			trace('Arabic=${word.arabic}, English=${word.english}');
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}
