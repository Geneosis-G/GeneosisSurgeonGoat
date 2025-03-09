class SurgeonGoat extends GGMutator;

struct BrainOriginInfos{
	var GGNpc currentOwner;
	var name originalOwnerName;
	var string originalOwnerActorName;
	var PhysicsAsset originalPhysicsAsset;
	var AnimSet originalAnimSet;
	var AnimTree originalAnimTreeTemplate;
	var array<NPCAnimationInfo> originalAnimations;
};
var array<BrainOriginInfos> brainInfos;

var GGNpc dummySwapper;
var int swapperBrainCount;
var float mSwapperSpawnRadius;

function AddBrainOwner(GGNpc ownerNPC)
{
	local int index;

	if(ownerNPC == none)
		return;

	if(brainInfos.Find('originalOwnerName', ownerNPC.Name) == INDEX_NONE)
	{
		index=brainInfos.Length;
		brainInfos.Add(1);
		brainInfos[index].originalOwnerName=ownerNPC.name;
		brainInfos[index].originalOwnerActorName=ownerNPC.GetActorName();
		brainInfos[index].currentOwner=ownerNPC;
		brainInfos[index].originalPhysicsAsset=ownerNPC.mesh.PhysicsAsset;
		brainInfos[index].originalAnimSet=ownerNPC.mesh.AnimSets[0];
		brainInfos[index].originalAnimTreeTemplate=ownerNPC.mesh.AnimTreeTemplate;
		brainInfos[index].originalAnimations.AddItem(ownerNPC.mDefaultAnimationInfo);
		brainInfos[index].originalAnimations.AddItem(ownerNPC.mRunAnimationInfo);
		brainInfos[index].originalAnimations.AddItem(ownerNPC.mAttackAnimationInfo);
		brainInfos[index].originalAnimations.AddItem(ownerNPC.mDanceAnimationInfo);
		brainInfos[index].originalAnimations.AddItem(ownerNPC.mPanicAtWallAnimationInfo);
		brainInfos[index].originalAnimations.AddItem(ownerNPC.mAngryAnimationInfo);
		brainInfos[index].originalAnimations.AddItem(ownerNPC.mIdleAnimationInfo);
		brainInfos[index].originalAnimations.AddItem(ownerNPC.mIdleSittingAnimationInfo);
		brainInfos[index].originalAnimations.AddItem(ownerNPC.mPanicAnimationInfo);
	}
}

function SetBrainCurrentOwner(GGNpc surgeryNPC, name ownerNPCName)
{
	local int index, animIndex;

	if(surgeryNPC == none || ownerNPCName == '')
		return;

	index=brainInfos.Find('originalOwnerName', ownerNPCName);
	if(index!=INDEX_NONE)
	{
		brainInfos[index].currentOwner=surgeryNPC;
		surgeryNPC.mesh.SetPhysicsAsset( brainInfos[index].originalPhysicsAsset, true);
		surgeryNPC.mesh.AnimSets[ 0 ] = brainInfos[index].originalAnimSet;
		surgeryNPC.mesh.SetAnimTreeTemplate( brainInfos[index].originalAnimTreeTemplate );
		surgeryNPC.mDefaultAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mRunAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mAttackAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mDanceAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mPanicAtWallAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mAngryAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mIdleAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mIdleSittingAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mPanicAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
	}
}

function bool HaveTransplantedBrain(GGNpc surgeryNPC)
{
	return brainInfos.Find('currentOwner', surgeryNPC) != INDEX_NONE;
}

function GetBrainOwnerNames(GGNpc surgeryNPC, out name ownerName, out string ownerActorName)
{
	local int index;

	index=brainInfos.Find('currentOwner', surgeryNPC);
	if(index!=INDEX_NONE)
	{
		ownerName=brainInfos[index].originalOwnerName;
		ownerActorName=brainInfos[index].originalOwnerActorName;
	}
}

function RestoreNPCMesh(GGNpc surgeryNPC)
{
	local int index, animIndex;

	index=brainInfos.Find('originalOwnerName', surgeryNPC.name);
	if(index != INDEX_NONE)
	{
		surgeryNPC.mesh.SetPhysicsAsset( brainInfos[index].originalPhysicsAsset, true);
		surgeryNPC.mesh.AnimSets[ 0 ] = brainInfos[index].originalAnimSet;
		surgeryNPC.mesh.SetAnimTreeTemplate( brainInfos[index].originalAnimTreeTemplate );
		surgeryNPC.mDefaultAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mRunAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mAttackAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mDanceAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mPanicAtWallAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mAngryAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mIdleAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mIdleSittingAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
		surgeryNPC.mPanicAnimationInfo=brainInfos[index].originalAnimations[animIndex++];
	}
}

function SpawnSwapperBrain()
{
	local ExtractedBrain tmpBrain, newBrain;
	local int index;
	//Only spawn brain if no other swapper brain available on the map
	foreach AllActors(class'ExtractedBrain', tmpBrain)
	{
		if(!tmpBrain.bPendingDelete && tmpBrain.contrClass == class'GGAIControllerSwapper')
		{
			return;
		}
	}

	if(dummySwapper == none || dummySwapper.bPendingDelete)
	{
		dummySwapper=Spawn(class'GGNpc',,,,,, true);
		dummySwapper.SetHidden(true);
		dummySwapper.SetPhysics(PHYS_None);
		dummySwapper.CollisionComponent=none;
	}
	//Create swapper brain
	newBrain=Spawn(class'ExtractedBrain',,, GetRandomSpawnLocation(),,, true);
	newBrain.SetSwapperBrain(swapperBrainCount);
	//WorldInfo.Game.Broadcast(self, "Swapper brain created: " $ newBrain);
	//Add fake brain owner
	AddBrainOwner(dummySwapper);
	index=brainInfos.Length-1;
	brainInfos[index].originalOwnerName=newBrain.mOwnerName;
	brainInfos[index].originalOwnerActorName=newBrain.mOwnerActorName;
	brainInfos[index].currentOwner=none;
}

function vector FindGoatCenter()
{
	local GGPlayerControllerGame pc;
	local vector center;
	local float count;
	local bool first;

	first=true;
	count=0;
	foreach WorldInfo.AllControllers( class'GGPlayerControllerGame', pc )
	{
		if( pc.IsLocalPlayerController() && pc.Pawn != none )
		{
			count+=1.f;
			if(first)
			{
				center=pc.Pawn.Location;
				first=false;
			}
			else
			{
				center+=pc.Pawn.Location;
			}

		}
	}
	if(count > 0)
	{
		center/=count;
	}
	else
	{
		center=GetALocalPlayerController().Pawn.Location;
	}

	return center;
}

function vector GetRandomSpawnLocation()
{
	local vector dest, center;
	local rotator rot;
	local float dist;
	local Actor hitActor;
	local vector hitLocation, hitNormal, traceEnd, traceStart;

	center=FindGoatCenter();

	rot=Rotator(vect(1, 0, 0));
	rot.Yaw+=RandRange(0.f, 65536.f);

	dist=mSwapperSpawnRadius;
	dist=RandRange(dist/2.f, dist);

	//dest=center;
	dest=center+Normal(Vector(rot))*dist;
	traceStart=dest;
	traceEnd=dest;
	traceStart.Z=10000.f;
	traceEnd.Z=-3000;

	hitActor = Trace( hitLocation, hitNormal, traceEnd, traceStart, true);
	if( hitActor == none )
	{
		hitLocation = traceEnd;
	}

	return hitLocation + vect(0, 0, 100);
	//return center + vect(0, 0, 100.f);
}

function SwapBrains(GGNpc sourceNPC, GGNpc destNPC)
{
	local GGAIController oldSourceContr, oldDestContr, newSourceContr, newDestContr;
	local name sourceName, destName;
	local string destActorName, sourceActorName;

	if(sourceNPC == none || destNPC == none)
		return;
	//WorldInfo.Game.Broadcast(self, "SwapBrains" @ sourceNPC.Controller @ destNPC.Controller);
	//Add brains to the list if needed
	if(!HaveTransplantedBrain(sourceNPC))
	{
		AddBrainOwner(sourceNPC);
	}
	if(!HaveTransplantedBrain(destNPC))
	{
		AddBrainOwner(destNPC);
	}
	//Remove old source brain and create new one
	GetBrainOwnerNames(sourceNPC, sourceName, sourceActorName);
	if(sourceNPC.Controller != none)
	{
		oldSourceContr=GGAIController(sourceNPC.Controller);
		newSourceContr=oldSourceContr;
		sourceNPC.Controller.Unpossess();
		/*if(oldSourceContr != none)
		{
			newSourceContr=Spawn(oldSourceContr.class, oldSourceContr.Owner);
			oldSourceContr.Destroy();
			if(GGAIControllerSwapper(newSourceContr) != none)
			{
				GGAIControllerSwapper(newSourceContr).previousBody=sourceNPC;
			}
		}*/
	}
	sourceNPC.mAnimNodeSlot.StopAnim();
	sourceNPC.mAnimNodeSlot.StopCustomAnim(0.1f);
	//Remove old dest brain and create new one
	GetBrainOwnerNames(destNPC, destName, destActorName);
	if(destNPC.Controller != none)
	{

		oldDestContr=GGAIController(destNPC.Controller);
		newDestContr=oldDestContr;
		//WorldInfo.Game.Broadcast(self, newDestContr @ "before unpossess" @ newDestContr.HasProtectItemsButNoRoute() @ newDestContr.IsProtectingSelf() @ newDestContr.ShouldCheckDistToThreats() @ newDestContr.IsProtectingItem());
		destNPC.Controller.Unpossess();
		/*if(oldDestContr != none)
		{
			newDestContr=Spawn(oldDestContr.class, oldDestContr.Owner);
			oldDestContr.Destroy();
			if(GGAIControllerSwapper(newDestContr) != none)
			{
				GGAIControllerSwapper(newDestContr).previousBody=destNPC;
			}
		}*/
	}
	destNPC.mAnimNodeSlot.StopAnim();
	destNPC.mAnimNodeSlot.StopCustomAnim(0.1f);
	//Give new source brain to dest NPC
	if(newSourceContr != none)
	{
		newSourceContr.Possess(destNPC, false);
		newSourceContr.StandUp();
		if(destNPC.mIsRagdoll)
		{
			destNPC.StandUp();
		}
		SetBrainCurrentOwner(destNPC, sourceName);
	}
	//Give new dest brain to source NPC
	if(newDestContr != none)
	{
		newDestContr.Possess(sourceNPC, false);
		//WorldInfo.Game.Broadcast(self, newDestContr @ "after possess" @ newDestContr.HasProtectItemsButNoRoute() @ newDestContr.IsProtectingSelf() @ newDestContr.ShouldCheckDistToThreats() @ newDestContr.IsProtectingItem());
		newDestContr.StandUp();
		if(sourceNPC.mIsRagdoll)
		{
			sourceNPC.StandUp();
		}
		SetBrainCurrentOwner(sourceNPC, destName);
	}
}

DefaultProperties
{
	mMutatorComponentClass=class'SurgeonGoatComponent'

	mSwapperSpawnRadius=5000.f
}