local component = require("component")
local term = require("term")
local os = require("os")
local io = require("io")
local event = require("event")  -- для отслеживания ввода без блокировки

-- Подключение реактора
local reactor = component.br_reactor
if not reactor then
  print("Ошибка: Реактор не найден. Убедитесь, что реактор подключен к компьютеру.")
  return
end

-- Путь к файлу для сохранения максимальной ёмкости
local maxEnergyFile = "/home/max_energy.txt"

-- Флаг для выхода из программы
local shouldExit = false

-- Функция для получения сохранённой максимальной ёмкости
local function getSavedMaxEnergy()
    local file = io.open(maxEnergyFile, "r")
    if file then
        local savedEnergy = tonumber(file:read("*all"))
        file:close()
        return savedEnergy
    end
    return nil
end

-- Функция для сохранения максимальной ёмкости
local function saveMaxEnergy(maxEnergy)
    local file = io.open(maxEnergyFile, "w")
    if file then
        file:write(tostring(maxEnergy))
        file:close()
    else
        print("Ошибка при записи в файл.")
    end
end

-- Функция для получения процента энергии
local function getEnergyPercentage(maxEnergy)
    local currentEnergy = reactor.getEnergyStored() -- Текущая энергия в реакторе
    if not currentEnergy then
        print("Ошибка: Не удалось получить текущую энергию из реактора.")
        return nil
    end
    -- Рассчитываем процент энергии
    return (currentEnergy / maxEnergy) * 100
end

-- Функция для обновления уровня всех стержней
local function updateControlRodLevels(energyPercentage)
    local rodLevel = math.floor(energyPercentage) -- Уровень стержней от 0 до 100
    reactor.setAllControlRodLevels(rodLevel) -- Устанавливаем уровень для всех стержней
end

-- Функция для запроса максимальной ёмкости при первом запуске
local function askForMaxEnergy()
    print("Какое максимальное количество энергии доступно в реакторе?")
    local input = term.read()
    input = tonumber(input)
    if input then
        saveMaxEnergy(input) -- Сохраняем значение
        return input
    else
        print("Ошибка: Введите корректное число.")
        return nil
    end
end

-- Функция для обработки ввода для выхода из программы
local function exitProgram(eventID, address, char, code)
    if char == 49 then  -- если нажата клавиша "1"
        print("\nЗавершаю программу...")
        shouldExit = true  -- устанавливаем флаг выхода
        event.ignore("key_down", exitProgram)  -- Отписываемся от события
    end
end

-- Основная функция программы
local function main()
    local maxEnergy = getSavedMaxEnergy()

    if not maxEnergy then
        maxEnergy = askForMaxEnergy()
        if not maxEnergy then return end
    else
        print("Последнее заданное значение максимальной ёмкости: " .. maxEnergy)
        print("Для изменения введите новое значение или нажмите Enter для использования последнего.")
        local input = term.read()
        if input ~= "\n" then
            maxEnergy = tonumber(input)
            if not maxEnergy then
                print("Ошибка: Введите корректное число.")
                return
            end
            saveMaxEnergy(maxEnergy)
        end
    end

    -- Начинаем слушать события
    event.listen("key_down", exitProgram)  -- Слушаем нажатие клавиши

    while not shouldExit do
        term.clear()
        print("Управление реактором Big Reactors")
        print("Нажмите 1 для выхода из программы.")

        -- Получаем процент заполненности
        local energyPercentage = getEnergyPercentage(maxEnergy)
        if not energyPercentage then
            print("Ошибка: Невозможно рассчитать процент энергии.")
            os.sleep(5)
            return
        end

        -- Обновляем уровень стержней
        updateControlRodLevels(energyPercentage)

        -- Выводим информацию
        print(string.format("Энергия в реакторе: %.2f%%", energyPercentage))
        print(string.format("Уровень стержней: %d%%", energyPercentage))

        os.sleep(5) -- Задержка перед следующим обновлением
    end

    print("Программа завершена.")
end

-- Запуск программы
main()
