

$(document).ready =>
  editor = ace.edit("editor")
  editor.setTheme("ace/theme/monokai")
  editor.getSession().setMode("ace/mode/coffee")

  editor1 = ace.edit("editor1")
  editor1.setTheme("ace/theme/monokai")
  editor1.getSession().setMode("ace/mode/javascript")

  console.log(editor)

  $("button").on("click", =>
    console.log("got click!")
    input = editor.getSession().getValue()
    console.log("code is", input)
    $.post("/test-page", {code: input}, (data) -> editor1.getSession().setValue(data))
  )









