#define LIB_NAME "TextInput"
#define MODULE_NAME "textinput"

#include <dmsdk/sdk.h>
#include "textinput_private.h"

#if defined(DM_PLATFORM_ANDROID) || defined(DM_PLATFORM_IOS)

static int TextInput_Create(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 1);
	int hidden = lua_toboolean(L, 1);
	dmScript::LuaCallbackInfo* callback = dmScript::CreateCallback(L, 2);
	int id = dmTextInput::Create(hidden == 1, callback);
	lua_pushnumber(L, id);
	return 1;
}

static int TextInput_Destroy(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	dmTextInput::Destroy(id);
	return 0;
}

static int TextInput_SetVisible(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	int visible = lua_toboolean(L, 2);
	dmTextInput::SetVisible(id, visible == 1);
	return 0;
}

static int TextInput_SetHint(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	const char* hint = luaL_checkstring(L, 2);
	dmTextInput::SetHint(id, hint);
	return 0;
}

static int TextInput_SetHintTextColor(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	const char* color = luaL_checkstring(L, 2);
	dmTextInput::SetHintTextColor(id, color);
	return 0;
}

static int TextInput_SetText(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	const char* text = luaL_checkstring(L, 2);
	dmTextInput::SetText(id, text);
	return 0;
}

static int TextInput_SetTextColor(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	const char* color = luaL_checkstring(L, 2);
	dmTextInput::SetTextColor(id, color);
	return 0;
}

static int TextInput_SetTextSize(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	int size = luaL_checknumber(L, 2);
	dmTextInput::SetTextSize(id, size);
	return 0;
}

static int TextInput_SetPosition(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	int x = luaL_checknumber(L, 2);
	int y = luaL_checknumber(L, 3);
	dmTextInput::SetPosition(id, x, y);
	return 0;
}

static int TextInput_SetSize(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	int width = luaL_checknumber(L, 2);
	int height = luaL_checknumber(L, 3);
	dmTextInput::SetSize(id, width, height);
	return 0;
}

static int TextInput_SetMaxLength(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	int maxLength = luaL_checknumber(L, 2);
	dmTextInput::SetMaxLength(id, maxLength);
	return 0;
}

static int TextInput_SetKeyboardType(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	int keyboardType = luaL_checknumber(L, 2);
	dmTextInput::SetKeyboardType(id, (dmTextInput::KeyboardType)keyboardType);
	return 0;
}

static int TextInput_SetAutoCapitalize(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	int autoCapitalize = luaL_checknumber(L, 2);
	dmTextInput::SetAutoCapitalize(id, (dmTextInput::Capitalize)autoCapitalize);
	return 0;
}

static int TextInput_GetText(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 1);
	int id = luaL_checknumber(L, 1);
	const char* text = dmTextInput::GetText(id);
	lua_pushstring(L, text);
	return 1;
}

static int TextInput_Focus(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	dmTextInput::Focus(id);
	return 0;
}

static int TextInput_ClearFocus(lua_State* L)
{
	DM_LUA_STACK_CHECK(L, 0);
	int id = luaL_checknumber(L, 1);
	dmTextInput::ClearFocus(id);
	return 0;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] =
{
	{"create", TextInput_Create},
	{"destroy", TextInput_Destroy},
	{"set_visible", TextInput_SetVisible},
	{"set_hint", TextInput_SetHint},
	{"set_hint_text_color", TextInput_SetHintTextColor},
	{"set_text", TextInput_SetText},
	{"set_text_color", TextInput_SetTextColor},
	{"set_text_size", TextInput_SetTextSize},
	{"set_position", TextInput_SetPosition},
	{"set_size", TextInput_SetSize},
	{"set_max_length", TextInput_SetMaxLength},
	{"set_keyboard_type", TextInput_SetKeyboardType},
	{"set_auto_capitalize", TextInput_SetAutoCapitalize},
	{"get_text", TextInput_GetText},
	{"focus", TextInput_Focus},
	{"clear_focus", TextInput_ClearFocus},
	{0, 0}
};

static void LuaInit(lua_State* L)
{
	int top = lua_gettop(L);

	// Register lua names
	luaL_register(L, MODULE_NAME, Module_methods);

#define SETKEYBOARD(name) \
	lua_pushnumber(L, (lua_Number) dmTextInput::KEYBOARD_TYPE_##name); \
	lua_setfield(L, -2, "KEYBOARD_TYPE_"#name);\

	SETKEYBOARD(DEFAULT)
	SETKEYBOARD(NUMBER_PAD)
	SETKEYBOARD(EMAIL)
	SETKEYBOARD(PASSWORD)
#undef SETKEYBOARD

#define SETCAPITALIZE(name) \
	lua_pushnumber(L, (lua_Number) dmTextInput::CAPITALIZE_##name); \
	lua_setfield(L, -2, "CAPITALIZE_"#name);\

	SETCAPITALIZE(NONE)
	SETCAPITALIZE(SENTENCES)
	SETCAPITALIZE(WORDS)
	SETCAPITALIZE(CHARACTERS)
#undef SETCAPITALIZE

#define SETEVENT(name) \
	lua_pushnumber(L, (lua_Number) dmTextInput::EVENT_##name); \
	lua_setfield(L, -2, "EVENT_"#name);\

	SETEVENT(ON_SUBMIT)
	SETEVENT(ON_TEXT_CHANGED)
	SETEVENT(ON_FOCUS_CHANGE)
#undef SETCAPITALIZE

	lua_pop(L, 1);
	assert(top == lua_gettop(L));
}

dmExtension::Result AppInitializeTextInput(dmExtension::AppParams* params)
{
	return dmExtension::RESULT_OK;
}

dmExtension::Result InitializeTextInput(dmExtension::Params* params)
{
	// Init Lua
	LuaInit(params->m_L);
	dmTextInput::Initialize();
	printf("Registered %s Extension\n", MODULE_NAME);
	return dmExtension::RESULT_OK;
}

dmExtension::Result UpdateTextInput(dmExtension::Params* params)
{
	dmTextInput::Update();
	return dmExtension::RESULT_OK;
}

dmExtension::Result AppFinalizeTextInput(dmExtension::AppParams* params)
{
	return dmExtension::RESULT_OK;
}

dmExtension::Result FinalizeTextInput(dmExtension::Params* params)
{
	dmTextInput::Finalize();
	return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(TextInput, LIB_NAME, AppInitializeTextInput, AppFinalizeTextInput, InitializeTextInput, UpdateTextInput, 0, FinalizeTextInput)

#else

static  dmExtension::Result InitializeTextInput(dmExtension::Params* params)
{
	dmLogInfo("Registered extension TextInput (null)");
	return dmExtension::RESULT_OK;
}

static dmExtension::Result FinalizeTextInput(dmExtension::Params* params)
{
	return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(TextInput, LIB_NAME, 0, 0, InitializeTextInput, 0, 0, FinalizeTextInput)

#endif