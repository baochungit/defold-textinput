#if defined(DM_PLATFORM_HTML5)

#include <map>
#include <string.h>
#include <dmsdk/sdk.h>
#include <emscripten.h>
#include "textinput_private.h"

namespace dmTextInput {

struct TextInput
{
	std::map<int,dmScript::LuaCallbackInfo*> m_Listeners;
	CommandQueue							 m_CommandQueue;
};

static TextInput g_TextInput;

typedef void (*OnAddToCommandQueue)(int id, int eventName, const char* value);
static void AddToCommandQueue(int id, int eventName, const char* value)
{
	if (eventName == EVENT_ON_TEXT_CHANGED || eventName == EVENT_ON_SUBMIT) {
		Command cmd;
		cmd.m_Command = eventName;
		cmd.m_Callback = g_TextInput.m_Listeners[id];
		cmd.m_Data = strdup(value);
		Queue_Push(&g_TextInput.m_CommandQueue, &cmd);
	} else if (eventName == EVENT_ON_FOCUS_CHANGE) {
		Command cmd;
		cmd.m_Command = eventName;
		cmd.m_Callback = g_TextInput.m_Listeners[id];
		cmd.m_Data = (void*)strdup(value);
		Queue_Push(&g_TextInput.m_CommandQueue, &cmd);
	}
}


extern "C" int JS_TextInput_initialize();
extern "C" int JS_TextInput_create(int isHidden, OnAddToCommandQueue f);
extern "C" void JS_TextInput_remove(int id);
extern "C" void JS_TextInput_setVisible(int id, bool visible);
extern "C" void JS_TextInput_setHint(int id, const char* hint);
extern "C" void JS_TextInput_setHintTextColor(int id, const char* color);
extern "C" void JS_TextInput_setText(int id, const char* text);
extern "C" void JS_TextInput_setTextColor(int id, const char* color);
extern "C" void JS_TextInput_setTextSize(int id, int size);
extern "C" void JS_TextInput_setPosition(int id, int x, int y);
extern "C" void JS_TextInput_setSize(int id, int width, int height);
extern "C" void JS_TextInput_setMaxLength(int id, int maxLength);
extern "C" void JS_TextInput_setKeyboardType(int id, int keyboardType);
extern "C" void JS_TextInput_setAutoCapitalize(int id, int autoCapitalize);
extern "C" void JS_TextInput_setReturnKeyType(int id, int returnKeyType);
extern "C" const char* JS_TextInput_getText(int id);
extern "C" void JS_TextInput_focus(int id);
extern "C" void JS_TextInput_clearFocus(int id);


void Initialize(dmExtension::Params* params)
{
	JS_TextInput_initialize();
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
	int id = JS_TextInput_create(isHidden, (OnAddToCommandQueue)AddToCommandQueue);
	g_TextInput.m_Listeners[id] = callback;

	return id;
}

void Destroy(int id)
{
	JS_TextInput_remove(id);
	dmScript::LuaCallbackInfo* callback = g_TextInput.m_Listeners[id];
	if (callback != 0)
	{
		dmScript::DestroyCallback(callback);
		g_TextInput.m_Listeners[id] = 0;
	}
}

void SetVisible(int id, bool visible)
{
	JS_TextInput_setVisible(id, visible);
}

void SetHint(int id, const char* hint)
{
	JS_TextInput_setHint(id, hint);
}

void SetHintTextColor(int id, const char* color)
{
	JS_TextInput_setHintTextColor(id, color);
}

void SetText(int id, const char* text)
{
	JS_TextInput_setText(id, text);
}

void SetTextColor(int id, const char* color)
{
	JS_TextInput_setTextColor(id, color);
}

void SetTextSize(int id, int size)
{
	JS_TextInput_setTextSize(id, size);
}

void SetPosition(int id, int x, int y)
{
	JS_TextInput_setPosition(id, x, y);
}

void SetSize(int id, int width, int height)
{
	JS_TextInput_setSize(id, width, height);
}

void SetMaxLength(int id, int maxLength)
{
	JS_TextInput_setMaxLength(id, maxLength);
}

void SetKeyboardType(int id, KeyboardType keyboardType)
{
	JS_TextInput_setKeyboardType(id, (int)keyboardType);
}

void SetAutoCapitalize(int id, Capitalize autoCapitalize)
{
	JS_TextInput_setAutoCapitalize(id, (int)autoCapitalize);
}

void SetReturnKeyType(int id, ReturnKeyType returnKeyType)
{
	JS_TextInput_setReturnKeyType(id, (int)returnKeyType);
}

const char* GetText(int id)
{
	return JS_TextInput_getText(id);
}

void Focus(int id)
{
	JS_TextInput_focus(id);
}

void ClearFocus(int id)
{
	JS_TextInput_clearFocus(id);
}

} // namespace

#endif // DM_PLATFORM_HTML5