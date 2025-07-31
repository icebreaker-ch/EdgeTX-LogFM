-- Class LogFile
local LogFile = {}
LogFile.__index = LogFile
-- pattern modelName, date, time
LogFile.pattern = "(.*)%-(%d%d%d%d%-%d%d%-%d%d)%-(%d%d%d%d%d%d)%.csv$"

function LogFile.new(path, fileName)
    local self = setmetatable({}, LogFile)
    self.path = path
    self.fileName = fileName
    self.info = fstat(path .. "/" .. fileName)
    self.modelName, self.date, self.time = string.match(fileName, self.pattern)
    return self
end

function LogFile.isLogFile(fname)
    return string.match(fname, LogFile.pattern)
end

function LogFile:getModelName()
    return self.modelName
end

function LogFile:getFileName()
    return self.fileName
end

function LogFile:getDate()
    return self.date
end

function LogFile:getTime()
    return self.time
end

function LogFile:getSize()
    return self.info.size
end

function LogFile:delete()
    del(self.path .. "/" .. self.fileName)
end

return LogFile
