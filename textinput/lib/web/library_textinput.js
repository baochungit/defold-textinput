
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
                var AddToCommandQueue = data.c_AddToCommandQueue;
                var cstr = stringToNewUTF8(value);
                {{{ makeDynCall('vii', 'AddToCommandQueue')}}}(id, name, cstr);
                _free(cstr);
            }
        }
    },

    JS_TextInput_initialize: function() {
    },

    JS_TextInput_create: function(isHidden, c_AddToCommandQueue) {
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
        field.addEventListener('keyup', (ev) => {
            const key = ev.code || ev.keyCode;
            if (key === 'Enter' || key === 13) {
                TextInput.addEventToQueue(id, TextInput.Event.EVENT_ON_SUBMIT, field.value);
            } else {
                TextInput.addEventToQueue(id, TextInput.Event.EVENT_ON_TEXT_CHANGED, field.value);
            }
        });
        field.addEventListener('keypress', (ev) => {
            TextInput.addEventToQueue(id, TextInput.Event.EVENT_ON_TEXT_CHANGED, field.value);
        });
        field.addEventListener('focus', (ev) => {
            TextInput.addEventToQueue(id, TextInput.Event.EVENT_ON_FOCUS_CHANGE, '1');
        });
        field.addEventListener('blur', (ev) => {
            TextInput.addEventToQueue(id, TextInput.Event.EVENT_ON_FOCUS_CHANGE, '0');
        });

        TextInput.list[id] = {
            isHidden,
            c_AddToCommandQueue,
            field,
            cstr_text: null,
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
        if (TextInput.list[id] && !TextInput.list[id].isHidden) {
            var data = TextInput.list[id];
            data.field.style.left = x + 'px';
            data.field.style.top = y + 'px';
        }
    },

    JS_TextInput_setSize: function(id, width, height) {
        if (TextInput.list[id] && !TextInput.list[id].isHidden) {
            var data = TextInput.list[id];
            data.field.style.width = width + 'px';
            data.field.style.height = height + 'px';
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
            data.field.focus();
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
