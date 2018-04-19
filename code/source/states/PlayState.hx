package states;

import flixel.FlxG;
import flixel.math.FlxRandom;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;

using haxesharp.collections.Linq;
import helix.core.HelixState;
import helix.core.HelixSprite;
using helix.core.HelixSpriteFluentApi;
import helix.core.HelixText;
import helix.data.Config;
import helix.GameTime;

import model.GameMode;
import model.Level;
import model.Word;
import utils.SaveManager;
import view.Card;
import view.Gem;
import view.TutorialWindow;

class PlayState extends HelixState
{
	public static inline var NUM_GEMS_TO_WIN:Int = 10;
	private static inline var TARGET_FONT_SIZE = 64;
	private static inline var PADDING:Int = 16;

	private static var STARTING_WORD_FREQUENCY:Int = 0;
	private static var WORD_FREQUENCY_MODIFIER:Int = 0; // +n on wrong, -n on right

	private static var TUTORIAL_ARROW_AMPLITUDE:Int = 25;
	private static var TUTORIAL_ARROW_SPEED_MULTIPLIER:Int = 4;
	private static inline var TUTORIAL_WINDOW_WIDTH:Int = 400;
    private static inline var TUTORIAL_WINDOW_HEIGHT:Int = 200;

	// These two must be the same order
	private var levelWords = new Array<Word>();
	private var wordFrequencies = new Array<Float>();

	private var mediator:QuestionAnswerMediator;
	private var gameMode:GameMode;
	private var levelNumber:Int = 0;

	private var targetWord:Word;
	private var random = new FlxRandom();
	private var targetText:Dynamic;
	private var wordsSelectedCorrectly = new Array<Word>();
	private var tutorialArrow:HelixSprite; // tutorial arrow
	private var tutorialArrowBaseX:Float = 0;
	
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

		new HelixSprite("assets/images/backgrounds/cave.png");

		STARTING_WORD_FREQUENCY = Config.get("startingWordFrequency");
		WORD_FREQUENCY_MODIFIER = Config.get("wordFrequencyModifier");

		this.correctSound = FlxG.sound.load(AssetPaths.correct__ogg);
		this.incorrectSound = FlxG.sound.load(AssetPaths.incorrect__ogg);

		this.mediator = new QuestionAnswerMediator(this.gameMode);
		
		for (word in levelWords)
		{
			this.wordFrequencies.push(STARTING_WORD_FREQUENCY);
			
			// Initialize audio sounds
			wordSounds.set('${word.english}-english', FlxG.sound.load('assets/sounds/words/${word.english}-english.ogg'));
			wordSounds.set('${word.english}-arabic', FlxG.sound.load('assets/sounds/words/${word.english}-arabic.ogg'));
		}

		this.generateAndShowRound();

		this.regenerateTargetText();
		
		var monsterNum = 3;

		if (this.gameMode == GameMode.AskInArabic) {
			monsterNum = 1;
		} else if (this.gameMode == GameMode.AskInEnglish) {
			monsterNum = 2;
		} else if (this.gameMode == GameMode.Mixed) {
			monsterNum = 3;
		}

		var monster = new HelixSprite('assets/images/monster-${monsterNum}.png');
		monster.move(this.targetText.x - monster.width - PADDING, this.targetText.y);
		monster.onClick(function() { this.playCurrentWord(); });

		this.backButton = new HelixSprite("assets/images/ui/back-button.png");
		backButton.move(FlxG.width - backButton.width - PADDING, PADDING);
		backButton.onClick(function() {
			FlxG.switchState(new LevelSelectState(false));
		});

		for (i in 0 ... NUM_GEMS_TO_WIN) {
			var gem = new Gem(i + 1);
			var gemY = Std.int(FlxG.height - gem.height - PADDING);
			gem.baseY = gemY;
			gem.move(i * (gem.width + PADDING), gemY);
			this.gems.add(gem);
			gem.showAsPlaceholder();
		}

		if (this.gameMode == GameMode.AskInArabic && !SaveManager.getShownEnglishLevelTutorial()) {
			this.showTutorialArrow();
			new TutorialWindow(TUTORIAL_WINDOW_WIDTH, TUTORIAL_WINDOW_HEIGHT, "Pick the card that matches the monsters' Arabic word to save the gems!");
			SaveManager.showedEnglishLevelTutorial();
		} else if (this.gameMode == GameMode.AskInEnglish && !SaveManager.getShownEnglishLevelTutorial()) {
			this.showTutorialArrow();
			new TutorialWindow(TUTORIAL_WINDOW_WIDTH, TUTORIAL_WINDOW_HEIGHT, "The monsters switched to English! Pick the card that matches the monsters' English word to save the gems!");
			SaveManager.showedArabicLevelTutorial();
		} else if (this.gameMode == GameMode.Mixed && !SaveManager.getShownMixedLevelTutorial()) {
			this.showTutorialArrow();
			new TutorialWindow(TUTORIAL_WINDOW_WIDTH, TUTORIAL_WINDOW_HEIGHT, "The monsters are switching between Arabic and English! Pick the matching card to save the gems!");
			SaveManager.showedMixedLevelTutorial();
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (this.tutorialArrow != null) {
			this.tutorialArrow.x  = this.tutorialArrowBaseX + 
				(TUTORIAL_ARROW_AMPLITUDE * Math.cos(TUTORIAL_ARROW_SPEED_MULTIPLIER * GameTime.totalElapsedSeconds));
		}
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
			this.regenerateTargetText();
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

							// Update only if we played a new level
							if (SaveManager.getMaxLevelReached() < this.levelNumber + 1) {
								SaveManager.setMaxLevelReached(this.levelNumber + 1);

								this.backButton.onClick(function() {
									FlxG.switchState(new LevelSelectState(true));
								});
							}

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
				card.disable();
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

	private function showTutorialArrow():Void {
		this.tutorialArrow = new HelixSprite("assets/images/ui/left-arrow.png");
		this.tutorialArrowBaseX = this.targetText.x + this.targetText.width + PADDING + TUTORIAL_ARROW_AMPLITUDE;
		this.tutorialArrow.y = this.targetText.y;
	}

	private function regenerateTargetText():Void {
		if (this.targetText != null) {
			remove(this.targetText);
			this.targetText.destroy();
		}

		trace('Regenerating; game mode is ${this.gameMode} and question language is ${this.mediator.questionLanguage}... question is ${this.mediator.getQuestion(this.targetWord)}');
		if (Config.get("arabicTextIsImages") == true && 
			// Game mode is Arabic, OR (game mode is mixed and question language is Arabic)
			(this.gameMode == GameMode.AskInArabic || 
				(this.gameMode == GameMode.Mixed && this.mediator.questionLanguage == "arabic")
			)) {
			this.targetText = new HelixSprite('assets/images/text/${this.targetWord.transliteration}.png');			
		} else {
			this.targetText = new HelixText(0, 0, this.mediator.getQuestion(this.targetWord), TARGET_FONT_SIZE);
		}

		this.targetText.x = 400;
		this.targetText.y = PADDING;
		this.targetText.onClick(function() { this.playCurrentWord(); });
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
