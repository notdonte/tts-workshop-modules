pID = "Custom_Cards"
version = '1.00'
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
      local dataTitle = {click_function = "updateButtonLabels", function_owner = o, label = o.getName(), position = {0, 0.4, -1.3}, scale = {0.5, 0.5, 0.5}, width = 0, height = 0, font_size = 125, font_color = textColor}
      local dataDescription = {click_function = "updateButtonLabels", function_owner = o, label = outstring[7], position = {0, 0.4, 0.85}, scale = {0.5, 0.5, 0.5}, width = 0, height = 0, font_size = 90, font_color = textColor}
      local typeLine = {click_function = "updateButtonLabels", function_owner = o, label = outstring[3], position = {0, 0.4, 0.275}, scale = {0.5, 0.5, 0.5}, width = 0, height = 0, font_size = 85, font_color = textColor}
      local powerToughness = {click_function = "updateButtonLabels", function_owner = o, label = outstring[5], position = {0.735, 0.4, 1.3}, scale = {0.5, 0.5, 0.5}, width = 0, height = 0, font_size = 100, font_color = textColor}
      local manaCost = {click_function = "updateButtonLabels", function_owner = self, label = outstring[1], position = {0.43, 0.4, -1.1}, scale = {0.5, 0.5, 0.5}, width = 1000, height = 200, font_size = 125, color = {0.74,0.63,0.56}}
      local scryber = {click_function = "recordName", function_owner = self, label = o.getGMNotes(), position = {-0.43, 0.4, 1.43}, scale = {0.5, 0.5, 0.5}, width = 400, height = 80, font_size = 50, font_color = {1,1,1}, color = {0,0,0}}
      o.createButton(dataTitle)
      o.createButton(dataDescription)
      o.createButton(typeLine)
      o.createButton(manaCost)
      o.createButton(powerToughness)
      o.createButton(scryber)

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
