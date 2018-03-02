package;

import flixel.util.FlxSave;

class LevelPersister
{
    private static inline var SAVE_SLOT:String = "DebugSave";

    public static function getMaxLevelReached():Int
    {
        var save = LevelPersister.getSave();
        if (save.data.maxLevelReached == null)
        {
            save.data.maxLevelReached = 0;
            save.flush();
        }

        return save.data.maxLevelReached;
    }

    public static function setMaxLevelReached(level:Int):Void
    {
        var save = LevelPersister.getSave();
        var currentMax = LevelPersister.getMaxLevelReached();
        if (level > currentMax)
        {
            save.data.maxLevelReached = level;
            save.flush();
        }
    }

    private static function getSave():FlxSave
    {
        var save = new FlxSave();
        save.bind(SAVE_SLOT);
        return save;
    }
}