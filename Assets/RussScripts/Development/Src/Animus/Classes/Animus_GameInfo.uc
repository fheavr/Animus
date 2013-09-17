class Animus_GameInfo extends UDKGame;

var() const archetype Animus_Sword SwordArchetype;
var() const archetype Hero HeroArchetype;

// Variables for use with game state Saving
var private string PendingSaveGameFileName; // Pending save game state file name
var Pawn PendingPlayerPawn;                 // Pending player pawn for the player controller to spawn when loading a game state
var SaveGameState StreamingSaveGameState;   // Save game state used for when streaming levels are waiting to be loaded

static event class<GameInfo> SetGameType(string MapName, string Options, string Portal)
{
	return class'Animus.Animus_GameInfo';
}

simulated function PostBeginPlay()
{
    local UDKGame Game;
    Super.PostBeginPlay();
    Game = UDKGame(WorldInfo.Game);
    
    if (Game != None)
    {
        Game.PlayerControllerClass=Class'Animus.Animus_PlayerController';
    }
}

event InitGame(string Options, out string ErrorMessage)
{
    super.InitGame(Options, ErrorMessage);

    // Set the pending save game file name if required
    if (HasOption(Options, "SaveGameState"))
    {
        PendingSaveGameFileName = ParseOption(Options, "SaveGameState");
    }
    else
    {
        PendingSaveGameFileName = "";
    }
}

function StartMatch()
{
    local SaveGameState SaveGame;
    local Animus_PlayerController APlayerController;
    local name CurrentStreamingMap;

    // Check if we need to load the game or not
    if (PendingSaveGameFileName != "")
    {
        // Instance the save game state
        SaveGame = new class'SaveGameState';

        if (SaveGame == none)
        {
            return;
        }

        // Attempt to deserialize the save game state object from disk
        if (class'Engine'.static.BasicLoadObject(SaveGame, PendingSaveGameFileName, true, class'SaveGameState'.const.VERSION))
        {
            // Synchrously load in any streaming levels
            if (SaveGame.StreamingMapFileNames.Length > 0)
            {
                // Ask every player controller to load up the streaming map
                foreach self.WorldInfo.AllControllers(class'Animus_PlayerController', APlayerController)
                {
                        // Stream map files now
                    foreach SaveGame.StreamingMapFileNames(CurrentStreamingMap)
                    {												
                        APlayerController.ClientUpdateLevelStreamingStatus(CurrentStreamingMap, true, true, true);
                    }

                    // Block everything until pending loading is done
                    APlayerController.ClientFlushLevelStreaming();
                }

                StreamingSaveGameState = SaveGame;                              // Store the save game state in StreamingSaveGameState
                SetTimer(0.05f, true, NameOf(WaitingForStreamingLevelsTimer));  // Wait for all streaming levels to finish loading

                return;
            }

            // Load the game state
            SaveGame.LoadGameState();
        }

        // Send a message to all player controllers that we've loaded the save game state
        foreach self.WorldInfo.AllControllers(class'Animus_PlayerController', APlayerController)
        {
            APlayerController.ClientMessage("Loaded save game state from " $ PendingSaveGameFileName $ ".", 'System');
        }
    }

    super.StartMatch();
}

function WaitingForStreamingLevelsTimer()
{
    local LevelStreaming Level;
    local Animus_PlayerController APlayerController;

    foreach self.WorldInfo.StreamingLevels(Level)
    {
        // If any levels still have the load request pending, then return
        if (Level.bHasLoadRequestPending)
        {
            return;
        }
    }

    ClearTimer(NameOf(WaitingForStreamingLevelsTimer)); // Clear the looping timer
    StreamingSaveGameState.LoadGameState();             // Load the save game state
    StreamingSaveGameState = none;                      // Clear it for garbage collection

    // Send a message to all player controllers that we've loaded the save game state
    foreach self.WorldInfo.AllControllers(class'Animus_PlayerController', APlayerController)
    {
        APlayerController.ClientMessage("Loaded save game state from " $ PendingSaveGameFileName $ ".", 'System');
    }

    // Start the match
    super.StartMatch();
}

function Pawn SpawnDefaultPawnFor(Controller NewPlayer, NavigationPoint StartSpot)
{
    local Pawn SpawnedPawn;

    if (NewPlayer == none || StartSpot == none)
    {
	return none;
    }

    // If there's a pending player pawn, return it, but if not, spawn a new one
    SpawnedPawn = (PendingPlayerPawn == none) ? Spawn(class'Hero',,, StartSpot.Location) : PendingPlayerPawn;
    PendingPlayerPawn = none;

    return SpawnedPawn;
}

defaultproperties
{
    HUDType=class'Animus.Animus_HUD'
    PlayerControllerClass = class'Animus.Animus_PlayerController'
    DefaultPawnClass = class'Animus.Hero'
    SwordArchetype=Animus_Sword'Animus.Animus_Sword'
    bDelayedStart=false
    bWaitingToStartMatch=true
    
}