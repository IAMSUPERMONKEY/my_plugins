package com.example.flutternativeimage;

import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

/**
 * FlutterNativeImagePlugin
 */
public class FlutterNativeImagePlugin implements FlutterPlugin {
  private static final String CHANNEL_NAME = "flutter_native_image";
  private MethodChannel channel;

  @Override
  public void onAttachedToEngine(FlutterPlugin.FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    MethodCallHandlerImpl methodCallHandler = new MethodCallHandlerImpl(binding.getApplicationContext());
    channel.setMethodCallHandler(methodCallHandler);
  }

  @Override
  public void onDetachedFromEngine(FlutterPlugin.FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    channel = null;
  }

}
