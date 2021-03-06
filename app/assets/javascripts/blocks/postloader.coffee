$ ->
  $('.b-postloader').appear()

# динамическая подгрузка контента по мере прокрутки страницы
$(document).on 'click appear', '.b-postloader', (e) ->
  $postloader = $(@)
  return if $postloader.data('locked') || (e.type == 'appear' && $postloader.data('ignore-appear'))

  loading = I18n.t('frontend.lib.postloader.loading')
  $postloader.html "<div class=\"ajax-loading vk-like\" title=\"#{loading}...\" />"
  url = $postloader.data('remote')
  filter = $postloader.data('filter')

  $postloader.data locked: true

  $.getJSON url, (data) ->
    $data = $('<div>').append("#{data.content}#{data.postloader}")

    filter_present_entries($data, $postloader.parent(), filter) if filter

    $postloader.trigger 'postloader:before', [$data, data]
    $data.process(data.JS_EXPORTS)

    $insert_content = $data.children()
    $postloader.replaceWith $insert_content
    $insert_content.first().trigger 'postloader:success'

    $postloader.data locked: false

# удаляем уже имеющиеся подгруженные элементы
filter_present_entries = ($new_entries, $root, filter) ->
  present_ids = $(".#{filter}", $root)
    .toArray()
    .map (v) -> v.id
    .filter (v) -> v

  exclude_selector = present_ids.map (id) ->
      ".#{filter}##{id}"
    .join(',')

  $new_entries.children().filter(exclude_selector).remove()
