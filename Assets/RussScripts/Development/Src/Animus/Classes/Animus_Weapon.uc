/**
 * Thanks to:
 * http://forums.epicgames.com/threads/720246-Source-code-Isometric-cam-Move-Aim-Hold-Weapon
 */
class Animus_Weapon extends UDKWeapon
    dependson(UTPlayerController)
    config(Weapon)
    abstract;

var name AttachmentSocket;
var name WeaponAttachmentSocketName;
var SkeletalMeshComponent WeaponMesh;

var int               damage;        // Damage done by the weapon
var Animus_DamageType damageType;
var int               hit_breadth;   // the angle spread of attack
var float             hit_depth;     // the distance forward of attack
var name              atk_anim;      // atack animation name
var float             atk_time;
var ParticleSystem    hit_effect;    // Particle effect to spawn when hitting a pawn
var float             momentum;      // Hit momentum, very high number.

var Animus_Pawn temp_pawn;

var class<Animus_Inventory> item;    // associated item when in storage

simulated event PostBeginPlay()
{
    Super.PostBeginPlay();
    
    // allow attack animation to be specified per weapon
    atk_anim='Male_Slash_Animation';
}

/* Attaches the weapon to the specified socket of a model */
simulated function AttachWeaponTo( SkeletalMeshComponent MeshCpnt, optional Name SocketName )
{
	local Animus_Pawn P;

	super.AttachWeaponTo(MeshCpnt, SocketName);

	P = Animus_Pawn(Instigator);

    SetBase(P,,P.Mesh,WeaponAttachmentSocketName);
    P.Mesh.AttachComponentToSocket(Mesh,WeaponAttachmentSocketName);
    //P.pawn_weapon = self;
    temp_pawn = P;
}

simulated function Activate()
{
	super.Activate();
	AttachWeaponTo(Instigator.Mesh);
}

simulated function phys_attack(byte FireModeNum)
{
    `log("StartFire entered\n");

    // player is not allowed to attack until current attack has completed
    if (Animus_Pawn(owner).AttackSlot.bIsPlayingCustomAnim == true)
        return;

    `log("StartFire continued\n");
        
    /* Could put additional animations in here */
    Animus_Pawn(owner).AttackSlot.PlayCustomAnim('Male_Slash_Animation', atk_time,,, false);
    
    // damage is dealt halfway through animation to all within sword arc
    //SetTimer(atk_time/2, false, 'compute_atk');
    compute_atk();
}

function bool withinSwordArc(vector owner_loc, rotator forward, vector enemy_loc)
{
    local rotator angle;
    local vector  difference_vector; // the vector between a forward, range bounded point and the enemy renage bounded direction
    local vector  forward_bound;     // the vector representing a forward range bounded location
    local vector  breadth_bound;
    local vector tmp1;
    local vector tmp2;
    
    tmp1 = Normal(vector(forward));
    tmp2 = tmp1 * hit_depth;
    `log("hit_depth is "@hit_depth);
    `log(""@tmp1@" vs "@tmp2);
    
    /* all vectors are in local coordinates */
    forward_bound = Normal(vector(forward)) * hit_depth;
    
    // calculate the difference between forward and enemy vectors
    difference_vector = Normal(enemy_loc - owner_loc) * hit_depth - forward_bound;
    
    // calculate the difference between the forward and boundary vectors
    angle = forward;
    angle.Yaw += hit_breadth;
    breadth_bound = Normal(vector(angle)) * hit_depth - forward_bound;
    
    /* using the cosine law, the angle between two vectors is: |  c^2 = a^2 + b^2 - 2abcosC
     * since A and B are both our range this is                |  c^2 = 2R (R - 2RcosC)
     * Thus in order to check if the enemy is within range     |
     * all we have to do is compare the values of cosC         |
     * or the values of c^2 (provided C is less than 90deg)    |
     */
     
    `log("owner location is "@owner_loc@"\n");
    `log("we think forward is "@forward@"\n");
    `log("we think the enemy is at"@enemy_loc@"\n");
    `log(""@forward_bound@" "@difference_vector@" "@breadth_bound);
     
    if (VSize(breadth_bound) < VSize(difference_vector))
    {
    `log("false 1\n");
        return false;
    }
    else
    {
    `log("true\n");
        return true;
    }
    
}

function compute_atk()
{
    local Animus_Pawn hitpawn;
    local int adjustedDamage;

    `log("compute_atk entered");
    
    // check every pawn within sword distance
    foreach WorldInfo.AllPawns(class'Animus_Pawn', hitpawn, owner.location, hit_depth)
	{
        // check if pawn is an enemy
        if (hitpawn != None && !hitpawn.bIsPlayer && !hitpawn.bIsAlly)
        {
            // check it is within forward sword arc
            if (withinSwordArc(owner.Location, owner.Rotation, hitpawn.Location))
            {
                // calculate and deal damage
                adjustedDamage = Animus_Pawn(owner).calculateDamage(damageType.animus_damageSpec, damage, 10000);
                hitpawn.TakeDamage(adjustedDamage, Animus_Pawn(owner).Controller, hitpawn.Location - Normal(hitpawn.location - owner.location), Normal(hitpawn.location - owner.location) * momentum, damageType.Class,, Animus_Pawn(owner));

                //spawn particle effect at hitlocation.	
                //WorldInfo.MyEmitterPool.SpawnEmitter(pawnhiteffect,Hitlocation,, Traced);
            }
        }
    }
}

DefaultProperties
{
	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent0
		CollideActors=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bUseAsOccluder=FALSE
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=FALSE
	End Object
	Components.Add(SkeletalMeshComponent0)
	Mesh=SkeletalMeshComponent0
	WeaponAttachmentSocketName=RHand
    
    // allow animation speed to be
    // specified per weapon
    atk_time=2.2f
    
    momentum=20000
    hit_breadth=8192 //  65536/8 = 360/8 = 45 degrees
    hit_depth=400
    
    // specify what type of damage this sword does
    Begin Object Class=Physical_DamageType Name=dt
    End Object
    
    damage = 35
    damageType=dt
    
    item=None
}