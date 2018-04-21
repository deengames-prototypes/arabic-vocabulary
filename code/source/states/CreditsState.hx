package states;

import flixel.FlxG;
import helix.core.HelixSprite;
using helix.core.HelixSpriteFluentApi;
import helix.core.HelixState;
import helix.core.HelixText;

class CreditsState extends HelixState
{
    private static inline var FONT_SIZE:Int = 48;
    private static inline var DETAILS_FONT_SIZE:Int = 24;
    private static inline var PADDING:Int = 8;

    override public function create():Void
    {
        super.create();

        var credits = new HelixText(0, 0, "Credits", FONT_SIZE);
        credits.x = (FlxG.width - credits.width) / 2;
        credits.y = PADDING;

        var detailsText = new HelixText(0, 0, "", DETAILS_FONT_SIZE);
        detailsText.y = FlxG.height - detailsText.height - PADDING;

        var images = ["book", "fire", "grapes", "hear", "heart", "people", "sun", "water"];
        // 10x6
        var perRow:Int = 10;
        var perColumn:Int = 6;

        var idealWidth:Int = Math.round(FlxG.width / perRow);
        var idealHeight:Int = Math.round(FlxG.height / perRow);
        var i:Int = 0;
        var random = new flixel.math.FlxRandom();

        for (y in 0 ... perColumn) {
            for (x in 0 ... perRow) {
                var sprite = new HelixSprite('assets/images/words/${images[i % images.length]}.png');
                if (idealWidth < idealHeight) {
                    sprite.setGraphicSize(idealWidth, 0);
                } else {
                    sprite.setGraphicSize(0, idealHeight);
                }

                sprite.updateHitbox();
                sprite.move(x * idealWidth + PADDING, y * (sprite.height + PADDING) + credits.height + (2 * PADDING));
                sprite.onClick(function() {
                    var n = random.int(0, 100);
                    detailsText.text = this.createLink('Image ${n}', "Unknown", 'https://random.iconfinder.com/derekrs/m${n}.png');
                    detailsText.x = (FlxG.width - detailsText.width) / 2;
                });
                i += 1;
            }
        }
    }

    private function createLink(title:String, author:String, url:String):String
    {
        return '${title} by ${author} (${url})';
    }
}