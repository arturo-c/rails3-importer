$(document).ready(
  function(){
    $('#live-poll-members').on("click", function(e) {
      if ($('#live-poll-members').hasClass('enabled')) {
        clearInterval(intval);
        $(this).toggleClass('disabled');
      }else {
        intval = setInterval(function(){
          $.ajax({
            url: "new_members/live",
            type: "GET",
            dataType: "script"
          });
        }, 3000 );
        $(this).toggleClass('disabled');
      }
      $(this).toggleClass('enabled');
    });
    if ($('#live-poll-groups').hasClass('enabled')) {
      setInterval(function(){
        $.ajax({
          url: "new_groups/live",
          type: "GET",
          dataType: "script"
        });
      }, 3000 );
    }
  });