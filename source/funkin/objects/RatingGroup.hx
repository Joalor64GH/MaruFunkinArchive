package funkin.objects;

class RatingGroup extends FlxTypedSpriteGroup<Dynamic> {
    public var targetSpr:FlxObject = null;
    var _offset:FlxPoint;

    public function new(?targetSpr:FlxSprite):Void {
        super();
        this.targetSpr = targetSpr;
        _offset = new FlxPoint();
        if (targetSpr is FlxSprite)
            _offset.set(targetSpr.frameWidth * targetSpr.scale.x, targetSpr.frameHeight * targetSpr.scale.y);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        if (targetSpr != null) {
            setPosition(targetSpr.x - _offset.x * 0.5, targetSpr.y - _offset.y * 0.5);
        }
    }

    public function drawCombo(combo:Int):Void {
        if (combo < 10) return;

        if (!Preferences.getPref('vanilla-ui')) {
            var comboSpr:ComboRating = recycle(ComboRating);
            comboSpr.init();
            addTop(comboSpr);
        }

        var numSplit:Array<String> = Std.string(combo).split('');
        numSplit.reverse();

        for (i in 0...numSplit.length) {
            var num:NumRating = recycle(NumRating);
            num.init(numSplit[i], i);
            addTop(num);
        }
    }

    public function drawJudgement(judgement:String):Void {
        var judgeSpr:JudgeRating = recycle(JudgeRating);
        judgeSpr.init(judgement);
        addTop(judgeSpr);
    }

    public function drawComplete(judgement:String, combo:Int) {
        drawJudgement(judgement);
        drawCombo(combo);
    }

    function addTop(spr:Dynamic) {
        add(spr);
        remove(spr, true);
        insert(members.length, spr);
    }
}

class JudgeRating extends RemoveRating {
    public static var judgeRatings:Array<String> =  ['shit', 'bad', 'good', 'sick'];
    var animated:Bool = true;
    public function new() {
        super();
        for (i in judgeRatings) {
            if (Paths.exists(Paths.image('skins/${SkinUtil.curSkin}/ratings/$i', null, true), IMAGE)) {
                animated = false; // Backwards compatibility ???
                break;
            }
        }

        if (animated) {
            var imagePath = 'skins/${SkinUtil.curSkin}/ratings/ratings';
            loadImage(imagePath);
            var _length = CoolUtil.returnJudgements.length + 1;
            loadImageAnimated(imagePath, Std.int(width / _length), Std.int(height));
            for (i in 0..._length) animation.add(judgeRatings[i], [i], 1);
        }
    }

    public function init(judgement:String) {
        setPosition();
        animated ? animation.play(judgement, true) : loadImage('skins/${SkinUtil.curSkin}/ratings/$judgement');
        updateHitbox();
        start(Conductor.crochet * 0.001, Conductor.stepCrochet * 0.025);
        jump();
    }
}

class ComboRating extends RemoveRating {
    public function new() {
        super();
        loadImage('skins/${SkinUtil.curSkin}/ratings/combo');
    }

    public function init() {
        setPosition(50, 100);
        updateHitbox();
        start(Conductor.crochet * 0.001 * 2, Conductor.stepCrochet * 0.025);
        jump(0.8);
    }
}

class NumRating extends RemoveRating {
    public function new() {
        super();
        var imagePath = 'skins/${SkinUtil.curSkin}/ratings/nums';
        loadImage(imagePath);
        loadImageAnimated(imagePath, Std.int(width / 10), Std.int(height));
        for (i in 0...10) animation.add(Std.string(i), [i], 1);
        setScale(scale.x * 1.2);
    }

    public function init(num:Dynamic, id:Int = 0) {
        setPosition(0, 100);
        animation.play(Std.string(num), true);
        updateHitbox();
        start(Conductor.crochet * 0.001 * 2, Conductor.stepCrochet * 0.025);
        jump(0.8);
        offset.x = width * id;
    }
}

class RemoveRating extends FlxSpriteExt {
    public var lifeTime:Float = 1;
    public var alphaSpeed:Float = 1;
    public function new() {
        super();
        _dynamic.update = function (elapsed:Float) {
            if (lifeTime > 0) lifeTime -= elapsed; 
            else if (alive) {
                if (alpha > 0)  alpha -= elapsed * alphaSpeed;
                else            kill();
            }
        }

        var skinData = SkinUtil.getSkinData(SkinUtil.curSkin);
        setScale(skinData.scale);
        antialiasing = skinData.antialiasing ? Preferences.getPref('antialiasing') : false;
    }

    public function start(lifeTime:Float = 1, alphaSpeed:Float = 1) {
        this.lifeTime = lifeTime;
        this.alphaSpeed = alphaSpeed;
        alpha = 1;
    }

    public function jump(randomness:Float = 1) {
        acceleration.y = FlxG.random.float(200 * randomness, 300 * randomness);
        velocity.y = FlxG.random.float(-140 * randomness, -160 * randomness);
        velocity.x = FlxG.random.float(-5 * randomness, 5 * randomness);
    }
}