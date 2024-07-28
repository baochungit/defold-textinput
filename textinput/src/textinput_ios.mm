#if defined(DM_PLATFORM_IOS)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include <map>
#include <string.h>
#include "textinput_private.h"


@class CTextInputHandler;
struct TextInput
{
	TextInput()
	{
		m_IdIncr = 0;
		m_FocusingOn = -1;
	}

	int m_IdIncr;
	int m_FocusingOn;
	std::map<int,CTextInputHandler*>		 m_TextInputs;
	std::map<int,dmScript::LuaCallbackInfo*> m_Listeners;
	dmTextInput::CommandQueue				 m_CommandQueue;
};

static TextInput g_TextInput;

static char* CopyString(NSString* s)
{
	const char* osstring = [s UTF8String];
	char* copy = strdup(osstring);
	return copy;
}


@interface CTextInputHandler : NSObject<UITextFieldDelegate>

@property (nonatomic, assign) BOOL isHidden;
@property (nonatomic, assign) BOOL isFocused;
@property (nonatomic, assign) int maximumLength;
@property (nonatomic, assign) NSString* placeholderText;
@property (nonatomic, assign) NSString* placeholderTextColor;

- (void)initialize:(int)id isHidden:(BOOL)hidden;
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
- (void)setHintText:(NSString*)text;
- (void)setHintTextColor:(NSString*)value;
- (void)setTextColor:(NSString*)value;
- (void)setTextSize:(int)value;
- (void)destroy;

@end


@implementation CTextInputHandler{
	UITextField* _field;
}

- (void)initialize:(int)id isHidden:(BOOL)hidden
{
	_field = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
	[_field addTarget:self action:@selector(onTextChanged:) forControlEvents:UIControlEventEditingChanged];
	[_field addTarget:self action:@selector(onFocused:) forControlEvents:UIControlEventEditingDidBegin];
	[_field addTarget:self action:@selector(onUnfocused:) forControlEvents:UIControlEventEditingDidEnd];
	[_field addTarget:self action:@selector(onSubmit:) forControlEvents:UIControlEventEditingDidEndOnExit];
	_field.delegate = self;
	UIView * topView = [[[[UIApplication sharedApplication] keyWindow] rootViewController] view];
	[topView addSubview:_field];

	_field.tag = id;

	self.isHidden = hidden;
	self.isFocused = NO;
	self.placeholderText = @"";
	self.placeholderTextColor = @"#000000";
	self.maximumLength = -1;

	UIReturnKeyType returnKeyType = self.isHidden ? UIReturnKeyDone : UIReturnKeyDefault;
	[self setKeyboardType:UIKeyboardTypeDefault];
	[self setAutocapitalizationType:UITextAutocapitalizationTypeNone];
	[self setReturnKeyType:returnKeyType];
	[self setSecureTextEntry:NO];
	[self setVisible:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
	NSString *str = textField.text;
	str = [str stringByReplacingCharactersInRange:range withString:string];
	return (self.maximumLength != -1 && str.length > self.maximumLength) ? NO : YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField{
	return true;
}

- (void)onTextChanged:(UITextField*)textField
{
	dmTextInput::Command cmd;
	cmd.m_Command = dmTextInput::EVENT_ON_TEXT_CHANGED;
	cmd.m_Callback = g_TextInput.m_Listeners[textField.tag];
	cmd.m_Data = CopyString(_field.text);
	dmTextInput::Queue_Push(&g_TextInput.m_CommandQueue, &cmd);
}

- (void)onFocused:(UITextField*)textField
{
	dmTextInput::Command cmd;
	cmd.m_Command = dmTextInput::EVENT_ON_FOCUS_CHANGE;
	cmd.m_Callback = g_TextInput.m_Listeners[textField.tag];
	cmd.m_Data = (void*)"1";
	dmTextInput::Queue_Push(&g_TextInput.m_CommandQueue, &cmd);
}

- (void)onUnfocused:(UITextField*)textField
{
	dmTextInput::Command cmd;
	cmd.m_Command = dmTextInput::EVENT_ON_FOCUS_CHANGE;
	cmd.m_Callback = g_TextInput.m_Listeners[textField.tag];
	cmd.m_Data = (void*)"0";
	dmTextInput::Queue_Push(&g_TextInput.m_CommandQueue, &cmd);
}

- (void)onSubmit:(UITextField*)textField
{
	dmTextInput::Command cmd;
	cmd.m_Command = dmTextInput::EVENT_ON_SUBMIT;
	cmd.m_Callback = g_TextInput.m_Listeners[textField.tag];
	cmd.m_Data = CopyString(_field.text);
	dmTextInput::Queue_Push(&g_TextInput.m_CommandQueue, &cmd);
	[_field resignFirstResponder];
}

- (void)setSecureTextEntry:(BOOL)value
{
	_field.secureTextEntry = value;
}

- (void)setKeyboardType:(UIKeyboardType)type
{
	_field.keyboardType = type;
}

- (void)setAutocapitalizationType:(UITextAutocapitalizationType)type
{
	_field.autocapitalizationType = type;
}

- (void)setReturnKeyType:(UIReturnKeyType)type
{
	_field.returnKeyType = type;
}

- (void)setFocused:(BOOL)value
{
	if (!_field.hidden)
	{
		if (value)
		{
			[_field becomeFirstResponder];
			g_TextInput.m_FocusingOn = _field.tag;
		} else {
			[_field resignFirstResponder];
			if (self.isFocused)
			{
				g_TextInput.m_FocusingOn = -1;
			}
		}
		self.isFocused = value;
	}
}

- (void)setVisible:(BOOL)value
{
	if (!value && self.isFocused)
	{
		[self setFocused:NO];
	}
	_field.hidden = !value;
}

- (void)setMaxLength:(int)value
{
	self.maximumLength = value;
}

- (void)setFrame:(CGRect)frame
{
	if (self.isHidden) return;
	_field.frame = frame;
}

- (CGRect)getFrame
{
	return _field.frame;
}

- (void)setText:(NSString*)text
{
	_field.text = text;
}

- (NSString*)getText
{
	return _field.text;
}

- (void)setHintText:(NSString*)text
{
	self.placeholderText = text;
	NSString* textColor = self.placeholderTextColor;
	UIColor* color = [self colorFromHexString:textColor];
	_field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName: color}];
}

- (void)setHintTextColor:(NSString*)value
{
	self.placeholderTextColor = value;
	UIColor* color = [self colorFromHexString:value];
	NSString* text = self.placeholderText;
	_field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName: color}];
}

- (void)setTextColor:(NSString*)value
{
	UIColor* color = [self colorFromHexString:value];
	_field.textColor = color;
}

- (void)setTextSize:(int)value
{
	CGFloat fontSize = (float)value;
	UIFont* font = [_field.font fontWithSize:fontSize];
	_field.font = font;
}

- (void)destroy
{
	if (self.isFocused)
	{
		[self setFocused:NO];
	}
	[_field removeFromSuperview];
	[_field release];
}

- (nullable UIColor *)colorFromHex:(NSUInteger)hex {
	unsigned char r, g, b;
	if (hex & ~0xffffffUL) return nil;
	r = (unsigned char) (hex >> 16);
	g = (unsigned char) (hex >> 8);
	b = (unsigned char) hex;
	return [UIColor colorWithRed:(CGFloat) r / 0xff
							green:(CGFloat) g / 0xff
							blue:(CGFloat) b / 0xff
							alpha:1.0];
}

- (nullable UIColor *)colorFromHexString:(nonnull NSString *)hexString {
	unsigned int hex = 0;
	if (hexString == nil) return nil;
	if ([hexString hasPrefix:@"#"]) {
		hexString = [hexString substringFromIndex:1];
	}
	if ([[NSScanner scannerWithString:hexString] scanHexInt:&hex]) {
		return [self colorFromHex:hex];
	}
	return nil;
}

@end


namespace dmTextInput {

	void Initialize(dmExtension::Params* params)
	{
		Queue_Create(&g_TextInput.m_CommandQueue);
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
		CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
		if (textInput && !textInput.isHidden)
		{
			NSString* t = [NSString stringWithUTF8String:hint];
			[textInput setHintText:t];
		}
	}

	void SetHintTextColor(int id, const char* color)
	{
		CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
		if (textInput && !textInput.isHidden)
		{
			NSString* s = [NSString stringWithUTF8String:color];
			[textInput setHintTextColor:s];
		}
	}

	void SetText(int id, const char* text)
	{
		CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
		if (textInput)
		{
			NSString* t = [NSString stringWithUTF8String:text];
			[textInput setText:t];
		}
	}

	void SetTextColor(int id, const char* color)
	{
		CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
		if (textInput && !textInput.isHidden)
		{
			NSString* s = [NSString stringWithUTF8String:color];
			[textInput setTextColor:s];
		}
	}

	void SetTextSize(int id, int size)
	{
		CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
		if (textInput && !textInput.isHidden)
		{
			[textInput setTextSize:size];
		}
	}

	void SetPosition(int id, int x, int y)
	{
		CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
		if (textInput && !textInput.isHidden)
		{
			UIView* glview = (UIView*)dmGraphics::GetNativeiOSUIView();
			CGRect screenRect = glview.frame;
			CGFloat scale = glview.layer.contentsScale;
			CGRect frame = [textInput getFrame];
			frame.origin.x = screenRect.origin.x + (x / scale);
			frame.origin.y = screenRect.origin.y + (y / scale);
			[textInput setFrame:frame];
		}
	}

	void SetSize(int id, int width, int height)
	{
		CTextInputHandler* textInput = g_TextInput.m_TextInputs[id];
		if (textInput && !textInput.isHidden)
		{
			UIView* glview = (UIView*)dmGraphics::GetNativeiOSUIView();
			CGFloat scale = glview.layer.contentsScale;
			CGRect frame = [textInput getFrame];
			frame.size.width = width / scale;
			frame.size.height = height / scale;
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
		if (textInput && !textInput.isFocused)
		{
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
		if (textInput && textInput.isFocused)
		{
			[textInput setFocused:NO];
		}
	}

} // namespace

#endif // DM_PLATFORM_IOS