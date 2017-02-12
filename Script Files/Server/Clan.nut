function LoadClansFromDatabase ( ) {
   
    local pClansData = [ ];
    local pClanData = { };
    local iClansCount = 0;
    
    iClansCount = GetNumberOfClans ( );
    
    for ( local i = 1 ; i <= iClansCount ; i++ ) {
    
        pClanData = GetCoreTable ( ).Classes.ClanData ( );
        
        pClansData.push ( pClansData );
    
    }
    
    // -- Return the table, even if it's empty. It will show that no clans exist to load.
    
    return pClansData;
    
}

// -------------------------------------------------------------------------------------------------

function GetNumberOfClans ( ) {

    return ReadIniInteger ( "Scripts/LURP/Data/Index.ini" , "General" , "iClanAmount" );

}

// -------------------------------------------------------------------------------------------------

function NewClanCommand ( pPlayer , szCommand , szParams ) {

    if ( !DoesPlayerHaveStaffPermission ( pPlayer , "ManageClans" ) ) {
    
        SendPlayerErrorMessage ( pPlayer , GetPlayerLocaleMessage ( pPlayer , "NoCommandPermission" ) );
        
        return false;
    
    }
    
    if ( !szParams ) {
    
        SendPlayerSyntaxMessage ( pPlayer , "/newclan <name>" );
        
        return false;
    
    }
    
    if ( szParams.len ( ) > 3 ) {
    
        SendPlayerErrorMessage ( pPlayer , "The full clan name must be at least three characters" );
        
        return false;
    
    }
    
    local pClanData = CreateNewClan ( szParams );
    
    ReloadAllClans ( );
    
    SendPlayerSuccessMessage ( pPlayer , "The '" + pClanData.szName + "' clan has been created! ID: " + pClanData.iDatabaseID );
    
    return true;

}

// -------------------------------------------------------------------------------------------------

function ReloadClansCommand ( pPlayer , szCommand , szParams ) {

    if ( !DoesPlayerHaveStaffPermission ( pPlayer , "ManageClans" ) ) {
    
        SendPlayerErrorMessage ( pPlayer , GetPlayerLocaleMessage ( pPlayer , "NoCommandPermission" ) );
        
        return false;
    
    }
    
    ReloadAllClans ( );
    
    return true;

}

// -------------------------------------------------------------------------------------------------

function ReloadAllClans ( ) {

    StopAllTurfWars ( );
    
    GetCoreTable ( ).Clans <- null;
    GetCoreTable ( ).Clans <- LoadClansFromDatabase ( );

}

// -------------------------------------------------------------------------------------------------

function StopAllTurfWars ( ) {

    return true;

}

// -------------------------------------------------------------------------------------------------

function TakeTurfCommand ( pPlayer , szCommand , szParams ) {

    return true;

}

// -------------------------------------------------------------------------------------------------

function GiveTurfCommand ( pPlayer , szCommand , szParams ) {

    if ( DoesPlayerHaveClanPermission ( pPlayer , "ClanOwner" ) ) {
    
        return false;
    
    }
    return true;

}

// -------------------------------------------------------------------------------------------------

function SetClanOwnerCommand ( pPlayer , szCommand , szParams ) {

    local pPlayerData = GetCoreTable ( ).Players [ pPlayer.ID ];
    
    if ( !DoesPlayerHaveStaffPermission ( pPlayer , "ManageClans" ) ) {
    
        SendPlayerErrorMessage ( pPlayer , GetPlayerLocaleMessage ( pPlayer , "NoCommandPermission" ) );
        
        return false;
    
    }
    
    if ( !szParams ) {
    
        SendPlayerSyntaxMessage ( pPlayer , "/clanowner <clan id> <owner id/name>" );
        SendPlayerAlertMessage ( pPlayer , "Use /clans for a list of clan ID's" );
        
        return false;
    
    }
    
    if ( NumTok ( szParams , " " ) != 2 ) {
    
        SendPlayerSyntaxMessage ( pPlayer , "/clanowner <clan id> <owner id/name>" );
        
        return false;
    
    }
    
    local iClan = FindPlayer ( GetTok ( szParams , " " , 1 ) );
    
    if ( IsNum ( iClan ) ) {
    
        SendPlayerErrorMessage ( pPlayer , "The clan ID must be a number!" );
        
        return false;
    
    }
    
    iClan = iClan.tointeger ( );
    
    local pClanData = GetClanFromDatabaseID ( iClan );
    
    if ( !pClanData ) {
    
        SendPlayerErrorMessage ( pPlayer , "That clan does not exist!" );
        
        return false;
    
    }
    
    local pTarget = FindPlayer ( GetTok ( szParams , " " , 2 ) );
    
    if ( !pTarget ) {
    
        SendPlayerErrorMessage ( pPlayer , "That player is invalid or offline" );
        
        return false;
        
    }
    
    local pTargetData = GetCoreTable ( ).Players [ pTarget.ID ];
    
    if ( pTargetData.iClan != 0 ) {
    
        if ( pTargetData.iClan == pClanData.iDatabaseID ) {
        
            SetClanOwner ( pTarget , pClanData );
            
            SendPlayerSuccessMessage ( pPlayer , format ( GetPlayerLocaleMessage ( pPlayer , "ClanLeaderSet" ) , pTarget.Name , pClanData.szName ) );
            
            return true;
        
        }
    
        SendPlayerErrorMessage ( pPlayer , GetPlayerLocaleMessage ( pPlayer , "PlayerAlreadyInClan" ) );
        
        return false;
    
    }
    
    return true;

}

// -------------------------------------------------------------------------------------------------

function SetClanTagCommand ( pPlayer , szCommand , szParams ) {
    
    local pPlayerData = GetCoreTable ( ).Players [ pPlayer.ID ];

    if ( !DoesPlayerHaveClanPermission ( pPlayer , pPlayerData.iClan , "EditTag" ) ) {
    
        SendPlayerErrorMessage ( pPlayer , GetPlayerLocaleMessage ( pPlayer , "NoCommandPermission" ) );
        
        return false;
    
    }
    
    if ( !szParams ) {
    
        SendPlayerSyntaxMessage ( pPlayer , "/clantag <new tag>" );
        
        return false;
    
    }

    return true;

}

// -------------------------------------------------------------------------------------------------

function DoesPlayerHaveClanPermission ( pPlayer , szClanFlag ) {

    local pPlayerData = GetCoreTable ( ).Players [ pPlayer.ID ];
    
    if ( DoesPlayerHaveStaffPermission ( pPlayer , "ManageClans" ) ) {
    
        return true;
    
    }
    
    if ( pPlayerData.iClan == pClanData.iDatabaseID ) {
    
        if ( HasBitFlag ( pPlayerData.iClanFlags , GetCoreTable ( ).BitFlags.ClanFlags [ szClanFlag ] ) ) {
        
            return true;
        
        }
        
        if ( HasBitFlag ( pPlayerData.iClanFlags , GetCoreTable ( ).BitFlags.ClanFlags [ "ClanOwner" ] ) ) {
        
            return true;
        
        }        
    
    }
    
    return false;

}

// -------------------------------------------------------------------------------------------------

function AreClansAllied ( pClan1Data , pClan2Data ) {

    // -- We are only going to check for pClan1Data's allies. They can add another clan as an ally, but it doesnt have to be two ways.
    // -- Meaning, clan 1 could consider clan 2 an ally, but clan 2 might not be the same for clan 1
    
    // -- Introduces a weakness though. If clan 1 leader allows clan 2 to use their stuff (vehicles and such), clan 2 might not have them
    // -- ... as an ally, which keeps clan 2 vehicles protected while they can use clan 1's vehicles.
    
    foreach ( ii , iv in pClan1Data.pAlliances ) {
    
        if ( iv.iClan == pClan2Data.iDatabaseID ) { 
            
            return true;
            
        }
    
    }
    
    return false;

}

// -------------------------------------------------------------------------------------------------

function SetClanOwner ( pPlayer , pClanData ) {

    local pPlayerData = GetCoreTable ( ).Players [ pPlayer.ID ];
    
    pPlayerData.iClan = pClanData.iDatabaseID;
    
    foreach ( ii , iv in GetCoreTable ( ).BitFlags.ClanFlags ) {
    
        GiveClanFlag ( pPlayer , iv );
    
    }
    
    pClanData.iOwner = pPlayerData.iDatabaseID;
    
    return true;

}

// -------------------------------------------------------------------------------------------------

function AddClanAlliance ( pClan1Data , pClan2Data ) {

    if ( AreClansAllied ( pClan1Data , pClan2Data ) ) {
        
        return false;
    
    }
    
    pClan1Data.pAlliances.push ( pClan2Data.iDatabaseID );
    
    return true;

}

// -------------------------------------------------------------------------------------------------

// -- THIS GOES LAST

print ( "[Server.Clan]: Script file loaded and ready." );

// -------------------------------------------------------------------------------------------------