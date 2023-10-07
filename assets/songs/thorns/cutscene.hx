function createPost() {
    if (GameVars.isStoryMode && !GameVars.seenCutscene)
        PlayState.inCutscene = true;
}

function startCutscene() {
    var red:FlxSprite = new FlxSprite(-400, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
    add(red);

    var senpaiEvil:FunkinSprite = new FunkinSprite('weeb/senpaiCrazy', [0,0], [0,0]);
    senpaiEvil.addAnim('preCutscene', 'Senpai Pre Explosion instance 1', 24, false, [0]);
    senpaiEvil.addAnim('cutscene', 'Senpai Pre Explosion instance 1');
    senpaiEvil.playAnim('preCutscene');
    senpaiEvil.setScale(6, false);
    senpaiEvil.screenCenter();
    senpaiEvil.x += 50;
    senpaiEvil.alpha = 0;
    add(senpaiEvil);

    PlayState.camHUD.visible = false;

    new FlxTimer().start(0.3, function(swagTimer:FlxTimer) {
        senpaiEvil.alpha += 0.15;
        if (senpaiEvil.alpha < 1)   swagTimer.reset();
        else {
            senpaiEvil.playAnim('cutscene');
            FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function() {
                senpaiEvil.destroy();
                red.destroy();
                PlayState.camGame.fade(FlxColor.WHITE, 0.01, true, function() {
                    PlayState.camHUD.visible = true;
                    PlayState.createDialogue();
                }, true);
            });
            new FlxTimer().start(3.2, function(deadTime:FlxTimer) {
                PlayState.camGame.fade(FlxColor.WHITE, 1.6, false);
            });
        }
    });
}

var bgFade:FlxSprite;
var dialogueBox:PixelDialogueBox;
var face:FunkinSprite;
var inDialogue:Bool = false;

function createDialogue() {
    bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), FlxColor.fromRGB(25,0,5));
    bgFade.scrollFactor.set();
    bgFade.alpha = 0;
    add(bgFade);

    face = new FunkinSprite('weeb/spiritFaceForward', [320, 170]);
    face.setScale(6, false);
    face.cameras = [PlayState.camHUD];
    add(face);

    initShader('thornsBg', 'faceShader');
    setShaderInt('faceShader', 'effectType', 1);
    setShaderFloat('faceShader', 'uFrequency', 10);
    setSpriteShader(face, 'faceShader');

    dialogueBox = new PixelDialogueBox('evil');
    dialogueBox.cameras = [PlayState.camHUD];

    var handPos = dialogueBox.handSelect.getPosition();
    dialogueBox.handSelect = new FunkinSprite('skins/pixel/evil_hand', [handPos.x,handPos.y], [0,0]);
    dialogueBox.handSelect.addAnim('enter', 'nextLine', 12);
    dialogueBox.handSelect.addAnim('load', 'waitLine', 12, true);
    dialogueBox.handSelect.addAnim('click', 'clickLine', 12);
    dialogueBox.handSelect.setScale(6 * 0.9);
    dialogueBox.handSelect.playAnim('load');
    dialogueBox.add(dialogueBox.handSelect);

    dialogueBox.bgFade.visible = false;
    dialogueBox.portraitLeft.alpha = 0;
    dialogueBox.swagDialogue.color = FlxColor.WHITE;
    dialogueBox.swagDialogue.borderColor = FlxColor.TRANSPARENT;

    PlayState.dialogueBox = dialogueBox;
    add(dialogueBox);
    inDialogue = true;
}

var timeElapsed:Float = 0;
function updatePost(elapsed) {
    if (dialogueBox != null && inDialogue) {
        face.alpha = dialogueBox.box.alpha;
        timeElapsed += elapsed;
        face.offset.y = FlxMath.roundDecimal(Math.sin(timeElapsed), 1) * 10;
        setShaderFloat('faceShader', 'iTime', timeElapsed);
        bgFade.alpha = dialogueBox.bgFade.alpha;
    }
}

function startCountdown() {
    if (GameVars.isStoryMode && inDialogue) {
        inDialogue = false;
        face.destroy();
        bgFade.destroy();
    }
}