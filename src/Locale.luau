-- Interface labels only. Player names, API errors and diagnostic evidence stay verbatim.
local RU={
 ["Notifications"]="Уведомления",["Notification Duration"]="Длительность уведомлений",
 ["Motion"]="Анимация",["Reduce Animations"]="Уменьшить анимацию",["Animation Speed"]="Скорость анимации",["UI Scale"]="Масштаб интерфейса",
 ["General"]="Основное",["Player Overlays"]="Метки игроков",["Appearance"]="Оформление",["Filters"]="Фильтры",
 ["Home"]="Главная",["Combat"]="Бой",["Visuals"]="Визуализация",["Player"]="Игрок",["World"]="Мир",["Safe Zone"]="Безопасная точка",["Teleports"]="Перемещения",["Utility"]="Утилиты",["Config"]="Конфигурации",["Settings"]="Настройки",
 ["Movement"]="Передвижение",["Movement Panel"]="Панель движения",["Panel Size"]="Размер панели",["Speed"]="Скорость",["WalkSpeed"]="Скорость ходьбы",["Walk Speed"]="Скорость ходьбы",["WalkSpeed key"]="Клавиша скорости",["Speed Mode"]="Режим скорости",["Speed Multiplier"]="Множитель скорости",
 ["Lighting"]="Освещение",["Fullbright"]="Яркий свет",["No Fog"]="Без тумана",["No Shadows"]="Без теней",["Custom Time"]="Своё время",["Time of Day"]="Время суток",["Camera"]="Камера",["Reset Camera"]="Сбросить камеру",
 ["Player ESP"]="Видимые игроки",["Enabled"]="Включено",["Visualization key"]="Клавиша визуализации",["Box Style"]="Рамка",["HealthBar"]="Полоса здоровья",["Names"]="Имена",["Distance"]="Расстояние",["Skeleton"]="Скелет",["Head Dot"]="Точка головы",["Chams"]="Подсветка",["Chams: Enemies Only"]="Подсветка: противники",["Chams Fill"]="Прозрачность заливки",["Chams Outline"]="Прозрачность контура",
 ["Tracers"]="Линии",["Tracers Enabled"]="Линии включены",["Origin"]="Начало линии",["Off-screen Arrows"]="Стрелки вне экрана",["Colours"]="Цвета",["Enemy"]="Противник",["Team"]="Команда",["Friend"]="Друг",["Behind Wall (preview only)"]="За стеной (только образец)",["Team Check"]="Проверять команду",["Show Teammates"]="Показывать союзников",["Mark Friends"]="Отмечать друзей",
 ["Performance"]="Производительность",["Update Rate"]="Частота обновления",["Cheap Boxes"]="Упрощённые рамки",["Max Targets"]="Лимит игроков",["Skeleton Budget"]="Лимит скелетов",["FullRate Targets"]="Полное обновление",["Far Target Rate"]="Интервал дальних целей",["Max Distance"]="Дальность",["Text Size"]="Размер текста",["Vertical Offset"]="Смещение по высоте",["Preview"]="Образец",["Preview hidden target"]="Образец скрытого игрока",
 ["Interface"]="Интерфейс",["Background Blur"]="Размытие фона",["Search shortcut key"]="Клавиша поиска",["Panic key"]="Аварийная клавиша",["Language"]="Язык",["Rendering"]="Отрисовка",["FPS Cap"]="Лимит FPS",["Rejoin"]="Переподключиться",["Server Hop"]="Сменить сервер",["Copy Job ID"]="Копировать ID сервера",["Check Reinjection"]="Проверить перезапуск",["Unsupported"]="Недоступно",
 ["Save as"]="Сохранить как",["Load"]="Загрузить",["Delete"]="Удалить",["Overwrite"]="Перезаписать",["Apply Import"]="Импортировать",["Copy Config To Clipboard"]="Копировать конфигурацию",["Turn Off Autoload"]="Отключить автозагрузку",["Set Selected As Autoload"]="Выбрать для автозагрузки",["Autoload per game"]="Автозагрузка для игры",["Copy Logs"]="Копировать журнал",["Copy Boot Log"]="Копировать журнал запуска",
 ["Auto Roll"]="Автобросок",["Styles"]="Стили",["Diagnostics"]="Диагностика",["Session"]="Сеанс",["Show M1 cooldown HUD"]="Показывать таймер M1",["Enable Safe Zone"]="Безопасная точка",["Menu opacity"]="Непрозрачность меню",
}
local Locale={}
function Locale.text(text,language)
 if language~="RU" or type(text)~="string" then return text end
 if RU[text] then return RU[text] end
 for english,russian in pairs(RU) do if text==english:upper() then return russian end end
 return text
end
function Locale.fold(text)
 local out={}
 for _,code in utf8.codes(text) do
  if code>=1040 and code<=1071 then code+=32 elseif code==1025 then code=1105 end
  table.insert(out,string.lower(utf8.char(code)))
 end
 return table.concat(out)
end
return Locale
