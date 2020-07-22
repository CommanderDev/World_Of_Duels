local matchsettingsManager = {}

---[[ Player Object ]]---
local playerObject = game.Players.LocalPlayer
local playerGui = playerObject:WaitForChild("PlayerGui")
local duelUI = playerGui:WaitForChild("duelUI")
local changeSettingsFrame = duelUI:WaitForChild("changeSettingsFrame")
local firsttoButton = changeSettingsFrame:WaitForChild("firsttoButton")
local firsttoList = firsttoButton:WaitForChild("listFrame")
local firsttoClicker = firsttoButton:WaitForChild("clicker")

local winbyButton = changeSettingsFrame:WaitForChild("winbyButton")
local winbyList = winbyButton:WaitForChild("listFrame")
local winbyClicker = winbyButton:WaitForChild("clicker")

local firsttoToggled = false 
local winbyToggled = false
local tweenOffset = 2.75 --The amount the buttons will tween up and down.
local tweenInterval = 0.2 --Time for the tween to take.

function TweenButtons(list, bool)
    for index, button in ipairs(list:GetChildren()) do
        if(bool == true) then 
            button:TweenPosition(UDim2.new(button.Position.X.Scale, 0, button.Position.Y.Scale - tweenOffset, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, tweenInterval, false)
        else
            button:TweenPosition(UDim2.new(button.Position.X.Scale, 0, button.Position.Y.Scale + tweenOffset, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, tweenInterval, false)
        end
        wait(tweenInterval)
    end 
end 

function ToggleFirstTo()
    if(not firsttoToggled) then 
        firsttoToggled = true
    else 
        firsttoToggled = false
    end
	TweenButtons(firsttoList, firsttoToggled)
end 

function ToggleWinBy()
    print("Toggling win by")
	if(not winbyToggled) then
		winbyToggled = true
	else
		winbyToggled = false
	end
	TweenButtons(winbyList, winbyToggled)
end

function matchsettingsManager:connect()
    firsttoClicker.MouseButton1Click:Connect(ToggleFirstTo)
    winbyClicker.MouseButton1Click:Connect(ToggleWinBy)
    --Placeholder
end 

function matchsettingsManager:init()
    self:connect()
end 

return matchsettingsManager