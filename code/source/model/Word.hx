package model;

class Word
{
	public var arabic(default, default):String;
	public var english(default, default):String;
	public var transliteration(default, default):String;

	public function new(arabic:String, english:String, transliteration:String)
	{
		this.arabic = arabic;
		this.english = english;
		this.transliteration = transliteration;
	}
}