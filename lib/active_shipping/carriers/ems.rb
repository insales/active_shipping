require 'open-uri'

# http://emspost.ru/service/online/api/
module ActiveShipping
  class Ems  < Carrier
    READ_TIMEOUT                      = 3
    TOTAL_TIMEOUT                     = 3

    EMS_INSURANCE                     = 0.01
    EMS_MAX_INSURANCE                 = 50_000

    INGOSSTRAH_INSURANCE              = 0.006
    INGOSSTRAH_MIN_INSURANCE          = 3000
    INGOSSTRAH_MAX_FOR_JEWELRY        = 1_000_000
    INGOSSTRAH_MAX_FOR_CORRESPONDENCE = 20_000
    INGOSSTRAH_MAX_FOR_OTHER          = 600_000

    cattr_reader :name
    @@name = 'EMS почта россии'
    URL = 'http://emspost.ru/api/rest/?'
    # http://www.emspost.ru/api/rest/?method=ems.get.locations&type=regions
    # http://www.emspost.ru/api/rest/?method=ems.get.locations&type=cities
    # http://www.emspost.ru/api/rest/?method=ems.calculate&from=city--kaliningrad&to=city--sevastopol&weight=3

    ALLOWED_COUNTRIES = %w(
      AE AG AI AL AM AN AO AR AT AU AU AW AZ BA BB BD BE BF BG BH BJ BM BN BO BR BS BT BW BY BZ
      CA CF CG CH CI CL CM CN CO CR CS CU CY CZ DE DJ DK DM DO DZ EC EE EG EQ ES ES ET FI FJ FO
      FR FR FR FR FR FR FR FR FR GA GB GB GD GE GH GI GL GM GN GR GS GT HK HN HR HU ID IE II IN
      IR IS IT IT JM JO JP JS KE KG KH KN KR KW KY KZ LA LB LC LI LK LS LT LU LV MA MD MG MK ML
      MN MR MT MU MV MW MX MY MZ NA NC NE NG NI NL NO NZ NZ OM PA PE PG PH PK PL PT PT PT PY QA
      RO SA SB SC SD SE SG SI SK SN SR ST SV SY SZ TC TD TG TH TJ TM TN TR TT TW TZ UA UG US UY
      UZ VC VC VE VG VN VU YE ZA ZM ZW).freeze

    REGIONS = [
      ['Алтайский край',              'region--altajskij-kraj'],
      ['Амурская область',            'region--amurskaja-oblast'],
      ['Архангельская область',       'region--arhangelskaja-oblast'],
      ['Астраханская область',        'region--astrahanskaja-oblast'],
      ['Белгородская область',        'region--belgorodskaja-oblast'],
      ['Брянская область',            'region--brjanskaja-oblast'],
      ['Владимирская область',        'region--vladimirskaja-oblast'],
      ['Волгоградская область',       'region--volgogradskaja-oblast'],
      ['Вологодская область',         'region--vologodskaja-oblast'],
      ['Воронежская область',         'region--voronezhskaja-oblast'],
      ['Еврейская АО',                'region--evrejskaja-ao'],
      ['Забайкальский край',          'region--zabajkalskij-kraj'],
      ['Ивановская область',          'region--ivanovskaja-oblast'],
      ['Иркутская область',           'region--irkutskaja-oblast'],
      ['Кабардино-Балкарская Республика', 'region--kabardino-balkarskaja-respublika'],
      ['Калининградская область',     'region--kaliningradskaja-oblast'],
      ['Калужская область',           'region--kaluzhskaja-oblast'],
      ['Камчатский край',             'region--kamchatskij-kraj'],
      ['Карачаево-Черкесская Республика', 'region--karachaevo-cherkesskaja-respublika'],
      ['Кемеровская область',         'region--kemerovskaja-oblast'],
      ['Кировская область',           'region--kirovskaja-oblast'],
      ['Костромская область',         'region--kostromskaja-oblast'],
      ['Краснодарский край',          'region--krasnodarskij-kraj'],
      ['Красноярский край',           'region--krasnojarskij-kraj'],
      ['Курганская область',          'region--kurganskaja-oblast'],
      ['Курская область',             'region--kurskaja-oblast'],
      ['Ленинградская область',       'region--leningradskaja-oblast'],
      ['Липецкая область',            'region--lipeckaja-oblast'],
      ['Магаданская область',         'region--magadanskaja-oblast'],
      ['Московская область',          'region--moskovskaja-oblast'],
      ['Москва',                      'city--moskva'],
      ['Мурманская область',          'region--murmanskaja-oblast'],
      ['Ненецкий АО',                 'region--neneckij-ao'],
      ['Нижегородская область',       'region--nizhegorodskaja-oblast'],
      ['Новгородская область',        'region--novgorodskaja-oblast'],
      ['Новосибирская область',       'region--novosibirskaja-oblast'],
      ['Омская область',              'region--omskaja-oblast'],
      ['Оренбургская область',        'region--orenburgskaja-oblast'],
      ['Орловская область',           'region--orlovskaja-oblast'],
      ['Пензенская область',          'region--penzenskaja-oblast'],
      ['Пермский край',               'region--permskij-kraj'],
      ['Приморский край',             'region--primorskij-kraj'],
      ['Псковская область',           'region--pskovskaja-oblast'],
      ['Республика Адыгея',           'region--respublika-adygeja'],
      ['Республика Алтай',            'region--respublika-altaj'],
      ['Республика Башкортостан',     'region--respublika-bashkortostan'],
      ['Республика Бурятия',          'region--respublika-burjatija'],
      ['Республика Дагестан',         'region--respublika-dagestan'],
      ['Республика Ингушетия',        'region--respublika-ingushetija'],
      ['Республика Калмыкия',         'region--respublika-kalmykija'],
      ['Республика Карелия',          'region--respublika-karelija'],
      ['Республика Коми',             'region--respublika-komi'],
      ['Республика Крым',             'region--crimea'],
      ['Республика Марий Эл',         'region--respublika-marij-el'],
      ['Республика Мордовия',         'region--respublika-mordovija'],
      ['Республика Саха (Якутия)',    'region--respublika-saha-yakutija'],
      ['Республика Сев.Осетия-Алания', 'region--respublika-sev.osetija-alanija'],
      ['Республика Татарстан',        'region--respublika-tatarstan'],
      ['Республика Тыва',             'region--respublika-tyva'],
      ['Республика Хакасия',          'region--respublika-khakasija'],
      ['Ростовская область',          'region--rostovskaja-oblast'],
      ['Рязанская область',           'region--rjazanskaja-oblast'],
      ['Самарская область',           'region--samarskaja-oblast'],
      ['Санкт-Петербург',             'city--sankt-peterburg'],
      ['Саратовская область',         'region--saratovskaja-oblast'],
      ['Сахалинская область',         'region--sahalinskaja-oblast'],
      ['Свердловская область',        'region--sverdlovskaja-oblast'],
      ['Смоленская область',          'region--smolenskaja-oblast'],
      ['Ставропольский край',         'region--stavropolskij-kraj'],
      ['Таймырский АО',               'region--tajmyrskij-ao'],
      ['Тамбовская область',          'region--tambovskaja-oblast'],
      ['Тверская область',            'region--tverskaja-oblast'],
      ['Томская область',             'region--tomskaja-oblast'],
      ['Тульская область',            'region--tulskaja-oblast'],
      ['Тюменская область',           'region--tjumenskaja-oblast'],
      ['Удмуртская Республика',       'region--udmurtskaja-respublika'],
      ['Ульяновская область',         'region--uljanovskaja-oblast'],
      ['Хабаровский край',            'region--khabarovskij-kraj'],
      ['Ханты-Мансийский АО',         'region--khanty-mansijskij-ao'],
      ['Челябинская область',         'region--cheljabinskaja-oblast'],
      ['Чеченская Республика',        'region--chechenskaja-respublika'],
      ['Чувашская Республика',        'region--chuvashskaja-respublika'],
      ['Чукотский АО',                'region--chukotskij-ao'],
      ['Ямало-Ненецкий АО',           'region--yamalo-neneckij-ao'],
      ['Ярославская область',         'region--yaroslavskaja-oblast']
    ].freeze

    CITIES = [
      ['Абакан',              'city--abakan'],
      ['Анадырь',             'city--anadyr'],
      ['Анапа',               'city--anapa'],
      ['Архангельск',         'city--arhangelsk'],
      ['Астрахань',           'city--astrahan'],
      ['Барнаул',             'city--barnaul'],
      ['Байконур',            'city--bajkonur'],
      ['Белгород',            'city--belgorod'],
      ['Биробиджан',          'city--birobidzhan'],
      ['Благовещенск',        'city--blagoveshhensk'],
      ['Брянск',              'city--brjansk'],
      ['Великий Новгород',    'city--velikij-novgorod'],
      ['Владивосток',         'city--vladivostok'],
      ['Владикавказ',         'city--vladikavkaz'],
      ['Владимир',            'city--vladimir'],
      ['Волгоград',           'city--volgograd'],
      ['Вологда',             'city--vologda'],
      ['Воркута',             'city--vorkuta'],
      ['Воронеж',             'city--voronezh'],
      ['Горно-Алтайск',       'city--gorno-altajsk'],
      ['Грозный',             'city--groznyj'],
      ['Дудинка',             'city--dudinka'],
      ['Екатеринбург',        'city--ekaterinburg'],
      ['Елизово',             'city--elizovo'],
      ['Иваново',             'city--ivanovo'],
      ['Ижевск',              'city--izhevsk'],
      ['Иркутск',             'city--irkutsk'],
      ['Йошкар-Ола',          'city--ioshkar-ola'],
      ['Казань',              'city--kazan'],
      ['Калининград',         'city--kaliningrad'],
      ['Калуга',              'city--kaluga'],
      ['Кемерово',            'city--kemerovo'],
      ['Киров',               'city--kirov'],
      ['Костомукша',          'city--kostomuksha'],
      ['Кострома',            'city--kostroma'],
      ['Краснодар',           'city--krasnodar'],
      ['Красноярск',          'city--krasnojarsk'],
      ['Курган',              'city--kurgan'],
      ['Курск',               'city--kursk'],
      ['Кызыл',               'city--kyzyl'],
      ['Липецк',              'city--lipeck'],
      ['Магадан',             'city--magadan'],
      ['Магнитогорск',        'city--magnitogorsk'],
      ['Майкоп',              'city--majkop'],
      ['Махачкала',           'city--mahachkala'],
      ['Минеральные Воды',    'city--mineralnye-vody'],
      ['Мирный',              'city--mirnyj'],
      ['Москва',              'city--moskva'],
      ['Мурманск',            'city--murmansk'],
      ['Мытищи',              'city--mytishhi'],
      ['Набережные Челны',    'city--naberezhnye-chelny'],
      ['Надым',               'city--nadym'],
      ['Назрань',             'city--nazran'],
      ['Нальчик',             'city--nalchik'],
      ['Нарьян-Мар',          'city--narjan-mar'],
      ['Нерюнгри',            'city--nerjungri'],
      ['Нефтеюганск',         'city--neftejugansk'],
      ['Нижневартовск',       'city--nizhnevartovsk'],
      ['Нижний Новгород',     'city--nizhnij-novgorod'],
      ['Новокузнецк',         'city--novokuzneck'],
      ['Новороссийск',        'city--novorossijsk'],
      ['Новосибирск',         'city--novosibirsk'],
      ['Новый Уренгой',       'city--novyj-urengoj'],
      ['Норильск',            'city--norilsk'],
      ['Ноябрьск',            'city--nojabrsk'],
      ['Омск',                'city--omsk'],
      ['Орел',                'city--orel'],
      ['Оренбург',            'city--orenburg'],
      ['Пенза',               'city--penza'],
      ['Пермь',               'city--perm'],
      ['Петрозаводск',        'city--petrozavodsk'],
      ['Петропавловск-Камчатский', 'city--petropavlovsk-kamchatskij'],
      ['Псков',               'city--pskov'],
      ['Ростов-на-Дону',      'city--rostov-na-donu'],
      ['Рязань',              'city--rjazan'],
      ['Салехард',            'city--salehard'],
      ['Самара',              'city--samara'],
      ['Санкт-Петербург',     'city--sankt-peterburg'],
      ['Саранск',             'city--saransk'],
      ['Саратов',             'city--saratov'],
      ['Севастополь',         'city--sevastopol'],
      ['Симферополь',         'city--simferopol'],
      ['Смоленск',            'city--smolensk'],
      ['Сочи',                'city--sochi'],
      ['Ставрополь',          'city--stavropol'],
      ['Стрежевой',           'city--strezhevoj'],
      ['Сургут',              'city--surgut'],
      ['Сыктывкар',           'city--syktyvkar'],
      ['Тамбов',              'city--tambov'],
      ['Тверь',               'city--tver'],
      ['Тольятти',            'city--toljatti'],
      ['Томск',               'city--tomsk'],
      ['Тула',                'city--tula'],
      ['Тында',               'city--tynda'],
      ['Тюмень',              'city--tjumen'],
      ['Улан-Удэ',            'city--ulan-udje'],
      ['Ульяновск',           'city--uljanovsk'],
      ['Усинск',              'city--usinsk'],
      ['Уфа',                 'city--ufa'],
      ['Ухта',                'city--uhta'],
      ['Хабаровск',           'city--khabarovsk'],
      ['Ханты-Мансийск',      'city--khanty-mansijsk'],
      ['Холмск',              'city--kholmsk'],
      ['Чебоксары',           'city--cheboksary'],
      ['Челябинск',           'city--cheljabinsk'],
      ['Череповец',           'city--cherepovec'],
      ['Черкесск',            'city--cherkessk'],
      ['Чита',                'city--chita'],
      ['Элиста',              'city--elista'],
      ['Южно-Сахалинск',      'city--yuzhno-sahalinsk'],
      ['Якутск',              'city--yakutsk'],
      ['Ярославль',           'city--yaroslavl']
    ].freeze

    ADDRESS = (REGIONS + CITIES).freeze
    ADDRESS_HASH = {}
    ADDRESS.each { |e| ADDRESS_HASH[e[0]] = e[1] }
    ADDRESS_HASH.freeze

    def find_rates(origin, destination, packages)
      packages = Array(packages)

      request = build_rate_request(origin, destination, packages)

      response = commit(request)

      parse_rate_response(origin, destination, packages, response)
    end

    #  * from (обязательный, кроме международной доставки) — пункт отправления
    #  * to (обязательный) —пункт назначения отправления
    #  * weight (обязательный) — вес отправления
    #  * type (обязательный для международной доставки) — тип международного отправления:
    #         "doc" — документы (до 2-х килограм), "att" — товарные вложения
    def build_rate_request(origin, destination, packages)
      params = ['method=ems.calculate']
      raise ArgumentError.new("EMS packages must originate in the RU") unless ['RU',nil].include?(origin.country_code(:alpha2))

      if !['RU',nil].include?(destination.country_code(:alpha2))
        params.push("to=#{destination.country_code(:alpha2)}")
        params.push("type=att")
      else
        from = ADDRESS_HASH[origin.city] || ADDRESS_HASH[origin.state]
        raise ArgumentError.new("EMS origin state incorrect: #{origin.state}") unless from
        params.push("from=#{from}")
        to = ADDRESS_HASH[destination.city] || ADDRESS_HASH[destination.state]
        raise ArgumentError.new("EMS destination state incorrect: #{destination.state}") unless to
        params.push("to=#{to}")
      end
      weight = [(packages.first.kgs.to_f*1000).round/1000.0, 0.1].max
      params.push("weight=#{weight}")
      URL + params.join('&')
    end

    def commit(uri)
      Rails.logger.info "EMS fetch: #{uri}"

      uri = URI(uri)

      result = nil
      Timeout.timeout(TOTAL_TIMEOUT) do
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = READ_TIMEOUT
        response = http.get(uri.request_uri)

        result = response.body.to_s
      end

      begin
        @response = JSON.parse(result)
      rescue JSON::ParserError
        # в случае с отправкой в UA приходит невалидный JSON "{\"rsp\":{\"stat\":\"ok\",\"price\":\"1115\"}}}",
        # в таком случае откусываем лишнюю скобку в конце.
        @response = JSON.parse(json.chop) rescue nil
      end

      raise ArgumentError.new("EMS fail.\nRequest:\n#{uri}\nResponse:\n#{@response.inspect}") unless response_success?
      @response['rsp']
    rescue Timeout::Error
      raise ArgumentError.new("EMS fail.\nTimeout.")
    end

    def parse_rate_response(origin, destination, packages, response)
      rate_estimate(origin, destination, packages, response['price'], response['term'] ? "#{response['term']['min']} - #{response['term']['max']}" : '')
    end

    def rate_estimate(origin, destination, packages, price, delivery_date='')
      package = packages.first
      rate_estimation = RateEstimate.new(
        origin,
        destination,
        @@name,
        nil,
        currency:      'RUB',
        delivery_date: delivery_date
      )

      # Стоимость доставки
      price = price.to_f

      # Стоимость страховки
      if @options[:insurance] && ['RU',nil].include?(destination.country_code(:alpha2)) && package.value > min_insurance
        price += (package.value > max_insurance ? max_insurance : package.value) * insurance_percent
      end

      # Стоимость упаковки
      price += @options[:packing_price].to_f if @options[:packing_price]

      rate_estimation.add(package, price)
    end

    def response_success?
      @response && @response['rsp']['stat'] == "ok"
    end

    def insurance_percent
      case @options[:insurance_type]
      when 'ems'
        EMS_INSURANCE
      when 'jewelry', 'other', 'correspondence'
        INGOSSTRAH_INSURANCE
      else
        0
      end
    end

    def max_insurance
      case @options[:insurance_type]
      when 'ems'
        EMS_MAX_INSURANCE
      when 'jewelry'
        INGOSSTRAH_MAX_FOR_JEWELRY
      when 'other'
        INGOSSTRAH_MAX_FOR_OTHER
      when 'correspondence'
        INGOSSTRAH_MAX_FOR_CORRESPONDENCE
      else
        0
      end
    end

    def min_insurance
      case @options[:insurance_type]
      when 'jewelry', 'other', 'correspondence'
        INGOSSTRAH_MIN_INSURANCE
      else
        0
      end
    end
  end
end
