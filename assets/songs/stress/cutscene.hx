var cutsceneTankman_Body:FunkinSprite;
var cutsceneTankman_Head:FunkinSprite;
var gfFaceplant:Bool = false;

// Cutscene stuff
var demonGf:FunkinSprite;
var john:FunkinSprite;
var steve:FunkinSprite;
var demonBg:FlxSprite;
var beef:FlxSpriteExt;
var geef:FunkinSprite;

var loadedCutsceneAssets:Bool = false;

function create() {
    if (GameVars.isStoryMode && !GameVars.seenCutscene) {
        PlayState.inCutscene = true;
        var censored:Bool = !getPref('naughty');
        var censorStr:String = censored ? '-censor' : '';

        cutsceneTankman_Body = new FunkinSprite('tankmanCutscene_body', [PlayState.dad.x, PlayState.dad.y + 155], [1,1]);
        cutsceneTankman_Body.addAnim('godEffingDamnIt', 'body/BODY_3_10');
        cutsceneTankman_Body.addAnim('lookWhoItIs', 'body/BODY_3_20');
        cutsceneTankman_Body.addOffset('godEffingDamnIt', 95, 160);
        cutsceneTankman_Body.addOffset('lookWhoItIs', 5, 32);

        cutsceneTankman_Head = new FunkinSprite('tankmanCutscene_head', [PlayState.dad.x + 60, PlayState.dad.y - 10], [1,1]);
        cutsceneTankman_Head.addAnim('godEffingDamnIt', 'HEAD_3_10');
        cutsceneTankman_Head.addAnim('lookWhoItIs', 'HEAD_3_20');
        cutsceneTankman_Head.addOffset('godEffingDamnIt', 30, 25);
        cutsceneTankman_Head.addOffset('lookWhoItIs', 15, 15);

        demonGf = new FunkinSprite('cutscenes/demon_gf' + censorStr, [PlayState.gf.x - 920, PlayState.gf.y - 454], [0.95, 0.95]);
        demonGf.addAnim('demonGf', 'DEMON_GF');
        demonGf.addAnim('dancing', 'GF Dancing at Gunpoint', 24, true);
        demonGf.addOffset('dancing', -738, -464);
        if (censored) {
            demonGf.addOffset('demonGf', -152, 0);
        }
        john = new FunkinSprite('cutscenes/john' + censorStr, [PlayState.gf.x + 398, PlayState.gf.y - 45], [0.95, 0.95]);
        john.addAnim('john', 'JOHN');
        steve = new FunkinSprite('cutscenes/steve' + censorStr, [PlayState.gf.x - 887.5, PlayState.gf.y - 345], [0.95, 0.95]);
        steve.addAnim('steve', 'STEVE');

        PlayState.dad.visible = PlayState.gf.visible = false;
        PlayState.dadGroup.add(cutsceneTankman_Body);
        PlayState.dadGroup.add(cutsceneTankman_Head);

        add(john);
        add(steve);
        PlayState.gfGroup.add(demonGf);

        john.visible = steve.visible = false;
        demonGf.playAnim('dancing');

        loadedCutsceneAssets = true;

        initShader('demon_blur', 'demon_blur');
        setShaderFloat('demon_blur', 'u_size', 0);
        setShaderFloat('demon_blur', 'u_alpha', 0);

        gfFaceplant = FlxG.random.bool(10);
        if (gfFaceplant) {
            geef = new FunkinSprite("cutscenes/faceplantGf", [600,500], [1.1,1.1]);
            geef.addAnim('faceplant', 'girlfriend face plant');
            geef.visible = false;
            addSpr(geef, 'gfFaceplant', true);
        } else {
            PlayState.boyfriend.visible = false;
            beef = new FlxSpriteExt(PlayState.boyfriend.x, PlayState.boyfriend.y).loadImage('cutscenes/beef');
            PlayState.boyfriendGroup.add(beef);
        }
    } else {
        closeScript();
    }
}

function createPost() {
    if (gfFaceplant) {
        removeScript('_charScript_bf');
        PlayState.switchChar('bf', 'bf'); // make sure its not bf holding gf
        PlayState.boyfriend.iconSpr.staticSize = 1;
        PlayState.objMap.get('gfIcon').alpha = 0;
    }
}

function startCutscene() {
    PlayState.showUI(false);
    var stressCutscene:FlxSound = getSound(getPref('naughty') ? 'stressCutscene' : 'song3censor');
    FlxG.sound.list.add(stressCutscene);

    demonBg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 4, FlxG.height * 4, FlxColor.BLACK);
    demonBg.scrollFactor.set();
    demonBg.alpha = 0;
    addSpr(demonBg, 'demonBg');

    PlayState.camFollow.x = PlayState.dad.x + 400;
    PlayState.camFollow.y = PlayState.dad.y + 170;
    FlxTween.tween(PlayState.camGame, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});

    var manager = makeCutsceneManager();

    manager.pushEvent(0.1, function () { // God effing damn it
        cutsceneTankman_Body.playAnim('godEffingDamnIt', true);
        cutsceneTankman_Head.playAnim('godEffingDamnIt', true);
        manager.setSound(stressCutscene);
    });

    manager.pushEvent(15.2, function () { // Zoom to gf
        demonGf.playAnim('demonGf');
        FlxTween.tween(PlayState.camFollow, {x: 700, y: 300}, 1, {ease: FlxEase.sineOut});
        FlxTween.tween(PlayState.camGame, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});
        FlxTween.tween(demonBg, {alpha: 0.9}, 2.25, {ease: FlxEase.quadOut});
        setCameraShader(PlayState.camGame, 'demon_blur');
    });

    manager.pushEvent(17.5, function () { // Pico appears
        demonBg.alpha = 0;
        PlayState.camGame.setFilters([]);
        zoomBack();
    });

    manager.pushEvent(19.5, function () { // Look who it is
        cutsceneTankman_Body.playAnim('lookWhoItIs', true);
        cutsceneTankman_Head.playAnim('lookWhoItIs', true);
        cutsceneTankman_Head.visible = true;
    });

    manager.pushEvent(20, function () { // Focus to tankman
        PlayState.camFollow.setPosition(PlayState.dad.x + 500, PlayState.dad.y + 170);
    });

    manager.pushEvent(21, function () { // Small anticipation
        PlayState.gf.dance();
    });

    manager.pushEvent(21.5, function () { // Little friend
        PlayState.gf.playAnim('shoot1-loop');
    });

    manager.pushEvent(31.2, function () { // Little cunt
        PlayState.camFollow.setPosition(PlayState.boyfriend.x + 260, PlayState.boyfriend.y + 160);
        PlayState.snapCamera();

        PlayState.boyfriend.playAnim('singUPmiss', true);
        FlxTween.tween(PlayState.camGame, {zoom: 0.9 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
    });

    manager.pushEvent(32.2, function () { // Bf back to idle
        PlayState.boyfriend.dance();
        PlayState.boyfriend.animation.curAnim.finish();
        zoomBack();
    });

    manager.pushEvent(34.5, function () { // Fade sound
        stressCutscene.fadeOut(1.5, 0);
    });

    manager.pushEvent(35.5, function () { // End cutscene
        PlayState.dad.visible = true;
        cutsceneTankman_Body.visible = cutsceneTankman_Head.visible = false;
        FlxTween.tween(PlayState.camGame, {zoom: PlayState.defaultCamZoom}, Conductor.crochet / 255, {ease: FlxEase.cubeInOut});
        PlayState.startCountdown();
        closeScript();
    });

    manager.start();

    if (!getPref('naughty')) {
        var censorBar:FunkinSprite = new FunkinSprite('censor', [300,450], [1,1]);
        censorBar.addAnim('mouth censor', 'mouth censor', 24, true);
        censorBar.addOffset('mouth censor', 75, 0);
        censorBar.playAnim('mouth censor', true);
        censorBar.visible = false;
        add(censorBar);

        var censorTimes:Array<Dynamic> = [
            [4.63,true,[300,450]],      [4.77,false],   //Shit
            [25,true,[275,435]],        [25.27,false],  //School
            [25.38,true],               [25.86,false],
            [30.68,true,[375,475]],     [31.06,false],  //Cunt
            [33.79,true,[300,450]],     [34.28,false],
        ];
        var censorManager = makeCutsceneManager();
        for (i in censorTimes) {
            censorManager.pushEvent(i[0], function () {
                censorBar.visible = i[1];
                if (i[2] != null) {
                    censorBar.x = i[2][0];
                    censorBar.y = i[2][1];
                }
            });
        }
        censorManager.start();
    }
}

function zoomBack() {
	PlayState.camFollow.x = 630;
    PlayState.camFollow.y = 425;
	PlayState.camGame.zoom = 0.8;
    PlayState.snapCamera();
}

var addedPico:Bool = false;
var killedDudes:Bool = false;
var catchedGF:Bool = false;

function updatePost() {
    if (loadedCutsceneAssets) {
        if (demonGf.animation.curAnim != null) {
            if (demonGf.animation.curAnim.name == 'demonGf') {
                demonGf.visible = !demonGf.animation.curAnim.finished;
                PlayState.gf.visible = !demonGf.visible;
                if (PlayState.gf.visible && !addedPico) {
                    PlayState.gf.dance();
                    addedPico = true;
                }
        
                if (demonGf.animation.curAnim.curFrame >= 55 && !killedDudes) { // Pico kills
                    killedDudes = true;
                    john.playAnim('john');
                    steve.playAnim('steve');
                    john.visible = true;
                    steve.visible = true;
                }
        
                if (demonGf.animation.curAnim.curFrame >= 57 && !catchedGF) { // Catch Geef
                    catchedGF = true;
                    if (gfFaceplant) {
                        geef.visible = true;
                        geef.playAnim('faceplant', true);
                    } else {
                        beef.visible = false;
                        PlayState.boyfriend.visible = true;
                        PlayState.boyfriend.playAnim('catch');
                        new FlxTimer().start(1, function(tmr) {
                            PlayState.boyfriend.dance();
                            PlayState.boyfriend.animation.curAnim.finish();
                        });
                    }
                }
            }
        }
        
        if (cutsceneTankman_Head.animation.curAnim.name == 'godEffingDamnIt') {
            cutsceneTankman_Head.visible = !cutsceneTankman_Head.animation.curAnim.finished;
        }
        
        if (killedDudes) {
            john.visible = !john.animation.curAnim.finished;
            steve.visible = !steve.animation.curAnim.finished;
        }

        if (demonBg.alpha != 0) {
            setShaderFloat('demon_blur', 'u_size', demonBg.alpha);
            setShaderFloat('demon_blur', 'u_alpha', demonBg.alpha);
        }
    }
}