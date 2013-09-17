/* Thanks http://www.moug-portfolio.info/udk-ai-pawn-movement/ 
 * for the base code
 * also http://willyg302.wordpress.com/2011/12/25/learning-unrealscript-part-4-building-an-ai-class/
 * also thanks http://forums.epicgames.com/threads/798718-Code-%28New-Bot-Added%29-Simple-Random-Movement-AI
 */
 
/*
 * This is the AI responsible for NPCs that would be fighting with your outside of the city
 * as such, it has the capability for attack, as well as just navigation
 */
class Animus_AllyController extends UDKBot
    dependson(Animus_Pawn);
    
enum ACTION
{
    // physical actions
    ACT_ATTACK,
    ACT_CLOSE,
    // magical actions
    ACT_FIRE,
    ACT_LIGHTNING,
    ACT_WIND
};

var() Animus_Pawn Controlled_Pawn;
var() Animus_Pawn Target_Pawn;

var float Cast_Frequency;
var float Sight_Range; // range forward from enemy
var float Detect_Range; // circular range around enemy
var float Forget_Range; // how far one must be for enemy to stop tracking

var Actor  NavFinalActor; // nearest actor to destination
var vector NavFinalDest;  // final destination
var Actor  NavStep;       // node on the way to destination

/* Tools for the Back-up navigation method */
var Actor  NavObstacle;   // object obstructing our path
var vector InFront;
var vector X,Y,Z;
var vector HitLoc, HitNormal;

var ACTION next_action;
var bool   bCanCast; // has enough time elapsed to be able to cast again?

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
}

/* function to enable spell casting after a certain
 * duration */
function CastTimer()
{
    bCanCast = true;
}

// check to see if the player is within the enemies visible line of sight
function bool Sight(Animus_Pawn P)
{
    return CanSee(P) && Sight_Range >= VSize2D(Pawn.Location - P.Location);
}

// check to see if player is within detectable vicinity
function Animus_Pawn Detected()
{
    local Animus_Pawn P;

    foreach WorldInfo.AllPawns(class'Animus_Pawn', P, Pawn.Location, Detect_Range)
	{
        if (P != None)   // check if a pawn is returned
        {
            // check sight and distance from pawn vs detection ranges
            if (Sight(P) && !P.bIsAlly)
            {
                Pawn.SetDesiredRotation(Rotator(Normal(P.Location)));
                Target_Pawn = P;
                return P;
            }
        }
    }
    return None;
}

/*
 * return the max index of the pased in indices
 * used to determine the best elements to use
 */
function int getMaxIndex(float p, float f, float l, float w)
{
    if (p >= f && p >= l && p >= w)
        return 0;

    else if (f >= l && f >= w)
        return 1;
    
    else if (l >= w)
        return 2;

    else
        return (w > 0) ? 3 : -1;
}

/* this function lets the pawn determine how to act towards another pawn, hostile or not
 * it is used to make sure that enemy spirits do not attack each other */
function ACTION choose_action()
{
    local int i;
    local int distance;
    local Stats pawn_stats;
    local Stats target_stats;
    local int max_index;
    
    /* a weight for the use of each type
     * of spell:
     * [0] : physical
     * [1] : fire
     * [2] : lightning
     * [3] : wind
     */
    local float action_index[4];
    
    // if health below 50% pawn can heal, do so
    if (Controlled_Pawn.GetHealthPercent() < 0.5)
    {
        if (Controlled_Pawn.pawn_spell_info[2].can_use == 1 &&
            Controlled_Pawn.pawn_spell_info[2].spell1.enabled == 1)
        return ACT_WIND;
    }
    
    distance = VSize2D(Target_Pawn.Location - Pawn.Location);
    pawn_stats = Controlled_Pawn.pawn_stats;
    target_stats = Target_Pawn.pawn_stats;
    
    /* determine effectiveness of elements against target
     * normalize out the subtraction of physical defence, since it should never
     * be negative (others stats can be)
     * */
     
    //`log("ControlledPawn = " $ Controlled_Pawn $ " pawn_stats = " $ pawn_stats);
    //`log("TargetPawn = " $ Target_Pawn $ " target_stats = " $ target_stats);
    action_index[0]  = pawn_stats.atk * (1 - target_stats.physical_res / 100);
    action_index[1]  = (target_stats.def + pawn_stats.fire_atk - target_stats.fire_def) * (1 - target_stats.fire_res / 100);
    action_index[2]  = (target_stats.def + pawn_stats.lightning_atk - target_stats.lightning_def) * (1 - target_stats.lightning_res / 100);
    action_index[3]  = (target_stats.def + pawn_stats.wind_atk - target_stats.wind_def) * (1 - target_stats.wind_res / 100);

    // add weight to physical attack if the attacker is very close
    if (distance < 30)
        action_index[0] += 5;
    
    // filter out elements that are not available
    // (from 1 b/c attack is always available)
    for (i=1; i < 4; i++)
    {
        if (Controlled_Pawn.pawn_spell_info[i-1].can_use == 0)
        {
            action_index[i] = 0;
        }
    }
    
    // work through the indices in order of weight looking for a possible solution
    max_index = getMaxIndex(action_index[0], action_index[1], action_index[2], action_index[3]);
    
    switch(max_index)
    {
        /* TODO: allow the AI to use a second type of magic instead of defaulting to physical
         *       unimportant as no enemies in this game need this... */
        case 1:
            return ACT_FIRE;
        case 2:
            return ACT_LIGHTNING;
        case 3:
            return ACT_WIND;
        case 0: // use physical attacking as the default
        default:
            return ACT_CLOSE;
    }
}

function bool NavigateObstacle(optional Actor target=None)
{
    local int LeftRight;
    local vector forward;
    local Rotator adjust;

    /* x is in front of the player
     * y is to the left and right of the player
     * 16500 is just over a 90 deg search in either
     * direction for new path
     */
    
    // make a random number
    LeftRight = Rand(16500) - Rand(16500);
    adjust  = Pawn.Rotation;
    adjust.Yaw += LeftRight;
    
     /* Convert global forward vector to
      * local coordinates */
    forward = vect(40, 0, 0) >> adjust;
    
    // trace in new orientation to check for collision
    NavObstacle = Trace(HitLoc, HitNormal, forward, Pawn.Location);
    
    // still a collision, try once more
    if (NavObstacle != None &&
        NavObstacle != target)
    {
        LeftRight = Rand(17500) - Rand(17500);
        adjust  = Pawn.Rotation;
        adjust.Yaw += LeftRight;
        forward = vect(40, 0, 0) >> adjust;
        NavObstacle = Trace(HitLoc, HitNormal, forward, Pawn.Location);
    }
    
    /* if still a collision then rotate the pawn 45 deg left
     * and give up, this will let the next iteration have a
     * different range to work with */
    if (NavObstacle != None &&
        NavObstacle != target)
    {
        adjust = Pawn.Rotation;
        adjust.yaw -= 8000;
        if (adjust.yaw < 0)
            adjust.yaw += 65536; // add 360 deg to keep our orientation reasonable
        Pawn.SetDesiredRotation(adjust);
        NavFinalDest = Pawn.Location;
        
        return false;
    }
    else  //if we trace nothing
    {
        //move there
        NavFinalDest = forward;
        return true;
    }
}

/* Find A new travel location using environment sampling rather than
 * path nodes */
function bool SetDestFallback(optional Actor target=None)
{
    GetAxes(Pawn.Rotation, X,Y,Z);

    if (target == None)
        InFront = Pawn.Location + 200 * X;
    else
    {
        InFront = Pawn.Location + Normal(target.Location - Pawn.Location) * 100; // vector towards target
    }
        
    // trace in front
    NavObstacle = Trace(HitLoc, HitNormal, InFront, Pawn.Location);
    // DrawDebugSphere( HitLoc, 30, 10, 0, 255, 0 );

    if (NavObstacle != None &&
        NavObstacle != target) //theres something in front (other than target)
    {
        // trace randomly left or right
        return NavigateObstacle(target);
    }
    else  //theres nothing in front
    {
        // move forward
        NavFinalDest = InFront;
        return true;
    }
}

/* While in this state arbitrarily chose destinations and wander. Tries to use
 * any path nodes in the area for navigation, but defaults to environment
 * sampling method */
auto state Wander
{
Begin:
    if(Detected() == None)
    {
        if (NavFinalActor == None ||
            ActorReachable(NavFinalActor) == false ||
            VSize2D(NavFinalActor.Location - Pawn.Location) < 5)
        {
            NavFinalActor = FindRandomDest();
            NavStep = None;
        }

        if (NavStep == None ||
            VSize2D(NavStep.Location - Pawn.Location) < 5)
        {
            NavStep = FindPathToward(NavFinalActor);
        }
        
        if (NavStep == None)
        {
            /* Path node navigation is failing, revert
             * to old method of travel */
            if (SetDestFallback())
                MoveTo(NavFinalDest);
        }
        else
        {
            MoveToward(NavStep);
        }
        
        Sleep(0.1);
        GoTo('Begin');
    }
    `log("Player Detected");
    GoToState('Attack');
}

state Attack // approach the target
{
    function bool CheckSpell(Spell spell, int stamina, int distance)
    {
    /*
        `log("range = " $ spell.range $ " vs distance = " $ distance);
        `log("cost = " $ spell.cost $ " vs stamina = " $ stamina);
        `log("enabled = " $ spell.enabled);
     */
        if (spell.enabled == 1 &&
            spell.cost < stamina &&
            spell.range > distance)
            return true;
        else
            return false;
    }
    // perform the most expensive spell that pawn can, that will hit
    // the player
    function Cast(ACTION attack_action)
    {
        local int     stamina;
        local int     distance;
        local Element element;
        
        `log("Casting spell " $ attack_action);
        distance = VSize2D(Target_Pawn.Location - Pawn.Location);
        
        switch (attack_action)
        {
            case ACT_FIRE:
                stamina = Controlled_Pawn.GetFireStamina();
                element = Controlled_Pawn.pawn_spell_info[0];
                switch(Rand(3)) // add some randomization to spell casting
                {
                    /* NPCs will not cast the firestorm spell
                    case 2:
                        if (CheckSpell(element.spell3, stamina, distance))
                        {
                            Controlled_Pawn.Magic_Firestorm(Target_Pawn);
                            break;
                        }
                    */
                    case 1:
                        if (CheckSpell(element.spell2, stamina, distance))
                        {
                            Controlled_Pawn.Magic_Heat_wave(Target_Pawn);
                        }
                        break;
                    default:
                        if (CheckSpell(element.spell1, stamina, distance))
                        {
                            Controlled_Pawn.Magic_Fireball(Target_Pawn);
                            break;
                        }
                }
                break;
            case ACT_LIGHTNING:
                stamina = Controlled_Pawn.GetLightningStamina();
                element = Controlled_Pawn.pawn_spell_info[1];
                if (CheckSpell(element.spell3, stamina, distance))
                    Controlled_Pawn.Magic_Storm(Target_Pawn);
                else if (CheckSpell(element.spell2, stamina, distance))
                    Controlled_Pawn.Magic_Chain_Lightning(Target_Pawn);
                else if (CheckSpell(element.spell1, stamina, distance))
                    Controlled_Pawn.Magic_Lightning_bolt(Target_Pawn);
                break;
            case ACT_WIND:
                stamina = Controlled_Pawn.GetWindStamina();
                element = Controlled_Pawn.pawn_spell_info[2];
                if (CheckSpell(element.spell1, stamina, distance))
                    Controlled_Pawn.Magic_Breeze();
                else if (CheckSpell(element.spell4, stamina, distance))
                    Controlled_Pawn.Magic_Tornado(Target_Pawn);
                else if (CheckSpell(element.spell3, stamina, distance))
                    Controlled_Pawn.Magic_Cutting_wind(Target_Pawn);
                else if (CheckSpell(element.spell2, stamina, distance))
                    Controlled_Pawn.Magic_Tail_wind(Target_Pawn);
                break;
            case ACT_ATTACK:
            default:
                // do nothing
        }
    }
    
Begin:
    if (Target_Pawn == None ||
        VSize2D(Target_Pawn.Location - Pawn.Location) > Forget_Range)
    {
        Target_Pawn=None;
        GoToState('Wander');
    }

    next_action = choose_action();
    
    if (next_action == ACT_CLOSE ||
        bCanCast == false)
    {
        GoToState('Track');
    }
    else
    {
        Cast(next_action);
        bCanCast = false;
        SetTimer(Cast_Frequency, false, 'CastTimer');
    }
    
    GoTo('Begin');
}

state Track
{
Begin:
    //Sleep(0.1);
    /*
    if (ActorReachable(Target_Pawn) == false ||
           Target_Pawn.Location == Pawn.Location )
    {
        GoToState('Attack');
    }
    */

    if (NavStep == None ||
        NavStep.Location == Pawn.Location)
    {
        NavStep = FindPathToward(Target_Pawn);
    }
    if (NavStep == None)
    {
        /* unable to track through nodes, go back to old method of
         * chasing the player */
        if (SetDestFallback(Target_Pawn))
            MoveTo(NavFinalDest);
    }
    else
    {
        // travel to the closer of node or player
        if (VSize2D(Target_Pawn.Location - Pawn.Location) >
            VSize2D(NavStep.Location - Pawn.Location))
            MoveToward(NavStep);
        else
        {
            // doing this should allow minor obstacle avoidance
            if (SetDestFallback(Target_Pawn))
                MoveTo(NavFinalDest);
        }
    }
    GoToState('Attack');
}

event Possess(Pawn inPawn, bool bVehicleTransition)
{
    super.Possess(inPawn, bVehicleTransition);
    
    // IMPORTANT - reinits the physics which lets the pawn move
    Pawn.SetMovementPhysics();
        
    Controlled_Pawn = Animus_Pawn(Pawn);
    
    // flag the pawn as ally so it wont be attacked by other people on our side
    Controlled_Pawn.bIsAlly = true;
}

defaultproperties
{
    bCanCast=true
    Sight_Range=600
    Detect_Range=400
    Forget_Range=800
    Cast_Frequency=2.0
}