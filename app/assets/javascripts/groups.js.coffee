$(document).ready ->
  $("#live-poll-groups").on "click", (e) ->
    if $("#live-poll-groups").hasClass("enabled")
      clearInterval intval
      $(this).toggleClass "disabled"
    else
      intval = setInterval(->
        $.ajax
          url: "new_groups/live"
          type: "GET"
          dataType: "script"

      , 3000)
      $(this).toggleClass "disabled"
    $(this).toggleClass "enabled"