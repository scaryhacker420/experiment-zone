player = 'robnox995'
if not Workspace.Player_Orientation_References then 
  player = Workspace.Player_Orientation_References:GetChildren()[1].Name
end
player = 'robnox995'
frame = Workspace.NPCS.Eloise.HumanoidRootPart.CFrame
frame2 = CFrame.new(Vector3.new(0.0,100.0,0.0))
frame3 = frame2 * frame
Workspace[player].HumanoidRootPart.CFrame = frame2
