package com.defold.textinput;

import android.app.Activity;
import android.content.Context;
import android.view.View;
import android.view.Gravity;
import android.view.MotionEvent;
import android.widget.EditText;
import android.widget.TextView;
import android.view.KeyEvent;
import android.view.WindowManager;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.graphics.PixelFormat;
import android.util.Log;
import android.widget.FrameLayout;
import android.graphics.Color;
import android.text.Editable;
import android.text.InputFilter;
import android.text.InputType;
import android.text.TextWatcher;
import android.view.inputmethod.InputMethodManager;
import android.view.inputmethod.EditorInfo;
import android.os.Build;

import java.util.ArrayList;
import java.util.concurrent.*;


/**
 */
public class TextInputJNI {
  public enum KeyboardType {
    DEFAULT,
    NUMBER_PAD,
    EMAIL,
    PASSWORD;
  }

  public enum Capitalize {
    NONE,
    SENTENCES,
    WORDS,
    CHARACTERS;
  }

  public enum ReturnKeyType {
    DONE,
    GO,
    NEXT,
    SEARCH,
    SEND;
  }

  private class EditTextInfo {
    EditText                    editText;
    FrameLayout.LayoutParams    params;
    KeyboardType                keyboardType;
    Capitalize                  autoCapitalize;
    boolean                     isHidden;
    int                         id;
  };

  private Activity mActivity;
  private ArrayList<EditTextInfo> mList;
  private WindowManager.LayoutParams layoutMasterParams;
  private FrameLayout mLayoutMaster;
  private FrameLayout mLayout1;
  private FrameLayout mLayout2;
  private int idIncr = 0;

  public native void onSubmit(int id, String text);
  public native void onTextChanged(int id, String text);
  public native void onFocusChange(int id, boolean hasFocus);

  public TextInputJNI(Activity activity) {
    mActivity = activity;
    mList = new ArrayList<EditTextInfo>();
  }

  public int create(boolean isHidden) {
    int id = idIncr++;
    final TextInputJNI self = this;
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditText editText = new EditText(mActivity);
        editText.setBackgroundResource(android.R.color.transparent);
        editText.setInputType(InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS);
        editText.addTextChangedListener(new TextWatcher() {
          public void afterTextChanged(Editable s) {}
          public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
          public void onTextChanged(CharSequence s, int start, int before, int count) {
            self.onTextChanged(id, s.toString());
          }
        });
        editText.setOnEditorActionListener(new EditText.OnEditorActionListener() {
           @Override
           public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
             if (actionId == EditorInfo.IME_ACTION_DONE || actionId == EditorInfo.IME_ACTION_SEND || actionId == EditorInfo.IME_ACTION_SEARCH || actionId == EditorInfo.IME_ACTION_GO) {
                self.onSubmit(id, editText.getText().toString());
             }
             return false;
           }
         });
        editText.setOnFocusChangeListener(new EditText.OnFocusChangeListener() {
          @Override
          public void onFocusChange(View view, boolean hasFocus) {
            self.onFocusChange(id, hasFocus);
          }
        });

        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(300, 150);
        params.gravity = Gravity.TOP | Gravity.LEFT;
        params.setMargins(0, 0, 0, 0);
        editText.setLayoutParams(params);
        editText.setVisibility(isHidden ? View.VISIBLE : View.GONE);
        if (isHidden) {
          editText.setImeOptions(EditorInfo.IME_ACTION_DONE);
        }

        getLayout(isHidden).addView(editText, params);

        EditTextInfo info = new EditTextInfo();
        info.editText = editText;
        info.params = params;
        info.id = id;
        info.isHidden = isHidden;
        mList.add(info);
      }
    });
    return id;
  }

  public void destroy(int id) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          FrameLayout layout = (FrameLayout)info.editText.getParent();
          layout.removeView(info.editText);
          if (!info.isHidden && layout.getChildCount() == 0) {
            mLayoutMaster.removeView(layout);
            mLayout2 = null;
            refreshLayoutMaster();
          }
          mList.set(id, null);
        }
      }
    });
  }

  public void setVisible(int id, boolean visible) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          info.editText.setVisibility(visible ? View.VISIBLE : View.GONE);
        }
      }
    });
  }

  public void setHint(int id, String hint) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          info.editText.setHint(hint);
        }
      }
    });
  }

  public void setHintTextColor(int id, String color) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          info.editText.setHintTextColor(Color.parseColor(color));
        }
      }
    });
  }

  public void setText(int id, String text) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          info.editText.setText(text);
          info.editText.setSelection(info.editText.getText().length());
        }
      }
    });
  }

  public void setTextColor(int id, String color) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          info.editText.setTextColor(Color.parseColor(color));
        }
      }
    });
  }

  public void setTextSize(int id, int size) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          info.editText.setTextSize((float)size);
        }
      }
    });
  }

  public void setPosition(int id, int x, int y) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          info.params.leftMargin = x;
          info.params.topMargin = y;
          info.editText.setLayoutParams(info.params);
        }
      }
    });
  }

  public void setSize(int id, int width, int height) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          info.params.width = width;
          info.params.height = height;
          info.editText.setLayoutParams(info.params);
        }
      }
    });
  }

  public void setMaxLength(int id, int maxLength) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          info.editText.setFilters(new InputFilter[] {new InputFilter.LengthFilter(maxLength)});
        }
      }
    });
  }

  public void setKeyboardType(int id, int keyboardType) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          info.keyboardType = KeyboardType.values()[keyboardType];
          info.editText.setInputType(cookInputType(info.keyboardType, info.autoCapitalize));
        }
      }
    });
  }

  public void setAutoCapitalize(int id, int autoCapitalize) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          info.autoCapitalize = Capitalize.values()[autoCapitalize];
          info.editText.setInputType(cookInputType(info.keyboardType, info.autoCapitalize));
        }
      }
    });
  }

  public void setReturnKeyType(int id, int returnKeyType) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          ReturnKeyType type = ReturnKeyType.values()[returnKeyType];
          if (type == ReturnKeyType.DONE) {
            info.editText.setImeOptions(EditorInfo.IME_ACTION_DONE);
          } else if (type == ReturnKeyType.GO) {
            info.editText.setImeOptions(EditorInfo.IME_ACTION_GO);
          } else if (type == ReturnKeyType.NEXT && !info.isHidden) {
            info.editText.setImeOptions(EditorInfo.IME_ACTION_NEXT);
          } else if (type == ReturnKeyType.SEARCH) {
            info.editText.setImeOptions(EditorInfo.IME_ACTION_SEARCH);
          } else if (type == ReturnKeyType.SEND) {
            info.editText.setImeOptions(EditorInfo.IME_ACTION_SEND);
          }
        }
      }
    });
  }

  public String getText(int id) {
    FutureTask<String> futureResult = new FutureTask<String>(new Callable<String>() {
      @Override
      public String call() throws Exception {
        EditTextInfo info = getEditTextInfo(id);
        return info != null ? info.editText.getText().toString() : "";
      }
    });
    mActivity.runOnUiThread(futureResult);
    try {
      return futureResult.get();
    } catch (Exception wrappedException) {}
    return "";
  }

  public void focus(int id) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          if (info.editText.requestFocus()) {
            InputMethodManager imm = (InputMethodManager)mActivity.getSystemService(Context.INPUT_METHOD_SERVICE);
            imm.showSoftInput(info.editText, InputMethodManager.SHOW_IMPLICIT);
           }
        }
      }
    });
  }

  public void clearFocus(int id) {
    mActivity.runOnUiThread(new Runnable() {
      @Override
      public void run() {
        EditTextInfo info = getEditTextInfo(id);
        if (info != null) {
          InputMethodManager imm = (InputMethodManager)mActivity.getSystemService(Context.INPUT_METHOD_SERVICE);
          imm.hideSoftInputFromWindow(info.editText.getWindowToken(), 0);
          info.editText.clearFocus();
        }
      }
    });
  }

  private FrameLayout getLayout(boolean isHidden) {
    if (mLayoutMaster == null) {
      layoutMasterParams = new WindowManager.LayoutParams(
        WindowManager.LayoutParams.TYPE_APPLICATION,
        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
        PixelFormat.TRANSLUCENT
      );
      layoutMasterParams.gravity = Gravity.TOP | Gravity.LEFT;
      layoutMasterParams.softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING;
      if (Build.VERSION.SDK_INT < 30) {
        layoutMasterParams.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                                              | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                                              | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                                              | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                                              | View.SYSTEM_UI_FLAG_FULLSCREEN
                                              | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY;
      }
      if (Build.VERSION.SDK_INT >= 30) {
        layoutMasterParams.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS;
      }
      layoutMasterParams.width = 1;
      layoutMasterParams.height = 1;

      mLayoutMaster = new FrameLayout(mActivity) {
        @Override
        public boolean onTouchEvent(MotionEvent e) {
          MotionEvent motionEvent = MotionEvent.obtainNoHistory(e);
          mActivity.getWindow().injectInputEvent(motionEvent);
          return true;
        }
      };

      WindowManager wm = mActivity.getWindowManager();
      wm.addView(mLayoutMaster, layoutMasterParams);

      if (Build.VERSION.SDK_INT >= 30) {
        WindowInsetsController windowInsetsController = mLayoutMaster.getWindowInsetsController();
        windowInsetsController.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
        windowInsetsController.hide(WindowInsets.Type.systemBars());
      }

      FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(1, 1);
      mLayout1 = new FrameLayout(mActivity);
      mLayoutMaster.addView(mLayout1, params);
    }
    if (isHidden) {
      return mLayout1;
    } else {
      if (mLayout2 == null) {
        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
          FrameLayout.LayoutParams.MATCH_PARENT,
          FrameLayout.LayoutParams.MATCH_PARENT,
          Gravity.TOP | Gravity.LEFT
        );
        mLayout2 = new FrameLayout(mActivity);
        mLayoutMaster.addView(mLayout2, params);
        refreshLayoutMaster();
      }
      return mLayout2;
    }
  }

  private void refreshLayoutMaster() {
    layoutMasterParams.width = mLayout2 != null ? WindowManager.LayoutParams.MATCH_PARENT : 1;
    layoutMasterParams.height = mLayout2 != null ? WindowManager.LayoutParams.MATCH_PARENT : 1;
    WindowManager wm = mActivity.getWindowManager();
    wm.updateViewLayout(mLayoutMaster, layoutMasterParams);
  }

  private EditTextInfo getEditTextInfo(int id) {
    return mList.get(id);
  }

  private int cookInputType(KeyboardType keyboardType, Capitalize autoCapitalize) {
    int inputType;
    if (keyboardType == KeyboardType.PASSWORD) {
      inputType = InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
    } else if (keyboardType == KeyboardType.EMAIL) {
      inputType = InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
    } else if (keyboardType == KeyboardType.NUMBER_PAD) {
      inputType = InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_VARIATION_NORMAL;
    } else {
      inputType = InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_NORMAL | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
    }
    if (autoCapitalize == Capitalize.SENTENCES) {
      inputType = inputType | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES;
    } else if (autoCapitalize == Capitalize.WORDS) {
      inputType = inputType | InputType.TYPE_TEXT_FLAG_CAP_WORDS;
    } else if (autoCapitalize == Capitalize.CHARACTERS) {
      inputType = inputType | InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS;
    }
    return inputType;
  }

}
