package view;

import helix.core.HelixSprite;
import view.TutorialWindow;

class VictoryTutorialWindow extends TutorialWindow {

    private static inline var BANNER_PADDING:Int = 24;

    private var topBanner:HelixSprite;
    private var bottomBanner:HelixSprite;

    public function new(width:Int, height:Int, text:String) {
        super(width, height, text);

        topBanner = new HelixSprite("assets/images/ui/gems-completion.png");
        bottomBanner = new HelixSprite("assets/images/ui/gems-completion.png");
        bottomBanner.flipX = true;
    }

    override public function set_x(x:Float):Float {
        var toReturn = super.set_x(x);
        if (topBanner != null) {
            topBanner.x = x + (this.width - topBanner.width) / 2;
        }
        if (bottomBanner != null) {
            bottomBanner.x = x + (this.width - topBanner.width) / 2;
        }
        return toReturn;
    }

    override public function set_y(y:Float):Float {
        var toReturn = super.set_y(y);
        if (this.textField != null) {
            this.textField.y += (2 * BANNER_PADDING);
            if (topBanner != null) {
                this.textField.y += topBanner.height;
            }
        }
        if (topBanner != null) {
            topBanner.y = y + BANNER_PADDING;
        }
        if (bottomBanner != null) {
            bottomBanner.y = y + this.height - BANNER_PADDING - bottomBanner.height;
        }
        return toReturn;
    }

    override public function destroy():Void {
        this.topBanner.destroy();
        this.bottomBanner.destroy();
        super.destroy();        
    }
}