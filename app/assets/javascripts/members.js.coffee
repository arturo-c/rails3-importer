$(document).ready ->
  $("#live-poll-members").bind 'click', ->
    $(this).toggleClass "enabled"
    if $(this).hasClass('disabled')
      clearInterval intval
    else
      intval = setInterval(->
        $.ajax
          url: "new_members/live"
          type: "GET"
          dataType: "script"

      , 3000)
  $("#members th a").live "click", ->
    $.getScript @href
    false