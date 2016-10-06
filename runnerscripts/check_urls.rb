# cut -f1 checkurls.txt | uniq | tr '\n' ','
#cat xaa | cut -f3 | sort -u | awk '{print "<img src=\"" $1 "\">"}' > ./checkurls.html

$ok_types = ['image/gif', 'image/jpeg', 'image/jpg', 'image/png', 'image/x-icon', 'image/svg+xml', 'font/woff', 'image/vnd.microsoft.icon', 'application/x-font-ttf', 'image/bmp', 'application/octet-stream', 'application/vnd.ms-fontobject', 'font/x-woff', 'application/x-woff', 'application/x-font-woff', 'image/x-ms-bmp', 'jpg', 'gif', 'png', 'image/pjpeg', 'image/webp', 'application/font-woff', 'font/otf', 'font/truetype', 'font/ttf', 'image/x-ico', 'image/x-png', 'text/xml']
$ignore_content_type_extensions = ['.cur', '.ico', '.ttf']
$ignore_content_type_types = ['text/plain']
$known_bad_urls = {}
$known_good_urls = []

def fetch(uri_str, limit = 5, head = false)
	limit = 5 if limit.nil?
	raise ArgumentError, 'too many HTTP redirects' if limit == 0

	uri = URI(uri_str.strip.gsub(' ', '%20').gsub('|', '%7C').gsub('[', '%5B').gsub(']', '%5D'))
	if head
		req = Net::HTTP::Head.new(uri.request_uri)
	else
		req = Net::HTTP::Get.new(uri.request_uri)
	end

	req['User-Agent'] = 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0'

	Timeout::timeout(20) {
		con = Net::HTTP.new(uri.host, uri.port)
		if uri.scheme == 'https'
			con.verify_mode = OpenSSL::SSL::VERIFY_NONE
			con.use_ssl = true
		end

		res = con.start {|http|
			http.request(req)
		}

		if res.kind_of?(Net::HTTPRedirection)
			# handle relative redirects
			redirect = URI.join(uri.to_s, res['location'])
			return fetch(redirect.to_s, limit - 1) 
		end

		return res
	}
end

def print_error(style_id, image_uri, err)
	puts "#{style_id}\t#{err}\t#{image_uri}"
end

def validate(url)
	begin
		# Start with a HEAD
		vr = validate_response(url, fetch(url, nil, true))
		# If the response isn't good, do a GET
		vr = validate_response(url, fetch(url, nil, false)) if !vr.nil?
		return vr
	# Won't retry on any network error
	rescue Errno::ETIMEDOUT
		return 'TIMEOUT'
	rescue Timeout::Error
		return 'TIMEOUT2'
	rescue EOFError
		return 'EOFError'
	rescue ArgumentError
		return 'Too many redirects'
	rescue Errno::ECONNREFUSED
		return 'Connection refused'
	rescue StandardError => e  
		return 'Unhandled exception - ' + e.message
	end
end

def validate_response(url, res)
	return 'HTTP ' + res.code if res.code != '200'
	return 'No Content-Type' if res['Content-Type'].nil?
	type = res['Content-Type'].split(';')[0]
	return 'No Content-Type' if type.nil?
	if !$ok_types.include?(type.downcase)
		if $ignore_content_type_types.include?(type)
			$ignore_content_type_extensions.each do |ext|
				return nil if url.end_with?(ext)
			end
		end
		return type
	end
	return nil
end

def validate_urls(style_refs, mod_this, mod_total)
	style_refs.each do |style_id, refs|
		next unless style_id % mod_total == mod_this
		refs.each do |url|
			next unless url.start_with?('http:') or url.start_with?('https:')
			if $known_bad_urls.include?(url)
				print_error(style_id, url, $known_bad_urls[url])
				next
			end
			next if $known_good_urls.include?(url)
			error = validate(url)
			if error.nil?
				$known_good_urls << url
			else
				$known_bad_urls[url] = error
				print_error(style_id, url, error)
			end
		end
	end
end

#puts "calculating refs"
style_refs = {}
Style.active.where("id in (308,480,788,871,1021,1145,1359,1369,1666,1770,2001,2130,2249,2256,2278,2330,2346,2426,2482,2625,2637,2666,2842,2911,2919,2949,3053,3242,3261,3324,3326,3413,3466,3487,3510,3549,3582,3583,3588,3605,3857,3917,3980,3990,3991,4012,4089,4250,4312,4374,4438,4456,4553,4612,4644,4774,4892,4926,5126,5167,5191,5260,5267,5497,5502,5503,5504,5508,5520,5525,5547,5563,5592,5610,5612,5619,5630,5648,5682,5776,5777,6061,6164,6369,6565,6746,6747,6748,6749,6758,6768,6778,6779,6808,6847,6965,7132,7283,7367,7377,7520,7553,7696,7735,7795,7797,7800,7863,7895,8162,8182,8265,8292,8367,8373,8432,8549,8623,8707,8708,8774,8793,8796,8797,8919,8922,9012,9013,9022,9065,9108,9109,9126,9131,9135,9137,9143,9144,9145,9172,9256,9280,9290,9402,9479,9533,9654,9667,9701,9747,9750,9769,9791,9823,9920,9978,10022,10048,10078,10085,10097,10144,10150,10247,10316,10333,10336,10343,10371,10376,10389,10414,10446,10487,10693,10701,10722,10739,10836,10870,10874,10901,10903,10917,11076,11088,11237,11317,11321,11343,11406,11439,11478,11507,11564,11567,11568,11574,11575,11602,11689,11714,11722,11752,11755,11802,11807,11816,11817,11818,11919,12003,12043,12048,12193,12198,12201,12260,12280,12319,12322,12384,12553,12819,12928,12929,12956,13040,13088,13161,13267,13330,13343,13357,13368,13376,13428,13429,13495,13534,13558,13586,13587,13596,13652,13711,13807,13880,13897,13955,13991,14183,14190,14200,14215,14364,14373,14390,14392,14393,14398,14487,14603,14623,14784,14794,14914,14954,15028,15073,15142,15215,15279,15316,15332,15518,15530,15571,15585,15613,15695,15733,15809,15821,15838,15908,15915,15929,15930,16005,16065,16071,16159,16163,16245,16246,16297,16355,16431,16458,16552,16580,16602,16618,16655,16660,16669,16698,16712,16745,16779,16828,16888,16909,16915,16972,17035,17041,17042,17043,17048,17085,17097,17099,17100,17105,17155,17227,17249,17421,17469,17471,17473,17486,17504,17570,17594,17625,17642,17695,17784,17830,17988,18116,18130,18146,18167,18216,18310,18319,18336,18376,18386,18414,18427,18478,18480,18520,18529,18533,18551,18582,18610,18650,18732,18804,18813,18955,18975,18980,18984,19002,19003,19041,19064,19070,19071,19127,19143,19284,19305,19307,19345,19395,19462,19609,19656,19712,19739,19794,19806,19856,19868,19881,19905,19918,19925,19926,19927,19948,19950,20018,20026,20030,20053,20119,20138,20201,20204,20243,20244,20354,20389,20464,20465,20514,20522,20588,20595,20599,20637,20760,20769,20770,20841,20860,20862,20903,21022,21040,21042,21087,21191,21202,21282,21290,21294,21296,21333,21402,21450,21547,21548,21580,21584,21602,21651,21726,21741,21742,21743,21744,21745,21746,21748,21749,21828,21881,21924,21960,21962,22061,22155,22161,22206,22207,22220,22294,22305,22370,22371,22392,22454,22466,22497,22526,22543,22565,22574,22606,22607,22741,22748,22773,22789,22822,22881,22882,22931,22952,22953,22998,23012,23024,23052,23068,23082,23100,23136,23139,23188,23192,23209,23226,23235,23243,23275,23276,23282,23290,23292,23298,23301,23344,23346,23387,23483,23492,23508,23509,23510,23514,23544,23550,23586,23589,23590,23592,23593,23594,23613,23617,23624,23634,23635,23636,23640,23641,23644,23645,23646,23647,23648,23649,23659,23660,23661,23669,23670,23674,23678,23683,23685,23687,23688,23689,23694,23695,23696,23697,23698,23699,23700,23701,23703,23721,23722,23724,23725,23726,23750,23751,23758,23759,23821,23827,23839,23847,23851,23906,23914,23928,23932,23936,23937,23946,23955,23957,23964,23981,23989,24004,24017,24040,24045,24082,24127,24139,24247,24277,24316,24369,24434,24530,24550,24593,24594,24616,24709,24729,24745,24747,24748,24749,24750,24751,24752,24754,24755,24756,24757,24758,24759,24761,24762,24763,24764,24777,24796,24798,24799,24800,24801,24802,24806,24820,24840,24863,24912,24941,24944,24947,24959,24989,25011,25013,25113,25155,25163,25166,25173,25174,25175,25186,25206,25212,25232,25237,25245,25282,25338,25435,25442,25446,25449,25519,25550,25633,25705,25711,25712,25739,25822,25823,25825,25869,25872,25878,25886,25909,25920,25921,25924,25926,25984,25994,26004,26021,26025,26026,26027,26028,26031,26041,26051,26066,26067,26101,26124,26128,26133,26134,26135,26157,26210,26268,26288,26306,26307,26356,26372,26415,26417,26455,26535,26575,26599,26601,26603,26604,26625,26635,26668,26687,26702,26709,26710,26711,26748,26756,26783,26785,26786,26787,26802,26835,26856,26857,26870,26871,26878,26906,26921,26923,26970,26974,26980,26985,27041,27042,27048,27053,27064,27068,27070,27071,27081,27097,27104,27138,27140,27141,27153,27247,27291,27292,27294,27295,27308,27319,27391,27397,27400,27436,27460,27470,27744,27745,27747,27899,27930,28051,28234,28235,28238,28245,28347,28352,28353,28354,28355,28378,28386,28504,28551,28630,28632,28635,28638,28639,28640,28641,28642,28697,28752,28774,28793,28854,28856,28872,28959,29033,29035,29042,29057,29062,29078,29079,29149,29151,29186,29223,29297,29396,29398,29438,29441,29443,29481,29482,29483,29489,29965,30085,30113,30114,30115,30246,30271,30273,30426,30676,30743,30989,31011,31111,31172,31183,31197,31198,31245,31246,31253,31287,31295,31297,31319,31329,31346,31353,31384,31387,31409,31444,31445,31457,31522,31541,31598,31656,31670,31720,31745,31746,31750,31778,31836,31837,31854,31868,31870,31872,31873,31875,31876,31916,31982,32002,32016,32080,32086,32090,32091,32092,32096,32098,32099,32100,32101,32103,32104,32105,32106,32109,32112,32113,32114,32119,32122,32127,32132,32135,32136,32144,32148,32156,32161,32164,32170,32176,32187,32188,32243,32244,32271,32279,32282,32290,32333,32370,32496,32511,32528,32536,32562,32594,32598,32606,32638,32643,32682,32685,32740,32741,32744,32745,32766,32769,32783,32790,32792,32799,32801,32804,32824,32832,32836,32851,32853,32864,32868,32873,32880,32882,32887,32901,32904,32911,32912,32922,32929,32944,32958,32960,32985,33001,33008,33012,33013,33015,33031,33044,33046,33047,33048,33053,33057,33058,33060,33067,33071,33072,33089,33102,33103,33113,33120,33126,33139,33147,33158,33159,33160,33193,33194,33195,33201,33213,33221,33222,33223,33227,33228,33258,33260,33263,33283,33284,33285,33286,33305,33347,33357,33425,33475,33478,33479,33480,33486,33499,33500,33503,33507,33508,33518,33576,33577,33578,33582,33595,33599,33636,33645,33742,33774,33779,33839,33877,33938,33939,33940,33943,33958,33959,33960,33961,33962,34045,34046,34134,34135,34137,34138,34141,34142,34144,34153,34159,34164,34167,34170,34175,34176,34178,34179,34181,34188,34193,34194,34195,34198,34199,34210,34216,34219,34221,34223,34225,34226,34231,34235,34237,34243,34247,34252,34253,34261,34264,34268,34271,34273,34286,34292,34293,34300,34311,34312,34314,34316,34322,34325,34326,34328,34329,34333,34335,34337,34344,34350,34356,34359,34362,34363,34365,34369,34372,34375,34379,34383,34385,34386,34392,34393,34395,34400,34407,34416,34419,34425,34430,34433,34443,34444,34447,34449,34457,34465,34471,34473,34475,34477,34479,34481,34483,34494,34495,34497,34500,34501,34502,34504,34509,34510,34530,34545,34547,34548,34552,34557,34560,34561,34565,34567,34577,34580,34582,34592,34596,34600,34605,34606,34607,34611,34613,34614,34615,34618,34620,34626,34627,34629,34633,34636,34644,34648,34655,34656,34657,34659,34663,34667,34675,34676,34679,34683,34684,34690,34691,34694,34696,34700,34702,34703,34708,34710,34711,34716,34723,34730,34734,34735,34737,34740,34744,34766,34768,34769,34770,34778,34779,34780,34782,34785,34787,34790,34793,34794,34795,34796,34798,34799,34800,34805,34808,34813,34814,34815,34817,34819,34822,34824,34827,34835,34839,34844,34850,34853,34860,34863,34864,34865,34870,34871,34873,34874,34875,34876,34877,34878,34883,34886,34887,34958,34967,34998,35005,35006,35007,35064,35133,35164,35188,35227,35233,35300,35345,35360,35442,35470,35473,35489,35514,35533,35590,35593,35595,35596,35603,35604,35616,35645,35722,35725,35755,35756,35758,35760,35762,35770,35777,35785,35809,35811,35822,35840,35891,35935,35937,35961,35978,35980,36024,36043,36058,36083,36151,36165,36172,36185,36205,36208,36209,36223,36224,36225,36226,36230,36231,36234,36244,36256,36257,36263,36264,36265,36267,36269,36275,36291,36419,36447,36467,36496,36497,36498,36567,36614,36618,36712,36716,36721,36744,36754,36776,36782,36790,36791,36799,36808,36811,36822,36837,36840,36852,36867,36868,36915,36941,36951,36976,36985,36994,37025,37031,37038,37042,37052,37073,37077,37092,37120,37152,37158,37183,37185,37186,37210,37215,37221,37240,37244,37292,37295,37394,37395,37398,37399,37403,37404,37405,37423,37425,37426,37430,37431,37432,37437,37447,37455,37467,37471,37474,37486,37511,37542,37543,37545,37546,37550,37564,37604,37605,37611,37648,37661,37663,37666,37673,37678,37696,37697,37705,37751,37780,37785,37841,37842,37868,37872,37873,37910,37912,37919,37920,37921,37922,37963,37966,37970,37971,37992,38049,38051,38053,38074,38160,38166,38189,38200,38233,38248,38279,38294,38296,38299,38313,38327,38366,38367,38394,38401,38415,38416,38426,38434,38491,38511,38564,38567,38588,38631,38650,38674,38696,38697,38740,38766,38777,38805,38858,38872,38878,38884,38893,38908,38939,38957,38962,39106,39140,39200,39211,39293,39338,39404,39472,39520,39550,39588,39591,39627,39631,39863,39942,39946,40011,40065,40082,40147,40205,40246,40280,40282,40283,40442,40457,40591,40609,40613,40655,40672,40682,40728,40737,40943,40958,40965,40980,41023,41030,41125,41142,41167,41381,41401,41454,41508,41632,41767,41848,41906,42056,42141,42218,42292,42326,42331,42356,42358,42469,42481,42485,42544,42562,42571,42578,42652,42672,42742,42745,42767,42882,42900,42933,42934,42957,42994,42999,43064,43091,43108,43119,43125,43132,43209,43257,43345,43369,43398,43450,43459,43602,43603,43631,43634,43788,43794,43812,43847,44045,44209,44236,44243,44281,44332,44370,44379,44391,44398,44418,44458,44499,44545,44554,44585,44588,44590,44598,44612,44614,44662,44664,44676,44689,44692,44712,44719,44734,44763,44764,44766,44784,44786,44788,44823,44841,44860,44880,44897,44902,44905,44910,44911,44944,44949,44951,44978,45058,45062,45064,45067,45088,45091,45095,45106,45116,45125,45176,45181,45273,45317,45368,45370,45385,45386,45396,45429,45434,45463,45509,45533,45537,45573,45638,45648,45660,45667,45673,45686,45737,45762,45788,45805,45826,45827,45894,45895,45930,45958,45962,45967,45969,45970,45971,45972,45976,45993,45995,45996,46002,46042,46093,46105,46122,46129,46130,46195,46207,46210,46257,46328,46347,46406,46435,46442,46478,46479,46508,46552,46560,46605,46606,46673,46683,46709,46876,46897,46905,46907,46922,46928,46931,46980,47000,47029,47047,47059,47060,47072,47086,47113,47118,47135,47138,47152,47203,47204,47206,47214,47236,47239,47246,47251,47291,47315,47387,47425,47441,47448,47468,47537,47553,47580,47599,47673,47784,47793,47798,47814,47867,47885,47895,47928,47938,47939,47970,48007,48024,48026,48028,48097,48136,48159,48183,48206,48226,48291,48292,48310,48315,48359,48361,48364,48368,48396,48448,48457,48484,48527,48587,48812,48816,48817,48900,48913,48978,49028,49030,49086,49123,49125,49127,49185,49212,49228,49241,49245,49246,49278,49302,49303,49304,49305,49306,49307,49319,49329,49354,49357,49390,49399,49405,49446,49515,49548,49580,49582,49611,49634,49635,49638,49654,49713,49718,49721,49727,49731,49827,49848,49852,49890,49902,49911,49924,50089,50117,50119,50141,50192,50353,50409,50413,50419,50455,50460,50494,50507,50517,50596,50631,50650,50653,50654,50656,50658,50666,50669,50686,50690,50691,50692,50693,50711,50713,50715,50716,50721,50772,50776,50777,50778,50779,50780,50781,50782,50783,50784,50785,50786,50787,50791,50792,50799,50825,50834,50837,50838,50839,50868,50898,50899,50927,50928,50929,50952,50953,51001,51004,51012,51022,51037,51058,51070,51071,51072,51091,51107,51128,51129,51130,51131,51136,51139,51169,51176,51223,51250,51263,51363,51423,51459,51471,51485,51498,51532,51604,51606,51621,51652,51672,51678,51686,51687,51689,51696,51741,51755,51789,51790,51791,51792,51793,51794,51902,52121,52127,52128,52130,52133,52146,52210,52219,52229,52261,52360,52388,52404,52420,52554,52592,52602,52695,52696,52697,52699,52702,52705,52713,52778,52800,52805,52849,52865,52872,52873,52875,52937,52980,53039,53059,53060,53061,53083,53114,53129,53147,53151,53187,53207,53208,53209,53210,53245,53249,53253,53269,53308,53325,53333,53340,53406,53450,53490,53519,53546,53585,53586,53589,53595,53677,53678,53703,53746,53818,53898,53906,53989,54263,54332,54373,54452,54485,54582,54634,54635,54647,54682,54723,54746,54748,54756,54768,54770,54771,54772,54792,54795,54796,54797,54815,54820,54842,54847,54860,54862,54863,54866,54876,54928,54936,55006,55011,55012,55014,55018,55019,55020,55025,55033,55057,55061,55078,55153,55194,55213,55228,55285,55286,55287,55289,55293,55296,55311,55313,55391,55419,55425,55463,55466,55475,55499,55510,55514,55516,55526,55535,55663,55727,55739,55766,55767,55769,55772,55781,55786,55806,55823,55827,55837,55846,55847,55848,55849,55852,55872,55896,55897,55914,55916,55923,55932,55934,55938,55939,55943,55951,55955,55996,55999,56014,56071,56080,56093,56102,56117,56155,56157,56162,56163,56168,56169,56172,56177,56183,56247,56251,56327,56334,56366,56370,56383,56384,56386,56388,56389,56440,56445,56450,56472,56483,56505,56515,56535,56545,56615,56616,56622,56684,56687,56693,56737,56769,56792,57018,57035,57040,57041,57043,57045,57047,57049,57057,57072,57081,57099,57108,57112,57113,57114,57121,57135,57137,57151,57152,57153,57154,57155,57156,57157,57158,57166,57170,57171,57172,57174,57197,57216,57270,57272,57273,57278,57301,57302,57306,57317,57340,57367,57464,57527,57535,57537,57548,57614,57687,57717,57726,57732,57747,57774,57781,57788,57805,57823,57862,57900,57920,57930,57934,57959,58012,58014,58024,58045,58047,58071,58073,58075,58077,58095,58096,58097,58098,58115,58125,58126,58160,58187,58189,58210,58245,58302,58307,58335,58360,58410,58490,58503,58539,58644,58645,58646,58653,58707,58762,58807,58814,58851,58859,58871,58875,58896,58899,58913,58917,58964,59014,59027,59062,59063,59077,59092,59130,59137,59142,59145,59156,59162,59203,59213,59228,59270,59276,59285,59301,59302,59354,59383,59453,59566,59567,59577,59598,59623,59625,59632,59649,59660,59698,59705,59706,59757,59776,59780,59781,59787,59846,59873,59874,59915,59936,59976,59982,60034,60074,60079,60081,60130,60142,60151,60207,60280,60310,60318,60331,60363,60395,60493,60504,60525,60530,60591,60593,60616,60617,60652,60671,60773,60782,60794,60796,60866,60878,60883,61018,61025,61035,61100,61155,61187,61194,61195,61205,61222,61227,61238,61249,61266,61268,61279,61290,61291,61314,61319,61337,61344,61348,61365,61366,61375,61396,61415,61457,61459,61471,61482,61488,61524,61527,61557,61564,61603,61604,61628,61641,61649,61684,61695,61697,61735,61789,61790,61806,61809,61814,61822,61834,61860,61890,61904,61909,61933,61951,61952,61953,61958,61984,62063,62107,62110,62111,62112,62116,62118,62122,62136,62142,62195,62201,62230,62250,62272,62288,62292,62321,62329,62338,62353,62432,62455,62523,62543,62577,62600,62668,62680,62699,62765,62798,62810,62820,62868,62922,63018,63047,63101,63107,63121,63126,63140,63200,63212,63245,63247,63278,63400,63401,63525,63530,63533,63536,63623,63654,63658,63659,63660,63661,63678,63748,63759,63801,63817,63870,63878,63887,63910,63912,63927,63930,63957,63959,63991,64001,64004,64006,64028,64038,64049,64052,64053,64054,64055,64080,64093,64094,64215,64224,64232,64238,64239,64260,64263,64265,64286,64287,64291,64300,64312,64316,64320,64395,64399,64400,64402,64403,64408,64417,64419,64423,64428,64430,64431,64432,64444,64449,64454,64461,64473,64497,64533,64565,64566,64620,64641,64674,64680,64681,64709,64723,64745,64753,64856,64884,64886,64898,64925,64941,64948,64950,64951,65005,65037,65059,65119,65156,65212,65222,65237,65250,65275,65288,65299,65336,65350,65359,65362,65368,65404,65405,65406,65409,65412,65414,65415,65426,65435,65441,65443,65447,65461,65476,65477,65478,65479,65481,65483,65484,65499,65501,65509,65532,65566,65569,65580,65585,65596,65597,65635,65651,65713,65716,65717,65719,65721,65722,65754,65755,65756,65779,65796,65801,65818,65842,65859,65860,65866,65867,65877,65879,65898,65899,65915,65916,65950,65998,66020,66023,66045,66048,66050,66124,66166,66202,66203,66214,66220,66258,66290,66291,66309,66321,66361,66367,66368,66369,66384,66397,66405,66416,66417,66419,66424,66433,66439,66447,66451,66452,66454,66458,66462,66463,66469,66591,66628,66631,66634,66646,66672,66683,66696,66703,66707,66758,66770,66832,66839,66890,66895,66902,66908,66909,66913,66945,66958,66982,66983,66987,66989,66994,67012,67020,67023,67044,67045,67047,67059,67068,67090,67104,67134,67159,67169,67173,67182,67211,67213,67214,67217,67219,67231,67277,67278,67282,67290,67292,67300,67372,67441,67452,67464,67474,67543,67586,67587,67589,67594,67615,67616,67618,67620,67639,67675,67778,67806,67810,67811,67816,67883,67917,67918,67930,67960,67961,67963,67964,67966,67967,67968,67972,67973,68014,68048,68082,68084,68087,68090,68091,68098,68100,68108,68136,68160,68163,68164,68169,68215,68230,68261,68265,68281,68300,68309,68310,68371,68421,68455,68457,68484,68485,68523,68529,68534,68587,68598,68599,68608,68610,68617,68618,68620,68621,68628,68632,68647,68674,68698,68717,68743,68784,68820,68825,68866,68885,68887,68925,68940,68950,68959,68971,68989,68995,69002,69009,69013,69032,69047,69074,69078,69079,69100,69133,69142,69158,69159,69195,69197,69198,69199,69200,69201,69202,69204,69205,69206,69207,69211,69212,69213,69262,69289,69295,69298,69353,69354,69361,69363,69364,69410,69433,69452,69471,69472,69474,69476,69479,69501,69519,69545,69548,69549,69552,69682,69684,69705,69767,69788,69803,69824,69845,69868,69875,69878,69879,69882,69883,69885,69886,69887,69924,69926,69935,69939,69941,69948,69955,69976,69985,69986,69987,70018,70024,70044,70047,70143,70182,70185,70186,70187,70188,70194,70196,70197,70201,70203,70204,70206,70208,70219,70229,70230,70266,70270,70286,70289,70301,70324,70331,70343,70356,70377,70438,70439,70510,70511,70527,70549,70550,70554,70561,70570,70575,70600,70601,70606,70614,70631,70634,70650,70662,70702,70704,70706,70707,70713,70778,70780,70796,70800,70801,70827,70832,70836,70878,70880,70898,70917,70980,70986,70988,71007,71015,71076,71079,71083,71091,71092,71093,71094,71153,71161,71166,71168,71172,71179,71186,71199,71216,71222,71223,71232,71268,71282,71294,71323,71330,71335,71362,71365,71366,71400,71402,71403,71404,71405,71437,71447,71451,71459,71460,71483,71496,71514,71532,71538,71546,71595,71618,71662,71725,71731,71737,71763,71788,71802,71849,71867,71940,71941,71954,71992,72023,72033,72036,72041,72042,72044,72096,72099,72100,72125,72263,72281,72291,72299,72306,72310,72317,72375,72378,72384,72398,72399,72406,72412,72416,72429,72502,72550,72572,72608,72637,72646,72650,72670,72672,72675,72681,72710,72712,72731,72808,73003,73093,73373,73398,73404,73406,73434,73457,73466,73470,73482,73497,73503,73538,73593,73661,73696,73831,73972,74017,74019,74034,74072,74100,74101,74110,74117,74140,74155,74191,74194,74199,74235,74239,74305,74369,74371,74378,74385,74387,74388,74389,74390,74391,74392,74393,74394,74395,74396,74397,74399,74402,74431,74455,74469,74505,74533,74540,74569,74638,74670,74679,74691,74699,74700,74709,74711,74715,74722,74825,74842,74852,74867,74878,74882,74897,74930,74931,74942,74952,74954,74964,74968,74983,75096,75103,75106,75112,75147,75148,75149,75150,75158,75162,75173,75199,75211,75216,75217,75218,75304,75305,75327,75331,75343,75379,75410,75429,75441,75459,75466,75469,75480,75482,75486,75492,75543,75558,75572,75577,75586,75633,75644,75648,75651,75670,75671,75692,75707,75769,75779,75875,75877,75892,75969,76005,76050,76058,76097,76132,76149,76161,76186,76189,76192,76194,76252,76254,76288,76305,76308,76316,76325,76326,76327,76349,76352,76357,76370,76372,76373,76379,76387,76405,76406,76409,76410,76411,76463,76466,76506,76514,76524,76559,76562,76583,76595,76632,76639,76683,76684,76697,76765,76787,76790,76791,76802,76820,76842,76843,76854,76865,76876,76885,76887,76899,76918,76929,76936,76967,76984,76987,77028,77030,77036,77045,77048,77049,77069,77072,77074,77079,77091,77114,77119,77124,77134,77136,77158,77161,77185,77187,77209,77211,77212,77217,77305,77361,77363,77375,77398,77404,77452,77484,77491,77502,77513,77520,77527,77539,77563,77569,77596,77602,77636,77657,77683,77741,77748,77806,77814,77815,77867,77871,77876,77912,77925,77964,77974,78045,78052,78055,78082,78092,78094,78102,78105,78115,78126,78133,78155,78167,78173,78174,78176,78179,78206,78226,78233,78363,78395,78403,78423,78435,78439,78440,78454,78455,78461,78464,78558,78559,78560,78571,78640,78643,78646,78651,78652,78653,78705,78715,78719,78751,78752,78774,78790,78815,78836,78851,78937,78968,79047,79053,79054,79074,79104,79106,79139,79173,79203,79219,79225,79236,79241,79245,79246,79259,79264,79265,79271,79273,79288,79300,79309,79325,79326,79333,79334,79339,79346,79349,79356,79358,79360,79370,79381,79382,79383,79384,79385,79389,79396,79409,79413,79414,79427,79436,79443,79449,79457,79459,79462,79468,79481,79506,79507,79508,79539,79540,79547,79550,79566,79569,79579,79588,79593,79612,79618,79624,79628,79629,79635,79642,79675,79676,79682,79687,79694,79695,79703,79706,79753,79759,79764,79768,79771,79781,79786,79787,79789,79791,79809,79815,79817,79818,79820,79835,79840,79856,79857,79860,79872,79877,79883,79892,79918,79920,79923,79934,79935,79937,79945,79948,79970,79973,79974,79978,80028,80103,80125,80147,80148,80150,80156,80169,80175,80176,80177,80203,80211,80221,80222,80223,80224,80228,80246,80247,80253,80258,80262,80277,80283,80285,80319,80321,80346,80354,80356,80357,80359,80360,80361,80362,80364,80398,80415,80416,80420,80424,80430,80438,80451,80466,80470,80490,80491,80493,80503,80506,80507,80510,80533,80535,80536,80538,80551,80556,80592,80594,80599,80604,80606,80618,80640,80644,80653,80661,80663,80664,80665,80671,80672,80674,80679,80680,80691,80692,80693,80695,80711,80713,80722,80739,80740,80741,80742,80746,80747,80748,80754,80756,80758,80768,80779,80784,80790,80801,80802,80803,80811,80812,80814,80815,80822,80861,80868,80870,80872,80878,80885,80889,80912,80913,80914,80943,80945,80946,80951,80954,80958,80972,80975,81001,81012,81014,81018,81019,81022,81043,81044,81046,81067,81079,81081,81082,81094,81098,81109,81116,81117,81147,81150,81153,81157,81159,81160,81161,81162,81163,81166,81169,81177,81180,81195,81197,81201,81206,81208,81212,81214,81218,81235,81236,81251,81252,81259,81262,81282,81292,81297,81304,81317,81318,81329,81350,81364,81370,81387,81393,81395,81398,81402,81404,81407,81408,81409,81428,81437,81438,81440,81448,81449,81457,81463,81493,81502,81504,81506,81507,81508,81510,81513,81540,81566,81575,81590,81592,81593,81604,81609,81622,81660,81670,81679,81713,81714,81722,81726,81727,81729,81736,81766,81774,81777,81782,81783,81796,81815,81816,81817,81822,81823,81825,81827,81828,81843,81844,81852,81856,81866,81867,81871,81872,81875,81893,81898,81901,81902,81904,81905,81915,81917,81922,81925,81927,81952,81964,81969,81973,82008,82013,82016,82046,82047,82053,82055,82057,82058,82059,82073,82077,82097,82112,82115,82128,82144,82171,82175,82176,82181,82186,82188,82191,82193,82199,82201,82210,82213,82218,82240,82243,82244,82253,82257,82259,82278,82280,82283,82288,82291,82296,82303,82314,82316,82319,82320,82348,82349,82354,82357,82371,82405,82411,82448,82450,82456,82461,82479,82480,82483,82512,82516,82551,82560,82569,82591,82613,82614,82615,82616,82630,82633,82637,82641,82647,82658,82675,82690,82704,82707,82723,82727,82736,82737,82747,82748,82749,82755,82757,82766,82784,82856,82867,82881,82895,82897,82899,82901,82904,82907,82911,82912,82934,82940,82942,82952,82955,82958,82975,82992,82994,83000,83007,83020,83030,83038,83042,83048,83067,83084,83091,83098,83104,83117,83120,83133,83140,83144,83155,83166,83174,83175,83180,83181,83183,83185,83186,83187,83220,83230,83232,83270,83276,83283,83297,83303,83311,83317,83332,83335,83336,83337,83340,83342,83347,83355,83365,83369,83372,83374,83378,83379,83383,83419,83426,83450,83453,83459,83471,83484,83489,83504,83508,83516,83530,83534,83538,83539,83547,83551,83554,83556,83562,83573,83575,83576,83579,83580,83591,83592,83596,83616,83625,83631,83632,83653,83659,83662,83664,83665,83669,83682,83684,83686,83688,83690,83698,83701,83712,83715,83739,83742,83744,83745,83746,83747,83748,83749,83756,83758,83794,83796,83797,83798,83802,83805,83806,83819,83823,83828,83831,83832,83833,83848,83909,83925,83926,83927,83928,83929,83930,83935,83936,83937,83938,83940,83941,83942,83943,83963,83965,83968,83978,83979,84025,84033,84093,84103,84107,84139,84158,84159,84160,84163,84164,84182,84184,84191,84201,84207,84208,84213,84227,84244,84263,84268,84284,84292,84304,84347,84348,84359,84395,84419,84422,84433,84434,84445,84450,84451,84483,84486,84504,84505,84528,84582,84590,84610,84625,84632,84654,84687,84756,84757,84780,84802,84809,84838,84843,84852,84912,84916,84927,84928,84929,84930,84952,84953,84963,84964,84968,84971,84990,85009,85010,85035,85039,85048,85077,85094,85099,85120,85128,85135,85146,85149,85220,85224,85234,85254,85255,85268,85270,85281,85312,85314,85324,85330,85340,85383,85391,85437,85460,85461,85462,85467,85476,85477,85489,85493,85495,85507,85536,85538,85585,85588,85596,85637,85671,85676,85696,85708,85718,85719,85720,85755,85758,85762,85769,85789,85794,85813,85821,85826,85841,85845,85855,85856,85857,85863,85865,85893,85898,85913,85928,85929,85959,85967,85974,85996,85999,86035,86081,86124,86127,86131,86147,86149,86154,86157,86162,86169,86173,86187,86196,86197,86199,86221,86235,86258,86260,86301,86322,86329,86332,86351,86366,86400,86405,86418,86423,86430,86437,86440,86464,86471,86481,86507,86524,86562,86568,86577,86578,86587,86591,86605,86611,86639,86655,86672,86675,86677,86696,86704,86706,86713,86716,86742,86764,86766,86776,86795,86802,86805,86817,86826,86842,86874,86904,86908,86948,86951,86961,86962,86982,87019,87041,87059,87071,87081,87084,87100,87111,87113,87114,87124,87140,87147,87165,87166,87169,87187,87190,87209,87213,87215,87222,87236,87238,87239,87280,87289,87298,87308,87310,87353,87389,87391,87393,87437,87449,87452,87460,87471,87487,87517,87652,87677,87682,87700,87709,87775,87820,87822,87824,87825,87849,87854,87894,87895,87898,87907,87916,87929,87933,87937,87944,87955,88001,88019,88042,88050,88076,88092,88098,88099,88106,88129,88140,88162,88171,88187,88192,88193,88197,88209,88210,88224,88233,88240,88241,88262,88264,88289,88291,88309,88320,88328,88332,88342,88348,88349,88363,88366,88369,88403,88404,88409,88410,88411,88418,88427,88431,88452,88454,88457,88459,88467,88485,88493,88497,88500,88501,88505,88508,88509,88537,88551,88571,88585,88594,88602,88632,88640,88654,88661,88744,88745,88747,88786,88827,88834,88841,88849,88850,88868,88871,88879,88880,88881,88882,88883,88885,88886,88895,88906,88921,88926,88928,88937,88945,88946,88947,88951,88965,88971,89011,89018,89021,89033,89035,89039,89071,89080,89081,89089,89094,89105,89116,89120,89131,89139,89141,89143,89148,89149,89151,89157,89165,89183,89194,89197,89198,89210,89211,89222,89224,89232,89242,89251,89254,89257,89294,89305,89328,89356,89360,89367,89389,89392,89412,89428,89441,89457,89458,89460,89472,89473,89474,89480,89486,89519,89520,89521,89522,89523,89524,89525,89526,89527,89531,89539,89553,89562,89572,89584,89586,89597,89609,89629,89637,89649,89672,89695,89696,89698,89701,89714,89717,89720,89786,89802,89807,89808,89847,89854,89880,89913,89921,89971,89987,89988,89989,89990,89991,89996,90005,90008,90010,90028,90045,90090,90128,90133,90135,90152,90157,90168,90169,90175,90176,90177,90193,90204,90210,90213,90229,90244,90249,90250,90267,90275,90276,90284,90303,90349,90355,90361,90423,90438,90440,90481,90571,90592,90595,90598,90608,90618,90626,90627,90632,90633,90650,90652,90657,90666,90674,90676,90677,90683,90708,90723,90728,90734,90757,90764,90772,90774,90775,90787,90793,90823,90826,90827,90829,90863,90866,90888,90901,90917,90936,90938,90952,90969,90984,90992,91000,91015,91036,91051,91052,91071,91072,91074,91077,91079,91107,91124,91130,91138,91144,91159,91169,91176,91180,91182,91188,91189,91194,91195,91214,91220,91236,91282,91307,91312,91318,91353,91356,91360,91366,91371,91373,91382,91390,91409,91446,91455,91457,91471,91475,91481,91502,91533,91536,91542,91556,91598,91599,91606,91607,91614,91627,91648,91651,91655,91658,91659,91694,91747,91748,91769,91777,91778,91806,91807,91810,91811,91816,91858,91889,91893,91895,91896,91897,91902,91906,91930,91972,91976,91983,92000,92003,92008,92010,92016,92019,92040,92049,92050,92067,92093,92097,92098,92099,92109,92134,92148,92156,92157,92161,92192,92209,92210,92212,92229,92238,92250,92268,92272,92273,92287,92297,92298,92324,92332,92336,92347,92396,92406,92436,92462,92464,92466,92467,92469,92472,92473,92475,92476,92477,92478,92479,92481,92494,92498,92530,92555,92564,92608,92628,92636,92657,92674,92690,92733,92754,92757,92763,92781,92797,92817,92878,92884,92893,92920,92928,92938,92959,93020,93027,93045,93062,93075,93090,93132,93151,93199,93202,93203,93217,93222,93223,93246,93279,93290,93317,93318,93324,93358,93365,93373,93395,93396,93400,93487,93504,93562,93574,93578,93593,93616,93635,93639,93674,93692,93717,93718,93719,93721,93727,93729,93740,93763,93777,93801,93802,93831,93832,93883,93936,93949,93967,93970,93972,93984,93989,93993,93996,94003,94015,94018,94024,94037,94071,94111,94113,94130,94149,94178,94181,94223,94228,94238,94287,94293,94309,94346,94364,94373,94378,94431,94442,94455,94472,94494,94501,94505,94584,94598,94603,94621,94622,94660,94707,94710,94711,94712,94742,94748,94751,94754,94778,94780,94783,94807,94854,94865,94872,94877,94880,94884,94885,94893,94898,94904,94908,94911,94914,94920,94932,94943,94980,94984,94989,94993,95049,95066,95068,95069,95070,95157,95160,95177,95194,95204,95206,95238,95260,95290,95295,95296,95308,95310,95345,95395,95415,95428,95467,95476,95477,95511,95514,95515,95535,95581,95604,95609,95616,95618,95655,95661,95686,95695,95707,95729,95732,95740,95743,95744,95745,95746,95747,95749,95827,95847,95862,95872,95879,95880,95892,95896,95912,95933,95951,95984,95985,95986,95988,95989,95991,95996,96003,96006,96008,96022,96040,96063,96064,96069,96079,96083,96100,96104,96132,96162,96182,96212,96219,96228,96287,96311,96312,96322,96332,96338,96347,96362,96380,96421,96455,96457,96472,96480,96484,96503,96511,96523,96570,96591,96608,96621,96646,96677,96702,96858,96879,96913,96944,96968,96972,97001,97007,97024,97069,97117,97118,97158,97175,97200,97201,97221,97228,97237,97251,97270,97274,97286,97289,97292,97293,97294,97342,97349,97350,97351,97355,97394,97431,97440,97457,97523,97537,97547,97587,97625,97647,97649,97692,97719,97767,97777,97783,97793,97828,97829,97831,97833,97847,97858,97859,97860,97921,97925,97930,97956,97960,97979,97983,98036,98062,98064,98081,98082,98096,98111,98124,98140,98156,98188,98212,98221,98233,98271,98299,98320,98361,98387,98493,98499,98514,98520,98532,98535,98544,98571,98576,98624,98663,98693,98719,98727,98737,98745,98774,98818,98856,98857,98884,98919,98920,98926,99007,99041,99042,99058,99066,99068,99079,99085,99087,99090,99105,99108,99112,99125,99141,99165,99185,99191,99205,99254,99273,99292,99294,99327,99389,99398,99402,99423,99462,99466,99468,99493,99518,99519,99528,99537,99539,99561,99563,99565,99591,99592,99593,99594,99595,99596,99597,99615,99631,99633,99634,99635,99636,99637,99643,99647,99715,99716,99718,99719,99720,99721,99778,99779,99817,99876,99913,99930,99943,99944,99956,99958,99959,99960,100016,100017,100030,100062,100067,100071,100089,100091,100092,100094,100113,100114,100116,100118,100119,100121,100134,100141,100178,100282,100301,100344,100346,100347,100349,100350,100351,100352,100385,100386,100412,100418,100427,100428,100479,100480,100481,100482,100484,100485,100486,100487,100488,100489,100490,100492,100493,100494,100495,100497,100498,100499,100500,100501,100502,100503,100504,100508,100523,100530,100531,100533,100534,100535,100536,100537,100538,100539,100540,100541,100542,100543,100544,100545,100546,100559,100561,100562,100563,100564,100565,100566,100567,100570,100572,100574,100619,100621,100636,100652,100658,100671,100678,100688,100689,100698,100750,100751,100753,100754,100755,100756,100758,100764,100765,100775,100778,100779,100799,100802,100804,100817,100818,100828,100846,100847,100877,100908,100909,100965,100981,100984,100985,100986,100988,100989,100994,101000,101005,101037,101053,101075,101109,101134,101144,101157,101161,101167,101176,101180,101181,101199,101257,101258,101316,101329,101330,101336,101341,101366,101378,101379,101380,101381,101382,101383,101384,101386,101388,101389,101390,101391,101392,101393,101394,101395,101397,101413,101422,101423,101424,101425,101471,101476,101477,101488,101494,101504,101548,101553,101561,101595,101630,101631,101632,101633,101634,101635,101636,101637,101638,101639,101640,101641,101642,101677,101686,101704,101708,101712,101717,101727,101743,101748,101754,101755,101813,101838,101840,101868,101882,101903,101915,101929,101956,101964,101968,101981,101983,101998,101999,102011,102012,102013,102014,102015,102021,102024,102025,102026,102027,102048,102055,102056,102079,102081,102082,102083,102121,102185,102195,102208,102216,102222,102246,102249,102264,102281,102302,102339,102348,102350,102373,102375,102432,102435,102436,102439,102448,102460,102470,102471,102505,102702,102703,102706,102726,102750,102762,102821,102823,102828,102853,102870,102871,102913,102935,102954,102990,102999,103002,103004,103024,103032,103034,103036,103065,103074,103090,103109,103113,103114,103126,103128,103130,103131,103134,103135,103137,103142,103145,103162,103165,103201,103234,103263,103307,103319,103358,103381,103389,103417,103451,103452,103470,103478,103479,103498,103515,103529,103557,103558,103571,103585,103588,103607,103617,103619,103669,103670,103672,103679,103693,103702,103703,103760,103818,103826,103875,103889,103898,103934,104006,104011,104019,104057,104072,104083,104130,104141,104187,104188,104219,104231,104237,104243,104244,104245,104247,104248,104259,104322,104361,104371,104372,104388,104425,104449,104457,104460,104461,104475,104478,104501,104520,104521,104522,104530,104536,104580,104619,104655,104656,104660,104666,104702,104727,104731,104772,104788,104837,104838,104840,104842,104843,104939,104940,104949,105005,105098,105304,105319,105348,105367,105393,105411,105436,105474,105495,105534,105546,105578,105585,105620,105662,105713,105723,105725,105747,105765,105822,105879,105897,105911)").includes([:style_code, {:style_settings => :style_setting_options}]).order('styles.id').find_each do |style|
	next if style.style_code.nil?
	refs = style.calculate_external_references
	# used by style options as a placeholder for user-supplied values
	refs.delete('http://example.com/image.gif')
	style_refs[style.id] = refs
end
#puts "done calculating refs"

thread_count = 1
threads = []
(0..(thread_count - 1)).each do |i|
	threads << Thread.new {
		validate_urls(style_refs, i, thread_count)
	}
end

threads.each {|t| t.join}