xs = 1.42
ys = 1.47
xd = -6.45
yd = 4.3
keyboard = {
    {'q',0,0},
    {'w',0,1},
    {'e',0,2},
    {'r',0,3},
    {'t',0,4},
    {'y',0,5},
    {'u',0,6},
    {'i',0,7},
    {'o',0,8},
    {'p',0,9},
    {'a',1,0.5},
    {'s',1,1.5},
    {'d',1,2.5},
    {'f',1,3.5},
    {'g',1,4.5},
    {'h',1,5.5},
    {'j',1,6.5},
    {'k',1,7.5},
    {'l',1,8.5},
    {'z',2,1.5},
    {'x',2,2.5},
    {'c',2,3.5},
    {'v',2,4.5},
    {'b',2,5.5},
    {'n',2,6.5},
    {'m',2,7.5}
}
enterKey = {2,0.07}
backspaceKey = {2,8.9}
resetButton = {3,6}
white = {1,1,1}
yellow = {1,0.77,0}
green = {0,1,0}
red = {1,0,0}

answer = nil
currentWord = {}
currentWordLen = 0
guesses = {}
guessCount = 0
seed = ""
fin = false

wordBank = nil
wordKeys = {}

function onLoad()
    WebRequest.get("https://davidy22.github.io/api/words.json", function(a) webRequestCallback(a) end)
    renderKeyboard()
end

function renderCleanup()
    local buttons = self.getButtons()
    for k = #buttons, 1, -1 do
        if #buttons <= 28 + guessCount * 5 then
            break
        end
        self.removeButton(buttons[k].index)
        table.remove(buttons)
    end
end

function renderKeyboard()
    for i, key in ipairs(keyboard) do
        self.createButton({
            click_function = "keypress" .. key[1],
            function_owner = self,
            font_size = 400,
            width = 500,
            height = 600,
            color = {0,0,0,1},
            font_color = {1,1,1},
            position = {xs*key[3]+xd,1,ys*key[2]+yd},
            label = string.upper(key[1]),
            scale = {1.32,1,1}
        })
    end
    self.createButton({
        click_function = "enter",
        function_owner = self,
        font_size = 300,
        width = 920,
        height = 600,
        color = {0,0,0,1},
        font_color = {1,1,1},
        position = {xs*enterKey[2]+xd,1,ys*enterKey[1]+yd},
        label = "Enter",
        scale = {1.32,1,1}
    })
    self.createButton({
        click_function = "backspace",
        function_owner = self,
        font_size = 300,
        width = 890,
        height = 600,
        color = {0,0,0,1},
        font_color = {1,1,1},
        position = {xs*backspaceKey[2]+xd,1,ys*backspaceKey[1]+yd},
        label = "Back",
        scale = {1.32,1,1}
    })
end


function renderWord(word)
    local letterCounts = {}
    for i = 1, 5 do
        if string.sub(word, i, i) == string.sub(answer, i, i) then
            self.createButton({
                click_function = "blank",
                function_owner = self,
                font_size = 550,
                width = 800,
                height = 800,
                color = green,
                font_color = {0,0,0},
                position = {xs*i*1.8-1+xd,1,ys*guessCount*1.2 - 11+yd},
                label = string.upper(string.sub(word, i, i)),
                scale = {1.32,1,1}
            })
        else
            if letterCounts[string.sub(answer, i, i)] == nil then
                letterCounts[string.sub(answer, i, i)] = 1
            else
                letterCounts[string.sub(answer, i, i)] = letterCounts[string.sub(answer, i, i)] + 1
            end
        end
    end
    for i = 1, 5 do
        if string.sub(word, i, i) ~= string.sub(answer, i, i) then
            if letterCounts[string.sub(word, i, i)] == nil then
                self.createButton({
                    click_function = "blank",
                    function_owner = self,
                    font_size = 550,
                    width = 800,
                    height = 800,
                    color = {0,0,0,1},
                    font_color = {1,1,1},
                    position = {xs*i*1.8-1+xd,1,ys*guessCount*1.2 - 11+yd},
                    label = string.upper(string.sub(word, i, i)),
                    scale = {1.32,1,1}
                })
                if string.find(answer, string.sub(word, i, i)) == nil then
                    for j = 0, 25 do
                        if keyboard[j+1][1] == string.sub(word, i, i) then
                            self.editButton({index=j, color = {0.5,0.5,0.5,1}})
                            break
                        end
                    end
                end
            else
                letterCounts[string.sub(word, i, i)] = letterCounts[string.sub(word, i, i)] - 1
                if letterCounts[string.sub(word, i, i)] == 0 then letterCounts[string.sub(word, i, i)] = nil end
                self.createButton({
                    click_function = "blank",
                    function_owner = self,
                    font_size = 550,
                    width = 800,
                    height = 800,
                    color = yellow,
                    font_color = {0,0,0},
                    position = {xs*i*1.8-1+xd,1,ys*guessCount*1.2 - 11+yd},
                    label = string.upper(string.sub(word, i, i)),
                    scale = {1.32,1,1}
                })
            end
        end
    end
end


function renderCurrent()
    for i = 1, #currentWord do
        self.createButton({
            click_function = "blank",
            function_owner = self,
            font_size = 550,
            width = 800,
            height = 800,
            color = {0,0,0,1},
            font_color = {1,1,1},
            position = {xs*i*1.8-1+xd,1,ys*guessCount*1.2 - 11+yd},
            label = string.upper(currentWord[i]),
            scale = {1.32,1,1}
        })
    end
end


function webRequestCallback(webReturn)
    wordBank = JSON.decode(webReturn.text)[1]
    for k, v in pairs(wordBank) do
        table.insert(wordKeys, k)
    end
    reset()
end

function checkWord(word)
    if word == answer then
        self.setColorTint(green)
        renderCleanup()
        renderWord(word)
        createReset()
    elseif wordBank[word] == nil then
        self.setColorTint(red)
        Wait.frames(function() self.setColorTint(white) end, 80)
    else
        table.insert(guesses, word)
        renderCleanup()
        renderWord(word)
        guessCount = guessCount + 1
        currentWord = {}
        currentWordLen = 0
        if guessCount == 6 then
            self.setColorTint(red)
            createReset()
            self.createButton({
                click_function = "blank",
                function_owner = self,
                font_size = 300,
                width = 2300,
                height = 600,
                color = {0.1,0.15,0.3,1},
                font_color = {1,1,0.9},
                position = {xs*resetButton[2]+xd-6,1,ys*resetButton[1]+yd},
                label = "Word was " .. answer,
                scale = {1.32,1,1}
            })
        else
            self.setColorTint(yellow)
            Wait.frames(function() self.setColorTint(white) end, 80)
        end
    end
end

function createReset()
    fin = true
    self.createButton({
        click_function = "reset",
        function_owner = self,
        font_size = 300,
        width = 910,
        height = 600,
        color = {0.1,0.15,0.3,1},
        font_color = {1,1,0.9},
        position = {xs*resetButton[2]+xd,1,ys*resetButton[1]+yd},
        label = "Reset",
        scale = {1.32,1,1}
    })
end

function reset()
    self.setColorTint(white)
    guesses = {}
    currentWord = {}
    currentWordLen = 0
    guessCount = 0
    self.clearButtons()
    renderKeyboard()
    answer = wordKeys[math.random(1, #wordKeys)]
    fin = false
end


function blank() end


function enter()
    if LOCK then return end
    LOCK = true
    Wait.time(function() LOCK = false end, 0.1)

    checkWord(table.concat(currentWord))
end


function backspace()
    if LOCK or fin then return end
    LOCK = true
    Wait.time(function() LOCK = false end, 0.1)

    if currentWordLen > 0 then
        currentWordLen = currentWordLen - 1
        table.remove(currentWord)
        local buttons = self.getButtons()
        self.removeButton(buttons[#buttons].index)
    end
end

function keypress(letter)
    if LOCK or fin then return end
    LOCK = true
    Wait.time(function() LOCK = false end, 0.1)

    if currentWordLen < 5 and guessCount < 6 then
        table.insert(currentWord, letter)
        currentWordLen = currentWordLen + 1
        
        self.createButton({
            click_function = "blank",
            function_owner = self,
            font_size = 550,
            width = 800,
            height = 800,
            color = {0,0,0,1},
            font_color = {1,1,1},
            position = {xs*#currentWord*1.8-1+xd,1,ys*guessCount*1.2 - 11+yd},
            label = string.upper(letter),
            scale = {1.32,1,1}
        })
    end
end

function updateButtonText(ply, text)
    seed = text
    if seed == "" then
        self.UI.setAttribute("submit", "text", "Reset")
    else
        self.UI.setAttribute("submit", "text", "Set Seed")
    end
end

function setSeed()
    if seed ~= "" then
        math.randomseed(tonumber(seed))
    end
    reset()
    self.setColorTint(green)
    Wait.frames(function() self.setColorTint(white) end, 60)
end

function keypressq() keypress("q") end
function keypressw() keypress("w") end
function keypresse() keypress("e") end
function keypressr() keypress("r") end
function keypresst() keypress("t") end
function keypressy() keypress("y") end
function keypressu() keypress("u") end
function keypressi() keypress("i") end
function keypresso() keypress("o") end
function keypressp() keypress("p") end
function keypressa() keypress("a") end
function keypresss() keypress("s") end
function keypressd() keypress("d") end
function keypressf() keypress("f") end
function keypressg() keypress("g") end
function keypressh() keypress("h") end
function keypressj() keypress("j") end
function keypressk() keypress("k") end
function keypressl() keypress("l") end
function keypressz() keypress("z") end
function keypressx() keypress("x") end
function keypressc() keypress("c") end
function keypressv() keypress("v") end
function keypressb() keypress("b") end
function keypressn() keypress("n") end
function keypressm() keypress("m") end
