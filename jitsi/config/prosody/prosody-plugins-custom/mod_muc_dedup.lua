-- mod_muc_dedup.lua
-- Серверный дедуп участников по стабильному JWT context.user.id.
--
-- Проблема: коллекторы заходят через НАТИВНЫЙ Jitsi-клиент (мобайл / window.open),
-- на который не распространяется takeover-фикс нашего веба (useCallTabLock). При
-- медленном подключении / реконнекте один человек открывает 2-3 параллельные живые
-- сессии — все шлют один микрофон и проигрывают звук комнаты → эхо и дубль плитки.
--
-- Решение (takeover на сервере): при входе нового occupant'а ищем уже сидящего с тем
-- же context.user.id и выкидываем СТАРОГО (kick через set_role "none"). Остаётся только
-- последнее подключение — та же семантика, что у веб-takeover. Работает независимо от
-- клиента, т.к. опирается на JWT (id кладёт наш JitsiTokenGenerator: context.user.id).
--
-- Грузится в MUC-компоненте (XMPP_MUC_MODULES), как token_affiliation — хук
-- muc-occupant-joined принадлежит MUC-компоненту.

local is_admin = require "core.usermanager".is_admin;
local is_healthcheck_room = module:require "util".is_healthcheck_room;

module:log("info", "mod_muc_dedup loaded — dedup occupants by JWT context.user.id");

local function _is_admin(jid)
    return is_admin(jid, module.host);
end

module:hook("muc-occupant-joined", function (event)
    local room, occupant, origin = event.room, event.occupant, event.origin;

    -- Пропускаем служебные комнаты и системных участников (focus, jvb, recorder).
    if is_healthcheck_room(room.jid) or _is_admin(occupant.jid) then
        return;
    end

    -- Стабильный идентификатор берём из JWT той же сессии, что и token_affiliation.
    local context_user = origin and origin.jitsi_meet_context_user;
    local uid = context_user and context_user.id;
    if not uid or uid == "" then
        -- Нет стабильного id (гость / служебная сессия) — не дедуплицируем,
        -- чтобы случайно не выкинуть легитимных участников.
        return;
    end

    -- Карта user.id -> nick живёт на объекте комнаты (на всё время её жизни).
    local seen = room._meettrack_dedup;
    if not seen then
        seen = {};
        room._meettrack_dedup = seen;
    end

    local prev_nick = seen[uid];
    seen[uid] = occupant.nick;

    if prev_nick and prev_nick ~= occupant.nick then
        -- Старое подключение того же человека ещё в комнате? Выкидываем его.
        local prev = room:get_occupant_by_nick(prev_nick);
        if prev then
            module:log("info",
                "dedup: user=%s — kick stale occupant %s, keep %s (room=%s)",
                tostring(uid), prev_nick, occupant.nick, room.jid);
            -- actor=true → серверный kick в обход проверок прав (даже для owner-куратора).
            room:set_role(true, prev_nick, "none");
        end
    end
end);

-- Подчищаем карту, когда участник честно вышел (чтобы запись не указывала на
-- отсутствующий nick и повторный вход того же человека не считался дублем).
module:hook("muc-occupant-left", function (event)
    local room, occupant = event.room, event.occupant;
    local seen = room._meettrack_dedup;
    if not seen then return; end
    for uid, nick in pairs(seen) do
        if nick == occupant.nick then
            seen[uid] = nil;
            break;
        end
    end
end);
