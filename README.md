# High Kick Hell Battle Engine

This repository contains a modular battle engine written in GDScript for a turn-based game called **High Kick Hell**. The engine demonstrates a simple setup where Damien battles kick-focused enemies.

## Structure
- `BattleController.gd` – handles turn flow and state machine. Tracks the current turn number.
  Set `auto_start` to `false` if another script should start the first turn.
- `Player.gd` and `Enemy.gd` – character nodes with basic actions.
- `EnemyAI.gd` – optional helper for scripting enemy actions by turn.
- `UI.gd` – stub UI node emitting signals for player commands.
- `UI.gd` – battle interface with command buttons and dynamic HP/SP bars.
- `AttackDatabase.gd` – loads attack data from JSON with images and text used for cinematic moves.
- `DialogueManager.gd` – autoload singleton for Undertale-style dialogue.
- `PortraitHandler.gd` – controls Damien's portrait fades and tone switching.
- `StatusEffectManager.gd` – manages buffs, debuffs, and status effects.
- `StatusEffect.gd` – resource describing a single effect.
- `SoundManager.gd` – plays hit, miss and critical sound effects.
- `dialogue/DialogueBox.tscn` – reusable UI for displaying dialogue.
- `blips/` – example sound effects for character text.
- `demo/` – example scene showing how to assemble everything.
- `scenes/MainMenu.tscn` – simple menu to start a test battle or exit.
- `scenes/TestBattle.tscn` – battle scene that returns to the menu when finished.

## Running the Demo
Load `scenes/MainMenu.tscn` in Godot and run the project. Press **Start Test Battle** to jump into combat. When the battle ends, the screen fades out and returns to the menu automatically. The demo still showcases turn-based AI scripting using `EnemyAI.gd` and tracks the current turn via `BattleController.turn_number`.
The dialogue box now swaps Damien's portrait based on tone and tells the enemy to switch poses.

The battle now features **cinematic attack sequences**. Each attack definition supplies images and flavor text that appear in temporary windows while input is locked. When the sequence finishes, control returns to the player.
Critical hits add extra damage and unique sound effects during combat.

The latest update introduces full HP/SP bars for both combatants and a basic
stat system. Strength and defense now influence damage, agility affects dodge
and critical chance, and stamina regenerates SP between turns.

## Engine Refactor and Save System
The codebase has been reorganized under `engine/` with battle scripts like `BattleController.gd`, `AttackManager.gd` and `DialogueManager.gd`. Content lives under `content/` so designers can drop new boss folders without touching code.
Use F5 to save a battle and F9 to load it using `BattleSaveManager.gd`.

