local module = { }

function module.GetUnorderedTableKeyset(table)
  local keyset={}
  local n = 0

  for k,v in pairs(table) do
    n=n+1
    keyset[n]=k
  end
  return keyset
end

function module.ConvertTZDateToTable(tz_date)
  local tz_table = {year = 0, month = 0, day = 0, hour = 0, min = 0, sec = 0}
  local keyset = {"year", "month", "day", "hour", "min", "sec"}
  local count = 1
  for element in string.gmatch(tz_date,'%d+') do
    tz_table[keyset[count]] = element
    count = count + 1
  end
  return tz_table
end

return module

