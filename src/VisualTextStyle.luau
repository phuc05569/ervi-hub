local Style={}
function Style.apply(label,white,black)
 label.TextColor3=white
 label.TextStrokeColor3=black
 label.TextStrokeTransparency=0
end
return Style
