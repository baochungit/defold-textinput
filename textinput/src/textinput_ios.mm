#if defined(DM_PLATFORM_IOS)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "textinput_private.h"


struct TextInput
{
	TextInput
	{
		m_IdIncr = 0;
		m_FocusingOn = -1;
	}

	int m_IdIncr;
	int m_FocusingOn;
	std::map<int,CTextInputHandler*>		 m_TextInputs;
	std::map<int,dmScript::LuaCallbackInfo*> m_Listeners;
	CommandQueue							 m_CommandQueue;
};

static TextInput g_TextInput;

static char* CopyString(NSString* s)
{
	const char* osstring = [s UTF8String];
	char* copy = strdup(osstring);
	return copy;
}


@interface CTextInputHandler : NSObject<UITextFieldDelegate>

UITextField view;
@property (nonatomic, assign) int id;
@property (nonatomic, assign) BOOL isHidden;
@property (nonatomic, assign) BOOL focused;
@property (nonatomic, assign) int maxLength;

- (void)initialize:(int)id isHidden:(BOOL)hidden;
- (void)onTexChanged;
- (void)onFocused;
- (void)onUnfocused;
- (void)onSubmit;
- (void)setSecureTextEntry:(BOOL)value;
- (void)setKeyboardType:(UIKeyboardType)type;
- (void)setAutocapitalizationType:(UITextAutocapitalizationType)type;
- (void)setReturnKeyType:(UIReturnKeyType)type;
- (void)setFocused:(BOOL)value;
- (void)setVisible:(BOOL)value;
- (void)setMaxLength:(int)value;
- (void)setFrame:(CGRect)frame;
- (CGRect)getFrame;
- (void)setText:(NSString*)text;
- (NSString*)getText;
- (void)destroy;

@end

@implementation CTextInputHandler

- (void)initialize:(int)id isHidden:(BOOL)hidden
{
	self.view = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
	[view addTarget:self action:@selector(onTexChanged) forControlEvents:UIControlEventEditingChanged];
	[view addTarget:self action:@selector(onFocused) forControlEvents:UIControlEventEditingDidBegin];
	[view addTarget:self action:@selector(onUnfocused) forControlEvents:UIControlEventEditingDidEnd];
	[view addTarget:self action:@selector(onSubmit) forControlEvents:UIControlEventEditingDidEndOnExit];
	self.view.delegate = self;

	self.id = id;
	self.isHidden = hidden;
	self.focused = NO;
	self.maxLength = -1;

	UIReturnKeyType returnKeyType = self.isHidden ? UIReturnKeyDone : UIReturnKeyDefault;
	[self setKeyboardType:UIKeyboardTypeDefault];
	[self setAutocapitalizationType:UITextAutocapitalizationTypeNone];
	[self setReturnKeyType:returnKeyType];
	[self setSecureTextEntry:NO];
	[self setVisible:YES];
}

- (BOOL)textField:(UITextField *)view shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    NSUInteger newLength = [view.text length] + [string length] - range.length;
    return (maxLength != -1 && newLength > maxLength) ? NO : YES;
}

- (void)onTexChanged
{
	NSLog(@"text changed: %@", self.view.text);
	Command cmd;
	cmd.m_Command = EVENT_ON_TEXT_CHANGED;
	cmd.m_Callback = g_TextInput.m_Listeners[self.id];
	cmd.m_Data = CopyString(self.view.text);
	dmTextInput::Queue_Push(&g_TextInput.m_CommandQueue, &cmd);
}

- (void)onFocused
{
	Command cmd;
	cmd.m_Command = EVENT_ON_FOCUS_CHANGE;
	cmd.m_Callback = g_TextInput.m_Listeners[self.id];
	cmd.m_Data = (void*)"1";
	dmTextInput::Queue_Push(&g_TextInput.m_CommandQueue, &cmd);
}

- (void)onUnfocused
{
	Command cmd;
	cmd.m_Command = EVENT_ON_FOCUS_CHANGE;
	cmd.m_Callback = g_TextInput.m_Listeners[self.id];
	cmd.m_Data = (void*)"0";
	dmTextInput::Queue_Push(&g_TextInput.m_CommandQueue, &cmd);
}

- (void)onSubmit
{
	Command cmd;
	cmd.m_Command = EVENT_ON_SUBMIT;
	cmd.m_Callback = g_TextInput.m_Listeners[self.id];
	cmd.m_Data = CopyString(self.view.text);
	dmTextInput::Queue_Push(&g_TextInput.m_CommandQueue, &cmd);
	[view resignFirstResponder];
}

- (void)setSecureTextEntry:(BOOL)value
{
	self.view.secureTextEntry = value;
}

- (void)setKeyboardType:(UIKeyboardType)type
{
	self.view.keyboardType = type;
}

- (void)setAutocapitalizationType:(UITextAutocapitalizationType)type
{
	self.view.autocapitalizationType = type;
}

- (void)setReturnKeyType:(UIReturnKeyType)type
{
	self.view.returnKeyType = type;
}

- (void)setFocused:(BOOL)value
{
	if (!self.view.hidden)
	{
		if (value)
		{
			[view becomeFirstResponder];
			g_TextInput.m_FocusingOn = self.id;
		} else {
			[view resignFirstResponder];
			if (self.focused)
			{
				g_TextInput.m_FocusingOn = -1;
			}
		}
		self.focused = value;
	}
}

- (void)setVisible:(BOOL)value
{
	if (!value && self.focused)
	{
		[self setFocused:NO];
	}
	self.view.hidden = !value;
}

- (void)setMaxLength:(int)value
{
	maxLength = value;
}

- (void)setFrame:(CGRect)frame
{
	if (self.isHidden) return;
	self.view.frame = frame;
}

- (CGRect)getFrame
{
	if (self.isHidden) return NULL;
	return self.view.frame;
}

- (void)setText:(NSString*)text
{
	self.view.text = text;
}

- (NSString*)getText
{
	return self.view.text;
}

- (void)destroy
{
	if (self.focused)
	{
		[self setFocused:NO];
	}
	[view removeFromSuperview];
    [view release];
}

@end


namespace dmTextInput {

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
	CTextInputHandler* textInput = [[CTextInputHandler alloc] init];
	BOOL hidden = isHidden ? YES : NO;
	[textInput initialize:id isHidden:hidden];
	g_TextInput.m_TextInputs[id] = textInput;
	g_TextInput.m_Listeners[id] = callback;

	return id;
}

void Destroy(int id)
{
	CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
	if (textInput)
	{
		[textInput destroy];
	}
	g_TextInput.m_TextInputs[id] = NULL;
	dmScript::LuaCallbackInfo* callback = g_TextInput.m_Listeners[id];
	if (callback != 0)
	{
		dmScript::DestroyCallback(callback);
		g_TextInput.m_Listeners[id] = 0;
	}
}

void SetVisible(int id, bool visible)
{
	CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
	if (textInput)
	{
		BOOL value = visible ? YES : NO;
		[textInput setVisible:value];
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
	NSString* t = [NSString stringWithUTF8String:text];
	[textInput setText:t]
}

void SetTextColor(int id, const char* color)
{
}

void SetTextSize(int id, int size)
{
}

void SetPosition(int id, int x, int y)
{
	CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
	if (textInput && !textInput.isHidden)
	{
		CGRect frame = [textInput getFrame];
		frame.origin.x = x;
		frame.origin.y = y;
		[textInput setFrame:frame];
	}
}

void SetSize(int id, int width, int height)
{
	CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
	if (textInput && !textInput.isHidden)
	{
		CGRect frame = [textInput getFrame];
		frame.size.width = width;
		frame.size.height = height;
		[textInput setFrame:frame];
	}
}

void SetMaxLength(int id, int maxLength)
{
	CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
	if (textInput)
	{
		[textInput setMaxLength:maxLength];
	}
}

void SetKeyboardType(int id, KeyboardType keyboardType)
{
	CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
	if (textInput)
	{
		switch (keyboardType) {
			case KEYBOARD_TYPE_NUMBER_PAD:
				[textInput setSecureTextEntry:NO];
				[textInput setKeyboardType:UIKeyboardTypeNumberPad];
				break;
			case KEYBOARD_TYPE_EMAIL:
				[textInput setSecureTextEntry:NO];
				[textInput setKeyboardType:UIKeyboardTypeEmailAddress];
				break;
			case KEYBOARD_TYPE_PASSWORD:
				[textInput setSecureTextEntry:YES];
				[textInput setKeyboardType:UIKeyboardTypeDefault];
				break;
			default:
				[textInput setSecureTextEntry:NO];
				[textInput setKeyboardType:UIKeyboardTypeDefault];
		}
	}
}

void SetAutoCapitalize(int id, Capitalize autoCapitalize)
{
	CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
	if (textInput)
	{
		switch (autoCapitalize) {
			case CAPITALIZE_SENTENCES:
				[textInput setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
				break;
			case CAPITALIZE_WORDS:
				[textInput setAutocapitalizationType:UITextAutocapitalizationTypeWords];
				break;
			case CAPITALIZE_CHARACTERS:
				[textInput setAutocapitalizationType:UITextAutocapitalizationTypeAllCharacters];
				break;
			default:
				[textInput setAutocapitalizationType:UITextAutocapitalizationTypeNone];
		}
	}
}

void SetReturnKeyType(int id, ReturnKeyType returnKeyType)
{
	CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
	if (textInput)
	{
		switch (returnKeyType) {
			case RETURN_KEY_TYPE_DONE:
				[textInput setReturnKeyType:UIReturnKeyDone];
				break;
			case RETURN_KEY_TYPE_GO:
				[textInput setReturnKeyType:UIReturnKeyGo];
				break;
			case RETURN_KEY_TYPE_NEXT:
				[textInput setReturnKeyType:UIReturnKeyNext];
				break;
			case RETURN_KEY_TYPE_SEARCH:
				[textInput setReturnKeyType:UIReturnKeySearch];
				break;
			case RETURN_KEY_TYPE_SEND:
				[textInput setReturnKeyType:UIReturnKeySend];
				break;
			default:
				[textInput setReturnKeyType:UIReturnKeyDefault];
		}
	}
}

const char* GetText(int id)
{
	CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
	if (textInput)
	{
		NSString* text = [textInput getText];
		return CopyString(text);
	}
	return NULL;
}

void Focus(int id)
{
	CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
	if (textInput && !textInput.focused)
		if (g_TextInput.m_FocusingOn != -1)
		{
			CTextInputHandler* focusingTextInput = g_TextInput.m_TextInputs[g_TextInput.m_FocusingOn];
			[textInput setFocused:NO];
		}
		[textInput setFocused:YES];
	}
}

void ClearFocus(int id)
{
	CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
	if (textInput && textInput.focused)
	{
		[textInput setFocused:NO];
	}
}

} // namespace

#endif // DM_PLATFORM_IOS