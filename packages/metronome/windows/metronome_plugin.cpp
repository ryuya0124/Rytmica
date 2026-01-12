#include "metronome_plugin.h"
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/encodable_value.h>
#include <flutter/plugin_registrar_windows.h>
#include <iostream>
#include <windows.h>

#define WM_METRONOME_TICK (WM_USER + 999)

namespace metronome
{
  MetronomePlugin *MetronomePlugin::instance = nullptr;

  void MetronomePlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar)
  {
    auto methodChannel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "metronome",
            &flutter::StandardMethodCodec::GetInstance());

    auto eventChannel =
        std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
            registrar->messenger(), "metronome_tick",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<MetronomePlugin>();

    plugin->hwnd = registrar->GetView()->GetNativeWindow();

    registrar->RegisterTopLevelWindowProcDelegate(
      [plugin_pointer = plugin.get()](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) -> std::optional<LRESULT> {
         if (message == WM_METRONOME_TICK) {
            plugin_pointer->SendTick((int)wparam);
            return 0;
         }
         if (message == MM_WOM_DONE) {
             // MM_WOM_DONE passes hWaveOut in wParam, and WAVEHDR* in lParam
             if (plugin_pointer->metronome) {
                 plugin_pointer->metronome->ProcessBuffer((WAVEHDR*)lparam);
             }
             return 0;
         }
         return std::nullopt;
      });

    methodChannel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result)
        {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    eventChannel->SetStreamHandler(
        std::make_unique<flutter::StreamHandlerFunctions<>>(
            [plugin_pointer = plugin.get()](
                const flutter::EncodableValue *arguments,
                std::unique_ptr<flutter::EventSink<>> &&events)
                -> std::unique_ptr<flutter::StreamHandlerError<>>
            {
              plugin_pointer->eventSink = std::shared_ptr<flutter::EventSink<flutter::EncodableValue>>(events.release());
              return nullptr;
            },
            [plugin_pointer = plugin.get()](const flutter::EncodableValue *arguments)
                -> std::unique_ptr<flutter::StreamHandlerError<>>
            {
              plugin_pointer->eventSink.reset();
              return nullptr;
            }));

    registrar->AddPlugin(std::move(plugin));
  }

  MetronomePlugin::MetronomePlugin()
  {
      instance = this;
  }

  MetronomePlugin::~MetronomePlugin() {
      if (instance == this) instance = nullptr;
  }

  void MetronomePlugin::SendTick(int tick) {
      if (eventSink) {
          eventSink->Success(flutter::EncodableValue(tick));
      }
  }

  void MetronomePlugin::HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    const auto &method = method_call.method_name();
    if (method == "init")
    {
      auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
      std::vector<uint8_t> mainFileBytes = std::get<std::vector<uint8_t>>(arguments[flutter::EncodableValue("mainFileBytes")]);
      std::vector<uint8_t> accentedFileBytes = std::get<std::vector<uint8_t>>(arguments[flutter::EncodableValue("accentedFileBytes")]);
      int timeSignature = std::get<int>(arguments[flutter::EncodableValue("timeSignature")]);
      int bpm = std::get<int>(arguments[flutter::EncodableValue("bpm")]);
      double volume = std::get<double>(arguments[flutter::EncodableValue("volume")]);
      int sampleRate = std::get<int>(arguments[flutter::EncodableValue("sampleRate")]);
      bool enableTickCallback = std::get<bool>(arguments[flutter::EncodableValue("enableTickCallback")]);

      metronome = std::make_unique<Metronome>(this->hwnd, mainFileBytes, accentedFileBytes, bpm, timeSignature, volume, sampleRate);
      if (enableTickCallback)
      {
        HWND targetHwnd = this->hwnd;
        metronome->EnableTickCallback([targetHwnd](int tick) {
             if (targetHwnd) {
                 PostMessage(targetHwnd, WM_METRONOME_TICK, (WPARAM)tick, 0);
             }
        });
      }
      result->Success(true);
    }
    else if (method == "play")
    {
      metronome->Play();
      result->Success(true);
    }
    else if (method == "pause")
    {
      metronome->Pause();
      result->Success(true);
    }
    else if (method == "stop")
    {
      metronome->Stop();
      result->Success(true);
    }
    else if (method == "setBPM")
    {
      auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
      int bpm = std::get<int>(arguments[flutter::EncodableValue("bpm")]);
      metronome->SetBPM(bpm);
      std::cout << "bpm " << bpm << std::endl;
      result->Success(true);
    }
    else if (method == "getBPM")
    {
      result->Success(flutter::EncodableValue(metronome->audioBpm));
    }
    else if (method == "setTimeSignature")
    {
      auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
      int timeSignature = std::get<int>(arguments[flutter::EncodableValue("timeSignature")]);
      metronome->SetTimeSignature(timeSignature);
      result->Success(true);
    }
    else if (method == "getTimeSignature")
    {
      result->Success(flutter::EncodableValue(metronome->audioTimeSignature));
    }
    else if (method == "setVolume")
    {
      auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
      double volume = std::get<double>(arguments[flutter::EncodableValue("volume")]);
      metronome->SetVolume(volume);
      result->Success(true);
    }
    else if (method == "getVolume")
    {
      result->Success(flutter::EncodableValue(metronome->GetVolume()));
    }
    else if (method == "setAudioFile")
    {
      auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
      auto mainFileBytes = std::get<std::vector<uint8_t>>(arguments[flutter::EncodableValue("mainFileBytes")]);
      auto accentedFileBytes = std::get<std::vector<uint8_t>>(arguments[flutter::EncodableValue("accentedFileBytes")]);
      metronome->SetAudioFile(mainFileBytes, accentedFileBytes);
      result->Success(true);
    }
    else if (method == "isPlaying")
    {
      result->Success(flutter::EncodableValue(metronome->IsPlaying()));
    }
    else if (method == "destroy")
    {
      if (eventSink)
      {
        eventSink.reset();
      }
      if (metronome) metronome->Destroy();
      result->Success(true);
    }
    else
    {
      result->NotImplemented();
    }
  }
}
