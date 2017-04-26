require './static_loader'

using 'Images'
class Images.ImageboardsLoader extends Images.StaticLoader
  # какие теги отфильтровывать
  FORBIDDEN_TAGS = [
    'comic', 'cum', 'fellatio', 'pussy', 'penis', 'sex', 'pussy_juice', 'nude',
    'nipples', 'spread_legs', 'flat_color', 'micro_bikini', 'monochrome',
    'bottomless', 'censored', 'chibi', 'meme', 'dakimakura', 'undressing',
    'lowres', 'plump', 'cameltoe', 'bandaid_on_pussy', 'bandaids_on_nipples',
    'oral', 'footjob', "erect_nipples\b.*\bpanties", "breasts\b.*\btopless",
    'crotch_zipper', 'bdsm', 'side-tie_panties', 'anal', 'masturbation',
    'panty_pull', 'loli', 'print_panties'
  ]

  LOADERS = [
    Images.Imageboard.SafebooruLoader,
    Images.Imageboard.DanbooruLoader,
    Images.Imageboard.YandereLoader,
    Images.Imageboard.KonachanLoader
  ]

  constructor: (@batch_size, @tags) ->
    uEvent.mixin @

    @forbidden_tags =
      new RegExp FORBIDDEN_TAGS.map((v) -> "\\b#{v}\\b").join('|')

    @cache = []
    @hashes = {}
    @awaiting_load = false

    @loaders = LOADERS.map (klass) => new klass(@tags, @forbidden_tags)
    @loaders.forEach (loader) =>
      loader.on Images.Imageboard.LoaderBase.FETCH_EVENT, @_loader_fetch

  # public methods
  fetch: (count) ->
    if @cache.length
      @_return_from_cache()
    else
      @awaiting_load = true
      @_vacant_loaders().forEach (loader) -> loader.fetch()

  is_finished: ->
    @cache.length == 0 &&
      @loaders.all (loader) -> loader.is_finished

  # callbacks
  # loader returned images
  _loader_fetch: (images) =>
    images
      .filter (image) => (image.md5 not of @hashes)
      .forEach (image) =>
        @hashes[image.md5] = true
        @cache.push image

    if @awaiting_load
      @awaiting_load = false
      @_return_from_cache()

  # private methods
  _vacant_loaders: ->
    @loaders.filter (loader) -> !loader.is_loading && !loader.is_finished
