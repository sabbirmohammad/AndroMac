import Foundation

public final class AVDManager: Sendable {
    public static let shared = AVDManager()

    public init() {}

    public var avdHomeDirectory: String {
        let home = NSHomeDirectory()
        return "\(home)/.android/avd"
    }

    public func doesAVDExist(named name: String = "AndroMac_Laptop") -> Bool {
        let iniFile = "\(avdHomeDirectory)/\(name).ini"
        let avdDir = "\(avdHomeDirectory)/\(name).avd"
        if FileManager.default.fileExists(atPath: iniFile) && FileManager.default.fileExists(atPath: avdDir) {
            return true
        }
        // Fallback check for legacy AndroMac_Tablet AVD
        if name == "AndroMac_Laptop" {
            let legacyIni = "\(avdHomeDirectory)/AndroMac_Tablet.ini"
            let legacyDir = "\(avdHomeDirectory)/AndroMac_Tablet.avd"
            return FileManager.default.fileExists(atPath: legacyIni) && FileManager.default.fileExists(atPath: legacyDir)
        }
        return false
    }

    public func configureAVD(config: TabletConfig, systemImagePackage: String? = nil, report: EnvironmentReport) throws {
        let name = config.avdName
        let fm = FileManager.default
        let avdDir = "\(avdHomeDirectory)/\(name).avd"
        let iniFile = "\(avdHomeDirectory)/\(name).ini"

        try fm.createDirectory(atPath: avdHomeDirectory, withIntermediateDirectories: true)

        let resolvedSysImg: String
        if let pkg = systemImagePackage {
            resolvedSysImg = pkg
        } else if let found = report.availableSystemImages.first(where: { $0.contains("google_apis_playstore") && $0.contains("arm64") }) {
            resolvedSysImg = found
        } else {
            throw NSError(domain: "AVDManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No compatible ARM64 Google Play system image found."])
        }

        let parts = resolvedSysImg.split(separator: ";")
        let sysdirRel: String
        if parts.count >= 4 {
            sysdirRel = "system-images/\(parts[1])/\(parts[2])/\(parts[3])/"
        } else {
            sysdirRel = "system-images/android-36/google_apis_playstore/arm64-v8a/"
        }

        let targetAndroid = parts.count >= 2 ? String(parts[1]) : "android-36"

        if !fm.fileExists(atPath: avdDir) {
            try fm.createDirectory(atPath: avdDir, withIntermediateDirectories: true)
        }

        let iniContent = """
        avd.ini.encoding=UTF-8
        path=\(avdDir)
        path.rel=avd/\(name).avd
        target=\(targetAndroid)
        """
        try iniContent.write(toFile: iniFile, atomically: true, encoding: .utf8)

        let isLaptop = (config.deviceMode == .laptop)
        let deviceName = isLaptop ? "desktop" : "pixel_tablet"

        let configIniContent = """
        PlayStore.enabled=\(config.playStoreEnabled ? "true" : "false")
        abi.type=arm64-v8a
        avd.id=\(name)
        avd.ini.displayname=\(config.displayName)
        avd.ini.encoding=UTF-8
        avd.name=\(name)
        disk.cachePartition=yes
        disk.cachePartition.size=66MB
        disk.dataPartition.size=\(config.storageGB)G
        fastboot.forceFastBoot=\(config.coldBoot ? "no" : "yes")
        fastboot.forceColdBoot=\(config.coldBoot ? "yes" : "no")
        firstboot.bootFromDownloadableSnapshot=yes
        firstboot.bootFromLocalSnapshot=yes
        firstboot.saveToLocalSnapshot=yes
        hw.accelerometer=no
        hw.audioInput=yes
        hw.audioOutput=yes
        hw.battery=yes
        hw.camera.back=none
        hw.camera.front=none
        hw.cpu.arch=arm64
        hw.cpu.ncore=\(config.cpuCores)
        hw.device.manufacturer=Google
        hw.device.name=\(deviceName)
        hw.gps=no
        hw.gpu.enabled=yes
        hw.gpu.mode=\(config.gpuMode == "auto" ? "host" : config.gpuMode)
        hw.initialOrientation=\(config.orientation)
        hw.keyboard=yes
        hw.keyboard.charmap=qwerty2
        hw.keyboard.lid=yes
        hw.mouse=yes
        hw.lcd.density=\(config.density)
        hw.lcd.height=\(config.height)
        hw.lcd.width=\(config.width)
        hw.mainKeys=no
        hw.ramSize=\(config.ramMB)
        hw.sdCard=yes
        hw.sensors.orientation=no
        hw.touchScreen=yes
        image.sysdir.1=\(sysdirRel)
        runtime.network.latency=none
        runtime.network.speed=full
        sdcard.size=512M
        showDeviceFrame=\(config.showDeviceFrame ? "yes" : "no")
        skin.dynamic=yes
        skin.name=\(config.width)x\(config.height)
        tag.display=Google Play
        tag.id=google_apis_playstore
        target=\(targetAndroid)
        vm.heapSize=\(config.heapSizeMB)M
        """

        let configIniPath = "\(avdDir)/config.ini"
        try configIniContent.write(toFile: configIniPath, atomically: true, encoding: .utf8)
    }

    public func wipeData(avdName: String = "AndroMac_Laptop") throws {
        let avdDir = "\(avdHomeDirectory)/\(avdName).avd"
        let fm = FileManager.default
        let itemsToDelete = [
            "\(avdDir)/userdata-qemu.img",
            "\(avdDir)/userdata-qemu.img.qcow2",
            "\(avdDir)/cache.img",
            "\(avdDir)/cache.img.qcow2",
            "\(avdDir)/snapshots"
        ]

        for item in itemsToDelete {
            if fm.fileExists(atPath: item) {
                try fm.removeItem(atPath: item)
            }
        }
    }
}
