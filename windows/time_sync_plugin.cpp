#include "time_sync_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <stdio.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

#include "wlanapi.h"

int getWifiStrength();

namespace time_sync_plugin {

// static
void TimeSyncPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "time_sync_plugin",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<TimeSyncPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

TimeSyncPlugin::TimeSyncPlugin() {}

TimeSyncPlugin::~TimeSyncPlugin() {}

void TimeSyncPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  } else if (method_call.method_name().compare("setSyncTime") == 0) {
      std::string sync_time;
      const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (arguments) {
          auto time_it = arguments->find(flutter::EncodableValue("syncTime"));
          if (time_it != arguments->end()) {
              sync_time = std::get<std::string>(time_it->second);
              SYSTEMTIME st = {0};
              int year=0, mon=0, day=0, hour=0, min=0, sec=0, msec=0;
              sscanf_s(sync_time.c_str(), "%4d-%2d-%2dT%2d:%2d:%2d.%3d",
                       &year, &mon, &day, &hour, &min, &sec, &msec);
              st.wYear = (WORD)year;
              st.wMonth = (WORD)mon;
              st.wDay = (WORD)day;
              st.wHour = (WORD)hour;
              st.wMinute = (WORD)min;
              st.wSecond = (WORD)sec;
              st.wMilliseconds = (WORD)msec;
              SetSystemTime(&st);
          }
      }
      result->Success(true);
  } else if (method_call.method_name().compare("getWifiStrength") == 0) {
      result->Success(getWifiStrength());
  } else {
    result->NotImplemented();
  }
}

}  // namespace time_sync_plugin


int getWifiStrength() {
    HANDLE hClient = NULL;
    PWLAN_INTERFACE_INFO_LIST pIfList = NULL;
    PWLAN_INTERFACE_INFO pIfConnInfo = NULL;
    PWLAN_CONNECTION_ATTRIBUTES pConnectInfo = NULL;

    PWLAN_BSS_LIST pBssList = NULL;
    PWLAN_BSS_ENTRY  pBssEntry = NULL;
    WLAN_OPCODE_VALUE_TYPE opCode = wlan_opcode_value_type_invalid;

    DWORD dwResult = 0;
    DWORD dwMaxClient = 2;
    DWORD dwCurVersion = 0;
    DWORD connectInfoSize = sizeof(WLAN_CONNECTION_ATTRIBUTES);

    int i;

    // Initialise the Handle
    dwResult = WlanOpenHandle(dwMaxClient, NULL, &dwCurVersion, &hClient);
    if (dwResult != ERROR_SUCCESS)
    {
        return -100;
    }

    // Get the Interface List
    dwResult = WlanEnumInterfaces(hClient, NULL, &pIfList);
    if (dwResult != ERROR_SUCCESS)
    {
        WlanCloseHandle(hClient, NULL);
        return -100;
    }

    //Loop through the List to find the connected Interface
    PWLAN_INTERFACE_INFO pIfInfo = NULL;
    for (i = 0; i < (int)pIfList->dwNumberOfItems; i++)
    {
        pIfInfo = (WLAN_INTERFACE_INFO *)& pIfList->InterfaceInfo[i];
        if (pIfInfo->isState == wlan_interface_state_connected)
        {
            pIfConnInfo = pIfInfo;
            break;
        }
    }

    if (pIfConnInfo == NULL)
    {
        WlanFreeMemory(pIfList);
        WlanCloseHandle(hClient, NULL);
        return -100;
    }

    // Query the Interface
    dwResult = WlanQueryInterface(hClient, &pIfConnInfo->InterfaceGuid, wlan_intf_opcode_current_connection, NULL, &connectInfoSize, (PVOID *)&pConnectInfo, &opCode);
    if (dwResult != ERROR_SUCCESS)
    {
        WlanFreeMemory(pIfList);
        WlanCloseHandle(hClient, NULL);
        return -100;
    }

    // Scan the connected SSID
    //dwResult = WlanScan(hClient, &pIfConnInfo->InterfaceGuid, /*&pConnectInfo->wlanAssociationAttributes.dot11Ssid*/NULL, NULL, NULL);
    //if (dwResult != ERROR_SUCCESS)
    //{
    //	return -100;
    //}

    // Get the BSS Entry
    dwResult = WlanGetNetworkBssList(hClient, &pIfConnInfo->InterfaceGuid, /*&pConnectInfo->wlanAssociationAttributes.dot11Ssid*/NULL, /*dot11_BSS_type_infrastructure*/dot11_BSS_type_any, TRUE, NULL, &pBssList);

    if (dwResult != ERROR_SUCCESS)
    {
        WlanFreeMemory(pIfList);
        WlanCloseHandle(hClient, NULL);
        return -100;
    }

    // Get the RSSI value
    WlanFreeMemory(pIfList);
    WlanCloseHandle(hClient, NULL);
    pBssEntry = &pBssList->wlanBssEntries[0];
    return pBssEntry->lRssi;
}
