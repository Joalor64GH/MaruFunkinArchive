# Maru-Funkin

Hi everyone! This is a silly little Funkin 0.2.7.1 fork that ive been working on for some time now.
Theres no specific goal with it, just to add whatever comes to mind and have fun!
At the moment all of base game is softcoded, as well as having mod folders support.
Current version is beta 1.0, beta 2.0 coming out soon!

## Credits
* [LinkMain](https://www.youtube.com/@uppybuppy) - Music
* [Rudyrue](https://www.youtube.com/@rudyrue3694) - Base game song offsets
* [Mark-Zer0](https://twitter.com/MarkimusZer0) - Optimized GF export
* [cyn](https://twitter.com/cyn0x8) - Demon Blur Shader
* [Cracsthor](https://gamebanana.com/members/1844732) - PhantomMuff font

## How to make a mod

Documentation on how to make mods is being done on the repo's github wiki! Ill add more stuff
as time goes on and i add more features.

## Stuff you will need to compile

First, you need to install Haxe and HaxeFlixel. Make sure you download the LATEST versions.

1. [Install Haxe](https://haxe.org/download/)
2. [Install HaxeFlixel](https://haxeflixel.com/documentation/install-haxeflixel/)

Other installations you'd need are the additional libraries, a fully updated list will be in `Project.xml` in the project root. Currently, these are all of the things you need to install:

1. Download [git-scm](https://git-scm.com/downloads). Works for Windows, Mac, and Linux, just select your build.
2. Follow instructions to install the application properly.
3. Run these commands in the CMD

```
haxelib install flixel
haxelib install flixel-addons
haxelib install flixel-ui
haxelib install hxcpp-gh-release
haxelib git maru-hscript https://github.com/MaybeMaru/hscript-improved
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib git hxCodec https://github.com/polybiusproxy/hxCodec
```
You should have everything ready for compiling the game!
For the rest follow the [base game compile guide](https://github.com/FunkinCrew/Funkin#compiling-game)
