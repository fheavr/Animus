class Citizen_Male extends UTPawn
  placeable;

var(NPC) SkeletalMeshComponent NPCMesh;
var(NPC) class<AIController> NPCController;

simulated event PostBeginPlay()
{
    if (NPCController != none)
    {
        // overwrite the NPCController with ours
        ControllerClass = NPCController;
    }
    
    Super.PostBeginPlay();
}

// override to do nothing

defaultproperties
{
    Begin Object Class=CylinderComponent Name=CylinderComp
        CollisionRadius=32
        CollisionHeight=90
        CollideActors=true        
        BlockActors=true
    End Object
    
    Components.Add( CylinderComp )
    CollisionComponent=CylinderComp  
    
    // default NPC mesh
    Begin Object Class=SkeletalMeshComponent Name=NPCMesh0
        SkeletalMesh=SkeletalMesh'Characters.Citizen_Male'
        PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
        AnimSets(0)=AnimSet'Characters.Male_Relaxed_Stand'
        AnimSets(1)=AnimSet'Characters.Male_Walking'
        AnimSets(2)=AnimSet'Characters.Male_Jump'
        AnimSets(3)=AnimSet'Characters.Male_Climb'
        AnimSets(4)=AnimSet'Characters.Male_Cast'
        AnimSets(5)=AnimSet'Characters.Male_Slash'
        AnimtreeTemplate=AnimTree'Characters.Default_Male'
        Scale=0.6
        Translation=(Z=-95)
    End Object
    NPCMesh=NPCMesh0
    Mesh=NPCMesh0
    Components.Add(NPCMesh0)

    //Points to your custom AIController class - as the default value
    NPCController=class'Animus_NPCController'
    SuperHealthMax=300
}