package funkin.objects;

typedef CharacterJson =
{
	var icon:String;
	var camOffsets:Array<Int>;
	var charOffsets:Array<Int>;
	var gameOverChar:String;
	var gameOverSuffix:String;
	var isPlayer:Bool;
	var isGF:Bool;
} &
	SpriteJson;

class Character extends FlxSpriteExt
{
	public static var DEFAULT_CHARACTER:CharacterJson = {
		anims: [],
		imagePath: "week1/BOYFRIEND",
		icon: 'bf',
		scale: 1,
		antialiasing: true,
		flipX: false,
		camOffsets: [0, 0],
		charOffsets: [0, 0],
		gameOverChar: 'bf-dead',
		gameOverSuffix: '',
		isPlayer: false,
		isGF: false
	}

	//	Offsets
	public var worldOffsets:FlxPoint;
	public var stageOffsets:FlxPoint;
	public var camOffsets:FlxPoint;
	public var OG_X:Float = 0;
	public var OG_Y:Float = 0;
	public var debugMode:Bool = false;

	//	Display
	public var icon:String = 'face';
	public var iconSpr:HealthIcon = null;
	public var curCharacter:String = 'bf';
	public var isPlayer:Bool = false;
	public var isPlayerJson:Bool = false;
	public var isGF:Bool = false;
	public var gameOverChar:String = 'bf-dead';
	public var gameOverSuffix:String = '';

	//	Gameplay
	public var holdTimer:Float = 0;
	public var stunned:Bool = false;
	public var forceDance:Bool = true;
	public var group:FlxTypedSpriteGroup<Dynamic> = null;

	public static function getCharData(char:String = 'bf'):CharacterJson
	{
		var charJson:CharacterJson = JsonUtil.getJson(char, 'characters');
		charJson = JsonUtil.checkJsonDefaults(DEFAULT_CHARACTER, charJson);
		return charJson;
	}

	public function updatePosition()
	{
		setXY(OG_X, OG_Y);
	}

	public function setX(value:Float = 0):Void
	{
		x = value - worldOffsets.x - stageOffsets.x;
		OG_X = value;
	}

	public function setY(value:Float = 0):Void
	{
		y = value - worldOffsets.y - stageOffsets.y;
		OG_Y = value;
	}

	public function setXY(valueX:Float = 0, valueY:Float = 0):Void
	{
		setX(valueX);
		setY(valueY);
	}

	public function setFlipX(value:Bool):Void
	{
		flippedOffsets = false;
		if (isPlayer != isPlayerJson)
		{
			flipCharOffsets();
		}
		flipX = isPlayer ? !value : value;
	}

	public function loadCharJson(inputJson:CharacterJson):Void
	{
		var imagePath:String = (!inputJson.imagePath.startsWith('characters/')) ? 'characters/${inputJson.imagePath}' : inputJson.imagePath;
		loadImage(imagePath);
		for (anim in inputJson.anims)
		{
			anim = JsonUtil.checkJsonDefaults(JsonUtil.copyJson(FlxSpriteExt.DEFAULT_ANIM), anim);
			addAnim(anim.animName, anim.animFile, anim.framerate, anim.loop, anim.indices, anim.offsets);
		}
	}

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false, ?debugMode:Bool = false, ?inputJson:CharacterJson):Void
	{
		super(x, y);
		worldOffsets = new FlxPoint().set(0, 0);
		stageOffsets = new FlxPoint().set(0, 0);
		camOffsets = new FlxPoint().set(0, 0);
		curCharacter = character;
		antialiasing = true;
		this.isPlayer = isPlayer;
		this.debugMode = debugMode;

		var charJson:CharacterJson = getCharData(curCharacter);
		loadCharJson(charJson);
		worldOffsets.set(charJson.charOffsets[0], charJson.charOffsets[1]);
		camOffsets.set(charJson.camOffsets[0], charJson.camOffsets[1]);
		scale.set(charJson.scale, charJson.scale);
		updateHitbox();
		isPlayerJson = charJson.isPlayer;
		isGF = charJson.isGF;
		gameOverChar = charJson.gameOverChar;
		gameOverSuffix = charJson.gameOverSuffix;
		setFlipX(charJson.flipX);
		setXY(x, y);
		antialiasing = charJson.antialiasing ? Preferences.getPref('antialiasing') : false;
		icon = charJson.icon;
		nullAnimCheck(); //	Find an anim to play to not have null curAnim
	}

	public function nullAnimCheck():Void
	{
		danceCheck();
		if (animation.curAnim == null)
		{
			for (anim => charOffsets in animOffsets)
			{
				playAnim(anim);
			}
		}
	}

	public function flipCharOffsets():Void
	{
		flippedOffsets = true;
		// worldOffsets.x *= -1; IDK
		// stageOffsets.x *= -1;
		camOffsets.x *= -1;
		if (!debugMode)
		{
			switchAnim('danceLeft', 'danceRight');
			switchAnim('singRIGHT', 'singLEFT');
			switchAnim('singRIGHTmiss', 'singLEFTmiss');
		}
	}

	override function update(elapsed:Float):Void
	{
		if (animation.curAnim != null)
		{
			var _curAnim = animation.curAnim;
			if (_curAnim.finished)
			{
				var loopAnim:String = '${_curAnim.name}-loop';
				if (animOffsets.exists(loopAnim))
					playAnim(loopAnim);
			}

			if (_curAnim.name.startsWith('sing') && !specialAnim)
			{
				holdTimer += elapsed;

				var finishAnim:Bool = (Preferences.getPref('botplay') || !isPlayer) ? (holdTimer >= Conductor.crochetMills) : (_curAnim.name.endsWith('miss')
					&& _curAnim.finished && !debugMode);

				if (finishAnim)
				{
					dance();
					holdTimer = 0;
				}
			}
		}

		super.update(elapsed);
	}

	public var _singHoldTimer:Float = 0;
	public var holdFrame:Int = 2;

	public function sing(noteData:Int = 0, altAnim:String = '', hit:Bool = true):Void
	{
		if (hit)
		{
			playAnim('sing${CoolUtil.directionArray[noteData % Conductor.NOTE_DATA_LENGTH]}$altAnim', true);
			_singHoldTimer = 0;
		}
		else
		{
			_singHoldTimer += FlxG.elapsed;
			if (_singHoldTimer >= ((holdFrame / 24) - 0.01) && !specialAnim)
			{
				playAnim('sing${CoolUtil.directionArray[noteData % Conductor.NOTE_DATA_LENGTH]}$altAnim', true);
				_singHoldTimer = 0;
			}
		}
	}

	public function hey():Void
	{
		playAnim(isGF ? 'cheer' : 'hey', true);
		specialAnim = true;
		new FlxTimer().start(Conductor.stepCrochet * 0.001 * Conductor.STEPS_LENGTH, function(tmr:FlxTimer)
		{
			specialAnim = false;
			dance();
		});
	}

	public var danced:Bool = false;

	public function dance():Void
	{
		if (!debugMode && forceDance && !specialAnim)
		{
			danceCheck();
		}
	}

	function danceCheck():Void
	{
		if (animOffsets.exists('danceRight') && animOffsets.exists('danceLeft'))
		{
			danced = !danced;
			playAnim(danced ? 'danceRight' : 'danceLeft');
		}
		else if (animOffsets.exists('idle'))
		{
			playAnim('idle');
		}
	}
}
