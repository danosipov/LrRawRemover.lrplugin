local logger = import 'LrLogger'( 'LrRawRemover' )

logger:enable( "logfile" )

RRLogger = {}

-- Log levels
-- ALL:   0
-- TRACE: 1
-- INFO:  2
-- WARN:  3
-- ERROR: 4
RRLogger.level=0

function RRLogger.trace(message)
    if RRLogger.level <= 1 then
        logger:trace(message)
    end
end

function RRLogger.info(message)
    if RRLogger.level <= 2 then
        logger:info(message)
    end
end

function RRLogger.warn(message)
    if RRLogger.level <= 3 then
        logger:warn(message)
    end
end

function RRLogger.error(message)
    if RRLogger.level <= 4 then
        logger:error(message)
    end
end

function RRLogger.logTable(name, value)
    if RRLogger.level <= 1 then
        if type(name) == "string" then
            logger:trace(name .. ":")
        end

        if type(value) == "table" then
            for i,j in pairs(value) do
                if type(value) == "string" then
                    logger:trace(i .. " => " .. j)
                else
                    RRLogger.logTable(i, j)
                end
            end
        else
            logger:trace(value)
        end
    end
end