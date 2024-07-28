
var LibraryTextInput = {

    // This can be accessed from the bootstrap code in the .html file
    $TextInput: {
        _incrId: 0,
        list: {},
        Event: {
            EVENT_ON_SUBMIT: 0,
            EVENT_ON_TEXT_CHANGED: 1,
            EVENT_ON_FOCUS_CHANGE: 2,
        },
        ReturnKeyType: {
            RETURN_KEY_TYPE_DONE: 0,
            RETURN_KEY_TYPE_GO: 1,
            RETURN_KEY_TYPE_NEXT: 2,
            RETURN_KEY_TYPE_SEARCH: 3,
            RETURN_KEY_TYPE_SEND: 4,
        },
        Capitalize: {
            CAPITALIZE_NONE: 0,
            CAPITALIZE_SENTENCES: 1,
            CAPITALIZE_WORDS: 2,
            CAPITALIZE_CHARACTERS: 3,
        },
        KeyboardType: {
            KEYBOARD_TYPE_DEFAULT: 0,
            KEYBOARD_TYPE_NUMBER_PAD: 1,
            KEYBOARD_TYPE_EMAIL: 2,
            KEYBOARD_TYPE_PASSWORD: 3,
        },

        addEventToQueue: function(id, name, value) {
            if (TextInput.list[id]) {
                var data = TextInput.list[id];
                var AddToCommandQueue = TextInput._AddToCommandQueue;
                var cstr = stringToNewUTF8(value);
                {{{ makeDynCall('vii', 'AddToCommandQueue')}}}(id, name, cstr);
                _free(cstr);
            }
        },

        isMobile: function() {
          var check = false;
          (function(a){if(/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino|android|ipad|playbook|silk/i.test(a)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0,4))) check = true;})(navigator.userAgent||navigator.vendor||window.opera);
          return check;
        },

    },

    JS_TextInput_initialize: function(c_AddToCommandQueue) {
        TextInput._AddToCommandQueue = c_AddToCommandQueue;

        // this is a hacky method to show virtual keyboard on unsupported mobile browsers
        // only for hidden inputs having position and size via `textinput.set_position(...)` and `textinput.set_size(...)`
        if (TextInput.isMobile() && !('virtualKeyboard' in navigator && window.location.protocol == 'https:')) {
            var touchstartEvent = null;
            var container = document.getElementById('canvas-container');
            container.addEventListener('touchstart', function(ev) {
                touchstartEvent = ev.originalEvent ?? ev;
            });
            container.addEventListener('touchend', function(ev) {
                var touch = touchstartEvent.touches[0];
                for (var id in TextInput.list) {
                    var data = TextInput.list[id];
                    if (data.isHidden && data.position && data.size) {
                        if (touch.pageX >= data.position.x && touch.pageY >= data.position.y && touch.pageX <= (data.position.x + data.size.width) && touch.pageY <= (data.position.y + data.size.height)) {
                            data.field.focus();
                            break;
                        }
                    }
                }
            });
        }
    },

    JS_TextInput_create: function(isHidden) {
        var id = TextInput._incrId++;
        var field = document.createElement('input');
        field.setAttribute('id', 'LibraryTextInput-' + id);
        field.type = 'text';
        field.style.position = 'absolute';
        field.style.left = 0;
        field.style.top = 0;
        field.style.width = 0;
        field.style.height = 0;
        field.style.padding = 0;
        field.style.outline = 'none';
        field.style.border = 'none';
        field.style.background = 'transparent';
        field.style.display = 'block';
        field.addEventListener('keyup', function(ev) {
            const key = ev.code || ev.keyCode;
            if (key === 'Enter' || key === 13) {
                TextInput.addEventToQueue(id, TextInput.Event.EVENT_ON_SUBMIT, field.value);
            } else {
                TextInput.addEventToQueue(id, TextInput.Event.EVENT_ON_TEXT_CHANGED, field.value);
            }
        });
        field.addEventListener('keypress', function(ev) {
            TextInput.addEventToQueue(id, TextInput.Event.EVENT_ON_TEXT_CHANGED, field.value);
        });
        field.addEventListener('focus', function(ev) {
            TextInput.addEventToQueue(id, TextInput.Event.EVENT_ON_FOCUS_CHANGE, '1');
        });
        field.addEventListener('blur', function(ev) {
            TextInput.addEventToQueue(id, TextInput.Event.EVENT_ON_FOCUS_CHANGE, '0');
        });

        TextInput.list[id] = {
            isHidden,
            field,
        };

        var container = document.getElementById('canvas-container');
        container.appendChild(field);
        if (!isHidden) {
            var styleSheet = document.createElement('style');
            styleSheet.textContent = '#LibraryTextInput-' + id + '::placeholder { color: var(--hintColor); }';
            document.head.appendChild(styleSheet);
            TextInput.list[id].styleSheet = styleSheet;
        }
        return id;
    },

    JS_TextInput_remove: function(id) {
        if (TextInput.list[id]) {
            var data = TextInput.list[id];
            if (data.cstr_text) _free(data.cstr_text);
            data.field.parentNode.removeChild(data.field);
            if (data.styleSheet) {
                data.styleSheet.parentNode.removeChild(data.styleSheet);
            }
            delete TextInput.list[id];
        }
    },

    JS_TextInput_setVisible: function(id, visible) {
        if (TextInput.list[id]) {
            var data = TextInput.list[id];
            data.field.style.display = visible ? 'block' : 'none';
        }
    },

    JS_TextInput_setHint: function(id, hint) {
        if (TextInput.list[id] && !TextInput.list[id].isHidden) {
            var data = TextInput.list[id];
            data.field.placeholder = UTF8ToString(hint);
        }
    },

    JS_TextInput_setHintTextColor: function(id, color) {
        if (TextInput.list[id] && !TextInput.list[id].isHidden) {
            var data = TextInput.list[id];
            data.field.style.setProperty('--hintColor', UTF8ToString(color));
        }
    },

    JS_TextInput_setText: function(id, text) {
        if (TextInput.list[id]) {
            var data = TextInput.list[id];
            data.field.value = UTF8ToString(text);
        }
    },

    JS_TextInput_setTextColor: function(id, color) {
        if (TextInput.list[id] && !TextInput.list[id].isHidden) {
            var data = TextInput.list[id];
            data.field.style.color = UTF8ToString(color);
        }
    },

    JS_TextInput_setTextSize: function(id, size) {
        if (TextInput.list[id] && !TextInput.list[id].isHidden) {
            var data = TextInput.list[id];
            data.field.style.fontSize = size + 'px';
        }
    },

    JS_TextInput_setPosition: function(id, x, y) {
        if (TextInput.list[id]) {
            var data = TextInput.list[id];
            if (!data.isHidden) {
                data.field.style.left = x + 'px';
                data.field.style.top = y + 'px';
            } else {
                data.position = { x, y };
            }
        }
    },

    JS_TextInput_setSize: function(id, width, height) {
        if (TextInput.list[id]) {
            var data = TextInput.list[id];
            if (!data.isHidden) {
                data.field.style.width = width + 'px';
                data.field.style.height = height + 'px';
            } else {
                data.size = { width, height };
            }
        }
    },

    JS_TextInput_setMaxLength: function(id, maxLength) {
        if (TextInput.list[id]) {
            var data = TextInput.list[id];
            data.field.setAttribute('maxlength', maxLength);
        }
    },

    JS_TextInput_setKeyboardType: function(id, keyboardType) {
        if (TextInput.list[id]) {
            var data = TextInput.list[id];
            if (keyboardType == TextInput.KeyboardType.KEYBOARD_TYPE_NUMBER_PAD) {
                data.field.type = 'number';
            } else if (keyboardType == TextInput.KeyboardType.KEYBOARD_TYPE_EMAIL) {
                data.field.type = 'email';
            } else if (keyboardType == TextInput.KeyboardType.KEYBOARD_TYPE_PASSWORD) {
                data.field.type = 'password';
            } else {
                data.field.type = 'text';
            }
        }
    },

    JS_TextInput_setAutoCapitalize: function(id, autoCapitalize) {
        if (TextInput.list[id]) {
            var data = TextInput.list[id];
            if (autoCapitalize == TextInput.Capitalize.CAPITALIZE_SENTENCES) {
                data.field.autocapitalize = 'sentences';
            } else if (autoCapitalize == TextInput.Capitalize.CAPITALIZE_WORDS) {
                data.field.autocapitalize = 'words';
            } else if (autoCapitalize == TextInput.Capitalize.CAPITALIZE_CHARACTERS) {
                data.field.autocapitalize = 'characters';
            } else {
                data.field.autocapitalize = 'none';
            }
        }
    },

    JS_TextInput_setReturnKeyType: function(id, returnKeyType) {
        if (TextInput.list[id]) {
            var data = TextInput.list[id];
            if (returnKeyType == TextInput.ReturnKeyType.RETURN_KEY_TYPE_GO) {
                data.field.enterkeyhint = 'go';
            } else if (returnKeyType == TextInput.ReturnKeyType.RETURN_KEY_TYPE_NEXT) {
                data.field.enterkeyhint = 'next';
            } else if (returnKeyType == TextInput.ReturnKeyType.RETURN_KEY_TYPE_SEARCH) {
                data.field.enterkeyhint = 'search';
            } else if (returnKeyType == TextInput.ReturnKeyType.RETURN_KEY_TYPE_SEND) {
                data.field.enterkeyhint = 'send';
            } else {
                data.field.enterkeyhint = 'done';
            }
        }
    },

    JS_TextInput_getText: function(id) {
        if (TextInput.list[id]) {
            var data = TextInput.list[id];
            if (data.cstr_text) _free(data.cstr_text);
            var cstr = stringToNewUTF8(data.field.value);
            data.cstr_text = cstr;
            return cstr;
        }
    },

    JS_TextInput_focus: function(id) {
        if (TextInput.list[id]) {
            var data = TextInput.list[id];
            if (TextInput.isMobile()) {
                if ('virtualKeyboard' in navigator && window.location.protocol == 'https:') {
                    data.field.focus();
                    navigator.virtualKeyboard.show();
                } else {
                    // can't show virtual keyboard so we will try another method...
                }
            } else {
                data.field.focus();
            }
        }
    },

    JS_TextInput_clearFocus: function(id) {
        if (TextInput.list[id]) {
            var data = TextInput.list[id];
            data.field.blur();
        }
    },

};

autoAddDeps(LibraryTextInput, '$TextInput');
addToLibrary(LibraryTextInput);
