#if defined(DM_PLATFORM_IOS)
/*
// Please help to finish this for iOS platform.
// Thanks!

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "textinput_private.h"

namespace dmTextInput {

@interface TextInputDelegate
{
	@public UIKeyboardType keyboardType;
	@public UITextAutocapitalizationType autocapitalizationType;
	@public UIReturnKeyType returnKeyType;
	@public BOOL secureTextEntry;
	@public BOOL visible;
	@public BOOL focused;
	@public BOOL isHidden;
}
@end
@implementation TextInputDelegate : UIViewController <UITextInputDelegate>
- (void) refectKeyboard
{
	if (visible && focused)
	{
		if (isHidden)
		{
			BaseView* view = (BaseView*) _glfwWin.view;
			view.secureTextEntry = secureTextEntry;
			view.keyboardType = keyboardType;
			view.autocapitalizationType = autocapitalizationType;
			view.returnKeyType = returnKeyType;	
		}
		else
		{
			// 
		}
	}
}
- (void) setFocused: (BOOL)value
{
	if (visible)
	{
		focused = value;
		if (focused) {
			[self refectKeyboard];
			if (isHidden)
			{
				BaseView* view = (BaseView*) _glfwWin.view;
				view.autoCloseKeyboard = 0;
				[view clearMarkedText];
				[view becomeFirstResponder];
			}
			else
			{
				// 
			}
		} else {
			if (isHidden)
			{
				BaseView* view = (BaseView*) _glfwWin.view;
				[view resignFirstResponder];
			}
			else
			{
				// 
			}
		}
	}
}
- (void) destroy
{
	if (focused)
	{
		[self setFocused:NO];
	}
	if (!isHidden)
	{
		// 
	}
}
- (void)textDidChange:(id<UITextInput>)textInput
{
	// 
}
@end

struct TextInputState
{
	TextInputState
	{
		m_IdIncr = 0;
		m_FocusingOn = -1;
	}

	int m_IdIncr;
	int m_FocusingOn;
	std::map<int,TextInputDelegate*>		 m_TextInputDelegates;
	std::map<int,dmScript::LuaCallbackInfo*> m_Listeners;
	CommandQueue							 m_CommandQueue;
};

static TextInputState g_TextInput;

static char* CopyString(NSString* s)
{
	const char* osstring = [s UTF8String];
	char* copy = strdup(osstring);
	return copy;
}

void Initialize(dmExtension::Params* params)
{
}

void Update()
{
	if (g_TextInput.m_CommandQueue.m_Commands.Empty())
	{
		return;
	}

	dmArray<Command> tmp;
	{
		DM_MUTEX_SCOPED_LOCK(g_TextInput.m_CommandQueue.m_Mutex);
		tmp.Swap(g_TextInput.m_CommandQueue.m_Commands);
	}

	for(uint32_t i = 0; i != tmp.Size(); ++i)
	{
		Command* cmd = &tmp[i];
		if (cmd->m_Callback != 0)
		{
			lua_State* L = dmScript::GetCallbackLuaContext(cmd->m_Callback);
			DM_LUA_STACK_CHECK(L, 0);

			if (dmScript::SetupCallback(cmd->m_Callback))
			{
				lua_pushnumber(L, cmd->m_Command);
				if (cmd->m_Command == EVENT_ON_SUBMIT || cmd->m_Command == EVENT_ON_TEXT_CHANGED) {
					lua_pushstring(L, (const char*)cmd->m_Data);
				} else if (cmd->m_Command == EVENT_ON_FOCUS_CHANGE) {
					lua_pushboolean(L, strcmp((const char*)cmd->m_Data, "1") == 0);
				} else {
					lua_pushnil(L);
				}

				dmScript::PCall(L, 3, 0);
				dmScript::TeardownCallback(cmd->m_Callback);
			}
		}
	}
}

void Finalize()
{
	Queue_Destroy(&g_TextInput.m_CommandQueue);
	for(std::map<int,dmScript::LuaCallbackInfo*>::iterator it = g_TextInput.m_Listeners.begin(); it != g_TextInput.m_Listeners.end(); ++it) {
		dmScript::LuaCallbackInfo* callback = it->second;
		if (callback != 0)
		{
			dmScript::DestroyCallback(callback);
		}
	}
}

int Create(bool isHidden, dmScript::LuaCallbackInfo* callback)
{
	int id = g_TextInput.m_IdIncr++;
	TextInputDelegate* textInput = [TextInputDelegate alloc];
	textInput.keyboardType = UIKeyboardTypeDefault;
	textInput.autocapitalizationType = UITextAutocapitalizationTypeNone;
	textInput.returnKeyType = isHidden ? UIReturnKeyDone : UIReturnKeyDefault;
	textInput.secureTextEntry = NO;
	textInput.visible = YES;
	textInput.focused = NO;
	textInput.isHidden = isHidden ? YES : NO;
	g_TextInput.m_TextInputDelegates[id] = textInput;
	g_TextInput.m_Listeners[id] = callback;

	return id;
}

void Destroy(int id)
{
	TextInputDelegate* textInput = g_TextInput.m_TextInputDelegates[id];
	if (textInput)
	{
		if (textInput.focused)
		{
			g_TextInput.m_FocusingOn = -1;
		}
		[textInput destroy];
	}
	g_TextInput.m_TextInputDelegates[id] = NULL;
	dmScript::LuaCallbackInfo* callback = g_TextInput.m_Listeners[id];
	if (callback != 0)
	{
		dmScript::DestroyCallback(callback);
		g_TextInput.m_Listeners[id] = 0;
	}
}

void SetVisible(int id, bool visible)
{
	TextInputDelegate* textInput = g_TextInput.m_TextInputDelegates[id];
	if (textInput)
	{
		textInput->visible = visible ? YES : NO;
		if (!textInput->visible && textInput->focused)
		{
			[textInput setFocused:NO];
			g_TextInput.m_FocusingOn = -1;
		}
	}
}

void SetHint(int id, const char* hint)
{
}

void SetHintTextColor(int id, const char* color)
{
}

void SetText(int id, const char* text)
{
}

void SetTextColor(int id, const char* color)
{
}

void SetTextSize(int id, int size)
{
}

void SetPosition(int id, int x, int y)
{
}

void SetSize(int id, int width, int height)
{
}

void SetMaxLength(int id, int maxLength)
{
}

void SetKeyboardType(int id, KeyboardType keyboardType)
{
	TextInputDelegate* textInput = g_TextInput.m_TextInputDelegates[id];
	if (textInput)
	{
		switch (keyboardType) {
			case KEYBOARD_TYPE_DEFAULT:
				textInput.secureTextEntry = NO;
				textInput.keyboardType = UIKeyboardTypeDefault;
				break;
			case KEYBOARD_TYPE_NUMBER_PAD:
				textInput.secureTextEntry = NO;
				textInput.keyboardType = UIKeyboardTypeNumberPad;
				break;
			case KEYBOARD_TYPE_EMAIL:
				textInput.secureTextEntry = NO;
				textInput.keyboardType = UIKeyboardTypeEmailAddress;
				break;
			case KEYBOARD_TYPE_PASSWORD:
				textInput.secureTextEntry = YES;
				textInput.keyboardType = UIKeyboardTypeDefault;
				break;
			default:
				textInput.secureTextEntry = NO;
				textInput.keyboardType = UIKeyboardTypeDefault;
		}
		if (textInput.focused)
		{
			[textInput refectKeyboard];
		}
	}
}

void SetAutoCapitalize(int id, Capitalize autoCapitalize)
{
	TextInputDelegate* textInput = g_TextInput.m_TextInputDelegates[id];
	if (textInput)
	{
		switch (autoCapitalize) {
			case CAPITALIZE_SENTENCES:
				textInput.autocapitalizationType = UITextAutocapitalizationTypeSentences;
				break;
			case CAPITALIZE_WORDS:
				textInput.autocapitalizationType = UITextAutocapitalizationTypeWords;
				break;
			case CAPITALIZE_CHARACTERS:
				textInput.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
				break;
			default:
				textInput.autocapitalizationType = UITextAutocapitalizationTypeNone;
		}
		if (textInput.focused)
		{
			[textInput refectKeyboard];
		}
	}
}

void SetReturnKeyType(int id, ReturnKeyType returnKeyType)
{
	TextInputDelegate* textInput = g_TextInput.m_TextInputDelegates[id];
	if (textInput)
	{
		switch (returnKeyType) {
			case RETURN_KEY_TYPE_DONE:
				textInput.returnKeyType = UIReturnKeyDone;
				break;
			case RETURN_KEY_TYPE_GO:
				textInput.returnKeyType = UIReturnKeyGo;
				break;
			case RETURN_KEY_TYPE_NEXT:
				textInput.returnKeyType = UIReturnKeyNext;
				break;
			case RETURN_KEY_TYPE_SEARCH:
				textInput.returnKeyType = UIReturnKeySearch;
				break;
			case RETURN_KEY_TYPE_SEND:
				textInput.returnKeyType = UIReturnKeySend;
				break;
			default:
				textInput.returnKeyType = UIReturnKeyDefault;
		}
		if (textInput.focused)
		{
			[textInput refectKeyboard];
		}
	}
}

const char* GetText(int id)
{
	NSString* return_value = "";
	return CopyString(return_value);
}

void Focus(int id)
{
	TextInputDelegate* textInput = g_TextInput.m_TextInputDelegates[id];
	if (textInput && !textInput.focused)
		if (g_TextInput.m_FocusingOn != -1)
		{
			TextInputDelegate* focusingTextInput = g_TextInput.m_TextInputDelegates[g_TextInput.m_FocusingOn];
			focusingTextInput.focused = NO;
		}
		[textInput setFocused:YES];
		g_TextInput.m_FocusingOn = id;
	}
}

void ClearFocus(int id)
{
	TextInputDelegate* textInput = g_TextInput.m_TextInputDelegates[id];
	if (textInput && textInput.focused)
	{
		[textInput setFocused:NO];
		g_TextInput.m_FocusingOn = -1;
	}
}

} // namespace
*/
#endif // DM_PLATFORM_IOS