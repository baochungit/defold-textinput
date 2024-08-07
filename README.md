# Defold TextInput

This extension brings Native Text Input Field to Defold.
Currently it supports Android, iOS, HTML5.

## Demo:
https://baochungit.github.io/defold-textinput/

## Example:
```lua
local id = textinput.create(false, function(self, ev, data)
  if ev == textinput.EVENT_ON_TEXT_CHANGED then
    print(data)
  elseif ev == textinput.EVENT_ON_SUBMIT then
    print(data)
  end
end)
textinput.set_hint(id, "Enter here...")
textinput.set_hint_text_color(id, "#ff0000")
textinput.set_text_color(id, "#ffff00")
textinput.set_position(id, 300, 400)
textinput.set_size(id, 500, 150)
textinput.set_auto_capitalize(id, textinput.CAPITALIZE_SENTENCES)
textinput.set_visible(id, true)
```

## Exposed APIs:
* `textinput.create(is_hidden, listener)`
* `textinput.set_visible(id, visible)`
* `textinput.set_position(id, x, y)`
* `textinput.set_size(id, width, height)`
* `textinput.set_text(id, text)`
* `textinput.set_text_color(id, color)`
* `textinput.set_text_size(id, text_size)`
* `textinput.set_hint(id, hint)`
* `textinput.set_hint_text_color(id, color)`
* `textinput.set_max_length(id, max_length)`
* `textinput.set_keyboard_type(id, keyboard_type)`
* `textinput.set_auto_capitalize(id, capitalize)`
* `textinput.set_return_key_type(id, return_key_type)`
* `textinput.get_text(id)`
* `textinput.focus(id)`
* `textinput.clear_focus(id)`
* `textinput.destroy(id)`

## Exposed Constants:
* KeyboardType: `textinput.KEYBOARD_TYPE_DEFAULT`, `textinput.KEYBOARD_TYPE_NUMBER_PAD`, `textinput.KEYBOARD_TYPE_EMAIL`, `textinput.KEYBOARD_TYPE_PASSWORD`
* Capitalize: `textinput.CAPITALIZE_NONE`, `textinput.CAPITALIZE_SENTENCES`, `textinput.CAPITALIZE_WORDS`, `textinput.CAPITALIZE_CHARACTERS`
* ReturnKeyType: `textinput.RETURN_KEY_TYPE_DONE`, `textinput.RETURN_KEY_TYPE_GO`, `textinput.RETURN_KEY_TYPE_NEXT`, `textinput.RETURN_KEY_TYPE_SEARCH`, `textinput.RETURN_KEY_TYPE_SEND`
* Event: `textinput.EVENT_ON_SUBMIT`, `textinput.EVENT_ON_TEXT_CHANGED`, `textinput.EVENT_ON_FOCUS_CHANGE`

---
