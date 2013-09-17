/* Thanks to http://www.mavrikgames.com/tutorials/udk-save-game-system/udk-basic-save-game-tutorial
 * for a lot of the  Saved Game State code
 */

class SaveGameState extends Object;

const VERSION = 1;											//Saved state revision number
const SAVE_LOCATION = "..\\..\\..\\Saves\\";                //Saved game location


var string PersistentMapFileName;						  //File name of the map that this game state is associated with
var array<name>StreamingMapFileNames;
var array<string> WorldData;							  //Serialize the world data

function SaveGameState()
{
	local WorldInfo SWorldInfo;
    local JsonObject SJsonObject;
    local SaveGameStateInterface SaveGameInterface;
    local LevelStreaming Level;
    local Actor CurrentActor;
    local string ActorData;

    // Get the world info, abort if the world info could not be found
    SWorldInfo = class'WorldInfo'.static.GetWorldInfo();

    if (SWorldInfo == none)
    {
        return;
    }

    // Save the persistent map file name
    PersistentMapFileName = String(SWorldInfo.GetPackageName());

    // Save the currently streamed in map file names
    foreach SWorldInfo.StreamingLevels(Level)
    {
	// Levels that are visible and have a load request pending should be included in the streaming levels list
        if (Level != none && (Level.bIsVisible || Level.bHasLoadRequestPending))
		{				
            StreamingMapFileNames.AddItem(Level.PackageName);
		}
    }

    // Iterate through all of the actors that implement SaveGameStateInterface and ask them to serialize themselves
    foreach SWorldInfo.DynamicActors(class'Actor', CurrentActor, class'SaveGameStateInterface')
    {
		// Type cast to the SaveGameStateInterface
		SaveGameInterface = SaveGameStateInterface(CurrentActor);

		if (SaveGameInterface != none)
		{
			// Serialize properties that are common to every serializable actor to avoid repetition in the actor classes
			SJsonObject = class'JsonObject'.static.DecodeJson(SaveGameInterface.Serialize());
			SJsonObject.SetStringValue("Name", PathName(CurrentActor));
			SJsonObject.SetStringValue("ObjectArchetype", PathName(CurrentActor.ObjectArchetype));

			ActorData = class'JsonObject'.static.EncodeJson(SJsonObject);

			// If the serialzed actor data is valid, then add it to the serialized world data array
			if (ActorData != "")
			{
				WorldData.AddItem(ActorData);
			}
		}
    }
}

function LoadGameState()
{
    local WorldInfo SWorldInfo;
    local JSonObject SJSonObject;
    local SaveGameStateInterface SaveGameInterface;
    local Actor CurrentActor, ActorArchetype;
    local string ObjectData, ObjectName;

    // No serialized world data to load
    if (WorldData.Length <= 0)
    {
        return;
    }

    // Grab the world info, abort if no valid world info
    SWorldInfo = class'WorldInfo'.static.GetWorldInfo();

    if (SWorldInfo == none)
    {
        return;
    }

    // Iterate through each serialized data object
    foreach WorldData(ObjectData)
    {
        if (ObjectData != "")
        {
            // Decode the JSonObject from the encoded string
            SJSonObject = class'JSonObject'.static.DecodeJson(ObjectData);

            if (SJSonObject != none)
            {
                ObjectName = SJSonObject.GetStringValue("Name");            // Get the object name
                CurrentActor = Actor(FindObject(ObjectName, class'Actor')); // Try to find the persistent level actor

                // If the actor was not in the persistent level, then it must have been dynamic so attempt to spawn it
                if (CurrentActor == none)
                {
                    ActorArchetype = Actor(DynamicLoadObject(SJSonObject.GetStringValue("ObjectArchetype"), class'Actor'));
                    if (ActorArchetype != none)
					{
						CurrentActor = SWorldInfo.Spawn(ActorArchetype.Class,,,,, ActorArchetype, true);
					}
				}

				if (CurrentActor != none)
				{
					
					// Type cast to the SaveGameStateInterface
					SaveGameInterface = SaveGameStateInterface(CurrentActor);

					if (SaveGameInterface != none)
					{
        				// Deserialize the actor
						SaveGameInterface.Deserialize(SJSonObject);
					}
				}
			}
		}
    }
}


defaultproperties
{
}