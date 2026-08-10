# Registers the Start Menu shortcut a WinRT toast needs (docs/architecture.md, Platform Considerations).
#
# Windows will not show a toast for an unpackaged Win32 application unless a
# Start Menu shortcut exists carrying the same AppUserModelID the app files its
# notifications under. There is no error when it is missing: WinRT accepts the
# toast and displays nothing, which is the single most confusing way this can
# fail and the reason this script exists rather than a line in a README.
#
# Run it **once**, from this directory, before the Sprint 06 manual pass:
#
#     powershell -ExecutionPolicy Bypass -File tool/register_windows_toast.ps1
#
# It writes one shortcut under the current user's Start Menu and touches
# nothing else. Remove it with -Remove when you are done.
#
# The AUMID must match _windowsApplicationId in lib/main.dart. When Norte
# gains a real installer, the installer creates this shortcut and this script
# becomes a development-only convenience.

param(
    [string]$ApplicationId = 'com.norte.app',
    [string]$DisplayName = 'Norte',
    [string]$Target = '',
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'

$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$shortcutPath = Join-Path $startMenu "$DisplayName.lnk"

if ($Remove) {
    if (Test-Path $shortcutPath) {
        Remove-Item $shortcutPath
        Write-Host "Removed $shortcutPath"
    } else {
        Write-Host "Nothing to remove at $shortcutPath"
    }
    exit 0
}

if (-not $Target) {
    # The debug build `flutter run -d windows` produces. Pass -Target explicitly
    # to point the shortcut at a release build instead.
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $Target = Join-Path $repoRoot 'build\windows\x64\runner\Debug\norte.exe'
}

if (-not (Test-Path $Target)) {
    Write-Error @"
No executable at:
  $Target

Build it first - "flutter build windows --debug", or one "flutter run -d windows"
- then run this script again. A shortcut pointing at nothing registers the
AUMID but gives you nothing to click from the toast.
"@
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $Target
$shortcut.WorkingDirectory = Split-Path -Parent $Target
$shortcut.Save()

# The shortcut is only half of it. The AUMID lives in the shell property store
# under PKEY_AppUserModel_ID (System.AppUserModel.ID), which WScript.Shell
# cannot write - so the property is set through the shell's own property
# system, which is what Set-ShortcutProperty below does via Windows.Storage.
$propertyStore = @'
using System;
using System.Runtime.InteropServices;

public static class ShortcutAumid
{
    [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
    private static extern void SHGetPropertyStoreFromParsingName(
        string path, IntPtr zero, int flags, ref Guid iid,
        [MarshalAs(UnmanagedType.Interface)] out IPropertyStore store);

    [ComImport, Guid("886d8eeb-8cf2-4446-8d02-cdba1dbdcf99"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IPropertyStore
    {
        void GetCount(out uint count);
        void GetAt(uint index, out PropertyKey key);
        void GetValue(ref PropertyKey key, out PropVariant value);
        void SetValue(ref PropertyKey key, ref PropVariant value);
        void Commit();
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct PropertyKey
    {
        public Guid FormatId;
        public int PropertyId;
        public PropertyKey(Guid formatId, int propertyId)
        {
            FormatId = formatId;
            PropertyId = propertyId;
        }
    }

    [StructLayout(LayoutKind.Explicit)]
    private struct PropVariant
    {
        [FieldOffset(0)] public ushort VariantType;
        [FieldOffset(8)] public IntPtr Pointer;
    }

    public static void Set(string shortcutPath, string applicationId)
    {
        var storeId = new Guid("886d8eeb-8cf2-4446-8d02-cdba1dbdcf99");
        IPropertyStore store;
        SHGetPropertyStoreFromParsingName(shortcutPath, IntPtr.Zero, 2,
            ref storeId, out store);

        // PKEY_AppUserModel_ID
        var key = new PropertyKey(
            new Guid("9f4c2855-9f79-4b39-a8d0-e1d42de1d5f3"), 5);

        var value = new PropVariant();
        value.VariantType = 31; // VT_LPWSTR
        value.Pointer = Marshal.StringToCoTaskMemUni(applicationId);

        store.SetValue(ref key, ref value);
        store.Commit();
        Marshal.FreeCoTaskMem(value.Pointer);
        Marshal.ReleaseComObject(store);
    }
}
'@

Add-Type -TypeDefinition $propertyStore -Language CSharp
[ShortcutAumid]::Set($shortcutPath, $ApplicationId)

Write-Host "Registered:"
Write-Host "  shortcut  $shortcutPath"
Write-Host "  target    $Target"
Write-Host "  AUMID     $ApplicationId"
Write-Host ""
Write-Host "Sign out and back in, or restart Explorer, if the first toast does"
Write-Host "not appear - the shell caches the AUMID table."
