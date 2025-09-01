player = 'robnox995'
if Workspace.Player_Orientation_References then 
  player = nil
end
frame = Workspace.NPCS.Eloise.HumanoidRootPart.CFrame
frame2 = CFrame.new(Vector3.new(0.0,100.0,0.0))
frame3 = frame2 * frame
Workspace[player].HumanoidRootPart.CFrame = frame2
