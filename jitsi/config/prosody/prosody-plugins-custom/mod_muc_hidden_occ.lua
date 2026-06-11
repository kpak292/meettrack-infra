-- mod_muc_hidden_occ.lua
-- Hides MUC occupants from the recorder hidden domain.
-- Their presence is not broadcast to other participants.

local jid_host = require "util.jid".host;
local hidden_domain = "hidden.meet.jitsi";

module:log("info", "mod_muc_hidden_occ loaded — hiding occupants from: %s", hidden_domain);

module:hook("muc-broadcast-presence", function(event)
    local occupant = event.occupant;
    if occupant and occupant.bare_jid then
        local occ_host = jid_host(occupant.bare_jid);
        if occ_host == hidden_domain then
            module:log("debug", "Hiding presence of %s", occupant.bare_jid);
            return true;
        end
    end
end, 100);
