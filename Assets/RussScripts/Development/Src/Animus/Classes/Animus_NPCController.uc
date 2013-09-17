/* Thanks http://www.moug-portfolio.info/udk-ai-pawn-movement/ 
 * for the base code
 * also http://willyg302.wordpress.com/2011/12/25/learning-unrealscript-part-4-building-an-ai-class/
 * also thanks http://forums.epicgames.com/threads/798718-Code-%28New-Bot-Added%29-Simple-Random-Movement-AI
 */

class Animus_NPCController extends UDKBot
    dependson(Animus_Pawn);
    
var() Animus_Pawn Controlled_Pawn;

var Actor  NavFinalActor; // nearest actor to destination
var vector NavFinalDest;  // final destination
var Actor  NavStep;       // node on the way to destination

/* Tools for the Back-up navigation method */
var Actor  NavObstacle;   // object obstructing our path
var vector InFront;
var vector X,Y,Z;
var vector HitLoc, HitNormal;

var ACTION next_action;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
    MoveTimer=-1;
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

/* While in this state arbitrarily choose destinations and wander. Tries to use
 * any path nodes in the area for navigation, but defaults to environment
 * sampling method */
auto state Wander
{
Begin:
    if (NavFinalActor == None ||
        Pawn.Anchor == NavFinalActor ||
        Pawn.ReachedDestination(NavFinalActor))
    {
        NavFinalActor = FindRandomDest();
        NavStep = None;
    }

    if (NavFinalActor != None &&
        (NavStep == None ||
         Pawn.ReachedDestination(NavStep)))
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

event Possess(Pawn inPawn, bool bVehicleTransition)
{
    super.Possess(inPawn, bVehicleTransition);
    
    // IMPORTANT - reinits the physics which lets the pawn move
    Pawn.SetMovementPhysics();
        
    Controlled_Pawn = Animus_Pawn(Pawn);
}

defaultproperties
{
}