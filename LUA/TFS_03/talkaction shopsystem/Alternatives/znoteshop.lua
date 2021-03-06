-- Znote Shop v1.0 for Znote AAC on TFS 0.3.6+ Crying Damson.
function onSay(cid, words, param)
	local storage = 54073 -- Make sure to select non-used storage. This is used to prevent SQL load attacks.
	local cooldown = 15 -- in seconds.
	
	if getPlayerStorageValue(cid, storage) <= os.time() then
		setPlayerStorageValue(cid, storage, os.time() + cooldown)
		local accid = getAccountNumberByPlayerName(getCreatureName(cid))
		
		local type_desc = {
			"itemids",
			"pending premium (skip)",
			"pending gender change (skip)",
			"pending character name change (skip)",
			"Outfit and addons",
			"Mounts"
		}
		print("Player: " .. getCreatureName(cid) .. " triggered !shop talkaction.")
		-- Create the query
		local orderQuery = db.storeQuery("SELECT `id`, `type`, `itemid`, `count` FROM `znote_shop_orders` WHERE `account_id` = " .. accid .. ";")
		local served = false 

		-- Detect if we got any results
		if orderQuery ~= false then
			repeat
				-- Fetch order values
				local q_id = result.getDataInt(orderQuery, "id")
				local q_type = result.getDataInt(orderQuery, "type")
				local q_itemid = result.getDataInt(orderQuery, "itemid")
				local q_count = result.getDataInt(orderQuery, "count")
				print("Processing type "..q_type..": ".. type_desc[q_type])
				
				-- ORDER TYPE 1 (Regular item shop products)
				if q_type == 1 then
					served = true
					-- Get wheight
					local playerCap = getPlayerFreeCap(cid)
					local itemweight = getItemWeightById(q_itemid, q_count)
						if playerCap >= itemweight then
							local delete = db.storeQuery("DELETE FROM `znote_shop_orders` WHERE `id` = " .. q_id .. ";")
							result.free(delete)
							doPlayerAddItem(cid, q_itemid, q_count)
							doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Congratulations! You have recieved ".. q_count .." "..getItemNameById(q_itemid).."(s)!")
						else
							doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, "Need more CAP!")
						end
				end
				-- ORDER TYPE 5 (Outfit and addon)
				if q_type == 5 then
					served = true
					-- Make sure player don't already have this outfit and addon
					if not canPlayerWearOutfit(cid, q_itemid, q_count) then
						local delete = db.storeQuery("DELETE FROM `znote_shop_orders` WHERE `id` = " .. q_id .. ";")
						result.free(delete)
						doPlayerAddOutfit(cid,q_itemid,q_count)
						doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Congratulations! You have received a new outfit!")
					else
						doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, "You already have this outfit and addon!")
					end
				end

				-- ORDER TYPE 6 (Mounts)
				if q_type == 6 then
					served = true
					-- Make sure player don't already have this outfit and addon
					if not getPlayerMount(cid, q_itemid) then -- Failed to find a proper hasMount 0.3 function?
						local delete = db.storeQuery("DELETE FROM `znote_shop_orders` WHERE `id` = " .. q_id .. ";")
						result.free(delete)
						doPlayerAddMount(cid, q_itemid)
						doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Congratulations! You have received a new mount!")
					else
						doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, "You already have this mount!")
					end
				end
				
				-- Add custom order types here
				-- Type 1 is for itemids (Already coded here)
				-- Type 2 is for premium (Coded on web)
				-- Type 3 is for gender change (Coded on web)
				-- Type 4 is for character name change (Coded on web)
				-- Type 5 is for character outfit and addon (Already coded here)
				-- Type 6 is for mounts (Already coded here)
				-- So use type 7+ for custom stuff, like etc packages.
				-- if q_type == 7 then
				-- end
			until not result.next(orderQuery)
			result.free(orderQuery)
			if not served then
				doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "You have no orders to process in-game.")
			end
		else
			doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING, "You have no orders.")
		end
	else
		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Can only be executed once every "..cooldown.." seconds. Remaining cooldown: ".. getPlayerStorageValue(cid, storage) - os.time())
	end
	return false
end