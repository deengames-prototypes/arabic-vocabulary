package utils;

import flixel.util.FlxSave;

class SaveManager
{
    private static inline var SAVE_SLOT:String = "Save0";

    public static function getMaxLevelReached():Int
    {
        var save = SaveManager.getSave();
        if (save.data.maxLevelReached == null)
        {
            save.data.maxLevelReached = 0;
            save.flush();
        }

        return save.data.maxLevelReached;
    }

    public static function setMaxLevelReached(level:Int):Void
    {
        var save = SaveManager.getSave();
        var currentMax = SaveManager.getMaxLevelReached();
        if (level > currentMax)
        {
            save.data.maxLevelReached = level;
            save.flush();
        }
    }

    public static function getShownStoryPanel():Bool {
        var save = SaveManager.getSave();
        var value:Any = save.data.shownStoryPanel;
        return value == true;
    }

    public static function showedStoryPanel():Void
    {
        var save = SaveManager.getSave();
        save.data.shownStoryPanel = true;
        save.flush();
    }
    
    public static function getShownGameCompletionPanel():Bool {
        var save = SaveManager.getSave();
        var value:Any = save.data.shownGameCompletionPanel;
        return value == true;
    }

    public static function showedGameCompletionPanel():Void {
        var save = SaveManager.getSave();
        save.data.shownGameCompletionPanel = true;
        save.flush();
    }

    public static function getShownEnglishLevelTutorial():Bool {
        var save = SaveManager.getSave();
        var value:Any = save.data.shownEnglishLevelTutorial;
        return value == true;
    }

    public static function showedEnglishLevelTutorial():Void {
        var save = SaveManager.getSave();
        save.data.shownEnglishLevelTutorial = true;
        save.flush();
    }

    public static function getShownArabicLevelTutorial():Bool {
        var save = SaveManager.getSave();
        var value:Any = save.data.shownArabicLevelTutorial;
        return value == true;
    }

    public static function showedArabicLevelTutorial():Void {
        var save = SaveManager.getSave();
        save.data.shownArabicLevelTutorial = true;
        save.flush();
    }

        public static function getShownMixedLevelTutorial():Bool {
        var save = SaveManager.getSave();
        var value:Any = save.data.shownMixedLevelTutorial;
        return value == true;
    }

    public static function showedMixedLevelTutorial():Void {
        var save = SaveManager.getSave();
        save.data.shownMixedLevelTutorial = true;
        save.flush();
    }

    private static function getSave():FlxSave
    {
        var save = new FlxSave();
        save.bind(SAVE_SLOT);
        return save;
    }
}