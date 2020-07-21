def tick args
  s = args.state
  s.x ||= 0
  s.y ||= 0
  key_down = args.inputs.keyboard.key_down
  if key_down.w then s.y += 8 end
  if key_down.s then s.y -= 8 end
  if key_down.a then s.x -= 8 end
  if key_down.d then s.x += 8 end

  draw(args)
end

def draw args
  s = args.state

  args.outputs.sprites << {
    x: s.x,
    y: s.y,
    w: 128,
    h: 128,
    path: "sprites/spritesheet.png",
    source_x: 0,
    source_y: 0,
    source_w: 16,
  }  
end
