package view;

import flixel.FlxG;

import helix.core.HelixSprite;
using helix.core.HelixSpriteFluentApi;
import helix.core.HelixText;

import model.GameMode;
import model.Level;
import states.PlayState;

class LevelButton extends HelixSprite
{
    private static inline var FONT_SIZE:Int = 32;

    private static var LEVEL_MODE_IMAGES:Map<GameMode, String> = [
        GameMode.AskInArabic => "words-button-1",
        GameMode.AskInEnglish => "words-button-2",
        GameMode.Mixed => "words-button-3",
    ];

    private var text:HelixText;

    public function new(label:String, level:Level, isEnabled:Bool, overrideImage:String = "")
    {
        var suffix = isEnabled ? "" : "-disabled";
        var imageName = '${LEVEL_MODE_IMAGES[level.levelType]}${suffix}.png';

        if (overrideImage != "") {
            imageName = overrideImage;
        }

        super('assets/images/ui/${imageName}');
        this.text = new HelixText(0, 0, label, FONT_SIZE);
        if (isEnabled) {
            this.onClick(function() {
                FlxG.switchState(new PlayState(level));
            });
        }
    }

    public function move(x, y):Void
    {
        this.x = x; 
        this.y = y;
        this.text.x = Std.int(this.x + (this.width - this.text.width) / 2);
        this.text.y = Std.int(this.y + (this.height - this.text.height) / 2);
    }

    override public function set_alpha(alpha:Float):Float
    {
        var toReturn = super.set_alpha(alpha);
        this.text.alpha = alpha;
        return toReturn;
    }
}