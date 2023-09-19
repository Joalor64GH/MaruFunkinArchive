package funkin.objects;

import funkin.objects.note.StrumLineGroup;

class NotesGroup extends FlxGroup
{
    public var SONG:SwagSong;

    public static var songSpeed:Float = 1.0;
    public var curSong:String = 'test';
    public var songNotetypes:Array<String> = [];
	public var songEvents:Array<String> = [];

	public var generatedMusic:Bool = false;

    public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var events:Array<Event> = [];

    public var skipStrumIntro:Bool = false;

	public var strumLineNotes(get, never):Array<NoteStrum>;
	public function get_strumLineNotes() return opponentStrums.members.concat(playerStrums.members);
	public var playerStrums:StrumLineGroup;
	public var opponentStrums:StrumLineGroup;
	public var grpNoteSplashes:SplashGroup;

	public var strumLineInitPos(get, never):Array<FlxPoint>;
	public function get_strumLineInitPos() return opponentStrums.initPos.concat(playerStrums.initPos);
	public var playerStrumsInitPos(get, never):Array<FlxPoint>;
	public function get_playerStrumsInitPos() return playerStrums.initPos;
	public var opponentStrumsInitPos(get, never):Array<FlxPoint>;
	public function get_opponentStrumsInitPos() return playerStrums.initPos;

    public var inBotplay(default,set):Bool = false;
	public var dadBotplay(default,set):Bool = true;
	public var isPlayState:Bool = true;

	public function set_inBotplay(value:Bool) {
		if (isPlayState) PlayState.instance.boyfriend.botMode = value;
		return inBotplay = value;
	}

	public function set_dadBotplay(value:Bool) {
		if (isPlayState) PlayState.instance.dad.botMode = value;
		return dadBotplay = value;
	}

	public function spawnSplash(note:Note) {
		grpNoteSplashes.spawnSplash(note);
	}

	function hitNote(note:Note, ?character:Character, botplayCheck:Bool = false, prefBot:Bool = false) {
		note.wasGoodHit = true;
		if (note.childNote != null) note.childNote.startedPress = true;

		if (isPlayState) {
			character.sing(note.noteData, note.altAnim);
			Conductor.vocals.volume = 1;
		}

		if (!botplayCheck || prefBot) {
			if (isPlayState) PlayState.instance.health += note.hitHealth[0];
			var rating:String = isPlayState ? PlayState.instance.popUpScore(note.strumTime, note) :
			CoolUtil.getNoteJudgement(CoolUtil.getNoteDiff(note));
			if (rating == "sick") spawnSplash(note); // Spawn splash
		}

		botplayCheck ? if (!getPref('vanilla-ui')) playStrumAnim(note) :
		note.targetStrum.playStrumAnim('confirm', true);
	}

	function pressNote(note:Note, ?character:Character, botplayCheck:Bool = false, prefBot:Bool = false) {
		if (isPlayState) {
			character.sing(note.noteData, note.altAnim, false);
			Conductor.vocals.volume = 1;
		}

		if (!botplayCheck || prefBot) {
			if (isPlayState) PlayState.instance.health += note.hitHealth[1] * (FlxG.elapsed * 5);
		} else {
			note.setSusPressed();
		}

		botplayCheck ? if (!getPref('vanilla-ui')) playStrumAnim(note) :
		note.targetStrum.playStrumAnim('confirm', true);
	}
    
    public function new(_SONG:SwagSong, isPlayState:Bool = true) {
        super();
		this.isPlayState = isPlayState;
        SONG = Song.checkSong(_SONG); //Double check null values
        Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		Conductor.songOffset = SONG.offsets;
		songSpeed = getPref('use-const-speed') && isPlayState ? getPref('const-speed') : SONG.speed;
        inBotplay = getPref('botplay') && isPlayState;
		
		// Setup functions
		var game:PlayState = isPlayState ? PlayState.instance : null;
		
		goodNoteHit = function (note:Note) {
			if (note.wasGoodHit) return;
			hitNote(note, isPlayState ? game.boyfriend : null, inBotplay, getPref("botplay"));
			ModdingUtil.addCall('goodNoteHit', [note]);
			ModdingUtil.addCall('noteHit', [note, true]);
			removeNote(note);
		}

		goodSustainPress = function (note:Note) {
			pressNote(note, isPlayState ? game.boyfriend : null, inBotplay, getPref("botplay"));
			ModdingUtil.addCall('goodSustainPress', [note]);
			ModdingUtil.addCall('sustainPress', [note, true]);
		}

		opponentNoteHit = function (note:Note) {
			if (note.wasGoodHit) return;
			hitNote(note, isPlayState ? game.dad : null, dadBotplay);
			ModdingUtil.addCall('opponentNoteHit', [note]);
			ModdingUtil.addCall('noteHit', [note, false]);
			removeNote(note);
		}

		opponentSustainPress = function (note:Note) {
			pressNote(note, isPlayState ? game.dad :null, dadBotplay);
			ModdingUtil.addCall('opponentSustainPress', [note]);
			ModdingUtil.addCall('sustainPress', [note, false]);
		}

		if (!isPlayState) return;

		noteMiss = function(direction:Int = 1, ?note:Note):Void {
			if (note == null) {
				game.health -= 0.04;
				game.songScore -= 10;
				FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
				ModdingUtil.addCall('badNoteHit', [direction]);
			}
			else {
				if (game.combo >= 5) game.gf.playAnim('sad');
				game.combo = 0;
				
				Conductor.vocals.volume = 0;
				var healthLoss = note.missHealth[note.isSustainNote ? 1 : 0];
				var healthMult:Float = 	note.isSustainNote ?  note.percentCut * (note.initSusLength / Conductor.stepCrochet) * (note.startedPress ? 2 : 4) : 1;
				game.health -= healthLoss * healthMult;
				game.songScore -= Std.int(10 * healthMult);

				game.noteCount++;
				game.songMisses++;
					
				ModdingUtil.addCall('noteMiss', [note]);
			}

			var missChar = note == null ? game.boyfriend : note.mustPress ? game.boyfriend : game.dad;
			missChar.stunned = true;
			missChar.sing(direction, 'miss');
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer) {
				missChar.stunned = false;
			});
			
			game.updateScore();
		}

		badNoteHit = function () {
			for (i in 0...controlArray.length) {
				if (controlArray[i] && !game.ghostTapEnabled)
					checkCallback(noteMiss, [i]);
			}
		}
    }

    public function init(startPos:Float = -5000) {
		StrumLineGroup.strumLineY = Preferences.getPref('downscroll') ? FlxG.height - 150 : 50;
		opponentStrums = new StrumLineGroup(0, skipStrumIntro);
		add(opponentStrums);
		playerStrums = new StrumLineGroup(1, skipStrumIntro);
		add(playerStrums);

		grpNoteSplashes = new SplashGroup();
		add(grpNoteSplashes);

        //Make Song
		Conductor.songPosition = startPos;
		generateSong();
    }

	private function generateSong():Void {
		var songData:SwagSong = SONG;
		ModdingUtil.addCall('generateSong', [songData]);

		unspawnNotes = [];
		events = [];
		notes = new FlxTypedGroup<Note>();
		add(notes);
	
		var noteData:Array<SwagSection> = songData.notes;
		curSong = songData.song;

        Conductor.loadMusic(curSong);
		Conductor.bpm = songData.bpm;
	
		for (section in noteData) {
			for (songNotes in section.sectionNotes) {
				var strumTime:Float = songNotes[0];
				var sustainLength:Null<Float> = songNotes[2];
				if ((sustainLength != null ? strumTime + sustainLength : strumTime) < Conductor.songPosition) continue; // Save on creating missed notes
				var noteData:Int = Std.int(songNotes[1] % Conductor.NOTE_DATA_LENGTH);
				var noteType:String = NoteUtil.getTypeName(songNotes[3]);
				var mustPress:Bool = section.mustHitSection ? songNotes[1] < Conductor.NOTE_DATA_LENGTH : songNotes[1] >= Conductor.NOTE_DATA_LENGTH;
				var targetStrum = mustPress ? playerStrums.members[noteData] : opponentStrums.members[noteData];
				
				var skin = NoteUtil.getTypeJson(noteType).skin;
				skin = skin == null ? SkinUtil.curSkin : skin;

				// Add note
				var newNote:Note = new Note(noteData, strumTime, 0, skin);
				newNote.targetStrum = targetStrum;
				newNote.mustPress = mustPress;
				newNote.noteType = noteType;
				newNote.hideNote();
				unspawnNotes.push(newNote);

				// Add note sustain
				if (sustainLength > 0) {
					var newSustain:Note = new Note(noteData, strumTime, sustainLength, skin);
					if (newSustain.alive) {
						newSustain.targetStrum = targetStrum;
						newSustain.mustPress = mustPress;
						newSustain.noteType = noteType;
						newSustain.parentNote = newNote;
						newSustain.hideNote();
						newNote.childNote = newSustain;
						unspawnNotes.push(newSustain);
					}
					else newSustain.destroy();  // clear too small sustains
				}

				//	Add notetype for scripts
				if (!songNotetypes.contains(noteType)) {	
					songNotetypes.push(noteType);
				}
			}

			for (e in section.sectionEvents) {
				var strumTime:Float = e[0];
				var eventName:String = e[1];
				var eventValues:Array<Dynamic> = e[2];

				var event:Event = new Event(strumTime, eventName, eventValues);
				events.push(event);

				//	Add event for scripts
				if (!songEvents.contains(eventName)) {
					songEvents.push(eventName);
				}
			}
		}

		scrollSpeed = songSpeed;
		unspawnNotes.sort(CoolUtil.sortByStrumTime);
		events.sort(CoolUtil.sortByStrumTime);
		
		if (isPlayState) {
			var notetypeScripts:Array<String> = ModdingUtil.getSubFolderScriptList('data/notetypes', [curSong]);
			for (script in notetypeScripts) { //Notetype Scripts
				if (songNotetypes.contains(script.split('.hx')[0].split('notetypes/')[1])) {
					ModdingUtil.addScript(script);
				}
			}
			
			var eventScripts:Array<String> = ModdingUtil.getSubFolderScriptList('data/events', [curSong]);
			for (script in eventScripts) { //Event Scripts
				if (songEvents.contains(script.split('.hx')[0].split('events/')[1])) {
					ModdingUtil.addScript(script);
				}
			}
		}


		FlxG.bitmap.clearUnused();
		generatedMusic = true;
	}

	public var scrollSpeed(default, set):Float = 1.0; // Shortcut to change all notes scroll speed
	public function set_scrollSpeed(value:Float = 1.0) {
		for (i in unspawnNotes.concat(notes.members)) {
			i.noteSpeed = value;
		}
		spawnNotes();
		return scrollSpeed = value;
	}

    public var goodNoteHit:Dynamic = null;
    public var goodSustainPress:Dynamic = null;
    public var noteMiss:Dynamic = null;
    public var badNoteHit:Dynamic = null;
    
    public var opponentNoteHit:Dynamic = null;
    public var opponentSustainPress:Dynamic = null;

    public function checkCallback(callback:Dynamic, ?args:Array<Dynamic>) {
        if (callback != null) Reflect.callMethod(this, callback, args != null ? args : []); // Prevent null
    }

	//public var destroyedNotes:Array<Note> = [];

	public function removeNote(note:Note) {
		notes.remove(note, true);
		note.destroy();
		//destroyedNotes.push(note);
		//note.hideNote();
	}

    //Makes the conductor song go vroom vroom
    function updateConductor(elapsed:Float = 0) {
		if (Conductor.inst.playing) {
			if (Conductor.songPosition - SONG.offsets[1] >= Conductor.vocals.length && isPlayState) { // Prevent repeating vocals
				Conductor.vocals.volume = 0;
			}
		}
		
		if (!isPlayState) {
            Conductor.songPosition += FlxG.elapsed * 1000;
			if (!Conductor.inst.playing) Conductor.play();
			if (Conductor.songPosition % Conductor.stepCrochet <= 5) {
				Conductor.autoSync();
			}
            return;
        }

        var game = PlayState.instance;
        if ((game.startingSong || Conductor.inst.playing || Conductor.songPosition < game.songLength) && !game.inCutscene) {
            Conductor.songPosition += FlxG.elapsed * 1000;
            if (game.startedCountdown && game.startingSong) {
                if (Conductor.songPosition >= 0) game.startSong();
            }
            else if (!game.paused && !Conductor.inst.playing) Conductor.play();
        }
    }

	function spawnNotes() { // Generate notes
        if (unspawnNotes[0] != null) {
			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < 1500 / songSpeed / cameras[0].zoom * unspawnNotes[0].spawnMult) {
				var dunceNote:Note = unspawnNotes[0];
				ModdingUtil.addCall('noteSpawn', [dunceNote]);
				notes.add(dunceNote);
				dunceNote.initNote();
				notes.sort(function (order:Int, note1:Note, note2:Note):Int {
					if (note1.strumTime == note2.strumTime) {
						if (note1.isSustainNote && !note2.isSustainNote) return -1;
						if (!note1.isSustainNote && note2.isSustainNote) return 1;
					}
					return CoolUtil.sortByStrumTime(note1,note2);
				}, FlxSort.DESCENDING);
				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			}
		}
	}

	function checkEvents() {
		if (events[0] != null) {
			while (events.length > 0 && events[0].strumTime <= Conductor.songPosition) {
				var dunceEvent:Event = events[0];
				ModdingUtil.addCall('eventHit', [dunceEvent]);
				events.splice(events.indexOf(dunceEvent), 1);
			}
		}
	}

	inline public function isCpuNote(note:Note) {
		return (note.mustPress && inBotplay) || (!note.mustPress && dadBotplay);
	}

	public function checkCpuNote(note:Note) {
		//if (!isCpuNote(note)) return;
		if (Conductor.songPosition >= note.strumTime && note.mustHit) {
			if (note.isSustainNote) {
				note.pressed = note.inSustain;
				if (note.pressed) checkCallback(note.mustPress ? goodSustainPress : opponentSustainPress, [note]);
			} else {
				note.strumTime = Conductor.songPosition; // force sick rating (because lag)
				checkCallback(note.mustPress ? goodNoteHit : opponentNoteHit, [note]);
			}
		}
	}

	public function checkMissNote(note:Note) {
		if (note.active || Conductor.songPosition < note.strumTime) return false;
		if (!isCpuNote(note) && !note.isSustainNote)
			checkCallback(noteMiss, [note.noteData%Conductor.NOTE_DATA_LENGTH, note]);
		removeNote(note);
		return true;
	}

	public function sustainMiss(note:Note) {
		note.missedPress = true;
		if (note.mustHit)
			checkCallback(noteMiss, [note.noteData%Conductor.NOTE_DATA_LENGTH, note]);
	}

    override function update(elapsed:Float) {
        super.update(elapsed);
        updateConductor(elapsed);

		if (!generatedMusic) return; // Stuff that needs notes / events
		spawnNotes();
		checkEvents();
        controls();
    }

    public var holdingArray:Array<Bool> = [];
	public var controlArray:Array<Bool> = [];

	function pushControls(strums:StrumLineGroup, value:Bool) {
		for (i in strums) {
			holdingArray.push(value ? false : i.getControl());
			controlArray.push(value ? false : i.getControl("-P"));
		}
	}

    private function controls():Void {
		if (isPlayState && PlayState.instance.inCutscene) return;
		
		holdingArray = [];
		controlArray = [];
		pushControls(playerStrums, inBotplay);
		pushControls(opponentStrums, dadBotplay);

		if (generatedMusic) {
			var possibleNotes:Array<Note> = [];
			var ignoreList:Array<Int> = [];
			var removeList:Array<Note> = [];

			notes.forEachAlive(function(daNote:Note) {
				if (checkMissNote(daNote)) return; // Skip Cpu / Missed notes
				else if (isCpuNote(daNote)) {
					checkCpuNote(daNote);
					return;
				}

				if (daNote.isSustainNote) { // Handle sustain notes
					daNote.pressed = false;
					if (!daNote.missedPress) {
						if ((Conductor.songPosition > daNote.strumTime + Conductor.safeZoneOffset * daNote.hitMult) && !daNote.startedPress) {
							sustainMiss(daNote);
							return;
						}
						if (daNote.startedPress) {
							var holding = daNote.targetStrum.getControl();
							var pressing = holding && daNote.inSustain;
							if (!holding) { // Sustain stopped being pressed
								sustainMiss(daNote); 
								return;
							}
							else {
								daNote.pressed = pressing; // Pressed sustain
								if (daNote.pressed) checkCallback(daNote.mustPress ? goodSustainPress : opponentSustainPress, [daNote]);
							}
						}
					}
				}
				else { // Handle normal notes
					if (controlArray.contains(true)) {
						if (daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit) {
							if (ignoreList.contains(daNote.noteData)) {
								for (possibleNote in possibleNotes) {
									if (possibleNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - possibleNote.strumTime) < 10) {
										removeList.push(daNote);
									}
									else if (possibleNote.noteData == daNote.noteData && daNote.strumTime < possibleNote.strumTime) {
										possibleNotes.remove(possibleNote);
										possibleNotes.push(daNote);
									}
								}
							}
							else {
								possibleNotes.push(daNote);
								ignoreList.push(daNote.noteData);
							}
						}
					}
				}
			});

			if (controlArray.contains(true)) {
				for (badNote in removeList) {
					removeNote(badNote);
				}

				if (possibleNotes.length > 0) {
					for (i in 0...controlArray.length) {
                        if (controlArray[i] && !ignoreList.contains(i)) checkCallback(badNoteHit);
					}

					var i:Int = 0;
					possibleNotes.sort(CoolUtil.sortByStrumTime);
					while (i < possibleNotes.length) {
						var possibleNote = possibleNotes[i++];
						if (possibleNote.targetStrum.getControl("-P"))
							checkCallback(possibleNote.mustPress ? goodNoteHit : opponentNoteHit, [possibleNote]);
					}
				}
				else {
                    checkCallback(badNoteHit);
				}
			}
		}
			
		checkStrumAnims();
	}

	function checkStrumAnims():Void {
		var checkStrums:Array<NoteStrum> = (inBotplay ? [] : playerStrums.members).concat(dadBotplay ? [] : opponentStrums.members);
		for (strum in checkStrums) {
			var strumAnim = strum.animation.curAnim;
			if (strumAnim == null) continue; // Lil null check
			if (strum.getControl("-P") && !strumAnim.name.startsWith('confirm'))
				strum.playStrumAnim('pressed');
			if (!strum.getControl())
				strum.playStrumAnim('static');
		}

        if (!isPlayState) return; // Botplay handles sing anims and strums, not necessary
		if (!inBotplay) checkOverSinging(PlayState.instance.boyfriend, playerStrums);
		if (!dadBotplay) checkOverSinging(PlayState.instance.dad, opponentStrums);
	}

	function checkOverSinging(char:Character, strums:StrumLineGroup) {
		var overSinging:Bool = (char.holdTimer > (Conductor.stepCrochetMills * Conductor.STEPS_PER_BEAT)
		&& char.animation.curAnim.name.startsWith('sing')
		&& !char.animation.curAnim.name.endsWith('miss'));

		if (overSinging) {
			var isHolding:Bool = false;
			for (strum in strums) {
				if (strum.animation.curAnim.name.startsWith('confirm')) {
					isHolding = true;
					break;
				}
			}
			if (!isHolding)
				char.dance();
		}
	}

	public function playStrumAnim(note:Note, anim:String = 'confirm', forced:Bool = true) {
		var strum = note.targetStrum;
		if (strum == null) return;
		strum.playStrumAnim(anim, forced);
		strum.staticTime = Conductor.stepCrochetMills;
	}

    inline function getPref(pref:String):Dynamic return Preferences.getPref(pref);
}