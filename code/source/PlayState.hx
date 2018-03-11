package;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using haxesharp.collections.Linq;
import helix.core.HelixState;
import helix.core.HelixSprite;
using helix.core.HelixSpriteFluentApi;
import helix.core.HelixText;
import helix.data.Config;

import LevelPersister;
import LevelSelectState; // Level
import WordsParser;

class PlayState extends HelixState
{
	public static inline var NUM_GEMS_TO_WIN:Int = 10;
	private static inline var TARGET_FONT_SIZE = 64;
	private static inline var PADDING:Int = 16;

	private static var STARTING_WORD_FREQUENCY:Int = 0;
	private static var WORD_FREQUENCY_MODIFIER:Int = 0; // +n on wrong, -n on right

	// These two must be the same order
	private var levelWords = new Array<Word>();
	private var wordFrequencies = new Array<Float>();

	private var mediator:QuestionAnswerMediator;
	private var gameMode:GameMode;
	private var levelNumber:Int = 0;

	private var targetWord:Word;
	private var random = new FlxRandom();
	private var targetText:HelixText;
	private var wordsSelectedCorrectly = new Array<Word>();
	
	private var correctSound:FlxSound;
	private var incorrectSound:FlxSound;
	
	private var wordSounds = new Map<String, FlxSound>();

	private var cards = new Array<Card>();
	private var gems = new Array<Gem>();
	private var backButton:HelixSprite;

	public function new(level:Level)
	{
		super();
		this.gameMode = level.levelType;
		this.levelWords = level.words;
		this.levelNumber = level.number;
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
		
		for (word in levelWords)
		{
			this.wordFrequencies.push(STARTING_WORD_FREQUENCY);
			
			// Initialize audio sounds
			wordSounds.set('${word.english}-english', FlxG.sound.load('assets/sounds/words/${word.english}-english.ogg'));
			wordSounds.set('${word.english}-arabic', FlxG.sound.load('assets/sounds/words/${word.english}-arabic.ogg'));
		}

		this.generateAndShowRound();

		this.targetText = new HelixText(400, PADDING, this.mediator.getQuestion(this.targetWord), TARGET_FONT_SIZE);
		this.targetText.onClick(function() { this.playCurrentWord(); });

		this.backButton = new HelixSprite("assets/images/back-button.png");
		backButton.move(FlxG.width - backButton.width - PADDING, PADDING);
		backButton.onClick(function() {
			FlxG.switchState(new LevelSelectState());
		});

		for (i in 0 ... NUM_GEMS_TO_WIN) {
			var gem = new Gem(i + 1);
			var gemY = Std.int(FlxG.height - gem.height - PADDING);
			gem.baseY = gemY;
			gem.move(i * (gem.width + PADDING), gemY);
			this.gems.add(gem);
			gem.showAsPlaceholder();
		}
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
			var nextWord = random.getObject(this.levelWords, this.wordFrequencies);
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
			var card = new Card('assets/images/words/${word.english}.png', word, this.gameMode);

			card.onClick(function() {
				var index = this.levelWords.indexOf(targetWord);				
				if (word == targetWord)
				{
					// Correct => Arabic => English
					this.correctSound.stop();
					this.correctSound.onComplete = function() {
						
						// Correct: appear less frequently. Only for the first time the
						// user click the card (when presented with several options), not
						// on the second click (to clear the right answer).
						//
						// The second click handler is defined in tweenCards.
						this.wordFrequencies[index] -= WORD_FREQUENCY_MODIFIER;
						if (this.wordFrequencies[index] < 1) {
							this.wordFrequencies[index] = 1;
						}

						var wordSound = this.wordSounds.get('${targetWord.english}-${this.mediator.questionLanguage}');
						wordSound.onComplete = function() {
							// If the player clicks fast, it'll be the next round and we play
							// the wrong word by mistake.
							if (word == targetWord) {
								var sound = this.wordSounds.get('${targetWord.english}-${this.mediator.answerLanguage}');
								sound.play();
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
					var wrongWordIndex = this.levelWords.indexOf(word);
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
		for (card in this.cards)
		{
			if (card.word == this.targetWord)
			{
				FlxTween.tween(card, { x: (FlxG.width - card.width) / 2,
					y: (FlxG.height - card.height) / 2 }, 1);

				card.cardBase.onClick(function() {
					card.destroy();
					this.cards.remove(card);

					if (!this.wordsSelectedCorrectly.contains(this.targetWord))
					{
						// Highlight gem
						var index = this.wordsSelectedCorrectly.length;
						var gem = this.gems[index];
						gem.showAsGem();

						this.wordsSelectedCorrectly.push(this.targetWord);

						// Debug
						trace('Correct:${this.wordsSelectedCorrectly.map(function(w) { return w.english; } )}');

						if (this.wordsSelectedCorrectly.length == this.levelWords.length)
						{
							this.targetText.text = "YOU WIN!";
							LevelPersister.setMaxLevelReached(this.levelNumber + 1);
							this.showLevelCompleteAnimation();
						} else {
							this.fadeCardIntoOblivion(card);
							this.generateAndShowRound();
						}
					} else {
						this.fadeCardIntoOblivion(card);
						this.generateAndShowRound();
					}
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

	private function showLevelCompleteAnimation():Void
	{
		// First, move all gems to center screen and fade to white
		var firstGem = this.gems[0];
		var centerY = (FlxG.height - firstGem.height) / 2;

		for (gem in gems) {
			gem.dance();
		}

		FlxTween.tween(this.backButton, {
			x: (FlxG.width - this.backButton.width) / 2,
			y: (FlxG.height - this.backButton.height) / 3
		}, Gem.VICTORY_GEM_FADE_TIME_SECONDS);
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
	// private var fadingToWhite:Bool = false;
	private var totalElapsedTime:Float = 0;
	private var dancing:Bool = false;
	private var victoryDanceOffset:Float = 0;

	public function new(num:Int) {
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

	override public function update(elapsedSeconds:Float):Void
	{
		super.update(elapsedSeconds);
 		this.totalElapsedTime += elapsedSeconds;

		if (this.dancing) {
			var offset = -Math.cos(2 * totalElapsedTime + this.victoryDanceOffset) * WAVE_AMPLITUDE;
			this.y = this.baseY - WAVE_AMPLITUDE + offset;
		}

	// 	if (this.fadingToWhite) {
	// 		totalElapsedTime += elapsedSeconds;

	// 		// elapsedSeconds / victory time => percent we should show
	// 		// multiply by 255 because 100% = 255
	// 		var rgbOffset:Int = Std.int(this.totalElapsedTime / VICTORY_GEM_FADE_TIME_SECONDS * 255);
	// 		rgbOffset = Std.int(Math.min(rgbOffset, 255));

	// 		trace('time=${this.totalElapsedTime}, v=1, rgb=${rgbOffset}');

	// 		this.setColorTransform(1, 1, 1, 1,
	// 			rgbOffset, rgbOffset, rgbOffset, 0);
	// 	}
	}
}