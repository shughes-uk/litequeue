--[[
  @file      oqueue.ru.lua
  @brief      localization for oqueue addon (russian)

  @author    rmcinnis
  @date      june 11, 2012
  @par        copyright (c) 2012 Solid ICE Technologies, Inc.  All rights reserved.
              this file may be distributed so long as it remains unaltered
              if this file is posted to a web site, credit must be given to me along with a link to my web page
              no code in this file may be used in other works without expressed permission 
]]--
local addonName, OQ = ... ;

OQ.TRANSLATED_BY["ruRU"] = "" ;
if ( GetLocale() ~= "ruRU" ) then
  return ;
end
local L = OQ._T ; -- for literal string translations

-- OQ.FONT = "Fonts\\ARIALB.TTF" ;

OQ.TITLE_LEFT      = "oQueue v" ;
OQ.TITLE_RIGHT      = " - поиск премейдов" ;
OQ.BNET_FRIENDS    = "%d  b-net друзей" ;
OQ.PREMADE          = "Премейд" ;
OQ.FINDPREMADE      = "Найти" ;
OQ.CREATEPREMADE    = "Создать" ;
OQ.CREATE_BUTTON    = "создать премейд" ;
OQ.UPDATE_BUTTON    = "обновить премейд" ;
OQ.WAITLIST        = "ожидание" ;
OQ.HONOR_BUTTON    = "OQ премейд" ;
OQ.SETUP            = "Настройка" ;
OQ.PLEASE_SELECT_BG = "Пожалуйста, выберите поле боя" ;
OQ.BAD_REALID      = "Неправильный real-id или battle-tag.\n" ;
OQ.QUEUE1_SELECTBG  = "<выберите поле боя>" ;
OQ.NOLEADS_IN_RAID  = "В рейде нет лидеров групп" ;
OQ.NOGROUPS_IN_RAID = "Невозможно присоединить группу к рейду" ;
OQ.BUT_INVITE      = "пригласить" ;
OQ.BUT_GROUPLEAD    = "передать лидера" ;
OQ.BUT_INVITEGROUP  = "группа (%d)" ;
OQ.BUT_WAITLIST    = "в очередь" ;
OQ.BUT_INGAME      = "в игре" ;
OQ.BUT_PENDING      = "ожидание" ;
OQ.BUT_INPROGRESS  = "в бою" ;
OQ.BUT_NOTAVAILABLE = "недоступно" ;
OQ.BUT_FINDMESH    = "найти связи" ;
OQ.BUT_SUBMIT2MESH  = "отправ. b-tag" ;
OQ.BUT_PULL_BTAG    = "отозвать b-tag" ;
OQ.BUT_BAN_BTAG    = "ввести b-tag" ;
OQ.TT_LEADER        = "лидер" ;
OQ.TT_REALM        = "сервер" ;
OQ.TT_BATTLEGROUP  = "боевая группа" ;
OQ.TT_MEMBERS      = "в группе" ;
OQ.TT_WAITLIST      = "в очереди" ;
OQ.TT_RECORD        = "счет (победы - поражения)" ;
OQ.TT_AVG_HONOR    = "чести за игру" ;
OQ.TT_AVG_HKS      = "убийств за игру" ;
OQ.TT_AVG_GAME_LEN  = "продолжительность игр" ;
OQ.TT_AVG_DOWNTIME  = "время без активности" ;
OQ.TT_RESIL        = "устойчивость" ;
OQ.TT_ILEVEL        = "уровень предметов" ;
OQ.TT_MAXHP        = "макс здоровья" ;
OQ.TT_WINLOSS      = "выигрыш - поражение" ;
OQ.TT_HKS          = "всего почетных побед" ;
OQ.TT_OQVERSION    = "версия" ;
OQ.TT_TEARS        = "покинувших" ;
OQ.TT_PVPPOWER      = "пвп сила" ;
OQ.TT_MMR          = "рбг рейтинг" ;
OQ.JOIN_QUEUE      = "встать в очередь" ;
OQ.LEAVE_QUEUE      = "выйти из очереди" ;
OQ.LEAVE_QUEUE_BIG  = "ВЫЙТИ ИЗ ОЧЕРЕДИ" ;
OQ.DAS_BOOT        = "БОТ !!" ;
OQ.DISBAND_PREMADE  = "распустить группу" ;
OQ.LEAVE_PREMADE    = "выйти из группы" ;
OQ.RELOAD          = "перегрузить" ;
OQ.ILL_BRB          = "скоро вернусь" ;
OQ.LUCKY_CHARMS    = "расставить метки" ;
OQ.IAM_BACK        = "вернулся" ;
OQ.ROLE_CHK        = "проверка ролей" ;
OQ.READY_CHK        = "проверка готовности" ;
OQ.APPROACHING_CAP  = "СКОРО ЗАХВАТЫВАТЬ" ;
OQ.CAPPED          = "ЗАХВАЧЕН" ;
OQ.HDR_PREMADE_NAME = "премейды" ;
OQ.HDR_LEADER      = "лидер" ;
OQ.HDR_LEVEL_RANGE  = "уровень" ;
OQ.HDR_ILEVEL      = "ИЛ" ;
OQ.HDR_RESIL        = "усройчивость" ;
OQ.HDR_TIME        = "время" ;
OQ.QUALIFIED        = "подходит" ;
OQ.PREMADE_NAME    = "название премейда" ;
OQ.LEADERS_NAME    = "ник лидера" ;
OQ.REALID          = "Real-Id или B-tag" ;
OQ.REALID_MOP      = "Battle-tag" ;
OQ.MIN_ILEVEL      = "минимальный ИЛ" ;
OQ.MIN_RESIL        = "минимальная устойчивость" ;
OQ.MIN_MMR          = "минимальный рейтинг" ;
OQ.BATTLEGROUNDS    = "Описание" ;
OQ.ENFORCE_LEVELS  = "подобрать группы по уровню" ;
OQ.NOTES            = "Пометка" ;
OQ.PASSWORD        = "Пароль" ;
OQ.CREATEURPREMADE  = "Создать свой премейд" ;
OQ.LABEL_LEVEL      = "Уровень" ;
OQ.LABEL_LEVELS    = "Уровни" ;
OQ.HDR_BGROUP      = "боевая группа" ;
OQ.HDR_TOONNAME    = "ник альта" ;
OQ.HDR_REALM        = "сервер" ;
OQ.HDR_LEVEL        = "уровень" ;
OQ.HDR_ILEVEL      = "ИЛ" ;
OQ.HDR_RESIL        = "устойчивость" ;
OQ.HDR_MMR          = "рейтинг" ;
OQ.HDR_PVPPOWER    = "ПВП-сила" ;
OQ.HDR_DATE        = "дата" ;
OQ.HDR_BTAG        = "battle.tag" ;
OQ.HDR_REASON      = "причина" ;
OQ.RAFK_ENABLED    = "начался afk" ;
OQ.RAFK_DISABLED    = "закончился afk" ;
OQ.SETUP_HEADING    = "Установки и разные команды" ;
OQ.SETUP_BTAG      = "почтовый адрес Battlenet" ;
OQ.SETUP_GODARK_LBL = "сказать всем OQ друзьям что вы заняты" ;
OQ.SETUP_CAPCHK    = "запустить проверку OQ совместимости" ;
OQ.SETUP_REMOQADDED = "удалить всех OQ B.net друзей" ;
OQ.SETUP_REMOVEBTAG = "отозвать свой b-tag" ;
OQ.SETUP_ALTLIST    = "Список альтов на этом battle.net аккаунте:\n(только для мультибоксеров)" ;
OQ.SETUP_AUTOROLE  = "Автоматически расставить роли" ;
OQ.SETUP_CLASSPORTRAIT = "Использовать иконки классов" ;
OQ.SETUP_SAYSAPPED  = "Оповещать Ошеломление" ;
OQ.SETUP_WHOPOPPED  = "Кто дал БЛ(героизм)?" ;
OQ.SETUP_GARBAGE    = "удаление мусора (30 сек интервал)" ;
OQ.SETUP_SHOUTKBS  = "Оповещать о смертельных ударах" ;
OQ.SETUP_SHOUTCAPS  = "Оповещать о целях поля боя" ;
OQ.SETUP_SHOUTADS   = "Объявить premades" ;

OQ.SETUP_AUTOACCEPT_MESH_REQ = "Автоматически принимать запросы связей b-tag" ;
OQ.SETUP_ANNOUNCE_RAGEQUIT = "Оповещать о покинувших бой" ;
OQ.SETUP_OK2SUBMIT_BTAG    = "Отправлять b-tag каждые 4 дня" ;
OQ.SETUP_ADD        = "добавить" ;
OQ.SETUP_MYCREW    = "моя команда" ;
OQ.SETUP_CLEAR      = "очистить" ;
OQ.SAPPED          = "{череп}  Ошеломлен  {череп}" ;
OQ.BN_FRIENDS      = "друзья, добавленные OQ" ;
OQ.LOCAL_OQ_USERS  = "OQ переменные" ;
OQ.PPS_SENT        = "пакеты отправка/сек" ;
OQ.PPS_RECVD        = "пакеты прием/сек" ;
OQ.PPS_PROCESSED    = "пакеты обработка/сек" ;
OQ.MEM_USED        = "использовано памяти (kB)" ;
OQ.BANDWIDTH_UP    = "выгрузка (кБ/с)" ;
OQ.BANDWIDTH_DN    = "загрузка (кБ/с)" ;
OQ.OQSK_DTIME       = "время дисперсией" ;
OQ.SETUP_CHECKNOW  = "проверить сейчас" ;
OQ.SETUP_GODARK    = "занят" ;
OQ.SETUP_REMOVENOW  = "удалить сейчас" ;
OQ.STILL_IN_PREMADE = "пожалуйста выйдите из свогего премейда перед созданием нового" ;
OQ.DD_PROMOTE      = "назначить лидером группы" ;
OQ.DD_KICK          = "удалить игрока" ;
OQ.DD_BAN          = "заблокировать battle.tag игрока" ;
OQ.DISABLED        = "выключить oQueue" ;
OQ.ENABLED          = "включить oQueue" ;
OQ.THETIMEIS        = "время %d (GMT)" ;
OQ.RAGEQUITSOFAR    = " вышло из боя: %s  после %d:%02d  (%d уже)" ;
OQ.RAGEQUITTERS    = "%d покинувших бой за %d:%02d" ;
OQ.RAGELASTGAME    = "%d вышло из боя (бой длился %d:%02d)" ;
OQ.NORAGEQUITS      = "вы не на поле боя" ;
OQ.RAGEQUITS        = "%d уже покинуло бой" ;
OQ.MSG_PREMADENAME  = "пожалуйста введите название перемейда" ;
OQ.MSG_MISSINGNAME  = "пожалуйста назовите свой премейд" ;
OQ.MSG_REJECT      = "запрос не принят.\nпричина: %s" ;
OQ.MSG_CANNOTCREATE_TOOLOW = "Невозможно создать премейд.  \nНеобходим уровень 10 и выше" ;
OQ.MSG_NOTLFG      = "Пожалуйста не используйте oQueue для поиска вместо стандартного ЛФД. \nВозможны проблемы в работе аддона." ;
OQ.TAB_PREMADE      = "Премейд" ;
OQ.TAB_FINDPREMADE  = "Найти" ;
OQ.TAB_CREATEPREMADE = "Создать" ;
OQ.TAB_THESCORE    = "Счёт" ;
OQ.TAB_SETUP        = "Настройка" ;
OQ.TAB_BANLIST      = "Чёрный список" ;
OQ.TAB_WAITLIST    = "Ожидающие" ;
OQ.TAB_WAITLISTN    = "Ожидающие (%d)" ;
OQ.CONNECTIONS      = "соединения  %d - %d" ;
OQ.ANNOUNCE_PREMADES= "%d премейдов доступно" ;
OQ.NEW_PREMADE      = "(|cFF808080%d|r) |cFFC0C0C0%s|r : %s  |cFFC0C0C0%s|r" ;
OQ.PREMADE_NAMEUPD  = "(|cFF808080%d|r) |cFFC0C0C0%s|r : %s  |cFFC0C0C0%s|r" ;
OQ.DLG_OK          = "ok" ;
OQ.DLG_YES          = "да" ;
OQ.DLG_NO          = "нет" ;
OQ.DLG_CANCEL      = "отменить" ;
OQ.DLG_ENTER        = "войти в бой" ;
OQ.DLG_LEAVE        = "выйти из очереди" ;
OQ.DLG_READY        = "Готов" ;
OQ.DLG_NOTREADY    = "НЕ Готов" ;
OQ.DLG_01          = "Пожалуйста введите ник альта:" ;
OQ.DLG_02          = "Войти в бой" ;
OQ.DLG_03          = "Пожалуйтса назовите свой премейд:" ;
OQ.DLG_04          = "Пожалуйста введите Ваш real-id:" ;
OQ.DLG_05          = "Пароль:" ;
OQ.DLG_06          = "Пожалуйста введите real-id или ник лидера новой группы:" ;
OQ.DLG_07          = "\nДоступна новая версия !!\n\noQueue  v%s  сборка  %d\n" ;
OQ.DLG_08          = "Пожалуйста покиньте вашу группу чтобы присоединиться к дркгой или \nпорпосите лидера поставить в очередь всю группу" ;
OQ.DLG_09          = "Тлько лидер группы может создать премейд" ;
OQ.DLG_10          = "Пришло приглашение.\n\nВаше решение?" ;
OQ.DLG_11          = "Пришло приглашение.  Ожидаем пока лидер рейда примет решение.\nПожплуйста подождите." ;
OQ.DLG_12          = "Вы уверены, что хотите покинуть рейдовую группу?" ;
OQ.DLG_13          = "Лидер премейда запустил проверку готовности" ;
OQ.DLG_14          = "Лидер рейда перезагружается" ;
OQ.DLG_15          = "Блокировка: %s \nукажите причину:" ;
OQ.DLG_16          = "Невозможно выбрать тип премейда.\nСлишком много игроков (макс. %d)" ;
OQ.DLG_17          = "Пожалуйста введите battle-tag для блокировки:" ;
OQ.DLG_18a          = "Версия %d.%d.%d уже доступна для" ;
OQ.DLG_18b          = "--  Необходимо обновление  --" ;
OQ.DLG_19           = "Вы должны соответствовать требованиям своего премейда" ;
OQ.MENU_KICKGROUP  = "удалить группу" ;
OQ.MENU_SETLEAD    = "назначить лидера группы" ;
OQ.HONOR_PTS        = "Очки чести" ;
OQ.NOBTAG_01        = " информация battle-tag не получена вовремя." ;
OQ.NOBTAG_02        = " пожалуйста попробуйте еще раз." ;
OQ.MINIMAP_HIDDEN  = "(OQ) спрятать кнопку у минмкарты" ;
OQ.MINIMAP_SHOWN    = "(OQ) показать кнопку у мимникарты" ;
OQ.FINDMESH_OK      = "соединение в порядке.  премейды обновляются каждые 30 сек" ;
OQ.TIMEERROR_1      = "OQ: ваше системное время сильно отличается (%s)." ;
OQ.TIMEERROR_2      = "OQ: пожалуйста синхронизируйте системное время с вашим часовым поясом." ;
OQ.SYS_YOUARE_AFK    = "Вы АФК" ;
OQ.SYS_YOUARENOT_AFK = "Вы вернулись" ;
OQ.ERROR_REGIONDATA = "Региональные данные загружены неправильно." ;
OQ.TT_LEAVEPREMADE  = "ЛКМ: скрыть премейд\nПКМ: заблокировать лидера" ;
OQ.TT_FINDMESH      = "запрсить battle-tagи\nчтобы получить связи" ;
OQ.TT_SUBMIT2MESH  = "отправить ваш battle-tag\nдля увеличения связей" ;
OQ.LABEL_TYPE      = "|cFF808080type:|r  %s" ;
OQ.LABEL_ALL        = "все премейды" ;
OQ.LABEL_BGS        = "поля сражений" ;
OQ.LABEL_RBGS      = "рейтинговые БГ" ;
OQ.LABEL_DUNGEONS  = "подземелья" ;
OQ.LABEL_RAIDS      = "рейды" ;
OQ.LABEL_SCENARIOS  = "сценарии" ;
OQ.LABEL_BG        = "поле боя" ;
OQ.LABEL_RBG        = "рейтинговое БГ" ;
OQ.LABEL_ARENAS     = "Аренас" ;
OQ.LABEL_ARENA      = "арене" ;
--OQ.LABEL_ARENAS     = "Аренас (не х-области)" ;
--OQ.LABEL_ARENA      = "арене (не х-сфера)" ;
OQ.LABEL_DUNGEON    = "подземелье" ;
OQ.LABEL_RAID      = "рейд" ;
OQ.LABEL_SCENARIO  = "сценарий" ;
OQ.CONTRIBUTE       = "d'oh!" ;

OQ.CONTRIBUTION_DLG = { "",
                        "Пожалуйста, поддержите oQueue",
                        "",
                        "Для поддержки oQueue",
                        "beg.oq",
                        "",
                        "Для поддержки общественных серверов Ventrilo",
                        "beg.vent",
                        "",
                        "Спасибо за Вашу помошь!",
                        "",
                        "- tiny",
                      } ;
                      
OQ.TIMEVARIANCE_DLG = { "",
                        "Предупреждение:",
                        "",
                        "  Ваше системное время значительно ",
                        "  отличается от сетевого. Вы должны",
                        "  скорректировать его, прежде чем приступите",
                        "  к созданию премейда.",
                        "",
                        "  разница времени:  %s",
                        "",
                        "- tiny",
                      } ;
OQ.LFGNOTICE_DLG = { "",
                        "Предупреждение:",
                        "",
                        "  Не используйте названия премейдов oQueue для",
                        "  поиска обыкновенных групп или в личных целях",
                        "  или рекламы. Игроки могут добавить Вас в чёрный",
                        "  список за злоупотребление функциями аддона. Если",
                        "  Вас внесут в чёрный список, вы не сможете",
                        "  присоединяться к премейдам.",
                        "",
                        "- tiny",
                      } ;

OQ.BG_NAMES    = { [ "Случайное поле боя"    ] = { type_id = OQ.RND  },
                    [ "Ущелье Песни Войны"          ] = { type_id = OQ.WSG  },
                    [ "Два Пика"            ] = { type_id = OQ.TP  },
                    [ "Битва за Гилнеас" ] = { type_id = OQ.BFG  },
                    [ "Низина Арати"          ] = { type_id = OQ.AB  },
                    [ "Око Бури"      ] = { type_id = OQ.EOTS },
                    [ "Берег Древних" ] = { type_id = OQ.SOTA },
                    [ "Остов Завоеваний"      ] = { type_id = OQ.IOC  },
                    [ "Альтеракская долина"        ] = { type_id = OQ.AV  },
                    [ "Сверкающие Копи"      ] = { type_id = OQ.SSM  },
                    [ "Храм Котмогу"      ] = { type_id = OQ.TOK  },
                    [ ""                      ] = { type_id = OQ.NONE },
                  } ;
               
OQ.BG_SHORT_NAME = { [ "Низина Арати"          ] = "Арати",
                    [ "Альтеракская долина"        ] = "Альтерак",
                    [ "Битва за Гилнеас" ] = "Гилнеас",
                    [ "Око Бури"      ] = "Око",
                    [ "Остов Завоеваний"      ] = "ОЗ",
                    [ "Берег Древних" ] = "Берег",
                    [ "Два Пика"            ] = "Пики",
                    [ "Ущелье Песни Войны"          ] = "Ущелье",
                    [ "Сверкающие Копи"      ] = "Копи",
                    [ "Храм Котмогу"      ] = "Котмогу",
                    [ OQ.AB                    ] = "Арати",
                    [ OQ.AV                    ] = "Альтерак",
                    [ OQ.BFG                  ] = "Гилнеас",
                    [ OQ.EOTS                  ] = "Око",
                    [ OQ.IOC                  ] = "ОЗ",
                    [ OQ.SOTA                  ] = "Берег",
                    [ OQ.TP                    ] = "Пики",
                    [ OQ.WSG                  ] = "Ущелье",
                    [ OQ.SSM                  ] = "Копи",
                    [ OQ.TOK                  ] = "Котмогу",

                    [ "Арати"                    ] = OQ.AB,
                    [ "Альтерак"                    ] = OQ.AV,
                    [ "Гилнеас"                    ] = OQ.BFG,
                    [ "Око"                  ] = OQ.EOTS,
                    [ "ОЗ"                    ] = OQ.IOC,
                    [ "Берег"                  ] = OQ.SOTA,
                    [ "Пики"                    ] = OQ.TP,
                    [ "Ущелье"                    ] = OQ.WSG,
                    [ "Копи"                    ] = OQ.SSM,
                    [ "Котмогу"                    ] = OQ.TOK,
                  } ;
               
OQ.BG_STAT_COLUMN = { [ "База атакована"      ] = "База атакована",
                      [ "База защищена"        ] = "База защищена",
                      [ "Разрушитель уничтожен" ] = "Разрушитель уничтожен",
                      [ "Флаг захвачен"        ] = "Флаг захвачен",
                      [ "Флаг возвращен"          ] = "Флаг возвращен",
                      [ "Врата разрушены"      ] = "Врата разрушены",
                      [ "Кладбище отаковано"  ] = "Кладбище отаковано",
                      [ "Кладбище защищено"  ] = "Кладбище защищено",
                      [ "Башни атакованы"      ] = "Башни атакованы",
                      [ "Башни защищены"      ] = "Башни защищены",
                    } ;


local WARLOCK = {
  ["Колдовство"] = "Knockback",
  ["Демонология"] = "Knockback",
  ["Разрушение"] = "Knockback",
}

local DK = {
  ["Кровь"] = "Tank",
  ["Лед"] = "Melee",
  ["Нечестивость"] = "Melee",
}

local HUNTER = {
  ["Повелитель зверей"] = "Knockback",
  ["Стрельба"] = "Ranged",
  ["Выживание"] = "Ranged",
}

local DRUID = {
  ["Баланс"] = "Knockback",
  ["Сила зверя"] = "Melee",
  ["Исцеление"] = "Healer",
  ["Страж"] = "Tank",
}

local MAGE = {
  ["Тайная магия"] = "Knockback",
  ["Огонь"] = "Ranged",
  ["Лед"] = "Ranged",
}

local MONK = {
  ["Хмелевар"] = "Tank",
  ["Ткач туманов"] = "Healer",
  ["Танцующий с ветром"] = "Melee",
}

local PALADIN = {
  ["Свет"] = "Healer",
  ["Защита"] = "Tank",
  ["Воздаяние"] = "Melee",
}

local PRIEST = {
  ["Послушание"] = "Healer",
  ["Свет"] = "Healer",
  ["Тьма"] = "Ranged",
}

local ROGUE = {
  ["Ликвидация"] = "Melee",
  ["Бой"] = "Melee",
  ["Скрытность"] = "Melee",
}

local SHAMAN = {
  ["Стихии"] = "Knockback",
  ["Совершенствование"] = "Melee",
  ["Исцеление"] = "Healer",
}

local WARRIOR = {
  ["Оружие"] = "Melee",
  ["Неистовство"] = "Melee",
  ["Защита"] = "Tank",
}

--[[
OQ.BG_ROLES["Чернокнижник" ] = WARLOCK;
OQ.BG_ROLES["Чернокнижница"] = WARLOCK;
OQ.BG_ROLES["Охотник"      ] = HUNTER;
OQ.BG_ROLES["Охотница"    ] = HUNTER;
OQ.BG_ROLES["Охотник"      ] = HUNTER;
OQ.BG_ROLES["Охотница"    ] = HUNTER;
OQ.BG_ROLES["Жрец"        ] = PRIEST;
OQ.BG_ROLES["Жрица"        ] = PRIEST;
OQ.BG_ROLES["Рыцарь смерти"] = DK;
OQ.BG_ROLES["Друид"        ] = DRUID;
OQ.BG_ROLES["Маг"          ] = MAGE;
OQ.BG_ROLES["Монах"        ] = MONK;
OQ.BG_ROLES["Монахиня"    ] = MONK;
OQ.BG_ROLES["Паладин"      ] = PALADIN;
OQ.BG_ROLES["Воин"        ] = WARRIOR;
OQ.BG_ROLES["Шаман"        ] = SHAMAN;
OQ.BG_ROLES["Шаманка"      ] = SHAMAN;
OQ.BG_ROLES["Разбойник"    ] = ROGUE;
OQ.BG_ROLES["Разбойница"  ] = ROGUE;
]]--

OQ.BG_ROLES["DEATHKNIGHT" ] = DK ;
OQ.BG_ROLES["DRUID"       ] = DRUID ;
OQ.BG_ROLES["HUNTER"      ] = HUNTER ;
OQ.BG_ROLES["MAGE"        ] = MAGE ;
OQ.BG_ROLES["MONK"        ] = MONK ;
OQ.BG_ROLES["PALADIN"     ] = PALADIN ;
OQ.BG_ROLES["PRIEST"      ] = PRIEST ;
OQ.BG_ROLES["ROGUE"       ] = ROGUE ;
OQ.BG_ROLES["SHAMAN"      ] = SHAMAN ;
OQ.BG_ROLES["WARLOCK"     ] = WARLOCK ;
OQ.BG_ROLES["WARRIOR"     ] = WARRIOR ;

