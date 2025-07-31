LIB_DIR = "/SCRIPTS/TOOLS/LogFM/"

local LogFiles = loadfile(LIB_DIR .. "logfiles.lua")()
local Node = loadfile(LIB_DIR .. "node.lua")()

local VERSION_STRING = "v0.1.1"

local INDENT = 6
local ONE_K = 1024
local ONE_M = ONE_K * ONE_K

local DISPLAY_DELAY = 30 -- 300 ms

local LEFT = 0
local FONT_W
local FONT_H
local SMALL_FONT_W
local SMALL_FONT_H

local NODE_TYPE = {
    ROOT = 0,
    MODEL = 1,
    FILE = 2
}

local STATE = {
    SHOW_TREE = 1,
    SHOW_CONFIRM = 2,
    DELETING = 3,
    REPORT = 4
}

local CONFIRM_STATE = {
    IDLE = 1,
    CANCEL_SELECTED = 2,
    DELETE_SELECTED = 3
}

--------------------
-- Helper functions
--------------------
local function move(value, increment, min, max)
    local result = value + increment
    if result < min then
        result = min
    elseif result > max then
        result = max
    end
    return result
end

local function s(number)
    if number == 1 then
        return ""
    else
        return "s"
    end
end

--------------------
-- Helper class
--------------------
local NodeData = {}

function NodeData.create(index, nodeType, name, logFile, selected, checked)
    local self = {}
    self.index = index
    self.nodeType = nodeType
    self.name = name
    self.logFile = logFile
    self.selected = selected or false
    self.checked = checked or false
    return self
end

--------------------
-- Application class
--------------------
local LogFM = {}
LogFM.__index = LogFM

function LogFM.new()
    local self = setmetatable({}, LogFM)
    self.state = STATE.SHOW_TREE
    self.logFiles = LogFiles.new()
    self.root = nil
    self.nodes = nil
    self.numNodes = 0
    self.windowStart = 0
    self.windowSize = 0
    self.selectedIndex = 0
    self.xPos = 0
    self.yPos = 0
    self.confirmState = nil
    self.deletePos = 0
    self.deleteQueue = nil
    self.deletedFiles = 0
    self.deletedBytes = 0
    self.timer = nil
    return self
end

function LogFM:initScreen()
    if lcd.RGB then
        FONT_W, FONT_H = lcd.sizeText("Wg")
        FONT_W = FONT_W / 2
        SMALL_FONT_W, SMALL_FONT_H = lcd.sizeText("Wg", SMLSIZE)
        SMALL_FONT_W = SMALL_FONT_W / 2
    else
        FONT_W = 5
        FONT_H = 7
        SMALL_FONT_W = 4
        SMALL_FONT_H = 6
    end
end

function LogFM:readLogs()
    self.root = Node.new(NodeData.create(1, NODE_TYPE.ROOT, "LogFM " .. VERSION_STRING, nil, true))
    self.nodes = { self.root }
    self.selectedIndex = 1
    self.windowStart = 1
    self.logFiles:read()
    local index = 1
    for _, model in pairs(self.logFiles:getModels()) do
        index = index + 1
        local modelNode = Node.new(NodeData.create(index, NODE_TYPE.MODEL, model))
        self.nodes[#self.nodes + 1] = modelNode
        for _, logFile in pairs(self.logFiles:getFiles(model)) do
            index = index + 1
            local name = logFile:getDate() .. "-" .. logFile:getTime()
            local fileNode = Node.new(NodeData.create(index, NODE_TYPE.FILE, name, logFile))
            self.nodes[#self.nodes + 1] = fileNode
            modelNode:addChild(fileNode)
        end
        self.root:addChild(modelNode)
    end
end

function LogFM:init()
    self:initScreen()
    self.windowSize = LCD_H // (FONT_H + 1)
    self:readLogs()
end

function LogFM:getNodeText(node)
    local data = node.data
    local text
    if data.nodeType == NODE_TYPE.FILE then
        local size = data.logFile:getSize()
        if size >= ONE_M then
            text = string.format("%s %.1fM", data.name, size / ONE_M)
        elseif size >= ONE_K then
            text = string.format("%s %.1fK", data.name, size / ONE_K)
        else
            text = string.format("%s %d", data.name, size)
        end
    else
        text = data.name
    end
    return text
end

function LogFM:drawNode(node)
    if self.yPos <= LCD_H - FONT_H then
        local data = node.data
        if data.index >= self.windowStart then
            local flags = 0
            if data.selected then
                flags = flags + INVERS
            end
            lcd.drawText(self.xPos, self.yPos, self:getNodeText(node), flags)

            if node.data.nodeType == NODE_TYPE.FILE then
                local w = INDENT - 1
                local xRect = self.xPos - INDENT
                local yRect = self.yPos + (FONT_H - w) // 2
                if node.data.checked then
                    lcd.drawFilledRectangle(xRect, yRect, w, w)
                else
                    lcd.drawRectangle(xRect, yRect, w, w)
                end
            end
            self.yPos = self.yPos + FONT_H + 1
        end
        self.xPos = self.xPos + INDENT
        for _, childNode in pairs(node:getChildren()) do
            self:drawNode(childNode)
        end
        self.xPos = self.xPos - INDENT
    end
end

function LogFM:prepareDelete()
    self.deleteQueue = {}
    self.deletePos = 1
    self.deletedFiles = 0
    self.deletedBytes = 0
    for _, node in pairs(self.nodes) do
        if node.data.nodeType == NODE_TYPE.FILE and node.data.checked then
            self.deleteQueue[#self.deleteQueue + 1] = node.data.logFile
        end
    end

    self.timer = getTime()
end

function LogFM:drawTitle()
    lcd.drawText(LEFT, 0, "LogFM " .. VERSION_STRING, INVERS)
end

function LogFM:updateUi()
    self.xPos = 0
    self.yPos = 0
    lcd.clear()
    if self.state == STATE.SHOW_TREE then
        self:drawNode(self.root)
        if #self.nodes <= 1 then
            lcd.drawText(LEFT, 20, "No logfiles found")
        end
    elseif self.state == STATE.SHOW_CONFIRM then
        self:drawTitle()
        local cancelFlags = 0
        local deleteFlags = 0
        if self.confirmState == CONFIRM_STATE.CANCEL_SELECTED then
            cancelFlags = INVERS
        elseif self.confirmState == CONFIRM_STATE.DELETE_SELECTED then
            deleteFlags = INVERS
        end
        local deleteCount = #self.deleteQueue
        local y = 20
        lcd.drawText(LEFT, y, string.format("Delete %d file%s", deleteCount, s(deleteCount)), deleteFlags)
        y = y + FONT_H + 1
        lcd.drawText(LEFT, y, "Cancel", cancelFlags)
    elseif self.state == STATE.DELETING then
        self:drawTitle()
        local logFile = self.deleteQueue[self.deletePos]
        y = 20
        lcd.drawText(LEFT, y, string.format("Deleting %d/%d", self.deletePos, #self.deleteQueue))
        y = y + FONT_H + 1
        lcd.drawText(LEFT, y, logFile:getModelName())
        y = y + FONT_H + 1
        lcd.drawText(LEFT, y, string.format("%s-%s", logFile:getDate(), logFile:getTime()))
        y = y + FONT_H + 1
        lcd.drawText(LEFT, y, string.format("Size: %d Byte%s", logFile:getSize(), s(logFile:getSize())))
        y = y + FONT_H + 1
        lcd.drawGauge(1, y, LCD_W - 2, FONT_H, self.deletePos, #self.deleteQueue)
    elseif self.state == STATE.REPORT then
        self:drawTitle()
        y = 20
        lcd.drawText(LEFT, y, string.format("Deleted %d file%s", self.deletedFiles, s(self.deletedFiles)))
        y = y + FONT_H + 1
        lcd.drawText(LEFT, y, string.format("Freed up %d Byte%s", self.deletedBytes, s(self.deletedBytes)))
        y = y + FONT_H + 1
        lcd.drawText(LEFT, y, "Press RTN")
    end
end

function LogFM:moveSelection(inc)
    local numNodes = #self.nodes
    local index = self.selectedIndex

    self.nodes[index].data.selected = false
    index = move(index, inc, 1, numNodes)
    self.nodes[index].data.selected = true

    if index >= self.windowStart + self.windowSize then
        self.windowStart = move(self.windowStart, 1, 1, numNodes - self.windowSize + 1)
    elseif index < self.windowStart then
        self.windowStart = move(self.windowStart, -1, 1, numNodes - self.windowSize + 1)
    end
    self.selectedIndex = index
end

function LogFM:setChecked(node, state)
    node.data.checked = state
    for _, child in pairs(node:getChildren()) do
        self:setChecked(child, state)
    end
end

function LogFM:handleEnter()
    local selectedNode = self.nodes[self.selectedIndex]
    local checked = selectedNode.data.checked
    self:setChecked(selectedNode, not checked)
end

function LogFM:handleShowTree(event)
    if event == EVT_VIRTUAL_NEXT then
        self:moveSelection(1)
    elseif event == EVT_VIRTUAL_PREV then
        self:moveSelection(-1)
    elseif event == EVT_VIRTUAL_ENTER then
        self:handleEnter()
    elseif event == EVT_VIRTUAL_ENTER_LONG then
        self:prepareDelete()
        self.confirmState = CONFIRM_STATE.IDLE
        self.state = STATE.SHOW_CONFIRM
    end
    self:updateUi()
    return 0
end

function LogFM:handleShowConfirm(event)
    if event == EVT_VIRTUAL_NEXT or event == EVT_VIRTUAL_PREV then
        if self.confirmState == CONFIRM_STATE.CANCEL_SELECTED then
            self.confirmState = CONFIRM_STATE.DELETE_SELECTED
        else
            self.confirmState = CONFIRM_STATE.CANCEL_SELECTED
        end
    elseif event == EVT_VIRTUAL_ENTER then
        if self.confirmState == CONFIRM_STATE.CANCEL_SELECTED then
            self.state = STATE.SHOW_TREE
        elseif self.confirmState == CONFIRM_STATE.DELETE_SELECTED then
            self.state = STATE.DELETING
        end
    elseif event == EVT_VIRTUAL_EXIT then
        self.state = STATE.SHOW_TREE
    end
    self:updateUi()
    return 0
end

function LogFM:handleDeleting(event)
    if self.deletePos <= #self.deleteQueue then
        self:updateUi()
        local currentTime = getTime()
        if currentTime - self.timer > DISPLAY_DELAY then
            local logFile = self.deleteQueue[self.deletePos]
            logFile:delete()
            self.timer = currentTime
            self.deletedFiles = self.deletedFiles + 1
            self.deletedBytes = self.deletedBytes + logFile:getSize()
            self.deletePos = self.deletePos + 1
        end
    else -- all requested files deleted
        self:readLogs()
        self.state = STATE.REPORT
    end
    return 0
end

function LogFM:handleReport(event)
    if event == EVT_EXIT_BREAK then
        self:readLogs()
        self.state = STATE.SHOW_TREE
    else
        self:updateUi()
    end
    return 0
end

function LogFM:run(event)
    local result = 0
    if self.state == STATE.SHOW_TREE then
        result = self:handleShowTree(event)
    elseif self.state == STATE.SHOW_CONFIRM then
        result = self:handleShowConfirm(event)
    elseif self.state == STATE.DELETING then
        result = self:handleDeleting(event)
    elseif self.state == STATE.REPORT then
        result = self:handleReport(event)
    end
    return result
end

local logViz = LogFM.new()

return { init = function() logViz:init() end, run = function(event) return logViz:run(event) end }
