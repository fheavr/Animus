/* Class for specifying items dropped from a pawn's
 * inventory rather than being previously placed */
class Animus_DroppedPickup extends DroppedPickup;

/** give pickup to player */
function GiveTo( Pawn P )
{
    local Animus_Inventory inv;

	if( Inventory != None )
	{
        inv = Animus_Inventory(Inventory);
		inv.AnnouncePickup(P);
		inv.aGiveTo(P);
		Inventory = None;
	}
	PickedUpBy(P);
}