package model;

import model.GameMode;
import model.Word;

class Level
{
    public var words(default, null):Array<Word>;
    public var levelType(default, null):GameMode; 
    public var number(default, null):Int; // 0-based index

    public function new(words:Array<Word>, levelType:GameMode, number:Int)
    {
        this.words = words;
        this.levelType = levelType;
        this.number = number;
    }
}