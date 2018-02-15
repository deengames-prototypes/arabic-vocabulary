package;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRandom;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import haxe.Json;
using haxesharp.collections.Linq;
import helix.core.HelixState;
import helix.core.HelixSprite;
using helix.core.HelixSpriteFluentApi;
import helix.core.HelixText;
import helix.data.Config;
import openfl.Assets;

class PlayState extends HelixState
{
	private static inline var TARGET_FONT_SIZE = 64;
	private static inline var PADDING:Int = 16;
	private static var STARTING_WORD_FREQUENCY:Int = 0;
	private static var WORD_FREQUENCY_MODIFIER:Int = 0; // +n on wrong, -n on right

	// These two must be the same order
	private var allWords = new Array<Word>();
	private var wordFrequencies = new Array<Float>();

	private var mediator:QuestionAnswerMediator;
	private var gameMode:GameMode;

	private var targetWord:Word;
	private var random = new FlxRandom();
	private var targetText:HelixText;
	
	private var correctSound:FlxSound;
	private var incorrectSound:FlxSound;
	
	private var wordSounds = new Map<String, FlxSound>();

	private var cards = new Array<Card>();

	public function new(mode:GameMode)
	{
		super();
		this.gameMode = mode;
	}

	override public function create():Void
	{
		super.create();

		STARTING_WORD_FREQUENCY = Config.get("startingWordFrequency");
		WORD_FREQUENCY_MODIFIER = Config.get("wordFrequencyModifier");

		this.correctSound = FlxG.sound.load(AssetPaths.correct__ogg);
		this.incorrectSound = FlxG.sound.load(AssetPaths.incorrect__ogg);

		this.mediator = new QuestionAnswerMediator(this.gameMode);
		new HelixSprite("assets/images/background.png");
		
		var words:Array<Dynamic> = Json.parse(Assets.getText("assets/data/words.json"));

		for (word in words) {
			var w = new Word(word.arabic, word.english);

			this.allWords.push(w);
			this.wordFrequencies.push(STARTING_WORD_FREQUENCY);
			
			// Initialize audio sounds
			wordSounds.set('${word.english}-english', FlxG.sound.load('assets/sounds/words/${word.english}-english.ogg'));
			wordSounds.set('${word.english}-arabic', FlxG.sound.load('assets/sounds/words/${word.english}-arabic.ogg'));
		}

		this.generateAndShowRound();

		this.targetText = new HelixText(400, PADDING, this.mediator.getQuestion(this.targetWord), TARGET_FONT_SIZE);
		this.targetText.onClick(function() { this.playCurrentWord(); });

		var backButton = new HelixSprite("assets/images/back-button.png");
		backButton.move(FlxG.width - backButton.width - PADDING, FlxG.height - backButton.height - PADDING);
		backButton.onClick(function() {
			FlxG.switchState(new SelectModeState());
		});
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	private function generateAndShowRound():Void
	{
		var numWords:Int = Std.int(Config.get("wordsPerRound"));
		
		// pick random words based on weight
		var words = new Array<Word>();
		while (words.length < numWords)
		{
			var nextWord = random.getObject(this.allWords, this.wordFrequencies);
			if (words.indexOf(nextWord) == -1) {
				words.push(nextWord);
			}
		}

		var i:Int = 0;

		this.targetWord = random.getObject(words);

		if (this.targetText != null)
		{
			this.targetText.text = this.mediator.getQuestion(targetWord);
		}

		this.playCurrentWord();

		for (word in words)
		{
			var card = new Card('assets/images/${word.english}.png', word, this.gameMode);

			card.onClick(function() {
				var index = this.allWords.indexOf(targetWord);				
				if (word == targetWord)
				{
					// Correct => Arabic => English
					this.correctSound.stop();
					this.correctSound.onComplete = function() {
						// Correct: appear less frequently. The FIRST TIME.
						this.wordFrequencies[index] -= WORD_FREQUENCY_MODIFIER;
						if (this.wordFrequencies[index] < 1) {
							this.wordFrequencies[index] = 1;
						}

						var wordSound = this.wordSounds.get('${targetWord.english}-${this.mediator.questionLanguage}');
						wordSound.onComplete = function() {
							// If the player clicks fast, it'll be the next round and we play
							// the wrong word by msitake.
							if (word == targetWord) {
								this.wordSounds.get('${targetWord.english}-${this.mediator.answerLanguage}').play();
							}
						}
						if (word == targetWord) {
							wordSound.play();
						}
					}
					this.correctSound.play();
					this.tweenCards();
				}
				else
				{
					// Incorrect: target word appears more frequently
					this.wordFrequencies[index] += WORD_FREQUENCY_MODIFIER;
					
					// Word you picked wrongly also appears more frequently
					var wrongWordIndex = this.allWords.indexOf(word);
					this.wordFrequencies[wrongWordIndex] += WORD_FREQUENCY_MODIFIER;
					
					this.incorrectSound.stop();

					this.incorrectSound.onComplete = function() {
						this.wordSounds.get('${word.english}-${this.mediator.questionLanguage}').play();
					};

					this.incorrectSound.play();					
					this.fadeCardIntoOblivion(card);
				}
			});

			this.add(card);
			card.x = PADDING + (i * card.width) + (i * PADDING);
			card.y = 2 * TARGET_FONT_SIZE;
			i += 1;

			this.cards.push(card);
		}
	}

	private function tweenCards():Void
	{
		var rightCard = this.cards.single((c) => c.word == this.targetWord);
		for (card in this.cards)
		{
			if (card == rightCard)
			{
				FlxTween.tween(card, { x: (FlxG.width - card.width) / 2,
					y: (FlxG.height - card.height) / 2 }, 1);

				card.cardBase.onClick(function() {
					card.destroy();
					this.cards.remove(card);
					this.generateAndShowRound();
				});
			}
			else
			{
				this.fadeCardIntoOblivion(card);
			}
		}
	}

	private function fadeCardIntoOblivion(card:Card):Void
	{
		FlxTween.tween(card, { alpha: 0 }, 1, { onComplete: function(tween) { 
			this.cards.remove(card);
			card.destroy();
		}});
	}

	private function playCurrentWord():Void
	{
		var sound = this.wordSounds.get('${this.targetWord.english}-${this.mediator.questionLanguage}');
		sound.stop();
		sound.play();
	}
}

class Word
{
	public var arabic(default, default):String;
	public var english(default, default):String;

	public function new(arabic:String, english:String)
	{
		this.arabic = arabic;
		this.english = english;
	}
}

// Class that takes a game mode and returns a question/answer.
// I.e. chooses between Arabic and English for you.
class QuestionAnswerMediator
{
	public var mode(default, null):GameMode;
	public var questionLanguage(get, null):String;
	public var answerLanguage(get, null):String;

	public function new(mode:GameMode)
	{
		this.mode =  mode;
	}

	public function getQuestion(word:Word):String
	{
		return this.mode == GameMode.AskInArabic ? word.arabic : word.english;
	}

	public function getAnswer(word:Word):String
	{
		return this.mode == GameMode.AskInArabic ? word.english : word.arabic;
	}
	
	public function get_questionLanguage():String
	{
		return this.mode == GameMode.AskInArabic ? "arabic" : "english";
	}

	public function get_answerLanguage():String
	{
		return this.mode == GameMode.AskInArabic ? "english" : "arabic";
	}
}

class Card extends FlxSpriteGroup
{
	private static inline var CARD_WIDTH_TO_FIT:Float = 200;
	private static inline var PADDING:Int = 8;
	private static inline var DEFAULT_FONT_SIZE:Int = 32;
	
	public var cardBase:HelixSprite;
	public var cover:HelixSprite;
	public var image:HelixSprite;
	public var englishText:HelixText;
	public var arabicText:HelixText;
	public var word:Word;
	private var clickable:Bool = true;

	public function new(imageFile:String, word:Word, mode:GameMode)
	{
		super();

		this.word = word;
		this.cardBase = new HelixSprite("assets/images/card-base.png");		
		this.add(cardBase);

		this.arabicText = new HelixText(PADDING, PADDING, word.arabic, DEFAULT_FONT_SIZE);
		arabicText.x += (cardBase.width - arabicText.width)  / 2;
		this.arabicText.alpha = mode == GameMode.AskInArabic ? 0 : 1;
		this.add(arabicText);		

		this.image = new HelixSprite(imageFile);
		image.move((cardBase.width - image.width) / 2, (cardBase.height - image.height) / 2);
		this.add(image);

		this.englishText = new HelixText(Std.int(PADDING), Std.int(cardBase.height - PADDING), word.english, DEFAULT_FONT_SIZE);
		englishText.x += (cardBase.width - englishText.width)  / 2;
		englishText.y -= englishText.height;
		this.englishText.alpha = mode == GameMode.AskInArabic ? 1 : 0;
		this.add(englishText);
	}

	public function onClick(callback:Void->Void):Void
	{
		this.cardBase.onClick(function() {
			if (this.clickable) {
				this.clickable = false;
				callback();
			}
		});
	}
}