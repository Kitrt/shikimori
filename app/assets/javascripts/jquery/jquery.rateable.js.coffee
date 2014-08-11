(($) ->
  $.fn.extend rateable: ->
    @each ->
      $stars = $('.stars-container', @)
      $hover = $('.hover', @)

      $score = $('.score', @)
      $text_score = $('.text-score', @)
      $score_notice = $('.score-notice', @)

      notices = $(@).data('notices')
      input_selector = $(@).data('input_selector')
      with_input = !!input_selector
      with_form = !!$(@).data('with_form')

      initial_score = parseInt($text_score.text()) || 0
      new_score = null

      $stars.on 'mousemove', (e) ->
        offset = $(e.target).offset().left
        raw_score = (e.clientX - offset) * 10.0 / $stars.width()
        new_score = if raw_score > 0.5
          Math.floor(raw_score) + 1
        else
          0

        $score_notice.html(notices[new_score])
        $hover.attr(class: "#{without_score $hover} score-#{new_score}")
        $text_score
          .html(new_score)
          .attr(class: "#{without_score $text_score} score-#{new_score}")

      $stars.on 'mouseover', (e) ->
        $score.addClass 'hovered'

      $stars.on 'mouseout', (e) ->
        $score.removeClass 'hovered'
        $score_notice.html(notices[initial_score])
        $hover.attr(class: without_score $hover)
        $text_score
          .attr(class: "#{without_score $text_score} score-#{initial_score}")
          .html(initial_score)

      $stars.on 'click', (e) ->
        if with_input
          initial_score = new_score

          $(@).closest('form').find(input_selector).val(new_score)
          $(@).closest('form').submit() if with_form
          $stars.trigger('mouseout')

  without_score = ($node) ->
    $node.attr('class').replace(/\s?score-\d+/, '')

) jQuery
