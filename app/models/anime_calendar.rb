require 'set'

# TODO: вынести Fixes в yml конфиг
# TODO: использовать NameMatcher вместо собственного кривого сравнения
class AnimeCalendar < ActiveRecord::Base
  belongs_to :anime

  validates_presence_of :anime
  validates_presence_of :episode
  validates_presence_of :start_at

  # импорт аниме календаря с animecalendar.net
  def self.parse
    calendar = self.load_calendar.first.events.map do |v|
      name = v
        .categories
        .first
          .split(',')
            .first
            .downcase
            .sub(/episodes$/, '')
            .strip
            .gsub('ū', 'u')
            .gsub('ō', 'o')
            .gsub('×', 'x')
            .gsub('é', 'e')

      id = Fixes.include?(name) ? Fixes[name] : nil

      {
        start_at: v.dtstart - 4.hours,
        episode: v.uid.split('_').last.to_i,
        anime_name: id ? "FIXES MATCHED #{name}" : name,
        anime_id: id
      }
    end
    return if calendar.empty?
    AnimeCalendar.delete_all

    calendar_names = calendar.map {|v| v[:anime_name] }.uniq
    fixed_calendar_names = calendar_names.map {|v| self.hashname(v) }.uniq

    replaced = "replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(%s, '♪', ''), '☆', ''), 'The ', ''), 'the ', ''), '''', ''), '?', ''), '!', ''), ':', ''), '-', ''), ' ', ''), '.', ''), ',', '')"
    query = "#{replaced % 'name'} in ('#{fixed_calendar_names.join("','")}')"
    fixed_calendar_names.each do |v|
      query += " or #{replaced % 'name'} ilike '%#{v}%'"
      query += " or #{replaced % 'english'} ilike '%#{v}%'"
      query += " or #{replaced % 'synonyms'} ilike '%#{v}%'"
      query += " or #{replaced % 'japanese'} ilike '%#{v}%'"
    end

    query += " or id in (#{(calendar.map {|v| v[:anime_id] }.compact + [0]).join(',')})"

    #animes = Anime.where(:id => 10464).where(query).inject({}) do |data,anime|
    animes = (Anime.latest + Anime.ongoing.where(query).to_a + Anime.anons.where(query).to_a)
      .select {|v| v.kind == 'TV' || v.kind == 'ONA' || [15133, 19799].include?(v.id) }.inject({}) do |data,anime|
        data[self.hashname(anime.name)] = anime
        data[anime.id] = anime
        anime.synonyms.each {|v| data[self.hashname(v)] = anime } if anime.synonyms
        anime.japanese.each {|v| data[self.hashname(v)] = anime } if anime.japanese
        anime.english.each {|v| data[self.hashname(v)] = anime } if anime.english
        data
      end

    cache = {}
    imported = Set.new

    batch = []

    calendar.each do |v|
      key = self.hashname(v[:anime_name])
      entry = animes[key] || animes[v[:anime_id]]

      next unless entry
      next if cache.include?(entry.id) && cache[entry.id].include?(v[:episode])
      v[:episode] -= EpisodesDiff[v[:anime_name]] if EpisodesDiff[v[:anime_name]]

      batch << AnimeCalendar.new({
          episode: v[:episode],
          start_at: v[:start_at],
          anime: entry
        })
      imported << v[:anime_name]
    end
    AnimeCalendar.import batch.select {|v| v.episode > v.anime.episodes_aired }

    Rails.cache.write 'calendar_unrecognized', (calendar_names - imported.to_a)

    {
      :imported => imported,
      :unrecognized => calendar_names - imported.to_a
    }
  end

  # получение календаря аниме с animecalendar.net
  def self.load_calendar
    content = Proxy.get('http://animecalendar.net/user/ical/8831/e599e8323643658c14eef67e85bdb534', timeout: 30, required_text: 'Calendar for TV from AnimeCalendar', no_proxy: true)
    Icalendar.parse(content)
  end

  def self.hashname(name)
    name.downcase.gsub(/the /, '').gsub(/[ :,.!?'☆♪-]+/, '')
  end

  Fixes = {
    "danganronpa kibo no gakuen to zetsubo no kokosei the animation" => 16592,
    "ginga kikotai majestic prince" => 15863,
    "kitakubu katsudo kiroku" => 18495,
    "pocket monsters: best wishes! season 2" => 17873,
    "rozen maiden (new)" => 18041,
    "senki zessho symphogear g" => 15793,
    "stella jo-gakuin c3-bu" => 17821,
    "furusato saisei nippon no mukashi banashi" => 13163,
    "hakkenden: toho hakken ibun 2" => 18055,
    "hunter x hunter" => 11061,
    "makai Ōji: devils and realist" => 16890,
    "teekyu 2" => 18121,
    "cho soku henkei gyrozetter" => 14989,
    "gifu dodo!!" => 18771,
    "senyu. dai 2 ki" => 18523,
    "cho jigen game neptune" => 16157,
    "maji de otaku na english! ribbon-chan: eigo de tatakau maho shojo" => 19207,
    "genei o kakeru taiyo" => 17651,
    "kamisama no inai nichiyobi" => 16009,
    "kingdom 2" => 17389,
    "kuromajo-san ga toru!!" => 17653,
    "inu to hasami wa tsukaiyo" => 17831,
    "makai oji: devils and realist" => 16890,
    "battle spirits: sword eyes" => 19877,
    "infinite stratos 2" => 18247,
    "aoki hagane no arpeggio" => 18893,
    "daiya no a" => 18689,
    "kyousogiga" => 19703,
    "phi brain: kami no puzzle 3" => 15651,
    "yozakura quartet ~hana no uta~" => 18497,
    "ore no nonai sentakushi ga" => 19221,
    "aikatsu!" => 20181,
    "kuroko no basuke 2" => 16894,
    "yusha ni narenakatta ore wa shibushibu shushoku o ketsui shimashita." => 18677,
    "diabolik lovers" => 17513,
    "wake up" => 19023,
    "chunibyo demo koi ga shitai! ren" => 18671,
    "toaru hikushi e no koiuta" => 19117,
    "gin no saji dai-2-ki" => 19363,
    "mikakunin de shinkokei" => 20541,
    "hamatora" => 20689,
    "wooser no sono higurashi kakusei-hen" => 20267,
    "inari" => 20457,
    "maken-ki! tsu" => 15565,
    "sekai seifuku ~ boryaku no zvezda" => 20973,
    'saikin' => 17777,
    'seitokai yakuindomo＊' => 20847,
    'nobunaga za furu' => 21177,
    'robot girls z' => 19799,
    'yu-gi-oh! zexal ii' => 21639,
    "haikyu!!" => 20583,
    "isshukan friends." => 21327,
    "kanojo ga flag o oraretara" => 19685,
    "love live! (2014)" => 19111,
    "gochumon wa usagi desu ka?" => 21273,
    "ping pong" => 22135,
    "ryugajo nanana no maizokin" => 21561,
    "maho shojo taisen" => 21421,
    "kindaichi shonen no jikenbo r" => 22817,
    "abarenbo rikishi!! matsutaro" => 22831,
    "fuun ishin dai shogun" => 21821,
    "no game" => 19815,
    "mahoka koko no rettosei" => 20785,
    "the world is still beautiful" => 22101,
    'break blade' => 22433,
    "mangaka-san to assistant-san to" => 21863,
    'gekkan shojo nozaki-kun' => 23289,
    'kido senshi gundam-san' => 24835,
    'la bonne vie' => 23121,
    'space dandy season 2' => 23327,
    'survival game club!' => 20709,
    'ai mai mi ~moso catastrophie~' => 23551,
    'futsu no joshikosei ga locodol yattemitaz' => 22189,
    'bishojo senshi sailor moon crystal' => 14751,
    'shonen hollywood - holly stage for 49' => 23151,
    'magimoji rurumo' => 23945,
    'rokujyoma no shinryakusha!?' => 22865,
    'zankyo no terror' => 23283,
    'ino-battle wa nichijo-kei no naka de' => 25159,
    'kaito joker' => 24909,
    'narihero www' => 27519,
    'orenchi no furo jijo' => 24211,
    'hi scoool! seha girl' => 23787,
    'kiseiju: sei no kakuritsu' => 22535,
    'danna ga nani o itteiru ka wakaranai ken' => 26349,
    'nanatsu no taiza' => 23755,
    'okami shojo to kuro oji' => 23673,
    'cross ange: tenshi to ryu no rondo' => 25731,
    'fate/stay night: unlimited blade works' => 22297,
    'log horizon 2' => 23321,
    'madan no o to vanadis' => 24455,
    'yama no susume second season' => 21435,
    'mushishi: the next chapter' => 24701,
    'aldnoah.zero 2' => 27655,
    'juo mujin no fafnir' => 24873,
    'sokyu no fafner exodus' => 17080,
    'cute high earth defense club love!' => 27727,
    'kuroko no basuke 3' => 24415,
    'dog days″' => 16385,
    'durarara!!x2 sho' => 23199,
    'shonen hollywood - holly stage for 50' => 27741,
    'tenkai knights' => 23067,
    'ansatsu kyoshitsu' => 24833,
    'jojo no kimyo na boken: stardust crusaders egypt-hen' => 26055,
    'shinmai mao no testament' => 23233,
    'kamisama hajimemashita 2' => 25681
  }

  EpisodesDiff = {
    'gintama\' enchousen' => 252,
    'diabolik lovers' => 1,
    'kuroko no basuke 2' => 25,
    'kuroko no basuke 2' => 25,
    'fairy tail (2014)' => 175,
    'FIXES MATCHED mushishi: the next chapter' => 12
  }
end
