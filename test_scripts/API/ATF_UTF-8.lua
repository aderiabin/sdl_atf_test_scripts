Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local json  = require('json')


----------------------------------------------------------------------------
-- User required files
require('user_modules/AppTypes')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')

----------------------------------------------------------------------------
-- User variables, arrays

local audibleState

if 
	Test.isMediaApplication == true or
	Test.appHMITypes["COMMUNICATION"] == true or
	Test.appHMITypes["NAVIGATION"] == true then
		audibleState = "AUDIBLE"
else
	audibleState = "NOT_AUDIBLE"
end

local AddCommandValues = { 
	-- string with 12 characters, totaling 23 bytes
	{ languageName = "Arabic", value = "قيادة المسار" },
	-- string with 21 characters, totaling 22 bytes
	{ languageName = "French", value = "Commandement Français" },
	-- string with 13 characters, totaling 14 bytes
	{ languageName = "German", value = "Befehl wählen"},
	-- string with 4 characters, totaling 12 bytes
	{ languageName = "Japanese", value = "コマンド"}, 
	-- string with 6 characters, totaling 16 bytes
	{ languageName = "Korean", value = "트랙의 명령"}, 
	-- string with 7 characters, totaling 14 bytes
	{ languageName = "Russian", value = "Команда"}, 
	-- string with 15 characters, totaling 16 bytes
	{ languageName = "Spanish", value = "Español Comando"}
}

local AddCommandUpperBound = { 
	-- string with 500 characters, totaling 914 bytes
	{ languageName = "ArabicUpperBound", value = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج" },
	-- string with 500 characters, totaling 688 bytes
	{ languageName = "FrenchUpperBound", value = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï" },
	-- string with 500 characters, totaling 634 bytes
	{ languageName = "GermanUpperBound", value = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn"},
	-- string with 500 characters, totaling 1,500 bytes
	{ languageName = "JapaneseUpperBound", value = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの"}, 
	-- string with 500 characters, totaling 1,500 bytes
	{ languageName = "KoreanUpperBound", value = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호"}, 
	-- string with 500 characters, totaling 1,000 bytes
	{ languageName = "RussianUpperBound", value = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ"}, 
	-- string with 500 characters, totaling 566 bytes
	{ languageName = "SpanishUpperBound", value = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF"}
}

local messageBodyValues = { 
	-- string with 12 characters, totaling 23 bytes
	{ languageName = "Arabic", value = "قيادة المسار" },
	-- string with 21 characters, totaling 22 bytes
	{ languageName = "French", value = "Commandement Français" },
	-- string with 13 characters, totaling 14 bytes
	{ languageName = "German", value = "Befehl wählen"},
	-- string with 4 characters, totaling 12 bytes
	{ languageName = "Japanese", value = "コマンド"}, 
	-- string with 6 characters, totaling 16 bytes
	{ languageName = "Korean", value = "트랙의 명령"}, 
	-- string with 7 characters, totaling 14 bytes
	{ languageName = "Russian", value = "Команда"}, 
	-- string with 15 characters, totaling 16 bytes
	{ languageName = "Spanish", value = "Español Comando"}
}


local messageBodyUpperBound = { 
	-- string with 500 characters, totaling 914 bytes
	{ languageName = "ArabicUpperBound", value = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج" },
	-- string with 500 characters, totaling 688 bytes
	{ languageName = "FrenchUpperBound", value = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï" },
	-- string with 500 characters, totaling 634 bytes
	{ languageName = "GermanUpperBound", value = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn"},
	-- string with 500 characters, totaling 1,500 bytes
	{ languageName = "JapaneseUpperBound", value = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの"}, 
	-- string with 500 characters, totaling 1,500 bytes
	{ languageName = "KoreanUpperBound", value = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호"}, 
	-- string with 500 characters, totaling 1,000 bytes
	{ languageName = "RussianUpperBound", value = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ"}, 
	-- string with 500 characters, totaling 566 bytes
	{ languageName = "SpanishUpperBound", value = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF"}
}



local PutFileValues = {
	-- string with 11 characters, totaling 25 bytes
	{ languageName = "Japanese", value =  "ボタンアイコン.png"},
	-- string with 10 characters, totaling 20 bytes
	{ languageName = "Korean", value =  "버튼 아이콘.png"},
	-- string with 10 characters, totaling 16 bytes
	{ languageName = "Russian", value = "Иконка.png"},
	-- string with 17 characters, totaling 18 bytes
	{ languageName = "Spanish", value =  "icono_Español.png"},
	-- string with 10 characters, totaling 15 bytes
	{ languageName = "Arabic", value =  "رمز زر.png"},
	-- string with 21 characters, totaling 23 bytes
	{ languageName = "French", value =  "l'icône_Française.png"},
	-- string with 23 characters, totaling 24 bytes
	{ languageName = "German", value =  "Schaltflächensymbol.png"}
}

local PutFileUpperBound = {
	-- string with 255 characters, totaling 757 bytes
	{ languageName = "JapaneseUpperBound", value =  "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のの.png"},
	-- string with 255 characters, totaling 757 bytes
	{ languageName = "KoreanUpperBound", value =  "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아아이이.png"},
	-- string with 255 characters, totaling 506 bytes
	{ languageName = "RussianUpperBound", value =  "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССММ.png"},
	-- string with
	{ languageName = "SpanishUpperBound", value =  "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficiall.png"},
	-- string with 255 characters, totaling 288 bytes
	{ languageName = "ArabicUpperBound", value =  "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ةة العرض حيةاجيةاجلحيةا.png"},
	-- string with 255 characters, totaling 463 bytes
	{ languageName = "FrenchUpperBound", value =  "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇÇ.png"},
	-- string with 255 characters, totaling 321 bytes
	{ languageName = "GermanUpperBound", value =  "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboo.png"}
}

local appNameValues = { 
	-- string with 15 characters, totaling 28 bytes
	{languageName = "Arabic", value = "تزامن تستر وكيل"},
	-- string with 24 characters, totaling 27 bytes
	{languageName = "French", value = "Mon application préférée"},
	-- string with 26 characters, totaling 28 bytes
	{languageName = "German", value = "Großen Geschützt Anwendung"},
	-- string with 10 characters, totaling 30 bytes
	{languageName = "Japanese", value = "同期プロキシテスター"},
	-- string with 11 characters, totaling 29 bytes
	{languageName = "Korean", value = "동기화 프록시 테스터"},
	-- string with 17 characters, totaling 34 bytes
	{languageName = "Russian", value = "СинхрПроксиТестер"},
	-- string with 16 characters, totaling 18 bytes
	{languageName = "Spanish", value = "Aplicación Móvil"}}

local appNameUpperBound = { 
	-- string with 100 characters, totaling 181 bytes
	{languageName = "ArabicUpperBound", value = "لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجج"},
	-- string with 100 characters, totaling 134 bytes
	{languageName = "FrenchUpperBound", value = "l'icôneFrançaiseÂâÊêaisondel'arbrelcdelaforêtÎîÔlaforôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondell"},
	-- string with 100 characters, totaling 132 bytes
	{languageName = "GermanUpperBound", value = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄäsymboÜüÖöÄänsymlSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖÖ"},
	-- string with 100 characters, totaling 300 bytes
	{languageName = "JapaneseUpperBound", value = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示のタンアイコン言語表示言語表示言語表家語表家示のの示示"},
	-- string with 100 characters, totaling 300 bytes
	{languageName = "KoreanUpperBound", value = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운마운트운트버튼아이콘트리하우스의숲호수마언어표시트리하우스의숲호수수"},
	-- string with 100 characters, totaling 200 bytes
	{languageName = "RussianUpperBound", value = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССС"},
	-- string with 100 characters, totaling 112 bytes
	{languageName = "SpanishUpperBound", value = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficiaa"}}

local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.appID .. "_" .. tostring(config.deviceMAC) .. "/")

---------------------------------------------------------------------------------------------------------
-- User functions

local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = ctx })
end

function copy_table(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  	:Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

---------------------------------------------------------------------------------------------------------

local function AddCommand(self, iCmdID, uimenuName, vrCommandsArray)
	--mobile side: sending AddCommand request
	local cid = self.mobileSession:SendRPC("AddCommand",
				{
					cmdID = iCmdID,
					menuParams = 	
					{
						position = 1,
						menuName = uimenuName
					},
					vrCommands = vrCommandsArray
				})
	
	--hmi side: expect UI.AddCommand request 
	EXPECT_HMICALL("UI.AddCommand", 
				{ 
					cmdID = iCmdID,		
					menuParams = 
					{
						position = 1,
						menuName = uimenuName
					}
				})
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)


	--hmi side: expect VR.AddCommand request
	EXPECT_HMICALL("VR.AddCommand", 
				{ 
					cmdID = iCmdID,							
					type = "Command",
					vrCommands = vrCommandsArray
				})
		:Do(function(exp,data)
			--hmi side: sending VR.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)	
	
	--mobile side: expect AddCommand response 
	EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"})
	
	EXPECT_NOTIFICATION("OnHashChange", {})
		:Do(function(_,data)
			self.currentHashID = data.payload.hashID
		end)

	DelayedExp(500)		
end 

--------------------------------------------------------------------------------------------------------------

local function ScrollableMessage(self, messageBody)

        --mobile side: sending ScrollableMessage request
	local cid = self.mobileSession:SendRPC("ScrollableMessage", 
                                {
                                   scrollableMessageBody = messageBody,
				   timeout = 10000  
                                }) 


	--hmi side: expect UI.ScrollableMessage request
	EXPECT_HMICALL("UI.ScrollableMessage",
                                {
                                   messageText = {
			                          fieldName = "scrollableMessageBody",
			                          fieldText = messageBody
	                                         },
				   timeout = 10000  
                                })
	:Do(function(_,data)
	
	    --HMI sends UI.OnSystemContext
             self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = "HMI_OBSCURED" })
              scrollableMessageId = data.id

		local function scrollableMessageResponse()
			
			--hmi sends response
			self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "SUCCESS", {})	

			--HMI sends UI.OnSystemContext
                        self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = "MAIN" })
		end
		RUN_AFTER(scrollableMessageResponse, 1000)
		
	end)


	--mobile side: expect OnHMIStatus notification
	if HmiLevel == nil then
		HmiLevel = "FULL"
	end
	if 
		HmiLevel == "BACKGROUND" or 
		HmiLevel == "LIMITED" then
		EXPECT_NOTIFICATION("OnHMIStatus",{})
		:Times(0)
	else

		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "HMI_OBSCURED", hmiLevel = HmiLevel, audioStreamingState = audibleState},
				{systemContext = "MAIN", hmiLevel = HmiLevel, audioStreamingState = audibleState}
		)
		:Times(2)
	end

	--mobile side: expect ScrollableMessage response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			
end

----------------------------------------------------------------------------------------------------------

local function Slider(self, SliderValues)
	
	--mobile side: sending Slider request
	local cid = self.mobileSession:SendRPC("Slider", SliderValues)

	--hmi side: expect the request
	EXPECT_HMICALL("UI.Slider", SliderValues)
	:Do(function(_,data)
		
		--HMI sends UI.OnSystemContext
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = "HMI_OBSCURED" })

			
			--hmi side: sending response
			self.hmiConnection:SendResponse(data.id, "UI.Slider", "SUCCESS", {sliderPosition = SliderValues.position })

			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = "MAIN" })
				
	end)

	DelayedExp(500)	
	
	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", sliderPosition})
	
end

----------------------------------------------------------------------------------------------------------

local function SendLocation(self, LocationValues)

		--mobile side: sending SendLocation request
	local cid = self.mobileSession:SendRPC("SendLocation", LocationValues)
	
	--hmi side: expect Navigation.SendLocation request
	EXPECT_HMICALL("Navigation.SendLocation", LocationValues)
	:Do(function(_,data)

		--hmi side: sending Navigation.SendLocation response
		self.hmiConnection:SendResponse(data.id, "UI.SendLocation", "SUCCESS", {})
	end)

	--mobile side: expect SendLocation response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })			
end

-------------------------------------------------------------------------------------------------------------------------------------------------

--Create UI expected result based on parameters from PerformAudioPassThru request
function Test:createUIParameters(AudioParams)
	 param =  {}
	
	param["muteAudio"] =  AudioParams["muteAudio"]
	param["maxDuration"] =  AudioParams["maxDuration"]
	
	local j = 0
	--audioPassThruDisplayText1	
	if AudioParams["audioPassThruDisplayText1"] ~= nil then
		j = j + 1
		if param["audioPassThruDisplayTexts"] == nil then
			param["audioPassThruDisplayTexts"] = {}			
		end		
		param["audioPassThruDisplayTexts"][j] = {
			fieldName = "audioPassThruDisplayText1",
			fieldText = AudioParams["audioPassThruDisplayText1"]
		}
	end
	
	--audioPassThruDisplayText2
	if AudioParams["audioPassThruDisplayText2"] ~= nil then
		j = j + 1
		if param["audioPassThruDisplayTexts"] == nil then
			param["audioPassThruDisplayTexts"] = {}			
		end		
		param["audioPassThruDisplayTexts"][j] = {
			fieldName = "audioPassThruDisplayText2",
			fieldText = AudioParams["audioPassThruDisplayText2"]
		}
	end
		
	return param
end

-------------------------------------------------------

--Create TTS.Speak expected result based on parameters from PerformAudioPassThru request
function Test:createTTSSpeakParameters(AudioParams)
	local param =  {}
	
	param["speakType"] =  "AUDIO_PASS_THRU"
	
	--initialPrompt
	if AudioParams["initialPrompt"]  ~= nil then	
		param["ttsChunks"] =  {	
								{ 
									text = AudioParams.initialPrompt[1].text,
									type = AudioParams.initialPrompt[1].type,									
								}, 
							}			
	end	
		
	return param
end

------------------------------------------------

local function PerformAudioPassThru(self, AudioParams)
	
	--mobile side: sending PerformAudioPassThru request
	local cid = self.mobileSession:SendRPC("PerformAudioPassThru", AudioParams)

        UIParams = self:createUIParameters(AudioParams)
	TTSSpeakParams = self:createTTSSpeakParameters(AudioParams)
				
	if AudioParams["initialPrompt"]  ~= nil then
		--hmi side: expect TTS.Speak request
		EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
		:Do(function(_,data)	
			--Send notification to start TTS
			self.hmiConnection:SendNotification("TTS.Started")
			
			local function ttsSpeakResponse()
				--hmi side: sending TTS.Speak response
				self.hmiConnection:SendResponse(data.id, "TTS.Speak", "SUCCESS", {})
				
				--Send notification to stop TTS
				self.hmiConnection:SendNotification("TTS.Stopped")				
				
				--hmi side: expect UI.OnRecordStart
				EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
			end
			
			RUN_AFTER(ttsSpeakResponse, 50)
		end)
	end
	
	--hmi side: expect UI.PerformAudioPassThru request
	EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
	:Do(function(_,data)	

		--HMI sends UI.OnSystemContext
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = "HMI_OBSCURED" })
		
		
			--hmi side: sending UI.PerformAudioPassThru response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			
			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = "MAIN" })
		--end		
		--RUN_AFTER(uiResponse, 1500)
	end)
	
	--ExpectOnHMIStatusWithAudioStateChanged(self, level, RequestParams["initialPrompt"]  ~= nil)
		
	--mobile side: expect OnAudioPassThru response
	EXPECT_NOTIFICATION("OnAudioPassThru")
	:Times(AtLeast(1))
	:Timeout(10000)
	
	--mobile side: expect PerformAudioPassThru response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
							
	DelayedExp(1000)
end

-------------------------------------------------------------------------------------------------------------

--Create UI expected result based on parameters from ShowConstantTBT request
function Test:createUIParameters(TBTValues)

	local param =  {}

	--maneuverComplete
	param["maneuverComplete"] =  TBTValues["maneuverComplete"]
	
	--distanceToManeuver
	param["distanceToManeuver"] =  TBTValues["distanceToManeuver"]
	
	--distanceToManeuverScale
	param["distanceToManeuverScale"] =  TBTValues["distanceToManeuverScale"]
		
	--Convert navigationTexts parameter
	local j = 0
	
	--navigationText1
	if TBTValues["navigationText1"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}			
		end
		param["navigationTexts"][j] = {
			fieldName = "navigationText1",
			fieldText = TBTValues["navigationText1"]
		}
	end
	
	
	--navigationText2
	if TBTValues["navigationText2"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}			
		end		
		param["navigationTexts"][j] = {
			fieldName = "navigationText2",
			fieldText = TBTValues["navigationText2"]
		}
	end
	
	--eta
	if TBTValues["eta"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}			
		end				
		param["navigationTexts"][j] = {
			fieldName = "ETA",
			fieldText = TBTValues["eta"]
		}
	end
	
	--totalDistance
	if TBTValues["totalDistance"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}			
		end				
		param["navigationTexts"][j] = {
			fieldName = "totalDistance",
			fieldText = TBTValues["totalDistance"]
		}
	end
	
	--timeToDestination
	if TBTValues["timeToDestination"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}			
		end				
		param["navigationTexts"][j] = {
			fieldName = "timeToDestination",
			fieldText = TBTValues["timeToDestination"]
		}
	end
	
	--nextTurnIcon
	param["nextTurnIcon"] =  TBTValues["nextTurnIcon"]
	if param["nextTurnIcon"] ~= nil and 
		param["nextTurnIcon"].imageType ~= "STATIC" and
		param["nextTurnIcon"].value ~= nil and
		param["nextTurnIcon"].value ~= "" then
			param["nextTurnIcon"].value = storagePath ..param["nextTurnIcon"].value
	end	
	
	--turnIcon
	param["turnIcon"] =  TBTValues["turnIcon"]
	if param["turnIcon"] ~= nil and 
		param["turnIcon"].imageType ~= "STATIC" and
		param["turnIcon"].value ~= nil and
		param["turnIcon"].value ~= "" then
			param["turnIcon"].value = storagePath ..param["turnIcon"].value
	end
	
	if TBTValues["softButtons"]  ~= nil then		
		if next(TBTValues["softButtons"]) == nil then
			TBTValues["softButtons"] = nil
		else
			param["softButtons"] =  TBTValues["softButtons"]
			for i = 1, #param["softButtons"] do
			
				--if type = TEXT, image = nil, else type = IMAGE, text = nil
				if param["softButtons"][i].type == "TEXT" then			
					param["softButtons"][i].image =  nil

				elseif param["softButtons"][i].type == "IMAGE" then			
					param["softButtons"][i].text =  nil
				end
				
				--if image.imageType ~=STATIC, add app folder to image value 
				if param["softButtons"][i].image ~= nil and 
					param["softButtons"][i].image.imageType ~= "STATIC" then
					
					param["softButtons"][i].image.value = storagePath ..param["softButtons"][i].image.value
				end	
				
				--if SystemAction is missed then default value will be DEFAULT_ACTION
				if param["softButtons"][i].systemAction == nil then			
					param["softButtons"][i].systemAction =  "DEFAULT_ACTION"
				end
			end
		end
	end		
		
	return param
end

------------------------------------------------

local function ShowConstantTBT(self, TBTValues)	

		--mobile side: sending ShowConstantTBT request
	local	cid = self.mobileSession:SendRPC("ShowConstantTBT", TBTValues)

	-- TODO: remove after resolving APPLINK-16094
	-----------------------------
	if 
		(TBTValues.softButtons and
		#TBTValues.softButtons == 0) then
			TBTValues.softButtons = nil
	end

	if TBTValues.softButtons then
		for i=1,#TBTValues.softButtons do
			if TBTValues.softButtons[i].image then
				TBTValues.softButtons[i].image = nil
			end
		end
	end
	----------------------------

	UIParams = self:createUIParameters(TBTValues)
		
	--hmi side: expect Navigation.ShowConstantTBT request
	EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
	:Do(function(_,data)
		--hmi side: sending Navigation.ShowConstantTBT response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })			
end

-----------------------------------------------------------------------------------------------------------

local function AddSubMenu(self, imenuID, uimenuName)
	--mobile side: sending AddSubMenu request
	local cid = self.mobileSession:SendRPC("AddSubMenu",
				{
					menuID = imenuID,
					position = 1,
					menuName = uimenuName
				})
	
	--hmi side: expect UI.AddSubMenu request 
	EXPECT_HMICALL("UI.AddSubMenu", 
				{ 
					cmdID = iCmdID,		
					menuParams = 
					{
						position = 1,
						menuName = uimenuName
					}
				})
		:Do(function(_,data)
			--hmi side: sending UI.AddSubMenu response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)


	--mobile side: expect AddSubMenu response 
	EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"})
	
	EXPECT_NOTIFICATION("OnHashChange", {})
		:Do(function(_,data)
			self.currentHashID = data.payload.hashID
		end)

	DelayedExp(500)		
end 

---------------------------------------------------------------------------------------------------------

local function CreateInteractionChoiceSet(self, id, choiceName)
	--mobile side: sending CreateInteractionChoiceSet request
	local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
											{
												interactionChoiceSetID = id,
												choiceSet = 
												{ 
													
													{ 
														choiceID = id,
														menuName = choiceName,
														vrCommands = 
														{ 
															choiceName
														}
													}
												}
											})
	
		
	--hmi side: expect VR.AddCommand request
	EXPECT_HMICALL("VR.AddCommand", 
					{ 
						cmdID = id,
						appID = self.applications[config.application1.registerAppInterfaceParams.appName],
						type = "Choice",
						vrCommands = { choiceName }
					})
	:Do(function(_,data)
		--hmi side: sending VR.AddCommand response
		grammarIDValue = data.params.grammarID
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	
	--mobile side: expect CreateInteractionChoiceSet response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
end

---------------------------------------------------------------------------------------------------------

local function SetGlobalProperties(self, StringInRequest)
	--mobile side: sending SetGlobalProperties request
	local cid = self.mobileSession:SendRPC("SetGlobalProperties",
											{
												menuTitle = StringInRequest,
												timeoutPrompt = 
												{
													{
														text = StringInRequest,
														type = "TEXT"
													}
												},
												vrHelp = 
												{
													{
														position = 1,
														text = StringInRequest
													}
												},
												helpPrompt = 
												{
													{
														text = StringInRequest,
														type = "TEXT"
													}
												},
												vrHelpTitle = StringInRequest,
											})


	--hmi side: expect TTS.SetGlobalProperties request
	EXPECT_HMICALL("TTS.SetGlobalProperties",
					{
						timeoutPrompt = 
						{
							{
								text = StringInRequest,
								type = "TEXT"
							}
						},
						helpPrompt = 
						{
							{
								text = StringInRequest,
								type = "TEXT"
							}
						}
					})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)



	--hmi side: expect UI.SetGlobalProperties request
	EXPECT_HMICALL("UI.SetGlobalProperties",
					{
						menuTitle = StringInRequest,
						vrHelp = 
						{
							{
								position = 1,
								text = StringInRequest
							}
						},
						vrHelpTitle = StringInRequest
					})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)


	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	
	EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
end

---------------------------------------------------------------------------------------------------------

local function IGNITION_OFF(self, appNumber)
	StopSDL()

	if appNumber == nil then 
		appNumber = 1
	end

	-- hmi side: sends OnExitAllApplications (SUSPENDED)
	self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
		{
		  reason = "IGNITION_OFF"
		})

	-- hmi side: expect OnSDLClose notification
	EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

	-- hmi side: expect OnAppUnregistered notification
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
		:Times(appNumber)
end

local function SUSPEND(self)
	self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
      {
        reason = "SUSPEND"
      })

    -- hmi side: expect OnSDLPersistenceComplete notification
    EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
end

---------------------------------------------------------------------------------------------------------

local function PutFile(self, syncFileName)
	local cid = self.mobileSession:SendRPC("PutFile",
				{			
					syncFileName = syncFileName,
					fileType	= "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/icon.png")	

	--mobile side: expect PutFile response 
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
end 

---------------------------------------------------------------------------------------------------------

local function SetAppIcon(self, strFileName)
	--mobile side: sending SetAppIcon request
	local cid = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = strFileName })

	--hmi side: expect UI.SetAppIcon request
	EXPECT_HMICALL("UI.SetAppIcon",
	{
		syncFileName = 
		{
			imageType = "DYNAMIC",
			value = storagePath .. strFileName
		}				
	})
	:Do(function(_,data)
		--hmi side: sending UI.SetAppIcon response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	
	--mobile side: expect SetAppIcon response
	EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true })
end 

---------------------------------------------------------------------------------------------------------

local function SoftButtons(self,ShowValue)
	--mobile side: sending Show request	
	local cid = self.mobileSession:SendRPC("Show", ShowValue)

	local UIShowValue = {}

	if ShowValue.softButtons then
		UIShowValue.softButtons = ShowValue.softButtons
		for i=1, #UIShowValue.softButtons do
			if UIShowValue.softButtons[i].image then
				UIShowValue.softButtons[i].image.value = storagePath .. UIShowValue.softButtons[i].image.value
			end
		end
	end

	if 
		ShowValue.mainField1 or
		ShowValue.mainField2 or
		ShowValue.mainField3 or
		ShowValue.mainField4 or
		ShowValue.statusBar or
		ShowValue.mediaClock or
		ShowValue.mediaTrack then

		UIShowValue.showStrings = {}

		local TextFieldName = {"mainField1", "mainField2", "mainField3", "mainField4", "mediaClock", "mediaTrack", "statusBar"}

		for i=1,#TextFieldName do

			if ShowValue[TextFieldName[i]] then
				table.insert (UIShowValue.showStrings, {fieldName = TextFieldName[i], fieldText = ShowValue[TextFieldName[i]]})
			end
		end

	end

	--hmi side: expect the request
	EXPECT_HMICALL("UI.Show", UIShowValue)
	:Do(function(_,data)
		--hmi side: sending the response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	
	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end 

---------------------------------------------------------------------------------------------------------

local function Show(self, ShowValue)

	--mobile side: sending Show request	
	local cid = self.mobileSession:SendRPC("Show", ShowValue)

	if ShowValue.softButtons then
		for i=1, #ShowValue.softButtons do
			if ShowValue.softButtons[i].image then
				softButtonsValue[i].image.value = storagePath .. softButtonsValue[i].image.value
			end
		end
	end

	local UIShowValue = {}

	if 
		ShowValue.mainField1 or
		ShowValue.mainField2 or
		ShowValue.mainField3 or
		ShowValue.mainField4 or
		ShowValue.statusBar or
		ShowValue.mediaClock or
		ShowValue.mediaTrack then

		UIShowValue.showStrings = {}

		local TextFieldName = {"mainField1", "mainField2", "mainField3", "mainField4", "mediaClock", "mediaTrack", "statusBar"}

		for i=1,#TextFieldName do

			if ShowValue[TextFieldName[i]] then
				table.insert (UIShowValue.showStrings, {fieldName = TextFieldName[i], fieldText = ShowValue[TextFieldName[i]]})
			end
		end

	end

	UIShowValue.alignment = ShowValue.alignment
	UIShowValue.softButtons = ShowValue.softButtons
	UIShowValue.customPresets = ShowValue.customPresets

	--hmi side: expect the request
	EXPECT_HMICALL("UI.Show", UIShowValue)
	:Do(function(_,data)
		--hmi side: sending the response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	
	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end 

---------------------------------------------------------------------------------------------------------

local function RegisterAppInterface(self, session, RAIParameters, RAIParamsToCheck)

	--mobile side: RegisterAppInterface request 
	local CorIdRAI = session:SendRPC("RegisterAppInterface", RAIParameters)
	

 	--hmi side: expected  BasicCommunication.OnAppRegistered
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", RAIParamsToCheck)
		:Do(function(_,data)
			self.applications[data.params.application.appName] = data.params.application.appID
		end)

	--mobile side: RegisterAppInterface response 
	session:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})

	session:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

end 

---------------------------------------------------------------------------------------------------------

local function ChangeRegistration(self, paramsSend)
	--mobile side: send ChangeRegistration request 	 	
	local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)
	
	--hmi side: expect UI.ChangeRegistration request 
	EXPECT_HMICALL("UI.ChangeRegistration", 
	{									
		appName = paramsSend.appName,
		language = paramsSend.hmiDisplayLanguage,
		ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
	})
	:Do(function(_,data)
		--hmi side: send UI.ChangeRegistration response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)

	--hmi side: expect VR.ChangeRegistration request 
	EXPECT_HMICALL("VR.ChangeRegistration", 
	{	
		language = paramsSend.language,
		vrSynonyms = paramsSend.vrSynonyms
	})
	:Do(function(_,data)
		--hmi side: send VR.ChangeRegistration response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)

	--hmi side: expect TTS.ChangeRegistration request 
	EXPECT_HMICALL("TTS.ChangeRegistration", 
	{	
		language = paramsSend.language,
		ttsName = paramsSend.ttsName
	})
	:Do(function(_,data)
		--hmi side: send TTS.ChangeRegistration response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)
	
	--mobile side: expect ChangeRegistration response
	EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })

	EXPECT_NOTIFICATION("OnHMIStatus", {})
	:Times(0)

	DelayedExp(1000)
end 

---------------------------------------------------------------------------------------------------------

local function PerformInteraction(self, paramsSend, manualTextEntryValue)
	--mobile side: sending PerformInteraction request
	local cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)
	
	--hmi side: expect VR.PerformInteraction request 
	EXPECT_HMICALL("VR.PerformInteraction")
	:Do(function(_,data)
		--Send notification to start TTS 						
		self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
	end)
	
	--hmi side: expect UI.PerformInteraction request 
	EXPECT_HMICALL("UI.PerformInteraction")
	:Do(function(_,data)
		--hmi side: send UI.PerformInteraction response
		SendOnSystemContext(self,"HMI_OBSCURED")							
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {manualTextEntry = manualTextEntryValue})					
		--Send notification to stop TTS 
		SendOnSystemContext(self,"MAIN")						
	end)
	
	--mobile side: OnHMIStatus notifications
	self.mobileSession:ExpectNotification("OnHMIStatus", 
		{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "HMI_OBSCURED"},
		{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
		:Times(2)
	
	--mobile side: expect PerformInteraction response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", manualTextEntry = manualTextEntryValue })
end

---------------------------------------------------------------------------------------------------------

local function UnregisterApplication_Success(self, session)
	--mobile side: UnregisterAppInterface request 
	local CorIdUAI = session:SendRPC("UnregisterAppInterface",{}) 

	--hmi side: expect OnAppUnregistered notification 
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false})
 

	--mobile side: UnregisterAppInterface response 
	session:ExpectResponse(CorIdUAI, { success = true, resultCode = "SUCCESS"})
end

-- Activation of application
function ActivationApp(self, appId)

	--hmi side: sending SDL.ActivateApp request
  	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId})

  	--hmi side: expect SDL.ActivateApp response
	EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)
			--In case when app is not allowed, it is needed to allow app
	    	if
	        	data.result.isSDLAllowed ~= true then

	        		--hmi side: sending SDL.GetUserFriendlyMessage request
	            	local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
								        {language = "EN-US", messageCodes = {"DataConsent"}})

	            	--hmi side: expect SDL.GetUserFriendlyMessage response
    			  	--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
						EXPECT_HMIRESPONSE(RequestId)
						:Do(function(_,data)

		    			    --hmi side: send request SDL.OnAllowSDLFunctionality
		    			    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
		    			    	{allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

		    			    --hmi side: expect BasicCommunication.ActivateApp request
				            EXPECT_HMICALL("BasicCommunication.ActivateApp")
				            	:Do(function(_,data)

				            		--hmi side: sending BasicCommunication.ActivateApp response
						          	self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

						        end)
						        :Times(2)
		              	end)
		    else 
		    	-- hmi side: expect of absence BasicCommunication.ActivateApp
		    	EXPECT_HMICALL("BasicCommunication.ActivateApp")
		    	:Times(0)
			end
	      end)

	DelayedExp(500)

end

---------------------------------------------------------------------------------------------------------

function ReregistrationApplication(prefix, appNameValue)
	Test[ "UnregisterApplication_" .. tostring(prefix) ] = function (self)
		UnregisterApplication_Success(self, self.mobileSession)
	end

	Test[ "RegisterApplication_" .. tostring(prefix) ] = function (self)

		local RAIParameters = copy_table(config.application1.registerAppInterfaceParams)
		RAIParameters.appName = appNameValue

		local RAIParamsToCheck = {
				application = {
					appName = appNameValue
				}

			}

		RegisterAppInterface(self, self.mobileSession, RAIParameters, RAIParamsToCheck)
	end

end

---------------------------------------------------------------------------------------------------------

function SetUseDBForResumption(UseDBForResumptionValue)

	local StringToReplace = "\nUseDBForResumption = " .. tostring(UseDBForResumptionValue) .. "\n"

	local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")

	f = assert(io.open(SDLini, "r"))
	if f then
		fileContent = f:read("*all")
			local MatchResult = string.match(fileContent, "\nUseDBForResumption%s-=%s-.-%s-\n")
			if MatchResult ~= nil then
				fileContentUpdated  =  string.gsub(fileContent, MatchResult, StringToReplace)
				f = assert(io.open(SDLini, "w"))
				f:write(fileContentUpdated)
			else 
				userPrint(31, "Finding of 'UseDBForResumption = value' is failed. Expect string finding and replacing of value to " .. tostring(UseDBForResumptionValue))
			end
		f:close()
	end
end

---------------------------------------------------------------------------------------------------------

function StartSDLHMI(prefix)
	Test["Precondition_StartSDL_" .. tostring(prefix)] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["Precondition_InitHMI_" .. tostring(prefix)] = function(self)
		self:initHMI()
	end

	Test["Precondition_InitHMI_onReady_" .. tostring(prefix)] = function(self)
		self:initHMI_onReady()
	end

	Test["Precondition_ConnectMobile_" .. tostring(prefix)] = function(self)
		self:connectMobile()
	end

	Test["Precondition_StartSession_" .. tostring(prefix)] = function(self)
	 	self.mobileSession = mobile_session.MobileSession(
	    self,
	    self.mobileConnection,
	    config.application1.registerAppInterfaceParams)

	     self.mobileSession:StartService(7)

	end
end

---------------------------------------------------------------------------------------------------------

function SwitchOffSDL(prefix, appNumber)
	Test["Precondition_SUSPEND_" .. tostring(prefix)] = function(self)
		SUSPEND(self)
	end

	Test["Precondition_IGNITION_OFF_" .. tostring(prefix)] = function(self)
		IGNITION_OFF(self)
	end
end

-- Check directory existence 
local function Directory_exist(DirectoryPath)
	local returnValue

	local Command = assert( io.popen(  "[ -d " .. tostring(DirectoryPath) .. " ] && echo \"Exist\" || echo \"NotExist\"" , 'r'))
	local CommandResult = tostring(Command:read( '*l' ))

	if 
		CommandResult == "NotExist" then
			returnValue = false
	elseif 
		CommandResult == "Exist" then
		returnValue =  true
	else 
		userPrint(31," Some unexpected result in Directory_exist function, CommandResult = " .. tostring(CommandResult))
		returnValue = false
	end

	return returnValue
end

-- Check file existence 
function file_exists(name, messages)
   	local f=io.open(name,"r")

   	if f ~= nil then 
   		io.close(f)
   		return true
   	else 
   		return false 
   	end
end
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
 -- Precondition: activate application
function Test:Precondition_ActivateApp()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
end

-- APPLINK-16726: 01[P][XML]_TC_AddCommand_in_UTF-8
--===================================================================================--
-- Checking displaying Command name on HMI in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish). (String parameter menuName is in Structure menuParams of AddCommand request).
--===================================================================================--

for i=1,#AddCommandValues do
	Test["AddCommand_" .. tostring(AddCommandValues[i].languageName)] = function(self)
		AddCommand(self, i, AddCommandValues[i].value, {AddCommandValues[i].value})
	end
end


--===================================================================================--
-- Checking displaying ScrollableMessage on HMI in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish).
--===================================================================================--

for i=1,#messageBodyValues do
	Test["ScrollableMessage_" .. tostring(messageBodyValues[i].languageName)] = function(self)
		ScrollableMessage(self, messageBodyValues[i].value)
	end
end

--===================================================================================--
-- Checking displaying Slider on HMI in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish).
--===================================================================================--

local SliderValues = {
                -- Korean language
 { 			languageName = "Korean",
   			value = 
		{
                        numTicks = 3,
			position = 2,
			sliderHeader = "가까운",
                        sliderFooter = {"가까운"}, 
			timeout = 5000
		}
 },
                -- Japanese language
 { 			languageName = "Japanese",
    			value = 
                {			
                        numTicks = 3,
			position = 2,
			sliderHeader = "クローズ",
                        sliderFooter = {"クローズ"},
			timeout = 5000
		}
 },
                -- Russian language
 { 			languageName = "Russian",
    			value = 
                {
			numTicks = 3,
			position = 2,
                        sliderHeader = "Закрыть",
			sliderFooter = {"Закрыть"},
			timeout = 5000
		}
 },
                -- Spanish language
 { 			languageName = "Spanish",
    			value = 
            
                {
			numTicks = 3,
			position = 2,
			sliderHeader = "español",
			sliderFooter = {"español"},
			timeout = 5000
		}
 },
                -- Arabic language
 { 			languageName = "Arabic",
   		 	value = 
                {
			numTicks = 3,
			position = 2,
			sliderHeader = "رمز زر",
			sliderFooter = {"رمز زر"},
			timeout = 5000
		}
 },
                -- French language
 {                      languageName = "French",
                        value = 

                {
			numTicks = 3,
			position = 2,
			sliderHeader = "l'icône",
			sliderFooter = {"l'icône"},
			timeout = 5000
		}
 },
                -- German language
 {                      languageName = "German",
                         value = 
                {
			numTicks = 3,
			position = 2,
			sliderHeader = "schließen",
			sliderFooter = {"schließen"},
			timeout = 5000
		}
 } 
}

for i=1,#SliderValues do
	Test["Slider_" .. tostring(SliderValues[i].languageName)] = function(self)
		Slider(self, SliderValues[i].value)
	end
end


--===================================================================================--
-- Checking displaying SendLocation on HMI in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish).
--===================================================================================--

 local LocationValues = {
                        -- Korean language
 	{ 		languageName = "Korean",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "가까운",
			locationDescription = "가까운",
			addressLines = 
				{ 
					"가까운",
					"가까운",
				}, 
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         },  
                           -- Japanese language
 	{ 		languageName = "Japanese",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "クローズ",
			locationDescription = "クローズ",
			addressLines = 
				{ 
					"クローズ",
					"クローズ",
				}, 
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         }, 
                           -- Russian language
 	{ 		languageName = "Russian",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "Закрыть",
			locationDescription = "Закрыть",
			addressLines = 
				{ 
					"Закрыть",
					"Закрыть",
				}, 
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         }, 
                           -- Spanish language
 	{ 		languageName = "Spanish",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "español",
			locationDescription = "español",
			addressLines = 
				{ 
					"español",
					"español",
				}, 
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         }, 
                           -- Arabic language
 	{ 		languageName = "Arabic",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "رمز زر",
			locationDescription = "رمز زر",
			addressLines = 
				{ },
					
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         }, 
                           -- French language
 	{ 		languageName = "French",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "l'icône",
			locationDescription = "l'icône",
			addressLines = 
				{ 
					"l'icône",
					"l'icône",
				}, 
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         }, 
                           -- German language
 	{ 		languageName = "German",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "schließen",
			locationDescription = "schließen",
			addressLines = 
				{ 
					"schließen",
					"schließen",
				}, 
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         }      

}

for i=1,#LocationValues do
	Test["SendLocation_" .. tostring(LocationValues[i].languageName)] = function(self)
		SendLocation(self, LocationValues[i].value)
	end
end

--===================================================================================--
-- Checking displaying PerformAudioPassThru on HMI in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish).
--===================================================================================--

local AudioParams = {					-- Korean language
 						{ 	languageName = "Korean",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="가까운",
									audioPassThruDisplayText2 ="가까운",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 },
						         -- Japanese language
 						{ 	languageName = "Japanese",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="クローズ",
									audioPassThruDisplayText2 ="クローズ",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 }, 
						         -- Russian language
 						{ 	languageName = "Russian",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="Закрыть",
									audioPassThruDisplayText2 ="Закрыть",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 },
					                  -- Spanish language
 						{ 	languageName = "Spanish",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="español",
									audioPassThruDisplayText2 ="español",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 },
						         -- Arabic language
 						{ 	languageName = "Arabic",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="رمز زر",
									audioPassThruDisplayText2 ="رمز زر",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 },
						         -- French language
 						{ 	languageName = "French",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="l'icône",
									audioPassThruDisplayText2 ="l'icône",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 },	
						           -- German language
 						{ 	languageName = "German",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="schließen",
									audioPassThruDisplayText2 ="schließen",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 }	
																					
                                                 
		     }



for i=1,#AudioParams do
	Test["PerformAudioPassThru_" .. tostring(AudioParams[i].languageName)] = function(self)
		PerformAudioPassThru(self, AudioParams[i].value)
	end
end

--===================================================================================--
-- Checking displaying ShowConstantTBT on HMI in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish).
--===================================================================================--


local TBTValues = {           -- Arabic language
 			    { 	languageName = "Arabic",
   				value = {                
						navigationText1 ="رمز زر1",
						navigationText2 ="2رمز زر",
						eta ="12:34",
						totalDistance ="رمز زر100",
                                                timeToDestination = "100رمز زر", 
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }, 
                             -- Korean language
 			    { 	languageName = "Korean",
   				value = {                
						navigationText1 ="가까운1",
						navigationText2 ="가까운2",
						eta ="12:34",
						totalDistance ="100가까운",
                                                timeToDestination = "100가까운", 
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }, 
                            -- Japanese language
 			    { 	languageName = "Japanese",
   				value = {                
						navigationText1 ="クローズ",
						navigationText2 ="クローズ",
						eta ="12:34",
						totalDistance ="100クローズ",
                                                timeToDestination = "100クローズ", 
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }, 
                            -- Russian language
 			    { 	languageName = "Russian",
   				value = {                
						navigationText1 ="Закрыть1",
						navigationText2 ="Закрыть2",
						eta ="12:34",
						totalDistance ="100Закрыть",
                                                timeToDestination = "100Закрыть", 
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }, 
                            -- French language
 			    { 	languageName = "French",
   				value = {                
						navigationText1 ="l'icône1",
						navigationText2 ="l'icône2",
						eta ="12:34",
						totalDistance ="100l'icône",
                                                timeToDestination = "100l'icône", 
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }, 
                            -- German language
 			    { 	languageName = "German",
   				value = {                
						navigationText1 ="schließen1",
						navigationText2 ="schließen2",
						eta ="12:34",
						totalDistance ="100schließen",
                                                timeToDestination = "100schließen", 
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }, 
                            -- Spanish language
 			    { 	languageName = "Spanish",
   				value = {                
						navigationText1 ="español1",
						navigationText2 ="español2",
						eta ="12:34",
						totalDistance ="100español",
                                                timeToDestination = "100español", 
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }  
		} 


for i=1,#TBTValues do
	Test["ShowConstantTBT_" .. tostring(TBTValues[i].languageName)] = function(self)
		ShowConstantTBT(self, TBTValues[i].value)
	end
end


-- APPLINK-16729: 02[P][XML]_TC_PutFile_in_UTF-8
--===================================================================================--
-- Checking saving files to SDL directory with names in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
--===================================================================================--

for i=1,#PutFileValues do
	Test["PutFile_" .. tostring(PutFileValues[i].languageName)] = function(self)
		PutFile(self, PutFileValues[i].value)
	end
end

-- APPLINK-16731: 03[P][XML]_TC_SetAppIcon_in_UTF-8
--===================================================================================--
-- Checking setting application icon from image file  which name in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
--===================================================================================--

for i=1,#PutFileValues do
	Test["SetAppIcon_usingPutFile_" .. tostring(PutFileValues[i].languageName)] = function(self)
		SetAppIcon(self, PutFileValues[i].value)
	end
end

-- APPLINK-16734: 04[P][XML]_TC_TC_SoftButtons_in_UTF-8
--===================================================================================--
-- Checking displaying SoftButtons names and displaying they images fields on HMI in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
--===================================================================================--

function Test:ShowWithSoftButtonsTextAndImageNameIn_Korean_Japanese_Russian_Spanish_Arabic_French_German()

	local ShowValue = {	
		mainField1 = "SoftButtons names",
		softButtons = {
			-- Korean language
			{
				type = "BOTH",
				text = "가까운",
				image = {
					value = "버튼 아이콘.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 111,
				systemAction = "DEFAULT_ACTION"
			},
			-- Japanese language
			{
				type = "BOTH",
				text = "クローズ",
				image = {
					value = "ボタンアイコン.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 112,
				systemAction = "DEFAULT_ACTION"
			},
			-- Russian language
			{
				type = "BOTH",
				text = "Закрыть",
				image = {
					value = "Иконка.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 113,
				systemAction = "DEFAULT_ACTION"
			},
			-- Spanish language
			{
				type = "BOTH",
				text = "Cerrar",
				image = {
					value = "icono_Español.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 114,
				systemAction = "DEFAULT_ACTION"
			},
			-- Arabic language
			{
				type = "BOTH",
				text = "قريب",
				image = {
					value = "رمز زر.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 115,
				systemAction = "DEFAULT_ACTION"
			},
			-- French language
			{
				type = "BOTH",
				text = "Près",
				image = {
					value = "l'icône_Française.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 116,
				systemAction = "DEFAULT_ACTION"
			},
			-- German language
			{
				type = "BOTH",
				text = "Schließen",
				image = {
					value = "Schaltflächensymbol.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 117,
				systemAction = "DEFAULT_ACTION"
			}
		}
	}

	SoftButtons(self, ShowValue)
end

-- APPLINK-16737: 05[P][XML]_TC_Show_in_UTF-8
--===================================================================================--
 -- Checking displaying Show fields on HMI in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
--===================================================================================--

local ShowValues = {
	{
		languageName = "Arabic",
		value = 
		{
			mainField1 = "الكورية",
			mainField2 = "اللغة",
			mainField3 = "اختبار",
			alignment = "RIGHT_ALIGNED",
			statusBar = "شريط الحالة ",
			mediaClock = "دقيقة: ثانية: ح",
			mediaTrack = "المسار الصوتي",
			customPresets = {"مسبقا1", "مسبقا2", "مسبقا3"},
			softButtons = {
				{
					type = "TEXT",
					text = "قريب",
					isHighlighted = true,
					softButtonID = 111,
					systemAction = "DEFAULT_ACTION"
				}
			}
		}
	},
	{
		languageName = "French",
		value = 
		{
			mainField1 = "Vérifiez l'affichage",
			mainField2 = "de la",
			mainField3 = "Française",
			alignment = "RIGHT_ALIGNED",
			statusBar = "la barre d'état",
			mediaClock = "minutes: secondes: h",
			mediaTrack = "chemin média",
			customPresets = {"préréglé1", "préréglé2", "préréglé3"},
			softButtons = {
				{
					type = "TEXT",
					text = "Près",
					isHighlighted = true,
					softButtonID = 111,
					systemAction = "DEFAULT_ACTION"
				}
			}
		}
	},
	{
		languageName = "German",
		value = 
		{
			mainField1 = "Die Prüfungr",
			mainField2 = "der Abbildung",
			mainField3 = "des Deutschen",
			alignment = "RIGHT_ALIGNED",
			statusBar = "Die Statusleiste",
			mediaClock = "Minute: Sekunde: h",
			mediaTrack = "Audiospur",
			customPresets = {"Voreinstellung1", "Voreinstellung1", "Voreinstellung1"},
			softButtons = {
				{
					type = "TEXT",
					text = "Schließen",
					isHighlighted = true,
					softButtonID = 111,
					systemAction = "DEFAULT_ACTION"
				}
			}
		}
	},
	{
		languageName = "Japanese",
		value = 
		{
			mainField1 = "日本語",
			mainField2 = "の",
			mainField3 = "テスト",
			alignment = "RIGHT_ALIGNED",
			statusBar = "ステータスバー ",
			mediaClock = "分：秒：H",
			mediaTrack = "オーディオトラック ",
			customPresets = {"プリセット1", "プリセット2", "プリセット3"},
			softButtons = {
				{
					type = "TEXT",
					text = "クローズ",
					isHighlighted = true,
					softButtonID = 111,
					systemAction = "DEFAULT_ACTION"
				}
			}
		}
	},
	{
		languageName = "Korean",
		value = 
		{
			mainField1 = "한국어",
			mainField2 = "시험ة",
			mainField3 = "한국어",
			alignment = "RIGHT_ALIGNED",
			statusBar = "상태 표시 줄",
			mediaClock = "분 : 초 : H",
			mediaTrack = "오디오 트랙",
			customPresets = {"م사전1", "م사전2", "م사전3"},
			softButtons = {
				{
					type = "TEXT",
					text = "가까운",
					isHighlighted = true,
					softButtonID = 111,
					systemAction = "DEFAULT_ACTION"
				}
			}
		}
	},
	{
		languageName = "Russian",
		value = 
		{
			mainField1 = "Проверка",
			mainField2 = "Отображения",
			mainField3 = "Русского",
			alignment = "RIGHT_ALIGNED",
			statusBar = "Строка состояния",
			mediaClock = "минута:секунда:час",
			mediaTrack = "Аудиодорожка",
			customPresets = {"Предустановка1", "Предустановка2", "Предустановка3"},
			softButtons = {
				{
					type = "TEXT",
					text = "Закрыть",
					isHighlighted = true,
					softButtonID = 111,
					systemAction = "DEFAULT_ACTION"
				}
			}
		}
	},
	{
		languageName = "Spanish",
		value = 
		{
			mainField1 = "Comprobar",
			mainField2 = "Mostrar",
			mainField3 = "Español",
			alignment = "RIGHT_ALIGNED",
			statusBar = "La barra de estado",
			mediaClock = "minutos: segundos: h",
			mediaTrack = "pista de audio",
			customPresets = {"preajuste1", "preajuste2", "preajuste3"},
			softButtons = {
				{
					type = "TEXT",
					text = "Cerrar",
					isHighlighted = true,
					softButtonID = 111,
					systemAction = "DEFAULT_ACTION"
				}
			}
		}
	}
}

for i=1,#ShowValues do
	Test["Show_" .. tostring(ShowValues[i].languageName)] = function(self)
		Show(self, ShowValues[i].value)
	end
end

-- APPLINK-16738: 06[P][MAN]_TC_RegisterAppInterface_in_UTF-8
--===================================================================================--
-- Checking creating app folder in SDL directory with names in different languages.
-- Checking Registering application and displaying app name in different languages on HMI. (Arabic, French, German, Japanese, Korean, Russian, Spanish)
--===================================================================================--

for i=1, #appNameValues do
	ReregistrationApplication(appNameValues[i].languageName, appNameValues[i].value)
end

-- APPLINK-16740: 07[P][XML]_TC_ChangeRegistration_in_UTF-8
--===================================================================================--
-- Checking displaying appName, vrSynonyms of application and Show fields on HMI in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
--===================================================================================--

--Precondition for Changeregistration test cases

ReregistrationApplication("ChangeRegistration", config.application1.registerAppInterfaceParams.appName)

function Test:Precondition_ActivateApp_ChangeRegistration()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
end
---------------------------------------------------

local ChangeRegistrationValues = {
	{
		languageName = "Arabic",
		value = {
			language = "AR-SA",
			hmiDisplayLanguage = "AR-SA",
			appName = "الكورية",
			ttsName = { {text = "الكورية", type = "TEXT"} },
			ngnMediaScreenAppName = "لكورية",
			vrSynonyms = {"الكورية"}
		}
	},
	{
		languageName = "French",
		value = {
			language = "FR-FR",
			hmiDisplayLanguage = "FR-FR",
			appName = "Française",
			ttsName = { {text = "Française", type = "TEXT"} },
			ngnMediaScreenAppName = "Française",
			vrSynonyms = {"Française"}
		}
	},
	{
		languageName = "German",
		value = {
			language = "DE-DE",
			hmiDisplayLanguage = "DE-DE",
			appName = "Die Prüfungr",
			ttsName = { {text = "Die Prüfungr", type = "TEXT"} },
			ngnMediaScreenAppName = "Die Prüfungr",
			vrSynonyms = {"Die Prüfungr"}
		}
	},
	{
		languageName = "Japanese",
		value = {
			language = "JA-JP",
			hmiDisplayLanguage = "JA-JP",
			appName = "日本語",
			ttsName = { {text = "日本語", type = "TEXT"} },
			ngnMediaScreenAppName = "日本語",
			vrSynonyms = {"日本語"}
		}
	},
	{
		languageName = "Korean",
		value = {
			language = "KO-KR",
			hmiDisplayLanguage = "KO-KR",
			appName = "한국어",
			ttsName = { {text = "한국어", type = "TEXT"} },
			ngnMediaScreenAppName = "한국어",
			vrSynonyms = {"한국어"}
		}
	},
	{
		languageName = "Russian",
		value = {
			language = "RU-RU",
			hmiDisplayLanguage = "RU-RU",
			appName = "СинкПроксиТестер",
			ttsName = { {text = "СинкПроксиТестер", type = "TEXT"} },
			ngnMediaScreenAppName = "СинкПроксиТестер",
			vrSynonyms = {"СинкПроксиТестер"}
		}
	},
	{
		languageName = "Spanish",
		value = {
			language = "ES-MX",
			hmiDisplayLanguage = "ES-MX",
			appName = "Español",
			ttsName = { {text = "Español", type = "TEXT"} },
			ngnMediaScreenAppName = "Español",
			vrSynonyms = {"Español"}
		}
	}
}

for i=1, #ChangeRegistrationValues do
	Test[ "ChangeRegistration_" .. tostring(ChangeRegistrationValues[i].languageName) ] = function(self)
		ChangeRegistration(self, ChangeRegistrationValues[i].value)
		for j=1, #ShowValues do
			if ChangeRegistrationValues[i].languageName == ShowValues[j].languageName then
				Show(self, ShowValues[j].value)
			end
		end
	end
end

--===================================================================================--
-- Checking processing manualTextEntry to mobile application in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
--===================================================================================--

ReregistrationApplication("PerformInteraction", config.application1.registerAppInterfaceParams.appName)

function Test:Precondition_ActivateApp_PerformInteraction()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
end

function Test:Precondition_ChoiceSet_for_PI()
CreateInteractionChoiceSet(self, 11111, "Precondition_PerformInteractionChoiceSet")
end

for i=1,#AddCommandValues do
	Test["PerformInteraction_" .. tostring(AddCommandValues[i].languageName)] = function(self)
		local PIParams = {
			initialText = "StartPerformInteraction" .. tostring(AddCommandValues[i].languageName),
			interactionMode = "MANUAL_ONLY",
			interactionChoiceSetIDList = {11111},
			timeout = 5000,
			interactionLayout = "KEYBOARD"
		}
		PerformInteraction(self, PIParams, AddCommandValues[i].value)
	end
end


----------------------------------------------------------------------------------------
-- Unregister registered app, register application again
ReregistrationApplication("AddCommandUpperBound", config.application1.registerAppInterfaceParams.appName)

----------------------------------------------------------------------------------------
--Acticvate application
function Test:Precondition_ActivateApp_AddCommandUpperBound()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
end

-- APPLINK-16751: 12[P][XML]_TC_AddCommand_UTF-8_UpperBound
--===================================================================================--
 -- Upper bound  of AddCommand menuName in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
 --===================================================================================--
for i=1,#AddCommandUpperBound do
	Test["AddCommand_" .. tostring(AddCommandUpperBound[i].languageName)] = function(self)
		AddCommand(self, i, AddCommandUpperBound[i].value, {AddCommandUpperBound[i].value})
	end
end


--===================================================================================--
 -- Upper bound  of ScrollableMessage in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
 --===================================================================================--
for i=1,#messageBodyUpperBound do
	Test["ScrollableMessage_" .. tostring(messageBodyUpperBound[i].languageName)] = function(self)
		ScrollableMessage(self, messageBodyUpperBound[i].value)
	end
end


--===================================================================================--
-- Upper bound of Slider on HMI in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish).
--===================================================================================--

local SliderValues = {
                -- Korean language
 { 			languageName = "Korean",
   			value = 
		{
                        numTicks = 3,
			position = 2,
			sliderHeader = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
                        sliderFooter = {"버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호"}, 
			timeout = 5000
		}
 },
                -- Japanese language
 { 			languageName = "Japanese",
    			value = 
                {			
                        numTicks = 3,
			position = 2,
			sliderHeader = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
                        sliderFooter = {"ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの"},
			timeout = 5000
		}
 },
                -- Russian language
 { 			languageName = "Russian",
    			value = 
                {
			numTicks = 3,
			position = 2,
                        sliderHeader = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
			sliderFooter = {"вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ"},
			timeout = 5000
		}
 },
                -- Spanish language
 { 			languageName = "Spanish",
    			value = 
            
                {
			numTicks = 3,
			position = 2,
			sliderHeader = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
			sliderFooter = {"ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF"},
			timeout = 5000
		}
 },
                -- Arabic language
 { 			languageName = "Arabic",
   		 	value = 
                {
			numTicks = 3,
			position = 2,
			sliderHeader = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
			sliderFooter = {"منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج"},
			timeout = 5000
		}
 },
                -- French language
 {                      languageName = "French",
                        value = 

                {
			numTicks = 3,
			position = 2,
			sliderHeader = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
			sliderFooter = {"l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï"},
			timeout = 5000
		}
 },
                -- German language
 {                      languageName = "German",
                         value = 
                {
			numTicks = 3,
			position = 2,
			sliderHeader = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
			sliderFooter = {"SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn"},
			timeout = 5000
		}
 } 
}

for i=1,#SliderValues do
	Test["Slider_UpperBound_" .. tostring(SliderValues[i].languageName)] = function(self)
		Slider(self, SliderValues[i].value)
	end
end


--===================================================================================--
-- Upper bound of SendLocation in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish).
--===================================================================================--

 local LocationValues = {
                        -- Korean language
 	{ 		languageName = "Korean",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
			locationDescription = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
			addressLines = 
				{ 
					"버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
					"버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
				}, 
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         },  
                           -- Japanese language
 	{ 		languageName = "Japanese",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
			locationDescription = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
			addressLines = 
				{ 
					"ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
					"ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
				}, 
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         }, 
                           -- Russian language
 	{ 		languageName = "Russian",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
			locationDescription = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
			addressLines = 
				{ 
					"вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
					"вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
				}, 
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         }, 
                           -- Spanish language
 	{ 		languageName = "Spanish",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
			locationDescription = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
			addressLines = 
				{ 
					"ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
					"ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
				}, 
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         }, 
                           -- Arabic language
 	{ 		languageName = "Arabic",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
			locationDescription = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
			addressLines = 
				{},
					
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         }, 
                           -- French language
 	{ 		languageName = "French",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
			locationDescription = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
			addressLines = 
				{ 
					"l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
					"l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
				}, 
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         }, 
                           -- German language
 	{ 		languageName = "German",
   			value = 
 		{
          		longitudeDegrees = 1.1,
			latitudeDegrees = 1.1,
			locationName = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
			locationDescription = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
			addressLines = 
				{ 
					"SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
					"SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
				}, 
			phoneNumber = "phone Number",
			locationImage =	
				{ 
					value = "icon.png",
					imageType = "DYNAMIC",
				}
               }
         }      

}

for i=1,#LocationValues do
	Test["SendLocation_UpperBound_" .. tostring(LocationValues[i].languageName)] = function(self)
		SendLocation(self, LocationValues[i].value)
	end
end


--===================================================================================--
-- Upper bound of PerformAudioPassThru on HMI in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish).
--===================================================================================--

local AudioParams = {					-- Korean language
 						{ 	languageName = "Korean",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
									audioPassThruDisplayText2 ="버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 },
						         -- Japanese language
 						{ 	languageName = "Japanese",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
									audioPassThruDisplayText2 ="ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 }, 
						         -- Russian language
 						{ 	languageName = "Russian",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
									audioPassThruDisplayText2 ="вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 },
					                  -- Spanish language
 						{ 	languageName = "Spanish",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
									audioPassThruDisplayText2 ="ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 },
						         -- Arabic language
 						{ 	languageName = "Arabic",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
									audioPassThruDisplayText2 ="منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 },
						         -- French language
 						{ 	languageName = "French",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
									audioPassThruDisplayText2 ="l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 },	
						           -- German language
 						{ 	languageName = "German",
   							value = {
									initialPrompt = 
									{	
										{ 
											text ="Makeyourchoice",
											type ="TEXT",
										}, 
									}, 
									audioPassThruDisplayText1 ="SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
									audioPassThruDisplayText2 ="SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
									samplingRate ="8KHZ",
									maxDuration = 2000,
									bitsPerSample ="8_BIT",
									audioType ="PCM",
									muteAudio = true
                                                                  }
                                                 }	
																					
                                                 
		     }



for i=1,#AudioParams do
	Test["PerformAudioPassThru_UpperBound_" .. tostring(AudioParams[i].languageName)] = function(self)
		PerformAudioPassThru(self, AudioParams[i].value)
	end
end


--===================================================================================--
-- Upper bound of ShowConstantTBT on HMI in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish).
--===================================================================================--

local TBTValues = {           -- Arabic language
 			    { 	languageName = "Arabic",
   				value = {                
						navigationText1 ="منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
						navigationText2 ="منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
						eta ="12:34",
						totalDistance ="منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
                                                timeToDestination = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج", 
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }, 
                             -- Korean language
 			    { 	languageName = "Korean",
   				value = {                
						navigationText1 ="버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
						navigationText2 ="버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
						eta ="12:34",
						totalDistance ="버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
                                                timeToDestination = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호", 
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }, 
                            -- Japanese language
 			    { 	languageName = "Japanese",
   				value = {                
						navigationText1 ="ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
						navigationText2 ="ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
						eta ="12:34",
						totalDistance ="ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
                                                timeToDestination = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの", 
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }, 
                            -- Russian language
 			    { 	languageName = "Russian",
   				value = {                
						navigationText1 ="вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
						navigationText2 ="вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
						eta ="12:34",
						totalDistance ="вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
                                                timeToDestination = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ", 
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }, 
                            -- French language
 			    { 	languageName = "French",
   				value = {                
						navigationText1 ="ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
						navigationText2 ="ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
						eta ="12:34",
						totalDistance ="ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
                                                timeToDestination = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF", 
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }, 
                            -- German language
 			    { 	languageName = "German",
   				value = {                
						navigationText1 ="SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
						navigationText2 ="SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
						eta ="12:34",
						totalDistance ="SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
                                                timeToDestination = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }, 
                            -- Spanish language
 			    { 	languageName = "Spanish",
   				value = {                
						navigationText1 ="ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
						navigationText2 ="ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
						eta ="12:34",
						totalDistance ="ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
                                                timeToDestination = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF",
						distanceToManeuver = 50.5,
						distanceToManeuverScale = 100.5,
						maneuverComplete = false 
                                            }
                            }  
		} 


for i=1,#TBTValues do
	Test["ShowConstantTBT_UpperBound_" .. tostring(TBTValues[i].languageName)] = function(self)
		ShowConstantTBT(self, TBTValues[i].value)
	end
end


-- APPLINK-16742: 08[P][XML]_TC_PutFile_UTF-8_UpperBound
--===================================================================================--
 -- Upper bound  of PutFile syncFileName  in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
 --===================================================================================--
for i=1,#PutFileUpperBound do
	Test["PutFile_" .. tostring(PutFileUpperBound[i].languageName)] = function(self)
		PutFile(self, PutFileUpperBound[i].value)
	end
end

-- APPLINK-16743: 09[P][XML]_TC_SetAppIcon_UTF-8_UpperBound
--===================================================================================--
 -- Upper bound  of SetAppIcon syncFileName  in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
 --===================================================================================--
for i=1,#PutFileUpperBound do
	Test["SetAppIcon_usingPutFile_" .. tostring(PutFileUpperBound[i].languageName)] = function(self)
		SetAppIcon(self, PutFileUpperBound[i].value)
	end
end

-- APPLINK-16745: 10[P][XML]_TC_SoftButtons_UTF-8_UpperBound
--===================================================================================--
-- Show request with SoftButtons with button upper bound names in different languages and with button images which names are upper bound in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
--===================================================================================--
function Test:ShowWithSoftButtonsTextAndImageNameIn_Korean_Japanese_Russian_Spanish_Arabic_French_German_UpperBound()

	local ShowValue = {	
		mainField1 = "SoftButtons names",
		softButtons = {
			-- Korean language
			{
				type = "BOTH",
				text = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
				image = {
					value = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아아이이.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 111,
				systemAction = "DEFAULT_ACTION"
			},
			-- Japanese language
			{
				type = "BOTH",
				text = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
				image = {
					value = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のの.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 112,
				systemAction = "DEFAULT_ACTION"
			},
			-- Russian language
			{
				type = "BOTH",
				text = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
				image = {
					value = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССММ.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 113,
				systemAction = "DEFAULT_ACTION"
			},
			-- Spanish language
			{
				type = "BOTH",
				text = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsoff",
				image = {
					value = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficiall.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 114,
				systemAction = "DEFAULT_ACTION"
			},
			-- Arabic language
			{
				type = "BOTH",
				text = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لةلة لة ل ة العرض حيةاجيةاججةا",
				image = {
					value = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ةة العرض حيةاجيةاجلحيةا.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 115,
				systemAction = "DEFAULT_ACTION"
			},
			-- French language
			{
				type = "BOTH",
				text = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
				image = {
					value = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇÇ.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 116,
				systemAction = "DEFAULT_ACTION"
			},
			-- German language
			{
				type = "BOTH",
				text = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄän",
				image = {
					value = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboo.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 117,
				systemAction = "DEFAULT_ACTION"
			}
		}
	}

	SoftButtons(self, ShowValue)
end


-- APPLINK-16749: 11[P][XML]_TC_Show_UTF-8_UpperBound
--===================================================================================--
-- Show request with upper bound of Show string parameters in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
--===================================================================================--
local ShowUpperBound = {
	{
		languageName = "ArabicUpperBound",
		value = 
		{
			mainField1 = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
			mainField2 = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
			mainField3 = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
			alignment = "RIGHT_ALIGNED",
			statusBar = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
			mediaClock = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
			mediaTrack = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج",
			customPresets = {"منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاج1", "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاج2", "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاج3"}
		}
	},
	{
		languageName = "FrenchUpperBound",
		value = 
		{
			mainField1 = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
			mainField2 = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
			mainField3 = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
			alignment = "RIGHT_ALIGNED",
			statusBar = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
			mediaClock = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
			mediaTrack = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï",
			customPresets = {"l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏï1", "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏï2", "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏï3"}
		}
	},
	{
		languageName = "GermanUpperBound",
		value = 
		{
			mainField1 = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
			mainField2 = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
			mainField3 = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
			alignment = "RIGHT_ALIGNED",
			statusBar = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
			mediaClock = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
			mediaTrack = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn",
			customPresets = {"SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄän1", "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄän2", "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄän3"}
		}
	},
	{
		languageName = "JapaneseUpperBound",
		value = 
		{
			mainField1 = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
			mainField2 = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
			mainField3 = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
			alignment = "RIGHT_ALIGNED",
			statusBar = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
			mediaClock = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
			mediaTrack = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの",
			customPresets = {"ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示の1", "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示の2", "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示の3"}
		}
	},
	{
		languageName = "KoreanUpperBound",
		value = 
		{
			mainField1 = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
			mainField2 = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
			mainField3 = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
			alignment = "RIGHT_ALIGNED",
			statusBar = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
			mediaClock = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
			mediaTrack = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호",
			customPresets = {"버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호1", "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호2", "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호3"}
		}
	},
	{
		languageName = "RussianUpperBound",
		value = 
		{
			mainField1 = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
			mainField2 = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
			mainField3 = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
			alignment = "RIGHT_ALIGNED",
			statusBar = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
			mediaClock = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
			mediaTrack = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ",
			customPresets = {"вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФ1", "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФ2", "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФ3"}
		}
	},
	{
		languageName = "SpanishUpperBound",
		value = 
		{
			mainField1 = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsoff",
			mainField2 = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsoff",
			mainField3 = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsoff",
			alignment = "RIGHT_ALIGNED",
			statusBar = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsoff",
			mediaClock = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsoff",
			mediaTrack = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsoff",
			customPresets = {"ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsof1", "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsof2", "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsof3"}
		}
	}
}
for i=1,#ShowUpperBound do
	Test["Show_" .. tostring(ShowUpperBound[i].languageName)] = function(self)
		Show(self, ShowUpperBound[i].value)
	end
end

-- APPLINK-16753: 13[P][XML]_TC_RegisterAppInterface_UTF-8_UpperBound
--===================================================================================--
-- Upper bound  of RAI appName in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
--===================================================================================--

for i=1, #appNameUpperBound do
	ReregistrationApplication(appNameUpperBound[i].languageName, appNameUpperBound[i].value)
end

----------------------------------------------------------------------------------------
-- unregistration registered application, register application again
ReregistrationApplication("ChangeRegistrationUpperBound", config.application1.registerAppInterfaceParams.appName)

----------------------------------------------------------------------------------------
-- Activate application
function Test:Precondition_ActivateApp_ChangeRegistrationUpperBound()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
end

--===================================================================================--
-- Upper bound  of ChangeRegistration parameters in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
--===================================================================================--
local ChangeRegistrationUpperBound = {
	{
		languageName = "ArabicUpperBound",
		value = {
			language = "AR-SA",
			hmiDisplayLanguage = "AR-SA",
			appName = "لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجج",
			ttsName = { {text = "منزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاجلحيةامنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجبلحيةاجمنةاجب لحيةاجبحيبحيةاجمنزمنزل نزل شرة لة لة ل ة العرض حيةاجيةاججةاجج", type = "TEXT"} },
			ngnMediaScreenAppName = "لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرة لة لة لة العرض حيةازمنزل نزل شرة لة لة لة العرض حيةاجبلحيةجج",
			vrSynonyms = {"لة لمنزمنزل نزل شرة لة لمنزمنزل نزل شرةل"}
		}
	},
	{
		languageName = "FrenchUpperBound",
		value = {
			language = "FR-FR",
			hmiDisplayLanguage = "FR-FR",
			appName = "l'icôneFrançaiseÂâÊêaisondel'arbrelcdelaforêtÎîÔlaforôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondell",
			ttsName = { {text = "l'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelÜüŸÿÇçl'ôneaiseÂâÊêaisondel'arbrelacdeladel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondel'arbrelacdelaforêtÎîÔôÛûÀàÈèÙËëÏïÜëÏïï", type = "TEXT"} },
			ngnMediaScreenAppName = "l'icôneFrançaiseÂâÊêaisondel'arbrelcdelaforêtÎîÔlaforôÛûÀàÈèÙËëÏïÜüŸÿÇçl'icôneFrançaiseÂâÊêaisondell",
			vrSynonyms = {"l'icôneFrançaiseÂâÊêaisondel'arbrelcdela"}
		}
	},
	{
		languageName = "GermanUpperBound",
		value = {
			language = "DE-DE",
			hmiDisplayLanguage = "DE-DE",
			appName = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄäsymboÜüÖöÄänsymlSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖÖ",
			ttsName = { {text = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymboSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolScÄänsymbolShaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächembolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄänsÄänn", type = "TEXT"} },
			ngnMediaScreenAppName = "SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖöÄäsymboÜüÖöÄänsymlSchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖÖ",
			vrSynonyms = {"SchaltflächeÜüÖöÄänsymbolSchaltflächeÜüÖ"}
		}
	},
	{
		languageName = "JapaneseUpperBound",
		value = {
			language = "JA-JP",
			hmiDisplayLanguage = "JA-JP",
			appName = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示のタンアイコン言語表示言語表示言語表家語表家示のの示示",
			ttsName = { {text = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表タンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言表示のの表示のの", type = "TEXT"} },
			ngnMediaScreenAppName = "ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表示言語表示言語表示のボタンボタンアイコン言語表示言語表示言語表家示のタンアイコン言語表示言語表示言語表家語表家示のの示示",
			vrSynonyms = {"ボタンアイコン言語表示言語表示言語表家示の木の家の森湖マウントボタンアイコン語表"}
		}
	},
	{
		languageName = "KoreanUpperBound",
		value = {
			language = "KO-KR",
			hmiDisplayLanguage = "KO-KR",
			appName = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운마운트운트버튼아이콘트리하우스의숲호수마언어표시트리하우스의숲호수수",
			ttsName = { {text = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아트버튼아이트버이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수마운트버튼아이트버튼아이버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우스의숲호수의숲호호", type = "TEXT"} },
			ngnMediaScreenAppName = "버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언어표시트리하우버튼아이콘언어표시트리하스의숲호수마운마운트운트버튼아이콘트리하우스의숲호수마언어표시트리하우스의숲호수수",
			vrSynonyms = {"버튼아이콘언어표시트리하스의버튼아이콘언어표시트리하스의숲호수마운트버튼아이콘언"}
		}
	},
	{
		languageName = "RussianUpperBound",
		value = {
			language = "RU-RU",
			hmiDisplayLanguage = "RU-RU",
			appName = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССС",
			ttsName = { {text = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССМвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФыВЫФФ", type = "TEXT"} },
			ngnMediaScreenAppName = "вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУКЕнгшщзхъждвапапкапЩОЗЩШОЩШОшщощЙЦУКЕнгшщзхъждлОРПАВЫВЫФЯЧССС",
			vrSynonyms = {"вапапкапЩОЗЩШвввввОвапапкапЩОЩШОшщощЙЦУК"}
		}
	},
	{
		languageName = "SpanishUpperBound",
		value = {
			language = "ES-MX",
			hmiDisplayLanguage = "ES-MX",
			appName = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficiaa",
			ttsName = { {text = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHaméricopañaHéréricopañaHioEspañEloibañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHmérioEspañEloibéricoEsoflsofF", type = "TEXT"} },
			ngnMediaScreenAppName = "ElidpañoibéricopañaHamérioEspañEloibéricoEsoficialElidpañoibéricopañaHamérioEspañEloibéricoEsoficiaa",
			vrSynonyms = {"ElidpañoibéricopañaHamérioEspañEloibéric"}
		}
	}
}

for i=1, #ChangeRegistrationUpperBound do
	Test[ "ChangeRegistration" .. tostring(ChangeRegistrationUpperBound[i].languageName) ] = function(self)
		ChangeRegistration(self, ChangeRegistrationUpperBound[i].value)
		for j=1, #ShowValues do
			if ChangeRegistrationUpperBound[i].languageName == ShowValues[j].languageName then
				Show(self, ShowValues[j].value)
			end
		end
	end
end

--===================================================================================--
-- Upper bound manualTextEntry to mobile application in different languages (Arabic, French, German, Japanese, Korean, Russian, Spanish)
--===================================================================================--

ReregistrationApplication("PerformInteractionUpperBound", config.application1.registerAppInterfaceParams.appName)

function Test:Precondition_ActivateApp_PerformInteractionUpperBound()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
end

function Test:Precondition_ChoiceSet_for_PIUpperBound()
CreateInteractionChoiceSet(self, 11111, "Precondition_PerformInteractionChoiceSetUpperBound")
end

for i=1,#AddCommandUpperBound do
	Test["PerformInteraction_" .. tostring(AddCommandUpperBound[i].languageName)] = function(self)
		local PIParams = {
			initialText = "StartPerformInteraction" .. tostring(AddCommandUpperBound[i].languageName),
			interactionMode = "MANUAL_ONLY",
			interactionChoiceSetIDList = {11111},
			timeout = 5000,
			interactionLayout = "KEYBOARD"
		}
		PerformInteraction(self, PIParams, AddCommandUpperBound[i].value)
	end
end

--===================================================================================--
-- Resumption. 
--===================================================================================--

---------------------------------------------------------------------------------------
--Preconditiion for resumption set

function Test:Precondition_SUSPEND_Resumption()
	SUSPEND(self)
end

function Test:Precondition_IGNITION_OFF_Resumption()
	IGNITION_OFF(self)
end

function Test:Precondition_remove_resumption_file_DB()
	local AddedFolderInScript = {"storage/IconsFolder", "AnotherFolder", "Icons"}

	local ExistDirectoryResult = Directory_exist( tostring(config.pathToSDL .. "storage"))
	if ExistDirectoryResult == true then
		local RmFolder  = assert( os.execute( "rm -rf " .. tostring(config.pathToSDL .. "storage" )))
		if RmFolder ~= true then
			userPrint(31, "Folder 'storage' is not deleted")
		end
	end

	local ExistFileResult = file_exists( tostring(config.pathToSDL .. "app_info.dat"))
	if ExistFileResult == true then
		local Rmfile  = assert( os.execute( "rm -f " .. tostring(config.pathToSDL .. "app_info.dat" )))
		if Rmfile ~= true then
			userPrint(31, "app_info.dat file is not deleted")
		end
	end

	DelayedExp(1000)
end

function Test:SetUseDBForResumptionFalse()
	SetUseDBForResumption("false")
end

---------------------------------------------------------------------------------------
--Start SDL and HMI
StartSDLHMI("Resumption")


--===================================================================================--
-- Resumption. Saving utf-8 strings to app_info.dat
--===================================================================================--

---------------------------------------------------------------------------------------
--Register application after ignition off
Test["RegisterApp_Resumption_saving_toFile_beforeIGNOFF"] = function(self)
	local RAIParameters = copy_table(config.application1.registerAppInterfaceParams)

	local RAIParamsToCheck = {
			application = {
				appName = RAIParameters.appName
			}

		}

	RegisterAppInterface(self, self.mobileSession, RAIParameters, RAIParamsToCheck)
end

---------------------------------------------------------------------------------------
--Activate application
function Test:Precondition_ActivateApp_Resumption_saving_toFile_beforeIGNOFF()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
end

---------------------------------------------------------------------------------------
-- AddCommand
---------------------------------------------------------------------------------------

for i=1,#AddCommandValues do
	Test["AddCommandResumption_" .. tostring(AddCommandValues[i].languageName)] = function(self)
		AddCommand(self, i, AddCommandValues[i].value, {AddCommandValues[i].value})
	end
end

---------------------------------------------------------------------------------------
-- AddSubMenu
---------------------------------------------------------------------------------------
 
for i=1,#AddCommandValues do
	Test["AddSubMenuResumption_" .. tostring(AddCommandValues[i].languageName)] = function(self)
		AddSubMenu(self, i, AddCommandValues[i].value)
	end
end

---------------------------------------------------------------------------------------
-- CreateInteractionChoiceSet
---------------------------------------------------------------------------------------
for i=1,#AddCommandValues do
	Test["CreateInteractionResumption_" .. tostring(AddCommandValues[i].languageName)] = function(self)
		CreateInteractionChoiceSet(self, i, AddCommandValues[i].value)
	end
end

---------------------------------------------------------------------------------------
-- Shutdown SDL
SwitchOffSDL("AddCommand_AddSubMenu_CreateInteractionChoiceSet")

---------------------------------------------------------------------------------------
-- Check saved data in *.dat file
function Test:CheckSavedDataInAppInfoDat_AddCommand_AddSubMenu_CreateInteractionChoiceSet()
	local resumptionAppData
	local resumptionDataTable

	local file = io.open(config.pathToSDL .."app_info.dat",r)

	local resumptionfile = file:read("*a")

	-- print(resumptionfile)

	resumptionDataTable = json.decode(resumptionfile)

	for p = 1, #resumptionDataTable.resumption.resume_app_list do
		if resumptionDataTable.resumption.resume_app_list[p].appID == config.application1.registerAppInterfaceParams.appID then
			resumptionAppData = resumptionDataTable.resumption.resume_app_list[p]
		end
	end

	local ErrorMessage = "" 
	local errorFlag = false

	if 
		not resumptionAppData.applicationChoiceSets or
		type(resumptionAppData.applicationChoiceSets) ~= "table" then
		errorFlag = true
		ErrorMessage = ErrorMessage .. "\n" .. "applicationChoiceSets is absent in app_info.dat"
	elseif
		#resumptionAppData.applicationChoiceSets ~= #AddCommandValues then
			errorFlag = true
			ErrorMessage = ErrorMessage .. "\n" .. "Wrong number of ChoiceSets saved in app_info.dat " .. tostring(#resumptionAppData.applicationChoiceSets) .. ", expected " .. tostring(#AddCommandValues)
	end

	if 
		not resumptionAppData.applicationCommands or
		type(resumptionAppData.applicationCommands) ~= "table" then
		errorFlag = true
		ErrorMessage = ErrorMessage .. "\n" .. "applicationCommands is absent in app_info.dat"
	elseif
		#resumptionAppData.applicationCommands ~= #AddCommandValues then
			errorFlag = true
			ErrorMessage = ErrorMessage .. "\n" .. "Wrong number of Commands saved in app_info.dat " .. tostring(#resumptionAppData.applicationCommands) .. ", expected " .. tostring(#AddCommandValues)
	end

	if 
		not resumptionAppData.applicationSubMenus or
		type(resumptionAppData.applicationSubMenus) ~= "table" then
		errorFlag = true
		ErrorMessage = ErrorMessage .. "\n" .. "applicationSubMenus is absent in app_info.dat"
	elseif
		resumptionAppData.applicationSubMenus and
		#resumptionAppData.applicationSubMenus ~= #AddCommandValues then
			errorFlag = true
			ErrorMessage = ErrorMessage .. "\n" .. "Wrong number of SubMenus saved in app_info.dat " .. tostring(#resumptionAppData.applicationSubMenus) .. ", expected " .. tostring(#AddCommandValues)
	end		

	for i=1, #resumptionAppData.applicationChoiceSets do
		if 
			resumptionAppData.applicationChoiceSets[i].choiceSet[1].menuName ~= AddCommandValues[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuName of ChoiceSets saved in app_info.dat " .. tostring(resumptionAppData.applicationChoiceSets[i].choiceSet[1].menuName) .. ", expected " .. tostring(AddCommandValues[i].value)
		end

		if
			resumptionAppData.applicationChoiceSets[i].choiceSet[1].vrCommands[1] ~= AddCommandValues[i].value  then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrCommand of ChoiceSets saved in app_info.dat " .. tostring(resumptionAppData.applicationChoiceSets[i].choiceSet[1].vrCommands[1]) .. ", expected " .. tostring(AddCommandValues[i].value)
		end
	end

	for i=1, #resumptionAppData.applicationCommands do

		if 
			resumptionAppData.applicationCommands[i].menuParams.menuName ~= AddCommandValues[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuName of command saved in app_info.dat " .. tostring(resumptionAppData.applicationCommands[i].menuParams.menuName) .. ", expected " .. tostring(AddCommandValues[i].value)
		end

		if
			resumptionAppData.applicationCommands[i].vrCommands[1] ~= AddCommandValues[i].value  then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrCommand of command saved in app_info.dat " .. tostring(resumptionAppData.applicationCommands[i].vrCommands[1]) .. ", expected " .. tostring(AddCommandValues[i].value)
		end
	end

	for i=1, #resumptionAppData.applicationSubMenus do
		if 
			resumptionAppData.applicationSubMenus[i].menuName ~= AddCommandValues[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuName of SubMenu saved in app_info.dat " .. tostring(resumptionAppData.applicationSubMenus[i].menuName) .. ", expected " .. tostring(AddCommandValues[i].value)
		end

	end

	if errorFlag == true then
		self:FailTestCase(ErrorMessage)
	end

end

---------------------------------------------------------------------------------------
-- Start SDL and HMI
StartSDLHMI("AddCommand_AddSubMenu_CreateInteractionChoiceSet")

---------------------------------------------------------------------------------------
-- Resume data from *.dat file after ignition off
function Test:Resumption_AddCommand_AddSubMenu_CreateInteractionChoiceSet()

	local RAIParams =  copy_table(config.application1.registerAppInterfaceParams)
	RAIParams.hashID = self.currentHashID

	local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", RAIParams)

	self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })

	local LanguageStringToCheckUIAddCommand = copy_table(AddCommandValues)

	-- hmi side: expect UI.AddCommand request
	EXPECT_HMICALL("UI.AddCommand")
		:Times(#AddCommandValues)
		:ValidIf(function(exp,data)
			local returnValue

			for i=1,#LanguageStringToCheckUIAddCommand do
				if data.params.menuParams.menuName == LanguageStringToCheckUIAddCommand[i].value then
					table.remove(LanguageStringToCheckUIAddCommand,i)
					return true
				elseif
					i >= #LanguageStringToCheckUIAddCommand and
					returnValue == false then
						userPrint(" UI.AddCommand came with unexpected value " .. tostring(data.params.menuParams.menuName))
						return false
				else
					returnValue = false
				end
			end
		end)

	local LanguageStringToCheckVRCommand = copy_table(AddCommandValues)

	-- hmi side: expect VR.AddCommand request
	EXPECT_HMICALL("VR.AddCommand")
		:Times(#AddCommandValues*2)
		:ValidIf(function(exp,data)
			local returnValue

			if exp.occurences == #AddCommandValues + 1 then
						LanguageStringToCheckVRCommand = copy_table(AddCommandValues)
					end

			for i=1,#LanguageStringToCheckVRCommand do

				if data.params.vrCommands[1] == LanguageStringToCheckVRCommand[i].value then
					table.remove(LanguageStringToCheckVRCommand,i)
					return true
				elseif
					i >= #LanguageStringToCheckVRCommand and
					returnValue == false then
						userPrint(" VR.AddCommand came with unexpected value " .. tostring(data.params.vrCommands[1]))
						return false
				else
					returnValue = false
				end
			end
		end)


	local LanguageStringToCheckUIAddSubMenu = copy_table(AddCommandValues)

	-- hmi side: expect UI.AddSubMenu request
	EXPECT_HMICALL("UI.AddSubMenu")
		:Times(#AddCommandValues)
		:ValidIf(function(exp,data)
			local returnValue

			for i=1,#LanguageStringToCheckUIAddSubMenu do
				if data.params.menuParams.menuName == LanguageStringToCheckUIAddSubMenu[i].value then
					table.remove(LanguageStringToCheckUIAddSubMenu,i)
					return true
				elseif
					i >= #LanguageStringToCheckUIAddSubMenu and
					returnValue == false then
						userPrint(" UI.AddSubMenu came with unexpected value " .. tostring(data.params.menuParams.menuName))
						return false
				else
					returnValue = false
				end
			end
		end)

	EXPECT_NOTIFICATION("OnHashChange", {})
		:Do(function(_,data)
			self.currentHashID = data.payload.hashID
		end)
end

---------------------------------------------------------------------------------------
-- Addcommand, addsubmenu, createinteractionchoiceset upper bound values
---------------------------------------------------------------------------------------

ReregistrationApplication("Resumption_AddCommand_AddSubMenu_CreateInteractionChoiceSet_UpperBound_saving_toFile_beforeIGNOFF", config.application1.registerAppInterfaceParams.appName)

function Test:Precondition_ActivateApp_Resumption_AddCommand_AddSubMenu_CreateInteractionChoiceSet_UpperBound_saving_toFile_beforeIGNOFF()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
end

---------------------------------------------------------------------------------------
-- AddCommand
---------------------------------------------------------------------------------------

for i=1,#AddCommandUpperBound do
	Test["AddCommandResumption" .. tostring(AddCommandUpperBound[i].languageName)] = function(self)
		AddCommand(self, i, AddCommandUpperBound[i].value, {AddCommandUpperBound[i].value})
	end
end

---------------------------------------------------------------------------------------
-- AddSubMenu
---------------------------------------------------------------------------------------
 
for i=1,#AddCommandUpperBound do
	Test["AddSubMenuResumption" .. tostring(AddCommandUpperBound[i].languageName)] = function(self)
		AddSubMenu(self, i, AddCommandUpperBound[i].value)
	end
end

---------------------------------------------------------------------------------------
-- CreateInteractionChoiceSet
---------------------------------------------------------------------------------------
for i=1,#AddCommandUpperBound do
	Test["CreateInteractionResumption" .. tostring(AddCommandUpperBound[i].languageName)] = function(self)
		CreateInteractionChoiceSet(self, i, AddCommandUpperBound[i].value)
	end
end

---------------------------------------------------------------------------------------
-- Shutdown SDL
SwitchOffSDL("AddCommand_AddSubMenu_CreateInteractionChoiceSet_UpperBound")

---------------------------------------------------------------------------------------
-- Check saved data in *.dat file
function Test:CheckSavedDataInAppInfoDat_AddCommand_AddSubMenu_CreateInteractionChoiceSet_UpperBound()
		local resumptionAppData
		local resumptionDataTable

		local file = io.open(config.pathToSDL .."app_info.dat",r)

		local resumptionfile = file:read("*a")

		-- print(resumptionfile)

		resumptionDataTable = json.decode(resumptionfile)

		for p = 1, #resumptionDataTable.resumption.resume_app_list do
			if resumptionDataTable.resumption.resume_app_list[p].appID == config.application1.registerAppInterfaceParams.appID then
				resumptionAppData = resumptionDataTable.resumption.resume_app_list[p]
			end
		end

		local ErrorMessage = "" 
		local errorFlag = false

		if 
			not resumptionAppData.applicationChoiceSets or
			type(resumptionAppData.applicationChoiceSets) ~= "table" then
			errorFlag = true
			ErrorMessage = ErrorMessage .. "\n" .. "applicationChoiceSets is absent in app_info.dat"
		elseif
			#resumptionAppData.applicationChoiceSets ~= #AddCommandUpperBound then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong number of ChoiceSets saved in app_info.dat " .. tostring(#resumptionAppData.applicationChoiceSets) .. ", expected " .. tostring(#AddCommandUpperBound)
		end

		if 
			not resumptionAppData.applicationCommands or
			type(resumptionAppData.applicationCommands) ~= "table" then
			errorFlag = true
			ErrorMessage = ErrorMessage .. "\n" .. "applicationCommands is absent in app_info.dat"
		elseif
			#resumptionAppData.applicationCommands ~= #AddCommandUpperBound then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong number of Commands saved in app_info.dat " .. tostring(#resumptionAppData.applicationCommands) .. ", expected " .. tostring(#AddCommandUpperBound)
		end

		if 
			not resumptionAppData.applicationSubMenus or
			type(resumptionAppData.applicationSubMenus) ~= "table" then
			errorFlag = true
			ErrorMessage = ErrorMessage .. "\n" .. "applicationSubMenus is absent in app_info.dat"
		elseif
			resumptionAppData.applicationSubMenus and
			#resumptionAppData.applicationSubMenus ~= #AddCommandUpperBound then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong number of SubMenus saved in app_info.dat " .. tostring(#resumptionAppData.applicationSubMenus) .. ", expected " .. tostring(#AddCommandUpperBound)
		end		

		for i=1, #resumptionAppData.applicationChoiceSets do
			if 
				resumptionAppData.applicationChoiceSets[i].choiceSet[1].menuName ~= AddCommandUpperBound[i].value then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuName of ChoiceSets saved in app_info.dat " .. tostring(resumptionAppData.applicationChoiceSets[i].choiceSet[1].menuName) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
			end

			if
				resumptionAppData.applicationChoiceSets[i].choiceSet[1].vrCommands[1] ~= AddCommandUpperBound[i].value  then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrCommand of ChoiceSets saved in app_info.dat " .. tostring(resumptionAppData.applicationChoiceSets[i].choiceSet[1].vrCommands[1]) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
			end
		end

		for i=1, #resumptionAppData.applicationCommands do

			if 
				resumptionAppData.applicationCommands[i].menuParams.menuName ~= AddCommandUpperBound[i].value then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuName of command saved in app_info.dat " .. tostring(resumptionAppData.applicationCommands[i].menuParams.menuName) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
			end

			if
				resumptionAppData.applicationCommands[i].vrCommands[1] ~= AddCommandUpperBound[i].value  then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrCommand of command saved in app_info.dat " .. tostring(resumptionAppData.applicationCommands[i].vrCommands[1]) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
			end
		end

		for i=1, #resumptionAppData.applicationSubMenus do
			if 
				resumptionAppData.applicationSubMenus[i].menuName ~= AddCommandUpperBound[i].value then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuName of SubMenu saved in app_info.dat " .. tostring(resumptionAppData.applicationSubMenus[i].menuName) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
			end

		end

		if errorFlag == true then
			self:FailTestCase(ErrorMessage)
		end

end

---------------------------------------------------------------------------------------
-- Start SDL and HMI
StartSDLHMI("AddCommand_AddSubMenu_CreateInteractionChoiceSet_UpperBound")

---------------------------------------------------------------------------------------
-- Resume data from *.dat file after ignition off
function Test:Resumption_AddCommand_AddSubMenu_CreateInteractionChoiceSet_UpperBound()

	local RAIParams =  copy_table(config.application1.registerAppInterfaceParams)
	RAIParams.hashID = self.currentHashID

	local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", RAIParams)

	self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })

	local LanguageStringToCheckUIAddCommand = copy_table(AddCommandUpperBound)

	-- hmi side: expect UI.AddCommand request
	EXPECT_HMICALL("UI.AddCommand")
		:Times(#AddCommandUpperBound)
		:ValidIf(function(exp,data)
			local returnValue

			for i=1,#LanguageStringToCheckUIAddCommand do
				if data.params.menuParams.menuName == LanguageStringToCheckUIAddCommand[i].value then
					table.remove(LanguageStringToCheckUIAddCommand,i)
					return true
				elseif
					i >= #LanguageStringToCheckUIAddCommand and
					returnValue == false then
						userPrint(" UI.AddCommand came with unexpected value " .. tostring(data.params.menuParams.menuName))
						return false
				else
					returnValue = false
				end
			end
		end)

	local LanguageStringToCheckVRCommand = copy_table(AddCommandUpperBound)

	-- hmi side: expect VR.AddCommand request
	EXPECT_HMICALL("VR.AddCommand")
		:Times(#AddCommandUpperBound*2)
		:ValidIf(function(exp,data)
			local returnValue

			if exp.occurences == #AddCommandUpperBound + 1 then
						LanguageStringToCheckVRCommand = copy_table(AddCommandUpperBound)
					end

			for i=1,#LanguageStringToCheckVRCommand do

				if data.params.vrCommands[1] == LanguageStringToCheckVRCommand[i].value then
					table.remove(LanguageStringToCheckVRCommand,i)
					return true
				elseif
					i >= #LanguageStringToCheckVRCommand and
					returnValue == false then
						userPrint(" VR.AddCommand came with unexpected value " .. tostring(data.params.vrCommands[1]))
						return false
				else
					returnValue = false
				end
			end
		end)


	local LanguageStringToCheckUIAddSubMenu = copy_table(AddCommandUpperBound)

	-- hmi side: expect UI.AddSubMenu request
	EXPECT_HMICALL("UI.AddSubMenu")
		:Times(#AddCommandUpperBound)
		:ValidIf(function(exp,data)
			local returnValue

			for i=1,#LanguageStringToCheckUIAddSubMenu do
				if data.params.menuParams.menuName == LanguageStringToCheckUIAddSubMenu[i].value then
					table.remove(LanguageStringToCheckUIAddSubMenu,i)
					return true
				elseif
					i >= #LanguageStringToCheckUIAddSubMenu and
					returnValue == false then
						userPrint(" UI.AddSubMenu came with unexpected value " .. tostring(data.params.menuParams.menuName))
						return false
				else
					returnValue = false
				end
			end
		end)

	EXPECT_NOTIFICATION("OnHashChange", {})
		:Do(function(_,data)
			self.currentHashID = data.payload.hashID
		end)
end

---------------------------------------------------------------------------------------
-- SetGlobalProperties
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
-- Unregister registered app, register application again
ReregistrationApplication("Resumption_SetGlobalProperties_saving_toFile_beforeIGNOFF", config.application1.registerAppInterfaceParams.appName)

---------------------------------------------------------------------------------------
-- Activate application
function Test:Precondition_ActivateApp_Resumption_SetGlobalProperties_saving_toFile_beforeIGNOFF()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
end


for i=1,#AddCommandValues do
	---------------------------------------------------------------------------------------
	-- Set global properties
	Test["SetGlobalPropertiesResumption_" .. tostring(AddCommandValues[i].languageName)] = function(self)
		SetGlobalProperties(self, AddCommandValues[i].value)
	end

	---------------------------------------------------------------------------------------
	-- Shutdown SDL
	SwitchOffSDL("SetGlobalProperties_" ..tostring(AddCommandValues[i].languageName) )

	---------------------------------------------------------------------------------------
	-- Check saved data in *.dat file
	Test["CheckSavedDataInAppInfoDat_SetGlobalProperties_" .. tostring(AddCommandValues[i].languageName)] = function (self)
		local resumptionAppData
		local resumptionDataTable

		local file = io.open(config.pathToSDL .."app_info.dat",r)

		local resumptionfile = file:read("*a")

		-- print(resumptionfile)

		resumptionDataTable = json.decode(resumptionfile)

		for p = 1, #resumptionDataTable.resumption.resume_app_list do
			if resumptionDataTable.resumption.resume_app_list[p].appID == config.application1.registerAppInterfaceParams.appID then
				resumptionAppData = resumptionDataTable.resumption.resume_app_list[p]
			end
		end

		if not resumptionAppData.globalProperties or 
			type(resumptionAppData.globalProperties) ~= "table" then
			self:FailTestCase(" globalProperties is absent in app_info.dat ")
		else

			local ErrorMessage = "" 
			local errorFlag = false

			if 
				not resumptionAppData.globalProperties.helpPrompt or
				type(resumptionAppData.globalProperties.helpPrompt) ~= "table" or
				not resumptionAppData.globalProperties.helpPrompt[1] then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "globalProperties.helpPrompt is absent in app_info.dat"
			elseif
				resumptionAppData.globalProperties.helpPrompt[1].text ~= AddCommandValues[i].value then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong helpPrompt of GlobalProperties saved in app_info.dat " .. tostring(resumptionAppData.globalProperties.helpPrompt[1].text) .. ", expected " .. tostring(AddCommandValues[i].value)
			end

			if 
				not resumptionAppData.globalProperties.timeoutPrompt or
				type(resumptionAppData.globalProperties.timeoutPrompt) ~= "table" or
				not resumptionAppData.globalProperties.helpPrompt[1] then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "globalProperties.timeoutPrompt is absent in app_info.dat"
			elseif
				resumptionAppData.globalProperties.timeoutPrompt[1].text ~= AddCommandValues[i].value then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong timeoutPrompt of GlobalProperties saved in app_info.dat " .. tostring(resumptionAppData.globalProperties.timeoutPrompt[1].text) .. ", expected " .. tostring(AddCommandValues[i].value)
			end

			if 
				not resumptionAppData.globalProperties.vrHelp or
				type(resumptionAppData.globalProperties.vrHelp) ~= "table" or
				not resumptionAppData.globalProperties.helpPrompt[1] then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "globalProperties.vrHelp is absent in app_info.dat "
			elseif
				resumptionAppData.globalProperties.vrHelp[1].text ~= AddCommandValues[i].value then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrHelp of GlobalProperties saved in app_info.dat " .. tostring(resumptionAppData.globalProperties.vrHelp[1].text) .. ", expected " .. tostring(AddCommandValues[i].value)
			end

			if 
				not resumptionAppData.globalProperties.menuTitle or
				type(resumptionAppData.globalProperties.menuTitle) ~= "string" then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "globalProperties.menuTitle is absent in app_info.dat "
			elseif
				resumptionAppData.globalProperties.menuTitle~= AddCommandValues[i].value then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuTitle of GlobalProperties saved in app_info.dat " .. tostring(resumptionAppData.globalProperties.menuTitle) .. ", expected " .. tostring(AddCommandValues[i].value)
			end

			if 
				not resumptionAppData.globalProperties.vrHelpTitle or
				type(resumptionAppData.globalProperties.vrHelpTitle) ~= "string" then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "globalProperties.vrHelpTitle is absent in app_info.dat "
			elseif
				resumptionAppData.globalProperties.vrHelpTitle~= AddCommandValues[i].value then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrHelpTitle of GlobalProperties saved in app_info.dat " .. tostring(resumptionAppData.globalProperties.vrHelpTitle) .. ", expected " .. tostring(AddCommandValues[i].value)
			end

			if errorFlag == true then
				self:FailTestCase(ErrorMessage)
			end

		end

	end

	---------------------------------------------------------------------------------------
	--Start SDL, HMI
	StartSDLHMI("SetGlobalProperties_" .. tostring(AddCommandValues[i].languageName) )

	---------------------------------------------------------------------------------------
	--Resume global properties after ignition off 
	Test[ "Resumption_SetGlobalProperties_".. tostring(AddCommandValues[i].languageName)] = function(self)

		local RAIParams =  copy_table(config.application1.registerAppInterfaceParams)
		RAIParams.hashID = self.currentHashID

		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", RAIParams)

		self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
			{},
			{
				timeoutPrompt = 
				{
					{
						text = AddCommandValues[i].value,
						type = "TEXT"
					}
				},
				helpPrompt = 
				{
					{
						text = AddCommandValues[i].value,
						type = "TEXT"
					}
				}
			})
			:Do(function(exp,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(2)


		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
			{
				menuTitle = AddCommandValues[i].value,
				vrHelp = 
				{
					{
						position = 1,
						text = AddCommandValues[i].value
					}
				},
				vrHelpTitle = AddCommandValues[i].value
			})
			:Do(function(_,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)

		EXPECT_NOTIFICATION("OnHashChange", {})
		:Do(function(_,data)
			self.currentHashID = data.payload.hashID
		end)
		
	end

end

---------------------------------------------------------------------------------------
-- SetGlobalProperties upper bound
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
--Unregister registered app, and register app again
ReregistrationApplication("Resumption_SetGlobalProperties_UpperBound_saving_toFile_beforeIGNOFF", config.application1.registerAppInterfaceParams.appName)

---------------------------------------------------------------------------------------
--Precondition: activate app
function Test:Precondition_ActivateApp_Resumption_SetGlobalProperties_UpperBound_saving_toFile_beforeIGNOFF()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
end


for i=1,#AddCommandUpperBound do
	---------------------------------------------------------------------------------------
	--Set global properties
	Test["SetGlobalPropertiesResumption_" .. tostring(AddCommandUpperBound[i].languageName)] = function(self)
		SetGlobalProperties(self, AddCommandUpperBound[i].value)
	end

	---------------------------------------------------------------------------------------
	-- Shutdown SDL
	SwitchOffSDL("SetGlobalProperties_" ..tostring(AddCommandUpperBound[i].languageName) )

	---------------------------------------------------------------------------------------
	-- Check saved data in *.dat file
	Test["CheckSavedDataInAppInfoDat_SetGlobalProperties_" .. tostring(AddCommandUpperBound[i].languageName)] = function (self)
		local resumptionAppData
		local resumptionDataTable

		local file = io.open(config.pathToSDL .."app_info.dat",r)

		local resumptionfile = file:read("*a")

		-- print(resumptionfile)

		resumptionDataTable = json.decode(resumptionfile)

		for p = 1, #resumptionDataTable.resumption.resume_app_list do
			if resumptionDataTable.resumption.resume_app_list[p].appID == config.application1.registerAppInterfaceParams.appID then
				resumptionAppData = resumptionDataTable.resumption.resume_app_list[p]
			end
		end

		if not resumptionAppData.globalProperties or 
			type(resumptionAppData.globalProperties) ~= "table" then
			self:FailTestCase(" globalProperties is absent in app_info.dat ")
		else

			local ErrorMessage = "" 
			local errorFlag = false

			if 
				not resumptionAppData.globalProperties.helpPrompt or
				type(resumptionAppData.globalProperties.helpPrompt) ~= "table" or
				not resumptionAppData.globalProperties.helpPrompt[1] then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "globalProperties.helpPrompt is absent in app_info.dat"
			elseif
				resumptionAppData.globalProperties.helpPrompt[1].text ~= AddCommandUpperBound[i].value then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong helpPrompt of GlobalProperties saved in app_info.dat " .. tostring(resumptionAppData.globalProperties.helpPrompt[1].text) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
			end

			if 
				not resumptionAppData.globalProperties.timeoutPrompt or
				type(resumptionAppData.globalProperties.timeoutPrompt) ~= "table" or
				not resumptionAppData.globalProperties.helpPrompt[1] then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "globalProperties.timeoutPrompt is absent in app_info.dat"
			elseif
				resumptionAppData.globalProperties.timeoutPrompt[1].text ~= AddCommandUpperBound[i].value then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong timeoutPrompt of GlobalProperties saved in app_info.dat " .. tostring(resumptionAppData.globalProperties.timeoutPrompt[1].text) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
			end

			if 
				not resumptionAppData.globalProperties.vrHelp or
				type(resumptionAppData.globalProperties.vrHelp) ~= "table" or
				not resumptionAppData.globalProperties.helpPrompt[1] then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "globalProperties.vrHelp is absent in app_info.dat "
			elseif
				resumptionAppData.globalProperties.vrHelp[1].text ~= AddCommandUpperBound[i].value then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrHelp of GlobalProperties saved in app_info.dat " .. tostring(resumptionAppData.globalProperties.vrHelp[1].text) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
			end

			if 
				not resumptionAppData.globalProperties.menuTitle or
				type(resumptionAppData.globalProperties.menuTitle) ~= "string" then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "globalProperties.menuTitle is absent in app_info.dat "
			elseif
				resumptionAppData.globalProperties.menuTitle~= AddCommandUpperBound[i].value then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuTitle of GlobalProperties saved in app_info.dat " .. tostring(resumptionAppData.globalProperties.menuTitle) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
			end

			if 
				not resumptionAppData.globalProperties.vrHelpTitle or
				type(resumptionAppData.globalProperties.vrHelpTitle) ~= "string" then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "globalProperties.vrHelpTitle is absent in app_info.dat "
			elseif
				resumptionAppData.globalProperties.vrHelpTitle~= AddCommandUpperBound[i].value then
					errorFlag = true
					ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrHelpTitle of GlobalProperties saved in app_info.dat " .. tostring(resumptionAppData.globalProperties.vrHelpTitle) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
			end

			if errorFlag == true then
				self:FailTestCase(ErrorMessage)
			end

		end

	end

	---------------------------------------------------------------------------------------
	-- Start HMI, SDL
	StartSDLHMI("SetGlobalProperties_" .. tostring(AddCommandUpperBound[i].languageName) )

	---------------------------------------------------------------------------------------
	-- Resume global properties
	Test[ "Resumption_SetGlobalProperties_".. tostring(AddCommandUpperBound[i].languageName)] = function(self)

		local RAIParams =  copy_table(config.application1.registerAppInterfaceParams)
		RAIParams.hashID = self.currentHashID

		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", RAIParams)

		self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
			{},
			{
				timeoutPrompt = 
				{
					{
						text = AddCommandUpperBound[i].value,
						type = "TEXT"
					}
				},
				helpPrompt = 
				{
					{
						text = AddCommandUpperBound[i].value,
						type = "TEXT"
					}
				}
			})
			:Do(function(exp,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(2)


		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
			{
				menuTitle = AddCommandUpperBound[i].value,
				vrHelp = 
				{
					{
						position = 1,
						text = AddCommandUpperBound[i].value
					}
				},
				vrHelpTitle = AddCommandUpperBound[i].value
			})
			:Do(function(_,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)

		EXPECT_NOTIFICATION("OnHashChange", {})
		:Do(function(_,data)
			self.currentHashID = data.payload.hashID
		end)
		
	end

end

--===================================================================================--
-- Resumption. Saving utf-8 strings to app_info.dat
--===================================================================================--
---------------------------------------------------------------------------------------
-- Shutdown SDL		 	
SwitchOffSDL("Resumption_saving_toDB_beforeIGNOFF")

---------------------------------------------------------------------------------------
-- Set value to true in SDL .ini for saving data in DB
function Test:SetUseDBForResumptionTrue()
	SetUseDBForResumption("true")
end

---------------------------------------------------------------------------------------
-- Start SDL, HMI
StartSDLHMI("Resumption_saving_toDB_beforeIGNOFF")

---------------------------------------------------------------------------------------
-- Register application 
Test["Resumption_saving_toDB_beforeIGNOFF"] = function(self)
	local RAIParameters = copy_table(config.application1.registerAppInterfaceParams)

	local RAIParamsToCheck = {
			application = {
				appName = RAIParameters.appName
			}

		}

	RegisterAppInterface(self, self.mobileSession, RAIParameters, RAIParamsToCheck)
end

---------------------------------------------------------------------------------------
-- Activate application
function Test:Precondition_ActivateApp_Resumption_saving_toDB_beforeIGNOFF()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
end

---------------------------------------------------------------------------------------
-- AddCommand
---------------------------------------------------------------------------------------

for i=1,#AddCommandValues do
	Test["AddCommandDBResumption_" .. tostring(AddCommandValues[i].languageName)] = function(self)
		AddCommand(self, i, AddCommandValues[i].value, {AddCommandValues[i].value})
	end
end

---------------------------------------------------------------------------------------
-- AddSubMenu
---------------------------------------------------------------------------------------
 
for i=1,#AddCommandValues do
	Test["AddSubMenuDBResumption_" .. tostring(AddCommandValues[i].languageName)] = function(self)
		AddSubMenu(self, i, AddCommandValues[i].value)
	end
end

---------------------------------------------------------------------------------------
-- CreateInteractionChoiceSet
---------------------------------------------------------------------------------------
for i=1,#AddCommandValues do
	Test["CreateInteractionDBResumption_" .. tostring(AddCommandValues[i].languageName)] = function(self)
		CreateInteractionChoiceSet(self, i, AddCommandValues[i].value)
	end
end

---------------------------------------------------------------------------------------
-- Shutdown SDL
SwitchOffSDL("DB_AddCommand_AddSubMenu_CreateInteractionChoiceSet")

---------------------------------------------------------------------------------------
-- Check saved data in DB
function Test:CheckSavedDataInDB_AddCommand_AddSubMenu_CreateInteractionChoiceSet()
	----------------------------------------------------------------
	--AddCommand
	local CommandmenuName = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT menuName FROM command\""

	local vrCommandmenuName = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT vrCommand FROM vrCommandsArray WHERE idchoice IS NULL\""

	local aHandleCommand = assert( io.popen( CommandmenuName , 'r'))
	local CommandMenuNamesArray = {}
	repeat  
		local value = aHandleCommand:read( '*l' ) 
		table.insert (CommandMenuNamesArray, value)
	until value == nil

	os.execute("sleep " .. tonumber(1))

	local aHandleVrCommand = assert( io.popen( vrCommandmenuName , 'r'))
	local vrCommandMenuNamesArray = {}
	repeat  
		local value = aHandleVrCommand:read( '*l' ) 
		table.insert (vrCommandMenuNamesArray, value)
	until value == nil

	os.execute("sleep " .. tonumber(1))

	----------------------------------------------------------------
	-- AddSubMenu

	local SubMenumenuName = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT menuName FROM subMenu\""

	local aHandleSubMenu = assert( io.popen( SubMenumenuName , 'r'))
	local SubMenuMenuNamesArray = {}
	repeat  
		local value = aHandleSubMenu:read( '*l' ) 
		table.insert (SubMenuMenuNamesArray, value)
	until value == nil

	os.execute("sleep " .. tonumber(1))

	----------------------------------------------------------------
	-- Choice

	local ChoiceSetName = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT menuName FROM choice\""
	local vrChoiceSetName = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT vrCommand FROM vrCommandsArray WHERE idcommand IS NULL \""

	local aHandleChoice = assert( io.popen( ChoiceSetName , 'r'))
	local ChoiceMenuNamesArray = {}
	repeat  
		local value = aHandleChoice:read( '*l' ) 
		table.insert (ChoiceMenuNamesArray, value)
	until value == nil

	os.execute("sleep " .. tonumber(1))

	local aHandleVrChoice = assert( io.popen( vrChoiceSetName , 'r'))
	local vrChoiceMenuNamesArray = {}
	repeat  
		local value = aHandleVrChoice:read( '*l' ) 
		table.insert (vrChoiceMenuNamesArray, value)
	until value == nil


	local ErrorMessage = "" 
	local errorFlag = false


	if 
		ChoiceMenuNamesArray and
		#ChoiceMenuNamesArray ~= #AddCommandValues then
			errorFlag = true
			ErrorMessage = ErrorMessage .. "\n" .. "Wrong number of ChoiceSets saved in resumption.sqlite " .. tostring(#ChoiceMenuNamesArray) .. ", expected " .. tostring(#AddCommandValues)
	end

	if
		CommandMenuNamesArray and
		#CommandMenuNamesArray ~= #AddCommandValues then
			errorFlag = true
			ErrorMessage = ErrorMessage .. "\n" .. "Wrong number of Commands saved in resumption.sqlite " .. tostring(#CommandMenuNamesArray) .. ", expected " .. tostring(#AddCommandValues)
	end

	if
		SubMenuMenuNamesArray and
		#SubMenuMenuNamesArray ~= #AddCommandValues then
			errorFlag = true
			ErrorMessage = ErrorMessage .. "\n" .. "Wrong number of SubMenus saved in resumption.sqlite " .. tostring(#SubMenuMenuNamesArray) .. ", expected " .. tostring(#AddCommandValues)
	end

	for i=1, #ChoiceMenuNamesArray do
		if 
			ChoiceMenuNamesArray[i] ~= AddCommandValues[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuName of ChoiceSets saved in resumption.sqlite " .. tostring(ChoiceMenuNamesArray[i]) .. ", expected " .. tostring(AddCommandValues[i].value)
		end
	end

	for i=1, #vrChoiceMenuNamesArray do
		if
			vrChoiceMenuNamesArray[i] ~= AddCommandValues[i].value   then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrCommand of choice saved in resumption.sqlite " .. tostring(vrChoiceMenuNamesArray[i]) .. ", expected " .. tostring(AddCommandValues[i].value)
		end
	end

	for i=1, #CommandMenuNamesArray do
		if 
			CommandMenuNamesArray[i] ~= AddCommandValues[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuName of command saved in resumption.sqlite " .. tostring(CommandMenuNamesArray[i]) .. ", expected " .. tostring(AddCommandValues[i].value)
		end
	end

	for i=1, #vrCommandMenuNamesArray do
		if
			vrCommandMenuNamesArray[i] ~= AddCommandValues[i].value  then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrCommand of command saved in resumption.sqlite " .. tostring(vrCommandMenuNamesArray[i]) .. ", expected " .. tostring(AddCommandValues[i].value)
		end
	end

	for i=1, #SubMenuMenuNamesArray do
		if 
			SubMenuMenuNamesArray[i] ~= AddCommandValues[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuName of SubMenu saved in resumption.sqlite " .. tostring(SubMenuMenuNamesArray[i]) .. ", expected " .. tostring(AddCommandValues[i].value)
		end

	end

	if errorFlag == true then
		self:FailTestCase(ErrorMessage)
	end

end


---------------------------------------------------------------------------------------
-- Start SDL, HMI
StartSDLHMI("DB_AddCommand_AddSubMenu_CreateInteractionChoiceSet")

---------------------------------------------------------------------------------------
-- Resume sved data in DB
function Test:DBResumption_AddCommand_AddSubMenu_CreateInteractionChoiceSet()

	local RAIParams =  copy_table(config.application1.registerAppInterfaceParams)
	RAIParams.hashID = self.currentHashID

	local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", RAIParams)

	self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })

	local LanguageStringToCheckUIAddCommand = copy_table(AddCommandValues)

	-- hmi side: expect UI.AddCommand request
	EXPECT_HMICALL("UI.AddCommand")
		:Times(#AddCommandValues)
		:ValidIf(function(exp,data)
			local returnValue

			for i=1,#LanguageStringToCheckUIAddCommand do
				if data.params.menuParams.menuName == LanguageStringToCheckUIAddCommand[i].value then
					table.remove(LanguageStringToCheckUIAddCommand,i)
					return true
				elseif
					i >= #LanguageStringToCheckUIAddCommand and
					returnValue == false then
						userPrint(" UI.AddCommand came with unexpected value " .. tostring(data.params.menuParams.menuName))
						return false
				else
					returnValue = false
				end
			end
		end)

	local LanguageStringToCheckVRCommand = copy_table(AddCommandValues)

	-- hmi side: expect VR.AddCommand request
	EXPECT_HMICALL("VR.AddCommand")
		:Times(#AddCommandValues*2)
		:ValidIf(function(exp,data)
			local returnValue

			if exp.occurences == #AddCommandValues + 1 then
						LanguageStringToCheckVRCommand = copy_table(AddCommandValues)
					end

			for i=1,#LanguageStringToCheckVRCommand do

				if data.params.vrCommands[1] == LanguageStringToCheckVRCommand[i].value then
					table.remove(LanguageStringToCheckVRCommand,i)
					return true
				elseif
					i >= #LanguageStringToCheckVRCommand and
					returnValue == false then
						userPrint(" VR.AddCommand came with unexpected value " .. tostring(data.params.vrCommands[1]))
						return false
				else
					returnValue = false
				end
			end
		end)


	local LanguageStringToCheckUIAddSubMenu = copy_table(AddCommandValues)

	-- hmi side: expect UI.AddSubMenu request
	EXPECT_HMICALL("UI.AddSubMenu")
		:Times(#AddCommandValues)
		:ValidIf(function(exp,data)
			local returnValue

			for i=1,#LanguageStringToCheckUIAddSubMenu do
				if data.params.menuParams.menuName == LanguageStringToCheckUIAddSubMenu[i].value then
					table.remove(LanguageStringToCheckUIAddSubMenu,i)
					return true
				elseif
					i >= #LanguageStringToCheckUIAddSubMenu and
					returnValue == false then
						userPrint(" UI.AddSubMenu came with unexpected value " .. tostring(data.params.menuParams.menuName))
						return false
				else
					returnValue = false
				end
			end
		end)

	EXPECT_NOTIFICATION("OnHashChange", {})
		:Do(function(_,data)
			self.currentHashID = data.payload.hashID
		end)
end

---------------------------------------------------------------------------------------
-- Unregister registered app, register app again 
ReregistrationApplication("DB_AddCommand_AddSubMenu_CreateInteractionChoiceSetUpperBound", config.application1.registerAppInterfaceParams.appName)

---------------------------------------------------------------------------------------
-- AddCommand upper bound
---------------------------------------------------------------------------------------

for i=1,#AddCommandUpperBound do
	Test["AddCommandDBResumption_" .. tostring(AddCommandUpperBound[i].languageName)] = function(self)
		AddCommand(self, i, AddCommandUpperBound[i].value, {AddCommandUpperBound[i].value})
	end
end

---------------------------------------------------------------------------------------
-- AddSubMenu upper bound
---------------------------------------------------------------------------------------
 
for i=1,#AddCommandUpperBound do
	Test["AddSubMenuDBResumption_" .. tostring(AddCommandUpperBound[i].languageName)] = function(self)
		AddSubMenu(self, i, AddCommandUpperBound[i].value)
	end
end

---------------------------------------------------------------------------------------
-- CreateInteractionChoiceSet upper bound
---------------------------------------------------------------------------------------
for i=1,#AddCommandUpperBound do
	Test["CreateInteractionDBResumption_" .. tostring(AddCommandUpperBound[i].languageName)] = function(self)
		CreateInteractionChoiceSet(self, i, AddCommandUpperBound[i].value)
	end
end

---------------------------------------------------------------------------------------
-- Shutdown SDL
SwitchOffSDL("DB_AddCommand_AddSubMenu_CreateInteractionChoiceSetUpperBound")

---------------------------------------------------------------------------------------
-- Check saved data in DB
function Test:CheckSavedDataInDB_AddCommand_AddSubMenu_CreateInteractionChoiceSetUpperBound()
	----------------------------------------------------------------
	--AddCommand
	local CommandmenuName = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT menuName FROM command\""

	local vrCommandmenuName = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT vrCommand FROM vrCommandsArray WHERE idchoice IS NULL\""

	local aHandleCommand = assert( io.popen( CommandmenuName , 'r'))
	local CommandMenuNamesArray = {}
	repeat  
		local value = aHandleCommand:read( '*l' ) 
		table.insert (CommandMenuNamesArray, value)
	until value == nil

	os.execute("sleep " .. tonumber(1))

	local aHandleVrCommand = assert( io.popen( vrCommandmenuName , 'r'))
	local vrCommandMenuNamesArray = {}
	repeat  
		local value = aHandleVrCommand:read( '*l' ) 
		table.insert (vrCommandMenuNamesArray, value)
	until value == nil

	os.execute("sleep " .. tonumber(1))

	----------------------------------------------------------------
	-- AddSubMenu

	local SubMenumenuName = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT menuName FROM subMenu\""

	local aHandleSubMenu = assert( io.popen( SubMenumenuName , 'r'))
	local SubMenuMenuNamesArray = {}
	repeat  
		local value = aHandleSubMenu:read( '*l' ) 
		table.insert (SubMenuMenuNamesArray, value)
	until value == nil

	os.execute("sleep " .. tonumber(1))

	----------------------------------------------------------------
	-- Choice

	local ChoiceSetName = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT menuName FROM choice\""
	local vrChoiceSetName = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT vrCommand FROM vrCommandsArray WHERE idcommand IS NULL \""

	local aHandleChoice = assert( io.popen( ChoiceSetName , 'r'))
	local ChoiceMenuNamesArray = {}
	repeat  
		local value = aHandleChoice:read( '*l' ) 
		table.insert (ChoiceMenuNamesArray, value)
	until value == nil

	os.execute("sleep " .. tonumber(1))

	local aHandleVrChoice = assert( io.popen( vrChoiceSetName , 'r'))
	local vrChoiceMenuNamesArray = {}
	repeat  
		local value = aHandleVrChoice:read( '*l' ) 
		table.insert (vrChoiceMenuNamesArray, value)
	until value == nilC

	local ErrorMessage = "" 
	local errorFlag = false


	if 
		ChoiceMenuNamesArray and
		#ChoiceMenuNamesArray ~= #AddCommandUpperBound then
			errorFlag = true
			ErrorMessage = ErrorMessage .. "\n" .. "Wrong number of ChoiceSets saved in resumption.sqlite " .. tostring(#ChoiceMenuNamesArray) .. ", expected " .. tostring(#AddCommandUpperBound)
	end
	if
		CommandMenuNamesArray and
		#CommandMenuNamesArray ~= #AddCommandUpperBound then
			errorFlag = true
			ErrorMessage = ErrorMessage .. "\n" .. "Wrong number of Commands saved in resumption.sqlite " .. tostring(#CommandMenuNamesArray) .. ", expected " .. tostring(#AddCommandUpperBound)
	end
	if
		SubMenuMenuNamesArray and
		#SubMenuMenuNamesArray ~= #AddCommandUpperBound then
			errorFlag = true
			ErrorMessage = ErrorMessage .. "\n" .. "Wrong number of SubMenus saved in resumption.sqlite " .. tostring(#SubMenuMenuNamesArray) .. ", expected " .. tostring(#AddCommandUpperBound)
	end

	for i=1, #ChoiceMenuNamesArray do
		if 
			ChoiceMenuNamesArray[i] ~= AddCommandUpperBound[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuName of ChoiceSets saved in resumption.sqlite " .. tostring(ChoiceMenuNamesArray[i]) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
		end
	end

	for i=1, #vrChoiceMenuNamesArray do
		if
			vrChoiceMenuNamesArray[i] ~= AddCommandUpperBound[i].value   then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrCommand of choice saved in resumption.sqlite " .. tostring(vrChoiceMenuNamesArray[i]) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
		end
	end

	for i=1, #CommandMenuNamesArray do
		if 
			CommandMenuNamesArray[i] ~= AddCommandUpperBound[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuName of command saved in resumption.sqlite " .. tostring(CommandMenuNamesArray[i]) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
		end
	end

	for i=1, #vrCommandMenuNamesArray do
		if
			vrCommandMenuNamesArray[i] ~= AddCommandUpperBound[i].value  then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrCommand of command saved in resumption.sqlite " .. tostring(vrCommandMenuNamesArray[i]) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
		end
	end

	for i=1, #SubMenuMenuNamesArray do
		if 
			SubMenuMenuNamesArray[i] ~= AddCommandUpperBound[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuName of SubMenu saved in resumption.sqlite " .. tostring(SubMenuMenuNamesArray[i]) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
		end

	end

	if errorFlag == true then
		self:FailTestCase(ErrorMessage)
	end

end


---------------------------------------------------------------------------------------
-- Start SDL, HMI
StartSDLHMI("DB_AddCommand_AddSubMenu_CreateInteractionChoiceSetUpperBound")

---------------------------------------------------------------------------------------
-- Resume sved data in DB
function Test:DBResumption_AddCommand_AddSubMenu_CreateInteractionChoiceSetUpperBound()

	local RAIParams =  copy_table(config.application1.registerAppInterfaceParams)
	RAIParams.hashID = self.currentHashID

	local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", RAIParams)

	self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })

	local LanguageStringToCheckUIAddCommand = copy_table(AddCommandUpperBound)

	-- hmi side: expect UI.AddCommand request
	EXPECT_HMICALL("UI.AddCommand")
		:Times(#AddCommandUpperBound)
		:ValidIf(function(exp,data)
			local returnValue

			for i=1,#LanguageStringToCheckUIAddCommand do
				if data.params.menuParams.menuName == LanguageStringToCheckUIAddCommand[i].value then
					table.remove(LanguageStringToCheckUIAddCommand,i)
					return true
				elseif
					i >= #LanguageStringToCheckUIAddCommand and
					returnValue == false then
						userPrint(" UI.AddCommand came with unexpected value " .. tostring(data.params.menuParams.menuName))
						return false
				else
					returnValue = false
				end
			end
		end)

	local LanguageStringToCheckVRCommand = copy_table(AddCommandUpperBound)

	-- hmi side: expect VR.AddCommand request
	EXPECT_HMICALL("VR.AddCommand")
		:Times(#AddCommandUpperBound*2)
		:ValidIf(function(exp,data)
			local returnValue

			if exp.occurences == #AddCommandUpperBound + 1 then
						LanguageStringToCheckVRCommand = copy_table(AddCommandUpperBound)
					end

			for i=1,#LanguageStringToCheckVRCommand do

				if data.params.vrCommands[1] == LanguageStringToCheckVRCommand[i].value then
					table.remove(LanguageStringToCheckVRCommand,i)
					return true
				elseif
					i >= #LanguageStringToCheckVRCommand and
					returnValue == false then
						userPrint(" VR.AddCommand came with unexpected value " .. tostring(data.params.vrCommands[1]))
						return false
				else
					returnValue = false
				end
			end
		end)


	local LanguageStringToCheckUIAddSubMenu = copy_table(AddCommandUpperBound)

	-- hmi side: expect UI.AddSubMenu request
	EXPECT_HMICALL("UI.AddSubMenu")
		:Times(#AddCommandUpperBound)
		:ValidIf(function(exp,data)
			local returnValue

			for i=1,#LanguageStringToCheckUIAddSubMenu do
				if data.params.menuParams.menuName == LanguageStringToCheckUIAddSubMenu[i].value then
					table.remove(LanguageStringToCheckUIAddSubMenu,i)
					return true
				elseif
					i >= #LanguageStringToCheckUIAddSubMenu and
					returnValue == false then
						userPrint(" UI.AddSubMenu came with unexpected value " .. tostring(data.params.menuParams.menuName))
						return false
				else
					returnValue = false
				end
			end
		end)

	EXPECT_NOTIFICATION("OnHashChange", {})
		:Do(function(_,data)
			self.currentHashID = data.payload.hashID
		end)
end


---------------------------------------------------------------------------------------
-- SetGlobalProperties
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
-- Unregister registered app, register app again 
ReregistrationApplication("Resumption_SetGlobalProperties_saving_toDB_beforeIGNOFF", config.application1.registerAppInterfaceParams.appName)

---------------------------------------------------------------------------------------
-- Activate application
function Test:Precondition_ActivateApp_Resumption_SetGlobalProperties_saving_toDB_beforeIGNOFF()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
end

for i=1,#AddCommandValues do

	---------------------------------------------------------------------------------------
	-- Set global properties
	Test["SetGlobalPropertiesDBResumption_" .. tostring(AddCommandValues[i].languageName)] = function(self)
		SetGlobalProperties(self, AddCommandValues[i].value)
	end

	---------------------------------------------------------------------------------------
	-- Shutdown SDL
	SwitchOffSDL("DBSetGlobalProperties_" ..tostring(AddCommandValues[i].languageName) )

	---------------------------------------------------------------------------------------
	-- Check saved data in DB
	Test["CheckSavedDataInDBt_SetGlobalProperties_" .. tostring(AddCommandValues[i].languageName)] = function (self)

		----------------------------------------------------------------
		-- menuTitle
		local menuTitle = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT menuTitle FROM globalProperties\""

		local aHandlemenuTitle = assert( io.popen( menuTitle , 'r'))
		local menuTitleValue = aHandlemenuTitle:read( '*l' ) 

		os.execute("sleep " .. tonumber(1))

		----------------------------------------------------------------
		-- vrHelpTitle
		local vrHelpTitle = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT vrHelpTitle FROM globalProperties\""

		local aHandlevrHelpTitle = assert( io.popen( vrHelpTitle , 'r'))
		local vrHelpTitleValue = aHandlevrHelpTitle:read( '*l' ) 

		os.execute("sleep " .. tonumber(1))

		----------------------------------------------------------------
		-- vrHelp
		local vrHelp = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT text FROM vrHelpItem WHERE idvrHelpItem = 1\""

		local aHandlevrHelp = assert( io.popen( vrHelp, 'r'))
		local vrHelpValue = aHandlevrHelp:read( '*l' ) 

		os.execute("sleep " .. tonumber(1))

		----------------------------------------------------------------
		-- helpPrompt, timeoutPrompt

		local helpPromptItem = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT idhelpPrompt FROM helpTimeoutPromptArray WHERE idhelpTimeoutPromptArray = 1\""
		local aHandlehelpPrompt = assert( io.popen( helpPromptItem , 'r'))
		local helpPromptItemValue =  aHandlehelpPrompt:read( '*l' )

		os.execute("sleep " .. tonumber(1))

		local timeoutPromptItem = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT idtimeoutPrompt FROM helpTimeoutPromptArray WHERE idhelpTimeoutPromptArray = 1\""
		local aHandletimeoutPrompt = assert( io.popen( timeoutPromptItem , 'r'))
		local timeoutPromptItemValue =  aHandletimeoutPrompt:read( '*l' )

		os.execute("sleep " .. tonumber(1))

		local PromptItems = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT text FROM TTSChunk \""
		local aHandlePrompts = assert( io.popen( PromptItems , 'r'))

		local helpPromptValue
		local timeoutPromptValue
		if tonumber(helpPromptItemValue) == 1 then
			helpPromptValue = aHandlePrompts:read('*l')
			timeoutPromptValue = aHandlePrompts:read('*l')
		else
			timeoutPromptValue = aHandlePrompts:read( '*l' )
			helpPromptValue = aHandlePrompts:read( '*l' )
		end

		local ErrorMessage = "" 
		local errorFlag = false


		if 
			helpPromptValue ~= AddCommandValues[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong helpPrompt of GlobalProperties saved in resumption.sqlite " .. tostring(helpPromptValue) .. ", expected " .. tostring(AddCommandValues[i].value)
		end

		if
			timeoutPromptValue ~= AddCommandValues[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong timeoutPrompt of GlobalProperties saved in resumption.sqlite " .. tostring(timeoutPromptValue) .. ", expected " .. tostring(AddCommandValues[i].value)
		end

		if
			menuTitleValue ~= AddCommandValues[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuTitle of GlobalProperties saved in resumption.sqlite " .. tostring(menuTitleValue) .. ", expected " .. tostring(AddCommandValues[i].value)
		end

		if
			vrHelpTitleValue ~= AddCommandValues[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrHelpTitle of GlobalProperties saved in resumption.sqlite " .. tostring(vrHelpTitleValue) .. ", expected " .. tostring(AddCommandValues[i].value)
		end

		if
			vrHelpValue ~= AddCommandValues[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrHelp of GlobalProperties saved in resumption.sqlite " .. tostring(vrHelpValue) .. ", expected " .. tostring(AddCommandValues[i].value)
		end

		if errorFlag == true then
			self:FailTestCase(ErrorMessage)
		end

	end

	---------------------------------------------------------------------------------------
	-- Start SDL, HMI
	StartSDLHMI("DBSetGlobalProperties_" .. tostring(AddCommandValues[i].languageName) )

	---------------------------------------------------------------------------------------
	-- Resumption saved in db data
	Test[ "DBResumption_SetGlobalProperties_".. tostring(AddCommandValues[i].languageName)] = function(self)

		local RAIParams =  copy_table(config.application1.registerAppInterfaceParams)
		RAIParams.hashID = self.currentHashID

		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", RAIParams)

		self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
			{},
			{
				timeoutPrompt = 
				{
					{
						text = AddCommandValues[i].value,
						type = "TEXT"
					}
				},
				helpPrompt = 
				{
					{
						text = AddCommandValues[i].value,
						type = "TEXT"
					}
				}
			})
			:Do(function(exp,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(2)


		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
			{
				menuTitle = AddCommandValues[i].value,
				vrHelp = 
				{
					{
						position = 1,
						text = AddCommandValues[i].value
					}
				},
				vrHelpTitle = AddCommandValues[i].value
			})
			:Do(function(_,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)

		EXPECT_NOTIFICATION("OnHashChange", {})
		:Do(function(_,data)
			self.currentHashID = data.payload.hashID
		end)
		
	end

end

---------------------------------------------------------------------------------------
-- SetGlobalProperties UpperBound
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
-- Unregister registered app, register app again 
ReregistrationApplication("Resumption_SetGlobalPropertiesUpperBound_saving_toDB_beforeIGNOFF", config.application1.registerAppInterfaceParams.appName)

---------------------------------------------------------------------------------------
-- Activate application
function Test:Precondition_ActivateApp_Resumption_SetGlobalPropertiesUpperBound_saving_toDB_beforeIGNOFF()
	ActivationApp(self, self.applications[config.application1.registerAppInterfaceParams.appName])

	EXPECT_NOTIFICATION("OnHMIStatus",
				{hmiLevel = "FULL", audioStreamingState = audibleState, systemContext = "MAIN"})
end

for i=1,#AddCommandUpperBound do

	---------------------------------------------------------------------------------------
	-- Set global properties
	Test["SetGlobalPropertiesUpperBoundDBResumption_" .. tostring(AddCommandUpperBound[i].languageName)] = function(self)
		SetGlobalProperties(self, AddCommandUpperBound[i].value)
	end

	---------------------------------------------------------------------------------------
	-- Shutdown SDL
	SwitchOffSDL("DBSetGlobalPropertiesUpperBound_" ..tostring(AddCommandUpperBound[i].languageName) )

	---------------------------------------------------------------------------------------
	-- Check saved data in DB
	Test["CheckSavedDataInDBt_SetGlobalPropertiesUpperBound_" .. tostring(AddCommandUpperBound[i].languageName)] = function (self)

		----------------------------------------------------------------
		-- menuTitle
		local menuTitle = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT menuTitle FROM globalProperties\""

		local aHandlemenuTitle = assert( io.popen( menuTitle , 'r'))
		local menuTitleValue = aHandlemenuTitle:read( '*l' ) 

		os.execute("sleep " .. tonumber(1))

		----------------------------------------------------------------
		-- vrHelpTitle
		local vrHelpTitle = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT vrHelpTitle FROM globalProperties\""

		local aHandlevrHelpTitle = assert( io.popen( vrHelpTitle , 'r'))
		local vrHelpTitleValue = aHandlevrHelpTitle:read( '*l' ) 

		os.execute("sleep " .. tonumber(1))

		----------------------------------------------------------------
		-- vrHelp
		local vrHelp = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT text FROM vrHelpItem WHERE idvrHelpItem = 1\""

		local aHandlevrHelp = assert( io.popen( vrHelp, 'r'))
		local vrHelpValue = aHandlevrHelp:read( '*l' ) 

		os.execute("sleep " .. tonumber(1))

		----------------------------------------------------------------
		-- helpPrompt, timeoutPrompt

		local helpPromptItem = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT idhelpPrompt FROM helpTimeoutPromptArray WHERE idhelpTimeoutPromptArray = 1\""
		local aHandlehelpPrompt = assert( io.popen( helpPromptItem , 'r'))
		local helpPromptItemValue =  aHandlehelpPrompt:read( '*l' )

		os.execute("sleep " .. tonumber(1))

		local timeoutPromptItem = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT idtimeoutPrompt FROM helpTimeoutPromptArray WHERE idhelpTimeoutPromptArray = 1\""
		local aHandletimeoutPrompt = assert( io.popen( timeoutPromptItem , 'r'))
		local timeoutPromptItemValue =  aHandletimeoutPrompt:read( '*l' )

		os.execute("sleep " .. tonumber(1))

		local PromptItems = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/resumption.sqlite \"SELECT text FROM TTSChunk \""
		local aHandlePrompts = assert( io.popen( PromptItems , 'r'))

		local helpPromptValue
		local timeoutPromptValue
		if tonumber(helpPromptItemValue) == 1 then
			helpPromptValue = aHandlePrompts:read('*l')
			timeoutPromptValue = aHandlePrompts:read('*l')
		else
			timeoutPromptValue = aHandlePrompts:read( '*l' )
			helpPromptValue = aHandlePrompts:read( '*l' )
		end

		local ErrorMessage = "" 
		local errorFlag = false

		if 
			helpPromptValue ~= AddCommandUpperBound[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong helpPrompt of GlobalProperties saved in resumption.sqlite " .. tostring(helpPromptValue) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
		end

		if
			timeoutPromptValue ~= AddCommandUpperBound[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong timeoutPrompt of GlobalProperties saved in resumption.sqlite " .. tostring(timeoutPromptValue) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
		end

		if
			menuTitleValue ~= AddCommandUpperBound[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong menuTitle of GlobalProperties saved in resumption.sqlite " .. tostring(menuTitleValue) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
		end

		if
			vrHelpTitleValue ~= AddCommandUpperBound[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrHelpTitle of GlobalProperties saved in resumption.sqlite " .. tostring(vrHelpTitleValue) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
		end

		if
			vrHelpValue ~= AddCommandUpperBound[i].value then
				errorFlag = true
				ErrorMessage = ErrorMessage .. "\n" .. "Wrong vrHelp of GlobalProperties saved in resumption.sqlite " .. tostring(vrHelpValue) .. ", expected " .. tostring(AddCommandUpperBound[i].value)
		end

		if errorFlag == true then
			self:FailTestCase(ErrorMessage)
		end

	end

	---------------------------------------------------------------------------------------
	-- Start SDL, HMI
	StartSDLHMI("DBSetGlobalPropertiesUpperBound_" .. tostring(AddCommandUpperBound[i].languageName) )

	---------------------------------------------------------------------------------------
	-- Resumption saved in db data
	Test[ "DBResumption_SetGlobalPropertiesUpperBound_".. tostring(AddCommandUpperBound[i].languageName)] = function(self)

		local RAIParams =  copy_table(config.application1.registerAppInterfaceParams)
		RAIParams.hashID = self.currentHashID

		local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", RAIParams)

		self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
			{},
			{
				timeoutPrompt = 
				{
					{
						text = AddCommandUpperBound[i].value,
						type = "TEXT"
					}
				},
				helpPrompt = 
				{
					{
						text = AddCommandUpperBound[i].value,
						type = "TEXT"
					}
				}
			})
			:Do(function(exp,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Times(2)


		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
			{
				menuTitle = AddCommandUpperBound[i].value,
				vrHelp = 
				{
					{
						position = 1,
						text = AddCommandUpperBound[i].value
					}
				},
				vrHelpTitle = AddCommandUpperBound[i].value
			})
			:Do(function(_,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)

		EXPECT_NOTIFICATION("OnHashChange", {})
		:Do(function(_,data)
			self.currentHashID = data.payload.hashID
		end)
		
	end

end
