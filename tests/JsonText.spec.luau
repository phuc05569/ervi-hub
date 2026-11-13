local JsonText=require("JsonText")
return {
 {"ASCII JSON escapes remain unchanged",function(_,eq)
  local raw='{"value":"a\\nb\\\"c"}';eq(JsonText.ascii(raw),raw)
 end},
 {"UTF-8 JSON uses portable BMP escapes without mojibake",function(check,eq)
  local encoded=JsonText.ascii('{"mark":"–","name":"é"}')
  eq(encoded,'{"mark":"\\u2013","name":"\\u00e9"}');check(not encoded:find("[\128-\255]"))
 end},
 {"supplementary Unicode is emitted as a valid surrogate pair",function(_,eq)
  eq(JsonText.ascii('"'..utf8.char(0x1f642)..'"'),'"\\ud83d\\ude42"')
 end},
}
