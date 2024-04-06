#if defined(DM_PLATFORM_ANDROID)

#include <map>
#include <string.h>
#include <dmsdk/sdk.h>
#include <dmsdk/dlib/android.h>
#include "textinput_private.h"

namespace dmTextInput {

struct TextInput
{
	jobject            m_Instance;
	jmethodID          m_Create;
	jmethodID          m_Destroy;
	jmethodID          m_SetVisible;
	jmethodID          m_SetHint;
	jmethodID          m_SetHintTextColor;
	jmethodID          m_SetText;
	jmethodID          m_SetTextColor;
	jmethodID          m_SetTextSize;
	jmethodID          m_SetPosition;
	jmethodID          m_SetSize;
	jmethodID          m_SetMaxLength;
	jmethodID          m_SetKeyboardType;
	jmethodID          m_SetAutoCapitalize;
	jmethodID          m_SetReturnKeyType;
	jmethodID          m_GetText;
	jmethodID          m_Focus;
	jmethodID          m_ClearFocus;

	std::map<int,dmScript::LuaCallbackInfo*> m_Listeners;
	CommandQueue							 m_CommandQueue;
};

static TextInput g_TextInput;

static char* CopyString(JNIEnv* env, jstring s)
{
	const char* javastring = env->GetStringUTFChars(s, 0);
	char* copy = strdup(javastring);
	env->ReleaseStringUTFChars(s, javastring);
	return copy;
}

extern "C" {
	JNIEXPORT void JNICALL Java_com_defold_textinput_TextInputJNI_onSubmit(JNIEnv* env, jobject, jint id, jstring text)
	{
		Command cmd;
		cmd.m_Command = EVENT_ON_SUBMIT;
		cmd.m_Callback = g_TextInput.m_Listeners[id];
		cmd.m_Data = CopyString(env, text);
		Queue_Push(&g_TextInput.m_CommandQueue, &cmd);
	}
	JNIEXPORT void JNICALL Java_com_defold_textinput_TextInputJNI_onTextChanged(JNIEnv* env, jobject, jint id, jstring text)
	{
		Command cmd;
		cmd.m_Command = EVENT_ON_TEXT_CHANGED;
		cmd.m_Callback = g_TextInput.m_Listeners[id];
		cmd.m_Data = CopyString(env, text);
		Queue_Push(&g_TextInput.m_CommandQueue, &cmd);
	}
	JNIEXPORT void JNICALL Java_com_defold_textinput_TextInputJNI_onFocusChange(JNIEnv* env, jobject, jint id, jboolean hasFocus)
	{
		Command cmd;
		cmd.m_Command = EVENT_ON_FOCUS_CHANGE;
		cmd.m_Callback = g_TextInput.m_Listeners[id];
		cmd.m_Data = (bool)hasFocus ? (void*)"1" : (void*)"0";
		Queue_Push(&g_TextInput.m_CommandQueue, &cmd);
	}
}

void Initialize()
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	jclass cls = dmAndroid::LoadClass(env, "com.defold.textinput.TextInputJNI");

	jmethodID constructor = env->GetMethodID(cls, "<init>", "(Landroid/app/Activity;)V");
	g_TextInput.m_Instance = env->NewGlobalRef(env->NewObject(cls, constructor, threadAttacher.GetActivity()->clazz));

	g_TextInput.m_Create = env->GetMethodID(cls, "create", "(Z)I");
	g_TextInput.m_Destroy = env->GetMethodID(cls, "destroy", "(I)V");
	g_TextInput.m_SetVisible = env->GetMethodID(cls, "setVisible", "(IZ)V");
	g_TextInput.m_SetHint = env->GetMethodID(cls, "setHint", "(ILjava/lang/String;)V");
	g_TextInput.m_SetHintTextColor = env->GetMethodID(cls, "setHintTextColor", "(ILjava/lang/String;)V");
	g_TextInput.m_SetText = env->GetMethodID(cls, "setText", "(ILjava/lang/String;)V");
	g_TextInput.m_SetTextColor = env->GetMethodID(cls, "setTextColor", "(ILjava/lang/String;)V");
	g_TextInput.m_SetTextSize = env->GetMethodID(cls, "setTextSize", "(II)V");
	g_TextInput.m_SetPosition = env->GetMethodID(cls, "setPosition", "(III)V");
	g_TextInput.m_SetSize = env->GetMethodID(cls, "setSize", "(III)V");
	g_TextInput.m_SetMaxLength = env->GetMethodID(cls, "setMaxLength", "(II)V");
	g_TextInput.m_SetKeyboardType = env->GetMethodID(cls, "setKeyboardType", "(II)V");
	g_TextInput.m_SetAutoCapitalize = env->GetMethodID(cls, "setAutoCapitalize", "(II)V");
	g_TextInput.m_SetReturnKeyType = env->GetMethodID(cls, "setReturnKeyType", "(II)V");
	g_TextInput.m_GetText = env->GetMethodID(cls, "getText", "(I)Ljava/lang/String;");
	g_TextInput.m_Focus = env->GetMethodID(cls, "focus", "(I)V");
	g_TextInput.m_ClearFocus = env->GetMethodID(cls, "clearFocus", "(I)V");

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
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	int id = (int)env->CallIntMethod(g_TextInput.m_Instance, g_TextInput.m_Create, (jboolean)isHidden);
	g_TextInput.m_Listeners[id] = callback;

	return id;
}

void Destroy(int id)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_Destroy, id);
	dmScript::LuaCallbackInfo* callback = g_TextInput.m_Listeners[id];
	if (callback != 0)
	{
		dmScript::DestroyCallback(callback);
		g_TextInput.m_Listeners[id] = 0;
	}
}

void SetVisible(int id, bool visible)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_SetVisible, id, (jboolean)visible);
}

void SetHint(int id, const char* hint)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_SetHint, id, env->NewStringUTF(hint));
}

void SetHintTextColor(int id, const char* color)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_SetHintTextColor, id, env->NewStringUTF(color));
}

void SetText(int id, const char* text)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_SetText, id, env->NewStringUTF(text));
}

void SetTextColor(int id, const char* color)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_SetTextColor, id, env->NewStringUTF(color));
}

void SetTextSize(int id, int size)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_SetTextSize, id, size);
}

void SetPosition(int id, int x, int y)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_SetPosition, id, x, y);
}

void SetSize(int id, int width, int height)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_SetSize, id, width, height);
}

void SetMaxLength(int id, int maxLength)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_SetMaxLength, id, maxLength);
}

void SetKeyboardType(int id, KeyboardType keyboardType)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_SetKeyboardType, id, (int)keyboardType);
}

void SetAutoCapitalize(int id, Capitalize autoCapitalize)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_SetAutoCapitalize, id, (int)autoCapitalize);
}

void SetReturnKeyType(int id, ReturnKeyType returnKeyType)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_SetReturnKeyType, id, (int)returnKeyType);
}

const char* GetText(int id)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	jstring return_value = (jstring)env->CallObjectMethod(g_TextInput.m_Instance, g_TextInput.m_GetText, id);
	return CopyString(env, return_value);
}

void Focus(int id)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_Focus, id);
}

void ClearFocus(int id)
{
	dmAndroid::ThreadAttacher threadAttacher;
	JNIEnv* env = threadAttacher.GetEnv();

	env->CallVoidMethod(g_TextInput.m_Instance, g_TextInput.m_ClearFocus, id);
}

} // namespace

#endif // DM_PLATFORM_ANDROID