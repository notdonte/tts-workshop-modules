pID = "Custom_Cards"
version = '1.0.8'
UPDATE_URL='https://raw.githubusercontent.com/notdonte/tts-workshop-modules/main/customcards.lua'
Style={} --can be ignored
function registerModule() --Register the mod with the encoder.
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    properties = {
    propID = pID,
    name = "Custom Card",
    values = {},
    funcOwner = self,
    tags="basic",
    visible_in_hand = 1,
    activateFunc ='toggleProp'
    }
    enc.call("APIregisterProperty",properties)
  end
end
function toggleProp(obj,ply)
  enc = Global.getVar('Encoder')
  enc.call("APItoggleProperty",{obj=obj,propID=pID})
  enc.call("APIrebuildButtons",{obj=obj})
end
function onLoad(save_state)
  Wait.condition(registerModule,function() return Global.getVar('Encoder') ~= nil and true or false end)
end
function createButtons(t) --The encoder calls this when
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    editing = enc.call("APIgetEditing",{obj=t.obj})
    if editing == nil then
      local o = t.obj
      local instring = o.getDescription()
      local outstring = {}
      for str in string.gmatch(instring, "[^\n]*") do
        table.insert(outstring, str)
      end

      if #outstring > 6 then
          local new_outstring = ""
          for i = 7, #outstring, 2 do
              new_outstring = new_outstring .. outstring[i] .. "\n"
          end
          new_outstring = string.sub(new_outstring, 1, string.len(new_outstring)-1)
          outstring[7] = new_outstring
      end
      if o.getVar('invertText')== true then
        textColor = {r=1, g=1, b=1}
      else
        textColor = {r=0, g=0, b=0}
      end
	  if o.getVar('isPlaneswalker')== true then
        textColor = {r=0, g=0, b=0}
		powerTextColor = {r=1, g=1, b=1}
		titleOffset = {0, 0.4, -1.34}
		powerOffset = {0.835, 0.4, 1.3}
      else
        textColor = {r=0, g=0, b=0}
		powerTextColor = {r=0, g=0, b=0}
		titleOffset = {0, 0.4, -1.3}
		powerOffset = {0.735, 0.4, 1.3}
      end
      local dataTitle = {click_function = "updateButtonLabels", function_owner = o, label = o.getName(), position = titleOffset, scale = {0.5, 0.5, 0.5}, width = 0, height = 0, font_size = 125, font_color = textColor}
      local dataDescription = {click_function = "updateButtonLabels", function_owner = o, label = outstring[7], position = {0, 0.4, 0.85}, scale = {0.5, 0.5, 0.5}, width = 0, height = 0, font_size = 90, font_color = textColor}
      local typeLine = {click_function = "updateButtonLabels", function_owner = o, label = outstring[3], position = {0, 0.4, 0.275}, scale = {0.5, 0.5, 0.5}, width = 0, height = 0, font_size = 85, font_color = textColor}
      local scryber = {click_function = "recordName", function_owner = self, label = o.getGMNotes(), position = {-0.43, 0.4, 1.43}, scale = {0.5, 0.5, 0.5}, width = 400, height = 80, font_size = 50, font_color = {1,1,1}, color = {0,0,0}}
      o.createButton(dataTitle)
      o.createButton(dataDescription)
      o.createButton(typeLine)
      o.createButton(scryber)
      
      -- DS: Hi I'm invading this function as well lol

      -- old mana cost display system
      --local manaCost = {click_function = "updateButtonLabels", function_owner = self, label = outstring[1], position = {0.43, 0.64, -1.1}, scale = {0.5, 0.5, 0.5}, width = 1000, height = 200, font_size = 125, color = {0.74,0.63,0.56}}
      --o.createButton(manaCost)
      
      -- fixing to make sure power/toughness doesn't draw over an already-existing power/toughness meter (_MTG_Simplified_UNIFIED)
      local ptData = enc.call("APIobjIsPropEnabled", {obj = o, propID = "_MTG_Simplified_UNIFIED"})
      if not (ptData and ptData ~= nil and ptData.displayPowTou) then
        local powerToughness = {click_function = "updateButtonLabels", function_owner = o, label = outstring[5], position = powerOffset, scale = {0.5, 0.5, 0.5}, width = 0, height = 0, font_size = 100, font_color = powerTextColor}
        o.createButton(powerToughness)
      end

      generateManaDecals(outstring[1], o)
    end
  end
end
function updateButtonLabels(o)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    enc.call("APIrebuildButtons",{obj=o})
  end
end
function recordName(o, color, alt_click)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    o.setGMNotes(Player[color].steam_name)
    enc.call("APIrebuildButtons",{obj=o})
  end
end

-- DS: Hi Donte!
function generateManaDecals(str, obj)
    -- short for Unformatted Mana Costs
    local unfManaCosts = {}
    -- short for Formatted Mana Costs
    local fManaCosts = {}
    for i in string.gmatch(str, "%g") do
        table.insert(unfManaCosts, i)
    end
    local i = 1
    local madeColorless = false
    while i < #unfManaCosts + 1 do
        local v = unfManaCosts[i]
        if tonumber(v) ~= nil then -- has to be a number, start colorless check
            if madeColorless then
                -- this accounts for people who put multiple sets of numbers in their card. what the fuck are you doing
                fManaCosts = {}
                break
            end
            local num = ""
            while tonumber(unfManaCosts[i]) ~= nil do
                num = num..unfManaCosts[i]
                i = i + 1
            end
            i = i - 1
            -- this one generates a button because we can't be assed to support EVERY NUMBER with an image
            table.insert(fManaCosts, num)
        elseif v == "(" then -- if special opener then handle special cost
            i = i + 1 -- go ahead of the parenthesis
            local startRange = i
            local endRange = i -- start recording range
            while unfManaCosts[i] ~= ")" do
                if i > #unfManaCosts + 1 then error("You must close that parenthesis starting at position "..startRange.." in the mana cost!") return end
                i = i + 1
            end
            endRange = i - 1 -- back up one, so it doesn't select the close parenthesis
            local newstr = ""
            for j = startRange, endRange, 1 do -- add the letters from the set (but not the slash) into its own string
                if unfManaCosts[j] ~= "/" then
                    newstr = newstr..unfManaCosts[j]
                end
            end
            table.insert(fManaCosts, newstr) -- insert it to be handled later
        else -- neither a number or a special, handle as normal
            table.insert(fManaCosts, v)
        end
        i = i + 1
    end

    local decals = obj.getDecals()
    local toRemove = {}
    if decals ~= nil then
        for i,v in ipairs(decals) do
            if v.name == "MagiscryptionManaCount" then
                table.insert(toRemove, 1, i)
            end
        end
    else
        decals = {}
    end
    for i,v in ipairs(toRemove) do
        table.remove(decals, v)
    end

    local tableCopy = fManaCosts
    fManaCosts = {}
    for i = #tableCopy, 1, -1 do
        fManaCosts[#fManaCosts + 1] = tableCopy[i]
    end

    local manaCount = 0
    local posHolder = {0, 0, 0}
    for i,v in ipairs(fManaCosts) do
        if tonumber(v) ~= nil then break end
        posHolder = {x = -0.8 + 0.15 * manaCount, y = 0.45, z = -1.1}
        table.insert(decals, {
            name = "MagiscryptionManaCount",
            url = colorURLs[v] or colorURLs["C"], -- default to colorless icon as fallback
            position = posHolder,
            rotation = {x = 90, y = 180, z = 0},
            scale = {0.15, 0.15, 0.5}
        })
        manaCount = manaCount + 1
    end
    obj.setDecals(decals)
    if tonumber(fManaCosts[#fManaCosts]) ~= nil then
        obj.createButton({
            click_function = "updateButtonLabels",
            function_owner = self,
            label = fManaCosts[#fManaCosts], -- grabs the last string in fManaCosts, which SHOULD be the colorless cost
            position = {0.8 - 0.15 * manaCount, 0.45, -1.1},
            scale = {0.5, 0.5, 0.5},
            width = 200, height = 200,
            font_size = 125,
            color = {0.79,0.77,0.75}
        })
    end
end

colorSorting = {
    X = -3,
    Y = -2,
    Z = -1,
    S = 0,
    C = 1,
    W = 2,
    U = 3,
    B = 4,
    R = 5,
    G = 6
}

colorURLs = {
    X = "https://cdn.discordapp.com/attachments/947638127160336445/996802146894876772/mana_x.png",
    Y = "https://cdn.discordapp.com/attachments/947638127160336445/996802147129770004/mana_y.png",
    Z = "https://cdn.discordapp.com/attachments/947638127160336445/996802146613874759/mana_z.png",
    S = "https://cdn.discordapp.com/attachments/947638127160336445/996802756163686400/mana_s.png",
    C = "https://cdn.discordapp.com/attachments/947638127160336445/996802349110657044/mana_c.png",
    W = "https://cdn.discordapp.com/attachments/947638127160336445/996802261328068608/mana_w.png",
    U = "https://cdn.discordapp.com/attachments/947638127160336445/996802262171127898/mana_u.png",
    B = "https://cdn.discordapp.com/attachments/947638127160336445/996802261567164416/mana_b.png",
    R = "https://cdn.discordapp.com/attachments/947638127160336445/996802261986590720/mana_r.png",
    G = "https://cdn.discordapp.com/attachments/947638127160336445/996802261764284536/mana_g.png",

    GU = "https://cdn.discordapp.com/attachments/947638127160336445/996802744130211932/mana_gu.png", -- Green/Blue    
    UG = "https://cdn.discordapp.com/attachments/947638127160336445/996802744130211932/mana_gu.png", -- Blue/Green    
    GW = "https://cdn.discordapp.com/attachments/947638127160336445/996802744390271077/mana_gw.png", -- Green/White   
    WG = "https://cdn.discordapp.com/attachments/947638127160336445/996802744390271077/mana_gw.png", -- White/Green   
    RG = "https://cdn.discordapp.com/attachments/947638127160336445/996802742414757948/mana_rg.png", -- Red/Green     
    GR = "https://cdn.discordapp.com/attachments/947638127160336445/996802742414757948/mana_rg.png", -- Green/Red     
    RW = "https://cdn.discordapp.com/attachments/947638127160336445/996802742624452748/mana_rw.png", -- Red/White     
    WR = "https://cdn.discordapp.com/attachments/947638127160336445/996802742624452748/mana_rw.png", -- White/Red     
    UB = "https://cdn.discordapp.com/attachments/947638127160336445/996802742809006092/mana_ub.png", -- Blue/Black    
    BU = "https://cdn.discordapp.com/attachments/947638127160336445/996802742809006092/mana_ub.png", -- Black/Blue    
    WB = "https://cdn.discordapp.com/attachments/947638127160336445/996802743207473222/mana_wb.png", -- White/Black   
    BW = "https://cdn.discordapp.com/attachments/947638127160336445/996802743207473222/mana_wb.png", -- Black/White   
    UR = "https://cdn.discordapp.com/attachments/947638127160336445/996802742985183364/mana_ur.png", -- Blue/Red      
    RU = "https://cdn.discordapp.com/attachments/947638127160336445/996802742985183364/mana_ur.png", -- Red/Blue      
    WU = "https://cdn.discordapp.com/attachments/947638127160336445/996802743446540309/mana_wu.png", -- White/Blue    
    UW = "https://cdn.discordapp.com/attachments/947638127160336445/996802743446540309/mana_wu.png", -- Blue/White    
    BG = "https://cdn.discordapp.com/attachments/947638127160336445/996802743660466388/mana_bg.png", -- Black/Green   
    GB = "https://cdn.discordapp.com/attachments/947638127160336445/996802743660466388/mana_bg.png", -- Green/Black   
    BR = "https://cdn.discordapp.com/attachments/947638127160336445/996802743891144784/mana_br.png", -- Black/Red     
    RB = "https://cdn.discordapp.com/attachments/947638127160336445/996802743891144784/mana_br.png", -- Red/Black     

    PW = "https://cdn.discordapp.com/attachments/947638127160336445/996842222475542538/mana_phyw.png", -- Phyrexian White, Colorblind Tweak Thanks Adi
    PU = "https://cdn.discordapp.com/attachments/947638127160336445/996842223033389096/mana_phyu.png", -- Phyrexian Blue, Colorblind Tweak 
    PB = "https://cdn.discordapp.com/attachments/947638127160336445/996842222181961902/mana_phyb.png", -- Phyrexian Black, Colorblind Tweak 
    PR = "https://cdn.discordapp.com/attachments/947638127160336445/996842223297642496/mana_phyr.png", -- Phyrexian Red, Colorblind Tweak 
    PG = "https://cdn.discordapp.com/attachments/947638127160336445/996842221863186443/mana_phyg.png"  -- Phyrexian Green, Colorblind Tweak 
}
-- add these ones separately because Lua doesn't like to let you declare them NORMALLY
colorURLs["2W"] = "https://cdn.discordapp.com/attachments/947638127160336445/996802297189372045/2W.png"
colorURLs["2U"] = "https://cdn.discordapp.com/attachments/947638127160336445/996802296992252005/2U.png"
colorURLs["2B"] = "https://cdn.discordapp.com/attachments/947638127160336445/996802296358916147/2B.png"
colorURLs["2R"] = "https://cdn.discordapp.com/attachments/947638127160336445/996802296790917171/2R.png"
colorURLs["2G"] = "https://cdn.discordapp.com/attachments/947638127160336445/996802296585388113/2G.png"

function updateModule(wr)
  enc = Global.getVar('Encoder')
  if enc ~= nil then
    wr = wr.text
    wrv = string.match(wr,"version = '(.-)'")
    if wrv == 'DEPRECIATED' then
      enc.call("APIremoveProperty",{propID=pID})
      self.destruct()
    end
    local ver = enc.call("APIversionComp",{wv=wrv,cv=version})
    if ''..ver ~= ''..version then
      broadcastToAll("An update has been found for "..pID..". Reloading Module.")
      self.script_code = wr
      self.reload()
    else
      broadcastToAll("No update found for "..pID..". Carry on.")
    end
  end
end
