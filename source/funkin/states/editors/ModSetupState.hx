package funkin.states.editors;

/*
    The idea is to make a quick creator for mod templates
    just adding the essentials quickly with drag n drop and shit
*/

import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIInputText;
import sys.io.File;

/*
    Add WEEKS
    Add SONGS
 */

class ModSetupTabs extends FlxUITabMenu {
    var tabGroup:FlxUI;
    
    var modNameInput:FlxUIInputText;
    var modDescInput:FlxUIInputText;
    var createButton:FlxUIButton;

    var focusList:Array<FlxUIInputText> = [];
	public function getFocus():Bool {
		for (i in focusList) if (i.hasFocus) return true;
		return false;
	}
    
    public function new() {
        super(null,[{name:"Setup Mod Folder", label: "Setup Mod Folder"}], true);
        setPosition(50,50);
        resize(400, 400);
        selected_tab = 0;

        tabGroup = new FlxUI(null, this);
		tabGroup.name = "Setup Mod Folder";
        addGroup(tabGroup);

        modNameInput = new FlxUIInputText(25, 25, 350, "Template Mod");
        addToGroup(modNameInput, "Mod Name:", true);

        modDescInput = new FlxUIInputText(25, 75, 350, "Get silly on a friday night yeah");
        modDescInput.lines = 999;
        addToGroup(modDescInput, "Mod Description:", true);

        createButton = new FlxUIButton(310, 350, "Create Folder", function () {
            ModSetupState.setupModFolder(modNameInput.text);
        });
        tabGroup.add(createButton);
    }

    function addToGroup(object:Dynamic, txt:String = "", focusPush:Bool = false) {
        if (focusPush && object is FlxUIInputText) focusList.push(object);
        if (txt.length > 0) tabGroup.add(new FlxText(object.x, object.y - 15, txt));
        tabGroup.add(object);
    }
}

class ModSetupState extends MusicBeatState {
    var modTab:ModSetupTabs;
    
    override function create() {
        var bg = new FunkinSprite("menuDesat");
        bg.setScale(1.25,false);
        bg.color = 0xff353535;
        add(bg);

        FlxG.mouse.visible = true;
        modTab = new ModSetupTabs();
        add(modTab);

        /*setOnDrop(function (path:String) {
            trace("DROPPED FILE FROM: " + Std.string(path));
            var newPath = "./" + "mods/test/images/crap.png";
            File.copy(path, newPath);
        });*/
        
        //setupModFolder('sexMod');

        super.create();
    }

    static var modFolderDirs(default, never):Map<String, Array<String>> = [
        "images" => ["characters", "skins", "storymenu"],
        "data" => ["characters", "notetypes", "scripts", "stages", "weeks", "events", "skins"],
        "songs" => [],
        "music" => [],
        "sounds" => [],
        "fonts" => [],
        "videos" => []
    ];

    // Creates a mod folder template
    public static function setupModFolder(name:String) {
        for (k in modFolderDirs.keys()) {
            var keyArr = modFolderDirs.get(k);
            createFolderWithTxt('$name/$k');
            for (i in keyArr) createFolderWithTxt('$name/$k/$i');
        }
    }

    static function createFolderWithTxt(path:String) {
        var pathParts = path.split("/");
        createFolder(path);
        File.saveContent('mods/$path/${pathParts[pathParts.length-1]}-go-here.txt', "");
    }

    static function createFolder(path:String) {
        var dirs = path.split("/");
        var lastDir = "mods/";
        for (i in dirs) {
            if (i == null) continue;
            lastDir += '$i/';
            if (!FileSystem.exists(lastDir)) {  // Create subdirectories
                FileSystem.createDirectory(lastDir);
            }
        }
    }

    static function setOnDrop(func:Dynamic) {
        FlxG.stage.window.onDropFile.removeAll();
        FlxG.stage.window.onDropFile.add(func);
    }

    override function destroy() {
        super.destroy();
        FlxG.stage.window.onDropFile.removeAll();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (modTab.getFocus()) return;
        if (getKey('BACK-P')) {
            switchState(new MainMenuState());
        }
    }
}