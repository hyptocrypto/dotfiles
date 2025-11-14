return function(opts)
  -- Fix booleans inside keymaps
  if opts.cmdline and opts.cmdline.keymap then
    for key, value in pairs(opts.cmdline.keymap) do
      if value == false then
        opts.cmdline.keymap[key] = nil -- remove invalid boolean
      end
    end
  end

  -- Also fix top-level keymap
  if opts.keymap then
    for key, value in pairs(opts.keymap) do
      if value == false then
        opts.keymap[key] = nil
      end
    end
  end

  return opts
end
