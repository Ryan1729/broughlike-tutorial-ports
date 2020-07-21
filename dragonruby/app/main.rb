def tick args
  args.outputs.labels << [200, 200, 'Hello World!', 50]
  args.outputs.sprites << {
    x: 100,
    y: 100,
    w: 100,
    h: 100,
    path: "sprites/spritesheet.png",
    source_x: 0,
    source_y: 0,
    source_w: 16,
  }
  
  args.outputs.sprites << {
    x: 300,
    y: 400,
    w: 400,
    h: 400,
    path: "sprites/spritesheet.png",
    source_x: 16,
    source_y: 0,
    source_w: 16,
  }
end
