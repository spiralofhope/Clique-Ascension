#!/usr/bin/env  sh
# Roll back Clique.lua if it gets updated, to restore raid functionality.
# This is a terrible idea; what needs to happen is


file='Clique.lua'


\git  commit  "$file"  --message='Checkin from the official Ascension update.'

# This will be a bad idea:
\echo  '\git  checkout  HEAD^  "$file"'
#\git  checkout  HEAD^  "$file"

\git  diff  HEAD^  Clique.lua



:<<'}'
{


-- /run CompactRaidFrameContainer:Hide()
-- /run CompactRaidFrame2:Hide()

--		CompactRaidFrame2Container, CompactRaidFrame2Elements, CompactRaidFrame2HealthBar, CompactRaidFrame2PowerBar, 
--		CompactRaidFrame3Container, CompactRaidFrame3Elements, CompactRaidFrame3HealthBar, CompactRaidFrame3PowerBar, 
-- CompactRaidFrameContainerBorderFrame:Hide()
-- Must reloadui if raid size changes
-- Each person who joins is appended as a new number. For example, a third person to join is CompactRaidFrame3 which wouldn't have existed in the initial reloadui.
-- Once that person exists, then the CompactRaidFrame_ is populated and then any person can leave/join and be reassigned that slot, and Clique will work as-expected.



-- /run CompactRaidFrameContainer:SetScale(1.6)
CompactRaidFrameContainer:SetScale(1.6)
-- TODO - create an onevent to 


function Clique:EnableFrames()
    local tbl = {
		PlayerFrame,
		PetFrame,
		PartyMemberFrame1,
		PartyMemberFrame2,
		PartyMemberFrame3,
		PartyMemberFrame4,
		PartyMemberFrame1PetFrame,
		PartyMemberFrame2PetFrame,
		PartyMemberFrame3PetFrame,
		PartyMemberFrame4PetFrame,
		TargetFrame,
		TargetFrameToT,
		FocusFrame,
        FocusFrameToT,
        Boss1TargetFrame,
        Boss2TargetFrame,
        Boss3TargetFrame,
        Boss4TargetFrame,
		CompactRaidFrame1, 
		CompactRaidFrame2, 
		CompactRaidFrame3, 
		CompactRaidFrame4,
		CompactRaidFrame5,
		CompactRaidFrame6,
		CompactRaidFrame7,
		CompactRaidFrame8,
		CompactRaidFrame9,
		CompactRaidFrame10,
		CompactRaidFrame11,
		CompactRaidFrame12,
		CompactRaidFrame13,
		CompactRaidFrame14,
		CompactRaidFrame15,
		CompactRaidFrame16,
		CompactRaidFrame17,
		CompactRaidFrame18,
		CompactRaidFrame20,
		CompactRaidFrame21,
		CompactRaidFrame22,
		CompactRaidFrame23,
		CompactRaidFrame24,
		CompactRaidFrame25,
		CompactRaidFrame26,
		CompactRaidFrame27,
		CompactRaidFrame28,
		CompactRaidFrame30,
		CompactRaidFrame31,
		CompactRaidFrame32,
		CompactRaidFrame33,
		CompactRaidFrame34,
		CompactRaidFrame35,
		CompactRaidFrame36,
		CompactRaidFrame37,
		CompactRaidFrame38,
		CompactRaidFrame30,
		CompactRaidFrame31,
		CompactRaidFrame32,
		CompactRaidFrame33,
		CompactRaidFrame34,
		CompactRaidFrame35,
		CompactRaidFrame36,
		CompactRaidFrame37,
		CompactRaidFrame38,
		CompactRaidFrame39,
		CompactRaidFrame40,
    }
    
    for i,frame in pairs(tbl) do
		rawset(self.ccframes, frame, true)
    end
end

}
