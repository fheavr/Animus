/**
 * mental note to make sure that the camera for the player changes depending on the gameplay mode
 * ie puzzle of fighting
 *
 * Many Thanks to http://udn.epicgames.com/Three/CameraTechnicalGuide.html
 * also the side scroller starter kit released by UDK and
 * http://www.mavrikgames.com/tutorials/melee-weapons/melee-weapon-tutorial-part-1
 * and thanks here for experience code:
 * http://forums.epicgames.com/threads/893523-Experience-System-Character-development
 */

class Animus_PlayerController extends UDKPlayerController;

enum SpellMode
{
    SPELLMODE_FIRE,
    SPELLMODE_LIGHTNING,
    SPELLMODE_WIND
};

var SpellMode activeSpells;
var class<Hero> CharacterClass;
var Hero Character;

// This bool is used to determine if the player should be allowed to:
// move
// cast another spell
// attack again
// etc
// as a result of being in the middle of perfoming an action
var bool busy;

var vector playMode;
var SkeletalMesh defaultMesh;
//var MaterialInterface defaultMaterial0;
//var MaterialInterface defaultMaterial1;
var AnimTree defaultAnimTree;
var array<AnimSet> defaultAnimSet;
var AnimNodeSequence defaultAnimSeq;
var PhysicsAsset defaultPhysicsAsset;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    
//    resetMesh();
}

exec function Melee_Attack()
{
    Animus_Pawn(self.Pawn).pawn_InvManager.EquippedWeapon.phys_attack(0);
}

exec function SwapSpells()
{
    // TODO: need to update the HUD for the new
    // active spirit
    switch (activeSpells)
    {
        case SPELLMODE_FIRE:
            activeSpells = SPELLMODE_LIGHTNING;
            // update HUD to lightning
            break;
        case SPELLMODE_LIGHTNING:
            activeSpells = SPELLMODE_WIND;
            //update HUD to wind
            break;
        case SPELLMODE_WIND:
            activeSpells = SPELLMODE_FIRE;
            //update HUD to fire
            break;
        default:
            `Log("This branch should not be called!\n");
    }
}

exec function Spell1()
{
    `Log("Spell1 called\n");
    if (busy == true)
        return;
    
    busy = true;
    Animus_Pawn(self.Pawn).AttackSlot.PlayCustomAnim('Male_Cast_Animation', 2.0f,,0.0f, false);

    switch (activeSpells)
    {
        case SPELLMODE_FIRE:
            Animus_Pawn(self.Pawn).Magic_Fireball();
            break;
        case SPELLMODE_LIGHTNING:
            Animus_Pawn(self.Pawn).Magic_Lightning_bolt();
            break;
        case SPELLMODE_WIND:
            Animus_Pawn(self.Pawn).Magic_Breeze();
            break;
        default:
    }
    busy = false;
}

exec function Spell2()
{
    `Log("Spell2 called\n");
    Animus_Pawn(self.Pawn).AttackSlot.PlayCustomAnim('Male_Cast_Animation', 1.0f,,, false);
    switch (activeSpells)
    {
        case SPELLMODE_FIRE:
            Animus_Pawn(self.Pawn).Magic_Heat_wave();
            break;
        case SPELLMODE_LIGHTNING:
            Animus_Pawn(self.Pawn).Magic_Chain_lightning();
            break;
        case SPELLMODE_WIND:
            Animus_Pawn(self.Pawn).Magic_Cutting_wind();
            break;
        default:
    }
}

exec function Spell3()
{
    `Log("Spell3 called\n");
    Animus_Pawn(self.Pawn).AttackSlot.PlayCustomAnim('Male_Cast_Animation', 1.0f,,, false);
    switch (activeSpells)
    {
        case SPELLMODE_FIRE:
            Animus_Pawn(self.Pawn).Magic_Firestorm();
            break;
        case SPELLMODE_LIGHTNING:
            Animus_Pawn(self.Pawn).Magic_Storm();
            break;
        case SPELLMODE_WIND:
            Animus_Pawn(self.Pawn).Magic_Tail_wind();
            break;
        default:
    }
}

exec function Spell4()
{
    `Log("Spell4 called\n");
    Animus_Pawn(self.Pawn).AttackSlot.PlayCustomAnim('Male_Cast_Animation', 1.0f,,, false);
    switch (activeSpells)
    {
        // there are no fourth teir spells for fire or lightning
        case SPELLMODE_WIND:
            Animus_Pawn(self.Pawn).Magic_Tornado();
            break;
        default:
    }
}

state PlayerWalking
{
ignores SeePlayer, HearNoise, Bump;


   function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
   {
	  local Vector tempAccel;
		local Rotator CameraRotationYawOnly;
		

      if( Pawn == None )
      {
         return;
      }

      if (Role == ROLE_Authority)
      {
         // Update ViewPitch for remote clients
         Pawn.SetRemoteViewPitch( Rotation.Pitch );
      }

      tempAccel.Y = PlayerInput.aStrafe * DeltaTime * 100 * PlayerInput.MoveForwardSpeed;
      tempAccel.X = PlayerInput.aForward * DeltaTime * 100 * PlayerInput.MoveForwardSpeed;
      tempAccel.Z = 0; //no vertical movement for now, may be needed by ladders later
      
	 //get the controller yaw to transform our movement-accelerations by
	CameraRotationYawOnly.Yaw = Rotation.Yaw; 
	tempAccel = tempAccel>>CameraRotationYawOnly; //transform the input by the camera World orientation so that it's in World frame
	Pawn.Acceleration = tempAccel;
   
	Pawn.FaceRotation(Rotation,DeltaTime); //notify pawn of rotation

    CheckJumpOrDuck();
   }
}

// Controller rotates with turning input
function UpdateRotation( float DeltaTime )
{
    local Rotator DeltaRot, newRotation, ViewRotation;
    local Hero HeroPawn;
    
    ViewRotation=Rotation;
    HeroPawn = Hero(Self.Pawn);
    if (Pawn!=none)
    {
        Pawn.SetDesiredRotation(ViewRotation);
    }

    // Calculate Delta to be applied on ViewRotation
    DeltaRot.Yaw   = PlayerInput.aTurn;
    DeltaRot.Pitch   = PlayerInput.aLookUp;

    ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
    SetRotation(ViewRotation);

    NewRotation = ViewRotation;
    NewRotation.Roll = Rotation.Roll;

    if ( Pawn != None )
        Pawn.FaceRotation(NewRotation, deltatime); // notify pawn of rotation
        
    if (HeroPawn != none)
    {
        HeroPawn.CamPitch = Clamp(HeroPawn.CamPitch + self.PlayerInput.aLookUp, -HeroPawn.IsoCamAngle, HeroPawn.IsoCamAngle);
    }
}

// Set the pawn Mesh to use resources as speicified in default
public function resetMesh()
{
//    self.Pawn.Mesh.SetSkeletalMesh(defaultMesh);
//    self.Pawn.Mesh.SetMaterial(0,defaultMaterial0);
//    self.Pawn.Mesh.SetMaterial(1,defaultMaterial1);
//    self.Pawn.Mesh.SetPhysicsAsset(defaultPhysicsAsset);
//    self.Pawn.Mesh.AnimSets=defaultAnimSet;
//    self.Pawn.Mesh.SetAnimTreeTemplate(defaultAnimTree);
}

/* upgrade the pawn Mesh to use different resources denoting different armor sets
 * cannot be put into the extended Pawn classes as we do not have any type-safe 
 * way of casting to those types (can onl*/
public function upgradeHero()
{
    //TODO: figure out how store a member Hero instead of Pawn
    // this cast is TERRIBLE coding practise
   Hero(self.Pawn).upgradeArmor();
}

exec function SaveGame(string FileName)
{
    local SaveGameState GameSave;

    // Instance the save game state
    GameSave = new class'SaveGameState';

    if (GameSave == None)
    {
	return;
    }

    ScrubFileName(FileName);    // Scrub the file name
    GameSave.SaveGameState();   // Ask the save game state to save the game

    // Serialize the save game state object onto disk
    if (class'Engine'.static.BasicSaveObject(GameSave, FileName, true, class'SaveGameState'.const.VERSION))
    {
        // If successful then send a message
        ClientMessage("Saved game state to " $ FileName $ ".", 'System');
    }
}

exec function LoadGame(string FileName)
{
    local SaveGameState GameSave;

    // Instance the save game state
    GameSave = new class'SaveGameState';

    if (GameSave == None)
    {
	return;
    }

    // Scrub the file name
    ScrubFileName(FileName);

    // Attempt to deserialize the save game state object from disk
    if (class'Engine'.static.BasicLoadObject(GameSave, FileName, true, class'SaveGameState'.const.VERSION))
    {
        // Start the map with the command line parameters required to then load the save game state
        ConsoleCommand("start " $ GameSave.PersistentMapFileName $ "?Game=Animus.Animus_GameInfo?SaveGameState=" $ FileName);
    }
}

function ScrubFileName(out string FileName)
{
    // Add the extension if it does not exist
    if (InStr(FileName, ".sav",, true) == INDEX_NONE)
    {
	FileName $= ".sav";
    }

    FileName = Repl(FileName, " ", "_");                            // If the file name has spaces, replace then with under scores
    FileName = class'SaveGameState'.const.SAVE_LOCATION $ FileName; // Prepend the filename with the save folder location
}

defaultproperties
{
    CharacterClass=class'Animus.Hero'
}
