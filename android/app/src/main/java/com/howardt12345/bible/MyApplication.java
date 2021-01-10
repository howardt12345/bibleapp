package com.howardt12345.bible;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import androidx.multidex.MultiDex;
import androidx.annotation.CallSuper;

import io.flutter.view.FlutterMain;

public class MyApplication extends Application {
    @Override
    @CallSuper
    public void onCreate() {
        super.onCreate();
        FlutterMain.startInitialization(this);
    }

    @Override
    protected void attachBaseContext(Context base) {
        super.attachBaseContext(base);
        MultiDex.install(this);
    }

    private Activity mCurrentActivity = null;
    public Activity getCurrentActivity() {
        return mCurrentActivity;
    }
    public void setCurrentActivity(Activity mCurrentActivity) {
        this.mCurrentActivity = mCurrentActivity;
    }
}