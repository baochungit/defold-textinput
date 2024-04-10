#pragma once

#include <dmsdk/sdk.h>

namespace dmTextInput {

enum KeyboardType
{
	KEYBOARD_TYPE_DEFAULT,
	KEYBOARD_TYPE_NUMBER_PAD,
	KEYBOARD_TYPE_EMAIL,
	KEYBOARD_TYPE_PASSWORD,
};

enum Capitalize
{
	CAPITALIZE_NONE,
	CAPITALIZE_SENTENCES,
	CAPITALIZE_WORDS,
	CAPITALIZE_CHARACTERS,
};

enum ReturnKeyType
{
	RETURN_KEY_TYPE_DONE,
	RETURN_KEY_TYPE_GO,
	RETURN_KEY_TYPE_NEXT,
	RETURN_KEY_TYPE_SEARCH,
	RETURN_KEY_TYPE_SEND,
};

enum Event
{
	EVENT_ON_SUBMIT,
	EVENT_ON_TEXT_CHANGED,
	EVENT_ON_FOCUS_CHANGE,
};

extern void Initialize(dmExtension::Params* params);
extern void Update();
extern void Finalize();
extern int Create(bool isHidden, dmScript::LuaCallbackInfo* callback);
extern void Destroy(int id);
extern void SetVisible(int id, bool visible);
extern void SetHint(int id, const char* hint);
extern void SetHintTextColor(int id, const char* color);
extern void SetText(int id, const char* text);
extern void SetTextColor(int id, const char* color);
extern void SetTextSize(int id, int size);
extern void SetPosition(int id, int x, int y);
extern void SetSize(int id, int width, int height);
extern void SetMaxLength(int id, int maxLength);
extern void SetKeyboardType(int id, KeyboardType keyboardType);
extern void SetAutoCapitalize(int id, Capitalize autoCapitalize);
extern void SetReturnKeyType(int id, ReturnKeyType returnKeyType);
extern const char* GetText(int id);
extern void Focus(int id);
extern void ClearFocus(int id);

// Command Queue
struct DM_ALIGNED(16) Command
{
	Command()
	{
		memset(this, 0, sizeof(Command));
	}

	// Used for storing eventual callback info (if needed)
	dmScript::LuaCallbackInfo* m_Callback;

	// The actual command payload
	int32_t  	m_Command;
	void*    	m_Data;
};

struct CommandQueue
{
	dmArray<Command>  m_Commands;
	dmMutex::HMutex      m_Mutex;
};

inline void Queue_Create(CommandQueue* queue)
{
	queue->m_Mutex = dmMutex::New();
}

inline void Queue_Destroy(CommandQueue* queue)
{
	dmMutex::Delete(queue->m_Mutex);
}

inline void Queue_Push(CommandQueue* queue, Command* cmd)
{
	DM_MUTEX_SCOPED_LOCK(queue->m_Mutex);

	if(queue->m_Commands.Full())
	{
		queue->m_Commands.OffsetCapacity(2);
	}
	queue->m_Commands.Push(*cmd);
}

} // namespace
