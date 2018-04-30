package;

import openfl.Lib;
import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, states.LevelSelectState, 1, 60, 60, true));
	}
}
