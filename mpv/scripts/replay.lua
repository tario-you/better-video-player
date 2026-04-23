mp.add_key_binding("SPACE", "replay_eof", function()
    if mp.get_property_native("eof-reached") then
        mp.command("no-osd seek 0 absolute")
        mp.set_property("pause", "no")
    else
        mp.command("cycle pause")
    end
end)
