package view;

import haxesharp.exceptions.Exception;
import helix.core.HelixSprite;

/**
 *  A gem with states. Like, seriously.
 *  First state: shows as a placeholder
 *  Second state: shows the actual gem
 *  Third state: dancing in a wave motion
 */
class Gem extends HelixSprite {

	public static inline var VICTORY_GEM_FADE_TIME_SECONDS = 1;
	private static inline var OFFSET_PER_GEM:Float = 0.5; // radians?
	private static inline var WAVE_AMPLITUDE:Int = 100;
	private static inline var DANCE_SPEED_MULTIPLIER:Int = 2;

	public var baseY(null, default):Int = 0;
	private var num:Int = 0;
	private var image:String = "";
	private var fadingToWhite:Bool = false;
	private var totalElapsedTime:Float = 0;
	private var dancing:Bool = false;
	private var victoryDanceOffset:Float = 0;

	public function new(num:Int) {
		if (num <= 0) {
			throw new Exception("Gem number must be a positive integer");
		}

		this.image = 'assets/images/gems/gem-${num}.png';
		super(image);
		this.num = num;
		this.victoryDanceOffset = num * OFFSET_PER_GEM;
	}

	public function showAsPlaceholder() {
		this.loadGraphic("assets/images/gems/gem-placeholder.png");
		this.alpha = 0.5;
	}

	public function showAsGem() {
		this.loadGraphic(image);
		this.alpha = 1;
	}

	public function dance():Void
	{
		this.dancing = true;
	}

	public function fadeToWhite():Void
	{
		this.fadingToWhite = true;
	}

	override public function update(elapsedSeconds:Float):Void
	{
		super.update(elapsedSeconds);
 		this.totalElapsedTime += elapsedSeconds;

		if (this.dancing) {
			var offset = -Math.cos(2 * totalElapsedTime + this.victoryDanceOffset) * WAVE_AMPLITUDE;
			this.y = this.baseY - WAVE_AMPLITUDE + offset;
		}

		if (this.fadingToWhite) {
			totalElapsedTime += elapsedSeconds;

			// elapsedSeconds / victory time => percent we should show
			// multiply by 255 because 100% = 255
			var rgbOffset:Int = Std.int(this.totalElapsedTime / VICTORY_GEM_FADE_TIME_SECONDS * 255);
			rgbOffset = Std.int(Math.min(rgbOffset, 255));

			trace('time=${this.totalElapsedTime}, v=1, rgb=${rgbOffset}');

			this.setColorTransform(1, 1, 1, 1, rgbOffset, rgbOffset, rgbOffset, 0);
		}
	}
}