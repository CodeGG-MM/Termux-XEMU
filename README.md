# Termux-XEMU
Trying to natively build Xemu Original Xbox emulator and run it in Termux.

Without Root, Proot, Chroot, Box64, Wine.

# Install

Install Termux and copy-paste enter -

[https://f-droid.org/repo/com.termux_1020.apk](https://f-droid.org/repo/com.termux_1020.apk)

    apt update -y && \
    yes | apt upgrade -y && \
    yes | termux-setup-storage >/dev/null; \
    apt install -y --no-install-recommends wget openbox && \
    wget -O xemu-arm64.deb "https://github.com/George-Seven/Termux-XEMU/releases/latest/download/xemu-arm64.deb" && \
    apt install ./xemu-arm64.deb

# Use
1) Download the game's ISO file for the [Original Xbox](https://myrient.erista.me/files/Redump/Microsoft%20-%20Xbox/). If it is zipped/compressed, extract the ISO file from the zip.

2) Convert the ISO file to XISO format needed by Xemu emulator.

       iso2xiso "/path/to/game.iso"

    Replace `"/path/to/game.iso"` with the file path to the game's ISO.
    
    Copy the path of the converted file that will be printed, such as `"/path/to/game.x.iso"`

3) Install Termux:X11 -

    [https://github.com/termux/termux-x11/releases/download/nightly/app-universal-debug.apk](https://github.com/termux/termux-x11/releases/download/nightly/app-universal-debug.apk)

4) Start the game in Xemu emulator -

       export DISPLAY=:1 && kill -9 $(pgrep -f "termux.x11") 2>/dev/null; if command -v openbox-session >/dev/null 2>&1; then termux-x11 -ac -xstartup openbox-session :1 2>/dev/null; else termux-x11 -ac :1; fi &
       
    And then,
       
       xemu -dvd_path "/path/to/game.x.iso"
    
    Replace `"/path/to/game.x.iso"` with the game's XISO file path.
    
    Open Termux:X11 app to access Xemu emulator UI.

5) Renderer is OpenGL by default. Try switching to Vulkan in **Xemu > View > Backend > Vulkan**.

# Progress
Seems to be working normally with OpenGL renderer. The games work, but OpenGL renderer is too slow. Instead trying to use Vulkan renderer.

Normally when using Vulkan renderer (in chroot) it gives around 10~12 times more FPS -

[https://www.reddit.com/r/EmulationOnAndroid/comments/1hkxaqj/ninja_gaiden_black_on_android_xemu_original_xbox/](https://www.reddit.com/r/EmulationOnAndroid/comments/1hkxaqj/ninja_gaiden_black_on_android_xemu_original_xbox/)

It works in chroot, so it should work even better without root.

# Vulkan Backend Attempts

For maximum performance, trying to run it natively in Termux using this Vulkan implementation -

**[mesa-vulkan-icd-wrapper](https://github.com/termux/termux-packages/pull/22500)**

It could potentially work with Mali/Xclipse GPU as well -

[https://github.com/xMeM/vulkan-wsi-layer/issues/40](https://github.com/xMeM/vulkan-wsi-layer/issues/40)

But, it is crashing when trying to switch to Vulkan renderer in **Xemu > View > Backend > Vulkan**.

```
$ apt install -y /sdcard/Download/mesa-vulkan-icd-wrapper_24.3.1-4_aarch64.deb
$ termux-x11 :1 &
$ export VK_INSTANCE_LAYERS=VK_LAYER_KHRONOS_validation
$ DISPLAY=:1 xemu
xemu_version: 0.7.132-123-g98a03e944c
xemu_branch: master
xemu_commit: 98a03e944c5d4c9f3f4973a51bf3b707819d1a89
xemu_date: Thu Dec 26 07:12:08 UTC 2024
xemu_settings_get_base_path: base path: /data/data/com.termux/files/home/.local/share/xemu/xemu/
xemu_settings_get_path: config path: /data/data/com.termux/files/home/.local/share/xemu/xemu/xemu.toml
CPU: 
OS_Version: Unknown Distro
GL_VENDOR: Mesa/X.org
GL_RENDERER: llvmpipe (LLVM 11.1.0, 128 bits)
GL_VERSION: 4.5 (Core Profile) Mesa 22.0.5
GL_SHADING_LANGUAGE_VERSION: 4.50
Created QEMU launch parameters: xemu -machine xbox,bootrom=/data/data/com.termux/files/usr/share/xemu/mcpx_1.0.bin,kernel-irqchip=off,avpack=hdtv -device smbus-storage,file=/data/data/com.termux/files/home/.local/share/xemu/xemu/eeprom.bin -bios /data/data/com.termux/files/usr/share/xemu/4627v1.03.bin -m 64 -drive index=0,media=disk,file=/data/data/com.termux/files/usr/share/xemu/xbox_hdd.qcow2,locked=on -drive index=1,media=cdrom,file= -display xemu -device usb-hub,port=1,ports=4 
Enabled instance extensions:
- VK_KHR_surface
- VK_KHR_xlib_surface
- VK_KHR_get_physical_device_properties2
- VK_KHR_external_semaphore_capabilities
- VK_KHR_external_memory_capabilities
Available physical devices:
- Adreno (TM) 750
Selected physical device: Adreno (TM) 750
- Vendor: 5143, Device: 43051401
- Driver Version: 512.744.12
Warning: extension not available: VK_EXT_memory_budget
Enabled device extensions:
- VK_KHR_external_semaphore
- VK_KHR_external_memory
- VK_KHR_external_memory_fd
- VK_KHR_external_semaphore_fd
- VK_EXT_custom_border_color
- VK_EXT_provoking_vertex
VUID-VkMemoryAllocateInfo-pNext-00639(ERROR / SPEC): msgNum: -49292556 - Validation Error: [ VUID-VkMemoryAllocateInfo-pNext-00639 ] Object 0: handle = 0x84e000000084e, type = VK_OBJECT_TYPE_IMAGE; Object 1: handle = 0x84f000000084f, type = VK_OBJECT_TYPE_DEVICE_MEMORY; | MessageID = 0xfd0fdaf4 | vkBindImageMemory(): memory (VkDeviceMemory 0x84f000000084f[]) has VkExportMemoryAllocateInfo::handleTypes with the VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT flag set, which requires dedicated allocation for the image created with format (VK_FORMAT_R8G8B8A8_UNORM), type (VK_IMAGE_TYPE_2D), tiling (VK_IMAGE_TILING_LINEAR), usage (VK_IMAGE_USAGE_SAMPLED_BIT|VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT), flags (VkImageCreateFlags(0)), but the memory is allocated without dedicated allocation support.
The Vulkan spec states: If the pNext chain includes a VkExportMemoryAllocateInfo structure, and any of the handle types specified in VkExportMemoryAllocateInfo::handleTypes require a dedicated allocation, as reported by vkGetPhysicalDeviceImageFormatProperties2 in VkExternalImageFormatProperties::externalMemoryProperties.externalMemoryFeatures, or by vkGetPhysicalDeviceExternalBufferProperties in VkExternalBufferProperties::externalMemoryProperties.externalMemoryFeatures, the pNext chain must include a VkMemoryDedicatedAllocateInfo or VkDedicatedAllocationMemoryAllocateInfoNV structure with either its image or buffer member set to a value other than VK_NULL_HANDLE (https://www.khronos.org/registry/vulkan/specs/1.3-extensions/html/vkspec.html#VUID-VkMemoryAllocateInfo-pNext-00639)
    Objects: 2
        [0] 0x84e000000084e, type: 10, name: NULL
        [1] 0x84f000000084f, type: 8, name: NULL
VUID-VkImageViewCreateInfo-image-01020(ERROR / SPEC): msgNum: -1539087141 - Validation Error: [ VUID-VkImageViewCreateInfo-image-01020 ] Object 0: handle = 0x84e000000084e, type = VK_OBJECT_TYPE_IMAGE; | MessageID = 0xa44364db | vkCreateImageView(): pCreateInfo->image VkImage 0x84e000000084e[] used with no memory bound. Memory should be bound by calling vkBindImageMemory().
The Vulkan spec states: If image is non-sparse then it must be bound completely and contiguously to a single VkDeviceMemory object (https://www.khronos.org/registry/vulkan/specs/1.3-extensions/html/vkspec.html#VUID-VkImageViewCreateInfo-image-01020)
    Objects: 1
        [0] 0x84e000000084e, type: 10, name: NULL
vk_result = -1
../hw/xbox/nv2a/pgraph/vk/display.c:691: void create_display_image(PGRAPHState *, int, int): assertion "vk_result == VK_SUCCESS && "vk check failed"" failed
```

Crashing at line -

**[xemu/hw/xbox/nv2a/pgraph/vk/display.c:691](https://github.com/xemu-project/xemu/blob/98a03e944c5d4c9f3f4973a51bf3b707819d1a89/hw/xbox/nv2a/pgraph/vk/display.c#L691)**

# Build
    cd; \
    git clone https://github.com/George-Seven/Termux-XEMU; \
    cd Termux-XEMU; \
    ./build-xemu.sh