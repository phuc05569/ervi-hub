local JsonText={}
-- JSON produced by HttpService is valid UTF-8. ASCII transport avoids executor
-- file APIs that transcode non-ASCII bytes while preserving the JSON values.
function JsonText.ascii(text)
 local out={}
 for _,code in utf8.codes(text) do
  if code<128 then out[#out+1]=string.char(code)
  elseif code<=0xffff then out[#out+1]=("\\u%04x"):format(code)
  else
   local value=code-0x10000
   out[#out+1]=("\\u%04x\\u%04x"):format(0xd800+math.floor(value/1024),0xdc00+value%1024)
  end
 end
 return table.concat(out)
end
return JsonText
